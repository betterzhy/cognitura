# W1-I11 Partial Acceptance Persistence Rebaseline Implementation Plan

> Execute in small append-only commits. Preserve `raw/**`, `.idea/**`, formal
> database state, deployment state, and remote branches.

**Goal:** Deliver the formal partial-acceptance command against real
PostgreSQL, including irreversible CAS, idempotent replay, trusted actor scope,
and accepted-preview compatibility.

**Architecture:** Keep the acceptance fact on `source_processing_revision`.
Use a dedicated JDBC port, the existing source-command `DataSource`, a V3
Flyway migration, and the existing trusted request context. Do not introduce a
second fact store or a generic workflow framework.

**Technology:** Java 21, Spring Boot 4.1.0, JDBC, Flyway, PostgreSQL 18.4
Testcontainers, JUnit 5, AssertJ, MockMvc.

---

## Task 1: Admit the corrected I11 WriteSet

**Files:**

- Modify: `tests/task-cards/verify-wave1-implementation-cards.sh`
- Modify: `scripts/verify-wave1-implementation-cards`
- Modify: `docs/task-cards/wave-1-implementation/README.md`
- Modify: `docs/task-cards/wave-1-implementation/W1-I11-partial-acceptance-command-api.md`

1. Commit the design specification as a single-path, mode-100644, NUL-free
   governance commit.
2. Commit this implementation plan as the next single-path, mode-100644,
   NUL-free governance commit.
3. Add `--w1-i11-persistence-rebaseline-contract-only`. Build real shared-Git
   fixtures from the literal origin and prove RED for the new transition.
4. The focused contract must include two positives and negatives for wrong
   origin/evidence, wrong count/order, merge/empty, rename/copy/mode/NUL,
   projection drift, authorization drift, an extra path, an obsolete I11 path
   set, and a descendant outside the new exact set.
5. Commit the RED test as a single-path 100755 commit.
6. Implement a verifier route that fixes the governance identities, freezes
   the I10 product and closure projection, validates a deterministic two-file
   task-card projection, and permits only the new thirteen-path I11 descendants.
7. Run the focused contract with Bash 3.2 and the static verifier. Commit the
   verifier as a single-path 100755 commit.
8. Materialize and commit the exact two-file task-card projection. Confirm I11
   remains the only READY card and database/push remain unauthorized.

## Task 2: Write the real PostgreSQL RED contract

**Files:**

- Create: `server/src/test/java/io/cognitura/source/api/acceptance/PartialAcceptanceServiceTest.java`
- Create: `server/src/test/java/io/cognitura/source/api/acceptance/PartialAcceptanceControllerTest.java`
- Modify: `server/src/test/java/io/cognitura/source/api/query/SourcePreviewControllerTest.java`

1. In `PartialAcceptanceServiceTest`, start the pinned PostgreSQL 18.4
   Testcontainer with reuse disabled and apply Flyway migrations.
2. Seed exact workspace/source/revision publication facts through real JDBC.
3. Write failing tests for new acceptance, identical replay, all tuple drift,
   complete/non-ready states, post-acceptance immutability, concurrent identical
   and conflicting requests, and SQL failure rollback.
4. Assert exactly one new winner under identical concurrency and unchanged
   accepted facts under conflicting concurrency.
5. Record and assert PostgreSQL version/database identity and container removal.
6. In the controller test, prove trusted-context sourcing, exact path/body
   handling, stable 200/400/404/409 shapes, and no body workspace/actor fields.
   Controller-only serialization tests may isolate the HTTP boundary, but no
   fake result may count as persistence evidence.
7. Add a failing preview regression proving an accepted partial revision remains
   readable with the same digests, omissions, blocks, and pagination.
8. Run only these three tests and confirm they fail for the missing production
   implementation or accepted-status incompatibility.

## Task 3: Add V3 acceptance facts

**File:**

- Create: `server/src/main/resources/db/migration/V3__add_partial_acceptance_facts.sql`

1. Drop and replace the V2 partial-acceptance enum constraint to include
   `ACCEPTED`.
