package io.cognitura.source.persistence;

import java.time.Instant;

public record SourceDocumentRow(
        String sourceDocumentId,
        String workspaceId,
        String sourceBinaryId,
        String originalFileName,
        String mediaType,
        long byteLength,
        String contentSha256,
        Instant receivedAt,
        String idempotencyKey,
        String validationStatus,
        String validationFailureCode,
        String validationFailureDetail) {}
