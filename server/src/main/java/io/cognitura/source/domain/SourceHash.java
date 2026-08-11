package io.cognitura.source.domain;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;
import java.util.regex.Pattern;

public record SourceHash(String value) {

    private static final Pattern CANONICAL_SHA_256 = Pattern.compile("[0-9a-f]{64}");

    public SourceHash {
        Objects.requireNonNull(value, "value");
        if (!CANONICAL_SHA_256.matcher(value).matches()) {
            throw new IllegalArgumentException("SHA256_MUST_BE_64_LOWERCASE_HEX");
        }
    }

    public static SourceHash ofHex(String value) {
        return new SourceHash(value);
    }

    public static SourceHash sha256(byte[] bytes) {
        Objects.requireNonNull(bytes, "bytes");
        try {
            var digest = MessageDigest.getInstance("SHA-256").digest(bytes);
            return new SourceHash(HexFormat.of().formatHex(digest));
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException("SHA_256_ALGORITHM_UNAVAILABLE", error);
        }
    }
}
