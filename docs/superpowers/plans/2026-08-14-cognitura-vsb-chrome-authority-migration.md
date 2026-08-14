# Cognitura VSB Chrome Authority Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** migrate the VSB-03 reproducibility authority from exact Chrome `151.0.7922.109` to exact installed Chrome `151.0.7922.138` without widening the VSB-03 Owner WriteSet.

**Architecture:** The rejected pairs `ce2a3ca... / 4a62647f...` and `a2d22c2... / b0b77e8...` remain immutable `NO_GO / P1=1` evidence. The first commit after `b0b77e8...` containing the corrected three Authority files becomes the fixed successor Authority; later verifier/test work produces a successor G4 while the origin, exact six-path cumulative WriteSet, and ledger bytes remain unchanged. Stage A validates one canonical exact-byte capture wrapper while the actual capture path stays absent through G4/R4. Stage B materializes that wrapper beside the reviewed-G4 task-card verifier and executes the exact materialized pair; only the verifier-owned `--chrome-fixed-capture` mode may start Chrome.

**Tech Stack:** Markdown Authority, Bash 3.2-compatible public verifier and real-Git fixtures, exact Chrome `151.0.7922.138`, Git fixed commits, `deep_reviewer / xhigh / ONE`.

## Global Constraints

- Origin is exactly `7b7b9bcab8b372c66ebd0533cbfe3dca885d0f3d`.
- The two rejected Authority/candidate pairs are exactly `ce2a3ca466cc4df2ff077017f1ddb03cb285416f / 4a62647fdb8226cc5c0527c48f552ef553ff146e` and `a2d22c2e8218413d26f7d8940a9ea5564e59b7f0 / b0b77e878fd468f38d40ddd702c96ea8e7446658`; all four commits remain immutable `NO_GO` evidence and none may anchor R4.
- The first correction commit after `b0b77e878fd468f38d40ddd702c96ea8e7446658` is the successor fixed Authority; its three `100644` Authority blobs remain immutable through the successor G4.
- Normalize only trailing whitespace from the fixed Chrome binary's `--version` output.
- Only the reviewed-G4 `scripts/verify-visual-style-baseline-cards --chrome-fixed-capture` mode invokes `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`; no browser-path override, non-empty `CHROME_BIN`, PATH lookup, or fallback is accepted. Candidate-owned Bash contains no browser executable or launch logic.
- `scripts/capture-visual-style-baseline` is one exact `100755` wrapper that resolves its sibling `verify-visual-style-baseline-cards` and `exec`s `--chrome-fixed-capture "$@"`; no additional byte is allowed.
- G4 cumulative WriteSet is the exact six paths in the design; the ledger is byte-identical to origin.
- `scripts/capture-visual-style-baseline` is absent at origin and must remain absent through successor G4 and R4; it may be created only by the later VSB-03 exact twelve-path Owner candidate.
- R4 is a ledger-only direct child of the reviewed successor G4 and the only version `4 -> 5` migration.
- Current VSB-03 route remains `L4 / deep_reviewer / xhigh / ONE`; Ultra is not run.
- Do not touch product code, VSB-03's twelve Owner paths, Wave 1 files, `.idea/`, `dist/`, `temp-input/`, database state, or remotes.
- Use `apply_patch`; do not reset, rebase, amend, merge, push, or deploy.

---

### Task 1: Freeze the governed-launcher successor Authority

**Files:**
- Modify: `docs/superpowers/specs/2026-08-14-cognitura-vsb-chrome-authority-migration-design.md`
- Modify: `docs/superpowers/plans/2026-08-14-cognitura-vsb-chrome-authority-migration.md`
- Modify: `docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md`

**Interfaces:**
- Consumes: user approval of architecture A, exact target Chrome `151.0.7922.138`, origin `7b7b9bcab8b372c66ebd0533cbfe3dca885d0f3d`, and append-only recovery from both rejected Authority/candidate pairs.
- Produces: one fixed successor Authority commit whose SHA and three immutable `100644` blobs are consumed by the successor G4 validator.

- [ ] **Step 1: Fix the rejected predecessor evidence and installed binary**

