# Cognitura Wave 1 Implementation Task Card Bootstrap Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the approved 14-card Wave 1 implementation task-card set, execute only the non-business W1-I00 governance slice, and stop before W1-I01 at the explicit business-implementation authorization Gate.

**Architecture:** Bootstrap the card documents in a dedicated `wave-1-implementation` directory before the validator exists, then treat W1-I00 as the owner of the validator, mutation tests and unified implementation verification entrypoint. The bootstrap never touches product code; after W1-I00 passes review, the set has no READY implementation card until the user separately authorizes W1-I01.

**Tech Stack:** Bash 3.2-compatible validators, Markdown task cards, Git, existing Wave 0 and Wave 1 design verification scripts.

## Global Constraints

- Canonical project name is `Cognitura`.
- The approved design input is commit `17dabff23b029e1a6fc7f47155f552ed3f16d775`.
- The implementation slicing specification is `docs/superpowers/specs/2026-07-30-wave1-implementation-slicing-design.md`.
- Exactly 14 cards are allowed: `W1-I00` through `W1-I13`.
- Each card has one fact owner or risk surface and exactly one `PrimaryBoundary`.
- `ProductionFileLimit = 8`; an exception requires a non-empty atomicity reason and independent Gate evidence.
- Database, Parser, HTTP and Web production boundaries may not be combined in one card.
- At most one card is `READY`.
- The bootstrap and W1-I00 may not modify `server/`, `web/`, migrations, provider configuration or `raw/`.
- `BusinessImplementation = NOT_AUTHORIZED`.
- `FormalDatabaseWrite = NOT_AUTHORIZED`.
- `RemotePush = NOT_AUTHORIZED`.
- Preserve the untracked `.idea/` directory and all unrelated user changes.
- Do not read Golden Case DOCX contents or access the Redis legacy link target.

---

## File Structure

The bootstrap creates:

```text
docs/task-cards/wave-1-implementation/
  README.md
  W1-I00-implementation-governance.md
  W1-I01-source-ingestion-domain.md
  W1-I02-source-persistence.md
  W1-I03-docx-security-gate.md
  W1-I04-text-list-section-parser.md
  W1-I05-table-fidelity.md
  W1-I06-image-anchor-relationship-projection.md
  W1-I07-revision-attempt-fencing-publication.md
  W1-I08-stable-reference-reparse-lineage.md
  W1-I09-upload-processing-command-api.md
  W1-I10-source-preview-query-api.md
  W1-I11-partial-acceptance-command-api.md
  W1-I12-desktop-web-source-preview.md
  W1-I13-fixed-implementation-review.md
```

W1-I00 creates:

```text
scripts/verify-wave1-implementation-cards
scripts/verify-wave1-implementation
tests/task-cards/verify-wave1-implementation-cards.sh
docs/engineering/cognitura-wave-1-implementation-plan.md
```

Dynamic status projections modified during bootstrap and W1-I00:

```text
AGENTS.md
README.md
docs/design/wave-1/README.md
docs/engineering/cognitura-design-index.md
docs/engineering/cognitura-wave-1-design-plan.md
docs/engineering/cognitura-wave-1-design-acceptance.md
docs/task-cards/wave-1/README.md
docs/superpowers/specs/2026-07-30-wave1-implementation-slicing-design.md
```

Historical W1-D00 through W1-D05 cards and the four approved Wave 1 contracts are read-only
inputs. Their historical candidate evidence must not be rewritten.

## Card Contract Matrix

The task-card bodies must use this exact Gate, risk and primary production write-set mapping.
Tests, synthetic fixtures and status documents remain separately declared in each card.

