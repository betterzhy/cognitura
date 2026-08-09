# Cognitive Knowledge Atlas V1 总体设计正式基线

- DesignVersion: `Cognitive-Knowledge-Atlas-Overall-Design-1.2`
- PreviousVersion: `Cognitive-Knowledge-Atlas-Overall-Design-1.1`
- SpecialtyDesignVersion: `Cognitive-Knowledge-System-Construction-Design-1.0`
- UIDesignVersion: `Cognitive-Knowledge-Atlas-UIUX-Design-1.0`
- Status: `FORMAL_BASELINE`
- PrimaryPurpose: `PERSONAL_COGNITIVE_STRUCTURE_BUILDING`
- KnowledgeBaseManagement: `OUT_OF_SCOPE`

## 1. 产品定位

本项目不是知识库、笔记工具、知识图谱平台或普通知识卡片 App。

> 面向个人阅读与学习的 AI 认知结构生成系统。系统基于一份或多份现有文档，生成相对客观、稳定、可逐层展开的知识主题体系，帮助用户在脑中建立从领域全景、主题主干、认知模块到具体知识元素的结构化知识。

核心结果不是保存了多少资料，而是用户能否快速看到领域全貌、理解主题关键性、沿稳定主线掌握模块，并知道具体知识点在整体体系中的位置。


## 1.1 专项设计回迁结论

《认知知识体系构造与生成契约设计》已经完成六项 P0 专项设计并通过：

```text
KnowledgeHierarchyRules = PASS
CognitiveOutputContract = PASS
GenerationPipelineContract = PASS
CognitiveDensityPolicy = PASS
RevisionRegenerationPolicy = PASS
GoldenCaseQualityGate = PASS
RemainingP0 = 0
```

本版本已经应用 `RM-01～RM-11` 全部 Reverse Migration，专项设计成为以下内容的正式细化来源：

- Theme / Module / Element 层级判定与升降级；
- 多文档归并与唯一主归属；
- UnderstandingRoute；
- 十项认知输出契约；
- 分阶段生成与 LLM Schema；
- 认知密度和 Renderer 选择；
- 用户修订与局部重生成；
- 质量门禁和三份 Golden Case。

总体设计保留产品级原则、范围与跨专项一致性；字段级 Schema、生成阶段输入输出、质量检查细则，以专项设计为权威来源。



## 1.2 输出与页面交互专项回迁结论

《认知知识体系输出与页面交互设计》已经完成页面信息架构、核心用户流程、Skeleton Review、Landscape、Theme、Module Reading、Renderer、Source Evidence、页面状态和 MVP 页面契约设计。

```text
PageInformationArchitecture = PASS
CoreUserFlow = PASS
SkeletonReviewDesign = PASS
LandscapeDesign = PASS
ThemeDetailDesign = PASS
ModuleReadingDesign = PASS
RendererComponentDesign = PASS
SourceEvidenceDesign = PASS
MVPPageContract = PASS
RemainingUIP0 = 0
```

结合后续正式范围裁决，V1 交付平台进一步收敛为：

```text
DeliveryPlatform = WEB_BROWSER
PrimaryExperience = DESKTOP_WEB

NativeIOSApp = OUT_OF_SCOPE
NativeAndroidApp = OUT_OF_SCOPE
HybridApp = OUT_OF_SCOPE
DedicatedMobileExperience = DEFERRED

BasicResponsiveSafety = REQUIRED
MobileWebFeatureParity = NOT_REQUIRED
```

本版本应用 `UI-RM-01～UI-RM-10` 以及 `UI-SCOPE-RM-01～UI-SCOPE-RM-05`。UI/UX 专项成为页面职责、组件契约、交互状态和布局规则的正式细化来源；总体设计保留跨专项边界、V1 平台范围和 MVP 优先级。


## 2. 核心目标

```text
原始文档
→ 领域全景
→ 知识主题体系
→ 主题主干
→ 认知模块
→ 知识元素
→ 核心理解路径
→ 脑中形成结构化知识
```

核心原则：

- `HierarchyFirst`：优先表达稳定知识层级；
- `CognitiveClosure`：以认知闭环划分模块；
- `KnowledgeDensity`：高密度不等于文字多，而是结构、关系和边界完整；
- `SourceFaithfulness`：关键认知可追溯到来源；
- `CanonicalStructureStable`：知识结构由知识本身决定，不由用户水平决定；
- `ProgressiveDisclosure`：同一结构提供全景、快速理解和深度理解三档展开。

## 3. 当前非目标

V1 不负责：

- 个人知识库治理；
- 长期知识资产管理；
- Claim 生命周期和复杂可信度治理；
- 跨 Workspace 全局知识图谱；
- 多人协作和知识社区；
- 个性化初学者/高级用户知识树；
- 学习计划、记忆曲线、间隔重复；
- 自由画布和复杂节点连线；
- 自动把所有文档外知识补齐；
- 自动全面联网校验所有事实；
- 原生 iOS App、原生 Android App 或 Hybrid App；
- V1 专用移动端产品体验和移动端功能等价；
- 移动端复杂结构拖拽、MERGE、SPLIT 和大范围 MOVE。

未来可以单向导出认知结构，作为个人知识库输入，但当前不考虑双向同步和知识库治理。

## 4. 核心不变量

