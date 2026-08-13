# Cognitura VSB Receipt Correction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preserve failed receipt `0ff4109...`, add one fixed and non-reusable
`RECEIPT_CORRECTION`, and restore a valid VSB-02 release anchor without rewriting history.

**Architecture:** A linear five-path governance chain starts at the fixed failed receipt and leaves
the version 2 ledger byte-identical while the verifier and real-Git contract are implemented. After
fixed candidate `G2` passes deep and ultra review, direct ledger-only child `R2` performs the exact
version 2 to version 3 transform and becomes the only VSB-02 release anchor.

**Tech Stack:** Bash 3.2, Git object plumbing, Markdown governance documents, existing Cognitura
task-card validators and shell contract tests.

## Global Constraints

```text
CanonicalProjectName = Cognitura
ApprovedReceiptCorrectionSpecSHA = dc4a105bbe95b1b07fa0e734cec1148eab15279c
CorrectionOriginReceiptSHA = 0ff410961b0f3865652e54ae46453646ed87f69e
ReviewedVSB01CandidateSHA = 108592b757ba50ea6ded7b901bd2b623737a7048
CorrectionKind = RECEIPT_CORRECTION
CorrectionMultiplicity = EXACTLY_ONCE
GovernanceCandidateReviewRoute = deep_reviewer+ultra_gatekeeper
HistoryRewrite = FORBIDDEN
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

- Work only on `codex/high-fidelity-design-integration`; preserve untracked `.idea/`.
- Do not use reset, rebase, amend, replacement refs, force branch updates, merge, revert, or
  cherry-pick to hide the failed receipt.
- Do not change the execution ledger before fixed `G2` passes both reviews.
- Do not change VSB deliverables, VSB-02 business paths, production components, backend, schemas,
  raw inputs, historical evidence, screenshots, package files, or CI.
- The governance cumulative WriteSet is exactly the five paths in the approved specification.
- Every governance commit is single-parent, non-empty, no-ledger, and a non-empty WriteSet subset.
- Git blob and ledger checks are binary-safe; Bash variables never carry whole file/blob contents.
- Test first, observe the intended RED, implement minimal GREEN, and commit non-amend.

---

### Task 1: Implement and review the one-time receipt correction

**Files:**

- Frozen: `docs/superpowers/specs/2026-08-13-cognitura-vsb-receipt-correction-design.md`
- Created by this plan commit: `docs/superpowers/plans/2026-08-13-cognitura-vsb-receipt-correction.md`
- Modify: `docs/task-cards/visual-style-baseline/README.md`
- Modify: `scripts/verify-visual-style-baseline-cards`
- Modify: `tests/task-cards/verify-visual-style-baseline-cards.sh`
- Modify only after both reviews: `docs/task-cards/visual-style-baseline/execution-state.md`

**Interfaces:**

- Consumes: fixed origin `0ff410961b0f3865652e54ae46453646ed87f69e`, approved spec
  `dc4a105bbe95b1b07fa0e734cec1148eab15279c`, cumulative Owner-chain validation, version 2 ledger,
  and public static/transition verifier entrypoints.
- Produces: pending governance state, exact version 3 receipt transform, version 3 ordinary receipt
  replay, and one legal VSB-02 release anchor.

- [ ] **Step 1: Commit this plan and record its exact SHA**

```bash
git add docs/superpowers/plans/2026-08-13-cognitura-vsb-receipt-correction.md
git diff --cached --check
test "$(git diff --cached --name-only)" = \
  "docs/superpowers/plans/2026-08-13-cognitura-vsb-receipt-correction.md"
git commit -m "docs: plan VSB receipt correction"
P2_SHA="$(git rev-parse HEAD)"
test "$(git rev-parse HEAD^)" = \
  "dc4a105bbe95b1b07fa0e734cec1148eab15279c"
```

Production later contains literal `P2_SHA`; it does not discover it from live branch state.

- [ ] **Step 2: Establish fixed preflight evidence**

```bash
test "$(git branch --show-current)" = "codex/high-fidelity-design-integration"
test "$(git rev-parse 0ff410961b0f3865652e54ae46453646ed87f69e^)" = \
  "108592b757ba50ea6ded7b901bd2b623737a7048"
