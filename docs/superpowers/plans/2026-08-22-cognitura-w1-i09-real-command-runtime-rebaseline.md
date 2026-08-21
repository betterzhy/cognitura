# W1-I09 Real Command Runtime Rebaseline Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: use superpowers:test-driven-development for every product batch and superpowers:verification-before-completion before any PASS/complete claim.

**Goal:** Rebaseline the existing W1-I09 card from an HTTP-only shell to one real local-first upload and processing-command vertical slice, then implement it with real filesystem and PostgreSQL 18 evidence.

**Architecture:** Keep the Wave 1 card count and single READY state unchanged. Add a server-owned trusted local context, immutable local content-addressed binary storage, transactional source/processing command services, a production PostgreSQL implementation of the existing I07 publication port, and finally the W1-D04 HTTP boundary. Keep the runtime disabled unless explicit server configuration supplies the local workspace, actor, storage root, and PostgreSQL connection.

**Tech Stack:** JDK 21, Spring Boot 4.1.0 MVC, Spring transaction support, MyBatis 4.0.0 starter, Flyway, PostgreSQL 18.4 pinned by digest, Testcontainers, JUnit 5, AssertJ, MockMvc, Java NIO.

---

## 0. Fixed boundaries

```text
RebaselineOrigin = ae6d0ba7c1caf6365825909f39ccc3e71da9e966
RebaselineDesign = 2a5f818f22673e3af20bce369e99810e21f0095d
TaskCardCount = 14
ActiveTaskCard = W1-I09
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
RawFormalInputAccess = FORBIDDEN
I09FinalReview = ONE_SOL_XHIGH_DEEP_REVIEWER
```

The rebaseline must not rewrite the I08 closure receipt or any historical fixed candidate. The only authorized external state is local Git commits. It never connects to a formal/shared database and never pushes.

## 1. Cumulative exact product WriteSet

The rebaselined W1-I09 card must list these 27 paths exactly.

### Production and configuration (19)

```text
server/src/main/java/io/cognitura/source/application/command/TrustedRequestContext.java
server/src/main/java/io/cognitura/source/application/command/TrustedRequestContextProvider.java
server/src/main/java/io/cognitura/source/application/command/SourceBinaryStore.java
server/src/main/java/io/cognitura/source/application/command/SourceCommandPersistencePort.java
server/src/main/java/io/cognitura/source/application/command/SourceCommandService.java
server/src/main/java/io/cognitura/source/application/command/SourceCommandException.java
server/src/main/java/io/cognitura/source/storage/LocalContentAddressedSourceBinaryStore.java
server/src/main/java/io/cognitura/source/persistence/SourceCommandMapper.java
server/src/main/java/io/cognitura/source/persistence/SourceCommandPersistenceAdapter.java
server/src/main/java/io/cognitura/source/persistence/JdbcProcessingPublicationPort.java
server/src/main/java/io/cognitura/source/runtime/SourceCommandRuntimeConfiguration.java
server/src/main/resources/db/migration/V2__create_source_command_runtime.sql
server/src/main/resources/application.yaml
server/src/main/java/io/cognitura/source/api/command/SourceUploadController.java
server/src/main/java/io/cognitura/source/api/command/ProcessingCommandController.java
server/src/main/java/io/cognitura/source/api/command/SourceUploadRequest.java
server/src/main/java/io/cognitura/source/api/command/ProcessingCommandRequest.java
server/src/main/java/io/cognitura/source/api/command/CommandAcceptedResponse.java
server/src/main/java/io/cognitura/source/api/command/SourceCommandErrorAdvice.java
```

### Tests and isolated database fixture (8)

```text
server/src/test/java/io/cognitura/source/application/command/TrustedRequestContextTest.java
server/src/test/java/io/cognitura/source/storage/LocalContentAddressedSourceBinaryStoreTest.java
server/src/test/java/io/cognitura/source/application/command/SourceUploadCommandIntegrationTest.java
server/src/test/java/io/cognitura/source/persistence/JdbcProcessingPublicationPortIntegrationTest.java
server/src/test/java/io/cognitura/source/runtime/SourceCommandRuntimeIntegrationTest.java
server/src/test/java/io/cognitura/source/api/command/SourceUploadControllerTest.java
server/src/test/java/io/cognitura/source/api/command/ProcessingCommandControllerTest.java
server/src/test/resources/db/source-command-runtime-fixture.sql
```

No wildcard is allowed in the task-card WriteSet or staging command.

## 2. Rebaseline governance chain

### Task 1: Commit this plan as the second fixed governance step

**Files:**

- Create: `docs/superpowers/plans/2026-08-22-cognitura-w1-i09-real-command-runtime-rebaseline.md`

