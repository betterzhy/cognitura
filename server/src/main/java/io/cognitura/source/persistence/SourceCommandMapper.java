package io.cognitura.source.persistence;

import java.time.Instant;
import org.apache.ibatis.annotations.Arg;
import org.apache.ibatis.annotations.ConstructorArgs;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

public interface SourceCommandMapper {

    @Select("""
            select source_document_id, workspace_id, source_binary_id, original_file_name,
                   media_type, byte_length, content_sha256, received_at, idempotency_key,
                   validation_status
            from source_document
            where workspace_id = #{workspaceId} and idempotency_key = #{idempotencyKey}
            """)
    @ConstructorArgs({
        @Arg(column = "source_document_id", javaType = String.class),
        @Arg(column = "workspace_id", javaType = String.class),
        @Arg(column = "source_binary_id", javaType = String.class),
        @Arg(column = "original_file_name", javaType = String.class),
        @Arg(column = "media_type", javaType = String.class),
        @Arg(column = "byte_length", javaType = long.class),
        @Arg(column = "content_sha256", javaType = String.class),
        @Arg(column = "received_at", javaType = Instant.class),
        @Arg(column = "idempotency_key", javaType = String.class),
        @Arg(column = "validation_status", javaType = String.class)
    })
    DocumentRow selectDocumentByIdempotencyKey(
            @Param("workspaceId") String workspaceId,
            @Param("idempotencyKey") String idempotencyKey);

    @Select("""
            select source_document_id, content_sha256, validation_status,
                   validation_failure_code
            from source_document
            where workspace_id = #{workspaceId} and source_document_id = #{sourceDocumentId}
            """)
    @ConstructorArgs({
        @Arg(column = "source_document_id", javaType = String.class),
        @Arg(column = "content_sha256", javaType = String.class),
        @Arg(column = "validation_status", javaType = String.class),
        @Arg(column = "validation_failure_code", javaType = String.class)
    })
    ProcessingSourceRow selectDocumentByWorkspaceAndId(
            @Param("workspaceId") String workspaceId,
            @Param("sourceDocumentId") String sourceDocumentId);

    @Select("""
            select source_processing_revision_id, revision_status
            from source_processing_revision
            where source_document_id = #{sourceDocumentId}
              and content_sha256 = #{contentSha256}
              and parser_profile_version = #{parserProfileVersion}
            """)
    @ConstructorArgs({
        @Arg(column = "source_processing_revision_id", javaType = String.class),
        @Arg(column = "revision_status", javaType = String.class)
    })
    RevisionRow selectRevision(
            @Param("sourceDocumentId") String sourceDocumentId,
            @Param("contentSha256") String contentSha256,
            @Param("parserProfileVersion") String parserProfileVersion);

    @Select("""
            select source_binary_id, content_sha256, byte_length, media_type,
                   binary_location, created_at
            from source_binary
            where content_sha256 = #{contentSha256}
            """)
    @ConstructorArgs({
        @Arg(column = "source_binary_id", javaType = String.class),
        @Arg(column = "content_sha256", javaType = String.class),
        @Arg(column = "byte_length", javaType = long.class),
        @Arg(column = "media_type", javaType = String.class),
        @Arg(column = "binary_location", javaType = String.class),
        @Arg(column = "created_at", javaType = Instant.class)
    })
    BinaryRow selectBinaryByHash(@Param("contentSha256") String contentSha256);

    @Insert("""
            insert into source_binary (
                source_binary_id, content_sha256, byte_length, media_type,
                binary_location, created_at
            ) values (
                #{sourceBinaryId}, #{contentSha256}, #{byteLength}, #{mediaType},
                #{binaryLocation}, #{createdAt}
            ) on conflict (content_sha256) do nothing
            """)
    int insertBinaryIfAbsent(BinaryRow row);

    @Insert("""
            insert into source_document (
                source_document_id, workspace_id, source_binary_id, original_file_name,
                media_type, byte_length, content_sha256, received_at, idempotency_key,
                validation_status, validation_failure_code, validation_failure_detail
            ) values (
                #{sourceDocumentId}, #{workspaceId}, #{sourceBinaryId}, #{originalFileName},
                #{mediaType}, #{byteLength}, #{contentSha256}, #{receivedAt}, #{idempotencyKey},
                'RECEIVED', null, null
            )
            """)
    int insertDocument(DocumentRow row);

    record BinaryRow(
            String sourceBinaryId,
            String contentSha256,
            long byteLength,
            String mediaType,
            String binaryLocation,
            Instant createdAt) {
    }

    record DocumentRow(
            String sourceDocumentId,
            String workspaceId,
            String sourceBinaryId,
            String originalFileName,
            String mediaType,
            long byteLength,
            String contentSha256,
            Instant receivedAt,
            String idempotencyKey,
            String validationStatus) {
    }

    record RevisionRow(String sourceProcessingRevisionId, String revisionStatus) {
    }

    record ProcessingSourceRow(
            String sourceDocumentId,
            String contentSha256,
            String validationStatus,
            String validationFailureCode) {
    }
}
