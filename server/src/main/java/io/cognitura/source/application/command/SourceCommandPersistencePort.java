package io.cognitura.source.application.command;

import io.cognitura.source.domain.SourceBinary;
import io.cognitura.source.domain.SourceDocument;
import io.cognitura.source.domain.SourceHash;
import io.cognitura.source.domain.ProcessingRevision;
import java.time.Instant;
import java.util.Objects;
import java.util.Optional;

public interface SourceCommandPersistencePort {

    RegistrationOutcome registerUpload(UploadRegistration registration);

    Optional<ProcessingCommandState> findProcessingCommandState(
            String workspaceId, String sourceDocumentId, String parserProfileVersion);

    record UploadRegistration(
            String sourceDocumentId,
            String workspaceId,
            String sourceBinaryId,
            String originalFileName,
            String mediaType,
            long byteLength,
            SourceHash contentSha256,
            String idempotencyKey,
            String binaryLocation,
            Instant receivedAt) {

        public UploadRegistration {
            Objects.requireNonNull(contentSha256, "contentSha256");
            Objects.requireNonNull(receivedAt, "receivedAt");
        }
    }

    record RegistrationOutcome(
            SourceDocument sourceDocument,
            SourceBinary sourceBinary,
            boolean createdSourceDocument,
            boolean createdSourceBinary) {

        public RegistrationOutcome {
            Objects.requireNonNull(sourceDocument, "sourceDocument");
            Objects.requireNonNull(sourceBinary, "sourceBinary");
        }
    }

    record ProcessingCommandState(
            String sourceDocumentId,
            SourceHash contentSha256,
            SourceDocument.ValidationStatus validationStatus,
            String validationFailureCode,
            ExistingRevision existingRevision) {

        public ProcessingCommandState {
            Objects.requireNonNull(sourceDocumentId, "sourceDocumentId");
            Objects.requireNonNull(contentSha256, "contentSha256");
            Objects.requireNonNull(validationStatus, "validationStatus");
            boolean rejected = validationStatus == SourceDocument.ValidationStatus.REJECTED;
            boolean validRejectedCode = "DOCX_SECURITY_REJECTED".equals(validationFailureCode)
                    || "DOCX_FORMAT_INVALID".equals(validationFailureCode);
            if (rejected != validRejectedCode) {
                throw new IllegalArgumentException(
                        "PROCESSING_COMMAND_SOURCE_FAILURE_FACTS_INVALID");
            }
        }
    }

    record ExistingRevision(
            String sourceProcessingRevisionId,
            ProcessingRevision.Status status) {

        public ExistingRevision {
            Objects.requireNonNull(sourceProcessingRevisionId, "sourceProcessingRevisionId");
            Objects.requireNonNull(status, "status");
        }
    }
}
