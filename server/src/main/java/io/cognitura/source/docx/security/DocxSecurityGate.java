package io.cognitura.source.docx.security;

import io.cognitura.source.domain.SourceDomainException;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.zip.ZipEntry;
import java.util.zip.ZipException;
import java.util.zip.ZipFile;
import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.xml.sax.ErrorHandler;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

public final class DocxSecurityGate {

    private static final Set<String> REQUIRED_PARTS = Set.of(
            "[Content_Types].xml",
            "_rels/.rels",
            "word/document.xml");
    private static final String CONTENT_TYPES_NAMESPACE =
            "http://schemas.openxmlformats.org/package/2006/content-types";
    private static final String MAIN_DOCUMENT_CONTENT_TYPE =
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml";
    private static final String XINCLUDE_NAMESPACE = "http://www.w3.org/2001/XInclude";
    private static final String XML_SCHEMA_INSTANCE_NAMESPACE =
            "http://www.w3.org/2001/XMLSchema-instance";

    private final DocxPackageLimits limits;
    private final DocxRelationshipClassifier relationshipClassifier;

    public DocxSecurityGate() {
        this(DocxPackageLimits.defaults());
    }

    public DocxSecurityGate(DocxPackageLimits limits) {
        this.limits = Objects.requireNonNull(limits, "limits");
        this.relationshipClassifier = new DocxRelationshipClassifier();
    }

    public SafeDocxPackage open(Path packagePath) {
        Objects.requireNonNull(packagePath, "packagePath");
        ZipFile zipFile = null;
        try {
            zipFile = new ZipFile(packagePath.toFile());
            ValidationResult validation = validate(zipFile);
            SafeDocxPackage safePackage = new SafeDocxPackage(
                    validation.partNames(),
                    validation.relationships(),
                    validation.verifiedEntryContents());
            zipFile.close();
            zipFile = null;
            return safePackage;
        } catch (DocxSecurityViolation | SourceDomainException error) {
            closeAfterFailure(zipFile);
            throw error;
        } catch (ZipException error) {
            closeAfterFailure(zipFile);
            throw formatInvalid("DOCX container is not a valid ZIP package");
        } catch (IOException error) {
            closeAfterFailure(zipFile);
            throw retryableReadFailure();
        } catch (RuntimeException error) {
            closeAfterFailure(zipFile);
            throw error;
        }
    }

    private ValidationResult validate(ZipFile zipFile) throws IOException {
        Set<String> partNames = new LinkedHashSet<>();
        Map<String, Document> relationshipDocuments = new LinkedHashMap<>();
        Map<String, byte[]> verifiedEntryContents = new LinkedHashMap<>();
        List<ZipEntry> verifiedEntries = new ArrayList<>();
        long declaredTotalBytes = 0;
        for (ZipEntry entry : enumerateWithinEntryCount(
                zipFile.entries(), limits.maximumEntryCount())) {
            String rawName = entry.getName();
            validateRawEntryName(rawName);
            if (!partNames.add(rawName)) {
                throw new DocxSecurityViolation(
                        DocxSecurityViolation.Rule.DUPLICATE_ZIP_ENTRY_NAME,
                        "DOCX package contains a duplicate entry name");
            }
            if (entry.isDirectory()) {
                continue;
            }
            verifiedEntries.add(entry);
            rejectActiveContent(rawName);
            long declaredSize = entry.getSize();
            long compressedSize = entry.getCompressedSize();
            requireKnownEntrySizes(declaredSize, compressedSize);
            if (declaredSize > limits.maximumEntryBytes()) {
                throw limitViolation();
            }
            declaredTotalBytes = addWithinTotalLimit(declaredTotalBytes, declaredSize);
            if (declaredSize > 0
                    && (compressedSize == 0
                            || declaredSize
                                    > limits.maximumCompressionRatio()
                                            * Math.max(1L, compressedSize))) {
                throw limitViolation();
            }

        }

        if (!partNames.containsAll(REQUIRED_PARTS)) {
            throw formatInvalid("DOCX package is missing a required verified part");
        }

        long actualTotalBytes = 0;
        for (ZipEntry entry : verifiedEntries) {
            byte[] content = readBounded(
                    zipFile, entry, limits.maximumTotalBytes() - actualTotalBytes);
            actualTotalBytes = addWithinTotalLimit(actualTotalBytes, content.length);
            if (content.length != entry.getSize()) {
                throw limitViolation();
            }
            verifiedEntryContents.put(entry.getName(), content);
            if (isXmlPart(entry.getName())) {
                Document document = parseSecureXml(content);
                if (entry.getName().equals("[Content_Types].xml")) {
                    rejectActiveContentTypes(document);
                    validateContentTypes(document);
                }
                if (entry.getName().endsWith(".rels")) {
                    relationshipDocuments.put(entry.getName(), document);
                }
            }
        }

        List<DocxRelationshipClassifier.RelationshipMetadata> relationships = new ArrayList<>();
        for (Map.Entry<String, Document> relationshipDocument : relationshipDocuments.entrySet()) {
            relationships.addAll(relationshipClassifier.classify(
                    relationshipDocument.getKey(), relationshipDocument.getValue(), partNames));
        }
        boolean hasMainDocumentRelationship = relationships.stream().anyMatch(relationship ->
                relationship.sourcePart().isEmpty()
                        && relationship.mode() == DocxRelationshipClassifier.Mode.INTERNAL
                        && relationship.relationshipType().endsWith("/officeDocument")
                        && relationship.internalTargetPart().orElseThrow().equals("word/document.xml"));
        if (!hasMainDocumentRelationship) {
            throw formatInvalid("package relationships do not identify the main document part");
        }
        return new ValidationResult(partNames, relationships, verifiedEntryContents);
    }

