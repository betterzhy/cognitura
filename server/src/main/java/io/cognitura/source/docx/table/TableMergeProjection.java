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

    public TableMergeProjection {
        if (anchorRow < 0 || anchorColumn < 0 || rowSpan < 1 || columnSpan < 1) {
            throw new IllegalArgumentException("TABLE_MERGE_COORDINATE_INVALID");
        }
        if (rowSpan == 1 && columnSpan == 1) {
            throw new IllegalArgumentException("TABLE_MERGE_SPAN_REQUIRED");
        }
        coveredPositions = List.copyOf(
                Objects.requireNonNull(coveredPositions, "coveredPositions"));
        List<GridPosition> expected = new ArrayList<>();
        for (int row = anchorRow; row < anchorRow + rowSpan; row++) {
            for (int column = anchorColumn; column < anchorColumn + columnSpan; column++) {
                if (row != anchorRow || column != anchorColumn) {
                    expected.add(new GridPosition(row, column));
                }
            }
        }
        if (!coveredPositions.equals(expected)) {
            throw new IllegalArgumentException("TABLE_MERGE_COVERAGE_INVALID");
        }
    }

    public static TableMergeProjection fromCell(TableCellCandidate cell) {
        Objects.requireNonNull(cell, "cell");
        List<GridPosition> covered = new ArrayList<>();
        for (int row = cell.rowIndex(); row < cell.rowIndex() + cell.rowSpan(); row++) {
            for (int column = cell.columnIndex();
                    column < cell.columnIndex() + cell.columnSpan();
                    column++) {
                if (row != cell.rowIndex() || column != cell.columnIndex()) {
                    covered.add(new GridPosition(row, column));
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

    public record GridPosition(int rowIndex, int columnIndex) {
        public GridPosition {
            if (rowIndex < 0 || columnIndex < 0) {
                throw new IllegalArgumentException("TABLE_GRID_POSITION_INVALID");
            }
        }
    }
}
