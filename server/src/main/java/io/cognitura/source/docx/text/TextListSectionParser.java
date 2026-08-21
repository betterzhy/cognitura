package io.cognitura.source.docx.text;

import io.cognitura.source.docx.security.SafeDocxPackage;
import io.cognitura.source.domain.SourceDomainException;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.text.Normalizer;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.IdentityHashMap;
import java.util.LinkedHashMap;
import java.util.List;
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

public final class TextListSectionParser {

    private static final String WORD_NAMESPACE =
            "http://schemas.openxmlformats.org/wordprocessingml/2006/main";
    private static final String WORDPROCESSING_DRAWING_NAMESPACE =
            "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing";
    private static final String DRAWING_NAMESPACE =
            "http://schemas.openxmlformats.org/drawingml/2006/main";
    private static final String RELATIONSHIPS_NAMESPACE =
            "http://schemas.openxmlformats.org/officeDocument/2006/relationships";
    private static final String VML_NAMESPACE = "urn:schemas-microsoft-com:vml";
    private static final String MAIN_DOCUMENT_PART = "word/document.xml";
    private static final String STYLES_PART = "word/styles.xml";
    private static final String NUMBERING_PART = "word/numbering.xml";
    private static final char INLINE_IMAGE_ANCHOR = '\uFFFC';

    public List<DocumentBlockCandidate> parse(SafeDocxPackage safePackage) {
        Objects.requireNonNull(safePackage, "safePackage");
        try {
            Document document = parseXml(safePackage.readVerifiedEntry(MAIN_DOCUMENT_PART));
            Styles styles = safePackage.partNames().contains(STYLES_PART)
                    ? Styles.parse(parseXml(safePackage.readVerifiedEntry(STYLES_PART)))
                    : Styles.empty();
            Numbering numbering = safePackage.partNames().contains(NUMBERING_PART)
                    ? Numbering.parse(parseXml(safePackage.readVerifiedEntry(NUMBERING_PART)))
                    : Numbering.empty();
            return parseDocument(document, styles, numbering);
        } catch (SourceDomainException error) {
            throw error;
        } catch (IllegalArgumentException error) {
            throw terminal(error.getMessage());
        }
    }

    private static List<DocumentBlockCandidate> parseDocument(
            Document document, Styles styles, Numbering numbering) {
        Element root = document.getDocumentElement();
        requireWordElement(root, "document", "MAIN_DOCUMENT_ROOT_INVALID");
        Element body = onlyDirectChild(root, "body", true);
        IdentityHashMap<Element, Integer> elementIndexes = preorderElementIndexes(root);
        SectionPathTracker sectionPath = new SectionPathTracker();
        SourceOrderCursor sourceOrder = new SourceOrderCursor();
        ListState listState = new ListState(numbering);
        List<DocumentBlockCandidate> blocks = new ArrayList<>();

        for (Node node = body.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (!(node instanceof Element element)) {
                continue;
            }
            requireWordNamespace(element, "UNSUPPORTED_DOCX_FLOW_NAMESPACE");
            if ("sectPr".equals(element.getLocalName())) {
                listState.endSegment();
                continue;
            }
            if (!"p".equals(element.getLocalName())) {
                throw terminal("UNSUPPORTED_DOCX_FLOW:" + element.getLocalName());
            }
            DocumentBlockCandidate block = parseParagraph(
                    element,
                    elementIndexes.get(element),
                    styles,
                    sectionPath,
                    listState,
                    sourceOrder.nextBlock());
            blocks.add(block);
            sourceOrder.reserveChildren(countInlineImagePlaceholders(block.text()));
        }

        sourceOrder.requireIssuedBlockOrder(blocks);
        return List.copyOf(blocks);
    }

