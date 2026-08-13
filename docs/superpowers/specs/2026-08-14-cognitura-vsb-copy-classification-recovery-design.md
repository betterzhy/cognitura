# Cognitura VSB Copy Classification Recovery Design

```text
CanonicalProjectName = Cognitura
DesignKind = ONE_TIME_VERIFIER_RECOVERY
Status = USER_AUTHORIZED_EXECUTION_SCOPE_DERIVED
RecoveryOriginReceiptSHA = 9904d3deb87e4a3e2820c5a12463929916057c36
FailedVSB02CandidateSHA = b16f867bfb951bf969ac8c4a8697c8b8913325bd
PreRecoveryExecutionStateVersion = 3
PostRecoveryExecutionStateVersion = 4
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
UltraRequired = NO
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. Problem statement

VSB-02 formally requires a second local Vite HTML entry at
`web/visual-reference.html`.  The failed fixed candidate created that path as a
different blob while leaving `web/index.html` byte-identical to its parent.
Git's similarity heuristic nevertheless classified the new file as
`C053 web/index.html web/visual-reference.html` when the verifier used
`--find-copies-harder`.

Git does not record a copy operation.  `C053` is a comparison-time inference.
Treating every such inference as a path mutation makes the approved VSB-02
WriteSet impossible even though the source path was not changed.  The
ledger-only RETURN commit `9904d3d...` has the intended business finding but is
not an accepted receipt because explicit replay rejects its reviewed candidate.
It remains immutable failed evidence and must not be amended, reset, deleted,
or reported as a legal release anchor.

## 2. Recovery boundary

The recovery has exactly two responsibilities:

1. distinguish one Authority-required new HTML entry from a real rename/copy
   evasion without weakening other candidate-chain checks; and
2. make static validation replay the provenance of non-terminal ledger receipts
   instead of accepting their final text alone.

It does not fix the VSB-02 visual findings, change product files, mark VSB-02
GO, release VSB-03, restore Wave 1, authorize a database write, or authorize a
remote push.

## 3. Narrow copy-classification rule

All `R*` classifications remain forbidden.  All `C*` classifications remain
forbidden except this literal pair:

```text
CopySource = web/index.html
CopyTarget = web/visual-reference.html
```

The exception is valid only when every assertion below holds for the inspected
candidate commit and its single parent:

- source mode and blob are identical in parent and child;
- source mode is `100644`;
- target is absent in the parent and mode `100644` in the child;
- target blob differs from the source blob;
- the candidate Owner is VSB-02 and the target belongs to its exact WriteSet;
- target HTML contains exactly one local root with id
  `visual-reference-root` and exactly one local module script
  `/src/visual-reference/main.tsx`;
- target HTML contains no remote or protocol-relative resource;
- the classification is not `C100`.

Other source/target pairs, exact copies, a source changed in the same commit,
Owner-internal copy classifications, mode drift, rename-limit evasions, merge
commits, ledger changes, and paths outside the Owner WriteSet continue to fail.

## 4. Static receipt provenance

For an IN_PROGRESS static state whose latest ledger-changing first-parent
commit is a receipt, the verifier must locate that commit and replay the same
direct parent/receipt transition validator used by the explicit
`--transition-base/--transition-head` entry.  A nominal ledger body is never a
substitute for candidate WriteSet, parent receipt, topology, or reviewed-SHA
validation.

The replay applies to `ACTIVATE_SET`, `ADVANCE`, `RETURN_TO_OWNER`,
`GOVERNANCE_REPAIR`, `RECEIPT_CORRECTION`, and the recovery transition defined
below.  Historical frozen repairs keep their own exact validators.

## 5. Fixed governance candidate G3

Starting at the failed RETURN evidence `9904d3d...`, the governance chain is
linear, single-parent, non-empty per commit, ledger-preserving, and cumulative
exactly these five paths:

```text
docs/superpowers/specs/2026-08-14-cognitura-vsb-copy-classification-recovery-design.md
docs/superpowers/plans/2026-08-14-cognitura-vsb-copy-classification-recovery.md
docs/task-cards/visual-style-baseline/README.md
scripts/verify-visual-style-baseline-cards
tests/task-cards/verify-visual-style-baseline-cards.sh
```

G3 receives one fixed `L3 / deep_reviewer / xhigh / ONE` zero-finding review.
There is no Ultra escalation reason.

## 6. One-time VERIFIER_RECOVERY receipt R3

Only the reviewed G3 may be the base of the recovery receipt.  R3 is its
ledger-only direct child and upgrades the state from version 3 to version 4.
It preserves the VSB-02 finding facts from `9904d3d...`, removes the transient
`Owner` field, keeps VSB-02 active/released with the strict VSB-00,VSB-01
completed prefix, and appends this canonical block exactly once:

```text
VerifierRecoveryStatus = PASS
VerifierRecoverySpecSHA = <fixed commit containing this design>
VerifierRecoveryOriginReceiptSHA = 9904d3deb87e4a3e2820c5a12463929916057c36
VerifierRecoveryFailedCandidateSHA = b16f867bfb951bf969ac8c4a8697c8b8913325bd
VerifierRecoveryReviewedCandidateSHA = <G3>
VerifierRecoveryReviewLevel = L3
VerifierRecoveryReviewRoute = deep_reviewer
VerifierRecoveryReviewEffort = xhigh
VerifierRecoveryReviewMultiplicity = ONE
VerifierRecoveryReviewVerdict = GO_P0_0_P1_0_P2_0
```

R3 also sets:

```text
TransitionSequence = 7
TransitionKind = VERIFIER_RECOVERY
TransitionBaseSHA = <G3>
```

The transition is allowed exactly once.  Later ordinary receipts preserve the
canonical recovery block byte-for-byte.  Candidate discovery recognizes only a
fully validated R3 as the new VSB-02 release anchor; it never skips an invalid
receipt and never retroactively converts `9904d3d...` into PASS.

## 7. Acceptance

Acceptance requires public-entry tests for the historical failed pair, the
fixed exception, all listed copy/rename negatives, static replay of a tampered
non-terminal receipt, exact G3 provenance, exact R3 transformation, repeated
recovery rejection, and later-block preservation.  The full Visual Style
Baseline contract, static VSB state, Wave 1 suspended state, Bash 3.2 syntax,
and `git diff --check` must pass before G3 review and after R3.