| Card | Gate | Risk | PrimaryBoundary | Allowed production write-set root |
|---|---|---|---|---|
| `W1-I00` | `W1-IG0 ImplementationGovernance` | `HIGH` | `TASK_CARD_GOVERNANCE` | `NONE` |
| `W1-I01` | `W1-IG1 SourceIntakeDomain` | `HIGH` | `SOURCE_DOMAIN` | `server/src/main/java/io/cognitura/source/domain/**` |
| `W1-I02` | `W1-IG2 SourcePersistence` | `HIGH` | `SOURCE_PERSISTENCE` | `server/src/main/java/io/cognitura/source/persistence/**`, `server/src/main/resources/db/migration/**` |
| `W1-I03` | `W1-IG3 DocxSecurity` | `HIGH` | `DOCX_SECURITY` | `server/src/main/java/io/cognitura/source/docx/security/**` |
| `W1-I04` | `W1-IG4 TextListSectionParser` | `HIGH` | `DOCX_PARSER` | `server/src/main/java/io/cognitura/source/docx/text/**` |
| `W1-I05` | `W1-IG5 TableFidelity` | `HIGH` | `DOCX_TABLE_PARSER` | `server/src/main/java/io/cognitura/source/docx/table/**` |
| `W1-I06` | `W1-IG6 ImageRelationshipProjection` | `HIGH` | `DOCX_IMAGE_PARSER` | `server/src/main/java/io/cognitura/source/docx/image/**` |
| `W1-I07` | `W1-IG7 ProcessingPublication` | `HIGH` | `SOURCE_APPLICATION` | `server/src/main/java/io/cognitura/source/application/processing/**` |
| `W1-I08` | `W1-IG8 StableReferenceReparse` | `HIGH` | `SOURCE_REFERENCE` | `server/src/main/java/io/cognitura/source/reference/**` |
| `W1-I09` | `W1-IG9 UploadProcessingCommandApi` | `HIGH` | `SOURCE_HTTP_COMMAND` | `server/src/main/java/io/cognitura/source/api/command/**` |
| `W1-I10` | `W1-IG10 SourcePreviewQueryApi` | `HIGH` | `SOURCE_HTTP_QUERY` | `server/src/main/java/io/cognitura/source/api/query/**` |
| `W1-I11` | `W1-IG11 PartialAcceptanceCommandApi` | `HIGH` | `SOURCE_HTTP_COMMAND` | `server/src/main/java/io/cognitura/source/api/acceptance/**` |
| `W1-I12` | `W1-IG12 DesktopWebSourcePreview` | `MEDIUM` | `WEB_DOCUMENT_INGESTION` | `web/src/modules/document-ingestion/**` |
| `W1-I13` | `W1-IG13 FixedImplementationReview` | `HIGH` | `WAVE1_IMPLEMENTATION_GATE` | `NONE` |

Each server card may also modify its matching test package under
`server/src/test/java/io/cognitura/source/**`. I02 alone may create Flyway files. I12 alone may
modify Web production files. I00 and I13 may modify only governance, verification and status
documents. No card may expand its allowed root without a separately approved task-card amendment.

### Task 1: Bootstrap governance and domain card documents

**Files:**
- Create: `docs/task-cards/wave-1-implementation/W1-I00-implementation-governance.md`
- Create: `docs/task-cards/wave-1-implementation/W1-I01-source-ingestion-domain.md`
- Create: `docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md`
- Create: `docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md`

**Interfaces:**
- Consumes: approved slicing specification sections 3–6.
- Produces: exact card metadata and write-set contracts used by the implementation-card validator.

- [ ] **Step 1: Create the four card headers**

Each card must contain exactly one value for every field:

```text
TaskCardID
CardKind
Status
Gate
Risk
DependsOn
PrimaryBoundary
ProductionFileLimit
ProductionWriteSetException
BusinessImplementationAuthorization
FormalDatabaseGate
RemotePush
```

Use these exact dynamic values:

```text
W1-I00 Status = READY
W1-I00 BusinessImplementationAuthorization = NOT_REQUIRED_GOVERNANCE_ONLY
W1-I00 FormalDatabaseGate = NOT_APPLICABLE
W1-I01 Status = BLOCKED_BY_USER_AUTHORIZATION
W1-I01 BusinessImplementationAuthorization = REQUIRED_BEFORE_READY
W1-I02 Status = BLOCKED_BY_DEPENDENCY
W1-I02 FormalDatabaseGate = REQUIRED_BEFORE_READY
W1-I03 Status = BLOCKED_BY_DEPENDENCY
RemotePush = NOT_AUTHORIZED
ProductionFileLimit = 8
ProductionWriteSetException = NONE
```

