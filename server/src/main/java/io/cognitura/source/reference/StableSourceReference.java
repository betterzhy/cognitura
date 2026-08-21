package io.cognitura.source.reference;

import java.util.regex.Pattern;

public record StableSourceReference(
        String sourceDocumentId,
        String sourceProcessingRevisionId,
        String documentBlockId) {

    private static final Pattern IDENTIFIER =
            Pattern.compile("[A-Za-z0-9][A-Za-z0-9._:-]{0,127}");

    public StableSourceReference {
        sourceDocumentId = requireIdentifier(sourceDocumentId, "SOURCE_DOCUMENT_ID");
        sourceProcessingRevisionId = requireIdentifier(
                sourceProcessingRevisionId, "PROCESSING_REVISION_ID");
        documentBlockId = requireIdentifier(documentBlockId, "DOCUMENT_BLOCK_ID");
    }

    static String requireText(String value, String errorCode) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(errorCode);
        }
        return value;
    }

    static String requireIdentifier(String value, String field) {
        if (value == null || !IDENTIFIER.matcher(value).matches()) {
            throw new IllegalArgumentException(field + "_INVALID");
        }
        return value;
    }
}
