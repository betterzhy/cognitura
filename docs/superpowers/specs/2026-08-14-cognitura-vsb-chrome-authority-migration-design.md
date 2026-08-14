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
RejectedSuccessorAuthoritySHA = a2d22c2e8218413d26f7d8940a9ea5564e59b7f0
RejectedSuccessorCandidateSHA = b0b77e878fd468f38d40ddd702c96ea8e7446658
RejectedSuccessorCandidateReviewVerdict = NO_GO
RejectedSuccessorCandidateP1Count = 1
SuccessorAuthorityBinding = FIRST_COMMIT_AFTER_B0B77E8_CONTAINING_GOVERNED_LAUNCHER_CORRECTION
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

That first successor Authority at
`a2d22c2e8218413d26f7d8940a9ea5564e59b7f0` and its fixed candidate
`b0b77e878fd468f38d40ddd702c96ea8e7446658` are also immutable `NO_GO`
evidence. Its `L3 / deep_reviewer / xhigh / ONE` review found one P1: the
source checker accepted legal contract tokens hidden in an uncalled function
while the live path selected and executed `"$ALT_BROWSER"`. Token presence,
regex blacklists, source-data-flow inference, and adding more spellings cannot
prove which executable arbitrary Bash will run. Neither SHA may anchor R4.
The user approved architecture A: browser selection and every Chrome process
launch move into the frozen task-card verifier, while the later VSB-03 capture
path becomes one exact-byte wrapper with no browser input or launch logic.

The original plan is outside VSB-03's exact twelve-path Owner WriteSet.  It
must not be committed as an ordinary VSB-03 candidate change, and the Owner
WriteSet must not be widened.  This design therefore defines one narrow
governance migration and a new ledger-only VSB-03 release anchor.

## 2. Chrome contract

The only code allowed to start a Chrome process is the dedicated
`--chrome-fixed-capture` mode in the fixed
`scripts/verify-visual-style-baseline-cards` blob. That mode invokes only this
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

No candidate-owned Bash source may contain browser selection or Chrome launch
logic. `scripts/capture-visual-style-baseline` is instead the canonical
exact-byte wrapper defined in section 3.1. It delegates its arguments to the
sibling frozen task-card verifier and does nothing else. The verifier-owned
capture mode parses the exact three-option capture CLI, rejects a non-empty
`CHROME_BIN` and all unknown options before any test/build/server/browser
effect, and owns the complete deterministic capture workflow. The visual
verifier may invoke only the exact wrapper; it may not invoke Chrome directly.
VSB-03 capture, verification, evidence metadata, and behavioral negative tests
must all bind the same fixed verifier blob and exact version literal.

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
The first commit after rejected successor candidate
`b0b77e878fd468f38d40ddd702c96ea8e7446658` that contains this correction is
the new successor fixed migration Authority SHA. It is a single-parent direct
child of that rejected candidate, changes exactly the three existing Authority
paths above, and preserves their `100644` modes. Both rejected Authority /
candidate pairs remain in first-parent history as immutable `NO_GO` evidence;
none is a current Authority or reviewed G4.

Every later governance commit through the successor G4 remains on the same
linear origin-exclusive chain and changes only a non-empty subset of the same
exact six paths.  The successor Authority's three blobs and their `100644`
modes must stay identical from that successor Authority commit through the
successor G4.  The old execution plan must contain no
`151.0.7922.109`, must contain the target literal in all six browser-version
contract locations, must bind the executable to the fixed literal path, and
must normalize trailing whitespace only.

Later verifier and test work must bind the new successor Authority SHA
literally, record all four rejected SHAs and both `NO_GO` relationships, reject
every predecessor as current Authority/G4/R4 base, validate the successor
topology, and implement the two-stage exact-wrapper/owned-launcher contract
below. It must not remove predecessor commits from ancestry or widen the
cumulative WriteSet.

### 3.1 Two-stage capture source-contract closure

Stage A is governance-only. The path
`scripts/capture-visual-style-baseline` is absent at the fixed origin and
must remain absent at every governance commit through successor G4, in the G4
working tree, and in R4. G4's exact six paths and R4's ledger-only WriteSet do
not authorize creating it.

For Stage A, `scripts/verify-visual-style-baseline-cards` exposes exactly one
read-only public wrapper-contract mode:

```text
--chrome-capture-source-contract FILE
```

That mode invokes `validate_chrome_capture_source_contract FILE`, accepts only
a regular `100755` file, and compares its bytes including the final newline to
this canonical wrapper exactly:

```bash
#!/bin/bash
set -euo pipefail

script_dir="${0%/*}"
[[ "${script_dir}" != "${0}" ]] || script_dir='.'
script_dir="$(cd -- "${script_dir}" && pwd -P)"
exec "${script_dir}/verify-visual-style-baseline-cards" --chrome-fixed-capture "$@"
```

