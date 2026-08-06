# Cognitura High-Fidelity Design Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate the user-provided interaction-state design into Cognitura, produce verified high-fidelity visual and usability evidence, and stop with a development-entry prompt while business implementation remains unauthorized.

**Architecture:** Preserve Overall Design 1.2 as the product authority and adopt the new historical-named file as one subordinate specialty body after source, terminology, state-model, and conflict validation. Represent the 46 interaction names as orthogonal axes, transient states, flow phases, events, and derived results instead of extending the existing 12-value `PageState`. Use a documentation-only local prototype and captured screenshots as visual evidence; no files under `server/`, `web/`, migrations, or `raw/` may change.

**Tech Stack:** Markdown, YAML, Bash 3.2-compatible validators, static HTML/CSS/JavaScript design prototype under `docs/`, Google Chrome headless screenshots, Git, `gpt-5.6-sol/high` independent reviews.

## Global Constraints

- `CanonicalProjectName = Cognitura`.
- `CanonicalHierarchy = KnowledgeLandscape → KnowledgeTheme → CognitiveModule → KnowledgeElement`.
- `PrimaryReadingUnit = COGNITIVE_MODULE`.
- `PrimaryPresentationModel = INTERACTIVE_COGNITIVE_DOCUMENT`.
- `PrimaryExperienceModel = READING_FIRST`.
- `DeliveryPlatform = WEB_BROWSER`; `PrimaryExperience = DESKTOP_WEB`.
- `V1Architecture = MODULAR_MONOLITH`.
- `BusinessImplementation = NOT_AUTHORIZED`.
- `FormalDatabaseWrite = NOT_AUTHORIZED`.
- `RemotePush = NOT_AUTHORIZED`.
- Do not modify `server/**`, `web/**`, `raw/**`, database migrations, deployment configuration, or `.idea/`.
- Do not modify the linked `wave1-implementation-card-bootstrap` worktree or its W1-I00–W1-I13 cards.
- This authorization makes `HF-D00` the sole active design card on this branch; it does not create or release `W1-I00` and does not authorize business implementation.
- Keep these fixed Wave 0 historical contracts outside every HF/HV write set: `docs/engineering/cognitura-source-manifest.yaml`, `docs/engineering/cognitura-specialty-contract-coverage.md`, `scripts/verify-source-manifest`, `tests/source-manifest/verify-source-manifest.sh`, `scripts/verify-specialty-contract-coverage`, and `tests/contracts/specialty-coverage/verify-specialty-contract-coverage.sh`.
- Wave 0 source-manifest and specialty-coverage tests remain unchanged regression checks only; HF registration and coverage use independent HF governance assets.
- Do not read the Golden Case DOCX bodies or follow the Redis legacy local link.
- Preserve all 46 original state codes, 20 exception codes, 20 RF-AC items, and 30 reverse-migration items with one-to-one traceability.
- Contract, high-fidelity visual, high-fidelity usability, and implementation PASS are separate stages.
- All Gate and fixed-candidate reviews use `gpt-5.6-sol/high`; do not use ultra.
- Each design card produces one independently verifiable local commit.

---

### Task 1: HF-D00 Design Governance and Source Registration

