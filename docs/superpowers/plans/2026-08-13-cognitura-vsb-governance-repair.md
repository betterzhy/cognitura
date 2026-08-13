# Cognitura Visual Style Baseline Governance Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不改写 Git 历史的前提下，使 Visual Style Baseline 治理器支持经过多轮 non-amend 审查修复的线性累计候选，并通过一次性 `GOVERNANCE_REPAIR` 为 VSB-01 建立合法 release anchor。

**Architecture:** 普通业务候选由“最近合法 Owner release receipt → 最终 reviewed tip”的单父提交链定义；每个提交必须是 Owner WriteSet 的非空子集，累计差异必须精确等于完整 WriteSet。固定失败回执 `d47c8c7...` 不追认为普通 `ADVANCE`，而由受限的治理修复链、双重固定 SHA 审查和 version 2 ledger-only receipt 恢复状态机。

**Tech Stack:** Bash 3.2、Git object/tree/blob 命令、Markdown 治理文档、现有 task-card contract tests。

---

## 0. Fixed authority and boundaries

```text
ApprovedGovernanceRepairSpecSHA = 2123594540c91341c480f504949315a6abec316c
GovernanceRepairOriginReceiptSHA = d47c8c7bd7355947b5e8e1de6c264d80c2e27c9a
ReviewedVSB00CandidateSHA = 737c053483d1f3d084d5f90d5c36f76b0ae8f5a3
ValidVSB00ReleaseReceiptSHA = c9fe3d6c081f67459e13cbcff010ddb5cdbf1508
FrozenWave1I03SHA = 4e63936c631ab34807e714b90d30415a959bc13d
HistoryRewrite = FORBIDDEN
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

治理修复候选 `G` 相对固定 origin 的累计 WriteSet 必须精确为：

```text
docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md
docs/superpowers/plans/2026-08-13-cognitura-vsb-governance-repair.md
docs/task-cards/visual-style-baseline/README.md
scripts/verify-visual-style-baseline-cards
tests/task-cards/verify-visual-style-baseline-cards.sh
```

实现期间不得修改 `docs/task-cards/visual-style-baseline/execution-state.md`。只有 Task 6
在 `G` 通过两级固定 SHA 审查后，才允许创建一个 ledger-only receipt。

## 1. File responsibilities

- `docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md`
  - 已批准的一次性治理修复设计；实施阶段只读。
- `docs/superpowers/plans/2026-08-13-cognitura-vsb-governance-repair.md`
  - 本执行计划和修复 WriteSet 的正式组成部分。
- `docs/task-cards/visual-style-baseline/README.md`
  - 记录累计候选、合法 release receipt、一次性 repair 和后续 anchor 规则；不得维护第二份 active 状态。
- `scripts/verify-visual-style-baseline-cards`
  - 唯一 VSB ledger、candidate chain、receipt replay、terminal provenance 和 repair transition 验证器。
- `tests/task-cards/verify-visual-style-baseline-cards.sh`
  - 真实 Git history 正例、负例、binary-safe、single-parent、terminal 和 repair 回归合同。
- `docs/task-cards/visual-style-baseline/execution-state.md`
  - 唯一可变运行态；仅最终 ledger-only receipt 修改。

### Task 1: Add RED fixtures for linear cumulative business candidates

**Files:**
- Modify: `tests/task-cards/verify-visual-style-baseline-cards.sh:428-471`
- Modify: `tests/task-cards/verify-visual-style-baseline-cards.sh:857-1012`
- Modify: `tests/task-cards/verify-visual-style-baseline-cards.sh:1110-1148`
- Modify: `tests/task-cards/verify-visual-style-baseline-cards.sh:1374-1457`
- Modify: `tests/task-cards/verify-visual-style-baseline-cards.sh:1677-1792`

- [ ] **Step 1: Add reusable cumulative-candidate helpers**

Add helpers that create one path at a time without changing the ledger, and that invoke the
public transition entry with captured output:

```bash
commit_candidate_subset() {
  local fixture_repo="$1"
  local subject="$2"
  shift 2
  local candidate_path
  for candidate_path in "$@"; do
    mkdir -p "${fixture_repo}/$(dirname "${candidate_path}")"
    printf '\nround-marker=%s\n' "${subject}" >> "${fixture_repo}/${candidate_path}"
  done
  git -C "${fixture_repo}" add -- "$@"
  git -C "${fixture_repo}" commit -m "${subject}" >/dev/null
  git -C "${fixture_repo}" rev-parse HEAD
}