```bash
test "$(git rev-parse HEAD)" = 'b0b77e878fd468f38d40ddd702c96ea8e7446658'
git cat-file -e 'ce2a3ca466cc4df2ff077017f1ddb03cb285416f^{commit}'
git cat-file -e '4a62647fdb8226cc5c0527c48f552ef553ff146e^{commit}'
git cat-file -e 'a2d22c2e8218413d26f7d8940a9ea5564e59b7f0^{commit}'
test -x '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
test "$(plutil -extract CFBundleShortVersionString raw -o - \
  '/Applications/Google Chrome.app/Contents/Info.plist')" = '151.0.7922.138'
```

Expected: PASS. Record both rejected pairs as immutable `NO_GO / P1=1`
predecessor evidence; do not amend or relabel any rejected commit.

- [ ] **Step 2: Apply the exact successor Authority correction**

Keep all six existing `151.0.7922.138` contract literals in the old plan and
keep `151.0.7922.109` absent. Move the complete capture implementation and the
sole Chrome launch into the frozen task-card verifier. The later candidate
capture path is exactly:

```bash
#!/bin/bash
set -euo pipefail

script_dir="${0%/*}"
[[ "${script_dir}" != "${0}" ]] || script_dir='.'
script_dir="$(cd -- "${script_dir}" && pwd -P)"
exec "${script_dir}/verify-visual-style-baseline-cards" --chrome-fixed-capture "$@"
```

The wrapper contains no fixed path, executable variable, parser, function,
fallback, browser call, external path helper, or source self-check. The sibling frozen verifier owns
the only capture parser and accepts only `--repo-root PATH`, `--output-dir
PATH`, and `--replace-existing`; it rejects non-empty `CHROME_BIN` and every
unknown override flag before any effect, then calls the fixed literal browser.

- [ ] **Step 3: Verify the Authority content**

```bash
test "$(rg -o '151\.0\.7922\.138' docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md | wc -l | tr -d ' ')" = 6
! rg -n '151\.0\.7922\.109' docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md
test "$(plutil -extract CFBundleShortVersionString raw -o - \
  '/Applications/Google Chrome.app/Contents/Info.plist')" = '151.0.7922.138'
! rg -n -- '--chrome-bin PATH|optional; use CHROME_BIN|selected browser|macOS Chrome|chromium fallback' \\
  docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md
git diff --check
```

Expected: PASS.

- [ ] **Step 4: Commit the three-path successor Authority**

After Authority approval, stage only the three existing paths and create a new
non-amend direct child of rejected candidate `b0b77e8...`:

```bash
git add -- \
  docs/superpowers/specs/2026-08-14-cognitura-vsb-chrome-authority-migration-design.md \
  docs/superpowers/plans/2026-08-14-cognitura-vsb-chrome-authority-migration.md \
  docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md
git commit -m 'docs(vsb): govern the fixed Chrome launcher'
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
fixed origin, replay the immutable predecessor chain through both rejected
pairs, then replay the fixed successor Authority blobs. Add
README/verifier/test changes as later governance commits and prove:

```text
single parent per commit
non-empty subset per commit
exact six-path cumulative WriteSet
origin/HEAD/working ledger blobs identical
all modes canonical
no rename/copy, NUL, merge, ledger, or outside-path change
all rejected SHAs remain in ancestry but are never current Authority/G4/R4
successor Authority is the first correction commit after b0b77e8...
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
canonical exact wrapper under the test invocation's `mktemp -d` root, set mode
`100755`, and pass it to `--chrome-capture-source-contract FILE`. Add isolated
byte/mode mutations for comments, dead functions, heredocs, `$VAR`, `${VAR}`,
indirect expansion, arrays, aliases, `eval`, alternate/fallback executables,
missing/reordered/suffixed lines, NUL, newline, and mode drift. Every mutation
must fail and the fake executable invocation log must remain empty. Exercise
the owned capture mode with non-empty `CHROME_BIN`, poisoned PATH, unknown
options, and `--chrome-bin`; each must fail before any browser/server/build
sentinel. Add one positive verifier-owned temporary capture fixture that uses
the fixed binary, writes only under the invocation root, cleans completely,
and is explicitly not formal VSB evidence. Add
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
- Consumes: the fixed successor Authority commit, all rejected predecessor identities, and tests from Tasks 1-2.
- Produces: `validate_chrome_authority_migration_chain`, exact-wrapper `validate_chrome_capture_source_contract FILE`, public `--chrome-capture-source-contract FILE`, owned `--chrome-fixed-capture`, Stage A pending admission, exact R4 construction/replay, version-5 ordinary preservation, and the Stage B materialized-pair hook.

