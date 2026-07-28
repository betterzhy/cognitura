# Cognitura Schema Baseline 2.0

```text
DecisionDate = 2026-07-28
CanonicalProjectName = Cognitura
EngineeringReferenceName = Cognitura-Schema-Baseline-2.0
BaselineVersion = 2.0.0
Status = FORMAL_SCHEMA_REBASELINE
AuthorityType = USER_APPROVED_ENGINEERING_REBASELINE
ApprovalBasis = USER_APPROVED_COMPLETE_DESIGN_AND_LANDING
PreviousReviewCandidate = Cognitura-Schema-Baseline-1.0@730ce9873b9791baa30e370628cb60a74b05fba1
MajorVersionReason = FIXED_COMMIT_REVIEW_BREAKING_CONTRACT_HARDENING
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
→ Cognitura-Schema-Baseline-2.0
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

`Cognitura-Schema-Baseline-1.0` 在固定提交审查中被判定为 `NO-GO`，且从未
生成或发布 JSON Schema。审查要求新增 required、identity 和 relation 约束；
本文件因此按 `MAJOR` 规则升级为 2.0，而不在 1.0 工程引用和版本下原地漂移。

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
| `RB-004` | 十项正式认知产物携带 `schemaVersion`、`artifactId`、`revisionId` 和 `publicationState`；Generation Record 与 Renderer Input 携带 `schemaVersion` |
| `RB-005` | Draft 可显式不完整；Published 必须满足发布条件 |
| `RB-006` | Schema `$id` 使用稳定 URN，所有引用只能由本地 Catalog 解析 |
| `RB-007` | 每个字段和关键约束必须有总体设计证据或重基线裁决映射 |
| `RB-008` | JSON Schema 负责结构约束，语义验证器负责跨对象不变量 |
| `RB-009` | Generation Record 保存阶段快照和验证结果，不成为第二个可编辑事实源 |
| `RB-010` | Renderer Input 只能投影一个已验证 CognitiveModule 的内容；节点和关系不得跨出该 Module |
| `RB-011` | Page State 与 Generation Status 使用不同 Schema 和枚举 |
| `RB-012` | 破坏兼容性的变更必须升级 major，不得在任一已命名 major 下原地漂移语义 |
| `RB-013` | 所有校验必须离线运行，禁止通过网络解析 Schema 或来源 |
| `RB-014` | Schema 验证错误与语义错误使用稳定、可断言的错误分类 |
| `RB-015` | 来源冲突必须以状态和冲突组显式表达；仅用户可形成解决裁决，且任何裁决都不得删除或隐藏冲突来源 |
| `RB-016` | 所有 `ArtifactRef` 必须在一个不可变 revision context 内唯一解析，并接受目标类型与作用域校验 |
| `RB-017` | `KnowledgeSkeleton` 是 L0 `KnowledgeLandscape` 的唯一正式版本化投影；其 `artifactId` 同时承担该 Landscape revision 的父级引用身份 |

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

每个 Schema 文件必须声明：

```text
$schema = https://json-schema.org/draft/2020-12/schema
$id = urn:cognitura:schema:<domain>:<name>:2.0.0
```

十项认知产物、Generation Record 和 Renderer Input 共 12 个对象实例 Schema
还必须要求实例属性 `schemaVersion = const 2.0.0`。Page State 是第 13 个正式
可实例化 Schema；它的实例是纯字符串枚举，不携带对象属性
`schemaVersion`。`common.schema.json` 不可实例化，也不要求实例属性。

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
| `SchemaVersion` | string，常量 `2.0.0` | `RB-004` |
| `ArtifactId` | string，长度 1–128，模式 `^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$` | `RB-004` |
| `RevisionId` | 与 `ArtifactId` 相同约束 | 总体设计 §18、`RB-004` |
| `ArtifactRef` | 与 `ArtifactId` 相同约束 | `RB-008` |
| `NonBlankText` | string，`minLength = 1` | `RB-003` |
| `Sha256` | string，模式 `^[a-f0-9]{64}$` | 总体设计 §17、`RB-009` |

`revision context` 是一次语义验证调用所使用的不可变对象快照：同一
`artifactId` 在该快照内最多解析到一个 `revisionId`，所有 `ArtifactRef`
都只能由该快照的本地对象注册表解析。下文“同一 revision context”均使用此
定义，不允许退回存储层的任意最新版本。对象注册表同时索引正式产物 ID 以及
内嵌 Relation、Gap 等共享对象 ID，并保持 ID 在其 owning revision 内唯一。
此语义来自 `RB-016`。

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

ConflictState =
  NONE
  UNRESOLVED
  RESOLVED_BY_USER
```

