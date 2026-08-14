# Cognitura VSB Historical HV Replay Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the final VSB-03 P1 by replaying the fixed historical HV Gate from `77d8c1e...`, admitting one append-only exact-eight repair candidate, and recording the existing version-5 sequence-11 `COMPLETE` receipt.

**Architecture:** Keep the VSB state machine at version 5. The task-card verifier receives one literal one-time branch for the `2690ab9...` successor chain; the fixed visual verifier replays the complete `77d8c1e...` archive in an invocation-owned directory. The same unchanged exact-eight candidate receives one L3 governance review and one L4 final review before a ledger-only direct child closes VSB-03.

**Tech Stack:** Bash 3.2, Git object plumbing, `/usr/bin/git archive`, `/usr/bin/tar`, existing VSB real-Git fixtures, Node `24.18.0`, pnpm `11.17.0`, Chrome `151.0.7922.138`.

## Global Constraints

- Repair origin: `2690ab9e6d0318c63deb56f86bc0b923ae845c04`; VSB release R4: `efc763966d64fc808e9098bec52566edb7d15dc3`.
- Historical HV snapshot: `77d8c1e780f5cc4d209a56baff349135a3c04ee8`; tree: `476bc02272b2e0c4f8f6eb4565e9dcf08369f762`.
- Historical visual evidence baseline remains `70eefba5912e6884e4e7e1d6477a65f4091d6590`.
- Execution state stays version `5`; do not add G5, R5, version 6, or `HistoricalHVReplayCorrection*` fields.
- Candidate cumulative diff from `2690ab9...` is exactly the approved eight paths. The other ten original VSB-03 Owner paths remain byte- and mode-identical.
- All repair commits are single-parent, non-empty, free of R/C, and preserve ledger, Wave 1, evidence, raw, `.idea/`, database, deployment, and remote state.
- Route is `L3 deep_reviewer/xhigh/ONE`, then `L4 deep_reviewer/xhigh/ONE`, on one unchanged SHA. Ultra is `NOT_RUN`.
- Locked toolchain prefix is `/Users/yuzhuangzhuang/.npm/_npx/4aa47c519def57bc/node_modules/.bin:/Users/yuzhuangzhuang/.npm/_npx/acaf29b40d536b0e/node_modules/.bin:`.
- Do not run full suites concurrently. Preserve `.idea/`; do not read or stage `temp-input/**` or ignored `dist/`.
- No database write, deploy, push, reset, amend, rebase, or destructive history operation is authorized.

## File Structure

The cumulative exact-eight candidate contains only:

```text
docs/superpowers/specs/2026-08-15-cognitura-vsb-historical-hv-replay-repair-design.md
docs/superpowers/plans/2026-08-15-cognitura-vsb-historical-hv-replay-repair.md
docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md
docs/task-cards/visual-style-baseline/README.md
scripts/verify-visual-style-baseline-cards
tests/task-cards/verify-visual-style-baseline-cards.sh
scripts/verify-visual-style-baseline
tests/visual-style-baseline/verify-visual-style-baseline.sh
```

Only after both reviews may `docs/task-cards/visual-style-baseline/execution-state.md` change in the ledger-only receipt.

---

### Task 1: Establish the task-card exact-eight and receipt RED

**Files:**
- Modify: `tests/task-cards/verify-visual-style-baseline-cards.sh`

**Interfaces:**
- Consumes: fixed origin `2690ab9...` and the existing public static/transition verifier entries.
- Produces: `--historical-hv-replay-repair-contract-only` and `run_historical_hv_replay_repair_contract` for Task 4.

- [ ] **Step 1: Add the focused flag and fixed fixture identities**

```bash
--historical-hv-replay-repair-contract-only)
  run_historical_hv_replay_repair_contract_only=1
  shift
  ;;

historical_hv_repair_origin_sha=2690ab9e6d0318c63deb56f86bc0b923ae845c04
historical_hv_snapshot_sha=77d8c1e780f5cc4d209a56baff349135a3c04ee8
historical_hv_snapshot_tree=476bc02272b2e0c4f8f6eb4565e9dcf08369f762
```

The focused branch runs only this contract and checks the existing invocation-root cleanup/sibling sentinel.