**Files:**
- Create: `docs/task-cards/high-fidelity-design/README.md`
- Create: `docs/task-cards/high-fidelity-design/HF-D00-design-governance.md`
- Create: `docs/task-cards/high-fidelity-design/HF-D01-reading-presentation-contract.md`
- Create: `docs/task-cards/high-fidelity-design/HF-D02-interaction-state-model.md`
- Create: `docs/task-cards/high-fidelity-design/HF-D03-high-fidelity-evidence-contract.md`
- Create: `docs/task-cards/high-fidelity-design/HF-D04-fixed-design-review.md`
- Create: `scripts/verify-high-fidelity-design`
- Create: `tests/task-cards/verify-high-fidelity-design-cards.sh`
- Create: `scripts/verify-interaction-state-contracts`
- Create: `tests/contracts/interaction-state/verify-interaction-state-contracts.sh`
- Create: `docs/engineering/cognitura-high-fidelity-design-manifest.yaml`
- Create: `docs/engineering/cognitura-high-fidelity-contract-coverage.md`
- Create: `scripts/verify-high-fidelity-design-manifest`
- Create: `tests/contracts/interaction-state/verify-high-fidelity-design-manifest.sh`
- Create: `scripts/verify-high-fidelity-contract-coverage`
- Create: `tests/contracts/interaction-state/verify-high-fidelity-contract-coverage.sh`
- Modify: `Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `README.md`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: approved integration spec `docs/superpowers/specs/2026-08-06-high-fidelity-interaction-design-integration.md` and the untracked user candidate.
- Produces: a five-card `HIGH_FIDELITY_DESIGN` state machine with only `HF-D00` READY, an independently registered HF candidate source, HF contract coverage, and reproducible validator entrypoints.

- [ ] **Step 1: Create the failing card and interaction contract tests**

Write Bash checks that require exactly five `HF-Dxx` cards, only `HF-D00` READY, canonical project/hierarchy markers, exact state/exception/RF-AC counts, independent HF source registration and contract coverage, explicit `BusinessImplementation = NOT_AUTHORIZED`, and no W1-I00 creation or release.

- [ ] **Step 2: Run the tests and confirm RED**

Run:

```bash
bash tests/task-cards/verify-high-fidelity-design-cards.sh
bash tests/contracts/interaction-state/verify-interaction-state-contracts.sh
bash tests/contracts/interaction-state/verify-high-fidelity-design-manifest.sh
bash tests/contracts/interaction-state/verify-high-fidelity-contract-coverage.sh
```

Expected: all four fail because cards, normalized authority fields, independent HF source registration, and HF contract coverage do not yet exist.

- [ ] **Step 3: Bootstrap the five-card set and validator wrappers**

Create statuses:

```text
HF-D00 = READY
HF-D01 = BLOCKED_BY_DEPENDENCY
HF-D02 = BLOCKED_BY_DEPENDENCY
HF-D03 = BLOCKED_BY_DEPENDENCY
HF-D04 = BLOCKED_BY_DEPENDENCY
```

Each card must declare one design owner, exact write set, forbidden write set, Gate, positive/negative validation, and local-only commit boundary.

- [ ] **Step 4: Normalize the candidate identity and source authority**

Change self-declared formal status to `CANDIDATE_AWAITING_REPOSITORY_GATE`, add `CanonicalProjectName = Cognitura`, map historical aliases to the canonical hierarchy, replace unverifiable Git claims with actual repository status, and classify absent predecessor bodies as documentation gaps rather than verified authorities.

- [ ] **Step 5: Register the candidate without prematurely promoting it**

Add the file path, version, role, byte count, and SHA-256 to
`docs/engineering/cognitura-high-fidelity-design-manifest.yaml` and the design index. Record
the candidate's traceability and deferred Gate status in
`docs/engineering/cognitura-high-fidelity-contract-coverage.md`; it closes no Gate until
HF-D04. Do not change the fixed Wave 0 source manifest or specialty coverage.

- [ ] **Step 6: Run GREEN and negative mutations**

Run:

```bash
bash tests/task-cards/verify-high-fidelity-design-cards.sh
bash tests/contracts/interaction-state/verify-interaction-state-contracts.sh
bash tests/contracts/interaction-state/verify-high-fidelity-design-manifest.sh
bash tests/contracts/interaction-state/verify-high-fidelity-contract-coverage.sh
bash tests/source-manifest/verify-source-manifest.sh
bash tests/contracts/specialty-coverage/verify-specialty-contract-coverage.sh
git diff --check
```

Expected: all pass; temporary HF mutations for missing source, wrong hash, missing coverage,
missing state, wrong hierarchy, premature formal status, and a READY successor fail closed.
The two Wave 0 commands pass only as unchanged regression checks.

- [ ] **Step 7: Close HF-D00 and release HF-D01**

Set `HF-D00 = DONE`, `HF-D01 = READY`, update index/README/AGENTS projections, rerun the same commands, then commit:

```bash
git add AGENTS.md README.md \
  Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-high-fidelity-design-manifest.yaml \
  docs/engineering/cognitura-high-fidelity-contract-coverage.md \
  docs/task-cards/high-fidelity-design \
  scripts/verify-high-fidelity-design scripts/verify-interaction-state-contracts \
  scripts/verify-high-fidelity-design-manifest \
  scripts/verify-high-fidelity-contract-coverage \
  tests/task-cards/verify-high-fidelity-design-cards.sh \
  tests/contracts/interaction-state/verify-interaction-state-contracts.sh \
  tests/contracts/interaction-state/verify-high-fidelity-design-manifest.sh \
  tests/contracts/interaction-state/verify-high-fidelity-contract-coverage.sh
