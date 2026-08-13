# Cognitura VSB Receipt Correction Design

## 1. Purpose

This specification defines one narrowly scoped recovery transition for the Cognitura Visual Style
Baseline task-card ledger. It preserves the failed receipt, restores a valid linear governance
anchor, and resumes the already approved VSB-02 card without rewriting Git history.

```text
CanonicalProjectName = Cognitura
CorrectionKind = RECEIPT_CORRECTION
CorrectionScope = ONE_FIXED_VSB01_ADVANCE_RECEIPT
CorrectionOriginReceiptSHA = 0ff410961b0f3865652e54ae46453646ed87f69e
ReviewedVSB01CandidateSHA = 108592b757ba50ea6ded7b901bd2b623737a7048
CorrectionMultiplicity = EXACTLY_ONCE
HistoryRewrite = FORBIDDEN
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

This specification changes governance mechanics only. It does not authorize a product route,
component implementation, schema change, database write, screenshot capture, deployment, or push.

## 2. Fixed incident facts

The reviewed VSB-01 candidate is:

```text
C = 108592b757ba50ea6ded7b901bd2b623737a7048
ReviewRoute = deep_reviewer
ReviewVerdict = GO_P0_0_P1_0_P2_0
Gate = VSB-G1_PASS
```

The attempted ledger-only `ADVANCE` receipt is:

```text
O2 = 0ff410961b0f3865652e54ae46453646ed87f69e
Parent(O2) = C
ChangedPaths(C..O2) = docs/task-cards/visual-style-baseline/execution-state.md
```

`O2` correctly records the reviewed VSB-01 candidate, Gate, review route, zero-finding verdict,
completed prefix, and VSB-02 active/released state. It is invalid because it leaves:

```text
NextTaskCard = VSB-02
```

The only correct successor projection is:

```text
NextTaskCard = VSB-03
```

The public transition validator correctly rejected `C -> O2` with:

```text
IN_PROGRESS active, released, or next card mismatch
```

`O2` remains permanent failed evidence. It must never be reclassified as an ordinary `ADVANCE`,
an Owner release receipt, or a valid VSB-02 candidate-chain anchor.

## 3. Alternatives and decision

### 3.1 Rewrite or amend `O2`

Rejected. `reset`, `rebase`, `commit --amend`, replacement refs, force-updated branch refs, and
history-filtering would remove or obscure the failed evidence and violate the repository's
non-amend task-card history.

### 3.2 Reuse `GOVERNANCE_REPAIR`

Rejected. The approved version 1 to version 2 repair is explicitly fixed to
`d47c8c7bd7355947b5e8e1de6c264d80c2e27c9a` and allowed exactly once. Generalizing it would create
an unbounded governance escape hatch.

### 3.3 Add one fixed `RECEIPT_CORRECTION`

Approved. The correction is bound to `O2`, upgrades ledger version 2 to version 3, changes exactly
one incorrect business projection, preserves every reviewed VSB-01 fact, requires a fixed
governance candidate with independent deep and ultra review, and can never be reused.

## 4. Git topology

Let:

```text
D2 = the single-path commit that adds only this approved specification
P2 = the single-path commit that adds only its implementation plan
G2 = the final reviewed governance implementation candidate
R2 = the ledger-only RECEIPT_CORRECTION receipt
```

The required first-parent topology is:

```text
C -> O2 -> D2 -> P2 -> one or more governance implementation commits -> G2 -> R2
```

Every commit from `O2` exclusive through `G2` must:

- have exactly one parent;
- be non-empty;
- change a non-empty subset of the fixed governance WriteSet;
- preserve the execution ledger byte-for-byte and preserve its `100644` mode;
- contain no rename, copy, merge, mode drift, NUL byte, or path outside the governance WriteSet.

The cumulative `O2..G2` path set must equal the fixed governance WriteSet exactly. `R2` must be the
single-parent direct child of `G2` and change only the execution ledger.

## 5. Fixed governance WriteSet

The correction governance candidate owns exactly five paths:

```text
docs/superpowers/specs/2026-08-13-cognitura-vsb-receipt-correction-design.md
docs/superpowers/plans/2026-08-13-cognitura-vsb-receipt-correction.md
docs/task-cards/visual-style-baseline/README.md
scripts/verify-visual-style-baseline-cards
tests/task-cards/verify-visual-style-baseline-cards.sh
```

The execution ledger is deliberately excluded from `G2`. The ledger may change only in `R2` after
`G2` receives both required zero-finding reviews.

The following remain frozen throughout `O2..R2`:

- all VSB-00 and VSB-01 business deliverables;
- all VSB-02 component and visual-reference paths;
- Wave 1 production, server, schema, raw input, historical visual evidence, and screenshots;
- `FormalDatabaseWrite = NOT_AUTHORIZED`;
- `RemotePush = NOT_AUTHORIZED`.

## 6. Approved-spec provenance

`D2` is the commit that adds only this specification. `P2` is the later commit that adds only the
implementation plan. The plan must record the concrete 40-character `D2` SHA; the verifier must use
literal `D2` and `P2` SHAs and must not discover either value from the current branch, tag, remote,
reflog, environment variable, or working tree.

For any pending or completed correction:

- `D2` must be an ancestor of `G2`;
- the specification blob in `G2` must be byte-identical to the blob in `D2`;
- `P2` must be an ancestor of `G2`, and the plan blob in `G2` must be byte-identical to the blob in
  `P2`;
- every commit after `D2` through `G2` must preserve the specification blob and mode exactly;
- every commit after `P2` through `G2` must preserve the plan blob and mode exactly;
- copying the final five-path tree onto an ancestry that excludes `D2` must fail closed;
- changing and later restoring the specification or plan must still fail closed.

## 7. Pending governance-candidate state

At `G2`, the repository ledger is still the byte-identical invalid `O2` version 2 ledger. The
validator may recognize exactly this state as a governance candidate under review and print:

```text
VisualStyleBaselineTaskCardValidation = PASS
TaskCardCount = 4
TaskCardSetStatus = IN_PROGRESS
ActiveTaskCard = VSB-02
ReceiptCorrectionStatus = PENDING
```

This pending branch is valid only when all of the following hold:

- repository `HEAD` is exactly the inspected governance tip;
- `O2` is an ancestor of `HEAD` through one linear first-parent chain;
- the chain satisfies the exact five-path, no-ledger, byte, mode, rename/copy, merge, and provenance
  rules;
- the working ledger equals the `O2` ledger and contains the fixed invalid `NextTaskCard = VSB-02`;
- no `ReceiptCorrection*` fields exist yet;
- no ordinary business candidate or ordinary receipt validation is skipped.

Pending acceptance exists only to allow fixed-SHA review of `G2`. It does not make `O2` an ordinary
receipt and does not release VSB-02.

## 8. Ledger version 3

`R2` upgrades the ledger from version 2 to version 3 and adds exactly these six fields:

```text
ReceiptCorrectionStatus = PASS
ReceiptCorrectionSpecSHA = ${D2}
ReceiptCorrectionOriginReceiptSHA = 0ff410961b0f3865652e54ae46453646ed87f69e
ReceiptCorrectionReviewedCandidateSHA = ${G2}
ReceiptCorrectionReviewRoute = deep_reviewer+ultra_gatekeeper
ReceiptCorrectionReviewVerdict = FINAL_GO_P0_0_P1_0_P2_0
```

`${D2}` and `${G2}` are concrete 40-character commit SHAs when `R2` is constructed. They are not
runtime discovery placeholders.

`R2` must contain this exact task-card state:

```text
ExecutionStateVersion = 3
TaskCardSetStatus = IN_PROGRESS
ActiveTaskCard = VSB-02
ReleasedTaskCard = VSB-02
CompletedTaskCards = VSB-00,VSB-01
CurrentCandidateSHA = 108592b757ba50ea6ded7b901bd2b623737a7048
CurrentGateStatus = VSB-G1_PASS
CurrentReviewRoute = deep_reviewer
CurrentReviewVerdict = GO_P0_0_P1_0_P2_0
VSB01CandidateSHA = 108592b757ba50ea6ded7b901bd2b623737a7048
VSB01GateStatus = VSB-G1_PASS
VSB01ReviewRoute = deep_reviewer
VSB01ReviewVerdict = GO_P0_0_P1_0_P2_0
NextTaskCard = VSB-03
TransitionSequence = 5
TransitionKind = RECEIPT_CORRECTION
TransitionBaseSHA = ${G2}
```

Every other ledger field must be byte-for-byte the same as in `O2`, except for insertion of the six
correction fields and these exact replacements:

```text
ExecutionStateVersion: 2 -> 3
NextTaskCard: VSB-02 -> VSB-03
TransitionSequence: 4 -> 5
TransitionKind: ADVANCE -> RECEIPT_CORRECTION
TransitionBaseSHA: 108592b757ba50ea6ded7b901bd2b623737a7048 -> ${G2}
```

The ledger must remain NUL-free and mode `100644`. Unknown keys, duplicate keys, extra prose,
newline drift, or any other byte difference must fail closed.

## 9. Transition validation

The public correction transition is:

```text
--transition-base ${G2} --transition-head ${R2}
```

It passes only when:

- `R2` has exactly one parent and that parent is `G2`;
- `G2..R2` changes only the execution ledger;
- `G2` has passed the complete pending-candidate validation;
- sequence increments from 4 to 5;
- the exact expected version 3 ledger transform matches byte-for-byte;
- the deep and ultra review route and verdict are exact;
- the reviewed candidate, prior VSB-00/VSB-01 receipts, frozen SHAs, authorizations, repair fields,
  and business state are preserved exactly;
- `O2` remains rejected by every ordinary transition path.

`RECEIPT_CORRECTION` is allowed only when the base ledger is version 2 and has no correction fields.
Any second correction, a version 3 correction base, another origin, another spec, or another
reviewed governance candidate must fail closed.

## 10. Post-correction ordinary execution

After `R2`:

- static validation returns normal `IN_PROGRESS / ActiveTaskCard = VSB-02`;
- `R2`, and only `R2`, is the VSB-02 release anchor;
- an ordinary VSB-02 candidate may contain one or more non-amend commits whose cumulative paths are
  exactly the VSB-02 WriteSet and whose individual commits satisfy existing Owner-chain rules;
- ordinary receipts must preserve all six `ReceiptCorrection*` fields byte-for-byte;
- VSB-02 `ADVANCE` uses `TransitionSequence = 6`;
- VSB-03 terminal `COMPLETE` uses `TransitionSequence = 7` on the no-return path;
- later `RETURN_TO_OWNER`, `STOP_BY_USER`, or other authorized transitions always increment the
  prior sequence by exactly one and never reuse an earlier number.

Neither `O2` nor any governance commit from `D2..G2` may be absorbed into a VSB-02 business
candidate chain.

## 11. Required negative evidence

The contract test must use real Git objects and public verifier entrypoints for at least:

- `O2` rejected as an ordinary receipt and as a VSB-02 anchor;
- copied five-path tree without `D2` ancestry;
- `D2` ancestry with final specification blob drift;
- missing or extra governance path;
- empty governance commit;
- merge commit;
- rename or copy, including Owner-internal paths and low `diff.renameLimit` degradation;
- intermediate ledger modification restored before `G2`;
- NUL byte, newline drift, or file-mode drift;
- wrong origin, spec, reviewed candidate, route, deep verdict, ultra verdict, or sequence;
- missing, duplicate, unknown, or altered correction ledger field;
- `R2` with an extra changed path, wrong parent, merge parent, or non-tip `G2`;
- a second `RECEIPT_CORRECTION`;
- post-`R2` VSB-02 candidate anchored at `O2` or `G2`;
- post-`R2` ordinary receipt that mutates a `ReceiptCorrection*` field.

Positive evidence must include pending `G2`, exact `G2 -> R2`, static version 3, and single-commit and
multi-commit VSB-02 candidate chains rooted at `R2`.

## 12. Review and release gates

Before `R2` may be created, fixed `G2` must pass:

```text
DeepReview = GO_P0_0_P1_0_P2_0
UltraReview = FINAL_GO_P0_0_P1_0_P2_0
```

The reviewers must receive fixed `O2`, `D2`, plan, `G2`, parent and tree SHAs, the exact five-path
WriteSet, ledger blob identity, ancestry and mode evidence, focused RED/GREEN results, Bash 3.2
syntax, and the frozen Wave 1/high-fidelity boundaries.

After `R2`, the following must all pass before VSB-02 implementation resumes:

- explicit `G2 -> R2` transition validation;
- static Visual Style Baseline validation;
- static Wave 1 suspension validation;
- exact ledger-only diff and single-parent topology;
- `git diff --check`;
- worktree audit showing only pre-existing user-owned residue.

## 13. Acceptance criteria

```text
FailedReceiptPreserved = PASS
HistoryRewriteAbsent = PASS
CorrectionFixedToO2 = PASS
CorrectionExactlyOnce = PASS
ApprovedSpecProvenance = PASS
GovernanceWriteSetExact = PASS
LedgerUnchangedThroughG2 = PASS
DeepReview = PASS
UltraReview = PASS
ExactLedgerTransform = PASS
VSB01ReviewFactsPreserved = PASS
VSB02UniqueActiveCard = PASS
NextTaskCardVSB03 = PASS
OrdinaryO2ReplayRejected = PASS
PostCorrectionAnchorR2Only = PASS
FormalDatabaseWriteUnchanged = PASS
RemotePushUnchanged = PASS
```

Any failed criterion is a `NO_GO`; VSB-02 implementation remains paused.
