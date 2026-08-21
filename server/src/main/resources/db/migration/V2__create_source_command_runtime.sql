alter table source_processing_revision
    add column active_attempt_id text,
    add column current_generation bigint not null default 0,
    add column published_digest char(64),
    add column omissions_digest char(64),
    add column revision_diagnostics bytea,
    add column parse_completeness text,
    add column partial_acceptance_status text;

alter table source_processing_revision
    add constraint ck_source_processing_revision_generation
        check (current_generation >= 0),
    add constraint ck_source_processing_revision_published_digest
        check (published_digest is null or published_digest ~ '^[0-9a-f]{64}$'),
    add constraint ck_source_processing_revision_omissions_digest
        check (omissions_digest is null or omissions_digest ~ '^[0-9a-f]{64}$'),
    add constraint ck_source_processing_revision_parse_completeness
        check (parse_completeness is null or parse_completeness in ('COMPLETE', 'PARTIAL')),
    add constraint ck_source_processing_revision_partial_acceptance
        check (partial_acceptance_status is null
            or partial_acceptance_status in ('NOT_APPLICABLE', 'PENDING'));

create table source_processing_attempt (
    attempt_id text constraint pk_source_processing_attempt primary key,
    source_processing_revision_id text not null,
    attempt_number bigint not null,
    generation bigint not null,
    fencing_token text not null,
    attempt_status text not null,
    lease_expires_at timestamptz,
    heartbeat_at timestamptz,
    failure_code text,
    failure_detail text,
    started_at timestamptz not null,
    completed_at timestamptz,
    constraint fk_source_processing_attempt_revision
        foreign key (source_processing_revision_id)
        references source_processing_revision(source_processing_revision_id),
    constraint uq_source_processing_attempt_generation
        unique (source_processing_revision_id, generation),
    constraint ck_source_processing_attempt_number check (attempt_number > 0),
    constraint ck_source_processing_attempt_generation check (generation > 0),
    constraint ck_source_processing_attempt_status check (
        attempt_status in (
            'PENDING', 'RUNNING', 'SUCCEEDED', 'FAILED_RETRYABLE', 'FAILED_TERMINAL'
        )
    ),
    constraint ck_source_processing_attempt_failure_code check (
        failure_code is null or failure_code in (
            'PARSER_RETRYABLE_FAILURE', 'PARSER_TERMINAL_FAILURE', 'DOCX_FORMAT_INVALID'
        )
    )
);

alter table source_processing_revision
    add constraint fk_source_processing_revision_active_attempt
        foreign key (active_attempt_id)
        references source_processing_attempt(attempt_id)
        deferrable initially deferred;

create table source_processing_staged_set (
    attempt_id text constraint pk_source_processing_staged_set primary key,
    source_document_id text not null,
    source_processing_revision_id text not null,
    parse_completeness text not null,
    partial_acceptance_status text not null,
    block_set_digest char(64) not null,
    omissions_digest char(64) not null,
    omissions_canonical bytea not null,
    revision_diagnostics bytea not null,
    constraint fk_source_processing_staged_set_attempt
        foreign key (attempt_id) references source_processing_attempt(attempt_id),
    constraint fk_source_processing_staged_set_revision
        foreign key (source_processing_revision_id)
        references source_processing_revision(source_processing_revision_id),
    constraint ck_source_processing_staged_set_digest
        check (block_set_digest ~ '^[0-9a-f]{64}$'),
    constraint ck_source_processing_staged_omissions_digest
        check (omissions_digest ~ '^[0-9a-f]{64}$')
);

create table source_processing_staged_block (
    attempt_id text not null,
    source_order integer not null,
    document_block_id text not null,
    canonical_block bytea not null,
    constraint pk_source_processing_staged_block primary key (attempt_id, source_order),
    constraint uq_source_processing_staged_block_id unique (attempt_id, document_block_id),
    constraint fk_source_processing_staged_block_attempt
        foreign key (attempt_id) references source_processing_attempt(attempt_id)
);

create table source_document_block (
    source_processing_revision_id text not null,
    source_order integer not null,
    document_block_id text not null,
    canonical_block bytea not null,
    constraint pk_source_document_block
        primary key (source_processing_revision_id, source_order),
    constraint uq_source_document_block_id
        unique (source_processing_revision_id, document_block_id),
    constraint fk_source_document_block_revision
        foreign key (source_processing_revision_id)
        references source_processing_revision(source_processing_revision_id)
);

create table source_reference_alias (
    alias_identifier varchar(68) constraint pk_source_reference_alias primary key,
    source_document_id text not null,
    source_processing_revision_id text not null,
    document_block_id text not null,
    constraint uq_source_reference_alias_target
        unique (source_document_id, source_processing_revision_id, document_block_id),
    constraint fk_source_reference_alias_revision
        foreign key (source_processing_revision_id)
        references source_processing_revision(source_processing_revision_id)
);

create table source_generation_stage_record (
    stage_record_id bigserial constraint pk_source_generation_stage_record primary key,
    source_processing_revision_id text not null,
    attempt_id text not null,
    terminal_status text not null,
    block_set_digest char(64),
    schema_version text not null,
    run_id text not null,
    stage_name text not null,
    input_hash char(64) not null,
    prompt_version text not null,
    model text not null,
    source_block_refs text not null,
    output_kind text not null,
    output_schema_id text,
    structured_output jsonb,
    output_hash char(64),
    validation_result jsonb not null,
    generation_status text not null,
    retry_count bigint not null,
    retry_scope_refs text not null,
    failure_code text,
    failure_detail text,
    failure_retryable boolean,
    failure_revision_scope text,
    created_at timestamptz not null,
    constraint fk_source_generation_stage_record_revision
        foreign key (source_processing_revision_id)
        references source_processing_revision(source_processing_revision_id),
    constraint fk_source_generation_stage_record_attempt
        foreign key (attempt_id) references source_processing_attempt(attempt_id),
    constraint ck_source_generation_stage_record_status
        check (generation_status in ('SUCCEEDED', 'FAILED')),
    constraint ck_source_generation_stage_record_input_hash
        check (input_hash ~ '^[0-9a-f]{64}$')
);

create table source_processing_rejection_event (
    rejection_event_id bigserial constraint pk_source_processing_rejection_event primary key,
    source_processing_revision_id text not null,
    attempt_id text not null,
    submitted_generation bigint not null,
    current_generation bigint not null,
    reason text not null,
    rejected_at timestamptz not null default clock_timestamp()
);
