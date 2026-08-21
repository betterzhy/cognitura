package io.cognitura.source.application.processing;

import io.cognitura.source.domain.SourceDomainException;
import java.time.Instant;
import java.util.Objects;

public record ProcessingAttempt(
        String revisionId,
        String attemptId,
        long attemptNumber,
        long generation,
        String fencingToken,
        Status status,
        Instant leaseExpiresAt,
        Instant heartbeatAt,
        SourceDomainException.Code failureCode,
        String failureDetail,
        Instant startedAt,
        Instant completedAt) {

    public enum Status {
        PENDING,
        RUNNING,
        SUCCEEDED,
        FAILED_RETRYABLE,
        FAILED_TERMINAL
    }

    public ProcessingAttempt {
        revisionId = requireText(revisionId, "REVISION_ID_REQUIRED");
        attemptId = requireText(attemptId, "ATTEMPT_ID_REQUIRED");
        if (generation <= 0) {
            throw new IllegalArgumentException("ATTEMPT_GENERATION_MUST_BE_POSITIVE");
        }
        if (attemptNumber <= 0) {
            throw new IllegalArgumentException("ATTEMPT_NUMBER_MUST_BE_POSITIVE");
        }
        fencingToken = requireText(fencingToken, "FENCING_TOKEN_REQUIRED");
        if (!fencingToken.equals(AttemptFence.fencingTokenFor(revisionId, generation))) {
            throw new IllegalArgumentException("FENCING_TOKEN_MUST_MATCH_REVISION_GENERATION");
        }
        Objects.requireNonNull(status, "status");
        Objects.requireNonNull(startedAt, "startedAt");
        validateState(status, leaseExpiresAt, heartbeatAt, failureCode, failureDetail, completedAt);
    }

    public static ProcessingAttempt pending(
            String revisionId,
            String attemptId,
            long attemptNumber,
            long generation,
            Instant claimDeadline,
            Instant startedAt) {
        return new ProcessingAttempt(
                revisionId,
                attemptId,
                attemptNumber,
                generation,
                AttemptFence.fencingTokenFor(revisionId, generation),
                Status.PENDING,
                Objects.requireNonNull(claimDeadline, "claimDeadline"),
                null,
                null,
                null,
                startedAt,
                null);
    }

    public AttemptFence fence() {
        return new AttemptFence(revisionId, attemptId, generation, fencingToken);
    }

    private static void validateState(
            Status status,
            Instant leaseExpiresAt,
            Instant heartbeatAt,
            SourceDomainException.Code failureCode,
            String failureDetail,
            Instant completedAt) {
        if (status == Status.PENDING || status == Status.RUNNING) {
            Objects.requireNonNull(leaseExpiresAt, "leaseExpiresAt");
            if (status == Status.PENDING && heartbeatAt != null) {
                throw new IllegalArgumentException("PENDING_ATTEMPT_CANNOT_HAVE_HEARTBEAT");
            }
            if (failureCode != null || failureDetail != null || completedAt != null) {
                throw new IllegalArgumentException("ACTIVE_ATTEMPT_CANNOT_HAVE_COMPLETION_FACTS");
            }
            return;
        }
        Objects.requireNonNull(completedAt, "completedAt");
        if (leaseExpiresAt != null) {
            throw new IllegalArgumentException("TERMINAL_ATTEMPT_CANNOT_HAVE_ACTIVE_LEASE");
        }
        if (status == Status.SUCCEEDED) {
            if (failureCode != null || failureDetail != null) {
                throw new IllegalArgumentException("SUCCEEDED_ATTEMPT_CANNOT_HAVE_FAILURE_FACTS");
            }
            return;
        }
        Objects.requireNonNull(failureCode, "failureCode");
        if (status == Status.FAILED_RETRYABLE
                && failureCode != SourceDomainException.Code.PARSER_RETRYABLE_FAILURE) {
            throw new IllegalArgumentException(
                    "RETRYABLE_ATTEMPT_REQUIRES_PARSER_RETRYABLE_FAILURE");
        }
        if (status == Status.FAILED_TERMINAL
                && failureCode != SourceDomainException.Code.PARSER_TERMINAL_FAILURE
                && failureCode != SourceDomainException.Code.DOCX_FORMAT_INVALID) {
            throw new IllegalArgumentException(
                    "TERMINAL_ATTEMPT_REQUIRES_TERMINAL_FAILURE_CODE");
        }
        requireText(failureDetail, "FAILED_ATTEMPT_DETAIL_REQUIRED");
    }

    private static String requireText(String value, String code) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(code);
        }
        return value;
    }
}
