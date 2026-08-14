# Cognitura VSB Chrome Authority Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** migrate the VSB-03 reproducibility authority from exact Chrome `151.0.7922.109` to exact installed Chrome `151.0.7922.138` without widening the VSB-03 Owner WriteSet.

**Architecture:** A fixed six-path governance candidate G4 carries the approved Authority and fail-closed verifier support while preserving the ledger bytes from `7b7b9bc...`. A ledger-only direct child R4 upgrades execution state version 4 to 5, records the reviewed migration once, and becomes the new VSB-03 release anchor. Later VSB-03 work remains an ordinary exact twelve-path Owner chain.

**Tech Stack:** Markdown Authority, Bash 3.2-compatible public verifier and real-Git fixtures, exact Chrome `151.0.7922.138`, Git fixed commits, `deep_reviewer / xhigh / ONE`.

## Global Constraints

- Origin is exactly `7b7b9bcab8b372c66ebd0533cbfe3dca885d0f3d`.
- Normalize only trailing whitespace from the fixed Chrome binary's `--version` output.
- G4 cumulative WriteSet is the exact six paths in the design; the ledger is byte-identical to origin.
- R4 is a ledger-only direct child of reviewed G4 and the only version `4 -> 5` migration.
- Current VSB-03 route remains `L4 / deep_reviewer / xhigh / ONE`; Ultra is not run.
- Do not touch product code, VSB-03's twelve Owner paths, Wave 1 files, `.idea/`, `dist/`, `temp-input/`, database state, or remotes.
- Use `apply_patch`; do not reset, rebase, amend, merge, push, or deploy.

---

### Task 1: Freeze the migration Authority

**Files:**
- Create: `docs/superpowers/specs/2026-08-14-cognitura-vsb-chrome-authority-migration-design.md`
- Create: `docs/superpowers/plans/2026-08-14-cognitura-vsb-chrome-authority-migration.md`
- Modify: `docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md`

**Interfaces:**
- Consumes: user approval of exact target Chrome `151.0.7922.138` and origin `7b7b9bcab8b372c66ebd0533cbfe3dca885d0f3d`.
- Produces: one fixed Authority commit whose SHA and three immutable `100644` blobs are consumed by the G4 validator.

- [ ] **Step 1: Prove the old Authority fails locally**

```bash
VSB_CHROME_BIN='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
actual="$("${VSB_CHROME_BIN}" --version | sed 's/[[:space:]]*$//')"
test "${actual}" = 'Google Chrome 151.0.7922.109'
```

Expected: FAIL because normalized output is `Google Chrome 151.0.7922.138`.

- [ ] **Step 2: Apply the exact Authority migration**

Replace all six `151.0.7922.109` literals in the old plan with
`151.0.7922.138`.  Capture/version pseudocode must use:

```bash
VSB_CHROME_VERSION="$("${VSB_CHROME_BIN}" --version | sed 's/[[:space:]]*$//')"
test "${VSB_CHROME_VERSION}" = 'Google Chrome 151.0.7922.138'
```

- [ ] **Step 3: Verify the Authority content**

```bash
test "$(rg -o '151\.0\.7922\.138' docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md | wc -l | tr -d ' ')" = 6
! rg -n '151\.0\.7922\.109' docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md
VSB_CHROME_BIN='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
test "$("${VSB_CHROME_BIN}" --version | sed 's/[[:space:]]*$//')" = 'Google Chrome 151.0.7922.138'
git diff --check
```

Expected: PASS.

- [ ] **Step 4: Independently review and commit the three Authority paths**

The review must return `GO_P0_0_P1_0_P2_0` for the exact three-path tree.
Then stage only the three paths and create a new non-amend commit:

```bash
git add -- \
  docs/superpowers/specs/2026-08-14-cognitura-vsb-chrome-authority-migration-design.md \
  docs/superpowers/plans/2026-08-14-cognitura-vsb-chrome-authority-migration.md \
  docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md
git commit -m 'docs(vsb): migrate Chrome authority to 151.0.7922.138'
git rev-parse HEAD
```

Expected: the output SHA becomes the literal `chrome_authority_migration_spec_sha` in Task 3.

### Task 2: Establish tests-only RED

**Files:**
- Modify: `tests/task-cards/verify-visual-style-baseline-cards.sh`

**Interfaces:**
- Consumes: fixed migration Authority SHA from Task 1.
- Produces: public-entry real-Git fixtures for pending G4, explicit R4, static R4, release-anchor replay, and version-5 preservation.

- [ ] **Step 1: Add a focused public entry**

Add `--chrome-authority-migration-contract-only`.  It must run only the
migration fixtures and print exact positive/negative counts before PASS.

- [ ] **Step 2: Add the first legal positive**

Clone the repository into the invocation-owned temporary root, detach the
fixed origin, replay the fixed three Authority blobs, add README/verifier/test
changes as later governance commits, and prove:

```text
single parent per commit
non-empty subset per commit
exact six-path cumulative WriteSet
origin/HEAD/working ledger blobs identical
all modes canonical
no rename/copy, NUL, merge, ledger, or outside-path change
```

