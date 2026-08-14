# Cognitura VSB Chrome Authority Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** migrate the VSB-03 reproducibility authority from exact Chrome `151.0.7922.109` to exact installed Chrome `151.0.7922.138` without widening the VSB-03 Owner WriteSet.

**Architecture:** Rejected Authority `ce2a3ca...` and rejected G4 `4a62647f...` remain immutable `NO_GO / P1=1` predecessor evidence. The first commit after `4a62647f...` containing the corrected three Authority files becomes the fixed successor Authority; later verifier/test work produces a successor G4 while the origin, exact six-path cumulative WriteSet, and ledger bytes remain unchanged. Stage A validates a verifier-owned canonical temporary Bash fixture while the actual capture path stays absent through G4/R4; Stage B starts only with the exact twelve-path VSB-03 candidate and applies the same public checker to its candidate-bound capture source before any browser launch.

**Tech Stack:** Markdown Authority, Bash 3.2-compatible public verifier and real-Git fixtures, exact Chrome `151.0.7922.138`, Git fixed commits, `deep_reviewer / xhigh / ONE`.

## Global Constraints

- Origin is exactly `7b7b9bcab8b372c66ebd0533cbfe3dca885d0f3d`.
- Rejected predecessor Authority is exactly `ce2a3ca466cc4df2ff077017f1ddb03cb285416f`; rejected predecessor candidate is exactly `4a62647fdb8226cc5c0527c48f552ef553ff146e`; both remain immutable `NO_GO` evidence and neither may anchor R4.
- The first correction commit after the rejected candidate is the successor fixed Authority; its three `100644` Authority blobs remain immutable through the successor G4.
- Normalize only trailing whitespace from the fixed Chrome binary's `--version` output.
- Capture invokes only `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`; no browser-path override, non-empty `CHROME_BIN`, PATH lookup, or fallback is accepted. An internal variable may carry this literal only when declared readonly and never assigned from environment, CLI, PATH, or discovery output.
- G4 cumulative WriteSet is the exact six paths in the design; the ledger is byte-identical to origin.
- `scripts/capture-visual-style-baseline` is absent at origin and must remain absent through successor G4 and R4; it may be created only by the later VSB-03 exact twelve-path Owner candidate.
- R4 is a ledger-only direct child of the reviewed successor G4 and the only version `4 -> 5` migration.
- Current VSB-03 route remains `L4 / deep_reviewer / xhigh / ONE`; Ultra is not run.
- Do not touch product code, VSB-03's twelve Owner paths, Wave 1 files, `.idea/`, `dist/`, `temp-input/`, database state, or remotes.
- Use `apply_patch`; do not reset, rebase, amend, merge, push, or deploy.

---

### Task 1: Freeze the successor migration Authority

**Files:**
- Modify: `docs/superpowers/specs/2026-08-14-cognitura-vsb-chrome-authority-migration-design.md`
- Modify: `docs/superpowers/plans/2026-08-14-cognitura-vsb-chrome-authority-migration.md`
- Modify: `docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md`

**Interfaces:**
- Consumes: user approval of exact target Chrome `151.0.7922.138`, origin `7b7b9bcab8b372c66ebd0533cbfe3dca885d0f3d`, and append-only recovery from the rejected predecessor Authority/candidate.
- Produces: one fixed successor Authority commit whose SHA and three immutable `100644` blobs are consumed by the successor G4 validator.

- [ ] **Step 1: Fix the rejected predecessor evidence and installed binary**

```bash
test "$(git rev-parse HEAD)" = '4a62647fdb8226cc5c0527c48f552ef553ff146e'
git cat-file -e 'ce2a3ca466cc4df2ff077017f1ddb03cb285416f^{commit}'
actual="$(/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version | sed 's/[[:space:]]*$//')"
test "${actual}" = 'Google Chrome 151.0.7922.138'
```

Expected: PASS. Record `ce2a3ca...` and `4a62647f...` as immutable
`NO_GO / P1=1` predecessor evidence; do not amend or relabel either commit.

- [ ] **Step 2: Apply the exact successor Authority correction**

Keep all six existing `151.0.7922.138` contract literals in the old plan and
keep `151.0.7922.109` absent. Replace browser selection with a readonly
internal constant set directly to the fixed literal executable:

