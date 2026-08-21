package io.cognitura.source.application.processing;

import io.cognitura.source.domain.SourceDomainException;
import java.time.Instant;
import java.util.Objects;

public final class ProcessingPublicationService {

    public static final class Rejected extends RuntimeException {

        private final ProcessingPublicationPort.Outcome outcome;

        private Rejected(ProcessingPublicationPort.Outcome outcome) {
            super(Objects.requireNonNull(outcome, "outcome").name());
            this.outcome = outcome;
        }

        public ProcessingPublicationPort.Outcome outcome() {
            return outcome;
        }
    }

    private final ProcessingPublicationPort port;

    public ProcessingPublicationService(ProcessingPublicationPort port) {
        this.port = Objects.requireNonNull(port, "port");
    }

    public ProcessingAttempt beginInitial(
            String sourceDocumentId,
            String revisionId,
            String attemptId,
            String contentSha256,
            String parserProfileVersion,
            Instant startedAt,
            Instant claimDeadline) {
        return requireBeginApplied(port.beginInitial(new ProcessingPublicationPort.BeginAttempt(
                sourceDocumentId,
                revisionId,
                attemptId,
                contentSha256,
                parserProfileVersion,
                startedAt,
                claimDeadline)));
    }

    public ProcessingAttempt retry(
            String sourceDocumentId,
            String revisionId,
            String attemptId,
            String contentSha256,
            String parserProfileVersion,
            Instant startedAt,
            Instant claimDeadline) {
        return requireBeginApplied(port.beginRetry(new ProcessingPublicationPort.BeginAttempt(
                sourceDocumentId,
                revisionId,
                attemptId,
                contentSha256,
                parserProfileVersion,
                startedAt,
                claimDeadline)));
    }

    public void claim(
            AttemptFence fence,
            Instant observedClaimDeadline,
            Instant runningLeaseExpiresAt,
            Instant observedAt) {
        Objects.requireNonNull(observedAt, "observedAt");
        if (!observedAt.isBefore(observedClaimDeadline)) {
            throw new Rejected(ProcessingPublicationPort.Outcome.STALE_LEASE);
        }
        requireApplied(port.claim(
                Objects.requireNonNull(fence, "fence"),
                AttemptLease.claim(observedClaimDeadline, runningLeaseExpiresAt),
                observedAt));
    }

    public void heartbeat(
            AttemptFence fence,
            Instant observedLeaseExpiresAt,
            Instant extendedLeaseExpiresAt,
            Instant observedAt) {
        Objects.requireNonNull(observedAt, "observedAt");
        if (!observedAt.isBefore(observedLeaseExpiresAt)) {
            throw new Rejected(ProcessingPublicationPort.Outcome.STALE_LEASE);
        }
        requireApplied(port.heartbeat(
                Objects.requireNonNull(fence, "fence"),
                AttemptLease.heartbeat(observedLeaseExpiresAt, extendedLeaseExpiresAt),
                observedAt));
    }

    public void timeout(
            AttemptFence fence,
            ProcessingAttempt.Status expectedStatus,
            Instant observedLeaseExpiresAt,
            Instant timedOutAt) {
        Objects.requireNonNull(timedOutAt, "timedOutAt");
        if (timedOutAt.isBefore(observedLeaseExpiresAt)) {
            throw new Rejected(ProcessingPublicationPort.Outcome.STALE_LEASE);
        }
        requireApplied(port.timeout(
                Objects.requireNonNull(fence, "fence"),
                AttemptLease.timeout(expectedStatus, observedLeaseExpiresAt),
                timedOutAt));
    }

    public void stage(AttemptFence fence, CandidateBlockSet blockSet) {
        requireBlockSetIdentity(fence, blockSet);
        requireApplied(port.stage(fence, blockSet));
    }

    public BlockSetDigest publish(
            AttemptFence fence, CandidateBlockSet blockSet, Instant completedAt) {
        requireBlockSetIdentity(fence, blockSet);
        Objects.requireNonNull(completedAt, "completedAt");
        BlockSetDigest digest = BlockSetDigest.compute(blockSet);
        requireApplied(port.publish(fence, blockSet, digest, completedAt));
        return digest;
    }

    public void fail(
            AttemptFence fence,
            ProcessingAttempt.Status terminalStatus,
            SourceDomainException.Code failureCode,
            String failureDetail,
            Instant completedAt) {
        requireApplied(port.fail(
                Objects.requireNonNull(fence, "fence"),
                new ProcessingPublicationPort.Failure(
                        terminalStatus, failureCode, failureDetail, completedAt)));
    }

    private static ProcessingAttempt requireBeginApplied(
            ProcessingPublicationPort.BeginResult result) {
        Objects.requireNonNull(result, "result");
        if (result.outcome() != ProcessingPublicationPort.Outcome.APPLIED) {
            throw new Rejected(result.outcome());
        }
        return result.attempt();
    }

    private static void requireApplied(ProcessingPublicationPort.Outcome outcome) {
        Objects.requireNonNull(outcome, "outcome");
        if (outcome != ProcessingPublicationPort.Outcome.APPLIED) {
            throw new Rejected(outcome);
        }
    }

    private static void requireBlockSetIdentity(
            AttemptFence fence, CandidateBlockSet blockSet) {
        Objects.requireNonNull(fence, "fence");
        Objects.requireNonNull(blockSet, "blockSet");
        if (!fence.revisionId().equals(blockSet.revisionId())
                || !fence.attemptId().equals(blockSet.attemptId())) {
            throw new Rejected(ProcessingPublicationPort.Outcome.BLOCK_SET_MISMATCH);
        }
    }
}
