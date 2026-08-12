package io.cognitura.source.docx.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.cognitura.source.domain.SourceDomainException;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class DocxSecurityGateTest {

    private static final String DOCUMENT = resource("minimal-document.xml");
    private static final String STYLES = resource("minimal-styles.xml");
    private static final String EMPTY_RELATIONSHIPS = resource("empty-document.xml.rels");
    private static final String CONTENT_TYPES = resource("minimal-content-types.xml");
    private static final String ROOT_RELATIONSHIPS = resource("root-office-document.xml.rels");

    @TempDir
    Path temporaryDirectory;

    @Test
    void opensOnlyVerifiedEntriesAndInvalidatesThePackageOnClose() throws IOException {
        byte[] image = "synthetic-image".getBytes(StandardCharsets.UTF_8);
        String relationships = relationships(
                relationship("rId1", imageType(), "media/image.png", null));
        Path packagePath = writeZip("safe.docx", entries(
                "[Content_Types].xml", CONTENT_TYPES.getBytes(StandardCharsets.UTF_8),
                "_rels/.rels", ROOT_RELATIONSHIPS.getBytes(StandardCharsets.UTF_8),
                "word/document.xml", DOCUMENT.getBytes(StandardCharsets.UTF_8),
                "word/styles.xml", STYLES.getBytes(StandardCharsets.UTF_8),
                "word/_rels/document.xml.rels", relationships.getBytes(StandardCharsets.UTF_8),
                "word/media/image.png", image));

        SafeDocxPackage safePackage = new DocxSecurityGate().open(packagePath);

        assertThat(safePackage.partNames()).containsExactlyInAnyOrder(
                "[Content_Types].xml",
                "_rels/.rels",
                "word/document.xml",
                "word/styles.xml",
                "word/_rels/document.xml.rels",
                "word/media/image.png");
        assertThat(new String(safePackage.readVerifiedEntry("word/document.xml"), StandardCharsets.UTF_8))
                .contains("<w:t>safe</w:t>");
        var internal = safePackage.relationships().stream()
                .filter(relationship -> relationship.relationshipId().equals("rId1"))
                .findFirst()
                .orElseThrow();
        assertThat(internal.mode()).isEqualTo(DocxRelationshipClassifier.Mode.INTERNAL);
        assertThat(internal.internalTargetPart()).contains("word/media/image.png");
        assertThat(safePackage.readRelationshipTarget(internal)).containsExactly(image);

        safePackage.close();

        assertThatThrownBy(() -> safePackage.readVerifiedEntry("word/document.xml"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("SAFE_DOCX_PACKAGE_CLOSED");
    }

    @Test
    void rejectsTraversalAbsoluteDriveAndBackslashEntryNames() throws IOException {
        for (String unsafeName : new String[] {
                "../escape.xml", "/absolute.xml", "C:/drive.xml", "word\\escape.xml"
        }) {
            Path packagePath = writeZip(
                    "unsafe-" + Math.abs(unsafeName.hashCode()) + ".docx",
                    withRequiredEntry(unsafeName, "unsafe".getBytes(StandardCharsets.UTF_8)));

            assertThatThrownBy(() -> new DocxSecurityGate().open(packagePath))
                    .isInstanceOf(DocxSecurityViolation.class)
                    .satisfies(error -> assertThat(((DocxSecurityViolation) error).code())
                            .isEqualTo(SourceDomainException.Code.DOCX_SECURITY_REJECTED));
        }
    }

    @Test
    void rejectsDuplicateEntryNamesBeforeReadingTheirContent() throws IOException {
        LinkedHashMap<String, byte[]> packageEntries = requiredEntries();
        packageEntries.put("word/a.xml", "a".getBytes(StandardCharsets.UTF_8));
        packageEntries.put("word/b.xml", "b".getBytes(StandardCharsets.UTF_8));
        byte[] distinctZip = zipBytes(packageEntries);
        byte[] duplicateZip = replaceAscii(distinctZip, "word/b.xml", "word/a.xml");
        Path packagePath = temporaryDirectory.resolve("duplicate.docx");
        Files.write(packagePath, duplicateZip);

        assertThatThrownBy(() -> new DocxSecurityGate().open(packagePath))
                .isInstanceOf(DocxSecurityViolation.class)
                .satisfies(error -> assertThat(((DocxSecurityViolation) error).rule())
                        .isEqualTo(DocxSecurityViolation.Rule.DUPLICATE_ZIP_ENTRY_NAME));
    }

    @Test
    void rejectsEntryCountEntrySizeTotalSizeAndCompressionRatioLimits() throws IOException {
        Path countLimited = writeZip(
                "count.docx",
                withRequiredEntry("word/extra.xml", "x".getBytes(StandardCharsets.UTF_8)));
        Path entryLimited = writeZip("entry.docx", requiredEntries());
        Path totalLimited = writeZip("total.docx", requiredEntries());
        byte[] compressible = new byte[2_000_000];
        Path ratioLimited = writeZip(
                "ratio.docx", withRequiredEntry("word/large.bin", compressible));

        assertLimitViolation(countLimited, new DocxPackageLimits(5, 16_777_216, 134_217_728, 200));
        assertLimitViolation(entryLimited, new DocxPackageLimits(4_096, 64, 134_217_728, 200));
        assertLimitViolation(totalLimited, new DocxPackageLimits(4_096, 300, 400, 200));
        assertLimitViolation(ratioLimited, DocxPackageLimits.defaults());
    }

    @Test
    void stopsStreamingAsSoonAsTheRemainingPackageBudgetIsExceeded() {
        CountingInputStream input = new CountingInputStream(new byte[1_024]);

        assertThatThrownBy(() -> DocxSecurityGate.readWithinBudgets(input, 1_024, 10))
                .isInstanceOf(DocxSecurityViolation.class)
                .satisfies(error -> assertThat(((DocxSecurityViolation) error).rule())
                        .isEqualTo(DocxSecurityViolation.Rule.ZIP_LIMIT_EXCEEDED));
        assertThat(input.bytesRead()).isLessThanOrEqualTo(11);
    }

    @Test
    void rejectsUnknownZipEntrySizeMetadataBeforeReadingContent() {
        assertThatThrownBy(() -> DocxSecurityGate.requireKnownEntrySizes(-1, 1))
                .isInstanceOf(DocxSecurityViolation.class)
                .satisfies(error -> assertThat(((DocxSecurityViolation) error).rule())
                        .isEqualTo(DocxSecurityViolation.Rule.UNKNOWN_ZIP_ENTRY_SIZE));
        assertThatThrownBy(() -> DocxSecurityGate.requireKnownEntrySizes(1, -1))
                .isInstanceOf(DocxSecurityViolation.class)
                .satisfies(error -> assertThat(((DocxSecurityViolation) error).rule())
                        .isEqualTo(DocxSecurityViolation.Rule.UNKNOWN_ZIP_ENTRY_SIZE));
    }

    @Test
    void rejectsDoctypeExternalEntitiesAndActiveEmbeddedContent() throws IOException {
        String xxe = """
                <?xml version="1.0"?>
                <!DOCTYPE w:document [<!ENTITY leak SYSTEM "file:///definitely-not-read">]>
                <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
                  <w:body><w:p><w:r><w:t>&leak;</w:t></w:r></w:p></w:body>
                </w:document>
                """;
        Path xxePackage = writeZip(
                "xxe.docx",
                entries(
                        "[Content_Types].xml", CONTENT_TYPES.getBytes(StandardCharsets.UTF_8),
                        "_rels/.rels", ROOT_RELATIONSHIPS.getBytes(StandardCharsets.UTF_8),
                        "word/document.xml", xxe.getBytes(StandardCharsets.UTF_8),
                        "word/styles.xml", STYLES.getBytes(StandardCharsets.UTF_8),
                        "word/_rels/document.xml.rels", EMPTY_RELATIONSHIPS.getBytes(StandardCharsets.UTF_8)));

        assertThatThrownBy(() -> new DocxSecurityGate().open(xxePackage))
                .isInstanceOf(DocxSecurityViolation.class)
                .satisfies(error -> assertThat(((DocxSecurityViolation) error).rule())
                        .isEqualTo(DocxSecurityViolation.Rule.XML_EXTERNAL_ENTITY));

        for (String activePart : new String[] {
                "word/vbaProject.bin", "word/embeddings/oleObject1.bin", "word/activeX/activeX1.bin"
        }) {
            Path activePackage = writeZip(
                    "active-" + Math.abs(activePart.hashCode()) + ".docx",
                    withRequiredEntry(activePart, new byte[] {1}));

            assertThatThrownBy(() -> new DocxSecurityGate().open(activePackage))
                    .isInstanceOf(DocxSecurityViolation.class)
                    .satisfies(error -> assertThat(((DocxSecurityViolation) error).code())
                            .isEqualTo(SourceDomainException.Code.DOCX_SECURITY_REJECTED));
        }

        Path macroContentType = writeZip(
                "macro-content-type.docx",
                withRequiredEntry(
                        "[Content_Types].xml",
                        "<Types><Override ContentType=\"application/vnd.ms-word.document.macro&#69;nabled.main+xml\"/></Types>"
                                .getBytes(StandardCharsets.UTF_8)));
        assertThatThrownBy(() -> new DocxSecurityGate().open(macroContentType))
                .isInstanceOf(DocxSecurityViolation.class)
                .satisfies(error -> assertThat(((DocxSecurityViolation) error).rule())
                        .isEqualTo(DocxSecurityViolation.Rule.MACRO_REQUIRING_EXECUTION));
    }

    @Test
    void rejectsExternalDtdXIncludeAndExternalSchemaHints() throws IOException {
        String externalDtd = """
                <?xml version="1.0"?>
                <!DOCTYPE w:document SYSTEM "file:///definitely-not-read.dtd">
                <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
                  <w:body/>
                </w:document>
                """;
        String xInclude = """
                <?xml version="1.0"?>
                <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
                            xmlns:xi="http://www.w3.org/2001/XInclude">
                  <w:body><xi:include href="file:///definitely-not-read.xml" parse="xml"/></w:body>
                </w:document>
                """;
        String externalSchema = """
                <?xml version="1.0"?>
                <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
                            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                            xsi:schemaLocation="urn:test https://w1-i03-canary.invalid/schema.xsd">
                  <w:body/>
                </w:document>
                """;
        Map<String, String> maliciousXml = Map.of(
                "external-dtd", externalDtd,
                "xinclude", xInclude,
                "external-schema", externalSchema);

        for (Map.Entry<String, String> fixture : maliciousXml.entrySet()) {
            Path packagePath = writeZip(
                    fixture.getKey() + ".docx",
                    entries(
                            "[Content_Types].xml", CONTENT_TYPES.getBytes(StandardCharsets.UTF_8),
                            "_rels/.rels", ROOT_RELATIONSHIPS.getBytes(StandardCharsets.UTF_8),
                            "word/document.xml", fixture.getValue().getBytes(StandardCharsets.UTF_8)));

            assertThatThrownBy(() -> new DocxSecurityGate().open(packagePath))
                    .isInstanceOf(DocxSecurityViolation.class)
                    .satisfies(error -> assertThat(((DocxSecurityViolation) error).rule())
                            .isEqualTo(DocxSecurityViolation.Rule.XML_EXTERNAL_ENTITY));
        }
    }

    @Test
    void rejectsActiveRelationshipTypesBehindOrdinaryPackagePaths() throws IOException {
        Map<String, DocxSecurityViolation.Rule> activeTypes = Map.of(
                "oleObject", DocxSecurityViolation.Rule.EXECUTABLE_EMBEDDED_OBJECT,
                "control", DocxSecurityViolation.Rule.EXECUTABLE_EMBEDDED_OBJECT,
                "vbaProject", DocxSecurityViolation.Rule.MACRO_REQUIRING_EXECUTION);
        for (Map.Entry<String, DocxSecurityViolation.Rule> activeType : activeTypes.entrySet()) {
            String relationships = relationships(relationship(
                    "rActive",
                    "http://schemas.openxmlformats.org/officeDocument/2006/relationships/"
                            + activeType.getKey(),
                    "media/payload.bin",
                    null));
            LinkedHashMap<String, byte[]> packageEntries = entries(
                    "[Content_Types].xml", CONTENT_TYPES.getBytes(StandardCharsets.UTF_8),
                    "_rels/.rels", ROOT_RELATIONSHIPS.getBytes(StandardCharsets.UTF_8),
                    "word/document.xml", DOCUMENT.getBytes(StandardCharsets.UTF_8),
                    "word/styles.xml", STYLES.getBytes(StandardCharsets.UTF_8),
                    "word/_rels/document.xml.rels", relationships.getBytes(StandardCharsets.UTF_8),
                    "word/media/payload.bin", new byte[] {1, 2, 3});
            Path packagePath = writeZip(activeType.getKey() + ".docx", packageEntries);

            assertThatThrownBy(() -> new DocxSecurityGate().open(packagePath))
                    .isInstanceOf(DocxSecurityViolation.class)
                    .satisfies(error -> assertThat(((DocxSecurityViolation) error).rule())
                            .isEqualTo(activeType.getValue()));
        }
    }

    @Test
    void acceptsOrdinaryDocumentTextThatNamesMacroTechnologies() throws IOException {
        String educationalText = DOCUMENT.replace(
                "<w:t>safe</w:t>",
                "<w:t>macroEnabled and vbaProject are security terms</w:t>");
        Path packagePath = writeZip(
                "security-education.docx",
                entries(
                        "[Content_Types].xml", CONTENT_TYPES.getBytes(StandardCharsets.UTF_8),
                        "_rels/.rels", ROOT_RELATIONSHIPS.getBytes(StandardCharsets.UTF_8),
                        "word/document.xml", educationalText.getBytes(StandardCharsets.UTF_8),
                        "word/styles.xml", STYLES.getBytes(StandardCharsets.UTF_8),
                        "word/_rels/document.xml.rels", EMPTY_RELATIONSHIPS.getBytes(StandardCharsets.UTF_8)));

        try (SafeDocxPackage safePackage = new DocxSecurityGate().open(packagePath)) {
            assertThat(safePackage.partNames()).contains("word/document.xml");
        }
    }

    @Test
    void acceptsExplicitInternalRelationshipMode() throws IOException {
        byte[] image = "explicit-internal".getBytes(StandardCharsets.UTF_8);
        String relationshipXml = relationships(
                relationship("rExplicit", imageType(), "media/image.png", "Internal"));
        Path packagePath = writeZip(
                "explicit-internal.docx",
                entries(
                        "[Content_Types].xml", CONTENT_TYPES.getBytes(StandardCharsets.UTF_8),
                        "_rels/.rels", ROOT_RELATIONSHIPS.getBytes(StandardCharsets.UTF_8),
                        "word/document.xml", DOCUMENT.getBytes(StandardCharsets.UTF_8),
                        "word/_rels/document.xml.rels", relationshipXml.getBytes(StandardCharsets.UTF_8),
                        "word/media/image.png", image));

        try (SafeDocxPackage safePackage = new DocxSecurityGate().open(packagePath)) {
            var relationship = safePackage.relationships().stream()
                    .filter(candidate -> candidate.relationshipId().equals("rExplicit"))
                    .findFirst()
                    .orElseThrow();
            assertThat(relationship.mode()).isEqualTo(DocxRelationshipClassifier.Mode.INTERNAL);
            assertThat(safePackage.readRelationshipTarget(relationship)).containsExactly(image);
        }
    }

    @Test
    void classifiesUnavailableSourceReadAsRetryable() {
        Path unavailableSource = temporaryDirectory.resolve("source-no-longer-available.docx");

        assertThatThrownBy(() -> new DocxSecurityGate().open(unavailableSource))
                .isInstanceOf(SourceDomainException.class)
                .satisfies(error -> {
                    SourceDomainException failure = (SourceDomainException) error;
                    assertThat(failure.code())
                            .isEqualTo(SourceDomainException.Code.PARSER_RETRYABLE_FAILURE);
                    assertThat(failure.retryable()).isTrue();
                });
    }

    @Test
    void classifiesMissingPartsMalformedXmlAndUnknownRelationshipModeAsFormatInvalid()
            throws IOException {
        LinkedHashMap<String, byte[]> missingEntries = requiredEntries();
        missingEntries.remove("[Content_Types].xml");
        Path missing = writeZip("missing.docx", missingEntries);
        Path malformed = writeZip(
                "malformed.docx",
                entries(
                        "[Content_Types].xml", CONTENT_TYPES.getBytes(StandardCharsets.UTF_8),
                        "_rels/.rels", ROOT_RELATIONSHIPS.getBytes(StandardCharsets.UTF_8),
                        "word/document.xml", "<broken>".getBytes(StandardCharsets.UTF_8),
                        "word/styles.xml", STYLES.getBytes(StandardCharsets.UTF_8),
                        "word/_rels/document.xml.rels", EMPTY_RELATIONSHIPS.getBytes(StandardCharsets.UTF_8)));
        Path unknownMode = writeZip(
                "unknown-mode.docx",
                entries(
                        "[Content_Types].xml", CONTENT_TYPES.getBytes(StandardCharsets.UTF_8),
                        "_rels/.rels", ROOT_RELATIONSHIPS.getBytes(StandardCharsets.UTF_8),
                        "word/document.xml", DOCUMENT.getBytes(StandardCharsets.UTF_8),
                        "word/styles.xml", STYLES.getBytes(StandardCharsets.UTF_8),
                        "word/_rels/document.xml.rels",
                        relationships(relationship("rId1", imageType(), "media/image.png", "Sideways"))
                                .getBytes(StandardCharsets.UTF_8)));

        assertFormatInvalid(missing);
        assertFormatInvalid(malformed);
        assertFormatInvalid(unknownMode);
    }

    @Test
    void requiresPackageMetadataButAllowsOptionalStylesAndDocumentRelationships()
            throws IOException {
        LinkedHashMap<String, byte[]> minimalEntries = entries(
                "[Content_Types].xml", CONTENT_TYPES.getBytes(StandardCharsets.UTF_8),
                "_rels/.rels", ROOT_RELATIONSHIPS.getBytes(StandardCharsets.UTF_8),
                "word/document.xml", DOCUMENT.getBytes(StandardCharsets.UTF_8));
        Path minimal = writeZip("minimal-package.docx", minimalEntries);
        LinkedHashMap<String, byte[]> missingRootEntries = new LinkedHashMap<>(minimalEntries);
        missingRootEntries.remove("_rels/.rels");
        Path missingRoot = writeZip("missing-root-rels.docx", missingRootEntries);

        try (SafeDocxPackage safePackage = new DocxSecurityGate().open(minimal)) {
            assertThat(safePackage.partNames()).containsExactlyInAnyOrder(
                    "[Content_Types].xml", "_rels/.rels", "word/document.xml");
        }
        assertFormatInvalid(missingRoot);
    }

    @Test
    void rejectsUnknownRelationshipXmlStructureAsFormatInvalid() throws IOException {
        Path unknownStructure = writeZip(
                "unknown-relationship-structure.docx",
                entries(
                        "[Content_Types].xml", CONTENT_TYPES.getBytes(StandardCharsets.UTF_8),
                        "_rels/.rels", ROOT_RELATIONSHIPS.getBytes(StandardCharsets.UTF_8),
                        "word/document.xml", DOCUMENT.getBytes(StandardCharsets.UTF_8),
                        "word/styles.xml", STYLES.getBytes(StandardCharsets.UTF_8),
                        "word/_rels/document.xml.rels",
                        """
                        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                          <Unknown Id="rId1" Type="urn:unknown" Target="elsewhere"/>
                        </Relationships>
                        """.getBytes(StandardCharsets.UTF_8)));

        assertFormatInvalid(unknownStructure);
    }

    @Test
    void rejectsMalformedXmlWithoutWritingParserDiagnosticsToStderr() throws IOException {
        Path malformed = writeZip(
                "quiet-malformed.docx",
                entries(
                        "[Content_Types].xml", CONTENT_TYPES.getBytes(StandardCharsets.UTF_8),
                        "_rels/.rels", ROOT_RELATIONSHIPS.getBytes(StandardCharsets.UTF_8),
                        "word/document.xml", "<broken>".getBytes(StandardCharsets.UTF_8),
                        "word/styles.xml", STYLES.getBytes(StandardCharsets.UTF_8),
                        "word/_rels/document.xml.rels", EMPTY_RELATIONSHIPS.getBytes(StandardCharsets.UTF_8)));
        ByteArrayOutputStream diagnostics = new ByteArrayOutputStream();
        PrintStream originalError = System.err;
        try {
            System.setErr(new PrintStream(diagnostics, true, StandardCharsets.UTF_8));
            assertFormatInvalid(malformed);
        } finally {
            System.setErr(originalError);
        }

        assertThat(diagnostics.toString(StandardCharsets.UTF_8)).isEmpty();
    }

    private void assertLimitViolation(Path packagePath, DocxPackageLimits limits) {
        assertThatThrownBy(() -> new DocxSecurityGate(limits).open(packagePath))
                .isInstanceOf(DocxSecurityViolation.class)
                .satisfies(error -> assertThat(((DocxSecurityViolation) error).rule())
                        .isEqualTo(DocxSecurityViolation.Rule.ZIP_LIMIT_EXCEEDED));
    }

    private void assertFormatInvalid(Path packagePath) {
        assertThatThrownBy(() -> new DocxSecurityGate().open(packagePath))
                .isInstanceOf(SourceDomainException.class)
                .satisfies(error -> {
                    SourceDomainException failure = (SourceDomainException) error;
                    assertThat(failure.code()).isEqualTo(SourceDomainException.Code.DOCX_FORMAT_INVALID);
                    assertThat(failure.retryable()).isFalse();
                });
    }

    private LinkedHashMap<String, byte[]> requiredEntries() {
        return entries(
                "[Content_Types].xml", CONTENT_TYPES.getBytes(StandardCharsets.UTF_8),
                "_rels/.rels", ROOT_RELATIONSHIPS.getBytes(StandardCharsets.UTF_8),
                "word/document.xml", DOCUMENT.getBytes(StandardCharsets.UTF_8),
                "word/styles.xml", STYLES.getBytes(StandardCharsets.UTF_8),
                "word/_rels/document.xml.rels", EMPTY_RELATIONSHIPS.getBytes(StandardCharsets.UTF_8));
    }

    private LinkedHashMap<String, byte[]> withRequiredEntry(String name, byte[] content) {
        LinkedHashMap<String, byte[]> packageEntries = requiredEntries();
        packageEntries.put(name, content);
        return packageEntries;
    }

    private Path writeZip(String fileName, LinkedHashMap<String, byte[]> packageEntries)
            throws IOException {
        Path path = temporaryDirectory.resolve(fileName);
        Files.write(path, zipBytes(packageEntries));
        return path;
    }

    static LinkedHashMap<String, byte[]> entries(Object... values) {
        LinkedHashMap<String, byte[]> result = new LinkedHashMap<>();
        for (int index = 0; index < values.length; index += 2) {
            result.put((String) values[index], (byte[]) values[index + 1]);
        }
        return result;
    }

    static byte[] zipBytes(LinkedHashMap<String, byte[]> packageEntries) throws IOException {
        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        try (ZipOutputStream zip = new ZipOutputStream(bytes)) {
            for (Map.Entry<String, byte[]> entry : packageEntries.entrySet()) {
                zip.putNextEntry(new ZipEntry(entry.getKey()));
                zip.write(entry.getValue());
                zip.closeEntry();
            }
        }
        return bytes.toByteArray();
    }

    private static byte[] replaceAscii(byte[] source, String oldValue, String newValue) {
        byte[] oldBytes = oldValue.getBytes(StandardCharsets.US_ASCII);
        byte[] newBytes = newValue.getBytes(StandardCharsets.US_ASCII);
        assertThat(newBytes).hasSameSizeAs(oldBytes);
        byte[] result = source.clone();
        for (int offset = 0; offset <= result.length - oldBytes.length; offset++) {
            boolean match = true;
            for (int index = 0; index < oldBytes.length; index++) {
                if (result[offset + index] != oldBytes[index]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                System.arraycopy(newBytes, 0, result, offset, newBytes.length);
                offset += newBytes.length - 1;
            }
        }
        return result;
    }

    static String relationships(String... relationships) {
        return """
                <?xml version="1.0" encoding="UTF-8"?>
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                """ + String.join("\n", relationships) + "</Relationships>";
    }

    static String relationship(String id, String type, String target, String targetMode) {
        String mode = targetMode == null ? "" : " TargetMode=\"" + targetMode + "\"";
        return "<Relationship Id=\"" + id + "\" Type=\"" + type + "\" Target=\""
                + target + "\"" + mode + "/>";
    }

    static String imageType() {
        return "http://schemas.openxmlformats.org/officeDocument/2006/relationships/image";
    }

    private static String resource(String name) {
        try (InputStream input = DocxSecurityGateTest.class.getResourceAsStream(
                "/docx/security/" + name)) {
            if (input == null) {
                throw new IllegalStateException("MISSING_TEST_RESOURCE:" + name);
            }
            return new String(input.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException error) {
            throw new IllegalStateException("FAILED_TO_READ_TEST_RESOURCE:" + name, error);
        }
    }

    private static final class CountingInputStream extends InputStream {
        private final byte[] bytes;
        private int position;

        private CountingInputStream(byte[] bytes) {
            this.bytes = bytes.clone();
        }

        int bytesRead() {
            return position;
        }

        @Override
        public int read() {
            return position < bytes.length ? bytes[position++] & 0xff : -1;
        }

        @Override
        public int read(byte[] target, int offset, int length) {
            if (position >= bytes.length) {
                return -1;
            }
            int count = Math.min(length, bytes.length - position);
            System.arraycopy(bytes, position, target, offset, count);
            position += count;
            return count;
        }
    }
}
