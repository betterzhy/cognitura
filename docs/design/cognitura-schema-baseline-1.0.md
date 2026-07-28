# Cognitura Schema Baseline 1.0

```text
DecisionDate = 2026-07-28
CanonicalProjectName = Cognitura
EngineeringReferenceName = Cognitura-Schema-Baseline-1.0
BaselineVersion = 1.0.0
Status = FORMAL_SCHEMA_REBASELINE
AuthorityType = USER_APPROVED_ENGINEERING_REBASELINE
SupersedesOverallDesign = NO
ClaimsHistoricalSpecialtyProvenance = NO
ResolvesExecutionDisposition = DOC-GAP-001
ImplementationGate = W0-G3 JsonSchemaValidation
```

## 1. 目的与权威边界

本基线是在
`Cognitive-Knowledge-System-Construction-Design-1.0`
正文未落地的情况下，经用户明确批准形成的字段级工程裁决。它为十项正式认知
产物、生成阶段记录、Renderer 输入和页面状态提供可执行的类型、必填项、枚举、
条件和关系约束。

权威顺序如下：

```text
Cognitura-Overall-Design-1.2
→ Cognitura-Schema-Baseline-1.0
→ versioned JSON Schema projections
→ runtime storage and rendering projections
```

- 总体设计继续拥有产品语义、范围和不变量的最高权威。
- 本基线补足总体设计明确留给缺失专项正文的字段级细节。
- JSON Schema 是本基线的机器投影，不得反向修改本基线语义。
- 本基线不是历史专项正文的副本、恢复稿或替代命名版本。
- 后续若权威专项正文实际落地，冲突必须形成显式版本化裁决，不得静默覆盖。

本基线不设计数据库表、API DTO、业务服务、Prompt 正文、页面组件或 Wave 1
功能，不引入第二棵个性化知识树。

## 2. 不可变产品约束

以下约束直接来自总体设计，并高于所有字段级裁决：

```text
CanonicalHierarchy =
  KnowledgeLandscape
  → KnowledgeTheme
  → CognitiveModule
  → KnowledgeElement

PrimaryReadingUnit = COGNITIVE_MODULE
CanonicalKnowledgeStructureIsUserIndependent = YES
UserLevelModel = NOT_REQUIRED
KnowledgeCardIsCoreObject = NO
StructureBeforeDeepGeneration = YES
PrimaryCognitiveSpinePerModule = EXACTLY_ONE
PrimaryParentPerThemeOrModule = EXACTLY_ONE
RendererCreatesIndependentFacts = NO
MissingKnowledgeMayBeSilentlyCompleted = NO
```

## 3. 重基线裁决

| 裁决 ID | 裁决 |
|---|---|
| `RB-001` | Schema 方言固定为 JSON Schema Draft 2020-12 |
| `RB-002` | 每项正式产物独立成文件，通过共享定义和本地 `$ref` 组合 |
| `RB-003` | 实例对象默认拒绝未知字段 |
| `RB-004` | 所有正式产物携带 `schemaVersion`、`artifactId`、`revisionId` 和 `publicationState` |
| `RB-005` | Draft 可显式不完整；Published 必须满足发布条件 |
| `RB-006` | Schema `$id` 使用稳定 URN，所有引用只能由本地 Catalog 解析 |
| `RB-007` | 每个字段和关键约束必须有总体设计证据或重基线裁决映射 |
| `RB-008` | JSON Schema 负责结构约束，语义验证器负责跨对象不变量 |
| `RB-009` | Generation Record 保存阶段快照和验证结果，不成为第二个可编辑事实源 |
| `RB-010` | Renderer Input 的每个节点和关系都必须投影正式认知产物 |
| `RB-011` | Page State 与 Generation Status 使用不同 Schema 和枚举 |
| `RB-012` | 破坏兼容性的变更必须升级 major，不得原地漂移 1.0 语义 |
| `RB-013` | 所有校验必须离线运行，禁止通过网络解析 Schema 或来源 |
| `RB-014` | Schema 验证错误与语义错误使用稳定、可断言的错误分类 |

