# Cognitura VSB Chrome Authority Migration Design

```text
CanonicalProjectName = Cognitura
DesignKind = ONE_TIME_CHROME_AUTHORITY_MIGRATION
Status = USER_APPROVED
MigrationOriginReceiptSHA = 7b7b9bcab8b372c66ebd0533cbfe3dca885d0f3d
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

The original plan is outside VSB-03's exact twelve-path Owner WriteSet.  It
must not be committed as an ordinary VSB-03 candidate change, and the Owner
WriteSet must not be widened.  This design therefore defines one narrow
governance migration and a new ledger-only VSB-03 release anchor.

## 2. Chrome contract

The selected browser remains:

```text
/Applications/Google Chrome.app/Contents/MacOS/Google Chrome
```

Its `--version` output may be normalized only by removing trailing whitespace.
The normalized value must equal this literal exactly:

```text
Google Chrome 151.0.7922.138
```

No leading whitespace, product-name change, shortened version, wildcard,
version range, environment override, PATH lookup, or arbitrary whitespace
normalization is allowed.  VSB-03 capture, verification, evidence metadata,
and negative tests must all use the same literal.

## 3. Fixed migration candidate G4

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

The commit that first contains the three Authority documents is the fixed
migration Authority SHA.  Those three blobs and their `100644` modes must stay
identical through G4.  The old execution plan must contain no
`151.0.7922.109`, must contain the target literal in all six browser-version
contract locations, and must normalize trailing whitespace only.

G4 receives one fixed `L3 / deep_reviewer / xhigh / ONE` zero-finding review.
There is no Ultra escalation reason.

## 4. Pending admission

Before G4 is reviewed, the public verifier may report
`ChromeAuthorityMigrationStatus = PENDING` only when:

- repository HEAD descends the fixed origin on a linear first-parent chain;
- working, HEAD, and origin execution-ledger blobs are byte-identical;
- no `ChromeAuthorityMigration*` field exists;
- all version-4, sequence-9, VSB-03 active/released, VSB-00..VSB-02 completed,
  VSB-G2 PASS, authorization, W1 freeze, database, and push facts remain exact;
- the full governance chain and exact six-path cumulative WriteSet pass.

This branch is admission only.  G4 is not an Owner candidate, receipt, or
release anchor.

## 5. One-time migration receipt R4

Only reviewed G4 may be the base of R4.  R4 is G4's ledger-only direct child.
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
mode remains `100644` and contains no NUL.

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
versions 3 and 4.

## 7. Non-goals

This migration does not create screenshots, accept VSB-03, change the twelve
Owner paths, alter product code, restore Wave 1, authorize formal database
writes, authorize remote push, rewrite historical receipts, or delete failed
evidence.  After R4 passes, VSB-03 starts again from R4 and must still complete
its full Owner implementation and L4 gate.
