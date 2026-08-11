package io.cognitura.source.domain;

import java.time.Instant;
import java.util.Objects;

public record ProcessingRevision(
        String sourceProcessingRevisionId,
        String sourceDocumentId,
        SourceHash contentSha256,
        String parserProfileVersion,
        Status status,
        SourceDomainException.Code failureCode,
        String failureDetail,
        Instant startedAt,
        Instant completedAt) {

    public enum Status {
        PARSING,
        PARSED,
        PREVIEW_READY,
        FAILED_RETRYABLE,
        FAILED_TERMINAL
    }

    public ProcessingRevision {
        sourceProcessingRevisionId =
                requireText(sourceProcessingRevisionId, "PROCESSING_REVISION_ID_REQUIRED");
        sourceDocumentId = requireText(sourceDocumentId, "SOURCE_DOCUMENT_ID_REQUIRED");
        Objects.requireNonNull(contentSha256, "contentSha256");
        parserProfileVersion =
                requireText(parserProfileVersion, "PARSER_PROFILE_VERSION_REQUIRED");
        Objects.requireNonNull(status, "status");
        Objects.requireNonNull(startedAt, "startedAt");
        validateState(status, failureCode, failureDetail, completedAt);
    }

    public static ProcessingRevision start(
            String sourceProcessingRevisionId,
            SourceDocument sourceDocument,
            SourceHash expectedContentSha256,
            String parserProfileVersion,
            Instant startedAt) {
        Objects.requireNonNull(sourceDocument, "sourceDocument");
        Objects.requireNonNull(expectedContentSha256, "expectedContentSha256");
        if (sourceDocument.validationStatus() != SourceDocument.ValidationStatus.ACCEPTED) {
            throw new IllegalStateException("SOURCE_DOCUMENT_MUST_BE_ACCEPTED_FOR_REVISION");
        }
        if (!sourceDocument.contentSha256().equals(expectedContentSha256)) {
            throw new IllegalArgumentException("PROCESSING_REVISION_CONTENT_HASH_MISMATCH");
        }
        return new ProcessingRevision(
                sourceProcessingRevisionId,
                sourceDocument.sourceDocumentId(),
                sourceDocument.contentSha256(),
                parserProfileVersion,
                Status.PARSING,
                null,
                null,
                startedAt,
                null);
    }

    public static ProcessingRevision restore(
            String sourceProcessingRevisionId,
            String sourceDocumentId,
            SourceHash contentSha256,
            String parserProfileVersion,
            Status status,
            SourceDomainException.Code failureCode,
            String failureDetail,
            Instant startedAt,
            Instant completedAt) {
        return new ProcessingRevision(
                sourceProcessingRevisionId,
                sourceDocumentId,
                contentSha256,
                parserProfileVersion,
                status,
                failureCode,
                failureDetail,
                startedAt,
                completedAt);
    }

    public void requireTransitionAllowed(Status target) {
        Objects.requireNonNull(target, "target");
        boolean allowed = switch (status) {
            case PARSING -> target == Status.PARSED
                    || target == Status.FAILED_RETRYABLE
                    || target == Status.FAILED_TERMINAL;
            case FAILED_RETRYABLE -> target == Status.PARSING;
            case PARSED -> target == Status.PREVIEW_READY;
            case PREVIEW_READY, FAILED_TERMINAL -> false;
        };
        if (!allowed) {
            throw new IllegalStateException(
                    "PROCESSING_REVISION_TRANSITION_NOT_ALLOWED:" + status + "->" + target);
        }
    }

    private static void validateState(
            Status status,
            SourceDomainException.Code failureCode,
            String failureDetail,
            Instant completedAt) {
        if (status == Status.PARSING) {
            if (failureCode != null || failureDetail != null || completedAt != null) {
                throw new IllegalArgumentException("PARSING_REVISION_CANNOT_HAVE_COMPLETION_FACTS");
            }
            return;
        }
        Objects.requireNonNull(completedAt, "completedAt");
        if (status == Status.FAILED_RETRYABLE) {
            if (failureCode != SourceDomainException.Code.PARSER_RETRYABLE_FAILURE) {
                throw new IllegalArgumentException(
                        "RETRYABLE_REVISION_FAILURE_REQUIRES_PARSER_RETRYABLE_FAILURE");
            }
            requireText(failureDetail, "PROCESSING_REVISION_FAILURE_DETAIL_REQUIRED");
            return;
        }
        if (status == Status.FAILED_TERMINAL) {
            if (failureCode != SourceDomainException.Code.PARSER_TERMINAL_FAILURE
                    && failureCode != SourceDomainException.Code.DOCX_FORMAT_INVALID) {
                throw new IllegalArgumentException(
                        "TERMINAL_REVISION_FAILURE_REQUIRES_TERMINAL_FAILURE_CODE");
            }
            requireText(failureDetail, "PROCESSING_REVISION_FAILURE_DETAIL_REQUIRED");
            return;
        }
        if (failureCode != null || failureDetail != null) {
            throw new IllegalArgumentException("SUCCESSFUL_REVISION_CANNOT_HAVE_FAILURE_FACTS");
        }
    }

    private static String requireText(String value, String errorCode) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(errorCode);
        }
        return value;
    }
}
