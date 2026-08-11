# Cognitura MDR Automatic Serial Execution Governance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish the approved single-authority execution ledger, pass its fixed-commit governance review, activate `MDR-I00` from the user's set-level authorization, and then enter the existing `MDR-I00..MDR-I08` automatic serial card loop without further user checkpoints.

**Architecture:** A one-time 17-path bootstrap removes mutable card state from central documents and card bodies, then creates `execution-state.md` as the sole runtime authority. Business candidates remain limited to each card's exact `WriteSet`; after a candidate passes its Gate and independent fixed-SHA review, a separate local commit changes only `execution-state.md` and releases the unique successor.

**Tech Stack:** Bash 3.2-compatible validator and mutation fixtures, Markdown governance artifacts, Git fixed commits, the existing Node 24.18.0/pnpm 11.17.0 Web toolchain, `deep_reviewer`, and `ultra_gatekeeper`.

## Global Constraints

- `CanonicalProjectName = Cognitura`.
- Approved governance design: `docs/superpowers/specs/2026-08-11-mdr-automatic-serial-execution-governance-design.md`.
- Governed set: exactly `MDR-I00..MDR-I08`, in that order.
- The user's `2026-08-11` instruction authorizes the governance bootstrap and the later set activation from `MDR-I00` through `MDR-I08` without per-card user checkpoints.
- “No human review” removes user checkpoints only; `MDR-I00..MDR-I07` still require independent `deep_reviewer` zero-finding review and `MDR-I08` still requires `ultra_gatekeeper` final GO/NO-GO.
- Bootstrap may modify exactly the 17 paths in Task 2. Plan/approval recording in Task 1 is a separate docs-only commit and is not part of the bootstrap candidate.
- Every business candidate is limited to the owning card's exact `WriteSet` and uses RED before GREEN.
- Every runtime transition is a separate non-amend local commit whose only changed path is `docs/task-cards/module-default-reading-implementation/execution-state.md`.
- Preserve existing Wave 1 source work and untracked `.idea/`.
- Do not modify `schemas/**`, `server/**`, `raw/**`, `web/src/App.tsx`, routes, persistence, migrations, provider configuration, or formal design Owners.
- `FormalDatabaseWrite = NOT_AUTHORIZED`.
- `RemotePush = NOT_AUTHORIZED`.
- Renderer projects Canonical facts and must not invent Conditions, Results, Relation semantics, or a second fact model.
- `DOC-GAP-MDR-001` continues to block full Conditions/Results acceptance; it does not block the bounded MDR projection slice.
- Use non-amend local commits. Never reset or push.

---

## File Structure

Task 1 changes only:

```text
docs/superpowers/specs/2026-08-11-mdr-automatic-serial-execution-governance-design.md
docs/superpowers/plans/2026-08-11-mdr-automatic-serial-execution-governance.md
```

Task 2 bootstrap changes exactly:

```text
AGENTS.md
README.md
docs/engineering/cognitura-design-index.md
docs/task-cards/README.md
docs/task-cards/module-default-reading-implementation/README.md
docs/task-cards/module-default-reading-implementation/execution-state.md
docs/task-cards/module-default-reading-implementation/MDR-I00-web-test-foundation.md
docs/task-cards/module-default-reading-implementation/MDR-I01-canonical-narrative-projection.md
docs/task-cards/module-default-reading-implementation/MDR-I02-question-conclusion-spine.md
docs/task-cards/module-default-reading-implementation/MDR-I03-element-boundary-reading.md
docs/task-cards/module-default-reading-implementation/MDR-I04-stage-chain-renderer-projection.md
docs/task-cards/module-default-reading-implementation/MDR-I05-key-relation-projection.md
docs/task-cards/module-default-reading-implementation/MDR-I06-source-entry-projection.md
docs/task-cards/module-default-reading-implementation/MDR-I07-reading-first-composition.md
docs/task-cards/module-default-reading-implementation/MDR-I08-fixed-slice-review.md
scripts/verify-module-default-reading-implementation-cards
tests/task-cards/verify-module-default-reading-implementation-cards.sh
```

`execution-state.md` owns only mutable authorization and runtime facts. Card bodies continue to own dependencies, Gates, business `WriteSet`, validation commands, commit commands, and review routes.

---

### Task 1: Record approval and fix the executable plan

