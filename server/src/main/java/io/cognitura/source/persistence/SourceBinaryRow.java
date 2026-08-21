package io.cognitura.source.persistence;

import java.time.Instant;

public record SourceBinaryRow(
        String sourceBinaryId,
        String contentSha256,
        long byteLength,
        String mediaType,
        String binaryLocation,
        Instant createdAt) {}