    private static DocumentBlockCandidate parseParagraph(
            Element paragraph,
            int sourceElementIndex,
            Styles styles,
            SectionPathTracker sectionPath,
            ListState listState,
            int sourceOrder) {
        Element properties = onlyDirectChild(paragraph, "pPr", false);
        String styleId = properties == null ? null : optionalVal(onlyDirectChild(properties, "pStyle", false));
        StyleDefinition style = styles.definition(styleId);
        Boolean directPageBreakBefore = properties == null
                ? null
                : optionalOnOff(onlyDirectChild(properties, "pageBreakBefore", false));
        if (Boolean.TRUE.equals(directPageBreakBefore)
                || (directPageBreakBefore == null && Boolean.TRUE.equals(style.pageBreakBefore()))) {
            throw terminal("UNSUPPORTED_DOCX_FLOW:paragraph/pageBreakBefore");
        }
        Integer directOutlineLevel = properties == null
                ? null
                : optionalIntegerVal(onlyDirectChild(properties, "outlineLvl", false));
        Integer headingLevel = directOutlineLevel == null
                ? style.headingLevel()
                : headingLevel(directOutlineLevel);
        Element numberingProperties = properties == null
                ? null
                : onlyDirectChild(properties, "numPr", false);
        String text = normalizeText(readParagraphText(paragraph));
        List<String> incomingPath = sectionPath.currentPath();

        if (headingLevel != null) {
            if (numberingProperties != null) {
                throw new IllegalArgumentException("HEADING_AND_LIST_SEMANTICS_CONFLICT");
            }
            listState.endSegment();
            DocumentBlockCandidate heading = new DocumentBlockCandidate(
                    DocumentBlockCandidate.BlockType.HEADING,
                    sourceOrder,
                    incomingPath,
                    MAIN_DOCUMENT_PART,
                    sourceElementIndex,
                    text,
                    headingLevel,
                    style.styleName(),
                    null);
            sectionPath.acceptHeading(headingLevel, text);
            return heading;
        }

        if (numberingProperties != null) {
            String numId = requiredVal(onlyDirectChild(numberingProperties, "numId", true));
            int level = requiredNonNegativeInteger(
                    requiredVal(onlyDirectChild(numberingProperties, "ilvl", true)),
                    "LIST_ITEM_LEVEL_INVALID");
            ListSemantics semantics = listState.next(numId, level);
            return new DocumentBlockCandidate(
                    DocumentBlockCandidate.BlockType.LIST,
                    sourceOrder,
                    incomingPath,
                    MAIN_DOCUMENT_PART,
                    sourceElementIndex,
                    text,
                    null,
                    style.styleName(),
                    semantics);
        }

        listState.endSegment();
        return new DocumentBlockCandidate(
                DocumentBlockCandidate.BlockType.PARAGRAPH,
                sourceOrder,
                incomingPath,
                MAIN_DOCUMENT_PART,
                sourceElementIndex,
                text,
                null,
                style.styleName(),
                null);
    }

    private static String readParagraphText(Element paragraph) {
        StringBuilder text = new StringBuilder();
        for (Node node = paragraph.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (!(node instanceof Element element)) {
                continue;
            }
            requireWordNamespace(element, "UNSUPPORTED_DOCX_FLOW_NAMESPACE");
            switch (element.getLocalName()) {
                case "pPr", "bookmarkStart", "bookmarkEnd", "proofErr" -> {
                    // Explicitly non-visible paragraph metadata.
                }
                case "r" -> appendRunText(element, text);
                case "hyperlink" -> appendHyperlinkText(element, text);
                default -> throw terminal("UNSUPPORTED_DOCX_FLOW:paragraph/" + element.getLocalName());
            }
        }
        return text.toString();
    }

    private static void appendHyperlinkText(Element hyperlink, StringBuilder text) {
        for (Node node = hyperlink.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (!(node instanceof Element element)) {
                continue;
            }
            requireWordNamespace(element, "UNSUPPORTED_DOCX_FLOW_NAMESPACE");
            if (!"r".equals(element.getLocalName())) {
                throw terminal("UNSUPPORTED_DOCX_FLOW:hyperlink/" + element.getLocalName());
            }
            appendRunText(element, text);
        }
    }

    private static void appendRunText(Element run, StringBuilder text) {
        for (Node node = run.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (!(node instanceof Element element)) {
                continue;
            }
            requireWordNamespace(element, "UNSUPPORTED_DOCX_FLOW_NAMESPACE");
            switch (element.getLocalName()) {
                case "rPr" -> {
                    // Formatting metadata does not create visible text.
                }
                case "t" -> appendTextElement(element, text);
                case "tab" -> text.append('\t');
                case "br" -> appendBreak(element, text);
                case "cr" -> text.append('\n');
                case "noBreakHyphen" -> text.append('\u2011');
                case "softHyphen" -> text.append('\u00ad');
                case "drawing", "pict" -> appendInlineImageAnchor(element, text);
                default -> throw terminal("UNSUPPORTED_DOCX_FLOW:run/" + element.getLocalName());
            }
        }
    }

