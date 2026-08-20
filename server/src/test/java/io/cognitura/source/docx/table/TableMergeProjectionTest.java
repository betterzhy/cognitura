package io.cognitura.source.docx.table;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.cognitura.source.docx.security.SafeDocxPackage;
import io.cognitura.source.domain.SourceDomainException;
import java.io.IOException;
import java.nio.file.Path;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class TableMergeProjectionTest {

    @TempDir
    Path temporaryDirectory;

    @Test
    void emitsOnlyMergeAnchorsAndProjectsEveryCoveredGridCoordinate() throws IOException {
        try (SafeDocxPackage safePackage =
                TableFidelityParserTest.openFixture(temporaryDirectory, "merged-table.xml")) {
            TableBlockCandidate table = new TableFidelityParser().parse(safePackage).getFirst();

            assertThat(table.cells())
                    .extracting(
                            TableCellCandidate::rowIndex,
                            TableCellCandidate::columnIndex,
                            TableCellCandidate::rowSpan,
                            TableCellCandidate::columnSpan,
                            TableCellCandidate::text)
                    .containsExactly(
                            org.assertj.core.groups.Tuple.tuple(0, 0, 2, 2, "Merged"),
                            org.assertj.core.groups.Tuple.tuple(0, 2, 1, 1, "C2"),
                            org.assertj.core.groups.Tuple.tuple(0, 3, 2, 1, "Vertical"),
                            org.assertj.core.groups.Tuple.tuple(1, 2, 1, 1, "R1C2"));
            assertThat(table.merges()).containsExactly(
                    new TableMergeProjection(
                            0,
                            0,
                            2,
                            2,
                            List.of(
                                    new TableMergeProjection.GridPosition(0, 1),
                                    new TableMergeProjection.GridPosition(1, 0),
                                    new TableMergeProjection.GridPosition(1, 1))),
                    new TableMergeProjection(
                            0,
                            3,
                            2,
                            1,
                            List.of(new TableMergeProjection.GridPosition(1, 3))));
        }
    }

    @Test
    void rejectsInvalidVerticalMergeProvenanceAndGridBounds() throws IOException {
        assertTerminal("invalid-vmerge.xml", "TABLE_VERTICAL_MERGE_ANCHOR_MISSING");
        assertTerminal("span-overflow.xml", "TABLE_CELL_SPAN_OUT_OF_BOUNDS");
        assertTerminal("span-mismatch.xml", "TABLE_VERTICAL_MERGE_SPAN_MISMATCH");
    }

    @Test
    void rejectsLegacyHorizontalMergeInsteadOfInventingVisualGridFacts() throws IOException {
        assertTerminal("legacy-hmerge.xml", "UNSUPPORTED_DOCX_TABLE_STRUCTURE:hMerge");
    }

    @Test
    void rejectsRowGridOffsetsInsteadOfShiftingVisualCoordinates() throws IOException {
        assertTerminal("row-grid-before.xml", "UNSUPPORTED_DOCX_TABLE_STRUCTURE:gridBefore");
        assertTerminal("row-grid-after.xml", "UNSUPPORTED_DOCX_TABLE_STRUCTURE:gridAfter");
    }

    @Test
    void mergeProjectionRejectsMissingOrReorderedCoveredCoordinates() {
        assertThatThrownBy(() -> new TableMergeProjection(
                        0,
                        0,
                        2,
                        2,
                        List.of(
                                new TableMergeProjection.GridPosition(1, 0),
                                new TableMergeProjection.GridPosition(0, 1),
                                new TableMergeProjection.GridPosition(1, 1))))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("TABLE_MERGE_COVERAGE_INVALID");
        assertThatThrownBy(() -> new TableMergeProjection(0, 0, 2, 2, List.of()))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("TABLE_MERGE_COVERAGE_INVALID");

        TableCellCandidate horizontal = new TableCellCandidate(
                0,
                0,
                1,
                2,
                "A",
                List.of(new TableTextEvidence(0, "A", List.of())));
        TableCellCandidate overlap = new TableCellCandidate(
                0,
                1,
                1,
                1,
                "B",
                List.of(new TableTextEvidence(0, "B", List.of())));
        assertThatThrownBy(() -> new TableBlockCandidate(
                        0,
                        "word/document.xml",
                        2,
                        1,
                        2,
                        List.of(horizontal, overlap),
                        List.of(new TableMergeProjection(
                                0,
                                0,
                                1,
                                2,
                                List.of(new TableMergeProjection.GridPosition(0, 1))))))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("TABLE_CELL_GRID_OVERLAP");
    }

    private void assertTerminal(String fixture, String detail) throws IOException {
        try (SafeDocxPackage safePackage =
                TableFidelityParserTest.openFixture(temporaryDirectory, fixture)) {
            assertThatThrownBy(() -> new TableFidelityParser().parse(safePackage))
                    .isInstanceOf(SourceDomainException.class)
                    .satisfies(error -> assertThat(((SourceDomainException) error).code())
                            .isEqualTo(SourceDomainException.Code.PARSER_TERMINAL_FAILURE))
                    .hasMessageContaining(detail);
        }
    }
}
