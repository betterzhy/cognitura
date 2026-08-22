package io.cognitura.source.api.query;

import io.cognitura.source.application.command.TrustedRequestContext;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;
import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(
        prefix = "cognitura.source-command",
        name = "preview-enabled",
        havingValue = "true")
public final class SourcePreviewQuery {

    private static final int DEFAULT_LIMIT = 100;
    private static final int MAXIMUM_LIMIT = 500;
    private static final int MAX_BLOCKS = 100_000;
    private static final int MAX_CANONICAL_BYTES = 16_777_216;
    private static final long MAX_TOTAL_CANONICAL_BYTES = 268_435_456L;
    private static final String CURSOR_KEY_PROPERTY =
            "cognitura.source-command.preview-cursor-signing-key";

    private final DataSource dataSource;
    private final SourcePreviewCursor cursor;

    @Autowired
    SourcePreviewQuery(DataSource dataSource, Environment environment) {
        this(dataSource, new SourcePreviewCursor(cursorKey(environment)));
    }

    public SourcePreviewQuery(DataSource dataSource, SourcePreviewCursor cursor) {
        this.dataSource = Objects.requireNonNull(dataSource, "dataSource");
        this.cursor = Objects.requireNonNull(cursor, "cursor");
    }

    public SourcePreviewPage preview(
            TrustedRequestContext context,
            String sourceDocumentId,
            String sourceProcessingRevisionId,
            String after,
            Integer requestedLimit) {
        Objects.requireNonNull(context, "context");
        int limit = requestedLimit == null ? DEFAULT_LIMIT : requestedLimit;
        if (limit < 1 || limit > MAXIMUM_LIMIT) {
            throw PreviewException.pagination(sourceDocumentId, sourceProcessingRevisionId);
        }
        try (Connection connection = dataSource.getConnection()) {
            Header header = loadHeader(
                    connection, context.workspaceId(),
                    sourceDocumentId, sourceProcessingRevisionId);
            if (!"PREVIEW_READY".equals(header.revisionStatus())) {
                throw PreviewException.notReady(sourceDocumentId, sourceProcessingRevisionId);
            }
            PublishedSet published = loadPublishedSet(connection, header);
            List<SourcePreviewPage.Omission> omissions =
                    decodeOmissions(published.omissionsCanonical());
            validateHeaderFacts(header, published, omissions);
            int blockCount = validateBlockSet(connection, header);

            int afterOrder = -1;
            if (after != null) {
                try {
                    afterOrder = cursor.decode(
                            after, context.workspaceId(),
                            sourceDocumentId, sourceProcessingRevisionId);
                } catch (IllegalArgumentException error) {
                    throw PreviewException.pagination(
                            sourceDocumentId, sourceProcessingRevisionId);
                }
                if (afterOrder >= blockCount - 1) {
                    throw PreviewException.pagination(
                            sourceDocumentId, sourceProcessingRevisionId);
                }
            }
            PageSlice page = loadPage(connection, header, afterOrder, limit);
            List<SourcePreviewPage.Item> items = new ArrayList<>(page.blocks().size());
            for (StoredBlock stored : page.blocks()) {
                SourceBlockPayload.DecodedBlock block = stored.decoded();
                boolean affected = omissions.stream().anyMatch(omission ->
                        omission.sourcePart().equals(block.sourcePart())
                                && omission.sourceElementIndex() == block.sourceElementIndex());
                items.add(new SourcePreviewPage.Item(
                        block.documentBlockId(), stored.alias(), block.blockType(),
                        block.sourceOrder(), block.sectionPath(), null, null,
                        block.sourceAnchor(), block.contentHash(), block.payload(), affected));
            }
            String nextCursor = page.hasMore()
                    ? cursor.encode(
                            context.workspaceId(), sourceDocumentId,
                            sourceProcessingRevisionId,
                            page.blocks().get(page.blocks().size() - 1).sourceOrder())
                    : null;
            boolean incomplete = "PARTIAL".equals(header.parseCompleteness());
            return new SourcePreviewPage(
                    sourceDocumentId, sourceProcessingRevisionId,
                    header.originalFileName(), header.parseCompleteness(),
                    header.publishedDigest(), header.omissionsDigest(), incomplete,
                    incomplete ? SourcePreviewPage.PARTIAL_WARNING : null,
                    omissions, items, nextCursor);
        } catch (PreviewException error) {
            throw error;
        } catch (SQLException | IllegalArgumentException error) {
            throw PreviewException.notReady(sourceDocumentId, sourceProcessingRevisionId);
        }
    }

