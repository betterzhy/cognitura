package io.cognitura.source.docx.image;

import io.cognitura.source.docx.security.DocxRelationshipClassifier;
import io.cognitura.source.docx.security.DocxRelationshipClassifier.RelationshipMetadata;
import io.cognitura.source.docx.security.SafeDocxPackage;
import io.cognitura.source.docx.table.TableBlockCandidate;
import io.cognitura.source.docx.table.TableFidelityParser;
import io.cognitura.source.domain.SourceDomainException;
import io.cognitura.source.domain.SourceHash;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.text.Normalizer;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.IdentityHashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.xml.sax.SAXException;

public final class ImageRelationshipProjector {

    private static final String MAIN_DOCUMENT_PART = "word/document.xml";
    private static final String CONTENT_TYPES_PART = "[Content_Types].xml";
    private static final String WORD_NAMESPACE =
            "http://schemas.openxmlformats.org/wordprocessingml/2006/main";
    private static final String RELATIONSHIPS_NAMESPACE =
            "http://schemas.openxmlformats.org/officeDocument/2006/relationships";
    private static final String WORDPROCESSING_DRAWING_NAMESPACE =
            "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing";
    private static final String DRAWING_NAMESPACE =
            "http://schemas.openxmlformats.org/drawingml/2006/main";
    private static final String VML_NAMESPACE = "urn:schemas-microsoft-com:vml";
    private static final String CONTENT_TYPES_NAMESPACE =
            "http://schemas.openxmlformats.org/package/2006/content-types";
    private static final String IMAGE_RELATIONSHIP_TYPE =
            "http://schemas.openxmlformats.org/officeDocument/2006/relationships/image";
    private static final char INLINE_IMAGE_ANCHOR = '\uFFFC';

    @FunctionalInterface
    public interface ParentBlockIdResolver {
        String resolve(
                String sourcePart,
                int sourceElementIndex,
                ImageAnchor.AnchorKind anchorKind,
                Integer rowIndex,
                Integer columnIndex);
    }

    @FunctionalInterface
    public interface ImmutableMediaSink {
        ImmutableMediaRef store(
                String sourcePart,
                String relationshipId,
                String mediaType,
                byte[] content,
                MediaDigest digest);
    }

    public record Projection(
            List<ProjectedImage> images,
            List<ExternalRelationshipLiteral> revisionDiagnostics) {

        public Projection {
            images = List.copyOf(Objects.requireNonNull(images, "images"));
            revisionDiagnostics = List.copyOf(
                    Objects.requireNonNull(revisionDiagnostics, "revisionDiagnostics"));
        }
    }

    public record ProjectedImage(
            int sourceOrder,
            String sourcePart,
            int sourceElementIndex,
            ImageAnchor anchor,
            String relationshipId,
            DocxRelationshipClassifier.Mode relationshipMode,
            SourceHash externalTargetLiteralSha256,
            ImmutableMediaRef mediaRef,
            String mediaType,
            Long byteLength,
            SourceHash contentSha256,
            String securityDisclosure,
            SourceHash contentHash) {

        public ProjectedImage {
            if (sourceOrder < 0 || sourceElementIndex < 0) {
                throw new IllegalArgumentException("IMAGE_SOURCE_POSITION_INVALID");
            }
            requireText(sourcePart, "IMAGE_SOURCE_PART_REQUIRED");
            Objects.requireNonNull(anchor, "anchor");
            requireText(relationshipId, "IMAGE_RELATIONSHIP_ID_REQUIRED");
            Objects.requireNonNull(relationshipMode, "relationshipMode");
            Objects.requireNonNull(contentHash, "contentHash");
            if (relationshipMode == DocxRelationshipClassifier.Mode.INTERNAL
                    && (externalTargetLiteralSha256 != null
                            || mediaRef == null
                            || mediaType == null
                            || byteLength == null
                            || contentSha256 == null
                            || securityDisclosure != null)) {
                throw new IllegalArgumentException("INTERNAL_IMAGE_PAYLOAD_INVALID");
            }
            if (relationshipMode == DocxRelationshipClassifier.Mode.EXTERNAL
                    && (externalTargetLiteralSha256 == null
                            || mediaRef != null
                            || mediaType != null
                            || byteLength != null
                            || contentSha256 != null
                            || securityDisclosure == null)) {
                throw new IllegalArgumentException("EXTERNAL_IMAGE_PAYLOAD_INVALID");
            }
        }
    }

