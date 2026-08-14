# Cognitura VSB Historical HV Replay Repair Design

```text
CanonicalProjectName = Cognitura
DesignKind = ONE_TIME_TERMINAL_HISTORICAL_HV_REPLAY_REPAIR
Status = USER_APPROVED_APPROACH_WRITTEN_SPEC_PENDING_REVIEW
VSBReleaseReceiptSHA = efc763966d64fc808e9098bec52566edb7d15dc3
RejectedVSB03CandidateSHA = 2690ab9e6d0318c63deb56f86bc0b923ae845c04
HistoricalHVReplaySnapshotSHA = 77d8c1e780f5cc4d209a56baff349135a3c04ee8
HistoricalHVReplaySnapshotTree = 476bc02272b2e0c4f8f6eb4565e9dcf08369f762
HistoricalVisualEvidenceBaselineSHA = 70eefba5912e6884e4e7e1d6477a65f4091d6590
PreRepairExecutionStateVersion = 5
PostRepairExecutionStateVersion = 5
FinalTransitionSequence = 11
FinalTransitionKind = COMPLETE
GovernanceReviewLevel = L3
FinalReviewLevel = L4
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
UltraRequired = NO
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

In the terminal receipt examples below, `<exact-eight candidate>` is a
mechanical notation for the one reviewed 40-character candidate SHA.  The
receipt builder writes that literal SHA; angle brackets or symbolic refs never
appear in the ledger.

## 1. Problem statement

The fixed VSB-03 candidate
`2690ab9e6d0318c63deb56f86bc0b923ae845c04` closes the browser mutation,
candidate binding, ambient-environment, evidence, screenshot, and Chrome
`151.0.7922.138` contracts.  Its final `L4 / deep_reviewer / xhigh / ONE`
review nevertheless returned `NO_GO` with one P1 finding.

The VSB execution plan still requires replay of the historical High Fidelity
Visual Gate from old Task 5 Steps 1 through 12.  Running the mutable current
`scripts/verify-high-fidelity-visual` is not that replay: the current Repository
has legitimately advanced to `WAVE1_IMPLEMENTATION_IN_PROGRESS`, so that
script rejects the current `AGENTS.md` even though the historical HV stage was
closed correctly.  Treating this current-stage failure as a product defect
would rewrite unrelated projections and widen VSB-03 beyond its Owner scope.

The terminal HV closure and evidence-lock commit
`77d8c1e780f5cc4d209a56baff349135a3c04ee8` is the fixed historical snapshot
whose archived `scripts/verify-high-fidelity-visual` validates the matching
historical Repository tree and reports the completed HV facts.  The repair is
therefore a fixed-snapshot replay correction, not a new product feature or a
new execution-state migration.

## 2. Minimal repair boundary

This design adopts one terminal, append-only repair candidate after the
rejected candidate.  It deliberately does **not** introduce execution-state
version 6, an R5 receipt, a new correction block, a reusable release anchor, a
second task-card set, or a general-purpose historical replay framework.

The repair has exactly four responsibilities:

1. replace the ambiguous current-tree HV invocation with replay of the fixed
   `77d8c1e...` historical tree;
2. bind that replay to immutable Git identity, isolated materialization, exact
   PASS output, cleanup, and fail-closed negative tests;
3. admit one combined governance-and-VSB repair candidate with the exact
   cumulative eight-path WriteSet defined below; and
4. allow one direct ledger-only `COMPLETE` receipt after both required reviews
   pass on that unchanged candidate.

The repair does not change the visual evidence, screenshots, product DOM/CSS,
capture launcher, Chrome Authority, VSB-00..VSB-02 receipts, Wave 1 production
tree, frozen W1-I03 candidate, historical HV evidence, raw inputs, database,
deployment, or remote repository.

## 3. Fixed historical replay

The fixed candidate's `scripts/verify-visual-style-baseline` owns one internal
historical replay operation used only by this terminal Gate.  It adds no
generic replay CLI and must first prove:

- `77d8c1e...` exists as a commit and has tree
  `476bc02272b2e0c4f8f6eb4565e9dcf08369f762`;
- its single parent is
  `98d5f89731626c0ead69de46255ba4d433d03c86`;
- `scripts/verify-high-fidelity-visual` is mode `100755` with blob
  `73c1b62e643d3808c16ccab89aefb13e3646502b`;
- `AGENTS.md` is mode `100644` with blob
  `3b9dbe8c3241671ed2070446d3781b1453239f07`; and
- `docs/engineering/cognitura-design-index.md` is mode `100644` with blob
  `d0b85366e8eaee7771afdb95436e1a7e28aa75ae`.

The verifier then creates one invocation-owned temporary directory, exports
the complete `77d8c1e...` tree with the fixed absolute Git executable, extracts
it with the fixed absolute system tar executable, and runs the archived
`scripts/verify-high-fidelity-visual` from that archived Repository root.  It
must not copy current working-tree files into the archive or pass current
`AGENTS.md`, README, design index, cards, plan, prototype, or evidence paths as
overrides.

The archived verifier runs under a clean environment with the locked system and
Node toolchain PATH, no `BASH_ENV`, `ENV`, exported Bash functions, or browser
override variables.  Before replay, the repair verifier requires the literal
installed Chrome path
`/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` to be executable.
`CHROME_BIN` remains absent, so the frozen historical script selects that
literal first; its historical fallback source remains immutable but is not
used as current VSB capture Authority.

Replay succeeds only when the archived process exits zero and its output
contains each of these complete lines exactly once:

```text
HighFidelityVisualTaskCardValidation = PASS
TaskCardSetStatus = COMPLETE
HighFidelityVisualDesign = PASS
HighFidelityDesignStatus = COMPLETE
HighFidelityVisualValidation = PASS
HighFidelityUsabilityValidation = PASS
HighFidelityStateAcceptance = PASS
ImplementationValidation = NOT_RUN
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The output must not contain a FAIL field or contradictory duplicate.  The
temporary archive, Chrome profiles, server state, logs, and replay output are
removed on success, failure, and signal exit.  A sibling sentinel outside the
invocation root and the main worktree must remain unchanged.

