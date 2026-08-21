package io.cognitura.source.docx.image;

import java.util.Locale;

public record ImmutableMediaRef(String value) {

    public ImmutableMediaRef {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("IMMUTABLE_MEDIA_REF_REQUIRED");
        }
        String lowerCaseValue = value.toLowerCase(Locale.ROOT);
        if (value.startsWith("/")
                || value.contains("\\")
                || value.contains("://")
                || lowerCaseValue.startsWith("file:")
                || lowerCaseValue.startsWith("http:")
                || lowerCaseValue.startsWith("https:")
                || value.matches("^[A-Za-z]:/.*")
                || value.equals(".")
                || value.equals("..")
                || value.contains("/../")
                || value.startsWith("../")
                || value.endsWith("/..")) {
            throw new IllegalArgumentException("IMMUTABLE_MEDIA_REF_MUST_BE_OPAQUE");
        }
    }
}
