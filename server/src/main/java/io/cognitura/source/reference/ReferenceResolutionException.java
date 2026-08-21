package io.cognitura.source.reference;

import java.util.Objects;

public final class ReferenceResolutionException extends RuntimeException {

    public enum Code {
        REFERENCE_NOT_FOUND,
        REFERENCE_SCOPE_MISMATCH,
        REFERENCE_ALIAS_CONFLICT,
        PARTIAL_ACCEPTANCE_REQUIRED,
        LINEAGE_REVISION_SCOPE_MISMATCH,
        LINEAGE_COVERAGE_INVALID,
        LINEAGE_CARDINALITY_INVALID,
        LINEAGE_AMBIGUOUS,
        HISTORICAL_RETARGET_FORBIDDEN
    }

    private final Code code;

    public ReferenceResolutionException(Code code, String detail) {
        super(Objects.requireNonNull(code, "code").name() + ":" + requireDetail(detail));
        this.code = code;
    }

    public Code code() {
        return code;
    }

    private static String requireDetail(String detail) {
        if (detail == null || detail.isBlank()) {
            throw new IllegalArgumentException("REFERENCE_ERROR_DETAIL_REQUIRED");
        }
        return detail;
    }
}
