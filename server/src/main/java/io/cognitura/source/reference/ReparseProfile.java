package io.cognitura.source.reference;

public record ReparseProfile(String parserProfileVersion) {

    public ReparseProfile {
        parserProfileVersion = StableSourceReference.requireIdentifier(
                parserProfileVersion, "PARSER_PROFILE_VERSION");
    }
}
