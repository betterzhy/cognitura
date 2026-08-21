package io.cognitura.source.persistence;

import java.time.Instant;
import org.apache.ibatis.annotations.Arg;
import org.apache.ibatis.annotations.ConstructorArgs;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

public interface SourceDocumentMapper {

    @Insert("""
            insert into source_binary (
                source_binary_id, content_sha256, byte_length, media_type, binary_location, created_at
            ) values (
                #{sourceBinaryId}, #{contentSha256}, #{byteLength}, #{mediaType},
                #{binaryLocation}, #{createdAt}
            )
            """)
    int insertSourceBinary(SourceBinaryRow row);

    @Insert("""
            insert into source_document (
                source_document_id, workspace_id, source_binary_id, original_file_name,
                media_type, byte_length, content_sha256, received_at, idempotency_key,
                validation_status, validation_failure_code, validation_failure_detail
            ) values (
                #{sourceDocumentId}, #{workspaceId}, #{sourceBinaryId}, #{originalFileName},
                #{mediaType}, #{byteLength}, #{contentSha256}, #{receivedAt}, #{idempotencyKey},
                #{validationStatus}, #{validationFailureCode}, #{validationFailureDetail}
            )
            """)
    int insertSourceDocument(SourceDocumentRow row);

    @Insert("""
            insert into source_processing_revision (
                source_processing_revision_id, source_document_id, content_sha256,
                parser_profile_version, revision_status, failure_code, failure_detail,
                started_at, completed_at
            ) values (
                #{sourceProcessingRevisionId}, #{sourceDocumentId}, #{contentSha256},
                #{parserProfileVersion}, #{revisionStatus}, #{failureCode}, #{failureDetail},
                #{startedAt}, #{completedAt}
            )
            """)
    int insertProcessingRevision(ProcessingRevisionRow row);

    @Select("""
            select source_binary_id, content_sha256, byte_length, media_type, binary_location,
                   created_at
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
    SourceBinaryRow selectSourceBinaryByHash(@Param("contentSha256") String contentSha256);

    @Select("""
            select source_document_id, workspace_id, source_binary_id, original_file_name,
                   media_type, byte_length, content_sha256, received_at, idempotency_key,
                   validation_status, validation_failure_code, validation_failure_detail
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
        @Arg(column = "validation_status", javaType = String.class),
        @Arg(column = "validation_failure_code", javaType = String.class),
        @Arg(column = "validation_failure_detail", javaType = String.class)
    })
    SourceDocumentRow selectSourceDocument(
            @Param("workspaceId") String workspaceId,
            @Param("idempotencyKey") String idempotencyKey);

    @Select("""
            select source_processing_revision_id, source_document_id, content_sha256,
                   parser_profile_version, revision_status, failure_code, failure_detail,
                   started_at, completed_at
            from source_processing_revision
            where source_document_id = #{sourceDocumentId}
              and content_sha256 = #{contentSha256}
              and parser_profile_version = #{parserProfileVersion}
            """)
    @ConstructorArgs({
        @Arg(column = "source_processing_revision_id", javaType = String.class),
        @Arg(column = "source_document_id", javaType = String.class),
        @Arg(column = "content_sha256", javaType = String.class),
        @Arg(column = "parser_profile_version", javaType = String.class),
        @Arg(column = "revision_status", javaType = String.class),
        @Arg(column = "failure_code", javaType = String.class),
        @Arg(column = "failure_detail", javaType = String.class),
        @Arg(column = "started_at", javaType = Instant.class),
        @Arg(column = "completed_at", javaType = Instant.class)
    })
    ProcessingRevisionRow selectProcessingRevision(
            @Param("sourceDocumentId") String sourceDocumentId,
            @Param("contentSha256") String contentSha256,
            @Param("parserProfileVersion") String parserProfileVersion);
}
