# Cognitura W1-I02 Database Gate Design

```text
CanonicalProjectName = Cognitura
DesignKind = MINIMAL_W1_I02_DATABASE_GATE
TransitionKind = I02_DATABASE_GATE_ADMISSION
GateOriginSHA = 8175f340c4f3d116a7aa5bc1f6ee5f67b489dee6
DatabaseGate = W1-I02
DatabaseGateStatus = DESIGN_APPROVED_PENDING_EXECUTION
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
Ultra = NOT_RUN
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. Purpose and authority

W1-D01 intentionally fixes domain semantics without selecting database tables. W1-I02 cannot become
`READY` until an independent database Gate fixes the physical Schema, migration order and isolated
PostgreSQL test boundary. This design supplies that missing decision without starting W1-I02 product
implementation or authorizing any formal database connection or write.

The Gate is deliberately narrow:

- it covers only the three I01 records already present in the Repository: `SourceBinary`,
  `SourceDocument` and `ProcessingRevision`;
- it fixes one Flyway migration, three tables, their constraints and the Java/SQL mapping;
- it proves that the fixed PostgreSQL 18.4 Testcontainers image can start in an isolated container
  and is removed after the probe;
- it adds the one-time successor transition needed after the terminal I06 receipt;
- it does not create runtime persistence code, execute the W1-I02 WriteSet, or release W1-I07.

Source attempt, lease, fencing, heartbeat, block-set publication and completion CAS remain owned by
W1-I07. Parser, API, Web, object storage, deployment and generic database governance are outside this
Gate. No Omini/Harness integration or reusable lifecycle engine is introduced.

## 2. Considered approaches

The selected approach is a pre-implementation physical-Schema admission Gate. It preserves the
existing state machine: design and isolated environment are admitted first, then W1-I02 becomes the
single `READY` card and implements its exact eight-path WriteSet with RED -> GREEN.

Combining Gate and implementation was rejected because it would implement a card while its formal
state is still `QUEUED`. A generic database governance subsystem was rejected because this project
has one current persistence slice and no demonstrated need for a reusable orchestration layer.

## 3. Physical Schema decision

### 3.1 General rules

The migration is exactly:

```text
MigrationVersion = V1
MigrationPath = server/src/main/resources/db/migration/V1__create_source_intake.sql
DatabaseSchema = public
IdentifierStorage = text
HashStorage = char(64)
TimestampStorage = timestamptz
StatusStorage = text_with_check_constraint
PostgreSQLEnumTypes = NONE
JSONB = NONE
Triggers = NONE
StoredProcedures = NONE
```

Identifiers remain `text` because the I01 domain contract requires nonblank identity but does not
authorize an arbitrary length limit or UUID-only representation. Every domain string that is
required by I01 has `CHECK (btrim(value) <> '')`. SHA-256 values additionally have the lower-case
hexadecimal check `value ~ '^[0-9a-f]{64}$'`. Java `Instant` maps to `timestamptz`; the JDBC driver
must preserve the instant rather than a local wall-clock representation.

PostgreSQL enum types are not used. Closed status and failure-code sets use `text` plus named check
constraints so later contract versions can evolve through ordinary Flyway migrations without
irreversible enum surgery.

### 3.2 `source_binary`

```text
source_binary_id text primary key
content_sha256 char(64) not null unique
byte_length bigint not null check (byte_length > 0)
media_type text not null check (btrim(media_type) <> '')
binary_location text not null check (btrim(binary_location) <> '')
created_at timestamptz not null
```

The table also has a unique key on
`(source_binary_id, content_sha256, byte_length, media_type)`. Its purpose is not a second identity;
it is the target for the composite foreign key that prevents a `source_document` row from claiming
binary facts that differ from the referenced immutable binary.

### 3.3 `source_document`

```text
source_document_id text primary key
workspace_id text not null
source_binary_id text not null
original_file_name text not null
media_type text not null
byte_length bigint not null check (byte_length > 0)
content_sha256 char(64) not null
received_at timestamptz not null
idempotency_key text not null
validation_status text not null
validation_failure_code text null
validation_failure_detail text null
```

Required keys and constraints are:

```text
unique (workspace_id, idempotency_key)
unique (source_document_id, content_sha256)
foreign key (source_binary_id, content_sha256, byte_length, media_type)
  references source_binary(source_binary_id, content_sha256, byte_length, media_type)
