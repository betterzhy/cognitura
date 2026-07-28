# Cognitura 页面契约

```text
DecisionDate = 2026-07-28
CanonicalProjectName = Cognitura
ContractScope = W0-06_NON_SCHEMA_PAGE_CONTRACTS
AuthoritativeSource = Cognitura-Overall-Design-1.2§20.1-20.11
UIUXSpecialtyBody = MISSING
DocumentationGap = DOC-GAP-002:OPEN
FieldLevelSchemaAuthority = NOT_PROVIDED
```

本文件从总体设计已经回迁的正式内容提取 Desktop Web 页面验收契约，不重写
产品设计，也不补写字段类型、必填性、枚举或 JSON Schema。

## 1. 页面地图与职责

```text
PageContract = WORKSPACE_LIST|WorkspaceList|OD1.2§20.2|VIEW_AND_ENTER_EXISTING_COGNITIVE_WORKSPACES
PageContract = WORKSPACE_CREATE|WorkspaceCreate|OD1.2§20.2|CREATE_WORKSPACE_AND_DOCUMENT_COLLECTION
PageContract = DOCUMENT_UPLOAD|DocumentUpload|OD1.2§20.2|UPLOAD_DOCX_AND_OTHER_SOURCE_FILES
PageContract = DOCUMENT_PARSING_STATUS|DocumentParsingStatus|OD1.2§20.2|SHOW_PARSING_SEGMENT_TABLE_AND_IMAGE_STATUS
PageContract = THEME_MODEL_SELECTION|ThemeModelSelection|OD1.2§20.2|SELECT_BUILT_IN_MODEL_OR_CONTROLLED_ADJUSTMENT
PageContract = SKELETON_REVIEW|SkeletonReview|OD1.2§20.2,20.4|REVIEW_THEME_MODULE_HIERARCHY_AND_DECIDE_STRUCTURE
PageContract = LANDSCAPE_OVERVIEW|LandscapeOverview|OD1.2§20.2,20.5|FORM_DOMAIN_LEVEL_COGNITIVE_CONVERGENCE
PageContract = THEME_DETAIL|ThemeDetail|OD1.2§20.2,20.6|SHOW_THEME_CLOSURE_AND_MODULE_COOPERATION
PageContract = MODULE_READING|ModuleReading|OD1.2§20.2,20.7|READ_ALONG_PRIMARY_COGNITIVE_SPINE
PageContract = SOURCE_EVIDENCE|SourceEvidence|OD1.2§20.2,20.9|TRACE_SOURCE_AND_RETURN_TO_COGNITIVE_POSITION
PageContract = STRUCTURE_REVISION|StructureRevision|OD1.2§20.2|SHOW_DIFF_IMPACT_AND_LOCAL_REGENERATION
PageContract = GENERATION_HISTORY|GenerationHistory|OD1.2§20.2|SHOW_STAGE_FAILURE_AND_LOCAL_RETRY_HISTORY
```

主路径保持层级优先：

```text
WorkspaceList
→ WorkspaceCreate
→ DocumentUpload / DocumentParsingStatus / ThemeModelSelection
→ SkeletonReview
→ LandscapeOverview
→ ThemeDetail
→ ModuleReading
→ SourceEvidence
```

`StructureRevision` 和 `GenerationHistory` 是辅助入口。阅读深度只改变展开程度，
不得改变 Theme、Module、Role、PrimaryCognitiveSpine 或结论。

## 2. Skeleton Review

Skeleton Review 只审核认知结构，不要求同时审核大量深度正文。

```text
SkeletonLayoutZone = LEFT|OD1.2§20.4|STABLE_THEME_AND_MODULE_HIERARCHY
SkeletonLayoutZone = CENTER|OD1.2§20.4|CURRENT_OBJECT_QUESTION_ROLE_OWNERSHIP_COVERAGE_SPINE_AND_SOURCE_RANGE
SkeletonLayoutZone = RIGHT|OD1.2§20.4|AMBIGUITY_OPTIONS_RISK_OPERATIONS_AND_LOCAL_REGENERATION

SkeletonOperation = RENAME|OD1.2§20.4|SUPPORTED
SkeletonOperation = MOVE|OD1.2§20.4|SUPPORTED
SkeletonOperation = MERGE|OD1.2§20.4|SUPPORTED
SkeletonOperation = SPLIT|OD1.2§20.4|SUPPORTED
SkeletonOperation = PIN|OD1.2§20.4|SUPPORTED
SkeletonOperation = EXCLUDE|OD1.2§20.4|SUPPORTED
```

交互不变量：

- 拖拽必须有菜单或命令式替代入口。
- MERGE/SPLIT 前显示来源重分配、关系、ThemeClosure 与 UnderstandingRoute 影响。
- PIN 后续不得被 AI 重生成覆盖。
- 中高风险 StructureAmbiguity 在确认前保持可见。
- 不生成多棵完整知识树增加比较负担。
- 完整结构编辑只要求桌面浏览器支持。

## 3. 认知阅读页面

LandscapeOverview 必须表达总体设计 §20.5 列出的九项概念：

```text
LandscapeThesis
CoreThemes
ThemeRoles
KeyDependencies
CrossThemeSpine
UnderstandingRoute
GlobalBoundaries
SourceCoverage
KnownGaps
```

