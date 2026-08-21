package io.cognitura.source.api.command;

import io.cognitura.source.application.command.SourceCommandService;
import io.cognitura.source.domain.ProcessingRevision;
import java.time.Instant;

public sealed interface CommandAcceptedResponse
        permits CommandAcceptedResponse.Upload, CommandAcceptedResponse.Processing {

    record Upload(
            String sourceDocumentId,
            String sourceIngestionDisplayStatus,
            String contentSha256,
            Instant receivedAt) implements CommandAcceptedResponse {

        static Upload from(SourceCommandService.UploadResult result) {
            String display = result.status() == io.cognitura.source.domain.SourceDocument
                    .ValidationStatus.REJECTED ? "TERMINAL_FAILURE" : "VALIDATING";
            return new Upload(
                    result.sourceDocumentId(),
                    display,
                    result.contentSha256().value(),
                    result.receivedAt());
        }
    }

    record Processing(
            String sourceDocumentId,
            String sourceProcessingRevisionId,
            String sourceProcessingRevisionStatus,
            String sourceIngestionDisplayStatus,
            String pollLocation,
            boolean reused) implements CommandAcceptedResponse {

        static Processing from(SourceCommandService.ProcessingResult result) {
            return new Processing(
                    result.sourceDocumentId(),
                    result.sourceProcessingRevisionId(),
                    result.status().name(),
                    display(result.status()),
                    "/api/v1/source-documents/" + result.sourceDocumentId()
                            + "/processing-revisions/" + result.sourceProcessingRevisionId(),
                    result.reused());
        }

        private static String display(ProcessingRevision.Status status) {
            return switch (status) {
                case PARSING, PARSED -> "PARSING";
                case PREVIEW_READY -> "PREVIEW_READY";
                case FAILED_RETRYABLE -> "RETRYABLE_FAILURE";
                case FAILED_TERMINAL -> "TERMINAL_FAILURE";
            };
        }
    }
}
