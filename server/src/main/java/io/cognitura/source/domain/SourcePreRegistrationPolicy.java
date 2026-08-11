package io.cognitura.source.domain;

import java.time.Instant;
import java.util.Arrays;
import java.util.Objects;
import java.util.Optional;

public final class SourcePreRegistrationPolicy {

    public static final String DOCX_MEDIA_TYPE =
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document";

    private final long maximumRawBytes;

    public SourcePreRegistrationPolicy(long maximumRawBytes) {
        if (maximumRawBytes <= 0) {
            throw new IllegalArgumentException("MAXIMUM_RAW_BYTES_MUST_BE_POSITIVE");
        }
        this.maximumRawBytes = maximumRawBytes;
    }

    public RegistrationDecision preRegister(
            RegistrationRequest request, ExistingFacts existingFacts) {
        Objects.requireNonNull(request, "request");
        Objects.requireNonNull(existingFacts, "existingFacts");

        if (!DOCX_MEDIA_TYPE.equals(request.mediaType())) {
            throw failure(
                    SourceDomainException.Code.UNSUPPORTED_MEDIA_TYPE,
                    "Wave 1 accepts only the canonical DOCX media type");
        }

        byte[] rawBytes = request.rawBytes();
        if (rawBytes.length == 0) {
            throw failure(
                    SourceDomainException.Code.EMPTY_SOURCE_FILE,
                    "source bytes must not be empty");
        }
        if (rawBytes.length > maximumRawBytes) {
            throw failure(
                    SourceDomainException.Code.SOURCE_SIZE_LIMIT,
                    "source bytes exceed the configured raw limit");
        }

        SourceHash actualHash = SourceHash.sha256(rawBytes);
        if (!actualHash.equals(request.declaredContentSha256())) {
            throw failure(
                    SourceDomainException.Code.SOURCE_HASH_MISMATCH,
                    "declared SHA-256 does not match isolated source bytes");
        }

        Optional<SourceDocument> existingById = existingFacts.sourceDocumentById();
        Optional<SourceDocument> existingByKey = existingFacts.sourceDocumentByIdempotencyKey();
        if (existingById.isPresent()
                && existingByKey.isPresent()
                && !existingById.orElseThrow().sourceDocumentId()
                        .equals(existingByKey.orElseThrow().sourceDocumentId())) {
            throw new IllegalArgumentException(
                    "SOURCE_DOCUMENT_AND_IDEMPOTENCY_FACTS_CONFLICT");
        }
        if (existingByKey.isPresent()) {
            SourceDocument existing = existingByKey.orElseThrow();
            if (!existing.workspaceId().equals(request.workspaceId())
                    || !existing.idempotencyKey().equals(request.idempotencyKey())) {
                throw new IllegalArgumentException("IDEMPOTENCY_SCOPE_LOOKUP_MISMATCH");
            }
            if (!existing.contentSha256().equals(actualHash)) {
                throw failure(
                        SourceDomainException.Code.IDEMPOTENCY_CONFLICT,
                        "idempotency key is already bound to different source bytes");
            }
            SourceBinary binary = requireExistingBinary(existing, existingFacts.sourceBinaryByHash());
            return new RegistrationDecision(existing, binary, false, false);
        }
        if (existingById.isPresent()) {
            SourceDocument existing = existingById.orElseThrow();
            if (!existing.sourceDocumentId().equals(request.sourceDocumentId())) {
                throw new IllegalArgumentException("SOURCE_DOCUMENT_ID_LOOKUP_MISMATCH");
            }
            if (!existing.workspaceId().equals(request.workspaceId())) {
                throw new IllegalArgumentException("SOURCE_DOCUMENT_WORKSPACE_IDENTITY_CONFLICT");
            }
            if (!sameImmutableUpload(existing, request, actualHash)) {
                throw new IllegalArgumentException("SOURCE_DOCUMENT_IMMUTABLE_FACT_CONFLICT");
            }
            SourceBinary binary = requireExistingBinary(existing, existingFacts.sourceBinaryByHash());
            return new RegistrationDecision(existing, binary, false, false);
        }

        SourceBinary binary;
        boolean createdBinary;
        if (existingFacts.sourceBinaryByHash().isPresent()) {
            binary = existingFacts.sourceBinaryByHash().orElseThrow();
            requireMatchingBinary(binary, actualHash, rawBytes.length, request.mediaType());
            createdBinary = false;
        } else {
            binary = new SourceBinary(
                    request.newSourceBinaryId(),
                    actualHash,
                    rawBytes.length,
                    request.mediaType(),
                    request.binaryLocation(),
                    request.receivedAt());
            createdBinary = true;
        }

        SourceDocument document = SourceDocument.received(
                request.sourceDocumentId(),
                request.workspaceId(),
                binary.sourceBinaryId(),
                request.originalFileName(),
                request.mediaType(),
                rawBytes.length,
                actualHash,
                request.receivedAt(),
                request.idempotencyKey());
        return new RegistrationDecision(document, binary, true, createdBinary);
    }

