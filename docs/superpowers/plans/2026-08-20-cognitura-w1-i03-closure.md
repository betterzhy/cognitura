# Cognitura W1-I03 Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add one fail-closed `I03_CLOSE_ADVANCE` transition, record the reviewed W1-I03 candidate, close I03, and release I04 as the only READY card.

**Architecture:** Use a four-path linear governance chain rooted at `cc25439de8019a4434c2ab5aba8b32927240d8b4`, followed by one direct-child eleven-path projection receipt. Extend only the existing Wave1 card verifier and its public test harness; do not create a generic state machine or another ledger.

**Tech Stack:** Bash 3.2, Git commit/tree/blob plumbing, Markdown task-card projections, Maven/JDK 21 verification.

**Spec:** `docs/superpowers/specs/2026-08-20-cognitura-w1-i03-closure-design.md`

## Global Constraints

- `ReviewedCandidateSHA = 4e63936c631ab34807e714b90d30415a959bc13d`.
- `ReviewLevel=L3`, `ReviewRoute=deep_reviewer`, `ReviewEffort=xhigh`, `ReviewMultiplicity=ONE`, `ReviewVerdict=GO`, `P0=P1=P2=0`, `Ultra=NOT_RUN`.
- W1-I03 production and fixtures remain byte-identical to the reviewed candidate.
- `W1-I02=QUEUED`, `FormalDatabaseWrite=NOT_AUTHORIZED`, and `RemotePush=NOT_AUTHORIZED` remain unchanged.
- Do not read or modify `raw/**`, `.idea/**`, `temp-input/**`, or `dist/**`.
- Do not run concurrent full suites. Use only the smallest falsifying gate during RED/GREEN iteration.
- The closure receipt changes exactly eleven projection paths and no verifier, test, product, ledger, or VSB path.

---

### Task 1: Commit the execution plan

**Files:**
- Create: `docs/superpowers/plans/2026-08-20-cognitura-w1-i03-closure.md`

**Interfaces:**
- Consumes: the approved closure design and fixed `ClosureOriginSHA`.
- Produces: the exact TDD and receipt sequence used by Tasks 2-5.

- [ ] **Step 1: Verify the plan has no placeholders**

```bash
placeholder_pattern='T''BD|TO''DO|implement lat''er|fill in det''ails|同''上|类似''处理'
! rg -n "${placeholder_pattern}" \
  docs/superpowers/plans/2026-08-20-cognitura-w1-i03-closure.md
```

- [ ] **Step 2: Verify the governance prefix**

```bash
test "$(git rev-parse cc25439de8019a4434c2ab5aba8b32927240d8b4^{commit})" = \
  cc25439de8019a4434c2ab5aba8b32927240d8b4
git diff --check
```

- [ ] **Step 3: Commit only the plan**

```bash
git add docs/superpowers/plans/2026-08-20-cognitura-w1-i03-closure.md
test "$(git diff --cached --name-only)" = \
  docs/superpowers/plans/2026-08-20-cognitura-w1-i03-closure.md
git commit -m "docs: plan W1-I03 closure transition"
```

### Task 2: Add the focused tests-only RED

**Files:**
- Modify: `tests/task-cards/verify-wave1-implementation-cards.sh`

**Interfaces:**
- Consumes: the public production verifier and the fixed Git objects at `ClosureOriginSHA` and `ReviewedCandidateSHA`.
- Produces: `--w1-i03-closure-contract-only`, a real-Git positive chain, an eleven-path receipt, and fail-closed mutations.

- [ ] **Step 1: Add the focused CLI dispatch**

Add this exact accepted argument beside the existing focused modes:

```bash
--w1-i03-closure-contract-only)
  run_w1_i03_closure_contract
  exit 0
  ;;
```

- [ ] **Step 2: Build the governance chain from the fixed origin**

The fixture must detach a shared clone at the fixed origin and create four linear commits whose cumulative changed-path set is exactly:

```bash
closure_governance_paths=(
  docs/superpowers/specs/2026-08-20-cognitura-w1-i03-closure-design.md
  docs/superpowers/plans/2026-08-20-cognitura-w1-i03-closure.md
  tests/task-cards/verify-wave1-implementation-cards.sh
  scripts/verify-wave1-implementation-cards
)
```

Materialize each path from the main repository, preserve `100644/100755`, commit each path only once, and assert a single-parent nonempty chain with no `R*` or `C*` record. Before GREEN, if the production verifier blob equals the origin blob, append a fixture-only comment inside the clone so that the RED fixture still has a real fourth governance-path change; after GREEN the branch must naturally copy the changed production blob without the comment.

- [ ] **Step 3: Build the legal eleven-path closure receipt**

The helper must change exactly these fields and narratives:

```text
Active...TaskCard: W1-I03 -> W1-I04
W1-I03 Status: READY -> DONE
W1-I04 Status: BLOCKED_BY_DEPENDENCY -> READY
ReadyTaskCardCount: 1
W1-I02 Status: QUEUED
FormalDatabaseWrite: NOT_AUTHORIZED
RemotePush: NOT_AUTHORIZED
```

