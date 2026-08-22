package io.cognitura.source.api.acceptance;

import io.cognitura.source.api.acceptance.PartialAcceptanceService.PartialAcceptanceException;
import io.cognitura.source.application.command.TrustedRequestContext;
import io.cognitura.source.application.command.TrustedRequestContextProvider;
import java.util.Objects;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestController
@ConditionalOnProperty(
        prefix = "cognitura.source-command",
        name = "enabled",
        havingValue = "true")
@RequestMapping(
        "/api/v1/source-documents/{sourceDocumentId}/processing-revisions/"
                + "{sourceProcessingRevisionId}/partial-acceptance")
public final class PartialAcceptanceController {

    private final PartialAcceptanceService service;
    private final TrustedRequestContextProvider contexts;

    public PartialAcceptanceController(
            PartialAcceptanceService service, TrustedRequestContextProvider contexts) {
        this.service = Objects.requireNonNull(service, "service");
        this.contexts = Objects.requireNonNull(contexts, "contexts");
    }

    @PostMapping
    public PartialAcceptanceResponse accept(
            @PathVariable String sourceDocumentId,
            @PathVariable String sourceProcessingRevisionId,
            @RequestBody PartialAcceptanceRequest request) {
        TrustedRequestContext context = contexts.currentContext();
        PartialAcceptanceCommand command = request.toCommand(
                sourceDocumentId, sourceProcessingRevisionId);
        return PartialAcceptanceResponse.from(service.accept(context, command));
    }
}

@RestControllerAdvice(assignableTypes = PartialAcceptanceController.class)
final class PartialAcceptanceErrorAdvice {

    @ExceptionHandler(PartialAcceptanceException.class)
    ResponseEntity<ApiError> acceptance(PartialAcceptanceException error) {
        return switch (error.code()) {
            case RESOURCE_NOT_FOUND -> response(
                    HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND",
                    "The requested resource was not found.", false, null, null);
            case PREVIEW_NOT_READY -> response(
                    HttpStatus.CONFLICT, "PREVIEW_NOT_READY",
                    "The exact source revision is not ready for preview.", true,
                    error.sourceDocumentId(), error.sourceProcessingRevisionId());
            case PARTIAL_ACCEPTANCE_CONFLICT -> response(
                    HttpStatus.CONFLICT, "PARTIAL_ACCEPTANCE_CONFLICT",
                    "The partial acceptance command conflicts with the exact revision.", false,
                    error.sourceDocumentId(), error.sourceProcessingRevisionId());
            case CONCURRENT_COMPLETION_CONFLICT -> response(
                    HttpStatus.CONFLICT, "CONCURRENT_COMPLETION_CONFLICT",
                    "The source revision changed concurrently.", true,
                    error.sourceDocumentId(), error.sourceProcessingRevisionId());
        };
    }

    @ExceptionHandler({HttpMessageNotReadableException.class, IllegalArgumentException.class})
    ResponseEntity<ApiError> malformed(Exception error) {
        return response(
                HttpStatus.BAD_REQUEST, "MALFORMED_COMMAND",
                "The command is malformed.", false, null, null);
    }

    private static ResponseEntity<ApiError> response(
            HttpStatus status,
            String code,
            String message,
            boolean retryable,
            String sourceDocumentId,
            String revisionId) {
        return ResponseEntity.status(status).body(new ApiError(
                code, message, retryable, sourceDocumentId, revisionId));
    }

    record ApiError(
            String errorCode,
            String message,
            boolean retryable,
            String sourceDocumentId,
            String sourceProcessingRevisionId) {}
}