```text
CanonicalKnowledgeStructureIsUserIndependent = YES
UserLevelAffectsCanonicalStructure = NO
ReadingDepthMayChangePresentation = YES
ReadingDepthMayChangeKnowledgeStructure = NO

PrimaryNavigation = HIERARCHY
PrimaryReadingUnit = COGNITIVE_MODULE
KnowledgeCardIsCoreObject = NO

StructureBeforeDeepGeneration = YES
ConfirmedStructureCannotBeSilentlyChanged = YES

DocumentStructureMayBeReorganized = YES
SourceMeaningMayBeSilentlyChanged = NO
MissingKnowledgeMayBeSilentlyCompleted = NO

DeliveryPlatform = WEB_BROWSER
PrimaryExperience = DESKTOP_WEB
NativeAppInV1 = NO
DedicatedMobileExperienceInV1 = NO
BasicResponsiveSafetyRequired = YES
MobileFeatureParityRequired = NO
```

## 5. 四层认知结构

```text
L0 KnowledgeLandscape
└── L1 KnowledgeTheme
    └── L2 CognitiveModule
        └── L3 KnowledgeElement
```

### 5.1 KnowledgeLandscape

表达领域整体知识版图，回答：领域解决什么问题、由哪些关键主题构成、哪些是基础/核心/桥接/应用/扩展、主题依赖是什么、核心理解路径是什么。

### 5.2 KnowledgeTheme

一个相对独立的领域级主题，应满足：

- 能用一个主题核心问题概括；
- 包含多个认知模块，或承担显著领域职责；
- 与其他主题具有可解释边界；
- 能形成主题级认知收敛；
- 在整体版图中具有明确角色。

### 5.3 CognitiveModule

主要阅读和生成单位。围绕一至三个紧密相关核心问题，要求：

- 共享同一机制、规则体系或决策上下文；
- 可以形成唯一 `PrimaryCognitiveSpine`；
- 至少存在一个关键边界；
- 关键结论可追溯；
- 阅读后形成局部认知闭环。

### 5.4 KnowledgeElement

模块内部细粒度知识：

```text
CONCEPT
RULE
MECHANISM
STEP
DISTINCTION
BOUNDARY
EXAMPLE
PRACTICE
```

KnowledgeElement 默认不进入主导航。只有形成独立核心问题、独立主线和独立边界时，才升级为 CognitiveModule。

## 6. 层级升降级规则

```text
Element → Module
当该知识能够形成独立认知闭环

Module → Theme
当一个模块实际包含多个独立认知闭环，并承担领域级职责

Module → Element
当该模块脱离上级模块后无法独立理解

Theme → Module
当其缺少足够内部模块和主题级收敛，只是一个局部机制
```

硬约束：

- 不按原文标题机械生成 Theme 或 Module；
- 不按段落或名词数量生成知识点；
- 不允许一个知识正文复制到多个主层级位置；
- 每个 Module 必须有唯一主归属；
- 跨主题通过有限语义关系表达。

## 7. 主题与模块关键性

采用可解释角色：

```text
FOUNDATION
理解其他主题必需的基础结构或公共概念

CORE
解释领域核心问题的主要机制、规则或统一原理

BRIDGE
连接两个或多个重要主题，使整体知识体系连通

APPLICATION
将基础和核心知识用于判断、设计、实践或排查

EXTENSION
特殊场景、版本细节、底层实现和进一步深入
```

判定依据：

- `DependencyCentrality`
- `ExplanatoryPower`
- `ClosureContribution`
- `CrossThemeConnectivity`
- `PracticalImpact`

必须区分：

```text
StructuralImportance
知识在体系中的客观重要性

UnderstandingOrder
由知识依赖产生的推荐理解顺序

SourceCoverage
当前文档对该知识的覆盖程度
```


### 7.1 UnderstandingRoute

`UnderstandingRoute` 是基于知识客观依赖和结构角色生成的推荐认知顺序，不是个性化学习计划。

生成原则：

```text
FOUNDATION
→ CORE
→ BRIDGE
→ APPLICATION
→ EXTENSION
```

同时满足：

- 前置依赖优先；
- 对全局解释力高的模块优先；
- BRIDGE 用于连接不同主题；
- SourceCoverage 不改变结构角色，但可以显示来源缺口；
- 用户可以调整阅读顺序，但不能因此改变 CanonicalHierarchy；
- Route 是派生投影，不产生第二棵知识树。

## 8. Primary Cognitive Spine

每个 CognitiveModule 必须有一条稳定主线：

> 用户正确理解该模块时必须经过的最短认知路径。

```text
CognitiveModule
├── CoreThesis
├── PrimaryCognitiveSpine
├── SupportingFacets
├── CriticalBoundaries
└── SourceReferences
```

主线通常为 4～9 个顶层步骤。

### 技术机制

```text
目标问题
→ 参与对象
→ 输入
→ 核心处理
→ 状态或数据变化
→ 输出
→ 异常边界
```

### 规则体系

```text
分类依据
→ 统一规律
→ 类型划分
→ 判定过程
→ 易混区分
→ 规则应用
```

### 架构设计

```text
业务目标
→ 系统边界
→ 核心组件
→ 交互链路
→ 一致性与约束
→ 异常恢复
→ 设计权衡
```

### 问题解决

