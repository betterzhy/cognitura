# Cognitura W0-04 JSON Schema Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the 13 instantiable Cognitura JSON Schemas, their local catalog and evidence map, plus reproducible structural and semantic contract verification for W0-G3.

**Architecture:** JSON Schema Draft 2020-12 files live under `schemas/` and use stable URN identifiers resolved only through `schemas/catalog.json`. A self-contained Node 24 test toolchain under `tests/contracts/schema/` pins Ajv and runs both schema validation and cross-object semantic checks; `scripts/verify-json-schemas` is the repository entrypoint. All implementation is a direct projection of `Cognitura-Schema-Baseline-2.0`.

**Tech Stack:** JSON Schema Draft 2020-12, Node.js 24.18.0, pnpm 11.17.0, Ajv 8.20.0, ECMAScript modules, Bash.

---

## File map

| Path | Responsibility |
|---|---|
| `schemas/catalog.json` | Unique mapping from 14 Schema URNs (13 instantiable plus common definitions) to local files and versions |
| `schemas/evidence-map.json` | Per-Schema and per-JSON-Pointer source mapping for fields, required sets, enums, cardinalities, conditionals and semantic rules |
| `schemas/cognition/common.schema.json` | Shared scalar types, enums and strict shared objects |
| `schemas/cognition/knowledge-skeleton.schema.json` | Landscape-level skeleton and Published density rules |
| `schemas/cognition/knowledge-theme.schema.json` | Theme, module candidates, parent identity and Published density rules |
| `schemas/cognition/cognitive-module.schema.json` | Module, nested spine/elements/assessment and Published closure rules |
| `schemas/cognition/primary-cognitive-spine.schema.json` | Four-to-nine ordered spine steps |
| `schemas/cognition/knowledge-element.schema.json` | Element content, provenance and Module relation references |
| `schemas/cognition/theme-closure.schema.json` | Theme convergence artifact |
| `schemas/cognition/landscape-closure.schema.json` | Landscape convergence artifact |
| `schemas/cognition/evidence-reference.schema.json` | Source location, synthesis disclosure and conflict state |
| `schemas/cognition/structure-ambiguity.schema.json` | One local structural ambiguity and its alternatives |
| `schemas/cognition/quality-assessment.schema.json` | Seven dimensions and hard-failure codes |
| `schemas/generation/generation-stage-record.schema.json` | Stage snapshot, output, validation, failure and retry lifecycle |
| `schemas/ui/renderer-input.schema.json` | Projection of exactly one validated CognitiveModule |
| `schemas/ui/page-state.schema.json` | Pure string page-state enum |
| `tests/contracts/schema/package.json` | Exact Node/pnpm/Ajv test dependency contract |
| `tests/contracts/schema/pnpm-lock.yaml` | Frozen dependency graph |
| `tests/contracts/schema/.gitignore` | Excludes generated `node_modules/` |
| `tests/contracts/schema/verify-json-schemas.mjs` | Meta-schema, catalog, local-ref, instance, evidence-map and semantic validator |
| `tests/contracts/schema/verify-json-schemas.sh` | Positive/negative test harness and stable output assertions |
| `tests/task-cards/verify-task-cards.sh` | Authorized lifecycle-test repair that resolves the current active card dynamically |
| `tests/contracts/schema/fixtures/valid/*.json` | One complete valid instance for each instantiable Schema |
| `tests/contracts/schema/fixtures/invalid/*.json` | Explicit invalid instances for high-risk structural rules |
| `tests/contracts/schema/fixtures/semantic/*.json` | Valid and invalid cross-object revision contexts |
| `scripts/verify-json-schemas` | Stable repository command that enforces Node 24.18.0 and invokes the pinned verifier |

The original W0-04 implementation is fixed at `eb55ca5`. Deep review found
semantic false positives, so this remediation must be a separate follow-up
commit; it must not amend or rewrite the original commit. The first remediation
at `8cfd056` closed those findings but its fixed-commit review found two further
P1 gaps in COMPLETE coverage union and evidence-map completeness; this second
follow-up closed those gaps at `c15a005`. Its review found one P2 in truncated
full-map rendering; the final follow-up adds a pipe-backed round-trip regression
without rewriting any predecessor. Review of `e79e69c` confirmed the render fix
but rejected an undeclared `jq` dependency in the regression; the current
candidate uses only the already pinned Node runtime for parse and byte checks.

