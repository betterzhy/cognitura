package io.cognitura.source.docx.table;

import io.cognitura.source.docx.security.SafeDocxPackage;
import io.cognitura.source.domain.SourceDomainException;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.text.Normalizer;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.IdentityHashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;
import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.xml.sax.SAXException;

public final class TableFidelityParser {

    private static final String WORD_NAMESPACE =
            "http://schemas.openxmlformats.org/wordprocessingml/2006/main";
    private static final String MAIN_DOCUMENT_PART = "word/document.xml";
    private static final char INLINE_IMAGE_ANCHOR = '\uFFFC';

    public List<TableBlockCandidate> parse(SafeDocxPackage safePackage) {
        Objects.requireNonNull(safePackage, "safePackage");
        try {
            Document document = parseXml(safePackage.readVerifiedEntry(MAIN_DOCUMENT_PART));
            return parseDocument(document);
        } catch (SourceDomainException error) {
            throw error;
        } catch (IllegalArgumentException error) {
            throw terminal(error.getMessage());
        }
    }

    private static List<TableBlockCandidate> parseDocument(Document document) {
        Element root = document.getDocumentElement();
        requireWordElement(root, "document", "MAIN_DOCUMENT_ROOT_INVALID");
        Element body = onlyDirectChild(root, "body", true);
        IdentityHashMap<Element, Integer> elementIndexes = preorderElementIndexes(root);
        List<TableBlockCandidate> tables = new ArrayList<>();
        int sourceOrder = 0;

        for (Node node = body.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (!(node instanceof Element element)) {
                continue;
            }
            requireWordNamespace(element, "UNSUPPORTED_DOCX_TABLE_FLOW_NAMESPACE");
            switch (element.getLocalName()) {
                case "p" -> sourceOrder = advanceSourceOrder(
                        sourceOrder, countInlineImageElements(element));
                case "tbl" -> {
                    TableBlockCandidate table = parseTable(
                            element, elementIndexes.get(element), sourceOrder);
                    tables.add(table);
                    sourceOrder = advanceSourceOrder(sourceOrder, countInlineImages(table));
                }
                case "sectPr" -> {
                    // Section metadata is not a source block.
                }
                default -> throw terminal(
                        "UNSUPPORTED_DOCX_TABLE_FLOW:" + element.getLocalName());
            }
        }
        return List.copyOf(tables);
    }

    private static TableBlockCandidate parseTable(
            Element table, int sourceElementIndex, int sourceOrder) {
        onlyDirectChild(table, "tblPr", false);
        Element grid = onlyDirectChild(table, "tblGrid", true);
        int columnCount = countGridColumns(grid);
        List<Element> rows = new ArrayList<>();
        for (Node node = table.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (!(node instanceof Element element)) {
                continue;
            }
            requireWordNamespace(element, "UNSUPPORTED_DOCX_TABLE_FLOW_NAMESPACE");
            switch (element.getLocalName()) {
                case "tblPr", "tblGrid" -> {
                    // Structural metadata was validated above.
                }
                case "tr" -> rows.add(element);
                default -> throw terminal(
                        "UNSUPPORTED_DOCX_TABLE_FLOW:table/" + element.getLocalName());
            }
        }
        if (rows.isEmpty()) {
            throw terminal("TABLE_ROW_REQUIRED");
        }
        TableBlockCandidate.requireGridWithinLimits(rows.size(), columnCount);

        List<MutableCell> cells = new ArrayList<>();
        Map<Integer, ActiveVerticalMerge> activeMerges = Map.of();
        for (int rowIndex = 0; rowIndex < rows.size(); rowIndex++) {
            activeMerges = parseRow(
                    rows.get(rowIndex), rowIndex, columnCount, activeMerges, cells);
        }

        List<TableCellCandidate> candidates = cells.stream()
                .map(MutableCell::toCandidate)
                .toList();
        List<TableMergeProjection> merges = candidates.stream()
                .filter(cell -> cell.rowSpan() > 1 || cell.columnSpan() > 1)
                .map(TableMergeProjection::fromCell)
                .toList();
        return new TableBlockCandidate(
                sourceOrder,
                MAIN_DOCUMENT_PART,
                sourceElementIndex,
                rows.size(),
                columnCount,
                candidates,
                merges);
    }

