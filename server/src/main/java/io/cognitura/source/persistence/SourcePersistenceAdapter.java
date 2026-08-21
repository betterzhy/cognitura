package io.cognitura.source.persistence;

import io.cognitura.source.domain.ProcessingRevision;
import io.cognitura.source.domain.SourceBinary;
import io.cognitura.source.domain.SourceDocument;
import io.cognitura.source.domain.SourceDomainException;
import io.cognitura.source.domain.SourceHash;
import java.sql.SQLException;
import java.util.Objects;
import java.util.Optional;

public final class SourcePersistenceAdapter {

    public enum ErrorCode {
        IDEMPOTENCY_CONFLICT,
        SOURCE_BINARY_HASH_CONFLICT,
        PROCESSING_REVISION_IDENTITY_CONFLICT,
        SOURCE_FACT_CONSTRAINT_VIOLATION
    }

    public static final class SourcePersistenceException extends RuntimeException {

        private final ErrorCode code;

        private SourcePersistenceException(ErrorCode code, RuntimeException cause) {
            super(Objects.requireNonNull(code, "code").name(), cause);
            this.code = code;
        }

        public ErrorCode code() {
            return code;
        }
    }

    private final SourceDocumentMapper mapper;

    public SourcePersistenceAdapter(SourceDocumentMapper mapper) {
        this.mapper = Objects.requireNonNull(mapper, "mapper");
    }

    public void saveBinary(SourceBinary binary) {
        Objects.requireNonNull(binary, "binary");
        executeInsert(() -> mapper.insertSourceBinary(toRow(binary)));
    }

    public void saveDocument(SourceDocument document) {
        Objects.requireNonNull(document, "document");
        executeInsert(() -> mapper.insertSourceDocument(toRow(document)));
    }

    public void saveRevision(ProcessingRevision revision) {
        Objects.requireNonNull(revision, "revision");
        executeInsert(() -> mapper.insertProcessingRevision(toRow(revision)));
    }

    public Optional<SourceBinary> findBinaryByHash(SourceHash contentSha256) {
        Objects.requireNonNull(contentSha256, "contentSha256");
        return Optional.ofNullable(mapper.selectSourceBinaryByHash(contentSha256.value()))
                .map(SourcePersistenceAdapter::toDomain);
    }

    public Optional<SourceDocument> findDocument(String workspaceId, String idempotencyKey) {
        requireText(workspaceId, "WORKSPACE_ID_REQUIRED");
        requireText(idempotencyKey, "IDEMPOTENCY_KEY_REQUIRED");
        return Optional.ofNullable(mapper.selectSourceDocument(workspaceId, idempotencyKey))
                .map(SourcePersistenceAdapter::toDomain);
    }

    public Optional<ProcessingRevision> findRevision(
            String sourceDocumentId, SourceHash contentSha256, String parserProfileVersion) {
        requireText(sourceDocumentId, "SOURCE_DOCUMENT_ID_REQUIRED");
        Objects.requireNonNull(contentSha256, "contentSha256");
        requireText(parserProfileVersion, "PARSER_PROFILE_VERSION_REQUIRED");
        return Optional.ofNullable(mapper.selectProcessingRevision(
                        sourceDocumentId, contentSha256.value(), parserProfileVersion))
                .map(SourcePersistenceAdapter::toDomain);
    }

    private static SourceBinaryRow toRow(SourceBinary binary) {
        return new SourceBinaryRow(
                binary.sourceBinaryId(),
                binary.contentSha256().value(),
                binary.byteLength(),
                binary.mediaType(),
                binary.binaryLocation(),
                binary.createdAt());
    }

    private static SourceDocumentRow toRow(SourceDocument document) {
        return new SourceDocumentRow(
                document.sourceDocumentId(),
                document.workspaceId(),
                document.sourceBinaryId(),
                document.originalFileName(),
                document.mediaType(),
                document.byteLength(),
                document.contentSha256().value(),
                document.receivedAt(),
                document.idempotencyKey(),
                document.validationStatus().name(),
                document.failureCode() == null ? null : document.failureCode().name(),
                document.failureDetail());
    }