### Task 1: Establish the red contract harness and pinned validator

**Files:**
- Create: `tests/contracts/schema/package.json`
- Create: `tests/contracts/schema/.gitignore`
- Create: `tests/contracts/schema/verify-json-schemas.sh`
- Create: `tests/contracts/schema/verify-json-schemas.mjs`
- Create: `scripts/verify-json-schemas`

- [x] **Step 1: Write the failing shell harness**

The harness must resolve the repository root, require the executable repository verifier, run it, and assert these output lines:

```text
JsonSchemaValidation = PASS
SchemaDocumentCount = 14
InstantiableSchemaCount = 13
ValidFixtureCount = 13
InvalidFixtureCount = 18
SemanticValidContextCount = 2
NonPublishedModuleNullability = PASS
SemanticNegativeCaseCount = 34
SemanticViolationCodeCount = 68
EvidenceMapSchemaEntryCount = 645
EvidenceMapSemanticEntryCount = 16
EvidenceMapEntryCount = 661
EvidenceMapNegativeCaseCount = 6
EvidenceMapValidation = PASS
EvidenceMapRenderRoundTrip = PASS
NetworkResolution = FORBIDDEN
W0-G3 JsonSchemaValidation = PASS
```

- [x] **Step 2: Run the harness and verify red**

Run:

```bash
bash tests/contracts/schema/verify-json-schemas.sh
```

Expected: non-zero with `FAIL: schema verifier is missing or not executable`.

- [x] **Step 3: Add the exact test package**

`tests/contracts/schema/package.json` must be:

```json
{
  "name": "@cognitura/schema-contract-tests",
  "version": "2.0.0",
  "private": true,
  "type": "module",
  "packageManager": "pnpm@11.17.0",
  "engines": {
    "node": "24.18.0",
    "pnpm": "11.17.0"
  },
  "devDependencies": {
    "ajv": "8.20.0"
  }
}
```

`tests/contracts/schema/.gitignore` must contain:

```gitignore
/node_modules/
```

- [x] **Step 4: Generate and freeze the lockfile**

Run from `tests/contracts/schema/` with Node 24.18.0:

```bash
corepack pnpm install --lockfile-only
corepack pnpm install --frozen-lockfile
```

Expected: `pnpm-lock.yaml` records Ajv 8.20.0 and installation succeeds without changing `web/`.

- [x] **Step 5: Add the repository wrapper**

`scripts/verify-json-schemas` must:

1. use `set -euo pipefail`;
2. resolve the repository root physically;
3. reject any Node version other than `v24.18.0`;
4. reject any pnpm version other than `11.17.0`;
5. require the frozen lockfile and installed Ajv;
6. execute `node tests/contracts/schema/verify-json-schemas.mjs`.

- [x] **Step 6: Add the verifier entrypoint**

The module must import:

```js
import Ajv2020 from "ajv/dist/2020.js";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
```

It must exit through stable error classes:

```text
SCHEMA_PARSE_ERROR
META_SCHEMA_INVALID
UNRESOLVED_LOCAL_REF
NETWORK_RESOLUTION_FORBIDDEN
INSTANCE_CONTRACT_VIOLATION
SEMANTIC_REFERENCE_VIOLATION
EVIDENCE_MAPPING_MISSING
STAGE_EXECUTION_FAILED
```

- [x] **Step 7: Run the harness and verify the next red boundary**

Expected: non-zero `SCHEMA_PARSE_ERROR` naming the missing `schemas/catalog.json`.

### Task 2: Add common definitions, catalog and evidence-map contract

**Files:**
- Create: `schemas/cognition/common.schema.json`
- Create: `schemas/catalog.json`
- Create: `schemas/evidence-map.json`
- Modify: `tests/contracts/schema/verify-json-schemas.mjs`

- [x] **Step 1: Register the exact URNs**

Catalog version is `2.0.0`. It must map:

```text
urn:cognitura:schema:cognition:common:2.0.0
urn:cognitura:schema:cognition:knowledge-skeleton:2.0.0
urn:cognitura:schema:cognition:knowledge-theme:2.0.0
urn:cognitura:schema:cognition:cognitive-module:2.0.0
urn:cognitura:schema:cognition:primary-cognitive-spine:2.0.0
urn:cognitura:schema:cognition:knowledge-element:2.0.0
urn:cognitura:schema:cognition:theme-closure:2.0.0
urn:cognitura:schema:cognition:landscape-closure:2.0.0
urn:cognitura:schema:cognition:evidence-reference:2.0.0
urn:cognitura:schema:cognition:structure-ambiguity:2.0.0
urn:cognitura:schema:cognition:quality-assessment:2.0.0
urn:cognitura:schema:generation:generation-stage-record:2.0.0
urn:cognitura:schema:ui:renderer-input:2.0.0
urn:cognitura:schema:ui:page-state:2.0.0
```

Only `common` is non-instantiable.

- [x] **Step 2: Implement the shared definitions**

`common.schema.json` must define these strict `$defs`:

```text
schemaVersion, artifactId, revisionId, artifactRef, nonBlankText, sha256,
publicationState, knowledgeRole, relationType, knowledgeElementType,
sourceKind, assessmentStatus, conflictState, riskLevel,
relation, sourceCoverage, gap, criticalBoundary, evidenceStatement,
conflictResolutionDecision, orderedArtifactStep, assessmentFinding,
assessmentDimension
```

All object definitions use `additionalProperties: false`. `sourceCoverage`,
`relation`, `evidenceStatement` and `conflictResolutionDecision` encode the
conditional rules from baseline §5.3.

- [x] **Step 3: Define evidence-map shape**

The top-level object must contain:

```json
{
  "baseline": "Cognitura-Schema-Baseline-2.0",
  "baselineSha256": "d7f2a83ea2c0252478341d5e2cb37df1ee38798d1b7b4b5a8f96f9b3ef0cc1d4",
  "entries": []
}
```

Every entry contains exact `schemaId`, RFC 6901 `schemaPointer`,
`constraintKinds`, `evidenceKind`, `source` and nonblank `reason`.
`evidenceKind` is `OVERALL_DESIGN_EVIDENCE` or `REBASELINE_DECISION`.

- [x] **Step 4: Implement evidence coverage walking**

The verifier must walk `properties`, `required`, `enum`, `const`,
`minItems`, `maxItems`, `minLength`, `pattern`, `if`, `then`, `else`,
`allOf`, `anyOf`, `oneOf` and `not`. Every encountered constraint pointer
must have a matching evidence-map entry for that Schema ID.

The expected map is generated from the same exact-pointer policy used by the
validator. To render the deterministic document for review or regeneration:

```bash
node tests/contracts/schema/verify-json-schemas.mjs --render-evidence-map
```

- [x] **Step 5: Run and verify red**

Expected: catalog validation fails with the first missing instantiable Schema file.

### Task 3: Implement the hierarchy and module schemas

**Files:**
- Create: `schemas/cognition/knowledge-skeleton.schema.json`
- Create: `schemas/cognition/knowledge-theme.schema.json`
- Create: `schemas/cognition/cognitive-module.schema.json`
- Create: `schemas/cognition/primary-cognitive-spine.schema.json`
- Create: `schemas/cognition/knowledge-element.schema.json`
- Create: `tests/contracts/schema/fixtures/valid/knowledge-skeleton.json`
- Create: `tests/contracts/schema/fixtures/valid/knowledge-theme.json`
- Create: `tests/contracts/schema/fixtures/valid/cognitive-module.json`
- Create: `tests/contracts/schema/fixtures/valid/primary-cognitive-spine.json`
- Create: `tests/contracts/schema/fixtures/valid/knowledge-element.json`

- [x] **Step 1: Write five valid fixtures and structural mutations**

Fixtures must use `schemaVersion: "2.0.0"`, reject unknown properties and
include all required fields. The verifier programmatically creates the first
fifteen named invalid cases below; Task 5 adds three file-backed invalid cases.
Together they define the fixed `InvalidFixtureCount = 18` contract:

```text
knowledge-skeleton-missing-required
knowledge-theme-missing-required
cognitive-module-missing-required
cognitive-module-invalid-relation-type
cognitive-module-published-density
cognitive-module-published-spine
cognitive-module-published-source-refs
primary-cognitive-spine-missing-required
primary-cognitive-spine-order-type
knowledge-element-invalid-element-type
theme-closure-missing-required
landscape-closure-missing-required
evidence-reference-conflict-condition
structure-ambiguity-missing-required
quality-assessment-published-failure
generation-succeeded-not-pass
renderer-unknown-hint
page-state-invalid
```

