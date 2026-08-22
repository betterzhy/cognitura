# W1-I12 Revision Status Entry Repair

```text
AuthorityKind = R2_NARROW_ENTRY_REPAIR
RepairOrigin = 793790aa357ee56e5106893a7bcd0f6eefabd1f8
ActiveTaskCard = W1-I12
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. Problem

W1-I12 must consume the formal processing result `pollLocation`, whose contract is the exact
revision endpoint:

```text
GET /api/v1/source-documents/{sourceDocumentId}/processing-revisions/{sourceProcessingRevisionId}
```

The current server exposes the processing POST and the exact revision `/blocks` preview, but not
this GET endpoint. A web client cannot truthfully project changing processing state without it.
Polling the POST, treating preview conflict as processing status, or adding a client-local fake is
forbidden.

## 2. Narrow repair

The repair reuses the existing trusted workspace context, `SourcePreviewQuery`,
`SourcePreviewController`, and PostgreSQL runtime tables. It may only:

- resolve an exact `(workspaceId, sourceDocumentId, sourceProcessingRevisionId)` tuple;
- return the fourteen revision-query fields already fixed by the Wave 1 source preview contract;
- return `404 RESOURCE_NOT_FOUND` with no identities for missing and cross-workspace tuples;
- return omissions only for a published partial revision;
- preserve safe failure detail and hide attempt, fencing, lease, storage and active/latest facts.

It must not add or change Schema, migrations, persistence facts, processing state transitions,
partial-acceptance semantics, deployment, or remote state.

## 3. Exact governance chain

Starting at `RepairOrigin`, the entry repair is append-only and consists of exactly four direct,
single-parent, non-empty commits:

1. this specification (`100644`);
2. `tests/task-cards/verify-wave1-implementation-cards.sh` (`100755`);
3. `scripts/verify-wave1-implementation-cards` (`100755`);
4. `docs/task-cards/wave-1-implementation/W1-I12-desktop-web-source-preview.md` (`100644`).

Rename/copy inference, NUL bytes, path substitution, extra paths, merge commits and reordered
steps are forbidden. The specification and contract-test blobs are fixed evidence. The fourth
commit may only rebaseline the I12 WriteSet and verification text described below; status,
authorization, dependencies, database and push fields remain byte-for-byte equivalent in meaning.

## 4. Rebaselined I12 WriteSet

The existing ten web paths remain unchanged. The following three existing server paths are added:

```text
server/src/main/java/io/cognitura/source/api/query/SourcePreviewQuery.java
server/src/main/java/io/cognitura/source/api/query/SourcePreviewController.java
server/src/test/java/io/cognitura/source/api/query/SourcePreviewControllerTest.java
```

```text
ProductionFileLimit = 10
ProductionWriteSetException = FORMAL_REVISION_STATUS_ENDPOINT_COMPLETION
```

The product candidate must cumulatively modify exactly these thirteen paths relative to the fourth
governance commit. The status endpoint test uses the existing real PostgreSQL 18 Testcontainers
fixture; in-memory or mocked persistence is not product evidence.

## 5. Focused contract

The shared task-card contract must prove at least:

- the exact four-step chain and the exact rebaselined card pass;
- a legal thirteen-path I12 descendant passes;
- wrong origin/order/path/mode/evidence or card projection fails;
- a post-repair descendant outside the thirteen paths fails.

The repair does not close I12 and does not release I13.
