# Cognitura W1-I05 Verifier Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Admit one fixed verifier-recovery chain after the I04 closure receipt, then restore the exact I05-only descendant rule.

**Architecture:** The production verifier recognizes one immutable five-path recovery prefix rooted at `01cc567f31c104da2cc5699f3cb487324fae7963`. It validates every recovery commit and then applies the existing I05 WriteSet rule to every later descendant; no reusable exception field or maintenance lane is added.

**Tech Stack:** Bash 3.2, Git commit/tree/diff plumbing, real-Git fixture repositories.

**Spec:** `docs/superpowers/specs/2026-08-20-cognitura-w1-i05-verifier-recovery-design.md`

## Global Constraints

- `RecoveryOriginSHA = 01cc567f31c104da2cc5699f3cb487324fae7963`.
- `RequiredFirstRecoveryCommitSHA = ac42f26230cec348f3933400d8cd581c6e27970d`.
- The recovery prefix changes exactly five declared paths, each exactly once.
- W1-I05 implementation paths may change only after the recovery tip.
- W1-I04 production and closure projections remain byte-identical.
- `FormalDatabaseWrite = NOT_AUTHORIZED`; `RemotePush = NOT_AUTHORIZED`.
- Do not read or modify `raw/**`, `.idea/**`, or `temp-input/**`.
- Use one `deep_reviewer / xhigh` fixed-candidate review; do not run Ultra.

---

### Task 1: Add the real-Git recovery contract RED

**Files:**
- Modify: `tests/task-cards/verify-wave1-implementation-cards.sh`

**Interfaces:**
- Consumes: the fixed origin, the existing first recovery commit, and the public production verifier.
- Produces: `--w1-i05-verifier-recovery-contract-only` and real-Git positive/negative fixtures.

- [ ] **Step 1: Add the focused test entry**

Add `w1_i05_verifier_recovery_contract_only=0`, accept
`--w1-i05-verifier-recovery-contract-only`, invoke
`run_w1_i05_verifier_recovery_contract`, and exit before unrelated suites.

- [ ] **Step 2: Build the legal recovery prefix**

Clone the repository with `--shared`, detach at
`ac42f26230cec348f3933400d8cd581c6e27970d`, and commit the remaining four
recovery paths one at a time in specification order. Before production GREEN,
append a fixture-only comment to the copied production verifier when its blob is
still equal to the origin so the fifth commit remains non-empty.

- [ ] **Step 3: Exercise public behavior**

Run the copied verifier against the fixture repository and require:

```text
Wave1ImplementationTaskCardValidation = PASS
ActiveTaskCard = W1-I05
W1I05VerifierRecoveryStatus = PASS
```

Then commit a legal synthetic I05 table path and require the same PASS result.

- [ ] **Step 4: Add fail-closed mutations**

Use separate real commits for wrong first recovery commit, missing path, extra path,
repeated recovery path, merge, rename/copy, mode drift, I05 path before recovery
completion, and outside path after recovery completion. Assert stable diagnostics and
temporary-directory cleanup.

- [ ] **Step 5: Run the focused RED**

```bash
/bin/bash -n tests/task-cards/verify-wave1-implementation-cards.sh
/bin/bash tests/task-cards/verify-wave1-implementation-cards.sh \
  --w1-i05-verifier-recovery-contract-only
```

Expected: failure because the production verifier still reports
`post-I04-closure descendant changed a path outside the W1-I05 WriteSet`.

- [ ] **Step 6: Commit the tests-only RED**

```bash
git add tests/task-cards/verify-wave1-implementation-cards.sh
git diff --cached --check
git commit -m "test: define W1-I05 verifier recovery"
```

### Task 2: Implement the one-time recovery GREEN

**Files:**
- Modify: `scripts/verify-wave1-implementation-cards`

**Interfaces:**
- Consumes: the real-Git contract from Task 1.
- Produces: `validate_w1_i05_verifier_recovery_and_descendants <receipt> <head>`.

- [ ] **Step 1: Declare immutable recovery identity and path set**

Add the fixed origin and first-recovery SHA constants plus an exact five-path predicate.
Do not add a card field, environment override, wildcard docs path, or generic infra path.

- [ ] **Step 2: Validate the recovery prefix**

Enumerate first-parent descendants from the I04 receipt. Require the first descendant
to be the fixed first recovery SHA. Until all five recovery paths have changed exactly
once, require single-parent non-empty commits, no rename/copy, preserved modes, no NUL,
and only an as-yet-unseen recovery path. The first complete cumulative set is the
unique recovery tip.

- [ ] **Step 3: Restore the I05-only rule after the tip**

For every later descendant, reuse the current I05 path predicate and reject recovery
paths, closure projections, or other paths. Preserve the existing I04 frozen-production
and working-projection checks.

- [ ] **Step 4: Wire the static I04 DONE/I05 READY branch**

Replace the direct descendant validator call with the recovery-aware function and add:

```text
W1I05VerifierRecoveryStatus = PASS
```

to the successful output.

- [ ] **Step 5: Run focused GREEN and full affected regression**

```bash
/bin/bash -n scripts/verify-wave1-implementation-cards
/bin/bash -n tests/task-cards/verify-wave1-implementation-cards.sh
/bin/bash tests/task-cards/verify-wave1-implementation-cards.sh \
  --w1-i05-verifier-recovery-contract-only
/bin/bash tests/task-cards/verify-wave1-implementation-cards.sh
scripts/verify-wave1-implementation
git diff --check
```

- [ ] **Step 6: Commit the production GREEN**

```bash
git add scripts/verify-wave1-implementation-cards
git diff --cached --check
git commit -m "fix: recover W1-I05 verifier gate"
```

### Task 3: Freeze and review the recovery candidate

**Files:**
- Read-only review of the five-path recovery chain.

**Interfaces:**
- Consumes: fixed Candidate/Parent/Tree and focused/full Gate evidence.
- Produces: one `deep_reviewer / xhigh / ONE` verdict.

- [ ] **Step 1: Record candidate identity and changed paths**

```bash
git rev-parse HEAD HEAD^ HEAD^{tree}
git log --format='%H %P' \
  01cc567f31c104da2cc5699f3cb487324fae7963..HEAD
git diff --name-status \
  01cc567f31c104da2cc5699f3cb487324fae7963..HEAD
```

- [ ] **Step 2: Request one independent xhigh review**

The reviewer checks Bash 3.2 compatibility, fixed-prefix provenance, first-parent
topology, exact path counts, post-tip I05 restriction, protected I04 state, working-tree
masking, and negative fixture strength. Any P0/P1 finding returns to RED; zero findings
authorizes the separate I05 candidate.

- [ ] **Step 3: Continue the existing I05 task card**

Run the I05 focused and server regressions, unified Gate, exact WriteSet staging, local
commit, and one new fixed-SHA `deep_reviewer / xhigh` review. Do not close I05 or release
I06 until that product review is zero-finding.
