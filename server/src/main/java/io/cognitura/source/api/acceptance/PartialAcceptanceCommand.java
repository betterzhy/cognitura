package io.cognitura.source.api.acceptance;

import java.util.regex.Pattern;

public record PartialAcceptanceCommand(
        String sourceDocumentId,
        String sourceProcessingRevisionId,
        String blockSetDigest,
        String omissionsDigest,
        String idempotencyKey,
        String decision) {

    private static final Pattern IDENTIFIER =
            Pattern.compile("[A-Za-z0-9][A-Za-z0-9._:-]{0,127}");
    private static final Pattern SHA256 = Pattern.compile("[0-9a-f]{64}");

    public PartialAcceptanceCommand {
        sourceDocumentId = identifier(sourceDocumentId, "SOURCE_DOCUMENT_ID_INVALID");
        sourceProcessingRevisionId = identifier(
                sourceProcessingRevisionId, "SOURCE_PROCESSING_REVISION_ID_INVALID");
        blockSetDigest = digest(blockSetDigest, "BLOCK_SET_DIGEST_INVALID");
        omissionsDigest = digest(omissionsDigest, "OMISSIONS_DIGEST_INVALID");
        idempotencyKey = identifier(idempotencyKey, "IDEMPOTENCY_KEY_INVALID");
        if (!"ACCEPT_PARTIAL".equals(decision)) {
            throw new IllegalArgumentException("PARTIAL_ACCEPTANCE_DECISION_INVALID");
        }
    }

    private static String identifier(String value, String code) {
        if (value == null || !IDENTIFIER.matcher(value).matches()) {
            throw new IllegalArgumentException(code);
        }
        return value;
    }

    private static String digest(String value, String code) {
        if (value == null || !SHA256.matcher(value).matches()) {
            throw new IllegalArgumentException(code);
        }
        return value;
    }
}
