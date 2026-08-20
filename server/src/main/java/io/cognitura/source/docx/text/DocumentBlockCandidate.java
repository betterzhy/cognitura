package io.cognitura.source.docx.text;

import java.text.Normalizer;
import java.util.List;
import java.util.Objects;

public record DocumentBlockCandidate(
        BlockType blockType,
        int sourceOrder,
        List<String> sectionPath,
        String sourcePart,
        int sourceElementIndex,
        String text,
        Integer headingLevel,
        String styleName,
        ListSemantics listSemantics) {

    public enum BlockType {
        HEADING,
        PARAGRAPH,
        LIST
    }

    public DocumentBlockCandidate {
        Objects.requireNonNull(blockType, "blockType");
        if (sourceOrder < 0) {
            throw new IllegalArgumentException("SOURCE_ORDER_MUST_NOT_BE_NEGATIVE");
        }
        sectionPath = List.copyOf(Objects.requireNonNull(sectionPath, "sectionPath"));
        if (sectionPath.stream().anyMatch(value -> value == null || value.isBlank())) {
            throw new IllegalArgumentException("SECTION_PATH_HEADING_REQUIRED");
        }
        sourcePart = requireText(sourcePart, "SOURCE_PART_REQUIRED");
        if (sourceElementIndex < 0) {
            throw new IllegalArgumentException("SOURCE_ELEMENT_INDEX_MUST_NOT_BE_NEGATIVE");
        }
        Objects.requireNonNull(text, "text");
        if (!Normalizer.isNormalized(text, Normalizer.Form.NFC)) {
            throw new IllegalArgumentException("BLOCK_TEXT_MUST_BE_NFC");
        }
        if (styleName != null && styleName.isBlank()) {
            throw new IllegalArgumentException("STYLE_NAME_MUST_BE_NULL_OR_NON_BLANK");
        }
        switch (blockType) {
            case HEADING -> {
                if (headingLevel == null || headingLevel < 1 || headingLevel > 9) {
                    throw new IllegalArgumentException("HEADING_LEVEL_OUT_OF_RANGE");
                }
                if (text.isBlank()) {
                    throw new IllegalArgumentException("HEADING_TEXT_REQUIRED");
                }
                if (listSemantics != null) {
                    throw new IllegalArgumentException("HEADING_CANNOT_HAVE_LIST_SEMANTICS");
                }
            }
            case PARAGRAPH -> {
                if (headingLevel != null || listSemantics != null) {
                    throw new IllegalArgumentException("PARAGRAPH_PAYLOAD_INVALID");
                }
            }
            case LIST -> {
                if (headingLevel != null || listSemantics == null) {
                    throw new IllegalArgumentException("LIST_PAYLOAD_INVALID");
                }
            }
        }
    }

    private static String requireText(String value, String error) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(error);
        }
        return value;
    }
}