```text
现象
→ 问题分类
→ 证据采集
→ 原因定位
→ 方案选择
→ 处理
→ 验证
```

若一个 Module 无法形成唯一主线，必须触发拆分、合并或边界复查。

## 9. 模块认知闭环

底层质量检查使用：

```text
WHY
WHAT
HOW
RELATION
BOUNDARY
APPLY
```

V1 不要求界面机械生成六个栏目。最低发布标准：

```text
CoreThesisRequired = YES
PrimaryCognitiveSpineRequired = YES
CriticalBoundaryRequired = YES
EvidenceCoverageRequired = YES
```

## 10. 认知密度与压缩

### 10.1 领域全景

- 核心主题：3～9 个；
- 必须掌握主题：3～7 个；
- 顶层主关系：不超过 12 条；
- 一个领域核心结论；
- 一条核心理解路径。

### 10.2 主题层

- 核心模块：2～7 个；
- 扩展模块默认折叠；
- 主题核心问题：1～3 个；
- 必须形成主题级认知收敛。

### 10.3 模块层

- `CoreThesis`: 1 个；
- `CoreQuestions`: 1～3 个；
- `SpineSteps`: 4～9 个；
- `CriticalBoundaries`: 1～5 个；
- `KeyTakeaways`: 3～7 个；
- `PrimaryRelations`: 1～5 个。

## 11. 三档阅读深度

三档阅读深度是同一知识结构的不同投影。

### Panorama

显示领域核心目标、关键主题、主题角色、主要依赖、核心路径和关键缺口。

### Quick Understanding

显示 CoreThesis、模块重要性、PrimaryCognitiveSpine、CriticalBoundary、前置和后续模块。

### Deep Understanding

显示完整 Facet、KnowledgeElement、分类、对比、例外、示例、实践、来源和可选扩展。

## 12. 关系模型

V1 只支持：

```text
DEPENDS_ON
EXPLAINS
CONTRASTS_WITH
APPLIES_TO
IMPACTS
```

每个 Theme 和 Module 必须有唯一 `primaryParent`，不使用模糊的 `RELATED_TO`。

## 13. 来源约束与认知重构

系统允许：

```text
SourceNarrativeOrder
→ CognitiveSpineOrder
```

允许转换：

```text
DIRECT
REFORMULATED
MERGED
REORDERED
ABSTRACTED
SPLIT
BRIDGED
```

要求：

- 保留来源块、章节、页码和原始顺序；
- 重构不能改变事实、版本、条件和边界；
- 不能把相邻内容自动解释成因果；
- 不能为闭环静默补充缺失机制；
- 综合推断必须显式标记。

V1 默认：

```text
SourceFaithfulUnderstandingDefault = ON
ExternalVerificationDefault = OFF
SelectiveVerification = USER_TRIGGERED
```

## 14. 多文档归并

```text
DocumentSection
→ SectionUnderstanding
→ QuestionAndConceptCandidate
→ ModuleCandidate
→ ThemeCandidate
→ CrossDocumentMerge
→ CanonicalSkeleton
```

规则：

- 同义内容合并，保留多个来源；
- 补充内容进入同一 Module 的不同 Facet；
- 不同抽象层级，上层进入主线，细节进入深度层；
- 同一知识跨主题，保留唯一主归属，其他主题通过关系引用；
- 冲突内容保留冲突标识，不自动隐藏或裁决。

## 15. 主题级与领域级认知收敛

### ThemeClosure

```text
ThemeCoreQuestion
ThemeThesis
ModuleCooperation
ThemeSpine
CriticalDistinctions
ThemeBoundaries
ConnectionToOtherThemes
```

### LandscapeClosure

```text
LandscapeThesis
CoreThemes
ThemeRoles
CrossThemeSpine
KeyDependencies
GlobalBoundaries
UnderstandingRoute
```

完整认知包含：

```text
ModuleClosure
ThemeClosure
LandscapeClosure
```

## 16. ThemeModelDefinition

V1 提供：

- `SystemMechanismModel`
- `RuleSystemModel`
- `ArchitectureDesignModel`
- `ProblemSolvingModel`

ThemeModel 决定优先问题、候选结构、推荐 Facet、主线形式、Renderer 和质量检查规则。V1 支持自然语言受控调整，不建设完整自定义编辑器。

## 17. 生成流程

```text
1. SourceParsing
2. SectionUnderstanding
3. ConceptAndQuestionExtraction
4. ThemeCandidateGeneration
5. ModuleCandidateClustering
6. SkeletonQualityCheck
7. UserStructureConfirmation
8. ModuleDeepGeneration
9. ThemeClosureGeneration
10. LandscapeConvergence
11. Publication
```

采用两阶段生成：先 Skeleton 确认，再按主题深度生成。禁止整份文档一次性生成全部深度内容。

每个阶段必须保存：

```text
inputHash
promptVersion
model
sourceBlockRefs
structuredOutput
validationResult
generationStatus
retryCount
```

阶段性要求：