`PublicationState`、`KnowledgeRole`、`RelationType` 和
`KnowledgeElementType` 来自总体设计 §5–7、§12、§18；
`SourceKind` 来自总体设计 §20.9；`AssessmentStatus` 是 `RB-005` 下的发布
质量工程裁决；`ConflictState` 是为落实总体设计 §14 和 `RB-015` 的来源冲突
显式保留要求形成的字段级裁决。

### 5.3 共享对象

`Relation`：

| 字段 | 类型 | 必填 | 约束 |
|---|---|---|---|
| `relationId` | `ArtifactId` | YES | owning artifact revision 的关系注册表内唯一 |
| `type` | `RelationType` | YES | 不允许 `RELATED_TO` |
| `sourceRef` | `ArtifactRef` | YES | 必须可解析 |
| `targetRef` | `ArtifactRef` | YES | 必须可解析且不得等于 `sourceRef` |
| `origin` | `SourceKind` | YES | 综合关系必须显式标记 |
| `riskLevel` | enum | YES | `LOW/MEDIUM/HIGH` |
| `sourceRefs` | `ArtifactRef[]` | YES | 唯一 EvidenceReference 引用；允许为空 |
| `gapRefs` | `ArtifactRef[]` | YES | 唯一、由 owner 携带的 Gap 引用；允许为空 |

`sourceRefs` 为空时 `gapRefs` 必须非空；`origin = SOURCE_EXPLICIT` 时
`sourceRefs` 必须非空。

同一 owning artifact revision 的任何关系定义不得复用 `relationId`。在
CognitiveModule 中，正式 Relation 定义只能存在于 Module 顶层 `relations`；
KnowledgeElement 只保存对这些定义的引用，不复制 Relation 对象。

`SourceCoverage`：

| 字段 | 类型 | 必填 | 约束 |
|---|---|---|---|
| `status` | enum | YES | `COMPLETE/PARTIAL/MISSING` |
| `evidenceRefs` | `ArtifactRef[]` | YES | 唯一 EvidenceReference 引用 |
| `gapRefs` | `ArtifactRef[]` | YES | 唯一、由当前 owner 携带的 Gap 引用 |

条件约束：

- `status = COMPLETE`：`evidenceRefs` 非空，`gapRefs` 为空；
- `status = PARTIAL`：`evidenceRefs` 和 `gapRefs` 均非空；
- `status = MISSING`：`evidenceRefs` 为空，`gapRefs` 非空。

每个 `evidenceRefs` 目标都必须是同一 revision context 内的
EvidenceReference，且其 `supports` 必须包含携带该 SourceCoverage 的 owner
身份；任何其他 Artifact 类型不得充当来源覆盖。每个 `gapRefs` 必须解析到
owner 内嵌 `gaps` 的唯一 Gap。`COMPLETE` 还要求 owner 全部证据承载字段的
EvidenceReference 并集与 `evidenceRefs` 一致，不能用无关非空引用冒充完整。

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
| `sourceRefs` | `ArtifactRef[]` | YES | 唯一 EvidenceReference 引用；`PUBLISHED` Module 中不得为空 |

`EvidenceStatement`：

