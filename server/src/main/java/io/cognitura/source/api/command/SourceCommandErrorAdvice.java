package io.cognitura.source.api.command;

import io.cognitura.source.application.command.SourceCommandException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.support.MissingServletRequestPartException;

@RestControllerAdvice
public final class SourceCommandErrorAdvice {

    @ExceptionHandler(SourceCommandException.class)
    ResponseEntity<ApiError> sourceCommand(SourceCommandException error) {
        return switch (error.code()) {
            case RESOURCE_NOT_FOUND -> response(
                    HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND",
                    "The requested resource was not found.", false, null, null);
            case IDEMPOTENCY_CONFLICT -> response(
                    HttpStatus.CONFLICT, "IDEMPOTENCY_CONFLICT",
                    "The idempotency key is already bound to different content.",
                    false, error.sourceDocumentId(), null);
            case SOURCE_NOT_ACCEPTED_YET -> response(
                    HttpStatus.SERVICE_UNAVAILABLE, "SOURCE_NOT_ACCEPTED_YET",
                    "The source has not been accepted for processing yet.",
                    true, error.sourceDocumentId(), null);
            case PROCESSING_COMMAND_NOT_ACCEPTED, PERSISTENCE_FAILURE -> response(
                    HttpStatus.SERVICE_UNAVAILABLE, "PROCESSING_COMMAND_NOT_ACCEPTED",
                    "The processing command was not accepted.",
                    true, error.sourceDocumentId(), null);
            case DOCX_SECURITY_REJECTED -> response(
                    HttpStatus.UNPROCESSABLE_ENTITY, "DOCX_SECURITY_REJECTED",
                    "The source document was rejected by the security policy.",
                    false, error.sourceDocumentId(), null);
            case DOCX_FORMAT_INVALID -> response(
                    HttpStatus.UNPROCESSABLE_ENTITY, "DOCX_FORMAT_INVALID",
                    "The source document format is invalid.",
                    false, error.sourceDocumentId(), null);
        };
    }

    @ExceptionHandler({
        HttpMessageNotReadableException.class,
        MissingServletRequestPartException.class,
        MissingServletRequestParameterException.class
    })
    ResponseEntity<ApiError> malformed(Exception error) {
        return response(
                HttpStatus.BAD_REQUEST, "MALFORMED_COMMAND",
                "The command is malformed.", false, null, null);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    ResponseEntity<ApiError> invalid(IllegalArgumentException error) {
        String code = error.getMessage();
        if ("SOURCE_BINARY_LIMIT_EXCEEDED".equals(code)) {
            return response(
                    HttpStatus.PAYLOAD_TOO_LARGE, "SOURCE_SIZE_LIMIT",
                    "The source file exceeds the allowed size.", false, null, null);
        }
        if ("SOURCE_BINARY_MEDIA_TYPE_UNSUPPORTED".equals(code)) {
            return response(
                    HttpStatus.UNSUPPORTED_MEDIA_TYPE, "UNSUPPORTED_MEDIA_TYPE",
                    "The source media type is unsupported.", false, null, null);
        }
        if ("SOURCE_BINARY_EMPTY".equals(code)) {
            return response(
                    HttpStatus.UNPROCESSABLE_ENTITY, "EMPTY_SOURCE_FILE",
                    "The source file is empty.", false, null, null);
        }
        if ("SOURCE_BINARY_DECLARED_HASH_MISMATCH".equals(code)) {
            return response(
                    HttpStatus.UNPROCESSABLE_ENTITY, "SOURCE_HASH_MISMATCH",
                    "The source hash does not match the uploaded bytes.", false, null, null);
        }
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
            String sourceProcessingRevisionId) {
        return ResponseEntity.status(status).body(new ApiError(
                code, message, retryable, sourceDocumentId, sourceProcessingRevisionId));
    }

    record ApiError(
            String errorCode,
            String message,
            boolean retryable,
            String sourceDocumentId,
            String sourceProcessingRevisionId) {
    }
}