    private static Map<Integer, ActiveVerticalMerge> parseRow(
            Element row,
            int rowIndex,
            int columnCount,
            Map<Integer, ActiveVerticalMerge> previousMerges,
            List<MutableCell> cells) {
        Element rowProperties = onlyDirectChild(row, "trPr", false);
        if (rowProperties != null
                && onlyDirectChild(rowProperties, "gridBefore", false) != null) {
            throw terminal("UNSUPPORTED_DOCX_TABLE_STRUCTURE:gridBefore");
        }
        if (rowProperties != null
                && onlyDirectChild(rowProperties, "gridAfter", false) != null) {
            throw terminal("UNSUPPORTED_DOCX_TABLE_STRUCTURE:gridAfter");
        }
        List<Element> rowCells = new ArrayList<>();
        for (Node node = row.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (!(node instanceof Element element)) {
                continue;
            }
            requireWordNamespace(element, "UNSUPPORTED_DOCX_TABLE_FLOW_NAMESPACE");
            switch (element.getLocalName()) {
                case "trPr" -> {
                    // Row presentation metadata is outside the fidelity payload.
                }
                case "tc" -> rowCells.add(element);
                default -> throw terminal(
                        "UNSUPPORTED_DOCX_TABLE_FLOW:row/" + element.getLocalName());
            }
        }
        if (rowCells.isEmpty()) {
            throw terminal("TABLE_CELL_REQUIRED");
        }

        Map<Integer, ActiveVerticalMerge> currentMerges = new LinkedHashMap<>();
        int columnIndex = 0;
        for (Element cellElement : rowCells) {
            CellProperties properties = parseCellProperties(cellElement);
            if (columnIndex + properties.columnSpan() > columnCount) {
                throw terminal("TABLE_CELL_SPAN_OUT_OF_BOUNDS");
            }
            ParsedCellText parsedText = parseCellText(cellElement);
            if (properties.verticalMerge() == VerticalMerge.CONTINUE) {
                ActiveVerticalMerge active = previousMerges.get(columnIndex);
                if (active == null) {
                    throw terminal("TABLE_VERTICAL_MERGE_ANCHOR_MISSING");
                }
                if (active.columnSpan() != properties.columnSpan()) {
                    throw terminal("TABLE_VERTICAL_MERGE_SPAN_MISMATCH");
                }
                if (!parsedText.text().isEmpty()) {
                    throw terminal("TABLE_VERTICAL_MERGE_CONTINUATION_HAS_CONTENT");
                }
                active.anchor().extendTo(rowIndex);
                currentMerges.put(columnIndex, active);
            } else {
                MutableCell cell = new MutableCell(
                        rowIndex,
                        columnIndex,
                        properties.columnSpan(),
                        parsedText.text(),
                        parsedText.evidence());
                cells.add(cell);
                if (properties.verticalMerge() == VerticalMerge.RESTART) {
                    currentMerges.put(
                            columnIndex,
                            new ActiveVerticalMerge(cell, properties.columnSpan()));
                }
            }
            columnIndex += properties.columnSpan();
        }
        if (columnIndex != columnCount) {
            throw terminal("TABLE_ROW_DOES_NOT_FILL_GRID");
        }
        return Map.copyOf(currentMerges);
    }

    private static CellProperties parseCellProperties(Element cell) {
        Element properties = onlyDirectChild(cell, "tcPr", false);
        if (properties == null) {
            return new CellProperties(1, VerticalMerge.NONE);
        }
        if (onlyDirectChild(properties, "hMerge", false) != null) {
            throw terminal("UNSUPPORTED_DOCX_TABLE_STRUCTURE:hMerge");
        }
        Element gridSpan = onlyDirectChild(properties, "gridSpan", false);
        int columnSpan = gridSpan == null
                ? 1
                : requiredPositiveInteger(requiredVal(gridSpan), "TABLE_CELL_SPAN_INVALID");
        Element verticalMerge = onlyDirectChild(properties, "vMerge", false);
        if (verticalMerge == null) {
            return new CellProperties(columnSpan, VerticalMerge.NONE);
        }
        String value = verticalMerge.getAttributeNS(WORD_NAMESPACE, "val");
        if (value.isEmpty() || "continue".equals(value)) {
            return new CellProperties(columnSpan, VerticalMerge.CONTINUE);
        }
        if ("restart".equals(value)) {
            return new CellProperties(columnSpan, VerticalMerge.RESTART);
        }
        throw terminal("TABLE_VERTICAL_MERGE_VALUE_INVALID");
    }

