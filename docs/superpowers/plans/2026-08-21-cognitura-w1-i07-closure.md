# Cognitura W1-I07 Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the reviewed W1-I07 product candidate, release W1-I08 as the sole `READY` card,
and place dependency-satisfied W1-I09 in `QUEUED` without expanding database or push authority.

**Architecture:** Extend the existing Wave 1 Bash 3.2 verifier with one fixed, four-commit I07
governance prefix and one direct-child, twelve-path projection receipt. The public verifier first
recognizes the reviewed governance tip as `PENDING`, then validates the exact receipt and limits
later descendants to the W1-I08 WriteSet. It does not add a generic closure engine or a second
state ledger.

**Tech Stack:** Bash 3.2, Git object validation, real shared-clone fixtures, Maven/JDK 21,
PostgreSQL 18 Testcontainers for the existing I07 focused regression.

**Spec:** `docs/superpowers/specs/2026-08-21-cognitura-w1-i07-closure-design.md`

## Global Constraints

- `ClosureOriginSHA = 094f62546cf7a13435c5d61f2a7bede21b86f099`.
- Product identity is Candidate `094f62546cf7a13435c5d61f2a7bede21b86f099`, Parent
  `5433485e8f88f3846cbda722282223a3c8274b14`, Tree
  `d82ece96e0e3dabdfef64a766179b711ea6d557f`.
- Product review is `L3/deep_reviewer/xhigh/ONE/GO`, `P0=P1=P2=0`, `Ultra=NOT_RUN`.
- The four governance paths change once in canonical order; the receipt changes exactly twelve
  projection paths.
- W1-I07 product bytes and all predecessor receipts remain immutable.
- The receipt sets I07 `DONE`, I08 `READY/USER_AUTHORIZED`, I09 `QUEUED`, and leaves I10 blocked.
- Formal database write, deployment, release, remote push, history rewrite, and amend are forbidden.
- Do not read or modify `raw/**`, `.idea/**`, `temp-input/**`, or unrelated worktree state.
- Work remains on the user-authorized `main` worktree; stage every commit by exact path.
- Bash code must run on Bash 3.2: no associative arrays, `mapfile`, nameref, or lowercase expansion.

---

### Task 1: Commit the execution plan

**Files:**
- Create: `docs/superpowers/plans/2026-08-21-cognitura-w1-i07-closure.md`

**Interfaces:**
- Consumes: the committed design at `42b4826` and the fixed I07 product identity.
- Produces: the second canonical governance commit and the exact execution contract for Tasks 2–5.

- [ ] **Step 1: Self-review the plan**

Run:

```bash
rg -n 'TBD|TODO|FIXME|implement later|fill in' \
  docs/superpowers/plans/2026-08-21-cognitura-w1-i07-closure.md || true
git diff --check
```

Expected: no placeholder match and exit `0`.

- [ ] **Step 2: Commit only the plan**

Run:

```bash
git add -- docs/superpowers/plans/2026-08-21-cognitura-w1-i07-closure.md
git diff --cached --name-only
git diff --cached --check
git commit -m "docs: plan W1-I07 closure transition"
```

Expected staged path: exactly the plan file.

### Task 2: Define the real-Git RED closure contract

**Files:**
- Modify: `tests/task-cards/verify-wave1-implementation-cards.sh`

**Interfaces:**
- Consumes: public verifier CLI, fixed origin/product identities, existing shared-clone helpers,
  `set_field`, `set_table_status`, and the I02/I06 closure fixture patterns.
- Produces: `--w1-i07-closure-contract-only` and `run_w1_i07_closure_contract`.

- [ ] **Step 1: Add the focused CLI flag and dispatch**

Add one Bash 3.2 scalar:

```bash
w1_i07_closure_contract_only=0
```

Parse this exact flag:

```bash
--w1-i07-closure-contract-only)
  w1_i07_closure_contract_only=1
  shift
  ;;
```

