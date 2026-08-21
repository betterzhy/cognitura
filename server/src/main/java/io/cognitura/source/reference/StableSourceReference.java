package io.cognitura.source.reference;

public record StableSourceReference(
        String sourceDocumentId,
        String sourceProcessingRevisionId,
        String documentBlockId) {

    public StableSourceReference {
        sourceDocumentId = requireText(sourceDocumentId, "SOURCE_DOCUMENT_ID_REQUIRED");
        sourceProcessingRevisionId = requireText(
                sourceProcessingRevisionId, "PROCESSING_REVISION_ID_REQUIRED");
        documentBlockId = requireText(documentBlockId, "DOCUMENT_BLOCK_ID_REQUIRED");
    }

    static String requireText(String value, String errorCode) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(errorCode);
        }
        return value;
    }
}