```bash
readonly VSB_FIXED_CHROME='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
VSB_CHROME_VERSION="$("${VSB_FIXED_CHROME}" --version | sed 's/[[:space:]]*$//')"
test "${VSB_CHROME_VERSION}" = 'Google Chrome 151.0.7922.138'
```

The capture CLI is closed to only `--repo-root PATH`, `--output-dir PATH`,
and `--replace-existing`. It must reject a non-empty `CHROME_BIN` and every
unknown override flag, including `--chrome-bin`, without PATH lookup or
browser fallback. The formal positive capture always uses the fixed literal
installed binary.

- [ ] **Step 3: Verify the Authority content**

```bash
test "$(rg -o '151\.0\.7922\.138' docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md | wc -l | tr -d ' ')" = 6
! rg -n '151\.0\.7922\.109' docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md
test "$(/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version | sed 's/[[:space:]]*$//')" = 'Google Chrome 151.0.7922.138'
! rg -n -- '--chrome-bin PATH|optional; use CHROME_BIN|selected browser|macOS Chrome|chromium fallback' \\
  docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md
git diff --check
```

Expected: PASS.

- [ ] **Step 4: Commit the three-path successor Authority**

After Authority approval, stage only the three existing paths and create a new
non-amend direct child of rejected candidate `4a62647f...`:

```bash
git add -- \
  docs/superpowers/specs/2026-08-14-cognitura-vsb-chrome-authority-migration-design.md \
  docs/superpowers/plans/2026-08-14-cognitura-vsb-chrome-authority-migration.md \
  docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md
git commit -m 'docs(vsb): rebaseline fixed Chrome authority'
git rev-parse HEAD
```

Expected: the output SHA is the commit that first contains this correction and
becomes the successor `chrome_authority_migration_spec_sha` in Task 3. This
is not a second independent review: the single applicable L3 gate remains the
fixed successor G4 review in Task 4.

### Task 2: Establish tests-only RED

**Files:**
- Modify: `tests/task-cards/verify-visual-style-baseline-cards.sh`

**Interfaces:**
- Consumes: fixed successor Authority SHA and immutable rejected predecessor SHAs from Task 1.
- Produces: public-entry real-Git fixtures for successor G4 pending, explicit R4, static R4, release-anchor replay, version-5 preservation, and the closed capture source contract.

- [ ] **Step 1: Add a focused public entry**

Add `--chrome-authority-migration-contract-only`.  It must run only the
migration fixtures and print exact positive/negative counts before PASS.

- [ ] **Step 2: Add the first legal positive**

Clone the repository into the invocation-owned temporary root, detach the
fixed origin, replay the immutable predecessor chain through rejected
`ce2a3ca...` and `4a62647f...`, then replay the fixed successor Authority
blobs. Add README/verifier/test changes as later governance commits and prove:

