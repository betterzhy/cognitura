package io.cognitura.source.application.processing;

import java.time.Instant;
import java.util.Objects;

public record AttemptLease(
        ProcessingAttempt.Status expectedStatus,
        Instant observedLeaseExpiresAt,
        Instant nextLeaseExpiresAt) {

    public AttemptLease {
        Objects.requireNonNull(expectedStatus, "expectedStatus");
        Objects.requireNonNull(observedLeaseExpiresAt, "observedLeaseExpiresAt");
        if (expectedStatus != ProcessingAttempt.Status.PENDING
                && expectedStatus != ProcessingAttempt.Status.RUNNING) {
            throw new IllegalArgumentException("LEASE_EXPECTED_STATUS_MUST_BE_ACTIVE");
        }
        if (nextLeaseExpiresAt != null
                && !nextLeaseExpiresAt.isAfter(observedLeaseExpiresAt)) {
            throw new IllegalArgumentException("NEXT_LEASE_MUST_EXTEND_OBSERVED_LEASE");
        }
    }

    public static AttemptLease claim(Instant observedClaimDeadline, Instant runningLeaseExpiresAt) {
        return new AttemptLease(
                ProcessingAttempt.Status.PENDING,
                observedClaimDeadline,
                Objects.requireNonNull(runningLeaseExpiresAt, "runningLeaseExpiresAt"));
    }

    public static AttemptLease heartbeat(
            Instant observedLeaseExpiresAt, Instant extendedLeaseExpiresAt) {
        return new AttemptLease(
                ProcessingAttempt.Status.RUNNING,
                observedLeaseExpiresAt,
                Objects.requireNonNull(extendedLeaseExpiresAt, "extendedLeaseExpiresAt"));
    }

    public static AttemptLease timeout(
            ProcessingAttempt.Status expectedStatus, Instant observedLeaseExpiresAt) {
        if (expectedStatus != ProcessingAttempt.Status.PENDING
                && expectedStatus != ProcessingAttempt.Status.RUNNING) {
            throw new IllegalArgumentException("TIMEOUT_EXPECTED_STATUS_MUST_BE_ACTIVE");
        }
        return new AttemptLease(expectedStatus, observedLeaseExpiresAt, null);
    }
}