validation_status in (RECEIVED, VALIDATING, ACCEPTED, REJECTED)
```

`RECEIVED`, `VALIDATING` and `ACCEPTED` require both failure columns to be null. `REJECTED`
requires a nonblank detail and a code in
`(DOCX_SECURITY_REJECTED, DOCX_FORMAT_INVALID)`. Workspace and idempotency values are nonblank.
The composite binary foreign key enforces the I01 invariant that document and binary share hash,
length and media type, rather than relying only on adapter discipline.

### 3.4 `source_processing_revision`

```text
source_processing_revision_id text primary key
source_document_id text not null
content_sha256 char(64) not null
parser_profile_version text not null
revision_status text not null
failure_code text null
failure_detail text null
started_at timestamptz not null
completed_at timestamptz null
```

Required keys and constraints are:

```text
unique (source_document_id, content_sha256, parser_profile_version)
foreign key (source_document_id, content_sha256)
  references source_document(source_document_id, content_sha256)
revision_status in
  (PARSING, PARSED, PREVIEW_READY, FAILED_RETRYABLE, FAILED_TERMINAL)
```

State-shape checks mirror `ProcessingRevision.restore`:

- `PARSING`: failure columns and `completed_at` are null;
- `PARSED` and `PREVIEW_READY`: failure columns are null and `completed_at` is nonnull;
- `FAILED_RETRYABLE`: code is `PARSER_RETRYABLE_FAILURE`, detail is nonblank and
  `completed_at` is nonnull;
- `FAILED_TERMINAL`: code is `PARSER_TERMINAL_FAILURE` or `DOCX_FORMAT_INVALID`, detail is
  nonblank and `completed_at` is nonnull.

No attempt or publication column is added early. W1-I07 will introduce those facts through a later
versioned migration after its own contract and Gate.

## 4. Migration and mapping boundary

The V1 migration creates tables in dependency order:

```text
1. source_binary
2. source_document
3. source_processing_revision
```

It contains only deterministic DDL and named constraints. It contains no seed data, extension,
role, grant, database creation, schema drop, destructive statement or environment-specific value.
Reapplying the same Flyway migration history must report the version as already applied; manually
executing the V1 body twice is not a supported migration path and must fail rather than silently
masking drift.

W1-I02 maps the three tables through the three declared row records and the single
`SourceDocumentMapper`. The Mapper may use annotations because every I02 query is fixed and local;
it may not introduce an XML mapper outside the card WriteSet. `SourcePersistenceAdapter` performs
domain/row conversion and exposes source persistence operations only. It does not become an
application service, parser coordinator or transaction engine for W1-I07.

Database constraint names are mapped to stable persistence errors in the adapter. Unknown SQLState
or unknown constraint names are not reclassified as idempotency or uniqueness conflicts; they
remain infrastructure failures. Workspace-scoped lookup always requires both `workspace_id` and
`idempotency_key`; a key-only query is forbidden.

## 5. Isolated database Gate

The only allowed database environment is an invocation-owned Testcontainers instance using:

```text
PostgreSQLTestImage = postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a
ExpectedPostgreSQLMajor = 18
FormalDatabaseConnection = FORBIDDEN
HostDatabaseURLInput = FORBIDDEN
HostDatabaseCredentialInput = FORBIDDEN
ContainerReuse = FALSE
ContainerRemovalRequired = TRUE
```

The Gate probe records the container ID, image ID/digest, reported server version, generated
database name and removal result in command output. It must reject a wrong image reference, a
non-18 server, reuse, host-provided JDBC URL/user/password, a container that remains running, or a
probe that cannot prove removal. The output is evidence for the current execution only; no password
or reusable credential is committed.

This probe proves environment identity and isolation. It does not execute the future V1 migration.
The actual migration, constraints and round-trip behavior are proved during W1-I02 RED -> GREEN by
`SourcePersistenceIntegrationTest`. This avoids maintaining a second copy of production DDL in the
Gate.

## 6. Append-only governance and release

The current I06 terminal verifier permits no ordinary successor. The database Gate therefore uses
one append-only, fixed-purpose successor chain beginning at `GateOriginSHA`. The implementation plan
must bind the exact order and identities of these paths:

```text
docs/superpowers/specs/2026-08-21-cognitura-w1-i02-database-gate-design.md
docs/superpowers/plans/2026-08-21-cognitura-w1-i02-database-gate.md
tests/task-cards/verify-wave1-implementation-cards.sh
scripts/verify-wave1-implementation-cards
```

Each governance commit is single-parent, nonempty, NUL-free and free of rename/copy or mode drift.
The documents are `100644`; scripts are `100755`. The chain may only add this Gate and its public
verification. It may not alter I06 product, I02 product WriteSet, existing receipts, formal database
authorization or push state.

At the governance tip the task set remains `BLOCKED_BY_DATABASE_GATE`, I02 remains `QUEUED`, there
is no `READY` card, and the public verifier reports `W1I02DatabaseGateStatus = PENDING_REVIEW`.
The focused Gate and full Wave 1 verifier must pass before one `deep_reviewer/xhigh/ONE` review of
the fixed governance candidate. Ultra is not run.

After a zero-finding review, the only legal admission receipt is the direct projection child that
changes exactly these ten paths:

```text
AGENTS.md
README.md
docs/design/wave-1/README.md
docs/engineering/cognitura-design-index.md
docs/engineering/cognitura-wave-1-design-plan.md
docs/engineering/cognitura-wave-1-design-acceptance.md
docs/engineering/cognitura-wave-1-implementation-plan.md
docs/task-cards/wave-1/README.md
docs/task-cards/wave-1-implementation/README.md
docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md
```

The projection sets exactly:

```text
TaskCardSetStatus = READY_FOR_EXECUTION
ActiveTaskCard = W1-I02
ReadyTaskCardCount = 1
W1-I02 Status = READY
W1-I02 BusinessImplementationAuthorization = USER_AUTHORIZED
W1-I02 FormalDatabaseGate = PASS
W1-I06 Status = DONE
W1-I07 Status = BLOCKED_BY_DEPENDENCY
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The terminal implementation-plan receipt binds the reviewed Gate Candidate/Parent/Tree, the fixed
PostgreSQL image, isolated lifecycle PASS, zero findings, `ReleasedTaskCard = W1-I02`,
`FormalDatabaseWrite = NOT_AUTHORIZED` and `RemotePush = NOT_AUTHORIZED`. No other card is released.

