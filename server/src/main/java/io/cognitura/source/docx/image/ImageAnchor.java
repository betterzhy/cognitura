package io.cognitura.source.docx.image;

import java.util.Objects;

public record ImageAnchor(
        String parentBlockId,
        AnchorKind anchorKind,
        int textOffset,
        int childOrdinal,
        Integer rowIndex,
        Integer columnIndex) {

    public enum AnchorKind {
        PARAGRAPH_INLINE,
        TABLE_CELL_INLINE
    }

    public ImageAnchor {
        requireText(parentBlockId, "IMAGE_PARENT_BLOCK_ID_REQUIRED");
        Objects.requireNonNull(anchorKind, "anchorKind");
        if (textOffset < 0) {
            throw new IllegalArgumentException("IMAGE_TEXT_OFFSET_INVALID");
        }
        if (childOrdinal < 0) {
            throw new IllegalArgumentException("IMAGE_CHILD_ORDINAL_INVALID");
        }
        if (anchorKind == AnchorKind.PARAGRAPH_INLINE
                && (rowIndex != null || columnIndex != null)) {
            throw new IllegalArgumentException("PARAGRAPH_IMAGE_CELL_COORDINATES_FORBIDDEN");
        }
        if (anchorKind == AnchorKind.TABLE_CELL_INLINE
                && (rowIndex == null || rowIndex < 0 || columnIndex == null || columnIndex < 0)) {
            throw new IllegalArgumentException("TABLE_IMAGE_CELL_COORDINATES_REQUIRED");
        }
    }

    private static void requireText(String value, String message) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(message);
        }
    }
}