**Step 1: Validate the plan is the only change besides the protected `.idea/` entry**

Run:

```bash
git status --short
git diff --check
```

Expected: this plan is untracked; `.idea/` remains untouched.

**Step 2: Commit only the plan**

```bash
git add -- docs/superpowers/plans/2026-08-22-cognitura-w1-i09-real-command-runtime-rebaseline.md
git diff --cached --name-only
git commit -m "docs: plan W1-I09 real command runtime"
```

Expected staged path count: 1.

### Task 2: Add the real-Git rebaseline contract RED

**Files:**

- Modify: `tests/task-cards/verify-wave1-implementation-cards.sh`

Add `--w1-i09-runtime-rebaseline-contract-only`. In a shared-clone fixture fixed at `RebaselineOrigin`, construct the exact design → plan → test → verifier → authority projection chain.

Positive cases:

1. exact fixed chain with unchanged I08 receipt and 14-card vector;
2. legal post-projection descendant changing only one of the 27 exact product paths.

Negative cases must independently reach the intended guard:

1. wrong origin, design or plan identity;
2. merge, empty, rename, copy, wrong mode or NUL in any governance step;
3. wrong step order, repeated step or extra governance path;
4. projection omits or adds a path;
5. I09 stops being the only READY card or card count changes;
6. FormalDatabaseWrite or RemotePush becomes authorized;
7. I08 product/receipt bytes drift;
8. I09 WriteSet differs by one path or wildcard;
9. post-projection descendant outside the exact 27 paths;
10. formal/shared database location or `raw/**`/`.idea/**` is introduced.

Run on Bash 3.2:

```bash
/bin/bash tests/task-cards/verify-wave1-implementation-cards.sh \
  --w1-i09-runtime-rebaseline-contract-only
```

Expected: RED because production verifier does not yet recognize the fixed chain.

Commit only the test file:

```bash
git add -- tests/task-cards/verify-wave1-implementation-cards.sh
git commit -m "test: require W1-I09 runtime rebaseline"
```

### Task 3: Implement the narrow verifier GREEN

**Files:**

- Modify: `scripts/verify-wave1-implementation-cards`

Add fixed full SHAs for origin/design/plan/test/verifier candidate; validate the first-parent chain, exact single-path commits, modes, no R/C/NUL, and frozen I08 product/closure. Do not generalize the historical I08 descendant predicate.

Before projection, the fixed verifier tip may return:

```text
W1I09RuntimeRebaselineStatus = PENDING_PROJECTION
ActiveTaskCard = W1-I09
```

After projection it must validate the rebaselined task card and permit descendants only in the exact 27 product paths.

Run:

```bash
/bin/bash tests/task-cards/verify-wave1-implementation-cards.sh \
  --w1-i09-runtime-rebaseline-contract-only
```

Expected: all focused positive and negative cases pass.

Then run only the static card validator and Bash syntax checks, not the full Wave gate yet:

```bash
/bin/bash -n scripts/verify-wave1-implementation-cards
/bin/bash -n tests/task-cards/verify-wave1-implementation-cards.sh
scripts/verify-wave1-implementation-cards \
  --cards-dir docs/task-cards/wave-1-implementation
```

Commit only the verifier:

```bash
git add -- scripts/verify-wave1-implementation-cards
git commit -m "build: admit W1-I09 runtime rebaseline"
```

### Task 4: Fixed-candidate governance review and exact projection

**Governance candidate:** the Task 3 verifier commit.

Run one `deep_reviewer / sol xhigh` against Candidate/Parent/Tree. A GO must report P0/P1/P2 all zero. Findings are repaired append-only and re-reviewed; do not add Ultra without a concrete L4 escalation reason.

After GO, project exactly these five authority paths in one direct child commit:

```text
docs/engineering/cognitura-technology-baseline.md
docs/engineering/cognitura-design-index.md
docs/engineering/cognitura-wave-1-design-acceptance.md
docs/engineering/cognitura-wave-1-implementation-plan.md
docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md
```

Projection requirements:

- select `LOCAL_CONTENT_ADDRESSED_FILESYSTEM` only for Wave 1 source binaries;
- keep `TaskCardCount=14`, `ActiveTaskCard=W1-I09`, one READY;
- set I09 boundary to `SOURCE_COMMAND_RUNTIME` and its exact 27 paths;
- record `FormalDatabaseGate=PASS` for isolated migration implementation admission while
  `FormalDatabaseWrite=NOT_AUTHORIZED` remains unchanged;
- append a terminal receipt with reviewed Candidate/Parent/Tree and zero findings;
- explicitly state that the old HTTP exact-eight contract is superseded, not completed.