    private static ProcessingRevisionRow toRow(ProcessingRevision revision) {
        return new ProcessingRevisionRow(
                revision.sourceProcessingRevisionId(),
                revision.sourceDocumentId(),
                revision.contentSha256().value(),
                revision.parserProfileVersion(),
                revision.status().name(),
                revision.failureCode() == null ? null : revision.failureCode().name(),
                revision.failureDetail(),
                revision.startedAt(),
                revision.completedAt());
    }

    private static SourceBinary toDomain(SourceBinaryRow row) {
        return new SourceBinary(
                row.sourceBinaryId(),
                SourceHash.ofHex(row.contentSha256()),
                row.byteLength(),
                row.mediaType(),
                row.binaryLocation(),
                row.createdAt());
    }

    private static SourceDocument toDomain(SourceDocumentRow row) {
        return new SourceDocument(
                row.sourceDocumentId(),
                row.workspaceId(),
                row.sourceBinaryId(),
                row.originalFileName(),
                row.mediaType(),
                row.byteLength(),
                SourceHash.ofHex(row.contentSha256()),
                row.receivedAt(),
                row.idempotencyKey(),
                SourceDocument.ValidationStatus.valueOf(row.validationStatus()),
                failureCode(row.validationFailureCode()),
                row.validationFailureDetail());
    }

    private static ProcessingRevision toDomain(ProcessingRevisionRow row) {
        return ProcessingRevision.restore(
                row.sourceProcessingRevisionId(),
                row.sourceDocumentId(),
                SourceHash.ofHex(row.contentSha256()),
                row.parserProfileVersion(),
                ProcessingRevision.Status.valueOf(row.revisionStatus()),
                failureCode(row.failureCode()),
                row.failureDetail(),
                row.startedAt(),
                row.completedAt());
    }

    private static SourceDomainException.Code failureCode(String value) {
        return value == null ? null : SourceDomainException.Code.valueOf(value);
    }

    private static void executeInsert(InsertOperation operation) {
        try {
            if (operation.execute() != 1) {
                throw new IllegalStateException("SOURCE_PERSISTENCE_INSERT_COUNT_MUST_BE_ONE");
            }
        } catch (RuntimeException error) {
            throw mapConstraint(error);
        }
    }

    private static RuntimeException mapConstraint(RuntimeException error) {
        SQLException sqlError = findSqlException(error);
        if (sqlError == null || sqlError.getSQLState() == null || !sqlError.getSQLState().startsWith("23")) {
            return error;
        }
        String message = String.valueOf(sqlError.getMessage());
        if (message.contains("uq_source_document_workspace_idempotency")) {
            return new SourcePersistenceException(ErrorCode.IDEMPOTENCY_CONFLICT, error);
        }
        if (message.contains("uq_source_binary_content_sha256")) {
            return new SourcePersistenceException(ErrorCode.SOURCE_BINARY_HASH_CONFLICT, error);
        }
        if (message.contains("uq_source_processing_revision_identity")) {
            return new SourcePersistenceException(
                    ErrorCode.PROCESSING_REVISION_IDENTITY_CONFLICT, error);
        }
        if (isKnownSourceConstraint(message)) {
            return new SourcePersistenceException(ErrorCode.SOURCE_FACT_CONSTRAINT_VIOLATION, error);
        }
        return error;
    }

    private static boolean isKnownSourceConstraint(String message) {
        return message.contains("pk_source_")
                || message.contains("uq_source_")
                || message.contains("fk_source_")
                || message.contains("ck_source_");
    }

    private static SQLException findSqlException(Throwable error) {
        Throwable current = error;
        while (current != null) {
            if (current instanceof SQLException sqlException) {
                return sqlException;
            }
            current = current.getCause();
        }
        return null;
    }

    private static String requireText(String value, String errorCode) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(errorCode);
        }
        return value;
    }

    @FunctionalInterface
    private interface InsertOperation {
        int execute();
    }
}
