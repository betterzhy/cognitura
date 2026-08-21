package io.cognitura.source.application.command;

import io.cognitura.source.domain.SourceDocument;
import io.cognitura.source.domain.SourceHash;
import java.io.InputStream;
import java.time.Clock;
import java.time.Instant;
import java.util.Objects;
import java.util.function.Supplier;
import java.util.regex.Pattern;

public final class SourceCommandService {

    private static final Pattern IDEMPOTENCY_KEY =
            Pattern.compile("[A-Za-z0-9][A-Za-z0-9._:-]{0,127}");
    private static final Pattern SOURCE_DOCUMENT_ID =
            Pattern.compile("[A-Za-z0-9][A-Za-z0-9._:-]{0,127}");

    private final SourceBinaryStore binaryStore;
    private final SourceCommandPersistencePort persistence;
    private final Supplier<String> sourceDocumentIds;
    private final Clock clock;

    public SourceCommandService(
            SourceBinaryStore binaryStore,
            SourceCommandPersistencePort persistence,
            Supplier<String> sourceDocumentIds,
            Clock clock) {
        this.binaryStore = Objects.requireNonNull(binaryStore, "binaryStore");
        this.persistence = Objects.requireNonNull(persistence, "persistence");
        this.sourceDocumentIds = Objects.requireNonNull(sourceDocumentIds, "sourceDocumentIds");
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    public UploadResult upload(TrustedRequestContext context, UploadCommand command) {
        Objects.requireNonNull(context, "context");
        Objects.requireNonNull(command, "command");
        String originalFileName = requireFileName(command.originalFileName());
        String idempotencyKey = requireIdempotencyKey(command.idempotencyKey());
        SourceBinaryStore.StoredBinary stored = binaryStore.store(
                command.content(),
                command.declaredLength(),
                command.declaredContentSha256(),
                command.mediaType());
        String sourceDocumentId = requireSourceDocumentId(sourceDocumentIds.get());
        String sourceBinaryId = "source-binary-" + stored.contentSha256().value();
        Instant receivedAt = clock.instant();
        var registration = new SourceCommandPersistencePort.UploadRegistration(
                sourceDocumentId,
                context.workspaceId(),
                sourceBinaryId,
                originalFileName,
                stored.mediaType(),
                stored.byteLength(),
                stored.contentSha256(),
                idempotencyKey,
                stored.opaqueLocation(),
                receivedAt);
        var outcome = persistence.registerUpload(registration);
        SourceDocument document = outcome.sourceDocument();
        return new UploadResult(
                document.sourceDocumentId(),
                document.validationStatus(),
                document.contentSha256(),
                document.receivedAt(),
                outcome.createdSourceDocument());
    }

    public record UploadCommand(
            String originalFileName,
            String mediaType,
            InputStream content,
            long declaredLength,
            SourceHash declaredContentSha256,
            String idempotencyKey) {

        public UploadCommand {
            Objects.requireNonNull(content, "content");
            Objects.requireNonNull(declaredContentSha256, "declaredContentSha256");
        }
    }

    public record UploadResult(
            String sourceDocumentId,
            SourceDocument.ValidationStatus status,
            SourceHash contentSha256,
            Instant receivedAt,
            boolean created) {

        public UploadResult {
            Objects.requireNonNull(sourceDocumentId, "sourceDocumentId");
            Objects.requireNonNull(status, "status");
            Objects.requireNonNull(contentSha256, "contentSha256");
            Objects.requireNonNull(receivedAt, "receivedAt");
        }
    }

    private static String requireFileName(String value) {
        if (value == null || value.isBlank() || value.length() > 255
                || value.indexOf('/') >= 0 || value.indexOf('\\') >= 0
                || value.indexOf('\0') >= 0) {
            throw new IllegalArgumentException("SOURCE_FILE_NAME_INVALID");
        }
        return value;
    }

    private static String requireIdempotencyKey(String value) {
        if (value == null || !IDEMPOTENCY_KEY.matcher(value).matches()) {
            throw new IllegalArgumentException("SOURCE_IDEMPOTENCY_KEY_INVALID");
        }
        return value;
    }

    private static String requireSourceDocumentId(String value) {
        if (value == null || !SOURCE_DOCUMENT_ID.matcher(value).matches()) {
            throw new IllegalStateException("SOURCE_DOCUMENT_ID_GENERATOR_INVALID");
        }
        return value;
    }
}
