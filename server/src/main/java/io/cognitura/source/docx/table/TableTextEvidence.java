package io.cognitura.source.docx.table;

import java.text.Normalizer;
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
        int previous = -1;
        for (Integer offset : inlineImageOffsets) {
            if (offset == null
                    || offset <= previous
                    || offset < 0
                    || offset >= text.length()
                    || text.charAt(offset) != '\uFFFC') {
                throw new IllegalArgumentException("TABLE_IMAGE_ANCHOR_OFFSET_INVALID");
            }
            previous = offset;
        }
    }
}
