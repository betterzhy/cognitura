package io.cognitura.source.application.processing;

import io.cognitura.source.docx.image.ImageAnchor;
import io.cognitura.source.docx.image.ExternalRelationshipLiteral;
import io.cognitura.source.docx.image.ImageRelationshipProjector;
import io.cognitura.source.docx.table.TableBlockCandidate;
import io.cognitura.source.docx.table.TableCellCandidate;
import io.cognitura.source.docx.text.DocumentBlockCandidate;
import io.cognitura.source.docx.text.ListSemantics;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

public final class CandidateBlockSet {

    private static final String IMAGE_RELATIONSHIP_TYPE =
            "http://schemas.openxmlformats.org/officeDocument/2006/relationships/image";
    private static final String EXTERNAL_DISCLOSURE =
            "EXTERNAL_RELATIONSHIP_NOT_DEREFERENCED";

    public enum ParseCompleteness { COMPLETE, PARTIAL }

    public enum PartialAcceptanceStatus { NOT_APPLICABLE, PENDING }

    private final String sourceDocumentId;
    private final String revisionId;
    private final String attemptId;
    private final ParseCompleteness parseCompleteness;
    private final PartialAcceptanceStatus partialAcceptanceStatus;
    private final List<Block> blocks;
    private final List<Omission> omissions;
    private final List<ExternalRelationshipLiteral> revisionDiagnostics;
    private final BlockSetDigest omissionsDigest;

    public CandidateBlockSet(
            String sourceDocumentId,
            String revisionId,
            String attemptId,
            ParseCompleteness parseCompleteness,
            PartialAcceptanceStatus partialAcceptanceStatus,
            List<Block> blocks,
            List<Omission> omissions) {
        this(sourceDocumentId, revisionId, attemptId, parseCompleteness,
                partialAcceptanceStatus, blocks, omissions, List.of());
    }

    public CandidateBlockSet(
            String sourceDocumentId,
            String revisionId,
            String attemptId,
            ParseCompleteness parseCompleteness,
            PartialAcceptanceStatus partialAcceptanceStatus,
            List<Block> blocks,
            List<Omission> omissions,
            List<ExternalRelationshipLiteral> revisionDiagnostics) {
        this.sourceDocumentId = requireText(sourceDocumentId, "SOURCE_DOCUMENT_ID_REQUIRED");
        this.revisionId = requireText(revisionId, "REVISION_ID_REQUIRED");
        this.attemptId = requireText(attemptId, "ATTEMPT_ID_REQUIRED");
        this.parseCompleteness = Objects.requireNonNull(parseCompleteness, "parseCompleteness");
        this.partialAcceptanceStatus = Objects.requireNonNull(
                partialAcceptanceStatus, "partialAcceptanceStatus");
        this.blocks = List.copyOf(Objects.requireNonNull(blocks, "blocks"));
        this.omissions = Objects.requireNonNull(omissions, "omissions").stream()
                .sorted(Comparator.comparing(Omission::sourcePart)
                        .thenComparingInt(Omission::sourceElementIndex)
                        .thenComparing(Omission::errorCode)
                        .thenComparing(Omission::userVisibleDescription))
                .toList();
        this.omissionsDigest = BlockSetDigest.computeOmissions(this.omissions);
        this.revisionDiagnostics = Objects.requireNonNull(
                        revisionDiagnostics, "revisionDiagnostics").stream()
                .sorted(Comparator.comparing(ExternalRelationshipLiteral::sourcePart)
                        .thenComparing(ExternalRelationshipLiteral::relationshipId)
                        .thenComparing(ExternalRelationshipLiteral::relationshipType))
                .toList();
        validateCompleteness();
        validateBlocks();
        validateImageBindings();
        validateRevisionDiagnostics();
    }

    public String sourceDocumentId() { return sourceDocumentId; }

    public String revisionId() { return revisionId; }

    public String attemptId() { return attemptId; }

    public ParseCompleteness parseCompleteness() { return parseCompleteness; }

