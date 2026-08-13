# Cognitura Model Gate Routing Design

## 1. Purpose

This specification records the user's latest explicit model-intensity authority for Cognitura and
applies it to the paused Visual Style Baseline receipt correction and the remaining VSB-02/VSB-03
work. It replaces automatic `deep_reviewer + ultra_gatekeeper` stacking with one applicable
highest-level fixed-candidate gate.

```text
CanonicalProjectName = Cognitura
PolicyKind = MODEL_GATE_ROUTING
PolicyVersion = 1
L3DefaultModel = gpt-5.6-sol
L3DefaultReasoningEffort = xhigh
L4DefaultModel = gpt-5.6-sol
L4DefaultReasoningEffort = xhigh
AutomaticDeepPlusUltraStacking = FORBIDDEN
UltraEscalation = EXPLICIT_REASON_REQUIRED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

This specification changes execution and review routing only. It does not authorize product code,
database writes, deployment, remote push, destructive recovery, or Git history rewriting.

## 2. Fixed historical facts

The following commits remain immutable historical evidence:

```text
ReceiptCorrectionOriginReceiptSHA = 0ff410961b0f3865652e54ae46453646ed87f69e
ReceiptCorrectionDesignSHA = dc4a105bbe95b1b07fa0e734cec1148eab15279c
ReceiptCorrectionPlanSHA = f4bd848186a4a4d2d771d0d031340483bfa5de9b
ReviewedVSB01CandidateSHA = 108592b757ba50ea6ded7b901bd2b623737a7048
```

The design and plan blobs at the fixed SHAs must not be amended, reset, rebased, replaced, or
silently rewritten. Their earlier `deep_reviewer+ultra_gatekeeper` wording remains historical fact,
not current execution authority.

This specification supersedes only the model-route, review-count, and review-receipt clauses in the
fixed receipt-correction documents. All other receipt-correction topology, exact-transform,
binary-safety, single-parent, no-ledger, no-rename/copy, and exactly-once requirements remain in
force unless the implementation plan for this specification explicitly tightens them.

## 3. Risk levels

### 3.1 L0 read-only exploration

```text
AgentRole = fast_explorer
Model = gpt-5.6-terra
ReasoningEffort = medium
```

Use for read-only code search, large-file scanning, log summarization, and test-output
classification. L0 never owns implementation decisions or final verdicts.

### 3.2 L1 and L2 implementation

```text
AgentRole = main_or_worker
Model = gpt-5.6-sol
ReasoningEffort = high
```

Use for normal implementation, bounded debugging, tests, local integration, and low-to-medium-risk
design work.

### 3.3 L3 fixed-candidate review

```text
AgentRole = deep_reviewer
Model = gpt-5.6-sol
ReasoningEffort = xhigh
ReviewMultiplicity = ONE_APPLICABLE_GATE
```

Use for ordinary fixed-commit deep review, cumulative candidate-chain review, complex governance,
or a card-level release review that is not an L4 final-stage gate.

### 3.4 L4 final gate

```text
DefaultAgentRole = deep_reviewer
DefaultModel = gpt-5.6-sol
DefaultReasoningEffort = xhigh
ReviewMultiplicity = ONE_APPLICABLE_GATE
```

L4 is a final GO/NO-GO gate, not an instruction to run both L3 and L4. When L4 applies, it replaces
an otherwise redundant L3 review for the same unchanged candidate.

## 4. Ultra escalation

`ultra_gatekeeper` may replace the default L4 xhigh gate only when the main Agent records one of
these concrete reasons before dispatch:

- an irreversible formal database write;
- an irreversible remote external write;
- destructive recovery, deletion, or similarly broad blast radius;
- a critical authentication, authorization, key, or security-boundary change;
- an xhigh review that explicitly cannot close a load-bearing uncertainty;
- a direct user instruction requiring Ultra for the specific candidate.

```text
UltraAgentRole = ultra_gatekeeper
UltraModel = gpt-5.6-sol
UltraReasoningEffort = ultra
UltraRequiresRecordedReason = YES
UltraAutomaticallyFollowsXhigh = NO
```

Cost, historical wording, visual importance, or the existence of an old `deep+ultra` route is not
by itself an escalation reason. Escalation replaces the default xhigh final gate; it does not create
automatic stacked reviews.

## 5. Receipt-correction route

The paused receipt correction is local Git governance. It performs no database write, push,
deployment, destructive history operation, credential change, or security-boundary change.
Therefore its fixed governance candidate uses one L4 xhigh review:

```text
ReceiptCorrectionReviewLevel = L4
ReceiptCorrectionReviewRoute = deep_reviewer
ReceiptCorrectionReviewEffort = xhigh
ReceiptCorrectionReviewMultiplicity = ONE
ReceiptCorrectionReviewVerdict = FINAL_GO_P0_0_P1_0_P2_0
ReceiptCorrectionUltraRequired = NO
```

The eventual version 3 ledger receipt must record `ReceiptCorrectionReviewRoute = deep_reviewer`.
It must not claim that `ultra_gatekeeper` ran when it did not run. A later real escalation requires
a new explicit authority and a receipt value matching the route actually executed.

## 6. VSB-02 and VSB-03 routes

### 6.1 VSB-02

```text
TaskCard = VSB-02
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
```

VSB-02 remains a bounded local visual implementation candidate. One fixed-SHA L3 xhigh review is
required before its ledger-only release receipt.

### 6.2 VSB-03

```text
TaskCard = VSB-03
ReviewLevel = L4
DefaultReviewRoute = deep_reviewer
DefaultReviewEffort = xhigh
DefaultReviewMultiplicity = ONE
UltraRequiredByDefault = NO
```

VSB-03 remains the final visual acceptance candidate, but visual finality alone does not require
Ultra. One L4 xhigh fixed-SHA gate is the default. Ultra may replace it only under section 4.

## 7. Repository migration

The implementation plan for this specification must update the live repository authority without
rewriting the fixed receipt-correction commits. The migration owns only governance and review-route
surfaces:

```text
WriteSet = AGENTS.md
WriteSet = docs/superpowers/specs/2026-08-13-cognitura-model-gate-routing-design.md
WriteSet = docs/superpowers/plans/2026-08-13-cognitura-model-gate-routing.md
WriteSet = docs/task-cards/visual-style-baseline/README.md
WriteSet = docs/task-cards/visual-style-baseline/VSB-02-module-default-reading-visual.md
WriteSet = docs/task-cards/visual-style-baseline/VSB-03-fixed-visual-acceptance.md
WriteSet = scripts/verify-visual-style-baseline-cards
WriteSet = tests/task-cards/verify-visual-style-baseline-cards.sh
```

The new route specification and plan become append-only successors of the earlier receipt-correction
documents. The receipt-correction validator must bind to their literal reviewed SHAs, require their
ancestry and immutable blobs, and expand the pending governance-chain WriteSet explicitly. It must
not discover authority from a branch, tag, remote, reflog, environment variable, or mutable working
tree.

All commits in the expanded governance chain remain single-parent, non-empty, no-ledger, no-merge,
no-rename/copy, NUL-free, mode-preserving, and restricted to the explicitly approved governance
paths. The cumulative path set must equal the revised formal WriteSet exactly.

## 8. Test and evidence requirements

Tests must prove:

- L3 accepts exactly one `deep_reviewer / xhigh` review;
- L4 defaults to exactly one `deep_reviewer / xhigh` final gate;
- the receipt correction no longer requires or records an unexecuted Ultra review;
- VSB-03 no longer requires stacked deep and Ultra reviews;
- a second redundant review cannot be required merely because an old document used the former route;
- Ultra is accepted only with an explicit allowed escalation reason and matching actual route;
- route fields and verdicts are exact and fail closed on missing, duplicate, contradictory, or stale values;
- the fixed historical correction spec/plan blobs remain unchanged;
- the expanded governance chain remains within its exact WriteSet and preserves the execution ledger.

Use real Git fixtures and public verifier entrypoints. Follow RED before GREEN, Bash 3.2
compatibility, binary-safe blob handling, deterministic temporary cleanup, and non-amend commits.

## 9. Acceptance

```text
L3UsesXhigh = PASS
L4DefaultsToXhigh = PASS
AutomaticDeepUltraStacking = ABSENT
UltraRequiresExplicitReason = PASS
ReceiptCorrectionRouteMatchesActualReview = PASS
VSB02Route = SINGLE_L3_XHIGH
VSB03Route = SINGLE_L4_XHIGH_BY_DEFAULT
HistoricalReceiptEvidencePreserved = PASS
ReceiptCorrectionProvenancePreserved = PASS
FormalDatabaseWrite = NOT_PERFORMED
RemotePush = NOT_PERFORMED
```

No route migration is complete until all applicable values are backed by current repository tests,
the fixed candidate receives its one applicable xhigh review, and the worktree contains no tracked
residue outside the approved WriteSet.