它不是 Theme 列表，不使用自由节点画布；首屏优先领域结论、核心 Theme 和
UnderstandingRoute。

ThemeDetail 必须形成 ThemeClosure，并表达：

```text
ThemeCoreQuestion
ThemeThesis
CoreModules
ModuleCooperation
ThemeSpine
CriticalDistinctions
ThemeBoundaries
RelatedThemes
SourceCoverage
KnownGaps
```

ModuleReading 是核心学习页面。桌面正式布局为左侧层级、中间认知正文、右侧来源
与相关模块，正式顺序为：

```text
CoreThesis
→ PrimaryCognitiveSpine
→ DynamicRenderer
→ CriticalBoundaries
→ KnowledgeElements
→ Relations
→ SourceReferences
```

PrimaryCognitiveSpine 必须高于辅助 Facet，CriticalBoundary 不得弱化为普通备注，
页面不得退化为连续长文。

## 4. Source Evidence

SourceEvidence 是理解和追溯入口，不是独立知识库检索页面。它必须支持总体设计
§20.9 列出的文档名、章节路径、页码或顺序、DocumentBlock 类型、原始段落、
表格、图片与图注、双向来源使用关系、显式/综合来源区分、缺口/推断标记和返回
原 Module、SpineStep 或 Element。

## 5. 页面状态与错误模型

```text
PageState = EMPTY|OD1.2§20.10
PageState = UPLOADING|OD1.2§20.10
PageState = PARSING|OD1.2§20.10
PageState = ANALYZING|OD1.2§20.10
PageState = GENERATING|OD1.2§20.10
PageState = WAITING_REVIEW|OD1.2§20.10
PageState = PARTIALLY_GENERATED|OD1.2§20.10
PageState = FAILED|OD1.2§20.10
PageState = RETRYING|OD1.2§20.10
PageState = CONFIRMED|OD1.2§20.10
PageState = PUBLISHED|OD1.2§20.10
PageState = OUTDATED_BY_STRUCTURE_CHANGE|OD1.2§20.10
```

错误信息必须说明失败阶段、已完成内容、仍可使用结果、最小重试范围、是否重新
调用模型，以及结构变化是否使旧 Module 过期。局部失败不得阻断无关 Theme 或
Module 阅读。

## 6. 平台、响应式与禁止体验

```text
PlatformContract = DELIVERY_PLATFORM|WEB_BROWSER|OD1.2§20.11
PlatformContract = PRIMARY_EXPERIENCE|DESKTOP_WEB|OD1.2§20.11
PlatformContract = RESPONSIVE_SAFETY|REQUIRED|OD1.2§20.11
PlatformContract = DEDICATED_MOBILE_EXPERIENCE|DEFERRED|OD1.2§20.11
PlatformContract = MOBILE_FEATURE_PARITY|NOT_REQUIRED|OD1.2§20.11

ForbiddenExperience = COMPLEX_FREE_CANVAS|NO|OD1.2§20.1
ForbiddenExperience = CARD_ONLY_LAYOUT|NO|OD1.2§20.1
ForbiddenExperience = UNBOUNDED_NODE_GRAPH|NO|OD1.2§20.1
ForbiddenExperience = TRADITIONAL_ADMIN_TABLE_PRIMARY|NO|OD1.2§20.1
```

窄屏只保证文本和主路径可读、无严重溢出、Landscape/Theme/Module 可线性查看，
SourceEvidence 可使用 Overlay；复杂编辑必须提示使用桌面浏览器。V1 不建立
原生导航、底栏、移动手势、离线阅读、Push、原生分享、DeepLink、安装、
iOS/Android 权限、原生导入或移动端专属 Skeleton 编辑。

## 7. 来源与缺口边界

```text
ContractCoverage = UI-PAGE-IA|COVERED_BY_REVERSE_MIGRATION|OD1.2§20.2
ContractCoverage = UI-CORE-FLOW|COVERED_BY_REVERSE_MIGRATION|OD1.2§20.3
ContractCoverage = UI-SKELETON-REVIEW|COVERED_BY_REVERSE_MIGRATION|OD1.2§20.4
ContractCoverage = UI-LANDSCAPE|COVERED_BY_REVERSE_MIGRATION|OD1.2§20.5
ContractCoverage = UI-THEME-DETAIL|COVERED_BY_REVERSE_MIGRATION|OD1.2§20.6
ContractCoverage = UI-MODULE-READING|COVERED_BY_REVERSE_MIGRATION|OD1.2§20.7
ContractCoverage = UI-SOURCE-EVIDENCE|COVERED_BY_REVERSE_MIGRATION|OD1.2§20.9
ContractCoverage = UI-PAGE-STATE|COVERED_BY_REVERSE_MIGRATION|OD1.2§20.10
ContractCoverage = UI-DESKTOP-WEB|COVERED_BY_REVERSE_MIGRATION|OD1.2§20.11
DocumentationGapRecord = DOC-GAP-002|OPEN|UIUX_SPECIALTY_BODY_MISSING|NON_SCHEMA_CONTRACTS_ONLY
```

`DOC-GAP-002` 保持开放。本文只固化可追溯的非 Schema 契约，不声称替代缺失的
UI/UX 专项正文。