    public Projection project(
            SafeDocxPackage safePackage,
            ParentBlockIdResolver parentBlockIds,
            ImmutableMediaSink mediaSink) {
        Objects.requireNonNull(safePackage, "safePackage");
        Objects.requireNonNull(parentBlockIds, "parentBlockIds");
        Objects.requireNonNull(mediaSink, "mediaSink");
        try {
            Document document = parseXml(safePackage.readVerifiedEntry(MAIN_DOCUMENT_PART));
            ContentTypes contentTypes = ContentTypes.parse(
                    parseXml(safePackage.readVerifiedEntry(CONTENT_TYPES_PART)));
            Map<String, RelationshipMetadata> relationships = imageRelationships(safePackage);
            List<TableBlockCandidate> tables = new TableFidelityParser().parse(safePackage);
            return projectDocument(
                    safePackage,
                    document,
                    contentTypes,
                    relationships,
                    tables,
                    parentBlockIds,
                    mediaSink);
        } catch (SourceDomainException error) {
            throw error;
        } catch (IllegalArgumentException error) {
            throw terminal(error.getMessage());
        }
    }

    private static Projection projectDocument(
            SafeDocxPackage safePackage,
            Document document,
            ContentTypes contentTypes,
            Map<String, RelationshipMetadata> relationships,
            List<TableBlockCandidate> tables,
            ParentBlockIdResolver parentBlockIds,
            ImmutableMediaSink mediaSink) {
        Element root = document.getDocumentElement();
        requireElement(root, WORD_NAMESPACE, "document", "MAIN_DOCUMENT_ROOT_INVALID");
        Element body = onlyDirectChild(root, WORD_NAMESPACE, "body", true);
        IdentityHashMap<Element, Integer> elementIndexes = preorderElementIndexes(root);
        Map<Integer, TableBlockCandidate> tablesByElementIndex = new HashMap<>();
        for (TableBlockCandidate table : tables) {
            if (tablesByElementIndex.put(table.sourceElementIndex(), table) != null) {
                throw new IllegalArgumentException("TABLE_SOURCE_ELEMENT_INDEX_DUPLICATE");
            }
        }
        List<ProjectedImage> projected = new ArrayList<>();
        Set<Integer> consumedTables = new HashSet<>();
        int sourceOrder = 0;

        for (Node node = body.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (!(node instanceof Element element)) {
                continue;
            }
            requireElementNamespace(element, WORD_NAMESPACE, "UNSUPPORTED_DOCX_IMAGE_FLOW_NAMESPACE");
            switch (element.getLocalName()) {
                case "p" -> {
                    ParsedParagraph paragraph = parseParagraph(element, elementIndexes);
                    appendParagraphImages(
                            safePackage,
                            contentTypes,
                            relationships,
                            parentBlockIds,
                            mediaSink,
                            elementIndexes.get(element),
                            sourceOrder,
                            paragraph,
                            projected);
                    sourceOrder = advanceSourceOrder(sourceOrder, paragraph.images().size());
                }
                case "tbl" -> {
                    int tableElementIndex = elementIndexes.get(element);
                    TableBlockCandidate table = tablesByElementIndex.get(tableElementIndex);
                    if (table == null || table.sourceOrder() != sourceOrder) {
                        throw new IllegalArgumentException("TABLE_IMAGE_SOURCE_ORDER_MISMATCH");
                    }
                    List<TableImageOccurrence> images = parseTable(element, elementIndexes);
                    appendTableImages(
                            safePackage,
                            contentTypes,
                            relationships,
                            parentBlockIds,
                            mediaSink,
                            table,
                            sourceOrder,
                            images,
                            projected);
                    sourceOrder = advanceSourceOrder(sourceOrder, images.size());
                    consumedTables.add(tableElementIndex);
                }
                case "sectPr" -> {
                    // Section metadata does not occupy source order.
                }
                default -> throw new IllegalArgumentException(
                        "UNSUPPORTED_DOCX_IMAGE_FLOW:" + element.getLocalName());
            }
        }
        if (!consumedTables.equals(tablesByElementIndex.keySet())) {
            throw new IllegalArgumentException("TABLE_IMAGE_PROJECTION_INCOMPLETE");
        }
        for (int index = 0; index < projected.size(); index++) {
            if (projected.get(index).sourceOrder() < 0
                    || (index > 0
                            && projected.get(index).sourceOrder()
                                    <= projected.get(index - 1).sourceOrder())) {
                throw new IllegalArgumentException("IMAGE_SOURCE_ORDER_INVALID");
            }
        }
        return new Projection(projected, List.of());
    }