- [ ] **Step 2: Build the legal real-Git exact-eight fixture**

Use a shared clone detached at `2690ab9...`. Create a linear chain with path-unique content so `git diff-tree -M -C --find-copies-harder` reports no R/C. Assert every commit is single-parent/non-empty, the cumulative set is the literal eight paths above, and the ledger blob equals the origin.

- [ ] **Step 3: Build the direct version-5 terminal receipt fixture**

Change only `execution-state.md` and apply:

```bash
set_field "${fixture_state}" TaskCardSetStatus COMPLETE
set_field "${fixture_state}" ActiveTaskCard NONE
set_field "${fixture_state}" ReleasedTaskCard NONE
set_field "${fixture_state}" CompletedTaskCards VSB-00,VSB-01,VSB-02,VSB-03
set_field "${fixture_state}" CurrentCandidateSHA "${repair_candidate_sha}"
set_field "${fixture_state}" CurrentGateStatus VSB-G3_PASS
set_field "${fixture_state}" CurrentReviewRoute deep_reviewer
set_field "${fixture_state}" CurrentReviewVerdict FINAL_GO_P0_0_P1_0_P2_0
set_field "${fixture_state}" VSB03CandidateSHA "${repair_candidate_sha}"
set_field "${fixture_state}" VSB03GateStatus VSB-G3_PASS
set_field "${fixture_state}" VSB03ReviewRoute deep_reviewer
set_field "${fixture_state}" VSB03DeepReviewVerdict FINAL_GO_P0_0_P1_0_P2_0
set_field "${fixture_state}" VSB03UltraReviewVerdict NOT_RUN
set_field "${fixture_state}" TransitionSequence 11
set_field "${fixture_state}" TransitionKind COMPLETE
set_field "${fixture_state}" TransitionBaseSHA "${repair_candidate_sha}"
set_field "${fixture_state}" VisualImplementation COMPLETE
```

Require version 5 and byte-identical existing governance/correction/migration blocks.

- [ ] **Step 4: Add the fail-closed matrix**

Drive all cases through the public verifier: empty, merge, missing path, ninth path, ledger/W1 drift, NUL, mode, R/C, low rename limit, outside/ledger introduce-then-restore, Authority blob/mode drift, ten-owner-path drift, wrong origin/snapshot, reused `2690ab9...` GO, non-direct/extra-path receipt, version 6, wrong sequence/base, stacked route, Ultra execution, missing review, second repair, and historical-block mutation. Lock exact positive/negative counts.

- [ ] **Step 5: Run and record RED**

```bash
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh \
  --historical-hv-replay-repair-contract-only
```

Expected: exit `1`; the first legal exact-eight candidate is rejected by the old exact-twelve VSB-03 validator.

- [ ] **Step 6: Commit tests-only RED**

```bash
git add tests/task-cards/verify-visual-style-baseline-cards.sh
git diff --cached --check
git commit -m "test(vsb): define historical HV repair contract"
```

---

### Task 2: Establish the archived historical-HV replay RED

**Files:**
- Modify: `tests/visual-style-baseline/verify-visual-style-baseline.sh`

**Interfaces:**
- Consumes: `scripts/verify-visual-style-baseline --repo-root PATH --candidate-sha SHA`.
- Produces: executable requirements for `run_historical_hv_replay` and `require_historical_hv_output` in Task 5.

- [ ] **Step 1: Assert the fixed snapshot identity**

Use `/usr/bin/git cat-file`, `show`, and `ls-tree` to assert commit, parent, tree, and the three key mode/blob pairs from the design before any browser starts.

- [ ] **Step 2: Require public replay summaries**

Run a Git-extracted candidate visual verifier and require:

```text
HistoricalHVReplaySHA = 77d8c1e780f5cc4d209a56baff349135a3c04ee8
HistoricalHVReplay = PASS
HistoricalHVCurrentTreeVerifier = NOT_RUN
```

Retain all existing browser/evidence expectations and prove no TMP/worktree residue.

- [ ] **Step 3: Add replay mutations**

