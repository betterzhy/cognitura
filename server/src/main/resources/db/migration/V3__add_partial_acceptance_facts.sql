alter table source_processing_revision
    drop constraint ck_source_processing_revision_partial_acceptance;

alter table source_processing_revision
    add column partial_accepted_at timestamptz,
    add column partial_accepted_by text,
    add column partial_acceptance_idempotency_key text;

alter table source_processing_revision
    add constraint ck_source_processing_revision_partial_acceptance
        check (partial_acceptance_status is null
            or partial_acceptance_status in ('NOT_APPLICABLE', 'PENDING', 'ACCEPTED')),
    add constraint ck_source_processing_revision_partial_acceptance_facts
        check (
            (partial_acceptance_status = 'ACCEPTED'
                and revision_status = 'PREVIEW_READY'
                and parse_completeness = 'PARTIAL'
                and partial_accepted_at is not null
                and partial_accepted_by is not null
                and partial_acceptance_idempotency_key is not null)
            or
            (partial_acceptance_status is distinct from 'ACCEPTED'
                and partial_accepted_at is null
                and partial_accepted_by is null
                and partial_acceptance_idempotency_key is null)
        ),
    add constraint ck_source_processing_revision_partial_actor_nonblank
        check (partial_accepted_by is null or btrim(partial_accepted_by) <> ''),
    add constraint ck_source_processing_revision_partial_key_nonblank
        check (partial_acceptance_idempotency_key is null
            or btrim(partial_acceptance_idempotency_key) <> '');
