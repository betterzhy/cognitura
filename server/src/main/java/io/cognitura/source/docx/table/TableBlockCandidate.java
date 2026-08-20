package io.cognitura.source.docx.table;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public record TableBlockCandidate(
        int sourceOrder,
        String sourcePart,
        int sourceElementIndex,
        int rowCount,
        int columnCount,
        List<TableCellCandidate> cells,
        List<TableMergeProjection> merges) {

    private static final int MAX_GRID_DIMENSION = 10_000;
    private static final long MAX_GRID_AREA = 1_000_000L;

    public TableBlockCandidate {
        if (sourceOrder < 0 || sourceElementIndex < 0) {
            throw new IllegalArgumentException("TABLE_SOURCE_POSITION_INVALID");
        }
        if (sourcePart == null || sourcePart.isBlank()) {
            throw new IllegalArgumentException("TABLE_SOURCE_PART_REQUIRED");
        }
        if (rowCount < 1 || columnCount < 1) {
            throw new IllegalArgumentException("TABLE_GRID_SIZE_INVALID");
        }
        requireGridWithinLimits(rowCount, columnCount);
        cells = List.copyOf(Objects.requireNonNull(cells, "cells"));
        merges = List.copyOf(Objects.requireNonNull(merges, "merges"));
        if (cells.isEmpty()) {
            throw new IllegalArgumentException("TABLE_CELLS_REQUIRED");
        }

        boolean[][] occupied = new boolean[rowCount][columnCount];
        long previousAnchor = -1;
        List<TableMergeProjection> expectedMerges = new ArrayList<>();
        for (TableCellCandidate cell : cells) {
            long anchor = (long) cell.rowIndex() * columnCount + cell.columnIndex();
            if (anchor <= previousAnchor) {
                throw new IllegalArgumentException("TABLE_CELL_ORDER_INVALID");
            }
            previousAnchor = anchor;
            if (cell.rowIndex() > rowCount - cell.rowSpan()
                    || cell.columnIndex() > columnCount - cell.columnSpan()) {
                throw new IllegalArgumentException("TABLE_CELL_SPAN_OUT_OF_BOUNDS");
            }
            for (int row = cell.rowIndex(); row < cell.rowIndex() + cell.rowSpan(); row++) {
                for (int column = cell.columnIndex();
                        column < cell.columnIndex() + cell.columnSpan();
                        column++) {
                    if (occupied[row][column]) {
                        throw new IllegalArgumentException("TABLE_CELL_GRID_OVERLAP");
                    }
                    occupied[row][column] = true;
                }
            }
            if (cell.rowSpan() > 1 || cell.columnSpan() > 1) {
                expectedMerges.add(TableMergeProjection.fromCell(cell));
            }
        }
        for (boolean[] row : occupied) {
            for (boolean position : row) {
                if (!position) {
                    throw new IllegalArgumentException("TABLE_CELL_GRID_GAP");
                }
            }
        }
        if (!merges.equals(expectedMerges)) {
            throw new IllegalArgumentException("TABLE_MERGE_PROJECTION_MISMATCH");
        }
    }

    static void requireGridWithinLimits(int rowCount, int columnCount) {
        long area = (long) rowCount * columnCount;
        if (rowCount > MAX_GRID_DIMENSION
                || columnCount > MAX_GRID_DIMENSION
                || area > MAX_GRID_AREA) {
            throw new IllegalArgumentException("TABLE_GRID_SIZE_EXCEEDED");
        }
    }
}