git commit -m "docs: establish high fidelity design governance"
```

### Task 2: HF-D01 Reading and Presentation Contract

**Files:**
- Modify: `Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md`
- Modify: `cognitive-knowledge-atlas-overall-design-1.2.md`
- Modify: `docs/contracts/cognitura-page-contracts.md`
- Modify: `docs/contracts/cognitura-renderer-contract.md`
- Modify: `tests/contracts/ui/verify-ui-contracts.sh`
- Modify: `docs/task-cards/high-fidelity-design/HF-D01-reading-presentation-contract.md`
- Modify: `docs/task-cards/high-fidelity-design/README.md`
- Modify: `README.md`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: HF-D00 registered specialty candidate.
- Produces: one authoritative conflict resolution for Reading First, continuous narrative, default side panels, visual budgets, and SourceEvidence access.

- [ ] **Step 1: Add failing UI contract assertions**

Require `INTERACTIVE_COGNITIVE_DOCUMENT`, structured continuous narrative, zero persistent governance side panels in default reading, on-demand SourceEvidence, retained hierarchy orientation, primary visual budget, and no independent Renderer facts.

- [ ] **Step 2: Confirm RED**

Run:

```bash
bash tests/contracts/ui/verify-ui-contracts.sh
```

Expected: fail on missing new contract lines and the old unconditional three-column interpretation.

- [ ] **Step 3: Apply the page and Renderer decisions**

Append only a traceable reverse-migration record to Overall 1.2 and minimally reconcile its ModuleReading/Page/Renderer contract without changing the historical version number or rewriting existing product authority. Change the ModuleReading default from permanent SourceEvidence/RelatedModules/KnownGaps right rail to on-demand source and context surfaces. Preserve full SourceEvidence route responsibility and the nine Renderer types.

- [ ] **Step 4: Make density budgets operational**

Define CognitiveSection, PrimaryVisualProjection, PrimaryVisualPrimitiveFamily, SimultaneouslyEmphasizedVisualObject, and PrimaryAction measurement rules in the specialty; project only stable non-Schema invariants into page/Renderer contracts.

- [ ] **Step 5: Run UI and cross-document validation**

Run:

```bash
bash tests/contracts/ui/verify-ui-contracts.sh
bash tests/contracts/interaction-state/verify-interaction-state-contracts.sh
bash tests/contracts/specialty-coverage/verify-specialty-contract-coverage.sh
bash tests/source-manifest/verify-source-manifest.sh
bash tests/ci/verify-markdown-links.sh
git diff --check
```

Expected: all pass; mutations for permanent governance rail, pure article, and Renderer-created facts fail.

- [ ] **Step 6: Close HF-D01 and release HF-D02**

Update task-card projections, rerun the Gate, and commit:

```bash
git add AGENTS.md README.md \
  Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md \
  cognitive-knowledge-atlas-overall-design-1.2.md \
  docs/contracts/cognitura-page-contracts.md \
  docs/contracts/cognitura-renderer-contract.md \
  docs/task-cards/high-fidelity-design \
  tests/contracts/ui/verify-ui-contracts.sh