- [x] **Step 2: Run and verify red**

Expected: fixtures fail because their Schema files are missing.

- [x] **Step 3: Implement KnowledgeSkeleton**

Required fields:

```text
schemaVersion artifactId revisionId publicationState landscapeThesis themes
coreThemeRefs relations understandingRoute structureAmbiguityRefs
sourceCoverage gaps
```

Published `coreThemeRefs` is 3–9; `relations` is at most 12; no deep Module
body is accepted because Theme entries use only the KnowledgeTheme contract.

- [x] **Step 4: Implement KnowledgeTheme**

Required fields:

```text
schemaVersion artifactId revisionId publicationState title coreQuestions role
primaryParent moduleCandidates coreModuleRefs relations sourceCoverage gaps
```

`coreQuestions` is 1–3. Module candidates are strict and require
`moduleId`, `title`, `coreQuestions`, `role`, `primaryParent`,
`candidateSpine`, `sourceCoverage`, `gaps`. Published `coreModuleRefs` is 2–7.

- [x] **Step 5: Implement PrimaryCognitiveSpine and KnowledgeElement**

Spine steps are strict, ordered semantically and 4–9 structurally.
KnowledgeElement requires content, provenance and an array of at most five
Relation artifact references.

- [x] **Step 6: Implement CognitiveModule**

Required fields:

```text
schemaVersion artifactId revisionId publicationState primaryParent title thesis
role coreQuestions primaryCognitiveSpine facets knowledgeElements keyTakeaways
criticalBoundaries relations sourceRefs gaps qualityAssessment
```

Published Module requires nonblank thesis, non-null spine, 1–5 boundaries,
1–5 relations, nonempty sources, 3–7 takeaways and a non-null assessment with
no `FAIL` dimension or hard failure.

- [x] **Step 7: Run structural fixtures**

Expected: all five valid fixtures pass; mutations for missing required,
unknown field, invalid enum, wrong type and Published density fail with
`INSTANCE_CONTRACT_VIOLATION`.

### Task 4: Implement closure, evidence, ambiguity and assessment schemas

**Files:**
- Create: `schemas/cognition/theme-closure.schema.json`
- Create: `schemas/cognition/landscape-closure.schema.json`
- Create: `schemas/cognition/evidence-reference.schema.json`
- Create: `schemas/cognition/structure-ambiguity.schema.json`
- Create: `schemas/cognition/quality-assessment.schema.json`
- Create: `tests/contracts/schema/fixtures/valid/theme-closure.json`
- Create: `tests/contracts/schema/fixtures/valid/landscape-closure.json`
- Create: `tests/contracts/schema/fixtures/valid/evidence-reference.json`
- Create: `tests/contracts/schema/fixtures/valid/structure-ambiguity.json`
- Create: `tests/contracts/schema/fixtures/valid/quality-assessment.json`

- [x] **Step 1: Add the five complete valid fixtures**

Every fixture carries the formal artifact identity fields and all artifact
specific required fields.

- [x] **Step 2: Run and verify red**

Expected: missing Schema files are reported in catalog order.

- [x] **Step 3: Implement ThemeClosure**

Use strict `moduleCooperation`, `themeSpine`, `criticalDistinctions`,
`boundaries`, `relatedThemes`, `sourceCoverage` and `gaps`. Published closure
requires nonblank thesis and nonempty cooperation, spine, distinctions and
boundaries.

- [x] **Step 4: Implement LandscapeClosure**

Use strict `coreThemes`, `crossThemeSpine`, `keyDependencies`,
`globalBoundaries`, `understandingRoute`, `sourceCoverage` and `gaps`.
Published `coreThemes` is 3–9 and all convergence collections are nonempty.

- [x] **Step 5: Implement EvidenceReference**

Encode page/source-order fallback, block-type enum, synthesis disclosure and:

```text
NONE -> conflictGroupId null, resolutionDecision null
UNRESOLVED -> conflictGroupId non-null, resolutionDecision null
RESOLVED_BY_USER -> conflictGroupId non-null, decidedBy USER decision non-null
```

- [x] **Step 6: Implement StructureAmbiguity**

One strict local ambiguity requires a location, one recommendation, at least
one strict alternative, rationale, at least one closure impact, and either
source or gap evidence.

- [x] **Step 7: Implement QualityAssessment**