    static List<ZipEntry> enumerateWithinEntryCount(
            Enumeration<? extends ZipEntry> enumeration, int maximumEntryCount) {
        Objects.requireNonNull(enumeration, "enumeration");
        if (maximumEntryCount <= 0) {
            throw new IllegalArgumentException("DOCX_ENTRY_COUNT_LIMIT_MUST_BE_POSITIVE");
        }
        List<ZipEntry> entries = new ArrayList<>(Math.min(maximumEntryCount, 4_096));
        while (enumeration.hasMoreElements()) {
            if (entries.size() >= maximumEntryCount) {
                throw limitViolation();
            }
            entries.add(enumeration.nextElement());
        }
        return entries;
    }

    private byte[] readBounded(ZipFile zipFile, ZipEntry entry, long remainingTotalBytes)
            throws IOException {
        try (InputStream input = zipFile.getInputStream(entry)) {
            return readWithinBudgets(input, limits.maximumEntryBytes(), remainingTotalBytes);
        }
    }

    static byte[] readWithinBudgets(
            InputStream input, long maximumEntryBytes, long remainingTotalBytes)
            throws IOException {
        Objects.requireNonNull(input, "input");
        if (maximumEntryBytes < 0 || remainingTotalBytes < 0) {
            throw new IllegalArgumentException("DOCX_STREAM_BUDGET_MUST_NOT_BE_NEGATIVE");
        }
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        byte[] buffer = new byte[8_192];
        long total = 0;
        while (true) {
            long allowed = Math.min(maximumEntryBytes, remainingTotalBytes);
            int requested = (int) Math.min(buffer.length, Math.max(1L, allowed - total + 1));
            int count = input.read(buffer, 0, requested);
            if (count < 0) {
                return output.toByteArray();
            }
            total += count;
            if (total > maximumEntryBytes || total > remainingTotalBytes) {
                throw limitViolation();
            }
            output.write(buffer, 0, count);
        }
    }