    public PartialAcceptanceStatus partialAcceptanceStatus() { return partialAcceptanceStatus; }

    public List<Block> blocks() { return blocks; }

    public List<Omission> omissions() { return omissions; }

    public BlockSetDigest omissionsDigest() { return omissionsDigest; }

    public List<ExternalRelationshipLiteral> revisionDiagnostics() {
        return revisionDiagnostics;
    }

    public byte[] canonicalOmissionsBytes() {
        try {
            ByteArrayOutputStream bytes = new ByteArrayOutputStream();
            try (DataOutputStream output = new DataOutputStream(bytes)) {
                output.writeInt(omissions.size());
                for (Omission omission : omissions) {
                    byte[] canonical = omission.canonicalBytes();
                    output.writeInt(canonical.length);
                    output.write(canonical);
                }
            }
            return bytes.toByteArray();
        } catch (IOException error) {
            throw new IllegalStateException("OMISSION_LIST_ENCODING_FAILED", error);
        }
    }

    public byte[] canonicalRevisionDiagnosticsBytes() {
        return encode(output -> {
            output.writeInt(revisionDiagnostics.size());
            for (ExternalRelationshipLiteral diagnostic : revisionDiagnostics) {
                writeText(output, diagnostic.sourcePart());
                writeText(output, diagnostic.relationshipId());
                writeText(output, diagnostic.relationshipType());
                writeText(output, diagnostic.relationshipMode().name());
                writeText(output, diagnostic.externalTargetLiteralSha256().value());
                writeText(output, diagnostic.securityDisclosure());
            }
        });
    }

    private void validateCompleteness() {
        if (parseCompleteness == ParseCompleteness.COMPLETE
                && (partialAcceptanceStatus != PartialAcceptanceStatus.NOT_APPLICABLE
                        || !omissions.isEmpty())) {
            throw new IllegalArgumentException("COMPLETE_BLOCK_SET_MUST_HAVE_NO_OMISSIONS");
        }
        if (parseCompleteness == ParseCompleteness.PARTIAL
                && (partialAcceptanceStatus != PartialAcceptanceStatus.PENDING
                        || omissions.isEmpty())) {
            throw new IllegalArgumentException("PARTIAL_BLOCK_SET_REQUIRES_PENDING_OMISSIONS");
        }
    }

