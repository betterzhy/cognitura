# Cognitura Wave 1 Design Review Repairs Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the three Wave 1 fixed-design review findings without creating implementation cards or business code.

**Architecture:** Reopen only W1-D05, first change the contract verifiers so the current incorrect contracts fail, then make the smallest contract and governance corrections. Preserve all source-safety, immutable-reference, partial-acceptance, exact-revision and atomic-publication boundaries.

**Tech Stack:** Markdown formal contracts, Bash contract verifiers, Git local commits.

## Global Constraints

- `BusinessImplementation = NOT_AUTHORIZED`.
- Do not create `W1-Ixx`, an implementation plan, Java/TypeScript business code, DDL, Provider selection, deployment configuration or remote pushes.
- Do not read or modify the three `raw/` DOCX originals and do not dereference any legacy local/external link.
- W1-D05 uses two independent `gpt-5.6-sol/high` review stages; ultra is not used.
- Preserve the untracked `.idea/` directory and unrelated user changes.

---

### Task 1: Reopen the bounded W1-D05 repair loop

**Files:**
- Modify: `docs/task-cards/wave-1/W1-D05-fixed-design-review.md`
- Modify: `docs/task-cards/wave-1/README.md`
- Modify: `AGENTS.md`
- Modify: `README.md`
- Modify: `docs/engineering/cognitura-wave-1-design-plan.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/design/wave-1/README.md`
- Modify: `docs/engineering/cognitura-wave-1-design-acceptance.md`

**Interfaces:**
- Consumes: the read-only optimization review findings against candidate `3efe89fa532b7d58d7915dc891732dfdf5f4ee55`.
- Produces: W1-D05 as the sole `READY` design card with W1-DG5 reopened and business implementation still forbidden.

- [x] **Step 1: Record the three review findings and the user-authorized repair boundary in W1-D05.**
- [x] **Step 2: Expand the repair write set only for the D00 governance spec, two contract verifiers, this repair plan and required status projections.**
- [x] **Step 3: Synchronize the task-card index and stable status projections to `WAVE1_DESIGN_REVIEW_REPAIR_IN_PROGRESS`.**
- [x] **Step 4: Run `bash tests/task-cards/verify-wave1-design-cards.sh` and confirm the reopened state is accepted.**

### Task 2: Permit section-scoped Wave 2 consumption

**Files:**
- Modify: `tests/contracts/wave1-design/verify-reparse-reference-contract.sh`
- Modify: `docs/design/wave-1/cognitura-reparse-reference-contract-1.0.md`

**Interfaces:**
- Consumes: exact immutable `DocumentBlockRef` tuples from one processing revision.
- Produces: a Wave 2 consumer boundary that permits an explicit `DocumentSectionScope` whose first `sourceOrder` may be non-zero while preserving same-revision scope, uniqueness and strict order.

- [x] **Step 1: Change the verifier to require `EXPLICIT_DOCUMENT_SECTION`, `CONTIGUOUS_SOURCE_ORDER_WITHIN_SECTION_SCOPE` and a non-zero section start allowance; add mutations for whole-revision-only and unordered selection.**
- [x] **Step 2: Run `bash tests/contracts/wave1-design/verify-reparse-reference-contract.sh`.**

Expected: FAIL because the current D03 contract still requires an entire revision beginning at `sourceOrder=0`.

- [x] **Step 3: Replace the whole-document constraint in D03 with the minimal section-scoped boundary; leave section derivation and coverage to Wave 2.**
- [x] **Step 4: Run the same verifier.**

Expected: PASS, including the new negative cases.

### Task 3: Close the PENDING attempt timeout path

**Files:**
- Modify: `tests/contracts/wave1-design/verify-source-document-contract.sh`
- Modify: `docs/design/wave-1/cognitura-source-document-contract-1.0.md`

**Interfaces:**
- Consumes: the existing active attempt identity, attempt generation and lease fields.
- Produces: a legal `PENDING -> FAILED_RETRYABLE` transition on unclaimed lease expiry, with the same atomic revision cleanup as RUNNING lease expiry.

- [x] **Step 1: Update the verifier to require the PENDING timeout transition and add a mutation that removes it.**
- [x] **Step 2: Run `bash tests/contracts/wave1-design/verify-source-document-contract.sh`.**

Expected: FAIL because the current transition set has no PENDING failure exit.

- [x] **Step 3: Add the transition and specify that PENDING uses `leaseExpiresAt` as a claim deadline, cannot heartbeat, and expires atomically with the revision.**
- [x] **Step 4: Run the same verifier.**

Expected: PASS, including the new negative case.

### Task 4: Align W1-DG5 candidate completeness with the approval boundary

**Files:**
- Modify: `docs/superpowers/specs/2026-07-30-wave1-source-ingestion-governance-design.md`
- Modify: `tests/task-cards/verify-wave1-design-cards.sh`
- Modify: `scripts/verify-wave1-design-cards`
- Modify: `docs/task-cards/wave-1/W1-D05-fixed-design-review.md`
- Modify: `docs/engineering/cognitura-wave-1-design-acceptance.md`

**Interfaces:**
- Consumes: the rule that implementation plans/cards may only be created after explicit user approval.
- Produces: a D05 candidate requirement that contains no premature implementation-card recommendation list.

- [x] **Step 1: Add a task-card contract mutation that rejects a D05 card which claims an implementation recommendation list is required before user approval.**
- [x] **Step 2: Run `bash tests/task-cards/verify-wave1-design-cards.sh`.**

Expected: FAIL until D05 and D00 explicitly place implementation slicing after user approval.

- [x] **Step 3: Remove the premature candidate-list requirement from D00 and record that implementation slicing occurs only after approval.**
- [x] **Step 4: Update D05 and the acceptance record to identify the prior Gate result as superseded by the repair review.**
- [x] **Step 5: Run the task-card contract test again.**

Expected: PASS.

### Task 5: Verify, fix the candidate, review and close

**Files:**
- Modify: the status projection files from Task 1.
- Modify: `docs/task-cards/wave-1/W1-D05-fixed-design-review.md`
- Modify: `docs/engineering/cognitura-wave-1-design-acceptance.md`

**Interfaces:**
- Consumes: corrected formal contracts and passing verifiers.
- Produces: a new fixed local commit, two independent zero-finding reviews, and a local closure commit.

- [x] **Step 1: Run `scripts/verify-wave1-design`, `scripts/verify-wave0`, `git diff --check` and inspect `git status --short`.**
- [ ] **Step 2: Commit the repair candidate locally without `.idea/`.**
- [ ] **Step 3: Run an independent `gpt-5.6-sol/high` general review on the exact commit.**

Candidate `b1d4f78ed98fbe108358a8b07cc7681bea9ffd69` returned
`NOT_READY / P1=1`; the final Gate did not start. The next candidate must bind lease expiry
CAS to the observed attempt status and lease value, then restart this step.
- [ ] **Step 4: If and only if the general review is zero-finding, run a separate `gpt-5.6-sol/high` final Gate.**
- [ ] **Step 5: Synchronize W1-DG5 and all status projections to the actual result, rerun all verification and create a local closure commit.**
- [ ] **Step 6: Confirm no remote push occurred and report exact SHAs, Gate evidence and remaining authorization boundary.**
