# W1-I11 Partial Acceptance Persistence Rebaseline Design

```text
ChangeRisk = R2
RebaselineOrigin = b99f20feaa47f36aeb49e05a070bfb3c73615ac0
ActiveTaskCard = W1-I11
FormalDatabaseWrite = NOT_AUTHORIZED
TemporaryPostgreSQL = REQUIRED
RemotePush = NOT_AUTHORIZED
```

## 1. Purpose

W1-I11 currently permits only an HTTP/application shell. Its formal contract,
however, requires an irreversible and idempotent acceptance fact owned by the
exact `source_processing_revision`. The current V2 schema cannot store that
fact, its constraint rejects `ACCEPTED`, and the preview query rejects an
accepted partial revision. Implementing the eight-path card as written would
therefore prove behavior only against a fake port and would not deliver the
approved command.

This rebaseline expands only the persistence seam required by the existing
contract. It does not change the contract, create a second fact owner, access a
formal database, deploy, or push.

## 2. Chosen design

The acceptance fact remains on `source_processing_revision`. A V3 Flyway
migration:

- permits `partial_acceptance_status=ACCEPTED`;
- adds `partial_accepted_at`, `partial_accepted_by`, and
  `partial_acceptance_idempotency_key`;
- requires all three fields exactly when the status is `ACCEPTED`;
- preserves null acceptance facts for `NOT_APPLICABLE`, `PENDING`, pre-publish,
  and failed revisions.

A dedicated JDBC implementation of `PartialAcceptancePort` performs one atomic
conditional update scoped by trusted workspace, exact source and revision,
`PREVIEW_READY`, `PARTIAL`, `PENDING`, both digests, actor, and idempotency key.
When the update does not win, a scoped read classifies the result as:

- invisible or mismatched source/revision: `RESOURCE_NOT_FOUND` with no IDs;
- identical stored tuple: idempotent replay of the immutable first result;
- not preview-ready: `PREVIEW_NOT_READY`;
- complete, stale digest, actor/key drift, already accepted with a different
  tuple, or otherwise ineligible: `PARTIAL_ACCEPTANCE_CONFLICT`.

Two concurrent identical commands may have only one new acceptance winner;
the other must observe the committed tuple and return an idempotent replay.
No command may revoke or overwrite an accepted fact.

`SourcePreviewQuery` continues to expose the same immutable preview after a
partial revision moves from `PENDING` to `ACCEPTED`. It accepts both statuses
only when `parse_completeness=PARTIAL` and omissions are non-empty.

## 3. Runtime and HTTP boundary

`SourceCommandRuntimeConfiguration` wires the JDBC port from the existing
source-command `DataSource`. The controller obtains workspace and actor only
from `TrustedRequestContextProvider`; neither value is accepted from the body.
The body contains only both digests, idempotency key, and the literal decision
`ACCEPT_PARTIAL`. The two identities come from the path.

Both new acceptance and an identical replay return HTTP 200. Errors use the
existing five-field API shape. A 404 never exposes identities. A resolved
conflict may return the trusted same-workspace source and revision identities.

## 4. Exact implementation WriteSet

```text
server/src/main/resources/db/migration/V3__add_partial_acceptance_facts.sql
server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceController.java
server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceRequest.java
server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceCommand.java
server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceService.java
server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptancePort.java
server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceResponse.java
server/src/main/java/io/cognitura/source/persistence/JdbcPartialAcceptancePort.java
server/src/main/java/io/cognitura/source/runtime/SourceCommandRuntimeConfiguration.java
server/src/main/java/io/cognitura/source/api/query/SourcePreviewQuery.java
server/src/test/java/io/cognitura/source/api/acceptance/PartialAcceptanceControllerTest.java
server/src/test/java/io/cognitura/source/api/acceptance/PartialAcceptanceServiceTest.java
server/src/test/java/io/cognitura/source/api/query/SourcePreviewControllerTest.java
```

The task-card projection must replace the old eight-path WriteSet with this
exact thirteen-path set and set `ProductionFileLimit=10`. No other production,
migration, test, or authority path becomes an I11 product descendant.

## 5. Required evidence

The persistence proof uses the pinned PostgreSQL 18.4 Testcontainers image and
real JDBC/Flyway migrations. It records the container identity, server version,
database name, reuse=false, and removal proof. Fake, in-memory, or mocked
persistence is not acceptance evidence.

RED cases must cover at least:

- exact new acceptance and immutable result fields;
- identical replay;
- digest, actor, key, workspace, source, and revision drift;
- complete and non-preview-ready revisions;
- attempted revocation or second acceptance;
- two concurrent identical commands with exactly one new winner;
- two concurrent conflicting commands with no overwrite;
- transaction/SQL failure without a partial acceptance fact;
- preview remains readable after acceptance;
- runtime bean activation only when source-command runtime is enabled;
- request-body workspace/actor/identity injection is malformed.

## 6. Explicit non-goals

There is no second acceptance table, workflow engine, event bus, generic audit
framework, repository abstraction, background job, Web UI, parser change,
object-storage change, formal database access, deployment, or remote push.

## 7. Governance admission

The current post-I10 verifier permits only the obsolete eight-path I11 set.
Before product RED, an append-only rebaseline governance chain must pin this
specification, its implementation plan, its real-Git contract test, and the
verifier implementation in that exact order.
The chain may admit exactly one deterministic task-card projection updating
only the I11 card and the implementation-card index narrative/WriteSet count.
It must preserve I11 as the sole `READY` card and all database/push boundaries.
After that projection, descendants are limited to the thirteen product paths
above. This is a one-time successor rule, not a general Harness.
