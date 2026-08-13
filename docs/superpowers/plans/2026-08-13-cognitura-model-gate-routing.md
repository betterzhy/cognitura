# Cognitura Model Gate Routing Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the paused Visual Style Baseline governance chain to one applicable xhigh gate, implement the approved one-time receipt correction, and produce the only legal VSB-02 release anchor without rewriting historical evidence.

**Architecture:** The failed receipt `0ff4109...`, frozen correction design/plan, and approved model-route design remain immutable ancestors. A linear no-ledger governance candidate covers the union of the two frozen correction paths and approved eight-path migration WriteSet; real-Git fixtures prove the route and correction topology RED before production changes. One fixed-SHA L4 `deep_reviewer / xhigh` gate reviews that cumulative candidate, then a direct ledger-only child performs the exact version 2 to version 3 correction.

**Tech Stack:** Bash 3.2, Git object plumbing, Markdown governance contracts, shell contract tests, `apply_patch`, local non-amend Git commits.

---

## Fixed authority and boundaries

```text
CanonicalProjectName = Cognitura
ApprovedModelRouteDesignSHA = 1199e76a18db1d168c67c328ce7f195f3cdac7d9
FrozenReceiptCorrectionSpecSHA = dc4a105bbe95b1b07fa0e734cec1148eab15279c
FrozenReceiptCorrectionPlanSHA = f4bd848186a4a4d2d771d0d031340483bfa5de9b
CorrectionOriginReceiptSHA = 0ff410961b0f3865652e54ae46453646ed87f69e
ReviewedVSB01CandidateSHA = 108592b757ba50ea6ded7b901bd2b623737a7048
CorrectionKind = RECEIPT_CORRECTION
CorrectionMultiplicity = EXACTLY_ONCE
ReceiptCorrectionReviewLevel = L4
ReceiptCorrectionReviewRoute = deep_reviewer
ReceiptCorrectionReviewEffort = xhigh
ReceiptCorrectionReviewMultiplicity = ONE
ReceiptCorrectionReviewVerdict = FINAL_GO_P0_0_P1_0_P2_0
HistoryRewrite = FORBIDDEN
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
Deployment = NOT_AUTHORIZED
```

Historical `GovernanceRepairReviewRoute = deep_reviewer+ultra_gatekeeper` values remain immutable facts. The migration changes only current receipt-correction, VSB-02, and VSB-03 routing.

The eight-path migration WriteSet is exactly:

```text
AGENTS.md
docs/superpowers/specs/2026-08-13-cognitura-model-gate-routing-design.md
docs/superpowers/plans/2026-08-13-cognitura-model-gate-routing.md
docs/task-cards/visual-style-baseline/README.md
docs/task-cards/visual-style-baseline/VSB-02-module-default-reading-visual.md
docs/task-cards/visual-style-baseline/VSB-03-fixed-visual-acceptance.md
scripts/verify-visual-style-baseline-cards
tests/task-cards/verify-visual-style-baseline-cards.sh
```

Because the correction candidate chain starts after `0ff4109...`, its exact cumulative path set is those eight paths plus these two immutable historical paths:

```text
docs/superpowers/specs/2026-08-13-cognitura-vsb-receipt-correction-design.md
docs/superpowers/plans/2026-08-13-cognitura-vsb-receipt-correction.md
```

Every origin-exclusive governance commit must be single-parent, non-empty, no-ledger, NUL-free, mode-preserving, no-merge, no-rename/copy, and a non-empty subset of that exact ten-path set. The cumulative set must equal all ten paths. Preserve untracked `.idea/`; do not read or stage it.

### Task 1: Freeze this implementation plan

**Files:**

- Create: `docs/superpowers/plans/2026-08-13-cognitura-model-gate-routing.md`

- [ ] **Step 1: Verify the approved starting point**

```bash
test "$(git branch --show-current)" = "codex/high-fidelity-design-integration"
test "$(git rev-parse HEAD)" = "1199e76a18db1d168c67c328ce7f195f3cdac7d9"
test "$(git status --short)" = "?? .idea/"
test "$(git rev-parse 1199e76a18db1d168c67c328ce7f195f3cdac7d9^)" = "f4bd848186a4a4d2d771d0d031340483bfa5de9b"
```