**Files:**
- Modify: `docs/superpowers/specs/2026-08-11-mdr-automatic-serial-execution-governance-design.md`
- Create: `docs/superpowers/plans/2026-08-11-mdr-automatic-serial-execution-governance.md`

**Interfaces:**
- Consumes: the reviewed design candidate `697b39aebfdf3a6c0eeda0815da5b377d362ba70` and the user's set-level automatic-execution instruction.
- Produces: an approved spec state and this exact implementation route.

- [ ] **Step 1: Record the authorization without opening business execution early**

Use these exact spec fields:

```text
WrittenSpecReview = USER_APPROVED
AutomaticSerialExecutionEntry = BLOCKED_BY_GOVERNANCE_BOOTSTRAP
ExecutionStateAuthority = NOT_CREATED
GovernanceImplementationAuthorization = USER_AUTHORIZED
SetBusinessImplementationAuthorization = USER_AUTHORIZED_PENDING_GOVERNANCE_BOOTSTRAP
HumanCheckpointRequirement = NONE_WITHIN_AUTHORIZED_SET
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
ActiveImplementationTaskCard = NONE
```

- [ ] **Step 2: Self-review the complete plan**

Run:

```bash
git diff --check
! rg -n 'T''BD|T''ODO|implement ''later|fill in ''details|待''定|稍后''补充' \
  docs/superpowers/plans/2026-08-11-mdr-automatic-serial-execution-governance.md
bash tests/ci/verify-markdown-links.sh
```

Expected: diff check and Markdown links PASS; placeholder scan returns no matches.

- [ ] **Step 3: Commit the plan separately from bootstrap**

```bash
git add \
  docs/superpowers/specs/2026-08-11-mdr-automatic-serial-execution-governance-design.md \
  docs/superpowers/plans/2026-08-11-mdr-automatic-serial-execution-governance.md
git diff --cached --check
git commit -m "docs: approve MDR automatic execution plan"
```

Expected: the commit changes exactly the two Task 1 paths; `.idea/` remains untracked.

### Task 2: Bootstrap the single runtime authority with RED then GREEN

**Files:**
- Modify: `AGENTS.md`
- Modify: `README.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/task-cards/README.md`
- Modify: `docs/task-cards/module-default-reading-implementation/README.md`
- Create: `docs/task-cards/module-default-reading-implementation/execution-state.md`
- Modify: all nine `docs/task-cards/module-default-reading-implementation/MDR-I*.md` files
- Modify: `scripts/verify-module-default-reading-implementation-cards`
- Modify: `tests/task-cards/verify-module-default-reading-implementation-cards.sh`

**Interfaces:**
- Consumes: the approved spec and immutable card dependency/WriteSet/review contracts.
- Produces: `execution-state.md` as the only mutable state authority and a Bash 3.2 validator for bootstrap, activation, advance, stop, NO-GO, and completion states.

- [ ] **Step 1: Add failing behavioral fixtures before changing the validator or documents**

Extend `tests/task-cards/verify-module-default-reading-implementation-cards.sh` so it executes the real validator against copied card directories and literal ledger fixtures. The new canonical assertions are:

```text
ExecutionStateAuthority = docs/task-cards/module-default-reading-implementation/execution-state.md
GovernanceBootstrapStatus = AWAITING_FIXED_COMMIT_REVIEW
SetAuthorizationStatus = USER_AUTHORIZED_AWAITING_GOVERNANCE_BOOTSTRAP
TaskCardSetStatus = USER_AUTHORIZED_AWAITING_GOVERNANCE_REVIEW
ActiveImplementationTaskCard = NONE
ReleasedTaskCard = NONE
CompletedTaskCards = NONE
NextImplementationTaskCard = MDR-I00
ReadyTaskCardCount = 0
BusinessImplementation = NOT_AUTHORIZED
```

Add literal mutation fixtures for these breaks:

```text
missing execution-state ledger
second mutable Active state in AGENTS.md
card Status changed from GOVERNED_BY_EXECUTION_STATE to READY
set authorization missing before I00 activation
bootstrap review verdict missing before I00 activation
bootstrap review candidate is not a 40-character SHA
two READY/ACTIVE cards
dependency prefix skipped
review verdict has P1=1 but successor released
review receipt candidate SHA differs from TransitionBaseSHA
transition diff includes a business file
transition diff includes a card or central index
transition diff omits execution-state.md
transition attempts amend or push
transition introduces schemas/, server/, raw/, App.tsx, route, or migration path
STOPPED_BY_USER state still has an active card
BLOCKED_BY_DOCUMENTATION_GAP state still has an active card
FINAL_NO_GO releases a successor
COMPLETE releases Wave 1 source, Schema, database, or page work
```