Validate the explicit transition and static tree with the focused contract before starting product code.

## 3. Product Batch A — trusted context and real local CAS

### Task 5: Trusted context RED

**Files:**

- Create: `server/src/test/java/io/cognitura/source/application/command/TrustedRequestContextTest.java`
- Create later GREEN files:
  - `server/src/main/java/io/cognitura/source/application/command/TrustedRequestContext.java`
  - `server/src/main/java/io/cognitura/source/application/command/TrustedRequestContextProvider.java`

RED cases:

- null/blank/unsafe/overlong workspace and actor fail closed;
- context is immutable and has no constructor from HTTP request/header data;
- provider always returns the configured pair;
- path workspace mismatch is rejected without echoing the foreign value.

Run:

```bash
./mvnw -f server/pom.xml -Dtest=TrustedRequestContextTest test
```

Expected: test compilation or assertions fail before production classes exist.

### Task 6: Trusted context GREEN

Implement only an immutable validated record and a one-method provider interface. No authentication framework, JWT, RBAC or user registry.

Run the focused test, then:

```bash
./mvnw -f server/pom.xml -Dtest=ModuleBoundariesTest test
git diff --check
```

### Task 7: Local CAS RED

**Files:**

- Create: `server/src/test/java/io/cognitura/source/storage/LocalContentAddressedSourceBinaryStoreTest.java`
- Create later GREEN files:
  - `server/src/main/java/io/cognitura/source/application/command/SourceBinaryStore.java`
  - `server/src/main/java/io/cognitura/source/storage/LocalContentAddressedSourceBinaryStore.java`

Use a real temporary directory and an InputStream that fails if reread. Cover:

- content larger than the internal copy buffer is consumed once;
- actual length/SHA are computed and declaration mismatches fail;
- zero bytes, limit overflow and unsupported media fail;
- exact CAS path and opaque location are stable;
- same digest reuses verified bytes without overwrite;
- truncated/corrupt existing target fails closed;
- path traversal, symlink root/segment and untrusted location are rejected;
- failure leaves no temporary file;
- atomic move unsupported is not replaced by copy+delete.

Run RED, implement minimum GREEN, rerun focused tests and module boundaries.

## 4. Product Batch B — streaming upload transaction

### Task 8: Upload transaction RED against PostgreSQL 18

**Files:**

- Create: `server/src/test/java/io/cognitura/source/application/command/SourceUploadCommandIntegrationTest.java`
- Create: `server/src/test/resources/db/source-command-runtime-fixture.sql`
- Create later GREEN files:
  - `server/src/main/java/io/cognitura/source/application/command/SourceCommandPersistencePort.java`
  - `server/src/main/java/io/cognitura/source/application/command/SourceCommandService.java`
  - `server/src/main/java/io/cognitura/source/application/command/SourceCommandException.java`
  - `server/src/main/java/io/cognitura/source/persistence/SourceCommandMapper.java`
  - `server/src/main/java/io/cognitura/source/persistence/SourceCommandPersistenceAdapter.java`

Start the pinned PostgreSQL 18.4 container with reuse false and random database/user/password. Run Flyway. Use the real local CAS in a temporary directory.

RED matrix:

- new upload persists one binary and one document and returns 201 semantics;
- same workspace/key/actual hash is a 200 replay with identical IDs;
- same key/different actual hash conflicts with zero new logical facts;
- same digest/different keys creates two documents and one binary;
- declared length/hash mismatch creates no database facts;
- concurrent same key yields one document and deterministic replay/conflict;
- database rollback never exposes a logical document;
- a CAS orphan after forced database failure is immutable and harmless;
- no byte array of the full upload is retained by the service;
- container version/database identity and destruction are proved.

### Task 9: Upload transaction GREEN

Keep the transaction inside the persistence adapter. Map only stable constraint categories; never expose SQL text or absolute paths. Do not modify the historical `SourcePreRegistrationPolicy` byte-array API.

Run focused upload/CAS/context tests. Do not run the full Wave gate yet.

## 5. Product Batch C — production PostgreSQL processing port

### Task 10: Migration and production port RED

**Files:**

- Create: `server/src/main/resources/db/migration/V2__create_source_command_runtime.sql`
- Create: `server/src/test/java/io/cognitura/source/persistence/JdbcProcessingPublicationPortIntegrationTest.java`
- Create later GREEN: `server/src/main/java/io/cognitura/source/persistence/JdbcProcessingPublicationPort.java`

The migration must extend the existing source revision facts and add only the I07 protocol facts needed for attempt, lease, staging, publication, alias, generation-stage record and stale-result audit. It must not add cognition, query, partial acceptance or Web tables.