git commit -m "docs: align reading first presentation contracts"
```

### Task 3: HF-D02 Orthogonal State and Recovery Model

**Files:**
- Modify: `Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md`
- Modify: `docs/contracts/cognitura-page-contracts.md`
- Modify: `tests/contracts/interaction-state/verify-interaction-state-contracts.sh`
- Modify: `docs/task-cards/high-fidelity-design/HF-D02-interaction-state-model.md`
- Modify: `docs/task-cards/high-fidelity-design/README.md`
- Modify: `README.md`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: HF-D01 presentation contract and the original 46 state definitions.
- Produces: exact one-owner classification of every original state code plus URL, History, draft, session, and Canonical persistence boundaries.

- [ ] **Step 1: Extend the validator to require all 46 classification rows**

Each row must contain:

```text
OriginalStateCode
Classification = AXIS_VALUE|TRANSIENT_UI|FLOW_PHASE|EVENT|DERIVED_RESULT
OwningAxisOrFlow
PersistenceBoundary
URLHistoryDisposition
CanonicalWriteBoundary
```

Add mutations for duplicate Owner, unclassified state, event persisted as state, `GENERATING` namespace collision, and Preview in URL.

- [ ] **Step 2: Confirm RED**

Run:

```bash
bash tests/contracts/interaction-state/verify-interaction-state-contracts.sh
```

Expected: fail because the classification table and persistence ledger are absent.

- [ ] **Step 3: Add the six-axis snapshot and flow decomposition**

Document `ModeAxis`, `FocusAxis`, `AuxiliarySurfaceAxis`, `DraftAxis`, `ProcessingAxis`, and `RecoveryAxis`; separate navigation events and derived results. Namespace local projection generation as `PROJECTION_GENERATING` while retaining original `GENERATING` as a traced historical code.

- [ ] **Step 4: Add persistence and recovery ledgers**

Define Ephemeral UI, URL, Browser History, Session/Draft Store, and Canonical Server State. Preserve the 20 exception matrices, submit-unknown semantics, idempotent result query, explicit stale projection, and Revert-as-new-ChangeSet rules.

- [ ] **Step 5: Record Schema non-change decision**

State that `schemas/ui/page-state.schema.json`, Renderer Input, Catalog, and evidence map stay unchanged. Map candidate logical object names to existing revision/Relation/Evidence concepts without specifying physical tables.

- [ ] **Step 6: Run the Gate and close the card**

Run:

```bash
bash tests/contracts/interaction-state/verify-interaction-state-contracts.sh
bash tests/contracts/ui/verify-ui-contracts.sh
bash tests/contracts/schema/verify-json-schemas.sh
bash tests/source-manifest/verify-source-manifest.sh
bash tests/task-cards/verify-high-fidelity-design-cards.sh
git diff --check
```

Expected: all pass and PageState remains the original 12-value lifecycle enum.

Set `HF-D02 = DONE`, `HF-D03 = READY`, rerun, and commit:

```bash
git add AGENTS.md README.md \
  Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md \
  docs/contracts/cognitura-page-contracts.md \
  docs/task-cards/high-fidelity-design \
  tests/contracts/interaction-state/verify-interaction-state-contracts.sh
git commit -m "docs: normalize interaction state and recovery model"
```

### Task 4: HF-D03 High-Fidelity Evidence Contract

**Files:**
- Create: `docs/engineering/cognitura-high-fidelity-design-plan.md`
- Create: `docs/engineering/cognitura-high-fidelity-design-acceptance.md`
- Modify: `Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `tests/contracts/interaction-state/verify-interaction-state-contracts.sh`
- Modify: `docs/task-cards/high-fidelity-design/HF-D03-high-fidelity-evidence-contract.md`
- Modify: `docs/task-cards/high-fidelity-design/README.md`
- Modify: `README.md`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: HF-D02 normalized state model.
- Produces: eight required visual evidence classes, 20 RF-AC acceptance rows, two cross-domain scenarios, and a second small task-card set for visual design.

- [ ] **Step 1: Add failing evidence-stage assertions**

Require the eight evidence classes, 20 RF-AC rows, 20 exceptions, mechanism/rule cross-domain coverage, and explicit `HighFidelityVisualDesign = NOT_RUN`, `HighFidelityUsabilityValidation = NOT_RUN`.

- [ ] **Step 2: Confirm RED**

Run:

```bash
bash tests/contracts/interaction-state/verify-interaction-state-contracts.sh
```

Expected: fail because plan/acceptance records and visual task-card set do not exist.

- [ ] **Step 3: Write the visual design plan and acceptance record**

Define the ordered evidence path: Module default reading, Relation focus, source verification, revision/impact, recovery, Domain/Theme, small screen, static export. Record every stage as NOT_RUN until real artifacts are captured.

- [ ] **Step 4: Bootstrap the visual design card set**

Add to the engineering plan:

```text
HV-D00 VisualFoundation
HV-D01 ModuleDefaultReading
HV-D02 FocusAndSource
HV-D03 RevisionAndRecovery
HV-D04 CrossLayerResponsiveAndExport
HV-D05 FixedVisualUsabilityReview
```

Only `HV-D00` becomes READY after HF-D04 closes; no visual card is READY during HF-D03.