Call the public verifier with no transition flags and require
`ChromeAuthorityMigrationStatus = PENDING`.

- [ ] **Step 3: Run the focused test to record RED**

```bash
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh --chrome-authority-migration-contract-only
```

Expected: FAIL because production does not recognize the migration pending
state or version 5.

- [ ] **Step 4: Complete the closed matrix**

Use the public verifier for legal G4 pending, exact R4 explicit, R4 static,
VSB-03 release-anchor use, and later ordinary version-5 preservation.  Add
negatives for missing/duplicate/wrong/reordered/unknown migration fields,
second migration, non-direct/merge/extra-path receipt, old/target version
mismatch, bad route/effort/multiplicity/verdict, origin or Authority
ancestry/blob/mode drift, governance empty/merge/outside/ledger/reverted
intermediate drift/rename/copy/NUL/incomplete WriteSet, non-exact Chrome
literal, leading-whitespace normalization, and post-R4 block mutation.
Every case must assert its stable diagnostic plus sibling TMPDIR and Git
worktree cleanup.

### Task 3: Implement the version-5 migration GREEN

**Files:**
- Modify: `docs/task-cards/visual-style-baseline/README.md`
- Modify: `scripts/verify-visual-style-baseline-cards`
- Test: `tests/task-cards/verify-visual-style-baseline-cards.sh`

**Interfaces:**
- Consumes: the fixed Authority commit and tests from Tasks 1-2.
- Produces: `validate_chrome_authority_migration_chain`, pending admission, exact R4 construction/replay, version-5 ordinary preservation, and a legal VSB-03 release anchor.

- [ ] **Step 1: Bind README to the fixed Authority**

Add one exact current migration section naming the design, plan, fixed SHA,
origin, previous/target versions, exact six-path governance boundary, R4
release semantics, and `L3 / deep_reviewer / xhigh / ONE`.  Reject duplicate,
missing, stale, or contradictory Chrome migration prose.

- [ ] **Step 2: Implement the exact G4 chain validator**

Add constants for origin and fixed Authority SHA, an exact six-path list with
canonical modes, first-parent commit traversal, per-commit non-empty subset
validation, unlimited rename/copy inspection, NUL checks, ledger identity,
immutable three-Authority-blob checks, and final exact cumulative WriteSet.

- [ ] **Step 3: Implement pending admission and the R4 builder**

Before ordinary VSB-03 candidate replay, admit only a HEAD whose ledger is
byte-identical to origin and whose G4 chain is exact.  Build expected R4 by
inserting the eleven-field canonical block, changing only version `4 -> 5`,
sequence `9 -> 10`, kind to `CHROME_AUTHORITY_MIGRATION`, and base to G4.

- [ ] **Step 4: Implement explicit/static/history validation**

Require R4 to be G4's ledger-only direct child with mode `100644`, NUL-free
exact expected bytes, and working ledger equal to HEAD.  Static replay must
locate R4, revalidate G4 and the exact transform, require one migration in
first-parent history, and compare the canonical block at every later commit.

- [ ] **Step 5: Extend ordinary version-5 and VSB-03 routing**

Require all version-5 ordinary transitions to preserve the block bytes and
all prior governance blocks.  Admit `CHROME_AUTHORITY_MIGRATION` as a VSB-03
release receipt only after full replay.  Extend the current VSB-03 single-deep
COMPLETE/FINAL_NO_GO predicates from versions `3|4` to `3|4|5`; do not change
the frozen historical stacked receipt semantics.

- [ ] **Step 6: Run focused GREEN**

```bash
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh --chrome-authority-migration-contract-only
/bin/bash -n scripts/verify-visual-style-baseline-cards
/bin/bash -n tests/task-cards/verify-visual-style-baseline-cards.sh
git diff --check
```

Expected: all migration positives and negatives PASS, syntax PASS, diff PASS.

### Task 4: Fix, commit, and review G4

**Files:**
- Modify: the exact six governance paths only.

**Interfaces:**
- Consumes: stable GREEN tree.
- Produces: a fixed reviewed G4 candidate with origin-identical ledger.

- [ ] **Step 1: Run the pre-commit focused gates**

```bash
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh --chrome-authority-migration-contract-only
/bin/bash -n scripts/verify-visual-style-baseline-cards
/bin/bash -n tests/task-cards/verify-visual-style-baseline-cards.sh
git diff --check
```

Expected: migration focused, both syntax checks, and diff check PASS.  The real
repository static PENDING gate is intentionally not run yet: before G4 exists,
HEAD contains only the three fixed Authority paths rather than the exact
six-path cumulative governance chain.

- [ ] **Step 2: Commit G4 before repository-static validation**

Stage only the three remaining governance paths and create a new non-amend
commit:

```bash
git add -- \
  docs/task-cards/visual-style-baseline/README.md \
  scripts/verify-visual-style-baseline-cards \
  tests/task-cards/verify-visual-style-baseline-cards.sh
git commit -m 'feat(vsb): govern Chrome authority migration'
G4_SHA="$(git rev-parse HEAD)"
```