    private static void appendParagraphImages(
            SafeDocxPackage safePackage,
            ContentTypes contentTypes,
            Map<String, RelationshipMetadata> relationships,
            ParentBlockIdResolver parentBlockIds,
            ImmutableMediaSink mediaSink,
            int parentElementIndex,
            int parentSourceOrder,
            ParsedParagraph paragraph,
            List<ProjectedImage> projected) {
        for (int ordinal = 0; ordinal < paragraph.images().size(); ordinal++) {
            ImageOccurrence occurrence = paragraph.images().get(ordinal);
            String parentBlockId = parentBlockIds.resolve(
                    MAIN_DOCUMENT_PART,
                    parentElementIndex,
                    ImageAnchor.AnchorKind.PARAGRAPH_INLINE,
                    null,
                    null);
            ImageAnchor anchor = new ImageAnchor(
                    parentBlockId,
                    ImageAnchor.AnchorKind.PARAGRAPH_INLINE,
                    paragraph.imageOffsets().get(ordinal),
                    ordinal,
                    null,
                    null);
            projected.add(projectImage(
                    safePackage,
                    contentTypes,
                    relationships,
                    mediaSink,
                    parentSourceOrder + 1 + ordinal,
                    occurrence,
                    anchor));
        }
    }

    private static void appendTableImages(
            SafeDocxPackage safePackage,
            ContentTypes contentTypes,
            Map<String, RelationshipMetadata> relationships,
            ParentBlockIdResolver parentBlockIds,
            ImmutableMediaSink mediaSink,
            TableBlockCandidate table,
            int tableSourceOrder,
            List<TableImageOccurrence> images,
            List<ProjectedImage> projected) {
        Map<CellCoordinate, List<Integer>> expectedOffsets = new LinkedHashMap<>();
        table.cells().forEach(cell -> {
            List<Integer> offsets = new ArrayList<>();
            int paragraphBase = 0;
            for (int index = 0; index < cell.textEvidence().size(); index++) {
                var evidence = cell.textEvidence().get(index);
                for (int offset : evidence.inlineImageOffsets()) {
                    offsets.add(paragraphBase + offset);
                }
                paragraphBase += evidence.text().codePointCount(0, evidence.text().length());
                if (index + 1 < cell.textEvidence().size()) {
                    paragraphBase++;
                }
            }
            expectedOffsets.put(
                    new CellCoordinate(cell.rowIndex(), cell.columnIndex()), List.copyOf(offsets));
        });

        Map<CellCoordinate, Integer> ordinals = new HashMap<>();
        for (int imageIndex = 0; imageIndex < images.size(); imageIndex++) {
            TableImageOccurrence tableImage = images.get(imageIndex);
            CellCoordinate coordinate = new CellCoordinate(tableImage.rowIndex(), tableImage.columnIndex());
            List<Integer> offsets = expectedOffsets.get(coordinate);
            int ordinal = ordinals.getOrDefault(coordinate, 0);
            if (offsets == null
                    || ordinal >= offsets.size()
                    || offsets.get(ordinal) != tableImage.textOffset()) {
                throw new IllegalArgumentException("TABLE_IMAGE_ANCHOR_BIJECTION_INVALID");
            }
            ordinals.put(coordinate, ordinal + 1);
            String parentBlockId = parentBlockIds.resolve(
                    MAIN_DOCUMENT_PART,
                    table.sourceElementIndex(),
                    ImageAnchor.AnchorKind.TABLE_CELL_INLINE,
                    tableImage.rowIndex(),
                    tableImage.columnIndex());
            ImageAnchor anchor = new ImageAnchor(
                    parentBlockId,
                    ImageAnchor.AnchorKind.TABLE_CELL_INLINE,
                    tableImage.textOffset(),
                    ordinal,
                    tableImage.rowIndex(),
                    tableImage.columnIndex());
            projected.add(projectImage(
                    safePackage,
                    contentTypes,
                    relationships,
                    mediaSink,
                    tableSourceOrder + 1 + imageIndex,
                    tableImage.occurrence(),
                    anchor));
        }
        expectedOffsets.forEach((coordinate, offsets) -> {
            if (ordinals.getOrDefault(coordinate, 0) != offsets.size()) {
                throw new IllegalArgumentException("TABLE_IMAGE_ANCHOR_BIJECTION_INVALID");
            }
        });
    }