run_vsb_transition() {
  local fixture_repo="$1"
  local transition_base="$2"
  local transition_head="$3"
  /bin/bash "${fixture_repo}/scripts/verify-visual-style-baseline-cards" \
    --repo-root "${fixture_repo}" \
    --cards-dir "${fixture_repo}/docs/task-cards/visual-style-baseline" \
    --transition-base "${transition_base}" \
    --transition-head "${transition_head}" 2>&1
}
```

- [ ] **Step 2: Add a three-commit cumulative candidate positive**

Build `ACTIVATE_SET receipt → subset commit 1 → subset commit 2 → remaining paths commit 3 →
ADVANCE receipt`. Assert that every candidate commit is single-parent, the cumulative diff is the
exact VSB-00 WriteSet, and the public transition verifier accepts the final receipt.

```bash
cumulative_candidate_one="$(commit_candidate_subset "${fixture_repo}" \
  "test: candidate round one" "AGENTS.md" \
  "docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png")"
cumulative_candidate_two="$(commit_candidate_subset "${fixture_repo}" \
  "test: candidate round two" \
  "docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md" \
  "docs/engineering/cognitura-visual-style-baseline-manifest.yaml")"
cumulative_candidate_tip="$(commit_candidate_subset "${fixture_repo}" \
  "test: candidate final round" \
  "docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md" \
  "docs/engineering/cognitura-design-index.md" \
  "scripts/import-visual-style-reference" \
  "scripts/verify-visual-style-baseline-reference" \
  "tests/visual-style-baseline/verify-reference.sh")"
```

Expected after the production change: transition output contains
`VisualStyleBaselineTaskCardValidation = PASS`.

- [ ] **Step 3: Add cumulative-chain negatives**

Add distinct real Git fixtures and exact assertions for:

```text
missing one final WriteSet path
extra unauthorized path in an intermediate commit, removed before the tip
execution ledger in an intermediate commit, restored before the tip
another Owner's WriteSet path in an intermediate commit
rename inside the chain
merge commit inside the chain
empty commit inside the chain
reviewed candidate SHA points to a non-tip commit
an older valid receipt is selected when a newer valid Owner receipt exists
```

Every fixture must call the public `--transition-base/--transition-head` entry and assert a stable
failure fragment. Use these fragments:

```text
candidate cumulative diff must equal the exact Owner WriteSet
candidate chain commit changed a path outside the Owner WriteSet
candidate chain must not modify the execution ledger
candidate chain commit must have exactly one parent
candidate chain commit must not be empty
reviewed candidate must be the candidate chain tip
candidate chain must start at the nearest valid Owner release receipt
```

- [ ] **Step 4: Prove RED**

Run:

```bash
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh
```

Expected: non-zero, with the first legal multi-commit candidate rejected by the old direct-parent
rule, or one new adversarial history unexpectedly accepted. Record the exact failure in the ignored
task report before changing production code.

- [ ] **Step 5: Commit tests only**

```bash
git add tests/task-cards/verify-visual-style-baseline-cards.sh
git diff --cached --check
git commit -m "test: define cumulative VSB candidates"
```

Expected: one-path non-amend commit; ledger unchanged.

### Task 2: Implement linear cumulative candidate validation

**Files:**
- Modify: `scripts/verify-visual-style-baseline-cards:69-78`
- Modify: `scripts/verify-visual-style-baseline-cards:399-471`
- Modify: `scripts/verify-visual-style-baseline-cards:473-718`
- Modify: `scripts/verify-visual-style-baseline-cards:976-1146`
- Test: `tests/task-cards/verify-visual-style-baseline-cards.sh`

- [ ] **Step 1: Separate exact cumulative WriteSet from per-commit subset checks**

Replace direct-parent candidate validation with three byte-safe Git-history helpers:

```bash
candidate_commit_paths() {
  local repo_root="$1"
  local parent_sha="$2"
  local child_sha="$3"
  git -C "${repo_root}" diff --no-renames --name-only \
    "${parent_sha}" "${child_sha}"
}