The expected values must be hand-written literals. The tests must not derive expected successors or status values with validator helpers.

- [ ] **Step 2: Run the focused test and observe RED**

Run:

```bash
/bin/bash tests/task-cards/verify-module-default-reading-implementation-cards.sh
```

Expected: FAIL because the canonical ledger is missing and the current validator still enforces nine duplicated blocked statuses.

- [ ] **Step 3: Create the initial execution ledger**

Create `docs/task-cards/module-default-reading-implementation/execution-state.md` with this exact initial data block:

```text
CanonicalProjectName = Cognitura
TaskCardSet = MODULE_DEFAULT_READING_IMPLEMENTATION
ExecutionStateVersion = 1
ExecutionStateAuthority = THIS_DOCUMENT
GovernanceBootstrapStatus = AWAITING_FIXED_COMMIT_REVIEW
GovernanceReviewedCandidateSHA = NONE
GovernanceReviewRoute = deep_reviewer
GovernanceReviewVerdict = NOT_RUN
SetAuthorizationStatus = USER_AUTHORIZED_AWAITING_GOVERNANCE_BOOTSTRAP
SetAuthorizationScope = MDR-I00..MDR-I08_AUTOMATIC_SERIAL
HumanCheckpointRequirement = NONE_WITHIN_AUTHORIZED_SET
TaskCardSetStatus = USER_AUTHORIZED_AWAITING_GOVERNANCE_REVIEW
ActiveImplementationTaskCard = NONE
ReleasedTaskCard = NONE
CompletedTaskCards = NONE
CurrentCandidateSHA = NONE
CurrentGateStatus = NOT_RUN
CurrentReviewRoute = NONE
CurrentReviewVerdict = NOT_RUN
NextImplementationTaskCard = MDR-I00
TransitionSequence = 0
TransitionKind = BOOTSTRAP
TransitionBaseSHA = NONE
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The prose below the block must define the only allowed serial states:

```text
USER_AUTHORIZED_AWAITING_GOVERNANCE_REVIEW
IN_PROGRESS
STOPPED_BY_USER
BLOCKED_BY_DOCUMENTATION_GAP
BLOCKED_BY_AUTHORITY_EXPANSION
FINAL_NO_GO
COMPLETE
```

- [ ] **Step 4: Replace duplicated runtime facts with authority pointers**

In `AGENTS.md`, root `README.md`, `docs/engineering/cognitura-design-index.md`, and `docs/task-cards/README.md`, use:

```text
ModuleDefaultReadingExecutionStateAuthority = docs/task-cards/module-default-reading-implementation/execution-state.md
ModuleDefaultReadingImplementationTaskCardSet = GOVERNED_BY_EXECUTION_STATE
ModuleDefaultReadingImplementationEntry = GOVERNED_BY_EXECUTION_STATE
ModuleDefaultReadingActiveImplementationTaskCard = SEE_MODULE_DEFAULT_READING_EXECUTION_STATE
ModuleDefaultReadingBusinessImplementation = SEE_MODULE_DEFAULT_READING_EXECUTION_STATE
ActiveImplementationTaskCard = NONE
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The unqualified Active/Business fields are immutable terminal facts owned by the already-closed
high-fidelity visual Gate. They must remain unchanged; only the namespaced MDR fields point to the
new ledger. The MDR validator must reject any attempt to use the unqualified fields as MDR runtime
state.

In the MDR index and its table, use:

```text
ExecutionStateAuthority = execution-state.md
TaskCardSetStatus = GOVERNED_BY_EXECUTION_STATE
ActiveImplementationTaskCard = SEE_EXECUTION_STATE
ReleasedTaskCard = SEE_EXECUTION_STATE
BusinessImplementation = SEE_EXECUTION_STATE
TaskCardRelease = GOVERNED_BY_EXECUTION_STATE
TaskCardExecution = GOVERNED_BY_EXECUTION_STATE
```

For every `MDR-I00..MDR-I08` body, replace the mutable field with:

```text
Status = GOVERNED_BY_EXECUTION_STATE
ExecutionStateAuthority = docs/task-cards/module-default-reading-implementation/execution-state.md
```

