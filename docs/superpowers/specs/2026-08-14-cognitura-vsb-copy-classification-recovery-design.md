# Cognitura VSB Copy Classification Recovery Design

```text
CanonicalProjectName = Cognitura
DesignKind = ONE_TIME_VERIFIER_RECOVERY
Status = USER_AUTHORIZED_EXECUTION_SCOPE_DERIVED_REVISED
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
forbidden except this literal status token and pair:

```text
CopyStatus = C053
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
- the classification token is exactly `C053`.

Every other `C001..C100` score, other source/target pairs, exact copies, a source changed in the same commit,
Owner-internal copy classifications, mode drift, rename-limit evasions, merge
commits, ledger changes, and paths outside the Owner WriteSet continue to fail.

## 4. Static receipt provenance

For an ordinary IN_PROGRESS static state whose latest ledger-changing first-parent
commit is a receipt, the verifier must locate that commit and replay the same
direct parent/receipt transition validator used by the explicit
`--transition-base/--transition-head` entry.  A nominal ledger body is never a
substitute for candidate WriteSet, parent receipt, topology, or reviewed-SHA
validation.

The replay applies to `ACTIVATE_SET`, `ADVANCE`, `RETURN_TO_OWNER`,
`GOVERNANCE_REPAIR`, `RECEIPT_CORRECTION`, and the recovery transition defined
below.  Historical frozen repairs keep their own exact validators.

### 4.1 Exact G3/PENDING branch

G3 cannot obtain a fixed review if static admission recursively requires the
failed `b16f867... -> 9904d3d...` RETURN to already be an ordinary legal
receipt.  One and only one pending branch avoids that cycle:

- inspected HEAD is not `9904d3d...` and descends it on a linear first-parent
  chain;
- working, HEAD, and origin ledger blobs are byte-identical;
- version 3, sequence 6, `RETURN_TO_OWNER`, and the P1/P2 finding facts remain
  unchanged, and no recovery field exists;
- the complete chain satisfies section 5;
- the failed pair satisfies the new literal `C053` classifier without being
  accepted as an ordinary receipt.

This branch reports `VerifierRecoveryStatus = PENDING`.  It neither marks the
origin PASS nor makes it a release anchor.  Explicit G3-to-R3 validation calls
the recovery-chain validator directly and does not recursively invoke ordinary
static replay for `9904d3d...`.

## 5. Fixed governance candidate G3

Starting at `9904d3d...`, every origin-exclusive governance commit must have
one parent and change a non-empty subset of the approved five paths.  It must
not change the ledger, product, Wave 1, or any other path; be a merge or empty
commit; contain rename/copy classification, NUL, or mode drift; or introduce an
intermediate extra-path change later reverted.  The two Authority documents
remain immutable `100644` blobs after introduction, and G3 descends the fixed
commit containing this revised design and plan.  The cumulative paths are
exactly:

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

R3 is generated mechanically from the fixed `9904d3d...` ledger:

1. replace the unique version 3 line with version 4;
2. insert the ten recovery lines immediately after the unique
   `ReceiptCorrectionReviewVerdict = FINAL_GO_P0_0_P1_0_P2_0` line;
3. replace sequence 6 with 7, kind `RETURN_TO_OWNER` with
   `VERIFIER_RECOVERY`, and base `b16f867...` with G3;
4. delete the unique `Owner = VSB-02` line;
5. preserve every other byte, field, prose line, order, canonical correction
   block, and final newline.

R3 therefore also contains:

```text
TransitionSequence = 7
TransitionKind = VERIFIER_RECOVERY
TransitionBaseSHA = <G3>
```

The ledger remains mode `100644`, is NUL-free, and must compare byte-for-byte
with that generated file.  The transition is allowed exactly once.  Later ordinary receipts preserve the
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
