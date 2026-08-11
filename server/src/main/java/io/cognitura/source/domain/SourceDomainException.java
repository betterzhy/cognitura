package io.cognitura.source.domain;

import java.util.Objects;

public final class SourceDomainException extends RuntimeException {

    public enum Code {
        UNSUPPORTED_MEDIA_TYPE(false),
        EMPTY_SOURCE_FILE(false),
        SOURCE_SIZE_LIMIT(false),
        SOURCE_HASH_MISMATCH(false),
        IDEMPOTENCY_CONFLICT(false),
        DOCX_SECURITY_REJECTED(false),
        DOCX_FORMAT_INVALID(false),
        PARSER_RETRYABLE_FAILURE(true),
        PARSER_TERMINAL_FAILURE(false);

        private final boolean retryable;

        Code(boolean retryable) {
            this.retryable = retryable;
        }

        public boolean retryable() {
            return retryable;
        }
    }

    private final Code code;

    public SourceDomainException(Code code, String detail) {
        super(Objects.requireNonNull(code, "code") + ":" + requireDetail(detail));
        this.code = code;
    }

    public Code code() {
        return code;
    }

    public boolean retryable() {
        return code.retryable();
    }

    private static String requireDetail(String detail) {
        if (detail == null || detail.isBlank()) {
            throw new IllegalArgumentException("SOURCE_DOMAIN_ERROR_DETAIL_REQUIRED");
        }
        return detail;
    }
}
