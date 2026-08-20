# Cognitura W1-I05 Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bind the reviewed W1-I05 candidate to one atomic projection that closes I05 and releases I06 as the sole READY card.

**Architecture:** Extend the existing Wave 1 task-card verifier with one bounded I05 transition contract. The contract accepts only a direct-child, exact-eleven projection from I05 READY/I06 blocked to I05 DONE/I06 READY, preserves frozen product bytes and authorization boundaries, and then admits only I06 WriteSet descendants.

**Tech Stack:** Bash 3.2, Git object inspection, Markdown task-card projections.

**Spec:** `docs/task-cards/wave-1-implementation/W1-I05-table-fidelity.md`

## Global Constraints

- Reviewed W1-I05 candidate: `b4132e988cd88dce74ae026a1b52a496188452fc`.
- One `deep_reviewer / gpt-5.6-sol / xhigh / ONE` review before the closure receipt; Ultra remains `NOT_RUN`.
- Preserve I02 as `QUEUED`; formal database writes and remote push remain `NOT_AUTHORIZED`.
- Do not touch `raw/**`, `.idea/**`, deployment, database state, or Git history.
- Do not add a generic lifecycle engine, second execution ledger, or Omin Harness integration.

---

### Task 1: Define the transition contract with RED evidence

**Files:**
- Modify: `tests/task-cards/verify-wave1-implementation-cards.sh`

**Interfaces:**
- Consumes: `scripts/verify-wave1-implementation-cards --transition-base SHA --transition-head SHA`.
- Produces: real-Git acceptance/rejection evidence for the I05 closure transition.

- [ ] **Step 1: Add a legal direct-child fixture**

  Materialize the exact eleven projection paths, set I05 `DONE`, I06 `READY`, bind the receipt to the reviewed candidate, preserve I02/database/push boundaries, and expect `W1I05ClosureStatus = PASS`.

- [ ] **Step 2: Add mutation killers**

  Reject a wrong reviewed SHA, missing/extra projection path, non-direct receipt, second READY card, missing I06 authorization, changed I05 production byte, and post-receipt projection replay.

- [ ] **Step 3: Run RED**

  Run: `bash tests/task-cards/verify-wave1-implementation-cards.sh`

  Expected: nonzero exit because the production verifier does not yet recognize I05 DONE/I06 READY.

- [ ] **Step 4: Commit RED**

  Commit only the test script with `test: define W1-I05 closure transition`.

### Task 2: Implement the minimal verifier GREEN

**Files:**
- Modify: `scripts/verify-wave1-implementation-cards`

**Interfaces:**
- Consumes: fixed reviewed candidate, Git transition pair, eleven projection paths.
- Produces: `W1I05ClosureStatus = PENDING|PASS` and I06 descendant admission.

- [ ] **Step 1: Validate the exact transition**

  Require a single-parent receipt, exact path/mode set, I05 DONE/I06 READY, one READY card, I06 `USER_AUTHORIZED`, exact review receipt, unchanged I05 product bytes, and preserved I02/database/push state.

- [ ] **Step 2: Admit only I06 descendants**

  After the receipt, reject any repeated closure projection or path outside the declared I06 WriteSet.

- [ ] **Step 3: Run GREEN and regression**

  Run Bash syntax checks, the task-card contract suite, `scripts/verify-wave1-implementation`, and `git diff --check`; all must exit zero.

- [ ] **Step 4: Commit GREEN**

  Commit only the production verifier with `feat: verify W1-I05 closure transition`.

### Task 3: Review and apply the atomic receipt

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
- Modify: `docs/task-cards/wave-1-implementation/W1-I05-table-fidelity.md`
- Modify: `docs/task-cards/wave-1-implementation/W1-I06-image-anchor-relationship-projection.md`

**Interfaces:**
- Consumes: zero-finding review of the fixed verifier candidate.
- Produces: I05 `DONE`, I06 `READY`, and an exact I05 closure receipt.

- [ ] **Step 1: Freeze and review the verifier candidate**

  Record Candidate/Parent/Tree and obtain one `deep_reviewer/xhigh/ONE` `GO` with P0/P1/P2 all zero.

- [ ] **Step 2: Apply the exact projection**

  Change only I05/I06 active-state narratives and fields, append the exact review receipt, preserve I02/database/push boundaries, and set I06 business authorization to `USER_AUTHORIZED`.

- [ ] **Step 3: Commit the direct-child receipt**

  Commit exactly the eleven projection paths with `chore: close W1-I05 and release W1-I06`.

- [ ] **Step 4: Verify the fixed receipt**

  Run explicit transition replay, static verification, the full Wave 1 implementation gate, I05 product tests, tracked Markdown, Bash syntax, `git diff --check`, and final Git status. Stop before I06 product implementation.
