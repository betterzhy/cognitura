package io.cognitura.source.docx.text;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.cognitura.source.docx.security.DocxSecurityGate;
import io.cognitura.source.docx.security.SafeDocxPackage;
import io.cognitura.source.domain.SourceDomainException;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
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
                    .containsExactly(2, 7, 17, 25, 33, 41, 49, 54, 59, 67, 72);

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
    void preservesInlineImagePlaceholdersAndReservesTheirGlobalSourceOrderSlots()
            throws IOException {
        try (SafeDocxPackage safePackage = openFixture("inline-images.xml")) {
            List<DocumentBlockCandidate> blocks = new TextListSectionParser().parse(safePackage);

            assertThat(blocks).extracting(DocumentBlockCandidate::sourceOrder).containsExactly(0, 3);
            assertThat(blocks.getFirst().text()).isEqualTo("😀\uFFFC\uFFFC");
            assertThat(blocks.getFirst().text().codePoints().toArray())
                    .containsExactly(0x1F600, 0xFFFC, 0xFFFC);
            assertParagraph(blocks.get(1), "After", List.of(), null);
        }
    }

    @Test
    void rejectsLiteralImagePlaceholderInsideSourceText() throws IOException {
        String literalPlaceholder = """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
                  <w:body><w:p><w:r><w:t>Before\uFFFCAfter</w:t></w:r></w:p></w:body>
                </w:document>
                """;

        try (SafeDocxPackage safePackage =
                openDocumentXml("literal-image-placeholder", literalPlaceholder)) {
            assertThatThrownBy(() -> new TextListSectionParser().parse(safePackage))
                    .isInstanceOf(SourceDomainException.class)
                    .satisfies(error -> assertThat(((SourceDomainException) error).code())
                            .isEqualTo(SourceDomainException.Code.PARSER_TERMINAL_FAILURE))
                    .hasMessageContaining("TEXT_LITERAL_IMAGE_PLACEHOLDER_FORBIDDEN");
        }
    }

    @Test
    void sourceOrderCursorRejectsInvalidReservationsAndNonIssuedBlockSequences()
            throws Exception {
        Method nextBlock = SourceOrderCursor.class.getDeclaredMethod("nextBlock");
        Method reserveChildren =
                SourceOrderCursor.class.getDeclaredMethod("reserveChildren", int.class);
        Method requireIssuedBlockOrder =
                SourceOrderCursor.class.getDeclaredMethod("requireIssuedBlockOrder", List.class);
        SourceOrderCursor cursor = new SourceOrderCursor();

        assertThat(nextBlock.invoke(cursor)).isEqualTo(0);
        assertThatThrownBy(() -> reserveChildren.invoke(cursor, -1))
                .isInstanceOf(InvocationTargetException.class)
                .hasRootCauseInstanceOf(IllegalArgumentException.class)
                .hasRootCauseMessage("SOURCE_ORDER_RESERVATION_MUST_NOT_BE_NEGATIVE");
        reserveChildren.invoke(cursor, 2);
        assertThat(nextBlock.invoke(cursor)).isEqualTo(3);

        List<DocumentBlockCandidate> issued = List.of(paragraphCandidate(0), paragraphCandidate(3));
        requireIssuedBlockOrder.invoke(cursor, issued);
        assertThatThrownBy(() -> requireIssuedBlockOrder.invoke(
                        cursor, List.of(paragraphCandidate(3), paragraphCandidate(0))))
                .isInstanceOf(InvocationTargetException.class)
                .hasRootCauseInstanceOf(IllegalArgumentException.class)
                .hasRootCauseMessage("SOURCE_ORDER_ISSUED_SEQUENCE_MISMATCH");

        SourceOrderCursor overflow = new SourceOrderCursor();
        assertThat(nextBlock.invoke(overflow)).isEqualTo(0);
        assertThatThrownBy(() -> reserveChildren.invoke(overflow, Integer.MAX_VALUE))
                .isInstanceOf(InvocationTargetException.class)
                .hasRootCauseInstanceOf(IllegalArgumentException.class)
                .hasRootCauseMessage("SOURCE_ORDER_OVERFLOW");
    }

    @Test
    void rejectsUnsupportedMainFlowAndInlineNodesInsteadOfSilentlyDroppingThem() throws IOException {
        for (String fixture : List.of(
                "unsupported-table.xml",
                "unsupported-inline.xml",
                "unsupported-text-child.xml",
                "explicit-page-break.xml",
                "explicit-page-break-before.xml",
                "styled-page-break-before.xml")) {
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

    @Test
    void appliesDeterministicNumberingStartOverrideToMarkerText() throws IOException {
        try (SafeDocxPackage safePackage =
                openFixture("list-start-override.xml", "numbering-start-override.xml")) {
            List<DocumentBlockCandidate> blocks = new TextListSectionParser().parse(safePackage);

            assertThat(blocks).hasSize(1);
            assertThat(blocks.getFirst().listSemantics())
                    .isEqualTo(new ListSemantics("num-7-segment-0", 0, 0, "5."));
        }
    }

    @Test
    void restartsDisplayMarkerAfterTheConfiguredHigherLevelWithoutResettingItemOrdinal()
            throws IOException {
        try (SafeDocxPackage safePackage =
                openFixture("list-restart.xml", "numbering-default-restart.xml")) {
            List<DocumentBlockCandidate> blocks = new TextListSectionParser().parse(safePackage);

            assertThat(blocks).hasSize(4);
            assertThat(blocks.get(1).listSemantics())
                    .isEqualTo(new ListSemantics("num-7-segment-0", 1, 0, "1.1."));
            assertThat(blocks.get(3).listSemantics())
                    .isEqualTo(new ListSemantics("num-7-segment-0", 1, 1, "2.1."));
        }
    }

    @Test
    void preservesDisplayCounterWhenLevelRestartIsExplicitlyDisabled() throws IOException {
        try (SafeDocxPackage safePackage =
                openFixture("list-restart.xml", "numbering-no-restart.xml")) {
            List<DocumentBlockCandidate> blocks = new TextListSectionParser().parse(safePackage);

            assertThat(blocks).hasSize(4);
            assertThat(blocks.get(3).listSemantics())
                    .isEqualTo(new ListSemantics("num-7-segment-0", 1, 1, "2.2."));
        }
    }

    @Test
    void rejectsUnsupportedFullLevelNumberingOverride() throws IOException {
        try (SafeDocxPackage safePackage =
                openFixture("list-start-override.xml", "numbering-full-level-override.xml")) {
            assertThatThrownBy(() -> new TextListSectionParser().parse(safePackage))
                    .isInstanceOf(SourceDomainException.class)
                    .satisfies(error -> assertThat(((SourceDomainException) error).code())
                            .isEqualTo(SourceDomainException.Code.PARSER_TERMINAL_FAILURE))
                    .hasMessageContaining("UNSUPPORTED_NUMBERING_LEVEL_OVERRIDE");
        }
    }

    @Test
    void preservesVisibleTextAcrossNonSemanticXmlMetadata() throws IOException {
        try (SafeDocxPackage safePackage = openFixture("text-metadata.xml")) {
            List<DocumentBlockCandidate> blocks = new TextListSectionParser().parse(safePackage);

            assertThat(blocks).singleElement().extracting(DocumentBlockCandidate::text).isEqualTo("AB");
        }
    }

    @Test
    void rejectsCyclicOrMissingStyleInheritance() throws IOException {
        for (String fixture : List.of("style-cycle.xml", "style-missing-base.xml")) {
            try (SafeDocxPackage safePackage = openFixture(fixture)) {
                assertThatThrownBy(() -> new TextListSectionParser().parse(safePackage))
                        .isInstanceOf(SourceDomainException.class)
                        .satisfies(error -> assertThat(((SourceDomainException) error).code())
                                .isEqualTo(SourceDomainException.Code.PARSER_TERMINAL_FAILURE))
                        .hasMessageContaining("PARAGRAPH_STYLE_");
            }
        }
    }

    @Test
    void resolvesDeepStyleInheritanceAndRejectsADeepCycleWithoutExhaustingTheThreadStack()
            throws IOException {
        int depth = 12_000;
        String documentXml = """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
                  <w:body><w:p><w:pPr><w:pStyle w:val="S00000"/></w:pPr><w:r><w:t>Deep style</w:t></w:r></w:p></w:body>
                </w:document>
                """;

        try (SafeDocxPackage safePackage =
                openDocumentAndStylesXml("deep-style-chain", documentXml, deepStyles(depth, false))) {
            assertThat(new TextListSectionParser().parse(safePackage))
                    .singleElement()
                    .extracting(DocumentBlockCandidate::headingLevel)
                    .isEqualTo(1);
        }

        try (SafeDocxPackage safePackage =
                openDocumentAndStylesXml("deep-style-cycle", documentXml, deepStyles(depth, true))) {
            assertThatThrownBy(() -> new TextListSectionParser().parse(safePackage))
                    .isInstanceOf(SourceDomainException.class)
                    .satisfies(error -> assertThat(((SourceDomainException) error).code())
                            .isEqualTo(SourceDomainException.Code.PARSER_TERMINAL_FAILURE))
                    .hasMessageContaining("PARAGRAPH_STYLE_INHERITANCE_CYCLE");
        }
    }

    @Test
    void rejectsDeepUnsupportedFlowWithoutExhaustingTheThreadStack() throws IOException {
        int depth = 12_000;
        String documentXml = """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>
                """
                + "<w:sdt>".repeat(depth)
                + "<w:p><w:r><w:t>Unsupported</w:t></w:r></w:p>"
                + "</w:sdt>".repeat(depth)
                + "</w:body></w:document>";

        try (SafeDocxPackage safePackage = openDocumentXml("deep-unsupported", documentXml)) {
            assertThatThrownBy(() -> new TextListSectionParser().parse(safePackage))
                    .isInstanceOf(SourceDomainException.class)
                    .satisfies(error -> assertThat(((SourceDomainException) error).code())
                            .isEqualTo(SourceDomainException.Code.PARSER_TERMINAL_FAILURE))
                    .hasMessageContaining("UNSUPPORTED_DOCX_FLOW:sdt");
        }
    }

    private SafeDocxPackage openFixture(String documentResource) throws IOException {
        return openFixture(documentResource, "numbering.xml");
    }

    private SafeDocxPackage openFixture(String documentResource, String numberingResource)
            throws IOException {
        return openDocumentXml(
                documentResource,
                resource("/docx/text/" + documentResource),
                numberingResource);
    }

    private SafeDocxPackage openDocumentXml(String name, String documentXml) throws IOException {
        return openDocumentXml(name, documentXml, "numbering.xml");
    }

    private SafeDocxPackage openDocumentXml(
            String name, String documentXml, String numberingResource) throws IOException {
        return openDocumentXml(
                name,
                documentXml,
                resource("/docx/text/styles.xml"),
                numberingResource);
    }

    private SafeDocxPackage openDocumentAndStylesXml(
            String name, String documentXml, String stylesXml) throws IOException {
        return openDocumentXml(name, documentXml, stylesXml, "numbering.xml");
    }

    private SafeDocxPackage openDocumentXml(
            String name, String documentXml, String stylesXml, String numberingResource)
            throws IOException {
        LinkedHashMap<String, byte[]> entries = new LinkedHashMap<>();
        entries.put("[Content_Types].xml", bytes(CONTENT_TYPES));
        entries.put("_rels/.rels", bytes(ROOT_RELATIONSHIPS));
        entries.put("word/document.xml", bytes(documentXml));
        entries.put("word/styles.xml", bytes(stylesXml));
        entries.put("word/numbering.xml", bytes(resource("/docx/text/" + numberingResource)));
        entries.put("word/_rels/document.xml.rels", bytes(EMPTY_RELATIONSHIPS));
        Path packagePath = temporaryDirectory.resolve(name + ".docx");
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

    private static DocumentBlockCandidate paragraphCandidate(int sourceOrder) {
        return new DocumentBlockCandidate(
                DocumentBlockCandidate.BlockType.PARAGRAPH,
                sourceOrder,
                List.of(),
                "word/document.xml",
                sourceOrder,
                "text",
                null,
                null,
                null);
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

    private static String deepStyles(int depth, boolean cycle) {
        StringBuilder styles = new StringBuilder(
                "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
                        + "<w:styles xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\">");
        for (int index = 0; index < depth; index++) {
            String styleId = "S%05d".formatted(index);
            styles.append("<w:style w:type=\"paragraph\" w:styleId=\"")
                    .append(styleId)
                    .append("\">");
            if (index + 1 < depth) {
                styles.append("<w:basedOn w:val=\"S")
                        .append("%05d".formatted(index + 1))
                        .append("\"/>");
            } else if (cycle) {
                styles.append("<w:basedOn w:val=\"S00000\"/>");
            } else {
                styles.append("<w:pPr><w:outlineLvl w:val=\"0\"/></w:pPr>");
            }
            styles.append("</w:style>");
        }
        return styles.append("</w:styles>").toString();
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