## 4. Schema 包结构

```text
schemas/
├── catalog.json
├── evidence-map.json
├── cognition/
│   ├── common.schema.json
│   ├── knowledge-skeleton.schema.json
│   ├── knowledge-theme.schema.json
│   ├── cognitive-module.schema.json
│   ├── primary-cognitive-spine.schema.json
│   ├── knowledge-element.schema.json
│   ├── theme-closure.schema.json
│   ├── landscape-closure.schema.json
│   ├── evidence-reference.schema.json
│   ├── structure-ambiguity.schema.json
│   └── quality-assessment.schema.json
├── generation/
│   └── generation-stage-record.schema.json
└── ui/
    ├── renderer-input.schema.json
    └── page-state.schema.json
```

正式可实例化 Schema 共 13 个；`common.schema.json` 只提供共享定义，不作为
独立业务实例。

每个文件必须声明：

```text
$schema = https://json-schema.org/draft/2020-12/schema
$id = urn:cognitura:schema:<domain>:<name>:1.0.0
schemaVersion = const 1.0.0
```

`catalog.json` 维护 `$id`、版本和本地文件路径的一一映射。Catalog 中不存在的
Schema 不得成为正式引用目标。

`evidence-map.json` 按 Schema ID 和 JSON Pointer 登记字段与约束来源：

```text
EvidenceKind =
  OVERALL_DESIGN_EVIDENCE
  REBASELINE_DECISION
```

每条证据记录必须包含 Schema ID、JSON Pointer、EvidenceKind、章节或裁决 ID、
约束类型和理由。缺少证据映射的字段、`required`、枚举、数量约束、条件或跨对象
不变量使 `W0-G3` 失败。

## 5. 共享定义

### 5.1 基础值

| 名称 | 类型与约束 | 来源 |
|---|---|---|
| `SchemaVersion` | string，常量 `1.0.0` | `RB-004` |
| `ArtifactId` | string，长度 1–128，模式 `^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$` | `RB-004` |
| `RevisionId` | 与 `ArtifactId` 相同约束 | 总体设计 §18、`RB-004` |
| `ArtifactRef` | 与 `ArtifactId` 相同约束 | `RB-008` |
| `NonBlankText` | string，`minLength = 1` | `RB-003` |
| `Sha256` | string，模式 `^[a-f0-9]{64}$` | 总体设计 §17、`RB-009` |

### 5.2 正式枚举

```text
PublicationState =
  DRAFT
  CONFIRMED
  PUBLISHED

KnowledgeRole =
  FOUNDATION
  CORE
  BRIDGE
  APPLICATION
  EXTENSION

RelationType =
  DEPENDS_ON
  EXPLAINS
  CONTRASTS_WITH
  APPLIES_TO
  IMPACTS

KnowledgeElementType =
  CONCEPT
  RULE
  MECHANISM
  STEP
  DISTINCTION
  BOUNDARY
  EXAMPLE
  PRACTICE

SourceKind =
  SOURCE_EXPLICIT
  SOURCE_SYNTHESIZED

AssessmentStatus =
  PASS
  WARN
  FAIL
```

`PublicationState`、`KnowledgeRole`、`RelationType` 和
`KnowledgeElementType` 来自总体设计 §5–7、§12、§18；
`SourceKind` 来自总体设计 §20.9；`AssessmentStatus` 是 `RB-005` 下的发布
质量工程裁决。

### 5.3 共享对象

`Relation`：

| 字段 | 类型 | 必填 | 约束 |
|---|---|---|---|
| `relationId` | `ArtifactId` | YES | 当前关系集合内唯一 |
| `type` | `RelationType` | YES | 不允许 `RELATED_TO` |
| `sourceRef` | `ArtifactRef` | YES | 必须可解析 |
| `targetRef` | `ArtifactRef` | YES | 必须可解析且不得等于 `sourceRef` |
| `origin` | `SourceKind` | YES | 综合关系必须显式标记 |
| `riskLevel` | enum | YES | `LOW/MEDIUM/HIGH` |
| `sourceRefs` | `ArtifactRef[]` | YES | 唯一项；允许为空 |
| `gapRefs` | `ArtifactRef[]` | YES | 唯一 Gap 引用；允许为空 |

