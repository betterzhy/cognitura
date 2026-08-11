package io.cognitura.source.domain;

import java.time.Instant;
import java.util.Objects;

public record SourceBinary(
        String sourceBinaryId,
        SourceHash contentSha256,
        long byteLength,
        String mediaType,
        String binaryLocation,
        Instant createdAt) {

    public SourceBinary {
        sourceBinaryId = requireText(sourceBinaryId, "SOURCE_BINARY_ID_REQUIRED");
        Objects.requireNonNull(contentSha256, "contentSha256");
        if (byteLength <= 0) {
            throw new IllegalArgumentException("SOURCE_BINARY_BYTE_LENGTH_MUST_BE_POSITIVE");
        }
        mediaType = requireText(mediaType, "SOURCE_BINARY_MEDIA_TYPE_REQUIRED");
        binaryLocation = requireText(binaryLocation, "SOURCE_BINARY_LOCATION_REQUIRED");
        Objects.requireNonNull(createdAt, "createdAt");
    }

    private static String requireText(String value, String errorCode) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(errorCode);
        }
        return value;
    }
}
