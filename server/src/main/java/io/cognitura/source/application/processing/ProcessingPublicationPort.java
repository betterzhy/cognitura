package io.cognitura.source.application.processing;

import java.time.Instant;
import java.util.Objects;
import java.util.regex.Pattern;

public interface ProcessingPublicationPort {

    Pattern SHA_256 = Pattern.compile("[0-9a-f]{64}");

    enum Outcome {
        APPLIED,
        ACTIVE_ATTEMPT_EXISTS,
        RETRY_NOT_ALLOWED,
        STALE_FENCE,
        STALE_LEASE,
        BLOCK_SET_MISMATCH,
        ALREADY_PUBLISHED
    }

    record BeginAttempt(
            String sourceDocumentId,
            String revisionId,
            String attemptId,
            String contentSha256,
            String parserProfileVersion,
            Instant startedAt,
            Instant claimDeadline) {

        public BeginAttempt {
            sourceDocumentId = requireText(sourceDocumentId, "SOURCE_DOCUMENT_ID_REQUIRED");
            revisionId = requireText(revisionId, "REVISION_ID_REQUIRED");
            attemptId = requireText(attemptId, "ATTEMPT_ID_REQUIRED");
            contentSha256 = requireText(contentSha256, "CONTENT_SHA256_REQUIRED");
            if (!SHA_256.matcher(contentSha256).matches()) {
                throw new IllegalArgumentException("CONTENT_SHA256_MUST_BE_64_LOWERCASE_HEX");
            }
            parserProfileVersion = requireText(
                    parserProfileVersion, "PARSER_PROFILE_VERSION_REQUIRED");
            Objects.requireNonNull(startedAt, "startedAt");
            Objects.requireNonNull(claimDeadline, "claimDeadline");
            if (!claimDeadline.isAfter(startedAt)) {
                throw new IllegalArgumentException("CLAIM_DEADLINE_MUST_FOLLOW_ATTEMPT_START");
            }
        }
    }

    record BeginResult(Outcome outcome, ProcessingAttempt attempt) {

        public BeginResult {
            Objects.requireNonNull(outcome, "outcome");
            if ((outcome == Outcome.APPLIED) != (attempt != null)) {
                throw new IllegalArgumentException("BEGIN_RESULT_ATTEMPT_MUST_MATCH_OUTCOME");
            }
        }

        public static BeginResult applied(ProcessingAttempt attempt) {
            return new BeginResult(Outcome.APPLIED, Objects.requireNonNull(attempt, "attempt"));
        }

        public static BeginResult rejected(Outcome outcome) {
            if (outcome == Outcome.APPLIED) {
                throw new IllegalArgumentException("REJECTED_BEGIN_RESULT_CANNOT_BE_APPLIED");
            }
            return new BeginResult(outcome, null);
        }
    }

    record Failure(
            ProcessingAttempt.Status terminalStatus,
            String failureCode,
            String failureDetail,
            Instant completedAt) {

        public Failure {
            if (terminalStatus != ProcessingAttempt.Status.FAILED_RETRYABLE
                    && terminalStatus != ProcessingAttempt.Status.FAILED_TERMINAL) {
                throw new IllegalArgumentException("FAILURE_STATUS_MUST_BE_TERMINAL_FAILURE");
            }
            failureCode = requireText(failureCode, "FAILURE_CODE_REQUIRED");
            failureDetail = requireText(failureDetail, "FAILURE_DETAIL_REQUIRED");
            Objects.requireNonNull(completedAt, "completedAt");
        }
    }

    final class StorageException extends RuntimeException {

        public StorageException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    BeginResult beginInitial(BeginAttempt command);

    BeginResult beginRetry(BeginAttempt command);

    Outcome claim(AttemptFence fence, AttemptLease lease, Instant observedAt);

    Outcome heartbeat(AttemptFence fence, AttemptLease lease, Instant observedAt);

    Outcome timeout(AttemptFence fence, AttemptLease lease, Instant timedOutAt);

    Outcome stage(AttemptFence fence, CandidateBlockSet blockSet);

    Outcome publish(
            AttemptFence fence,
            CandidateBlockSet blockSet,
            BlockSetDigest blockSetDigest,
            Instant completedAt);

    Outcome fail(AttemptFence fence, Failure failure);

    private static String requireText(String value, String code) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(code);
        }
        return value;
    }
}
