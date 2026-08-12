# Cognitura Visual Style Baseline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reverse-engineer the approved historical dashboard reference into a formal Cognitura visual language, project it through one semantic CSS token authority, restyle the existing bounded `ModuleDefaultReading` projection, and produce reproducible real-DOM, computed-style, and screenshot evidence without restoring dashboard architecture.

**Architecture:** Formal design continues to own page structure and behavior. The new Visual Style Reference owns only Visual DNA; five CSS files are its single production projection. The existing `ModuleDefaultReading` remains the production semantic surface, while a separate Vite entry supplies deterministic offline visual evidence without modifying `App.tsx` or creating a product route. A dedicated execution ledger serializes `VSB-00..VSB-03`; Wave 1 card `W1-I03` is frozen at its reviewed candidate and restored only after the final fixed-candidate GO.

**Tech Stack:** Markdown authority records, Bash 3.2-compatible fail-closed validators, Python 3 with Pillow 12.2.0 for one-time pixel-equivalent JPEG-to-PNG import, CSS custom properties, React 19.2.8, TypeScript 7.0.2, Vite 8.1.5, Vitest 4.1.10 with Testing Library/jsdom, exact Node 24.18.0 and pnpm 11.17.0, exact Google Chrome 151.0.7922.109 headless capture, Git fixed commits, `deep_reviewer`, and `ultra_gatekeeper`.

## Global Constraints

- `CanonicalProjectName = Cognitura` for all new engineering and user-visible artifacts. Historical file titles retain `Cognitive Knowledge Atlas` where required by the approved authority chain.
- Approved design authority: `docs/superpowers/specs/2026-08-12-cognitura-visual-style-baseline-design.md` at commit `70eefba5912e6884e4e7e1d6477a65f4091d6590`.
- Branch: `codex/high-fidelity-design-integration`. Do not create a second branch or worktree.
- Preserve untracked `.idea/`; every staged-path check must prove it is absent.
- Freeze `W1-I03` at `4e63936c631ab34807e714b90d30415a959bc13d`. No later commit may modify its eight production WriteSet roots while the visual lane is active.
- The missing historical relationship/page-structure files remain `DOC-GAP-HF-001..003`. Never claim they were read or use this plan to reconstruct their absent contents.
- `DOC-GAP-MDR-001` continues to block a formal Conditions/Results projection. Production JSX and fixtures must not infer those fields.
- Keep the exact eight-section DOM order: `core-questions`, `core-conclusion`, `primary-spine`, `stage-chain`, `boundaries`, `elements`, `relations`, `source-entry`.
- Keep exactly one `data-primary-visual-projection`, one to three formal relations, zero `complementary` regions, and one closed source-entry button.
- Do not modify `web/src/App.tsx`, `web/src/main.tsx`, any router, `server/**`, `schemas/**`, `raw/**`, persistence, migrations, provider configuration, or historical `docs/design/high-fidelity/evidence/**`.
- Do not add Storybook, Playwright, an icon library, remote fonts, network calls, browser storage, glassmorphism, gradients, card walls, a permanent relationship panel, or a dashboard shell.
- The exact Web runtime is Node `24.18.0` and pnpm `11.17.0`; do not relax `.node-version`, `engines`, or `packageManager`.
- `FormalDatabaseWrite = NOT_AUTHORIZED` and `RemotePush = NOT_AUTHORIZED` throughout.
- Use non-amend local commits. Do not reset, force, merge, or push.
- Each business candidate gets a new fixed-SHA `deep_reviewer` review. The final unchanged `VSB-03` candidate also gets `ultra_gatekeeper` GO/NO-GO. Findings return to the owning card and create a new SHA.
- State releases are separate commits. They contain only the Visual Style Baseline execution ledger, except the final Wave 1 restore receipt, whose exact projection WriteSet is listed in Task 5.

## Exact Toolchain Bootstrap

At the start of every Web or browser step, resolve the pinned tools without changing the user's global installation:

```bash
VSB_NODE24_BIN="$(cd web && npm exec --yes --package=node@24.18.0 -- sh -c 'command -v node')"
VSB_PNPM11_BIN="$(cd web && npm exec --yes --package=pnpm@11.17.0 -- sh -c 'command -v pnpm')"
VSB_TOOLCHAIN_PATH="$(dirname "${VSB_NODE24_BIN}"):$(dirname "${VSB_PNPM11_BIN}"):${PATH}"
(
  cd web
  env PATH="${VSB_TOOLCHAIN_PATH}" node --version
  env PATH="${VSB_TOOLCHAIN_PATH}" pnpm --version
)
env PATH="${VSB_TOOLCHAIN_PATH}" pnpm --dir web --version
```

Expected literals:

```text
v24.18.0
11.17.0
11.17.0
```

Resolving both executables from `web/` is mandatory: the repository's parent directory has an unrelated `pnpm@9.15.9` declaration. If either `npm exec` resolution or any literal check fails, stop that card as blocked. Do not substitute Node 24.14.0, pnpm 11.16.0, or the current default Node 23.11.0/pnpm 9.15.9. Every later invocation either runs inside `web/` or uses `pnpm --dir web`; no Gate may use bare root-level `pnpm --version`.

---

## Task 1: Bootstrap governance, suspend W1-I03, and release VSB-00

**Files:**

- Modify: `AGENTS.md`
- Modify: `README.md`
- Modify: `docs/design/wave-1/README.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/engineering/cognitura-wave-1-design-plan.md`
- Modify: `docs/engineering/cognitura-wave-1-design-acceptance.md`
- Modify: `docs/engineering/cognitura-wave-1-implementation-plan.md`
- Modify: `docs/task-cards/README.md`
- Modify: `docs/task-cards/wave-1/README.md`
- Modify: `docs/task-cards/wave-1-implementation/README.md`
- Modify: `docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md` (`Status` only)
- Modify: `scripts/verify-wave1-implementation-cards`
- Modify: `tests/task-cards/verify-wave1-implementation-cards.sh`
- Create: `docs/task-cards/visual-style-baseline/README.md`
- Create: `docs/task-cards/visual-style-baseline/execution-state.md`
- Create: `docs/task-cards/visual-style-baseline/VSB-00-governance-reference.md`
- Create: `docs/task-cards/visual-style-baseline/VSB-01-semantic-tokens.md`
- Create: `docs/task-cards/visual-style-baseline/VSB-02-module-default-reading-visual.md`
- Create: `docs/task-cards/visual-style-baseline/VSB-03-fixed-visual-acceptance.md`
- Create: `scripts/verify-visual-style-baseline-cards`
- Create: `tests/task-cards/verify-visual-style-baseline-cards.sh`

**Interfaces:**

- Consumes: approved spec `70eefba`, current Wave 1 index/card state, fixed `W1-I03` candidate `4e63936`, and user authorization for the written specification.
- Produces: a closed four-card visual lane, a single mutable execution ledger, a fail-closed Wave 1 suspension, and—only after fixed bootstrap review—the unique release of `VSB-00`.

- [ ] **Step 1: Reconfirm the branch, clean scope, frozen candidate, and source attachment**

Run:

```bash
test "$(git branch --show-current)" = "codex/high-fidelity-design-integration"
git merge-base --is-ancestor 70eefba5912e6884e4e7e1d6477a65f4091d6590 HEAD
test "$(git diff --name-only \
  70eefba5912e6884e4e7e1d6477a65f4091d6590..HEAD)" = ""
test -f docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md
test "$(git status --short)" = "?? .idea/
?? docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md"
git status --short
git merge-base --is-ancestor 4e63936c631ab34807e714b90d30415a959bc13d HEAD
test "$(shasum -a 256 /tmp/codex-remote-attachments/019ff394-031c-7413-b56a-f998be9014b8/56C24D47-8B5E-4367-A394-5748FBC8DD5A/1-Photo-1.jpg | awk '{print $1}')" = \
  "812eb50de5b4c7678349bf427977d2917388b70f25f18b6035f55123c7739249"
```

Expected before the plan-record commit: branch and approved-spec HEAD match; the only extra untracked paths are preserved `.idea/` and this plan; the attachment hash check passes. If the plan is already committed, replace the empty committed diff/status literals with the actual plan-only commit SHA, require its diff contains exactly this one plan path, and keep `.idea/` as the only untracked path.

Commit this plan as a separate documentation record before Step 2:

```bash
git add docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md
git diff --cached --check
test "$(git diff --cached --name-only)" = \
  "docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md"
git commit -m "docs: plan Cognitura visual style baseline"
VSB_PLAN_SHA="$(git rev-parse HEAD)"
git diff --quiet 70eefba5912e6884e4e7e1d6477a65f4091d6590 "${VSB_PLAN_SHA}^" --
test "$(git diff --name-only \
  70eefba5912e6884e4e7e1d6477a65f4091d6590.."${VSB_PLAN_SHA}")" = \
  "docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md"
```

The later governance bootstrap begins from `VSB_PLAN_SHA`, never includes the plan file in its WriteSet, and preserves `.idea/` untracked.

- [ ] **Step 2: Add Wave 1 suspension mutation tests before changing its validator**

Extend `tests/task-cards/verify-wave1-implementation-cards.sh` with literal positive fixtures for `SUSPENDED_BY_USER` and restore, then add these literal failures:

```text
SUSPENDED_BY_USER with any READY card
SUSPENDED_BY_USER with ActiveTaskCard other than NONE
suspended card other than W1-I03
two suspended cards
README/card/table status disagreement
missing or duplicated SuspendedTaskCard
missing, short, invalid, non-ancestor, or non-fixed SuspendedCandidateSHA
SuspendedCandidateMutation other than FORBIDDEN
any change after 4e63936 in a frozen W1-I03 production path
BusinessImplementation changed from USER_AUTHORIZED
W1-I02 or W1-I04 released while W1-I03 is suspended
restore that leaves a suspended field populated
restore that releases any card other than W1-I03
restore transition with any production path in its diff
```

The test must initialize a temporary Git repository for the mutation case; copying only the card directory cannot prove a production WriteSet stayed frozen. The fixture must commit a base, commit an allowed `docs/task-cards/visual-style-baseline/example.md` change and observe PASS, then commit a change under `server/src/main/java/io/cognitura/source/docx/security/DocxSecurityGate.java` and observe FAIL.

- [ ] **Step 3: Add Visual Style Baseline state-machine tests before its validator exists**

Create `tests/task-cards/verify-visual-style-baseline-cards.sh` with hand-written expected card order and state transitions. It must reject:

```text
missing or duplicated execution-state.md fields
unknown card ID or fifth VSB card
mutable Status in any VSB card body
missing approved-spec SHA or wrong frozen W1 SHA
activation before bootstrap GO/P0=0/P1=0/P2=0
missing, duplicate, overwritten, or inconsistent per-card candidate/Gate/review receipt
two active/released cards
skipped predecessor or non-prefix CompletedTaskCards
successor release after any non-zero finding
candidate SHA different from TransitionBaseSHA
state transition whose fixed diff is not execution-state.md only
database, backend, App, router, raw, historical-evidence, or remote-push paths in any card WriteSet
VSB in progress while Wave 1 is not exactly suspended
RETURN_TO_OWNER that does not reopen the named owner, truncate CompletedTaskCards to its strict predecessor prefix, or increment TransitionSequence
COMPLETE without all four cards, all four Gates, deep review, and ultra GO
COMPLETE followed by a Wave 1 state other than exact suspended W1-I03 or exact restored READY W1-I03
```

Use the same `--transition-base SHA --transition-head SHA` direct-child contract as `scripts/verify-module-default-reading-implementation-cards`: `TransitionBaseSHA` equals the reviewed candidate SHA and that candidate is the direct parent of the transition head; a release receipt changes only `docs/task-cards/visual-style-baseline/execution-state.md`, and the ledger content matches the transition HEAD tree.

The validator must explicitly support one rollback transition for evidence or review findings:

```text
TransitionKind = RETURN_TO_OWNER
Owner = VSB-00|VSB-01|VSB-02|VSB-03
ActiveTaskCard = Owner
ReleasedTaskCard = Owner
CompletedTaskCards = exact strict predecessor prefix of Owner
NextTaskCard = exact successor of Owner, or NONE for VSB-03
CurrentGateStatus = FAIL
CurrentReviewVerdict = FINDING_P0_n_P1_n_P2_n or VISUAL_ACCEPTANCE_FAIL
```

It remains a ledger-only direct-child commit. Returning to an owner never preserves a later card as completed, never releases two cards, and never changes Wave 1 suspension.

The ledger carries immutable-by-successor per-card receipts:

```text
VSB00CandidateSHA = NONE
VSB00GateStatus = NOT_RUN
VSB00ReviewRoute = deep_reviewer
VSB00ReviewVerdict = NOT_RUN
VSB01CandidateSHA = NONE
VSB01GateStatus = NOT_RUN
VSB01ReviewRoute = deep_reviewer
VSB01ReviewVerdict = NOT_RUN
VSB02CandidateSHA = NONE
VSB02GateStatus = NOT_RUN
VSB02ReviewRoute = deep_reviewer
VSB02ReviewVerdict = NOT_RUN
VSB03CandidateSHA = NONE
VSB03GateStatus = NOT_RUN
VSB03ReviewRoute = deep_reviewer+ultra_gatekeeper
VSB03DeepReviewVerdict = NOT_RUN
VSB03UltraReviewVerdict = NOT_RUN
```

An `ADVANCE` receipt fills only the just-completed card's receipt fields. `RETURN_TO_OWNER` resets the owner and every successor receipt to `NONE/NOT_RUN`, while preserving the strict predecessor receipts; invalidated values remain auditable in Git history. `COMPLETE` checks every candidate as a resolvable 40-character commit SHA, `VSB00GateStatus = VSB-G0_PASS`, `VSB01GateStatus = VSB-G1_PASS`, `VSB02GateStatus = VSB-G2_PASS`, `VSB03GateStatus = VSB-G3_PASS`, three owner-card deep-review zero-finding verdicts, and both VSB-03 deep/ultra zero-finding verdicts.

The `TransitionSequence = 1..5` values shown below are exact for the first-pass path. After any `RETURN_TO_OWNER` or explicit stop transition, every later receipt uses `previous TransitionSequence + 1`; it never reuses the first-pass number. The card order, strict completed prefix, Gate, review, and transition-base rules remain unchanged.

- [ ] **Step 4: Run both focused tests and observe RED**

```bash
/bin/bash tests/task-cards/verify-wave1-implementation-cards.sh
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh
```

Expected: the Wave 1 test fails because `SUSPENDED_BY_USER` is unsupported; the VSB test fails because its validator and governed set do not exist.

- [ ] **Step 5: Implement the exact Wave 1 suspended state**