Before the full suite, dispatch:

```bash
if [[ "${w1_i07_closure_contract_only}" == 1 ]]; then
  run_w1_i07_closure_contract
  exit 0
fi
```

The full suite invokes `run_w1_i07_closure_contract` once after the I02 closure contract.

- [ ] **Step 2: Build the fixed governance fixture**

Implement these test-only functions:

```bash
new_w1_i07_closure_fixture()
commit_w1_i07_governance_path()
append_w1_i07_review_receipt()
make_w1_i07_closure_projection()
run_w1_i07_fixture_verifier()
expect_w1_i07_closure_failure()
run_w1_i07_closure_contract()
```

`new_w1_i07_closure_fixture` clones the repository with `git clone --shared -q`, checks out
`094f62546cf7a13435c5d61f2a7bede21b86f099` detached, and materializes the four canonical paths
as four single-path commits. Document modes are `100644`; script modes are `100755`.

- [ ] **Step 3: Materialize the exact legal receipt**

`make_w1_i07_closure_projection` changes exactly the twelve paths from design section 4 and
performs these literal state changes:

```text
I07 READY -> DONE
I08 BLOCKED_BY_DEPENDENCY -> READY
I08 BusinessImplementationAuthorization REQUIRED_BEFORE_READY -> USER_AUTHORIZED
I09 BLOCKED_BY_DEPENDENCY -> QUEUED
ActiveTaskCard W1-I07 -> W1-I08
ActiveTaskCardStatus READY -> READY
ReadyTaskCardCount 1 -> 1
```

It updates every active-card narrative/table, leaves I10 blocked, and appends a terminal receipt
whose product SHAs are fixed and whose governance Candidate/Parent/Tree are derived with
`git rev-parse "${governance_tip}"`, `git rev-parse "${governance_tip}^"`, and
`git rev-parse "${governance_tip}^{tree}"`.

- [ ] **Step 4: Add positive behavioral cases**

Use the public verifier, not source-text assertions, for these four positives:

```text
legal governance tip -> W1I07ClosureStatus = PENDING
explicit governance-tip..receipt -> W1I07ClosureStatus = PASS
static receipt -> ActiveTaskCard = W1-I08 and ReadyTaskCardCount = 1
one post-receipt commit changing only an I08 WriteSet path -> PASS
```

- [ ] **Step 5: Add independent negative mutations**

Each negative resets to the immutable fixture base, creates a real Git commit, invokes the public
verifier, and asserts the specific failure token. Cover at least these separate classes:

```text
I07_CLOSURE_GOVERNANCE_CHAIN_INVALID
I07_CLOSURE_RECEIPT_PATHS_INVALID
I07_CLOSURE_STATE_VECTOR_INVALID
I07_CLOSURE_REVIEW_RECEIPT_INVALID
I07_CLOSURE_PRODUCT_DRIFT
I07_CLOSURE_PROJECTION_MISMATCH
I07_CLOSURE_DESCENDANT_OUTSIDE_WRITE_SET
```

Mutations must include wrong governance order, extra/repeated path, merge, rename/copy, mode/NUL,
I07 product drift, non-direct receipt, missing/extra receipt path, I07 READY, I08 not READY, I09
not QUEUED, I08+I09 both READY, I09 released first, I10 READY, active/count mismatch, database/push
drift, wrong product and governance identities, non-GO/nonzero/Ultra receipt, duplicate/nonterminal
receipt, second closure, working-tree masking, projection introduce-restore, and post-receipt
outside-I08 mutation.

- [ ] **Step 6: Run RED against the old production verifier**

Run:

```bash
bash -n tests/task-cards/verify-wave1-implementation-cards.sh
bash tests/task-cards/verify-wave1-implementation-cards.sh \
  --w1-i07-closure-contract-only
```

Expected: nonzero exit because the legal governance tip cannot emit
`W1I07ClosureStatus = PENDING`. Record the exact failing output before GREEN.