- [ ] **Step 2: Add the seven required sections**

Every card must use:

```markdown
## 1. 目标
## 2. 前置条件与输入
## 3. 写集
## 4. 执行步骤
## 5. 验证命令
## 6. Gate 与完成定义
## 7. 提交与审查
```

I00's write set is limited to the validator, its tests, the unified entrypoint, implementation
plan and status projections. I01–I03 must copy their exact boundaries from the approved slicing
specification and explicitly forbid every out-of-scope runtime boundary.

- [ ] **Step 3: Run targeted document checks**

Run:

```bash
for card in docs/task-cards/wave-1-implementation/W1-I0{0,1,2,3}-*.md; do
  test "$(grep -c '^TaskCardID = ' "$card")" -eq 1
  test "$(grep -c '^PrimaryBoundary = ' "$card")" -eq 1
  test "$(grep -c '^ProductionFileLimit = 8$' "$card")" -eq 1
  test "$(grep -c '^## [1-7]\\. ' "$card")" -eq 7
done
```

Expected: exit code `0`.

- [ ] **Step 4: Verify no forbidden write leaked into I00**

Run:

```bash
! rg -n 'server/|web/|migration|raw/' \
  docs/task-cards/wave-1-implementation/W1-I00-implementation-governance.md
```

Expected: exit code `0`.

- [ ] **Step 5: Commit**

```bash
git add docs/task-cards/wave-1-implementation/W1-I0{0,1,2,3}-*.md
git commit -m "docs: bootstrap Wave 1 implementation governance cards"
```

### Task 2: Bootstrap parser fidelity card documents

**Files:**
- Create: `docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md`
- Create: `docs/task-cards/wave-1-implementation/W1-I05-table-fidelity.md`
- Create: `docs/task-cards/wave-1-implementation/W1-I06-image-anchor-relationship-projection.md`

**Interfaces:**
- Consumes: D02 DocumentBlock fidelity and safety contract.
- Produces: three independently reviewable Parser risk surfaces.

- [ ] **Step 1: Create I04 with only HEADING, PARAGRAPH and LIST ownership**

The card must declare:

```text
PrimaryBoundary = DOCX_PARSER
DependsOn = W1-I03
SupportedBlockTypes = HEADING,PARAGRAPH,LIST
```

Its forbidden write set includes table fidelity, image bytes/anchors, publication, HTTP and Web.

- [ ] **Step 2: Create I05 with only table fidelity ownership**

The card must declare:

```text
PrimaryBoundary = DOCX_TABLE_PARSER
DependsOn = W1-I04
```

Its Gate must cover rows, columns, cell text, merged-cell evidence and deterministic cell order.

- [ ] **Step 3: Create I06 with only image and relationship projection ownership**

The card must declare:

```text
PrimaryBoundary = DOCX_IMAGE_PARSER
DependsOn = W1-I04,W1-I05
ExternalRelationshipDereference = FORBIDDEN
```

Its Gate must observe zero stat, DNS, file-read and network access for external targets.

- [ ] **Step 4: Run targeted boundary checks**

Run:

```bash
test "$(rg -l '^PrimaryBoundary = DOCX_' \
  docs/task-cards/wave-1-implementation/W1-I0{4,5,6}-*.md | wc -l | tr -d ' ')" = 3
rg -n '^ExternalRelationshipDereference = FORBIDDEN$' \
  docs/task-cards/wave-1-implementation/W1-I06-image-anchor-relationship-projection.md
```

Expected: three Parser cards and one exact external-access fence.

- [ ] **Step 5: Commit**

```bash
git add docs/task-cards/wave-1-implementation/W1-I0{4,5,6}-*.md
git commit -m "docs: bootstrap Wave 1 parser task cards"
```

### Task 3: Bootstrap publication, reference and command card documents