require_candidate_commit_subset() {
  local repo_root="$1"
  local owner="$2"
  local parent_sha="$3"
  local child_sha="$4"
  local changed_paths
  changed_paths="$(candidate_commit_paths "${repo_root}" "${parent_sha}" "${child_sha}")"
  [[ -n "${changed_paths}" ]] || fail "candidate chain commit must not be empty"
  require_single_parent "${repo_root}" "${child_sha}" \
    "candidate chain commit must have exactly one parent"
  require_path_set_subset_of_owner "${owner}" "${changed_paths}"
}

require_exact_cumulative_candidate_write_set() {
  local repo_root="$1"
  local owner="$2"
  local release_sha="$3"
  local candidate_sha="$4"
  require_exact_owner_path_set "${owner}" "$({
    git -C "${repo_root}" diff --no-renames --name-only \
      "${release_sha}" "${candidate_sha}"
  })" "candidate cumulative diff must equal the exact Owner WriteSet"
}
```

Keep the existing exact per-card path constants as the only WriteSet authority. Do not infer
WriteSets from commit messages, branch names, tags, file contents or test fixtures.

- [ ] **Step 2: Locate and replay the nearest legal Owner release receipt**

Walk the candidate's single-parent ancestry until the first ledger-only commit whose parsed receipt
claims to release the Owner. Validate that receipt with the existing transition-pair state machine;
if validation fails, continue only to determine that the claimed receipt is invalid, then fail closed
rather than silently selecting an older matching receipt.

```bash
find_nearest_owner_release_receipt() {
  local repo_root="$1"
  local owner="$2"
  local cursor_sha="$3"
  while :; do
    local parent_sha
    parent_sha="$(single_parent_of "${repo_root}" "${cursor_sha}" \
      "candidate ancestry commit")"
    if commit_is_ledger_only "${repo_root}" "${cursor_sha}" && \
       ledger_release_owner_equals "${repo_root}" "${cursor_sha}" "${owner}"; then
      validate_release_receipt_transition "${repo_root}" "${cursor_sha}" "${owner}"
      printf '%s\n' "${cursor_sha}"
      return 0
    fi
    cursor_sha="${parent_sha}"
  done
}
```

`ACTIVATE_SET`、`ADVANCE`、`RETURN_TO_OWNER` 和 `GOVERNANCE_REPAIR` receipts may release
an Owner. `STOP_BY_USER` and terminal receipts cannot start a business candidate chain.

- [ ] **Step 3: Validate the whole candidate chain**

Collect commits from release child through tip using `git rev-list --reverse --first-parent`, then
require each commit to be the direct single-parent child of the previous SHA and a non-empty subset
of the Owner WriteSet. Explicitly reject the ledger path before the generic subset message.

```bash
validate_linear_cumulative_candidate() {
  local repo_root="$1"
  local owner="$2"
  local candidate_sha="$3"
  local release_sha
  release_sha="$(find_nearest_owner_release_receipt \
    "${repo_root}" "${owner}" "$(single_parent_of "${repo_root}" \
      "${candidate_sha}" "reviewed candidate")")"
  validate_candidate_commits_in_order \
    "${repo_root}" "${owner}" "${release_sha}" "${candidate_sha}"
  require_exact_cumulative_candidate_write_set \
    "${repo_root}" "${owner}" "${release_sha}" "${candidate_sha}"
  printf '%s\n' "${release_sha}"
}
```

Return the validated release SHA so transition logic and terminal provenance can bind to the same
fact without a second ancestry search.

- [ ] **Step 4: Wire cumulative validation into all candidate-bearing transitions**

Replace direct-parent WriteSet checks in both the fixed `--transition-base/head` dispatcher and
receipt ancestry replay for:

```text
ADVANCE
COMPLETE
RETURN_TO_OWNER
FINAL_NO_GO
terminal provenance replay
```

For `RETURN_TO_OWNER`, the business candidate Owner remains the BASE active/failed Owner; the target
Owner only controls the rollback prefix and next release state. Preserve all existing route, review,
sequence, NUL, binary-safe, single-parent and immutable-field checks.

- [ ] **Step 5: Keep the fixed failed receipt invalid as ordinary ADVANCE**

At the transition entry, reject the exact fixed origin before ordinary dispatcher acceptance:

```bash
governance_repair_origin_sha="d47c8c7bd7355947b5e8e1de6c264d80c2e27c9a"
if [[ "${resolved_head}" == "${governance_repair_origin_sha}" ]]; then
  fail "fixed governance repair origin is not a valid ordinary VSB receipt"