Add optional `--repo-root PATH`, `--transition-base SHA`, and `--transition-head SHA` parsing to `scripts/verify-wave1-implementation-cards`. Resolve the default repo root from the script path. The only frozen production paths are:

```bash
frozen_w1_i03_paths=(
  server/src/main/java/io/cognitura/source/docx/security/DocxSecurityGate.java
  server/src/main/java/io/cognitura/source/docx/security/DocxPackageLimits.java
  server/src/main/java/io/cognitura/source/docx/security/DocxRelationshipClassifier.java
  server/src/main/java/io/cognitura/source/docx/security/DocxSecurityViolation.java
  server/src/main/java/io/cognitura/source/docx/security/SafeDocxPackage.java
  server/src/test/java/io/cognitura/source/docx/security/DocxSecurityGateTest.java
  server/src/test/java/io/cognitura/source/docx/security/ExternalRelationshipIsolationTest.java
  server/src/test/resources/docx/security
)
```

In the `SUSPENDED_BY_USER` branch, require these exact facts:

```text
TaskCardSetStatus = SUSPENDED_BY_USER
ActiveTaskCard = NONE
SuspendedTaskCard = W1-I03
SuspendedCandidateSHA = 4e63936c631ab34807e714b90d30415a959bc13d
SuspendedCandidateMutation = FORBIDDEN
BusinessImplementation = USER_AUTHORIZED
W1-I00 = DONE
W1-I01 = DONE
W1-I02 = QUEUED
W1-I03 = SUSPENDED_BY_USER
W1-I04..W1-I13 = BLOCKED_BY_DEPENDENCY
ReadyTaskCardCount = 0
SuspendedTaskCardCount = 1
```

Resolve `SuspendedCandidateSHA^{commit}`, require it is an ancestor of HEAD, then run:

```bash
git -C "${repo_root}" diff --quiet \
  4e63936c631ab34807e714b90d30415a959bc13d..HEAD -- \
  "${frozen_w1_i03_paths[@]}"
```

Retain the existing normalized card digest so only `Status` may change in `W1-I03`. Do not add `SUSPENDED_BY_USER` as a generic dependency-satisfied status; allow it only for `W1-I03` when the set itself is suspended.

Project the suspension across exactly these ten current authority/status documents:

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
docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md
```

`docs/task-cards/wave-1-implementation/README.md` gets the three explicit suspension fields. `docs/task-cards/README.md` only registers the new VSB set and its execution-state authority. Central documents must point to the VSB ledger rather than duplicate VSB active-card facts.

For `--transition-base/--transition-head`, the Wave 1 validator supports only the final restore transition. It requires a direct child, a suspended base tree, a restored head tree, and a diff containing exactly the same ten paths above—no more and no fewer. It must reject any server, Web, Schema, raw, database, `.idea/`, or evidence path in that transition.

Without transition arguments it validates the current state, including the suspension written by the multi-path bootstrap. With transition arguments it accepts only the ten-path direct-child restore when the VSB ledger in the base tree is either `COMPLETE` or `STOPPED_BY_USER` with `UserStopAuthorization = EXPLICIT_USER_INSTRUCTION`; passing the suspension bootstrap itself as a transition fixture must fail. Both `docs/engineering/cognitura-wave-1-design-plan.md` and `docs/task-cards/wave-1/README.md` project `ActiveImplementationGovernanceTaskCard = NONE` during suspension and `W1-I03` after restore. Add a mutation that leaves either projection at `W1-I03` during suspension and require failure.

- [ ] **Step 6: Create the four immutable VSB cards and initial ledger**

Every VSB card body uses:

```text
Status = GOVERNED_BY_EXECUTION_STATE
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The exact card contracts are:

| Card | DependsOn | Gate | ReviewRoute | Business WriteSet |
|---|---|---|---|---|
| `VSB-00` | `GOVERNANCE_BOOTSTRAP` | `VSB-G0 GOVERNANCE_AND_REFERENCE` | `deep_reviewer` | reference PNG; Style Reference; authority bridge/index; reference importer/verifier/tests |
| `VSB-01` | `VSB-00` | `VSB-G1 SEMANTIC_TOKENS` | `deep_reviewer` | five `web/src/styles/*.css`; style contract; exact-toolchain verifier repair/test |
| `VSB-02` | `VSB-01` | `VSB-G2 MODULE_DEFAULT_READING_VISUAL` | `deep_reviewer` | existing module-reading presentation/tests; independent Vite visual-reference entry/fixture/tests |
| `VSB-03` | `VSB-02` | `VSB-G3 FIXED_VISUAL_ACCEPTANCE` | `deep_reviewer+ultra_gatekeeper` | capture/verifier/tests; new visual evidence/manifest; acceptance report |

Forbid these literals in every card:

```text
server/**
schemas/**
raw/**
web/src/App.tsx
web/src/main.tsx
web/src/routes/**
docs/design/high-fidelity/evidence/**
.idea/**
FORMAL_DATABASE_WRITE
REMOTE_PUSH
```

Lock each normalized card digest as a literal in `scripts/verify-visual-style-baseline-cards` after the four bodies are final. The normalizer may replace only the `Status` line; the mutation test must prove every other character change fails.

The card WriteSet fields must enumerate the exact non-ledger file list from their corresponding Task 2, Task 3, Task 4, or Task 5 `Files` block. Do not use globs except the four fixed PNG names already enumerated in Task 5; the validator compares the sorted literal lists.

Create `execution-state.md` with this exact initial block:

```text
CanonicalProjectName = Cognitura
TaskCardSet = VISUAL_STYLE_BASELINE
ExecutionStateVersion = 1
ExecutionStateAuthority = THIS_DOCUMENT
ApprovedSpecSHA = 70eefba5912e6884e4e7e1d6477a65f4091d6590
GovernanceBootstrapStatus = AWAITING_FIXED_COMMIT_REVIEW
GovernanceReviewedCandidateSHA = NONE
GovernanceReviewRoute = deep_reviewer
GovernanceReviewVerdict = NOT_RUN
SetAuthorizationStatus = USER_AUTHORIZED
SetAuthorizationScope = VSB-00..VSB-03_AUTOMATIC_SERIAL
HumanCheckpointRequirement = NONE_WITHIN_AUTHORIZED_SET
TaskCardSetStatus = USER_AUTHORIZED_AWAITING_GOVERNANCE_REVIEW
ActiveTaskCard = NONE
ReleasedTaskCard = NONE
CompletedTaskCards = NONE
CurrentCandidateSHA = NONE
CurrentGateStatus = NOT_RUN
CurrentReviewRoute = NONE
CurrentReviewVerdict = NOT_RUN
VSB00CandidateSHA = NONE
VSB00GateStatus = NOT_RUN
VSB00ReviewRoute = deep_reviewer
VSB00ReviewVerdict = NOT_RUN
VSB01CandidateSHA = NONE
VSB01GateStatus = NOT_RUN
VSB01ReviewRoute = deep_reviewer
VSB01ReviewVerdict = NOT_RUN
VSB02CandidateSHA = NONE
VSB02GateStatus = NOT_RUN
VSB02ReviewRoute = deep_reviewer
VSB02ReviewVerdict = NOT_RUN
VSB03CandidateSHA = NONE
VSB03GateStatus = NOT_RUN
VSB03ReviewRoute = deep_reviewer+ultra_gatekeeper
VSB03DeepReviewVerdict = NOT_RUN
VSB03UltraReviewVerdict = NOT_RUN
NextTaskCard = VSB-00
TransitionSequence = 0
TransitionKind = BOOTSTRAP
TransitionBaseSHA = NONE
FrozenWave1TaskCard = W1-I03
FrozenWave1CandidateSHA = 4e63936c631ab34807e714b90d30415a959bc13d
HistoricalVisualEvidenceBaselineSHA = 70eefba5912e6884e4e7e1d6477a65f4091d6590
VisualImplementation = USER_AUTHORIZED_PENDING_GOVERNANCE_REVIEW
FullProductImplementation = NOT_AUTHORIZED
UserStopAuthorization = NONE
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The allowed set states are a closed list:

```text
USER_AUTHORIZED_AWAITING_GOVERNANCE_REVIEW
IN_PROGRESS
STOPPED_BY_USER
FINAL_NO_GO
COMPLETE
```

`STOPPED_BY_USER` has no active/released/next card and requires `UserStopAuthorization = EXPLICIT_USER_INSTRUCTION`; the primary agent may set that literal only after an actual new user stop instruction. It permits a separate ten-path W1 restore receipt while keeping all frozen paths unchanged. `FINAL_NO_GO` has no active/released/next card and never restores Wave 1 automatically; a later explicit user stop may transition it by ledger-only receipt to `STOPPED_BY_USER`, after which the same restore rule applies. Add a positive stopped restore fixture and negative restore fixtures for missing/false user-stop authorization. `COMPLETE` is valid only with all four completed cards, all immutable per-card Gate/review receipts, and Wave 1 either still in the exact suspended state or already in the exact restored READY state.

- [ ] **Step 7: Make the governance tests GREEN and run the wider governance Gate**

```bash
/bin/bash tests/task-cards/verify-wave1-implementation-cards.sh
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh
scripts/verify-wave1-implementation-cards \
  --repo-root . \
  --cards-dir docs/task-cards/wave-1-implementation
scripts/verify-visual-style-baseline-cards \
  --repo-root . \
  --cards-dir docs/task-cards/visual-style-baseline