    private static ProjectedImage projectImage(
            SafeDocxPackage safePackage,
            ContentTypes contentTypes,
            Map<String, RelationshipMetadata> relationships,
            ImmutableMediaSink mediaSink,
            int sourceOrder,
            ImageOccurrence occurrence,
            ImageAnchor anchor) {
        RelationshipMetadata relationship = relationships.get(occurrence.relationshipId());
        if (relationship == null) {
            throw new IllegalArgumentException("IMAGE_RELATIONSHIP_MISSING");
        }
        if (!IMAGE_RELATIONSHIP_TYPE.equals(relationship.relationshipType())) {
            throw new IllegalArgumentException("IMAGE_RELATIONSHIP_TYPE_INVALID");
        }
        if (relationship.mode() == DocxRelationshipClassifier.Mode.EXTERNAL) {
            throw new IllegalArgumentException("EXTERNAL_IMAGE_PROJECTION_NOT_IMPLEMENTED");
        }
        String targetPart = relationship.internalTargetPart().orElseThrow(
                () -> new IllegalArgumentException("IMAGE_INTERNAL_TARGET_REQUIRED"));
        String mediaType = contentTypes.mediaType(targetPart);
        byte[] content = safePackage.readRelationshipTarget(relationship);
        MediaDigest digest = new MediaDigest(
                mediaType, content.length, SourceHash.sha256(content));
        ImmutableMediaRef mediaRef = Objects.requireNonNull(
                mediaSink.store(
                        MAIN_DOCUMENT_PART,
                        relationship.relationshipId(),
                        mediaType,
                        content.clone(),
                        digest),
                "mediaRef");
        SourceHash contentHash = payloadContentHash(
                relationship.relationshipId(),
                relationship.mode(),
                null,
                mediaRef,
                mediaType,
                (long) content.length,
                digest.contentSha256(),
                null);
        return new ProjectedImage(
                sourceOrder,
                MAIN_DOCUMENT_PART,
                occurrence.sourceElementIndex(),
                anchor,
                relationship.relationshipId(),
                relationship.mode(),
                null,
                mediaRef,
                mediaType,
                (long) content.length,
                digest.contentSha256(),
                null,
                contentHash);
    }

    private static ParsedParagraph parseParagraph(
            Element paragraph, IdentityHashMap<Element, Integer> elementIndexes) {
        StringBuilder text = new StringBuilder();
        List<ImageOccurrence> images = new ArrayList<>();
        appendParagraphContent(paragraph, text, images, elementIndexes);
        String normalized = normalizeText(text.toString());
        List<Integer> offsets = inlineImageOffsets(normalized);
        if (offsets.size() != images.size()) {
            throw new IllegalArgumentException("PARAGRAPH_IMAGE_ANCHOR_BIJECTION_INVALID");
        }
        return new ParsedParagraph(normalized, images, offsets);
    }

    private static void appendParagraphContent(
            Element paragraph,
            StringBuilder text,
            List<ImageOccurrence> images,
            IdentityHashMap<Element, Integer> elementIndexes) {
        for (Node node = paragraph.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (!(node instanceof Element element)) {
                continue;
            }
            requireElementNamespace(element, WORD_NAMESPACE, "UNSUPPORTED_DOCX_IMAGE_FLOW_NAMESPACE");
            switch (element.getLocalName()) {
                case "pPr", "bookmarkStart", "bookmarkEnd", "proofErr" -> {
                    // Non-visible paragraph metadata.
                }
                case "r" -> appendRun(element, text, images, elementIndexes);
                case "hyperlink" -> {
                    for (Element child : directElementChildren(element)) {
                        requireElement(child, WORD_NAMESPACE, "r", "UNSUPPORTED_DOCX_IMAGE_FLOW:hyperlink");
                        appendRun(child, text, images, elementIndexes);
                    }
                }
                default -> throw new IllegalArgumentException(
                        "UNSUPPORTED_DOCX_IMAGE_FLOW:paragraph/" + element.getLocalName());
            }
        }
    }