- [ ] **Step 7: Commit only the RED contract**

Run:

```bash
git add -- tests/task-cards/verify-wave1-implementation-cards.sh
git diff --cached --name-only
git diff --cached --check
git commit -m "test: define W1-I07 closure transition"
```

Expected staged path: exactly the test script.

### Task 3: Implement the production GREEN verifier

**Files:**
- Modify: `scripts/verify-wave1-implementation-cards`

**Interfaces:**
- Consumes: `run_w1_i07_closure_contract`, existing Git helpers, I02 closure receipt, and the fixed
  four-path chain rooted at `094f62546cf7a13435c5d61f2a7bede21b86f099`.
- Produces: fixed-chain validation, PENDING/static/explicit I07 close routes, receipt replay, and an
  I08-only post-receipt descendant boundary.

- [ ] **Step 1: Add exact identities and path arrays**

Add these literals and arrays near the I02 closure constants:

```bash
w1_i07_closure_origin_sha="094f62546cf7a13435c5d61f2a7bede21b86f099"
w1_i07_reviewed_candidate_sha="094f62546cf7a13435c5d61f2a7bede21b86f099"
w1_i07_reviewed_parent_sha="5433485e8f88f3846cbda722282223a3c8274b14"
w1_i07_reviewed_tree_sha="d82ece96e0e3dabdfef64a766179b711ea6d557f"
w1_i07_governance_paths=(
  docs/superpowers/specs/2026-08-21-cognitura-w1-i07-closure-design.md
  docs/superpowers/plans/2026-08-21-cognitura-w1-i07-closure.md
  tests/task-cards/verify-wave1-implementation-cards.sh
  scripts/verify-wave1-implementation-cards
)
w1_i07_closure_projection_paths=(
  AGENTS.md
  README.md
  docs/design/wave-1/README.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-plan.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1/README.md
  docs/task-cards/wave-1-implementation/README.md
  docs/task-cards/wave-1-implementation/W1-I07-revision-attempt-fencing-publication.md
  docs/task-cards/wave-1-implementation/W1-I08-stable-reference-reparse-lineage.md
  docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md
)
w1_i07_product_paths=(
  server/src/main/java/io/cognitura/source/application/processing/ProcessingAttempt.java
  server/src/main/java/io/cognitura/source/application/processing/AttemptLease.java
  server/src/main/java/io/cognitura/source/application/processing/AttemptFence.java
  server/src/main/java/io/cognitura/source/application/processing/CandidateBlockSet.java
  server/src/main/java/io/cognitura/source/application/processing/BlockSetDigest.java
  server/src/main/java/io/cognitura/source/application/processing/ProcessingPublicationService.java
  server/src/main/java/io/cognitura/source/application/processing/ProcessingPublicationPort.java
  server/src/test/java/io/cognitura/source/application/processing/ProcessingPublicationIntegrationTest.java
)
w1_i08_product_paths=(
  server/src/main/java/io/cognitura/source/reference/StableSourceReference.java
  server/src/main/java/io/cognitura/source/reference/SourceScopedAlias.java
  server/src/main/java/io/cognitura/source/reference/ReparseProfile.java
  server/src/main/java/io/cognitura/source/reference/ReparseLineage.java
  server/src/main/java/io/cognitura/source/reference/ReferenceResolutionService.java
  server/src/main/java/io/cognitura/source/reference/ReferenceResolutionException.java
  server/src/test/java/io/cognitura/source/reference/ReferenceResolutionServiceTest.java
  server/src/test/java/io/cognitura/source/reference/ReparseLineageTest.java
)
```

Use literal repository-relative paths in every array; do not derive authorization from globbing.

- [ ] **Step 2: Validate the four-path governance prefix**

Implement:

```bash
validate_w1_i07_closure_governance_chain()
```