- [ ] **Step 5: Run the Gate and close the card**

Run:

```bash
bash tests/contracts/interaction-state/verify-interaction-state-contracts.sh
bash tests/task-cards/verify-high-fidelity-design-cards.sh
bash tests/source-manifest/verify-source-manifest.sh
bash tests/ci/verify-markdown-links.sh
git diff --check
```

Set `HF-D03 = DONE`, `HF-D04 = READY`, rerun, and commit:

```bash
git add AGENTS.md README.md \
  Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-high-fidelity-design-plan.md \
  docs/engineering/cognitura-high-fidelity-design-acceptance.md \
  docs/task-cards/high-fidelity-design \
  tests/contracts/interaction-state/verify-interaction-state-contracts.sh
git commit -m "docs: define high fidelity evidence gates"
```

### Task 5: HF-D04 Fixed Contract Candidate Review

**Files:**
- Modify: `docs/engineering/cognitura-high-fidelity-design-acceptance.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/task-cards/high-fidelity-design/HF-D04-fixed-design-review.md`
- Modify: `docs/task-cards/high-fidelity-design/README.md`
- Modify: `README.md`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: fixed HF-D00–HF-D03 candidate.
- Produces: two independent `gpt-5.6-sol/high` contract review results and a closed `HIGH_FIDELITY_DESIGN` card set.

- [ ] **Step 1: Freeze and verify the candidate**

Run:

```bash
scripts/verify-high-fidelity-design
scripts/verify-wave0
git diff --check
git status --short
```

Commit any evidence-only preparation before review so reviewers receive an immutable SHA.

- [ ] **Step 2: Run independent general and final reviews**

Dispatch two independent agents using `gpt-5.6-sol/high`. Each must inspect the same SHA and return `GO|NO_GO` with P0/P1/P2 counts. Neither reviewer may edit files.

- [ ] **Step 3: Repair findings through the owning card**

If either review reports a finding, reopen the exact owner card, add a failing regression assertion, repair the design, rerun all Gates, create a new SHA, and repeat both reviews. Do not edit the fixed candidate during review.

- [ ] **Step 4: Close the integration card set**

Only with both reviews at `GO / P0=0 / P1=0 / P2=0`, set all HF cards DONE, promote the specialty to `FORMAL_SPECIALTY_BASELINE`, record reviewed SHA and results, and release `HV-D00 = READY` in the visual design plan.

- [ ] **Step 5: Verify and commit closure**

Run:

```bash
scripts/verify-high-fidelity-design
scripts/verify-wave0
git diff --check
```

Commit:

```bash
git add AGENTS.md README.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-high-fidelity-design-acceptance.md \
  docs/task-cards/high-fidelity-design
git commit -m "docs: close high fidelity contract design gate"
```

### Task 6: HV-D00 Visual Foundation and Prototype Governance

**Files:**
- Create: `docs/task-cards/high-fidelity-visual/README.md`
- Create: `docs/task-cards/high-fidelity-visual/HV-D00-visual-foundation.md`
- Create: `docs/task-cards/high-fidelity-visual/HV-D01-module-default-reading.md`
- Create: `docs/task-cards/high-fidelity-visual/HV-D02-focus-and-source.md`
- Create: `docs/task-cards/high-fidelity-visual/HV-D03-revision-and-recovery.md`
- Create: `docs/task-cards/high-fidelity-visual/HV-D04-cross-layer-responsive-export.md`
- Create: `docs/task-cards/high-fidelity-visual/HV-D05-fixed-visual-usability-review.md`
- Create: `tests/task-cards/verify-high-fidelity-visual-cards.sh`
- Create: `scripts/verify-high-fidelity-visual`
- Create: `docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md`
- Create: `docs/design/high-fidelity/prototype/index.html`
- Create: `docs/design/high-fidelity/prototype/styles.css`
- Create: `docs/design/high-fidelity/prototype/prototype.js`
- Create: `docs/design/high-fidelity/evidence/README.md`
- Modify: `docs/engineering/cognitura-high-fidelity-design-plan.md`
- Modify: `README.md`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: closed HF contract design and the eight evidence classes.
- Produces: a documentation-only prototype shell, visual tokens, interaction-state fixture selector, screenshot contract, and six-card visual design state machine.

- [ ] **Step 1: Write failing visual card and artifact validators**

