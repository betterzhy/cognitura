# Cognitura W1-I07 Closure and I08 Release Design

```text
CanonicalProjectName = Cognitura
DesignKind = ONE_TIME_W1_I07_CLOSURE
TransitionKind = I07_CLOSE_ADVANCE
ClosureOriginSHA = 094f62546cf7a13435c5d61f2a7bede21b86f099
ReviewedCandidateSHA = 094f62546cf7a13435c5d61f2a7bede21b86f099
ReviewedParentSHA = 5433485e8f88f3846cbda722282223a3c8274b14
ReviewedTreeSHA = d82ece96e0e3dabdfef64a766179b711ea6d557f
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
Ultra = NOT_RUN
ReleasedTaskCard = W1-I08
QueuedTaskCard = W1-I09
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. Purpose and authority

This design defines the only legal projection-only transition that consumes the fixed,
zero-finding W1-I07 product review, closes I07, releases I08 as the sole `READY` card, and moves
I09 to `QUEUED`. It follows the approved serial path `I07 -> I08 -> I09`; the I08 and I09
dependency fan-out does not authorize parallel execution.

This design does not create a generic closure engine, a second execution ledger, a production
processing adapter, a production publication schema, a formal database write, deployment, or
remote push. The fixed I07 product candidate and every predecessor product path remain immutable.

## 2. Fixed I07 product evidence

The reviewed product identity is exact:

```text
Candidate = 094f62546cf7a13435c5d61f2a7bede21b86f099
Parent = 5433485e8f88f3846cbda722282223a3c8274b14
Tree = d82ece96e0e3dabdfef64a766179b711ea6d557f
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
```

The cumulative diff from the I02 closure receipt to this candidate is exactly the eight W1-I07
WriteSet paths. Focused verification used a real PostgreSQL 18 Testcontainers instance and real
JDBC. The test-local adapter and DDL remain contract evidence only and are not production
migration or runtime wiring. Product review evidence does not itself mutate task-card state.

## 3. Exact four-path governance chain

Starting at `ClosureOriginSHA`, the governance prefix consists of four nonempty, single-parent
commits in this canonical order:

```text
docs/superpowers/specs/2026-08-21-cognitura-w1-i07-closure-design.md
docs/superpowers/plans/2026-08-21-cognitura-w1-i07-closure.md
tests/task-cards/verify-wave1-implementation-cards.sh
scripts/verify-wave1-implementation-cards
```

The two documents remain `100644`; the two scripts remain `100755`. Each path changes exactly
once. Every commit is nonempty and single-parent, contains no rename/copy, NUL, or mode drift, and
changes no path outside the exact four-path set. The twelve closure projections, all eight I07
product paths, every predecessor receipt, the VSB ledger, formal database boundary, and remote
push boundary remain byte-identical throughout this prefix.

At the governance tip, static validation accepts exactly this pending state:

```text
W1-I07 Status = READY
W1-I08 Status = BLOCKED_BY_DEPENDENCY
W1-I09 Status = BLOCKED_BY_DEPENDENCY
ActiveTaskCard = W1-I07
W1I07ClosureStatus = PENDING
```

## 4. Projection-only closure receipt

The closure receipt is the direct single-parent child of the reviewed governance tip and modifies
exactly these twelve paths:

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
docs/task-cards/wave-1-implementation/W1-I07-revision-attempt-fencing-publication.md
docs/task-cards/wave-1-implementation/W1-I08-stable-reference-reparse-lineage.md
docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md
```

The receipt preserves every path mode and contains no rename/copy or NUL. It performs only this
atomic projection:

```text
TaskCardSetStatus = READY_FOR_EXECUTION
ActiveTaskCard = W1-I08
W1-I07 Status = DONE
W1-I08 Status = READY
W1-I08 BusinessImplementationAuthorization = USER_AUTHORIZED
W1-I09 Status = QUEUED
W1-I09 BusinessImplementationAuthorization = REQUIRED_BEFORE_READY
ReadyTaskCardCount = 1
SuspendedTaskCardCount = 0
W1-I10 Status = BLOCKED_BY_DEPENDENCY
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

All central active-card fields, tables, and narratives agree. I09 is dependency-satisfied but not
selected, so it is `QUEUED`, never `READY` or `BLOCKED_BY_DEPENDENCY`. I10 and later cards remain
blocked. No I08 or I09 product path changes in the closure receipt.

## 5. Fixed product and governance review receipt

`docs/engineering/cognitura-wave-1-implementation-plan.md` appends exactly one terminal section
whose values are checked against Git objects:

```text
W1-I07 = DONE
ReviewedCandidate = 094f62546cf7a13435c5d61f2a7bede21b86f099
ReviewedParent = 5433485e8f88f3846cbda722282223a3c8274b14
ReviewedTree = d82ece96e0e3dabdfef64a766179b711ea6d557f
ReviewedGovernanceCandidate = direct parent of the closure receipt
ReviewedGovernanceParent = single parent of ReviewedGovernanceCandidate
ReviewedGovernanceTree = tree of ReviewedGovernanceCandidate
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
Ultra = NOT_RUN
I07ClosureReleasedTaskCard = W1-I08
QueuedTaskCard = W1-I09
QueuedReason = SERIAL_EXECUTION_ORDER
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The three governance identities are materialized as literal full SHAs after the fixed governance
candidate receives the one applicable `deep_reviewer/xhigh` review. The verifier derives the
expected identities from the receipt parent and rejects substitution, merge ancestry, an
unreviewed successor, missing or duplicated receipt, non-GO verdict, nonzero finding, Ultra use,
or a different released/queued card.

## 6. Public validation and post-closure descendants

The existing public verifier remains the only production entry:

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

Static validation at the governance tip prints `W1I07ClosureStatus = PENDING`. Explicit and
static validation of the legal receipt print `W1I07ClosureStatus = PASS` and
`ActiveTaskCard = W1-I08`. The verifier replays the I02 closure, freezes the I07 product bytes at
the reviewed product candidate, and proves the receipt is an exact projection transform.

After the receipt, each nonempty single-parent descendant must change only the W1-I08 exact
WriteSet until a separately authorized I08 closure route exists. The twelve projection paths may
not be changed again, including introduce-then-restore history. This design does not pre-authorize
the I08 close or I09 release transition.

## 7. Required TDD matrix

The focused contract uses real shared-clone Git fixtures and invokes the public verifier. Positive
cases include the exact governance PENDING tip, explicit closure transition, static closure state,
and one legal post-closure I08 descendant. Independent negatives include:

- governance wrong order, extra path, repeated path, empty commit, merge, rename/copy, mode, NUL,
  predecessor projection drift, I07 product drift, and substituted origin;
- receipt non-direct child, missing/extra/rename/copy path, mode/NUL drift, I07 not DONE, I08 not
  READY, I09 not QUEUED, I08 and I09 both READY, I09 released first, I10 released early, active or
  ready-count mismatch, database/push authorization drift, and product-byte drift;
- wrong product or governance Candidate/Parent/Tree, non-GO verdict, any nonzero finding, Ultra
  execution, duplicate/nonterminal receipt, second closure, working-tree masking, post-receipt
  projection mutation, and post-receipt path outside the I08 WriteSet.

The RED run must fail because the old production verifier has no `W1I07ClosureStatus` route. GREEN
requires focused and full Wave 1 task-card suites, Bash 3.2 syntax, the I07 real PostgreSQL focused
test, full server regression, `git diff --check`, and static state validation.

## 8. Model route and completion

Terra/medium may perform read-only mapping and output summarization. The main Sol/high Agent owns
this R2 Authority, state-transition implementation, and integration. The fixed four-path
governance candidate receives one `deep_reviewer/Sol/xhigh/ONE` review. Ultra remains `NOT_RUN`
because there is no formal database write, irreversible external write, destructive recovery,
critical authentication/key boundary, or unresolved xhigh uncertainty.

Only `GO/P0=0/P1=0/P2=0` permits the direct-child twelve-path receipt. After explicit and static
receipt validation pass, I08 becomes the sole executable card and may proceed under its own Exact
WriteSet. Formal database write, deployment, release, and remote push remain unauthorized.