- `SourceParsing` 保留标题、段落、列表、表格、图片、页码和顺序；
- `SectionUnderstanding` 输出局部核心问题、概念、规则、机制、边界和候选关系；
- Skeleton 只消费 SectionUnderstanding 和必要来源摘要，不直接依赖整份长文一次生成；
- Module 只消费已确认边界、相关来源块、必要前置摘要和 ThemeModelDefinition；
- ThemeClosure 只消费已确认 Module；
- LandscapeConvergence 只消费 ThemeClosure 和跨主题关系；
- 任一阶段失败可以局部重试，不影响无关 Theme 和 Module；
- 输入 Hash、PromptVersion 和 SchemaVersion 未变化时，不重复生成。

## 18. 用户修订与局部重生成

V1 支持：

```text
RENAME
MOVE
MERGE
SPLIT
PIN
EXCLUDE
```

版本状态：

```text
DRAFT
CONFIRMED
PUBLISHED
```

要求：用户 PIN 优先；支持差异、撤销和恢复；结构变化只重新生成受影响范围；禁止无关主题整体重跑。

局部影响矩阵：

| 操作 | 最小重生成范围 |
|---|---|
| `RENAME` | 当前对象标题及直接引用摘要 |
| `MOVE` | 当前 Module、新旧 ThemeClosure、UnderstandingRoute |
| `MERGE` | 合并后的 Module、直接关系、所属 ThemeClosure |
| `SPLIT` | 新 Module、来源重新分配、直接关系、ThemeClosure |
| `PIN` | 不触发生成；后续生成不得覆盖 |
| `EXCLUDE` | 上级摘要、关系、ThemeClosure、UnderstandingRoute |

结构裁决必须记录为 `StructureDecision`，后续生成优先遵守用户已确认的裁决。

## 19. 正式认知产物契约

专项设计已经正式定义十项 V1 契约：

```text
KnowledgeSkeleton
KnowledgeTheme
CognitiveModule
PrimaryCognitiveSpine
KnowledgeElement
ThemeClosure
LandscapeClosure
EvidenceReference
StructureAmbiguity
QualityAssessment
```

总体设计约束如下：

### 19.1 KnowledgeSkeleton

必须表达：

- `landscapeThesis`
- Theme 候选及其 `coreQuestion`
- Module 候选及主归属
- 主题和模块角色
- 有限语义关系
- `understandingRoute`
- 结构歧义和推荐方案
- SourceCoverage

### 19.2 CognitiveModule

必须包含：

```text
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

核心发布字段不得为空：

```text
thesis
primaryCognitiveSpine
criticalBoundaries
sourceRefs
```

### 19.3 ThemeClosure

必须说明：

- Theme 核心问题与统一结论；
- Module 如何协作；
- Theme 主线；
- 关键区别；
- Theme 边界；
- 与其他 Theme 的连接。

### 19.4 LandscapeClosure

必须说明：

- 领域统一结论；
- 核心 Theme 及角色；
- 跨主题认知主线；
- 关键依赖；
- 全局边界；
- UnderstandingRoute。

### 19.5 EvidenceReference

每个关键结论至少关联一个来源引用。引用必须可以回到：

- `SourceDocument`
- `DocumentBlock`
- 章节路径
- 页码或顺序
- 表格、图片或正文块
- 原始内容摘要

### 19.6 StructureAmbiguity

只有存在真实结构歧义时生成，必须包含：

- 歧义位置；
- 推荐结构；
- 局部备选；
- 推荐理由；
- 各方案对认知闭环的影响。

不得为形式完整而生成多棵完整候选树。

### 19.7 QualityAssessment

必须覆盖：

```text
HierarchyCorrectness
GranularityFitness
CognitiveClosure
SpineCoherence
ImportanceAccuracy
SourceFaithfulness
CompressionEfficiency
```

字段级 JSON Schema、required/optional、枚举、约束和示例，以
`Cognitive-Knowledge-System-Construction-Design-1.0`
为正式 Schema Source。

## 20. 表达形式选择

```text
分类体系 → Hierarchy / Matrix
工作机制 → Flow / StageChain
规则体系 → DecisionPath / RuleTable
状态变化 → StateTransition
对比知识 → ComparisonMatrix
因果知识 → CausalChain
架构知识 → LayeredStructure / InteractionFlow
问题解决 → Symptom-Cause-Solution-Validation
综合主题 → ModuleCooperationSpine
单一概念 → StructuredPanel
```

系统不强制使用卡片。


## 20.1 V1 页面设计总原则

```text
HierarchyFirst = YES
PrimarySpineVisuallyDominant = YES
ProgressiveDisclosure = YES
SourceTraceabilityVisible = YES

ComplexFreeCanvas = NO
CardOnlyLayout = NO
UnboundedNodeGraph = NO
TraditionalAdminTableAsPrimaryExperience = NO
```

页面首先表达认知结构，而不是管理数据。页面层级、间距、标题、路径和有限关系应优先于大量卡片边框和装饰性图形。

## 20.2 页面信息架构

V1 正式页面地图：

```text
WorkspaceList
└── WorkspaceCreate
    ├── DocumentUpload
    ├── DocumentParsingStatus
    ├── ThemeModelSelection
    └── SkeletonReview
        └── LandscapeOverview
            └── ThemeDetail
                └── ModuleReading
                    └── SourceEvidence

