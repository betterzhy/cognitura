package io.cognitura.source.docx.table;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public record TableTextEvidence(
        int paragraphIndex, String text, List<Integer> inlineImageOffsets) {

    public TableTextEvidence {
        if (paragraphIndex < 0) {
            throw new IllegalArgumentException("TABLE_TEXT_PARAGRAPH_INDEX_INVALID");
        }
        Objects.requireNonNull(text, "text");
        if (!Normalizer.isNormalized(text, Normalizer.Form.NFC)) {
            throw new IllegalArgumentException("TABLE_TEXT_EVIDENCE_MUST_BE_NFC");
        }
        inlineImageOffsets = List.copyOf(
                Objects.requireNonNull(inlineImageOffsets, "inlineImageOffsets"));
        List<Integer> expectedOffsets = new ArrayList<>();
        int codePointOffset = 0;
        for (int charOffset = 0; charOffset < text.length(); codePointOffset++) {
            int codePoint = text.codePointAt(charOffset);
            if (codePoint == 0xFFFC) {
                expectedOffsets.add(codePointOffset);
            }
            charOffset += Character.charCount(codePoint);
        }
        if (!inlineImageOffsets.equals(expectedOffsets)) {
            throw new IllegalArgumentException("TABLE_IMAGE_ANCHOR_BIJECTION_INVALID");
        }
    }
}