`sourceRefs` 为空时 `gapRefs` 必须非空；`origin = SOURCE_EXPLICIT` 时
`sourceRefs` 必须非空。

`SourceCoverage`：

| 字段 | 类型 | 必填 | 约束 |
|---|---|---|---|
| `status` | enum | YES | `COMPLETE/PARTIAL/MISSING` |
| `evidenceRefs` | `ArtifactRef[]` | YES | 唯一项 |
| `gapRefs` | `ArtifactRef[]` | YES | 唯一项 |

条件约束：

- `status = COMPLETE`：`evidenceRefs` 非空，`gapRefs` 为空；
- `status = PARTIAL`：`evidenceRefs` 和 `gapRefs` 均非空；
- `status = MISSING`：`evidenceRefs` 为空，`gapRefs` 非空。

`Gap`：

| 字段 | 类型 | 必填 | 约束 |
|---|---|---|---|
| `gapId` | `ArtifactId` | YES | 当前集合内唯一 |
| `summary` | `NonBlankText` | YES | 不得静默补齐 |
| `state` | enum | YES | `OPEN/RESOLVED` |
| `sourceRefs` | `ArtifactRef[]` | YES | 可为空 |

`CriticalBoundary`：

| 字段 | 类型 | 必填 | 约束 |
|---|---|---|---|
| `boundaryId` | `ArtifactId` | YES | 当前集合内唯一 |
| `statement` | `NonBlankText` | YES | 明确条件或适用边界 |
| `sourceRefs` | `ArtifactRef[]` | YES | `PUBLISHED` Module 中不得为空 |

`EvidenceStatement`：

| 字段 | 类型 | 必填 | 约束 |
|---|---|---|---|
| `statementId` | `ArtifactId` | YES | 当前集合内唯一 |
| `statement` | `NonBlankText` | YES | 保持条件和边界 |
| `sourceRefs` | `ArtifactRef[]` | YES | 唯一 EvidenceReference 引用 |
| `gapRefs` | `ArtifactRef[]` | YES | 唯一 Gap 引用 |

`sourceRefs` 为空时 `gapRefs` 必须非空。

`OrderedArtifactStep`：

| 字段 | 类型 | 必填 | 约束 |
|---|---|---|---|
| `stepId` | `ArtifactId` | YES | 当前序列内唯一 |
| `order` | integer | YES | 从 1 开始且在当前序列连续 |
| `artifactRef` | `ArtifactRef` | YES | 指向序列的正式参与对象 |
| `statement` | `NonBlankText` | YES | 说明该步骤的认知作用 |
| `sourceRefs` | `ArtifactRef[]` | YES | 唯一 EvidenceReference 引用 |

所有共享对象拒绝未知字段。

## 6. 十项正式认知产物

### 6.1 KnowledgeSkeleton

必填字段：

```text
schemaVersion
artifactId
revisionId
publicationState
landscapeThesis
themes
relations
understandingRoute
structureAmbiguityRefs
sourceCoverage
```

- `landscapeThesis` 为 string；`PUBLISHED` 时非空。
- `themes` 为 `KnowledgeTheme[]`，至少一项。
- `relations` 为 `Relation[]`，顶层最多 12 项。
- `understandingRoute` 为唯一 `ArtifactRef[]`，至少一项。
- `structureAmbiguityRefs` 为唯一 `ArtifactRef[]`，允许为空。
- `sourceCoverage` 为 `SourceCoverage`。
- Skeleton 只能包含候选结构，不得包含 Module 深度正文。

### 6.2 KnowledgeTheme

必填字段：

