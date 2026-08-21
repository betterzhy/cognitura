package io.cognitura.source.application.processing;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

public record AttemptFence(
        String revisionId, String attemptId, long generation, String fencingToken) {

    public AttemptFence {
        revisionId = requireText(revisionId, "REVISION_ID_REQUIRED");
        attemptId = requireText(attemptId, "ATTEMPT_ID_REQUIRED");
        if (generation <= 0) {
            throw new IllegalArgumentException("ATTEMPT_GENERATION_MUST_BE_POSITIVE");
        }
        fencingToken = requireText(fencingToken, "FENCING_TOKEN_REQUIRED");
    }

    public static AttemptFence forGeneration(
            String revisionId, String attemptId, long generation) {
        return new AttemptFence(
                revisionId, attemptId, generation, fencingTokenFor(revisionId, generation));
    }

    public static String fencingTokenFor(String revisionId, long generation) {
        String canonicalRevisionId = requireText(revisionId, "REVISION_ID_REQUIRED");
        if (generation <= 0) {
            throw new IllegalArgumentException("ATTEMPT_GENERATION_MUST_BE_POSITIVE");
        }
        byte[] revisionBytes = canonicalRevisionId.getBytes(StandardCharsets.UTF_8);
        ByteBuffer canonical = ByteBuffer.allocate(
                "cognitura:processing-fence".length() + Integer.BYTES
                        + revisionBytes.length + Long.BYTES);
        canonical.put("cognitura:processing-fence".getBytes(StandardCharsets.UTF_8));
        canonical.putInt(revisionBytes.length);
        canonical.put(revisionBytes);
        canonical.putLong(generation);
        try {
            return HexFormat.of().formatHex(
                    MessageDigest.getInstance("SHA-256").digest(canonical.array()));
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException("SHA_256_ALGORITHM_UNAVAILABLE", error);
        }
    }

    private static String requireText(String value, String code) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(code);
        }
        return value;
    }
}