辅助入口：
StructureRevision
GenerationHistory
```

页面职责：

| 页面 | 核心职责 |
|---|---|
| `WorkspaceList` | 查看和进入已有认知工程 |
| `WorkspaceCreate` | 创建 Workspace，建立文档集合 |
| `DocumentUpload` | 上传 DOCX 等来源文件 |
| `DocumentParsingStatus` | 查看解析、分段、表格和图片处理状态 |
| `ThemeModelSelection` | 选择系统内置整理模型或进行受控调整 |
| `SkeletonReview` | 审核 Theme / Module 层级并完成结构裁决 |
| `LandscapeOverview` | 建立领域整体认知 |
| `ThemeDetail` | 展示 ThemeClosure 和 Module 协作 |
| `ModuleReading` | 沿 PrimaryCognitiveSpine 深度阅读 |
| `SourceEvidence` | 查看原始来源并返回认知位置 |
| `StructureRevision` | 查看差异、影响范围并执行局部重生成 |
| `GenerationHistory` | 查看阶段运行、失败位置和局部重试记录 |

## 20.3 核心用户流程

### 首次生成

```text
创建 Workspace
→ 上传文档
→ 查看解析状态
→ 选择或确认 ThemeModel
→ 生成 KnowledgeSkeleton
→ Skeleton Review
→ 确认 CognitiveStructureRevision
→ 生成首个 Theme
→ Landscape Overview
→ Theme Detail
→ Module Reading
```

### 结构修订

```text
发现结构歧义或不合理边界
→ RENAME / MOVE / MERGE / SPLIT / PIN / EXCLUDE
→ 查看影响范围
→ 局部重生成
→ 比较 Revision
→ 确认或撤销
```

### 知识阅读

```text
Landscape
→ Theme
→ Module
→ KnowledgeElement / Boundary / Relation
→ SourceEvidence
→ 返回原认知位置
```

### 阅读深度

```text
Panorama
→ Quick Understanding
→ Deep Understanding
```

阅读深度仅改变信息展开程度，不得改变 Theme、Module、Role、PrimaryCognitiveSpine 或结论。

## 20.4 Skeleton Review 页面契约

Skeleton Review 是 V1 最重要的生产页面，只审核认知结构，不要求用户同时审核大量深度正文。

桌面布局：

```text
左侧：
Theme / Module 稳定层级

中间：
当前 Theme 或 Module
- coreQuestion
- role
- 聚合理由
- 主归属
- sourceCoverage
- candidate spine
- 来源范围

右侧：
StructureAmbiguity
- 推荐结构
- 局部备选
- 风险与影响范围
- 结构操作
- 局部重生成
```

必须支持：

```text
RENAME
MOVE
MERGE
SPLIT
PIN
EXCLUDE
```

交互约束：

- 拖拽可以作为快捷操作，但必须提供菜单或命令式替代入口；
- MERGE 和 SPLIT 前必须显示来源重分配、关系变化、ThemeClosure 和 UnderstandingRoute 影响；
- PIN 后，AI 不得在后续重生成中覆盖该结构裁决；
- 不建议升级为 Theme/Module 的内容，应明确显示其 KnowledgeElement 归属理由；
- 未处理的中高风险 StructureAmbiguity 必须在确认前可见；
- 不得通过生成多棵完整知识树增加用户比较负担。

完整结构编辑仅要求桌面浏览器支持。

## 20.5 Landscape Overview 页面契约

Landscape 不是 Theme 列表，而是领域级认知收敛页面。

必须表达：

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

页面原则：

- 默认首屏优先显示领域结论、核心 Theme 和 UnderstandingRoute；
- FOUNDATION、CORE、BRIDGE、APPLICATION、EXTENSION 使用克制且统一的角色标记；
- 扩展 Theme 默认折叠；
- 关系仅呈现主依赖和关键连接，不使用自由节点画布；
- 用户可以直接理解“为什么先看这个 Theme”；
- 点击 Theme 进入 ThemeDetail，并保留返回全景的上下文。

建议桌面结构：

```text
顶部：
LandscapeThesis + 来源覆盖摘要

主体：
核心 Theme 层级与角色

下方：
UnderstandingRoute + CrossThemeSpine

辅助区域：
GlobalBoundaries + KnownGaps
```

## 20.6 Theme Detail 页面契约

ThemeDetail 必须形成 ThemeClosure，不能只列出 Module。

必须表达：

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

页面要求：

- ThemeSpine 是主体认知路径；
- Module 以其在 Theme 中的职责和协作关系呈现；
- BRIDGE Module 应明确说明连接了哪些主题或模块；
- 关键区别优先使用 Matrix 或 Comparison；
- Module 阅读完成后，应可以回到 ThemeClosure 再次收敛整体认知。

## 20.7 Module Reading 页面契约

ModuleReading 是 V1 的核心学习页面。

桌面端正式布局以 Reading First 为默认。KnowledgeHierarchy 的层级定位始终保留，
但来源、关系和缺口治理能力不得作为默认常驻侧栏挤压连续认知正文：

```text
PrimaryPresentationModel = INTERACTIVE_COGNITIVE_DOCUMENT
PrimaryExperienceModel = READING_FIRST
PureUnstructuredLongArticle = FORBIDDEN
StructuredContinuousCognitiveNarrative = REQUIRED_WHEN_NEEDED

