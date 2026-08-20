# Cognitura W1-I04 Closure Successor Plan

**Goal:** Rebind the completed I04 closure contract to a clean four-path governance prefix without
amending historical RED commits, then review and apply the unchanged exact-eleven receipt.

**Spec:** `docs/superpowers/specs/2026-08-20-cognitura-w1-i04-closure-successor-design.md`

## Constraints

- Origin: `f9bef5a7f45ccd104d65b475f8bdabc6d2e6b9db`.
- Product review candidate: `4594406e9fd8a9ac380c3b2b880fda67271790bc`.
- The predecessor 4-positive/42-negative test matrix is preserved; only its fixed origin and
  governance paths change.
- Product, projection, VSB ledger, I02, database and push boundaries remain frozen.
- No amend, reset, raw input access, `.idea` access, database action, deploy or push.

### Task 1: Commit this plan

- [ ] Verify no placeholders and `git diff --check`.
- [ ] Commit only this file with `docs: plan W1-I04 closure successor`.

### Task 2: Rebind the fixed tests

**File:** `tests/task-cards/verify-wave1-implementation-cards.sh`

- [ ] Change the I04 closure origin to the successor origin.
- [ ] Replace predecessor design/plan paths with successor design/plan paths.
- [ ] Retain exactly 4 positive and 42 negative cases, real Git fixtures and TMP cleanup.
- [ ] Run Bash syntax and focused RED against production still bound to the predecessor topology.
- [ ] Commit only the test script with `test: bind W1-I04 closure successor`.

### Task 3: Implement successor production GREEN

**File:** `scripts/verify-wave1-implementation-cards`

- [ ] Bind origin and governance paths to the successor.
- [ ] Keep the narrow inferred XML copy predicate unchanged.
- [ ] Keep exact-four governance, exact-eleven receipt, mechanical normalization, review receipt,
  product/working freeze and post-receipt history checks unchanged.
- [ ] Run I04 focused 4/42 and I03 focused 5/65, both Bash syntax checks and diff check.
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
- [ ] Run explicit/static replay, focused/full Wave1, JDK 21 I04 tests, VSB static, tracked Markdown,
  Bash syntax and diff check.
- [ ] Stop before any W1-I05 product change; remote push remains unauthorized.