**Files:**
- Create: `docs/task-cards/wave-1-implementation/W1-I07-revision-attempt-fencing-publication.md`
- Create: `docs/task-cards/wave-1-implementation/W1-I08-stable-reference-reparse-lineage.md`
- Create: `docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md`

**Interfaces:**
- Consumes: D01 lifecycle, D03 stable-reference and D04 command contracts.
- Produces: separate application, reference and HTTP command boundaries.

- [ ] **Step 1: Create I07 with the atomic-publication dependency join**

Use:

```text
PrimaryBoundary = SOURCE_APPLICATION
DependsOn = W1-I02,W1-I04,W1-I05,W1-I06
```

The Gate must name expected attempt status and observed lease expiry in the timeout CAS negative.

- [ ] **Step 2: Create I08 with immutable reference ownership**

Use:

```text
PrimaryBoundary = SOURCE_REFERENCE
DependsOn = W1-I07
```

The forbidden set includes alias retarget, cross-revision silent replacement and automatic
ambiguity resolution.

- [ ] **Step 3: Create I09 with command HTTP ownership**

Use:

```text
PrimaryBoundary = SOURCE_HTTP_COMMAND
DependsOn = W1-I07
```

The card covers upload and processing commands only; preview queries and Web projection are
forbidden.

- [ ] **Step 4: Verify the three boundaries are distinct**

Run:

```bash
for pair in \
  'W1-I07-revision-attempt-fencing-publication.md|SOURCE_APPLICATION' \
  'W1-I08-stable-reference-reparse-lineage.md|SOURCE_REFERENCE' \
  'W1-I09-upload-processing-command-api.md|SOURCE_HTTP_COMMAND'; do
  file="${pair%%|*}"
  boundary="${pair#*|}"
  test "$(grep -c "^PrimaryBoundary = ${boundary}$" \
    "docs/task-cards/wave-1-implementation/${file}")" -eq 1
done
```

Expected: exit code `0`.

- [ ] **Step 5: Commit**

```bash
git add docs/task-cards/wave-1-implementation/W1-I0{7,8,9}-*.md
git commit -m "docs: bootstrap Wave 1 publication and API cards"
```

### Task 4: Bootstrap query, Web and fixed-review card documents

**Files:**
- Create: `docs/task-cards/wave-1-implementation/W1-I10-source-preview-query-api.md`
- Create: `docs/task-cards/wave-1-implementation/W1-I11-partial-acceptance-command-api.md`
- Create: `docs/task-cards/wave-1-implementation/W1-I12-desktop-web-source-preview.md`
- Create: `docs/task-cards/wave-1-implementation/W1-I13-fixed-implementation-review.md`

**Interfaces:**
- Consumes: D04 API/preview contract and current Repository reviewer routing.
- Produces: final query, user-decision, Web projection and fixed-candidate Gate cards.

- [ ] **Step 1: Create I10 and I11 as separate HTTP cards**

Use:

```text
W1-I10 PrimaryBoundary = SOURCE_HTTP_QUERY
W1-I10 DependsOn = W1-I08,W1-I09
W1-I11 PrimaryBoundary = SOURCE_HTTP_COMMAND
W1-I11 DependsOn = W1-I10
```

I10 owns exact-revision keyset preview. I11 owns exact digest-bound partial acceptance. Neither
card may modify Web files.

- [ ] **Step 2: Create I12 as the only Web card**

Use:

```text
PrimaryBoundary = WEB_DOCUMENT_INGESTION
DependsOn = W1-I10,W1-I11
```

Its Gate covers upload, processing, incomplete markers and partial-confirmation projection,
without Renderer or summary generation.

- [ ] **Step 3: Create I13 as a review-only card**

Use:

```text
CardKind = FIXED_CANDIDATE_REVIEW
PrimaryBoundary = WAVE1_IMPLEMENTATION_GATE
DependsOn = W1-I00,W1-I01,W1-I02,W1-I03,W1-I04,W1-I05,W1-I06,W1-I07,W1-I08,W1-I09,W1-I10,W1-I11,W1-I12
ReviewRoute = DEEP_REVIEWER_THEN_ULTRA_GATEKEEPER
```