It does not parse arbitrary Bash semantics, search for tokens, start Chrome,
build Web assets, mutate the repository, or accept transition flags. The
task-card tests create this exact fixture under their invocation-owned
temporary directory. Any extra comment, function, heredoc, alias, array,
indirect expansion, `eval`, `$VAR`/`${VAR}` executable, alternate path,
fallback, missing line, reordered line, suffix, mode drift, NUL, or newline
drift must fail byte comparison. A fake executable sentinel remains
uninvoked. Stage A also exercises the owned capture mode through early
rejection cases (non-empty `CHROME_BIN`, poisoned PATH, and unknown/browser
override flags) and one verifier-owned temporary positive capture fixture.
That positive may start only the fixed Chrome binary, writes only under the
invocation root, is fully cleaned, and is not VSB evidence or an authorization
to create the Repository capture path.

The same fixed task-card verifier contains the only Chrome-launch function and
the only capture mode, `--chrome-fixed-capture`. The launch function calls the
literal application path directly; it accepts Chrome arguments but no browser
executable input. The capture mode owns CLI parsing, version enforcement,
test/build/server lifecycle, probe, screenshot, cleanup, and output. No other
Repository file may call Chrome, Chromium, a browser executable variable,
`open`, or executable discovery for VSB capture.

Stage B begins only after a VSB-03 candidate has the complete exact twelve-path
cumulative Owner WriteSet, including
`scripts/capture-visual-style-baseline`. The task-card verifier materializes
that candidate Git blob and requires exact canonical bytes plus mode before
accepting the candidate or any release based on it. The fixed visual verifier
creates one invocation-owned `scripts/` directory, materializes the wrapper
from the VSB-03 candidate and `verify-visual-style-baseline-cards` from the
reviewed G4 recorded by R4 as sibling `100755` files, validates both Git
identities and the wrapper bytes, and executes that exact materialized wrapper
with a sanitized environment and the locked toolchain PATH. The fixed
`/bin/bash` shebang and builtin-only sibling resolution prevent PATH-selected
shell/path helpers; `BASH_ENV`, `ENV`, exported functions, and browser override
variables are absent. It must never validate one copy and execute another. The
wrapper delegates to the sibling frozen verifier, whose
`--chrome-fixed-capture` mode performs all effects. Once the capture path
exists in any candidate or working tree under validation, wrapper validation
is mandatory and has no conditional skip. G4 pending and R4 require the path
to remain absent and do not require or synthesize the actual script.

G4 receives one fixed `L3 / deep_reviewer / xhigh / ONE` zero-finding review.
There is no Ultra escalation reason.

## 4. Pending admission

Before G4 is reviewed, the public verifier may report
`ChromeAuthorityMigrationStatus = PENDING` only when:

- repository HEAD descends the fixed origin on a linear first-parent chain;
- the chain contains both rejected Authority/candidate pairs at their exact
  SHAs, followed by the fixed successor Authority and successor G4;
- none of the four rejected SHAs is accepted as current Authority, G4, or R4
  base;
- working, HEAD, and origin execution-ledger blobs are byte-identical;
- no `ChromeAuthorityMigration*` field exists;
- all version-4, sequence-9, VSB-03 active/released, VSB-00..VSB-02 completed,
  VSB-G2 PASS, authorization, W1 freeze, database, and push facts remain exact;
- the full governance chain and exact six-path cumulative WriteSet pass;
- `scripts/capture-visual-style-baseline` is absent from origin, every
  governance commit, successor G4, and the working tree;
- the Stage A canonical exact-wrapper fixture passes the public wrapper
  checker, every byte/mode mutation fails, and owned-launcher early-rejection
  cases leave all fake-browser sentinels untouched.

This branch is admission only.  G4 is not an Owner candidate, receipt, or
release anchor.

## 5. One-time migration receipt R4

Only the zero-finding reviewed successor G4 may be the base of R4. R4 is that
successor G4's ledger-only direct child. All rejected candidates and rejected
Authorities are ineligible.
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
twelve-path candidate-bound wrapper passes Stage B exact-byte/mode validation
and the exact materialized wrapper delegates to the sibling reviewed-G4
verifier before any browser launch; existence of that path disables all
absence/skip handling.

## 7. Non-goals

This migration does not create screenshots, accept VSB-03, change the twelve
Owner paths, alter product code, restore Wave 1, authorize formal database
writes, authorize remote push, rewrite historical receipts, or delete failed
evidence. In particular, neither G4 nor R4 creates
`scripts/capture-visual-style-baseline`. After R4 passes, VSB-03 starts again
from R4 and must still complete its full exact twelve-path Owner implementation,
Stage B source validation, and L4 gate.