    private static ParsedCellText parseCellText(Element cell) {
        onlyDirectChild(cell, "tcPr", false);
        List<TableTextEvidence> evidence = new ArrayList<>();
        for (Node node = cell.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (!(node instanceof Element element)) {
                continue;
            }
            requireWordNamespace(element, "UNSUPPORTED_DOCX_TABLE_FLOW_NAMESPACE");
            switch (element.getLocalName()) {
                case "tcPr" -> {
                    // Merge metadata was parsed separately.
                }
                case "p" -> evidence.add(parseParagraph(element, evidence.size()));
                case "tbl" -> throw terminal("UNSUPPORTED_DOCX_TABLE_FLOW:nested-table");
                default -> throw terminal(
                        "UNSUPPORTED_DOCX_TABLE_FLOW:cell/" + element.getLocalName());
            }
        }
        if (evidence.isEmpty()) {
            throw terminal("TABLE_CELL_PARAGRAPH_REQUIRED");
        }
        String text = evidence.stream()
                .map(TableTextEvidence::text)
                .collect(Collectors.joining("\n"));
        return new ParsedCellText(text, List.copyOf(evidence));
    }

    private static TableTextEvidence parseParagraph(Element paragraph, int paragraphIndex) {
        StringBuilder text = new StringBuilder();
        for (Node node = paragraph.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (!(node instanceof Element element)) {
                continue;
            }
            requireWordNamespace(element, "UNSUPPORTED_DOCX_TABLE_FLOW_NAMESPACE");
            switch (element.getLocalName()) {
                case "pPr", "bookmarkStart", "bookmarkEnd", "proofErr" -> {
                    // Non-visible paragraph metadata.
                }
                case "r" -> appendRunText(element, text);
                case "hyperlink" -> appendHyperlinkText(element, text);
                default -> throw terminal(
                        "UNSUPPORTED_DOCX_TABLE_FLOW:paragraph/" + element.getLocalName());
            }
        }
        String normalized = normalizeText(text.toString());
        List<Integer> normalizedImageOffsets = new ArrayList<>();
        int codePointOffset = 0;
        for (int charOffset = 0;
                charOffset < normalized.length();
                codePointOffset++) {
            int codePoint = normalized.codePointAt(charOffset);
            if (codePoint == INLINE_IMAGE_ANCHOR) {
                normalizedImageOffsets.add(codePointOffset);
            }
            charOffset += Character.charCount(codePoint);
        }
        return new TableTextEvidence(paragraphIndex, normalized, normalizedImageOffsets);
    }

    private static void appendHyperlinkText(Element hyperlink, StringBuilder text) {
        for (Node node = hyperlink.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (!(node instanceof Element element)) {
                continue;
            }
            requireWordNamespace(element, "UNSUPPORTED_DOCX_TABLE_FLOW_NAMESPACE");
            if (!"r".equals(element.getLocalName())) {
                throw terminal(
                        "UNSUPPORTED_DOCX_TABLE_FLOW:hyperlink/" + element.getLocalName());
            }
            appendRunText(element, text);
        }
    }

    private static void appendRunText(Element run, StringBuilder text) {
        for (Node node = run.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (!(node instanceof Element element)) {
                continue;
            }
            requireWordNamespace(element, "UNSUPPORTED_DOCX_TABLE_FLOW_NAMESPACE");
            switch (element.getLocalName()) {
                case "rPr" -> {
                    // Formatting metadata is not visible text.
                }
                case "t" -> appendTextElement(element, text);
                case "tab" -> text.append('\t');
                case "br" -> appendBreak(element, text);
                case "cr" -> text.append('\n');
                case "noBreakHyphen" -> text.append('\u2011');
                case "softHyphen" -> text.append('\u00ad');
                case "drawing", "pict" -> text.append(INLINE_IMAGE_ANCHOR);
                default -> throw terminal(
                        "UNSUPPORTED_DOCX_TABLE_FLOW:run/" + element.getLocalName());
            }
        }
    }

    private static void appendTextElement(Element textElement, StringBuilder text) {
        for (Node node = textElement.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (node.getNodeType() == Node.TEXT_NODE || node.getNodeType() == Node.CDATA_SECTION_NODE) {
                String value = node.getNodeValue();
                if (value.indexOf(INLINE_IMAGE_ANCHOR) >= 0) {
                    throw terminal("TABLE_LITERAL_IMAGE_PLACEHOLDER_FORBIDDEN");
                }
                text.append(value);
                continue;
            }
            if (node.getNodeType() == Node.COMMENT_NODE
                    || node.getNodeType() == Node.PROCESSING_INSTRUCTION_NODE) {
                continue;
            }
            throw terminal("UNSUPPORTED_DOCX_TABLE_FLOW:run/t/" + node.getNodeName());
        }
    }