Append the exact ordered review block from the design to
`docs/engineering/cognitura-wave-1-implementation-plan.md`. Commit exactly the eleven design-specified projection paths as the direct child of the governance tip.

- [ ] **Step 4: Add positive public-entry assertions**

```bash
assert_contains "${pending_output}" "W1I03ClosureStatus = PENDING"
assert_contains "${explicit_output}" "W1I03ClosureStatus = PASS"
assert_contains "${static_output}" "W1I03ClosureStatus = PASS"
assert_contains "${static_output}" "ActiveTaskCard = W1-I04"
```

- [ ] **Step 5: Add independent fail-closed mutations**

Use real commits for: governance merge, empty, outside path, same-path second change, rename, copy, NUL, mode drift, reviewed production drift; receipt non-direct child, missing path, extra path, I03 not DONE, I04 not READY, two READY cards, I02 release, wrong successor, database authorization, push authorization, each review-block missing/duplicate/reorder/wrong-value class, stale I03 narrative, second closure, and working-tree masking. Each case must call the public verifier and assert a stable semantic diagnostic plus sibling TMPDIR cleanup.

- [ ] **Step 6: Run the focused RED exactly once**

```bash
/bin/bash -n tests/task-cards/verify-wave1-implementation-cards.sh
/bin/bash tests/task-cards/verify-wave1-implementation-cards.sh \
  --w1-i03-closure-contract-only
```

Expected first failure:

```text
FAIL: legal W1-I03 closure governance PENDING state was rejected
```

The production verifier must not yet contain `W1I03ClosureStatus`.

- [ ] **Step 7: Commit the tests-only RED**

```bash
git add tests/task-cards/verify-wave1-implementation-cards.sh
git diff --cached --check
git commit -m "test: define W1-I03 closure transition"
```

### Task 3: Implement the minimal production GREEN

**Files:**
- Modify: `scripts/verify-wave1-implementation-cards`

**Interfaces:**
- Consumes: the focused real-Git contract from Task 2.
- Produces: pending, explicit receipt, and static receipt validation for `I03_CLOSE_ADVANCE` only.

- [ ] **Step 1: Add immutable identities and path sets**

```bash
readonly w1_i03_closure_origin_sha=cc25439de8019a4434c2ab5aba8b32927240d8b4
readonly w1_i03_reviewed_candidate_sha=4e63936c631ab34807e714b90d30415a959bc13d
```

Add functions returning the exact four governance paths, eleven receipt paths, expected modes, and the ordered review block. Do not share or weaken the existing VSB restore-path function.

- [ ] **Step 2: Validate the governance chain**

`validate_w1_i03_closure_governance_chain <tip>` must verify origin ancestry; every origin-exclusive commit has exactly one parent and a nonempty diff; no rename/copy/NUL/mode drift; only four governance paths; each path changes once; cumulative set is exact four; fixed candidate production, eleven projections, ledger, VSB and W1-I02-related paths do not change.

- [ ] **Step 3: Validate pending state**

When HEAD is a legal governance tip and cards still project I03 READY/I04 blocked, static validation must print:

```text
W1I03ClosureStatus = PENDING
```

and return success before ordinary projection logic can misclassify the governance paths.

- [ ] **Step 4: Validate the receipt**

`validate_w1_i03_closure_receipt <base> <head>` must require direct-child topology, exact eleven paths, preserved modes, no rename/copy/NUL, canonical I03/I04/index/plan states, exact review block, unchanged I02/database/push fields, unchanged fixed production and clean working projection.

- [ ] **Step 5: Dispatch explicit and static replay**

Before the existing restore transition branch, detect the legal I03 READY -> I03 DONE/I04 READY pair and run the dedicated validator. For static receipt, require HEAD parent to be the legal governance tip and reject any second closure descendant or working-tree mask. Print:

```text
W1I03ClosureStatus = PASS
```

- [ ] **Step 6: Run focused GREEN and syntax checks**

```bash
/bin/bash -n scripts/verify-wave1-implementation-cards
/bin/bash -n tests/task-cards/verify-wave1-implementation-cards.sh
/bin/bash tests/task-cards/verify-wave1-implementation-cards.sh \
  --w1-i03-closure-contract-only
git diff --check
```

- [ ] **Step 7: Run the affected full regression once**

```bash
/bin/bash tests/task-cards/verify-wave1-implementation-cards.sh
scripts/verify-wave1-implementation-cards \
  --repo-root . \
  --cards-dir docs/task-cards/wave-1-implementation
vsb_snapshot="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-i03-vsb.XXXXXX")"
git clone --shared -q . "${vsb_snapshot}"
git -C "${vsb_snapshot}" checkout -q --detach \
  cc25439de8019a4434c2ab5aba8b32927240d8b4
"${vsb_snapshot}/scripts/verify-visual-style-baseline-cards" \
  --repo-root "${vsb_snapshot}" \
  --cards-dir "${vsb_snapshot}/docs/task-cards/visual-style-baseline"
git diff --quiet \
  cc25439de8019a4434c2ab5aba8b32927240d8b4..HEAD -- \
  docs/task-cards/visual-style-baseline/execution-state.md
test "$(git ls-tree cc25439de8019a4434c2ab5aba8b32927240d8b4 -- \
  docs/task-cards/visual-style-baseline/execution-state.md)" = \
  "$(git ls-tree HEAD -- docs/task-cards/visual-style-baseline/execution-state.md)"
```

