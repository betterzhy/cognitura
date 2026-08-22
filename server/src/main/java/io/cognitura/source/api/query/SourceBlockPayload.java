package io.cognitura.source.api.query;

import java.io.ByteArrayInputStream;
import java.io.DataInputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;

public sealed interface SourceBlockPayload permits
        SourceBlockPayload.Heading,
        SourceBlockPayload.Paragraph,
        SourceBlockPayload.ListItem,
        SourceBlockPayload.Table,
        SourceBlockPayload.Image {

    int MAX_TEXT_BYTES = 1_048_576;
    int MAX_COLLECTION_SIZE = 100_000;
    int MAX_PAYLOAD_BYTES = 16_777_216;

    record Heading(String text, int level, String styleName) implements SourceBlockPayload {}

    record Paragraph(String text, String styleName) implements SourceBlockPayload {}

    record ListItem(
            String listInstanceId,
            int itemLevel,
            int itemOrdinal,
            String markerText,
            String text) implements SourceBlockPayload {}

    record Table(List<Row> rows) implements SourceBlockPayload {
        public Table { rows = List.copyOf(rows); }
        public record Row(int rowIndex, List<Cell> cells) {
            public Row { cells = List.copyOf(cells); }
        }
        public record Cell(
                int columnIndex, int rowSpan, int columnSpan, String text) {}
    }

    record Image(
            String relationshipMode,
            String externalTargetLiteralSha256,
            String mediaType,
            Long byteLength,
            String contentSha256,
            String securityDisclosure) implements SourceBlockPayload {}

    record DecodedBlock(
            String documentBlockId,
            String sourceDocumentId,
            String revisionId,
            String blockType,
            int sourceOrder,
            List<String> sectionPath,
            String sourcePart,
            int sourceElementIndex,
            SourcePreviewPage.SourceAnchor sourceAnchor,
            String contentHash,
            SourceBlockPayload payload) {}

    static DecodedBlock decodeBlock(byte[] canonical) {
        if (canonical == null || canonical.length == 0 || canonical.length > MAX_PAYLOAD_BYTES) {
            throw invalid();
        }
        try (DataInputStream input = new DataInputStream(new ByteArrayInputStream(canonical))) {
            String blockId = readText(input);
            String sourceId = readText(input);
            String revisionId = readText(input);
            String blockType = readText(input);
            int sourceOrder = input.readInt();
            List<String> sectionPath = readTextList(input);
            boolean hasPageNumber = input.readBoolean();
            boolean hasPageEvidence = input.readBoolean();
            if (hasPageNumber || hasPageEvidence || sourceOrder < 0) throw invalid();
            String anchorKind = readText(input);
            String sourcePart = readText(input);
            int sourceElementIndex = input.readInt();
            String parentBlockId = readNullableText(input);
            Integer textOffset = readNullableInteger(input);
            Integer childOrdinal = readNullableInteger(input);
            Integer rowIndex = readNullableInteger(input);
            Integer columnIndex = readNullableInteger(input);
            String contentHash = readText(input);
            int payloadLength = input.readInt();
            if (payloadLength < 0 || payloadLength > MAX_PAYLOAD_BYTES) throw invalid();
            byte[] payloadBytes = input.readNBytes(payloadLength);
            if (payloadBytes.length != payloadLength || input.available() != 0
                    || sourceElementIndex < 0
                    || !contentHash.matches("[0-9a-f]{64}")
                    || !contentHash.equals(sha256(payloadBytes))) {
                throw invalid();
            }
            requireFactText(blockId);
            requireFactText(sourceId);
            requireFactText(revisionId);
            requireFactText(sourcePart);
            for (String section : sectionPath) requireFactText(section);
            validateAnchor(anchorKind, parentBlockId, textOffset, childOrdinal,
                    rowIndex, columnIndex);
            SourcePreviewPage.SourceAnchor anchor = new SourcePreviewPage.SourceAnchor(
                    webAnchorKind(anchorKind), parentBlockId, textOffset,
                    childOrdinal, rowIndex, columnIndex);
            return new DecodedBlock(
                    blockId, sourceId, revisionId, blockType, sourceOrder,
                    sectionPath, sourcePart, sourceElementIndex, anchor,
                    contentHash, decodePayload(blockType, payloadBytes));
        } catch (IOException | RuntimeException error) {
            if (error instanceof IllegalArgumentException
                    && "PREVIEW_FACTS_INVALID".equals(error.getMessage())) {
                throw (IllegalArgumentException) error;
            }
            throw invalid();
        }
    }

    private static SourceBlockPayload decodePayload(String blockType, byte[] payload) {
        return switch (blockType) {
            case "HEADING" -> decodeHeading(payload);
            case "PARAGRAPH" -> decodeParagraph(payload);
            case "LIST" -> decodeList(payload);
            case "TABLE" -> decodeTable(payload);
            case "IMAGE" -> decodeImage(payload);
            default -> throw invalid();
        };
    }

    private static Heading decodeHeading(byte[] payload) {
        try (DataInputStream input = input(payload, "HEADING_PAYLOAD_V1")) {
            Heading value = new Heading(readText(input), input.readInt(), readNullableText(input));
            requireEnd(input);
            if (value.text().isBlank() || value.level() < 1 || value.level() > 9
                    || blankWhenPresent(value.styleName())) throw invalid();
            return value;
        } catch (IOException error) {
            throw invalid();
        }
    }

    private static Paragraph decodeParagraph(byte[] payload) {
        try (DataInputStream input = input(payload, "PARAGRAPH_PAYLOAD_V1")) {
            Paragraph value = new Paragraph(readText(input), readNullableText(input));
            requireEnd(input);
            if (blankWhenPresent(value.styleName())) throw invalid();
            return value;
        } catch (IOException error) {
            throw invalid();
        }
    }

    private static ListItem decodeList(byte[] payload) {
        try (DataInputStream input = input(payload, "LIST_PAYLOAD_V1")) {
            ListItem value = new ListItem(
                    readText(input), input.readInt(), input.readInt(),
                    readNullableText(input), readText(input));
            requireEnd(input);
            if (value.listInstanceId().isBlank()
                    || value.itemLevel() < 0 || value.itemLevel() > 8
                    || value.itemOrdinal() < 0 || blankWhenPresent(value.markerText())) {
                throw invalid();
            }
            return value;
        } catch (IOException error) {
            throw invalid();
        }
    }

    private static Table decodeTable(byte[] payload) {
        try (DataInputStream input = input(payload, "TABLE_PAYLOAD_V1")) {
            int rowCount = readSize(input);
            List<Table.Row> rows = new ArrayList<>(rowCount);
            for (int row = 0; row < rowCount; row++) {
                int rowIndex = input.readInt();
                int cellCount = readSize(input);
                if (rowIndex != row) throw invalid();
                List<Table.Cell> cells = new ArrayList<>(cellCount);
                int previousColumn = -1;
                for (int cell = 0; cell < cellCount; cell++) {
                    int columnIndex = input.readInt();
                    int rowSpan = input.readInt();
                    int columnSpan = input.readInt();
                    if (columnIndex <= previousColumn || rowSpan < 1 || columnSpan < 1) {
                        throw invalid();
                    }
                    previousColumn = columnIndex;
                    cells.add(new Table.Cell(
                            columnIndex, rowSpan, columnSpan, readText(input)));
                }
                rows.add(new Table.Row(rowIndex, cells));
            }
            requireEnd(input);
            return new Table(rows);
        } catch (IOException error) {
            throw invalid();
        }
    }

    private static Image decodeImage(byte[] payload) {
        ImageFields fields = ImageFields.parse(payload);
        String mode = fields.values().get(1);
        String externalDigest = fields.values().get(2);
        String mediaRef = fields.values().get(3);
        String mediaType = fields.values().get(4);
        String byteLengthText = fields.values().get(5);
        String contentDigest = fields.values().get(6);
        String disclosure = fields.values().get(7);
        if (fields.values().get(0) == null || mode == null) throw invalid();
        if ("INTERNAL".equals(mode)) {
            if (externalDigest != null || mediaRef == null || mediaType == null
                    || byteLengthText == null || contentDigest == null || disclosure != null
                    || !contentDigest.matches("[0-9a-f]{64}")) {
                throw invalid();
            }
            try {
                long byteLength = Long.parseLong(byteLengthText);
                if (byteLength <= 0) throw invalid();
                return new Image(mode, null, mediaType, byteLength, contentDigest, null);
            } catch (NumberFormatException error) {
                throw invalid();
            }
        }
        if ("EXTERNAL".equals(mode)) {
            if (externalDigest == null || !externalDigest.matches("[0-9a-f]{64}")
                    || mediaRef != null || mediaType != null || byteLengthText != null
                    || contentDigest != null
                    || !"EXTERNAL_RELATIONSHIP_NOT_DEREFERENCED".equals(disclosure)) {
                throw invalid();
            }
            return new Image(mode, externalDigest, null, null, null, disclosure);
        }
        throw invalid();
    }

    private static DataInputStream input(byte[] payload, String expectedKind) throws IOException {
        DataInputStream input = new DataInputStream(new ByteArrayInputStream(payload));
        if (!expectedKind.equals(readText(input))) throw invalid();
        return input;
    }

    private static List<String> readTextList(DataInputStream input) throws IOException {
        int size = readSize(input);
        List<String> values = new ArrayList<>(size);
        for (int index = 0; index < size; index++) values.add(readText(input));
        return List.copyOf(values);
    }

    private static int readSize(DataInputStream input) throws IOException {
        int size = input.readInt();
        if (size < 0 || size > MAX_COLLECTION_SIZE) throw invalid();
        return size;
    }

    private static String readText(DataInputStream input) throws IOException {
        int length = input.readInt();
        if (length < 0 || length > MAX_TEXT_BYTES) throw invalid();
        byte[] bytes = input.readNBytes(length);
        if (bytes.length != length) throw invalid();
        return decodeUtf8(bytes);
    }

    private static String readNullableText(DataInputStream input) throws IOException {
        return input.readBoolean() ? readText(input) : null;
    }

    private static Integer readNullableInteger(DataInputStream input) throws IOException {
        return input.readBoolean() ? input.readInt() : null;
    }

    private static void requireEnd(DataInputStream input) throws IOException {
        if (input.available() != 0) throw invalid();
    }

    private static String webAnchorKind(String internalKind) {
        return switch (internalKind) {
            case "TOP_LEVEL" -> "FLOW";
            case "PARAGRAPH_INLINE", "TABLE_CELL_INLINE" -> internalKind;
            default -> throw invalid();
        };
    }

    private static void validateAnchor(
            String kind,
            String parentBlockId,
            Integer textOffset,
            Integer childOrdinal,
            Integer rowIndex,
            Integer columnIndex) {
        boolean valid = switch (kind) {
            case "TOP_LEVEL" -> parentBlockId == null && textOffset == null
                    && childOrdinal == null && rowIndex == null && columnIndex == null;
            case "PARAGRAPH_INLINE" -> validParent(parentBlockId)
                    && nonNegative(textOffset) && nonNegative(childOrdinal)
                    && rowIndex == null && columnIndex == null;
            case "TABLE_CELL_INLINE" -> validParent(parentBlockId)
                    && nonNegative(textOffset) && nonNegative(childOrdinal)
                    && nonNegative(rowIndex) && nonNegative(columnIndex);
            default -> false;
        };
        if (!valid) throw invalid();
    }

    private static boolean validParent(String value) {
        return value != null && !value.isBlank();
    }

    private static boolean nonNegative(Integer value) {
        return value != null && value >= 0;
    }

    private static boolean blankWhenPresent(String value) {
        return value != null && value.isBlank();
    }

    private static void requireFactText(String value) {
        if (value.isBlank() || !Normalizer.isNormalized(value, Normalizer.Form.NFC)
                || value.chars().anyMatch(Character::isISOControl)) {
            throw invalid();
        }
    }

    private static String decodeUtf8(byte[] bytes) {
        try {
            return StandardCharsets.UTF_8.newDecoder()
                    .onMalformedInput(CodingErrorAction.REPORT)
                    .onUnmappableCharacter(CodingErrorAction.REPORT)
                    .decode(ByteBuffer.wrap(bytes)).toString();
        } catch (CharacterCodingException error) {
            throw invalid();
        }
    }

    private static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException("SHA_256_ALGORITHM_UNAVAILABLE", error);
        }
    }

    private static IllegalArgumentException invalid() {
        return new IllegalArgumentException("PREVIEW_FACTS_INVALID");
    }

    record ImageFields(List<String> values) {
        private static final byte[] PREFIX =
                "IMAGE_PAYLOAD_V1".getBytes(StandardCharsets.US_ASCII);

        static ImageFields parse(byte[] payload) {
            if (payload.length < PREFIX.length
                    || !MessageDigest.isEqual(
                            java.util.Arrays.copyOf(payload, PREFIX.length), PREFIX)) {
                throw invalid();
            }
            int offset = PREFIX.length;
            List<String> values = new ArrayList<>(8);
            for (int field = 0; field < 8; field++) {
                if (offset >= payload.length || payload[offset++] != '|') throw invalid();
                int colon = offset;
                while (colon < payload.length && payload[colon] != ':') colon++;
                if (colon == payload.length) throw invalid();
                String lengthText = new String(
                        payload, offset, colon - offset, StandardCharsets.US_ASCII);
                int length;
                try {
                    length = Integer.parseInt(lengthText);
                } catch (NumberFormatException error) {
                    throw invalid();
                }
                offset = colon + 1;
                if (length == -1) {
                    values.add(null);
                    continue;
                }
                if (length < 0 || length > MAX_TEXT_BYTES || offset + length > payload.length) {
                    throw invalid();
                }
                values.add(decodeUtf8(java.util.Arrays.copyOfRange(
                        payload, offset, offset + length)));
                offset += length;
            }
            if (offset != payload.length) throw invalid();
            return new ImageFields(java.util.Collections.unmodifiableList(values));
        }
    }
}