bash tests/ci/verify-markdown-links.sh
git diff --check
git status --short
```

Expected: all validators PASS; Wave 1 reports `SUSPENDED_BY_USER`, VSB reports `USER_AUTHORIZED_AWAITING_GOVERNANCE_REVIEW`, no visual deliverable exists yet, and `.idea/` remains the only unrelated untracked path.

- [ ] **Step 8: Commit the bootstrap candidate with its exact WriteSet**

Stage only the paths listed under Task 1, then run:

```bash
git diff --cached --check
git diff --cached --name-only
git commit -m "build: govern visual style baseline execution"
VSB_BOOTSTRAP_CANDIDATE_SHA="$(git rev-parse HEAD)"
git show --stat --oneline "${VSB_BOOTSTRAP_CANDIDATE_SHA}"
```

Expected: no reference PNG, CSS, production component, Visual Reference, screenshot, server path, `raw/**`, `.idea/`, or historical evidence file is in the commit.

- [ ] **Step 9: Obtain a fixed-SHA zero-finding bootstrap review**

Dispatch a fresh `deep_reviewer` with the fixed SHA, the approved spec SHA, exact Task 1 WriteSet, all mutation commands, and these questions: suspension atomicity, frozen-candidate protection, duplicate authority, transition fail-closed behavior, accidental implementation authorization, and restore safety.

Required verdict:

```text
GeneralReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
```

Any finding returns to Task 1 Step 2, adds a reproducing failure, creates a new non-amend candidate, and receives a new reviewer.

- [ ] **Step 10: Release VSB-00 in a ledger-only receipt**

After zero findings, edit only `docs/task-cards/visual-style-baseline/execution-state.md` to:

```text
GovernanceBootstrapStatus = PASS
GovernanceReviewedCandidateSHA = ${VSB_BOOTSTRAP_CANDIDATE_SHA}
GovernanceReviewVerdict = GO_P0_0_P1_0_P2_0
TaskCardSetStatus = IN_PROGRESS
ActiveTaskCard = VSB-00
ReleasedTaskCard = VSB-00
CompletedTaskCards = NONE
CurrentCandidateSHA = NONE
CurrentGateStatus = NOT_RUN
CurrentReviewRoute = NONE
CurrentReviewVerdict = NOT_RUN
NextTaskCard = VSB-01
TransitionSequence = 1
TransitionKind = ACTIVATE_SET
TransitionBaseSHA = ${VSB_BOOTSTRAP_CANDIDATE_SHA}
VisualImplementation = USER_AUTHORIZED
```

`${VSB_BOOTSTRAP_CANDIDATE_SHA}` is an execution variable: paste the exact 40-character value printed by Git. The committed ledger must contain no dollar sign or symbolic ref. Then:

```bash
git add docs/task-cards/visual-style-baseline/execution-state.md
git diff --cached --name-only
git commit -m "chore: release visual style reference card"
VSB_BOOTSTRAP_RECEIPT_SHA="$(git rev-parse HEAD)"
scripts/verify-visual-style-baseline-cards \
  --repo-root . \
  --cards-dir docs/task-cards/visual-style-baseline \
  --transition-base "${VSB_BOOTSTRAP_CANDIDATE_SHA}" \
  --transition-head "${VSB_BOOTSTRAP_RECEIPT_SHA}"
```

Expected: the transition diff is exactly one ledger path and `VSB-00` is the unique active/released card.

If the user gives a new explicit stop instruction before VSB completion, do not execute another business step. Preserve any unstaged user/visual files, then commit only the ledger with:

```text
TaskCardSetStatus = STOPPED_BY_USER
ActiveTaskCard = NONE
ReleasedTaskCard = NONE
CompletedTaskCards = the already reviewed strict prefix, or NONE
CurrentGateStatus = STOPPED_BY_USER
CurrentReviewRoute = NONE
CurrentReviewVerdict = NOT_APPLICABLE_USER_STOP
NextTaskCard = NONE
TransitionSequence = previous value plus 1
TransitionKind = STOP_BY_USER
TransitionBaseSHA = the exact parent HEAD of this ledger-only receipt
VisualImplementation = STOPPED_BY_USER
UserStopAuthorization = EXPLICIT_USER_INSTRUCTION
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

`TransitionBaseSHA` is the exact 40-character `git rev-parse HEAD` value captured before the stop receipt. Keep all per-card receipts for the reviewed strict prefix; reset the interrupted owner and successors to `NONE/NOT_RUN`. Validate and commit only `execution-state.md`, then use the same exact ten-path Wave 1 restore projection defined in Task 5 Step 15 with the stop receipt as `--transition-base`. Do not stage unfinished visual files, do not discard them, and report them as preserved dirty state before any later W1 card execution. `FINAL_NO_GO` alone does not take this branch; it first needs the new explicit user stop instruction and the ledger transition above.

---

## Task 2: VSB-00 — import the reference and establish the formal Visual Style Reference

**Files:**

- Modify: `AGENTS.md`
- Create: `docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png`
- Create: `docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md`
- Modify: `docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Create: `docs/engineering/cognitura-visual-style-baseline-manifest.yaml`
- Create: `scripts/import-visual-style-reference`
- Create: `scripts/verify-visual-style-baseline-reference`
- Create: `tests/visual-style-baseline/verify-reference.sh`
- Modify after review only: `docs/task-cards/visual-style-baseline/execution-state.md`

**Interfaces:**

- Consumes: actual JPEG attachment SHA `812eb50de5b4c7678349bf427977d2917388b70f25f18b6035f55123c7739249`, approved measured/inferred Visual DNA, formal Reading First authority, and active ledger card `VSB-00`.
- Produces: pixel-equivalent repository PNG SHA `a8446ea987f6a1710c3845f837e2776190997b77f81584cf7b667cbfebe2f95f`, a formal style-only reference, an explicit bridge from historical HV evidence, and a reproducible authority/reference verifier.

- [ ] **Step 1: Prove the only active lane and immutable baselines**

```bash
scripts/verify-wave1-implementation-cards \
  --repo-root . \
  --cards-dir docs/task-cards/wave-1-implementation
scripts/verify-visual-style-baseline-cards \
  --repo-root . \
  --cards-dir docs/task-cards/visual-style-baseline
test "$(sed -n 's/^ActiveTaskCard = //p' docs/task-cards/visual-style-baseline/execution-state.md)" = "VSB-00"
git diff --quiet \
  4e63936c631ab34807e714b90d30415a959bc13d..HEAD -- \
  server/src/main/java/io/cognitura/source/docx/security \
  server/src/test/java/io/cognitura/source/docx/security \
  server/src/test/resources/docx/security
git diff --quiet \
  70eefba5912e6884e4e7e1d6477a65f4091d6590..HEAD -- \
  docs/design/high-fidelity/evidence
```

Expected: both validators PASS; VSB-00 is active; the frozen W1 production tree and historical visual evidence are unchanged.

- [ ] **Step 2: Write the reference contract test first**

Create `tests/visual-style-baseline/verify-reference.sh`. Its positive fixture must assert all of these exact values:

```text
SourceMediaType = image/jpeg
SourcePixelSize = 1280x853
SourceSizeBytes = 210103
SourceSHA256 = 812eb50de5b4c7678349bf427977d2917388b70f25f18b6035f55123c7739249
ReferenceMediaType = image/png
ReferencePixelSize = 1280x853
ReferenceSizeBytes = 867083
ReferenceSHA256 = a8446ea987f6a1710c3845f837e2776190997b77f81584cf7b667cbfebe2f95f
ReferenceRole = VISUAL_STYLE_REFERENCE_ONLY
PageArchitectureAuthority = NO
InteractionAuthority = NO
DashboardLayoutAuthority = NO
ManifestPath = docs/engineering/cognitura-visual-style-baseline-manifest.yaml
```

Add literal negative copies for: wrong source hash, wrong PNG hash, 1×1 PNG, altered decoded pixel, missing `INFERRED`, `DashboardLayoutAuthority = YES`, missing `DOC-GAP-HF-001`, missing historical-token demotion, missing manifest, wrong manifest document size/hash, wrong manifest reference hash, wrong activation Gate, and an AGENTS authority entry that grants IA/interaction/dashboard authority.

- [ ] **Step 3: Run the contract and observe RED**

```bash
/bin/bash tests/visual-style-baseline/verify-reference.sh
```

Expected: FAIL because the importer, reference PNG, formal document, and authority bridge do not exist.

- [ ] **Step 4: Implement a no-replace, pixel-equivalent importer**

Create `scripts/import-visual-style-reference` as Bash 3.2-compatible orchestration around this exact Python operation:

```python
from hashlib import sha256
from pathlib import Path
from PIL import Image, ImageChops, __version__ as pillow_version
import sys

source_path = Path(sys.argv[1])
output_path = Path(sys.argv[2])
if pillow_version != "12.2.0":
    raise SystemExit(f"expected Pillow 12.2.0, got {pillow_version}")
if sha256(source_path.read_bytes()).hexdigest() != "812eb50de5b4c7678349bf427977d2917388b70f25f18b6035f55123c7739249":
    raise SystemExit("source JPEG SHA-256 mismatch")

with Image.open(source_path) as source_image:
    decoded_source = source_image.convert("RGB")
    if decoded_source.size != (1280, 853):
        raise SystemExit("source JPEG dimensions mismatch")
    decoded_source.save(output_path, format="PNG", optimize=False, compress_level=6)

with Image.open(output_path) as output_image:
    decoded_output = output_image.convert("RGB")
    if decoded_output.size != (1280, 853):
        raise SystemExit("output PNG dimensions mismatch")
    if ImageChops.difference(decoded_source, decoded_output).getbbox() is not None:
        raise SystemExit("output PNG is not pixel-equivalent")

if sha256(output_path.read_bytes()).hexdigest() != "a8446ea987f6a1710c3845f837e2776190997b77f81584cf7b667cbfebe2f95f":
    raise SystemExit("output PNG SHA-256 mismatch")
```

The Bash wrapper must:

1. accept exactly `--source-jpeg PATH --output-png PATH`;
2. refuse a source hash mismatch before decoding;
3. create the output in the destination directory through a temporary file;
4. if the destination already exists, verify the exact PNG hash and exit without overwriting;
5. use `mv -n` only after all checks pass;
6. print the source hash, output hash, dimensions, and `PixelEquivalence = PASS`.

Run it once against the actual attachment:

```bash
mkdir -p docs/design/reference
scripts/import-visual-style-reference \
  --source-jpeg /tmp/codex-remote-attachments/019ff394-031c-7413-b56a-f998be9014b8/56C24D47-8B5E-4367-A394-5748FBC8DD5A/1-Photo-1.jpg \
  --output-png docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png
```

Expected: `PixelEquivalence = PASS`, 1280×853, 867083 bytes, and exact PNG SHA `a8446ea987f6a1710c3845f837e2776190997b77f81584cf7b667cbfebe2f95f`.

- [ ] **Step 5: Create the formal style-only document with observation confidence**

Start `docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md` with this exact authority block:

```text
CanonicalProjectName = Cognitura
HistoricalDocumentName = Cognitive-Knowledge-Atlas-Visual-Style-Reference
Version = 1.0
Status = FORMAL_VISUAL_STYLE_BASELINE
ActivationAuthority = docs/task-cards/visual-style-baseline/execution-state.md
ActivationGate = VSB-G0 GOVERNANCE_AND_REFERENCE
ReferencePath = docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png
ReferenceRole = VISUAL_STYLE_REFERENCE_ONLY
SourceMediaType = image/jpeg
SourcePixelSize = 1280x853
SourceSizeBytes = 210103
SourceSHA256 = 812eb50de5b4c7678349bf427977d2917388b70f25f18b6035f55123c7739249
ReferenceMediaType = image/png
ReferencePixelSize = 1280x853
ReferenceSizeBytes = 867083
ReferenceSHA256 = a8446ea987f6a1710c3845f837e2776190997b77f81584cf7b667cbfebe2f95f
PixelEquivalence = PASS
ConversionTool = Pillow 12.2.0
ConversionOperation = RGB_PNG_OPTIMIZE_FALSE_COMPRESS_LEVEL_6
PageArchitectureAuthority = NO
InteractionAuthority = NO
InformationArchitectureAuthority = NO
ComponentHierarchyAuthority = NO
CardQuantityAuthority = NO
DashboardLayoutAuthority = NO
```

Include all required roles as an observation/normalized/confidence/rationale table. The normalized color rows are exactly:

```text
CanvasBackground = #F7F9FC
PrimarySurface = #FFFFFF
SecondarySurface = #FAFBFD
TertiarySurface = #F5F7FA
BorderSubtle = #E7EAF0
BorderDefault = #E2E6EC
BorderStrong = #D4DAE3
TextPrimary = #172033
TextSecondary = #475467
TextMuted = #667085
TextSubtle = #98A2B3
PrimaryColor = #4F67E8
PrimaryHover = #455BDD
PrimaryActive = #3D50C9
PrimarySoft = #EEF2FF
FocusColor = #7C6CF2
FocusSoft = #F3F0FF
Success = #278C68
SuccessSoft = #ECF8F3
Warning = #C98526
WarningSoft = #FFF6E5
Danger = #D64F58
DangerSoft = #FFF0F1
Information = #4385E0
InformationSoft = #EEF6FF
```

Mark pixel-cluster observations `MEASURED_FROM_REFERENCE_PIXELS`. Mark font identity, sizes, weights, spacing, radii, shadow, icon stroke, controls, motion, density, and semantic usage `INFERRED`; never use `MEASURED` for them. Include exact Typography, Spacing, Radius, Shadow, Icon, Button, Badge, Relation, Reading Surface, Card Budget, Semantic Color Budget, and forbidden dashboard/AI-SaaS rules from the approved spec.

Create `docs/engineering/cognitura-visual-style-baseline-manifest.yaml` after the formal Markdown bytes are final. It contains only literal values:

```yaml
canonicalProjectName: Cognitura
document:
  path: docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md
  version: "1.0"
  mediaType: text/markdown
  sizeBytes: ${VSB_STYLE_REFERENCE_SIZE_BYTES}
  sha256: ${VSB_STYLE_REFERENCE_SHA256}
referenceImage:
  path: docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png
  mediaType: image/png
  pixelSize: 1280x853
  sizeBytes: 867083
  sha256: a8446ea987f6a1710c3845f837e2776190997b77f81584cf7b667cbfebe2f95f
scope: VISUAL_DNA_AND_SEMANTIC_TOKENS_ONLY
activationStateAuthority: docs/task-cards/visual-style-baseline/execution-state.md
activationGate: VSB-G0 GOVERNANCE_AND_REFERENCE
excludedAuthorities:
  - PAGE_ARCHITECTURE
  - INTERACTION
  - INFORMATION_ARCHITECTURE
  - COMPONENT_HIERARCHY
  - CARD_QUANTITY
  - DASHBOARD_LAYOUT
```

Set the two execution variables from the finished Markdown before editing the manifest:

```bash
VSB_STYLE_REFERENCE_SIZE_BYTES="$(wc -c < docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md | tr -d ' ')"
VSB_STYLE_REFERENCE_SHA256="$(shasum -a 256 docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md | awk '{print $1}')"
```

Write those literal values into YAML; the committed manifest contains no dollar signs or symbolic refs. The manifest validator rejects zero, non-decimal size, non-64-character hash, mismatch, duplicate YAML keys, and unknown top-level keys.

- [ ] **Step 6: Bridge rather than overwrite the historical HV visual authority**

Add this exact projection block to `docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md`:

```text
CurrentVisualStyleAuthority = docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md
CurrentVisualStyleProjection = web/src/styles/**
LegacyPrototypeTokenRole = HISTORICAL_EVIDENCE_RENDERING_ONLY
HistoricalHVEvidenceValidity = PRESERVED
HistoricalHVEvidenceOverwrite = FORBIDDEN
```

Do not edit its prior colors, typography, screenshots, or historical Gate records. In `docs/engineering/cognitura-design-index.md`, register the new document beneath Overall and the formal HF interaction specialty, preserve explicit `DOC-GAP-HF-001..003`, and state that the reference has no architecture or interaction authority.

In `AGENTS.md` add the new source below Overall and the formal HF interaction specialty, never above them:

```text
VisualStyleReferenceAuthority = docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md
VisualStyleReferenceManifest = docs/engineering/cognitura-visual-style-baseline-manifest.yaml
VisualStyleReferenceScope = VISUAL_DNA_AND_SEMANTIC_TOKENS_ONLY
VisualStyleReferencePageArchitectureAuthority = NO
VisualStyleReferenceInteractionAuthority = NO
VisualStyleReferenceDashboardLayoutAuthority = NO
```

`docs/engineering/cognitura-design-index.md` references both the formal Markdown and its manifest. This addition does not rename historical design files or let the visual reference override Overall, Schema, Construction, UIUX, or HF interaction contracts.

- [ ] **Step 7: Implement the standalone reference verifier and make tests GREEN**

`scripts/verify-visual-style-baseline-reference` must accept `--repo-root PATH` and optional `--source-jpeg PATH`. Without the source it verifies the committed PNG bytes/dimensions/mode, formal-document literals, authority bridge, index registration, and every required semantic role. With the source it additionally verifies source SHA/size and decoded-pixel equality.

```bash
/bin/bash tests/visual-style-baseline/verify-reference.sh
scripts/verify-visual-style-baseline-reference \
  --repo-root . \
  --source-jpeg /tmp/codex-remote-attachments/019ff394-031c-7413-b56a-f998be9014b8/56C24D47-8B5E-4367-A394-5748FBC8DD5A/1-Photo-1.jpg
scripts/verify-visual-style-baseline-cards \
  --repo-root . \
  --cards-dir docs/task-cards/visual-style-baseline
bash tests/ci/verify-markdown-links.sh
git diff --check
```

Expected: all PASS, with no CSS, production JSX, Vite Visual Reference page, screenshot, or historical evidence change. The formal Style Reference, its manifest, reference PNG, AGENTS scope entry, authority bridge, index, importer, verifier, and tests are the only VSB-00 changes.

- [ ] **Step 8: Commit and review the VSB-00 candidate**

Stage exactly the nine business paths listed at the top of Task 2, excluding the execution ledger until the later receipt:

```bash
git diff --cached --check
git diff --cached --name-only
git commit -m "docs: establish Cognitura visual style reference"
VSB00_CANDIDATE_SHA="$(git rev-parse HEAD)"
```

Dispatch a fresh `deep_reviewer` against that exact SHA. Required review dimensions: source/provenance correctness, PNG pixel equivalence, measured-vs-inferred honesty, authority precedence, missing-doc honesty, semantic token completeness, no dashboard authority, no historical evidence mutation, and card WriteSet. Require `GO / P0=0 / P1=0 / P2=0`.

- [ ] **Step 9: Release VSB-01 with a ledger-only receipt**

Use the exact 40-character `VSB00_CANDIDATE_SHA` value in these ledger fields:

```text
TaskCardSetStatus = IN_PROGRESS
ActiveTaskCard = VSB-01
ReleasedTaskCard = VSB-01
CompletedTaskCards = VSB-00
CurrentCandidateSHA = ${VSB00_CANDIDATE_SHA}
CurrentGateStatus = VSB-G0_PASS
CurrentReviewRoute = deep_reviewer
CurrentReviewVerdict = GO_P0_0_P1_0_P2_0
VSB00CandidateSHA = ${VSB00_CANDIDATE_SHA}
VSB00GateStatus = VSB-G0_PASS
VSB00ReviewRoute = deep_reviewer
VSB00ReviewVerdict = GO_P0_0_P1_0_P2_0
NextTaskCard = VSB-02
TransitionSequence = 2
TransitionKind = ADVANCE
TransitionBaseSHA = ${VSB00_CANDIDATE_SHA}
```

`${VSB00_CANDIDATE_SHA}` means the exact value printed by Git; the committed ledger must contain no dollar sign or symbolic ref.

```bash
git add docs/task-cards/visual-style-baseline/execution-state.md
git commit -m "chore: release visual token card"
VSB00_RECEIPT_SHA="$(git rev-parse HEAD)"
scripts/verify-visual-style-baseline-cards \
  --repo-root . \
  --cards-dir docs/task-cards/visual-style-baseline \
  --transition-base "${VSB00_CANDIDATE_SHA}" \
  --transition-head "${VSB00_RECEIPT_SHA}"
```

Expected: only the ledger changed; VSB-01 is unique active/released; Wave 1 remains suspended.

---

## Task 3: VSB-01 — implement the single semantic CSS token projection

**Files:**

- Create: `web/src/styles/tokens.css`
- Create: `web/src/styles/typography.css`
- Create: `web/src/styles/surfaces.css`
- Create: `web/src/styles/cognitive-visual.css`
- Create: `web/src/styles/cognitura.css`
- Create: `web/src/styles/style-contract.test.ts`
- Modify: `scripts/verify-module-default-reading`
- Create: `tests/visual-style-baseline/verify-module-default-reading-toolchain.sh`
- Modify after review only: `docs/task-cards/visual-style-baseline/execution-state.md`

**Interfaces:**

- Consumes: formal Visual Style Reference, existing Vite raw-import test support, and exact Node/pnpm lock.
- Produces: one semantic token authority, reusable typography/surface/cognitive classes, and a deterministic fix for the current parent-package pnpm routing failure.

- [ ] **Step 1: Verify VSB-01 is active and reference authority still passes**

```bash
scripts/verify-visual-style-baseline-cards \
  --repo-root . \
  --cards-dir docs/task-cards/visual-style-baseline
test "$(sed -n 's/^ActiveTaskCard = //p' docs/task-cards/visual-style-baseline/execution-state.md)" = "VSB-01"
scripts/verify-visual-style-baseline-reference --repo-root .
```

- [ ] **Step 2: Write raw-CSS contract tests before creating the CSS files**

Create `web/src/styles/style-contract.test.ts` using `?raw` imports. Hand-write the required variable names and expected values. The tests must prove:

1. every semantic token is declared exactly once across the five files;
2. all token declarations live in `tokens.css`;
3. `cognitura.css` contains only four local imports, in order: tokens, typography, surfaces, cognitive visual;
4. Typography uses the exact Sans stack, only weights 400/500/600/700, and exact scale values;
5. Reading Body is `16px / 27px`, not 13px or 14px;
6. Reading Surface has no shadow; projection uses border before any shadow;
7. `:focus` and `:focus-visible` both expose a 2px ring with 2px offset and the approved translucent primary color;
8. no token name contains `blue-`, `purple-card`, `green-box`, `gradient`, `glass`, or `card-wall`;
9. no CSS contains external URL, `backdrop-filter`, gradient, glow, or colored shadow;
10. relationship classes expose verb, direction, endpoint, and line-style hooks rather than color-only types.

Create `tests/visual-style-baseline/verify-module-default-reading-toolchain.sh` with fake `node` and `pnpm` binaries. The fake pnpm must report `9.15.9` for bare `pnpm --version`, `11.17.0` for `pnpm --dir /fixture/repo/web --version`, and record all invocations. This makes the current root-level version check fail while proving the corrected check is scoped to `web/package.json`.

- [ ] **Step 3: Run both tests and observe RED**

With the exact toolchain PATH from the plan header:

```bash
env PATH="${VSB_TOOLCHAIN_PATH}" \
  pnpm --dir web test -- src/styles/style-contract.test.ts
/bin/bash tests/visual-style-baseline/verify-module-default-reading-toolchain.sh
```

Expected: the Vitest import fails because the CSS files are missing; the Bash test fails because `scripts/verify-module-default-reading` currently calls bare `pnpm --version` at repository root and sees the user's parent `pnpm@9.15.9` package-manager declaration.

- [ ] **Step 4: Implement `tokens.css` with exact semantic values**

Create `web/src/styles/tokens.css` with this complete declaration surface:

```css
:root {
  color-scheme: light;

  --color-canvas: #f7f9fc;
  --surface-reading: #ffffff;
  --surface-projection: #fafbfd;
  --surface-subtle: #f5f7fa;
  --border-subtle: #e7eaf0;
  --border-default: #e2e6ec;
  --border-strong: #d4dae3;
  --text-primary: #172033;
  --text-secondary: #475467;
  --text-muted: #667085;
  --text-subtle: #98a2b3;
  --color-primary: #4f67e8;
  --color-primary-hover: #455bdd;
  --color-primary-active: #3d50c9;
  --color-primary-soft: #eef2ff;
  --color-focus: #7c6cf2;
  --color-focus-soft: #f3f0ff;
  --color-success: #278c68;
  --color-success-soft: #ecf8f3;
  --color-warning: #c98526;
  --color-warning-soft: #fff6e5;
  --color-danger: #d64f58;
  --color-danger-soft: #fff0f1;
  --color-info: #4385e0;
  --color-info-soft: #eef6ff;

  --font-interface: Inter, "PingFang SC", "SF Pro Text", "Noto Sans SC",
    "Microsoft YaHei", system-ui, -apple-system, BlinkMacSystemFont,
    "Segoe UI", sans-serif;
  --font-reading: var(--font-interface);
  --font-weight-regular: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;
  --type-page-title-size: 32px;
  --type-page-title-line-height: 40px;
  --type-object-title-size: 28px;
  --type-object-title-line-height: 36px;
  --type-major-section-size: 22px;
  --type-major-section-line-height: 30px;
  --type-cognitive-section-size: 18px;
  --type-cognitive-section-line-height: 26px;
  --type-reading-size: 16px;
  --type-reading-line-height: 27px;
  --type-ui-size: 14px;
  --type-ui-line-height: 21px;
  --type-metadata-size: 13px;
  --type-metadata-line-height: 18px;
  --type-caption-size: 12px;
  --type-caption-line-height: 18px;

  --space-1: 4px;
  --space-2: 8px;
  --space-3: 12px;
  --space-4: 16px;
  --space-5: 20px;
  --space-6: 24px;
  --space-8: 32px;
  --space-10: 40px;
  --space-12: 48px;
  --space-16: 64px;
  --reading-column-width: 52rem;
  --projection-width: 64rem;
  --application-max-width: 90rem;

  --radius-xs: 6px;
  --radius-sm: 8px;
  --radius-md: 10px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-pill: 999px;
  --shadow-xs: 0 1px 2px rgb(16 24 40 / 4%);
  --shadow-sm: 0 2px 6px rgb(16 24 40 / 5%);
  --shadow-md: 0 6px 18px rgb(16 24 40 / 7%);
  --focus-ring-width: 2px;
  --focus-ring-offset: 2px;
  --focus-ring-color: rgb(79 103 232 / 32%);
  --motion-fast: 140ms;
  --motion-standard: 180ms;
  --motion-easing: ease-out;
}
```

Hex letter case is a CSS serialization detail; the test compares normalized lowercase values while the formal Markdown retains the approved uppercase notation.

- [ ] **Step 5: Implement the four projection styles without a parallel theme**

`web/src/styles/typography.css` defines only these role classes:

```css
.cka-visual-root {
  color: var(--text-primary);
  font-family: var(--font-interface);
  font-size: var(--type-reading-size);
  line-height: var(--type-reading-line-height);
  text-rendering: optimizeLegibility;
}

.cka-type-page-title { font-size: var(--type-page-title-size); line-height: var(--type-page-title-line-height); font-weight: var(--font-weight-bold); }
.cka-type-object-title { font-size: var(--type-object-title-size); line-height: var(--type-object-title-line-height); font-weight: var(--font-weight-semibold); }
.cka-type-major-section { font-size: var(--type-major-section-size); line-height: var(--type-major-section-line-height); font-weight: var(--font-weight-semibold); }
.cka-type-cognitive-section { font-size: var(--type-cognitive-section-size); line-height: var(--type-cognitive-section-line-height); font-weight: var(--font-weight-semibold); }
.cka-type-reading { font-size: var(--type-reading-size); line-height: var(--type-reading-line-height); font-weight: var(--font-weight-regular); }
.cka-type-ui { font-size: var(--type-ui-size); line-height: var(--type-ui-line-height); }
.cka-type-metadata { font-size: var(--type-metadata-size); line-height: var(--type-metadata-line-height); }
.cka-type-caption { font-size: var(--type-caption-size); line-height: var(--type-caption-line-height); }
```

`web/src/styles/surfaces.css` defines a canvas, unshadowed reading surface, bounded projection, subtle band, and semantic-boundary utility. The reading surface must use `box-shadow: none`; the projection must use `1px solid var(--border-subtle)` and at most `var(--shadow-xs)`; the semantic boundary uses a left rule and soft fill rather than a nested card.

`web/src/styles/cognitive-visual.css` defines:

```css
.cka-focusable:focus,
.cka-focusable:focus-visible {
  outline: var(--focus-ring-width) solid var(--focus-ring-color);
  outline-offset: var(--focus-ring-offset);
}

.cka-relation-statement { display: grid; grid-template-columns: minmax(0, 1fr) auto minmax(0, 1fr); }
.cka-relation-verb { color: var(--color-primary); font-weight: var(--font-weight-semibold); }
.cka-relation-direction { border-block-start: 1.5px solid currentColor; }
.cka-relation-direction::after { border: solid currentColor; border-width: 0 1.5px 1.5px 0; transform: rotate(-45deg); }
.cka-relation-statement[data-relation-strength="weak"] .cka-relation-direction { border-block-start-style: dashed; opacity: 0.64; }
```

Use neutral text and primary blue by default. Define soft status utilities only for confirmed/focus/warning/conflict; do not create colored relation-type selectors.

The deliberate `:focus` fallback makes the same accessible ring visible for keyboard, programmatic, and pointer focus, avoiding an untrusted headless input-modality heuristic. `:focus-visible` remains explicitly supported; the real-browser Gate verifies focusability and the computed ring through `:focus`, while the raw CSS contract verifies the `:focus-visible` selector exists.

`web/src/styles/cognitura.css` contains exactly:

```css
@import "./tokens.css";
@import "./typography.css";
@import "./surfaces.css";
@import "./cognitive-visual.css";
```

- [ ] **Step 6: Repair the existing verifier's exact pnpm check**

In `scripts/verify-module-default-reading`, replace only the bare pnpm version probe with:

```bash
[[ "$(pnpm --dir "${repo_root}/web" --version 2>/dev/null || true)" == "11.17.0" ]] || {
  printf 'ModuleDefaultReadingVerification = FAIL\nexpected pnpm 11.17.0\n' >&2
  exit 1
}
```

Keep the exact Node check and existing test/build invocations. This makes the verifier consume `web/package.json` instead of the unrelated `/Users/yuzhuangzhuang/package.json` declaration.

- [ ] **Step 7: Make targeted and full tests GREEN**

```bash
env PATH="${VSB_TOOLCHAIN_PATH}" \
  pnpm --dir web test -- src/styles/style-contract.test.ts
/bin/bash tests/visual-style-baseline/verify-module-default-reading-toolchain.sh
env PATH="${VSB_TOOLCHAIN_PATH}" \
  pnpm --dir web test -- src/modules/module-reading
env PATH="${VSB_TOOLCHAIN_PATH}" scripts/verify-module-default-reading
scripts/verify-visual-style-baseline-reference --repo-root .
scripts/verify-visual-style-baseline-cards \
  --repo-root . \
  --cards-dir docs/task-cards/visual-style-baseline
git diff --check
```

Expected: all PASS; `git diff --name-only` contains no module component, Visual Reference, App, backend, screenshot, or historical evidence path.

- [ ] **Step 8: Commit and review VSB-01**

```bash
git add \
  web/src/styles/tokens.css \
  web/src/styles/typography.css \
  web/src/styles/surfaces.css \
  web/src/styles/cognitive-visual.css \
  web/src/styles/cognitura.css \
  web/src/styles/style-contract.test.ts \
  scripts/verify-module-default-reading \
  tests/visual-style-baseline/verify-module-default-reading-toolchain.sh
git diff --cached --check
git commit -m "style: establish Cognitura semantic visual tokens"
VSB01_CANDIDATE_SHA="$(git rev-parse HEAD)"
```

Dispatch a new `deep_reviewer` on the fixed SHA. Require checks for token authority duplication, formal-value parity, typography accessibility, semantic color misuse, shadow/radius excess, local import safety, exact toolchain enforcement, and card WriteSet. Require `GO / P0=0 / P1=0 / P2=0`.

- [ ] **Step 9: Release VSB-02 with a ledger-only receipt**

Write the exact `VSB01_CANDIDATE_SHA` into:

```text
ActiveTaskCard = VSB-02
ReleasedTaskCard = VSB-02
CompletedTaskCards = VSB-00,VSB-01
CurrentCandidateSHA = ${VSB01_CANDIDATE_SHA}
CurrentGateStatus = VSB-G1_PASS
CurrentReviewRoute = deep_reviewer
CurrentReviewVerdict = GO_P0_0_P1_0_P2_0
VSB01CandidateSHA = ${VSB01_CANDIDATE_SHA}
VSB01GateStatus = VSB-G1_PASS
VSB01ReviewRoute = deep_reviewer
VSB01ReviewVerdict = GO_P0_0_P1_0_P2_0
NextTaskCard = VSB-03
TransitionSequence = 3
TransitionKind = ADVANCE
TransitionBaseSHA = ${VSB01_CANDIDATE_SHA}
```

Commit and validate only the ledger:

```bash
git add docs/task-cards/visual-style-baseline/execution-state.md
git diff --cached --name-only
git commit -m "chore: release module reading visual card"
VSB01_RECEIPT_SHA="$(git rev-parse HEAD)"
scripts/verify-visual-style-baseline-cards \
  --repo-root . \
  --cards-dir docs/task-cards/visual-style-baseline \
  --transition-base "${VSB01_CANDIDATE_SHA}" \
  --transition-head "${VSB01_RECEIPT_SHA}"
```

---

## Task 4: VSB-02 — restyle ModuleDefaultReading and add the independent Vite visual reference

**Files:**

- Modify: `web/src/modules/module-reading/ModuleDefaultReading.tsx`
- Modify: `web/src/modules/module-reading/ModuleDefaultReading.test.tsx`
- Modify: `web/src/modules/module-reading/ModuleNarrative.tsx`
- Modify: `web/src/modules/module-reading/ModuleNarrative.test.tsx`
- Modify: `web/src/modules/module-reading/StageChainProjection.tsx`
- Modify: `web/src/modules/module-reading/StageChainProjection.test.tsx`
- Modify: `web/src/modules/module-reading/ModuleClosure.tsx`
- Modify: `web/src/modules/module-reading/ModuleClosure.test.tsx`
- Modify: `web/src/modules/module-reading/KeyRelations.tsx`
- Modify: `web/src/modules/module-reading/KeyRelations.test.tsx`
- Modify: `web/src/modules/module-reading/SourceEntry.tsx`
- Modify: `web/src/modules/module-reading/SourceEntry.test.tsx`
- Modify: `web/src/modules/module-reading/module-default-reading.css`
- Modify: `web/vite.config.mjs`
- Create: `web/visual-reference.html`
- Create: `web/src/visual-reference/main.tsx`
- Create: `web/src/visual-reference/VisualReference.tsx`
- Create: `web/src/visual-reference/VisualReference.test.tsx`
- Create: `web/src/visual-reference/module-default-reading.fixture.ts`
- Create: `web/src/visual-reference/visual-reference.css`
- Modify after review only: `docs/task-cards/visual-style-baseline/execution-state.md`

**Interfaces:**

- Consumes: existing fail-closed `CognitiveModule`/`RendererInput` projection, semantic CSS tokens, and the formal eight-section Reading First contract.
- Produces: refined production presentation markup, natural-language relationship expression, one bounded mechanism projection, and a deterministic offline Vite entry that renders the real production component without touching the App shell.

- [ ] **Step 1: Verify VSB-02 is uniquely active and establish the exact baseline**

```bash
test "$(sed -n 's/^ActiveTaskCard = //p' docs/task-cards/visual-style-baseline/execution-state.md)" = "VSB-02"
scripts/verify-visual-style-baseline-reference --repo-root .
env PATH="${VSB_TOOLCHAIN_PATH}" \
  pnpm --dir web test -- src/styles/style-contract.test.ts src/modules/module-reading
env PATH="${VSB_TOOLCHAIN_PATH}" pnpm --dir web build
```

Expected: current semantic and projection tests pass before presentation changes.

- [ ] **Step 2: Strengthen component tests before changing presentation markup**

Update the six existing component tests first. Keep all existing fail-closed relation and projection tests, then add literal assertions for:

```text
exact eight-section order remains unchanged
exactly one primary visual projection
zero complementary roles
exactly one button
zero headings matching Conditions or Results
zero class names containing dashboard, card-wall, metric, coverage, progress, glass, or gradient
root consumes cka-visual-root and cka-reading-surface
stage chain consumes one cka-projection-surface
ordinary question, conclusion, spine, and element sections do not consume projection/card surfaces
boundary consumes one soft semantic-boundary band
source entry is closed and focusable
relation visible text is source label + natural verb + target label
machine Relation type remains in data-relation-type
machine source IDs are absent from visible text
```

The visible relation verb mapping is exact:

```text
DEPENDS_ON = 依赖于
EXPLAINS = 解释
CONTRASTS_WITH = 对照于
APPLIES_TO = 适用于
IMPACTS = 影响
```

Update accessible names from generic Dashboard-like English labels to these product labels without changing canonical data:

```text
Core questions = 核心问题
Core conclusion = 核心结论
Primary cognitive spine = 认知主线
Stage chain = 机制路径
Critical boundaries = 边界与例外
Knowledge elements = 关键知识
Key relations = 局部关系
Source entry = 来源锚点
```

- [ ] **Step 3: Write the Visual Reference test before creating its entry**

Create `VisualReference.test.tsx` so its initial imports fail. After rendering, it must inspect the actual production DOM and assert:

```text
data-visual-reference = SYNTHETIC_VISUAL_REFERENCE_ONLY
data-product-route = false
one production ModuleDefaultReading main
eight exact reading sections
one primary projection
one to three relations
zero complementary regions
zero dashboard/card-wall/metrics selectors
zero Conditions/Results headings
one source button
no raw source ID in visible text
```

Also raw-import `VisualReference.tsx`, the fixture, and `visual-reference.css` to reject `fetch`, `XMLHttpRequest`, `WebSocket`, `EventSource`, `sendBeacon`, `localStorage`, `sessionStorage`, `indexedDB`, `document.cookie`, `http://`, `https://`, `raw/`, imports from `App`, and router imports.

- [ ] **Step 4: Run the focused suite and observe RED**

```bash
env PATH="${VSB_TOOLCHAIN_PATH}" pnpm --dir web test -- \
  src/modules/module-reading \
  src/visual-reference/VisualReference.test.tsx
```

Expected: component presentation assertions fail against the old serif/fallback styling and raw relation codes; the Visual Reference import fails because its entry does not exist.

- [ ] **Step 5: Add presentation-only semantic markup without changing the model**

Keep `validateFormalRelations`, `projectModuleNarrative`, `projectModuleClosure`, and every model type unchanged. The root composition becomes:

```tsx
<main
  aria-label={module.title}
  className="module-default-reading cka-visual-root cka-reading-surface"
>
  <header className="module-default-reading__identity">
    <p className="module-default-reading__eyebrow">认知模块</p>
    <h1 className="cka-type-object-title">{module.title}</h1>
  </header>
  <ModuleNarrative projection={narrative} />
  <div
    className="module-default-reading__primary-projection cka-projection-surface"
    data-primary-visual-projection="true"
  >
    <StageChainProjection moduleRef={module.artifactId} input={rendererInput} />
  </div>
  <ModuleClosure boundaries={closure.criticalBoundaries} elements={closure.knowledgeElements} />
  <KeyRelations input={rendererInput} />
  <SourceEntry sourceRefs={rendererInput.sourceRefs} />
</main>
```

`StageChainProjection` displays its existing `input.title` and `input.summary`, then its ordered nodes. Each node gets a visible 1-based step number and divider/arrow hook, but no new semantic content or relation.

`SourceEntry` changes the reading-section owner from the button to a section while retaining exactly one button:

```tsx
<section
  aria-label="来源锚点"
  className="module-source-entry"
  data-reading-section="source-entry"
>
  <div>
    <p className="module-section-label">来源锚点</p>
    <p>关键结论可回到正式来源核验。</p>
  </div>
  <button
    className="module-source-entry__action cka-focusable"
    type="button"
    data-source-refs={JSON.stringify(sourceRefs)}
  >
    查看 {sourceRefs.length} 条来源证据
  </button>
</section>
```

The explanatory sentence is presentation copy about capability; it must not expose IDs, claim verification state, or create a second source fact.

Implement `KeyRelations` with an exhaustive typed map:

```tsx
const relationVerbByType: Readonly<Record<RelationType, string>> = {
  DEPENDS_ON: "依赖于",
  EXPLAINS: "解释",
  CONTRASTS_WITH: "对照于",
  APPLIES_TO: "适用于",
  IMPACTS: "影响",
};
```

For each resolved relation, render source endpoint, visible verb, direction marker, and target endpoint in that order. Keep identity/type/source/target datasets and all existing fail-closed validation. Do not add color-per-relation-type selectors.

- [ ] **Step 6: Implement the Reading First CSS translation**

Start `module-default-reading.css` with the local authority import:

```css
@import "../../styles/cognitura.css";
```

Use this layout contract:

```css
.module-default-reading {
  box-sizing: border-box;
  width: min(100%, var(--projection-width));
  margin-inline: auto;
  padding: clamp(var(--space-8), 5vw, var(--space-16));
  color: var(--text-primary);
  background: var(--surface-reading);
  box-shadow: none;
  overflow-wrap: anywhere;
}

.module-default-reading > :not(.module-default-reading__primary-projection) {
  width: min(100%, var(--reading-column-width));
  margin-inline: auto;
}

.module-default-reading > [data-reading-section],
.module-default-reading > .module-default-reading__primary-projection {
  margin-block-start: var(--space-12);
}
```

Additional exact visual behavior:

- identity uses whitespace and a subtle bottom border, no card or shadow;
- the visible `认知模块` eyebrow names the current cognitive focus in restrained `color-focus`; its `::before` is a 6px square with 2px radius and `focus-soft` fill, so purple is semantic and never the only signal;
- core question is 22/30 semibold text on the reading surface, not a card;
- conclusion uses a 2px primary left rule and whitespace, not a filled panel;
- spine and element rows use divider rhythm; no repeated rounded containers;
- the single mechanism projection uses `surface-projection`, 12px radius, subtle border, and `shadow-xs` at most;
- boundary uses `warning-soft`, a 3px warning left rule, 8px radius, and no shadow;
- relations are natural-language statement rows with visible direction; no graph canvas;
- source entry uses a top divider and a quiet secondary button;
- hover/focus transition is 140–180ms ease-out; focus is the formal 2px/2px ring;
- at `max-width: 64rem`, reduce outer padding; at `max-width: 48rem`, stack projection nodes and relation columns, preserve source button 44px minimum, and never create horizontal document overflow.

Do not use selectors named `card`, `dashboard`, `panel-wall`, `metric`, `glass`, or `hero`.

- [ ] **Step 7: Create the deterministic canonical-shaped visual fixture**

`module-default-reading.fixture.ts` exports exactly two values typed as `CognitiveModule` and `RendererInput`. Use this content identity:

```text
Module = module.mvcc.visual-reference
Title = MVCC 一致性读
CoreQuestion = 一次一致性读，如何从多个记录版本中选出当前事务真正可见的版本？
Thesis = 一致性读先固定可见性边界，再沿版本链排除不可见版本，最终返回边界内最新的可见记录。
Elements = 读取视图, 记录版本, 可见性判断, 可见结果
Boundary = 可见性判断解决读版本选择，但不会消除所有写冲突。
Relation = 可见结果 依赖于 读取视图
SourceRef = evidence.visual-reference.mvcc
```

The module contains four ordered `PrimaryCognitiveSpine` steps and four matching `knowledgeElements`; the Stage Chain renderer contains four nodes whose `contentPath` values are `/knowledgeElements/0/title` through `/knowledgeElements/3/title`. Its single `DEPENDS_ON` renderer relation points from the 可见结果 node to the 读取视图 node and references the identical formal module relation. Set `facets`, `keyTakeaways`, and `gaps` to empty arrays and `qualityAssessment` to `null`; do not add Conditions or Results fields.

Use these exact stable identifiers and statements so screenshots do not drift between runs:

```text
Revision = rev.module.mvcc.visual-reference.1
PrimaryParent = theme.database-concurrency
Spine = spine.mvcc.visual-reference
Step 1 = spine-step.mvcc.visual-reference.1 | 创建读取视图，固定当前事务的可见性边界。
Step 2 = spine-step.mvcc.visual-reference.2 | 从当前记录定位版本链入口。
Step 3 = spine-step.mvcc.visual-reference.3 | 比较事务标识与读取视图，排除不可见版本。
Step 4 = spine-step.mvcc.visual-reference.4 | 返回边界内最新的可见记录。
Element 0 = element.mvcc.read-view | 读取视图 | 固定一次一致性读所使用的事务可见性边界。
Element 1 = element.mvcc.record-version | 记录版本 | 保存记录在某次事务修改后的历史状态与版本链指针。
Element 2 = element.mvcc.visibility | 可见性判断 | 按读取视图逐项判断创建事务和删除事务是否可见。
Element 3 = element.mvcc.visible-result | 可见结果 | 在版本链中选择满足边界的最新记录版本。
Boundary = boundary.mvcc.visual-reference.1
FormalRelation = relation.mvcc.visible-result.depends-read-view
RendererNode 0 = renderer-node.mvcc.read-view
RendererNode 1 = renderer-node.mvcc.record-version
RendererNode 2 = renderer-node.mvcc.visibility
RendererNode 3 = renderer-node.mvcc.visible-result
RendererRelation = renderer-relation.mvcc.visible-result.depends-read-view
```

Every object uses `schemaVersion = 2.0.0`, `publicationState = PUBLISHED`, the same source ref, and a deterministic revision ID derived from the identifiers above. The relation has `origin = SOURCE_SYNTHESIZED`, `riskLevel = LOW`, and no gaps; the wrapper—not the canonical object—carries the synthetic visual-reference warning.

Complete the remaining required typed fields with these exact literals:

```text
Module.role = CORE
Module.sourceRefs = [evidence.visual-reference.mvcc]
Module.facets = []
Module.keyTakeaways = []
Module.gaps = []
Module.qualityAssessment = null
PrimarySpine.artifactId = spine.mvcc.visual-reference
PrimarySpine.revisionId = rev.spine.mvcc.visual-reference.1
PrimarySpine.moduleRef = module.mvcc.visual-reference
Step.order = 1,2,3,4
Step.sourceRefs = [evidence.visual-reference.mvcc]
Element 0.elementType = CONCEPT
Element 1.elementType = CONCEPT
Element 2.elementType = MECHANISM
Element 3.elementType = CONCEPT
Element.revisionId = rev.element.mvcc.read-view.1,rev.element.mvcc.record-version.1,rev.element.mvcc.visibility.1,rev.element.mvcc.visible-result.1
Element.moduleRef = module.mvcc.visual-reference
Element.sourceRefs = [evidence.visual-reference.mvcc]
Element 0.relations = [relation.mvcc.visible-result.depends-read-view]
Element 1.relations = []
Element 2.relations = []
Element 3.relations = [relation.mvcc.visible-result.depends-read-view]
Boundary.sourceRefs = [evidence.visual-reference.mvcc]
FormalRelation.sourceRef = element.mvcc.visible-result
FormalRelation.targetRef = element.mvcc.read-view
FormalRelation.sourceRefs = [evidence.visual-reference.mvcc]
FormalRelation.gapRefs = []
Renderer.schemaVersion = 2.0.0
Renderer.moduleRef = module.mvcc.visual-reference
Renderer.rendererType = STAGE_CHAIN
Renderer.title = 一致性读的可见版本选择机制
Renderer.summary = 从读取视图到可见结果的四步认知路径。
Renderer.groups = []
Renderer.sourceRefs = [evidence.visual-reference.mvcc]
Renderer.incompleteState = { status: COMPLETE, gapRefs: [] }
Renderer.interactionHints = [SHOW_SOURCE]
RendererNode.artifactRef = module.mvcc.visual-reference
RendererNode.contentPath = /knowledgeElements/0/title,/knowledgeElements/1/title,/knowledgeElements/2/title,/knowledgeElements/3/title
RendererNode.label = each matching Element title
RendererNode.summary = each matching Element content
RendererNode.groupRef = null
RendererNode.sourceRefs = [evidence.visual-reference.mvcc]
RendererRelation.type = DEPENDS_ON
RendererRelation.sourceNodeRef = renderer-node.mvcc.visible-result
RendererRelation.targetNodeRef = renderer-node.mvcc.read-view
RendererRelation.artifactRelationRef = relation.mvcc.visible-result.depends-read-view
RendererRelation.sourceRefs = [evidence.visual-reference.mvcc]
```

- [ ] **Step 8: Build an independent Vite entry, not an App route**

`web/visual-reference.html` contains only a local root and `/src/visual-reference/main.tsx` module script. `main.tsx` imports `../styles/cognitura.css`, then `./visual-reference.css`, and renders `VisualReference` into that root with `StrictMode`. The component stylesheet also imports the same semantic entry so the production component remains self-contained; Vite de-duplicates the identical CSS module, and no second token declaration exists.

`VisualReference` uses `useEffect` after the production component commits to set `document.documentElement.dataset.visualReferenceReady = "true"` and removes it on cleanup. `VisualReference.test.tsx` waits for this marker and still derives section/projection/relation counts from actual nodes; the marker is a timing signal only, never acceptance evidence.

The wrapper is deliberately small:

```tsx
<div
  className="visual-reference cka-visual-root"
  data-product-route="false"
  data-visual-reference="SYNTHETIC_VISUAL_REFERENCE_ONLY"
>
  <header className="visual-reference__topbar">
    <div className="visual-reference__brand-mark" aria-hidden="true">C</div>
    <div>
      <strong>Cognitura</strong>
      <span>个人认知结构工作台</span>
    </div>
    <span className="visual-reference__fixture-label">视觉参考 · 非产品路由</span>
  </header>
  <div className="visual-reference__canvas">
    <nav aria-label="知识路径" className="visual-reference__path">
      数据库系统 <span aria-hidden="true">/</span> 并发控制 <span aria-hidden="true">/</span> MVCC
    </nav>
    <ModuleDefaultReading module={visualReferenceModule} rendererInput={visualReferenceRenderer} />
  </div>
</div>
```

This wrapper has no sidebar, dashboard panels, search, governance controls, metrics, or fake product actions. `visual-reference.css` sets a quiet 56px white top bar, cool canvas, centered application max width, and responsive safe padding.

Modify `web/vite.config.mjs` using a stable ESM path:

```js
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";

const webRoot = fileURLToPath(new URL(".", import.meta.url));

export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      input: {
        app: resolve(webRoot, "index.html"),
        visualReference: resolve(webRoot, "visual-reference.html"),
      },
    },
  },
  test: {
    environment: "jsdom",
    setupFiles: ["./src/test/setup.ts"],
  },
});
```

- [ ] **Step 9: Make component, anti-dashboard, and build checks GREEN**

```bash
env PATH="${VSB_TOOLCHAIN_PATH}" pnpm --dir web test -- \
  src/styles/style-contract.test.ts \
  src/modules/module-reading \
  src/visual-reference/VisualReference.test.tsx
env PATH="${VSB_TOOLCHAIN_PATH}" pnpm --dir web build
test -f web/dist/index.html
test -f web/dist/visual-reference.html
env PATH="${VSB_TOOLCHAIN_PATH}" scripts/verify-module-default-reading
scripts/verify-visual-style-baseline-reference --repo-root .
scripts/verify-visual-style-baseline-cards \
  --repo-root . \
  --cards-dir docs/task-cards/visual-style-baseline
git diff --check
```

Expected: all tests/build PASS; no `App.tsx`, `main.tsx`, backend, schema, raw input, or evidence path changed.

- [ ] **Step 10: Commit and review VSB-02**

Stage exactly the twenty component/visual-reference paths listed at the top of Task 4, excluding the ledger. Then:

```bash
git diff --cached --check
git diff --cached --name-only
git commit -m "style: refine Module default reading"
VSB02_CANDIDATE_SHA="$(git rev-parse HEAD)"
```

Dispatch a fresh `deep_reviewer` on that fixed SHA. Required review: formal DOM order, relation identity/type/endpoints, natural-language relation semantics, source privacy/focus, Conditions/Results absence, CSS authority consumption, accessibility, responsive safety, one-projection budget, no card wall/dashboard/App integration, offline fixture isolation, and exact WriteSet. Require `GO / P0=0 / P1=0 / P2=0`.

- [ ] **Step 11: Release VSB-03 with a ledger-only receipt**

Write the exact `VSB02_CANDIDATE_SHA` into:

```text
ActiveTaskCard = VSB-03
ReleasedTaskCard = VSB-03
CompletedTaskCards = VSB-00,VSB-01,VSB-02
CurrentCandidateSHA = ${VSB02_CANDIDATE_SHA}
CurrentGateStatus = VSB-G2_PASS
CurrentReviewRoute = deep_reviewer
CurrentReviewVerdict = GO_P0_0_P1_0_P2_0
VSB02CandidateSHA = ${VSB02_CANDIDATE_SHA}
VSB02GateStatus = VSB-G2_PASS
VSB02ReviewRoute = deep_reviewer
VSB02ReviewVerdict = GO_P0_0_P1_0_P2_0
NextTaskCard = NONE
TransitionSequence = 4
TransitionKind = ADVANCE
TransitionBaseSHA = ${VSB02_CANDIDATE_SHA}
```

Commit and validate only the ledger:

```bash
git add docs/task-cards/visual-style-baseline/execution-state.md
git diff --cached --name-only
git commit -m "chore: release visual acceptance card"
VSB02_RECEIPT_SHA="$(git rev-parse HEAD)"
scripts/verify-visual-style-baseline-cards \
  --repo-root . \
  --cards-dir docs/task-cards/visual-style-baseline \
  --transition-base "${VSB02_CANDIDATE_SHA}" \
  --transition-head "${VSB02_RECEIPT_SHA}"
```

Wave 1 must still be exactly suspended.

---

## Task 5: VSB-03 — render, probe, compare, review the fixed candidate, and restore Wave 1

**Files:**

- Create: `scripts/capture-visual-style-baseline`
- Create: `scripts/verify-visual-style-baseline`
- Create: `tests/visual-style-baseline/browser-probe.html`
- Create: `tests/visual-style-baseline/browser-runtime-guard.js`
- Create: `tests/visual-style-baseline/reference-comparison.html`
- Create: `tests/visual-style-baseline/verify-visual-style-baseline.sh`
- Create: `docs/design/visual-style-baseline/evidence/README.md`
- Create: `docs/design/visual-style-baseline/evidence/module-default-reading-1440x1100.png`
- Create: `docs/design/visual-style-baseline/evidence/module-default-reading-1280x960.png`
- Create: `docs/design/visual-style-baseline/evidence/module-default-reading-1024x900.png`
- Create: `docs/design/visual-style-baseline/evidence/reference-comparison.png`
- Create: `docs/engineering/cognitura-visual-style-baseline-acceptance.md`
- Modify after both fixed reviews only: `docs/task-cards/visual-style-baseline/execution-state.md`
- Restore after final VSB receipt only: `AGENTS.md`
- Restore after final VSB receipt only: `README.md`
- Restore after final VSB receipt only: `docs/design/wave-1/README.md`
- Restore after final VSB receipt only: `docs/engineering/cognitura-design-index.md`
- Restore after final VSB receipt only: `docs/engineering/cognitura-wave-1-design-plan.md`
- Restore after final VSB receipt only: `docs/engineering/cognitura-wave-1-design-acceptance.md`
- Restore after final VSB receipt only: `docs/engineering/cognitura-wave-1-implementation-plan.md`
- Restore after final VSB receipt only: `docs/task-cards/wave-1/README.md`
- Restore after final VSB receipt only: `docs/task-cards/wave-1-implementation/README.md`
- Restore after final VSB receipt only: `docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md` (`Status` only)

**Interfaces:**

- Consumes: the reviewed VSB-02 DOM/CSS candidate, deterministic Visual Reference entry, committed reference PNG, local Chrome, and formal 15-field acceptance contract.
- Produces: real evaluated-DOM/computed-style evidence, fresh three-viewport PNGs, a side-by-side family comparison, fixed-candidate acceptance, a final ultra Gate, and a separate auditable restoration of the exact frozen Wave 1 card.

- [ ] **Step 1: Verify the final card is active and browser/toolchain prerequisites are exact**

```bash
test "$(sed -n 's/^ActiveTaskCard = //p' docs/task-cards/visual-style-baseline/execution-state.md)" = "VSB-03"
VSB02_RECEIPT_SHA="$(git rev-parse HEAD)"
VSB_CHROME_BIN='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
VSB_CHROME_VERSION="$("${VSB_CHROME_BIN}" --version)"
test "${VSB_CHROME_VERSION}" = "Google Chrome 151.0.7922.109"
env PATH="${VSB_TOOLCHAIN_PATH}" node --version
env PATH="${VSB_TOOLCHAIN_PATH}" pnpm --dir web --version
printf '%s\n' "${VSB_CHROME_VERSION}"
python3 -c 'from PIL import __version__; assert __version__ == "12.2.0", __version__'
scripts/verify-visual-style-baseline-reference --repo-root .
git diff --quiet \
  70eefba5912e6884e4e7e1d6477a65f4091d6590..HEAD -- \
  docs/design/high-fidelity/evidence
```

Expected now: Node `v24.18.0`, pnpm `11.17.0`, exact Chrome `Google Chrome 151.0.7922.109`, Pillow `12.2.0`, formal reference PASS, and no historical evidence diff. A different Chrome build is a reproducibility blocker, not permission to refresh committed evidence.

- [ ] **Step 2: Write the real-browser probe before the verifier**

`tests/visual-style-baseline/browser-probe.html` is a same-origin harness. It accepts a `target` query parameter and `runtimeGuard=required|not-required`, loads that path into an iframe, and after iframe `load` computes its own facts from `iframe.contentDocument`. It must never trust `data-*` counts supplied by `VisualReference`. `runtimeGuard=required` fails unless the guard exists, installed successfully, and reports all zeroes; `not-required` records `NOT_APPLICABLE` for runtime counters but still computes every DOM/style/focus fact.

The probe computes and writes these values onto its own `<body>`:

```text
probe-status
visual-reference-ready
section-order
section-count
primary-projection-count
complementary-count
dashboard-selector-count
card-wall-selector-count
nested-semantic-surface-count
button-count
relation-count
natural-language-relation-count
conditions-results-heading-count
machine-source-id-visible-count
root-background-color
root-text-color
body-font-family
body-font-size
body-line-height
object-title-font-size
object-title-line-height
focus-outline-style
focus-outline-width
focus-outline-offset
focus-outline-color
active-element-is-source-button
runtime-fetch-count
runtime-xhr-count
runtime-websocket-count
runtime-eventsource-count
runtime-beacon-count
runtime-storage-count
runtime-cookie-count
runtime-indexeddb-count
csp-violation-count
document-scroll-width
viewport-width
overflow-safe
```

The actual selector algorithm is:

```js
const sectionOrder = Array.from(
  doc.querySelectorAll("[data-reading-section]"),
  (node) => node.getAttribute("data-reading-section"),
);
const primaryProjectionCount = doc.querySelectorAll(
  '[data-primary-visual-projection="true"]',
).length;
const complementaryCount = doc.querySelectorAll(
  '[role="complementary"], aside',
).length;
const dashboardSelectorCount = doc.querySelectorAll(
  '[data-dashboard], [class*="dashboard"], [class*="metric"], [class*="coverage"]',
).length;
const cardWallSelectorCount = doc.querySelectorAll(
  '[data-card-wall], [class*="card-wall"], [class*="card-grid"]',
).length;
const nestedSemanticSurfaceCount = doc.querySelectorAll(
  '.cka-projection-surface .cka-projection-surface, .cka-semantic-boundary .cka-semantic-boundary',
).length;
const relationItems = Array.from(
  doc.querySelectorAll('[data-reading-section="relations"] li[data-relation-type]'),
);
const naturalLanguageRelationCount = relationItems.filter((item) => {
  const verb = item.querySelector('[data-relation-part="verb"]');
  return verb !== null && verb.textContent.trim() !== item.dataset.relationType;
}).length;
const forbiddenHeadings = Array.from(doc.querySelectorAll("h1,h2,h3")).filter(
  (heading) => /Conditions|Results|条件|结果/.test(heading.textContent ?? ""),
);
const sourceButton = doc.querySelector('[data-reading-section="source-entry"] button');
sourceButton.focus();
const machineSourceIds = JSON.parse(sourceButton.dataset.sourceRefs ?? "[]");
const machineSourceIdVisibleCount = machineSourceIds.filter((sourceId) =>
  doc.body.innerText.includes(sourceId),
).length;
const sourceStyle = frame.contentWindow.getComputedStyle(sourceButton);
const rootStyle = frame.contentWindow.getComputedStyle(
  doc.querySelector(".module-default-reading"),
);
const bodyTextStyle = frame.contentWindow.getComputedStyle(
  doc.querySelector('[data-reading-section="core-conclusion"] p'),
);
const titleStyle = frame.contentWindow.getComputedStyle(
  doc.querySelector(".module-default-reading h1"),
);
const runtimeUsage = frame.contentWindow.__vsbRuntimeUsage;
```

The probe requires `doc.documentElement.dataset.visualReferenceReady === "true"`, but that marker is only a timing precondition. `probe-status` becomes `READY` only after all selectors, focus state, computed styles, and runtime-usage counters were evaluated. A fixture-authored `data-probe-*` attribute must not affect these counts.

Create `browser-runtime-guard.js` for the instrumented probe target only. Before the built module script runs, it initializes `globalThis.__vsbRuntimeUsage` with zero counters, wraps `fetch`, `XMLHttpRequest`, `WebSocket`, `EventSource`, `navigator.sendBeacon`, `Storage.prototype.getItem/setItem/removeItem/clear`, the `Document.prototype.cookie` getter/setter, and `indexedDB.open/deleteDatabase`; every call increments its named counter and throws `VSB_FORBIDDEN_RUNTIME_API`. It also registers a `securitypolicyviolation` listener and increments `cspViolationCount`. If any required wrapper/listener cannot be installed, set `guardInstallStatus = FAIL`; otherwise set it to `PASS`. The production screenshot target is uninstrumented by JavaScript, while the same-origin probe target is an exact copy of the built HTML with this guard script inserted immediately before the Vite module script. Both targets receive the same strict CSP in the temporary staging tree.

- [ ] **Step 3: Write the screenshot comparison template**

`tests/visual-style-baseline/reference-comparison.html` accepts local `reference` and `candidate` image paths. It renders exactly two labeled figures on `#f7f9fc`, each constrained to half of a 2560×1100 viewport with `object-fit: contain`. Labels are:

```text
Historical Visual Style Reference — style only
New Module Default Reading — Reading First
```

No overlay, blend, crop, metrics, or pixel-difference visualization is allowed; the purpose is product-family judgment, not layout cloning.

The template parses only same-origin absolute paths beginning with `/__assets/`, assigns them to the two images, awaits `Promise.all(images.map((image) => image.decode()))`, checks both `naturalWidth > 0`, and then sets `document.documentElement.dataset.comparisonReady = "true"`. Any other path or decode failure sets `comparisonReady = "false"` and renders no evidence-ready marker.

- [ ] **Step 4: Write verifier negative tests first**

Create `tests/visual-style-baseline/verify-visual-style-baseline.sh` with these independent literal failures:

```text
missing one of the four evidence PNGs
wrong PNG dimensions
one-byte screenshot mutation
manifest SHA mismatch
computed reading size 14px instead of 16px
computed line height below 27px
missing or invisible 2px focus outline
horizontal overflow at 1024px
zero or two primary projections
an aside/complementary region
dashboard/metric/card-wall selector
nested semantic surface
raw relation type used as visible verb
visible machine source ID
Conditions or Results heading
fake data-probe count while actual projection is absent
external network or browser-storage use
runtime guard installation failure or any non-zero forbidden-API counter
CSP violation on the guarded instrumented target
server log request outside the local visual-reference asset allowlist
Chrome version other than Google Chrome 151.0.7922.109
missing visual-reference-ready or comparison-ready marker
historical HV evidence mutation
frozen W1-I03 production-path mutation
candidate verifier/probe/comparison/capture path that differs from the fixed candidate tree
any comparison or formal acceptance field other than PASS
full-product ImplementationValidation claimed PASS
```

For the spoof case, make a temporary source copy that adds `data-probe-primary-projection-count="1"` but removes the real primary projection, rebuild it, and require FAIL. For overflow, inject `min-width: 2000px` into the real module root, rebuild, and require FAIL at 1024. These two cases prove the Gate observes evaluated layout rather than static self-report.

The static forbidden-API scan starts at `web/src/visual-reference/main.tsx`, resolves every transitive relative `.ts`, `.tsx`, and `.css` import, and rejects any local import outside `web/src/visual-reference/**`, `web/src/modules/module-reading/**`, and `web/src/styles/**`. It scans that resolved production closure only—never tests or README files—and requires the literal closure list to match the expected production entry/component/style files. In that closure and both source HTML entries it rejects `http:`, `https:`, protocol-relative `//`, `data:` except the verifier-owned comparison images, `blob:`, CSS `url(`, every non-root-local `src=`, `href=`, dynamic import, or worker URL, and every CSS import edge outside this exact five-edge graph:

```text
web/src/modules/module-reading/module-default-reading.css -> web/src/styles/cognitura.css
web/src/styles/cognitura.css -> web/src/styles/tokens.css
web/src/styles/cognitura.css -> web/src/styles/typography.css
web/src/styles/cognitura.css -> web/src/styles/surfaces.css
web/src/styles/cognitura.css -> web/src/styles/cognitive-visual.css
```

`visual-reference/main.tsx` uses an ESM CSS import of `cognitura.css`, not a CSS `@import`, so it is checked by the TypeScript import-closure rule. The runtime negative fixture adds a guarded `fetch("/forbidden")` to a temporary Visual Reference copy and requires both the counter and Gate to fail; the storage fixture does the same with `localStorage.setItem`; an external `<img src="http://1.2.3.4/forbidden.png">` fixture on the instrumented target must produce a CSP violation and Gate failure. Browser flags deny non-loopback DNS, the CSP blocks direct-IP/protocol-relative/subresource bypasses, and the local HTTP log may contain only the staged HTML, guard, built `/assets/**`, reference PNG, candidate PNG, and favicon miss.

- [ ] **Step 5: Run the new test and observe RED**

```bash
/bin/bash tests/visual-style-baseline/verify-visual-style-baseline.sh
```

Expected: FAIL because capture/verifier scripts, evidence, manifest, and acceptance report do not exist.

- [ ] **Step 6: Implement a deterministic local build/server/capture runner**

`scripts/capture-visual-style-baseline` accepts:

```text
--repo-root PATH
--output-dir PATH
--chrome-bin PATH (optional; use CHROME_BIN, macOS Chrome, then chromium fallback)
--replace-existing (required only when an output already exists)
```

It must:

1. enforce Node 24.18.0 and `pnpm --dir web` 11.17.0;
2. require the selected browser version equals `Google Chrome 151.0.7922.109` exactly;
3. run the focused Web tests and production build;
4. create `runtime_tmp` with `mktemp -d`, create `staging_root="${runtime_tmp}/site"`, and copy `web/dist/.` into that root without modifying `web/dist`;
5. copy `browser-probe.html` to `${staging_root}/__probe.html`, `browser-runtime-guard.js` to `${staging_root}/__browser-runtime-guard.js`, and `reference-comparison.html` to `${staging_root}/__reference-comparison.html`;
6. inject this exact CSP as the first `<head>` child in staged `visual-reference.html`, its instrumented copy, the probe, and the comparison page: `<meta http-equiv="Content-Security-Policy" content="default-src 'self'; connect-src 'none'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; font-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'self'">`; `unsafe-inline` is limited to the committed deterministic probe/comparison scripts and local template styles, while `default-src/connect-src/img-src/font-src/object-src/base-uri` still forbid external resources, direct IPs, and protocol-relative subresources; production Vite code itself remains external hashed assets;
7. copy the CSP-bearing `visual-reference.html` to `${staging_root}/__instrumented-visual-reference.html` and insert `<script src="/__browser-runtime-guard.js"></script>` immediately before its existing Vite module script; fail unless each CSP insertion and the guard insertion has exactly one target;
8. copy the committed reference PNG to `${staging_root}/__assets/reference.png`;
9. start `python3 -u -m http.server 0 --bind 127.0.0.1 --directory "${staging_root}"`, parse the allocated loopback port from the server log, and fail after a bounded 30-second poll;
10. before each screenshot, dump the verifier-owned probe twice at the intended viewport with a 5000ms virtual-time budget: first with `target=%2F__instrumented-visual-reference.html&runtimeGuard=required` to require `probe-status=READY`, all actual DOM/style facts, `guardInstallStatus=PASS`, every runtime counter zero, and `cspViolationCount=0`; then with `target=%2Fvisual-reference.html&runtimeGuard=not-required` to require the same DOM/style facts and `visual-reference-ready=true` on the exact uninstrumented screenshot target. The uninstrumented target does not claim its own CSP event counter; it is protected by the byte-identical application code, identical CSP, exact static import/resource closure, browser network-denial flags, and local-request allowlist already proven against the instrumented execution;
11. capture the uninstrumented `http://127.0.0.1:${port}/visual-reference.html` at exactly `1440,1100`, `1280,960`, and `1024,900` using a fresh temporary Chrome profile per capture;
12. copy the new 1440 screenshot to `${staging_root}/__assets/candidate.png`, dump `http://127.0.0.1:${port}/__reference-comparison.html?reference=%2F__assets%2Freference.png&candidate=%2F__assets%2Fcandidate.png`, require `comparisonReady=true`, then capture that URL at 2560×1100;
13. use `--headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --force-color-profile=srgb --disable-background-networking --host-resolver-rules="MAP * ~NOTFOUND, EXCLUDE 127.0.0.1" --no-first-run --no-default-browser-check --use-mock-keychain --virtual-time-budget=5000` for dump/capture;
14. require each actual page to expose `visualReferenceReady=true`, require a valid PNG with the expected dimensions, terminate Chrome with bounded polling, and always stop the server and clean the entire runtime temp directory;
15. parse the HTTP log and reject every request not matching `/visual-reference.html`, `/__instrumented-visual-reference.html`, `/__probe.html`, `/__browser-runtime-guard.js`, `/__reference-comparison.html`, `/__assets/reference.png`, `/__assets/candidate.png`, `/assets/` paths emitted by the current build, or `/favicon.ico`;
16. print exact Node, pnpm, Chrome, every viewport, byte size, SHA-256, probe result, CSP result, comparison readiness, and allowed-request count.

The real-DOM/computed-style checks run before each image and are required in addition to the readiness marker; an empty or half-rendered image cannot become evidence merely by having the correct dimensions.

The output names are fixed:

```text
module-default-reading-1440x1100.png
module-default-reading-1280x960.png
module-default-reading-1024x900.png
reference-comparison.png
```

- [ ] **Step 7: Implement the full verifier against current DOM/CSS and fresh recapture**

`scripts/verify-visual-style-baseline` accepts `--repo-root PATH` and optional `--candidate-sha SHA`. It must run:

```text
reference verifier
VSB card validator
Wave 1 suspended-or-final-restored validator
style contract Vitest
module-reading and VisualReference Vitest
production Vite build
module-default-reading verifier
real-browser probe at all three viewports
fresh recapture of all four PNGs into a temp directory
byte-for-byte cmp against committed evidence
evidence manifest hash/dimension checks
historical HV visual verifier
frozen W1 production tree check
acceptance-report closed-set checks
git diff --check
```

For each viewport require these exact browser facts:

```text
section-order = core-questions,core-conclusion,primary-spine,stage-chain,boundaries,elements,relations,source-entry
section-count = 8
primary-projection-count = 1
complementary-count = 0
dashboard-selector-count = 0
card-wall-selector-count = 0
nested-semantic-surface-count = 0
button-count = 1
relation-count = 1..3
natural-language-relation-count = relation-count
conditions-results-heading-count = 0
machine-source-id-visible-count = 0
root-background-color = rgb(255, 255, 255)
root-text-color = rgb(23, 32, 51)
body-font-size = 16px
body-line-height = 27px
object-title-font-size = 28px
object-title-line-height = 36px
focus-outline-style = solid
focus-outline-width = 2px
focus-outline-offset = 2px
focus-outline-color = rgba(79, 103, 232, 0.32)
active-element-is-source-button = true
runtime-guard-install-status = PASS
runtime-fetch-count = 0
runtime-xhr-count = 0
runtime-websocket-count = 0
runtime-eventsource-count = 0
runtime-beacon-count = 0
runtime-storage-count = 0
runtime-cookie-count = 0
runtime-indexeddb-count = 0
csp-violation-count = 0
overflow-safe = true
```

Require the computed `body-font-family` to begin with `Inter` or one of the approved local fallbacks; do not require Inter to be installed. Parse probe attributes only from the verifier-owned probe document after `probe-status=READY`.

When `--candidate-sha` is supplied, resolve it as an ancestor commit before any build, probe, test, or capture. Compare the current working tree byte-for-byte with that candidate for every exclusive non-ledger WriteSet path from `VSB-00..VSB-03`: formal reference/manifest, reference PNG, importer/reference verifier/tests, HF authority bridge, all CSS, style tests, the toolchain verifier repair/test, all touched module-reading files, Vite/visual-reference files, capture/verifier scripts, runtime guard, probe/comparison templates, acceptance report, evidence manifest, and all four PNGs. Reject any missing, extra, modified, staged, or unstaged exclusive governed path. This comparison happens before executing current-tree tests or tools.

`AGENTS.md` and `docs/engineering/cognitura-design-index.md` are shared projections changed again by the final W1 restore, so they are not whole-file byte-compared. Instead, the fixed reference verifier requires their six Visual Style authority fields, manifest link, source ordering, `DOC-GAP-HF-001..003`, and no-authority exclusions to equal the candidate tree exactly; the fixed Wave 1 validator independently checks their mutable W1 status fields. The remaining Task 1 Wave 1/bootstrap projections are governed entirely by the fixed card validators. No shared projection is accepted through a broad ignore.

For fixed-candidate review and later final verification, do not start with the mutable working-tree verifier. Extract the reviewed verifier from Git and execute that copy:

```bash
VSB_FIXED_RUNTIME_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-vsb-fixed.XXXXXX")"
git show "${VSB03_CANDIDATE_SHA}:scripts/verify-visual-style-baseline" > \
  "${VSB_FIXED_RUNTIME_DIR}/verify-visual-style-baseline"
chmod +x "${VSB_FIXED_RUNTIME_DIR}/verify-visual-style-baseline"
env PATH="${VSB_TOOLCHAIN_PATH}" \
  "${VSB_FIXED_RUNTIME_DIR}/verify-visual-style-baseline" \
  --repo-root "$(pwd -P)" \
  --candidate-sha "${VSB03_CANDIDATE_SHA}"
```

The fixed verifier itself performs the governed-path comparison before invoking the candidate-bound capture script. It extracts `scripts/capture-visual-style-baseline` from the same candidate into its temp directory rather than calling a later working-tree copy. When the VSB ledger is `COMPLETE`, the candidate must equal both `CurrentCandidateSHA` and `VSB03CandidateSHA`. While VSB-03 is active, the manifest may use `CandidateSHA = SEE_VISUAL_STYLE_BASELINE_EXECUTION_STATE_AFTER_FIXED_REVIEW`; the command-line fixed SHA is the binding evidence. The ledger and later Wave 1 projections are intentionally excluded from the business-tree byte comparison and are separately validated as state receipts.

- [ ] **Step 8: Capture the four evidence PNGs from the current VSB-02 visual tree**

```bash
mkdir -p docs/design/visual-style-baseline/evidence
env PATH="${VSB_TOOLCHAIN_PATH}" scripts/capture-visual-style-baseline \
  --repo-root . \
  --output-dir docs/design/visual-style-baseline/evidence
file docs/design/visual-style-baseline/evidence/*.png
shasum -a 256 docs/design/visual-style-baseline/evidence/*.png
```

Expected dimensions: 1440×1100, 1280×960, 1024×900, and comparison 2560×1100. Do not write or replace anything under `docs/design/high-fidelity/evidence/**`.

- [ ] **Step 9: Inspect every image and return presentation defects to VSB-02**

Use the image viewer at original/high detail for the three viewport PNGs and `reference-comparison.png`. Inspect all of:

```text
TypographyHierarchy
Whitespace
VisualDensity
CardDensity
ControlDensity
FocusVisibility
ReadingContinuity
SemanticColorConsistency
Overflow
ResponsiveSafety
SameProductFamily
SameVisualCalmness
SameSurfaceCharacter
SameBorderCharacter
SameBluePurpleFamily
SameTypographyDensity
SameIconCharacter
SameRefinementLevel
SameSemanticColorRestraint
NewPageIsSubstantiallyMoreReadingFirst
```

If a component/CSS defect exists, do not edit VSB-02 paths while VSB-03 is active. Make a ledger-only `RETURN_TO_OWNER` receipt that sets `ActiveTaskCard = VSB-02`, `ReleasedTaskCard = VSB-02`, `CompletedTaskCards = VSB-00,VSB-01`, `NextTaskCard = VSB-03`, records the failed evidence candidate, and increments `TransitionSequence`. Add a failing DOM/style/browser test, fix and re-review VSB-02, re-release VSB-03, and recapture all four images. A screenshot-tool defect remains in VSB-03.

- [ ] **Step 10: Write the evidence manifest and visual acceptance report**

`docs/design/visual-style-baseline/evidence/README.md` records:

```text
CanonicalProjectName = Cognitura
EvidenceSet = VISUAL_STYLE_BASELINE_VSB_03
EvidenceStatus = FIXED_CANDIDATE
CandidateSHA = SEE_VISUAL_STYLE_BASELINE_EXECUTION_STATE_AFTER_FIXED_REVIEW
CaptureInputSHA = ${VSB02_RECEIPT_SHA}
ReferenceSHA256 = a8446ea987f6a1710c3845f837e2776190997b77f81584cf7b667cbfebe2f95f
Node = 24.18.0
pnpm = 11.17.0
Chrome = ${VSB_CHROME_VERSION}
CaptureToolBinding = FIXED_CANDIDATE_TREE
ProbeInput = tests/visual-style-baseline/browser-probe.html
RuntimeGuardInput = tests/visual-style-baseline/browser-runtime-guard.js
ComparisonInput = tests/visual-style-baseline/reference-comparison.html
HistoricalEvidenceOverwrite = FORBIDDEN
```

Set `VSB_CHROME_VERSION` from the exact `Chrome --version` output and require the literal `Google Chrome 151.0.7922.109`. `${VSB02_RECEIPT_SHA}` and `${VSB_CHROME_VERSION}` are execution variables: write their literal values into the manifest, with no dollar signs or symbolic refs. Add a four-row table with file, viewport, byte size, SHA-256, capture command, real-DOM probe result, computed-style result, runtime-guard result, comparison readiness, allowed HTTP requests, and freshness result.

Create `docs/engineering/cognitura-visual-style-baseline-acceptance.md` with the following closed block only after Step 9 inspection and the full verifier are PASS:

```text
CanonicalProjectName = Cognitura
AcceptanceKind = VISUAL_STYLE_BASELINE
Authority = docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md
Evidence = docs/design/visual-style-baseline/evidence/README.md
FixedCandidateSHA = SEE_VISUAL_STYLE_BASELINE_EXECUTION_STATE_AFTER_FIXED_REVIEW
SameProductFamily = PASS
SameVisualCalmness = PASS
SameSurfaceCharacter = PASS
SameBorderCharacter = PASS
SameBluePurpleFamily = PASS
SameTypographyDensity = PASS
SameIconCharacter = PASS
SameRefinementLevel = PASS
SameSemanticColorRestraint = PASS
NewPageIsSubstantiallyMoreReadingFirst = PASS
SameProductVisualFamilyWithReference = PASS
ReadingFirst = PASS
InteractiveCognitiveDocument = PASS
ContinuousDocumentFlow = PASS
ZeroInteractionReading = PASS
CardAndContainerRestraint = PASS
VisualPrimitiveDensity = PASS
InteractionExposureRestraint = PASS
TypographyHierarchy = PASS
ColorSemanticConsistency = PASS
RelationSemanticExpression = PASS
NoDashboardRegression = PASS
NoCardWallRegression = PASS
NoAISaaSTemplateDrift = PASS
NoFormalDesignAuthorityViolation = PASS
VisualStyleBaseline = PASS
ModuleDefaultReadingVisualImplementation = PASS_WITHIN_EXISTING_CANONICAL_PROJECTION
FullModuleDefaultReadingBusinessAcceptance = BLOCKED_BY_DOC_GAP_MDR_001
ImplementationValidation = NOT_CLAIMED_FOR_FULL_PRODUCT_PAGE
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

If any of the ten comparison fields or fifteen formal acceptance fields is not supported, write `FAIL`, set `VisualStyleBaseline = NO_GO`, and do not proceed to fixed review. `SameIconCharacter` is supported only if the CSS direction marker and any controls use the same restrained outline character and no mixed icon library was introduced; the absence of decorative product icons is not itself a failure.

- [ ] **Step 11: Make the browser/evidence Gate GREEN before committing**

```bash
/bin/bash tests/visual-style-baseline/verify-visual-style-baseline.sh
env PATH="${VSB_TOOLCHAIN_PATH}" scripts/verify-visual-style-baseline --repo-root .
env PATH="${VSB_TOOLCHAIN_PATH}" scripts/verify-module-default-reading
scripts/verify-high-fidelity-visual
scripts/verify-wave1-implementation-cards \
  --repo-root . \
  --cards-dir docs/task-cards/wave-1-implementation
scripts/verify-visual-style-baseline-cards \
  --repo-root . \
  --cards-dir docs/task-cards/visual-style-baseline
git diff --check
git status --short
```

Expected: every Gate passes; fresh recapture is byte-identical; historical evidence and frozen W1 paths are unchanged; `.idea/` remains untracked.

- [ ] **Step 12: Commit the fixed VSB-03 candidate**

Stage exactly the twelve VSB-03 business/evidence paths listed at the top of Task 5, excluding execution state and all Wave 1 projections:

```bash
git diff --cached --check
git diff --cached --name-only
git commit -m "test: fix visual style baseline evidence"
VSB03_CANDIDATE_SHA="$(git rev-parse HEAD)"
VSB_FIXED_RUNTIME_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-vsb-fixed.XXXXXX")"
git show "${VSB03_CANDIDATE_SHA}:scripts/verify-visual-style-baseline" > \
  "${VSB_FIXED_RUNTIME_DIR}/verify-visual-style-baseline"
chmod +x "${VSB_FIXED_RUNTIME_DIR}/verify-visual-style-baseline"
env PATH="${VSB_TOOLCHAIN_PATH}" \
  "${VSB_FIXED_RUNTIME_DIR}/verify-visual-style-baseline" \
  --repo-root "$(pwd -P)" \
  --candidate-sha "${VSB03_CANDIDATE_SHA}"
rm -rf "${VSB_FIXED_RUNTIME_DIR}"
```

Expected: the candidate contains no execution-state receipt, Wave 1 restore, App, backend, schema, raw, historical evidence, or `.idea/` path.

- [ ] **Step 13: Run two independent fixed-candidate reviews**

First dispatch a fresh `deep_reviewer` on the exact unchanged `VSB03_CANDIDATE_SHA`. Require review of browser-probe authenticity, screenshot freshness, viewport safety, acceptance evidence, reference comparison, no self-reported-count bypass, frozen write sets, and all fifteen acceptance fields.

Required general verdict:

```text
GeneralReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
```

Then dispatch `ultra_gatekeeper` on the same unchanged SHA. Provide the approved spec SHA, full candidate write set, all Gate output, reference PNG, three viewport screenshots, comparison screenshot, computed-style facts, general review verdict, and the explicit scope exclusions.

Required final verdict:

```text
FinalGateVerdict = GO
P0 = 0
P1 = 0
P2 = 0
SameProductVisualFamilyWithReference = PASS
ReadingFirst = PASS
NoDashboardRegression = PASS
NoFormalDesignAuthorityViolation = PASS
```

Any finding creates a new owner-card failure and candidate SHA. Never patch inside a review step or reuse the old verdict.

- [ ] **Step 14: Complete VSB in a ledger-only review receipt**

Write the exact `VSB03_CANDIDATE_SHA` into this terminal state:

```text
TaskCardSetStatus = COMPLETE
ActiveTaskCard = NONE
ReleasedTaskCard = NONE
CompletedTaskCards = VSB-00,VSB-01,VSB-02,VSB-03
CurrentCandidateSHA = ${VSB03_CANDIDATE_SHA}
CurrentGateStatus = VSB-G3_PASS
CurrentReviewRoute = deep_reviewer+ultra_gatekeeper
CurrentReviewVerdict = FINAL_GO_P0_0_P1_0_P2_0
VSB03CandidateSHA = ${VSB03_CANDIDATE_SHA}
VSB03GateStatus = VSB-G3_PASS
VSB03ReviewRoute = deep_reviewer+ultra_gatekeeper
VSB03DeepReviewVerdict = GO_P0_0_P1_0_P2_0
VSB03UltraReviewVerdict = FINAL_GO_P0_0_P1_0_P2_0
NextTaskCard = NONE
TransitionSequence = 5
TransitionKind = COMPLETE
TransitionBaseSHA = ${VSB03_CANDIDATE_SHA}
VisualImplementation = COMPLETE
FullProductImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

Commit only the ledger:

```bash
git add docs/task-cards/visual-style-baseline/execution-state.md
git commit -m "chore: close visual style baseline gate"
VSB03_RECEIPT_SHA="$(git rev-parse HEAD)"
scripts/verify-visual-style-baseline-cards \
  --repo-root . \
  --cards-dir docs/task-cards/visual-style-baseline \
  --transition-base "${VSB03_CANDIDATE_SHA}" \
  --transition-head "${VSB03_RECEIPT_SHA}"
VSB_FIXED_RUNTIME_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-vsb-fixed.XXXXXX")"
git show "${VSB03_CANDIDATE_SHA}:scripts/verify-visual-style-baseline" > \
  "${VSB_FIXED_RUNTIME_DIR}/verify-visual-style-baseline"
chmod +x "${VSB_FIXED_RUNTIME_DIR}/verify-visual-style-baseline"
env PATH="${VSB_TOOLCHAIN_PATH}" \
  "${VSB_FIXED_RUNTIME_DIR}/verify-visual-style-baseline" \
  --repo-root "$(pwd -P)" \
  --candidate-sha "${VSB03_CANDIDATE_SHA}"
rm -rf "${VSB_FIXED_RUNTIME_DIR}"
```

- [ ] **Step 15: Restore exactly W1-I03 in a separate projection receipt**

On the normal GO path, only after Step 14 passes, restore these exact Wave 1 facts. The separately authorized explicit-stop branch is defined in Task 1 and uses the same ten-path restore from its `STOPPED_BY_USER` receipt:

```text
TaskCardSetStatus = READY_FOR_EXECUTION
ActiveTaskCard = W1-I03
SuspendedTaskCard = NONE
SuspendedCandidateSHA = NONE
SuspendedCandidateMutation = NONE
W1-I03 Status = READY
W1-I03 table status = READY
BusinessImplementation = USER_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

Update exactly the ten `Restore after final VSB receipt only` paths listed at the top of Task 5; restore narrative projections to “W1-I03 is the unique READY card,” retain the completed VSB execution-state pointer, and do not amend or alter candidate `4e63936` or its production WriteSet.

```bash
git add \
  AGENTS.md \
  README.md \
  docs/design/wave-1/README.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-wave-1-design-plan.md \
  docs/engineering/cognitura-wave-1-design-acceptance.md \
  docs/engineering/cognitura-wave-1-implementation-plan.md \
  docs/task-cards/wave-1/README.md \
  docs/task-cards/wave-1-implementation/README.md \
  docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md
git diff --cached --check
git diff --cached --name-only
git commit -m "chore: restore Wave 1 DOCX security card"
W1_RESTORE_RECEIPT_SHA="$(git rev-parse HEAD)"
scripts/verify-wave1-implementation-cards \
  --repo-root . \
  --cards-dir docs/task-cards/wave-1-implementation \
  --transition-base "${VSB03_RECEIPT_SHA}" \
  --transition-head "${W1_RESTORE_RECEIPT_SHA}"
```

The Wave 1 transition validator must prove the direct-child diff equals the ten projection paths, the head returns only W1-I03 to READY, and every frozen production path remains byte-identical to `4e63936`.

- [ ] **Step 16: Run the final no-push acceptance suite**

```bash
VSB_FIXED_RUNTIME_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-vsb-fixed.XXXXXX")"
git show "${VSB03_CANDIDATE_SHA}:scripts/verify-visual-style-baseline" > \
  "${VSB_FIXED_RUNTIME_DIR}/verify-visual-style-baseline"
chmod +x "${VSB_FIXED_RUNTIME_DIR}/verify-visual-style-baseline"
env PATH="${VSB_TOOLCHAIN_PATH}" \
  "${VSB_FIXED_RUNTIME_DIR}/verify-visual-style-baseline" \
  --repo-root "$(pwd -P)" \
  --candidate-sha "${VSB03_CANDIDATE_SHA}"
rm -rf "${VSB_FIXED_RUNTIME_DIR}"
env PATH="${VSB_TOOLCHAIN_PATH}" scripts/verify-module-default-reading
scripts/verify-high-fidelity-visual
/bin/bash tests/task-cards/verify-wave1-implementation-cards.sh
/bin/bash tests/task-cards/verify-visual-style-baseline-cards.sh
scripts/verify-wave1-implementation-cards \
  --repo-root . \
  --cards-dir docs/task-cards/wave-1-implementation
scripts/verify-visual-style-baseline-cards \
  --repo-root . \
  --cards-dir docs/task-cards/visual-style-baseline
bash tests/ci/verify-markdown-links.sh
git diff --check
git status --short --branch
git log --oneline --decorate -12
```

Final acceptable state:

```text
VisualStyleBaseline = PASS
ModuleDefaultReadingVisualImplementation = PASS_WITHIN_EXISTING_CANONICAL_PROJECTION
FullModuleDefaultReadingBusinessAcceptance = BLOCKED_BY_DOC_GAP_MDR_001
ImplementationValidation = NOT_CLAIMED_FOR_FULL_PRODUCT_PAGE
Wave1TaskCardSetStatus = READY_FOR_EXECUTION
Wave1ActiveTaskCard = W1-I03
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
UntrackedUserState = .idea/
```

Do not push. Do not propagate styles to Domain Panorama, Theme, Element, Verification, or Revision without a new authorized card set.

---

## Plan Self-Review Checklist

- [ ] Every approved deliverable is owned by exactly one task/card.
- [ ] Every semantic deliverable path has one owning VSB card; explicitly enumerated authority/status projections may also appear in bootstrap, formal activation, or final restore receipts.
- [ ] W1 suspension and restoration are both independently testable and preserve `4e63936` production bytes.
- [ ] The formal Visual Style Reference distinguishes measured pixels from inferred system values.
- [ ] The five CSS files form one import chain and contain no parallel visual authority.
- [ ] Production data flow remains `CognitiveModule + RendererInput -> ModuleDefaultReading`; the synthetic fixture never enters production imports.
- [ ] App, route, backend, schema, database, raw input, and historical evidence remain out of scope.
- [ ] Browser evidence observes real evaluated DOM and computed style, not fixture-authored counters.
- [ ] The three required viewports and side-by-side comparison are generated and freshly recaptured.
- [ ] All fifteen acceptance fields fail closed; full product implementation is not overclaimed.
- [ ] Every candidate is independently reviewed at a fixed SHA; the final candidate has both deep and ultra reviews.
- [ ] No step contains a deferred placeholder or an unresolved design decision.