test "$(git diff --name-only \
  108592b757ba50ea6ded7b901bd2b623737a7048..\
  0ff410961b0f3865652e54ae46453646ed87f69e)" = \
  "docs/task-cards/visual-style-baseline/execution-state.md"
test "$(git rev-parse \
  0ff410961b0f3865652e54ae46453646ed87f69e:\
docs/task-cards/visual-style-baseline/execution-state.md)" = \
  "$(git rev-parse HEAD:docs/task-cards/visual-style-baseline/execution-state.md)"
test "$(sed -n 's/^NextTaskCard = //p' \
  docs/task-cards/visual-style-baseline/execution-state.md)" = "VSB-02"
```

Expected: all exit zero; unrelated worktree state is only `?? .idea/`.

- [ ] **Step 3: Write README and real-Git contract tests before production code**

Document in README that `0ff4109...` is failed evidence only, correction is fixed to exact
origin/spec/plan, version 2 upgrades to 3 exactly once, `G2` owns exact five no-ledger paths, `R2`
is the only VSB-02 anchor, and no-return sequences continue at 6 and 7.

Add test-only `--receipt-correction-contract-only`; it skips unrelated historical fixtures but never
changes production. Use real Git objects and public entrypoints for positives: exact pending `G2`,
exact `G2 -> R2`, normal version 3 static state, and single/multi-commit VSB-02 candidates at `R2`.

Implement all specification section 11 negatives: ordinary `O2`, copied tree without spec ancestry,
spec/plan drift, path omission/extra, empty/merge/rename/copy, low `diff.renameLimit`, intermediate
ledger drift, NUL/newline/mode drift, wrong fields/reviews/sequence, second correction, non-tip or
merge `R2`, wrong anchor, and post-`R2` correction-field mutation. Each isolated `TMPDIR` preserves
a sibling marker and contains no verifier-created residue after success or failure.

```bash
git add docs/task-cards/visual-style-baseline/README.md \
  tests/task-cards/verify-visual-style-baseline-cards.sh
git diff --cached --check
git commit -m "test: define VSB receipt correction contract"
```

- [ ] **Step 4: Observe the intended RED**

```bash
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh \
  --receipt-correction-contract-only
```

Expected: non-zero at the first new legal pending/correction positive because production lacks
`RECEIPT_CORRECTION`. Fixture setup, syntax, or unrelated failure is not acceptable RED.

- [ ] **Step 5: Implement deterministic chain validation**

Add literal constants for fixed spec, `P2_SHA`, origin, and reviewed VSB-01 candidate. Implement one
shared validator that walks the single-parent origin-exclusive chain; requires every commit non-empty
and a subset of exact five, cumulative exact five; rejects ledger/merge/extra paths; uses
`git -c diff.renameLimit=0 diff-tree -M -C --find-copies-harder` with separate stdout/stderr and
fails on Git error/warning/rename/copy; preserves mode history; requires fixed spec/plan ancestry and
immutable blobs/modes after their commits; materializes blobs to invocation-scoped files, rejects
NUL, compares with `cmp`, and removes only its registered invocation root on `EXIT`.

Do not modify ordinary cumulative-candidate or governance-repair behavior except for required
version 3 and release-receipt recognition.

- [ ] **Step 6: Implement pending, exact transform, and version 3 replay**

Add focused helpers:

```text
receipt_correction_fields
validate_receipt_correction_chain
build_expected_receipt_correction_ledger
require_receipt_correction_state_values
validate_receipt_correction_transition_files
validate_receipt_correction_pending_head
```

Exact version 2 origin ledger plus exact chain may return PENDING before ordinary state validation;
origin itself and altered/copied trees fail. Correction dispatch precedes ordinary immutable checks.
Expected ledger is built from origin bytes by inserting six fields and changing only version, next,
sequence, kind, and base. Expected/actual files match via `cmp`, are NUL-free and mode `100644`.
Version 3 static validation requires exact fields and replays unique `G2 -> R2`; ordinary version 3
transitions preserve them. Owner release recognition accepts correction only for VSB-02 after full
pair replay. Fixed `O2` ordinary replay fails stably. A second/version 3 correction fails exactly
once. Explicit transition calls never recursively self-replay the same terminal pair.

- [ ] **Step 7: Run focused GREEN, then one full regression**

```bash
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh \
  --receipt-correction-contract-only
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh
```

Expected: focused `ReceiptCorrectionContractTests=PASS`; full
`VisualStyleBaselineTaskCardContractTests=PASS` with correction counts. Never run concurrent full
suites. Diagnose failures using the focused flag before one final replacement full run.

- [ ] **Step 8: Run candidate Gates and commit `G2`**

```bash
/bin/bash -n scripts/verify-visual-style-baseline-cards
/bin/bash -n tests/task-cards/verify-visual-style-baseline-cards.sh
scripts/verify-visual-style-baseline-cards \
  --repo-root . --cards-dir docs/task-cards/visual-style-baseline
