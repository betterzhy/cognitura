package io.cognitura.source.docx.table;

import java.text.Normalizer;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

public record TableCellCandidate(
        int rowIndex,
        int columnIndex,
        int rowSpan,
        int columnSpan,
        String text,
        List<TableTextEvidence> textEvidence) {

    public TableCellCandidate {
        if (rowIndex < 0 || columnIndex < 0) {
            throw new IllegalArgumentException("TABLE_CELL_COORDINATE_INVALID");
        }
        if (rowSpan < 1 || columnSpan < 1) {
            throw new IllegalArgumentException("TABLE_CELL_SPAN_INVALID");
        }
        Objects.requireNonNull(text, "text");
        if (!Normalizer.isNormalized(text, Normalizer.Form.NFC)) {
            throw new IllegalArgumentException("TABLE_CELL_TEXT_MUST_BE_NFC");
        }
        textEvidence = List.copyOf(Objects.requireNonNull(textEvidence, "textEvidence"));
        if (textEvidence.isEmpty()) {
            throw new IllegalArgumentException("TABLE_CELL_TEXT_EVIDENCE_REQUIRED");
        }
        for (int index = 0; index < textEvidence.size(); index++) {
            if (textEvidence.get(index).paragraphIndex() != index) {
                throw new IllegalArgumentException("TABLE_TEXT_EVIDENCE_ORDER_INVALID");
            }
        }
        String reconstructed = textEvidence.stream()
                .map(TableTextEvidence::text)
                .collect(Collectors.joining("\n"));
        if (!text.equals(reconstructed)) {
            throw new IllegalArgumentException("TABLE_CELL_TEXT_EVIDENCE_MISMATCH");
        }
    }
}