I13's write set is limited to acceptance and status records. It must state that findings return
to the owning implementation card and no fix is allowed inside I13.

- [ ] **Step 4: Verify I13's dependency closure**

Run:

```bash
expected='W1-I00,W1-I01,W1-I02,W1-I03,W1-I04,W1-I05,W1-I06,W1-I07,W1-I08,W1-I09,W1-I10,W1-I11,W1-I12'
actual="$(sed -n 's/^DependsOn = //p' \
  docs/task-cards/wave-1-implementation/W1-I13-fixed-implementation-review.md)"
test "$actual" = "$expected"
```

Expected: exit code `0`.

- [ ] **Step 5: Commit**

```bash
git add docs/task-cards/wave-1-implementation/W1-I{10,11,12,13}-*.md
git commit -m "docs: bootstrap Wave 1 preview and review cards"
```

### Task 5: Publish the bootstrap index and make I00 the sole READY card

**Files:**
- Create: `docs/task-cards/wave-1-implementation/README.md`
- Modify: `AGENTS.md`
- Modify: `README.md`
- Modify: `docs/design/wave-1/README.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/engineering/cognitura-wave-1-design-plan.md`
- Modify: `docs/engineering/cognitura-wave-1-design-acceptance.md`
- Modify: `docs/task-cards/wave-1/README.md`
- Modify: `docs/superpowers/specs/2026-07-30-wave1-implementation-slicing-design.md`

**Interfaces:**
- Consumes: all 14 card documents.
- Produces: one canonical bootstrap state with only W1-I00 READY.

- [ ] **Step 1: Create the implementation card index**

The index header must be:

```text
CanonicalProjectName = Cognitura
TaskCardSet = WAVE1_IMPLEMENTATION
TaskCardIDs = W1-I00,W1-I01,W1-I02,W1-I03,W1-I04,W1-I05,W1-I06,W1-I07,W1-I08,W1-I09,W1-I10,W1-I11,W1-I12,W1-I13
TaskCardCount = 14
ActiveTaskCard = W1-I00
TaskCardSetStatus = READY_FOR_EXECUTION
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The table must list all 14 cards, their exact statuses, dependencies, Gate and risk.

- [ ] **Step 2: Synchronize dynamic status projections**

Use:

```text
CurrentStage = WAVE1_IMPLEMENTATION_GOVERNANCE_READY
ActiveTaskCard = W1-I00
ActiveTaskCardStatus = READY
Wave1ImplementationPlanningStatus = TASK_CARD_SET_BOOTSTRAPPED
Wave1ImplementationTaskCardSet = READY_FOR_EXECUTION
BusinessImplementation = NOT_AUTHORIZED
```

Do not change the fixed design candidate or historical W1-DG0 through W1-DG5 results.

- [ ] **Step 3: Run bootstrap structure checks**

Run:

```bash
test "$(find docs/task-cards/wave-1-implementation -maxdepth 1 \
  -name 'W1-I*.md' | wc -l | tr -d ' ')" = 14
test "$(rg -l '^Status = READY$' \
  docs/task-cards/wave-1-implementation/W1-I*.md | wc -l | tr -d ' ')" = 1
rg -n '^Status = READY$' \
  docs/task-cards/wave-1-implementation/W1-I00-implementation-governance.md
```

Expected: 14 cards and only I00 READY.

- [ ] **Step 4: Run existing design and link regressions**

Run:

```bash
scripts/verify-wave1-design
git diff --check
git status --short
```

Expected: Wave 1 design PASS; status contains only bootstrap write set and `.idea/`.

- [ ] **Step 5: Commit**

```bash
git add AGENTS.md README.md docs/design/wave-1/README.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-wave-1-design-plan.md \
  docs/engineering/cognitura-wave-1-design-acceptance.md \
  docs/task-cards/wave-1/README.md \
  docs/task-cards/wave-1-implementation/README.md \
  docs/superpowers/specs/2026-07-30-wave1-implementation-slicing-design.md