Invoke normal public CLI using invocation-owned mutated verifier copies: wrong commit/tree/key blob, restored current-tree HV call, current projection injection, extraction outside invocation root, nonexistent expected PASS line, FAIL/authorization contradiction, BASH_ENV/ENV/exported functions, and cleanup sentinel. The two output mutations run the real archive and fail after replay.

- [ ] **Step 4: Run and record RED**

```bash
VSB_TOOLCHAIN_PATH='/Users/yuzhuangzhuang/.npm/_npx/4aa47c519def57bc/node_modules/.bin:/Users/yuzhuangzhuang/.npm/_npx/acaf29b40d536b0e/node_modules/.bin:'"${PATH}"
env PATH="${VSB_TOOLCHAIN_PATH}" \
  /bin/bash tests/visual-style-baseline/verify-visual-style-baseline.sh
```

Expected: exit `1` because current production does not perform or print the historical replay.

- [ ] **Step 5: Commit tests-only RED**

```bash
git add tests/visual-style-baseline/verify-visual-style-baseline.sh
git diff --cached --check
git commit -m "test(vsb): require fixed historical HV replay"
```

---

### Task 3: Fix the append-only Authority text

**Files:**
- Modify: `docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md`
- Modify: `docs/task-cards/visual-style-baseline/README.md`

**Interfaces:**
- Consumes: approved design and this implementation plan.
- Produces: the literal repair Authority SHA used by Tasks 4 and 5.

- [ ] **Step 1: Correct old Task 5 Steps 7, 11, 13, and 14**

Replace the current-tree historical verifier requirement with:

```text
HistoricalHVGate = REPLAY_FIXED_GIT_SNAPSHOT
HistoricalHVReplaySnapshotSHA = 77d8c1e780f5cc4d209a56baff349135a3c04ee8
CurrentTreeHighFidelityVerifier = NOT_A_HISTORICAL_REPLAY
ExecutionStateVersion = 5
FinalTransitionSequence = 11
FinalReviewRoute = L4/deep_reviewer/xhigh/ONE
Ultra = NOT_RUN
```

Append the exact-eight terminal exception without rewriting the immutable exact-twelve failed candidate.

- [ ] **Step 2: Add one exact README Authority section**

Record `2690ab9...` as immutable `NO_GO/P1=1`, the fixed snapshot, exact-eight paths, version-5 terminal receipt, L3/L4 routes, and non-authorizations. Reject stale v6/R5/current-tree-HV prose outside its historical explanation.

- [ ] **Step 3: Commit and capture Authority**

```bash
git add \
  docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md \
  docs/task-cards/visual-style-baseline/README.md
git diff --cached --check
git commit -m "docs(vsb): authorize historical HV replay repair"
VSB_HV_REPAIR_AUTHORITY_SHA="$(git rev-parse HEAD)"
```

This is the first post-`2690ab9...` tree containing final design, final plan, and corrected old plan. Do not modify those three Authority blobs afterward.

---

### Task 4: Make one-time task-card topology and receipt GREEN

**Files:**
- Modify: `scripts/verify-visual-style-baseline-cards`
- Modify: `tests/task-cards/verify-visual-style-baseline-cards.sh`

**Interfaces:**
- Consumes: literal `VSB_HV_REPAIR_AUTHORITY_SHA`, origin `2690ab9...`, exact-eight and original exact-twelve lists.
- Produces: `validate_historical_hv_repair_chain SHA`, `validate_historical_hv_repair_candidate SHA`, and special COMPLETE admission.

- [ ] **Step 1: Add constants and exact path emitters**

```bash
historical_hv_repair_origin_sha=2690ab9e6d0318c63deb56f86bc0b923ae845c04
historical_hv_snapshot_sha=77d8c1e780f5cc4d209a56baff349135a3c04ee8

historical_hv_repair_write_set() {
  printf '%s\n' \
    docs/superpowers/specs/2026-08-15-cognitura-vsb-historical-hv-replay-repair-design.md \
    docs/superpowers/plans/2026-08-15-cognitura-vsb-historical-hv-replay-repair.md \
    docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md \
    docs/task-cards/visual-style-baseline/README.md \
    scripts/verify-visual-style-baseline-cards \
    tests/task-cards/verify-visual-style-baseline-cards.sh \
    scripts/verify-visual-style-baseline \
    tests/visual-style-baseline/verify-visual-style-baseline.sh
}

historical_hv_repair_governance_write_set() {
  historical_hv_repair_write_set | sed -n '1,6p'
}

historical_hv_repair_product_write_set() {
  historical_hv_repair_write_set | sed -n '7,8p'
}
```

