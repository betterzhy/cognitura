package io.cognitura.source.docx.table;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.cognitura.source.docx.security.DocxSecurityGate;
import io.cognitura.source.docx.security.SafeDocxPackage;
import io.cognitura.source.domain.SourceDomainException;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.text.Normalizer;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.zip.Deflater;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class TableFidelityParserTest {

    private static final String CONTENT_TYPES = resource("/docx/security/minimal-content-types.xml");
    private static final String ROOT_RELATIONSHIPS =
            resource("/docx/security/root-office-document.xml.rels");
    private static final String EMPTY_RELATIONSHIPS =
            resource("/docx/security/empty-document.xml.rels");

    @TempDir
    Path temporaryDirectory;

    @Test
    void preservesGridEmptyCellsParagraphTextAndInlineImageAnchorOrder() throws IOException {
        try (SafeDocxPackage safePackage = openFixture(temporaryDirectory, "regular-table.xml")) {
            List<TableBlockCandidate> tables = new TableFidelityParser().parse(safePackage);

            assertThat(tables).singleElement().satisfies(table -> {
                assertThat(table.sourceOrder()).isEqualTo(1);
                assertThat(table.sourcePart()).isEqualTo("word/document.xml");
                assertThat(table.sourceElementIndex()).isEqualTo(5);
                assertThat(table.rowCount()).isEqualTo(2);
                assertThat(table.columnCount()).isEqualTo(3);
                assertThat(table.cells())
                        .extracting(
                                TableCellCandidate::rowIndex,
                                TableCellCandidate::columnIndex,
                                TableCellCandidate::rowSpan,
                                TableCellCandidate::columnSpan,
                                TableCellCandidate::text)
                        .containsExactly(
                                org.assertj.core.groups.Tuple.tuple(0, 0, 1, 1, "Rule"),
                                org.assertj.core.groups.Tuple.tuple(
                                        0, 1, 1, 1, "Condition\tA\nResult\nLine"),
                                org.assertj.core.groups.Tuple.tuple(0, 2, 1, 1, ""),
                                org.assertj.core.groups.Tuple.tuple(1, 0, 1, 1, "Café"),
                                org.assertj.core.groups.Tuple.tuple(1, 1, 1, 1, "Café\uFFFCB"),
                                org.assertj.core.groups.Tuple.tuple(1, 2, 1, 1, "End"));
                assertThat(table.merges()).isEmpty();

                TableCellCandidate multiParagraph = table.cells().get(1);
                assertThat(multiParagraph.textEvidence())
                        .extracting(TableTextEvidence::paragraphIndex, TableTextEvidence::text)
                        .containsExactly(
                                org.assertj.core.groups.Tuple.tuple(0, "Condition\tA"),
                                org.assertj.core.groups.Tuple.tuple(1, "Result\nLine"));
                assertThat(multiParagraph.textEvidence())
                        .allSatisfy(evidence -> assertThat(evidence.inlineImageOffsets()).isEmpty());

                TableCellCandidate imageAnchor = table.cells().get(4);
                assertThat(imageAnchor.textEvidence()).singleElement().satisfies(evidence -> {
                    assertThat(evidence.text()).isEqualTo("Café\uFFFCB");
                    assertThat(evidence.inlineImageOffsets()).containsExactly(4);
                });
                assertThat(Normalizer.isNormalized(
                                table.cells().get(3).text(), Normalizer.Form.NFC))
                        .isTrue();
            });
        }
    }

    @Test
    void rejectsMissingCellsAndNestedTablesInsteadOfInventingOrFlatteningContent()
            throws IOException {
        assertTerminal("missing-cell.xml", "TABLE_ROW_DOES_NOT_FILL_GRID");
        assertTerminal("nested-table.xml", "UNSUPPORTED_DOCX_TABLE_FLOW:nested-table");
        assertTerminal(
                "literal-image-placeholder.xml", "TABLE_LITERAL_IMAGE_PLACEHOLDER_FORBIDDEN");
    }

    @Test
    void preservesGlobalContainerOrderAndUsesCodePointImageOffsets() throws IOException {
        try (SafeDocxPackage safePackage =
                openFixture(temporaryDirectory, "image-source-order.xml")) {
            List<TableBlockCandidate> tables = new TableFidelityParser().parse(safePackage);

            assertThat(tables).extracting(TableBlockCandidate::sourceOrder).containsExactly(2, 4);
            assertThat(tables.getFirst().cells().getFirst().textEvidence())
                    .singleElement()
                    .satisfies(evidence -> {
                        assertThat(evidence.text()).isEqualTo("😀￼");
                        assertThat(evidence.inlineImageOffsets()).containsExactly(1);
                    });
        }
    }

    @Test
    void candidateRecordsRejectReorderedCellsAndNonNormalizedText() {
        TableCellCandidate first = new TableCellCandidate(
                0, 0, 1, 1, "A", List.of(new TableTextEvidence(0, "A", List.of())));
        TableCellCandidate second = new TableCellCandidate(
                0, 1, 1, 1, "B", List.of(new TableTextEvidence(0, "B", List.of())));

        assertThatThrownBy(() -> new TableBlockCandidate(
                        0,
                        "word/document.xml",
                        2,
                        1,
                        2,
                        List.of(second, first),
                        List.of()))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("TABLE_CELL_ORDER_INVALID");
        assertThatThrownBy(() -> new TableCellCandidate(
                        0,
                        0,
                        1,
                        1,
                        "Cafe\u0301",
                        List.of(new TableTextEvidence(0, "Café", List.of()))))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("TABLE_CELL_TEXT_MUST_BE_NFC");

        assertThatThrownBy(() -> new TableTextEvidence(0, "￼", List.of()))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("TABLE_IMAGE_ANCHOR_BIJECTION_INVALID");
        assertThat(new TableTextEvidence(0, "😀￼", List.of(1)).inlineImageOffsets())
                .containsExactly(1);
    }

    private void assertTerminal(String fixture, String detail) throws IOException {
        try (SafeDocxPackage safePackage = openFixture(temporaryDirectory, fixture)) {
            assertThatThrownBy(() -> new TableFidelityParser().parse(safePackage))
                    .isInstanceOf(SourceDomainException.class)
                    .satisfies(error -> assertThat(((SourceDomainException) error).code())
                            .isEqualTo(SourceDomainException.Code.PARSER_TERMINAL_FAILURE))
                    .hasMessageContaining(detail);
        }
    }

    static SafeDocxPackage openFixture(Path temporaryDirectory, String documentResource)
            throws IOException {
        LinkedHashMap<String, byte[]> entries = new LinkedHashMap<>();
        entries.put("[Content_Types].xml", bytes(CONTENT_TYPES));
        entries.put("_rels/.rels", bytes(ROOT_RELATIONSHIPS));
        entries.put(
                "word/document.xml",
                bytes(resource("/docx/table/" + documentResource)));
        entries.put("word/_rels/document.xml.rels", bytes(EMPTY_RELATIONSHIPS));
        Path packagePath = temporaryDirectory.resolve(documentResource.replace(".xml", ".docx"));
        Files.write(packagePath, zip(entries));
        return new DocxSecurityGate().open(packagePath);
    }

    private static byte[] zip(LinkedHashMap<String, byte[]> entries) throws IOException {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        try (ZipOutputStream zip = new ZipOutputStream(output, StandardCharsets.UTF_8)) {
            zip.setLevel(Deflater.NO_COMPRESSION);
            for (Map.Entry<String, byte[]> entry : entries.entrySet()) {
                zip.putNextEntry(new ZipEntry(entry.getKey()));
                zip.write(entry.getValue());
                zip.closeEntry();
            }
        }
        return output.toByteArray();
    }

    private static byte[] bytes(String value) {
        return value.getBytes(StandardCharsets.UTF_8);
    }

    private static String resource(String path) {
        try (InputStream input = TableFidelityParserTest.class.getResourceAsStream(path)) {
            if (input == null) {
                throw new IllegalStateException("missing test resource " + path);
            }
            return new String(input.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException error) {
            throw new IllegalStateException("cannot read test resource " + path, error);
        }
    }
}