Expected: all commands exit zero.

- [ ] **Step 2: Commit only the plan**

```bash
git add docs/superpowers/plans/2026-08-13-cognitura-model-gate-routing.md
git diff --cached --check
test "$(git diff --cached --name-only)" = "docs/superpowers/plans/2026-08-13-cognitura-model-gate-routing.md"
git commit -m "docs: plan Cognitura model gate migration"
MODEL_ROUTE_PLAN_SHA="$(git rev-parse HEAD)"
test "$(git rev-parse HEAD^)" = "1199e76a18db1d168c67c328ce7f195f3cdac7d9"
```

Expected: a non-amend, single-parent plan commit; production and tests use its literal SHA.

### Task 2: Define route and correction behavior in RED

**Files:**

- Modify: `tests/task-cards/verify-visual-style-baseline-cards.sh`

- [ ] **Step 1: Add focused test mode**

Add `--model-gate-routing-contract-only`. It runs only route-migration and receipt-correction real-Git fixtures through public `scripts/verify-visual-style-baseline-cards` and never changes production behavior.

- [ ] **Step 2: Add exact positive fixtures**

Prove:

```text
L3_VSB02 = deep_reviewer / xhigh / ONE / GO_P0_0_P1_0_P2_0
L4_VSB03 = deep_reviewer / xhigh / ONE / FINAL_GO_P0_0_P1_0_P2_0
CORRECTION_G2_PENDING = exact ten-path chain / origin ledger byte-identical
CORRECTION_G2_TO_R2 = direct single-parent ledger-only child
CORRECTION_R2_ROUTE = deep_reviewer / xhigh / ONE / FINAL_GO_P0_0_P1_0_P2_0
HISTORICAL_GOVERNANCE_REPAIR = deep_reviewer+ultra_gatekeeper / unchanged / PASS
```

Bind the literal Task 1 plan SHA and `1199e76...` design SHA; require ancestry, immutable blobs, and mode `100644`.

- [ ] **Step 3: Add fail-closed fixtures**

Cover missing/duplicate effort or multiplicity; old stacked VSB-03 route; correction claiming unexecuted Ultra; Ultra without an allowed recorded reason; route/reviewer mismatch; spec or plan absent from ancestry; blob/mode drift; path omission/extra; empty/merge/rename/copy; intermediate ledger drift; NUL/newline/mode drift; wrong origin/base/sequence/version; non-tip or merge receipt; ordinary receipt substituted for correction; second correction; and post-R2 correction-field mutation. Each TMPDIR must preserve a sibling marker and contain no verifier-created residue after pass or fail.

- [ ] **Step 4: Commit tests only**

```bash
git add tests/task-cards/verify-visual-style-baseline-cards.sh
git diff --cached --check
test "$(git diff --cached --name-only)" = "tests/task-cards/verify-visual-style-baseline-cards.sh"
git commit -m "test: define Cognitura model gate migration"
```

- [ ] **Step 5: Observe intended RED**

```bash
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh --model-gate-routing-contract-only
```

Expected: non-zero at the first legal single-gate or correction positive because production still requires stacked VSB-03 review and lacks `RECEIPT_CORRECTION`. Syntax, fixture setup, missing command, or unrelated failure is not acceptable RED.

### Task 3: Implement deterministic route and correction validation

**Files:**

- Modify: `AGENTS.md`
- Modify: `docs/task-cards/visual-style-baseline/README.md`
- Modify: `docs/task-cards/visual-style-baseline/VSB-02-module-default-reading-visual.md`
- Modify: `docs/task-cards/visual-style-baseline/VSB-03-fixed-visual-acceptance.md`
- Modify: `scripts/verify-visual-style-baseline-cards`
- Test: `tests/task-cards/verify-visual-style-baseline-cards.sh`

- [ ] **Step 1: Migrate live Authority**

Apply exactly:

```text
L0 = fast_explorer / gpt-5.6-terra / medium / read-only
L1_L2 = main_or_worker / gpt-5.6-sol / high
L3 = deep_reviewer / gpt-5.6-sol / xhigh / ONE_APPLICABLE_GATE
L4_DEFAULT = deep_reviewer / gpt-5.6-sol / xhigh / ONE_APPLICABLE_GATE
AUTOMATIC_DEEP_PLUS_ULTRA_STACKING = FORBIDDEN
ULTRA = replacement L4 gate only with a recorded allowed reason
```

Retain named historical exceptions and completed GovernanceRepair stacked-route history. VSB-02 becomes `L3 deep_reviewer/xhigh/ONE`; VSB-03 becomes `L4 deep_reviewer/xhigh/ONE_BY_DEFAULT`.

- [ ] **Step 2: Migrate card schemas**

VSB-02 fields are `ReviewLevel=L3`, `ReviewRoute=deep_reviewer`, `ReviewEffort=xhigh`, `ReviewMultiplicity=ONE`. VSB-03 fields are `ReviewLevel=L4`, `ReviewRoute=deep_reviewer`, `ReviewEffort=xhigh`, `ReviewMultiplicity=ONE`, `UltraRequiredByDefault=NO`. Ultra may replace the default only after the main Agent records a permitted reason; it never automatically follows xhigh.

- [ ] **Step 3: Separate historical and current schemas**

Keep `governance_repair_fields`, `require_governance_repair_state_values`, and version 1-to-2 replay unchanged. Add current route fields so VSB-02 accepts one L3 xhigh verdict and VSB-03 accepts one L4 xhigh final verdict. Replace current VSB-03 dual verdict requirements with one route/effort/multiplicity/final-verdict schema. Fail on missing, duplicate, stale, or contradictory fields.

- [ ] **Step 4: Bind the approved chain**

Add literal constants for `1199e76...`, the Task 1 plan SHA, `dc4a105...`, `f4bd848...`, `0ff4109...`, and `108592b...`. Walk the origin-exclusive single-parent chain; require non-empty no-ledger commits, no merges/rename/copy, exact modes, each path inside the ten-path set, and cumulative equality to all ten. Use `git -c diff.renameLimit=0 diff-tree -M -C --find-copies-harder` with separate stdout/stderr and fail on Git errors, warnings, rename, or copy. Materialize blobs to invocation-scoped files, reject NUL, compare immutable blobs with `cmp`, and clean only the registered invocation root on EXIT.

- [ ] **Step 5: Implement version 3 replay**

Add `receipt_correction_fields`, `model_gate_routing_fields`, `validate_receipt_correction_chain`, `build_expected_receipt_correction_ledger`, `require_receipt_correction_state_values`, `validate_receipt_correction_transition_files`, and `validate_receipt_correction_pending_head`.

The R2 transform preserves every origin byte except:

```text
ExecutionStateVersion = 3
ReceiptCorrectionStatus = PASS
ReceiptCorrectionSpecSHA = dc4a105bbe95b1b07fa0e734cec1148eab15279c
ReceiptCorrectionOriginReceiptSHA = 0ff410961b0f3865652e54ae46453646ed87f69e
ReceiptCorrectionReviewedCandidateSHA = candidate G2 SHA
ReceiptCorrectionReviewLevel = L4
ReceiptCorrectionReviewRoute = deep_reviewer
ReceiptCorrectionReviewEffort = xhigh
ReceiptCorrectionReviewMultiplicity = ONE
ReceiptCorrectionReviewVerdict = FINAL_GO_P0_0_P1_0_P2_0
NextTaskCard = VSB-03
TransitionSequence = 5
TransitionKind = RECEIPT_CORRECTION
TransitionBaseSHA = candidate G2 SHA
```

Build expected content from the origin blob and compare with `cmp`; require mode `100644`. Dispatch correction before ordinary immutable checks. Static version 3 replay finds exactly one legal G2-to-R2 pair, later transitions preserve correction fields, and only this pair releases VSB-02. The origin, copied trees, ordinary O2, and second correction fail deterministically.

- [ ] **Step 6: Run focused GREEN and one full regression**