    private static void appendRun(
            Element run,
            StringBuilder text,
            List<ImageOccurrence> images,
            IdentityHashMap<Element, Integer> elementIndexes) {
        for (Node node = run.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (!(node instanceof Element element)) {
                continue;
            }
            requireElementNamespace(element, WORD_NAMESPACE, "UNSUPPORTED_DOCX_IMAGE_FLOW_NAMESPACE");
            switch (element.getLocalName()) {
                case "rPr" -> {
                    // Formatting metadata is not visible text.
                }
                case "t" -> appendText(element, text);
                case "tab" -> text.append('\t');
                case "cr" -> text.append('\n');
                case "br" -> appendBreak(element, text);
                case "noBreakHyphen" -> text.append('\u2011');
                case "softHyphen" -> text.append('\u00ad');
                case "drawing", "pict" -> {
                    images.add(parseImageOccurrence(element, elementIndexes));
                    text.append(INLINE_IMAGE_ANCHOR);
                }
                default -> throw new IllegalArgumentException(
                        "UNSUPPORTED_DOCX_IMAGE_FLOW:run/" + element.getLocalName());
            }
        }
    }

    private static ImageOccurrence parseImageOccurrence(
            Element imageElement, IdentityHashMap<Element, Integer> elementIndexes) {
        List<Element> wrappers = directElementChildren(imageElement).stream()
                .filter(child -> isSupportedWrapper(imageElement, child))
                .toList();
        if (wrappers.size() != 1) {
            throw new IllegalArgumentException("IMAGE_PAYLOAD_EVIDENCE_INVALID");
        }
        List<Element> payloads = descendants(wrappers.get(0)).stream()
                .filter(child -> isSupportedPayload(imageElement, child))
                .toList();
        if (payloads.size() != 1) {
            throw new IllegalArgumentException("IMAGE_PAYLOAD_EVIDENCE_INVALID");
        }
        Element payload = payloads.get(0);
        String relationshipId;
        if ("drawing".equals(imageElement.getLocalName())) {
            String embedded = payload.getAttributeNS(RELATIONSHIPS_NAMESPACE, "embed");
            String linked = payload.getAttributeNS(RELATIONSHIPS_NAMESPACE, "link");
            if (embedded.isBlank() == linked.isBlank()) {
                throw new IllegalArgumentException("IMAGE_RELATIONSHIP_REFERENCE_INVALID");
            }
            relationshipId = embedded.isBlank() ? linked : embedded;
        } else {
            relationshipId = payload.getAttributeNS(RELATIONSHIPS_NAMESPACE, "id");
            if (relationshipId.isBlank()) {
                throw new IllegalArgumentException("IMAGE_RELATIONSHIP_REFERENCE_INVALID");
            }
        }
        Integer elementIndex = elementIndexes.get(imageElement);
        if (elementIndex == null) {
            throw new IllegalArgumentException("IMAGE_SOURCE_ELEMENT_INDEX_MISSING");
        }
        return new ImageOccurrence(relationshipId, elementIndex);
    }

    private static boolean isSupportedWrapper(Element imageElement, Element child) {
        return switch (imageElement.getLocalName()) {
            case "drawing" -> WORDPROCESSING_DRAWING_NAMESPACE.equals(child.getNamespaceURI())
                    && ("inline".equals(child.getLocalName())
                            || "anchor".equals(child.getLocalName()));
            case "pict" -> VML_NAMESPACE.equals(child.getNamespaceURI())
                    && "shape".equals(child.getLocalName());
            default -> false;
        };
    }

    private static boolean isSupportedPayload(Element imageElement, Element child) {
        return switch (imageElement.getLocalName()) {
            case "drawing" -> DRAWING_NAMESPACE.equals(child.getNamespaceURI())
                    && "blip".equals(child.getLocalName());
            case "pict" -> VML_NAMESPACE.equals(child.getNamespaceURI())
                    && "imagedata".equals(child.getLocalName());
            default -> false;
        };
    }

