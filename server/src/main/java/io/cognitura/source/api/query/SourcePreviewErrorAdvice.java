package io.cognitura.source.api.query;

import io.cognitura.source.api.query.SourcePreviewQuery.PreviewException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

@RestControllerAdvice(assignableTypes = SourcePreviewController.class)
public final class SourcePreviewErrorAdvice {

    @ExceptionHandler(PreviewException.class)
    ResponseEntity<ApiError> preview(PreviewException error) {
        return switch (error.code()) {
            case RESOURCE_NOT_FOUND -> response(
                    HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND",
                    "The requested resource was not found.", false, null, null);
            case PAGINATION_INVALID -> response(
                    HttpStatus.BAD_REQUEST, "PAGINATION_INVALID",
                    "The preview pagination request is invalid.", false,
                    error.sourceDocumentId(), error.sourceProcessingRevisionId());
            case PREVIEW_NOT_READY -> response(
                    HttpStatus.CONFLICT, "PREVIEW_NOT_READY",
                    "The exact source revision is not ready for preview.", true,
                    error.sourceDocumentId(), error.sourceProcessingRevisionId());
        };
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    ResponseEntity<ApiError> malformedPagination(MethodArgumentTypeMismatchException error) {
        return response(
                HttpStatus.BAD_REQUEST, "PAGINATION_INVALID",
                "The preview pagination request is invalid.", false, null, null);
    }

    private static ResponseEntity<ApiError> response(
            HttpStatus status,
            String code,
            String message,
            boolean retryable,
            String sourceDocumentId,
            String sourceProcessingRevisionId) {
        return ResponseEntity.status(status).body(new ApiError(
                code, message, retryable, sourceDocumentId, sourceProcessingRevisionId));
    }

    record ApiError(
            String errorCode,
            String message,
            boolean retryable,
            String sourceDocumentId,
            String sourceProcessingRevisionId) {}
}