git commit -m "docs: release Wave 1 implementation governance card"
```

### Task 6: Start I00 with a failing implementation-card contract test

**Files:**
- Create: `tests/task-cards/verify-wave1-implementation-cards.sh`
- Create: `scripts/verify-wave1-implementation-cards`

**Interfaces:**
- Consumes: canonical implementation card set.
- Produces: executable card validator contract with observable mutation failures.

- [ ] **Step 1: Write the failing positive contract**

The test script must resolve the repository root and run:

```bash
validation_output="$(
  "${repo_root}/scripts/verify-wave1-implementation-cards" \
    --cards-dir "${repo_root}/docs/task-cards/wave-1-implementation"
)"
assert_contains "${validation_output}" "Wave1ImplementationTaskCardValidation = PASS"
assert_contains "${validation_output}" "TaskCardCount = 14"
assert_contains "${validation_output}" "TaskCardSetStatus = READY_FOR_EXECUTION"
assert_contains "${validation_output}" "ActiveTaskCard = W1-I00"
```

- [ ] **Step 2: Run the test to verify RED**

Run:

```bash
bash tests/task-cards/verify-wave1-implementation-cards.sh
```

Expected: FAIL because `scripts/verify-wave1-implementation-cards` is missing or has no
implementation.

- [ ] **Step 3: Add the minimal validator CLI and field parser**

Implement Bash 3.2-compatible:

```bash
usage() {
  echo "Usage: scripts/verify-wave1-implementation-cards --cards-dir PATH" >&2
}

fail() {
  echo "Wave1ImplementationTaskCardValidation = FAIL" >&2
  echo "$1" >&2
  exit 1
}

field_value() {
  local file="$1"
  local key="$2"
  sed -n "s/^${key} = //p" "${file}"
}
```

Parse only `--cards-dir`, reject missing/unknown arguments, and require the index and 14 exact
card filenames.

- [ ] **Step 4: Run the test to verify GREEN**

Run:

```bash
bash tests/task-cards/verify-wave1-implementation-cards.sh
```

Expected: PASS with `TaskCardCount = 14`.

- [ ] **Step 5: Commit**

```bash
git add scripts/verify-wave1-implementation-cards \
  tests/task-cards/verify-wave1-implementation-cards.sh
git commit -m "test: add Wave 1 implementation card contract"
```

### Task 7: Enforce card size, dependency and authorization mutations

**Files:**
- Modify: `scripts/verify-wave1-implementation-cards`
- Modify: `tests/task-cards/verify-wave1-implementation-cards.sh`

**Interfaces:**
- Consumes: canonical card metadata.
- Produces: deterministic rejection messages for invalid size, authorization and dependency states.

- [ ] **Step 1: Add mutation helpers and failing cases**

Copy the canonical set into `mktemp -d` fixtures and require these exact failures:

```text
second READY -> task card set must have exactly one READY card
I00 business write -> W1-I00 governance card contains forbidden runtime write
I01 READY without approval -> W1-I01 requires explicit business implementation authorization
I02 READY without DB Gate -> W1-I02 requires DatabaseGate PASS before READY
ProductionFileLimit 9 without exception -> ProductionFileLimit exceeds 8 without atomic exception
two PrimaryBoundary fields -> PrimaryBoundary must occur exactly once
I13 missing I12 dependency -> W1-I13 must depend on W1-I00 through W1-I12
wrong I13 route -> W1-I13 must use DEEP_REVIEWER_THEN_ULTRA_GATEKEEPER
```

- [ ] **Step 2: Add the valid blocked authorization terminal fixture**

Create an isolated copy with:

```text
W1-I00 Status = DONE
W1-I01 Status = BLOCKED_BY_USER_AUTHORIZATION
ActiveTaskCard = NONE
TaskCardSetStatus = BLOCKED_BY_USER_AUTHORIZATION
BusinessImplementation = NOT_AUTHORIZED
```

Require this fixture to pass. This is the terminal state produced when I00 closes.

- [ ] **Step 3: Run the tests to verify RED**

Run:

```bash
bash tests/task-cards/verify-wave1-implementation-cards.sh
```

Expected: FAIL because one or more invalid fixtures are accepted.

- [ ] **Step 4: Implement the metadata and state rules**

Require:

```text
CardKind
Status
Gate
Risk
DependsOn
PrimaryBoundary
ProductionFileLimit
ProductionWriteSetException
BusinessImplementationAuthorization
FormalDatabaseGate
RemotePush
```

Validate the declared dependency DAG, completed-card dependency closure, one READY, index/filename
identity, seven sections, `ProductionFileLimit`, I00/I01/I02 special Gates and I13 closure/route.
Accept `BLOCKED_BY_USER_AUTHORIZATION` only when there is no READY card, I00 is DONE, I01 is
blocked by user authorization and the index uses `ActiveTaskCard = NONE`.

- [ ] **Step 5: Run the contract tests to verify GREEN**

Run:

```bash
bash tests/task-cards/verify-wave1-implementation-cards.sh
```

Expected: PASS with `NegativeCases = 8` and `BlockedAuthorizationTerminalCases = 1`.

- [ ] **Step 6: Commit**

```bash
git add scripts/verify-wave1-implementation-cards \
  tests/task-cards/verify-wave1-implementation-cards.sh
