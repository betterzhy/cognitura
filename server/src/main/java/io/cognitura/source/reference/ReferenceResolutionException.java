package io.cognitura.source.reference;

import java.util.Objects;
import java.util.regex.Pattern;

public final class ReferenceResolutionException extends RuntimeException {

    private static final Pattern STRUCTURED_DETAIL = Pattern.compile(
            "(?:tuple|sourceAlias|blockAlias|aliasRegistration|reparse|revision|lineage)\\[.*");
    private static final Pattern SAFE_DETAIL = Pattern.compile(
            "[A-Za-z0-9][A-Za-z0-9._:=,\\[\\] -]{0,4095}");

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

    private ReferenceResolutionException(Code code, String detail) {
        super(Objects.requireNonNull(code, "code").name() + ":" + requireDetail(detail));
        this.code = code;
    }

    static ReferenceResolutionException of(Code code, String structuredDetail) {
        return new ReferenceResolutionException(code, structuredDetail);
    }

    public Code code() {
        return code;
    }

    private static String requireDetail(String detail) {
        if (detail == null
                || !STRUCTURED_DETAIL.matcher(detail).matches()
                || !SAFE_DETAIL.matcher(detail).matches()) {
            throw new IllegalArgumentException("REFERENCE_ERROR_DETAIL_UNSAFE");
        }
        return detail;
    }
}