    private static Document parseSecureXml(byte[] content) {
        String inspectionText = xmlInspectionText(content).toUpperCase(Locale.ROOT);
        if (inspectionText.contains("<!DOCTYPE") || inspectionText.contains("<!ENTITY")) {
            throw new DocxSecurityViolation(
                    DocxSecurityViolation.Rule.XML_EXTERNAL_ENTITY,
                    "DOCX XML must not declare a DOCTYPE or entity");
        }
        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newDefaultInstance();
            factory.setNamespaceAware(true);
            factory.setXIncludeAware(false);
            factory.setExpandEntityReferences(false);
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
            factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            factory.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
            factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_DTD, "");
            factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_SCHEMA, "");
            var builder = factory.newDocumentBuilder();
            builder.setErrorHandler(new ErrorHandler() {
                @Override
                public void warning(SAXParseException error) throws SAXException {
                    throw error;
                }

                @Override
                public void error(SAXParseException error) throws SAXException {
                    throw error;
                }

                @Override
                public void fatalError(SAXParseException error) throws SAXException {
                    throw error;
                }
            });
            Document document = builder.parse(new ByteArrayInputStream(content));
            rejectExternalXmlReferences(document);
            return document;
        } catch (ParserConfigurationException error) {
            throw new IllegalStateException("SECURE_XML_PARSER_CONFIGURATION_UNAVAILABLE", error);
        } catch (SAXException | IOException error) {
            throw formatInvalid("DOCX XML part is malformed");
        }
    }

    private static String xmlInspectionText(byte[] content) {
        Charset charset = StandardCharsets.ISO_8859_1;
        if (startsWith(content, 0x00, 0x00, 0xfe, 0xff)
                || startsWith(content, 0x00, 0x00, 0x00, 0x3c)) {
            charset = Charset.forName("UTF-32BE");
        } else if (startsWith(content, 0xff, 0xfe, 0x00, 0x00)
                || startsWith(content, 0x3c, 0x00, 0x00, 0x00)) {
            charset = Charset.forName("UTF-32LE");
        } else if (startsWith(content, 0xfe, 0xff)
                || startsWith(content, 0x00, 0x3c, 0x00, 0x3f)) {
            charset = StandardCharsets.UTF_16BE;
        } else if (startsWith(content, 0xff, 0xfe)
                || startsWith(content, 0x3c, 0x00, 0x3f, 0x00)) {
            charset = StandardCharsets.UTF_16LE;
        } else if (startsWith(content, 0x4c, 0x6f, 0xa7, 0x94)) {
            charset = Charset.forName("Cp037");
        }
        return new String(content, charset);
    }

    private static boolean startsWith(byte[] content, int... prefix) {
        if (content.length < prefix.length) {
            return false;
        }
        for (int index = 0; index < prefix.length; index++) {
            if ((content[index] & 0xff) != prefix[index]) {
                return false;
            }
        }
        return true;
    }

    static void requireKnownEntrySizes(long declaredSize, long compressedSize) {
        if (declaredSize < 0 || compressedSize < 0) {
            throw new DocxSecurityViolation(
                    DocxSecurityViolation.Rule.UNKNOWN_ZIP_ENTRY_SIZE,
                    "DOCX entry size metadata must be known before reading");
        }
    }

    private static void rejectExternalXmlReferences(Document document) {
        var elements = document.getElementsByTagName("*");
        for (int index = 0; index < elements.getLength(); index++) {
            Element element = (Element) elements.item(index);
            if (XINCLUDE_NAMESPACE.equals(element.getNamespaceURI())) {
                throw new DocxSecurityViolation(
                        DocxSecurityViolation.Rule.XML_EXTERNAL_ENTITY,
                        "DOCX XML must not contain XInclude instructions");
            }
            if (element.hasAttributeNS(XML_SCHEMA_INSTANCE_NAMESPACE, "schemaLocation")
                    || element.hasAttributeNS(
                            XML_SCHEMA_INSTANCE_NAMESPACE, "noNamespaceSchemaLocation")) {
                throw new DocxSecurityViolation(
                        DocxSecurityViolation.Rule.XML_EXTERNAL_ENTITY,
                        "DOCX XML must not contain external schema hints");
            }
        }
    }

    private static void validateRawEntryName(String rawName) {
        if (rawName == null || rawName.isEmpty() || rawName.indexOf('\0') >= 0) {
            throw new DocxSecurityViolation(
                    DocxSecurityViolation.Rule.ABSOLUTE_ZIP_PATH,
                    "DOCX entry name is empty or contains a NUL character");
        }
        if (rawName.startsWith("/")
                || rawName.startsWith("\\")
                || rawName.matches("^[A-Za-z]:.*")) {
            throw new DocxSecurityViolation(
                    DocxSecurityViolation.Rule.ABSOLUTE_ZIP_PATH,
                    "DOCX entry name must be package-relative");
        }
        if (rawName.indexOf('\\') >= 0) {
            throw new DocxSecurityViolation(
                    DocxSecurityViolation.Rule.ZIP_PARENT_TRAVERSAL,
                    "DOCX entry name must use canonical package separators");
        }
        for (String segment : rawName.split("/", -1)) {
            if (segment.equals("..")) {
                throw new DocxSecurityViolation(
                        DocxSecurityViolation.Rule.ZIP_PARENT_TRAVERSAL,
                        "DOCX entry name must not contain a parent segment");
            }
        }
    }

    private static void rejectActiveContent(String rawName) {
        String canonical = rawName.toLowerCase(Locale.ROOT);
        if (canonical.endsWith("/vbaproject.bin") || canonical.equals("vbaproject.bin")) {
            throw new DocxSecurityViolation(
                    DocxSecurityViolation.Rule.MACRO_REQUIRING_EXECUTION,
                    "DOCX package contains macro content");
        }
        if (canonical.contains("/activex/")
                || canonical.startsWith("activex/")
                || canonical.contains("/embeddings/")
                || canonical.startsWith("embeddings/")) {
            throw new DocxSecurityViolation(
                    DocxSecurityViolation.Rule.EXECUTABLE_EMBEDDED_OBJECT,
                    "DOCX package contains active or embedded executable content");
        }
    }

    private static void rejectActiveContentTypes(Document document) {
        var elements = document.getElementsByTagName("*");
        for (int index = 0; index < elements.getLength(); index++) {
            if (!(elements.item(index) instanceof org.w3c.dom.Element element)
                    || !element.hasAttribute("ContentType")) {
                continue;
            }
            String contentType = element.getAttribute("ContentType").toLowerCase(Locale.ROOT);
            if (contentType.contains("macroenabled") || contentType.contains("vbaproject")) {
                throw new DocxSecurityViolation(
                        DocxSecurityViolation.Rule.MACRO_REQUIRING_EXECUTION,
                        "DOCX content types declare macro-enabled content");
            }
            if (contentType.contains("activex")
                    || contentType.contains("oleobject")
                    || contentType.contains("ms-office.active")) {
                throw new DocxSecurityViolation(
                        DocxSecurityViolation.Rule.EXECUTABLE_EMBEDDED_OBJECT,
                        "DOCX content types declare active or embedded content");
            }
        }
    }

    private static void validateContentTypes(Document document) {
        Element root = document.getDocumentElement();
        if (root == null
                || !"Types".equals(root.getLocalName())
                || !CONTENT_TYPES_NAMESPACE.equals(root.getNamespaceURI())) {
            throw formatInvalid("content types part root element is invalid");
        }
        var overrides = root.getElementsByTagNameNS(CONTENT_TYPES_NAMESPACE, "Override");
        for (int index = 0; index < overrides.getLength(); index++) {
            Element override = (Element) overrides.item(index);
            if ("/word/document.xml".equals(override.getAttribute("PartName"))
                    && MAIN_DOCUMENT_CONTENT_TYPE.equals(override.getAttribute("ContentType"))) {
                return;
            }
        }
        throw formatInvalid("content types part does not declare the main document part");
    }

    private static boolean isXmlPart(String name) {
        String canonical = name.toLowerCase(Locale.ROOT);
        return canonical.endsWith(".xml")
                || canonical.endsWith(".rels")
                || canonical.equals("[content_types].xml");
    }

    private long addWithinTotalLimit(long total, long addition) {
        if (addition > limits.maximumTotalBytes() - total) {
            throw limitViolation();
        }
        return total + addition;
    }

    private static DocxSecurityViolation limitViolation() {
        return new DocxSecurityViolation(
                DocxSecurityViolation.Rule.ZIP_LIMIT_EXCEEDED,
                "DOCX package exceeds a closed resource budget");
    }

    private static SourceDomainException formatInvalid(String detail) {
        return new SourceDomainException(SourceDomainException.Code.DOCX_FORMAT_INVALID, detail);
    }

    private static SourceDomainException retryableReadFailure() {
        return new SourceDomainException(
                SourceDomainException.Code.PARSER_RETRYABLE_FAILURE,
                "DOCX source could not be read due to an I/O failure");
    }

    private static void closeAfterFailure(ZipFile zipFile) {
        if (zipFile == null) {
            return;
        }
        try {
            zipFile.close();
        } catch (IOException ignored) {
            // The original deterministic validation failure remains authoritative.
        }
    }

    private record ValidationResult(
            Set<String> partNames,
            List<DocxRelationshipClassifier.RelationshipMetadata> relationships,
            Map<String, byte[]> verifiedEntryContents) {

        private ValidationResult {
            partNames = Set.copyOf(partNames);
            relationships = List.copyOf(relationships);
            verifiedEntryContents = Map.copyOf(verifiedEntryContents);
        }
    }
}
