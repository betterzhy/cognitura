package io.cognitura.source.api.acceptance;

import io.cognitura.source.application.command.TrustedRequestContext;
import java.time.Instant;

public interface PartialAcceptancePort {

    Outcome accept(
            TrustedRequestContext context,
            PartialAcceptanceCommand command,
            Instant acceptedAt);

    sealed interface Outcome permits Accepted, Rejected {}

    record Accepted(
            String sourceDocumentId,
            String sourceProcessingRevisionId,
            Instant partialAcceptedAt,
            String acceptedBy,
            boolean idempotentReplay) implements Outcome {}

    record Rejected(Rejection code) implements Outcome {}

    enum Rejection {
        RESOURCE_NOT_FOUND,
        PREVIEW_NOT_READY,
        PARTIAL_ACCEPTANCE_CONFLICT
    }

    final class PersistenceFailure extends RuntimeException {
        public PersistenceFailure(Throwable cause) {
            super("PARTIAL_ACCEPTANCE_PERSISTENCE_FAILURE", cause);
        }
    }
}
