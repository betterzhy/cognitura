package io.cognitura.source.application.processing;

import io.cognitura.source.domain.SourceDomainException;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;
import java.util.regex.Pattern;

public interface ProcessingPublicationPort {

    Pattern SHA_256 = Pattern.compile("[0-9a-f]{64}");
    Pattern ARTIFACT_ID = Pattern.compile("[A-Za-z0-9][A-Za-z0-9._:-]{0,127}");
    Pattern SCHEMA_URN = Pattern.compile("urn:cognitura:schema:.*");

    enum Outcome {
        APPLIED,
        ACTIVE_ATTEMPT_EXISTS,
        RETRY_NOT_ALLOWED,
        STALE_FENCE,
        STALE_LEASE,
        BLOCK_SET_MISMATCH,
        ALREADY_PUBLISHED
    }

    record BeginAttempt(
            String sourceDocumentId,
            String revisionId,
            String attemptId,
            String contentSha256,
            String parserProfileVersion,
            Instant startedAt,
            Instant claimDeadline) {

        public BeginAttempt {
            sourceDocumentId = requireText(sourceDocumentId, "SOURCE_DOCUMENT_ID_REQUIRED");
            revisionId = requireText(revisionId, "REVISION_ID_REQUIRED");
            attemptId = requireText(attemptId, "ATTEMPT_ID_REQUIRED");
            contentSha256 = requireText(contentSha256, "CONTENT_SHA256_REQUIRED");
            if (!SHA_256.matcher(contentSha256).matches()) {
                throw new IllegalArgumentException("CONTENT_SHA256_MUST_BE_64_LOWERCASE_HEX");
            }
            parserProfileVersion = requireText(
                    parserProfileVersion, "PARSER_PROFILE_VERSION_REQUIRED");
            Objects.requireNonNull(startedAt, "startedAt");
            Objects.requireNonNull(claimDeadline, "claimDeadline");
            if (!claimDeadline.isAfter(startedAt)) {
                throw new IllegalArgumentException("CLAIM_DEADLINE_MUST_FOLLOW_ATTEMPT_START");
            }
        }
    }

    record BeginResult(Outcome outcome, ProcessingAttempt attempt) {

        public BeginResult {
            Objects.requireNonNull(outcome, "outcome");
            if ((outcome == Outcome.APPLIED) != (attempt != null)) {
                throw new IllegalArgumentException("BEGIN_RESULT_ATTEMPT_MUST_MATCH_OUTCOME");
            }
        }

        public static BeginResult applied(ProcessingAttempt attempt) {
            return new BeginResult(Outcome.APPLIED, Objects.requireNonNull(attempt, "attempt"));
        }

        public static BeginResult rejected(Outcome outcome) {
            if (outcome == Outcome.APPLIED) {
                throw new IllegalArgumentException("REJECTED_BEGIN_RESULT_CANNOT_BE_APPLIED");
            }
            return new BeginResult(outcome, null);
        }
    }

    record Failure(
            ProcessingAttempt.Status terminalStatus,
            SourceDomainException.Code failureCode,
            String failureDetail,
            Instant completedAt) {

        public Failure {
            if (terminalStatus != ProcessingAttempt.Status.FAILED_RETRYABLE
                    && terminalStatus != ProcessingAttempt.Status.FAILED_TERMINAL) {
                throw new IllegalArgumentException("FAILURE_STATUS_MUST_BE_TERMINAL_FAILURE");
            }
            Objects.requireNonNull(failureCode, "failureCode");
            if (terminalStatus == ProcessingAttempt.Status.FAILED_RETRYABLE
                    && failureCode != SourceDomainException.Code.PARSER_RETRYABLE_FAILURE) {
                throw new IllegalArgumentException(
                        "RETRYABLE_FAILURE_REQUIRES_PARSER_RETRYABLE_FAILURE");
            }
            if (terminalStatus == ProcessingAttempt.Status.FAILED_TERMINAL
                    && failureCode != SourceDomainException.Code.PARSER_TERMINAL_FAILURE
                    && failureCode != SourceDomainException.Code.DOCX_FORMAT_INVALID) {
                throw new IllegalArgumentException(
                        "TERMINAL_FAILURE_REQUIRES_TERMINAL_FAILURE_CODE");
            }
            failureDetail = requireText(failureDetail, "FAILURE_DETAIL_REQUIRED");
            Objects.requireNonNull(completedAt, "completedAt");
        }
    }

