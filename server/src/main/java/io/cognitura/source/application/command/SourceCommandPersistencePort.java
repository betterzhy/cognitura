package io.cognitura.source.application.command;

import io.cognitura.source.domain.SourceBinary;
import io.cognitura.source.domain.SourceDocument;
import io.cognitura.source.domain.SourceHash;
import java.time.Instant;
import java.util.Objects;

public interface SourceCommandPersistencePort {

    RegistrationOutcome registerUpload(UploadRegistration registration);

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
}
