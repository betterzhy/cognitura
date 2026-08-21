package io.cognitura.source.application.processing;

import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.Normalizer;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.regex.Pattern;

public record CandidateBlockSet(
        String sourceDocumentId,
        String revisionId,
        String attemptId,
        ParseCompleteness parseCompleteness,
        PartialAcceptanceStatus partialAcceptanceStatus,
        List<Block> blocks,
        BlockSetDigest omissionsDigest) {

    public enum ParseCompleteness { COMPLETE, PARTIAL }

    public enum PartialAcceptanceStatus { NOT_APPLICABLE, PENDING }

    public CandidateBlockSet {
        sourceDocumentId = requireText(sourceDocumentId, "SOURCE_DOCUMENT_ID_REQUIRED");
        revisionId = requireText(revisionId, "REVISION_ID_REQUIRED");
        attemptId = requireText(attemptId, "ATTEMPT_ID_REQUIRED");
        Objects.requireNonNull(parseCompleteness, "parseCompleteness");
        Objects.requireNonNull(partialAcceptanceStatus, "partialAcceptanceStatus");
        blocks = List.copyOf(Objects.requireNonNull(blocks, "blocks"));
        Objects.requireNonNull(omissionsDigest, "omissionsDigest");
        if (parseCompleteness == ParseCompleteness.COMPLETE
                && (partialAcceptanceStatus != PartialAcceptanceStatus.NOT_APPLICABLE
                        || !omissionsDigest.equals(BlockSetDigest.emptyOmissions()))) {
            throw new IllegalArgumentException("COMPLETE_BLOCK_SET_MUST_HAVE_NO_OMISSIONS");
        }
        if (parseCompleteness == ParseCompleteness.PARTIAL
                && (partialAcceptanceStatus != PartialAcceptanceStatus.PENDING
                        || omissionsDigest.equals(BlockSetDigest.emptyOmissions()))) {
            throw new IllegalArgumentException("PARTIAL_BLOCK_SET_REQUIRES_PENDING_OMISSIONS");
        }
        if (blocks.isEmpty()) {
            throw new IllegalArgumentException("CANDIDATE_BLOCK_SET_MUST_NOT_BE_EMPTY");
        }
        Set<String> blockIds = new HashSet<>();
        for (int index = 0; index < blocks.size(); index++) {
            Block block = Objects.requireNonNull(blocks.get(index), "block");
            if (block.sourceOrder() != index) {
                throw new IllegalArgumentException("CANDIDATE_BLOCK_SOURCE_ORDER_MUST_BE_CONTINUOUS");
            }
            if (!sourceDocumentId.equals(block.sourceDocumentId())
                    || !revisionId.equals(block.revisionId())
                    || !attemptId.equals(block.attemptId())) {
                throw new IllegalArgumentException("CANDIDATE_BLOCK_SCOPE_MISMATCH");
            }
            if (!blockIds.add(block.documentBlockId())) {
                throw new IllegalArgumentException("CANDIDATE_BLOCK_ID_MUST_BE_UNIQUE");
            }
        }
    }

    public record Block(
            String documentBlockId,
            String sourceDocumentId,
            String revisionId,
            String attemptId,
            String blockType,
            int sourceOrder,
            List<String> sectionPath,
            Integer pageNumber,
            String pageEvidence,
            String sourceAnchor,
            String sourcePart,
            long sourceElementIndex,
            String contentHash,
            String canonicalPayload,
            int inlineImagePlaceholderCount,
            int inlineImageBindingCount) {

        private static final Pattern SHA_256 = Pattern.compile("[0-9a-f]{64}");

        public Block {
            documentBlockId = requireText(documentBlockId, "CANDIDATE_BLOCK_ID_REQUIRED");
            sourceDocumentId = requireText(sourceDocumentId, "SOURCE_DOCUMENT_ID_REQUIRED");
            revisionId = requireText(revisionId, "REVISION_ID_REQUIRED");
            attemptId = requireText(attemptId, "ATTEMPT_ID_REQUIRED");
            blockType = requireText(blockType, "CANDIDATE_BLOCK_TYPE_REQUIRED");
            if (sourceOrder < 0 || sourceElementIndex < 0) {
                throw new IllegalArgumentException("CANDIDATE_BLOCK_SOURCE_POSITION_INVALID");
            }
            sectionPath = List.copyOf(Objects.requireNonNull(sectionPath, "sectionPath"));
            for (String section : sectionPath) {
                requireText(section, "CANDIDATE_BLOCK_SECTION_PATH_INVALID");
            }
            if ((pageNumber == null) != (pageEvidence == null)) {
                throw new IllegalArgumentException("CANDIDATE_BLOCK_PAGE_EVIDENCE_MISMATCH");
            }
            if (pageNumber != null && pageNumber <= 0) {
                throw new IllegalArgumentException("CANDIDATE_BLOCK_PAGE_NUMBER_INVALID");
            }
            if (pageEvidence != null) {
                pageEvidence = requireText(pageEvidence, "CANDIDATE_BLOCK_PAGE_EVIDENCE_INVALID");
            }
            sourceAnchor = requireText(sourceAnchor, "CANDIDATE_BLOCK_SOURCE_ANCHOR_REQUIRED");
            sourcePart = requireText(sourcePart, "CANDIDATE_BLOCK_SOURCE_PART_REQUIRED");
            if (sourcePart.startsWith("/") || sourcePart.contains("\\")
                    || sourcePart.contains("../") || sourcePart.equals("..")) {
                throw new IllegalArgumentException("CANDIDATE_BLOCK_SOURCE_PART_INVALID");
            }
            contentHash = requireText(contentHash, "CANDIDATE_BLOCK_CONTENT_HASH_REQUIRED");
            if (!SHA_256.matcher(contentHash).matches()) {
                throw new IllegalArgumentException("CANDIDATE_BLOCK_CONTENT_HASH_INVALID");
            }
            canonicalPayload = requireText(canonicalPayload, "CANDIDATE_BLOCK_CANONICAL_PAYLOAD_REQUIRED");
            if (!Normalizer.isNormalized(canonicalPayload, Normalizer.Form.NFC)) {
                throw new IllegalArgumentException("CANDIDATE_BLOCK_CANONICAL_PAYLOAD_MUST_BE_NFC");
            }
            if (canonicalPayload.indexOf('\0') >= 0) {
                throw new IllegalArgumentException("CANDIDATE_BLOCK_CANONICAL_PAYLOAD_MUST_NOT_CONTAIN_NUL");
            }
            if (!contentHash.equals(sha256Hex(canonicalPayload.getBytes(StandardCharsets.UTF_8)))) {
                throw new IllegalArgumentException("CANDIDATE_BLOCK_CONTENT_HASH_MISMATCH");
            }
            if (inlineImagePlaceholderCount < 0 || inlineImageBindingCount < 0
                    || inlineImagePlaceholderCount != inlineImageBindingCount) {
                throw new IllegalArgumentException("CANDIDATE_BLOCK_IMAGE_BINDING_MUST_BE_BIJECTIVE");
            }
        }

        public static Block create(
                String documentBlockId,
                String sourceDocumentId,
                String revisionId,
                String attemptId,
                String blockType,
                int sourceOrder,
                List<String> sectionPath,
                Integer pageNumber,
                String pageEvidence,
                String sourceAnchor,
                String sourcePart,
                long sourceElementIndex,
                String canonicalPayload,
                int inlineImagePlaceholderCount,
                int inlineImageBindingCount) {
            String payload = requireText(canonicalPayload, "CANDIDATE_BLOCK_CANONICAL_PAYLOAD_REQUIRED");
            return new Block(
                    documentBlockId, sourceDocumentId, revisionId, attemptId, blockType,
                    sourceOrder, sectionPath, pageNumber, pageEvidence, sourceAnchor, sourcePart,
                    sourceElementIndex, sha256Hex(payload.getBytes(StandardCharsets.UTF_8)), payload,
                    inlineImagePlaceholderCount, inlineImageBindingCount);
        }

        public String documentBlockAlias() {
            try {
                ByteArrayOutputStream bytes = new ByteArrayOutputStream();
                try (DataOutputStream output = new DataOutputStream(bytes)) {
                    output.write("cognitura:dbr".getBytes(StandardCharsets.UTF_8));
                    output.writeByte(1);
                    output.writeByte(3);
                    writeText(output, sourceDocumentId);
                    writeText(output, revisionId);
                    writeText(output, documentBlockId);
                }
                return "dbr:" + sha256Hex(bytes.toByteArray());
            } catch (IOException error) {
                throw new IllegalStateException("DOCUMENT_BLOCK_ALIAS_ENCODING_FAILED", error);
            }
        }

        byte[] canonicalBytes() {
            try {
                ByteArrayOutputStream bytes = new ByteArrayOutputStream();
                try (DataOutputStream output = new DataOutputStream(bytes)) {
                    writeText(output, documentBlockId);
                    writeText(output, sourceDocumentId);
                    writeText(output, revisionId);
                    writeText(output, blockType);
                    output.writeInt(sourceOrder);
                    output.writeInt(sectionPath.size());
                    for (String section : sectionPath) writeText(output, section);
                    output.writeBoolean(pageNumber != null);
                    if (pageNumber != null) {
                        output.writeInt(pageNumber);
                        writeText(output, pageEvidence);
                    }
                    writeText(output, sourceAnchor);
                    writeText(output, sourcePart);
                    output.writeLong(sourceElementIndex);
                    writeText(output, contentHash);
                    writeText(output, canonicalPayload);
                    output.writeInt(inlineImagePlaceholderCount);
                    output.writeInt(inlineImageBindingCount);
                }
                return bytes.toByteArray();
            } catch (IOException error) {
                throw new IllegalStateException("CANDIDATE_BLOCK_ENCODING_FAILED", error);
            }
        }
    }

    private static void writeText(DataOutputStream output, String value) throws IOException {
        byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
        output.writeInt(bytes.length);
        output.write(bytes);
    }

    private static String sha256Hex(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException("SHA_256_ALGORITHM_UNAVAILABLE", error);
        }
    }

    private static String requireText(String value, String code) {
        if (value == null || value.isBlank()) throw new IllegalArgumentException(code);
        return value;
    }
}
