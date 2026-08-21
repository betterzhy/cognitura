create table source_binary (
    source_binary_id text constraint pk_source_binary primary key,
    content_sha256 char(64) not null,
    byte_length bigint not null,
    media_type text not null,
    binary_location text not null,
    created_at timestamptz not null,
    constraint uq_source_binary_content_sha256 unique (content_sha256),
    constraint uq_source_binary_facts
        unique (source_binary_id, content_sha256, byte_length, media_type),
    constraint ck_source_binary_id_nonblank check (btrim(source_binary_id) <> ''),
    constraint ck_source_binary_hash check (content_sha256 ~ '^[0-9a-f]{64}$'),
    constraint ck_source_binary_byte_length check (byte_length > 0),
    constraint ck_source_binary_media_type_nonblank check (btrim(media_type) <> ''),
    constraint ck_source_binary_location_nonblank check (btrim(binary_location) <> '')
);

create table source_document (
    source_document_id text constraint pk_source_document primary key,
    workspace_id text not null,
    source_binary_id text not null,
    original_file_name text not null,
    media_type text not null,
    byte_length bigint not null,
    content_sha256 char(64) not null,
    received_at timestamptz not null,
    idempotency_key text not null,
    validation_status text not null,
    validation_failure_code text,
    validation_failure_detail text,
    constraint uq_source_document_workspace_idempotency
        unique (workspace_id, idempotency_key),
    constraint uq_source_document_identity_hash
        unique (source_document_id, content_sha256),
    constraint fk_source_document_binary_facts
        foreign key (source_binary_id, content_sha256, byte_length, media_type)
        references source_binary (source_binary_id, content_sha256, byte_length, media_type),
    constraint ck_source_document_id_nonblank check (btrim(source_document_id) <> ''),
    constraint ck_source_document_workspace_nonblank check (btrim(workspace_id) <> ''),
    constraint ck_source_document_binary_id_nonblank check (btrim(source_binary_id) <> ''),
    constraint ck_source_document_file_name_nonblank check (btrim(original_file_name) <> ''),
    constraint ck_source_document_media_type_nonblank check (btrim(media_type) <> ''),
    constraint ck_source_document_byte_length check (byte_length > 0),
    constraint ck_source_document_hash check (content_sha256 ~ '^[0-9a-f]{64}$'),
    constraint ck_source_document_idempotency_nonblank check (btrim(idempotency_key) <> ''),
    constraint ck_source_document_validation_status check (
        validation_status in ('RECEIVED', 'VALIDATING', 'ACCEPTED', 'REJECTED')
    ),
    constraint ck_source_document_validation_state check (
        (validation_status in ('RECEIVED', 'VALIDATING', 'ACCEPTED')
            and validation_failure_code is null
            and validation_failure_detail is null)
        or
        (validation_status = 'REJECTED'
            and validation_failure_code in ('DOCX_SECURITY_REJECTED', 'DOCX_FORMAT_INVALID')
            and validation_failure_detail is not null
            and btrim(validation_failure_detail) <> '')
    )
);

create table source_processing_revision (
    source_processing_revision_id text constraint pk_source_processing_revision primary key,
    source_document_id text not null,
    content_sha256 char(64) not null,
    parser_profile_version text not null,
    revision_status text not null,
    failure_code text,
    failure_detail text,
    started_at timestamptz not null,
    completed_at timestamptz,
    constraint uq_source_processing_revision_identity
        unique (source_document_id, content_sha256, parser_profile_version),
    constraint fk_source_processing_revision_document
        foreign key (source_document_id, content_sha256)
        references source_document (source_document_id, content_sha256),
    constraint ck_source_processing_revision_id_nonblank
        check (btrim(source_processing_revision_id) <> ''),
    constraint ck_source_processing_revision_document_id_nonblank
        check (btrim(source_document_id) <> ''),
    constraint ck_source_processing_revision_hash
        check (content_sha256 ~ '^[0-9a-f]{64}$'),
    constraint ck_source_processing_revision_profile_nonblank
        check (btrim(parser_profile_version) <> ''),
    constraint ck_source_processing_revision_status check (
        revision_status in (
            'PARSING', 'PARSED', 'PREVIEW_READY', 'FAILED_RETRYABLE', 'FAILED_TERMINAL'
        )
    ),
    constraint ck_source_processing_revision_state check (
        (revision_status = 'PARSING'
            and failure_code is null
            and failure_detail is null
            and completed_at is null)
        or
        (revision_status in ('PARSED', 'PREVIEW_READY')
            and failure_code is null
            and failure_detail is null
            and completed_at is not null)
        or
        (revision_status = 'FAILED_RETRYABLE'
            and failure_code = 'PARSER_RETRYABLE_FAILURE'
            and failure_detail is not null
            and btrim(failure_detail) <> ''
            and completed_at is not null)
        or
        (revision_status = 'FAILED_TERMINAL'
            and failure_code in ('PARSER_TERMINAL_FAILURE', 'DOCX_FORMAT_INVALID')
            and failure_detail is not null
            and btrim(failure_detail) <> ''
            and completed_at is not null)
    )
);