    record GenerationStageRecord(
            String schemaVersion,
            String runId,
            String stage,
            String inputHash,
            String promptVersion,
            String model,
            List<String> sourceBlockRefs,
            OutputKind outputKind,
            String outputSchemaId,
            BlockSetReference structuredOutput,
            BlockSetDigest outputHash,
            ValidationResult validationResult,
            GenerationStatus generationStatus,
            long retryCount,
            List<String> retryScopeRefs,
            FailureProjection failure) {

        public enum OutputKind { INTERMEDIATE, NONE }

        public enum GenerationStatus { SUCCEEDED, FAILED }

        public record BlockSetReference(String blockSetRef) {
            public BlockSetReference {
                blockSetRef = requireText(blockSetRef, "BLOCK_SET_REFERENCE_REQUIRED");
                if (!blockSetRef.matches("block-set:[0-9a-f]{64}")) {
                    throw new IllegalArgumentException("BLOCK_SET_REFERENCE_INVALID");
                }
            }

            public String canonicalJson() {
                return "{\"blockSetRef\":\"" + escapeJson(blockSetRef) + "\"}";
            }
        }

        public record ValidationError(
                String code, String instancePath, String schemaPath, String message) {
            public ValidationError {
                code = requireText(code, "VALIDATION_ERROR_CODE_REQUIRED");
                Objects.requireNonNull(instancePath, "instancePath");
                Objects.requireNonNull(schemaPath, "schemaPath");
                message = requireText(message, "VALIDATION_ERROR_MESSAGE_REQUIRED");
            }

            String canonicalJson() {
                return "{\"code\":\"" + escapeJson(code)
                        + "\",\"instancePath\":\"" + escapeJson(instancePath)
                        + "\",\"schemaPath\":\"" + escapeJson(schemaPath)
                        + "\",\"message\":\"" + escapeJson(message) + "\"}";
            }
        }

        public record ValidationResult(
                ValidationStatus status,
                List<String> validatedSchemaIds,
                List<ValidationError> errors) {

            public enum ValidationStatus { NOT_RUN, PASS, FAIL }

            public ValidationResult {
                Objects.requireNonNull(status, "status");
                validatedSchemaIds = List.copyOf(
                        Objects.requireNonNull(validatedSchemaIds, "validatedSchemaIds"));
                errors = List.copyOf(Objects.requireNonNull(errors, "errors"));
                if (validatedSchemaIds.stream().distinct().count() != validatedSchemaIds.size()) {
                    throw new IllegalArgumentException("VALIDATED_SCHEMA_IDS_MUST_BE_UNIQUE");
                }
                if (validatedSchemaIds.stream().anyMatch(
                        value -> value == null || !SCHEMA_URN.matcher(value).matches())) {
                    throw new IllegalArgumentException("VALIDATED_SCHEMA_ID_INVALID");
                }
                if (status == ValidationStatus.PASS && !errors.isEmpty()) {
                    throw new IllegalArgumentException("PASS_VALIDATION_ERRORS_FORBIDDEN");
                }
                if (status == ValidationStatus.FAIL && errors.isEmpty()) {
                    throw new IllegalArgumentException("FAIL_VALIDATION_ERROR_REQUIRED");
                }
                if (status == ValidationStatus.NOT_RUN
                        && (!validatedSchemaIds.isEmpty() || !errors.isEmpty())) {
                    throw new IllegalArgumentException("NOT_RUN_VALIDATION_DETAILS_FORBIDDEN");
                }
            }

            public String canonicalJson() {
                return "{\"status\":\"" + status.name()
                        + "\",\"validatedSchemaIds\":["
                        + validatedSchemaIds.stream()
                                .map(value -> "\"" + escapeJson(value) + "\"")
                                .reduce((left, right) -> left + "," + right).orElse("")
                        + "],\"errors\":["
                        + errors.stream().map(ValidationError::canonicalJson)
                                .reduce((left, right) -> left + "," + right).orElse("")
                        + "]}";
            }
        }

        public record FailureProjection(
                SourceDomainException.Code code,
                String message,
                boolean retryable,
                List<String> failedScopeRefs) {
            public FailureProjection {
                Objects.requireNonNull(code, "code");
                message = requireText(message, "STAGE_FAILURE_MESSAGE_REQUIRED");
                failedScopeRefs = List.copyOf(
                        Objects.requireNonNull(failedScopeRefs, "failedScopeRefs"));
                if (failedScopeRefs.isEmpty()
                        || failedScopeRefs.stream().distinct().count() != failedScopeRefs.size()) {
                    throw new IllegalArgumentException("STAGE_FAILURE_SCOPE_INVALID");
                }
                if (failedScopeRefs.stream().anyMatch(
                        value -> value == null || !ARTIFACT_ID.matcher(value).matches())) {
                    throw new IllegalArgumentException("STAGE_FAILURE_SCOPE_INVALID");
                }
                if (retryable != code.retryable()) {
                    throw new IllegalArgumentException("STAGE_FAILURE_RETRYABILITY_MISMATCH");
                }
            }
        }

        public GenerationStageRecord {
            schemaVersion = requireText(schemaVersion, "STAGE_SCHEMA_VERSION_REQUIRED");
            if (!"2.0.0".equals(schemaVersion)) {
                throw new IllegalArgumentException("STAGE_SCHEMA_VERSION_MUST_BE_2_0_0");
            }
            runId = requireText(runId, "STAGE_RUN_ID_REQUIRED");
            if (!ARTIFACT_ID.matcher(runId).matches()) {
                throw new IllegalArgumentException("STAGE_RUN_ID_INVALID");
            }
            stage = requireText(stage, "STAGE_NAME_REQUIRED");
            if (!"SOURCE_PARSING".equals(stage)) {
                throw new IllegalArgumentException("SOURCE_PARSING_STAGE_REQUIRED");
            }
            inputHash = requireText(inputHash, "STAGE_INPUT_HASH_REQUIRED");
            if (!SHA_256.matcher(inputHash).matches()) {
                throw new IllegalArgumentException("STAGE_INPUT_HASH_MUST_BE_SHA256");
            }
            promptVersion = requireText(promptVersion, "STAGE_PROMPT_VERSION_REQUIRED");
            model = requireText(model, "STAGE_MODEL_REQUIRED");
            if (!"NOT_APPLICABLE".equals(promptVersion) || !"NOT_APPLICABLE".equals(model)) {
                throw new IllegalArgumentException("SOURCE_PARSING_MODEL_FIELDS_INVALID");
            }
            sourceBlockRefs = List.copyOf(
                    Objects.requireNonNull(sourceBlockRefs, "sourceBlockRefs"));
            if (sourceBlockRefs.stream().distinct().count() != sourceBlockRefs.size()) {
                throw new IllegalArgumentException("SOURCE_BLOCK_REFS_MUST_BE_UNIQUE");
            }
            if (!sourceBlockRefs.isEmpty()) {
                throw new IllegalArgumentException("SOURCE_PARSING_BLOCK_REFS_MUST_BE_EMPTY");
            }
            Objects.requireNonNull(outputKind, "outputKind");
            Objects.requireNonNull(validationResult, "validationResult");
            Objects.requireNonNull(generationStatus, "generationStatus");
            if (retryCount < 0) throw new IllegalArgumentException("STAGE_RETRY_COUNT_INVALID");
            retryScopeRefs = List.copyOf(
                    Objects.requireNonNull(retryScopeRefs, "retryScopeRefs"));
            if (retryScopeRefs.stream().distinct().count() != retryScopeRefs.size()) {
                throw new IllegalArgumentException("RETRY_SCOPE_REFS_MUST_BE_UNIQUE");
            }
            if (retryScopeRefs.stream().anyMatch(
                    value -> value == null || !ARTIFACT_ID.matcher(value).matches())) {
                throw new IllegalArgumentException("RETRY_SCOPE_REF_INVALID");
            }
            if (generationStatus == GenerationStatus.SUCCEEDED) {
                if (outputKind != OutputKind.INTERMEDIATE
                        || outputSchemaId != null
                        || structuredOutput == null
                        || outputHash == null
                        || !structuredOutput.blockSetRef()
                                .equals("block-set:" + outputHash.value())
                        || validationResult.status() != ValidationResult.ValidationStatus.PASS
                        || failure != null
                        || !retryScopeRefs.isEmpty()) {
                    throw new IllegalArgumentException("SUCCESS_STAGE_PROJECTION_INVALID");
                }
            } else if (outputKind != OutputKind.NONE
                    || outputSchemaId != null
                    || structuredOutput != null
                    || outputHash != null
                    || validationResult.status() != ValidationResult.ValidationStatus.FAIL
                    || failure == null) {
                throw new IllegalArgumentException("FAILED_STAGE_PROJECTION_INVALID");
            }
            if (generationStatus == GenerationStatus.FAILED) {
                if (validationResult.errors().size() != 1
                        || !validationResult.errors().getFirst().code()
                                .equals(failure.code().name())
                        || !validationResult.errors().getFirst().message()
                                .equals(failure.message())
                        || (failure.retryable()
                                ? !retryScopeRefs.equals(failure.failedScopeRefs())
                                : !retryScopeRefs.isEmpty())) {
                    throw new IllegalArgumentException("FAILED_STAGE_PROJECTION_INVALID");
                }
            }
        }

        public static GenerationStageRecord succeeded(
                String sourceDocumentId,
                String contentSha256,
                String parserProfileVersion,
                String revisionId,
                String attemptId,
                long attemptNumber,
                BlockSetDigest digest) {
            Objects.requireNonNull(digest, "digest");
            return new GenerationStageRecord(
                    "2.0.0", attemptId, "SOURCE_PARSING",
                    inputHash(sourceDocumentId, contentSha256, parserProfileVersion),
                    "NOT_APPLICABLE", "NOT_APPLICABLE", List.of(),
                    OutputKind.INTERMEDIATE, null,
                    new BlockSetReference("block-set:" + digest.value()), digest,
                    new ValidationResult(
                            ValidationResult.ValidationStatus.PASS, List.of(), List.of()),
                    GenerationStatus.SUCCEEDED,
                    attemptNumber - 1, List.of(), null);
        }

        public static GenerationStageRecord failed(
                String sourceDocumentId,
                String contentSha256,
                String parserProfileVersion,
                String revisionId,
                String attemptId,
                long attemptNumber,
                SourceDomainException.Code code,
                String detail) {
            Objects.requireNonNull(code, "code");
            List<String> retryScope = code.retryable() ? List.of(revisionId) : List.of();
            return new GenerationStageRecord(
                    "2.0.0", attemptId, "SOURCE_PARSING",
                    inputHash(sourceDocumentId, contentSha256, parserProfileVersion),
                    "NOT_APPLICABLE", "NOT_APPLICABLE", List.of(),
                    OutputKind.NONE, null, null, null,
                    new ValidationResult(
                            ValidationResult.ValidationStatus.FAIL,
                            List.of(),
                            List.of(new ValidationError(code.name(), "", "", detail))),
                    GenerationStatus.FAILED,
                    attemptNumber - 1, retryScope,
                    new FailureProjection(code, detail, code.retryable(), List.of(revisionId)));
        }

        public static String inputHash(
                String sourceDocumentId, String contentSha256, String parserProfileVersion) {
            String documentId = requireText(sourceDocumentId, "SOURCE_DOCUMENT_ID_REQUIRED");
            String contentHash = requireText(contentSha256, "CONTENT_SHA256_REQUIRED");
            if (!SHA_256.matcher(contentHash).matches()) {
                throw new IllegalArgumentException("CONTENT_SHA256_MUST_BE_64_LOWERCASE_HEX");
            }
            String profile = requireText(parserProfileVersion, "PARSER_PROFILE_VERSION_REQUIRED");
            try {
                ByteArrayOutputStream bytes = new ByteArrayOutputStream();
                try (DataOutputStream output = new DataOutputStream(bytes)) {
                    output.write("cognitura:source-parsing-input".getBytes(StandardCharsets.UTF_8));
                    output.writeByte(1);
                    output.writeByte(3);
                    writeText(output, documentId);
                    writeText(output, contentHash);
                    writeText(output, profile);
                }
                return HexFormat.of().formatHex(
                        MessageDigest.getInstance("SHA-256").digest(bytes.toByteArray()));
            } catch (IOException error) {
                throw new IllegalStateException("STAGE_INPUT_HASH_ENCODING_FAILED", error);
            } catch (NoSuchAlgorithmException error) {
                throw new IllegalStateException("SHA_256_ALGORITHM_UNAVAILABLE", error);
            }
        }

        private static void writeText(DataOutputStream output, String value) throws IOException {
            byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
            output.writeInt(bytes.length);
            output.write(bytes);
        }

        private static String escapeJson(String value) {
            StringBuilder escaped = new StringBuilder(value.length());
            for (int index = 0; index < value.length(); index++) {
                char character = value.charAt(index);
                switch (character) {
                    case '\"' -> escaped.append("\\\"");
                    case '\\' -> escaped.append("\\\\");
                    case '\b' -> escaped.append("\\b");
                    case '\f' -> escaped.append("\\f");
                    case '\n' -> escaped.append("\\n");
                    case '\r' -> escaped.append("\\r");
                    case '\t' -> escaped.append("\\t");
                    default -> {
                        if (character < 0x20) {
                            escaped.append(String.format("\\u%04x", (int) character));
                        } else {
                            escaped.append(character);
                        }
                    }
                }
            }
            return escaped.toString();
        }
    }

    final class StorageException extends RuntimeException {

        public StorageException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    BeginResult beginInitial(BeginAttempt command);

    BeginResult beginRetry(BeginAttempt command);

    Outcome claim(AttemptFence fence, AttemptLease lease, Instant observedAt);

    Outcome heartbeat(AttemptFence fence, AttemptLease lease, Instant observedAt);

    Outcome timeout(AttemptFence fence, AttemptLease lease, Instant timedOutAt);

    Outcome stage(AttemptFence fence, CandidateBlockSet blockSet);

    Outcome publish(
            AttemptFence fence,
            CandidateBlockSet blockSet,
            BlockSetDigest blockSetDigest,
            Instant completedAt);

    Outcome fail(AttemptFence fence, Failure failure);

    private static String requireText(String value, String code) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(code);
        }
        return value;
    }
}