| 字段 | 类型 | 必填 | 约束 |
|---|---|---|---|
| `statementId` | `ArtifactId` | YES | 当前集合内唯一 |
| `statement` | `NonBlankText` | YES | 保持条件和边界 |
| `sourceRefs` | `ArtifactRef[]` | YES | 唯一 EvidenceReference 引用 |
| `gapRefs` | `ArtifactRef[]` | YES | 唯一 Gap 引用 |

`sourceRefs` 为空时 `gapRefs` 必须非空。

`ConflictResolutionDecision`：

| 字段 | 类型 | 必填 | 约束 |
|---|---|---|---|
| `decisionId` | `ArtifactId` | YES | 同一冲突组内一致 |
| `decidedBy` | string | YES | 常量 `USER` |
| `outcome` | enum | YES | `PRESERVE_ALL/PREFER_EVIDENCE` |
| `preferredEvidenceRef` | `ArtifactRef/null` | YES | 只能指向当前冲突组成员 |
| `rationale` | `NonBlankText` | YES | 保存用户裁决理由 |

`outcome = PRESERVE_ALL` 时 `preferredEvidenceRef` 必须为 `null`；
`outcome = PREFER_EVIDENCE` 时必须非空。同一冲突组的全部 EvidenceReference
必须携带值相同的决策对象；无论结果如何，全部冲突来源仍保留。

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

`KnowledgeSkeleton` 是 L0 `KnowledgeLandscape` 的正式版本化投影，不另建
第 11 个 KnowledgeLandscape Schema。其 `artifactId` 是当前 Landscape
revision 的唯一身份；KnowledgeTheme 的父级引用必须解析到该
KnowledgeSkeleton。此裁决来自 `RB-017`，不会引入第二棵根结构。

### 6.1 KnowledgeSkeleton

必填字段：

```text
schemaVersion
artifactId
revisionId
publicationState
landscapeThesis
themes
coreThemeRefs
relations
understandingRoute
structureAmbiguityRefs
sourceCoverage
gaps
```

- `landscapeThesis` 为 string；`PUBLISHED` 时非空。
- `themes` 为 `KnowledgeTheme[]`，至少一项。
- `coreThemeRefs` 为唯一 `ArtifactRef[]`，最多 9 项；每项必须指向当前
  `themes` 中的 Theme。Published 时必须为 3–9 项。