    public enum ErrorCode { RESOURCE_NOT_FOUND, PAGINATION_INVALID, PREVIEW_NOT_READY }

    public static final class PreviewException extends RuntimeException {
        private final ErrorCode code;
        private final String sourceDocumentId;
        private final String sourceProcessingRevisionId;

        private PreviewException(
                ErrorCode code, String sourceDocumentId, String sourceProcessingRevisionId) {
            super(code.name());
            this.code = code;
            this.sourceDocumentId = sourceDocumentId;
            this.sourceProcessingRevisionId = sourceProcessingRevisionId;
        }

        static PreviewException notFound() {
            return new PreviewException(ErrorCode.RESOURCE_NOT_FOUND, null, null);
        }

        static PreviewException pagination(String sourceId, String revisionId) {
            return new PreviewException(ErrorCode.PAGINATION_INVALID, sourceId, revisionId);
        }

        static PreviewException notReady(String sourceId, String revisionId) {
            return new PreviewException(ErrorCode.PREVIEW_NOT_READY, sourceId, revisionId);
        }

        public ErrorCode code() { return code; }
        public String sourceDocumentId() { return sourceDocumentId; }
        public String sourceProcessingRevisionId() { return sourceProcessingRevisionId; }
    }

    private static Header loadHeader(
            Connection connection,
            String workspaceId,
            String sourceDocumentId,
            String revisionId) throws SQLException {
        try (PreparedStatement query = connection.prepareStatement("""
                select document.original_file_name, revision.revision_status,
                       revision.published_digest, revision.omissions_digest,
                       revision.parse_completeness,
                       revision.partial_acceptance_status
                from source_document document
                join source_processing_revision revision
                  on revision.source_document_id = document.source_document_id
                where document.workspace_id = ?
                  and document.source_document_id = ?
                  and revision.source_processing_revision_id = ?
                """)) {
            query.setString(1, workspaceId);
            query.setString(2, sourceDocumentId);
            query.setString(3, revisionId);
            try (ResultSet result = query.executeQuery()) {
                if (!result.next()) throw PreviewException.notFound();
                Header header = new Header(
                        sourceDocumentId, revisionId, result.getString(1), result.getString(2),
                        result.getString(3), result.getString(4), result.getString(5),
                        result.getString(6));
                if (result.next()) throw PreviewException.notReady(sourceDocumentId, revisionId);
                return header;
            }
        }
    }

    private static PublishedSet loadPublishedSet(
            Connection connection, Header header) throws SQLException {
        try (PreparedStatement query = connection.prepareStatement("""
                select staged.block_set_digest, staged.omissions_digest,
                       staged.omissions_canonical
                from source_processing_attempt attempt
                join source_processing_staged_set staged
                  on staged.attempt_id = attempt.attempt_id
                where attempt.source_processing_revision_id = ?
                  and attempt.attempt_status = 'SUCCEEDED'
                  and staged.source_document_id = ?
                  and staged.source_processing_revision_id = ?
                order by attempt.generation
                """)) {
            query.setString(1, header.revisionId());
            query.setString(2, header.sourceDocumentId());
            query.setString(3, header.revisionId());
            try (ResultSet result = query.executeQuery()) {
                if (!result.next()) {
                    throw PreviewException.notReady(
                            header.sourceDocumentId(), header.revisionId());
                }
                PublishedSet published = new PublishedSet(
                        result.getString(1), result.getString(2), result.getBytes(3));
                if (result.next()) {
                    throw PreviewException.notReady(
                            header.sourceDocumentId(), header.revisionId());
                }
                return published;
            }
        }
    }