scripts/verify-wave1-implementation-cards \
  --repo-root . --cards-dir docs/task-cards/wave-1-implementation
git diff --check
```

Expected at `G2`: VSB PASS/PENDING; Wave 1 SUSPENDED/NONE. Audit `O2..HEAD` for exact five paths,
single-parent non-empty commits, ledger identity, frozen paths, and only `.idea/` residue.

```bash
git add scripts/verify-visual-style-baseline-cards \
  tests/task-cards/verify-visual-style-baseline-cards.sh
git diff --cached --check
git commit -m "fix: add one-time VSB receipt correction"
G2_SHA="$(git rev-parse HEAD)"
G2_PARENT_SHA="$(git rev-parse HEAD^)"
G2_TREE_SHA="$(git rev-parse HEAD^{tree})"
```

- [ ] **Step 9: Require deep and ultra fixed-SHA GO**

Dispatch fresh `deep_reviewer`, then independent `ultra_gatekeeper`, with fixed origin, spec, plan,
`G2`, parent/tree, exact-five paths, ledger identity, RED/GREEN, topology, Bash 3.2, frozen paths,
and origin rejection. Require `GO_P0_0_P1_0_P2_0` then `FINAL_GO_P0_0_P1_0_P2_0`. Findings enter
a TDD non-amend fix loop and yield a new reviewed `G2`; do not create `R2` before both all-zero GO.

- [ ] **Step 10: Create exact ledger-only `R2`**

With `apply_patch`, preserve every VSB-01 review fact and every other origin field while applying:

```text
ExecutionStateVersion = 3
ReceiptCorrectionStatus = PASS
ReceiptCorrectionSpecSHA = dc4a105bbe95b1b07fa0e734cec1148eab15279c
ReceiptCorrectionOriginReceiptSHA = 0ff410961b0f3865652e54ae46453646ed87f69e
ReceiptCorrectionReviewedCandidateSHA = ${G2_SHA}
ReceiptCorrectionReviewRoute = deep_reviewer+ultra_gatekeeper
ReceiptCorrectionReviewVerdict = FINAL_GO_P0_0_P1_0_P2_0
NextTaskCard = VSB-03
TransitionSequence = 5
TransitionKind = RECEIPT_CORRECTION
TransitionBaseSHA = ${G2_SHA}
```

```bash
git add docs/task-cards/visual-style-baseline/execution-state.md
git diff --cached --check
test "$(git diff --cached --name-only)" = \
  "docs/task-cards/visual-style-baseline/execution-state.md"
git commit -m "chore: correct VSB module reading release"
R2_SHA="$(git rev-parse HEAD)"
test "$(git rev-parse HEAD^)" = "${G2_SHA}"
```

- [ ] **Step 11: Verify correction and resume VSB-02**

```bash
scripts/verify-visual-style-baseline-cards \
  --repo-root . --cards-dir docs/task-cards/visual-style-baseline \
  --transition-base "${G2_SHA}" --transition-head "${R2_SHA}"
scripts/verify-visual-style-baseline-cards \
  --repo-root . --cards-dir docs/task-cards/visual-style-baseline
scripts/verify-wave1-implementation-cards \
  --repo-root . --cards-dir docs/task-cards/wave-1-implementation
git diff --check
git status --short
```

Expected: explicit/static VSB PASS, `IN_PROGRESS / VSB-02 / ReceiptCorrectionStatus=PASS`; Wave 1
remains `SUSPENDED_BY_USER / NONE`; `G2..R2` is ledger-only, single-parent, mode `100644`; residue
is only `.idea/`. Only then may VSB-02 implementation resume.