- `relations` 为 `Relation[]`，顶层最多 12 项。
- `understandingRoute` 为唯一 `ArtifactRef[]`，至少一项。
- `structureAmbiguityRefs` 为唯一 `ArtifactRef[]`，允许为空。
- `sourceCoverage` 为 `SourceCoverage`。
- `gaps` 为 `Gap[]`，允许为空；必须与 `sourceCoverage.gapRefs` 指向的 Gap
  集合一致。
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
coreModuleRefs
relations
sourceCoverage
gaps
```

- `title` 为 `NonBlankText`。
- `coreQuestions` 为 1–3 个非空字符串。
- `role` 为 `KnowledgeRole`。
- `primaryParent` 为 `ArtifactRef`，必须等于当前 revision context 中唯一
  KnowledgeSkeleton 的 `artifactId`；该 ID 按 `RB-017` 代表
  KnowledgeLandscape 父级身份。
- `moduleCandidates` 至少一项，每项必须包含：
  `moduleId`、`title`、1–3 个 `coreQuestions`、`role`、`primaryParent`、
  `candidateSpine`、`sourceCoverage` 和 `gaps`。
- `moduleId` 和 `primaryParent` 为 `ArtifactRef`，`title` 为
  `NonBlankText`，`role` 为 `KnowledgeRole`，`sourceCoverage` 为
  `SourceCoverage`，`gaps` 为 `Gap[]`。
- `candidateSpine` 为 0–9 个非空字符串；它不是已确认
  `PrimaryCognitiveSpine`。
- 每个 Module Candidate 的 `primaryParent` 必须等于当前 Theme ID。
- `coreModuleRefs` 为唯一 `ArtifactRef[]`，最多 7 项；每项必须指向当前
  `moduleCandidates` 中的 Module Candidate。Published 时必须为 2–7 项。
- `relations` 为 `Relation[]`，最多 12 项，只能使用正式 `RelationType`；
  Draft 时允许为空。
- Theme 顶层 `gaps` 和每个 Module Candidate 的 `gaps` 都允许为空，并必须
  分别与同一对象 `sourceCoverage.gapRefs` 指向的 Gap 集合一致。

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
keyTakeaways
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
- Facet 的 `elementRefs` 只能指向 owning Module 的 KnowledgeElement，
  `sourceRefs` 只能指向支持该 Module 的 EvidenceReference。
- `knowledgeElements` 为 `KnowledgeElement[]`。
- `keyTakeaways` 为 `EvidenceStatement[]`，最多 7 项；Published 时必须为
  3–7 项。
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
- `stepId` 为 `ArtifactId`，`statement` 为 `NonBlankText`，`sourceRefs`
  为唯一 EvidenceReference 引用；Step ID 和 order 在当前 Spine 内唯一且连续。
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
- `relations` 为唯一 `ArtifactRef[]`，最多 5 项；每项必须解析到 owning
  CognitiveModule 顶层 `relations` 中的唯一 Relation，且 `sourceRef` 或
  `targetRef` 至少一端必须等于当前 KnowledgeElement 的 `artifactId`。
  Draft 时允许为空，Published 时是否非空由 Module 层关系与认知内容共同
  决定，不另行强制。
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
- `relatedThemes` 为 `Relation[]`，最多 12 项，只能连接 Theme。
- `sourceCoverage` 为 `SourceCoverage`，适用 §5.3 的
  `COMPLETE/PARTIAL/MISSING` 条件；Published 时同样不得违反这些条件。
- `gaps` 为 `Gap[]`，允许为空；必须与 `sourceCoverage.gapRefs` 指向的 Gap
  集合一致。
- `sourceCoverage.evidenceRefs` 必须等于 `moduleCooperation`、
  `themeSpine`、`criticalDistinctions`、`boundaries` 和 `relatedThemes`
  中所有 `sourceRefs` 的并集；每个 EvidenceReference 的 `supports` 必须
  包含当前 ThemeClosure 的 `artifactId`。

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
  EvidenceReference 引用；最多 9 项，Published 时必须为 3–9 项。
- `crossThemeSpine` 为 `OrderedArtifactStep[]`，其中 `artifactRef` 只能
  指向 Theme；Published 时至少一项。
- `keyDependencies` 为 `Relation[]`，最多 12 项，只能连接 Theme。
- `globalBoundaries` 为 `EvidenceStatement[]`；Published 时至少一项。
- `understandingRoute` 为唯一 Theme/Module `ArtifactRef[]`；Published 时至少
  一项。
- `sourceCoverage` 为 `SourceCoverage`，适用 §5.3 的
  `COMPLETE/PARTIAL/MISSING` 条件；Published 时同样不得违反这些条件。
- `gaps` 为 `Gap[]`，允许为空；必须与 `sourceCoverage.gapRefs` 指向的 Gap
  集合一致。
- `sourceCoverage.evidenceRefs` 必须等于 `coreThemes`、
  `crossThemeSpine`、`keyDependencies` 和 `globalBoundaries` 中所有
  `sourceRefs` 的并集；每个 EvidenceReference 的 `supports` 必须包含当前
  LandscapeClosure 的 `artifactId`。
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
conflictState
conflictGroupId
resolutionDecision
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
- `conflictState` 为 `ConflictState`；`conflictGroupId` 为
  `ArtifactId` 或 `null`；`resolutionDecision` 为
  `ConflictResolutionDecision` 或 `null`。
- `conflictState = NONE` 时，`conflictGroupId` 与
  `resolutionDecision` 均必须为 `null`。
- `conflictState = UNRESOLVED` 时，`conflictGroupId` 必须非空且
  `resolutionDecision` 必须为 `null`；同一冲突组必须至少包含两项
  EvidenceReference。
- `conflictState = RESOLVED_BY_USER` 时 `conflictGroupId` 与
  `resolutionDecision` 都必须非空；只有 `decidedBy = USER` 的决策对象合法，
  自动生成、推断或模型裁决不得把冲突标记为已解决。
- 语义验证器必须保留同一冲突组的全部 EvidenceReference；不得因已有用户
  裁决而删除、隐藏或改写冲突来源。
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
- `recommendedStructure` 是严格对象，包含 `summary` 和唯一
  `affectedRefs`；`summary` 为 `NonBlankText`，`affectedRefs` 为至少一项的
  `ArtifactRef[]`。
- `alternatives` 至少一项，每项是严格对象，包含 `alternativeId`、
  `summary`、`affectedRefs` 和 `riskLevel`；`alternativeId` 为
  `ArtifactId` 且集合内唯一，`summary` 为 `NonBlankText`，
  `affectedRefs` 为至少一项的唯一 `ArtifactRef[]`，`riskLevel` 限于
  `LOW/MEDIUM/HIGH`。
- `rationale` 为 `NonBlankText`。
- `closureImpacts` 至少一项，每项是严格对象，包含 `scopeRef`、`impact` 和
  `riskLevel`；`scopeRef` 为指向 Theme、Module、ThemeClosure 或
  LandscapeClosure 的 `ArtifactRef`，`impact` 为 `NonBlankText`，
  `riskLevel` 限于 `LOW/MEDIUM/HIGH`。
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

`subjectRef` 为 `ArtifactRef`，只能指向同一 revision context 内的
`KnowledgeSkeleton`、`KnowledgeTheme`、`CognitiveModule`、
`ThemeClosure` 或 `LandscapeClosure`。不得指向 EvidenceReference、
StructureAmbiguity、QualityAssessment、Generation Record 或 Renderer
Input。

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
moduleRef
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

- `moduleRef` 必须且只能指向一个已通过 Schema 与语义验证的
  CognitiveModule；当前 Renderer Input 的所有内容都受该引用约束。
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
contentPath
label
summary
groupRef
sourceRefs
```

