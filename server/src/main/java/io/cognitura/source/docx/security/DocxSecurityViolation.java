package io.cognitura.source.docx.security;

import io.cognitura.source.domain.SourceDomainException;
import java.util.Objects;

public final class DocxSecurityViolation extends RuntimeException {

    public enum Rule {
        DUPLICATE_ZIP_ENTRY_NAME,
        ABSOLUTE_ZIP_PATH,
        ZIP_PARENT_TRAVERSAL,
        UNKNOWN_ZIP_ENTRY_SIZE,
        ZIP_LIMIT_EXCEEDED,
        XML_EXTERNAL_ENTITY,
        MACRO_REQUIRING_EXECUTION,
        EXECUTABLE_EMBEDDED_OBJECT,
        EXTERNAL_RELATIONSHIP_DEREFERENCE_REQUEST
    }

    private final Rule rule;

    public DocxSecurityViolation(Rule rule, String safeDetail) {
        super(Objects.requireNonNull(rule, "rule") + ":" + requireSafeDetail(safeDetail));
        this.rule = rule;
    }

    public Rule rule() {
        return rule;
    }

    public SourceDomainException.Code code() {
        return SourceDomainException.Code.DOCX_SECURITY_REJECTED;
    }

    public boolean retryable() {
        return false;
    }

    private static String requireSafeDetail(String safeDetail) {
        if (safeDetail == null || safeDetail.isBlank()) {
            throw new IllegalArgumentException("DOCX_SECURITY_DETAIL_REQUIRED");
        }
        return safeDetail;
    }
}