## 4. Combined exact-eight repair candidate

Starting immediately after rejected candidate `2690ab9...`, every
origin-exclusive repair commit must have exactly one parent and change a
non-empty subset of the following cumulative WriteSet:

```text
docs/superpowers/specs/2026-08-15-cognitura-vsb-historical-hv-replay-repair-design.md
docs/superpowers/plans/2026-08-15-cognitura-vsb-historical-hv-replay-repair.md
docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md
docs/task-cards/visual-style-baseline/README.md
scripts/verify-visual-style-baseline-cards
tests/task-cards/verify-visual-style-baseline-cards.sh
scripts/verify-visual-style-baseline
tests/visual-style-baseline/verify-visual-style-baseline.sh
```

The first six paths are the governance subset.  The final two paths are the
only VSB-03 product-verification repair subset.  The cumulative tip must change
all eight paths relative to `2690ab9...`, with their canonical Git modes, and
must not change any other path.

Every commit in the chain must be single-parent, non-empty, NUL-free, and free
of rename or copy classification.  No commit may change the VSB ledger, Wave 1
files, product files, evidence, screenshots, database paths, raw inputs, or
`.idea/`; introduce an outside-path, mode, Authority-blob, or ledger drift and
later restore it; or conceal changes through a merge, low rename limit, binary
rewrite, or working-tree substitution.

The repair Authority SHA is the first post-`2690ab9...` commit whose tree
contains the final reviewed bytes of this design, its implementation plan, and
the corrected 2026-08-12 VSB plan.  This avoids a self-SHA cycle: the documents
name the structural binding, and the later verifier/README/tests record the
resolved literal SHA.  Those three Authority blobs and modes are immutable
from the repair Authority through the combined candidate.

The other ten paths in the original VSB-03 exact-twelve Owner WriteSet must be
byte-for-byte and mode-for-mode identical to `2690ab9...`.  In particular, all
four PNGs, the evidence manifest, acceptance report, capture wrapper, probe,
runtime guard, and comparison template remain fixed.  The repaired visual
verifier and its test may change only to replace the stale current-tree HV Gate
with the fixed replay defined in section 3 and to test that behavior.

## 5. Candidate admission and reviews

The public task-card verifier exposes one focused repair-contract entry.  It
uses real Git fixtures and its production transition/static entry points to
prove the linear exact-eight chain, fixed Authority, ten unchanged Owner paths,
working-tree independence, and final receipt topology.  The visual verifier's
existing fixed-candidate entry and its test own the archived-HV replay proof;
the task-card verifier does not duplicate that runtime implementation.

The combined candidate receives two sequential reviews on one unchanged SHA:

