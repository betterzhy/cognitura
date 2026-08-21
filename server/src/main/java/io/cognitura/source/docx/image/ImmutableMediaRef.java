package io.cognitura.source.docx.image;

public record ImmutableMediaRef(String value) {

    public ImmutableMediaRef {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("IMMUTABLE_MEDIA_REF_REQUIRED");
        }
        if (value.startsWith("/")
                || value.contains("\\")
                || value.contains("://")
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
