# Cognitura W1-I04 Closure Successor Plan

**Goal:** Close the two findings on the rejected I04 closure candidate, bind the completion Gate to
the fixed legal VSB restore snapshot, complete the required mutation matrix, then review and apply
the unchanged exact-eleven receipt.

**Spec:** `docs/superpowers/specs/2026-08-20-cognitura-w1-i04-closure-successor-design.md`

## Constraints

- Origin: `e5c882f072db62d22b4de32b0aacb1d720a02154`.
- Rejected predecessor candidate: `eb6613e66d5ac1c03d033a814c2413cc0c883226`
  (`NO_GO / P1=2`), retained immutably.
- Product review candidate: `4594406e9fd8a9ac380c3b2b880fda67271790bc`.
- Fixed legal VSB restore snapshot: `cc25439de8019a4434c2ab5aba8b32927240d8b4`.
- Fixed VSB ledger blob: `9e47af9f6047f4586f960b1512098c6cb8efc864`, mode `100644`.
- The predecessor 4-positive/42-negative test matrix is preserved and expanded to 4 positive and
  49 negative cases.
- Product, projection, VSB ledger, I02, database and push boundaries remain frozen.
- No amend, reset, raw input access, `.idea` access, database action, deploy or push.

### Task 1: Commit this plan

- [ ] Verify no placeholders and `git diff --check`.
- [ ] Commit only this file with `docs: plan W1-I04 closure successor`.

### Task 2: Rebind the fixed tests

**File:** `tests/task-cards/verify-wave1-implementation-cards.sh`

- [ ] Change the I04 closure origin to the successor origin.
- [ ] Replace predecessor design/plan paths with successor design/plan paths.
- [ ] Add independent real-Git negatives for governance empty/reorder and receipt non-direct,
  rename/copy/NUL/mode; retain all prior cases, exact 4 positive/49 negative and TMP cleanup.
- [ ] Run Bash syntax and focused RED against production still bound to the predecessor topology.
- [ ] Commit only the test script with `test: bind W1-I04 closure successor`.

### Task 3: Implement successor production GREEN

**File:** `scripts/verify-wave1-implementation-cards`

- [ ] Bind origin and governance paths to the successor.
- [ ] Keep the narrow inferred XML copy predicate unchanged.
- [ ] Keep exact-four governance, exact-eleven receipt, mechanical normalization, review receipt,
  product/working freeze and post-receipt history checks unchanged.
- [ ] Require the fixed VSB restore snapshot to exist with the exact identity and public-static PASS.
- [ ] Require the VSB ledger blob/mode at product, origin, every governance commit, receipt and
  working tree to equal the fixed values; do not claim current-descendant VSB static PASS.
- [ ] Run I04 focused 4/49 and I03 focused 5/65, both Bash syntax checks and diff check.
- [ ] Run the full Wave1 task-card suite once on the stable tree.
- [ ] Commit only production with `feat: verify W1-I04 closure successor`.

### Task 4: Fixed governance review

- [ ] Freeze Candidate/Parent/Tree and prove the origin-exclusive exact-four canonical chain.
- [ ] Run one `deep_reviewer/xhigh/ONE` review; Ultra remains `NOT_RUN`.
- [ ] Proceed only with GO and P0/P1/P2 all zero.

### Task 5: Exact-eleven receipt

- [ ] Apply the predecessor design's unchanged mechanical I04 DONE/I05 READY projection.
- [ ] Append the exact I04 review block bound to the product candidate.
- [ ] Commit the direct-child exact-eleven receipt.
- [ ] Run explicit/static replay, focused/full Wave1, JDK 21 I04 tests, public VSB static from the
  fixed restore snapshot, current ledger identity/mode, tracked Markdown, Bash syntax and diff check.
- [ ] Stop before any W1-I05 product change; remote push remains unauthorized.