```text
single parent per commit
non-empty subset per commit
exact six-path cumulative WriteSet
origin/HEAD/working ledger blobs identical
all modes canonical
no rename/copy, NUL, merge, ledger, or outside-path change
rejected predecessor SHAs remain in ancestry but are never current Authority/G4/R4
successor Authority is the first correction commit after rejected candidate
successor Authority blobs stay immutable through successor G4
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
VSB-03 release-anchor use, and later ordinary version-5 preservation. Build one
canonical legal Bash source fixture under the test invocation's `mktemp -d`
root and pass it to
`--chrome-capture-source-contract FILE`. Add mutations of that same fixture
for each override, environment selection, PATH lookup/discovery, fallback, and
fake alternate path bypass; pass every mutation through the same public mode
and assert the fake executable invocation log remains empty. Add
negatives for missing/duplicate/wrong/reordered/unknown migration fields,
second migration, non-direct/merge/extra-path receipt, old/target version
mismatch, bad route/effort/multiplicity/verdict, origin or Authority
ancestry/blob/mode drift, governance empty/merge/outside/ledger/reverted
intermediate drift/rename/copy/NUL/incomplete WriteSet, non-exact Chrome
literal, leading-whitespace normalization, and post-R4 block mutation. Also
require the actual `scripts/capture-visual-style-baseline` path to be absent
at origin, at every governance commit, at successor G4, and at R4. A present
actual path before the VSB-03 exact twelve-path candidate is an outside-WriteSet
failure, not a fixture substitute.
Every case must assert its stable diagnostic plus sibling TMPDIR and Git
worktree cleanup.

### Task 3: Implement the version-5 migration GREEN

**Files:**
- Modify: `docs/task-cards/visual-style-baseline/README.md`
- Modify: `scripts/verify-visual-style-baseline-cards`
- Test: `tests/task-cards/verify-visual-style-baseline-cards.sh`

**Interfaces:**
- Consumes: the fixed successor Authority commit, rejected predecessor identities, and tests from Tasks 1-2.
- Produces: `validate_chrome_authority_migration_chain`, `validate_chrome_capture_source_contract FILE`, public `--chrome-capture-source-contract FILE`, Stage A pending admission, exact R4 construction/replay, version-5 ordinary preservation, and the Stage B candidate hook.

- [ ] **Step 1: Bind README to the fixed Authority**

Replace the current migration binding with one exact successor section naming
the design, plan, successor fixed SHA, rejected Authority/candidate and their
`NO_GO` disposition, origin, previous/target versions, exact six-path
governance boundary, R4 release semantics, and
`L3 / deep_reviewer / xhigh / ONE`. Reject duplicate, missing, stale, or
contradictory Chrome migration prose and reject either predecessor SHA as the
current Authority or R4 base.

- [ ] **Step 2: Implement the exact G4 chain validator**

Add constants for origin, both rejected SHAs, and the fixed successor Authority
SHA; retain the exact six-path list with canonical modes. First-parent
traversal must retain and classify the predecessor as `NO_GO`, require the
successor Authority to be the first correction commit after `4a62647f...`,
and reject a predecessor as current. Keep per-commit non-empty subset
validation, unlimited rename/copy inspection, NUL checks, ledger identity,
immutable successor three-Authority-blob checks, and final exact cumulative
WriteSet.

- [ ] **Step 3: Implement Stage A without the actual capture script**

Add public mode `--chrome-capture-source-contract FILE`. It accepts exactly
one explicit regular Bash source file, cannot be combined with repository,
cards, or transition flags, and invokes only
`validate_chrome_capture_source_contract FILE`. The helper is read-only: it
does not start Chrome, build Web assets, mutate Git, or require
`scripts/capture-visual-style-baseline` to exist. It checks the fixture's
readonly fixed literal path, exact `--repo-root`/`--output-dir`/
`--replace-existing` CLI, non-empty `CHROME_BIN` and unknown-option
rejection, trailing-whitespace-only normalization, and absence of PATH lookup,
discovery, fallback, or alternate executable selection.

Run the canonical fixture and every mutation from Task 2 through this public
mode. Independently fail unless `scripts/capture-visual-style-baseline` is
absent at origin, every governance commit, successor G4, the working tree, and
later R4. Neither the six-path G4 implementation nor the ledger-only R4 may
create or synthesize the actual script.

- [ ] **Step 4: Implement pending admission and the R4 builder**

Before ordinary VSB-03 candidate replay, admit only a HEAD whose ledger is
byte-identical to origin and whose G4 chain is exact.  Build expected R4 by
inserting the eleven-field canonical block, changing only version `4 -> 5`,
sequence `9 -> 10`, kind to `CHROME_AUTHORITY_MIGRATION`, and base to G4.
Pending admission validates Stage A fixture evidence and actual-path absence;
it does not require an actual capture implementation.

- [ ] **Step 5: Implement explicit/static/history validation**

Require R4 to be G4's ledger-only direct child with mode `100644`, NUL-free
exact expected bytes, and working ledger equal to HEAD.  Static replay must
locate R4, revalidate G4 and the exact transform, require one migration in
first-parent history, compare the canonical block at every later commit, and
prove the actual capture path remains absent at R4.

- [ ] **Step 6: Extend ordinary version-5 and VSB-03 routing**

Require all version-5 ordinary transitions to preserve the block bytes and
all prior governance blocks.  Admit `CHROME_AUTHORITY_MIGRATION` as a VSB-03
release receipt only after full replay.  Extend the current VSB-03 single-deep
COMPLETE/FINAL_NO_GO predicates from versions `3|4` to `3|4|5`; do not change
the frozen historical stacked receipt semantics. Once any candidate or working
tree under validation contains `scripts/capture-visual-style-baseline`, never
take the Stage A absence path: materialize the candidate-bound file into a
verifier-owned temporary file, run the same source-contract helper, and reject
the candidate or release on any failure.

- [ ] **Step 7: Run focused GREEN**

```bash
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh --chrome-authority-migration-contract-only
/bin/bash -n scripts/verify-visual-style-baseline-cards
/bin/bash -n tests/task-cards/verify-visual-style-baseline-cards.sh
git diff --check
```

Expected: all migration positives and negatives PASS, syntax PASS, diff PASS.

### Task 4: Fix, commit, and review the successor G4

**Files:**
- Modify: the exact six governance paths only.

**Interfaces:**
- Consumes: stable GREEN tree.
- Produces: a fixed reviewed successor G4 candidate with origin-identical ledger and immutable successor Authority blobs.

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

Expected: origin-to-`${G4_SHA}` cumulative changes are still the exact
six-path governance WriteSet, its ledger blob still equals the unchanged origin
blob, the rejected predecessor remains immutable `NO_GO` evidence, and the
successor Authority blobs remain identical to their first correction commit.

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
Wave 1 SUSPENDED/Active NONE, actual capture path absent at origin/every
governance commit/G4/working tree, Stage A canonical fixture PASS with all
mutations rejected, and diff check all PASS on the fixed G4 tree.

- [ ] **Step 4: Prove the fixed identity**

Record successor G4 SHA, parent, tree, origin-exclusive first-parent commits,
the rejected Authority/candidate verdict, successor Authority SHA, exact six
paths and modes, ledger blob identity, successor three-Authority blobs, W1-I03
frozen blobs, actual capture-path absence at every Stage A tree, canonical
fixture/mutation outputs, RED/GREEN outputs, Bash version, and residue state.

- [ ] **Step 5: Execute one independent gate**

Run one fixed-candidate `L3 / deep_reviewer / xhigh / ONE` review on the
already committed unchanged successor G4. Require
`GO_P0_0_P1_0_P2_0`.  Ultra remains `NOT_RUN`.

### Task 5: Create and validate R4

**Files:**
- Modify: `docs/task-cards/visual-style-baseline/execution-state.md`

**Interfaces:**
- Consumes: fixed zero-finding reviewed successor G4 SHA and fixed successor Authority SHA.
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
Wave 1 SUSPENDED/Active NONE, actual capture path still absent at R4, and diff
PASS. R4 does not create, materialize, or conditionally require the actual
capture script.

### Task 6: Resume VSB-03 from R4

**Files:**
- Modify/Create: only the twelve paths in `VSB-03-fixed-visual-acceptance.md`.

**Interfaces:**
- Consumes: validated R4 and exact Chrome `151.0.7922.138`.
- Produces: a new exact twelve-path VSB-03 candidate whose candidate-bound capture source passes the same public checker before candidate admission, release, or browser launch.

- [ ] **Step 1: Re-run the VSB-03 prerequisites**

Require exact Node `24.18.0`, pnpm `11.17.0`, the fixed literal Chrome
executable with normalized exact `151.0.7922.138`, Pillow `12.2.0`,
reference verifier PASS, and unchanged historical evidence/W1-I03 blobs.
Reject a non-empty browser environment override and any browser-path flag
before capture.

- [ ] **Step 2: Execute only the Owner implementation portion of the old plan**

Run only Steps 1 through 12 of Task 5 in
`2026-08-12-cognitura-visual-style-baseline.md` from R4: prerequisites,
tests-only RED, capture/verifier implementation, four fresh images, manual
inspection, evidence/report, GREEN, and the fixed VSB-03 candidate commit.  Its
candidate chain must be single-parent, non-empty per commit, and cumulatively
equal the twelve-path Owner WriteSet. The formal capture uses only the fixed
installed Chrome literal; fake paths exist only inside rejection fixtures and
must never execute.

As soon as `scripts/capture-visual-style-baseline` exists in a working tree
or candidate, the Stage A absence branch is illegal. Before task-card candidate
admission or release, materialize that exact candidate blob with `git show`
into a verifier-owned temporary file and pass it to:

```bash
scripts/verify-visual-style-baseline-cards \
  --chrome-capture-source-contract "${VSB_CANDIDATE_CAPTURE_TMP}"
```

The capture runner must pass its own source file to the same public mode before
its first test, build, server, or browser process. The visual verifier must
materialize and validate the candidate-bound capture source through that mode
before invoking it. Missing checker execution, a conditional skip after the
path exists, or validation of a working-tree copy instead of the candidate blob
is a candidate/release failure.

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
