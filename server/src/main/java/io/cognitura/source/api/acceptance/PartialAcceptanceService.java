package io.cognitura.source.api.acceptance;

import io.cognitura.source.application.command.TrustedRequestContext;
import java.time.Clock;
import java.time.Instant;
import java.util.Objects;

public final class PartialAcceptanceService {

    private final PartialAcceptancePort port;
    private final Clock clock;

    public PartialAcceptanceService(PartialAcceptancePort port, Clock clock) {
        this.port = Objects.requireNonNull(port, "port");
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    public Result accept(TrustedRequestContext context, PartialAcceptanceCommand command) {
        Objects.requireNonNull(context, "context");
        Objects.requireNonNull(command, "command");
        try {
            return switch (port.accept(context, command, clock.instant())) {
                case PartialAcceptancePort.Accepted accepted -> new Result(
                        accepted.sourceDocumentId(),
                        accepted.sourceProcessingRevisionId(),
                        "ACCEPTED",
                        accepted.partialAcceptedAt(),
                        accepted.acceptedBy(),
                        true,
                        accepted.idempotentReplay());
                case PartialAcceptancePort.Rejected rejected -> throw failure(
                        rejected.code(), command);
            };
        } catch (PartialAcceptancePort.PersistenceFailure failure) {
            throw PartialAcceptanceException.concurrent(
                    command.sourceDocumentId(), command.sourceProcessingRevisionId());
        }
    }

    private static PartialAcceptanceException failure(
            PartialAcceptancePort.Rejection rejection,
            PartialAcceptanceCommand command) {
        return switch (rejection) {
            case RESOURCE_NOT_FOUND -> PartialAcceptanceException.notFound();
            case PREVIEW_NOT_READY -> PartialAcceptanceException.resolved(
                    ErrorCode.PREVIEW_NOT_READY,
                    command.sourceDocumentId(), command.sourceProcessingRevisionId());
            case PARTIAL_ACCEPTANCE_CONFLICT -> PartialAcceptanceException.resolved(
                    ErrorCode.PARTIAL_ACCEPTANCE_CONFLICT,
                    command.sourceDocumentId(), command.sourceProcessingRevisionId());
        };
    }

    public record Result(
            String sourceDocumentId,
            String sourceProcessingRevisionId,
            String partialAcceptanceStatus,
            Instant partialAcceptedAt,
            String acceptedBy,
            boolean consumptionEligible,
            boolean idempotentReplay) {}

    public enum ErrorCode {
        RESOURCE_NOT_FOUND,
        PREVIEW_NOT_READY,
        PARTIAL_ACCEPTANCE_CONFLICT,
        CONCURRENT_COMPLETION_CONFLICT
    }

    public static final class PartialAcceptanceException extends RuntimeException {
        private final ErrorCode code;
        private final String sourceDocumentId;
        private final String sourceProcessingRevisionId;

        private PartialAcceptanceException(
                ErrorCode code, String sourceDocumentId, String sourceProcessingRevisionId) {
            super(code.name());
            this.code = code;
            this.sourceDocumentId = sourceDocumentId;
            this.sourceProcessingRevisionId = sourceProcessingRevisionId;
        }

        static PartialAcceptanceException notFound() {
            return new PartialAcceptanceException(ErrorCode.RESOURCE_NOT_FOUND, null, null);
        }

        static PartialAcceptanceException resolved(
                ErrorCode code, String sourceDocumentId, String revisionId) {
            return new PartialAcceptanceException(code, sourceDocumentId, revisionId);
        }

        static PartialAcceptanceException concurrent(String sourceDocumentId, String revisionId) {
            return resolved(ErrorCode.CONCURRENT_COMPLETION_CONFLICT, sourceDocumentId, revisionId);
        }

        public ErrorCode code() { return code; }
        public String sourceDocumentId() { return sourceDocumentId; }
        public String sourceProcessingRevisionId() { return sourceProcessingRevisionId; }
    }
}