```text
schemaVersion
artifactId
revisionId
publicationState
title
coreQuestions
role
primaryParent
moduleCandidates
relations
sourceCoverage
```

- `title` 为 `NonBlankText`。
- `coreQuestions` 为 1–3 个非空字符串。
- `role` 为 `KnowledgeRole`。
- `primaryParent` 为唯一 KnowledgeLandscape `ArtifactRef`。
- `moduleCandidates` 至少一项，每项必须包含：
  `moduleId`、`title`、1–3 个 `coreQuestions`、`role`、`primaryParent`、
  `candidateSpine` 和 `sourceCoverage`。
- `moduleId` 和 `primaryParent` 为 `ArtifactRef`，`title` 为
  `NonBlankText`，`role` 为 `KnowledgeRole`，`sourceCoverage` 为
  `SourceCoverage`。
- `candidateSpine` 为 0–9 个非空字符串；它不是已确认
  `PrimaryCognitiveSpine`。
- 每个 Module Candidate 的 `primaryParent` 必须等于当前 Theme ID。
- `relations` 只能使用正式 `RelationType`。

### 6.3 CognitiveModule

必填字段：

```text
schemaVersion
artifactId
revisionId
publicationState
primaryParent
title
thesis
role
coreQuestions
primaryCognitiveSpine
facets
knowledgeElements
criticalBoundaries
relations
sourceRefs
gaps
qualityAssessment
```

- `primaryParent` 是唯一 KnowledgeTheme `ArtifactRef`。
- `title` 为 `NonBlankText`。
- `thesis` 为 string；Draft/Confirmed 可以为空，Published 必须非空。
- `role` 为 `KnowledgeRole`。
- `coreQuestions` 为 1–3 个非空字符串。
- `primaryCognitiveSpine` 为 `PrimaryCognitiveSpine` 或 `null`；Published 时
  不得为 `null`。
- `facets` 为严格对象数组。每个 Facet 包含 `facetId`、`title`、`summary`、
  `elementRefs` 和 `sourceRefs`。
- Facet 的 `facetId` 为 `ArtifactId`，`title` 为 `NonBlankText`，
  `summary` 为 string，`elementRefs` 和 `sourceRefs` 为唯一
  `ArtifactRef[]`。
- `knowledgeElements` 为 `KnowledgeElement[]`。
- `criticalBoundaries` 为 `CriticalBoundary[]`；Published 时 1–5 项。
- `relations` 为 `Relation[]`，最多 5 项；Published 时至少一项。
- `sourceRefs` 为唯一 EvidenceReference `ArtifactRef[]`；Published 时非空。
- `gaps` 为 `Gap[]`，允许为空。
- `qualityAssessment` 为 `QualityAssessment` 或 `null`；Published 时不得为
  `null`，且任何维度不得为 `FAIL`。

Published Module 缺少 thesis、spine、boundary、sourceRefs 或合格
qualityAssessment 时必须被拒绝。

### 6.4 PrimaryCognitiveSpine

必填字段：

```text
schemaVersion
artifactId
revisionId
publicationState
moduleRef
steps
```

- `moduleRef` 必须指向且只指向一个 CognitiveModule。
- `steps` 为 4–9 个有序严格对象。
- 每个 Step 包含 `stepId`、从 1 开始的 `order`、`statement` 和
  `sourceRefs`。
- Step ID 和 order 在当前 Spine 内唯一且连续。
- Published Spine 的每个 Step 都必须至少有一个 EvidenceReference。
- 同一 Module Revision 只能解析到一个 PrimaryCognitiveSpine。

### 6.5 KnowledgeElement

必填字段：

```text
schemaVersion
artifactId
revisionId
publicationState
moduleRef
elementType
title
content
sourceRefs
relations
```

- `moduleRef` 是唯一 CognitiveModule 主归属。
- `elementType` 为 `KnowledgeElementType`。
- `title` 为 `NonBlankText`。
- `content` 为 string；Published 时非空。
- `sourceRefs` 为唯一 EvidenceReference 引用；Published 时非空。
- KnowledgeElement 不携带主导航位置，也不能声明第二个 Module 主归属。