1. `L3 / deep_reviewer / xhigh / ONE` reviews governance topology, Authority
   binding, historical replay isolation, mutation coverage, and the absence of
   a second state machine; then
2. `L4 / deep_reviewer / xhigh / ONE` reviews the complete VSB-03 fixed
   candidate, including the previously closed browser/evidence contracts and
   the new historical replay Gate.

Ultra is not run because this repair has no irreversible external write,
database, deletion, authentication, or key boundary, and the single xhigh
review route can close the evidence.  Either review finding creates a new
append-only candidate SHA.  A verdict for `2690ab9...` or any earlier tree may
not be reused.

## 6. Terminal version-5 receipt

After both zero-finding reviews, the only state mutation is a ledger-only
direct child of the exact-eight candidate.  It preserves
`ExecutionStateVersion = 5`, every Governance Repair, Receipt Correction,
Verifier Recovery, and Chrome Authority Migration block byte-for-byte, and
performs the existing terminal VSB transition with these facts:

```text
TaskCardSetStatus = COMPLETE
ActiveTaskCard = NONE
ReleasedTaskCard = NONE
CompletedTaskCards = VSB-00,VSB-01,VSB-02,VSB-03
CurrentCandidateSHA = <exact-eight candidate>
CurrentGateStatus = VSB-G3_PASS
CurrentReviewRoute = deep_reviewer
CurrentReviewVerdict = FINAL_GO_P0_0_P1_0_P2_0
VSB03CandidateSHA = <exact-eight candidate>
VSB03GateStatus = VSB-G3_PASS
VSB03ReviewRoute = deep_reviewer
VSB03DeepReviewVerdict = FINAL_GO_P0_0_P1_0_P2_0
VSB03UltraReviewVerdict = NOT_RUN
NextTaskCard = NONE
TransitionSequence = 11
TransitionKind = COMPLETE
TransitionBaseSHA = <exact-eight candidate>
VisualImplementation = COMPLETE
FullProductImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

No `HistoricalHVReplayCorrection*` fields or new receipt block are added.  The
historical replay identity remains Authority and candidate-validation data,
not a second mutable ledger state.  The separately governed ten-path Wave 1
restore remains outside this repair and is eligible only after the terminal
VSB receipt passes; it is not part of the exact-eight candidate or ledger
receipt.

## 7. Fail-closed test contract

Tests must first establish RED against the current production verifier, then
make the smallest production change needed for GREEN.  The focused public
matrix includes at least:

- the exact `77d8c1e...` archive replay positive;
- wrong commit, parent, tree, mode, or key blob;
- current-tree HV verifier use, current projection injection, archive mutation,
  missing or duplicate PASS lines, added FAIL/authorization contradictions,
  nonzero exit, toolchain/env poisoning, and temporary residue;
- exact-eight positive admission plus empty, merge, extra/missing path,
  intermediate introduce-and-restore, ledger/W1 drift, NUL, mode, rename/copy,
  low-rename-limit, Authority drift, and ten-owner-path drift negatives;
- attempts to reuse `2690ab9...` as GO or to use a different historical
  snapshot;
- exact direct-child version-5 `COMPLETE` positive plus wrong base, non-direct
  child, extra path, second repair, sequence/version change, stacked route,
  Ultra execution, missing review, and mutated historical block negatives; and
- explicit and static replay of the same terminal facts.

The final stable tree must pass the repair focused contract, full VSB suite,
fixed-candidate visual verifier, Bash 3.2 syntax, static VSB state, Wave 1
suspended state, `git diff --check`, exact WriteSet/mode checks, ledger identity
before the receipt, frozen W1 identity, and invocation cleanup checks.

## 8. Acceptance and non-goals

Acceptance requires a fixed exact-eight candidate, zero findings from both
reviews, a direct ledger-only version-5 sequence-11 `COMPLETE` receipt, and no
tracked residue.  `.idea/` remains untouched and untracked.  Formal database
writes, deployment, remote push, destructive history rewriting, and Wave 1
implementation are not authorized.

Rejected alternatives are:

- running or modifying the current-tree HV verifier, because it validates the
  current stage rather than the frozen historical closure;
- treating the old Step 11 command as implicitly satisfied, because that would
  leave the final Authority contradiction untested;
- adding version 6 plus G5/R5, because a terminal exact-eight candidate and the
  existing version-5 `COMPLETE` receipt already express all required state; and
- adding a general historical replay or release-anchor mechanism, because only
  this fixed terminal conflict is in scope.