fi
```

Do not reject the reviewed VSB-00 candidate `737c053...`; it remains the reviewed business tip.

- [ ] **Step 6: Run focused GREEN**

Run:

```bash
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh
```

Expected: all previous cases plus the cumulative-candidate matrix pass. Update counters from actual
fixture invocation increments, not a hand-written total disconnected from the fixtures.

- [ ] **Step 7: Commit the minimal validator**

```bash
git add scripts/verify-visual-style-baseline-cards \
  tests/task-cards/verify-visual-style-baseline-cards.sh
git diff --cached --check
git commit -m "fix: validate cumulative VSB candidates"
```

Expected: non-amend commit; no ledger change.

### Task 3: Add RED fixtures for the one-time governance repair

**Files:**
- Modify: `tests/task-cards/verify-visual-style-baseline-cards.sh`
- Modify: `docs/task-cards/visual-style-baseline/README.md:15-18`

- [ ] **Step 1: Document transition and repair rules without duplicating runtime state**

Insert a `## Transition rules` section before the task-card table. It must state:

```text
- execution-state.md is the only mutable Active/READY/completed authority.
- a business candidate is a single-parent, non-empty per-commit Owner-WriteSet-subset chain whose
  release-to-tip cumulative diff is the exact Owner WriteSet.
- ordinary receipt is candidate-tip direct child and ledger-only.
- d47c8c7... is preserved failed evidence and never an ordinary receipt or VSB-01 anchor.
- GOVERNANCE_REPAIR is a one-time v1-to-v2 transition fixed to origin d47c8c7..., approved spec
  2123594..., exact five-path governance chain, deep review GO and ultra final GO.
- its ledger-only receipt is the only legal VSB-01 release anchor after repair.
```

Do not write current ActiveTaskCard, CompletedTaskCards or READY instance values into README.

- [ ] **Step 2: Build a real pending-repair governance chain fixture**

Starting from a synthetic equivalent of the fixed failed receipt, create linear commits whose
cumulative paths are the exact five governance paths. Keep the ledger byte-identical to the origin
ledger throughout the chain.

Assert static validation at the final governance candidate prints:

```text
VisualStyleBaselineTaskCardValidation = PASS
GovernanceRepairStatus = PENDING
```

Also assert that explicit replay of the origin as ordinary `ADVANCE` still fails.

- [ ] **Step 3: Add governance-chain negatives**

Add separate fixtures for:

```text
missing any one of the five governance paths
extra path
execution ledger changed after the origin
merge commit
empty commit
second parent
origin SHA mismatch
reviewed VSB-00 candidate mismatch
governance candidate not equal to chain tip
```

Use stable failure fragments:

```text
governance repair chain must have the exact repair WriteSet
governance repair chain changed an unauthorized path
governance repair chain must preserve the origin ledger bytes
governance repair chain commit must have exactly one parent
governance repair chain commit must not be empty
governance repair origin SHA mismatch
governance repair reviewed VSB-00 candidate mismatch
```

- [ ] **Step 4: Add repair receipt positive and negatives**

Create a single-parent ledger-only receipt with:

```text
ExecutionStateVersion = 2
GovernanceRepairStatus = PASS
GovernanceRepairSpecSHA = 2123594540c91341c480f504949315a6abec316c
GovernanceRepairOriginReceiptSHA = d47c8c7bd7355947b5e8e1de6c264d80c2e27c9a
GovernanceRepairReviewedCandidateSHA = ${fixture_governance_candidate_sha}
GovernanceRepairReviewRoute = deep_reviewer+ultra_gatekeeper
GovernanceRepairReviewVerdict = FINAL_GO_P0_0_P1_0_P2_0
TransitionKind = GOVERNANCE_REPAIR
TransitionBaseSHA = ${fixture_governance_candidate_sha}
TransitionSequence = 3
```

The fixture must preserve all VSB-00 facts, VSB-01 active/released state, authorization fields and
empty VSB-01..03 receipts from the origin ledger. Add negatives for wrong spec/origin/base/reviewed
SHA, missing deep or ultra route, non-final verdict, modified preserved field, non-ledger path,
second repair and sequence not equal to 3.

- [ ] **Step 5: Add post-repair VSB-01 anchor cases**

From the legal repair receipt, create both a single-commit and multi-commit exact VSB-01 candidate.
Both must pass. A candidate chain that includes any governance-repair path must fail with:

```text
candidate chain commit changed a path outside the Owner WriteSet
```

- [ ] **Step 6: Prove RED**

Run:

```bash
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh
```

Expected: non-zero because `GOVERNANCE_REPAIR` is unsupported or the pending repair tree is rejected.
Record the exact first failure.

- [ ] **Step 7: Commit repair contracts and README**

```bash
git add docs/task-cards/visual-style-baseline/README.md \
  tests/task-cards/verify-visual-style-baseline-cards.sh
git diff --cached --check
git commit -m "test: define VSB governance repair"
```

Expected: two-path non-amend commit; ledger unchanged.

### Task 4: Implement pending repair and GOVERNANCE_REPAIR

**Files:**
- Modify: `scripts/verify-visual-style-baseline-cards:101-140`
- Modify: `scripts/verify-visual-style-baseline-cards:473-699`
- Modify: `scripts/verify-visual-style-baseline-cards:734-771`
- Modify: `scripts/verify-visual-style-baseline-cards:831-945`
- Modify: `scripts/verify-visual-style-baseline-cards:976-1146`
- Test: `tests/task-cards/verify-visual-style-baseline-cards.sh`

- [ ] **Step 1: Define fixed repair constants and exact governance WriteSet**

Add literal constants from section 0 and a function returning exactly the five paths. The approved
spec SHA must be `2123594540c91341c480f504949315a6abec316c`; do not discover it from branch state.

```bash
governance_repair_origin_sha="d47c8c7bd7355947b5e8e1de6c264d80c2e27c9a"
governance_repair_spec_sha="2123594540c91341c480f504949315a6abec316c"
governance_repair_vsb00_candidate_sha="737c053483d1f3d084d5f90d5c36f76b0ae8f5a3"
```

- [ ] **Step 2: Validate the pending-repair tree at governance candidate G**

Before ordinary static receipt validation, recognize only the fixed pending repair lineage:

```bash
validate_pending_governance_repair_tree() {
  local repo_root="$1"
  local current_head="$2"
  [[ "${current_head}" != "${governance_repair_origin_sha}" ]] || \
    fail "fixed governance repair origin is not a valid current receipt"
  git -C "${repo_root}" merge-base --is-ancestor \
    "${governance_repair_origin_sha}" "${current_head}" || \
    fail "governance repair origin is not an ancestor of the candidate"
  require_linear_nonempty_repair_commits \
    "${repo_root}" "${governance_repair_origin_sha}" "${current_head}"
  require_exact_governance_repair_path_set \
    "${repo_root}" "${governance_repair_origin_sha}" "${current_head}"
  require_ledger_blob_equal \
    "${repo_root}" "${governance_repair_origin_sha}" "${current_head}"
}
```

