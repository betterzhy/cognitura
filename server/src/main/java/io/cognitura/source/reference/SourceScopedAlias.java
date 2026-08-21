package io.cognitura.source.reference;

import io.cognitura.source.domain.SourceHash;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Objects;
import java.util.regex.Pattern;

public record SourceScopedAlias(
        Kind kind,
        String value,
        String sourceDocumentId,
        StableSourceReference blockTarget) {

    public enum Kind {
        SOURCE_DOCUMENT("sdr", "cognitura:sdr", 1),
        DOCUMENT_BLOCK("dbr", "cognitura:dbr", 3);

        private final String prefix;
        private final String domainTag;
        private final int fieldCount;

        Kind(String prefix, String domainTag, int fieldCount) {
            this.prefix = prefix;
            this.domainTag = domainTag;
            this.fieldCount = fieldCount;
        }
    }

    private static final Pattern DIGEST = Pattern.compile("[0-9a-f]{64}");

    public SourceScopedAlias {
        Objects.requireNonNull(kind, "kind");
        sourceDocumentId = StableSourceReference.requireIdentifier(
                sourceDocumentId, "SOURCE_DOCUMENT_ID");
        value = StableSourceReference.requireText(value, "REFERENCE_ALIAS_REQUIRED");
        String expectedPrefix = kind.prefix + ":";
        if (!value.startsWith(expectedPrefix)
                || !DIGEST.matcher(value.substring(expectedPrefix.length())).matches()) {
            throw new IllegalArgumentException("REFERENCE_ALIAS_FORMAT_INVALID");
        }
        if (kind == Kind.SOURCE_DOCUMENT && blockTarget != null) {
            throw new IllegalArgumentException("SOURCE_ALIAS_CANNOT_HAVE_BLOCK_TARGET");
        }
        if (kind == Kind.DOCUMENT_BLOCK) {
            Objects.requireNonNull(blockTarget, "blockTarget");
            if (!sourceDocumentId.equals(blockTarget.sourceDocumentId())) {
                throw new IllegalArgumentException("BLOCK_ALIAS_SOURCE_SCOPE_MISMATCH");
            }
        }
    }

    public static SourceScopedAlias sourceDocument(String sourceDocumentId) {
        String required = StableSourceReference.requireIdentifier(
                sourceDocumentId, "SOURCE_DOCUMENT_ID");
        return new SourceScopedAlias(
                Kind.SOURCE_DOCUMENT,
                canonicalValue(Kind.SOURCE_DOCUMENT, required, null),
                required,
                null);
    }

    public static SourceScopedAlias documentBlock(StableSourceReference target) {
        Objects.requireNonNull(target, "target");
        return new SourceScopedAlias(
                Kind.DOCUMENT_BLOCK,
                canonicalValue(Kind.DOCUMENT_BLOCK, target.sourceDocumentId(), target),
                target.sourceDocumentId(),
                target);
    }

    public static SourceScopedAlias registeredSourceDocument(
            String value, String sourceDocumentId) {
        return new SourceScopedAlias(Kind.SOURCE_DOCUMENT, value, sourceDocumentId, null);
    }

    public static SourceScopedAlias registeredDocumentBlock(
            String value, StableSourceReference target) {
        Objects.requireNonNull(target, "target");
        return new SourceScopedAlias(
                Kind.DOCUMENT_BLOCK, value, target.sourceDocumentId(), target);
    }

    public boolean isCanonical() {
        return value.equals(canonicalValue(kind, sourceDocumentId, blockTarget));
    }

    boolean sameTarget(SourceScopedAlias other) {
        return other != null
                && kind == other.kind
                && sourceDocumentId.equals(other.sourceDocumentId)
                && Objects.equals(blockTarget, other.blockTarget);
    }

    private static String canonicalValue(
            Kind kind, String sourceDocumentId, StableSourceReference blockTarget) {
        try {
            ByteArrayOutputStream bytes = new ByteArrayOutputStream();
            try (DataOutputStream output = new DataOutputStream(bytes)) {
                output.write(kind.domainTag.getBytes(StandardCharsets.UTF_8));
                output.writeByte(1);
                output.writeByte(kind.fieldCount);
                writeText(output, sourceDocumentId);
                if (kind == Kind.DOCUMENT_BLOCK) {
                    writeText(output, blockTarget.sourceProcessingRevisionId());
                    writeText(output, blockTarget.documentBlockId());
                }
            }
            return kind.prefix + ":" + SourceHash.sha256(bytes.toByteArray()).value();
        } catch (IOException error) {
            throw new IllegalStateException("REFERENCE_ALIAS_ENCODING_FAILED", error);
        }
    }

    private static void writeText(DataOutputStream output, String value) throws IOException {
        byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
        output.writeInt(bytes.length);
        output.write(bytes);
    }
}
