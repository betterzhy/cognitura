package io.cognitura.source.docx.security;

public record DocxPackageLimits(
        int maximumEntryCount,
        long maximumEntryBytes,
        long maximumTotalBytes,
        long maximumCompressionRatio) {

    public DocxPackageLimits {
        if (maximumEntryCount <= 0
                || maximumEntryBytes <= 0
                || maximumTotalBytes <= 0
                || maximumCompressionRatio <= 0) {
            throw new IllegalArgumentException("DOCX_PACKAGE_LIMITS_MUST_BE_POSITIVE");
        }
        if (maximumEntryBytes > maximumTotalBytes) {
            throw new IllegalArgumentException("DOCX_ENTRY_LIMIT_MUST_NOT_EXCEED_TOTAL_LIMIT");
        }
    }

    public static DocxPackageLimits defaults() {
        return new DocxPackageLimits(4_096, 16_777_216, 134_217_728, 200);
    }
}
