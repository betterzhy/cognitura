package io.cognitura.source.application.command;

import java.util.Objects;

public final class SourceCommandException extends RuntimeException {

    public enum Code {
        IDEMPOTENCY_CONFLICT,
        PERSISTENCE_FAILURE
    }

    private final Code code;

    private SourceCommandException(Code code, Throwable cause) {
        super(Objects.requireNonNull(code, "code").name(), cause);
        this.code = code;
    }

    public static SourceCommandException idempotencyConflict() {
        return new SourceCommandException(Code.IDEMPOTENCY_CONFLICT, null);
    }

    public static SourceCommandException persistenceFailure(Throwable cause) {
        return new SourceCommandException(Code.PERSISTENCE_FAILURE, cause);
    }

    public Code code() {
        return code;
    }
}