ModuleReadingDefaultPersistentSidePanel = 0
KnowledgeHierarchyOrientation = RETAINED
QuickSourcePanel = ON_DEMAND_TRANSIENT
FullSourceEvidence = ON_DEMAND_WORKSPACE_OR_ROUTE
RelatedModules = INLINE_OR_ON_DEMAND
KnownGaps = INLINE_WHEN_UNDERSTANDING_CHANGES
DefaultReadingPersistentPrimaryActionsPerPage <= 2
```

默认视口由保留层级定位的阅读导向、中间连续认知正文和按需交互表面组成。完整
SourceEvidence、关系 Workspace 与修订 Workspace 只在用户显式进入时打开；
RelatedModules 与真正改变理解的 KnownGaps 在正文内或按需入口呈现。

ModuleHeader 必须包含：

```text
title
role
thesis
sourceCoverage
primaryRelations
readingDepth
```

页面核心顺序：

```text
CoreThesis
→ PrimaryCognitiveSpine
→ 适配当前知识形态的 Renderer
→ CriticalBoundaries
→ KnowledgeElements
→ Relations
→ SourceReferences
```

要求：

- CoreThesis 是第一认知入口；
- PrimaryCognitiveSpine 在视觉上必须高于辅助 Facet；
- Facet 和细粒度 Element 默认折叠或按需展开；
- CriticalBoundary 不得被隐藏在页面末尾或弱化为普通备注；
- 页面不得退化为无结构连续长文；为形成认知闭环所需的结构化连续叙事必须保留；
- 来源部分完整、存在缺口或使用综合重构时必须显示轻量状态；
- 点击 RelatedModule 必须保留其在主层级中的位置和返回路径。

## 20.8 Renderer 组件体系

V1 正式 Renderer：

```text
HierarchyRenderer
MatrixRenderer
StageChainRenderer
DecisionPathRenderer
StateTransitionRenderer
ComparisonRenderer
CausalChainRenderer
LayeredStructureRenderer
StructuredPanelRenderer
```

统一输入能力：

```text
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

通用约束：

- Renderer 不建立独立知识事实，只投影 CognitiveModule 内容；
- 主要节点数量超出认知密度上限时必须分组、折叠或拆成阶段；
- 支持节点展开详情和来源标记；
- 不允许为了图形美观改变认知顺序或语义关系；
- 大型 Matrix、LayeredStructure 和 StateTransition 以桌面浏览器为正式验收环境；
- 窄屏仅保证可读取、横向滚动或纵向降级，不要求功能等价。

稳定呈现预算与事实边界：

```text
PrimaryVisualPrimitiveFamiliesPerModule <= 4
PrimaryVisualProjectionPerCognitiveSection <= 1
SimultaneouslyEmphasizedVisualObjects <= 7
RendererCreatesIndependentFacts = NO
```

以上预算只限制同一认知段和默认视口中的高显著性呈现；Renderer 仍只投影
CognitiveModule 的正式内容，不得因布局、交互或视觉需要补写第二套事实。

## 20.9 Source Evidence 交互

ModuleReading 默认只提供轻量来源入口。快速核验使用按需临时面板，完整核验使用
按需 Workspace 或独立路由；两者都必须保留当前层级位置、认知对象和返回路径，
不得恢复默认常驻治理右栏。

```text
QuickSourcePanel = ON_DEMAND_TRANSIENT
FullSourceEvidence = ON_DEMAND_WORKSPACE_OR_ROUTE
```

必须支持：

- 文档名称；
- 章节路径；
- 页码或顺序；
- DocumentBlock 类型；
- 原始段落；
- 表格；
- 图片与图注；
- 当前认知内容使用了哪些来源；
- 一个来源支持哪些 Module 或 Element；
- `SOURCE_EXPLICIT` 与 `SOURCE_SYNTHESIZED` 的区分；
- 缺口和推断标记；
- 返回原 Module、SpineStep 或 Element。

SourceEvidence 不能成为独立知识库检索页面；其职责是支撑理解和追溯。

## 20.10 页面状态与错误模型

页面必须支持：

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

错误信息必须说明：

- 失败阶段；
- 已完成内容；
- 当前仍可使用的结果；
- 最小重试范围；
- 是否会重新调用模型；
- 结构变化是否使旧 Module 过期。

局部失败不得阻断无关 Theme 和 Module 的阅读。

## 20.11 Web-Only 与响应式边界

V1 正式平台：

```text
DeliveryPlatform = WEB_BROWSER
PrimaryExperience = DESKTOP_WEB
```

桌面浏览器承担：

- 完整 Skeleton Review；
- RENAME / MOVE / MERGE / SPLIT / PIN / EXCLUDE；
- Reading First ModuleReading 默认布局（保留层级定位，SourceEvidence 按需打开）；
- 完整 Renderer；
- 来源对照；
- Revision 影响分析。

V1 不实现：

```text
NativeNavigation
BottomTabBar
MobileGestureSystem
OfflineReading
PushNotification
NativeShare
DeepLink
AppInstallation
IOSAndroidPermission
NativeFileImport
MobileSpecificSkeletonEditing
```

基础响应式仅保证：

- 窄屏下文本和主路径可阅读；
- 不发生严重布局溢出；
- Landscape、Theme、Module 可按顺序线性查看；
- SourceEvidence 可使用 Overlay；
- 对复杂结构编辑明确提示使用桌面浏览器。

```text
ResponsiveSafety = REQUIRED
DedicatedMobileExperience = DEFERRED
MobileFeatureParity = NOT_REQUIRED
```