It resolves the first-parent commits after the fixed origin, requires exactly four commits at the
pending tip, and for index `0..3` checks single parent, nonempty diff, exact one expected path,
expected mode, NUL-free blob, no rename/copy, and no cumulative path outside the exact four. It
also verifies all I07 product and twelve projection paths are byte-identical to the origin.

- [ ] **Step 3: Validate the receipt and its terminal block**

Implement:

```bash
require_w1_i07_closure_review_receipt()
write_normalized_w1_i07_closure_file()
validate_w1_i07_closure_receipt()
find_unique_w1_i07_closure_receipt()
validate_post_w1_i07_closure_descendants()
```

`require_w1_i07_closure_review_receipt` compares the terminal plan section byte-for-byte after
substituting the actual governance tip, its single parent, and its tree. The receipt validator
requires a direct child, exact twelve paths, preserved modes, no NUL/R/C, fixed product identity,
frozen I07 product, exact I07/I08/I09/I10 vector, one READY, synchronized projections, unchanged
database/push fields, and projection-only normalization.

`validate_post_w1_i07_closure_descendants` rejects empty/merge/R/C commits and every path outside
the literal W1-I08 WriteSet.

- [ ] **Step 4: Add explicit and static routes**

Before the current I02-ready route exits, recognize these states:

```text
four-path governance tip, I07 READY/I08 BLOCKED/I09 BLOCKED -> PENDING
explicit base=governance tip, head=direct receipt -> PASS
static descendant containing unique receipt, I07 DONE/I08 READY/I09 QUEUED -> PASS
```

Emit these exact summary fields:

```text
TaskCardSetStatus = READY_FOR_EXECUTION
ActiveTaskCard = W1-I08
ReadyTaskCardCount = 1
W1I07ClosureStatus = PASS
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

Do not modify generic card dependency validation or add an I09-ready route.

- [ ] **Step 5: Run GREEN and regression gates**

Run serially:

```bash
bash -n scripts/verify-wave1-implementation-cards
bash -n tests/task-cards/verify-wave1-implementation-cards.sh
bash tests/task-cards/verify-wave1-implementation-cards.sh \
  --w1-i07-closure-contract-only
scripts/verify-wave1-implementation
git diff --check
```

Expected: focused contract exit `0`, full Wave verification exit `0`, and no diff errors.

- [ ] **Step 6: Commit only the GREEN verifier**

Run:

```bash
git add -- scripts/verify-wave1-implementation-cards
git diff --cached --name-only
git diff --cached --check
git commit -m "feat: verify W1-I07 closure transition"
```

Expected staged path: exactly the production verifier.

### Task 4: Review the fixed governance candidate

**Files:**
- Read-only: the fixed four-path governance chain and all referenced Git objects.

**Interfaces:**
- Consumes: fixed origin, spec, plan, RED contract, GREEN verifier, and fresh gate evidence.
- Produces: one `deep_reviewer/Sol/xhigh/ONE` GO or a finding returned to the exact governance
  WriteSet.

- [ ] **Step 1: Freeze candidate evidence**

Run:

```bash
git rev-parse HEAD HEAD^ HEAD^{tree}
git diff --name-only 094f62546cf7a13435c5d61f2a7bede21b86f099..HEAD
git log --format='%H %P %T' \
  094f62546cf7a13435c5d61f2a7bede21b86f099..HEAD
