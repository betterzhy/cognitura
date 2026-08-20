package io.cognitura.source.docx.text;

public record ListSemantics(
        String listInstanceId,
        int itemLevel,
        int itemOrdinal,
        String markerText) {

    public ListSemantics {
        if (listInstanceId == null || listInstanceId.isBlank()) {
            throw new IllegalArgumentException("LIST_INSTANCE_ID_REQUIRED");
        }
        if (itemLevel < 0 || itemLevel > 8) {
            throw new IllegalArgumentException("LIST_ITEM_LEVEL_OUT_OF_RANGE");
        }
        if (itemOrdinal < 0) {
            throw new IllegalArgumentException("LIST_ITEM_ORDINAL_MUST_NOT_BE_NEGATIVE");
        }
        if (markerText != null && markerText.isBlank()) {
            throw new IllegalArgumentException("LIST_MARKER_TEXT_MUST_BE_NULL_OR_NON_BLANK");
        }
    }
}