Replace every clause that requires a new user release or forbids automatic release inside the MDR set with: the unique successor is released only by a valid `execution-state.md` transition after dependency, Gate, fixed-SHA, and review checks pass. Retain I08's prohibition on automatically releasing later Schema, database, page, or Wave 1 source work.

- [ ] **Step 5: Implement the minimum Bash 3.2 state validator**

Keep the current CLI and add optional fixed-transition arguments:

```text
scripts/verify-module-default-reading-implementation-cards \
  --cards-dir PATH \
  [--transition-base SHA --transition-head SHA]
```

Require both transition arguments together. Preserve all immutable card checks: exact nine filenames, exact dependencies, Gates, review routes, production limits, business `WriteSet`, commit `git add` paths, forbidden `server/**`, `schemas/**`, `raw/**`, `.idea/**`, `git push`, I05 identity/type/endpoints, and I07 exact formal order.

Add these state rules:

```text
all card Status fields = GOVERNED_BY_EXECUTION_STATE
all central and card ExecutionStateAuthority pointers = the one ledger
CompletedTaskCards = NONE or a strict prefix of MDR-I00..MDR-I08
NextImplementationTaskCard = first card outside that prefix, except terminal states
IN_PROGRESS has exactly one identical ActiveImplementationTaskCard and ReleasedTaskCard
non-IN_PROGRESS states have ActiveImplementationTaskCard = NONE and ReleasedTaskCard = NONE
activation requires GovernanceBootstrapStatus = PASS
activation requires GovernanceReviewVerdict = GO_P0_0_P1_0_P2_0
activation requires SetAuthorizationStatus = USER_AUTHORIZED
advance requires CurrentGateStatus = PASS
advance requires CurrentReviewVerdict = GO_P0_0_P1_0_P2_0
MDR-I00..MDR-I07 use CurrentReviewRoute = deep_reviewer
MDR-I08 uses CurrentReviewRoute = ultra_gatekeeper
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

When fixed-transition arguments are present, run `git diff --name-only BASE HEAD` and require exactly:

```text
docs/task-cards/module-default-reading-implementation/execution-state.md
```

Require `TransitionBaseSHA = BASE`. For `ACTIVATE_SET`, bind `GovernanceReviewedCandidateSHA` to `BASE`; for `ADVANCE`, `FINAL_NO_GO`, or `COMPLETE`, bind `CurrentCandidateSHA` to `BASE`. Reject non-40-character SHAs and non-zero review receipts.

- [ ] **Step 6: Run GREEN and regression verification**

Run:

```bash
/bin/bash tests/task-cards/verify-module-default-reading-implementation-cards.sh
scripts/verify-module-default-reading-implementation-cards \
  --cards-dir docs/task-cards/module-default-reading-implementation
bash tests/ci/verify-markdown-links.sh
scripts/verify-wave1-design
scripts/verify-high-fidelity-design
git diff --check
```

Expected: all commands PASS; the canonical output reports zero ready cards and the pending governance-review state.

- [ ] **Step 7: Check the exact bootstrap candidate and commit**

Run an exact path comparison against the 17-path list in this plan. Then:

```bash
git add AGENTS.md README.md \
  docs/engineering/cognitura-design-index.md \
  docs/task-cards/README.md \
  docs/task-cards/module-default-reading-implementation/README.md \
  docs/task-cards/module-default-reading-implementation/execution-state.md \
  docs/task-cards/module-default-reading-implementation/MDR-I*.md \
  scripts/verify-module-default-reading-implementation-cards \
  tests/task-cards/verify-module-default-reading-implementation-cards.sh