### 6.6 ThemeClosure

必填字段：

```text
schemaVersion
artifactId
revisionId
publicationState
themeRef
coreQuestions
thesis
moduleCooperation
themeSpine
criticalDistinctions
boundaries
relatedThemes
sourceCoverage
gaps
```

- `themeRef` 唯一指向 KnowledgeTheme。
- `coreQuestions` 为 1–3 个非空字符串。
- `thesis` 为 string；Published 时非空。
- `moduleCooperation` 为严格对象数组，每项包含唯一 `moduleRef`、
  `contribution` 和 `sourceRefs`；`moduleRef` 为 `ArtifactRef`，
  `contribution` 为 `NonBlankText`，`sourceRefs` 为唯一
  EvidenceReference 引用；Published 时至少一项。
- `themeSpine` 为 `OrderedArtifactStep[]`，其中 `artifactRef` 只能指向当前
  Theme 下的 Module；Published 时至少一项。
- `criticalDistinctions`、`boundaries` 为 `EvidenceStatement[]`；
  Published 时均至少一项。
- `relatedThemes` 为 `Relation[]`，只能连接 Theme。
- `sourceCoverage` 和 `gaps` 必须显式存在。

### 6.7 LandscapeClosure

必填字段：

```text
schemaVersion
artifactId
revisionId
publicationState
landscapeThesis
coreThemes
crossThemeSpine
keyDependencies
globalBoundaries
understandingRoute
sourceCoverage
gaps
```

- `landscapeThesis` 为 string；Published 时非空。
- `coreThemes` 为严格对象数组，每项包含唯一 `themeRef`、`role`、
  `contribution` 和 `sourceRefs`；`themeRef` 为 `ArtifactRef`，`role` 为
  `KnowledgeRole`，`contribution` 为 `NonBlankText`，`sourceRefs` 为唯一
  EvidenceReference 引用；Published 时至少一项。
- `crossThemeSpine` 为 `OrderedArtifactStep[]`，其中 `artifactRef` 只能
  指向 Theme；Published 时至少一项。
- `keyDependencies` 为 `Relation[]`，只能连接 Theme。
- `globalBoundaries` 为 `EvidenceStatement[]`；Published 时至少一项。
- `understandingRoute` 为唯一 Theme/Module `ArtifactRef[]`；Published 时至少
  一项。
- Route 是派生认知顺序，不得形成第二棵层级树。

### 6.8 EvidenceReference

必填字段：

```text
schemaVersion
artifactId
revisionId
publicationState
sourceDocumentRef
documentBlockRef
sectionPath
pageNumber
sourceOrder
blockType
contentSummary
sourceKind
supports
inferenceDisclosure
```

- `sourceDocumentRef` 和 `documentBlockRef` 均为 `ArtifactRef`。
- `sectionPath` 为至少一项的非空字符串数组。
- `pageNumber` 为大于等于 1 的整数或 `null`。
- `sourceOrder` 为大于等于 0 的整数或 `null`。
- `pageNumber` 和 `sourceOrder` 至少一个非 `null`。
- `blockType` 限于：
  `HEADING/PARAGRAPH/LIST/TABLE/IMAGE/CAPTION/OTHER`。
- `contentSummary` 为 `NonBlankText`。
- `sourceKind` 为 `SourceKind`。
- `supports` 是至少一项的唯一正式产物引用。
- `inferenceDisclosure` 为 string；
  `SOURCE_SYNTHESIZED` 时必须非空。
- EvidenceReference 只记录来源元数据和摘要，不复制完整原始文档。

### 6.9 StructureAmbiguity

必填字段：

```text
schemaVersion
artifactId
revisionId
publicationState
locationRef
recommendedStructure
alternatives
rationale
closureImpacts
sourceRefs
gapRefs
```