Set `historical_hv_repair_authority_sha` to the exact 40-character stdout
captured by Task 3's `git rev-parse HEAD`. Validate it with
`[[ "${historical_hv_repair_authority_sha}" =~ ^[0-9a-f]{40}$ ]]` and store it
as a single-quoted literal in production; do not read it from an environment
variable or symbolic ref at runtime.

- [ ] **Step 2: Validate every repair-chain commit**

`validate_historical_hv_repair_chain candidate_sha` requires: strict first-parent ancestry from `2690ab9...`; Authority ancestry; one parent/non-empty per commit; changed paths subset exact-eight; no R/C under `-M -C --find-copies-harder`; no NUL/mode drift; ledger and W1 equality at every commit; immutable Authority blobs/modes; and cumulative exact-eight. Use NUL-delimited raw status plus per-commit `ls-tree`/`cat-file`, not tip-only checks.

- [ ] **Step 3: Bind the old exact-twelve and ten unchanged paths**

`validate_historical_hv_repair_candidate candidate_sha` first validates `2690ab9...` as the ordinary R4-based VSB-03 exact-twelve candidate. It then requires the ten Owner paths other than visual verifier/test to match `2690ab9...` by blob and mode, and requires both repaired paths to differ and remain `100755`.

- [ ] **Step 4: Dispatch only the literal special case**

Before generic VSB-03 validation, select the repair branch only when both origin and fixed Authority are ancestors of the candidate. Every other candidate uses the unchanged generic Owner validator. Do not register the repair as a reusable release anchor.

- [ ] **Step 5: Reuse COMPLETE with the special admission**

Require direct child, ledger-only diff, sequence `10 -> 11`, version `5 -> 5`, candidate SHA equality, `deep_reviewer/xhigh/ONE`, Ultra `NOT_RUN`, and byte preservation of every existing history block. Static replay calls the same pair validator.

- [ ] **Step 6: Run focused GREEN**

```bash
/bin/bash -n scripts/verify-visual-style-baseline-cards
/bin/bash -n tests/task-cards/verify-visual-style-baseline-cards.sh
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh \
  --historical-hv-replay-repair-contract-only
```

Expected: locked counters and `HistoricalHVReplayRepairContractTests = PASS`.

- [ ] **Step 7: Commit task-card GREEN**

```bash
git add \
  scripts/verify-visual-style-baseline-cards \
  tests/task-cards/verify-visual-style-baseline-cards.sh
git diff --cached --check
git commit -m "fix(vsb): admit terminal historical HV repair"
```

---

### Task 5: Make candidate-bound historical replay GREEN

**Files:**
- Modify: `scripts/verify-visual-style-baseline`
- Modify: `tests/visual-style-baseline/verify-visual-style-baseline.sh`

**Interfaces:**
- Consumes: `validate_candidate_tree candidate_sha`, fixed snapshot identity, and `runtime_root`.
- Produces: `require_historical_hv_output FILE` and `run_historical_hv_replay` before current tests/build/capture.

- [ ] **Step 1: Teach candidate binding the exact-eight successor**

Keep R4→`2690ab9...` exact-twelve proof, then validate `2690ab9...`→candidate exact-eight only for the fixed Authority descendant. Compare every governed working path to the repair candidate before executing a current-tree tool.

- [ ] **Step 2: Implement whole-line archived-output validation**