## 21. 质量评价与 Golden Cases

评价维度：

```text
HierarchyCorrectness
GranularityFitness
CognitiveClosure
SpineCoherence
ImportanceAccuracy
SourceFaithfulness
CompressionEfficiency
```

硬失败条件：

- 直接复制原文目录；
- 一个机制拆成大量孤立模块；
- 核心模块没有唯一主线；
- 核心知识没有上级归属；
- Module 只有定义没有边界；
- 关键结论没有来源；
- 文档缺口被静默补齐；
- Theme 只是 Module 列表，没有 ThemeClosure；
- 同一正文重复出现在多个 Theme。

质量门禁分为：

```text
RuleValidation
SchemaValidation
SourceReferenceValidation
GoldenCaseRegression
HumanSpotCheck
```

任一硬失败条件成立时，不允许发布。

Golden Case 使用统一结构：

```text
MustInclude
MustMerge
MustNotSplit
MustNotPromote
ExpectedRole
ExpectedSpine
ExpectedThemeClosure
KnownSourceGaps
```

### MySQL

必须跨锁、事务、数据行、Undo Log 等章节形成“事务可见性与幻读控制”等闭环模块。
MVCC、Read View 字段、隐藏列或单个锁类型不得全部提升为独立一级模块。

### Redis

必须将事件循环、客户端输出缓冲、Pending Writes、beforeSleep、写事件兜底和 IO 多线程边界聚合为“请求处理与高性能线程模型”。
`beforeSleep` 明确属于 `MustNotPromote`。

### 英语

必须将五大句型组织为统一规则体系，突出：

```text
谓语动词类型
→ 必要成分
→ 五大句型
→ 判定路径
→ SVOO / SVOC 辨析
```

大量例句不得生成独立 Module 或主导航节点。

## 22. V1 技术架构

采用模块化单体：

```text
server/
├── source
├── cognition
├── generation
├── reading
└── llm

web/
├── workspace
├── document-ingestion
├── structure-review
├── landscape
├── theme
├── module-reading
├── source-evidence
├── generation-status
└── revision-history
```

推荐 Java 21、Spring Boot、PostgreSQL、JSONB、对象存储、React + TypeScript、LLM Provider Adapter 和 JSON Schema。

前端正式交付形态为 Desktop Web。V1 不建立 iOS、Android 或 Hybrid App 工程。

V1 不引入微服务、Kafka、Neo4j、Elasticsearch。

## 23. V1 物理核心对象

```text
Workspace
SourceDocument
DocumentBlock
CognitiveStructureRevision
CognitiveModuleRevision
EvidenceReference
GenerationRun
```

复杂概念简化为 JSON 内部结构：Claim → assertions[]；Gap → gaps[]；Bridge → relation 的 origin/riskLevel；Verification → assertion 可选字段；GoalView → 运行时投影。

## 24. MVP 实施波次

### Wave 0

仓库、AGENTS.md、总体和专项设计、JSON Schema、Golden Case、测试与 CI；落地 UI/UX 页面契约、Renderer 输入契约和 Desktop Web 平台边界。

### Wave 1

DOCX、DocumentBlock、标题/段落/列表/表格/图片引用/页码、来源预览。

### Wave 2

SectionUnderstanding、Theme/Module Candidate、SkeletonGeneration、Skeleton Review 页面、StructureRevision 和局部结构操作。

### Wave 3

CoreThesis、PrimaryCognitiveSpine、CriticalBoundary、KnowledgeElement、EvidenceMapping、
Reading First ModuleReading 默认布局（保留层级定位）和按需 SourceEvidence。

### Wave 4

ThemeClosure、LandscapeClosure、Panorama、Quick Understanding、UnderstandingRoute、LandscapeOverview、ThemeDetail 和核心 Renderer。

### Wave 5

结构化问答、选择性外部校验、增量影响分析、自然语言 ThemeModel 调整。

## 25. 第一里程碑

```text
上传一份 DOCX
→ 解析 DocumentBlock
→ 生成知识骨架
→ 用户确认
→ 选择一个 Module
→ 生成 CoreThesis、PrimaryCognitiveSpine、CriticalBoundaries、KnowledgeElements、Relations、SourceReferences
→ Desktop Web 页面展示
   - Skeleton Review
   - Module Reading
   - Source Evidence
```

验收目标：对 MySQL、Redis 和英语三类文档，生成结果在知识组织、整体理解和模块闭环上明显优于原目录与普通摘要。

## 26. Codex 落地

```text
knowledge-atlas/
├── AGENTS.md
├── README.md
├── docs/
│   ├── 00-overall-design.md
│   ├── 01-knowledge-hierarchy-and-theme-system.md
│   ├── 02-cognitive-output-contract.md
│   ├── 03-generation-pipeline-and-llm-schema.md
│   ├── 04-cognitive-density-and-rendering.md
│   ├── 05-revision-and-local-regeneration.md
│   ├── 06-quality-evaluation-and-golden-cases.md
│   ├── 07-mvp-scope-and-implementation-waves.md
│   └── 08-ui-information-architecture-and-interaction.md
├── server/
├── web/
└── test-data/
```

进入 Codex 后必须避免退化为“文档切块 + 向量检索 + 普通 RAG + AI 摘要”。

## 27. Reverse Migration 应用记录