All seven strict dimensions are required. `hardFailures` is a unique array
limited to the nine baseline codes. Published assessment rejects `FAIL`
dimensions and nonempty hard failures.

- [x] **Step 8: Run structural fixtures**

Expected: ten cognitive valid fixtures pass; key conditional invalid fixtures
fail with `INSTANCE_CONTRACT_VIOLATION`.

### Task 5: Implement generation, Renderer and Page State schemas

**Files:**
- Create: `schemas/generation/generation-stage-record.schema.json`
- Create: `schemas/ui/renderer-input.schema.json`
- Create: `schemas/ui/page-state.schema.json`
- Create: `tests/contracts/schema/fixtures/valid/generation-stage-record.json`
- Create: `tests/contracts/schema/fixtures/valid/renderer-input.json`
- Create: `tests/contracts/schema/fixtures/valid/page-state.json`
- Create: `tests/contracts/schema/fixtures/invalid/generation-succeeded-not-pass.json`
- Create: `tests/contracts/schema/fixtures/invalid/renderer-unknown-hint.json`
- Create: `tests/contracts/schema/fixtures/invalid/page-state-invalid.json`

- [x] **Step 1: Add valid and explicit invalid fixtures**

The Page State fixture is a JSON string, not an object. Generation and
Renderer fixtures use `schemaVersion: "2.0.0"`.

- [x] **Step 2: Run and verify red**

Expected: the first missing generation/UI Schema is reported.

- [x] **Step 3: Implement GenerationStageRecord**

Encode all eleven stages, five generation statuses, three validation statuses
and three output kinds. Enforce output-kind nullability, validation result
conditions, `SUCCEEDED -> PASS`, failure-object conditions and retry count.

- [x] **Step 4: Implement RendererInput**

Require exactly one `moduleRef`, 1–64 strict nodes, 0–16 groups, 0–64
relations, provenance, incomplete state and unique hints. More than twelve
nodes requires nonempty groups. All nodes require RFC 6901 `contentPath`.

- [x] **Step 5: Implement Page State**

The entire Schema is a string enum containing exactly:

```text
EMPTY UPLOADING PARSING ANALYZING GENERATING WAITING_REVIEW
PARTIALLY_GENERATED FAILED RETRYING CONFIRMED PUBLISHED
OUTDATED_BY_STRUCTURE_CHANGE
```

- [x] **Step 6: Run all 13 structural positives and explicit negatives**

Expected: `ValidFixtureCount = 13`; invalid fixtures fail for their expected
contract reason rather than parse or file errors.

### Task 6: Implement cross-object semantic validation

**Files:**
- Modify: `tests/contracts/schema/verify-json-schemas.mjs`
- Create: `tests/contracts/schema/fixtures/semantic/valid-context.json`
- Create: `tests/contracts/schema/fixtures/semantic/dangling-parent.json`
- Create: `tests/contracts/schema/fixtures/semantic/duplicate-spine.json`
- Create: `tests/contracts/schema/fixtures/semantic/element-relation-scope.json`
- Create: `tests/contracts/schema/fixtures/semantic/source-coverage-owner.json`
- Create: `tests/contracts/schema/fixtures/semantic/source-coverage-union.json`
- Create: `tests/contracts/schema/fixtures/semantic/unresolved-conflict-singleton.json`
- Create: `tests/contracts/schema/fixtures/semantic/automatic-conflict-resolution.json`
- Create: `tests/contracts/schema/fixtures/semantic/renderer-cross-module.json`
- Create: `tests/contracts/schema/fixtures/semantic/renderer-content-path.json`
- Create: `tests/contracts/schema/fixtures/semantic/renderer-relation-scope.json`
- Create: `tests/contracts/schema/fixtures/semantic/spine-order-gap.json`
- Create: `tests/contracts/schema/fixtures/semantic/duplicate-successful-run.json`

- [x] **Step 1: Add one valid immutable revision context**

The context must contain one Skeleton with three Themes, one Theme with two
Module candidates, one complete Module with its Spine, Elements, Relations,
sources and assessment, both Closures, EvidenceReferences, one Generation
record and one Renderer Input.

- [x] **Step 2: Add the twelve single-fault contexts**

Each file changes exactly one semantic invariant and declares one expected
`SEMANTIC_REFERENCE_VIOLATION` code.

- [x] **Step 3: Implement local registries**

