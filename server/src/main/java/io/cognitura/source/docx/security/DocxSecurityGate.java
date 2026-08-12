package io.cognitura.source.docx.security;

import io.cognitura.source.domain.SourceDomainException;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
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
import org.xml.sax.ErrorHandler;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

public final class DocxSecurityGate {

    private static final Set<String> REQUIRED_PARTS = Set.of(
            "word/document.xml",
            "word/styles.xml",
            "word/_rels/document.xml.rels");

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
            return new SafeDocxPackage(
                    zipFile,
                    validation.partNames(),
                    validation.relationships(),
                    limits);
        } catch (DocxSecurityViolation | SourceDomainException error) {
            closeAfterFailure(zipFile);
            throw error;
        } catch (ZipException error) {
            closeAfterFailure(zipFile);
            throw formatInvalid("DOCX container is not a valid ZIP package");
        } catch (IOException error) {
            closeAfterFailure(zipFile);
            throw formatInvalid("DOCX container could not be opened or validated");
        } catch (RuntimeException error) {
            closeAfterFailure(zipFile);
            throw error;
        }
    }

    private ValidationResult validate(ZipFile zipFile) throws IOException {
        Set<String> partNames = new LinkedHashSet<>();
        Map<String, Document> relationshipDocuments = new HashMap<>();
        List<ZipEntry> verifiedEntries = new ArrayList<>();
        long declaredTotalBytes = 0;
        int entryCount = 0;

        for (ZipEntry entry : Collections.list(zipFile.entries())) {
            entryCount++;
            if (entryCount > limits.maximumEntryCount()) {
                throw limitViolation();
            }
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
            if (declaredSize < 0 || compressedSize < 0) {
                throw new DocxSecurityViolation(
                        DocxSecurityViolation.Rule.UNKNOWN_ZIP_ENTRY_SIZE,
                        "DOCX entry size metadata must be known before reading");
            }
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
            byte[] content = readBounded(zipFile, entry);
            actualTotalBytes = addWithinTotalLimit(actualTotalBytes, content.length);
            if (content.length != entry.getSize()) {
                throw limitViolation();
            }
            if (isXmlPart(entry.getName())) {
                Document document = parseSecureXml(content);
                if (entry.getName().equals("[Content_Types].xml")) {
                    rejectMacroContentType(content);
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
        return new ValidationResult(partNames, relationships);
    }

    private byte[] readBounded(ZipFile zipFile, ZipEntry entry) throws IOException {
        try (InputStream input = zipFile.getInputStream(entry)) {
            ByteArrayOutputStream output = new ByteArrayOutputStream();
            byte[] buffer = new byte[8_192];
            long total = 0;
            int count;
            while ((count = input.read(buffer)) >= 0) {
                total += count;
                if (total > limits.maximumEntryBytes()) {
                    throw limitViolation();
                }
                output.write(buffer, 0, count);
            }
            return output.toByteArray();
        }
    }

    private static Document parseSecureXml(byte[] content) {
        String ascii = new String(content, StandardCharsets.ISO_8859_1).toUpperCase(Locale.ROOT);
        if (ascii.contains("<!DOCTYPE") || ascii.contains("<!ENTITY")) {
            throw new DocxSecurityViolation(
                    DocxSecurityViolation.Rule.XML_EXTERNAL_ENTITY,
                    "DOCX XML must not declare a DOCTYPE or entity");
        }
        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
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
            return builder.parse(new ByteArrayInputStream(content));
        } catch (ParserConfigurationException error) {
            throw new IllegalStateException("SECURE_XML_PARSER_CONFIGURATION_UNAVAILABLE", error);
        } catch (SAXException | IOException error) {
            throw formatInvalid("DOCX XML part is malformed");
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

    private static void rejectMacroContentType(byte[] content) {
        String text = new String(content, StandardCharsets.UTF_8).toLowerCase(Locale.ROOT);
        if (text.contains("macroenabled") || text.contains("vbaproject")) {
            throw new DocxSecurityViolation(
                    DocxSecurityViolation.Rule.MACRO_REQUIRING_EXECUTION,
                    "DOCX XML declares macro-enabled content");
        }
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
            List<DocxRelationshipClassifier.RelationshipMetadata> relationships) {

        private ValidationResult {
            partNames = Set.copyOf(partNames);
            relationships = List.copyOf(relationships);
        }
    }
}