- [ ] **Step 1: Bind README to the fixed Authority**

Replace the current migration binding with one exact successor section naming
the design, plan, successor fixed SHA, rejected Authority/candidate and their
`NO_GO` disposition, origin, previous/target versions, exact six-path
governance boundary, R4 release semantics, and
`L3 / deep_reviewer / xhigh / ONE`. Reject duplicate, missing, stale, or
contradictory Chrome migration prose and reject either predecessor SHA as the
current Authority or R4 base.

- [ ] **Step 2: Implement the exact G4 chain validator**

Add constants for origin, all four rejected SHAs, and the fixed successor
Authority SHA; retain the exact six-path list with canonical modes.
First-parent traversal must retain and classify both predecessor pairs as
`NO_GO`, require the successor Authority to be the first correction commit
after `b0b77e8...`, and reject any predecessor as current. Keep per-commit non-empty subset
validation, unlimited rename/copy inspection, NUL checks, ledger identity,
immutable successor three-Authority-blob checks, and final exact cumulative
WriteSet.

- [ ] **Step 3: Implement Stage A without the actual capture script**

Add public mode `--chrome-capture-source-contract FILE`. It accepts exactly
one explicit regular `100755` file, cannot be combined with repository, cards,
or transition flags, and invokes only
`validate_chrome_capture_source_contract FILE`. The helper is read-only: it
does not start Chrome, interpret Bash, build Web assets, mutate Git, or require
`scripts/capture-visual-style-baseline` to exist. It compares the supplied
bytes and final newline to the canonical wrapper in the design.

Add `--chrome-fixed-capture` to the same verifier. This is the only mode and
the only function allowed to start Chrome. It owns the exact capture CLI,
fixed literal version enforcement, test/build/server/probe/screenshot/cleanup
workflow, and early rejection of environment/browser overrides. It never
accepts an executable path. Stage A runs the wrapper checker, the capture
mode's early-rejection cases, and one verifier-owned positive temporary capture
fixture that cleans completely and is not formal evidence. Independently fail
unless `scripts/capture-visual-style-baseline` is
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
take the Stage A absence path: materialize the candidate wrapper and the
reviewed-G4 task-card verifier as `100755` siblings in one invocation-owned
directory, validate their exact Git identities and wrapper bytes, and reject
the candidate or release on any failure. Execute the pair with a sanitized
environment, locked toolchain PATH, fixed `/bin/bash`, and no `BASH_ENV`,
`ENV`, exported functions, or browser override variables. Validation of one
copy followed by execution of another is forbidden.

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
blob, both rejected pairs remain immutable `NO_GO` evidence, and the successor
Authority blobs remain identical to their first correction commit.

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
governance commit/G4/working tree, Stage A exact wrapper PASS with all
byte/mode mutations and owned-launcher early-rejection cases closed, and diff
check all PASS on the fixed G4 tree.

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
- Produces: a new exact twelve-path VSB-03 candidate whose candidate-bound exact wrapper delegates to the sibling reviewed-G4 verifier before candidate admission, release, or browser launch.

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
admission or release, materialize that exact candidate blob with `git show`,
require canonical bytes/mode through:

```bash
scripts/verify-visual-style-baseline-cards \
  --chrome-capture-source-contract "${VSB_CANDIDATE_CAPTURE_TMP}"
```

The fixed visual verifier must create one temporary `scripts/` directory,
materialize the validated candidate wrapper and the task-card verifier from the
reviewed G4 recorded by R4 as `100755` siblings, and execute that exact wrapper.
The wrapper delegates to sibling `--chrome-fixed-capture`; no candidate-owned
source may select or launch a browser. Missing validation, a conditional skip,
wrong G4 verifier blob, or validating one copy and executing another is a
candidate/release failure.

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