Require six cards, one READY card, non-production prototype labels, desktop/small-screen viewports, visual token names, state fixture IDs, screenshot naming, and no imports from `web/` or server APIs.

- [ ] **Step 2: Confirm RED**

Run:

```bash
bash tests/task-cards/verify-high-fidelity-visual-cards.sh
```

Expected: fail because the visual set and prototype do not exist.

- [ ] **Step 3: Create the visual system and prototype shell**

Define typography, spacing, colors, focus ring, document width, hierarchy rail, inline relation treatment, source marker, stale/error tokens, and responsive thresholds. The prototype must use embedded deterministic fixture data and URL query parameters only; it must not call HTTP or persist user data.

- [ ] **Step 4: Capture the foundation screen**

Run Chrome headless against the local prototype and capture a 1440×1100 screenshot into `docs/design/high-fidelity/evidence/`:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless=new --disable-gpu --hide-scrollbars \
  --window-size=1440,1100 \
  --screenshot="docs/design/high-fidelity/evidence/visual-foundation-desktop.png" \
  "file:///Users/yuzhuangzhuang/Projects/cognitura/docs/design/high-fidelity/prototype/index.html?state=visual-foundation"
```

Inspect the PNG locally before acceptance.

- [ ] **Step 5: Close HV-D00 and release HV-D01**

Run validators, update projections, and commit:

```bash
git add AGENTS.md README.md docs/design/high-fidelity \
  docs/engineering/cognitura-high-fidelity-design-plan.md \
  docs/task-cards/high-fidelity-visual \
  scripts/verify-high-fidelity-visual \
  tests/task-cards/verify-high-fidelity-visual-cards.sh
git commit -m "docs: establish high fidelity visual foundation"
```

### Task 7: HV-D01 Module Default Reading Evidence

**Files:**
- Modify: `docs/design/high-fidelity/prototype/index.html`
- Modify: `docs/design/high-fidelity/prototype/styles.css`
- Modify: `docs/design/high-fidelity/prototype/prototype.js`
- Modify: `docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md`
- Create: `docs/design/high-fidelity/evidence/module-default-reading-desktop.png`
- Modify: `docs/engineering/cognitura-high-fidelity-design-acceptance.md`
- Modify: `docs/task-cards/high-fidelity-visual/HV-D01-module-default-reading.md`
- Modify: `docs/task-cards/high-fidelity-visual/README.md`

**Interfaces:**
- Consumes: visual foundation and MySQL mechanism-type synthetic cognitive fixture.
- Produces: the primary desktop Module reading page proving zero-interaction cognitive closure.

- [ ] **Step 1: Add failing DOM and screenshot assertions**

Require CoreQuestion, CoreConclusion, continuous narrative, PrimaryCognitiveSpine, one primary visual projection, Conditions, Results, Boundaries/Exceptions, 1–3 Relations, and a source entry with zero persistent governance side panels.

- [ ] **Step 2: Implement the static design state and capture evidence**

Use deterministic synthetic content derived from the contract example rather than reading Golden Case DOCX. Capture at 1440×1100 with:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless=new --disable-gpu --hide-scrollbars \
  --window-size=1440,1100 \
  --screenshot="docs/design/high-fidelity/evidence/module-default-reading-desktop.png" \
  "file:///Users/yuzhuangzhuang/Projects/cognitura/docs/design/high-fidelity/prototype/index.html?state=module-default"
```

Inspect the PNG before recording acceptance.

- [ ] **Step 3: Evaluate RF-AC-01 through RF-AC-12 and RF-AC-15**

Record each result against the screenshot and DOM fixture. Mark only `HIGH_FIDELITY_VISUAL`; leave usability NOT_RUN.

- [ ] **Step 4: Close HV-D01 and release HV-D02**

Run visual/card/interaction validators and commit `docs: design module default reading evidence`.

### Task 8: HV-D02 Relation Focus and Source Verification Evidence

**Files:**
- Modify: `docs/design/high-fidelity/prototype/*`
- Create: `docs/design/high-fidelity/evidence/module-relation-focus-desktop.png`
- Create: `docs/design/high-fidelity/evidence/module-source-verification-desktop.png`
- Modify: `docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md`
- Modify: `docs/engineering/cognitura-high-fidelity-design-acceptance.md`
- Modify: `docs/task-cards/high-fidelity-visual/HV-D02-focus-and-source.md`
- Modify: `docs/task-cards/high-fidelity-visual/README.md`