Index formal artifact IDs plus nested Relation and Gap IDs. Reject duplicate
IDs, dangling refs, wrong target types and more than one revision for the same
artifact ID in one context.

- [x] **Step 4: Implement hierarchy and relation rules**

Validate Skeleton-as-Landscape parent identity, Theme/Module ownership, exactly
one Spine per Module revision, contiguous spine order, Element Relation
membership and at least one endpoint equal to the owning Element.

- [x] **Step 5: Implement provenance and conflict rules**

Validate EvidenceReference target types, SourceCoverage owner support,
closure evidence/gap set equality, conflict group cardinality, user-only
resolution and preservation of every conflict member.

- [x] **Step 6: Implement generation and Renderer rules**

Reject duplicate successful run keys. Renderer nodes must resolve their
`contentPath` inside the one Module, relations must reference that Module's
Relation registry and node/group references must be local.

- [x] **Step 7: Run semantic verification**

Expected: the valid context passes and all twelve single-fault contexts fail
with their declared stable semantic code.

### Task 7: Complete evidence coverage, regression and task-card transition

**Files:**
- Modify: `schemas/evidence-map.json`
- Modify: `tests/contracts/schema/verify-json-schemas.mjs`
- Modify: `tests/contracts/schema/verify-json-schemas.sh`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/engineering/cognitura-specialty-contract-coverage.md`
- Modify: `docs/task-cards/README.md`
- Modify: `docs/task-cards/W0-04-json-schema-source.md`
- Modify: `docs/task-cards/W0-05-golden-case-regression.md`
- Modify: `docs/engineering/cognitura-wave-0-plan.md`
- Modify: `docs/engineering/cognitura-wave-0-entry-decision.md`
- Modify (authorized supplemental write): `tests/task-cards/verify-task-cards.sh`

- [x] **Step 1: Complete the evidence map**

Use overall-design sections for inherited product semantics and exact
`RB-001` through `RB-017` identifiers for rebaseline decisions. The verifier
must report no uncovered field, required set, enum, cardinality, conditional
or semantic rule.

- [x] **Step 2: Run the W0-04 commands**

```bash
scripts/verify-json-schemas
bash tests/contracts/schema/verify-json-schemas.sh
bash tests/task-cards/verify-task-cards.sh
git diff --check
```

Expected: all commands pass and W0-G3 output is `PASS`.

- [x] **Step 3: Run all existing Wave 0 regression gates**

```bash
bash tests/source-manifest/verify-source-manifest.sh
bash tests/contracts/specialty-coverage/verify-specialty-contract-coverage.sh
bash tests/build-baseline/verify-build-baseline.sh
bash tests/contracts/ui/verify-ui-contracts.sh
```

Expected: all existing PASS results remain unchanged and formal source hashes
still match.

- [x] **Step 4: Update lifecycle state**

Set:

```text
W0-04 Status = DONE
W0-G3 JsonSchemaValidation = PASS
W0-05 Status = READY
ActiveTaskCard = W0-05
TaskCardSetStatus = READY_FOR_EXECUTION
Wave1FeatureDevelopmentEntry = NO_GO
```

Update completion evidence with actual fixture counts and the fixed Ajv
version. Do not mark W0-G4, W0-G5 or W0-G6 as PASS.

- [x] **Step 5: Re-run task-card validation after state changes and resolve the active card dynamically**

Expected:

```text
TaskCardValidation = PASS
TaskCardCount = 9
TaskCardSetStatus = READY_FOR_EXECUTION
ActiveTaskCard = W0-05
```

- [x] **Step 6: Commit the fixed-review candidate**

```bash
git add AGENTS.md README.md schemas tests/contracts/schema \
  scripts/verify-json-schemas \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-specialty-contract-coverage.md \
  docs/task-cards/README.md \
  docs/task-cards/W0-04-json-schema-source.md \
  docs/task-cards/W0-05-golden-case-regression.md \
  docs/engineering/cognitura-wave-0-plan.md \
  docs/engineering/cognitura-wave-0-entry-decision.md
git commit -m "fix: keep Cognitura schema verification self-contained"
```

Expected: follow-up W0-04 remediation commits do not amend history or change
`raw/`, server business source, web product code, W0-05 regression assets or CI
implementation. Fixed candidate `72b5ce7` is `GO / P0=0 / P1=0 / P2=0`;
W0-G3 is closed and W0-05 is only released to `READY`.
