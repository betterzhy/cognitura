package io.cognitura.source.application.command;

import java.util.Objects;

public final class SourceCommandException extends RuntimeException {

    public enum Code {
        IDEMPOTENCY_CONFLICT,
        PERSISTENCE_FAILURE,
        RESOURCE_NOT_FOUND,
        SOURCE_NOT_ACCEPTED_YET,
        PROCESSING_COMMAND_NOT_ACCEPTED,
        DOCX_SECURITY_REJECTED,
        DOCX_FORMAT_INVALID
    }

    private final Code code;
    private final String sourceDocumentId;
    private final String sourceProcessingRevisionId;

    private SourceCommandException(
            Code code,
            String sourceDocumentId,
            String sourceProcessingRevisionId,
            Throwable cause) {
        super(Objects.requireNonNull(code, "code").name(), cause);
        this.code = code;
        this.sourceDocumentId = sourceDocumentId;
        this.sourceProcessingRevisionId = sourceProcessingRevisionId;
    }

    public static SourceCommandException idempotencyConflict() {
        return new SourceCommandException(Code.IDEMPOTENCY_CONFLICT, null, null, null);
    }

    public static SourceCommandException persistenceFailure(Throwable cause) {
        return new SourceCommandException(Code.PERSISTENCE_FAILURE, null, null, cause);
    }

    public static SourceCommandException resourceNotFound() {
        return new SourceCommandException(Code.RESOURCE_NOT_FOUND, null, null, null);
    }

    public static SourceCommandException sourceNotAccepted(String sourceDocumentId) {
        return new SourceCommandException(
                Code.SOURCE_NOT_ACCEPTED_YET,
                requireIdentity(sourceDocumentId),
                null,
                null);
    }

    public static SourceCommandException processingNotAccepted(String sourceDocumentId) {
        return new SourceCommandException(
                Code.PROCESSING_COMMAND_NOT_ACCEPTED,
                requireIdentity(sourceDocumentId),
                null,
                null);
    }

    public static SourceCommandException rejectedSource(
            String sourceDocumentId, String failureCode) {
        Code code = switch (failureCode) {
            case "DOCX_SECURITY_REJECTED" -> Code.DOCX_SECURITY_REJECTED;
            case "DOCX_FORMAT_INVALID" -> Code.DOCX_FORMAT_INVALID;
            default -> throw new IllegalArgumentException(
                    "REJECTED_SOURCE_FAILURE_CODE_INVALID");
        };
        return new SourceCommandException(code, requireIdentity(sourceDocumentId), null, null);
    }

    public Code code() {
        return code;
    }

    public String sourceDocumentId() {
        return sourceDocumentId;
    }

    public String sourceProcessingRevisionId() {
        return sourceProcessingRevisionId;
    }

    private static String requireIdentity(String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("SOURCE_COMMAND_ERROR_IDENTITY_INVALID");
        }
        return value;
    }
}