## 7. Required contract matrix

The public verifier and real-Git focused tests must prove every class below. The implementation
plan fixes the exact case inventory and stable diagnostics before the RED test commit:

Positive:

1. exact Gate governance chain remains blocked and reports `PENDING_REVIEW`;
2. exact isolated PostgreSQL 18.4 lifecycle starts and is removed;
3. explicit direct admission receipt releases only I02;
4. static admission state has exactly one READY card, I02.

Negative:

1. wrong/mutable/unpinned image, wrong major version, reuse or host DB input;
2. missing container identity or removal proof;
3. governance merge, empty commit, wrong order/path/mode, rename/copy or NUL;
4. wrong reviewed Gate identity, nonzero finding, Ultra use or nonterminal receipt;
5. missing/extra admission path, non-direct receipt or second admission;
6. I02 READY without both business authorization and Database Gate PASS;
7. I07 READY, a second READY card, or any I02 product path changed during admission;
8. formal database write, deployment or remote push authorization drift;
9. any descendant before receipt outside the four Gate paths, or after receipt outside the exact
   W1-I02 WriteSet.

Completion of this Gate proves only that I02 may start. It does not prove W1-I02 migration or
persistence behavior complete. Those claims require the card's isolated integration test, full
Wave Gate, fixed product candidate and its separate zero-finding review.