```bash
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh --model-gate-routing-contract-only
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh --receipt-correction-contract-only
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh
/bin/bash -n scripts/verify-visual-style-baseline-cards
/bin/bash -n tests/task-cards/verify-visual-style-baseline-cards.sh
scripts/verify-visual-style-baseline-cards --repo-root . --cards-dir docs/task-cards/visual-style-baseline
scripts/verify-wave1-implementation-cards --repo-root . --cards-dir docs/task-cards/wave-1-implementation
git diff --check
```

Expected: both focused contracts and full VSB tests PASS; static VSB is PASS/PENDING; Wave 1 stays `SUSPENDED_BY_USER / NONE`; Bash syntax and diff checks pass. Never run concurrent full suites.

- [ ] **Step 7: Commit candidate G2**

```bash
git add AGENTS.md docs/task-cards/visual-style-baseline/README.md docs/task-cards/visual-style-baseline/VSB-02-module-default-reading-visual.md docs/task-cards/visual-style-baseline/VSB-03-fixed-visual-acceptance.md scripts/verify-visual-style-baseline-cards tests/task-cards/verify-visual-style-baseline-cards.sh
git diff --cached --check
git commit -m "fix: migrate Cognitura model gate routing"
G2_SHA="$(git rev-parse HEAD)"
G2_PARENT_SHA="$(git rev-parse HEAD^)"
G2_TREE_SHA="$(git rev-parse HEAD^{tree})"
```

Expected: exact ten-path cumulative chain, ledger identical to origin, W1-I03 tree unchanged, and only `.idea/` residue.

### Task 4: Review the fixed candidate once at L4 xhigh

**Files:** read-only fixed candidate and ancestors.

- [ ] **Step 1: Freeze identity and dispatch exactly one gate**

Record G2 SHA/parent/tree, origin-to-G2 commits, exact ten paths, ledger identity, design/plan blob identities, RED/GREEN output, Bash 3.2 evidence, Wave 1 state, and residue. Dispatch one `deep_reviewer` at `gpt-5.6-sol / xhigh` against the fixed SHA and require `FINAL_GO_P0_0_P1_0_P2_0`. Do not dispatch Ultra: no approved escalation condition exists. Do not stack L3 before L4.

- [ ] **Step 2: Handle findings**

For any P0/P1/P2, use `superpowers:receiving-code-review`, reproduce with RED, apply the smallest fix, run focused and affected regression, make a non-amend fix commit, and review the new fixed SHA. GO never transfers to a changed tree.

### Task 5: Create and verify legal R2

**Files:**

- Modify only: `docs/task-cards/visual-style-baseline/execution-state.md`

- [ ] **Step 1: Apply exact transform after final GO**

Use `apply_patch` to apply Task 3 Step 5 with reviewed G2 SHA, changing no other origin facts.

- [ ] **Step 2: Commit only the ledger**

```bash
git add docs/task-cards/visual-style-baseline/execution-state.md
git diff --cached --check
test "$(git diff --cached --name-only)" = "docs/task-cards/visual-style-baseline/execution-state.md"
git commit -m "chore: correct VSB module reading release"
R2_SHA="$(git rev-parse HEAD)"
test "$(git rev-parse HEAD^)" = "${G2_SHA}"
```

- [ ] **Step 3: Verify explicit/static replay**

```bash
scripts/verify-visual-style-baseline-cards --repo-root . --cards-dir docs/task-cards/visual-style-baseline --transition-base "${G2_SHA}" --transition-head "${R2_SHA}"
scripts/verify-visual-style-baseline-cards --repo-root . --cards-dir docs/task-cards/visual-style-baseline
scripts/verify-wave1-implementation-cards --repo-root . --cards-dir docs/task-cards/wave-1-implementation
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh --model-gate-routing-contract-only
git diff --check
git status --short
```

Expected: `IN_PROGRESS / Active=VSB-02 / Released=VSB-02 / Next=VSB-03`, correction PASS with single L4 xhigh final GO, Wave 1 `SUSPENDED_BY_USER / NONE`, and only `.idea/` untracked. Only then may VSB-02 resume.
