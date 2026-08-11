package io.cognitura.source.domain;

import java.time.Instant;
import java.util.Objects;

public record SourceDocument(
        String sourceDocumentId,
        String workspaceId,
        String sourceBinaryId,
        String originalFileName,
        String mediaType,
        long byteLength,
        SourceHash contentSha256,
        Instant receivedAt,
        String idempotencyKey,
        ValidationStatus validationStatus,
        SourceDomainException.Code failureCode,
        String failureDetail) {

    public enum ValidationStatus {
        RECEIVED,
        VALIDATING,
        ACCEPTED,
        REJECTED
    }

    public SourceDocument {
        sourceDocumentId = requireText(sourceDocumentId, "SOURCE_DOCUMENT_ID_REQUIRED");
        workspaceId = requireText(workspaceId, "WORKSPACE_ID_REQUIRED");
        sourceBinaryId = requireText(sourceBinaryId, "SOURCE_BINARY_ID_REQUIRED");
        originalFileName = requireText(originalFileName, "ORIGINAL_FILE_NAME_REQUIRED");
        mediaType = requireText(mediaType, "SOURCE_DOCUMENT_MEDIA_TYPE_REQUIRED");
        if (byteLength <= 0) {
            throw new IllegalArgumentException("SOURCE_DOCUMENT_BYTE_LENGTH_MUST_BE_POSITIVE");
        }
        Objects.requireNonNull(contentSha256, "contentSha256");
        Objects.requireNonNull(receivedAt, "receivedAt");
        idempotencyKey = requireText(idempotencyKey, "IDEMPOTENCY_KEY_REQUIRED");
        Objects.requireNonNull(validationStatus, "validationStatus");
        validateFailure(validationStatus, failureCode, failureDetail);
    }

    public static SourceDocument received(
            String sourceDocumentId,
            String workspaceId,
            String sourceBinaryId,
            String originalFileName,
            String mediaType,
            long byteLength,
            SourceHash contentSha256,
            Instant receivedAt,
            String idempotencyKey) {
        return new SourceDocument(
                sourceDocumentId,
                workspaceId,
                sourceBinaryId,
                originalFileName,
                mediaType,
                byteLength,
                contentSha256,
                receivedAt,
                idempotencyKey,
                ValidationStatus.RECEIVED,
                null,
                null);
    }

    public SourceDocument beginValidation() {
        requireStatus(ValidationStatus.RECEIVED, ValidationStatus.VALIDATING);
        return withStatus(ValidationStatus.VALIDATING, null, null);
    }

    public SourceDocument accept() {
        requireStatus(ValidationStatus.VALIDATING, ValidationStatus.ACCEPTED);
        return withStatus(ValidationStatus.ACCEPTED, null, null);
    }

    public SourceDocument reject(SourceDomainException.Code code, String detail) {
        requireStatus(ValidationStatus.VALIDATING, ValidationStatus.REJECTED);
        return withStatus(ValidationStatus.REJECTED, code, detail);
    }

    private SourceDocument withStatus(
            ValidationStatus status, SourceDomainException.Code code, String detail) {
        return new SourceDocument(
                sourceDocumentId,
                workspaceId,
                sourceBinaryId,
                originalFileName,
                mediaType,
                byteLength,
                contentSha256,
                receivedAt,
                idempotencyKey,
                status,
                code,
                detail);
    }

    private void requireStatus(ValidationStatus expected, ValidationStatus target) {
        if (validationStatus != expected) {
            throw new IllegalStateException(
                    "SOURCE_DOCUMENT_TRANSITION_NOT_ALLOWED:" + validationStatus + "->" + target);
        }
    }

    private static void validateFailure(
            ValidationStatus status, SourceDomainException.Code code, String detail) {
        if (status != ValidationStatus.REJECTED) {
            if (code != null || detail != null) {
                throw new IllegalArgumentException("SOURCE_DOCUMENT_FAILURE_REQUIRES_REJECTED_STATUS");
            }
            return;
        }
        if (code != SourceDomainException.Code.DOCX_SECURITY_REJECTED
                && code != SourceDomainException.Code.DOCX_FORMAT_INVALID) {
            throw new IllegalArgumentException("REJECTED_DOCUMENT_REQUIRES_VALIDATION_FAILURE_CODE");
        }
        requireText(detail, "SOURCE_DOCUMENT_FAILURE_DETAIL_REQUIRED");
    }

    private static String requireText(String value, String errorCode) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(errorCode);
        }
        return value;
    }
}