```bash
require_historical_hv_output() {
  local output_file="$1" line field
  for line in \
    'HighFidelityVisualTaskCardValidation = PASS' \
    'TaskCardSetStatus = COMPLETE' \
    'HighFidelityVisualDesign = PASS' \
    'HighFidelityDesignStatus = COMPLETE' \
    'HighFidelityVisualValidation = PASS' \
    'HighFidelityUsabilityValidation = PASS' \
    'HighFidelityStateAcceptance = PASS' \
    'ImplementationValidation = NOT_RUN' \
    'BusinessImplementation = NOT_AUTHORIZED' \
    'FormalDatabaseWrite = NOT_AUTHORIZED' \
    'RemotePush = NOT_AUTHORIZED'; do
    field="${line%% = *}"
    [[ "$(grep -c "^${field} = " "${output_file}" || true)" -eq 1 &&
       "$(grep -Fxc -- "${line}" "${output_file}" || true)" -eq 1 ]] ||
      fail "historical HV replay output mismatch: ${line}"
  done
  [[ -z "$(grep -E ' = (FAIL|AUTHORIZED|USER_AUTHORIZED)$' \
      "${output_file}" || true)" ]] ||
    fail 'historical HV replay output contains a contradiction'
}
```

Use exact records and exact-once counts; no substring acceptance.

- [ ] **Step 3: Implement isolated fixed-tree replay**

`run_historical_hv_replay` must verify commit/parent/tree and the three key modes/blobs; require the fixed installed Chrome executable; create `${runtime_root}/historical-hv-replay`; export with `/usr/bin/git -C "${repo_root}" archive --format=tar 77d8c1e...`; extract with `/usr/bin/tar`; and run only the archived verifier under `/usr/bin/env -i` with locked PATH and no `CHROME_BIN`, `BASH_ENV`, `ENV`, or exported functions. Capture output, require zero exit, call the output validator, and print the three replay summaries. Never pass current path overrides.

- [ ] **Step 4: Enforce execution order**

```text
parse -> invocation root -> candidate identity/exact-eight -> capture pair
-> fixed historical replay -> evidence/frozen paths -> current gates
-> fresh capture -> byte comparison
```

- [ ] **Step 5: Run visual GREEN**

```bash
VSB_TOOLCHAIN_PATH='/Users/yuzhuangzhuang/.npm/_npx/4aa47c519def57bc/node_modules/.bin:/Users/yuzhuangzhuang/.npm/_npx/acaf29b40d536b0e/node_modules/.bin:'"${PATH}"
/bin/bash -n scripts/verify-visual-style-baseline
/bin/bash -n tests/visual-style-baseline/verify-visual-style-baseline.sh
env PATH="${VSB_TOOLCHAIN_PATH}" \
  /bin/bash tests/visual-style-baseline/verify-visual-style-baseline.sh
```

Expected: existing browser `1+/48-`, replay mutations, archived HV completion, and fresh evidence all PASS.

- [ ] **Step 6: Commit the fixed exact-eight candidate**

First assert `git diff --name-only 2690ab9...` equals exact-eight and the ten frozen Owner paths match. Then:

```bash
git add \
  scripts/verify-visual-style-baseline \
  tests/visual-style-baseline/verify-visual-style-baseline.sh
git diff --cached --check
git commit -m "fix(vsb): replay fixed historical HV gate"
VSB03_REPAIR_CANDIDATE_SHA="$(git rev-parse HEAD)"
```

Any later edit creates a new candidate and invalidates reviews.

---

### Task 6: Fix candidate identity and run L3 then L4

**Files:**
- No Repository modification on the GO path.

**Interfaces:**
- Consumes: immutable `VSB03_REPAIR_CANDIDATE_SHA`.
- Produces: one L3 GO and one L4 GO for the same SHA.

- [ ] **Step 1: Run final gates serially**

```bash
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh \
  --historical-hv-replay-repair-contract-only
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh
/bin/bash -n scripts/verify-visual-style-baseline-cards
/bin/bash -n tests/task-cards/verify-visual-style-baseline-cards.sh
VSB_FIXED_RUNTIME_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-vsb-fixed.XXXXXX")"
git show "${VSB03_REPAIR_CANDIDATE_SHA}:scripts/verify-visual-style-baseline" > \
  "${VSB_FIXED_RUNTIME_DIR}/verify-visual-style-baseline"
chmod 755 "${VSB_FIXED_RUNTIME_DIR}/verify-visual-style-baseline"
env PATH="${VSB_TOOLCHAIN_PATH}" \
  "${VSB_FIXED_RUNTIME_DIR}/verify-visual-style-baseline" \
  --repo-root "$(pwd -P)" --candidate-sha "${VSB03_REPAIR_CANDIDATE_SHA}"
scripts/verify-visual-style-baseline-cards \
  --repo-root . --cards-dir docs/task-cards/visual-style-baseline
scripts/verify-wave1-implementation-cards \
  --repo-root . --cards-dir docs/task-cards/wave-1-implementation
git diff --check
```