```

Expected: exact four cumulative paths in canonical order and four single-parent commits.

- [ ] **Step 2: Request the one applicable deep review**

Provide Candidate/Parent/Tree, origin, exact-four paths, spec, plan, RED/GREEN evidence, full Wave
exit, and the fixed I07 product identities. The reviewer must report findings first and explicit
`P0/P1/P2` counts plus `GO/NO-GO`. Ultra is not dispatched.

- [ ] **Step 3: Resolve findings without widening scope**

For every valid finding, add a failing focused mutation first, run RED, change only the test or
verifier path permitted by the fixed governance prefix, run GREEN/full affected gates, make an
append-only repair commit, and request a new review for the changed tree. Do not amend or rewrite
the four historical commits.

- [ ] **Step 4: Continue only on zero-finding GO**

Required evidence:

```text
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
Ultra = NOT_RUN
```

### Task 5: Create and validate the twelve-path closure receipt

**Files:**
- Modify: `AGENTS.md`
- Modify: `README.md`
- Modify: `docs/design/wave-1/README.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/engineering/cognitura-wave-1-design-plan.md`
- Modify: `docs/engineering/cognitura-wave-1-design-acceptance.md`
- Modify: `docs/engineering/cognitura-wave-1-implementation-plan.md`
- Modify: `docs/task-cards/wave-1/README.md`
- Modify: `docs/task-cards/wave-1-implementation/README.md`
- Modify: `docs/task-cards/wave-1-implementation/W1-I07-revision-attempt-fencing-publication.md`
- Modify: `docs/task-cards/wave-1-implementation/W1-I08-stable-reference-reparse-lineage.md`
- Modify: `docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md`

**Interfaces:**
- Consumes: zero-finding governance review and the reviewed governance Candidate/Parent/Tree.
- Produces: one direct-child receipt with I07 DONE, I08 sole READY, I09 QUEUED, and an I08-only
  descendant lane.

- [ ] **Step 1: Apply the exact atomic projection**

Set all active projections to W1-I08, I07 to DONE, I08 to READY with
`BusinessImplementationAuthorization=USER_AUTHORIZED`, I09 to QUEUED, and keep I10 blocked.
Update only narratives that identify the active card or closed-card sequence. Preserve formal
database, deployment, release, and push fields verbatim.

- [ ] **Step 2: Append the terminal review receipt**

Append the exact design section 5 block using literal full product and governance SHAs. The
receipt is the final section and occurs exactly once.

- [ ] **Step 3: Commit exactly the twelve paths**

Run:

```bash
git add -- AGENTS.md README.md docs/design/wave-1/README.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-wave-1-design-plan.md \
  docs/engineering/cognitura-wave-1-design-acceptance.md \
  docs/engineering/cognitura-wave-1-implementation-plan.md \
  docs/task-cards/wave-1/README.md \
  docs/task-cards/wave-1-implementation/README.md \
  docs/task-cards/wave-1-implementation/W1-I07-revision-attempt-fencing-publication.md \
  docs/task-cards/wave-1-implementation/W1-I08-stable-reference-reparse-lineage.md \
  docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md
git diff --cached --name-only
git diff --cached --check
git commit -m "docs: close W1-I07 and release W1-I08"
```

Expected staged paths: exactly the twelve listed paths.

- [ ] **Step 4: Run fresh explicit, static, product, and full verification**

Run serially with the actual governance and receipt SHAs:

```bash
scripts/verify-wave1-implementation-cards \
  --repo-root . \
  --cards-dir docs/task-cards/wave-1-implementation \
  --transition-base "$(git rev-parse HEAD^)" \
  --transition-head "$(git rev-parse HEAD)"
scripts/verify-wave1-implementation
./mvnw -f server/pom.xml -Dtest=ProcessingPublicationIntegrationTest test
./mvnw -f server/pom.xml test
git diff --check
git status --short
```

Expected: explicit/static closure PASS, real PostgreSQL I07 focused regression PASS, full server
PASS, only the preserved untracked `.idea/` remains, and no formal database or push operation.

- [ ] **Step 5: Confirm the I08 handoff boundary**

Read the live index and I08 card. Required state:

```text
TaskCardSetStatus = READY_FOR_EXECUTION
ActiveTaskCard = W1-I08
ReadyTaskCardCount = 1
W1-I07 = DONE
W1-I08 = READY
W1-I09 = QUEUED
W1-I10 = BLOCKED_BY_DEPENDENCY
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

Only after this evidence is current may the next execution plan touch the eight W1-I08 product
paths.