    public record RegistrationRequest(
            String sourceDocumentId,
            String workspaceId,
            String newSourceBinaryId,
            String originalFileName,
            String mediaType,
            byte[] rawBytes,
            SourceHash declaredContentSha256,
            String idempotencyKey,
            String binaryLocation,
            Instant receivedAt) {

        public RegistrationRequest {
            rawBytes = Arrays.copyOf(Objects.requireNonNull(rawBytes, "rawBytes"), rawBytes.length);
            Objects.requireNonNull(declaredContentSha256, "declaredContentSha256");
            Objects.requireNonNull(receivedAt, "receivedAt");
        }

        @Override
        public byte[] rawBytes() {
            return Arrays.copyOf(rawBytes, rawBytes.length);
        }
    }

    public record ExistingFacts(
            Optional<SourceDocument> sourceDocumentById,
            Optional<SourceDocument> sourceDocumentByIdempotencyKey,
            Optional<SourceBinary> sourceBinaryByHash) {

        public ExistingFacts {
            Objects.requireNonNull(sourceDocumentById, "sourceDocumentById");
            Objects.requireNonNull(sourceDocumentByIdempotencyKey, "sourceDocumentByIdempotencyKey");
            Objects.requireNonNull(sourceBinaryByHash, "sourceBinaryByHash");
        }

        public static ExistingFacts empty() {
            return new ExistingFacts(Optional.empty(), Optional.empty(), Optional.empty());
        }
    }

    public record RegistrationDecision(
            SourceDocument sourceDocument,
            SourceBinary sourceBinary,
            boolean createdSourceDocument,
            boolean createdSourceBinary) {

        public RegistrationDecision {
            Objects.requireNonNull(sourceDocument, "sourceDocument");
            Objects.requireNonNull(sourceBinary, "sourceBinary");
            if (!sourceDocument.sourceBinaryId().equals(sourceBinary.sourceBinaryId())
                    || !sourceDocument.contentSha256().equals(sourceBinary.contentSha256())) {
                throw new IllegalArgumentException("REGISTRATION_FACTS_MUST_SHARE_BINARY_IDENTITY");
            }
            if (!createdSourceDocument && createdSourceBinary) {
                throw new IllegalArgumentException("REPLAY_CANNOT_CREATE_SOURCE_BINARY");
            }
        }
    }

    private static boolean sameImmutableUpload(
            SourceDocument existing, RegistrationRequest request, SourceHash actualHash) {
        return existing.contentSha256().equals(actualHash)
                && existing.idempotencyKey().equals(request.idempotencyKey())
                && existing.mediaType().equals(request.mediaType())
                && existing.byteLength() == request.rawBytes().length;
    }

    private static SourceBinary requireExistingBinary(
            SourceDocument document, Optional<SourceBinary> existingBinary) {
        SourceBinary binary = existingBinary.orElseThrow(
                () -> new IllegalArgumentException("EXISTING_SOURCE_BINARY_REQUIRED"));
        requireMatchingBinary(
                binary, document.contentSha256(), document.byteLength(), document.mediaType());
        if (!document.sourceBinaryId().equals(binary.sourceBinaryId())) {
            throw new IllegalArgumentException("SOURCE_DOCUMENT_BINARY_IDENTITY_CONFLICT");
        }
        return binary;
    }

    private static void requireMatchingBinary(
            SourceBinary binary, SourceHash hash, long byteLength, String mediaType) {
        if (!binary.contentSha256().equals(hash)
                || binary.byteLength() != byteLength
                || !binary.mediaType().equals(mediaType)) {
            throw new IllegalArgumentException("SOURCE_BINARY_IMMUTABLE_FACT_CONFLICT");
        }
    }

    private static SourceDomainException failure(
            SourceDomainException.Code code, String detail) {
        return new SourceDomainException(code, detail);
    }
}