This is not an ordinary receipt replay and must not make `d47c8c7...` a VSB-01 anchor. At `G`, static
output may report `GovernanceRepairStatus = PENDING`; no second state authority is created.

- [ ] **Step 3: Extend execution-state version contracts**

Version 1 retains the existing required fields. Version 2 additionally requires these five fields
exactly once:

```text
GovernanceRepairStatus
GovernanceRepairSpecSHA
GovernanceRepairOriginReceiptSHA
GovernanceRepairReviewedCandidateSHA
GovernanceRepairReviewRoute
GovernanceRepairReviewVerdict
```

All post-repair receipts must preserve their exact bytes/values. `ExecutionStateVersion` may change
only in the one `GOVERNANCE_REPAIR` transition from `1` to `2`; ordinary transitions require it
unchanged.

- [ ] **Step 4: Implement the repair transition dispatcher**

Add `GOVERNANCE_REPAIR` to both fixed transition and receipt-pair replay. Require:

```text
BASE is the final exact repair candidate G
HEAD is G's only child
HEAD diff is ledger-only
BASE ledger blob equals fixed d47 origin ledger blob
BASE repair chain is exact, linear and ledger-preserving
HEAD version is 2 and repair status PASS
spec/origin/reviewed candidate values are exact
route is deep_reviewer+ultra_gatekeeper
verdict is FINAL_GO_P0_0_P1_0_P2_0
sequence changes 2 -> 3
all VSB business state and authorization fields are preserved
```

Reject any `GOVERNANCE_REPAIR` when BASE version is not 1, BASE already has repair fields, HEAD
sequence is not 3, or any version 2 receipt already exists in ancestry.

- [ ] **Step 5: Make the repair receipt a legal VSB-01 release anchor**

Update the nearest-release replay so a fully valid `GOVERNANCE_REPAIR` receipt can release VSB-01.
The candidate walker must stop at this receipt and must never include the repair governance paths in
the VSB-01 candidate chain.

- [ ] **Step 6: Preserve terminal and Wave restore behavior**

Run targeted cases for `STOP_BY_USER`, `RETURN_TO_OWNER`, `FINAL_NO_GO`, `COMPLETE`, terminal static
state, terminal Wave restore and exact ten-path Wave-1 restore. No compatibility branch may bypass
NUL rejection, exact bytes, file mode or single-parent checks.

- [ ] **Step 7: Run focused GREEN**

Run once:

```bash
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh
```

Expected: PASS with counters that include every new real transition invocation and every new static
repair fixture. Preserve actual wall time and the final counter line in the ignored report.

- [ ] **Step 8: Commit implementation**

```bash
git add scripts/verify-visual-style-baseline-cards \
  tests/task-cards/verify-visual-style-baseline-cards.sh
git diff --cached --check
git commit -m "fix: add one-time VSB governance repair"
```

Expected: non-amend commit; ledger unchanged.

### Task 5: Converge, verify and fix governance candidate G

**Files:**
- Modify only when a real Gate or review finding requires it:
  - `docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md`
  - `docs/superpowers/plans/2026-08-13-cognitura-vsb-governance-repair.md`
  - `docs/task-cards/visual-style-baseline/README.md`
  - `scripts/verify-visual-style-baseline-cards`
  - `tests/task-cards/verify-visual-style-baseline-cards.sh`

- [ ] **Step 1: Verify exact repair-chain topology and WriteSet**

Run:

```bash
repair_origin_sha="d47c8c7bd7355947b5e8e1de6c264d80c2e27c9a"
repair_candidate_sha="$(git rev-parse HEAD)"
git rev-list --reverse --parents "${repair_origin_sha}..${repair_candidate_sha}"
git diff --no-renames --name-only "${repair_origin_sha}" "${repair_candidate_sha}"
git diff --no-renames --summary "${repair_origin_sha}" "${repair_candidate_sha}"
git diff --quiet "${repair_origin_sha}" "${repair_candidate_sha}" -- \
  docs/task-cards/visual-style-baseline/execution-state.md
```

Expected: every row has one parent; cumulative path set is exactly the five governance paths; no
rename/copy; ledger unchanged.

- [ ] **Step 2: Run the complete local convergence Gate once**

```bash
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh
/bin/bash tests/task-cards/verify-wave1-implementation-cards.sh
/bin/bash scripts/verify-visual-style-baseline-cards \
  --repo-root . --cards-dir docs/task-cards/visual-style-baseline
/bin/bash scripts/verify-wave1-implementation-cards \
  --repo-root . --cards-dir docs/task-cards/wave-1-implementation
/bin/bash tests/ci/verify-markdown-links.sh
/bin/bash -n scripts/verify-visual-style-baseline-cards
/bin/bash -n tests/task-cards/verify-visual-style-baseline-cards.sh
git diff --check
```

Expected: all PASS. Record every exact command, exit code and summary line in the ignored task report.

- [ ] **Step 3: Recheck frozen and prohibited paths**

```bash
git diff --quiet 4e63936c631ab34807e714b90d30415a959bc13d HEAD -- \
  server web schemas raw
git diff --quiet 70eefba5912e6884e4e7e1d6477a65f4091d6590 HEAD -- \
  docs/design/high-fidelity/evidence
git status --short
```

Expected: both diffs empty; only user-owned `?? .idea/` remains outside Git.

- [ ] **Step 4: Fix any Gate finding with RED -> GREEN and non-amend commit**

For each real finding, first add or tighten one failing fixture, record its exact failure, implement
the smallest correction inside the five-path repair WriteSet, rerun only the focused failed Gate,
then create a new non-amend commit. Never amend `G`; the newest fixed tip becomes the next candidate.

- [ ] **Step 5: Capture fixed candidate G**

```bash
repair_candidate_sha="$(git rev-parse HEAD)"
repair_candidate_parent_sha="$(git rev-parse HEAD^)"
repair_candidate_tree_sha="$(git rev-parse HEAD^{tree})"
printf 'G=%s\nParent=%s\nTree=%s\n' \
  "${repair_candidate_sha}" \
  "${repair_candidate_parent_sha}" \
  "${repair_candidate_tree_sha}"
```

Expected: fixed immutable G identifiers ready for independent review.

### Task 6: Obtain two independent fixed-SHA reviews

**Files:**
- No worktree changes during review.

- [ ] **Step 1: Run deep_reviewer on exact G**

Provide Base `d47c8c7...`, Candidate `G`, approved spec `2123594...`, exact five-path WriteSet, full
diff and Gate evidence. Require explicit:

```text
Verdict = GO
P0 = 0
P1 = 0
P2 = 0
```

Any finding returns to Task 5 Step 4 and creates a new non-amend tip followed by a completely fresh
review of the new SHA.

- [ ] **Step 2: Run ultra_gatekeeper on the same exact G**

Only after deep review is zero-finding, provide the identical immutable Candidate SHA and evidence to
`ultra_gatekeeper`. Require explicit:

```text
FinalVerdict = FINAL_GO
P0 = 0
P1 = 0
P2 = 0
```

Any finding returns to Task 5 Step 4 and invalidates both earlier review receipts for release use.

- [ ] **Step 3: Reconfirm HEAD before ledger write**

```bash
test "$(git rev-parse HEAD)" = "${repair_candidate_sha}"
git status --short
```

Expected: HEAD is exact reviewed G and only `?? .idea/` is present.

### Task 7: Create and verify ledger-only GOVERNANCE_REPAIR receipt R