    private static PageSlice loadPage(
            Connection connection, Header header, int afterOrder, int limit) throws SQLException {
        try (PreparedStatement query = connection.prepareStatement("""
                select block.source_order, block.document_block_id,
                       block.canonical_block, alias.alias_identifier
                from source_document_block block
                left join source_reference_alias alias
                  on alias.source_document_id = ?
                 and alias.source_processing_revision_id =
                     block.source_processing_revision_id
                 and alias.document_block_id = block.document_block_id
                where block.source_processing_revision_id = ?
                  and block.source_order > ?
                order by block.source_order
                limit ?
                """)) {
            query.setString(1, header.sourceDocumentId());
            query.setString(2, header.revisionId());
            query.setInt(3, afterOrder);
            query.setInt(4, limit + 1);
            List<StoredBlock> blocks = new ArrayList<>();
            try (ResultSet result = query.executeQuery()) {
                while (result.next()) {
                    int sourceOrder = result.getInt(1);
                    String documentBlockId = result.getString(2);
                    byte[] canonical = result.getBytes(3);
                    String alias = result.getString(4);
                    if (canonical == null || canonical.length > MAX_CANONICAL_BYTES
                            || alias == null || !alias.equals(documentBlockAlias(
                                    header.sourceDocumentId(), header.revisionId(),
                                    documentBlockId))) {
                        throw factsInvalid();
                    }
                    SourceBlockPayload.DecodedBlock decoded =
                            SourceBlockPayload.decodeBlock(canonical);
                    if (sourceOrder != afterOrder + blocks.size() + 1
                            || sourceOrder != decoded.sourceOrder()
                            || !documentBlockId.equals(decoded.documentBlockId())
                            || !header.sourceDocumentId().equals(decoded.sourceDocumentId())
                            || !header.revisionId().equals(decoded.revisionId())) {
                        throw factsInvalid();
                    }
                    blocks.add(new StoredBlock(sourceOrder, canonical, alias, decoded));
                }
            }
            if (blocks.isEmpty()) throw factsInvalid();
            boolean hasMore = blocks.size() > limit;
            if (hasMore) blocks.remove(blocks.size() - 1);
            return new PageSlice(List.copyOf(blocks), hasMore);
        }
    }

    private static void validateHeaderFacts(
            Header header,
            PublishedSet published,
            List<SourcePreviewPage.Omission> omissions) {
        if (header.publishedDigest() == null
                || header.omissionsDigest() == null
                || !header.publishedDigest().matches("[0-9a-f]{64}")
                || !header.omissionsDigest().matches("[0-9a-f]{64}")
                || !header.publishedDigest().equals(published.blockSetDigest())
                || !header.omissionsDigest().equals(published.omissionsDigest())
                || !header.omissionsDigest().equals(sha256(published.omissionsCanonical()))) {
            throw factsInvalid();
        }
        boolean complete = "COMPLETE".equals(header.parseCompleteness())
                && "NOT_APPLICABLE".equals(header.partialAcceptanceStatus())
                && omissions.isEmpty();
        boolean partial = "PARTIAL".equals(header.parseCompleteness())
                && "PENDING".equals(header.partialAcceptanceStatus())
                && !omissions.isEmpty();
        if (!complete && !partial) throw factsInvalid();
    }

    private static int validateBlockSet(Connection connection, Header header) throws SQLException {
        int count;
        try (PreparedStatement query = connection.prepareStatement("""
                select count(*) from source_document_block
                where source_processing_revision_id = ?
                """)) {
            query.setString(1, header.revisionId());
            try (ResultSet result = query.executeQuery()) {
                if (!result.next()) throw factsInvalid();
                count = result.getInt(1);
                if (result.next() || count < 1 || count > MAX_BLOCKS) throw factsInvalid();
            }
        }
        MessageDigest digest = sha256Digest();
        updateInt(digest, count);
        long totalBytes = 0;
        int actualCount = 0;
        try (PreparedStatement query = connection.prepareStatement("""
                select source_order, canonical_block from source_document_block
                where source_processing_revision_id = ? order by source_order
                """)) {
            query.setString(1, header.revisionId());
            try (ResultSet result = query.executeQuery()) {
                while (result.next()) {
                    byte[] canonical = result.getBytes(2);
                    if (result.getInt(1) != actualCount || canonical == null
                            || canonical.length == 0 || canonical.length > MAX_CANONICAL_BYTES) {
                        throw factsInvalid();
                    }
                    totalBytes += canonical.length;
                    if (totalBytes > MAX_TOTAL_CANONICAL_BYTES) throw factsInvalid();
                    updateInt(digest, canonical.length);
                    digest.update(canonical);
                    actualCount++;
                }
            }
        }
        if (actualCount != count
                || !header.publishedDigest().equals(HexFormat.of().formatHex(digest.digest()))) {
            throw factsInvalid();
        }
        return count;
    }

    private static List<SourcePreviewPage.Omission> decodeOmissions(byte[] canonical) {
        if (canonical == null || canonical.length == 0
                || canonical.length > MAX_CANONICAL_BYTES) {
            throw factsInvalid();
        }
        try (DataInputStream input = new DataInputStream(new ByteArrayInputStream(canonical))) {
            int count = input.readInt();
            if (count < 0 || count > MAX_BLOCKS) throw factsInvalid();
            List<SourcePreviewPage.Omission> omissions = new ArrayList<>(count);
            for (int index = 0; index < count; index++) {
                int length = input.readInt();
                if (length < 0 || length > MAX_CANONICAL_BYTES) throw factsInvalid();
                byte[] item = input.readNBytes(length);
                if (item.length != length) throw factsInvalid();
                omissions.add(decodeOmission(item));
            }
            if (input.available() != 0) throw factsInvalid();
            return List.copyOf(omissions);
        } catch (IOException error) {
            throw factsInvalid();
        }
    }