    private static List<TableImageOccurrence> parseTable(
            Element table, IdentityHashMap<Element, Integer> elementIndexes) {
        List<TableImageOccurrence> images = new ArrayList<>();
        int rowIndex = 0;
        for (Element row : directChildren(table, WORD_NAMESPACE, "tr")) {
            int columnIndex = 0;
            for (Element cell : directChildren(row, WORD_NAMESPACE, "tc")) {
                int columnSpan = gridSpan(cell);
                int paragraphBase = 0;
                int childOrdinal = 0;
                List<Element> paragraphs = directChildren(cell, WORD_NAMESPACE, "p");
                if (paragraphs.isEmpty()) {
                    throw new IllegalArgumentException("TABLE_CELL_PARAGRAPH_REQUIRED");
                }
                for (int paragraphIndex = 0; paragraphIndex < paragraphs.size(); paragraphIndex++) {
                    ParsedParagraph paragraph = parseParagraph(paragraphs.get(paragraphIndex), elementIndexes);
                    for (int imageIndex = 0; imageIndex < paragraph.images().size(); imageIndex++) {
                        images.add(new TableImageOccurrence(
                                rowIndex,
                                columnIndex,
                                paragraphBase + paragraph.imageOffsets().get(imageIndex),
                                childOrdinal++,
                                paragraph.images().get(imageIndex)));
                    }
                    paragraphBase += paragraph.text().codePointCount(0, paragraph.text().length());
                    if (paragraphIndex + 1 < paragraphs.size()) {
                        paragraphBase++;
                    }
                }
                columnIndex += columnSpan;
            }
            rowIndex++;
        }
        return List.copyOf(images);
    }

    private static int gridSpan(Element cell) {
        Element properties = onlyDirectChild(cell, WORD_NAMESPACE, "tcPr", false);
        if (properties == null) {
            return 1;
        }
        Element gridSpan = onlyDirectChild(properties, WORD_NAMESPACE, "gridSpan", false);
        if (gridSpan == null) {
            return 1;
        }
        String value = gridSpan.getAttributeNS(WORD_NAMESPACE, "val");
        try {
            int span = Integer.parseInt(value);
            if (span < 1) {
                throw new NumberFormatException();
            }
            return span;
        } catch (NumberFormatException error) {
            throw new IllegalArgumentException("TABLE_CELL_SPAN_INVALID");
        }
    }

    private static Map<String, RelationshipMetadata> imageRelationships(SafeDocxPackage safePackage) {
        Map<String, RelationshipMetadata> relationships = new LinkedHashMap<>();
        for (RelationshipMetadata relationship : safePackage.relationships()) {
            if (!MAIN_DOCUMENT_PART.equals(relationship.sourcePart())) {
                continue;
            }
            if (relationships.put(relationship.relationshipId(), relationship) != null) {
                throw new IllegalArgumentException("IMAGE_RELATIONSHIP_DUPLICATE");
            }
        }
        return Map.copyOf(relationships);
    }

    private static SourceHash payloadContentHash(
            String relationshipId,
            DocxRelationshipClassifier.Mode mode,
            SourceHash externalTargetLiteralSha256,
            ImmutableMediaRef mediaRef,
            String mediaType,
            Long byteLength,
            SourceHash contentSha256,
            String securityDisclosure) {
        StringBuilder canonical = new StringBuilder("IMAGE_PAYLOAD_V1");
        appendCanonical(canonical, relationshipId);
        appendCanonical(canonical, mode.name());
        appendCanonical(
                canonical,
                externalTargetLiteralSha256 == null ? null : externalTargetLiteralSha256.value());
        appendCanonical(canonical, mediaRef == null ? null : mediaRef.value());
        appendCanonical(canonical, mediaType);
        appendCanonical(canonical, byteLength == null ? null : byteLength.toString());
        appendCanonical(canonical, contentSha256 == null ? null : contentSha256.value());
        appendCanonical(canonical, securityDisclosure);
        return SourceHash.sha256(canonical.toString().getBytes(StandardCharsets.UTF_8));
    }

    private static void appendCanonical(StringBuilder target, String value) {
        target.append('|');
        if (value == null) {
            target.append("-1:");
            return;
        }
        byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
        target.append(bytes.length).append(':').append(value);
    }

    private static String normalizeText(String value) {
        return Normalizer.normalize(value.replace("\r\n", "\n").replace('\r', '\n'), Normalizer.Form.NFC);
    }