- [ ] **Step 8: Commit the production GREEN**

```bash
git add scripts/verify-wave1-implementation-cards
git diff --cached --check
git commit -m "feat: verify W1-I03 closure transition"
```

### Task 4: Review the fixed closure-contract candidate

**Files:**
- Read-only review of the four governance paths and their fixed candidate.

**Interfaces:**
- Consumes: the GREEN governance tip and focused/full evidence.
- Produces: one `deep_reviewer/xhigh/ONE` GO or NO_GO verdict; Ultra stays NOT_RUN.

- [ ] **Step 1: Freeze identity**

```bash
git rev-parse HEAD HEAD^ HEAD^{tree}
git log --format='%H %P' \
  cc25439de8019a4434c2ab5aba8b32927240d8b4..HEAD
git diff --name-status \
  cc25439de8019a4434c2ab5aba8b32927240d8b4..HEAD
```

- [ ] **Step 2: Request the single L3 review**

The reviewer must inspect the exact four-path chain, Bash 3.2 correctness, transition ordering, working-tree masking, candidate production freeze, review-block closed set, negative mutation ability, TMP cleanup, and unchanged authorization boundaries. Required output:

```text
ReviewLevel = L3
Route = deep_reviewer
Effort = xhigh
Multiplicity = ONE
Ultra = NOT_RUN
```

- [ ] **Step 3: Resolve findings inside the four governance paths**

For each P0/P1/P2, add a tests-only RED where behavior changes, implement the minimum correction, rerun only affected focused gates, and request review of the new fixed candidate. Do not modify receipt projections before GO.

### Task 5: Create and verify the eleven-path closure receipt

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
- Modify: `docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md`
- Modify: `docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md`

**Interfaces:**
- Consumes: the reviewed governance tip and the exact review receipt.
- Produces: a projection-only direct-child commit with I04 as the sole READY card.

- [ ] **Step 1: Apply only canonical state changes**

Set I03 DONE, I04 READY, all active projections to I04, both tables consistently, and append the ordered review block. Keep I02 QUEUED and every database/push field unchanged.

- [ ] **Step 2: Verify exact staged WriteSet**

```bash
git add \
  AGENTS.md README.md docs/design/wave-1/README.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-wave-1-design-plan.md \
  docs/engineering/cognitura-wave-1-design-acceptance.md \
  docs/engineering/cognitura-wave-1-implementation-plan.md \
  docs/task-cards/wave-1/README.md \
  docs/task-cards/wave-1-implementation/README.md \
  docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md \
  docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md
git diff --cached --check
test "$(git diff --cached --name-only | wc -l | tr -d ' ')" = 11
```

- [ ] **Step 3: Commit the receipt**

```bash
closure_base="$(git rev-parse HEAD)"
git commit -m "chore: close W1-I03 and release W1-I04"
closure_head="$(git rev-parse HEAD)"
```

- [ ] **Step 4: Verify explicit and static replay**

```bash
scripts/verify-wave1-implementation-cards \
  --repo-root . \
  --cards-dir docs/task-cards/wave-1-implementation \
  --transition-base "${closure_base}" \
  --transition-head "${closure_head}"
scripts/verify-wave1-implementation-cards \
  --repo-root . \
  --cards-dir docs/task-cards/wave-1-implementation
```

- [ ] **Step 5: Run final no-push acceptance**

```bash
/bin/bash tests/task-cards/verify-wave1-implementation-cards.sh
vsb_snapshot="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-i03-vsb-final.XXXXXX")"
git clone --shared -q . "${vsb_snapshot}"
git -C "${vsb_snapshot}" checkout -q --detach \
  cc25439de8019a4434c2ab5aba8b32927240d8b4
"${vsb_snapshot}/scripts/verify-visual-style-baseline-cards" \
  --repo-root "${vsb_snapshot}" \
  --cards-dir "${vsb_snapshot}/docs/task-cards/visual-style-baseline"
git diff --quiet \
  cc25439de8019a4434c2ab5aba8b32927240d8b4..HEAD -- \
  docs/task-cards/visual-style-baseline/execution-state.md
./mvnw -f server/pom.xml -Dtest='io.cognitura.source.docx.security.*Test' test
git diff --check
git status --short --branch
```

Run Markdown validation only from a tracked `git archive HEAD` snapshot so untracked `temp-input/**` and `.idea/**` are never enumerated.

- [ ] **Step 6: Confirm terminal handoff**

The final public output must include:

```text
W1I03ClosureStatus = PASS
TaskCardSetStatus = READY_FOR_EXECUTION
ActiveTaskCard = W1-I04
```

Stop before changing any W1-I04 production path. I02 remains queued behind its independent database Gate.