    private static void appendBreak(Element breakElement, StringBuilder text) {
        String type = breakElement.getAttributeNS(WORD_NAMESPACE, "type");
        if (type.isEmpty() || "textWrapping".equals(type)) {
            text.append('\n');
            return;
        }
        throw terminal("UNSUPPORTED_DOCX_TABLE_FLOW:run/br@type=" + type);
    }

    private static int countGridColumns(Element grid) {
        int columns = 0;
        for (Node node = grid.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (!(node instanceof Element element)) {
                continue;
            }
            requireWordElement(element, "gridCol", "UNSUPPORTED_DOCX_TABLE_FLOW:table-grid");
            columns++;
        }
        if (columns == 0) {
            throw terminal("TABLE_GRID_COLUMN_REQUIRED");
        }
        return columns;
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
            factory.setFeature(
                    "http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
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

    private static String requiredVal(Element element) {
        String value = element.getAttributeNS(WORD_NAMESPACE, "val");
        if (value == null || value.isBlank()) {
            throw terminal("DOCX_VAL_ATTRIBUTE_REQUIRED:" + element.getLocalName());
        }
        return value;
    }

    private static int requiredPositiveInteger(String value, String error) {
        try {
            int parsed = Integer.parseInt(value);
            if (parsed < 1) {
                throw terminal(error);
            }
            return parsed;
        } catch (NumberFormatException exception) {
            throw terminal(error);
        }
    }

    private static String normalizeText(String text) {
        return Normalizer.normalize(
                text.replace("\r\n", "\n").replace('\r', '\n'), Normalizer.Form.NFC);
    }

    private static int countInlineImageElements(Element container) {
        int count = 0;
        ArrayDeque<Element> pending = new ArrayDeque<>();
        pending.push(container);
        while (!pending.isEmpty()) {
            Element element = pending.pop();
            if (WORD_NAMESPACE.equals(element.getNamespaceURI())
                    && ("drawing".equals(element.getLocalName())
                            || "pict".equals(element.getLocalName()))) {
                count++;
                continue;
            }
            for (Node node = element.getLastChild();
                    node != null;
                    node = node.getPreviousSibling()) {
                if (node instanceof Element child) {
                    pending.push(child);
                }
            }
        }
        return count;
    }

    private static int countInlineImages(TableBlockCandidate table) {
        long count = table.cells().stream()
                .flatMap(cell -> cell.textEvidence().stream())
                .mapToLong(evidence -> evidence.inlineImageOffsets().size())
                .sum();
        if (count > Integer.MAX_VALUE) {
            throw terminal("TABLE_IMAGE_ANCHOR_COUNT_EXCEEDED");
        }
        return (int) count;
    }

    private static int advanceSourceOrder(int current, int inlineImageCount) {
        long next = (long) current + 1 + inlineImageCount;
        if (next > Integer.MAX_VALUE) {
            throw terminal("SOURCE_ORDER_EXCEEDED");
        }
        return (int) next;
    }

    private static SourceDomainException terminal(String detail) {
        return new SourceDomainException(
                SourceDomainException.Code.PARSER_TERMINAL_FAILURE,
                detail == null || detail.isBlank() ? "DOCX_TABLE_PARSER_INVARIANT_FAILED" : detail);
    }

    private enum VerticalMerge {
        NONE,
        RESTART,
        CONTINUE
    }

    private record CellProperties(int columnSpan, VerticalMerge verticalMerge) {}

    private record ParsedCellText(String text, List<TableTextEvidence> evidence) {}

    private record ActiveVerticalMerge(MutableCell anchor, int columnSpan) {}

    private static final class MutableCell {
        private final int rowIndex;
        private final int columnIndex;
        private final int columnSpan;
        private final String text;
        private final List<TableTextEvidence> evidence;
        private int rowSpan = 1;

        private MutableCell(
                int rowIndex,
                int columnIndex,
                int columnSpan,
                String text,
                List<TableTextEvidence> evidence) {
            this.rowIndex = rowIndex;
            this.columnIndex = columnIndex;
            this.columnSpan = columnSpan;
            this.text = text;
            this.evidence = evidence;
        }

        private void extendTo(int continuationRow) {
            if (continuationRow != rowIndex + rowSpan) {
                throw terminal("TABLE_VERTICAL_MERGE_ROW_DISCONTINUITY");
            }
            rowSpan++;
        }

        private TableCellCandidate toCandidate() {
            return new TableCellCandidate(
                    rowIndex, columnIndex, rowSpan, columnSpan, text, evidence);
        }
    }
}
