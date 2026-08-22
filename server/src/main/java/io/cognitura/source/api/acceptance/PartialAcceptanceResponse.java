package io.cognitura.source.api.acceptance;

import java.time.Instant;

public record PartialAcceptanceResponse(
        String sourceDocumentId,
        String sourceProcessingRevisionId,
        String partialAcceptanceStatus,
        Instant partialAcceptedAt,
        String acceptedBy,
        boolean consumptionEligible,
        boolean idempotentReplay) {

    static PartialAcceptanceResponse from(PartialAcceptanceService.Result result) {
        return new PartialAcceptanceResponse(
                result.sourceDocumentId(),
                result.sourceProcessingRevisionId(),
                result.partialAcceptanceStatus(),
                result.partialAcceptedAt(),
                result.acceptedBy(),
                result.consumptionEligible(),
                result.idempotentReplay());
    }
}
