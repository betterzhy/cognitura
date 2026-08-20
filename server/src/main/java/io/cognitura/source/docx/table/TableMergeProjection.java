package io.cognitura.source.docx.table;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public record TableMergeProjection(
        int anchorRow,
        int anchorColumn,
        int rowSpan,
        int columnSpan,
        List<GridPosition> coveredPositions) {

    private static final long MAX_MERGE_AREA = 1_000_000L;

    public TableMergeProjection {
        if (anchorRow < 0 || anchorColumn < 0 || rowSpan < 1 || columnSpan < 1) {
            throw new IllegalArgumentException("TABLE_MERGE_COORDINATE_INVALID");
        }
        if (rowSpan == 1 && columnSpan == 1) {
            throw new IllegalArgumentException("TABLE_MERGE_SPAN_REQUIRED");
        }
        requireGeometryWithinLimits(anchorRow, anchorColumn, rowSpan, columnSpan);
        long rowEnd = (long) anchorRow + rowSpan;
        long columnEnd = (long) anchorColumn + columnSpan;
        coveredPositions = List.copyOf(
                Objects.requireNonNull(coveredPositions, "coveredPositions"));
        List<GridPosition> expected = new ArrayList<>();
        for (long row = anchorRow; row < rowEnd; row++) {
            for (long column = anchorColumn; column < columnEnd; column++) {
                if (row != anchorRow || column != anchorColumn) {
                    expected.add(new GridPosition((int) row, (int) column));
                }
            }
        }
        if (!coveredPositions.equals(expected)) {
            throw new IllegalArgumentException("TABLE_MERGE_COVERAGE_INVALID");
        }
    }

    public static TableMergeProjection fromCell(TableCellCandidate cell) {
        Objects.requireNonNull(cell, "cell");
        requireGeometryWithinLimits(
                cell.rowIndex(), cell.columnIndex(), cell.rowSpan(), cell.columnSpan());
        List<GridPosition> covered = new ArrayList<>();
        long rowEnd = (long) cell.rowIndex() + cell.rowSpan();
        long columnEnd = (long) cell.columnIndex() + cell.columnSpan();
        for (long row = cell.rowIndex(); row < rowEnd; row++) {
            for (long column = cell.columnIndex();
                    column < columnEnd;
                    column++) {
                if (row != cell.rowIndex() || column != cell.columnIndex()) {
                    covered.add(new GridPosition((int) row, (int) column));
                }
            }
        }
        return new TableMergeProjection(
                cell.rowIndex(),
                cell.columnIndex(),
                cell.rowSpan(),
                cell.columnSpan(),
                covered);
    }

    static void requireGeometryWithinLimits(
            int anchorRow, int anchorColumn, int rowSpan, int columnSpan) {
        if (anchorRow < 0 || anchorColumn < 0 || rowSpan < 1 || columnSpan < 1) {
            throw new IllegalArgumentException("TABLE_MERGE_COORDINATE_INVALID");
        }
        long rowEnd = (long) anchorRow + rowSpan;
        long columnEnd = (long) anchorColumn + columnSpan;
        if (rowEnd > (long) Integer.MAX_VALUE + 1
                || columnEnd > (long) Integer.MAX_VALUE + 1) {
            throw new IllegalArgumentException("TABLE_MERGE_COORDINATE_INVALID");
        }
        if ((long) rowSpan * columnSpan > MAX_MERGE_AREA) {
            throw new IllegalArgumentException("TABLE_MERGE_SPAN_EXCEEDED");
        }
    }

    public record GridPosition(int rowIndex, int columnIndex) {
        public GridPosition {
            if (rowIndex < 0 || columnIndex < 0) {
                throw new IllegalArgumentException("TABLE_GRID_POSITION_INVALID");
            }
        }
    }
}