- `artifactRef` 必须等于顶层 `moduleRef`，不得指向 Theme、Closure、
  QualityAssessment、EvidenceReference 或其他正式认知产物。
- `contentPath` 为 RFC 6901 JSON Pointer，必须解析到该 CognitiveModule
  revision 内的被投影内容；不得定位到另一产物或外部文档。
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
指向顶层 `moduleRef` 对应 CognitiveModule 内的正式 Relation，`sourceRefs`
为唯一 EvidenceReference 引用。

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

- 每个 Node 的 `artifactRef` 都等于顶层 `moduleRef`，且 `contentPath`
  解析到该 Module revision 内的内容；
- 每条 Relation 都引用同一 Module 内的正式关系；
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
→ validated CognitiveModule
→ Renderer Input projection
→ Desktop Web
```

- Generation Record 保存可审计阶段快照，不是可独立编辑的认知事实。
- 只有通过 Schema 与语义验证的 CognitiveModule 才可成为 Renderer Input
  的投影来源。
- Renderer Input 是一次投影，不得被回写为认知产物。
- EvidenceReference 可从认知产物和 Renderer 双向定位，但原始来源保持只读。
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
- Published Skeleton 的核心 Theme 少于 3 个或多于 9 个、Published Theme 的
  核心 Module 少于 2 个或多于 7 个、Published Module 的 KeyTakeaways 少于
  3 个或多于 7 个时失败。
- Spine 少于 4 步、多于 9 步、order 不连续或同一 Module 多主线时失败。
- 非法关系、悬空 parent、source 或 artifact 引用时失败。
- 来源冲突缺少冲突组、被自动标记解决、用户裁决引用非法或冲突来源被隐藏时失败。
- Generation 阶段与 `structuredOutput` Schema 不匹配时失败。
- Renderer 节点跨 Module、`contentPath` 无法在同一 Module revision 解析或
  关系不是该 Module 内正式 Relation 时失败。
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
