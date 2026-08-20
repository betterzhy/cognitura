# Cognitura W1-I04 Closure Design

```text
CanonicalProjectName = Cognitura
DesignKind = ONE_TIME_W1_I04_CLOSURE
TransitionKind = I04_CLOSE_ADVANCE
ClosureOriginSHA = 4594406e9fd8a9ac380c3b2b880fda67271790bc
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
ReleasedTaskCard = W1-I05
QueuedTaskCard = W1-I02
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. Purpose and authority

This design records the fixed W1-I04 product review, corrects one Git copy-classifier
false positive without weakening actual rename/copy rejection, and defines the only legal
projection-only transition that closes I04 and releases I05. It does not introduce a generic
state machine, a second ledger, table-parser production, database access, deployment, or push.

The fixed product candidate is `4594406e9fd8a9ac380c3b2b880fda67271790bc`.
Its cumulative changes after the I03 closure receipt are confined to the W1-I04 card WriteSet.
The VSB execution ledger and all prior W1 production remain immutable.

## 2. Four-path governance chain

Starting at `ClosureOriginSHA`, the governance prefix consists of four nonempty,
single-parent commits in this canonical order:

```text
docs/superpowers/specs/2026-08-20-cognitura-w1-i04-closure-design.md
docs/superpowers/plans/2026-08-20-cognitura-w1-i04-closure.md
tests/task-cards/verify-wave1-implementation-cards.sh
scripts/verify-wave1-implementation-cards
```

The two documents must remain `100644`; the two scripts must remain `100755`. Each path may
change exactly once. Every commit must be nonempty and single-parent, contain no NUL or mode
drift, and change no path outside this exact four-path set. The eleven closure projections,
W1-I04 product WriteSet, VSB ledger, W1-I02, database and push boundaries remain byte-identical.

At the governance tip the public static verifier must accept exactly this pending state:

```text
W1-I04 Status = READY
W1-I05 Status = BLOCKED_BY_DEPENDENCY
ActiveTaskCard = W1-I04
W1I04ClosureStatus = PENDING
```

## 3. Narrow inferred XML fixture-copy correction

Git `diff-tree -M -C --find-copies-harder` may label an independently created synthetic XML
fixture as `Cnnn` because it resembles an existing fixture. The post-I03 descendant validator
may ignore only that heuristic record when every predicate below is true:

```text
Status = C*
Source = server/src/test/resources/docx/security/minimal-document.xml
      OR server/src/test/resources/docx/text/*.xml
Target = server/src/test/resources/docx/text/*.xml
BaseSourceMode = 100644
HeadSourceMode = 100644
HeadTargetMode = 100644
BaseTarget = ABSENT
BaseSourceBlob = HeadSourceBlob
```

All `R*` records remain forbidden. A non-XML target, target that existed in the base, changed or
deleted source, mode drift, outside path, or any copy record outside the W1-I04 synthetic fixture
boundary remains forbidden. The ordinary changed-path closed set still applies, so this exception
does not authorize an additional path. The classifier must use `diff.renameLimit=0` so repository
configuration cannot hide a record.

The contract must prove a real `C100` XML positive and independent real-Git negatives for a
non-XML target and `R100` rename. This correction is local to post-I03 W1-I04 descendants and
must not weaken governance-chain or closure-receipt rename/copy checks.

## 4. Projection-only closure receipt

The closure receipt is the direct single-parent child of the governance tip and modifies exactly
these eleven paths:

```text
AGENTS.md
README.md
docs/design/wave-1/README.md
docs/engineering/cognitura-design-index.md
docs/engineering/cognitura-wave-1-design-plan.md
docs/engineering/cognitura-wave-1-design-acceptance.md
docs/engineering/cognitura-wave-1-implementation-plan.md
docs/task-cards/wave-1/README.md
docs/task-cards/wave-1-implementation/README.md
docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md
docs/task-cards/wave-1-implementation/W1-I05-table-fidelity.md
```

The receipt must preserve every path mode and contain no rename/copy or NUL. It performs only
this atomic projection:

```text
TaskCardSetStatus = READY_FOR_EXECUTION
ActiveTaskCard = W1-I05
W1-I04 Status = DONE
W1-I05 Status = READY
W1-I05 BusinessImplementationAuthorization = USER_AUTHORIZED
ReadyTaskCardCount = 1
SuspendedTaskCardCount = 0
W1-I02 Status = QUEUED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

All central active-card fields and task tables must agree. Narratives may only replace “I04 is
the sole READY card” with “I04 closed with zero findings and I05 is the sole READY card”. I06 and
all later cards remain blocked. User authorization permits serial execution of the approved card
set, but does not authorize I02 or any formal database write.

## 5. Fixed review receipt

`docs/engineering/cognitura-wave-1-implementation-plan.md` must append exactly once, in this
order, the following closed block:

```text
W1-I04 = DONE
ReviewedCandidate = 4594406e9fd8a9ac380c3b2b880fda67271790bc
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
Ultra = NOT_RUN
I04ClosureReleasedTaskCard = W1-I05
QueuedTaskCard = W1-I02
QueuedReason = INDEPENDENT_DATABASE_GATE_REQUIRED
```

Missing, duplicate, reordered, unknown, or contradictory receipt fields; wrong candidate;
nonzero finding; non-GO verdict; Ultra execution; or release of any card other than I05 must fail.

## 6. Public validation and replay

The existing public verifier remains the only entry:

```bash
scripts/verify-wave1-implementation-cards \
  --repo-root . \
  --cards-dir docs/task-cards/wave-1-implementation

scripts/verify-wave1-implementation-cards \
  --repo-root . \
  --cards-dir docs/task-cards/wave-1-implementation \
  --transition-base <governance-tip> \
  --transition-head <closure-receipt>
```

Static validation at the governance tip prints `W1I04ClosureStatus = PENDING`. Explicit and
static validation of the legal receipt print `W1I04ClosureStatus = PASS` and
`ActiveTaskCard = W1-I05`. The I03 closure and its fixed production remain replayed and immutable.
Every post-receipt first-parent descendant must reject any later touch of the eleven projection
paths, thereby allowing this closure exactly once.

## 7. Required TDD matrix and completion

The focused contract must use real Git commits and the public verifier. Positive cases include
legal governance PENDING, explicit receipt, static receipt, and the real inferred XML fixture-copy
case. Independent negatives include governance merge/empty/outside/repeated path/rename/copy/NUL/
mode and product drift; receipt non-direct-child/missing/extra path/wrong I04 or I05 state/two READY/
I02 release/database or push authorization drift; every review-block mutation class; stale I04
narrative; second closure; post-receipt projection introduce-restore; working-tree masking; and the
copy-classifier negatives from section 3. All temporary artifacts are invocation-owned and cleaned.

Completion requires focused and full Wave1 task-card suites, Bash 3.2 syntax, static Wave1/VSB,
JDK 21 W1-I04 tests, Markdown validation from a tracked archive, and `git diff --check`. The fixed
four-path governance candidate then receives one `deep_reviewer/xhigh/ONE` review. Only zero
findings permit the direct-child eleven-path receipt. Remote push remains unauthorized.