    private static List<Integer> inlineImageOffsets(String text) {
        List<Integer> offsets = new ArrayList<>();
        int codePointOffset = 0;
        for (int charOffset = 0; charOffset < text.length(); codePointOffset++) {
            int codePoint = text.codePointAt(charOffset);
            if (codePoint == INLINE_IMAGE_ANCHOR) {
                offsets.add(codePointOffset);
            }
            charOffset += Character.charCount(codePoint);
        }
        return List.copyOf(offsets);
    }

    private static void appendText(Element element, StringBuilder text) {
        for (Node node = element.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (node.getNodeType() == Node.TEXT_NODE || node.getNodeType() == Node.CDATA_SECTION_NODE) {
                if (node.getNodeValue().indexOf(INLINE_IMAGE_ANCHOR) >= 0) {
                    throw new IllegalArgumentException("LITERAL_IMAGE_PLACEHOLDER_FORBIDDEN");
                }
                text.append(node.getNodeValue());
            } else if (node.getNodeType() != Node.COMMENT_NODE
                    && node.getNodeType() != Node.PROCESSING_INSTRUCTION_NODE) {
                throw new IllegalArgumentException("UNSUPPORTED_DOCX_IMAGE_FLOW:run/t");
            }
        }
    }

    private static void appendBreak(Element element, StringBuilder text) {
        String type = element.getAttributeNS(WORD_NAMESPACE, "type");
        if (type.isEmpty() || "textWrapping".equals(type)) {
            text.append('\n');
            return;
        }
        throw new IllegalArgumentException("UNSUPPORTED_DOCX_IMAGE_FLOW:run/br/" + type);
    }

    private static List<Element> directChildren(Element parent, String namespace, String localName) {
        List<Element> result = new ArrayList<>();
        for (Node node = parent.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (node instanceof Element element
                    && namespace.equals(element.getNamespaceURI())
                    && localName.equals(element.getLocalName())) {
                result.add(element);
            }
        }
        return List.copyOf(result);
    }

    private static List<Element> directElementChildren(Element parent) {
        List<Element> result = new ArrayList<>();
        for (Node node = parent.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (node instanceof Element element) {
                result.add(element);
            }
        }
        return List.copyOf(result);
    }

    private static List<Element> descendants(Element parent) {
        List<Element> result = new ArrayList<>();
        ArrayDeque<Element> pending = new ArrayDeque<>();
        pending.add(parent);
        while (!pending.isEmpty()) {
            Element current = pending.removeFirst();
            for (Node node = current.getFirstChild(); node != null; node = node.getNextSibling()) {
                if (node instanceof Element element) {
                    result.add(element);
                    pending.addLast(element);
                }
            }
        }
        return List.copyOf(result);
    }

    private static Element onlyDirectChild(
            Element parent, String namespace, String localName, boolean required) {
        Element result = null;
        for (Node node = parent.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (!(node instanceof Element element)
                    || !namespace.equals(element.getNamespaceURI())
                    || !localName.equals(element.getLocalName())) {
                continue;
            }
            if (result != null) {
                throw new IllegalArgumentException("DUPLICATE_" + localName.toUpperCase(Locale.ROOT));
            }
            result = element;
        }
        if (required && result == null) {
            throw new IllegalArgumentException(localName.toUpperCase(Locale.ROOT) + "_REQUIRED");
        }
        return result;
    }

    private static IdentityHashMap<Element, Integer> preorderElementIndexes(Element root) {
        IdentityHashMap<Element, Integer> indexes = new IdentityHashMap<>();
        ArrayDeque<Element> pending = new ArrayDeque<>();
        pending.push(root);
        int index = 0;
        while (!pending.isEmpty()) {
            Element current = pending.pop();
            indexes.put(current, index++);
            List<Element> children = directElementChildren(current);
            for (int childIndex = children.size() - 1; childIndex >= 0; childIndex--) {
                pending.push(children.get(childIndex));
            }
        }
        return indexes;
    }

    private static int advanceSourceOrder(int current, int imageCount) {
        try {
            return Math.addExact(current, Math.addExact(1, imageCount));
        } catch (ArithmeticException error) {
            throw new IllegalArgumentException("SOURCE_ORDER_EXCEEDED");
        }
    }