    private static void appendTextElement(Element textElement, StringBuilder text) {
        for (Node node = textElement.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (node.getNodeType() == Node.TEXT_NODE || node.getNodeType() == Node.CDATA_SECTION_NODE) {
                String value = node.getNodeValue();
                if (value.indexOf(INLINE_IMAGE_ANCHOR) >= 0) {
                    throw terminal("TEXT_LITERAL_IMAGE_PLACEHOLDER_FORBIDDEN");
                }
                text.append(value);
                continue;
            }
            if (node.getNodeType() == Node.COMMENT_NODE
                    || node.getNodeType() == Node.PROCESSING_INSTRUCTION_NODE) {
                continue;
            }
            throw terminal("UNSUPPORTED_DOCX_FLOW:run/t/" + node.getNodeName());
        }
    }

    private static void appendInlineImageAnchor(Element imageElement, StringBuilder text) {
        int wrapperCount = 0;
        int payloadCount = 0;
        for (Node node = imageElement.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (!(node instanceof Element child) || !isSupportedImageWrapper(imageElement, child)) {
                continue;
            }
            wrapperCount++;
            int childPayloadCount = countSupportedImagePayloads(imageElement, child);
            if (childPayloadCount < 0) {
                throw terminal("IMAGE_PAYLOAD_EVIDENCE_INVALID");
            }
            try {
                payloadCount = Math.addExact(payloadCount, childPayloadCount);
            } catch (ArithmeticException ignored) {
                throw terminal("IMAGE_PAYLOAD_EVIDENCE_INVALID");
            }
        }
        if (wrapperCount == 1 && payloadCount == 1) {
            text.append(INLINE_IMAGE_ANCHOR);
            return;
        }
        if (wrapperCount == 0) {
            throw terminal("UNSUPPORTED_DOCX_FLOW:run/" + imageElement.getLocalName());
        }
        throw terminal("IMAGE_PAYLOAD_EVIDENCE_INVALID");
    }

    private static boolean isSupportedImageWrapper(Element imageElement, Element child) {
        return switch (imageElement.getLocalName()) {
            case "drawing" -> WORDPROCESSING_DRAWING_NAMESPACE.equals(child.getNamespaceURI())
                    && ("inline".equals(child.getLocalName())
                            || "anchor".equals(child.getLocalName()));
            case "pict" -> VML_NAMESPACE.equals(child.getNamespaceURI())
                    && "shape".equals(child.getLocalName());
            default -> false;
        };
    }

    private static int countSupportedImagePayloads(Element imageElement, Element wrapper) {
        int count = 0;
        ArrayDeque<Element> pending = new ArrayDeque<>();
        pending.push(wrapper);
        while (!pending.isEmpty()) {
            Element element = pending.pop();
            if (isSupportedImagePayload(imageElement, element)) {
                if (!hasValidRelationshipReference(imageElement, element)) {
                    return -1;
                }
                try {
                    count = Math.addExact(count, 1);
                } catch (ArithmeticException ignored) {
                    return -1;
                }
            }
            for (Node node = element.getLastChild(); node != null; node = node.getPreviousSibling()) {
                if (node instanceof Element child) {
                    pending.push(child);
                }
            }
        }
        return count;
    }

    private static boolean isSupportedImagePayload(Element imageElement, Element element) {
        return switch (imageElement.getLocalName()) {
            case "drawing" -> DRAWING_NAMESPACE.equals(element.getNamespaceURI())
                    && "blip".equals(element.getLocalName());
            case "pict" -> VML_NAMESPACE.equals(element.getNamespaceURI())
                    && "imagedata".equals(element.getLocalName());
            default -> false;
        };
    }