    private static SourcePreviewPage.Omission decodeOmission(byte[] canonical) {
        try (DataInputStream input = new DataInputStream(new ByteArrayInputStream(canonical))) {
            SourcePreviewPage.Omission omission = new SourcePreviewPage.Omission(
                    readText(input), input.readInt(), readText(input), readText(input));
            if (input.available() != 0) throw factsInvalid();
            return omission;
        } catch (IOException error) {
            throw factsInvalid();
        }
    }

    private static String documentBlockAlias(
            String sourceDocumentId, String revisionId, String documentBlockId) {
        try {
            ByteArrayOutputStream bytes = new ByteArrayOutputStream();
            try (DataOutputStream output = new DataOutputStream(bytes)) {
                output.write("cognitura:dbr".getBytes(StandardCharsets.UTF_8));
                output.writeByte(1);
                output.writeByte(3);
                writeText(output, sourceDocumentId);
                writeText(output, revisionId);
                writeText(output, documentBlockId);
            }
            return "dbr:" + sha256(bytes.toByteArray());
        } catch (IOException error) {
            throw new IllegalStateException("PREVIEW_ALIAS_ENCODING_FAILED", error);
        }
    }

    private static void writeText(DataOutputStream output, String value) throws IOException {
        byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
        output.writeInt(bytes.length);
        output.write(bytes);
    }

    private static String readText(DataInputStream input) throws IOException {
        int length = input.readInt();
        if (length < 0 || length > MAX_CANONICAL_BYTES) throw factsInvalid();
        byte[] bytes = input.readNBytes(length);
        if (bytes.length != length) throw factsInvalid();
        try {
            return StandardCharsets.UTF_8.newDecoder()
                    .onMalformedInput(CodingErrorAction.REPORT)
                    .onUnmappableCharacter(CodingErrorAction.REPORT)
                    .decode(ByteBuffer.wrap(bytes)).toString();
        } catch (CharacterCodingException error) {
            throw factsInvalid();
        }
    }

    private static String sha256(byte[] bytes) {
        return HexFormat.of().formatHex(sha256Digest().digest(bytes));
    }

    private static MessageDigest sha256Digest() {
        try {
            return MessageDigest.getInstance("SHA-256");
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException("SHA_256_ALGORITHM_UNAVAILABLE", error);
        }
    }

    private static void updateInt(MessageDigest digest, int value) {
        digest.update((byte) (value >>> 24));
        digest.update((byte) (value >>> 16));
        digest.update((byte) (value >>> 8));
        digest.update((byte) value);
    }

    private static byte[] cursorKey(Environment environment) {
        String encoded = environment.getProperty(CURSOR_KEY_PROPERTY);
        if (encoded == null || encoded.isBlank()) {
            throw new IllegalStateException("PREVIEW_CURSOR_SIGNING_KEY_REQUIRED");
        }
        try {
            return Base64.getDecoder().decode(encoded);
        } catch (IllegalArgumentException error) {
            throw new IllegalStateException("PREVIEW_CURSOR_SIGNING_KEY_INVALID");
        }
    }

    private static IllegalArgumentException factsInvalid() {
        return new IllegalArgumentException("PREVIEW_FACTS_INVALID");
    }

    private record Header(
            String sourceDocumentId,
            String revisionId,
            String originalFileName,
            String revisionStatus,
            String publishedDigest,
            String omissionsDigest,
            String parseCompleteness,
            String partialAcceptanceStatus) {}

    private record PublishedSet(
            String blockSetDigest,
            String omissionsDigest,
            byte[] omissionsCanonical) {
        private PublishedSet {
            omissionsCanonical = omissionsCanonical == null
                    ? null : omissionsCanonical.clone();
        }
    }

    private record StoredBlock(
            int sourceOrder,
            byte[] canonical,
            String alias,
            SourceBlockPayload.DecodedBlock decoded) {
        private StoredBlock {
            canonical = canonical.clone();
        }
    }

    private record PageSlice(List<StoredBlock> blocks, boolean hasMore) {}
}