- `locationRef` 指向歧义所在 Theme、Module 或 Element。
- `recommendedStructure` 包含 `summary` 和唯一 `affectedRefs`。
- `alternatives` 至少一项，每项包含 `alternativeId`、`summary`、
  `affectedRefs` 和 `riskLevel`。
- `rationale` 为 `NonBlankText`。
- `closureImpacts` 至少一项，每项包含 `scopeRef`、`impact` 和
  `riskLevel`。
- `sourceRefs` 为唯一 EvidenceReference 引用，允许为空。
- `gapRefs` 为唯一 Gap 引用；`sourceRefs` 为空时必须非空。
- 一个实例只描述局部备选，不允许携带多棵完整候选树。

### 6.10 QualityAssessment

必填字段：

```text
schemaVersion
artifactId
revisionId
publicationState
subjectRef
hierarchyCorrectness
granularityFitness
cognitiveClosure
spineCoherence
importanceAccuracy
sourceFaithfulness
compressionEfficiency
hardFailures
```

七个质量维度均使用严格 `AssessmentDimension`：

```text
status = PASS | WARN | FAIL
findings = AssessmentFinding[]
```

每个 Finding 是严格对象，包含 `code`、`message`、`artifactRefs` 和
`sourceRefs`；`code`、`message` 为 `NonBlankText`，后两项为唯一
`ArtifactRef[]`。
`hardFailures` 为下列总体设计 §21 硬失败代码数组，必须去重：

```text
SOURCE_DIRECTORY_COPIED
MECHANISM_FRAGMENTED
PRIMARY_SPINE_MISSING
ORPHAN_CORE_KNOWLEDGE
BOUNDARY_MISSING
CRITICAL_CLAIM_WITHOUT_SOURCE
SOURCE_GAP_SILENTLY_FILLED
THEME_CLOSURE_MISSING
DUPLICATED_BODY_ACROSS_THEMES
```

Published Subject 的
`hardFailures` 必须为空，七个维度均不得为 `FAIL`。

## 7. Generation Stage Record

正式生成阶段枚举：

```text
SOURCE_PARSING
SECTION_UNDERSTANDING
CONCEPT_AND_QUESTION_EXTRACTION
THEME_CANDIDATE_GENERATION
MODULE_CANDIDATE_CLUSTERING
SKELETON_QUALITY_CHECK
USER_STRUCTURE_CONFIRMATION
MODULE_DEEP_GENERATION
THEME_CLOSURE_GENERATION
LANDSCAPE_CONVERGENCE
PUBLICATION
```

状态枚举：

```text
GenerationStatus =
  PENDING
  RUNNING
  SUCCEEDED
  FAILED
  RETRYING

ValidationStatus =
  NOT_RUN
  PASS
  FAIL

OutputKind =
  NONE
  INTERMEDIATE
  COGNITIVE_ARTIFACT
```

必填字段：

```text
schemaVersion
runId
stage
inputHash
promptVersion
model
sourceBlockRefs
outputKind
outputSchemaId
structuredOutput
outputHash
validationResult
generationStatus
retryCount
retryScopeRefs
failure
```

- `runId` 为 `ArtifactId`。
- `inputHash` 为 `Sha256`；`outputHash` 为 `Sha256` 或 `null`。
- `promptVersion`、`model` 为 `NonBlankText`；不调用模型的阶段使用
  `NOT_APPLICABLE`，不得省略。
- `sourceBlockRefs` 为唯一 DocumentBlock 引用。
- `outputSchemaId` 为 Schema URN 或 `null`。
- `structuredOutput` 为合法 JSON 值或 `null`。
- `outputKind = COGNITIVE_ARTIFACT` 时，`outputSchemaId` 必须指向 Catalog
  中的认知产物 Schema，`structuredOutput` 不得为 `null` 且必须通过该
  Schema，`outputHash` 不得为 `null`。
- `outputKind = INTERMEDIATE` 时，`outputSchemaId` 必须为 `null`，输出只作为
  阶段快照，不得被 Renderer 当作正式事实；`structuredOutput` 和
  `outputHash` 不得为 `null`。