Expected: VSB still IN_PROGRESS/VSB-03, Wave 1 SUSPENDED, historical replay PASS, evidence byte-identical, and no tracked residue.

- [ ] **Step 2: Record fixed identity evidence**

Record candidate/parent/tree, first-parent commits from `2690ab9...`, exact-eight name-status/modes/no R/C, ledger identity, ten unchanged Owner blobs/modes, Authority blobs, snapshot identity, W1 freeze, and `.idea/` residue.

- [ ] **Step 3: Run one L3 governance review**

Use `deep_reviewer / xhigh`. Require `GO`, P0/P1/P2 all zero, multiplicity ONE, Ultra NOT_RUN. Review topology, Authority, archive isolation, mutations, cleanup, and absence of v6/R5/general replay.

- [ ] **Step 4: Run one L4 final review on the unchanged SHA**

Use a fresh `deep_reviewer / xhigh`. Require `FinalGateVerdict = GO`, P0/P1/P2 all zero, `HistoricalHVReplay = PASS`, Ultra NOT_RUN. Any finding returns to its Owner, creates a new SHA, and invalidates both verdicts.

---

### Task 7: Write the ledger-only COMPLETE receipt

**Files:**
- Modify: `docs/task-cards/visual-style-baseline/execution-state.md`

**Interfaces:**
- Consumes: unchanged candidate and both zero-finding reviews.
- Produces: version-5 sequence-11 terminal receipt; no new correction block.

- [ ] **Step 1: Build exact terminal ledger**

Apply only Task 1 Step 3's field transform. Preserve every other byte, block, order, and final newline. The literal candidate SHA replaces all fixture variables.

- [ ] **Step 2: Commit only the ledger**

```bash
git add docs/task-cards/visual-style-baseline/execution-state.md
git diff --cached --check
git diff --cached --name-only
git commit -m "chore(vsb): close historical HV replay repair"
VSB03_COMPLETE_RECEIPT_SHA="$(git rev-parse HEAD)"
```

Require one staged path and receipt parent equal to the candidate.

- [ ] **Step 3: Verify explicit and static terminal replay**

```bash
scripts/verify-visual-style-baseline-cards \
  --repo-root . --cards-dir docs/task-cards/visual-style-baseline \
  --transition-base "${VSB03_REPAIR_CANDIDATE_SHA}" \
  --transition-head "${VSB03_COMPLETE_RECEIPT_SHA}"
scripts/verify-visual-style-baseline-cards \
  --repo-root . --cards-dir docs/task-cards/visual-style-baseline
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh
scripts/verify-wave1-implementation-cards \
  --repo-root . --cards-dir docs/task-cards/wave-1-implementation
git diff --check
git status --short
```

Expected: VSB COMPLETE, Active/Released NONE, exact candidate bound, deep final GO, Ultra NOT_RUN, Wave 1 still SUSPENDED, tracked/index clean, only existing `.idea/` untracked.

- [ ] **Step 4: Report separate Wave 1 boundary**

Do not execute the ten-path Wave 1 restore here. Report that it is eligible for its separately governed transition; database writes and push remain unauthorized.

---

## Plan Self-Review Checklist

- Every approved design requirement maps to Tasks 1-7.
- Candidate cumulative WriteSet is exactly eight; only the later receipt adds the ledger path.
- Historical replay is internal to the fixed visual verifier; no generic replay API exists.
- `2690ab9...` remains immutable NO_GO evidence; ten Owner paths stay unchanged.
- State remains version 5 and uses existing COMPLETE semantics.
- L3 and L4 use the same candidate, deep/xhigh/ONE, Ultra NOT_RUN.
- Wave 1 restoration, database, deploy, and push are outside this plan.
- No symbolic SHA is written to the ledger and no unbounded mutation category remains.