**Interfaces:**
- Consumes: Module default reading state.
- Produces: single-primary Relation focus, endpoint hierarchy, Quick Source, full verification, keyboard focus return, and explicit source-gap visuals.

- [ ] **Step 1: Add failing state-fixture assertions**

Require one primary focus, origin anchor, relation statement, endpoints at secondary weight, evidence support scope, conflict state, source gap, Escape return target, and no independent facts.

- [ ] **Step 2: Implement and capture both desktop states**

Capture deterministic screenshots for `RELATION_PINNED_FOCUS` and `FULL_VERIFICATION_WORKSPACE` with the Task 7 Chrome command, using `state=relation-focus` and `state=source-verification` and their declared output filenames.

- [ ] **Step 3: Run keyboard/touch-equivalence desk validation**

Use the prototype controls to verify Tab order, Enter activation, Escape close order, explicit touch-equivalent actions, and focus restoration. Record visual evidence separately from usability observations.

- [ ] **Step 4: Close HV-D02 and release HV-D03**

Run all visual validators and commit `docs: design focus and source verification evidence`.

### Task 9: HV-D03 Revision, Impact, and Recovery Evidence

**Files:**
- Modify: `docs/design/high-fidelity/prototype/*`
- Create: `docs/design/high-fidelity/evidence/module-revision-impact-desktop.png`
- Create: `docs/design/high-fidelity/evidence/module-partial-failure-desktop.png`
- Create: `docs/design/high-fidelity/evidence/module-conflicted-draft-desktop.png`
- Modify: `docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md`
- Modify: `docs/engineering/cognitura-high-fidelity-design-acceptance.md`
- Modify: `docs/task-cards/high-fidelity-visual/HV-D03-revision-and-recovery.md`
- Modify: `docs/task-cards/high-fidelity-visual/README.md`

**Interfaces:**
- Consumes: state axes, 20 exception contracts, and source verification design.
- Produces: Quick-to-Full upgrade, three-lane impact, commit boundaries, partial failure, stale projection, conflict draft, and Revert evidence.

- [ ] **Step 1: Add failing revision/recovery assertions**

Require Before/After, Semantic/Structural/Expression impact lanes, expanded Blocker, commit disabled, draft preserved, Canonical-saved boundary, stale mark, retry, result query, and Revert-as-new-change.

- [ ] **Step 2: Implement and capture the three high-risk states**

Capture revision impact, canonical-saved partial failure, and conflicted draft screens at 1440×1100 with the Task 7 Chrome command, using `state=revision-impact`, `state=partial-failure`, and `state=conflicted-draft`.

- [ ] **Step 3: Validate RF-AC-13, RF-AC-14, RF-AC-16, RF-AC-17, and RF-AC-18**

Record visual results and execute deterministic prototype transitions for duplicate submit, refresh restore, conflict rebase, and Escape close order.

- [ ] **Step 4: Close HV-D03 and release HV-D04**

Run all visual validators and commit `docs: design revision and recovery evidence`.

### Task 10: HV-D04 Cross-Layer, Responsive, and Export Evidence

**Files:**
- Modify: `docs/design/high-fidelity/prototype/*`
- Create: `docs/design/high-fidelity/evidence/domain-default-reading-desktop.png`
- Create: `docs/design/high-fidelity/evidence/theme-default-reading-desktop.png`
- Create: `docs/design/high-fidelity/evidence/module-default-reading-small-screen.png`
- Create: `docs/design/high-fidelity/evidence/static-export-example.png`
- Create: `docs/design/high-fidelity/evidence/static-export-manifest.json`
- Modify: `docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md`
- Modify: `docs/engineering/cognitura-high-fidelity-design-acceptance.md`
- Modify: `docs/task-cards/high-fidelity-visual/HV-D04-cross-layer-responsive-export.md`
- Modify: `docs/task-cards/high-fidelity-visual/README.md`

**Interfaces:**
- Consumes: validated Module states.
- Produces: Domain, Theme, small-screen, and static export evidence with stable machine-readable identity.

- [ ] **Step 1: Add failing cross-layer and export assertions**