    private void validateBlocks() {
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

    private void validateImageBindings() {
        Map<String, Block> parents = new HashMap<>();
        List<Block> imageBlocks = new ArrayList<>();
        for (Block block : blocks) {
            if (block.imageCandidate() == null) parents.put(block.documentBlockId(), block);
            else imageBlocks.add(block);
        }
        Set<Block> consumedImages = new HashSet<>();
        for (Block parent : parents.values()) {
            List<Block> children = imageBlocks.stream()
                    .filter(image -> parent.documentBlockId().equals(
                            image.sourceAnchor().parentBlockId()))
                    .toList();
            if (parent.textCandidate() != null) {
                requireParagraphImageBijection(parent, children);
                consumedImages.addAll(children);
            } else if (parent.tableCandidate() != null) {
                requireTableImageBijection(parent, children);
                consumedImages.addAll(children);
            }
        }
        if (consumedImages.size() != imageBlocks.size()) {
            throw new IllegalArgumentException("CANDIDATE_IMAGE_PARENT_BLOCK_MISSING");
        }
    }

    private void validateRevisionDiagnostics() {
        Set<DiagnosticIdentity> identities = new HashSet<>();
        for (ExternalRelationshipLiteral diagnostic : revisionDiagnostics) {
            requireText(diagnostic.sourcePart(), "REVISION_DIAGNOSTIC_SOURCE_PART_REQUIRED");
            DiagnosticIdentity identity = new DiagnosticIdentity(
                    diagnostic.sourcePart(), diagnostic.relationshipId());
            if (!identities.add(identity)) {
                throw new IllegalArgumentException("REVISION_DIAGNOSTIC_IDENTITY_DUPLICATE");
            }
        }
        Set<DiagnosticIdentity> consumed = new HashSet<>();
        for (Block block : blocks) {
            ImageRelationshipProjector.ProjectedImage image = block.imageCandidate();
            if (image == null || image.relationshipMode()
                    != io.cognitura.source.docx.security.DocxRelationshipClassifier.Mode.EXTERNAL) {
                continue;
            }
            DiagnosticIdentity identity = new DiagnosticIdentity(
                    image.sourcePart(), image.relationshipId());
            ExternalRelationshipLiteral diagnostic = revisionDiagnostics.stream()
                    .filter(candidate -> identity.equals(new DiagnosticIdentity(
                            candidate.sourcePart(), candidate.relationshipId())))
                    .findFirst()
                    .orElseThrow(() -> new IllegalArgumentException(
                            "EXTERNAL_IMAGE_REVISION_DIAGNOSTIC_REQUIRED"));
            if (!IMAGE_RELATIONSHIP_TYPE.equals(diagnostic.relationshipType())
                    || !diagnostic.externalTargetLiteralSha256()
                            .equals(image.externalTargetLiteralSha256())
                    || !EXTERNAL_DISCLOSURE.equals(image.securityDisclosure())
                    || !EXTERNAL_DISCLOSURE.equals(diagnostic.securityDisclosure())) {
                throw new IllegalArgumentException("EXTERNAL_IMAGE_DIAGNOSTIC_MISMATCH");
            }
            consumed.add(identity);
        }
        for (ExternalRelationshipLiteral diagnostic : revisionDiagnostics) {
            if (IMAGE_RELATIONSHIP_TYPE.equals(diagnostic.relationshipType())) {
                DiagnosticIdentity identity = new DiagnosticIdentity(
                        diagnostic.sourcePart(), diagnostic.relationshipId());
                if (!consumed.contains(identity)) {
                    throw new IllegalArgumentException("EXTERNAL_IMAGE_BLOCK_REQUIRED");
                }
            }
        }
    }

    private record DiagnosticIdentity(String sourcePart, String relationshipId) {}

    private static void requireParagraphImageBijection(Block parent, List<Block> children) {
        List<Integer> offsets = replacementCharacterOffsets(parent.textCandidate().text());
        List<Block> ordered = children.stream()
                .filter(child -> child.sourceAnchor().kind() == SourceAnchor.Kind.PARAGRAPH_INLINE)
                .sorted(Comparator.comparingInt(child -> child.sourceAnchor().childOrdinal()))
                .toList();
        if (ordered.size() != children.size() || ordered.size() != offsets.size()) {
            throw new IllegalArgumentException("CANDIDATE_PARAGRAPH_IMAGE_BINDING_INVALID");
        }
        for (int ordinal = 0; ordinal < offsets.size(); ordinal++) {
            SourceAnchor anchor = ordered.get(ordinal).sourceAnchor();
            if (anchor.childOrdinal() != ordinal || anchor.textOffset() != offsets.get(ordinal)) {
                throw new IllegalArgumentException("CANDIDATE_PARAGRAPH_IMAGE_BINDING_INVALID");
            }
        }
    }

    private static void requireTableImageBijection(Block parent, List<Block> children) {
        Map<String, List<Integer>> expectedByCell = new HashMap<>();
        for (TableCellCandidate cell : parent.tableCandidate().cells()) {
            List<Integer> offsets = replacementCharacterOffsets(cell.text());
            if (!offsets.isEmpty()) {
                expectedByCell.put(cell.rowIndex() + ":" + cell.columnIndex(), offsets);
            }
        }
        Map<String, List<Block>> actualByCell = new HashMap<>();
        for (Block child : children) {
            SourceAnchor anchor = child.sourceAnchor();
            if (anchor.kind() != SourceAnchor.Kind.TABLE_CELL_INLINE) {
                throw new IllegalArgumentException("CANDIDATE_TABLE_IMAGE_BINDING_INVALID");
            }
            actualByCell.computeIfAbsent(anchor.rowIndex() + ":" + anchor.columnIndex(), ignored ->
                    new ArrayList<>()).add(child);
        }
        if (!expectedByCell.keySet().equals(actualByCell.keySet())) {
            throw new IllegalArgumentException("CANDIDATE_TABLE_IMAGE_BINDING_INVALID");
        }
        for (Map.Entry<String, List<Integer>> entry : expectedByCell.entrySet()) {
            List<Block> actual = actualByCell.get(entry.getKey()).stream()
                    .sorted(Comparator.comparingInt(child -> child.sourceAnchor().childOrdinal()))
                    .toList();
            if (actual.size() != entry.getValue().size()) {
                throw new IllegalArgumentException("CANDIDATE_TABLE_IMAGE_BINDING_INVALID");
            }
            for (int ordinal = 0; ordinal < actual.size(); ordinal++) {
                SourceAnchor anchor = actual.get(ordinal).sourceAnchor();
                if (anchor.childOrdinal() != ordinal
                        || anchor.textOffset() != entry.getValue().get(ordinal)) {
                    throw new IllegalArgumentException("CANDIDATE_TABLE_IMAGE_BINDING_INVALID");
                }
            }
        }
    }

    private static List<Integer> replacementCharacterOffsets(String text) {
        List<Integer> offsets = new ArrayList<>();
        int codePointOffset = 0;
        for (int charOffset = 0; charOffset < text.length(); codePointOffset++) {
            int codePoint = text.codePointAt(charOffset);
            if (codePoint == 0xFFFC) offsets.add(codePointOffset);
            charOffset += Character.charCount(codePoint);
        }
        return List.copyOf(offsets);
    }

    @Override
    public boolean equals(Object candidate) {
        if (this == candidate) return true;
        if (!(candidate instanceof CandidateBlockSet other)) return false;
        return sourceDocumentId.equals(other.sourceDocumentId)
                && revisionId.equals(other.revisionId)
                && attemptId.equals(other.attemptId)
                && parseCompleteness == other.parseCompleteness
                && partialAcceptanceStatus == other.partialAcceptanceStatus
                && blocks.equals(other.blocks)
                && omissions.equals(other.omissions)
                && revisionDiagnostics.equals(other.revisionDiagnostics);
    }

    @Override
    public int hashCode() {
        return Objects.hash(sourceDocumentId, revisionId, attemptId, parseCompleteness,
                partialAcceptanceStatus, blocks, omissions, revisionDiagnostics);
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

        byte[] canonicalBytes() {
            try {
                ByteArrayOutputStream bytes = new ByteArrayOutputStream();
                try (DataOutputStream output = new DataOutputStream(bytes)) {
                    writeText(output, sourcePart);
                    output.writeInt(sourceElementIndex);
                    writeText(output, errorCode);
                    writeText(output, userVisibleDescription);
                }
                return bytes.toByteArray();
            } catch (IOException error) {
                throw new IllegalStateException("OMISSION_ENCODING_FAILED", error);
            }
        }
    }

    public record PageEvidence(
            String layoutProfileVersion,
            String layoutEngineVersion,
            int pageIndex,
            String evidenceHash) {
        public PageEvidence {
            layoutProfileVersion = requireText(
                    layoutProfileVersion, "PAGE_LAYOUT_PROFILE_VERSION_REQUIRED");
            layoutEngineVersion = requireText(
                    layoutEngineVersion, "PAGE_LAYOUT_ENGINE_VERSION_REQUIRED");
            if (pageIndex < 0) throw new IllegalArgumentException("PAGE_INDEX_INVALID");
            if (evidenceHash == null || !evidenceHash.matches("[0-9a-f]{64}")) {
                throw new IllegalArgumentException("PAGE_EVIDENCE_HASH_INVALID");
            }
        }
    }

    public record SourceAnchor(
            Kind kind,
            String sourcePart,
            int sourceElementIndex,
            String parentBlockId,
            Integer textOffset,
            Integer childOrdinal,
            Integer rowIndex,
            Integer columnIndex) {

        public enum Kind { TOP_LEVEL, PARAGRAPH_INLINE, TABLE_CELL_INLINE }

        public SourceAnchor {
            Objects.requireNonNull(kind, "kind");
            sourcePart = requireText(sourcePart, "SOURCE_ANCHOR_PART_REQUIRED");
            if (sourceElementIndex < 0) {
                throw new IllegalArgumentException("SOURCE_ANCHOR_ELEMENT_INDEX_INVALID");
            }
            if (kind == Kind.TOP_LEVEL) {
                if (parentBlockId != null || textOffset != null || childOrdinal != null
                        || rowIndex != null || columnIndex != null) {
                    throw new IllegalArgumentException("TOP_LEVEL_SOURCE_ANCHOR_INVALID");
                }
            } else {
                parentBlockId = requireText(parentBlockId, "IMAGE_PARENT_BLOCK_ID_REQUIRED");
                if (textOffset == null || textOffset < 0
                        || childOrdinal == null || childOrdinal < 0) {
                    throw new IllegalArgumentException("IMAGE_SOURCE_ANCHOR_INVALID");
                }
                if (kind == Kind.PARAGRAPH_INLINE && (rowIndex != null || columnIndex != null)) {
                    throw new IllegalArgumentException("PARAGRAPH_IMAGE_CELL_COORDINATES_FORBIDDEN");
                }
                if (kind == Kind.TABLE_CELL_INLINE
                        && (rowIndex == null || rowIndex < 0
                                || columnIndex == null || columnIndex < 0)) {
                    throw new IllegalArgumentException("TABLE_IMAGE_CELL_COORDINATES_REQUIRED");
                }
            }
        }

        static SourceAnchor topLevel(String sourcePart, int sourceElementIndex) {
            return new SourceAnchor(Kind.TOP_LEVEL, sourcePart, sourceElementIndex,
                    null, null, null, null, null);
        }

        static SourceAnchor image(
                String sourcePart, int sourceElementIndex, ImageAnchor anchor) {
            Kind kind = anchor.anchorKind() == ImageAnchor.AnchorKind.PARAGRAPH_INLINE
                    ? Kind.PARAGRAPH_INLINE : Kind.TABLE_CELL_INLINE;
            return new SourceAnchor(kind, sourcePart, sourceElementIndex,
                    anchor.parentBlockId(), anchor.textOffset(), anchor.childOrdinal(),
                    anchor.rowIndex(), anchor.columnIndex());
        }
    }

    public static final class Block {

        public enum BlockType { HEADING, PARAGRAPH, LIST, TABLE, IMAGE }

        private final String documentBlockId;
        private final String sourceDocumentId;
        private final String revisionId;
        private final String attemptId;
        private final BlockType blockType;
        private final int sourceOrder;
        private final List<String> sectionPath;
        private final Integer pageNumber;
        private final PageEvidence pageEvidence;
        private final SourceAnchor sourceAnchor;
        private final byte[] canonicalPayload;
        private final String contentHash;
        private final DocumentBlockCandidate textCandidate;
        private final TableBlockCandidate tableCandidate;
        private final ImageRelationshipProjector.ProjectedImage imageCandidate;

        private Block(
                String documentBlockId,
                String sourceDocumentId,
                String revisionId,
                String attemptId,
                BlockType blockType,
                int sourceOrder,
                List<String> sectionPath,
                SourceAnchor sourceAnchor,
                byte[] canonicalPayload,
                DocumentBlockCandidate textCandidate,
                TableBlockCandidate tableCandidate,
                ImageRelationshipProjector.ProjectedImage imageCandidate) {
            this.documentBlockId = requireText(documentBlockId, "CANDIDATE_BLOCK_ID_REQUIRED");
            this.sourceDocumentId = requireText(sourceDocumentId, "SOURCE_DOCUMENT_ID_REQUIRED");
            this.revisionId = requireText(revisionId, "REVISION_ID_REQUIRED");
            this.attemptId = requireText(attemptId, "ATTEMPT_ID_REQUIRED");
            this.blockType = Objects.requireNonNull(blockType, "blockType");
            if (sourceOrder < 0) throw new IllegalArgumentException("SOURCE_ORDER_INVALID");
            this.sourceOrder = sourceOrder;
            this.sectionPath = List.copyOf(Objects.requireNonNull(sectionPath, "sectionPath"));
            for (String section : this.sectionPath) {
                requireText(section, "SECTION_PATH_HEADING_REQUIRED");
            }
            this.pageNumber = null;
            this.pageEvidence = null;
            this.sourceAnchor = Objects.requireNonNull(sourceAnchor, "sourceAnchor");
            this.canonicalPayload = Objects.requireNonNull(canonicalPayload, "canonicalPayload").clone();
            this.contentHash = sha256Hex(this.canonicalPayload);
            this.textCandidate = textCandidate;
            this.tableCandidate = tableCandidate;
            this.imageCandidate = imageCandidate;
        }

        public static Block fromText(
                String documentBlockId,
                String sourceDocumentId,
                String revisionId,
                String attemptId,
                DocumentBlockCandidate candidate) {
            Objects.requireNonNull(candidate, "candidate");
            BlockType type = switch (candidate.blockType()) {
                case HEADING -> BlockType.HEADING;
                case PARAGRAPH -> BlockType.PARAGRAPH;
                case LIST -> BlockType.LIST;
            };
            return new Block(documentBlockId, sourceDocumentId, revisionId, attemptId,
                    type, candidate.sourceOrder(), candidate.sectionPath(),
                    SourceAnchor.topLevel(candidate.sourcePart(), candidate.sourceElementIndex()),
                    encodeText(candidate), candidate, null, null);
        }

        public static Block fromText(
                String documentBlockId,
                String sourceDocumentId,
                String revisionId,
                String attemptId,
                DocumentBlockCandidate candidate,
                PageEvidence pageEvidence) {
            requirePageEvidenceUnavailable(pageEvidence);
            return fromText(documentBlockId, sourceDocumentId, revisionId, attemptId, candidate);
        }

        public static Block fromTable(
                String documentBlockId,
                String sourceDocumentId,
                String revisionId,
                String attemptId,
                List<String> sectionPath,
                TableBlockCandidate candidate) {
            Objects.requireNonNull(candidate, "candidate");
            return new Block(documentBlockId, sourceDocumentId, revisionId, attemptId,
                    BlockType.TABLE, candidate.sourceOrder(), sectionPath,
                    SourceAnchor.topLevel(candidate.sourcePart(), candidate.sourceElementIndex()),
                    encodeTable(candidate), null, candidate, null);
        }

        public static Block fromTable(
                String documentBlockId,
                String sourceDocumentId,
                String revisionId,
                String attemptId,
                List<String> sectionPath,
                TableBlockCandidate candidate,
                PageEvidence pageEvidence) {
            requirePageEvidenceUnavailable(pageEvidence);
            return fromTable(documentBlockId, sourceDocumentId, revisionId, attemptId,
                    sectionPath, candidate);
        }

        public static Block fromImage(
                String documentBlockId,
                String sourceDocumentId,
                String revisionId,
                String attemptId,
                List<String> sectionPath,
                ImageRelationshipProjector.ProjectedImage candidate) {
            Objects.requireNonNull(candidate, "candidate");
            byte[] payload = encodeImage(candidate);
            if (!candidate.contentHash().value().equals(sha256Hex(payload))) {
                throw new IllegalArgumentException("IMAGE_CONTENT_HASH_MISMATCH");
            }
            return new Block(documentBlockId, sourceDocumentId, revisionId, attemptId,
                    BlockType.IMAGE, candidate.sourceOrder(), sectionPath,
                    SourceAnchor.image(
                            candidate.sourcePart(), candidate.sourceElementIndex(), candidate.anchor()),
                    payload, null, null, candidate);
        }

        public static Block fromImage(
                String documentBlockId,
                String sourceDocumentId,
                String revisionId,
                String attemptId,
                List<String> sectionPath,
                ImageRelationshipProjector.ProjectedImage candidate,
                PageEvidence pageEvidence) {
            requirePageEvidenceUnavailable(pageEvidence);
            return fromImage(documentBlockId, sourceDocumentId, revisionId, attemptId,
                    sectionPath, candidate);
        }

        private static void requirePageEvidenceUnavailable(PageEvidence pageEvidence) {
            if (pageEvidence != null) {
                throw new IllegalArgumentException("PAGE_EVIDENCE_PROFILE_NOT_AUTHORIZED");
            }
        }

        public String documentBlockId() { return documentBlockId; }

        public String sourceDocumentId() { return sourceDocumentId; }

        public String revisionId() { return revisionId; }

        public String attemptId() { return attemptId; }

        public BlockType blockType() { return blockType; }

        public int sourceOrder() { return sourceOrder; }

        public List<String> sectionPath() { return sectionPath; }

        public Integer pageNumber() { return pageNumber; }

        public PageEvidence pageEvidence() { return pageEvidence; }

        public SourceAnchor sourceAnchor() { return sourceAnchor; }

        public String sourcePart() { return sourceAnchor.sourcePart(); }

        public int sourceElementIndex() { return sourceAnchor.sourceElementIndex(); }

        public String contentHash() { return contentHash; }

        DocumentBlockCandidate textCandidate() { return textCandidate; }

        TableBlockCandidate tableCandidate() { return tableCandidate; }

        ImageRelationshipProjector.ProjectedImage imageCandidate() { return imageCandidate; }

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

        public byte[] canonicalBytes() {
            try {
                ByteArrayOutputStream bytes = new ByteArrayOutputStream();
                try (DataOutputStream output = new DataOutputStream(bytes)) {
                    writeText(output, documentBlockId);
                    writeText(output, sourceDocumentId);
                    writeText(output, revisionId);
                    writeText(output, blockType.name());
                    output.writeInt(sourceOrder);
                    writeTextList(output, sectionPath);
                    output.writeBoolean(pageNumber != null);
                    output.writeBoolean(pageEvidence != null);
                    if (pageEvidence != null) {
                        writeText(output, pageEvidence.layoutProfileVersion());
                        writeText(output, pageEvidence.layoutEngineVersion());
                        output.writeInt(pageEvidence.pageIndex());
                        writeText(output, pageEvidence.evidenceHash());
                    }
                    writeAnchor(output, sourceAnchor);
                    writeText(output, contentHash);
                    output.writeInt(canonicalPayload.length);
                    output.write(canonicalPayload);
                }
                return bytes.toByteArray();
            } catch (IOException error) {
                throw new IllegalStateException("CANDIDATE_BLOCK_ENCODING_FAILED", error);
            }
        }

        @Override
        public boolean equals(Object candidate) {
            if (this == candidate) return true;
            if (!(candidate instanceof Block other)) return false;
            return attemptId.equals(other.attemptId)
                    && Arrays.equals(canonicalBytes(), other.canonicalBytes());
        }

        @Override
        public int hashCode() {
            return 31 * attemptId.hashCode() + Arrays.hashCode(canonicalBytes());
        }
    }

    private static byte[] encodeText(DocumentBlockCandidate candidate) {
        return encode(output -> {
            switch (candidate.blockType()) {
                case HEADING -> {
                    writeText(output, "HEADING_PAYLOAD_V1");
                    writeText(output, candidate.text());
                    output.writeInt(candidate.headingLevel());
                    writeNullableText(output, candidate.styleName());
                }
                case PARAGRAPH -> {
                    writeText(output, "PARAGRAPH_PAYLOAD_V1");
                    writeText(output, candidate.text());
                    writeNullableText(output, candidate.styleName());
                }
                case LIST -> {
                    ListSemantics list = Objects.requireNonNull(
                            candidate.listSemantics(), "listSemantics");
                    writeText(output, "LIST_PAYLOAD_V1");
                    writeText(output, list.listInstanceId());
                    output.writeInt(list.itemLevel());
                    output.writeInt(list.itemOrdinal());
                    writeNullableText(output, list.markerText());
                    writeText(output, candidate.text());
                }
            }
        });
    }

    private static byte[] encodeTable(TableBlockCandidate candidate) {
        return encode(output -> {
            writeText(output, "TABLE_PAYLOAD_V1");
            output.writeInt(candidate.rowCount());
            for (int rowIndex = 0; rowIndex < candidate.rowCount(); rowIndex++) {
                output.writeInt(rowIndex);
                int currentRow = rowIndex;
                List<TableCellCandidate> cells = candidate.cells().stream()
                        .filter(cell -> cell.rowIndex() == currentRow)
                        .toList();
                output.writeInt(cells.size());
                for (TableCellCandidate cell : cells) {
                    output.writeInt(cell.columnIndex());
                    output.writeInt(cell.rowSpan());
                    output.writeInt(cell.columnSpan());
                    writeText(output, cell.text());
                }
            }
        });
    }

    private static byte[] encodeImage(ImageRelationshipProjector.ProjectedImage candidate) {
        StringBuilder canonical = new StringBuilder("IMAGE_PAYLOAD_V1");
        appendImageCanonical(canonical, candidate.relationshipId());
        appendImageCanonical(canonical, candidate.relationshipMode().name());
        appendImageCanonical(canonical, candidate.externalTargetLiteralSha256() == null
                ? null : candidate.externalTargetLiteralSha256().value());
        appendImageCanonical(canonical, candidate.mediaRef() == null
                ? null : candidate.mediaRef().value());
        appendImageCanonical(canonical, candidate.mediaType());
        appendImageCanonical(canonical, candidate.byteLength() == null
                ? null : candidate.byteLength().toString());
        appendImageCanonical(canonical, candidate.contentSha256() == null
                ? null : candidate.contentSha256().value());
        appendImageCanonical(canonical, candidate.securityDisclosure());
        return canonical.toString().getBytes(StandardCharsets.UTF_8);
    }

    private static void appendImageCanonical(StringBuilder target, String value) {
        target.append('|');
        if (value == null) {
            target.append("-1:");
            return;
        }
        target.append(value.getBytes(StandardCharsets.UTF_8).length).append(':').append(value);
    }

    private static byte[] encode(IoWriter writer) {
        try {
            ByteArrayOutputStream bytes = new ByteArrayOutputStream();
            try (DataOutputStream output = new DataOutputStream(bytes)) {
                writer.write(output);
            }
            return bytes.toByteArray();
        } catch (IOException error) {
            throw new IllegalStateException("CANDIDATE_PAYLOAD_ENCODING_FAILED", error);
        }
    }

    private static void writeAnchor(DataOutputStream output, SourceAnchor anchor) throws IOException {
        writeText(output, anchor.kind().name());
        writeText(output, anchor.sourcePart());
        output.writeInt(anchor.sourceElementIndex());
        writeNullableText(output, anchor.parentBlockId());
        writeNullableInteger(output, anchor.textOffset());
        writeNullableInteger(output, anchor.childOrdinal());
        writeNullableInteger(output, anchor.rowIndex());
        writeNullableInteger(output, anchor.columnIndex());
    }

    private static void writeTextList(DataOutputStream output, List<String> values) throws IOException {
        output.writeInt(values.size());
        for (String value : values) writeText(output, value);
    }

    private static void writeNullableInteger(DataOutputStream output, Integer value)
            throws IOException {
        output.writeBoolean(value != null);
        if (value != null) output.writeInt(value);
    }

    private static void writeNullableText(DataOutputStream output, String value) throws IOException {
        output.writeBoolean(value != null);
        if (value != null) writeText(output, value);
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

    @FunctionalInterface
    private interface IoWriter { void write(DataOutputStream output) throws IOException; }
}
