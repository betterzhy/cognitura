# Cognitura Terra-First Model Routing Design

## 1. Purpose

This successor Authority lowers routine execution cost and latency by allowing `gpt-5.6-terra`
to perform more read-only, reversible, and bounded single-Owner work. It preserves `gpt-5.6-sol`
for load-bearing implementation decisions and preserves the existing single `xhigh` fixed-candidate
and final-gate policy.

```text
CanonicalProjectName = Cognitura
PolicyKind = MODEL_GATE_ROUTING
PolicyVersion = 2
RoutingStrategy = TERRA_FIRST_SOL_GATED
EffectiveScope = FUTURE_TASK_DISPATCH
HistoricalReceiptRewrite = FORBIDDEN
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

This policy changes model selection only. It does not authorize product scope, database writes,
deployment, remote push, destructive recovery, task-card release, or Git history rewriting.

## 2. Predecessor and historical facts

The predecessor Authority remains immutable historical evidence:

```text
PredecessorDesign = docs/superpowers/specs/2026-08-13-cognitura-model-gate-routing-design.md
PredecessorPlan = docs/superpowers/plans/2026-08-13-cognitura-model-gate-routing.md
PredecessorL3Default = gpt-5.6-sol/xhigh/ONE
PredecessorL4Default = gpt-5.6-sol/xhigh/ONE
```

This successor supersedes only the current operational L0, L1, and L2 dispatch rules. It does not
modify fixed Visual Style Baseline blobs, historical `deep_reviewer+ultra_gatekeeper` receipts,
named completed-project exceptions, or any recorded review verdict.

## 3. Current routing

### 3.1 L0 read-only exploration

```text
AgentRole = fast_explorer
Model = gpt-5.6-terra
DefaultReasoningEffort = medium
```

Use for exact file, symbol, status, and literal searches, large-file scans, log summarization,
test-output classification, and repository mapping. The configured `fast_explorer` role is fixed at
Terra/medium. L0 never owns a write, implementation decision, Authority interpretation, or final
verdict.

### 3.2 L1 reversible work

```text
AgentRole = main_or_worker
DefaultModel = gpt-5.6-terra
DefaultReasoningEffort = medium
BehavioralReasoningEffort = high
```

L1 covers documentation, tests, deterministic fixtures, formatting, narrow Bash compatibility,
local error messages, and other reversible work that does not alter an R2 boundary. Use `high`
when the change affects observable behavior; otherwise use `medium`.

### 3.3 L2 bounded implementation

```text
AgentRole = main_or_worker
L2DefaultModel = gpt-5.6-terra
L2DefaultReasoningEffort = high
L2EscalatedModel = gpt-5.6-sol
L2EscalatedReasoningEffort = high
```

Terra/high is the default only for a bounded, single-Owner implementation with a clear contract,
safe rollback, and no R2 trigger. Sol/high replaces Terra/high when any of the following applies:

- cross-Owner or cross-module core semantics;
- state machines, identity, idempotency, concurrency, leases, CAS, recovery, or audit invariants;
- public API, event, compatibility, Schema, SQL, DDL, Migration, persistence, or formal projection;
- authentication, authorization, keys, secrets, or another security boundary;
- Authority, Governance, Task Card, Registry, Manifest, release, deployment, or external write;
- destructive behavior, a broad blast radius, or two failed implementation/debugging cycles whose
  root cause remains unexplained.

Terra may still perform read-only search, fixture preparation, and output summarization around an
R2 task, but Sol owns the load-bearing implementation decision and integration.

### 3.4 L3 fixed-candidate review

```text
AgentRole = deep_reviewer
Model = gpt-5.6-sol
ReasoningEffort = xhigh
ReviewMultiplicity = ONE_APPLICABLE_GATE
```

L3 is unchanged. It reviews fixed candidates, cumulative governance chains, complex security or
state-machine changes, and card-level releases that are not an L4 final-stage gate.

### 3.5 L4 final gate

```text
DefaultAgentRole = deep_reviewer
DefaultModel = gpt-5.6-sol
DefaultReasoningEffort = xhigh
ReviewMultiplicity = ONE_APPLICABLE_GATE
```

L4 is unchanged. It replaces a redundant L3 review for the same unchanged candidate and does not
stack a second expensive gate.

## 4. Ultra escalation

Ultra remains an exceptional replacement for the default L4 gate. The main Agent must record an
allowed reason before dispatch: an irreversible formal or external write, destructive recovery or
deletion, a critical authentication/authorization/key boundary, an xhigh review that cannot close
a load-bearing uncertainty, or a direct user instruction for the specific candidate.

```text
UltraAgentRole = ultra_gatekeeper
UltraModel = gpt-5.6-sol
UltraReasoningEffort = ultra
UltraRequiresRecordedReason = YES
UltraAutomaticallyFollowsXhigh = NO
```

## 5. Operational rules

- Risk and project Authority always override cost preference.
- Model choice is based on semantic risk, not line count or file count.
- One unchanged tree receives only the highest applicable expensive gate.
- A Terra task that discovers an escalation trigger stops at a clean boundary and hands the
  load-bearing decision to Sol; it does not silently continue.
- Historical model labels and completed review receipts remain byte-preserved facts.
- This policy is a routing policy, not a task quota; Terra participation is increased where safe,
  but no percentage target can weaken a Gate.

## 6. Acceptance contract

The live `AGENTS.md` must bind this successor as the current operational routing Authority and must
express the L0, L1, L2-default, L2-escalated, L3, L4, and Ultra rules without contradictory current
values. The predecessor design and plan must remain unmodified. The successor is the direct child
of `59144c9dfca4abacce62de41c7306021bf5b83f8` and changes exactly `AGENTS.md`, this specification,
the Wave 1 public verifier, and its test. Relevant Wave 1 and Visual Style Baseline static verifiers
must remain green, and the fixed four-path candidate receives one
`deep_reviewer / gpt-5.6-sol / xhigh / ONE` review before this migration is considered closed.