Expected: origin-to-`${G4_SHA}` cumulative changes are now the exact six-path
governance WriteSet and its ledger blob still equals the origin blob.

- [ ] **Step 3: Run the fixed-tree complete gates serially**

```bash
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh --chrome-authority-migration-contract-only
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh
/bin/bash -n scripts/verify-visual-style-baseline-cards
/bin/bash -n tests/task-cards/verify-visual-style-baseline-cards.sh
scripts/verify-visual-style-baseline-cards --repo-root . --cards-dir docs/task-cards/visual-style-baseline
scripts/verify-wave1-implementation-cards --repo-root . --cards-dir docs/task-cards/wave-1-implementation
git diff --check
```

Expected: migration focused, full VSB, both syntax checks, static VSB PENDING,
Wave 1 SUSPENDED/Active NONE, and diff check all PASS on the fixed G4 tree.

- [ ] **Step 4: Prove the fixed identity**

Record G4 SHA, parent, tree, origin-exclusive first-parent commits, exact six
paths and modes, ledger blob identity, three Authority blobs, W1-I03 frozen
blobs, RED/GREEN outputs, Bash version, and residue state.

- [ ] **Step 5: Execute one independent gate**

Run one fixed-candidate `L3 / deep_reviewer / xhigh / ONE` review on the
already committed unchanged G4.  Require
`GO_P0_0_P1_0_P2_0`.  Ultra remains `NOT_RUN`.

### Task 5: Create and validate R4

**Files:**
- Modify: `docs/task-cards/visual-style-baseline/execution-state.md`

**Interfaces:**
- Consumes: fixed reviewed G4 SHA and fixed Authority SHA.
- Produces: the ledger-only version-5 R4 release anchor for VSB-03.

- [ ] **Step 1: Generate the exact ledger mechanically**

Use `apply_patch` to reproduce the specified transform: insert the canonical
eleven-field block, set version 5, sequence 10, migration kind, and G4 base.
Change no other line.

- [ ] **Step 2: Verify bytes and topology before commit**

Generate the expected ledger from the fixed origin with the production builder
logic and require `cmp -s`, mode `100644`, NUL absence, final newline, and a
single working-tree diff path equal to `execution-state.md`.

- [ ] **Step 3: Commit the ledger-only receipt**

```bash
git add docs/task-cards/visual-style-baseline/execution-state.md
git commit -m 'chore(vsb): record Chrome authority migration receipt'
```

- [ ] **Step 4: Validate explicit, static, and frozen Wave 1 state**

```bash
scripts/verify-visual-style-baseline-cards \
  --repo-root . \
  --cards-dir docs/task-cards/visual-style-baseline \
  --transition-base <G4_SHA> \
  --transition-head HEAD
scripts/verify-visual-style-baseline-cards \
  --repo-root . \
  --cards-dir docs/task-cards/visual-style-baseline
scripts/verify-wave1-implementation-cards \
  --repo-root . \
  --cards-dir docs/task-cards/wave-1-implementation
git diff --check
```

Expected: Chrome migration PASS, static VSB IN_PROGRESS with VSB-03 active,
Wave 1 SUSPENDED/Active NONE, and diff PASS.

### Task 6: Resume VSB-03 from R4

**Files:**
- Modify/Create: only the twelve paths in `VSB-03-fixed-visual-acceptance.md`.

**Interfaces:**
- Consumes: validated R4 and exact Chrome `151.0.7922.138`.
- Produces: a new VSB-03 candidate independent of the superseded pre-migration chain.

- [ ] **Step 1: Re-run the VSB-03 prerequisites**

Require exact Node `24.18.0`, pnpm `11.17.0`, Chrome normalized exact
`151.0.7922.138`, Pillow `12.2.0`, reference verifier PASS, and unchanged
historical evidence/W1-I03 blobs.

- [ ] **Step 2: Execute only the Owner implementation portion of the old plan**

Run only Steps 1 through 12 of Task 5 in
`2026-08-12-cognitura-visual-style-baseline.md` from R4: prerequisites,
tests-only RED, capture/verifier implementation, four fresh images, manual
inspection, evidence/report, GREEN, and the fixed VSB-03 candidate commit.  Its
candidate chain must be single-parent, non-empty per commit, and cumulatively
equal the twelve-path Owner WriteSet.

Do not execute that old plan's Steps 13 through 16.  Their stacked Ultra route,
pre-migration sequence values, terminal receipt body, and direct W1 restore are
historical instructions superseded by the current model-route Authority,
version-5 execution-state verifier, current VSB-03 card, and current Wave 1
suspension boundary.

- [ ] **Step 3: Complete the fixed visual gate**

Run the real-browser verifier, manually inspect all four generated PNGs, fix
all P0/P1/P2 findings, commit the fixed candidate, and execute one
`L4 / deep_reviewer / xhigh / ONE` final gate.  Do not run Ultra without a new
explicit escalation reason.  Build and validate the final version-5 ledger-only
receipt through the current public verifier; restore Wave 1 only if a later
current Authority and separate authorized receipt require it.
