package io.cognitura.source.docx.text;

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
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class TextListSectionParserTest {

    private static final String CONTENT_TYPES = resource("/docx/security/minimal-content-types.xml");
    private static final String ROOT_RELATIONSHIPS = resource("/docx/security/root-office-document.xml.rels");
    private static final String EMPTY_RELATIONSHIPS = resource("/docx/security/empty-document.xml.rels");

    @TempDir
    Path temporaryDirectory;

    @Test
    void preservesMixedHeadingParagraphListOrderSectionPathsAndListSemantics() throws IOException {
        try (SafeDocxPackage safePackage = openFixture("mixed-document.xml")) {
            List<DocumentBlockCandidate> blocks = new TextListSectionParser().parse(safePackage);

            assertThat(blocks).extracting(DocumentBlockCandidate::blockType).containsExactly(
                    DocumentBlockCandidate.BlockType.HEADING,
                    DocumentBlockCandidate.BlockType.PARAGRAPH,
                    DocumentBlockCandidate.BlockType.LIST,
                    DocumentBlockCandidate.BlockType.LIST,
                    DocumentBlockCandidate.BlockType.LIST,
                    DocumentBlockCandidate.BlockType.LIST,
                    DocumentBlockCandidate.BlockType.HEADING,
                    DocumentBlockCandidate.BlockType.PARAGRAPH,
                    DocumentBlockCandidate.BlockType.LIST,
                    DocumentBlockCandidate.BlockType.HEADING,
                    DocumentBlockCandidate.BlockType.PARAGRAPH);
            assertThat(blocks).extracting(DocumentBlockCandidate::sourceOrder)
                    .containsExactly(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
            assertThat(blocks).extracting(DocumentBlockCandidate::sourcePart)
                    .containsOnly("word/document.xml");
            assertThat(blocks).extracting(DocumentBlockCandidate::sourceElementIndex)
                    .isSorted()
                    .doesNotHaveDuplicates();

            assertHeading(blocks.get(0), "Overview", 1, List.of(), "Heading One");
            assertParagraph(blocks.get(1), "Alpha\tBeta\nGamma", List.of("Overview"), "Body Text");
            assertList(
                    blocks.get(2),
                    "First",
                    List.of("Overview"),
                    new ListSemantics("num-7-segment-0", 0, 0, "1."));
            assertList(
                    blocks.get(3),
                    "Nested",
                    List.of("Overview"),
                    new ListSemantics("num-7-segment-0", 1, 0, "•"));
            assertList(
                    blocks.get(4),
                    "Second",
                    List.of("Overview"),
                    new ListSemantics("num-7-segment-0", 0, 1, "2."));
            assertList(
                    blocks.get(5),
                    "Nested Again",
                    List.of("Overview"),
                    new ListSemantics("num-7-segment-0", 1, 1, "•"));
            assertHeading(blocks.get(6), "Details", 2, List.of("Overview"), "Heading Two");
            assertParagraph(
                    blocks.get(7),
                    "Café",
                    List.of("Overview", "Details"),
                    "Body Text");
            assertThat(Normalizer.isNormalized(blocks.get(7).text(), Normalizer.Form.NFC)).isTrue();
            assertList(
                    blocks.get(8),
                    "Resumed",
                    List.of("Overview", "Details"),
                    new ListSemantics("num-7-segment-1", 0, 0, "1."));
            assertHeading(
                    blocks.get(9),
                    "Summary",
                    1,
                    List.of("Overview", "Details"),
                    "Heading One");
            assertParagraph(blocks.get(10), "End", List.of("Summary"), null);
        }
    }

    @Test
    void rejectsUnsupportedMainFlowAndInlineNodesInsteadOfSilentlyDroppingThem() throws IOException {
        for (String fixture : List.of(
                "unsupported-table.xml", "unsupported-inline.xml", "explicit-page-break.xml")) {
            try (SafeDocxPackage safePackage = openFixture(fixture)) {
                assertThatThrownBy(() -> new TextListSectionParser().parse(safePackage))
                        .isInstanceOf(SourceDomainException.class)
                        .satisfies(error -> assertThat(((SourceDomainException) error).code())
                                .isEqualTo(SourceDomainException.Code.PARSER_TERMINAL_FAILURE))
                        .hasMessageContaining("UNSUPPORTED_DOCX_FLOW");
            }
        }
    }

    @Test
    void rejectsEmptyHeadingAndInvalidListLevel() throws IOException {
        for (String fixture : List.of("empty-heading.xml", "invalid-list-level.xml")) {
            try (SafeDocxPackage safePackage = openFixture(fixture)) {
                assertThatThrownBy(() -> new TextListSectionParser().parse(safePackage))
                        .isInstanceOf(SourceDomainException.class)
                        .satisfies(error -> assertThat(((SourceDomainException) error).code())
                                .isEqualTo(SourceDomainException.Code.PARSER_TERMINAL_FAILURE));
            }
        }
    }

    @Test
    void preservesExplicitNonContiguousHeadingLevelsWithoutInventingMissingHeadings()
            throws IOException {
        try (SafeDocxPackage safePackage = openFixture("heading-level-drift.xml")) {
            List<DocumentBlockCandidate> blocks = new TextListSectionParser().parse(safePackage);

            assertHeading(blocks.get(0), "Root", 1, List.of(), "Heading One");
            assertHeading(blocks.get(1), "Skipped level", 3, List.of("Root"), null);
            assertThat(blocks).extracting(DocumentBlockCandidate::sourceOrder).containsExactly(0, 1);
        }
    }

    private SafeDocxPackage openFixture(String documentResource) throws IOException {
        LinkedHashMap<String, byte[]> entries = new LinkedHashMap<>();
        entries.put("[Content_Types].xml", bytes(CONTENT_TYPES));
        entries.put("_rels/.rels", bytes(ROOT_RELATIONSHIPS));
        entries.put("word/document.xml", bytes(resource("/docx/text/" + documentResource)));
        entries.put("word/styles.xml", bytes(resource("/docx/text/styles.xml")));
        entries.put("word/numbering.xml", bytes(resource("/docx/text/numbering.xml")));
        entries.put("word/_rels/document.xml.rels", bytes(EMPTY_RELATIONSHIPS));
        Path packagePath = temporaryDirectory.resolve(documentResource + ".docx");
        Files.write(packagePath, zip(entries));
        return new DocxSecurityGate().open(packagePath);
    }

    private static void assertHeading(
            DocumentBlockCandidate block,
            String text,
            int level,
            List<String> sectionPath,
            String styleName) {
        assertThat(block.text()).isEqualTo(text);
        assertThat(block.headingLevel()).isEqualTo(level);
        assertThat(block.sectionPath()).containsExactlyElementsOf(sectionPath);
        assertThat(block.styleName()).isEqualTo(styleName);
        assertThat(block.listSemantics()).isNull();
    }

    private static void assertParagraph(
            DocumentBlockCandidate block,
            String text,
            List<String> sectionPath,
            String styleName) {
        assertThat(block.text()).isEqualTo(text);
        assertThat(block.headingLevel()).isNull();
        assertThat(block.sectionPath()).containsExactlyElementsOf(sectionPath);
        assertThat(block.styleName()).isEqualTo(styleName);
        assertThat(block.listSemantics()).isNull();
    }

    private static void assertList(
            DocumentBlockCandidate block,
            String text,
            List<String> sectionPath,
            ListSemantics semantics) {
        assertThat(block.text()).isEqualTo(text);
        assertThat(block.headingLevel()).isNull();
        assertThat(block.sectionPath()).containsExactlyElementsOf(sectionPath);
        assertThat(block.styleName()).isEqualTo("Body Text");
        assertThat(block.listSemantics()).isEqualTo(semantics);
    }

    private static byte[] zip(LinkedHashMap<String, byte[]> entries) throws IOException {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        try (ZipOutputStream zip = new ZipOutputStream(output, StandardCharsets.UTF_8)) {
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
        try (InputStream input = TextListSectionParserTest.class.getResourceAsStream(path)) {
            if (input == null) {
                throw new IllegalStateException("missing test resource " + path);
            }
            return new String(input.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException error) {
            throw new IllegalStateException("cannot read test resource " + path, error);
        }
    }
}
