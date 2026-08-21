package io.cognitura.source.reference;

public record ReparseProfile(String parserProfileVersion) {

    public ReparseProfile {
        parserProfileVersion = StableSourceReference.requireText(
                parserProfileVersion, "PARSER_PROFILE_VERSION_REQUIRED");
    }
}
