package io.cognitura.source.application.command;

import io.cognitura.source.domain.SourceDocument;
import io.cognitura.source.domain.SourceHash;
import io.cognitura.source.domain.ProcessingRevision;
import io.cognitura.source.application.processing.ProcessingAttempt;
import io.cognitura.source.application.processing.ProcessingPublicationService;
import java.io.InputStream;
import java.time.Clock;
import java.time.Duration;
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
    private final ProcessingPublicationService processing;
    private final Supplier<String> processingRevisionIds;
    private final Supplier<String> processingAttemptIds;
    private final Duration initialClaimLease;

    public SourceCommandService(
            SourceBinaryStore binaryStore,
            SourceCommandPersistencePort persistence,
            Supplier<String> sourceDocumentIds,
            Clock clock) {
        this.binaryStore = Objects.requireNonNull(binaryStore, "binaryStore");
        this.persistence = Objects.requireNonNull(persistence, "persistence");
        this.sourceDocumentIds = Objects.requireNonNull(sourceDocumentIds, "sourceDocumentIds");
        this.clock = Objects.requireNonNull(clock, "clock");
        this.processing = null;
        this.processingRevisionIds = null;
        this.processingAttemptIds = null;
        this.initialClaimLease = null;
    }

    public SourceCommandService(
            SourceBinaryStore binaryStore,
            SourceCommandPersistencePort persistence,
            Supplier<String> sourceDocumentIds,
            Clock clock,
            ProcessingPublicationService processing,
            Supplier<String> processingRevisionIds,
            Supplier<String> processingAttemptIds,
            Duration initialClaimLease) {
        this.binaryStore = Objects.requireNonNull(binaryStore, "binaryStore");
        this.persistence = Objects.requireNonNull(persistence, "persistence");
        this.sourceDocumentIds = Objects.requireNonNull(sourceDocumentIds, "sourceDocumentIds");
        this.clock = Objects.requireNonNull(clock, "clock");
        this.processing = Objects.requireNonNull(processing, "processing");
        this.processingRevisionIds = Objects.requireNonNull(
                processingRevisionIds, "processingRevisionIds");
        this.processingAttemptIds = Objects.requireNonNull(
                processingAttemptIds, "processingAttemptIds");
        this.initialClaimLease = Objects.requireNonNull(initialClaimLease, "initialClaimLease");
        if (initialClaimLease.isZero() || initialClaimLease.isNegative()) {
            throw new IllegalArgumentException("INITIAL_CLAIM_LEASE_MUST_BE_POSITIVE");
        }
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

    public ProcessingResult process(
            TrustedRequestContext context, ProcessingCommand command) {
        Objects.requireNonNull(context, "context");
        Objects.requireNonNull(command, "command");
        if (processing == null) {
            throw SourceCommandException.processingNotAccepted(command.sourceDocumentId());
        }
        var state = persistence.findProcessingCommandState(
                        context.workspaceId(),
                        command.sourceDocumentId(),
                        command.parserProfileVersion())
                .orElseThrow(SourceCommandException::resourceNotFound);
        if (state.validationStatus() == SourceDocument.ValidationStatus.RECEIVED
                || state.validationStatus() == SourceDocument.ValidationStatus.VALIDATING) {
            throw SourceCommandException.sourceNotAccepted(state.sourceDocumentId());
        }
        if (state.validationStatus() == SourceDocument.ValidationStatus.REJECTED) {
            throw SourceCommandException.rejectedSource(
                    state.sourceDocumentId(), state.validationFailureCode());
        }
        var existing = state.existingRevision();
        if (existing != null
                && existing.status() != ProcessingRevision.Status.FAILED_RETRYABLE) {
            return resultForExisting(state.sourceDocumentId(), existing);
        }

        Instant startedAt = clock.instant();
        String attemptId = requireSourceDocumentId(processingAttemptIds.get());
        try {
            ProcessingAttempt attempt;
            if (existing == null) {
                String revisionId = requireSourceDocumentId(processingRevisionIds.get());
                attempt = processing.beginInitial(
                        state.sourceDocumentId(),
                        revisionId,
                        attemptId,
                        state.contentSha256().value(),
                        command.parserProfileVersion(),
                        startedAt,
                        startedAt.plus(initialClaimLease));
            } else {
                attempt = processing.retry(
                        state.sourceDocumentId(),
                        existing.sourceProcessingRevisionId(),
                        attemptId,
                        state.contentSha256().value(),
                        command.parserProfileVersion(),
                        startedAt,
                        startedAt.plus(initialClaimLease));
            }
            return new ProcessingResult(
                    state.sourceDocumentId(),
                    attempt.revisionId(),
                    ProcessingRevision.Status.PARSING,
                    false);
        } catch (ProcessingPublicationService.Rejected error) {
            var winner = persistence.findProcessingCommandState(
                            context.workspaceId(),
                            command.sourceDocumentId(),
                            command.parserProfileVersion())
                    .flatMap(value -> java.util.Optional.ofNullable(value.existingRevision()));
            if (winner.isPresent()) {
                return resultForExisting(state.sourceDocumentId(), winner.orElseThrow());
            }
            throw SourceCommandException.processingNotAccepted(state.sourceDocumentId());
        }
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

    public record ProcessingCommand(String sourceDocumentId, String parserProfileVersion) {
        public ProcessingCommand {
            if (sourceDocumentId == null
                    || !SOURCE_DOCUMENT_ID.matcher(sourceDocumentId).matches()) {
                throw new IllegalArgumentException("PROCESSING_SOURCE_DOCUMENT_ID_INVALID");
            }
            if (parserProfileVersion == null
                    || !SOURCE_DOCUMENT_ID.matcher(parserProfileVersion).matches()) {
                throw new IllegalArgumentException("PARSER_PROFILE_VERSION_INVALID");
            }
        }
    }

    private static ProcessingResult resultForExisting(
            String sourceDocumentId,
            SourceCommandPersistencePort.ExistingRevision existing) {
        boolean reused = existing.status() == ProcessingRevision.Status.PARSED
                || existing.status() == ProcessingRevision.Status.PREVIEW_READY
                || existing.status() == ProcessingRevision.Status.FAILED_TERMINAL;
        return new ProcessingResult(
                sourceDocumentId,
                existing.sourceProcessingRevisionId(),
                existing.status(),
                reused);
    }

    public record ProcessingResult(
            String sourceDocumentId,
            String sourceProcessingRevisionId,
            ProcessingRevision.Status status,
            boolean reused) {
        public ProcessingResult {
            Objects.requireNonNull(sourceDocumentId, "sourceDocumentId");
            Objects.requireNonNull(sourceProcessingRevisionId, "sourceProcessingRevisionId");
            Objects.requireNonNull(status, "status");
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
