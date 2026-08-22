package io.cognitura.source.api.acceptance;

import com.fasterxml.jackson.annotation.JsonAnySetter;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

public final class PartialAcceptanceRequest {

    private final String blockSetDigest;
    private final String omissionsDigest;
    private final String idempotencyKey;
    private final String decision;

    @JsonCreator
    public PartialAcceptanceRequest(
            @JsonProperty("blockSetDigest") String blockSetDigest,
            @JsonProperty("omissionsDigest") String omissionsDigest,
            @JsonProperty("idempotencyKey") String idempotencyKey,
            @JsonProperty("decision") String decision) {
        this.blockSetDigest = blockSetDigest;
        this.omissionsDigest = omissionsDigest;
        this.idempotencyKey = idempotencyKey;
        this.decision = decision;
    }

    @JsonAnySetter
    void rejectUnknownField(String name, Object value) {
        throw new IllegalArgumentException("PARTIAL_ACCEPTANCE_FIELD_INVALID");
    }

    PartialAcceptanceCommand toCommand(String sourceDocumentId, String revisionId) {
        return new PartialAcceptanceCommand(
                sourceDocumentId, revisionId, blockSetDigest, omissionsDigest,
                idempotencyKey, decision);
    }
}
