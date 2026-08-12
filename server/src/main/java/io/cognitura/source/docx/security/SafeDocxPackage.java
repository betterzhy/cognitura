package io.cognitura.source.docx.security;

import io.cognitura.source.domain.SourceDomainException;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

public final class SafeDocxPackage implements AutoCloseable {

    private final ZipFile zipFile;
    private final Set<String> partNames;
    private final List<DocxRelationshipClassifier.RelationshipMetadata> relationships;
    private final DocxPackageLimits limits;
    private boolean closed;

    SafeDocxPackage(
            ZipFile zipFile,
            Set<String> partNames,
            List<DocxRelationshipClassifier.RelationshipMetadata> relationships,
            DocxPackageLimits limits) {
        this.zipFile = Objects.requireNonNull(zipFile, "zipFile");
        this.partNames = Set.copyOf(partNames);
        this.relationships = List.copyOf(relationships);
        this.limits = Objects.requireNonNull(limits, "limits");
    }

    public Set<String> partNames() {
        requireOpen();
        return partNames;
    }

    public List<DocxRelationshipClassifier.RelationshipMetadata> relationships() {
        requireOpen();
        return relationships;
    }

    public byte[] readVerifiedEntry(String partName) {
        requireOpen();
        if (!partNames.contains(partName)) {
            throw new IllegalArgumentException("DOCX_PART_IS_NOT_VERIFIED");
        }
        ZipEntry entry = zipFile.getEntry(partName);
        if (entry == null || entry.isDirectory()) {
            throw new IllegalArgumentException("DOCX_VERIFIED_FILE_PART_REQUIRED");
        }
        try (InputStream input = zipFile.getInputStream(entry)) {
            return readBounded(input, limits.maximumEntryBytes());
        } catch (IOException error) {
            throw new SourceDomainException(
                    SourceDomainException.Code.PARSER_RETRYABLE_FAILURE,
                    "verified DOCX part could not be read");
        }
    }

    public byte[] readRelationshipTarget(
            DocxRelationshipClassifier.RelationshipMetadata relationship) {
        requireOpen();
        Objects.requireNonNull(relationship, "relationship");
        if (!relationships.contains(relationship)) {
            throw new IllegalArgumentException("RELATIONSHIP_IS_NOT_FROM_THIS_PACKAGE");
        }
        if (relationship.mode() == DocxRelationshipClassifier.Mode.EXTERNAL) {
            throw new DocxSecurityViolation(
                    DocxSecurityViolation.Rule.EXTERNAL_RELATIONSHIP_DEREFERENCE_REQUEST,
                    "external relationship targets must never be dereferenced");
        }
        return readVerifiedEntry(relationship.internalTargetPart().orElseThrow());
    }

    @Override
    public void close() {
        if (closed) {
            return;
        }
        closed = true;
        try {
            zipFile.close();
        } catch (IOException error) {
            throw new SourceDomainException(
                    SourceDomainException.Code.PARSER_RETRYABLE_FAILURE,
                    "verified DOCX package could not be closed");
        }
    }

    private void requireOpen() {
        if (closed) {
            throw new IllegalStateException("SAFE_DOCX_PACKAGE_CLOSED");
        }
    }

    private static byte[] readBounded(InputStream input, long maximumBytes) throws IOException {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        byte[] buffer = new byte[8_192];
        long total = 0;
        int count;
        while ((count = input.read(buffer)) >= 0) {
            total += count;
            if (total > maximumBytes) {
                throw new DocxSecurityViolation(
                        DocxSecurityViolation.Rule.ZIP_LIMIT_EXCEEDED,
                        "actual uncompressed DOCX part exceeds its verified limit");
            }
            output.write(buffer, 0, count);
        }
        return output.toByteArray();
    }
}