- `outputKind = NONE` 时，`structuredOutput`、`outputSchemaId` 和
  `outputHash` 必须为 `null`。
- `validationResult` 是严格对象，包含 `status`、唯一
  `validatedSchemaIds` 和 `errors`。每个 Error 包含稳定 `code`、
  `instancePath`、`schemaPath` 和 `message`；四项均为 string，其中
  `code`、`message` 非空。
- `status = PASS` 时 `errors` 必须为空；`status = FAIL` 时至少一项；
  `status = NOT_RUN` 时 `validatedSchemaIds` 和 `errors` 均为空。
- `generationStatus = SUCCEEDED` 时验证状态必须为 `PASS`。
- `failure` 为 `null` 或严格对象；对象包含 `code`、`message`、
  `retryable` 和唯一 `failedScopeRefs`。
- `generationStatus = FAILED` 时 `failure` 不得为 `null`；其他状态必须为
  `null`。
- `retryCount` 为大于等于 0 的整数。
- `generationStatus = RETRYING` 时 `retryCount` 必须大于等于 1。
- `retryScopeRefs` 只包含最小受影响范围。
- 相同 `stage + inputHash + promptVersion + schemaVersion` 已有成功结果时，
  语义验证器必须拒绝重复有效运行。

## 8. Renderer Input

Renderer 类型枚举：

```text
HIERARCHY
MATRIX
STAGE_CHAIN
DECISION_PATH
STATE_TRANSITION
COMPARISON
CAUSAL_CHAIN
LAYERED_STRUCTURE
STRUCTURED_PANEL
```

必填字段：

```text
schemaVersion
rendererType
title
summary
nodes
groups
relations
sourceRefs
incompleteState
interactionHints
```

- `title` 为 `NonBlankText`，`summary` 为 string。
- `nodes` 为 1–64 个唯一 Node；超过 12 个时 `groups` 必须非空。
- `groups` 为 0–16 个唯一 Group。
- `relations` 为 0–64 个唯一 Relation。
- `sourceRefs` 为唯一 EvidenceReference 引用。
- `interactionHints` 必须去重。

`RendererNode` 必须包含：

```text
nodeId
artifactRef
label
summary
groupRef
sourceRefs
```

- `artifactRef` 必须指向已验证的正式认知产物。
- `nodeId` 为 `ArtifactId`，`label` 为 `NonBlankText`，`summary` 为
  string。
- `groupRef` 为 Group ID 或 `null`。
- `sourceRefs` 为唯一 `ArtifactRef[]`，且必须是该产物可追溯
  EvidenceReference 的子集。

`RendererGroup` 必须包含 `groupId`、`title`、唯一 `nodeRefs` 和
`collapsed`；`groupId` 为 `ArtifactId`，`title` 为 `NonBlankText`，
`nodeRefs` 为至少一项的唯一 Node ID 数组，`collapsed` 为 boolean。所有 Node
和 Group 引用都必须在当前 Renderer Input 内解析；Node 超过 12 个时，每个
Node 必须恰好属于一个 Group。

`RendererRelation` 必须包含 `relationId`、`type`、`sourceNodeRef`、
`targetNodeRef`、`artifactRelationRef` 和 `sourceRefs`。它只能投影正式
Relation，不得创建额外语义边。`relationId` 为 `ArtifactId`，`type` 为
`RelationType`，Node Ref 必须在当前输入内解析，`artifactRelationRef` 必须
指向正式 Relation，`sourceRefs` 为唯一 EvidenceReference 引用。

`incompleteState`：

```text
status =
  COMPLETE
  PARTIAL
  BLOCKED_BY_SOURCE_GAP

gapRefs = ArtifactRef[]
```

- `gapRefs` 必须引用正式 Gap。
- `status = COMPLETE` 时 `gapRefs` 必须为空且顶层 `sourceRefs` 非空。
- `status = BLOCKED_BY_SOURCE_GAP` 时 `gapRefs` 必须非空。

`interactionHints` 只允许：

