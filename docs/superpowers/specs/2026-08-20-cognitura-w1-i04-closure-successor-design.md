# Cognitura W1-I04 Closure Successor Design

```text
CanonicalProjectName = Cognitura
DesignKind = ONE_TIME_W1_I04_CLOSURE_SUCCESSOR
TransitionKind = I04_CLOSE_ADVANCE
ClosureOriginSHA = eb6613e66d5ac1c03d033a814c2413cc0c883226
RejectedClosureCandidateSHA = eb6613e66d5ac1c03d033a814c2413cc0c883226
ReviewedCandidateSHA = 4594406e9fd8a9ac380c3b2b880fda67271790bc
VSBTerminalRestoreSHA = cc25439de8019a4434c2ab5aba8b32927240d8b4
VSBExecutionLedgerBlob = 9e47af9f6047f4586f960b1512098c6cb8efc864
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

This revision supersedes the rejected fixed candidate recorded by
`RejectedClosureCandidateSHA`. That candidate remains immutable `NO_GO / P1=2` evidence: its
completion Gate required current-descendant VSB static replay even though the VSB terminal contract
only accepts the terminal receipt or its exact Wave 1 restore, and its focused matrix omitted seven
required mutation killers. The earlier predecessor design, plans, RED commits and rejected
candidate remain historical evidence before `ClosureOriginSHA`; none is amended or replayed as the
new successor governance chain.

All product, receipt, review, authorization, copy-classifier and test semantics from the predecessor
design remain authoritative without change. In particular, the reviewed product candidate remains
`4594406e9fd8a9ac380c3b2b880fda67271790bc`; W1-I04 production, the VSB ledger, W1-I02,
formal database and push boundaries remain byte-identical from that candidate through this origin.

The successor records the expanded 4-positive/49-negative matrix without rewriting history and does
not add a product feature, generic lifecycle mechanism, VSB transition, or second ledger.

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
The tests commit rebinds the existing matrix to this successor origin and adds independent real-Git
negatives for an empty and reordered governance commit plus a non-direct receipt and receipt
rename/copy/NUL/mode drift. It may not remove an existing positive or negative case.

At the successor tip the state remains I04 READY/I05 blocked and static output is
`W1I04ClosureStatus = PENDING`. The reviewed W1-I04 product, eleven receipt projections, VSB ledger
and prior W1 production remain unchanged.

## 3. Receipt and completion

After one `deep_reviewer/xhigh/ONE` zero-finding review of the fixed successor tip, the only legal
receipt is the direct-child exact-eleven projection defined by the predecessor design. It closes I04,
sets I05 READY with `BusinessImplementationAuthorization=USER_AUTHORIZED`, preserves I02 queued and
keeps formal database writes and remote push unauthorized.

The fixed review block continues to bind `ReviewedCandidate` to the product candidate, not to this
governance tip. Explicit/static replay, full Wave1 tests, JDK 21 product tests, tracked Markdown and
`git diff --check` must pass before I04 is considered complete.

The VSB completion Gate is deliberately snapshot-bound rather than a current-descendant replay. The
public VSB verifier must PASS from an isolated checkout of the fixed exact Wave 1 restore
`VSBTerminalRestoreSHA`. The VSB execution ledger must remain `100644` with the exact
`VSBExecutionLedgerBlob` at the reviewed product, `ClosureOriginSHA`, every successor governance
commit, the closure receipt and the working tree. Current-tree VSB static is not substituted or
claimed: its terminal topology intentionally rejects later Wave 1 descendants. Any snapshot identity
drift, verifier failure, ledger byte/mode drift or working-tree mask blocks completion.
