package io.cognitura.source.api.query;

import java.util.List;
import java.util.Objects;

public record SourcePreviewPage(
        String sourceDocumentId,
        String sourceProcessingRevisionId,
        String originalFileName,
        String parseCompleteness,
        String publishedBlockSetDigest,
        String omissionsDigest,
        boolean incomplete,
        String partialWarning,
        List<Omission> omissions,
        List<Item> items,
        String nextCursor) {

    public static final String PARTIAL_WARNING =
            "This preview is incomplete. Review all listed omissions before acceptance.";

    public SourcePreviewPage {
        sourceDocumentId = requireText(sourceDocumentId, "SOURCE_DOCUMENT_ID_REQUIRED");
        sourceProcessingRevisionId = requireText(
                sourceProcessingRevisionId, "PROCESSING_REVISION_ID_REQUIRED");
        originalFileName = requireText(originalFileName, "ORIGINAL_FILE_NAME_REQUIRED");
        parseCompleteness = requireText(parseCompleteness, "PARSE_COMPLETENESS_REQUIRED");
        if (!"COMPLETE".equals(parseCompleteness) && !"PARTIAL".equals(parseCompleteness)) {
            throw new IllegalArgumentException("PARSE_COMPLETENESS_INVALID");
        }
        publishedBlockSetDigest = requireHash(
                publishedBlockSetDigest, "PUBLISHED_BLOCK_SET_DIGEST_INVALID");
        omissionsDigest = requireHash(omissionsDigest, "OMISSIONS_DIGEST_INVALID");
        omissions = List.copyOf(Objects.requireNonNull(omissions, "omissions"));
        items = List.copyOf(Objects.requireNonNull(items, "items"));
        if (incomplete != "PARTIAL".equals(parseCompleteness)
                || (incomplete && (!PARTIAL_WARNING.equals(partialWarning) || omissions.isEmpty()))
                || (!incomplete && (partialWarning != null || !omissions.isEmpty()))) {
            throw new IllegalArgumentException("PREVIEW_COMPLETENESS_INVARIANT_INVALID");
        }
    }

    public record Omission(
            String sourcePart,
            int sourceElementIndex,
            String errorCode,
            String userVisibleDescription) {
        public Omission {
            sourcePart = requireText(sourcePart, "OMISSION_SOURCE_PART_REQUIRED");
            if (sourceElementIndex < 0) {
                throw new IllegalArgumentException("OMISSION_SOURCE_ELEMENT_INDEX_INVALID");
            }
            errorCode = requireText(errorCode, "OMISSION_ERROR_CODE_REQUIRED");
            userVisibleDescription = requireText(
                    userVisibleDescription, "OMISSION_DESCRIPTION_REQUIRED");
        }
    }

    public record Item(
            String documentBlockId,
            String documentBlockRef,
            String blockType,
            int sourceOrder,
            List<String> sectionPath,
            Integer pageNumber,
            PageEvidence pageEvidence,
            SourceAnchor sourceAnchor,
            String contentHash,
            SourceBlockPayload payload,
            boolean affectedByOmission) {
        public Item {
            documentBlockId = requireText(documentBlockId, "DOCUMENT_BLOCK_ID_REQUIRED");
            documentBlockRef = requireText(documentBlockRef, "DOCUMENT_BLOCK_REF_REQUIRED");
            blockType = requireText(blockType, "BLOCK_TYPE_REQUIRED");
            if (sourceOrder < 0) throw new IllegalArgumentException("SOURCE_ORDER_INVALID");
            sectionPath = List.copyOf(Objects.requireNonNull(sectionPath, "sectionPath"));
            sourceAnchor = Objects.requireNonNull(sourceAnchor, "sourceAnchor");
            contentHash = requireHash(contentHash, "CONTENT_HASH_INVALID");
            payload = Objects.requireNonNull(payload, "payload");
            boolean payloadMatches = switch (blockType) {
                case "HEADING" -> payload instanceof SourceBlockPayload.Heading;
                case "PARAGRAPH" -> payload instanceof SourceBlockPayload.Paragraph;
                case "LIST" -> payload instanceof SourceBlockPayload.ListItem;
                case "TABLE" -> payload instanceof SourceBlockPayload.Table;
                case "IMAGE" -> payload instanceof SourceBlockPayload.Image;
                default -> false;
            };
            if (!payloadMatches) throw new IllegalArgumentException("BLOCK_PAYLOAD_TYPE_INVALID");
        }
    }

    public record SourceAnchor(
            String anchorKind,
            String parentBlockId,
            Integer textOffset,
            Integer childOrdinal,
            Integer rowIndex,
            Integer columnIndex) {
        public SourceAnchor {
            anchorKind = requireText(anchorKind, "SOURCE_ANCHOR_KIND_REQUIRED");
            boolean valid = switch (anchorKind) {
                case "FLOW" -> parentBlockId == null && textOffset == null
                        && childOrdinal == null && rowIndex == null && columnIndex == null;
                case "PARAGRAPH_INLINE" -> parentBlockId != null && !parentBlockId.isBlank()
                        && nonNegative(textOffset) && nonNegative(childOrdinal)
                        && rowIndex == null && columnIndex == null;
                case "TABLE_CELL_INLINE" -> parentBlockId != null && !parentBlockId.isBlank()
                        && nonNegative(textOffset) && nonNegative(childOrdinal)
                        && nonNegative(rowIndex) && nonNegative(columnIndex);
                default -> false;
            };
            if (!valid) throw new IllegalArgumentException("SOURCE_ANCHOR_INVALID");
        }
    }

    public record PageEvidence(
            String layoutProfileVersion,
            String layoutEngineVersion,
            int pageIndex,
            String evidenceHash) {
        public PageEvidence {
            if (pageIndex < 0) throw new IllegalArgumentException("PAGE_INDEX_INVALID");
            layoutProfileVersion = requireText(
                    layoutProfileVersion, "PAGE_LAYOUT_PROFILE_REQUIRED");
            layoutEngineVersion = requireText(
                    layoutEngineVersion, "PAGE_LAYOUT_ENGINE_REQUIRED");
            evidenceHash = requireHash(evidenceHash, "PAGE_EVIDENCE_HASH_INVALID");
        }
    }

    private static String requireHash(String value, String code) {
        if (value == null || !value.matches("[0-9a-f]{64}")) {
            throw new IllegalArgumentException(code);
        }
        return value;
    }

    private static String requireText(String value, String code) {
        if (value == null || value.isBlank()) throw new IllegalArgumentException(code);
        return value;
    }

    private static boolean nonNegative(Integer value) {
        return value != null && value >= 0;
    }
}
