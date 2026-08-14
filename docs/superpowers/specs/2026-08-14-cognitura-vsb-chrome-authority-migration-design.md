# Cognitura VSB Chrome Authority Migration Design

```text
CanonicalProjectName = Cognitura
DesignKind = ONE_TIME_CHROME_AUTHORITY_MIGRATION
Status = USER_APPROVED
AuthorityGeneration = SUCCESSOR_REBASELINE
MigrationOriginReceiptSHA = 7b7b9bcab8b372c66ebd0533cbfe3dca885d0f3d
RejectedAuthoritySHA = ce2a3ca466cc4df2ff077017f1ddb03cb285416f
RejectedCandidateSHA = 4a62647fdb8226cc5c0527c48f552ef553ff146e
RejectedCandidateReviewVerdict = NO_GO
RejectedCandidateP1Count = 1
SuccessorAuthorityBinding = FIRST_COMMIT_AFTER_REJECTED_CANDIDATE_CONTAINING_THIS_CORRECTION
PreviousChromeVersion = 151.0.7922.109
TargetChromeVersion = 151.0.7922.138
PreMigrationExecutionStateVersion = 4
PostMigrationExecutionStateVersion = 5
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
UltraRequired = NO
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. Problem and authority

VSB-03 was released by the ledger-only receipt
`7b7b9bcab8b372c66ebd0533cbfe3dca885d0f3d` while its approved execution plan
required exact Chrome `151.0.7922.109`.  That binary is unavailable in the
local installed application and in the inspected local caches.  The user has
explicitly approved migrating the reproducibility authority to the installed
Chrome `151.0.7922.138`.

The first migration Authority at
`ce2a3ca466cc4df2ff077017f1ddb03cb285416f` and its fixed candidate
`4a62647fdb8226cc5c0527c48f552ef553ff146e` are immutable predecessor
evidence.  The candidate received `L3 / deep_reviewer / xhigh / ONE = NO_GO`
with one P1 finding: the capture contract still admitted browser-selection
override and fallback seams.  Neither SHA may be amended, rebased, described
as accepted, or used as the base of R4.  This approved rebaseline is an
append-only successor, not a rewrite of either rejected Git object.

The original plan is outside VSB-03's exact twelve-path Owner WriteSet.  It
must not be committed as an ordinary VSB-03 candidate change, and the Owner
WriteSet must not be widened.  This design therefore defines one narrow
governance migration and a new ledger-only VSB-03 release anchor.

## 2. Chrome contract

The only browser executable that capture and verification may invoke is this
fixed literal path:

```text
/Applications/Google Chrome.app/Contents/MacOS/Google Chrome
```

Its `--version` output may be normalized only by removing trailing whitespace.
The normalized value must equal this literal exactly:

```text
Google Chrome 151.0.7922.138
```

No leading whitespace, product-name change, shortened version, wildcard,
version range, browser-path parameter, environment-selected executable, PATH
lookup, fallback, or arbitrary whitespace normalization is allowed.  The
capture CLI accepts only `--repo-root PATH`, `--output-dir PATH`, and
`--replace-existing`; every unknown browser override flag, including
`--chrome-bin`, is rejected.  A non-empty `CHROME_BIN` environment value is
also rejected rather than read as an executable selection.  An unset or empty
value grants no override and the fixed literal path is still mandatory.

The capture source contract must contain the fixed literal invocation and
must reject any alternate executable, fake executable, environment/PATH
selection, or fallback branch.  Negative tests may use temporary source
mutations and a fake-browser invocation sentinel only to prove rejection; the
formal positive capture must invoke the fixed installed binary.  VSB-03
capture, verification, evidence metadata, and negative tests must all use the
same exact version literal.

## 3. Successor Authority and fixed migration candidate G4

Starting at `7b7b9bcab8b372c66ebd0533cbfe3dca885d0f3d`, every
origin-exclusive governance commit must have exactly one parent and change a
non-empty subset of the approved six paths.  It must not change the execution
ledger, product files, Wave 1 files, evidence, or any other path; be a merge or
empty commit; contain rename/copy classification, NUL, or mode drift; or hide
an intermediate extra-path change that is later reverted.

The cumulative WriteSet is exactly:

```text
docs/superpowers/specs/2026-08-14-cognitura-vsb-chrome-authority-migration-design.md
docs/superpowers/plans/2026-08-14-cognitura-vsb-chrome-authority-migration.md
docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md
docs/task-cards/visual-style-baseline/README.md
scripts/verify-visual-style-baseline-cards
tests/task-cards/verify-visual-style-baseline-cards.sh
```

The origin and cumulative six-path WriteSet do not change in this successor.
The first commit after rejected candidate
`4a62647fdb8226cc5c0527c48f552ef553ff146e` that contains this correction is
the successor fixed migration Authority SHA.  It is a single-parent direct
child of that rejected candidate, changes exactly the three existing
Authority paths above, and preserves their `100644` modes.  The rejected
Authority and candidate remain in first-parent history as immutable `NO_GO`
evidence, but neither is a current Authority or reviewed G4.

Every later governance commit through the successor G4 remains on the same
linear origin-exclusive chain and changes only a non-empty subset of the same
exact six paths.  The successor Authority's three blobs and their `100644`
modes must stay identical from that successor Authority commit through the
successor G4.  The old execution plan must contain no
`151.0.7922.109`, must contain the target literal in all six browser-version
contract locations, must bind the executable to the fixed literal path, and
must normalize trailing whitespace only.

Later verifier and test work must bind the successor Authority SHA literally,
record both rejected SHAs and their `NO_GO` relationship, reject either
predecessor as current Authority/G4/R4 base, validate the successor topology,
and implement the two-stage closed capture source contract below. It must not
remove the predecessor commits from ancestry or widen the cumulative WriteSet.

### 3.1 Two-stage capture source-contract closure

Stage A is governance-only. The path
`scripts/capture-visual-style-baseline` is absent at the fixed origin and
must remain absent at every governance commit through successor G4, in the G4
working tree, and in R4. G4's exact six paths and R4's ledger-only WriteSet do
not authorize creating it.

For Stage A, `scripts/verify-visual-style-baseline-cards` exposes exactly one
read-only public source-contract mode:

```text
--chrome-capture-source-contract FILE
```

That mode invokes one helper,
`validate_chrome_capture_source_contract FILE`, and reads only the supplied
regular Bash source file. It does not require the repository capture path,
start Chrome, build Web assets, mutate the repository, or accept transition
flags. The task-card tests create one canonical legal fixture under their
invocation-owned temporary directory. The fixture has the readonly fixed
literal Chrome path, the exact three-option CLI, non-empty `CHROME_BIN` and
unknown-option rejection, trailing-whitespace-only version normalization, and
no PATH lookup, executable discovery, alternate path, or fallback. Every
override/environment/PATH/fallback/fake-path mutation is passed through this
same public checker and must fail. The fake executable is never invoked.

Stage B begins only after a VSB-03 candidate has the complete exact twelve-path
cumulative Owner WriteSet, including
`scripts/capture-visual-style-baseline`. The task-card verifier materializes
that file from the candidate Git object into a verifier-owned temporary file
and passes it to the same public source-contract mode/helper before accepting
the candidate or any release based on it. The capture runner also checks its
own source through the public mode before its first test, build, server, or
browser action; the visual verifier checks the candidate-bound materialized
capture source through the same mode before invoking it. Once the capture path
exists in any candidate or working tree under validation, source-contract
validation is mandatory and has no conditional skip. G4 pending and R4 require
the path to remain absent and do not require or synthesize the actual script.

G4 receives one fixed `L3 / deep_reviewer / xhigh / ONE` zero-finding review.
There is no Ultra escalation reason.

## 4. Pending admission

Before G4 is reviewed, the public verifier may report
`ChromeAuthorityMigrationStatus = PENDING` only when:

- repository HEAD descends the fixed origin on a linear first-parent chain;
- the chain contains the rejected Authority and rejected candidate at their
  exact SHAs, followed by the fixed successor Authority and successor G4;
- neither rejected SHA is accepted as the current Authority, G4, or R4 base;
- working, HEAD, and origin execution-ledger blobs are byte-identical;
- no `ChromeAuthorityMigration*` field exists;
- all version-4, sequence-9, VSB-03 active/released, VSB-00..VSB-02 completed,
  VSB-G2 PASS, authorization, W1 freeze, database, and push facts remain exact;
- the full governance chain and exact six-path cumulative WriteSet pass;
- `scripts/capture-visual-style-baseline` is absent from origin, every
  governance commit, successor G4, and the working tree;
- the Stage A canonical temporary fixture passes the public source-contract
  checker and every required mutation fails through that same checker.

This branch is admission only.  G4 is not an Owner candidate, receipt, or
release anchor.

## 5. One-time migration receipt R4

Only the zero-finding reviewed successor G4 may be the base of R4.  R4 is that
successor G4's ledger-only direct child.  The rejected candidate and rejected
Authority are ineligible.
It mechanically transforms the origin ledger by upgrading version 4 to 5,
incrementing sequence 9 to 10, setting transition kind and base, and inserting
this canonical block exactly once after `VerifierRecoveryReviewVerdict`:

```text
ChromeAuthorityMigrationStatus = PASS
ChromeAuthorityMigrationSpecSHA = <fixed migration Authority SHA>
ChromeAuthorityMigrationOriginReceiptSHA = 7b7b9bcab8b372c66ebd0533cbfe3dca885d0f3d
ChromeAuthorityMigrationReviewedCandidateSHA = <reviewed G4 SHA>
ChromeAuthorityMigrationPreviousVersion = 151.0.7922.109
ChromeAuthorityMigrationTargetVersion = 151.0.7922.138
ChromeAuthorityMigrationReviewLevel = L3
ChromeAuthorityMigrationReviewRoute = deep_reviewer
ChromeAuthorityMigrationReviewEffort = xhigh
ChromeAuthorityMigrationReviewMultiplicity = ONE
ChromeAuthorityMigrationReviewVerdict = GO_P0_0_P1_0_P2_0
```

The only other changed lines are:

```text
ExecutionStateVersion = 5
TransitionSequence = 10
TransitionKind = CHROME_AUTHORITY_MIGRATION
TransitionBaseSHA = <reviewed G4 SHA>
```

All business state, prior governance blocks, VSB receipt fields, authorization
boundaries, Wave 1 freeze, and final newline are byte-preserved.  The ledger
mode remains `100644` and contains no NUL. The actual capture-script path
remains absent at R4; R4 validates Stage A only.

## 6. Replay and release semantics

The public explicit and static entries must both validate the exact G4 chain,
fixed Authority blobs, R4 topology, ledger-only diff, mechanical transform,
canonical block, and zero-finding route.  First-parent history may contain
`CHROME_AUTHORITY_MIGRATION` exactly once.  Every later version-5 ordinary
transition must preserve the canonical block byte-for-byte and may not add an
unknown `ChromeAuthorityMigration*` field or reorder the block.

A fully validated R4 may serve as the nearest VSB-03 release receipt.  G4 and
the old origin remain non-release governance evidence.  Current VSB-03 review
remains `L4 / deep_reviewer / xhigh / ONE`; Ultra remains `NOT_RUN` unless a
new explicit escalation reason is recorded.  Version 5 must retain the current
single-deep VSB-03 COMPLETE and FINAL_NO_GO semantics already required for
versions 3 and 4. A VSB-03 candidate or release is invalid unless its exact
twelve-path candidate-bound capture source passes Stage B through the same
public checker before any browser launch; existence of that path disables all
absence/skip handling.

## 7. Non-goals

This migration does not create screenshots, accept VSB-03, change the twelve
Owner paths, alter product code, restore Wave 1, authorize formal database
writes, authorize remote push, rewrite historical receipts, or delete failed
evidence. In particular, neither G4 nor R4 creates
`scripts/capture-visual-style-baseline`. After R4 passes, VSB-03 starts again
from R4 and must still complete its full exact twelve-path Owner implementation,
Stage B source validation, and L4 gate.
