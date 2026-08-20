# Cognitura W1-I04 Closure Successor Design

```text
CanonicalProjectName = Cognitura
DesignKind = ONE_TIME_W1_I04_CLOSURE_SUCCESSOR
TransitionKind = I04_CLOSE_ADVANCE
ClosureOriginSHA = f9bef5a7f45ccd104d65b475f8bdabc6d2e6b9db
ReviewedCandidateSHA = 4594406e9fd8a9ac380c3b2b880fda67271790bc
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
Ultra = NOT_RUN
```

## 1. Supersession boundary

This document supersedes only the governance-chain topology in
`2026-08-20-cognitura-w1-i04-closure-design.md`. The predecessor design, plan and two tests-only
commits remain immutable historical evidence of the initial RED and completed mutation matrix.
They are before `ClosureOriginSHA` and are not replayed as the successor governance chain.

All product, receipt, review, authorization, copy-classifier and test semantics from the predecessor
design remain authoritative without change. In particular, the reviewed product candidate remains
`4594406e9fd8a9ac380c3b2b880fda67271790bc`; W1-I04 production, the VSB ledger, W1-I02,
formal database and push boundaries remain byte-identical from that candidate through this origin.

The successor is necessary because the project forbids amending the original tests-only RED commit.
It records the expanded 4-positive/42-negative matrix without rewriting history and does not add a
product feature, generic lifecycle mechanism, or second ledger.

## 2. Successor four-path chain

Starting at `ClosureOriginSHA`, exactly four nonempty single-parent commits must change one path each
in this canonical order:

```text
docs/superpowers/specs/2026-08-20-cognitura-w1-i04-closure-successor-design.md
docs/superpowers/plans/2026-08-20-cognitura-w1-i04-closure-successor.md
tests/task-cards/verify-wave1-implementation-cards.sh
scripts/verify-wave1-implementation-cards
```

The two documents are `100644`; the scripts are `100755`. No path may change twice. Each commit must
be nonempty, NUL-free and free of rename/copy or mode drift. The cumulative set is exact four.
The tests commit only rebinds the already-complete matrix to this successor origin and paths; it may
not remove a positive or negative case.

At the successor tip the state remains I04 READY/I05 blocked and static output is
`W1I04ClosureStatus = PENDING`. The reviewed W1-I04 product, eleven receipt projections, VSB ledger
and prior W1 production remain unchanged.

## 3. Receipt and completion

After one `deep_reviewer/xhigh/ONE` zero-finding review of the fixed successor tip, the only legal
receipt is the direct-child exact-eleven projection defined by the predecessor design. It closes I04,
sets I05 READY with `BusinessImplementationAuthorization=USER_AUTHORIZED`, preserves I02 queued and
keeps formal database writes and remote push unauthorized.

The fixed review block continues to bind `ReviewedCandidate` to the product candidate, not to this
governance tip. Explicit/static replay, full Wave1 tests, JDK 21 product tests, VSB static, tracked
Markdown and `git diff --check` must pass before I04 is considered complete.