Port contract matrix on real PostgreSQL 18:

- initial and retry attempt numbering/generation;
- one active attempt under concurrent begin;
- deterministic fencing token from revision+generation;
- claim/heartbeat/timeout expected-state and lease CAS;
- staged block-set identity and digest checks;
- publish transaction atomically writes blocks, aliases, stage record and revision outcome;
- alias collision rolls back the entire publication;
- retryable/terminal failure transition legality;
- late/forged/stale completion writes only rejection audit;
- publish-vs-timeout and double-publish races have one terminal winner;
- migration reapply is rejected by Flyway history;
- container removal is proved.

### Task 11: Production port GREEN

Implement `ProcessingPublicationPort` directly. Reuse I07 domain objects and canonical digest methods; do not copy their semantics into new DTOs. SQL transactions must use explicit row locks and conditional updates. Keep test-only inspection queries in the integration test, not the production adapter API.

Run:

```bash
./mvnw -f server/pom.xml \
  -Dtest='JdbcProcessingPublicationPortIntegrationTest,ProcessingPublicationIntegrationTest' test
```

Expected: both the historical contract adapter and the new production adapter pass the same behavioral invariants.

## 6. Product Batch D — runtime wiring and HTTP boundary

### Task 12: Runtime wiring RED/GREEN

**Files:**

- Create: `server/src/main/java/io/cognitura/source/runtime/SourceCommandRuntimeConfiguration.java`
- Modify: `server/src/main/resources/application.yaml`
- Create: `server/src/test/java/io/cognitura/source/runtime/SourceCommandRuntimeIntegrationTest.java`

The default application remains healthy without business infrastructure. The real command runtime is enabled only when explicit server configuration supplies trusted workspace/actor, CAS root and PostgreSQL credentials. When enabled in the integration test it must run Flyway, wire MyBatis/transactions, store a real streamed file, persist facts, accept a processing attempt and return exact IDs.

Test both:

```bash
./mvnw -f server/pom.xml -Dtest='HealthBaselineTest,SourceCommandRuntimeIntegrationTest' test
```

### Task 13: HTTP contract RED

**Files:**

- Create/modify the six `server/src/main/java/io/cognitura/source/api/command/*.java` paths in the exact WriteSet.
- Create:
  - `server/src/test/java/io/cognitura/source/api/command/SourceUploadControllerTest.java`
  - `server/src/test/java/io/cognitura/source/api/command/ProcessingCommandControllerTest.java`

Cover exact W1-D04 status/shape behavior, including body field allowlist, trusted path scope, streaming multipart, idempotent 200, new 201/202, terminal/success 200, 503 without revision, uniform 404 with null identities, and absence of binary location/path/fence/lease/SQL/stack trace.

MockMvc may use a controlled application-port stub to enumerate HTTP mappings. It is not completion evidence; `SourceCommandRuntimeIntegrationTest` remains mandatory.

### Task 14: HTTP GREEN

Controllers delegate only to `SourceCommandService` with `TrustedRequestContextProvider`; they do not query mappers or storage. Advice maps stable application errors to the exact five-field error contract.

Run:

```bash
./mvnw -f server/pom.xml -Dtest='io.cognitura.source.api.command.*Test' test
./mvnw -f server/pom.xml \
  -Dtest='SourceCommandRuntimeIntegrationTest,SourceUploadCommandIntegrationTest' test
```

## 7. Final candidate and closure

### Task 15: Candidate verification

Run the smallest complete evidence set once the tree is stable:

```bash
./mvnw -f server/pom.xml \
  -Dtest='io.cognitura.source.application.command.*Test,io.cognitura.source.storage.*Test,io.cognitura.source.persistence.*IntegrationTest,io.cognitura.source.runtime.*Test,io.cognitura.source.api.command.*Test' test
./mvnw -f server/pom.xml test
scripts/verify-wave1-implementation
git diff --check
git status --short
```

Require complete exit 0. Interrupted or partial container output is not evidence. Record container image, version, database name and removal proof; do not record credentials.

Stage only the 27 card paths via `--pathspec-from-file`, verify exact bidirectional equality, and create one local fixed candidate commit.

### Task 16: One fixed-candidate review and closure

Run one `deep_reviewer / sol xhigh` on fixed Candidate/Parent/Tree. Findings return to their product owner path and require only affected focused tests plus the final complete evidence after the tree changes. Do not repeat the same heavy gate on an unchanged tree.

Only GO with P0/P1/P2 all zero permits the I09 DONE → I10 READY closure projection. Keep formal database write, deployment and push unauthorized.