    private static boolean hasValidRelationshipReference(
            Element imageElement, Element payload) {
        if ("drawing".equals(imageElement.getLocalName())) {
            boolean embed = hasNonBlankAttribute(payload, RELATIONSHIPS_NAMESPACE, "embed");
            boolean link = hasNonBlankAttribute(payload, RELATIONSHIPS_NAMESPACE, "link");
            return embed ^ link;
        }
        return hasNonBlankAttribute(payload, RELATIONSHIPS_NAMESPACE, "id");
    }

    private static boolean hasNonBlankAttribute(
            Element element, String namespace, String localName) {
        return element.hasAttributeNS(namespace, localName)
                && !element.getAttributeNS(namespace, localName).isBlank();
    }

    private static void appendBreak(Element breakElement, StringBuilder text) {
        String type = breakElement.getAttributeNS(WORD_NAMESPACE, "type");
        if (type.isEmpty() || "textWrapping".equals(type)) {
            text.append('\n');
            return;
        }
        throw terminal("UNSUPPORTED_DOCX_FLOW:run/br@type=" + type);
    }

    private static String normalizeText(String text) {
        return Normalizer.normalize(
                text.replace("\r\n", "\n").replace('\r', '\n'), Normalizer.Form.NFC);
    }

    private static int countInlineImagePlaceholders(String text) {
        int count = 0;
        for (int charOffset = 0; charOffset < text.length(); ) {
            int codePoint = text.codePointAt(charOffset);
            if (codePoint == INLINE_IMAGE_ANCHOR) {
                try {
                    count = Math.addExact(count, 1);
                } catch (ArithmeticException ignored) {
                    throw terminal("IMAGE_ANCHOR_COUNT_EXCEEDED");
                }
            }
            charOffset += Character.charCount(codePoint);
        }
        return count;
    }

    private static Integer headingLevel(Integer zeroBasedOutlineLevel) {
        if (zeroBasedOutlineLevel < 0 || zeroBasedOutlineLevel > 8) {
            throw new IllegalArgumentException("HEADING_LEVEL_OUT_OF_RANGE");
        }
        return zeroBasedOutlineLevel + 1;
    }

