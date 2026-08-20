# Cognitura W1-I04 Closure Implementation Plan

> **Execution rule:** implement this plan serially with test-driven development. Do not run
> concurrent full suites or modify the closure receipt before the fixed governance candidate is GO.

**Goal:** Record the reviewed W1-I04 candidate, close I04, and release I05 as the sole READY card.

**Architecture:** Add one four-path governance chain rooted at
`4594406e9fd8a9ac380c3b2b880fda67271790bc`, followed by one direct-child eleven-path
projection receipt. Keep the Git inferred-copy correction local to W1-I04 synthetic XML fixtures.
Do not add a generic state machine or another ledger.

**Spec:** `docs/superpowers/specs/2026-08-20-cognitura-w1-i04-closure-design.md`

## Global constraints

- `ReviewedCandidateSHA = 4594406e9fd8a9ac380c3b2b880fda67271790bc`.
- Review is `L3/deep_reviewer/xhigh/ONE/GO`, `P0=P1=P2=0`, `Ultra=NOT_RUN`.
- W1-I04 production is immutable after the reviewed candidate.
- W1-I02 remains `QUEUED`; formal database writes and remote push remain unauthorized.
- Do not read or modify `raw/**`, `.idea/**`, `temp-input/**`, or `dist/**`.
- Governance commits touch only the exact four paths; the receipt touches only the exact eleven.

---

### Task 1: Commit the execution plan

**Files:**
- Create: `docs/superpowers/plans/2026-08-20-cognitura-w1-i04-closure.md`

- [ ] Verify there are no placeholders and `git diff --check` passes.
- [ ] Stage only this plan.
- [ ] Commit with `docs: plan W1-I04 closure transition`.

### Task 2: Extend the focused tests-only contract

**Files:**
- Modify: `tests/task-cards/verify-wave1-implementation-cards.sh`

- [ ] Add `--w1-i04-closure-contract-only` without changing existing public production CLI.
- [ ] Build a shared-clone governance fixture from the fixed origin. Materialize the design, plan,
      tests and production verifier in canonical order with exact modes and one path per commit.
- [ ] Build a direct-child receipt that changes the exact eleven projection paths, sets I04 DONE,
      I05 READY and `BusinessImplementationAuthorization=USER_AUTHORIZED`, and appends the exact
      review block.
- [ ] Assert PENDING, explicit PASS and static PASS through the public verifier.
- [ ] Cover every governance, receipt, review-block, authorization, history, working-mask and
      cleanup negative class from the design using real Git commits.
- [ ] Retain the literal `C100` XML positive, non-XML `C100` negative and `R100` negative for the
      narrow classifier correction.
- [ ] Run Bash syntax and the focused test once against old production. The first legal I04 PENDING
      state must fail because `W1I04ClosureStatus` is absent.
- [ ] Stage only the test script and commit with `test: define W1-I04 closure transition`.

### Task 3: Implement the production GREEN

**Files:**
- Modify: `scripts/verify-wave1-implementation-cards`

- [ ] Add fixed origin/candidate identities, exact four governance paths, exact eleven projection
      paths and expected modes.
- [ ] Validate every governance commit as single-parent, nonempty, single-touch, no NUL/mode drift,
      no real rename/copy, and cumulative exact-four. Keep product, projections and ledger frozen.
- [ ] Keep the inferred XML fixture-copy exception exactly within the design predicate and local to
      post-I03 W1-I04 descendants. All actual renames and other copies remain forbidden.
- [ ] Add the early I04 PENDING static branch before ordinary W1-I04 WriteSet validation.
- [ ] Add `I04_CLOSE_ADVANCE` explicit validation: direct child, exact eleven paths, preserved modes,
      exact states/narratives/review block, unchanged I02/database/push and frozen product.
- [ ] Add static replay, exactly-once closure and per-commit post-receipt projection history checks.
- [ ] Run the I04 focused contract to GREEN, both Bash syntax checks and `git diff --check`.
- [ ] Run the affected full Wave1 suite once after the tree is stable.
- [ ] Stage only the production verifier and commit with `feat: verify W1-I04 closure transition`.

### Task 4: Review the fixed governance candidate

**Files:**
- Read-only: the fixed four-path governance chain and all referenced Git objects.

- [ ] Freeze Candidate, Parent and Tree plus the origin-exclusive commit list.
- [ ] Verify exact-four cumulative paths, canonical order, modes, no R/C/NUL, frozen reviewed product,
      unchanged VSB ledger and unchanged authorization boundaries.
- [ ] Request one `deep_reviewer/xhigh/ONE` review; Ultra remains `NOT_RUN`.
- [ ] Resolve every finding inside the exact four governance paths with RED/GREEN evidence.
- [ ] Proceed only with `GO/P0=0/P1=0/P2=0`.

### Task 5: Create the eleven-path closure receipt

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
- Modify: `docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md`
- Modify: `docs/task-cards/wave-1-implementation/W1-I05-table-fidelity.md`

- [ ] Set I04 DONE, I05 READY, all active projections to I05, Ready count to one, and I05 business
      authorization to USER_AUTHORIZED. Keep I02 queued and database/push boundaries unchanged.
- [ ] Append the exact ordered I04 review block to the implementation plan.
- [ ] Stage exactly the eleven paths and commit `chore: close W1-I04 and release W1-I05`.
- [ ] Run explicit and static receipt replay.
- [ ] Run focused/full Wave1, VSB static, JDK 21 I04 tests, tracked-archive Markdown validation,
      Bash syntax and `git diff --check` without push.
- [ ] Confirm public output contains `W1I04ClosureStatus = PASS` and `ActiveTaskCard = W1-I05`.

Stop before modifying any W1-I05 product path. I02 remains behind its independent database Gate.