2. Add nullable `partial_accepted_at`, `partial_accepted_by`, and
   `partial_acceptance_idempotency_key` columns.
3. Add one state constraint requiring all three fields exactly for ACCEPTED and
   requiring `parse_completeness=PARTIAL` for that state.
4. Add nonblank checks for actor and idempotency key when present.
5. Run Flyway migration validation against a fresh PostgreSQL 18.4 container.

## Task 4: Implement the acceptance application boundary

**Files:**

- Create: `server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceCommand.java`
- Create: `server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptancePort.java`
- Create: `server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceService.java`
- Create: `server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceRequest.java`
- Create: `server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceResponse.java`

1. Validate identifiers with the existing trusted identifier grammar, digests as
   lower-case SHA-256, idempotency key as a bounded safe identifier, and the
   decision as exactly `ACCEPT_PARTIAL`.
2. Keep workspace and actor exclusively in `TrustedRequestContext`; keep source
   and revision identities in the path/application command, never body-owned.
3. Define a closed port result/error model for NEW, REPLAY, NOT_FOUND,
   NOT_READY, CONFLICT, and retryable concurrent completion.
4. Have the service produce only the formal result fields and never expose SQL,
   storage, lease, fencing, path, or stack-trace details.

## Task 5: Implement atomic JDBC CAS and runtime wiring

**Files:**

- Create: `server/src/main/java/io/cognitura/source/persistence/JdbcPartialAcceptancePort.java`
- Modify: `server/src/main/java/io/cognitura/source/runtime/SourceCommandRuntimeConfiguration.java`

1. Use one conditional `UPDATE ... FROM source_document ... RETURNING` scoped by
   workspace, source, revision, state, completeness, and both digests.
2. Store the trusted actor, idempotency key, and a single clock timestamp only
   for the winning transition.
3. When no row updates, perform a same-workspace exact-revision read and classify
   absent, replay, not-ready, or conflict without creating an existence oracle.
4. Use JDBC transaction boundaries that allow a waiting concurrent loser to
   observe the committed winner. Roll back every SQL failure.
5. Wire the port and service from the existing source-command DataSource and
   clock. Do not introduce another DataSource or runtime flag.
6. Run the real PostgreSQL service tests until GREEN.

## Task 6: Implement HTTP and accepted-preview compatibility

**Files:**

- Create: `server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceController.java`
- Modify: `server/src/main/java/io/cognitura/source/api/query/SourcePreviewQuery.java`

1. Add the exact POST route from the D04 contract and source context only from
   `TrustedRequestContextProvider`.
2. Return HTTP 200 for NEW and REPLAY. Map malformed input to 400, invisible
   scope to uniform 404, ineligible/drift to 409 nonretryable, and genuine
   concurrent completion to 409 retryable.
3. Keep the five-field error response and trusted identity disclosure rules.
4. Permit `PARTIAL + (PENDING or ACCEPTED)` in preview validation without
   changing digests, omissions, items, cursors, or warning semantics.
5. Run the controller, service, and preview tests until GREEN.

## Task 7: Verify and fix the product candidate

1. Run the three focused acceptance/query tests.
2. Run all server tests once on the stable tree.
3. Run `scripts/verify-wave1-implementation` once on the stable tree.
4. Run `git diff --check`, exact-WriteSet comparison, mode/no-R-C checks, and
   confirm only the known untracked `.idea/` remains outside scope.
5. Commit the exact thirteen product paths without directory-level staging.
6. Record Candidate, Parent, and Tree; request one `deep_reviewer / xhigh`
   fixed-candidate review. Repair only candidate-bound findings with fresh RED
   evidence, then rerun only affected gates before the final full gate.

## Task 8: Close I11

1. After zero-finding GO, add the minimal I11 closure spec/test/verifier route.
2. Project I11 DONE and release only the dependency-legal successor; preserve
   all database, deployment, and push boundaries.
3. Validate the explicit transition and static state, then run the final
   applicable gate once.