Require canonical hierarchy labels, core questions, responsibilities, boundaries, no card wall, no graph workspace, small-screen document flow, no persistent side panel, and stable export IDs in the companion manifest but hidden from normal reading.

- [ ] **Step 2: Implement and capture four evidence states**

Capture desktop Domain/Theme at 1440×1100 with `state=domain-default` and `state=theme-default`. Capture small-screen Module with `--window-size=390,844` and `state=module-small-screen`; capture static export with `--window-size=1200,1600` and `state=static-export`. Use the same Chrome binary and flags as Task 7 and the filenames declared in this task.

- [ ] **Step 3: Validate RF-AC-15, RF-AC-19, and RF-AC-20**

Check responsive safety, export identity, and low-fidelity-to-high-fidelity traceability.

- [ ] **Step 4: Close HV-D04 and release HV-D05**

Run all visual validators and commit `docs: complete cross layer visual evidence`.

### Task 11: HV-D05 Fixed Visual and Usability Review

**Files:**
- Modify: `docs/engineering/cognitura-high-fidelity-design-acceptance.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/task-cards/high-fidelity-visual/HV-D05-fixed-visual-usability-review.md`
- Modify: `docs/task-cards/high-fidelity-visual/README.md`
- Modify: `README.md`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: all eight evidence classes, screenshots, prototype transitions, RF-AC results, and exception recovery observations.
- Produces: independent visual/usability GO results and `HighFidelityDesignStatus = COMPLETE` without authorizing implementation.

- [ ] **Step 1: Run complete local evidence validation**

Run:

```bash
scripts/verify-high-fidelity-design
scripts/verify-high-fidelity-visual
scripts/verify-wave0
git diff --check
```

- [ ] **Step 2: Freeze the candidate and run two independent sol/high reviews**

The first review checks visual hierarchy, density, state distinguishability, accessibility, and cross-layer consistency. The second checks usability paths, History/refresh/draft recovery, exception handling, source fidelity, and development readiness. Both use the same SHA and make no edits.

- [ ] **Step 3: Repair findings through HV-D01–HV-D04 ownership**

For any finding, add a failing validator or acceptance observation, repair the owner artifact, capture replacement evidence, create a new SHA, and repeat both reviews.

- [ ] **Step 4: Close visual and usability stages**

Only after both reviews report `GO / P0=0 / P1=0 / P2=0`, record:

```text
HighFidelityVisualDesign = PASS
HighFidelityVisualValidation = PASS
HighFidelityUsabilityValidation = PASS
HighFidelityStateAcceptance = PASS
ImplementationValidation = NOT_RUN
BusinessImplementation = NOT_AUTHORIZED
```

Commit `docs: close high fidelity visual design gate`.

### Task 12: Development-Entry Prompt and Final Design Boundary

**Files:**
- Create: `docs/engineering/cognitura-development-entry-prompt.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `README.md`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: closed contract, visual, and usability design Gates.
- Produces: a copyable next-session prompt that asks for implementation task-card planning and explicit business authorization without authorizing code itself.

- [ ] **Step 1: Write the development-entry prompt**

The prompt must direct the next agent to re-check live HEAD/worktree/Gates, create small implementation task cards for the first `ModuleDefaultReadingState` slice, keep Schema and database changes separate, use test-first implementation, preserve existing Wave 1 source work, and stop before code until the user explicitly approves the written implementation cards.

- [ ] **Step 2: Add final authorization assertions**

Require these exact terminal fields:

```text
DesignAlignmentStatus = COMPLETE
DevelopmentPlanningEntry = READY_FOR_USER_AUTHORIZATION
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
ActiveImplementationTaskCard = NONE
```

- [ ] **Step 3: Run fresh final verification**

Run:

```bash
scripts/verify-high-fidelity-design
scripts/verify-high-fidelity-visual
scripts/verify-wave0
bash tests/ci/verify-markdown-links.sh
git diff --check
git status --short
```

Expected: all Gate commands pass; only `.idea/` remains unrelated user state; no remote push occurs.

- [ ] **Step 4: Commit the final design checkpoint**

```bash
git add AGENTS.md README.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-development-entry-prompt.md
git commit -m "docs: prepare Cognitura development entry prompt"
```

Stop after this commit and present the prompt to the user. Do not create implementation cards or business code in this plan.