git diff --cached --check
git commit -m "feat: bootstrap MDR automatic execution governance"
```

Expected: the fixed commit changes exactly 17 paths and excludes `.idea/`, `web/**`, `server/**`, `schemas/**`, and `raw/**`.

### Task 3: Pass the fixed bootstrap review and activate MDR-I00

**Files:**
- Review only: the fixed 17-path bootstrap candidate
- Modify after review: `docs/task-cards/module-default-reading-implementation/execution-state.md`

**Interfaces:**
- Consumes: Task 2 fixed SHA and a `deep_reviewer` receipt.
- Produces: one ledger-only activation commit with `MDR-I00` as the unique active/released card.

- [ ] **Step 1: Dispatch fixed-commit general review automatically**

Give the exact Task 2 SHA to a new `deep_reviewer`. Require:

```text
Verdict = GO
P0 = 0
P1 = 0
P2 = 0
```

Any finding returns to Task 2, stays inside the 17-path bootstrap WriteSet, creates a new non-amend candidate, reruns Task 2 Step 6, and triggers a new fixed-SHA review. No user checkpoint is inserted.

- [ ] **Step 2: Write the activation state**

After zero-finding GO, capture and validate the reviewed candidate:

```bash
bootstrap_candidate_sha="$(git rev-parse HEAD)"
test "${#bootstrap_candidate_sha}" -eq 40
```

Change only the ledger and interpolate the captured SHA into both SHA fields:

```text
GovernanceBootstrapStatus = PASS
GovernanceReviewedCandidateSHA = ${bootstrap_candidate_sha}
GovernanceReviewRoute = deep_reviewer
GovernanceReviewVerdict = GO_P0_0_P1_0_P2_0
SetAuthorizationStatus = USER_AUTHORIZED
TaskCardSetStatus = IN_PROGRESS
ActiveImplementationTaskCard = MDR-I00
ReleasedTaskCard = MDR-I00
CompletedTaskCards = NONE
CurrentCandidateSHA = NONE
CurrentGateStatus = NOT_RUN
CurrentReviewRoute = NONE
CurrentReviewVerdict = NOT_RUN
NextImplementationTaskCard = MDR-I00
TransitionSequence = 1
TransitionKind = ACTIVATE_SET
TransitionBaseSHA = ${bootstrap_candidate_sha}
BusinessImplementation = AUTHORIZED_FOR_MDR_I00_I08
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

- [ ] **Step 3: Validate and commit the activation**

Before commit:

```bash
test "$(git diff --name-only)" = \
  "docs/task-cards/module-default-reading-implementation/execution-state.md"
/bin/bash tests/task-cards/verify-module-default-reading-implementation-cards.sh
scripts/verify-module-default-reading-implementation-cards \
  --cards-dir docs/task-cards/module-default-reading-implementation
git diff --check
```

Commit:

```bash
git add docs/task-cards/module-default-reading-implementation/execution-state.md
git commit -m "docs: activate MDR automatic execution"
scripts/verify-module-default-reading-implementation-cards \
  --cards-dir docs/task-cards/module-default-reading-implementation \
  --transition-base HEAD^ --transition-head HEAD
```

Expected: validator PASS and exactly one active card, `MDR-I00`.

### Task 4: Execute the existing MDR card loop without user checkpoints

**Files:**
- Business candidate: exactly the current card's `WriteSet`
- Runtime transition: only `docs/task-cards/module-default-reading-implementation/execution-state.md`

**Interfaces:**
- Consumes: the unique active card from the ledger, the card body, and its formal design inputs.
- Produces: eight independently reviewed implementation candidates followed by the I08 final fixed-slice verdict.

Use this exact serial mapping:

| Card | Card body | Review route | Successor |
|---|---|---|---|
| `MDR-I00` | `MDR-I00-web-test-foundation.md` | `deep_reviewer` | `MDR-I01` |
| `MDR-I01` | `MDR-I01-canonical-narrative-projection.md` | `deep_reviewer` | `MDR-I02` |
| `MDR-I02` | `MDR-I02-question-conclusion-spine.md` | `deep_reviewer` | `MDR-I03` |
| `MDR-I03` | `MDR-I03-element-boundary-reading.md` | `deep_reviewer` | `MDR-I04` |
| `MDR-I04` | `MDR-I04-stage-chain-renderer-projection.md` | `deep_reviewer` | `MDR-I05` |
| `MDR-I05` | `MDR-I05-key-relation-projection.md` | `deep_reviewer` | `MDR-I06` |
| `MDR-I06` | `MDR-I06-source-entry-projection.md` | `deep_reviewer` | `MDR-I07` |
| `MDR-I07` | `MDR-I07-reading-first-composition.md` | `deep_reviewer` | `MDR-I08` |
| `MDR-I08` | `MDR-I08-fixed-slice-review.md` | `ultra_gatekeeper` | terminal |

- [ ] **Step 1: Rehydrate and verify the unique current card**

At every iteration, reread `AGENTS.md`, the ledger, the MDR index, the current card, its listed formal inputs, HEAD, status, recent commits, and Gate evidence. Require the ledger's `ActiveImplementationTaskCard`, `ReleasedTaskCard`, and `NextImplementationTaskCard` to be identical and require every dependency to appear in `CompletedTaskCards`.

- [ ] **Step 2: Follow the card's RED then GREEN literally**

Add only the card's specified failing tests, run the exact RED command, and record the expected behavioral failure. Implement the minimum GREEN only inside the card's exact `WriteSet`; run its target tests, locked-toolchain build, unified MDR verification, applicable existing Gates, `git diff --check`, and exact write-set comparison.

- [ ] **Step 3: Create and review the card's independent fixed candidate**

Use the card's exact `git add` command and commit message. For `MDR-I00..MDR-I07`, dispatch a new `deep_reviewer` against the exact SHA and require `GO / P0=0 / P1=0 / P2=0`. Review findings return to the same card, produce a new non-amend SHA, and are automatically re-reviewed.

- [ ] **Step 4: Persist the transition in a ledger-only commit**

For a successful `MDR-I00..MDR-I07` candidate, select the exact row below; values are literal and
must not be calculated by the validator under test:

| Completed current card | `CompletedTaskCards` | Successor for Active/Released/Next | `TransitionSequence` |
|---|---|---|---|
| `MDR-I00` | `MDR-I00` | `MDR-I01` | `2` |
| `MDR-I01` | `MDR-I00,MDR-I01` | `MDR-I02` | `3` |
| `MDR-I02` | `MDR-I00,MDR-I01,MDR-I02` | `MDR-I03` | `4` |
| `MDR-I03` | `MDR-I00,MDR-I01,MDR-I02,MDR-I03` | `MDR-I04` | `5` |
| `MDR-I04` | `MDR-I00,MDR-I01,MDR-I02,MDR-I03,MDR-I04` | `MDR-I05` | `6` |
| `MDR-I05` | `MDR-I00,MDR-I01,MDR-I02,MDR-I03,MDR-I04,MDR-I05` | `MDR-I06` | `7` |
| `MDR-I06` | `MDR-I00,MDR-I01,MDR-I02,MDR-I03,MDR-I04,MDR-I05,MDR-I06` | `MDR-I07` | `8` |
| `MDR-I07` | `MDR-I00,MDR-I01,MDR-I02,MDR-I03,MDR-I04,MDR-I05,MDR-I06,MDR-I07` | `MDR-I08` | `9` |

Load that literal mapping and capture the reviewed business candidate before editing the ledger:

```bash
current_card="$(sed -n 's/^ActiveImplementationTaskCard = //p' \
  docs/task-cards/module-default-reading-implementation/execution-state.md)"
case "${current_card}" in
  MDR-I00)
    selected_completed_prefix="MDR-I00"
    selected_successor="MDR-I01"
    selected_transition_sequence="2"
    ;;
  MDR-I01)
    selected_completed_prefix="MDR-I00,MDR-I01"
    selected_successor="MDR-I02"
    selected_transition_sequence="3"
    ;;
  MDR-I02)
    selected_completed_prefix="MDR-I00,MDR-I01,MDR-I02"
    selected_successor="MDR-I03"
    selected_transition_sequence="4"
    ;;
  MDR-I03)
    selected_completed_prefix="MDR-I00,MDR-I01,MDR-I02,MDR-I03"
    selected_successor="MDR-I04"
    selected_transition_sequence="5"
    ;;
  MDR-I04)
    selected_completed_prefix="MDR-I00,MDR-I01,MDR-I02,MDR-I03,MDR-I04"
    selected_successor="MDR-I05"
    selected_transition_sequence="6"
    ;;
  MDR-I05)
    selected_completed_prefix="MDR-I00,MDR-I01,MDR-I02,MDR-I03,MDR-I04,MDR-I05"
    selected_successor="MDR-I06"
    selected_transition_sequence="7"
    ;;
  MDR-I06)
    selected_completed_prefix="MDR-I00,MDR-I01,MDR-I02,MDR-I03,MDR-I04,MDR-I05,MDR-I06"
    selected_successor="MDR-I07"
    selected_transition_sequence="8"
    ;;
  MDR-I07)
    selected_completed_prefix="MDR-I00,MDR-I01,MDR-I02,MDR-I03,MDR-I04,MDR-I05,MDR-I06,MDR-I07"
    selected_successor="MDR-I08"
    selected_transition_sequence="9"
    ;;
  *)
    printf 'unsupported active MDR card: %s\n' "${current_card}" >&2
    exit 1
    ;;
esac
reviewed_candidate_sha="$(git rev-parse HEAD)"
test "${#reviewed_candidate_sha}" -eq 40
```

Update only the ledger with the selected literal prefix, successor, and sequence:

```text
CompletedTaskCards = ${selected_completed_prefix}
CurrentCandidateSHA = ${reviewed_candidate_sha}
CurrentGateStatus = PASS
CurrentReviewRoute = deep_reviewer
CurrentReviewVerdict = GO_P0_0_P1_0_P2_0
ActiveImplementationTaskCard = ${selected_successor}
ReleasedTaskCard = ${selected_successor}
NextImplementationTaskCard = ${selected_successor}
TransitionSequence = ${selected_transition_sequence}
TransitionKind = ADVANCE
TransitionBaseSHA = ${reviewed_candidate_sha}
```

Run the canonical validator, confirm the worktree diff is only the ledger, commit locally, then verify the fixed transition with `--transition-base HEAD^ --transition-head HEAD`. Immediately begin the successor without asking the user.

- [ ] **Step 5: Apply fail-closed terminal handling**

On user stop, real DocumentationGap, authority expansion, or an unclosable repeated Gate, make no out-of-scope change. Record the matching terminal state in a ledger-only commit only when the validator accepts it. Ordinary RED, test/build failure, or reviewer finding remains inside the current-card repair loop.

- [ ] **Step 6: Run I08 final gate**

After `MDR-I07` advances to `MDR-I08`, follow the I08 review-only card. Give the fixed full-slice candidate to `ultra_gatekeeper`. On GO, write a ledger-only `COMPLETE` transition with all nine cards in `CompletedTaskCards`, no active/released/next card, and no downstream release. On NO-GO, write `FINAL_NO_GO` with no successor and stop.

Capture the fixed full-slice candidate:

```bash
final_candidate_sha="$(git rev-parse HEAD)"
test "${#final_candidate_sha}" -eq 40
```

The GO terminal fields are exactly:

```text
TaskCardSetStatus = COMPLETE
ActiveImplementationTaskCard = NONE
ReleasedTaskCard = NONE
CompletedTaskCards = MDR-I00,MDR-I01,MDR-I02,MDR-I03,MDR-I04,MDR-I05,MDR-I06,MDR-I07,MDR-I08
CurrentCandidateSHA = ${final_candidate_sha}
CurrentGateStatus = PASS
CurrentReviewRoute = ultra_gatekeeper
CurrentReviewVerdict = GO_P0_0_P1_0_P2_0
NextImplementationTaskCard = NONE
TransitionSequence = 10
TransitionKind = COMPLETE
TransitionBaseSHA = ${final_candidate_sha}
BusinessImplementation = COMPLETE_FOR_MDR_I00_I08
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The NO-GO terminal fields are exactly:

```text
TaskCardSetStatus = FINAL_NO_GO
ActiveImplementationTaskCard = NONE
ReleasedTaskCard = NONE
CompletedTaskCards = MDR-I00,MDR-I01,MDR-I02,MDR-I03,MDR-I04,MDR-I05,MDR-I06,MDR-I07
CurrentCandidateSHA = ${final_candidate_sha}
CurrentGateStatus = NO_GO
CurrentReviewRoute = ultra_gatekeeper
CurrentReviewVerdict = NO_GO
NextImplementationTaskCard = NONE
TransitionSequence = 10
TransitionKind = FINAL_NO_GO
TransitionBaseSHA = ${final_candidate_sha}
BusinessImplementation = AUTHORIZED_FOR_MDR_I00_I08
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

In either case, the terminal commit changes only the ledger and is verified with
`--transition-base HEAD^ --transition-head HEAD` after commit.

## Plan Completion Gate

The governance plan is implemented when:

```text
ExecutionStateAuthority = docs/task-cards/module-default-reading-implementation/execution-state.md
GovernanceBootstrapStatus = PASS
GovernanceReviewVerdict = GO_P0_0_P1_0_P2_0
SetAuthorizationStatus = USER_AUTHORIZED
TaskCardSetStatus = IN_PROGRESS
ActiveImplementationTaskCard = MDR-I00
ReleasedTaskCard = MDR-I00
BusinessImplementation = AUTHORIZED_FOR_MDR_I00_I08
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

After that Gate, Task 4 continues automatically until `MDR-I08` reaches `COMPLETE` or a listed fail-closed terminal state. No remote push, formal database write, Schema/database/backend/route/raw change, or downstream card release is authorized.
