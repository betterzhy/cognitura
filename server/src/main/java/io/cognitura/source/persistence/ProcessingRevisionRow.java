package io.cognitura.source.persistence;

import java.time.Instant;

public record ProcessingRevisionRow(
        String sourceProcessingRevisionId,
        String sourceDocumentId,
        String contentSha256,
        String parserProfileVersion,
        String revisionStatus,
        String failureCode,
        String failureDetail,
        Instant startedAt,
        Instant completedAt) {}