git commit -m "feat: enforce Wave 1 implementation card boundaries"
```

### Task 8: Add the unified implementation verification entrypoint

**Files:**
- Create: `scripts/verify-wave1-implementation`
- Create: `docs/engineering/cognitura-wave-1-implementation-plan.md`
- Modify: `README.md`
- Modify: `docs/engineering/cognitura-design-index.md`

**Interfaces:**
- Consumes: design verification and implementation card verification.
- Produces: one safe entrypoint that grows only when later implementation cards add tests.

- [ ] **Step 1: Create the unified script**

Use:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"${repo_root}/scripts/verify-wave1-design"
bash "${repo_root}/tests/task-cards/verify-wave1-implementation-cards.sh"
"${repo_root}/scripts/verify-wave1-implementation-cards" \
  --cards-dir "${repo_root}/docs/task-cards/wave-1-implementation"

echo "Wave1ImplementationVerification = PASS"
```

Do not add database, Parser, API or Web tests before their owning cards exist.

- [ ] **Step 2: Create the engineering implementation plan projection**

Record the 14-card table, dependency graph, current active card, authorization Gates and unified
verification command. It must state that the implementation plan is an execution projection and
does not override the approved design contracts.

- [ ] **Step 3: Run the unified entrypoint**

Run:

```bash
scripts/verify-wave1-implementation
```

Expected:

```text
Wave1DesignVerification = PASS
Wave1ImplementationTaskCardContractTests = PASS
Wave1ImplementationTaskCardValidation = PASS
Wave1ImplementationVerification = PASS
```

- [ ] **Step 4: Run shell syntax and diff checks**

Run:

```bash
bash -n scripts/verify-wave1-implementation \
  scripts/verify-wave1-implementation-cards \
  tests/task-cards/verify-wave1-implementation-cards.sh
git diff --check
```

Expected: exit code `0`.

- [ ] **Step 5: Commit**

```bash
git add scripts/verify-wave1-implementation \
  docs/engineering/cognitura-wave-1-implementation-plan.md \
  README.md docs/engineering/cognitura-design-index.md
git commit -m "build: add Wave 1 implementation verification entrypoint"
```

### Task 9: Review and close I00 without releasing business implementation

**Files:**
- Modify: `docs/task-cards/wave-1-implementation/W1-I00-implementation-governance.md`
- Modify: `docs/task-cards/wave-1-implementation/README.md`
- Modify: `docs/engineering/cognitura-wave-1-implementation-plan.md`
- Modify: `AGENTS.md`
- Modify: `README.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/engineering/cognitura-wave-1-design-plan.md`
- Modify: `docs/engineering/cognitura-wave-1-design-acceptance.md`
- Modify: `docs/design/wave-1/README.md`
- Modify: `docs/task-cards/wave-1/README.md`