    private static Document parseXml(byte[] bytes) {
        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            factory.setNamespaceAware(true);
            factory.setXIncludeAware(false);
            factory.setExpandEntityReferences(false);
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
            factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_DTD, "");
            factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_SCHEMA, "");
            return factory.newDocumentBuilder().parse(new ByteArrayInputStream(bytes));
        } catch (ParserConfigurationException | SAXException | java.io.IOException error) {
            throw new IllegalArgumentException("DOCX_IMAGE_XML_INVALID");
        }
    }

    private static void requireElement(
            Element element, String namespace, String localName, String message) {
        if (element == null
                || !namespace.equals(element.getNamespaceURI())
                || !localName.equals(element.getLocalName())) {
            throw new IllegalArgumentException(message);
        }
    }

    private static void requireElementNamespace(Element element, String namespace, String message) {
        if (!namespace.equals(element.getNamespaceURI())) {
            throw new IllegalArgumentException(message);
        }
    }

    private static void requireText(String value, String message) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(message);
        }
    }

    private static SourceDomainException terminal(String detail) {
        return new SourceDomainException(
                SourceDomainException.Code.PARSER_TERMINAL_FAILURE,
                detail == null || detail.isBlank() ? "DOCX_IMAGE_PROJECTION_FAILED" : detail);
    }

    private record ParsedParagraph(
            String text, List<ImageOccurrence> images, List<Integer> imageOffsets) {
        private ParsedParagraph {
            text = Objects.requireNonNull(text, "text");
            images = List.copyOf(images);
            imageOffsets = List.copyOf(imageOffsets);
        }
    }

    private record ImageOccurrence(String relationshipId, int sourceElementIndex) {}

    private record TableImageOccurrence(
            int rowIndex,
            int columnIndex,
            int textOffset,
            int childOrdinal,
            ImageOccurrence occurrence) {}

    private record CellCoordinate(int rowIndex, int columnIndex) {}

    private record ContentTypes(Map<String, String> defaults, Map<String, String> overrides) {

        private static ContentTypes parse(Document document) {
            Element root = document.getDocumentElement();
            requireElement(root, CONTENT_TYPES_NAMESPACE, "Types", "CONTENT_TYPES_ROOT_INVALID");
            Map<String, String> defaults = new LinkedHashMap<>();
            Map<String, String> overrides = new LinkedHashMap<>();
            for (Element child : directElementChildren(root)) {
                requireElementNamespace(child, CONTENT_TYPES_NAMESPACE, "CONTENT_TYPES_NAMESPACE_INVALID");
                switch (child.getLocalName()) {
                    case "Default" -> {
                        String extension = requiredAttribute(child, "Extension").toLowerCase(Locale.ROOT);
                        String contentType = requiredAttribute(child, "ContentType").toLowerCase(Locale.ROOT);
                        if (defaults.put(extension, contentType) != null) {
                            throw new IllegalArgumentException("IMAGE_MEDIA_TYPE_INVALID");
                        }
                    }
                    case "Override" -> {
                        String partName = requiredAttribute(child, "PartName");
                        if (!partName.startsWith("/") || partName.length() == 1) {
                            throw new IllegalArgumentException("IMAGE_MEDIA_TYPE_INVALID");
                        }
                        String contentType = requiredAttribute(child, "ContentType").toLowerCase(Locale.ROOT);
                        if (overrides.put(partName.substring(1), contentType) != null) {
                            throw new IllegalArgumentException("IMAGE_MEDIA_TYPE_INVALID");
                        }
                    }
                    default -> throw new IllegalArgumentException("CONTENT_TYPES_ELEMENT_INVALID");
                }
            }
            return new ContentTypes(Map.copyOf(defaults), Map.copyOf(overrides));
        }

        private String mediaType(String partName) {
            String contentType = overrides.get(partName);
            if (contentType == null) {
                int dot = partName.lastIndexOf('.');
                if (dot < 0 || dot == partName.length() - 1) {
                    throw new IllegalArgumentException("IMAGE_MEDIA_TYPE_INVALID");
                }
                contentType = defaults.get(partName.substring(dot + 1).toLowerCase(Locale.ROOT));
            }
            if (contentType == null || !contentType.startsWith("image/")) {
                throw new IllegalArgumentException("IMAGE_MEDIA_TYPE_INVALID");
            }
            return contentType;
        }

        private static String requiredAttribute(Element element, String name) {
            String value = element.getAttribute(name);
            if (value.isBlank()) {
                throw new IllegalArgumentException("IMAGE_MEDIA_TYPE_INVALID");
            }
            return value;
        }
    }
}