    private static Document parseXml(byte[] content) {
        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newDefaultInstance();
            factory.setNamespaceAware(true);
            factory.setXIncludeAware(false);
            factory.setExpandEntityReferences(false);
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
            factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            factory.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
            factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_DTD, "");
            factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_SCHEMA, "");
            return factory.newDocumentBuilder().parse(new ByteArrayInputStream(content));
        } catch (ParserConfigurationException error) {
            throw new IllegalStateException("SECURE_XML_PARSER_CONFIGURATION_UNAVAILABLE", error);
        } catch (SAXException | IOException error) {
            throw terminal("VERIFIED_DOCX_XML_MALFORMED");
        }
    }

    private static IdentityHashMap<Element, Integer> preorderElementIndexes(Element root) {
        IdentityHashMap<Element, Integer> indexes = new IdentityHashMap<>();
        ArrayDeque<Element> pending = new ArrayDeque<>();
        pending.push(root);
        int next = 0;
        while (!pending.isEmpty()) {
            Element element = pending.pop();
            indexes.put(element, next++);
            for (Node node = element.getLastChild(); node != null; node = node.getPreviousSibling()) {
                if (node instanceof Element child) {
                    pending.push(child);
                }
            }
        }
        return indexes;
    }

    private static Element onlyDirectChild(Element parent, String localName, boolean required) {
        Element result = null;
        for (Node node = parent.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (node instanceof Element element
                    && WORD_NAMESPACE.equals(element.getNamespaceURI())
                    && localName.equals(element.getLocalName())) {
                if (result != null) {
                    throw terminal("DUPLICATE_DOCX_ELEMENT:" + localName);
                }
                result = element;
            }
        }
        if (required && result == null) {
            throw terminal("REQUIRED_DOCX_ELEMENT_MISSING:" + localName);
        }
        return result;
    }

    private static void requireWordElement(Element element, String localName, String error) {
        if (element == null
                || !WORD_NAMESPACE.equals(element.getNamespaceURI())
                || !localName.equals(element.getLocalName())) {
            throw terminal(error);
        }
    }

    private static void requireWordNamespace(Element element, String error) {
        if (!WORD_NAMESPACE.equals(element.getNamespaceURI())) {
            throw terminal(error);
        }
    }

    private static String optionalVal(Element element) {
        return element == null ? null : requiredVal(element);
    }

    private static Integer optionalIntegerVal(Element element) {
        return element == null
                ? null
                : requiredInteger(requiredVal(element), "DOCX_INTEGER_ATTRIBUTE_INVALID");
    }

    private static Boolean optionalOnOff(Element element) {
        if (element == null) {
            return null;
        }
        String value = element.getAttributeNS(WORD_NAMESPACE, "val");
        if (value.isEmpty() || "true".equals(value) || "1".equals(value) || "on".equals(value)) {
            return true;
        }
        if ("false".equals(value) || "0".equals(value) || "off".equals(value)) {
            return false;
        }
        throw terminal("DOCX_ON_OFF_ATTRIBUTE_INVALID:" + element.getLocalName());
    }

    private static String requiredVal(Element element) {
        String value = element.getAttributeNS(WORD_NAMESPACE, "val");
        if (value == null || value.isBlank()) {
            throw terminal("DOCX_VAL_ATTRIBUTE_REQUIRED:" + element.getLocalName());
        }
        return value;
    }

    private static int requiredInteger(String value, String error) {
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException exception) {
            throw terminal(error);
        }
    }

    private static int requiredNonNegativeInteger(String value, String error) {
        int parsed = requiredInteger(value, error);
        if (parsed < 0) {
            throw terminal(error);
        }
        return parsed;
    }

    private static SourceDomainException terminal(String detail) {
        return new SourceDomainException(
                SourceDomainException.Code.PARSER_TERMINAL_FAILURE,
                detail == null || detail.isBlank() ? "DOCX_TEXT_PARSER_INVARIANT_FAILED" : detail);
    }

    private record StyleDefinition(
            String styleName, Integer headingLevel, Boolean pageBreakBefore, String basedOn) {
        private static final StyleDefinition NONE = new StyleDefinition(null, null, false, null);
    }

    private record Styles(
            Map<String, StyleDefinition> definitions,
            Map<String, StyleDefinition> resolvedDefinitions) {

        private static Styles empty() {
            return new Styles(Map.of(), new HashMap<>());
        }

        private StyleDefinition definition(String styleId) {
            if (styleId == null || !definitions.containsKey(styleId)) {
                return StyleDefinition.NONE;
            }
            StyleDefinition resolved = resolvedDefinitions.get(styleId);
            return resolved == null ? resolve(styleId) : resolved;
        }

        private StyleDefinition resolve(String styleId) {
            List<String> inheritancePath = new ArrayList<>();
            Set<String> resolving = new HashSet<>();
            String currentStyleId = styleId;
            StyleDefinition inherited = StyleDefinition.NONE;
            while (currentStyleId != null) {
                StyleDefinition cached = resolvedDefinitions.get(currentStyleId);
                if (cached != null) {
                    inherited = cached;
                    break;
                }
                StyleDefinition direct = definitions.get(currentStyleId);
                if (direct == null) {
                    throw terminal("PARAGRAPH_STYLE_BASE_MISSING:" + currentStyleId);
                }
                if (!resolving.add(currentStyleId)) {
                    throw terminal("PARAGRAPH_STYLE_INHERITANCE_CYCLE:" + currentStyleId);
                }
                inheritancePath.add(currentStyleId);
                currentStyleId = direct.basedOn();
            }

            for (int index = inheritancePath.size() - 1; index >= 0; index--) {
                String inheritedStyleId = inheritancePath.get(index);
                StyleDefinition direct = definitions.get(inheritedStyleId);
                inherited = new StyleDefinition(
                        direct.styleName(),
                        direct.headingLevel() == null
                                ? inherited.headingLevel()
                                : direct.headingLevel(),
                        direct.pageBreakBefore() == null
                                ? inherited.pageBreakBefore()
                                : direct.pageBreakBefore(),
                        null);
                resolvedDefinitions.put(inheritedStyleId, inherited);
            }
            return resolvedDefinitions.get(styleId);
        }

        private static Styles parse(Document document) {
            Element root = document.getDocumentElement();
            requireWordElement(root, "styles", "STYLES_ROOT_INVALID");
            Map<String, StyleDefinition> definitions = new LinkedHashMap<>();
            for (Node node = root.getFirstChild(); node != null; node = node.getNextSibling()) {
                if (!(node instanceof Element style)
                        || !WORD_NAMESPACE.equals(style.getNamespaceURI())
                        || !"style".equals(style.getLocalName())) {
                    continue;
                }
                String type = style.getAttributeNS(WORD_NAMESPACE, "type");
                if (!"paragraph".equals(type)) {
                    continue;
                }
                String styleId = style.getAttributeNS(WORD_NAMESPACE, "styleId");
                if (styleId == null || styleId.isBlank()) {
                    throw terminal("PARAGRAPH_STYLE_ID_REQUIRED");
                }
                String styleName = optionalVal(onlyDirectChild(style, "name", false));
                String basedOn = optionalVal(onlyDirectChild(style, "basedOn", false));
                Element properties = onlyDirectChild(style, "pPr", false);
                Integer outlineLevel = properties == null
                        ? null
                        : optionalIntegerVal(onlyDirectChild(properties, "outlineLvl", false));
                Boolean pageBreakBefore = properties == null
                        ? null
                        : optionalOnOff(onlyDirectChild(properties, "pageBreakBefore", false));
                StyleDefinition previous = definitions.put(
                        styleId,
                        new StyleDefinition(
                                styleName,
                                outlineLevel == null ? null : headingLevel(outlineLevel),
                                pageBreakBefore,
                                basedOn));
                if (previous != null) {
                    throw terminal("DUPLICATE_PARAGRAPH_STYLE_ID");
                }
            }
            return new Styles(Map.copyOf(definitions), new HashMap<>());
        }
    }

    private record MarkerPattern(
            String format, String levelText, int start, Integer restartAfterLevel) {}

    private record NumberingInstance(String abstractId, Map<Integer, Integer> startOverrides) {}

    private record Numbering(Map<String, Map<Integer, MarkerPattern>> levelsByNumId) {

        private static Numbering empty() {
            return new Numbering(Map.of());
        }

        private String markerText(String numId, int level, Map<Integer, Integer> ordinals) {
            MarkerPattern pattern = levelsByNumId.getOrDefault(numId, Map.of()).get(level);
            if (pattern == null) {
                return null;
            }
            if ("bullet".equals(pattern.format())) {
                return pattern.levelText();
            }
            if (!"decimal".equals(pattern.format())) {
                return null;
            }
            String marker = pattern.levelText();
            for (int referencedLevel = 0; referencedLevel <= 8; referencedLevel++) {
                String placeholder = "%" + (referencedLevel + 1);
                if (marker.contains(placeholder)) {
                    Integer ordinal = ordinals.get(referencedLevel);
                    MarkerPattern referencedPattern = levelsByNumId
                            .getOrDefault(numId, Map.of())
                            .get(referencedLevel);
                    if (ordinal == null || referencedPattern == null) {
                        return null;
                    }
                    marker = marker.replace(
                            placeholder,
                            Integer.toString(referencedPattern.start() + ordinal));
                }
            }
            return marker;
        }

        private void restartDisplayCounters(
                String numId, int currentLevel, Map<Integer, Integer> displayOrdinals) {
            for (Map.Entry<Integer, MarkerPattern> entry :
                    levelsByNumId.getOrDefault(numId, Map.of()).entrySet()) {
                if (Objects.equals(entry.getValue().restartAfterLevel(), currentLevel)) {
                    displayOrdinals.remove(entry.getKey());
                }
            }
        }

        private static Numbering parse(Document document) {
            Element root = document.getDocumentElement();
            requireWordElement(root, "numbering", "NUMBERING_ROOT_INVALID");
            Map<String, Map<Integer, MarkerPattern>> abstractLevels = new HashMap<>();
            Map<String, NumberingInstance> instancesByNumId = new HashMap<>();
            for (Node node = root.getFirstChild(); node != null; node = node.getNextSibling()) {
                if (!(node instanceof Element element)
                        || !WORD_NAMESPACE.equals(element.getNamespaceURI())) {
                    continue;
                }
                if ("abstractNum".equals(element.getLocalName())) {
                    String abstractId = requiredWordAttribute(element, "abstractNumId");
                    Map<Integer, MarkerPattern> levels = parseLevels(element);
                    if (abstractLevels.put(abstractId, levels) != null) {
                        throw terminal("DUPLICATE_ABSTRACT_NUMBERING_ID");
                    }
                } else if ("num".equals(element.getLocalName())) {
                    String numId = requiredWordAttribute(element, "numId");
                    String abstractId = requiredVal(onlyDirectChild(element, "abstractNumId", true));
                    NumberingInstance instance =
                            new NumberingInstance(abstractId, parseStartOverrides(element));
                    if (instancesByNumId.put(numId, instance) != null) {
                        throw terminal("DUPLICATE_NUMBERING_ID");
                    }
                }
            }
            Map<String, Map<Integer, MarkerPattern>> levelsByNumId = new HashMap<>();
            for (Map.Entry<String, NumberingInstance> entry : instancesByNumId.entrySet()) {
                NumberingInstance instance = entry.getValue();
                Map<Integer, MarkerPattern> levels = abstractLevels.get(instance.abstractId());
                if (levels == null) {
                    throw terminal("NUMBERING_ABSTRACT_DEFINITION_MISSING");
                }
                Map<Integer, MarkerPattern> effectiveLevels = new HashMap<>(levels);
                for (Map.Entry<Integer, Integer> override : instance.startOverrides().entrySet()) {
                    MarkerPattern inherited = effectiveLevels.get(override.getKey());
                    if (inherited == null) {
                        throw terminal("NUMBERING_OVERRIDE_LEVEL_MISSING");
                    }
                    effectiveLevels.put(
                            override.getKey(),
                            new MarkerPattern(
                                    inherited.format(),
                                    inherited.levelText(),
                                    override.getValue(),
                                    inherited.restartAfterLevel()));
                }
                levelsByNumId.put(entry.getKey(), Map.copyOf(effectiveLevels));
            }
            return new Numbering(Map.copyOf(levelsByNumId));
        }

        private static Map<Integer, Integer> parseStartOverrides(Element numberingInstance) {
            Map<Integer, Integer> overrides = new HashMap<>();
            for (Node node = numberingInstance.getFirstChild(); node != null; node = node.getNextSibling()) {
                if (!(node instanceof Element child)) {
                    continue;
                }
                requireWordNamespace(child, "UNSUPPORTED_NUMBERING_INSTANCE_NAMESPACE");
                if ("abstractNumId".equals(child.getLocalName())) {
                    continue;
                }
                if (!"lvlOverride".equals(child.getLocalName())) {
                    throw terminal("UNSUPPORTED_NUMBERING_INSTANCE_ELEMENT:" + child.getLocalName());
                }
                int level = requiredNonNegativeInteger(
                        requiredWordAttribute(child, "ilvl"), "LIST_ITEM_LEVEL_INVALID");
                if (level > 8 || overrides.containsKey(level)) {
                    throw terminal("DUPLICATE_OR_INVALID_NUMBERING_OVERRIDE_LEVEL");
                }
                Element startOverride = onlyDirectChild(child, "startOverride", false);
                for (Node overrideNode = child.getFirstChild();
                        overrideNode != null;
                        overrideNode = overrideNode.getNextSibling()) {
                    if (overrideNode instanceof Element overrideElement
                            && !(WORD_NAMESPACE.equals(overrideElement.getNamespaceURI())
                                    && "startOverride".equals(overrideElement.getLocalName()))) {
                        throw terminal("UNSUPPORTED_NUMBERING_LEVEL_OVERRIDE");
                    }
                }
                if (startOverride == null) {
                    throw terminal("UNSUPPORTED_NUMBERING_LEVEL_OVERRIDE");
                }
                overrides.put(
                        level,
                        requiredNonNegativeInteger(requiredVal(startOverride), "LIST_START_INVALID"));
            }
            return Map.copyOf(overrides);
        }

        private static Map<Integer, MarkerPattern> parseLevels(Element abstractNum) {
            Map<Integer, MarkerPattern> levels = new HashMap<>();
            for (Node node = abstractNum.getFirstChild(); node != null; node = node.getNextSibling()) {
                if (!(node instanceof Element level)
                        || !WORD_NAMESPACE.equals(level.getNamespaceURI())
                        || !"lvl".equals(level.getLocalName())) {
                    continue;
                }
                int itemLevel = requiredNonNegativeInteger(
                        requiredWordAttribute(level, "ilvl"), "LIST_ITEM_LEVEL_INVALID");
                if (itemLevel > 8) {
                    throw terminal("LIST_ITEM_LEVEL_INVALID");
                }
                String format = requiredVal(onlyDirectChild(level, "numFmt", true));
                String levelText = requiredVal(onlyDirectChild(level, "lvlText", true));
                Element startElement = onlyDirectChild(level, "start", false);
                int start = startElement == null
                        ? 1
                        : requiredNonNegativeInteger(requiredVal(startElement), "LIST_START_INVALID");
                Element restartElement = onlyDirectChild(level, "lvlRestart", false);
                Integer restartAfterLevel = defaultRestartAfterLevel(itemLevel, restartElement);
                if (levels.put(
                                itemLevel,
                                new MarkerPattern(format, levelText, start, restartAfterLevel))
                        != null) {
                    throw terminal("DUPLICATE_NUMBERING_LEVEL");
                }
            }
            return Map.copyOf(levels);
        }

        private static Integer defaultRestartAfterLevel(int itemLevel, Element restartElement) {
            if (restartElement == null) {
                return itemLevel == 0 ? null : itemLevel - 1;
            }
            int oneBasedRestartLevel = requiredNonNegativeInteger(
                    requiredVal(restartElement), "LIST_RESTART_LEVEL_INVALID");
            if (oneBasedRestartLevel == 0) {
                return null;
            }
            if (oneBasedRestartLevel > itemLevel) {
                throw terminal("LIST_RESTART_LEVEL_INVALID");
            }
            return oneBasedRestartLevel - 1;
        }

        private static String requiredWordAttribute(Element element, String localName) {
            String value = element.getAttributeNS(WORD_NAMESPACE, localName);
            if (value == null || value.isBlank()) {
                throw terminal("DOCX_ATTRIBUTE_REQUIRED:" + localName);
            }
            return value;
        }
    }

    private static final class ListState {

        private final Numbering numbering;
        private final Map<String, Integer> nextSegmentByNumId = new HashMap<>();
        private ActiveList active;

        private ListState(Numbering numbering) {
            this.numbering = numbering;
        }

        private ListSemantics next(String numId, int level) {
            requiredNonNegativeInteger(numId, "LIST_NUMBERING_ID_INVALID");
            if (level > 8) {
                throw terminal("LIST_ITEM_LEVEL_INVALID");
            }
            if (active == null || !active.numId.equals(numId)) {
                int segment = nextSegmentByNumId.getOrDefault(numId, 0);
                nextSegmentByNumId.put(numId, segment + 1);
                active = new ActiveList(numId, "num-" + numId + "-segment-" + segment);
            }
            int ordinal = active.itemOrdinals.getOrDefault(level, 0);
            active.itemOrdinals.put(level, ordinal + 1);
            numbering.restartDisplayCounters(numId, level, active.displayOrdinals);
            int displayOrdinal = active.displayOrdinals.getOrDefault(level, 0);
            active.displayOrdinals.put(level, displayOrdinal + 1);
            Map<Integer, Integer> currentDisplayOrdinals = new HashMap<>();
            for (Map.Entry<Integer, Integer> entry : active.displayOrdinals.entrySet()) {
                currentDisplayOrdinals.put(entry.getKey(), entry.getValue() - 1);
            }
            return new ListSemantics(
                    active.instanceId,
                    level,
                    ordinal,
                    numbering.markerText(numId, level, currentDisplayOrdinals));
        }

        private void endSegment() {
            active = null;
        }
    }

    private static final class ActiveList {

        private final String numId;
        private final String instanceId;
        private final Map<Integer, Integer> itemOrdinals = new HashMap<>();
        private final Map<Integer, Integer> displayOrdinals = new HashMap<>();

        private ActiveList(String numId, String instanceId) {
            this.numId = numId;
            this.instanceId = instanceId;
        }
    }
}