### 27.1 知识体系构造专项

```text
RM-01 = APPLIED
RM-02 = APPLIED
RM-03 = APPLIED
RM-04 = APPLIED
RM-05 = APPLIED
RM-06 = APPLIED
RM-07 = APPLIED
RM-08 = APPLIED
RM-09 = APPLIED
RM-10 = APPLIED
RM-11 = APPLIED
```

```text
AppliedKnowledgeReverseMigration = 11/11
```

### 27.2 输出与页面交互专项

```text
UI-RM-01 = APPLIED
页面信息架构

UI-RM-02 = APPLIED
核心用户流程

UI-RM-03 = APPLIED
Skeleton Review 契约

UI-RM-04 = APPLIED
Landscape 页面契约

UI-RM-05 = APPLIED
Theme Detail 页面契约

UI-RM-06 = APPLIED
Module Reading 页面契约

UI-RM-07 = APPLIED
Renderer 组件体系

UI-RM-08 = APPLIED
Source Evidence 交互

UI-RM-09 = APPLIED
页面状态与错误模型

UI-RM-10 = APPLIED
MVP 页面范围
```

```text
AppliedUIReverseMigration = 10/10
```

### 27.3 Web-Only 平台范围修订

```text
UI-SCOPE-RM-01 = APPLIED
DeliveryPlatform 修订为 WEB_BROWSER

UI-SCOPE-RM-02 = APPLIED
Desktop Web 成为 V1 唯一正式体验

UI-SCOPE-RM-03 = APPLIED
Responsive Design 降级为基础布局安全

UI-SCOPE-RM-04 = APPLIED
原生 App 和专用移动端体验延后

UI-SCOPE-RM-05 = APPLIED
删除移动端功能等价性验收
```

```text
AppliedPlatformScopeMigration = 5/5
AppliedReverseMigration = 26/26
ReverseMigrationDecision = PASS
```

### 27.4 HF-DG1 Reading First 呈现细化

本次只对已回迁的 `UI-RM-06`、`UI-RM-07`、`UI-RM-08` 作显式呈现细化，
不新增历史迁移项，不改变 `AppliedReverseMigration = 26/26`：

```text
HF-DG1-REFINEMENT-01 = READING_FIRST_DEFAULT_PRESENTATION_COORDINATED
HF-DG1-REFINEMENT-02 = SOURCE_EVIDENCE_ON_DEMAND_COORDINATED
HF-DG1-REFINEMENT-03 = RENDERER_PRESENTATION_BUDGET_AND_FACT_BOUNDARY_COORDINATED
HistoricalReverseMigrationCountChanged = NO
```

## 28. 当前正式状态

```text
OverallDesignVersion =
  Cognitive-Knowledge-Atlas-Overall-Design-1.2

PreviousOverallDesignVersion =
  Cognitive-Knowledge-Atlas-Overall-Design-1.1

SpecialtyDesignVersion =
  Cognitive-Knowledge-System-Construction-Design-1.0

UIDesignVersion =
  Cognitive-Knowledge-Atlas-UIUX-Design-1.0

ProductDirection = STABLE
PrimaryPurpose = PERSONAL_COGNITIVE_STRUCTURE_BUILDING
KnowledgeBaseScope = OUT_OF_SCOPE

CanonicalHierarchy = STABLE
PrimaryUnit = COGNITIVE_MODULE
UserLevelModel = NOT_REQUIRED

KnowledgeHierarchyRules = PASS
CognitiveOutputContract = PASS
GenerationPipelineContract = PASS
CognitiveDensityPolicy = PASS
RevisionRegenerationPolicy = PASS
GoldenCaseQualityGate = PASS

PageInformationArchitecture = PASS
CoreUserFlow = PASS
SkeletonReviewDesign = PASS
LandscapeDesign = PASS
ThemeDetailDesign = PASS
ModuleReadingDesign = PASS
RendererComponentDesign = PASS
SourceEvidenceDesign = PASS
MVPPageContract = PASS

DeliveryPlatform = WEB_BROWSER
PrimaryExperience = DESKTOP_WEB
NativeApp = DEFERRED
DedicatedMobileExperience = DEFERRED
BasicResponsiveSafety = REQUIRED
MobileFeatureParity = NOT_REQUIRED

AppliedKnowledgeReverseMigration = 11/11
AppliedUIReverseMigration = 10/10
AppliedPlatformScopeMigration = 5/5
AppliedReverseMigration = 26/26

RemainingDesignP0 = 0
RemainingUIP0 = 0
OverallDesignReverseMigration = PASS

DesignRepositoryLandingReady = YES
FrontendCodexLandingReady = YES
DirectFullImplementationStart = NO

NextStage =
  CODEX_REPOSITORY_LANDING_AND_WAVE0_PLANNING
```

总体设计 1.2 已完成知识体系构造专项、输出与页面交互专项以及 Web-Only 平台范围的正式回迁。

进入 Codex 后应先落地：

```text
总体设计和两份专项设计
JSON Schema Source
Golden Cases
页面契约和 Renderer 契约
AGENTS.md
测试与 CI 基线
Wave 0 实施计划
```

随后按 Wave 1～Wave 4 推进 Desktop Web 产品。不得并行启动原生 App、专用移动端体验或与当前认知目标无关的知识库能力。