**Interfaces:**
- Consumes: fixed I00 governance candidate and all passing verification.
- Produces: I00 DONE, no READY card, and an explicit user-authorization block before I01.

- [ ] **Step 1: Run all applicable verification**

Run:

```bash
scripts/verify-wave1-implementation
npm exec --yes --package=node@24.18.0 -- sh -c 'scripts/verify-wave0'
git diff --check
git status --short
```

Expected: all Wave 0, Wave 1 design and implementation-governance stages PASS; only `.idea/`
remains outside the candidate.

- [ ] **Step 2: Create a fixed local candidate**

```bash
git add scripts/verify-wave1-implementation* \
  tests/task-cards/verify-wave1-implementation-cards.sh \
  docs/task-cards/wave-1-implementation \
  docs/engineering/cognitura-wave-1-implementation-plan.md \
  AGENTS.md README.md docs/design/wave-1/README.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-wave-1-design-plan.md \
  docs/engineering/cognitura-wave-1-design-acceptance.md \
  docs/task-cards/wave-1/README.md
git diff --cached --check
git commit -m "docs: fix Wave 1 implementation governance candidate"
```

Capture the complete 40-character SHA.

- [ ] **Step 3: Run a fixed-commit general review**

Dispatch `deep_reviewer` read-only against the exact SHA. Require:

```text
candidate_sha="$(git rev-parse HEAD)"
ReviewedCandidate = ${candidate_sha}
GeneralReviewVerdict = READY
P0 = 0
P1 = 0
P2 = 0
```

Any finding returns to its owning task and creates a new candidate. Do not start an
`ultra_gatekeeper`; I00 is not the final Wave 1 implementation GO/NO-GO candidate.

- [ ] **Step 4: Close I00 and block at user authorization**

Set:

```text
W1-I00 Status = DONE
W1-I01 Status = BLOCKED_BY_USER_AUTHORIZATION
ActiveTaskCard = NONE
TaskCardSetStatus = BLOCKED_BY_USER_AUTHORIZATION
CurrentStage = WAVE1_IMPLEMENTATION_AWAITING_BUSINESS_AUTHORIZATION
Wave1ImplementationTaskCardSet = BLOCKED_BY_USER_AUTHORIZATION
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

Record the review evidence without changing historical design Gate evidence.

- [ ] **Step 5: Verify the blocked terminal state and commit locally**

Run:

```bash
scripts/verify-wave1-implementation
git diff --check
git status --short
git rev-list --left-right --count origin/main...HEAD
```

Expected: validator accepts the blocked state, no READY cards exist, only `.idea/` is untracked,
and the branch remains ahead of `origin/main` with no push.

Commit:

```bash
git add AGENTS.md README.md docs/design/wave-1/README.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-wave-1-design-plan.md \
  docs/engineering/cognitura-wave-1-design-acceptance.md \
  docs/engineering/cognitura-wave-1-implementation-plan.md \
  docs/task-cards/wave-1/README.md \
  docs/task-cards/wave-1-implementation/README.md \
  docs/task-cards/wave-1-implementation/W1-I00-implementation-governance.md \
  docs/task-cards/wave-1-implementation/W1-I01-source-ingestion-domain.md
git commit -m "docs: close Wave 1 implementation governance gate"
```

Stop. Do not mark I01 READY and do not write business code.

## Plan Completion Gate

The plan is complete only when:

```text
ImplementationTaskCardCount = 14
W1-I00 = DONE
W1-I01 = BLOCKED_BY_USER_AUTHORIZATION
ActiveTaskCard = NONE
TaskCardSetStatus = BLOCKED_BY_USER_AUTHORIZATION
Wave1DesignVerification = PASS
Wave1ImplementationVerification = PASS
Wave0Verification = PASS
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The next action after this plan is a user decision on W1-I01 business implementation
authorization. Formal database authorization remains a separate later Gate before W1-I02.