**Files:**
- Modify: `docs/task-cards/visual-style-baseline/execution-state.md`

- [ ] **Step 1: Update the ledger from version 1 to version 2**

Use `apply_patch` to add the approved repair fields and change only:

```text
ExecutionStateVersion = 2
GovernanceRepairStatus = PASS
GovernanceRepairSpecSHA = 2123594540c91341c480f504949315a6abec316c
GovernanceRepairOriginReceiptSHA = d47c8c7bd7355947b5e8e1de6c264d80c2e27c9a
GovernanceRepairReviewedCandidateSHA = ${repair_candidate_sha}
GovernanceRepairReviewRoute = deep_reviewer+ultra_gatekeeper
GovernanceRepairReviewVerdict = FINAL_GO_P0_0_P1_0_P2_0
TransitionKind = GOVERNANCE_REPAIR
TransitionBaseSHA = ${repair_candidate_sha}
TransitionSequence = 3
```

Preserve VSB-01 active/released state, completed VSB-00 facts, reviewed business candidate
`737c053...`, all empty future receipts, `VisualImplementation = USER_AUTHORIZED`, DB and push
boundaries byte-for-byte.

- [ ] **Step 2: Verify the pre-commit ledger diff**

```bash
git diff --name-only
git diff -- docs/task-cards/visual-style-baseline/execution-state.md
git diff --check
```

Expected: exactly one modified path and only the approved version/repair/transition fields differ.

- [ ] **Step 3: Commit ledger-only receipt R**

```bash
git add docs/task-cards/visual-style-baseline/execution-state.md
git diff --cached --name-only
git commit -m "chore: repair visual baseline governance"
repair_receipt_sha="$(git rev-parse HEAD)"
test "$(git rev-parse HEAD^)" = "${repair_candidate_sha}"
```

Expected: R is G's direct single-parent child and changes only the execution ledger.

- [ ] **Step 4: Verify the explicit repair transition and static state**

```bash
/bin/bash scripts/verify-visual-style-baseline-cards \
  --repo-root . \
  --cards-dir docs/task-cards/visual-style-baseline \
  --transition-base "${repair_candidate_sha}" \
  --transition-head "${repair_receipt_sha}"
/bin/bash scripts/verify-visual-style-baseline-cards \
  --repo-root . --cards-dir docs/task-cards/visual-style-baseline
/bin/bash scripts/verify-wave1-implementation-cards \
  --repo-root . --cards-dir docs/task-cards/wave-1-implementation
git diff --check
git status --short
```

Expected:

```text
VisualStyleBaselineTaskCardValidation = PASS
TaskCardSetStatus = IN_PROGRESS
ActiveTaskCard = VSB-01
GovernanceRepairStatus = PASS
```

Wave 1 remains `SUSPENDED_BY_USER/NONE`; worktree contains only user-owned `?? .idea/`.

- [ ] **Step 5: Record the restored continuation boundary**

Treat R—not `d47c8c7...`—as the only VSB-01 release anchor. Resume VSB-01 from R using the approved
task card, cumulative candidate rule, RED → GREEN → Gates → local non-amend commit → fixed-SHA review.
Do not push and do not authorize any database write.

## 2. Plan self-review checklist

- [ ] Every approved design requirement maps to Tasks 1–7.
- [ ] No step rewrites history, amends, squashes, merges, pushes or writes a database.
- [ ] The failed origin receipt remains explicit invalid evidence.
- [ ] Ordinary candidates require both per-commit subset and cumulative exactness.
- [ ] Repair pending state is distinguishable from a valid ordinary receipt.
- [ ] Repair is one-time, fixed-origin, version 1 to 2, exact five-path and ledger-only at receipt.
- [ ] VSB-01 begins only from R, so governance paths cannot leak into its business candidate.
- [ ] All dynamic SHAs are captured from reviewed local commits; fixed authority SHAs are literal.
- [ ] `.idea/`, Wave 1 I03, high-fidelity evidence, production CSS/JSX, raw and schema paths remain untouched.