```text
EXPAND_DETAILS
SHOW_SOURCE
FOLD_GROUP
```

Renderer 语义验证必须证明：

- 每个 Node 都有正式产物引用；
- 每条 Relation 都有正式关系引用；
- Renderer 不改变认知顺序、关系类型或来源性质；
- 超过密度边界时使用 Group/Fold/Stage，而不是无限扩展节点。

## 9. Page State

Page State 使用独立字符串 Schema：

```text
EMPTY
UPLOADING
PARSING
ANALYZING
GENERATING
WAITING_REVIEW
PARTIALLY_GENERATED
FAILED
RETRYING
CONFIRMED
PUBLISHED
OUTDATED_BY_STRUCTURE_CHANGE
```

Page State 不得复用或扩写 Generation Status。

## 10. 数据流与单一事实源

```text
GenerationStageRecord
→ validated Cognitive Artifact
→ Renderer Input projection
→ Desktop Web
```

- Generation Record 保存可审计阶段快照，不是可独立编辑的认知事实。
- 正式认知产物通过 Schema 与语义验证后才可成为 Renderer 输入。
- Renderer Input 是一次投影，不得被回写为认知产物。
- SourceReference 可从认知产物和 Renderer 双向定位，但原始来源保持只读。
- Draft/Confirmed 的不完整状态必须显式表达，不能用静默补全换取验证通过。

## 11. 验证与错误模型

验证分四层：

1. Schema 文件可解析且符合 Draft 2020-12 元 Schema；
2. Catalog ID 唯一，全部 `$ref` 由本地 Catalog 解析；
3. 实例正反例通过对应 Schema；
4. 语义校验器检查跨对象引用和产品不变量。

稳定错误分类：

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

反例必须以预期契约错误失败，不能因脚本崩溃、文件缺失或联网失败而通过。

## 12. 测试基线

- 13 个正式 Schema 每个至少一个完整正例。
- 覆盖缺少 required、未知字段、非法枚举和错误类型。
- Published Module 缺少 thesis、spine、boundary、sourceRefs 或质量门禁时失败。
- Spine 少于 4 步、多于 9 步、order 不连续或同一 Module 多主线时失败。
- 非法关系、悬空 parent、source 或 artifact 引用时失败。
- Generation 阶段与 `structuredOutput` Schema 不匹配时失败。
- Renderer 节点无正式产物引用或关系无正式 Relation 引用时失败。
- 非法 Page State、未登记 Schema、远程 `$ref` 或缺失证据映射时失败。
- 所有验证离线运行，不读取 Golden Case 正文、不访问 Redis 遗留链接、不修改
  `raw/`。
- Source、Specialty Coverage、Build、UI Contract 和 Task Card 既有 Gate 必须
  保持通过。

## 13. 版本与变更控制

```text
MAJOR = breaking field, required, enum, relation, identity or lifecycle change
MINOR = backward-compatible optional capability
PATCH = clarification without validation behavior change
```

- 已发布 Schema 的 `$id` 和语义不可原地改变。
- 新 major/minor 版本必须拥有独立 Catalog 条目和证据映射。
- 实施中若发现本基线矛盾，必须停止 W0-04，形成新的设计版本和显式批准。
- 不允许在 Schema 文件中先修改，再回写设计使其“看起来一致”。

## 14. Gate 与任务卡状态

本设计落地后：

```text
DOC-GAP-001 Disposition =
  RESOLVED_BY_APPROVED_SCHEMA_REBASELINE

W0-04 Status = READY
W0-G3 JsonSchemaValidation = NOT_STARTED
```

只有 13 个正式 Schema、Catalog、Evidence Map、结构验证、语义验证、正反例和
全部回归验证通过后，才允许：

```text
W0-04 Status = DONE
W0-G3 JsonSchemaValidation = PASS
W0-05 Status = READY
```

本设计提交与 W0-04 Schema 实施提交必须分离。设计提交不创建 JSON Schema，
不实现业务功能，不修改原始输入。
