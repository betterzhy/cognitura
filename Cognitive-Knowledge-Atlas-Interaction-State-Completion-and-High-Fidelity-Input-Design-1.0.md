# Cognitive Knowledge Atlas V1 交互状态补齐与高保真输入设计

```text
DesignVersion =
  Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0

Status =
  FORMAL_SPECIALTY_BASELINE

CanonicalProjectName = Cognitura
HistoricalDesignName = Cognitive Knowledge Atlas V1
Product = Cognitura
DeliveryPlatform = WEB_BROWSER
PrimaryExperience = DESKTOP_WEB
V1Architecture = MODULAR_MONOLITH
BasicResponsiveSafety = REQUIRED
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
ReviewedPreparationSHA = 463fd4829e7c4bb8da071253e8ae9b15cee2a0cf
HF-DG4 FixedDesignReview = PASS
ReviewStage1 = gpt-5.6-sol/high|GO|P0=0|P1=0|P2=0
ReviewStage2 = gpt-5.6-sol/high|GO|P0=0|P1=0|P2=0
UltraReviewUsed = NO

PrimaryPurpose = PERSONAL_COGNITIVE_STRUCTURE_BUILDING

DesignPurpose =
  COMPLETE_THE_REMAINING_INTERACTION_STATE_CONTRACT,
  ESTABLISH_READING_FIRST_PRESENTATION,
  RESTRAIN_DEFAULT_INTERACTION_AND_VISUAL_DENSITY,
  AND_PROVIDE_THE_UNIQUE_INPUT_FOR_HIGH_FIDELITY_VISUAL_AND_USABILITY_DESIGN

PrimaryPresentationModel =
  INTERACTIVE_COGNITIVE_DOCUMENT

PrimaryExperienceModel =
  READING_FIRST

CanonicalHierarchy =
  KnowledgeLandscape
  → KnowledgeTheme
  → CognitiveModule
  → KnowledgeElement

HistoricalHierarchyAliases =
  DomainPanorama → KnowledgeLandscape projection
  Theme → KnowledgeTheme
  Module → CognitiveModule
  Element → KnowledgeElement

CanonicalRelationshipObject = Relation
RelationIsHierarchyLevel = NO

HighFidelityVisualAndUsabilityDesign = DEFERRED_TO_SEPARATE_HIGH_FIDELITY_STAGE
FrontendTechnologySelection = OUT_OF_SCOPE
FrontendImplementation = OUT_OF_SCOPE
ThirdRoundOverallLowFidelity = NOT_REQUIRED
```

---

## 0. 开始前正式核验与执行裁决

### 0.1 核验边界

本文件原始内容来自用户候选。HF-D00 依据当前 Repository、已批准整合规格与候选
实际正文完成身份和来源治理登记；后续合同裁决仍须逐卡通过 HF-DG1 至 HF-DG4。

```text
CurrentFormalFile =
  Cognitive-Knowledge-Atlas-
  Interaction-State-Completion-
  and-High-Fidelity-Input-Design-1.0.md

CurrentVersion = 1.0

DirectGitRepositoryAccess = YES

GitStatus =
  VERIFIED_ON_BRANCH_codex/high-fidelity-design-integration

CurrentArtifactCommitEvidence =
  UNTRACKED_USER_CANDIDATE_AT_HF_D00_START

RepositoryBaselineHead =
  23b75f63c9ff2dd1688b1ecc261d300581d667f8

RepositoryIntegrationStatus = UNTRACKED_CANDIDATE_REGISTERED_BY_HF_D00

VersionAction =
  MODIFY_1.0_IN_PLACE

AuditBasis =
  ACCESSIBLE_FORMAL_FILE_LIBRARY
  + CURRENT_1.0_ACTUAL_BODY
  + PREVIOUS_INTERACTION_STATE_BASELINE
  + SECOND_ROUND_LOW_FIDELITY_EVIDENCE
  + CURRENT_FORMAL_EXECUTION_INSTRUCTION
```

以上记录是 HF-D00 开始时的实际 Repository 观察值，不是正式候选审查证据。后续
本地提交和固定候选审查必须记录各自的新 SHA，不得沿用本起点 HEAD 冒充 reviewed
candidate。


### 0.1.1 本轮修改前检查结果

```text
CurrentFormalFile =
  Cognitive-Knowledge-Atlas-
  Interaction-State-Completion-
  and-High-Fidelity-Input-Design-1.0.md

CurrentVersion = 1.0

GitStatus =
  REPOSITORY_ACCESS_VERIFIED;
  CANDIDATE_UNTRACKED_AT_HF_D00_START;
  HF_D00_LOCAL_COMMIT_REQUIRED_AFTER_VALIDATION

CandidateInventoriedContracts =
  READING_FIRST_PRESENTATION
  + INTERACTIVE_COGNITIVE_DOCUMENT
  + ZERO_INTERACTION_READING
  + DOCUMENT_CONTINUITY
  + CARD_AND_CONTAINER_RESTRAINT
  + VISUAL_PRIMITIVE_BUDGET
  + INTERACTION_EXPOSURE_BUDGET
  + READING_VERIFICATION_REVISION_SEPARATION
  + UNIFIED_PROJECTION
  + PREVIEW_AND_PINNED_FOCUS
  + QUICK_AND_FULL_REVISION
  + POST_COMMIT_PROCESSING
  + DRAFT_PROTECTION

MissingStateMatrixItems =
  COMPLETE_HIGH_FIDELITY_INTERACTION_STATE_MATRIX
  + CLICK_CLOSE_AND_FOCUS_TRANSITION_MATRIX
  + COMPLETE_EXCEPTION_AND_RECOVERY_MATRIX
  + EXPLICIT_URL_HISTORY_REFRESH_BOUNDARY
  + BUDGET_MEASUREMENT_DEFINITIONS
  + STABLE_ID_READER_VISIBILITY_BOUNDARY
  + SECOND_ROUND_LOW_FIDELITY_ACCEPTANCE_TRACE

PrematureAcceptanceFields =
  RF_AC_RESULTS_WITHOUT_VALIDATION_STAGE
  + CROSS_DOMAIN_RESULTS_WITHOUT_EXPLICIT_CONTRACT_STAGE
  + HIGH_FIDELITY_READY_WORDING_THAT_COULD_BE_READ_AS_VISUAL_PASS

RequiredMinimalChanges =
  STATE_ACCEPTANCE_BOUNDARY_CORRECTION
  + COMPLETE_STATE_INPUT
  + COMPLETE_EXCEPTION_RECOVERY_INPUT
  + MEASUREMENT_DEFINITION
  + EXPORT_ID_BOUNDARY
  + TRACEABILITY_APPENDIX
  + FINAL_STATUS_NORMALIZATION

ForbiddenChanges =
  PAGE_INFORMATION_ARCHITECTURE
  + CANONICAL_HIERARCHY
  + RELATION_SEMANTIC_DICTIONARY
  + THIRD_ROUND_OVERALL_LOW_FIDELITY
  + LEARNING_REVIEW_PROGRESS_FEATURES
  + FRONTEND_TECHNOLOGY_SELECTION
  + FRONTEND_CODE
```

### 0.2 FormalAuthorityChain

```text
ProductPositioningAndCanonicalHierarchy =
  Cognitive-Knowledge-Atlas-Overall-Design-1.2
  UNTIL_THE_NEXT_UNIFIED_OVERALL_VERSION_IS_FORMALLY_REVERSE_MIGRATED

GenerationAndConstructionRules =
  Cognitive-Knowledge-System-Construction-Design-1.0
  AS_FORMALLY_REVERSE_MIGRATED_IN_THE_EFFECTIVE_OVERALL_BASELINE

CognitiveRelationshipAndPageStructure =
  HISTORICAL_INPUT_DECLARATION_ONLY_DOC_GAP_HF_001

CognitiveRelationshipExpressionAndInteraction =
  HISTORICAL_INPUT_DECLARATION_ONLY_DOC_GAP_HF_002

InteractionStateAndMultiViewConsistency =
  HISTORICAL_INPUT_DECLARATION_ONLY_DOC_GAP_HF_003

InteractionStateCompletionAndHighFidelityInput =
  THIS_DOCUMENT

ReadingFirstPresentationAndInteractionRestraint =
  THIS_DOCUMENT
```

```text
DocumentationGap = DOC-GAP-HF-001
MissingBody = Cognitive-Knowledge-Atlas-Cognitive-Relationship-and-Page-Structure-Design-1.0
Disposition = NOT_VERIFIED_AUTHORITY

DocumentationGap = DOC-GAP-HF-002
MissingBody = Cognitive-Knowledge-Atlas-Cognitive-Relationship-Expression-and-Interaction-Design-1.0
Disposition = NOT_VERIFIED_AUTHORITY

DocumentationGap = DOC-GAP-HF-003
MissingBody = Cognitive-Knowledge-Atlas-Interaction-State-and-Multi-View-Consistency-Design-1.0
Disposition = NOT_VERIFIED_AUTHORITY
```

三份正文在当前 Repository 中不存在，只保留为候选文件的历史输入声明。候选中已
完整写出的规则可以在对应 HF Gate 下审查，但不得伪称已从缺失正文核验。

HF-D01 的权威边界为：

```text
OverallDesign1_2Disposition = MINIMALLY_COORDINATED_PRODUCT_AUTHORITY
OverallDesign1_2BytesChangedByHFD01 = YES
Wave0OverallSourceManifestFingerprintRefreshedByHFD01 = YES
HistoricalAppliedReverseMigration26Of26Changed = NO
ReadingPresentationRefinementAuthority = THIS_SPECIALTY_UNDER_HF_DG1
PageAndRendererProjection = STABLE_NON_SCHEMA_REFINEMENT_ONLY
FormalSpecialtyPromotion = HF_DG4_FIXED_DESIGN_REVIEW_PASS
```

HF-D01 对 Overall 1.2 做了最小页面合同协调，并在同一卡原子刷新 Wave 0 source
manifest 中 Overall 的精确字节数与 SHA-256；它没有改变历史
`AppliedReverseMigration = 26/26`，也没有改写产品目标、正式层级或历史版本。本文档
在 `CONTRACT` 阶段对默认呈现做显式细化，页面与 Renderer 合同只投影该细化。

### 0.3 CurrentLatestFiles

| 权威范围 | 当前可核验最新文件 | 状态裁决 |
|---|---|---|
| 总体设计 | `Cognitive-Knowledge-Atlas-Overall-Design-1.2` | 当前可见的最新已落地总体基线；前序专项要求下一统一版本回迁全部新规则 |
| 知识体系构造 | `Cognitive-Knowledge-System-Construction-Design-1.0` | 继续有效；本轮不修改生成和构造规则 |
| 页面与关系结构 | Repository 中缺失 | `DOC-GAP-HF-001`；仅为候选历史输入声明 |
| 关系表达与交互 | Repository 中缺失 | `DOC-GAP-HF-002`；仅为候选历史输入声明 |
| 交互状态与多视图一致性 | Repository 中缺失 | `DOC-GAP-HF-003`；仅为候选历史输入声明 |
| 交互状态补齐与高保真输入 | `Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0` | HF-D00 登记的候选；正式晋级推迟到 HF-D04 |
| 第二轮低保真与评估 | Repository 中未发现独立正式 Markdown | 仅保留候选中的历史输入声明，不视为已核验权威 |

### 0.4 MissingFormalArtifactsAtInitialCreationAndCurrentClosure

```text
MissingBeforeInitial1_0Creation =
  Cognitive-Knowledge-Atlas-
  Interaction-State-Completion-
  and-High-Fidelity-Input-Design-1.0

CurrentFormalFileExists =
  NO

CurrentCandidateFileExists =
  YES

CurrentStateInputCompleteness =
  CANDIDATE_CONTENT_PRESENT_GATE_DEFERRED

IndependentReadingFirstAddendumRequired =
  NO

IndependentStateMatrixAddendumRequired =
  NO

ThirdRoundOverallLowFidelityRequired =
  NO
```

当前可见文件库未发现完成统一回迁后的下一总体设计版本，也未发现第二轮低保真评估的独立正式 Markdown。其影响如下：

1. 不阻止本文件成为 HF-D00 登记的唯一候选，但不得提前成为正式基线；
2. 下一统一总体设计版本必须一次性回迁全部 Reverse Migration Pack；
3. 不因缺少独立原型评估文件而重新制作第三轮整体低保真；
4. 高保真阶段必须使用本文件列出的局部状态证据补足可用性验证。

### 0.5 OutdatedStatusFields

`Cognitive-Knowledge-Atlas-Interaction-State-and-Multi-View-Consistency-Design-1.0` 中以下状态反映的是该文件封口时点，而不是当前项目进展：

```text
SecondRoundLowFidelityPrototypeRendered = NO
SecondRoundLowFidelityPrototypeAcceptance = NOT_RUN
HighFidelityVisualDesignReady = NO
```

本文件基于当前正式输入作出后续裁决：

```text
SecondRoundLowFidelityPrototype = HISTORICAL_INPUT_RECORDED

SecondRoundLowFidelityAssessment = HISTORICAL_DIRECTION_RECORDED_READING_FIRST_PATCH_REQUIRED

SecondRoundLowFidelityValidationStage =
  CONTRACT_AND_LOW_FIDELITY_DIRECTION_ACCEPTANCE

HighFidelityVisualValidation =
  NOT_RUN

RemainingInteractionStateP0 = HF_DG2_ORTHOGONAL_STATE_AND_RECOVERY_PASS

HighFidelityInputReady = CONTRACT_INPUT_COMPLETE

HighFidelityVisualDesign =
  NOT_RUN

HighFidelityVisualValidation =
  NOT_RUN
```

此裁决不修改旧文件的历史事实，只使旧状态不再代表当前项目最新状态。

### 0.6 ExistingAntiCardAndAntiGraphRules

现有正式设计已经包含：

```text
DashboardLikePanorama = FORBIDDEN
ThemeCardWall = FORBIDDEN
RelationshipOnlyGraphPage = FORBIDDEN
GlobalFreeKnowledgeGraph = OUT_OF_SCOPE
InfiniteCanvas = OUT_OF_SCOPE
PermanentRightSideRelationshipLists = SUPERSEDED
ReadingModeContainsGlobalGovernanceDashboard = HARD_FAILURE
SameShapeRectanglesForAllSemantics = SUPERSEDED
IndependentContentCopiesAcrossViews = FORBIDDEN
```

但这些规则仍可能被高保真实现误解为：

- 用大量不同形状组件替代同形卡片；
- 用多个局部面板拼成组件墙；
- 将核心正文隐藏在 Tab、Accordion、Popover 或右侧 Workspace；
- 为展示完整视觉语法而在同一页面使用全部原语；
- 将“禁止普通 Markdown 文章”误解为“禁止连续解释性正文”；
- 将底层交互能力全部暴露为默认控件。

### 0.7 RemainingReadingFirstGapsBeforeInitial1_0

```text
PrimaryPresentationModelNotExplicit = TRUE
ZeroInteractionCompletenessNotExplicit = TRUE
ContinuousNarrativeBoundaryNotExplicit = TRUE
CardContainerBudgetNotExplicit = TRUE
VisualPrimitiveDensityBudgetNotExplicit = TRUE
InteractionExposureBudgetNotExplicit = TRUE
ReadingAndGovernanceSeparationNotFullyOperationalized = TRUE
StaticImageMarkdownPdfProjectionBoundaryNotExplicit = TRUE
```

以上是初始 `1.0` 创建前的缺口记录。完成本轮后：

```text
CurrentRemainingReadingFirstGaps = 0
CurrentRemainingHighFidelityStateInputGaps = HF_DG3_EVIDENCE_INPUT_CONTRACT_PASS
ContractP0Remaining = HF_DG4_FIXED_DESIGN_REVIEW_PASS
```

### 0.8 PlannedMinimalPatchScope

本文件只完成：

1. 交互状态最后六项 P0 补齐；
2. 阅读优先总定位；
3. 零交互阅读完整性；
4. 连续文档叙事与结构投影职责；
5. 卡片、容器和视觉原语预算；
6. 默认交互控件暴露预算；
7. 四层页面呈现克制规则；
8. Web、静态图片、Markdown 与 PDF 的统一投影；
9. 局部高保真状态证据输入；
10. 高保真前硬门禁与 Reverse Migration Pack。

本文件不重新设计页面信息架构、Relation 语义、知识层级、生成管线或第二轮整体低保真布局。

---

## 1. 版本处理裁决

### 1.1 情况判定

当前 `1.0` 以未跟踪用户候选存在于实际 Git 工作树中。HF-D00 只对同一候选完成
治理规范化和独立登记，不把候选存在等同于正式来源或固定审查通过。

```text
VersionDecision =
  REGISTER_AND_NORMALIZE_EXISTING_UNTRACKED_1_0_CANDIDATE

CurrentVersion = 1.0
NewVersionCreated = NO
IndependentPatchAuthorityFile = FORBIDDEN
ParallelCandidateVersion = FORBIDDEN
ReadingFirstPatchRetained = YES
StateMatrixPatchAbsorbedInto1_0 = YES
```

### 1.2 版本关系

```text
PreviousInteractionStateBaseline =
  Cognitive-Knowledge-Atlas-
  Interaction-State-and-Multi-View-Consistency-Design-1.0

CurrentHighFidelityInputBaseline =
  Cognitive-Knowledge-Atlas-
  Interaction-State-Completion-
  and-High-Fidelity-Input-Design-1.0

Relationship =
  INHERITS_AND_COMPLETES
```

本文件不替代前序状态机和关系设计，而是在以下范围内更具体并优先：

- Preview 与 Pinned Focus；
- Element 与 Relation Focus 优先级；
- 快速修订与完整修订分流；
- 三类影响同屏和高风险默认展开；
- 提交后处理、部分失败、回退和撤销；
- 返回、重置、草稿与恢复；
- 默认阅读呈现；
- 控件、卡片、容器和视觉原语密度；
- 静态与可移植投影边界。

---

## 2. 保持不变的正式基线

本轮完整继承且不得重新设计：

```text
ProductGoal
HistoricalHierarchyCompositeAlias = DomainPanorama_Theme_Module_Element
PrimaryCognitiveSpine
CoreQuestionDrivenStructure
ThemeQuestionBoundary
ModuleCognitiveClosure
TypedElementExpression
RelationAsFirstClassObject
RelationSemanticsDirectionEvidenceAndVersion
L0_L1_L2_L3ProgressiveDisclosure
CurrentObjectCenteredExploration
OnePrimaryCognitiveFocus
ReadingVerificationRevisionModes
StableIdentityAcrossViews
UnifiedImpactPreview
CommitPropagationAndFreshness
DraftReturnResetAndRecovery
SecondRoundLowFidelityOverallLayout
```

以下方向继续废弃：

```text
DashboardAsPrimaryReading
ThemeCardWall
OrdinaryKnowledgeGraphWorkspace
PureMarkdownArticleTemplate
CardDragAsFormalRevision
ProgressAndMasteryFeatures
LearningPlan
SpacedRepetition
KnowledgeQuantityAsPrimaryInformation
```

### 2.1 ReadingFirstContract 的作用边界

```text
ReadingFirstContract
  DOES_NOT_SUPERSEDE
  CognitiveHierarchy
  RelationSemanticModel
  ProgressiveDisclosure
  LocalRelationFocus
  SourceVerification
  StructureRevision
  MultiViewIdentity
```

本文件只约束默认呈现和交互暴露，不删除已经正式成立的深层能力。

---

## 3. 正式总定位：Interactive Cognitive Document

### 3.1 正式枚举

```text
PrimaryPresentationModel =
  INTERACTIVE_COGNITIVE_DOCUMENT

PrimaryExperience =
  READING_FIRST

PrimaryReadingSurface =
  CONTINUOUS_DOCUMENT_FLOW

VisualStructureRole =
  EMBEDDED_COGNITIVE_PROJECTION

InteractionRole =
  OPTIONAL_COGNITIVE_DEEPENING

ImageRole =
  STATIC_PREVIEW_AND_EXPORT

MarkdownAndPdfRole =
  PORTABLE_READING_AND_ARCHIVE

CanonicalKnowledgeCarrier =
  STRUCTURED_OBJECT_AND_RELATION_MODEL

ImageAsCanonicalKnowledgeSource =
  FORBIDDEN
```

### 3.2 正式定义

Cognitive Knowledge Atlas 的 Web 页面首先是一份由正式认知结构驱动的可交互认知文档，而不是：

- 知识图谱浏览器；
- 卡片式知识库；
- 自由白板；
- 组件展示系统；
- 关系治理工作台；
- 学习进度或复习系统。

“可交互认知文档”同时具备：

1. 连续、可直接阅读的认知叙事；
2. 问题、结论、机制、条件、结果和边界的结构化排版；
3. 嵌入正文的有限认知投影；
4. 按需展开的局部关系；
5. 可定位到对象、陈述和 Relation 的来源核验；
6. 不破坏阅读上下文的结构修订；
7. 所有视图使用同一 Canonical Object 和 Relation。

### 3.3 默认体验顺序

```text
READ
→ ORIENT
→ UNDERSTAND
→ OPTIONAL_FOCUS
→ OPTIONAL_VERIFY
→ OPTIONAL_REVISE
```

不得将默认体验改为：

```text
OPEN_DASHBOARD
→ CHOOSE_WIDGET
→ OPEN_PANEL
→ SWITCH_TAB
→ FILTER_RELATIONS
→ FIND_THE_ACTUAL_EXPLANATION
```

---

## 4. 交互状态补齐契约

本章补齐进入高保真前最后六项交互 P0。

### 4.1 Preview 与 Pinned Focus

#### 4.1.1 状态定义

```text
PREVIEW =
  EPHEMERAL,
  NON_DESTRUCTIVE,
  NON_HISTORICAL,
  DOES_NOT_REPLACE_PRIMARY_FOCUS

PINNED_FOCUS =
  STABLE,
  EXPLICIT,
  HISTORY_RECOVERABLE,
  MAY_OPEN_SECONDARY_DETAIL
```

#### 4.1.2 Preview 允许显示

- 对象或 Relation 的短标题；
- 当前认知职责；
- 最重要一条 Relation；
- 来源或推断的轻量状态；
- 进入固定聚焦的明确操作。

Preview 不得：

- 替换当前已固定 Focus；
- 打开持久侧栏；
- 修改关系家族；
- 改变 Cognitive Perspective；
- 创建浏览器历史；
- 隐藏当前正文；
- 触发导航。

#### 4.1.3 Pinned Focus 触发

桌面：

- 单击对象并明确选择；
- 键盘确认；
- 从关系提示选择“固定查看”。

触控：

- 点击先进入稳定选择，不依赖 Hover；
- 长按只能提供 Preview 或上下文入口，不作为唯一方式；
- 所有 Hover 能力必须有触控等价路径。

键盘：

- `Tab` 或方向键移动可访问焦点；
- `Enter` 固定聚焦；
- `Escape` 关闭当前交互层并恢复上一级稳定状态；
- 不得要求鼠标悬停才能获得核心信息。

#### 4.1.4 视觉区分

```text
PreviewVisualWeight < PinnedFocusVisualWeight
PreviewDoesNotDimWholePage = YES
PinnedFocusMayDimNonCurrentContext = YES_BUT_RETAINS_ORIENTATION
ColorOnlyDistinction = FORBIDDEN
```

### 4.2 Element 与 Relation Focus 优先级

```text
PrimaryFocusCount = 1
ElementFocusAndRelationFocusEqualWeight = FORBIDDEN
RelationFocusReplacesElementAsPrimary = YES
RelationEndpointsRemainSecondaryContext = YES
ClosingRelationFocusRestoresOriginElementFocus = YES
```

状态转换：

```text
ELEMENT_PINNED
→ select relation
→ RELATION_FOCUSED
→ verify or revise
→ close
→ ELEMENT_PINNED_RESTORED
```

Relation Focus 时必须保留：

- 起点对象；
- 终点对象；
- 发起 Relation 的原 Element 或 Module；
- 当前 Primary Cognitive Spine 位置；
- 返回原阅读 Anchor。

不得同时将 Relation、起点、终点和原 Element 都渲染为相同最高视觉权重。

### 4.3 快速修订与完整修订分流

#### 4.3.1 快速修订 `QUICK_REVISION`

只允许低风险、局部、不会改变正式结构或主语义的操作：

```text
EDIT_WORDING_WITHOUT_SEMANTIC_CHANGE
EDIT_RATIONALE_WITHOUT_RELATION_CHANGE
ADD_MISSING_SOURCE_BINDING
REMOVE_INVALID_SOURCE_BINDING_WITHOUT_LOSING_REQUIRED_SUPPORT
CORRECT_SOURCE_LOCATION
CORRECT_TYPO_OR_LABEL
ADD_CLARIFYING_SCOPE_TEXT_WITHOUT_CHANGING_SCOPE
```

快速修订必须在当前 Focus 附近按需出现，不得形成常驻按钮组。

#### 4.3.2 完整修订 `FULL_REVISION`

以下任一操作必须进入完整修订：

```text
CHANGE_RELATION_TYPE
CHANGE_SUBJECT_OR_OBJECT
CHANGE_DIRECTION
CHANGE_PRIMARY_PARENT
CHANGE_PRIMARY_SPINE
CHANGE_THEME_OR_MODULE_BOUNDARY
CHANGE_CONDITION_OR_EFFECTIVE_SCOPE
PROMOTE_INFERENCE_TO_FORMAL
DEMOTE_FORMAL_RELATION
MERGE_OR_SPLIT_OBJECT
CHANGE_CORE_CONCLUSION
```

#### 4.3.3 自动升级规则

快速修订过程中，只要检测到：

- 语义真值改变；
- 条件或边界改变；
- 来源支持不足；
- Spine 或 Closure 可能变化；
- 锁定内容被触及；
- 对象或 Relation 身份可能变化；

系统必须：

```text
QuickRevisionAutoPromotedToFullRevision = YES
DraftPreserved = YES
UserIsToldWhy = YES
SilentPromotion = FORBIDDEN
```

### 4.4 三类影响同屏

完整修订必须同时提供：

```text
SemanticImpact
StructuralImpact
ExpressionImpact
```

高风险项规则：

```text
BLOCKER = EXPANDED_BY_DEFAULT
REVIEW_REQUIRED = EXPANDED_WHEN_DIRECTLY_RELEVANT
AUTO_REFRESH = COLLAPSED_SUMMARY_ALLOWED
INFORMATION = COLLAPSED
```

每项影响至少包含：

```text
impactCode
severity
whyItHappens
causalChain
canonicalTargets
projectionTargets
automaticAction
userDecisionRequired
```

禁止：

- 只显示受影响对象数量；
- 三类影响放在三个互斥 Tab 中导致用户无法同时判断；
- 隐藏高风险影响；
- 未解决 Blocker 时允许提交。

### 4.5 提交后四类处理状态

```text
IMMEDIATE_SYNC
  当前对象、Relation、直接阅读投影和当前 Workspace 立即读取新版本

RECOMPUTING
  Spine、Closure、问题映射或机制布局正在重新计算

LOCAL_REGENERATING
  受影响的局部解释、摘要或结构投影正在重新生成

PENDING_VERIFICATION
  新表达或新来源需要进一步核验
```

#### 4.5.1 成功路径

```text
CommitChangeSet
→ CreateNewCanonicalVersion
→ UpdateCurrentPointer
→ ImmediateSync
→ RecomputeAffectedStructures
→ LocalRegenerateAffectedProjections
→ ReverifyAffectedEvidence
→ ReturnToOriginalReadingContext
```

#### 4.5.2 部分失败

```text
CanonicalCommit = SUCCESS
ProjectionRefresh = PARTIAL_FAILURE

RequiredBehavior =
  EXPLICIT_STALE_MARK
  + RETRY
  + BEFORE_AFTER_DIFF
  + OPTIONAL_REVERT_CHANGESET
```

不得：

- 将已成功的正式提交伪装成未提交；
- 将旧 Projection 标记为最新；
- 在过期投影上继续无提示修订；
- 物理删除失败前版本。

#### 4.5.3 撤销

撤销已提交变更必须创建新的 `Revert ChangeSet`，保留原版本和完整历史。

### 4.6 返回、重置、草稿与恢复

#### 4.6.1 三类返回

```text
SOFT_BACK =
  close current interaction layer,
  restore previous focus and scroll

ROUTE_BACK =
  return to previous cognitive page,
  restore ContextReturnToken

HARD_RESET =
  clear local exploration and return to page default reading state
```

三者不得共用一个含义模糊的“返回”按钮。

#### 4.6.2 草稿状态

```text
NONE
CLEAN_DRAFT
DIRTY_DRAFT
SAVED_DRAFT
RECOVERABLE_DRAFT
CONFLICTED_DRAFT
```

存在 `DIRTY_DRAFT` 时离开必须提供：

- 保存草稿；
- 丢弃；
- 继续编辑。

不得静默保存为正式内容，也不得静默丢弃。

#### 4.6.3 恢复

刷新或重新进入时：

- 恢复稳定 Canonical Target；
- 恢复模式、Perspective、Relation Focus；
- 恢复可兼容的 Scroll Anchor；
- 恢复草稿；
- 若正式版本已变化，提示差异并进入 `CONFLICTED_DRAFT` 或重新基线化流程。

### 4.7 小屏与无障碍

小屏默认仍是阅读文档，不是缩小版桌面工作台。

```text
SmallScreenPrimarySurface = DOCUMENT_FLOW
PersistentSidePanelOnSmallScreen = FORBIDDEN
HoverOnlyInteraction = FORBIDDEN
HorizontalCanvasAsDefault = FORBIDDEN
CoreTextHiddenForSpace = FORBIDDEN
```

来源、关系和修订 Workspace 可采用临时全屏层，但必须保留：

- 当前对象；
- 返回来源；
- 原阅读 Anchor；
- 完整退出路径。

---

## 5. High-Fidelity Interaction State Matrix

### 5.0 矩阵适用规则

本矩阵是高保真视觉与可用性设计必须直接消费的唯一状态输入。前序流程图、低保真 Frame 和旧状态名称只能用于追溯，不得覆盖本矩阵。

```text
StateContractCompleteness = REQUIRED
StateNameOnly = FORBIDDEN
FlowArrowAsStateContractReplacement = FORBIDDEN
OnePrimaryCognitiveFocus = REQUIRED
CoreContentVisibilityIndependentFromState = REQUIRED
```

所有状态均使用以下统一字段：

```text
StateCode
Purpose
EntryCondition
ExitCondition
PrimaryFocus
SecondaryContext
VisualPriority
VisibleContent
AvailableActions
ForbiddenActions
PersistenceRule
URLHistoryRule
KeyboardBehavior
TouchBehavior
EmptyState
ErrorState
AccessibilityAnnouncement
HighFidelityEvidence
```

### 5.0.1 HF-DG2 正交快照与唯一分类

46 个历史 `StateCode` 继续保留逐项追溯，但不再被解释为一个互斥全局枚举。稳定
交互快照只由以下六个正交轴组成；流程阶段、导航事件、临时 UI 和派生结果均在轴外
单独表达。

```text
OrthogonalAxis = ModeAxis|READING,VERIFICATION,REVISION
OrthogonalAxis = FocusAxis|IDLE,ELEMENT_PINNED,RELATION_PINNED
OrthogonalAxis = AuxiliarySurfaceAxis|NONE,QUICK_SOURCE,FULL_VERIFICATION,FULL_REVISION
OrthogonalAxis = DraftAxis|NO_DRAFT,CLEAN_DRAFT,DIRTY_DRAFT,SAVED_DRAFT,RECOVERABLE_DRAFT,CONFLICTED_DRAFT
OrthogonalAxis = ProcessingAxis|PROCESSING_IDLE,IMPACT_ANALYZING,COMMIT_ALLOWED,COMMIT_BLOCKED,SUBMITTING,CANONICAL_SAVED,RECOMPUTING,PROJECTION_GENERATING,PENDING_VERIFICATION,PARTIAL_FAILURE,FAILED,COMPLETE
OrthogonalAxis = RecoveryAxis|STABLE,HISTORY_RESTORING,REFRESH_RESTORING,RESTORE_FAILED

HistoricalStateCode = GENERATING
LocalProjectionPhase = PROJECTION_GENERATING
StableProjectionParameter = CognitivePerspective|URL_AND_HISTORY|NOT_AN_ORTHOGONAL_AXIS
```

`ProcessingAxis.PROCESSING_IDLE` 与 `FocusAxis.IDLE` 分别表示处理空闲和无稳定对象
聚焦，禁止共享无命名空间的本地 `IDLE`。同理，历史 `GENERATING` 只作为本表的
原始追溯码；新投影流程一律使用 `PROJECTION_GENERATING`，不得与既有
`PageState.GENERATING` 或历史码碰撞。
`CognitivePerspective` 是可分享 URL 与稳定 Browser History 中恢复的 Projection
参数，因此使用 `AXIS_VALUE` 分类表达稳定取值；它不加入 `InteractionSnapshot` 的
六个正交主轴，也不构成第七主轴。

| OriginalStateCode | Classification | OwningAxisOrFlow | PersistenceBoundary | URLHistoryDisposition | CanonicalWriteBoundary |
|---|---|---|---|---|---|
| IDLE | AXIS_VALUE | FocusAxis:IDLE | URL | URL_AND_HISTORY | NO_CANONICAL_WRITE |
| INPUT_FOCUS | TRANSIENT_UI | InputFocusFlow | EPHEMERAL_UI | NOT_PERSISTED | NO_CANONICAL_WRITE |
| PREVIEW | TRANSIENT_UI | PreviewFlow | EPHEMERAL_UI | NOT_PERSISTED | NO_CANONICAL_WRITE |
| ELEMENT_PINNED_FOCUS | AXIS_VALUE | FocusAxis:ELEMENT_PINNED | BROWSER_HISTORY | URL_AND_HISTORY | NO_CANONICAL_WRITE |
| RELATION_PINNED_FOCUS | AXIS_VALUE | FocusAxis:RELATION_PINNED | BROWSER_HISTORY | URL_AND_HISTORY | NO_CANONICAL_WRITE |
| QUICK_SOURCE_PANEL | AXIS_VALUE | AuxiliarySurfaceAxis:QUICK_SOURCE | EPHEMERAL_UI | NOT_PERSISTED | NO_CANONICAL_WRITE |
| FULL_VERIFICATION_WORKSPACE | AXIS_VALUE | AuxiliarySurfaceAxis:FULL_VERIFICATION | BROWSER_HISTORY | URL_AND_HISTORY | NO_CANONICAL_WRITE |
| READING_MODE | AXIS_VALUE | ModeAxis:READING | URL | URL_AND_HISTORY | NO_CANONICAL_WRITE |
| VERIFICATION_MODE | AXIS_VALUE | ModeAxis:VERIFICATION | URL | URL_AND_HISTORY | NO_CANONICAL_WRITE |
| REVISION_MODE | AXIS_VALUE | ModeAxis:REVISION | URL | URL_AND_HISTORY | NO_CANONICAL_WRITE |
| COGNITIVE_PERSPECTIVE_OVERRIDE | AXIS_VALUE | StableProjectionParameter:CognitivePerspective | URL | URL_AND_HISTORY | NO_CANONICAL_WRITE |
| NO_DRAFT | AXIS_VALUE | DraftAxis:NO_DRAFT | SESSION_DRAFT_STORE | SESSION_RESTORE_ONLY | NO_CANONICAL_WRITE |
| DIRTY_DRAFT | AXIS_VALUE | DraftAxis:DIRTY_DRAFT | SESSION_DRAFT_STORE | SESSION_RESTORE_ONLY | NO_CANONICAL_WRITE |
| QUICK_REVISION | FLOW_PHASE | RevisionFlow:QUICK_REVISION | SESSION_DRAFT_STORE | SESSION_RESTORE_ONLY | NO_CANONICAL_WRITE |
| AUTO_UPGRADING | FLOW_PHASE | RevisionFlow:AUTO_UPGRADING | SESSION_DRAFT_STORE | SESSION_RESTORE_ONLY | NO_CANONICAL_WRITE |
| FULL_REVISION | FLOW_PHASE | RevisionFlow:FULL_REVISION | BROWSER_HISTORY | HISTORY_ONLY | NO_CANONICAL_WRITE |
| IMPACT_ANALYZING | AXIS_VALUE | ProcessingAxis:IMPACT_ANALYZING | SESSION_DRAFT_STORE | SESSION_RESTORE_ONLY | NO_CANONICAL_WRITE |
| IMPACT_ANALYSIS_FAILED | DERIVED_RESULT | ImpactAnalysisFlow:FAILED | SESSION_DRAFT_STORE | SESSION_RESTORE_ONLY | NO_CANONICAL_WRITE |
| COMMIT_ALLOWED | AXIS_VALUE | ProcessingAxis:COMMIT_ALLOWED | SESSION_DRAFT_STORE | SESSION_RESTORE_ONLY | NO_CANONICAL_WRITE |
| COMMIT_BLOCKED | AXIS_VALUE | ProcessingAxis:COMMIT_BLOCKED | SESSION_DRAFT_STORE | SESSION_RESTORE_ONLY | NO_CANONICAL_WRITE |
| SUBMITTING | AXIS_VALUE | ProcessingAxis:SUBMITTING | SESSION_DRAFT_STORE | SESSION_RESTORE_ONLY | WRITE_REQUIRES_CONFIRMED_CHANGESET |
| COMMIT_FAILED | DERIVED_RESULT | CommitFlow:FAILED | SESSION_DRAFT_STORE | SESSION_RESTORE_ONLY | NO_CANONICAL_WRITE |
| COMMIT_SUCCESS | DERIVED_RESULT | CommitFlow:SUCCESS | CANONICAL_SERVER_STATE | DERIVED_FROM_CANONICAL_RESULT | CANONICAL_WRITE_RESULT |
| CANONICAL_SAVED | AXIS_VALUE | ProcessingAxis:CANONICAL_SAVED | CANONICAL_SERVER_STATE | DERIVED_FROM_CANONICAL_RESULT | CANONICAL_WRITE_RESULT |
| RECOMPUTING | AXIS_VALUE | ProcessingAxis:RECOMPUTING | CANONICAL_SERVER_STATE | DERIVED_FROM_CANONICAL_RESULT | DERIVED_AFTER_CANONICAL_WRITE |
| RECOMPUTED | DERIVED_RESULT | RecomputeFlow:COMPLETE | CANONICAL_SERVER_STATE | DERIVED_FROM_CANONICAL_RESULT | DERIVED_AFTER_CANONICAL_WRITE |
| RECOMPUTE_FAILED | DERIVED_RESULT | RecomputeFlow:FAILED | CANONICAL_SERVER_STATE | DERIVED_FROM_CANONICAL_RESULT | DERIVED_AFTER_CANONICAL_WRITE |
| GENERATION_QUEUED | FLOW_PHASE | ProjectionGenerationFlow:QUEUED | CANONICAL_SERVER_STATE | DERIVED_FROM_CANONICAL_RESULT | DERIVED_AFTER_CANONICAL_WRITE |
| GENERATING | FLOW_PHASE | ProjectionGenerationFlow:PROJECTION_GENERATING | CANONICAL_SERVER_STATE | DERIVED_FROM_CANONICAL_RESULT | DERIVED_AFTER_CANONICAL_WRITE |
| GENERATED_CANDIDATE | DERIVED_RESULT | ProjectionGenerationFlow:CANDIDATE | CANONICAL_SERVER_STATE | DERIVED_FROM_CANONICAL_RESULT | DERIVED_AFTER_CANONICAL_WRITE |
| GENERATION_FAILED | DERIVED_RESULT | ProjectionGenerationFlow:FAILED | CANONICAL_SERVER_STATE | DERIVED_FROM_CANONICAL_RESULT | DERIVED_AFTER_CANONICAL_WRITE |
| OLD_EXPRESSION_RETAINED | DERIVED_RESULT | ProjectionFreshnessFlow:STALE_RETAINED | CANONICAL_SERVER_STATE | DERIVED_FROM_CANONICAL_RESULT | DERIVED_AFTER_CANONICAL_WRITE |
| NEW_EXPRESSION_PENDING_CONFIRMATION | FLOW_PHASE | ProjectionConfirmationFlow:PENDING | SESSION_DRAFT_STORE | SESSION_RESTORE_ONLY | NO_CANONICAL_WRITE |
| PENDING_REVERIFICATION | AXIS_VALUE | ProcessingAxis:PENDING_VERIFICATION | CANONICAL_SERVER_STATE | DERIVED_FROM_CANONICAL_RESULT | DERIVED_AFTER_CANONICAL_WRITE |
| VERIFIED | DERIVED_RESULT | VerificationFlow:COMPLETE | CANONICAL_SERVER_STATE | DERIVED_FROM_CANONICAL_RESULT | DERIVED_AFTER_CANONICAL_WRITE |
| PARTIAL_FAILURE | AXIS_VALUE | ProcessingAxis:PARTIAL_FAILURE | CANONICAL_SERVER_STATE | DERIVED_FROM_CANONICAL_RESULT | DERIVED_AFTER_CANONICAL_WRITE |
| CLOSE_AUXILIARY_PANEL | EVENT | NavigationEventFlow | EPHEMERAL_UI | NOT_PERSISTED | NO_CANONICAL_WRITE |
| CLOSE_RELATION_FOCUS | EVENT | NavigationEventFlow | EPHEMERAL_UI | NOT_PERSISTED | NO_CANONICAL_WRITE |
| RESTORE_ORIGIN_OBJECT | EVENT | NavigationEventFlow | EPHEMERAL_UI | NOT_PERSISTED | NO_CANONICAL_WRITE |
| RESTORE_COGNITIVE_PERSPECTIVE | EVENT | NavigationEventFlow | EPHEMERAL_UI | NOT_PERSISTED | NO_CANONICAL_WRITE |
| SOFT_RETURN | EVENT | NavigationEventFlow | EPHEMERAL_UI | NOT_PERSISTED | NO_CANONICAL_WRITE |
| HARD_RESET | EVENT | NavigationEventFlow | EPHEMERAL_UI | NOT_PERSISTED | NO_CANONICAL_WRITE |
| ROUTE_RETURN | EVENT | NavigationEventFlow | EPHEMERAL_UI | NOT_PERSISTED | NO_CANONICAL_WRITE |
| HISTORY_RESTORE | AXIS_VALUE | RecoveryAxis:HISTORY_RESTORING | BROWSER_HISTORY | HISTORY_ONLY | NO_CANONICAL_WRITE |
| REFRESH_RESTORE | AXIS_VALUE | RecoveryAxis:REFRESH_RESTORING | SESSION_DRAFT_STORE | SESSION_RESTORE_ONLY | NO_CANONICAL_WRITE |
| RESTORE_FAILED | AXIS_VALUE | RecoveryAxis:RESTORE_FAILED | SESSION_DRAFT_STORE | SESSION_RESTORE_ONLY | NO_CANONICAL_WRITE |

分类表的 `PersistenceBoundary` 是该原始码允许落入的最高事实层级，不表示每次进入
该状态都会写入。`URLHistoryDisposition` 独立表达可分享路由、浏览器稳定快照和仅
会话恢复的差异；`CanonicalWriteBoundary` 独立表达正式写入是否已经发生。事件只
触发轴快照转换，事件本身不写 URL、History、Draft Store 或 Canonical State。

### 5.0.2 五级持久化 Ledger 与恢复边界

```text
PersistenceLedger = EPHEMERAL_UI|Hover,Tooltip,Preview,InputFocus,TemporaryEndpointHighlight|NO_URL_NO_HISTORY_NO_REFRESH_RESTORE_NO_SERVER_WRITE
PersistenceLedger = URL|Page,StableObject,Mode,StableRelation,ShareablePerspective|NO_DRAFT_ID_NO_TECHNICAL_VERSION_NO_PROCESS_PHASE
PersistenceLedger = BROWSER_HISTORY|StableFocus,FullWorkspace,Perspective,SemanticAnchor|NO_CANONICAL_FACT_COPY
PersistenceLedger = SESSION_DRAFT_STORE|Draft,RecoveryGuard,UnconfirmedChangeSetReference,IdempotencyKey|NO_PUBLISHED_COGNITIVE_FACT
PersistenceLedger = CANONICAL_SERVER_STATE|ConfirmedRevision,Relation,Evidence,ChangeSetResult,ProcessingResult,CurrentVersionPointer|NO_VISUAL_STATE_NO_HOVER_NO_SCROLL_PIXEL

SubmitUnknownDisposition = QUERY_RESULT_WITH_SAME_IDEMPOTENCY_KEY
IdempotentResultQuery = CHANGESET_ID_OR_IDEMPOTENCY_KEY_REQUIRED
UnknownSaveResultTreatedAsFailure = FORBIDDEN
StaleProjectionDisposition = EXPLICIT_STALE_MARK_AND_CANONICAL_VERSION_REFERENCE
RevertDisposition = CREATE_NEW_REVERT_CHANGESET
PhysicalRollbackOfCommittedHistory = FORBIDDEN
```

恢复顺序固定为 `Route → Current Canonical Version → Stable ID → Mode/Workspace →
Draft/Session → Semantic Anchor`。提交结果未知时客户端保留同一草稿和幂等键，先
查询原请求结果；禁止创建第二个提交。Canonical 已保存而重算、生成、核验或 UI
投影失败时，旧投影必须显式标记 stale，并展示已保存边界、可重试任务与 Before/
After。任何已保存变更只能通过新的 Revert ChangeSet 补偿，不删除版本或伪装为
未提交。第 8 章既有 20 个异常矩阵继续作为这套边界的逐场景恢复合同。

### 5.0.3 PageState 与既有事实模型 non-change 决议

现有 12 个 `PageState` 继续表示页面/生成生命周期。它们只映射到正交快照或派生
结果，不吸收 46 个历史交互码，也不改变枚举、Schema、Renderer Input、Catalog
或 evidence map。

```text
PageStateMapping = EMPTY|ProcessingAxis.PROCESSING_IDLE_WITH_EMPTY_CONTENT
PageStateMapping = UPLOADING|SourceIngestionFlow.UPLOADING
PageStateMapping = PARSING|SourceIngestionFlow.PARSING
PageStateMapping = ANALYZING|ProcessingAxis.IMPACT_ANALYZING_OR_SOURCE_ANALYZING
PageStateMapping = GENERATING|ProcessingAxis.PROJECTION_GENERATING
PageStateMapping = WAITING_REVIEW|ProcessingAxis.PENDING_VERIFICATION
PageStateMapping = PARTIALLY_GENERATED|ProcessingAxis.PARTIAL_FAILURE_WITH_READABLE_RESULT
PageStateMapping = FAILED|ProcessingAxis.FAILED
PageStateMapping = RETRYING|RecoveryFlow.RETRYING
PageStateMapping = CONFIRMED|ProcessingAxis.COMPLETE_WITH_CONFIRMED_REVISION
PageStateMapping = PUBLISHED|CanonicalServerState.PUBLISHED_REVISION
PageStateMapping = OUTDATED_BY_STRUCTURE_CHANGE|ProjectionFreshnessFlow.STALE_RETAINED

PageStateEnumChange = NO
PageStateSchemaChange = NO
RendererInputChange = NO
SchemaCatalogChange = NO
SchemaEvidenceMapChange = NO
PhysicalSchemaSpecified = NO

LogicalObjectMapping = KnowledgeObjectVersion|EXISTING_COGNITIVE_ARTIFACT_REVISION_IDENTITY
LogicalObjectMapping = RelationVersion|EXISTING_RELATION_WITHIN_OWNING_ARTIFACT_REVISION
LogicalObjectMapping = ContextBinding|EXISTING_HIERARCHY_PRIMARY_OWNERSHIP_RETURN_TOKEN_AND_SEMANTIC_ANCHOR_PROJECTION
LogicalObjectMapping = EvidenceBinding|EXISTING_EVIDENCE_REFERENCE_TO_COGNITIVE_ARTIFACT_OR_RELATION
LogicalObjectMapping = ChangeSet|EXISTING_COGNITIVE_STRUCTURE_REVISION_OR_COGNITIVE_MODULE_REVISION_CHANGE_ENVELOPE
```

上述映射只说明逻辑 Owner 和恢复引用；本卡不指定物理表、DDL、Migration、Entity、
Repository、Mapper 或新 API。Renderer 仍只投影正式 `CognitiveModule`，不得由
交互轴、事件、草稿或投影状态创造第二套事实。


### 5.1 聚焦与阅读状态


#### `IDLE`

| Field | Contract |
|---|---|
| `StateCode` | IDLE |
| `Purpose` | 提供零交互完整阅读的稳定默认状态 |
| `EntryCondition` | 进入页面、关闭稳定聚焦或执行 HARD_RESET |
| `ExitCondition` | 固定对象、进入 Workspace、路由离开 |
| `PrimaryFocus` | 页面核心问题或 Module 认知闭环 |
| `SecondaryContext` | Primary Cognitive Spine 与当前上下文 |
| `VisualPriority` | 正文最高；结构投影次级；治理控件隐藏 |
| `VisibleContent` | 核心问题、结论、连续解释、关键 Relation、来源入口 |
| `AvailableActions` | 滚动阅读、选择对象、轻量来源、显式切换模式 |
| `ForbiddenActions` | 默认展开治理、自动选中对象、隐藏核心正文 |
| `PersistenceRule` | 保存页面、模式和语义 Anchor；不保存临时游标 |
| `URLHistoryRule` | URL 保存 workspaceId/pageLevel/pageObjectId/mode；不单独建立 IDLE 历史 |
| `KeyboardBehavior` | Tab 进入可交互对象；Enter 选择；方向键仅在结构投影内导航；Escape 无副作用 |
| `TouchBehavior` | 滚动；单击对象固定；无 Hover 依赖 |
| `EmptyState` | 显示缺失内容为何重要、可用恢复入口和可继续阅读范围 |
| `ErrorState` | 页面投影失败时显示可读降级正文与重试，不伪装为空 |
| `AccessibilityAnnouncement` | “阅读模式，当前无固定聚焦对象” |
| `HighFidelityEvidence` | Domain/Theme/Module/Element 默认阅读四类状态证据 |


#### `INPUT_FOCUS`

| Field | Contract |
|---|---|
| `StateCode` | INPUT_FOCUS |
| `Purpose` | 表达键盘或表单输入焦点，不改变认知主聚焦 |
| `EntryCondition` | Tab、Shift+Tab、程序化恢复焦点或进入编辑字段 |
| `ExitCondition` | Enter/Space 激活、Tab 移动、Escape 关闭当前层或失焦 |
| `PrimaryFocus` | 当前可访问控件或编辑字段 |
| `SecondaryContext` | 其绑定的 Canonical Target 与原主聚焦 |
| `VisualPriority` | 清晰焦点环；不得高于稳定主聚焦 |
| `VisibleContent` | 控件名称、状态、快捷键含义和必要错误 |
| `AvailableActions` | 激活控件、继续输入、移动焦点、Escape |
| `ForbiddenActions` | 仅凭颜色表示焦点；焦点移动即改变 Canonical Focus |
| `PersistenceRule` | 仅会话级恢复；刷新不恢复无语义的键盘游标位置 |
| `URLHistoryRule` | 不进入 URL，不创建 History |
| `KeyboardBehavior` | Tab 顺序可预测；Enter/Space 激活；Escape 关闭最上层；方向键遵循组件语义 |
| `TouchBehavior` | 触控无独立 INPUT_FOCUS 要求；点击直接激活目标 |
| `EmptyState` | 无可聚焦项时跳过容器并公告 |
| `ErrorState` | 焦点目标被删除时移动到最近稳定标题并说明 |
| `AccessibilityAnnouncement` | 朗读控件名称、状态、位置和可执行动作 |
| `HighFidelityEvidence` | 焦点环、跳过链接、图形结构键盘路径与焦点恢复证据 |


#### `PREVIEW`

| Field | Contract |
|---|---|
| `StateCode` | PREVIEW |
| `Purpose` | 在不替换稳定聚焦的前提下提供次级短信息 |
| `EntryCondition` | Hover、键盘 Preview、受控长按或明确预览操作 |
| `ExitCondition` | 指针离开、点击空白、Escape、固定目标或超时关闭 |
| `PrimaryFocus` | 临时目标，不是 Primary Focus |
| `SecondaryContext` | 原稳定聚焦和原阅读 Anchor |
| `VisualPriority` | 低于 Pinned Focus；不得全页降权 |
| `VisibleContent` | 短标题、职责、一条关键 Relation、轻量来源状态 |
| `AvailableActions` | 固定查看、打开轻量来源、关闭 |
| `ForbiddenActions` | 创建历史、打开持久 Workspace、修改结构、隐藏正文 |
| `PersistenceRule` | 不跨刷新、不跨路由、不恢复 |
| `URLHistoryRule` | 不进入 URL、不创建 History |
| `KeyboardBehavior` | 方向键移动 Preview；Enter 固定；Escape 关闭 |
| `TouchBehavior` | 点击目标可直接固定；长按仅为增强；点击外部关闭 |
| `EmptyState` | 目标无摘要时显示名称与“暂无次级说明” |
| `ErrorState` | 目标失效时关闭 Preview 并保留原状态 |
| `AccessibilityAnnouncement` | “预览：对象名；按 Enter 固定，按 Escape 关闭” |
| `HighFidelityEvidence` | 鼠标、键盘和触控等价 Preview 证据 |


#### `ELEMENT_PINNED_FOCUS`

| Field | Contract |
|---|---|
| `StateCode` | ELEMENT_PINNED_FOCUS |
| `Purpose` | 将一个 Element 设为唯一稳定认知中心 |
| `EntryCondition` | 单击 Element、键盘 Enter、Relation 端点转入 Element |
| `ExitCondition` | 选择其他 Element/Relation、Escape、HARD_RESET、路由离开 |
| `PrimaryFocus` | 当前 Element |
| `SecondaryContext` | 主归属、所在 Module、直接 Relation 与原进入路径 |
| `VisualPriority` | Element 最高；直接关系与上下文次级；其他内容降权但可辨认 |
| `VisibleContent` | 定义、职责、主归属、边界、1–3 条 Relation、来源入口 |
| `AvailableActions` | 切换对象、聚焦 Relation、来源核验、快速修订、完整修订、返回主归属 |
| `ForbiddenActions` | 再次点击切换关闭、空白点击关闭、并列第二主聚焦 |
| `PersistenceRule` | 跨模式、刷新、浏览器前进后退可恢复；同 ID 新版本时切换版本 |
| `URLHistoryRule` | 写入 primaryFocusKind=ELEMENT/primaryFocusId；创建稳定 History |
| `KeyboardBehavior` | Enter 打开 Focus Summary；Escape 回默认阅读；方向键仅遍历局部关系 |
| `TouchBehavior` | 单击固定；再次点击保持并定位 Summary；关闭按钮显式可见 |
| `EmptyState` | Element 无直接关系时说明主归属和可继续阅读路径 |
| `ErrorState` | 对象被删除/替代时进入恢复异常并提供新对象或上级入口 |
| `AccessibilityAnnouncement` | “已固定对象：名称；当前职责；可用关系数量不作为主要信息朗读” |
| `HighFidelityEvidence` | Element 默认、聚焦、跨实例同步及关闭后的视觉证据 |


#### `RELATION_PINNED_FOCUS`

| Field | Contract |
|---|---|
| `StateCode` | RELATION_PINNED_FOCUS |
| `Purpose` | 将一条 Relation 设为唯一稳定主聚焦 |
| `EntryCondition` | 从正文关系提示、局部面板、结构投影或端点路径选择 Relation |
| `ExitCondition` | 选择另一 Relation、选择端点、Escape、关闭、进入 Workspace |
| `PrimaryFocus` | 当前 Relation |
| `SecondaryContext` | 起点、终点、原 Element/Module 与 Spine 位置 |
| `VisualPriority` | Relation Statement 最高；端点次级；原对象作为返回快照 |
| `VisibleContent` | 完整陈述、理由、认知作用、方向、条件、来源和修订入口 |
| `AvailableActions` | 切换 Relation、进入端点、核验、修订、关闭恢复原对象 |
| `ForbiddenActions` | 同时突出多条 Relation；端点与 Relation 同权；空白点击关闭 |
| `PersistenceRule` | 跨模式、刷新和 History 恢复；被新版本替代时保持 relationId |
| `URLHistoryRule` | 写入 primaryFocusKind=RELATION/activeRelationId；创建 History |
| `KeyboardBehavior` | Enter 打开 Relation Summary；Escape 恢复原对象；方向键在端点/证据入口间移动 |
| `TouchBehavior` | 点击关系固定；点击端点转入端点；显式关闭恢复 |
| `EmptyState` | Relation 缺少证据时仍显示陈述并标明待核验 |
| `ErrorState` | Relation 被替代时显示旧→新映射或恢复失败路径 |
| `AccessibilityAnnouncement` | “已固定关系：主语、谓词、宾语、方向和状态” |
| `HighFidelityEvidence` | Relation 主聚焦、端点层级、关闭恢复和失效替代证据 |


#### `QUICK_SOURCE_PANEL`

| Field | Contract |
|---|---|
| `StateCode` | QUICK_SOURCE_PANEL |
| `Purpose` | 在不离开阅读上下文时查看最小来源支持 |
| `EntryCondition` | 点击轻量来源入口或键盘激活来源标记 |
| `ExitCondition` | 关闭、切换目标、升级为完整核验 |
| `PrimaryFocus` | 当前 Element/Relation 仍为主聚焦 |
| `SecondaryContext` | 来源摘录与支持范围 |
| `VisualPriority` | 主聚焦保持；面板次级且非持久侧栏 |
| `VisibleContent` | 来源名称、摘录、支持范围、加工类型、进入完整核验入口 |
| `AvailableActions` | 关闭、前后来源、进入核验；无草稿时跟随目标 |
| `ForbiddenActions` | 在此完成复杂裁决、改变正式结构、常驻默认页面 |
| `PersistenceRule` | 不跨路由；刷新默认关闭；可保留当前目标 |
| `URLHistoryRule` | 不进入 URL，不创建 History |
| `KeyboardBehavior` | Escape 关闭；Tab 限定在面板与返回目标；Enter 打开完整核验 |
| `TouchBehavior` | 小屏使用底部临时面板；点击遮罩关闭但不清除 Focus |
| `EmptyState` | 无来源时说明来源缺口和可核验入口 |
| `ErrorState` | 来源加载失败时保留目标并允许重试 |
| `AccessibilityAnnouncement` | “快速来源面板，支持范围……，按 Escape 返回对象” |
| `HighFidelityEvidence` | 桌面轻量层、小屏底部层和焦点归还证据 |


#### `FULL_VERIFICATION_WORKSPACE`

| Field | Contract |
|---|---|
| `StateCode` | FULL_VERIFICATION_WORKSPACE |
| `Purpose` | 对对象或 Relation 的证据、方向、条件和范围进行完整核验 |
| `EntryCondition` | 从 Quick Source、Focus Summary 或显式核验模式进入 |
| `ExitCondition` | 提交核验裁决、保存草稿、取消、浏览器返回 |
| `PrimaryFocus` | 当前 Canonical Target |
| `SecondaryContext` | 原阅读 Anchor、证据绑定、来源摘录和冲突 |
| `VisualPriority` | 核验命题与支持矩阵最高；阅读上下文持续可见 |
| `VisibleContent` | 主体/谓词/客体/方向/条件/范围支持、冲突与加工类型 |
| `AvailableActions` | 核验、补充来源、裁决、进入修订、返回 |
| `ForbiddenActions` | 丢失原 Target、只列来源文件、静默改变关系 |
| `PersistenceRule` | Workspace、Target、草稿和 Anchor 可恢复 |
| `URLHistoryRule` | mode=VERIFICATION、Target 和 Workspace 进入 URL；创建 History |
| `KeyboardBehavior` | Escape 关闭最上层后返回原 Focus；Tab 遵循核验顺序 |
| `TouchBehavior` | 小屏可全屏临时 Workspace；固定返回栏 |
| `EmptyState` | 无证据时显示缺口、影响和可用动作 |
| `ErrorState` | 加载/保存失败区分未保存与已保存边界 |
| `AccessibilityAnnouncement` | “核验工作区，当前核验对象/关系……，存在若干证据状态” |
| `HighFidelityEvidence` | 完整核验、冲突、无来源、保存失败与返回状态证据 |


#### `READING_MODE`

| Field | Contract |
|---|---|
| `StateCode` | READING_MODE |
| `Purpose` | 建立认知，不展示治理工作台 |
| `EntryCondition` | 页面默认进入或从核验/修订返回 |
| `ExitCondition` | 显式进入核验或修订、路由离开 |
| `PrimaryFocus` | 页面核心问题或当前稳定 Focus |
| `SecondaryContext` | Spine、关键 Relation 与轻量来源状态 |
| `VisualPriority` | 连续正文和当前认知对象最高 |
| `VisibleContent` | 零交互最低内容、必要结构投影、轻量来源入口 |
| `AvailableActions` | 阅读、聚焦、局部关系、快速来源、进入核验/修订 |
| `ForbiddenActions` | 常驻治理面板、批量编辑、全量图例和状态统计 |
| `PersistenceRule` | 模式跨刷新、路由和 History 保留 |
| `URLHistoryRule` | mode=READING；模式变化创建 History |
| `KeyboardBehavior` | 常规文档导航；Escape 逐层退出到默认阅读 |
| `TouchBehavior` | 触控以文档流为主；辅助层临时覆盖 |
| `EmptyState` | 内容缺失时解释缺口而非空卡片 |
| `ErrorState` | 投影失败时降级到 Canonical 文本或明确过期版本 |
| `AccessibilityAnnouncement` | “阅读模式”及当前主聚焦 |
| `HighFidelityEvidence` | 无交互默认、高聚焦、来源入口和治理控件隐藏证据 |


#### `VERIFICATION_MODE`

| Field | Contract |
|---|---|
| `StateCode` | VERIFICATION_MODE |
| `Purpose` | 突出证据、支持范围、冲突和用户裁决 |
| `EntryCondition` | 显式切换模式或进入完整核验 |
| `ExitCondition` | 返回阅读、进入修订、路由离开 |
| `PrimaryFocus` | 当前对象或 Relation |
| `SecondaryContext` | 原阅读上下文和证据集合 |
| `VisualPriority` | 证据与命题最高；正文作为上下文 |
| `VisibleContent` | 支持矩阵、加工类型、冲突、决定和返回路径 |
| `AvailableActions` | 核验、补源、裁决、进入修订、保存草稿 |
| `ForbiddenActions` | 将候选伪装为事实、丢失原阅读位置 |
| `PersistenceRule` | 模式、目标、Workspace、草稿可恢复 |
| `URLHistoryRule` | mode=VERIFICATION；创建稳定 History |
| `KeyboardBehavior` | 模式切换后焦点落到同一 Target；Escape 返回上层 |
| `TouchBehavior` | 小屏全屏 Workspace，固定返回目标 |
| `EmptyState` | 无证据显示为何重要及可继续阅读范围 |
| `ErrorState` | 加载/裁决失败明确保存边界 |
| `AccessibilityAnnouncement` | “核验模式，当前目标……” |
| `HighFidelityEvidence` | 核验主态、无证据、冲突、保存成功/失败证据 |


#### `REVISION_MODE`

| Field | Contract |
|---|---|
| `StateCode` | REVISION_MODE |
| `Purpose` | 修改正式结构或表达并预览影响 |
| `EntryCondition` | 显式切换、快速修订升级或从核验进入 |
| `ExitCondition` | 提交、保存/丢弃草稿、返回阅读/核验 |
| `PrimaryFocus` | 当前修订 Target/ChangeSet |
| `SecondaryContext` | 原 Focus、Before 状态、影响对象 |
| `VisualPriority` | 编辑字段和影响状态最高；阅读上下文持续存在 |
| `VisibleContent` | Before/After、正式字段、三类影响、锁定和版本 |
| `AvailableActions` | 编辑、分析影响、提交、保存草稿、撤销 |
| `ForbiddenActions` | 静默覆盖、跳过影响、无草稿保护离开 |
| `PersistenceRule` | 模式、Target、ChangeSet 和草稿持久恢复 |
| `URLHistoryRule` | mode=REVISION；进入完整修订创建 History |
| `KeyboardBehavior` | Escape 关闭最上层但不丢草稿；快捷提交必须满足门禁 |
| `TouchBehavior` | 小屏分步但三类影响可总览；明确返回 |
| `EmptyState` | 无可编辑字段时说明锁定/权限原因 |
| `ErrorState` | 分析或提交失败显示保存边界与恢复 |
| `AccessibilityAnnouncement` | “修订模式，存在/不存在未提交草稿，提交是否允许” |
| `HighFidelityEvidence` | 编辑、影响、阻断、提交与草稿保护全状态证据 |


#### `COGNITIVE_PERSPECTIVE_OVERRIDE`

| Field | Contract |
|---|---|
| `StateCode` | COGNITIVE_PERSPECTIVE_OVERRIDE |
| `Purpose` | 临时改变 Projection 强调而不改变正式语义 |
| `EntryCondition` | 选择当前内容需要的辅助认知视角 |
| `ExitCondition` | 恢复 OVERALL、切换视角、离开页面 |
| `PrimaryFocus` | 当前稳定 Focus 或 Module Closure |
| `SecondaryContext` | Primary Spine 与被降权内容 |
| `VisualPriority` | 所选视角相关内容提高；核心正文仍可见 |
| `VisibleContent` | 视角说明、被强调对象和关键 Relation |
| `AvailableActions` | 切换辅助视角、恢复整体、继续聚焦 |
| `ForbiddenActions` | 隐藏核心结论、改变正式顺序、永久 Tab Bar |
| `PersistenceRule` | 稳定状态；跨刷新/History 恢复 |
| `URLHistoryRule` | cognitivePerspective 写入 URL；切换创建 History |
| `KeyboardBehavior` | 选择后焦点留在同一 Canonical Target；Escape 恢复上一视角 |
| `TouchBehavior` | 触控使用按需菜单，不依赖 Hover |
| `EmptyState` | 当前内容无辅助视角时不显示控制 |
| `ErrorState` | 视角投影失败时回退 OVERALL 并说明 |
| `AccessibilityAnnouncement` | “当前认知视角：……；正式内容未改变” |
| `HighFidelityEvidence` | OVERALL 与一至两个辅助视角、恢复和失败回退证据 |


### 5.2 修订状态


#### `NO_DRAFT`

| Field | Contract |
|---|---|
| `StateCode` | NO_DRAFT |
| `Purpose` | 表示当前没有未提交 ChangeSet |
| `EntryCondition` | 进入修订前、提交/丢弃完成 |
| `ExitCondition` | 首次编辑或恢复草稿 |
| `PrimaryFocus` | 当前修订 Target |
| `SecondaryContext` | 原正式版本 |
| `VisualPriority` | 正式内容为唯一有效版本 |
| `VisibleContent` | 正式字段、无草稿提示和可编辑入口 |
| `AvailableActions` | 开始快速/完整修订、返回 |
| `ForbiddenActions` | 显示未保存警告、提交空变更 |
| `PersistenceRule` | 稳定；刷新保持无草稿 |
| `URLHistoryRule` | 不单独进入 URL |
| `KeyboardBehavior` | Enter 开始编辑；Escape 返回上层 |
| `TouchBehavior` | 点击编辑进入 |
| `EmptyState` | 无可编辑内容时说明原因 |
| `ErrorState` | 初始化草稿失败时保留阅读 |
| `AccessibilityAnnouncement` | “当前无未提交草稿” |
| `HighFidelityEvidence` | 无草稿初态证据 |


#### `DIRTY_DRAFT`

| Field | Contract |
|---|---|
| `StateCode` | DIRTY_DRAFT |
| `Purpose` | 保护已经修改但未提交的内容 |
| `EntryCondition` | 任一字段变化、来源变化或影响决策变化 |
| `ExitCondition` | 保存草稿、提交、丢弃、冲突化 |
| `PrimaryFocus` | 当前 ChangeSet 草稿 |
| `SecondaryContext` | 原版本和原 Focus |
| `VisualPriority` | 未保存状态清晰但不遮蔽编辑 |
| `VisibleContent` | 变更标识、保存状态、离开保护 |
| `AvailableActions` | 继续编辑、保存、分析、丢弃、提交条件检查 |
| `ForbiddenActions` | 静默离开、静默提交、切换 Target |
| `PersistenceRule` | DurableDraft；刷新和意外关闭可恢复 |
| `URLHistoryRule` | draftId 不写公开 URL，可写会话 History State；离开触发 Guard |
| `KeyboardBehavior` | Escape 只关闭上层；浏览器返回先保护 |
| `TouchBehavior` | 切换对象/Workspace 前弹出保护层 |
| `EmptyState` | 草稿字段为空但有结构删除时仍视为脏 |
| `ErrorState` | 草稿持久化失败明确“仅本会话”边界 |
| `AccessibilityAnnouncement` | “存在未提交草稿” |
| `HighFidelityEvidence` | 脏标识、离开保护、恢复和持久化失败证据 |


#### `QUICK_REVISION`

| Field | Contract |
|---|---|
| `StateCode` | QUICK_REVISION |
| `Purpose` | 完成低风险局部文本或来源修订 |
| `EntryCondition` | 从 Focus 附近选择快速修订且风险分类通过 |
| `ExitCondition` | 保存、取消、自动升级、提交 |
| `PrimaryFocus` | 当前局部字段/来源绑定 |
| `SecondaryContext` | 原对象或 Relation |
| `VisualPriority` | 轻量编辑层，不变成完整 Workspace |
| `VisibleContent` | 可编辑低风险字段、风险说明和升级条件 |
| `AvailableActions` | 编辑、保存、取消、升级完整修订 |
| `ForbiddenActions` | 修改端点、方向、主归属、Spine 或边界 |
| `PersistenceRule` | 草稿可恢复；关闭不得丢失脏状态 |
| `URLHistoryRule` | 不创建独立页面历史；升级后创建 History |
| `KeyboardBehavior` | Enter 确认字段；Escape 关闭上层但保护草稿 |
| `TouchBehavior` | 底部/行内编辑；显式升级入口 |
| `EmptyState` | 没有可快速修订字段时转完整修订 |
| `ErrorState` | 风险分类失败进入 AUTO_UPGRADING 或错误提示 |
| `AccessibilityAnnouncement` | “快速修订，允许修改范围……” |
| `HighFidelityEvidence` | 行内/轻量编辑、升级提示和草稿保护证据 |


#### `AUTO_UPGRADING`

| Field | Contract |
|---|---|
| `StateCode` | AUTO_UPGRADING |
| `Purpose` | 将触及高风险语义的快速修订安全迁移到完整修订 |
| `EntryCondition` | 检测语义、边界、锁定、来源或身份风险 |
| `ExitCondition` | 升级成功进入 FULL_REVISION；失败进入明确异常 |
| `PrimaryFocus` | 当前 Draft 和 Target |
| `SecondaryContext` | 触发升级的字段与原因 |
| `VisualPriority` | 状态说明优先，草稿内容保持可见 |
| `VisibleContent` | 升级原因、将打开的完整字段、草稿保留确认 |
| `AvailableActions` | 继续升级、返回编辑、取消但保留草稿 |
| `ForbiddenActions` | 静默升级、丢失草稿、继续快速提交 |
| `PersistenceRule` | 升级过程和草稿可恢复 |
| `URLHistoryRule` | 成功后写入完整修订 History；过程本身不新增 |
| `KeyboardBehavior` | Escape 返回快速修订且不丢草稿 |
| `TouchBehavior` | 阻止重复点击；显示单一进度 |
| `EmptyState` | 无升级目标时返回快速修订 |
| `ErrorState` | 升级失败提供重试和导出草稿 |
| `AccessibilityAnnouncement` | “正在将快速修订升级为完整修订，草稿已保留” |
| `HighFidelityEvidence` | 升级中、成功、失败和返回证据 |


#### `FULL_REVISION`

| Field | Contract |
|---|---|
| `StateCode` | FULL_REVISION |
| `Purpose` | 编辑正式语义、结构、来源和边界 |
| `EntryCondition` | 显式进入或 AUTO_UPGRADING 成功 |
| `ExitCondition` | 影响分析、保存草稿、取消、提交 |
| `PrimaryFocus` | 当前 ChangeSet 与 Target |
| `SecondaryContext` | Before 版本、相关对象与 Relation |
| `VisualPriority` | 正式字段和认知影响并重 |
| `VisibleContent` | 类型、端点、方向、归属、边界、Spine、来源、陈述 |
| `AvailableActions` | 编辑、分析、保存、比较、取消 |
| `ForbiddenActions` | 跳过影响直接提交、静默修改锁定项 |
| `PersistenceRule` | DurableDraft；跨刷新恢复 |
| `URLHistoryRule` | mode=REVISION/Target/Workspace 写 URL；创建 History |
| `KeyboardBehavior` | Tab 按语义分组；Escape 关闭上层；快捷提交受门禁 |
| `TouchBehavior` | 小屏分步编辑并保留影响摘要 |
| `EmptyState` | 目标被锁定时显示允许动作 |
| `ErrorState` | 版本变化进入冲突草稿而非覆盖 |
| `AccessibilityAnnouncement` | “完整修订，当前 Target……，未解决影响……” |
| `HighFidelityEvidence` | 完整字段、锁定、版本冲突和上下文保持证据 |


#### `IMPACT_ANALYZING`

| Field | Contract |
|---|---|
| `StateCode` | IMPACT_ANALYZING |
| `Purpose` | 计算语义、结构和表达三类影响 |
| `EntryCondition` | 用户请求预览或提交前自动触发 |
| `ExitCondition` | 成功进入 COMMIT_ALLOWED/BLOCKED；失败进入 IMPACT_ANALYSIS_FAILED |
| `PrimaryFocus` | 当前 ChangeSet |
| `SecondaryContext` | 受影响 Canonical 与 Projection Target |
| `VisualPriority` | 分析进度次于 Draft；三类通道占位稳定 |
| `VisibleContent` | 分析范围、已完成通道和可取消/重试说明 |
| `AvailableActions` | 等待、取消返回编辑 |
| `ForbiddenActions` | 提交、重复分析、编辑导致结果与草稿不一致 |
| `PersistenceRule` | 状态可恢复但结果需绑定 draftRevision |
| `URLHistoryRule` | 影响预览完成后创建稳定 History；分析中不新增 |
| `KeyboardBehavior` | Escape 返回编辑；焦点不陷入进度 |
| `TouchBehavior` | 阻止重复点击；允许后台后继续当前 Workspace |
| `EmptyState` | 无影响仍输出三类空结果及原因 |
| `ErrorState` | 超时进入失败，不伪造无影响 |
| `AccessibilityAnnouncement` | “正在分析三类影响” |
| `HighFidelityEvidence` | 三通道加载、取消、成功和超时证据 |


#### `IMPACT_ANALYSIS_FAILED`

| Field | Contract |
|---|---|
| `StateCode` | IMPACT_ANALYSIS_FAILED |
| `Purpose` | 明确影响未得出，阻止不安全提交 |
| `EntryCondition` | 任一必需影响通道失败或结果版本不匹配 |
| `ExitCondition` | 重试成功、返回编辑、取消修订 |
| `PrimaryFocus` | 失败的影响通道/ChangeSet |
| `SecondaryContext` | 已成功通道与失败原因 |
| `VisualPriority` | 错误和 Blocker 最高 |
| `VisibleContent` | 失败范围、已保存草稿、可重试动作 |
| `AvailableActions` | 重试、修改草稿、保存、取消 |
| `ForbiddenActions` | 提交、将失败通道视为无影响 |
| `PersistenceRule` | 错误与草稿可恢复 |
| `URLHistoryRule` | 不创建新的 History；保留 Impact 页面状态 |
| `KeyboardBehavior` | Enter 重试；Escape 返回编辑 |
| `TouchBehavior` | 单击重试；避免多次并发 |
| `EmptyState` | 无错误详情时显示可诊断编码 |
| `ErrorState` | 重复失败提供导出报告，不允许绕过 |
| `AccessibilityAnnouncement` | “影响分析失败，提交已阻止” |
| `HighFidelityEvidence` | 部分通道失败、重试和阻断证据 |


#### `COMMIT_ALLOWED`

| Field | Contract |
|---|---|
| `StateCode` | COMMIT_ALLOWED |
| `Purpose` | 表示所有提交门禁已满足 |
| `EntryCondition` | 影响分析成功且无 Blocker、决定已完成 |
| `ExitCondition` | 开始 SUBMITTING、草稿变化、取消 |
| `PrimaryFocus` | 当前 ChangeSet |
| `SecondaryContext` | 三类影响、锁定检查和 Before 版本 |
| `VisualPriority` | 提交动作可见但不压过摘要 |
| `VisibleContent` | Before/After、影响摘要、提交后计划 |
| `AvailableActions` | 提交、返回编辑、保存草稿 |
| `ForbiddenActions` | 改变字段后沿用旧允许状态、重复提交 |
| `PersistenceRule` | 允许状态绑定精确 draftRevision |
| `URLHistoryRule` | Impact Preview 已在 History；允许状态不额外创建 |
| `KeyboardBehavior` | Enter 在明确按钮上提交；Escape 返回编辑 |
| `TouchBehavior` | 单击提交后立即禁用 |
| `EmptyState` | 无实质变更时不得进入允许 |
| `ErrorState` | 版本过期立即降级 COMMIT_BLOCKED |
| `AccessibilityAnnouncement` | “提交条件已满足” |
| `HighFidelityEvidence` | 允许状态、失效后降级和单次提交证据 |


#### `COMMIT_BLOCKED`

| Field | Contract |
|---|---|
| `StateCode` | COMMIT_BLOCKED |
| `Purpose` | 解释为什么当前不能提交 |
| `EntryCondition` | 存在 Blocker、锁定冲突、缺字段、分析失败或版本过期 |
| `ExitCondition` | 解决所有 Blocker 后进入允许；取消 |
| `PrimaryFocus` | 阻断项 |
| `SecondaryContext` | 草稿和可修复字段 |
| `VisualPriority` | Blocker 默认展开并高于提交按钮 |
| `VisibleContent` | 原因、因果链、需要的用户决定 |
| `AvailableActions` | 修复、重新分析、保存草稿、取消 |
| `ForbiddenActions` | 提交、折叠全部 Blocker、只显示数量 |
| `PersistenceRule` | 草稿和阻断项可恢复 |
| `URLHistoryRule` | 不创建独立 History |
| `KeyboardBehavior` | 焦点优先进入首个 Blocker；Escape 返回编辑 |
| `TouchBehavior` | 点击阻断项定位字段 |
| `EmptyState` | 无具体原因时视为系统错误 |
| `ErrorState` | 阻断服务失败按影响分析失败处理 |
| `AccessibilityAnnouncement` | “提交被阻止：原因……” |
| `HighFidelityEvidence` | 多 Blocker、定位和解除后的状态证据 |


#### `SUBMITTING`

| Field | Contract |
|---|---|
| `StateCode` | SUBMITTING |
| `Purpose` | 执行幂等正式提交并防止重复版本 |
| `EntryCondition` | 从 COMMIT_ALLOWED 单次确认 |
| `ExitCondition` | 成功 COMMIT_SUCCESS；失败 COMMIT_FAILED；状态未知进入异常恢复 |
| `PrimaryFocus` | 提交请求/ChangeSet |
| `SecondaryContext` | 原 Focus 和幂等键 |
| `VisualPriority` | 单一进度与不可重复提交状态 |
| `VisibleContent` | 提交阶段、可安全关闭说明、幂等请求标识的用户友好状态 |
| `AvailableActions` | 等待；必要时取消仅客户端等待，不取消服务端语义 |
| `ForbiddenActions` | 重复点击、修改草稿、创建第二提交请求 |
| `PersistenceRule` | 服务端处理结果必须可查询；刷新后恢复 |
| `URLHistoryRule` | 处理状态可进入 History State，但不创建语义新路由 |
| `KeyboardBehavior` | 按钮禁用；Escape 不丢请求状态 |
| `TouchBehavior` | 重复点击无效；显示触控反馈 |
| `EmptyState` | 空 ChangeSet 禁止进入 |
| `ErrorState` | 网络超时进入“结果未知”恢复，不直接报未保存 |
| `AccessibilityAnnouncement` | “正在提交，重复操作已阻止” |
| `HighFidelityEvidence` | 提交中、刷新、网络超时和重复点击证据 |


#### `COMMIT_FAILED`

| Field | Contract |
|---|---|
| `StateCode` | COMMIT_FAILED |
| `Purpose` | 明确正式结构未保存或结果未确认 |
| `EntryCondition` | 服务端明确失败，或结果查询确认未保存 |
| `ExitCondition` | 重试、返回编辑、取消 |
| `PrimaryFocus` | 失败请求/ChangeSet |
| `SecondaryContext` | 草稿与原正式版本 |
| `VisualPriority` | 错误状态高于提交动作 |
| `VisibleContent` | 是否已保存、失败原因、草稿状态、恢复动作 |
| `AvailableActions` | 安全重试、编辑、保存草稿、查看详情 |
| `ForbiddenActions` | 假定已保存、丢草稿、创建重复版本 |
| `PersistenceRule` | 草稿持久；失败请求幂等信息保留 |
| `URLHistoryRule` | 不创建新 History；保留原 Impact 状态 |
| `KeyboardBehavior` | Enter 重试；Escape 返回编辑 |
| `TouchBehavior` | 点击重试仅复用同一幂等语义 |
| `EmptyState` | 无错误详情显示错误编码 |
| `ErrorState` | 结果未知不得使用本状态，必须进入专门异常 |
| `AccessibilityAnnouncement` | “提交失败，正式结构未保存/结果边界……” |
| `HighFidelityEvidence` | 明确失败与结果未知的差异证据 |


#### `COMMIT_SUCCESS`

| Field | Contract |
|---|---|
| `StateCode` | COMMIT_SUCCESS |
| `Purpose` | 确认 ChangeSet 已创建并进入后续传播 |
| `EntryCondition` | 服务端返回正式版本和 ChangeSet |
| `ExitCondition` | 进入 CANONICAL_SAVED、返回阅读或查看差异 |
| `PrimaryFocus` | 新 Canonical Version/ChangeSet |
| `SecondaryContext` | 旧版本、原 Focus、后续处理状态 |
| `VisualPriority` | 成功确认简洁；后续传播状态清晰 |
| `VisibleContent` | 新版本、已保存边界、下一处理、返回原位置 |
| `AvailableActions` | 查看差异、返回、继续观察传播、发起 Revert |
| `ForbiddenActions` | 再次提交相同草稿、将传播失败解释为未保存 |
| `PersistenceRule` | 结果持久；刷新后可查询 |
| `URLHistoryRule` | 创建稳定 History/版本结果状态 |
| `KeyboardBehavior` | Enter 返回原 Focus；Escape 关闭成功层但不清除结果 |
| `TouchBehavior` | 点击返回/查看差异 |
| `EmptyState` | 缺少版本号时视为协议错误 |
| `ErrorState` | 后续投影失败转 PARTIAL_FAILURE，不回滚成功提示 |
| `AccessibilityAnnouncement` | “提交成功，正式版本已保存” |
| `HighFidelityEvidence` | 成功、返回、差异和传播状态证据 |


### 5.3 提交后更新状态


#### `CANONICAL_SAVED`

| Field | Contract |
|---|---|
| `StateCode` | CANONICAL_SAVED |
| `Purpose` | 标记正式对象/Relation 与 ChangeSet 已持久化 |
| `EntryCondition` | COMMIT_SUCCESS 返回新版本 |
| `ExitCondition` | 进入重算/生成/待核验或完成 |
| `PrimaryFocus` | 新 Canonical Version |
| `SecondaryContext` | 原版本和受影响投影 |
| `VisualPriority` | 保存边界最高，投影新鲜度独立 |
| `VisibleContent` | 已保存内容、版本、待处理列表 |
| `AvailableActions` | 返回阅读、查看差异、观察处理、Revert |
| `ForbiddenActions` | 把旧投影当最新、自动回滚正式结构 |
| `PersistenceRule` | 服务端永久状态 |
| `URLHistoryRule` | 版本结果可恢复；不必单独改变 URL |
| `KeyboardBehavior` | Enter 返回原 Focus |
| `TouchBehavior` | 触控同等 |
| `EmptyState` | 无后续任务时直接完成 |
| `ErrorState` | 状态读取失败通过 ChangeSet 查询恢复 |
| `AccessibilityAnnouncement` | “正式结构已保存，后续投影处理状态……” |
| `HighFidelityEvidence` | 保存与投影处理分离证据 |


#### `RECOMPUTING`

| Field | Contract |
|---|---|
| `StateCode` | RECOMPUTING |
| `Purpose` | 重新计算 Spine、Closure、映射或布局依赖 |
| `EntryCondition` | Canonical Saved 且存在结构依赖 |
| `ExitCondition` | RECOMPUTED 或 RECOMPUTE_FAILED |
| `PrimaryFocus` | 受影响结构任务 |
| `SecondaryContext` | 当前新版本和旧投影 |
| `VisualPriority` | 任务状态附着，不抢占阅读 |
| `VisibleContent` | 重算范围、旧投影状态、可继续阅读说明 |
| `AvailableActions` | 继续阅读、查看任务、必要时重试 |
| `ForbiddenActions` | 在未完成时标记新投影 CURRENT |
| `PersistenceRule` | 任务跨刷新可查询 |
| `URLHistoryRule` | 不创建新语义 History |
| `KeyboardBehavior` | 焦点保持原对象；状态变更公告 |
| `TouchBehavior` | 非阻塞提示；小屏不常驻面板 |
| `EmptyState` | 无重算任务跳过 |
| `ErrorState` | 任务失败转失败状态 |
| `AccessibilityAnnouncement` | “正在重新计算受影响结构” |
| `HighFidelityEvidence` | 非阻塞重算、过期标记和完成公告证据 |


#### `RECOMPUTED`

| Field | Contract |
|---|---|
| `StateCode` | RECOMPUTED |
| `Purpose` | 结构依赖已基于新版本完成 |
| `EntryCondition` | 全部必需重算成功 |
| `ExitCondition` | 进入生成、待核验或完成 |
| `PrimaryFocus` | 新结构结果 |
| `SecondaryContext` | 原 Focus 和后续表达任务 |
| `VisualPriority` | 完成状态低调附着 |
| `VisibleContent` | 已更新范围和版本 |
| `AvailableActions` | 查看更新、继续阅读 |
| `ForbiddenActions` | 保留过期标记 |
| `PersistenceRule` | 结果持久可查询 |
| `URLHistoryRule` | 不新增 History |
| `KeyboardBehavior` | 无特殊；公告完成 |
| `TouchBehavior` | 无特殊 |
| `EmptyState` | 无结果视为协议异常 |
| `ErrorState` | 读取失败转 PARTIAL_FAILURE |
| `AccessibilityAnnouncement` | “结构重新计算完成” |
| `HighFidelityEvidence` | 完成标记和原 Focus 保持证据 |


#### `RECOMPUTE_FAILED`

| Field | Contract |
|---|---|
| `StateCode` | RECOMPUTE_FAILED |
| `Purpose` | 正式结构已保存但依赖重算失败 |
| `EntryCondition` | 重算任务失败/超时 |
| `ExitCondition` | 重试成功、Revert、人工处理 |
| `PrimaryFocus` | 失败任务 |
| `SecondaryContext` | Canonical Saved 与旧投影 |
| `VisualPriority` | 显式过期/失败标记 |
| `VisibleContent` | 保存边界、失败范围、旧投影版本和恢复动作 |
| `AvailableActions` | 重试、继续阅读旧版、Revert、查看差异 |
| `ForbiddenActions` | 将旧投影标 CURRENT、继续基于旧投影无提示修订 |
| `PersistenceRule` | 失败状态跨刷新持久 |
| `URLHistoryRule` | 不创建新 History |
| `KeyboardBehavior` | Enter 重试；焦点保持 |
| `TouchBehavior` | 点击重试防重复 |
| `EmptyState` | 无旧投影时提供 Canonical 文本降级 |
| `ErrorState` | 多次失败保留诊断码 |
| `AccessibilityAnnouncement` | “正式结构已保存，但重新计算失败” |
| `HighFidelityEvidence` | 部分失败、旧投影标记和 Revert 证据 |


#### `GENERATION_QUEUED`

| Field | Contract |
|---|---|
| `StateCode` | GENERATION_QUEUED |
| `Purpose` | 局部解释或投影生成已排队 |
| `EntryCondition` | 存在表达更新任务且尚未执行 |
| `ExitCondition` | 进入 GENERATING、取消候选任务或失败 |
| `PrimaryFocus` | 生成任务 |
| `SecondaryContext` | 新 Canonical Version 与旧表达 |
| `VisualPriority` | 队列状态低权重附着 |
| `VisibleContent` | 生成范围、旧表达保留规则 |
| `AvailableActions` | 继续阅读、查看任务 |
| `ForbiddenActions` | 将排队候选显示为新正式表达 |
| `PersistenceRule` | 任务持久可查询 |
| `URLHistoryRule` | 不新增 History |
| `KeyboardBehavior` | 无特殊；状态公告 |
| `TouchBehavior` | 无特殊 |
| `EmptyState` | 无生成范围则跳过 |
| `ErrorState` | 排队失败进入 GENERATION_FAILED |
| `AccessibilityAnnouncement` | “新的表达已排队生成” |
| `HighFidelityEvidence` | 排队与旧表达保留证据 |


#### `GENERATING`

| Field | Contract |
|---|---|
| `StateCode` | GENERATING |
| `Purpose` | 基于新 Canonical 生成局部候选表达 |
| `EntryCondition` | 队列任务开始 |
| `ExitCondition` | 生成候选或失败 |
| `PrimaryFocus` | 生成任务 |
| `SecondaryContext` | 旧表达和锁定内容 |
| `VisualPriority` | 非阻塞；锁定冲突预留状态 |
| `VisibleContent` | 进度、范围、旧表达版本 |
| `AvailableActions` | 继续阅读、取消未开始子任务 |
| `ForbiddenActions` | 覆盖锁定内容、显示未完成文本 |
| `PersistenceRule` | 跨刷新可查询 |
| `URLHistoryRule` | 不新增 History |
| `KeyboardBehavior` | 焦点不被夺取 |
| `TouchBehavior` | 非阻塞提示 |
| `EmptyState` | 无可生成内容跳过 |
| `ErrorState` | 超时进入失败 |
| `AccessibilityAnnouncement` | “正在生成新的局部表达” |
| `HighFidelityEvidence` | 生成中、阅读不中断和锁定保护证据 |


#### `GENERATED_CANDIDATE`

| Field | Contract |
|---|---|
| `StateCode` | GENERATED_CANDIDATE |
| `Purpose` | 生成内容完成但尚未成为用户确认的正式表达 |
| `EntryCondition` | 生成任务成功 |
| `ExitCondition` | 自动采纳安全投影、待确认或丢弃 |
| `PrimaryFocus` | 候选表达 |
| `SecondaryContext` | Canonical Version、旧表达、锁定差异 |
| `VisualPriority` | 候选标识明确，不能伪装正式 |
| `VisibleContent` | 候选内容、来源版本、差异和采纳规则 |
| `AvailableActions` | 预览、确认、拒绝、进入核验 |
| `ForbiddenActions` | 静默覆盖用户锁定内容 |
| `PersistenceRule` | 候选持久到处理完成 |
| `URLHistoryRule` | 如需用户决定可创建稳定状态 |
| `KeyboardBehavior` | 键盘可比较 Before/After |
| `TouchBehavior` | 触控分段比较 |
| `EmptyState` | 候选为空显示生成未产生变化 |
| `ErrorState` | 候选解析失败转 GENERATION_FAILED |
| `AccessibilityAnnouncement` | “生成候选，尚未确认” |
| `HighFidelityEvidence` | 候选标签、差异和采纳证据 |


#### `GENERATION_FAILED`

| Field | Contract |
|---|---|
| `StateCode` | GENERATION_FAILED |
| `Purpose` | 正式结构保留但局部表达生成失败 |
| `EntryCondition` | 生成任务失败 |
| `ExitCondition` | 重试、保留旧表达、Revert |
| `PrimaryFocus` | 失败生成任务 |
| `SecondaryContext` | 新 Canonical 与旧表达 |
| `VisualPriority` | 失败和旧表达版本显式 |
| `VisibleContent` | 失败范围、旧表达状态和恢复动作 |
| `AvailableActions` | 重试、继续旧表达、查看 Canonical 差异、Revert |
| `ForbiddenActions` | 将旧表达标最新、自动回滚结构 |
| `PersistenceRule` | 跨刷新持久 |
| `URLHistoryRule` | 不新增 History |
| `KeyboardBehavior` | Enter 重试 |
| `TouchBehavior` | 重复点击防并发 |
| `EmptyState` | 无旧表达时降级 Canonical 文本 |
| `ErrorState` | 持续失败提供诊断 |
| `AccessibilityAnnouncement` | “正式结构已保存，但新表达生成失败” |
| `HighFidelityEvidence` | 失败、旧表达保留和降级正文证据 |


#### `OLD_EXPRESSION_RETAINED`

| Field | Contract |
|---|---|
| `StateCode` | OLD_EXPRESSION_RETAINED |
| `Purpose` | 在新表达未就绪时安全保留旧表达 |
| `EntryCondition` | 重算/生成失败或候选待确认 |
| `ExitCondition` | 新表达确认、成功刷新、Revert |
| `PrimaryFocus` | 旧 Projection |
| `SecondaryContext` | 新 Canonical Version 和过期原因 |
| `VisualPriority` | 旧表达带明显 OUTDATED 标记 |
| `VisibleContent` | 旧版本号、为何保留、不可继续修订限制 |
| `AvailableActions` | 继续阅读、查看新旧差异、刷新、Revert |
| `ForbiddenActions` | 将旧表达当 CURRENT、无提示基于其编辑 |
| `PersistenceRule` | 状态跨刷新持久 |
| `URLHistoryRule` | 不新增 History |
| `KeyboardBehavior` | 焦点可继续阅读；编辑入口需警告 |
| `TouchBehavior` | 触控同等 |
| `EmptyState` | 无旧表达时使用 Canonical 降级 |
| `ErrorState` | 旧表达加载失败显示纯文本 |
| `AccessibilityAnnouncement` | “正在显示旧表达，正式结构已更新” |
| `HighFidelityEvidence` | 过期标记、阅读允许和修订限制证据 |


#### `NEW_EXPRESSION_PENDING_CONFIRMATION`

| Field | Contract |
|---|---|
| `StateCode` | NEW_EXPRESSION_PENDING_CONFIRMATION |
| `Purpose` | 新表达与锁定/用户内容冲突，等待确认 |
| `EntryCondition` | 生成候选触及锁定内容或需人工选择 |
| `ExitCondition` | 确认、拒绝、局部合并、Revert |
| `PrimaryFocus` | 候选与锁定内容差异 |
| `SecondaryContext` | 新 Canonical、旧表达、用户锁定 |
| `VisualPriority` | 差异和决定最高 |
| `VisibleContent` | Before/After、冲突字段、影响范围 |
| `AvailableActions` | 确认、保持锁定、局部合并、核验、Revert |
| `ForbiddenActions` | 自动采纳、隐藏来源冲突 |
| `PersistenceRule` | 决定状态跨刷新持久 |
| `URLHistoryRule` | 需要用户决定时创建稳定 History State |
| `KeyboardBehavior` | 焦点进入首个冲突；Escape 返回但保留待确认 |
| `TouchBehavior` | 小屏逐项比较，提供总览 |
| `EmptyState` | 无冲突项时自动完成 |
| `ErrorState` | 差异加载失败阻止确认 |
| `AccessibilityAnnouncement` | “新表达等待确认，涉及锁定内容” |
| `HighFidelityEvidence` | 锁定冲突、局部合并和保持旧版证据 |


#### `PENDING_REVERIFICATION`

| Field | Contract |
|---|---|
| `StateCode` | PENDING_REVERIFICATION |
| `Purpose` | 来源或陈述变化后需要重新核验 |
| `EntryCondition` | Evidence Binding 失效、Relation 变化或候选采纳 |
| `ExitCondition` | 核验通过、降级、否决或保留冲突 |
| `PrimaryFocus` | 待核验对象/Relation |
| `SecondaryContext` | 当前版本和旧证据 |
| `VisualPriority` | 状态附着；核心结论失去唯一来源时提高权重 |
| `VisibleContent` | 待核验原因、受影响谓词/方向/条件 |
| `AvailableActions` | 进入核验、补源、降级确定性、保留冲突 |
| `ForbiddenActions` | 继续标为已验证、隐藏核心风险 |
| `PersistenceRule` | 跨刷新持久 |
| `URLHistoryRule` | 目标稳定状态可编码；不一定新路由 |
| `KeyboardBehavior` | Enter 打开核验 |
| `TouchBehavior` | 点击状态打开核验 |
| `EmptyState` | 无来源显示来源缺口 |
| `ErrorState` | 核验服务失败保留待核验 |
| `AccessibilityAnnouncement` | “当前关系/对象需要重新核验” |
| `HighFidelityEvidence` | 轻量状态与核心风险增强证据 |


#### `VERIFIED`

| Field | Contract |
|---|---|
| `StateCode` | VERIFIED |
| `Purpose` | 确认当前版本的证据支持状态已完成核验 |
| `EntryCondition` | 核验裁决保存成功 |
| `ExitCondition` | 来源失效、版本变化或新冲突 |
| `PrimaryFocus` | 已核验对象/Relation |
| `SecondaryContext` | 证据绑定与裁决历史 |
| `VisualPriority` | 普通状态低调附着 |
| `VisibleContent` | 必要的可理解来源状态 |
| `AvailableActions` | 查看来源、重新核验 |
| `ForbiddenActions` | 将 verified 解释为绝对真理或百分比 |
| `PersistenceRule` | 正式状态跨刷新 |
| `URLHistoryRule` | 不单独创建 History |
| `KeyboardBehavior` | 状态可朗读 |
| `TouchBehavior` | 触控同等 |
| `EmptyState` | 无证据不得进入 VERIFIED |
| `ErrorState` | 状态读取失败降级待核验 |
| `AccessibilityAnnouncement` | “当前版本已完成来源核验” |
| `HighFidelityEvidence` | 已核验状态不过度突出证据 |


#### `PARTIAL_FAILURE`

| Field | Contract |
|---|---|
| `StateCode` | PARTIAL_FAILURE |
| `Purpose` | 汇总正式保存成功但一个或多个后续处理失败 |
| `EntryCondition` | 重算、生成、核验或投影更新部分失败 |
| `ExitCondition` | 全部重试成功、Revert 或人工关闭但保留状态 |
| `PrimaryFocus` | 新 Canonical Version |
| `SecondaryContext` | 失败任务、旧投影与原 Focus |
| `VisualPriority` | 保存成功与失败范围同时清晰 |
| `VisibleContent` | 已保存边界、失败清单、阅读/修订限制 |
| `AvailableActions` | 逐项重试、查看差异、继续阅读、Revert |
| `ForbiddenActions` | 笼统显示提交失败、隐藏过期投影 |
| `PersistenceRule` | 跨刷新持久直到处理完毕 |
| `URLHistoryRule` | 结果状态可由 ChangeSet 恢复 |
| `KeyboardBehavior` | 焦点保持原 Target；错误逐项可达 |
| `TouchBehavior` | 小屏用汇总层，不常驻默认阅读 |
| `EmptyState` | 无失败项不得进入 |
| `ErrorState` | 状态服务失败通过 ChangeSet 重建 |
| `AccessibilityAnnouncement` | “正式结构已保存，但部分后续处理失败” |
| `HighFidelityEvidence` | 部分成功、逐项恢复和不重复提交证据 |


### 5.4 返回与恢复状态


#### `CLOSE_AUXILIARY_PANEL`

| Field | Contract |
|---|---|
| `StateCode` | CLOSE_AUXILIARY_PANEL |
| `Purpose` | 关闭 Quick Source 等辅助层而不改变主聚焦 |
| `EntryCondition` | 用户关闭、Escape 或完成轻量查看 |
| `ExitCondition` | 返回原 Focus |
| `PrimaryFocus` | 原稳定对象/Relation |
| `SecondaryContext` | 被关闭面板的最后焦点 |
| `VisualPriority` | 主 Focus 恢复最高 |
| `VisibleContent` | 原正文和 Focus Summary |
| `AvailableActions` | 继续阅读、重新打开面板 |
| `ForbiddenActions` | 清除稳定 Focus、改变模式 |
| `PersistenceRule` | 不单独持久；结果恢复原状态 |
| `URLHistoryRule` | 不创建 History |
| `KeyboardBehavior` | Escape/关闭后焦点归还触发入口 |
| `TouchBehavior` | 点击关闭/遮罩 |
| `EmptyState` | 面板不存在时无操作 |
| `ErrorState` | 焦点归还失败落到 Focus 标题 |
| `AccessibilityAnnouncement` | “辅助面板已关闭，返回……” |
| `HighFidelityEvidence` | 关闭前后焦点与上下文不变证据 |


#### `CLOSE_RELATION_FOCUS`

| Field | Contract |
|---|---|
| `StateCode` | CLOSE_RELATION_FOCUS |
| `Purpose` | 关闭 Relation 主聚焦并恢复进入前对象 |
| `EntryCondition` | Escape、显式关闭或返回对象 |
| `ExitCondition` | 恢复原 Element/Module 或失败恢复 |
| `PrimaryFocus` | 原对象快照 |
| `SecondaryContext` | 刚关闭 Relation 和端点 |
| `VisualPriority` | 原对象恢复最高 |
| `VisibleContent` | 原对象 Summary、阅读 Anchor、Perspective |
| `AvailableActions` | 继续对象阅读、再次聚焦关系 |
| `ForbiddenActions` | 直接回 IDLE、丢失原 Anchor |
| `PersistenceRule` | 恢复快照跨 History 有效 |
| `URLHistoryRule` | History 返回到对象状态，不新增 |
| `KeyboardBehavior` | Escape 执行；焦点落原关系入口或对象标题 |
| `TouchBehavior` | 显式关闭按钮；不靠空白区 |
| `EmptyState` | 无原对象时恢复 Module Closure |
| `ErrorState` | 原对象失效进入 RESTORE_FAILED |
| `AccessibilityAnnouncement` | “关系聚焦已关闭，恢复对象……” |
| `HighFidelityEvidence` | Relation→Element 恢复证据 |


#### `RESTORE_ORIGIN_OBJECT`

| Field | Contract |
|---|---|
| `StateCode` | RESTORE_ORIGIN_OBJECT |
| `Purpose` | 从端点、Workspace 或跨视图恢复原认知对象 |
| `EntryCondition` | 关闭 Relation/Workspace、History/Route Return |
| `ExitCondition` | 成功固定原对象或进入失败 |
| `PrimaryFocus` | Origin Object |
| `SecondaryContext` | 当前 Target 与 ReturnToken |
| `VisualPriority` | 原对象逐步恢复；避免闪回默认页 |
| `VisibleContent` | 原 Focus、原滚动 Anchor、原 Perspective |
| `AvailableActions` | 继续阅读、查看变更后的对象 |
| `ForbiddenActions` | 创建对象副本、恢复旧版本为当前 |
| `PersistenceRule` | 稳定快照；按 ID 对齐新版本 |
| `URLHistoryRule` | 由现有 History 状态恢复 |
| `KeyboardBehavior` | 焦点落语义 Anchor |
| `TouchBehavior` | 触控滚动到 Anchor |
| `EmptyState` | 原对象无内容时落上级 |
| `ErrorState` | 对象删除时显示替代/上级路径 |
| `AccessibilityAnnouncement` | “正在/已恢复原对象” |
| `HighFidelityEvidence` | 跨 Workspace 和版本后的对象恢复证据 |


#### `RESTORE_COGNITIVE_PERSPECTIVE`

| Field | Contract |
|---|---|
| `StateCode` | RESTORE_COGNITIVE_PERSPECTIVE |
| `Purpose` | 恢复进入辅助状态前的认知视角 |
| `EntryCondition` | 关闭 Relation/Workspace、History Back 或显式恢复 |
| `ExitCondition` | 视角投影加载成功或回退 OVERALL |
| `PrimaryFocus` | 原 Perspective 下的同一 Target |
| `SecondaryContext` | 当前临时视角 |
| `VisualPriority` | Target 不变，仅权重恢复 |
| `VisibleContent` | 原视角说明和被强调内容 |
| `AvailableActions` | 继续阅读、切换视角 |
| `ForbiddenActions` | 改变 Canonical、隐藏核心正文 |
| `PersistenceRule` | 稳定状态可恢复 |
| `URLHistoryRule` | Perspective 写 URL/History 的上一值 |
| `KeyboardBehavior` | 焦点保持同一 Target |
| `TouchBehavior` | 触控同等 |
| `EmptyState` | 原视角不可用时 OVERALL |
| `ErrorState` | 投影失败回退 OVERALL 并说明 |
| `AccessibilityAnnouncement` | “认知视角已恢复为……” |
| `HighFidelityEvidence` | Perspective 前后 Target 不变证据 |


#### `SOFT_RETURN`

| Field | Contract |
|---|---|
| `StateCode` | SOFT_RETURN |
| `Purpose` | 关闭最上层交互并恢复上一稳定语义状态 |
| `EntryCondition` | Escape、面板返回、Workspace 关闭 |
| `ExitCondition` | 上一稳定状态恢复 |
| `PrimaryFocus` | 上一稳定 Focus |
| `SecondaryContext` | 关闭层的 Target 和 Anchor |
| `VisualPriority` | 逐层恢复，不路由跳转 |
| `VisibleContent` | 上一状态正文和 Focus |
| `AvailableActions` | 继续操作或再次进入 |
| `ForbiddenActions` | 跨页返回、清空草稿 |
| `PersistenceRule` | 当前页内恢复 |
| `URLHistoryRule` | 通常不创建 History；可调用 history.back 到最近稳定状态 |
| `KeyboardBehavior` | Escape 核心语义 |
| `TouchBehavior` | 显式返回按钮 |
| `EmptyState` | 无上层时保持 IDLE |
| `ErrorState` | 恢复失败进入 RESTORE_FAILED |
| `AccessibilityAnnouncement` | “返回上一交互状态” |
| `HighFidelityEvidence` | 层级关闭顺序证据 |


#### `HARD_RESET`

| Field | Contract |
|---|---|
| `StateCode` | HARD_RESET |
| `Purpose` | 清除局部探索并回到当前页面默认阅读 |
| `EntryCondition` | 显式“返回整体/重置”并确认必要草稿保护 |
| `ExitCondition` | IDLE/页面默认 |
| `PrimaryFocus` | 页面核心问题或 Module Closure |
| `SecondaryContext` | Primary Spine |
| `VisualPriority` | 默认阅读最高 |
| `VisibleContent` | 零交互完整内容 |
| `AvailableActions` | 重新聚焦、改变模式 |
| `ForbiddenActions` | 静默丢草稿、路由离开、改变 Canonical |
| `PersistenceRule` | 重置结果稳定；草稿另行保留/处理 |
| `URLHistoryRule` | 更新 URL 移除 focus/relation/perspective；创建稳定 History |
| `KeyboardBehavior` | 需要明确操作；Escape 不等同 HARD_RESET |
| `TouchBehavior` | 显式按钮；避免误触 |
| `EmptyState` | 页面无默认内容显示缺口 |
| `ErrorState` | 默认投影失败降级正文 |
| `AccessibilityAnnouncement` | “已返回页面默认阅读状态” |
| `HighFidelityEvidence` | 有无草稿的重置确认与结果证据 |


#### `ROUTE_RETURN`

| Field | Contract |
|---|---|
| `StateCode` | ROUTE_RETURN |
| `Purpose` | 返回上一认知页面并恢复 ContextReturnToken |
| `EntryCondition` | 页面内返回、面包屑或浏览器语义返回 |
| `ExitCondition` | 上一页面及快照恢复 |
| `PrimaryFocus` | 上一页面的原 Focus |
| `SecondaryContext` | 当前页面和进入关系 |
| `VisualPriority` | 上一页面认知中心最高 |
| `VisibleContent` | 原模式、Focus、关系家族、Perspective、Anchor |
| `AvailableActions` | 继续阅读、再次进入 |
| `ForbiddenActions` | 只返回路由默认页、丢失上下文 |
| `PersistenceRule` | ReturnToken 会话/History 持久 |
| `URLHistoryRule` | 页面路由与稳定状态创建 History |
| `KeyboardBehavior` | 焦点落原 Anchor |
| `TouchBehavior` | 触控返回栏 |
| `EmptyState` | 无 Token 时返回上级默认并说明 |
| `ErrorState` | Token 失效进入恢复失败 |
| `AccessibilityAnnouncement` | “返回上一认知页面并恢复……” |
| `HighFidelityEvidence` | Domain↔Theme↔Module 往返证据 |


#### `HISTORY_RESTORE`

| Field | Contract |
|---|---|
| `StateCode` | HISTORY_RESTORE |
| `Purpose` | 浏览器前进/后退恢复上一稳定语义状态 |
| `EntryCondition` | popstate 到稳定快照 |
| `ExitCondition` | 恢复成功或 RESTORE_FAILED |
| `PrimaryFocus` | 快照中的主 Focus/Workspace |
| `SecondaryContext` | 页面、模式、Perspective、Anchor |
| `VisualPriority` | 按快照恢复，不回放临时 UI |
| `VisibleContent` | 稳定语义状态和必要草稿 Guard |
| `AvailableActions` | 继续、前进/后退 |
| `ForbiddenActions` | 逐个回放 Hover/Tooltip/动画 |
| `PersistenceRule` | History State 持久，需版本兼容 |
| `URLHistoryRule` | 严格使用稳定语义快照 |
| `KeyboardBehavior` | 焦点恢复到快照 Target |
| `TouchBehavior` | 系统返回手势同等 |
| `EmptyState` | 快照无 Target 时页面默认 |
| `ErrorState` | 版本不兼容执行 ID 对齐/上级回退 |
| `AccessibilityAnnouncement` | “浏览器历史已恢复到……” |
| `HighFidelityEvidence` | 典型链 Impact→Revision→Relation→Element→Perspective→Page 证据 |


#### `REFRESH_RESTORE`

| Field | Contract |
|---|---|
| `StateCode` | REFRESH_RESTORE |
| `Purpose` | 页面刷新后恢复稳定状态与草稿 |
| `EntryCondition` | 重新加载并读取 URL/History/会话状态 |
| `ExitCondition` | 恢复完成或失败 |
| `PrimaryFocus` | 稳定主 Focus/Workspace |
| `SecondaryContext` | Perspective、Anchor、ChangeSet 状态 |
| `VisualPriority` | 先恢复页面，再恢复 Target，避免错误闪烁 |
| `VisibleContent` | 页面、模式、Focus、Workspace、草稿、处理状态 |
| `AvailableActions` | 继续、刷新失败重试、回退上级 |
| `ForbiddenActions` | 恢复 Hover/Tooltip/动画/无语义游标 |
| `PersistenceRule` | 稳定状态和 Durable Draft 恢复 |
| `URLHistoryRule` | URL+History+会话联合恢复 |
| `KeyboardBehavior` | 焦点落恢复 Target 或标题 |
| `TouchBehavior` | 触控无差异 |
| `EmptyState` | 目标缺失执行替代/上级回退 |
| `ErrorState` | 服务端状态未知先查询 ChangeSet |
| `AccessibilityAnnouncement` | “页面已刷新并恢复到……” |
| `HighFidelityEvidence` | 刷新前后对象、Relation、草稿和处理状态一致证据 |


#### `RESTORE_FAILED`

| Field | Contract |
|---|---|
| `StateCode` | RESTORE_FAILED |
| `Purpose` | 明确无法精确恢复原语义位置并提供安全降级 |
| `EntryCondition` | 目标删除、Anchor 移动、版本不兼容或状态缺失 |
| `ExitCondition` | 选择替代对象、上级、页面默认或重试 |
| `PrimaryFocus` | 最近可用上级/页面核心问题 |
| `SecondaryContext` | 失效目标信息和 ReturnToken |
| `VisualPriority` | 错误说明清晰但仍可阅读 |
| `VisibleContent` | 失败原因、已保留内容、可用替代路径 |
| `AvailableActions` | 重试、进入替代、上级、默认阅读、查看变更 |
| `ForbiddenActions` | 空白页、静默回默认、恢复旧副本 |
| `PersistenceRule` | 失败记录会话级；不创建 Canonical |
| `URLHistoryRule` | 可替换当前 History State 避免循环失败 |
| `KeyboardBehavior` | 焦点落恢复说明标题 |
| `TouchBehavior` | 触控按钮足够明确 |
| `EmptyState` | 无替代对象时页面默认阅读 |
| `ErrorState` | 连续失败提供诊断码 |
| `AccessibilityAnnouncement` | “无法恢复原位置，已保留到最近可用上下文” |
| `HighFidelityEvidence` | Anchor 移动、对象删除、替代和默认回退证据 |


---

## 6. 点击、关闭与聚焦切换矩阵

### 6.1 正式不变量

```text
ClickSameObjectToToggleFocus = FORBIDDEN
DoubleClickAsUniqueCapability = FORBIDDEN
BlankAreaClosesPinnedFocus = NO
OneStablePrimaryFocus = REQUIRED
InteractionLayerCloseOrder = TOPMOST_FIRST
DirtyDraftProtectionBeforeTargetChange = REQUIRED
DuplicateFormalVersion = FORBIDDEN
```

双击只允许作为桌面增强导航，例如直接进入 Theme 或 Module；同一能力必须存在可见按钮、单击后操作或键盘入口。

### 6.2 行为矩阵

| 当前状态 | 用户操作 | 正式结果 | History | 草稿保护 | 高保真必须证明 |
|---|---|---|---|---|---|
| 无聚焦 | 单击 Element | Element 成为唯一主聚焦，进入 `ELEMENT_PINNED_FOCUS` | 创建稳定快照 | 不适用 | 正文仍完整，Focus Summary 明确 |
| Element 已聚焦 | 再次单击同一 Element | 保持聚焦；定位或展开 Focus Summary，不切换关闭 | 不新增 | 保持 | 同一对象无闪烁、无状态反转 |
| Element A 聚焦 | 单击 Element B | B 原子替代 A，A 降为普通上下文 | 创建稳定快照 | 若 A 有草稿先保护 | 任何时刻只有一个主聚焦 |
| Element 聚焦 | 单击 Relation | Relation 替代 Element 成为主聚焦；Element 写入返回快照 | 创建稳定快照 | 若 Element 编辑中先保护 | Relation、端点、原对象层级清楚 |
| Relation A 聚焦 | 单击 Relation B | B 替代 A；保留 B 的进入来源 | 创建稳定快照 | 若 A 有草稿先保护 | 不并列高亮两条 Relation |
| Relation 聚焦 | 单击起点或终点 | 端点成为新 `ELEMENT_PINNED_FOCUS`；Relation 进入返回快照 | 创建稳定快照 | 有草稿先保护 | 可返回 Relation，端点成为唯一中心 |
| Quick Source 打开 | 切换对象 | 无草稿时面板跟随新对象；有草稿时先进入草稿保护 | 对象切换才创建 | REQUIRED | 面板不显示旧对象来源 |
| 完整核验打开 | 切换对象 | 无草稿时按明确操作切换并更新 Workspace；不得因 Preview 自动跟随 | 创建稳定快照 | REQUIRED | 当前核验 Target 始终可见 |
| 修订草稿存在 | 点击其他对象 | 不得静默切换；显示保存、丢弃、继续编辑 | 未决定前不创建 | REQUIRED | 草稿不丢失，新对象未提前激活 |
| 当前对象已聚焦 | 点击页面空白 | 不关闭稳定聚焦；仅关闭允许被外部点击关闭的临时 Preview/Tooltip | 不新增 | 保持 | Pinned Focus 稳定 |
| Preview 存在 | 点击空白或 Escape | 关闭 Preview，恢复原稳定状态 | 不新增 | 不适用 | 无页面跳动和 Focus 丢失 |
| Relation 聚焦 | Escape | 关闭 Relation Focus，恢复进入前对象和 Anchor | 返回上一稳定快照 | 保持 | 恢复对象而非默认页 |
| Element 聚焦 | Escape | 返回当前页面默认阅读状态；保留模式和页面 | 返回/替换稳定快照 | 若有编辑草稿先保护 | 默认阅读零交互完整 |
| Quick Source | Escape | 只关闭 Quick Source，保留对象/Relation Focus | 不新增 | 保持 | 焦点归还来源入口 |
| 完整 Workspace | Escape | 关闭最上层弹层或子状态；再次 Escape 才离开 Workspace | 按稳定层级返回 | REQUIRED | 不一次穿透多个交互层 |
| 修订编辑中 | Escape | 关闭最上层状态，不丢弃草稿；必要时回到修订主体 | 不新增或回上一稳定层 | REQUIRED | 草稿提示持续存在 |
| 影响预览中 | Escape | 返回修订编辑，保留影响结果和草稿 | 返回修订稳定快照 | REQUIRED | 三类影响不会因返回丢失 |
| 提交处理中 | 重复点击提交 | 忽略重复动作，复用同一幂等键并查询同一结果 | 不新增 | 草稿冻结 | 只产生一个 ChangeSet |
| 认知视角覆盖 | Escape 或恢复整体 | 恢复上一 Perspective 或 `OVERALL`，Target 不变 | 返回上一稳定视角 | 保持 | 核心正文始终存在 |
| 小屏临时 Workspace | 系统返回手势 | 等价于关闭最上层 Workspace；有草稿先保护 | 语义稳定返回 | REQUIRED | 不直接退出页面或丢草稿 |

### 6.3 关闭优先级

```text
TooltipOrPreview
→ QuickSourcePanel
→ WorkspaceSubLayer
→ ImpactPreview
→ FullWorkspace
→ RelationFocus
→ ElementFocus
→ PageDefaultReading
```

`Escape`、关闭按钮、浏览器返回和移动端系统返回必须遵守语义层级，但浏览器返回只恢复稳定快照，不逐个回放 Tooltip、Hover 或动画。

---

## 7. URL、浏览器历史与刷新恢复契约

### 7.1 URL 稳定状态字段

以下字段允许进入可分享 URL 或等价路由状态：

```text
workspaceId
pageLevel
pageObjectId
mode
primaryFocusKind
primaryFocusId
activeRelationId
cognitivePerspective
```

约束：

```text
CanonicalVersionMayBeResolvedAtLoad = YES
DraftContentInURL = FORBIDDEN
RawSourceExcerptInURL = FORBIDDEN
SensitiveGovernanceStateInURL = FORBIDDEN
```

`primaryFocusId` 与 `activeRelationId` 使用稳定 ID；加载时解析当前有效版本。需要精确历史快照时，版本信息保存在 History State 或受控会话恢复对象中，不强制暴露于普通可分享 URL。

### 7.2 不进入 URL 的状态

```text
Hover
Tooltip
KeyboardPreview
TemporaryEndpointHighlight
PanelWidth
TransientAnimation
QuickSourceExcerptHighlight
InputFocus
TemporaryScrollPixel
```

这些状态不得创建浏览器历史，也不得在刷新后恢复。

### 7.3 创建稳定浏览器历史快照

至少包括：

1. 固定新的主聚焦对象；
2. Relation 成为主聚焦；
3. 进入完整核验；
4. 进入完整修订；
5. 打开完整影响预览；
6. 切换认知视角；
7. 页面路由变化；
8. 从 Relation 端点切换到新的 Element 主聚焦；
9. 执行 HARD_RESET 后形成页面默认稳定状态。

### 7.4 不创建历史快照

至少包括：

- Hover；
- 键盘 Preview；
- Tooltip；
- Quick Source 轻量展开；
- 调整面板宽度；
- 展开纯说明文本；
- 动画开始或结束；
- 同一对象再次单击并定位 Focus Summary；
- 输入字段之间的 Tab 移动。

### 7.5 浏览器返回语义顺序

```text
DirtyDraftGuard
→ ImpactPreview
→ RevisionOrVerification
→ RelationFocus
→ ElementFocus
→ PreviousCognitivePerspective
→ PreviousPage
```

浏览器返回必须恢复上一稳定语义状态，而不是逐个回放临时 UI。

存在未提交草稿时：

```text
BrowserBackWithDirtyDraft =
  ENTER_DRAFT_PROTECTION_FIRST
```

在用户作出保存、丢弃或继续编辑决定前，不得离开当前稳定修订状态。

### 7.6 页面刷新恢复

刷新后必须恢复：

```text
CurrentPage
CurrentMode
CurrentStablePrimaryFocus
CurrentRelationFocus
CurrentCognitivePerspective
CurrentFullWorkspace
CurrentDurableDraft
CurrentChangeSetProcessingResult
CompatibleSemanticAnchor
```

刷新后不得恢复：

```text
Hover
Tooltip
TemporaryPreview
TransientAnimation
NonSemanticKeyboardCursor
TemporaryEndpointHighlight
QuickSourceExcerptHighlight
```

恢复算法：

```text
LoadRoute
→ ResolveCurrentCanonicalVersion
→ RestoreStablePrimaryFocusById
→ RestoreModeAndWorkspace
→ RestoreDraftAndChangeSetState
→ MapSemanticAnchor
→ AnnounceRestoredState
```

若正式版本已变化：

1. 保留稳定对象或 Relation ID；
2. 比较旧基线与当前版本；
3. 草稿进入重新基线化或 `CONFLICTED_DRAFT`；
4. 尝试迁移语义 Anchor；
5. 无法精确恢复时进入 `RESTORE_FAILED`，不得静默落回默认页。

### 7.7 History State 最低结构

```json
{
  "route": {
    "workspaceId": "ws_x",
    "pageLevel": "MODULE",
    "pageObjectId": "module_x",
    "mode": "READING"
  },
  "focus": {
    "primaryFocusKind": "RELATION",
    "primaryFocusId": "rel_x",
    "originObjectId": "el_x"
  },
  "cognitivePerspective": "CONDITIONS",
  "workspace": {
    "kind": "NONE",
    "targetId": null
  },
  "anchor": {
    "semanticAnchorId": "statement_x",
    "fallbackObjectId": "el_x"
  },
  "draftGuard": {
    "draftId": null,
    "dirty": false
  }
}
```

History State 是恢复输入，不是 Canonical Knowledge Carrier。

---

## 8. Exception and Recovery State Matrix

### 8.0 正式不变量

```text
SilentDataLoss = FORBIDDEN
SilentCanonicalRollback = FORBIDDEN
StaleProjectionAsCurrent = FORBIDDEN
DuplicateFormalVersion = FORBIDDEN
UnknownSaveResultTreatedAsFailure = FORBIDDEN
RecoveryMustPreserveCognitiveContext = REQUIRED
```

### 8.1 `EX-PREVIEW-TARGET-DELETED`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-PREVIEW-TARGET-DELETED |
| `Trigger` | 刷新后 Preview 目标已删除 |
| `UserVisibleState` | 关闭临时 Preview，提示目标已不存在；原稳定 Focus 不变 |
| `CanonicalSavedBoundary` | 无正式写入 |
| `UnsavedBoundary` | 仅临时 Preview 状态 |
| `ReadingAllowed` | YES |
| `CommitAllowed` | N/A |
| `AvailableRecoveryActions` | 继续阅读、定位上级或搜索替代对象 |
| `RetryRule` | 可刷新目标索引一次 |
| `RollbackRule` | 无需 Canonical 回退 |
| `DuplicatePrevention` | Preview 从不创建版本 |
| `FocusRecovery` | 保留原稳定 Focus；无原 Focus 则 IDLE |
| `AccessibilityAnnouncement` | “预览目标已不存在，已返回原阅读状态” |

### 8.2 `EX-RELATION-SUPERSEDED`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-RELATION-SUPERSEDED |
| `Trigger` | 当前聚焦 Relation 被其他修订替代 |
| `UserVisibleState` | 显示旧 Relation 已被新版本/新 Relation 替代及差异入口 |
| `CanonicalSavedBoundary` | 其他修订产生的新版本已保存 |
| `UnsavedBoundary` | 当前本地临时查看状态；若有草稿则仍未保存 |
| `ReadingAllowed` | YES_WITH_EXPLICIT_STATUS |
| `CommitAllowed` | 仅在草稿重新基线化并重跑影响后 |
| `AvailableRecoveryActions` | 查看新版本、映射到替代 Relation、保存草稿、重新基线化 |
| `RetryRule` | 允许按 relationId/lineage 重试解析 |
| `RollbackRule` | 不得静默回滚其他已保存修订 |
| `DuplicatePrevention` | 提交使用 ChangeSet 幂等键和 baseVersion 检查 |
| `FocusRecovery` | 优先恢复新 relationId/version；无法映射则回原对象 |
| `AccessibilityAnnouncement` | “当前关系已更新，需要重新核对后继续修订” |

### 8.3 `EX-ELEMENT-PRIMARY-PARENT-CHANGED`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-ELEMENT-PRIMARY-PARENT-CHANGED |
| `Trigger` | Element 聚焦期间主归属被修改 |
| `UserVisibleState` | 显示主归属已变化，保留 Element 身份与旧/新位置 |
| `CanonicalSavedBoundary` | 新主归属版本已保存 |
| `UnsavedBoundary` | 当前页面旧 Context Projection 可能过期 |
| `ReadingAllowed` | YES_WITH_STALE_MARK |
| `CommitAllowed` | 基于旧 Context 的提交 BLOCKED |
| `AvailableRecoveryActions` | 跳转新主归属、保留当前上下文查看、刷新 Projection |
| `RetryRule` | 允许重载 Context Binding |
| `RollbackRule` | 可发起独立 Revert ChangeSet，不自动回退 |
| `DuplicatePrevention` | baseVersion 和 contextBindingVersion 防重复/错提 |
| `FocusRecovery` | 保持 objectId，Anchor 迁移到新主归属或当前上级 |
| `AccessibilityAnnouncement` | “对象主归属已改变，当前上下文已标记过期” |

### 8.4 `EX-AUTO-UPGRADE-FAILED`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-AUTO-UPGRADE-FAILED |
| `Trigger` | 快速修订自动升级到完整修订失败 |
| `UserVisibleState` | 显示升级原因、失败原因和草稿已保留状态 |
| `CanonicalSavedBoundary` | 无新的正式保存 |
| `UnsavedBoundary` | 快速修订草稿未提交 |
| `ReadingAllowed` | YES |
| `CommitAllowed` | NO |
| `AvailableRecoveryActions` | 重试升级、导出/保存草稿、返回快速修订、取消 |
| `RetryRule` | 复用同一 draftId 重试 |
| `RollbackRule` | 无需 Canonical 回退 |
| `DuplicatePrevention` | 升级不创建版本；重试不得复制草稿 |
| `FocusRecovery` | 恢复原 Element/Relation Focus 和 QUICK_REVISION |
| `AccessibilityAnnouncement` | “升级失败，草稿已保留，提交被阻止” |

### 8.5 `EX-IMPACT-ANALYSIS-FAILED`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-IMPACT-ANALYSIS-FAILED |
| `Trigger` | 任一影响通道失败或结果版本不匹配 |
| `UserVisibleState` | 三类影响中失败通道明确标红，Blocker 默认展开 |
| `CanonicalSavedBoundary` | 无新的正式保存 |
| `UnsavedBoundary` | ChangeSet 草稿未提交 |
| `ReadingAllowed` | YES |
| `CommitAllowed` | NO |
| `AvailableRecoveryActions` | 重试失败通道、修改草稿、保存草稿、取消 |
| `RetryRule` | 结果绑定 draftRevision；仅重算失效通道 |
| `RollbackRule` | 无需 Canonical 回退 |
| `DuplicatePrevention` | 同一分析请求幂等，旧结果不可复用 |
| `FocusRecovery` | 保留 FULL_REVISION 和当前字段 Anchor |
| `AccessibilityAnnouncement` | “影响分析失败，正式提交已阻止” |

### 8.6 `EX-CANONICAL-SAVED-RECOMPUTE-FAILED`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-CANONICAL-SAVED-RECOMPUTE-FAILED |
| `Trigger` | 正式结构保存成功但重新计算失败 |
| `UserVisibleState` | 同时显示“结构已保存”和“重算失败”，旧投影标 OUTDATED |
| `CanonicalSavedBoundary` | Canonical Version、ChangeSet、当前指针已保存 |
| `UnsavedBoundary` | Spine/Closure/布局等新 Projection 未完成 |
| `ReadingAllowed` | YES_WITH_OLD_EXPRESSION_MARK |
| `CommitAllowed` | 基于过期投影的进一步修订 BLOCKED_OR_REBASE_REQUIRED |
| `AvailableRecoveryActions` | 重试重算、查看 Canonical 差异、继续阅读旧表达、Revert |
| `RetryRule` | 任务按 ChangeSet+projectionType 幂等重试 |
| `RollbackRule` | 只能通过新 Revert ChangeSet |
| `DuplicatePrevention` | 不得重复创建 Canonical Version |
| `FocusRecovery` | 保持同一 objectId/relationId 和原 Anchor |
| `AccessibilityAnnouncement` | “正式结构已保存，但重新计算失败” |

### 8.7 `EX-CANONICAL-SAVED-GENERATION-FAILED`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-CANONICAL-SAVED-GENERATION-FAILED |
| `Trigger` | 正式结构保存成功但局部重新生成失败 |
| `UserVisibleState` | 显示旧表达保留、版本过期和生成失败范围 |
| `CanonicalSavedBoundary` | Canonical Version 和 ChangeSet 已保存 |
| `UnsavedBoundary` | 新解释/摘要/结构投影未生成 |
| `ReadingAllowed` | YES_WITH_OLD_EXPRESSION_MARK |
| `CommitAllowed` | 旧表达上提交 BLOCKED_OR_REBASE_REQUIRED |
| `AvailableRecoveryActions` | 重试生成、查看 Canonical 文本、继续阅读旧表达、Revert |
| `RetryRule` | 生成任务使用唯一 task key |
| `RollbackRule` | 通过 Revert ChangeSet，不回滚数据库假装未提交 |
| `DuplicatePrevention` | 同一 ChangeSet 不生成重复正式版本 |
| `FocusRecovery` | 保持原 Focus；旧表达 Anchor 可继续使用 |
| `AccessibilityAnnouncement` | “正式结构已保存，新表达生成失败，当前显示旧表达” |

### 8.8 `EX-GENERATED-CONFLICTS-LOCKED`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-GENERATED-CONFLICTS-LOCKED |
| `Trigger` | 新生成内容与用户锁定内容冲突 |
| `UserVisibleState` | 显示候选差异、锁定范围和待确认状态 |
| `CanonicalSavedBoundary` | Canonical 结构可能已保存；锁定正式表达仍有效 |
| `UnsavedBoundary` | 候选表达尚未确认 |
| `ReadingAllowed` | YES |
| `CommitAllowed` | NO_UNTIL_DECISION |
| `AvailableRecoveryActions` | 保持锁定、采纳候选、局部合并、核验、Revert |
| `RetryRule` | 候选生成可重试但不得覆盖锁定 |
| `RollbackRule` | Revert 仅针对已保存 ChangeSet |
| `DuplicatePrevention` | 候选不创建正式版本，确认操作带幂等决策 ID |
| `FocusRecovery` | 保持原 Target，定位首个冲突字段 |
| `AccessibilityAnnouncement` | “生成候选与锁定内容冲突，等待确认” |

### 8.9 `EX-DRAFT-CONFLICTS-LATEST`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-DRAFT-CONFLICTS-LATEST |
| `Trigger` | 草稿基于旧正式版本，最新版本已变化 |
| `UserVisibleState` | Before/Latest/Draft 三方差异和冲突字段 |
| `CanonicalSavedBoundary` | 最新正式版本由其他 ChangeSet 保存 |
| `UnsavedBoundary` | 当前草稿未提交 |
| `ReadingAllowed` | YES |
| `CommitAllowed` | NO_UNTIL_REBASE |
| `AvailableRecoveryActions` | 重新基线化、手工合并、保留草稿副本、丢弃 |
| `RetryRule` | 重新加载最新版本后可重试影响分析 |
| `RollbackRule` | 不得回滚他人新版本；可另发 Revert |
| `DuplicatePrevention` | 提交必须校验 baseVersion，冲突不创建版本 |
| `FocusRecovery` | 保持原 objectId/relationId，Anchor 映射到最新版本 |
| `AccessibilityAnnouncement` | “草稿与最新正式版本冲突，需要重新基线化” |

### 8.10 `EX-SOURCE-INVALIDATED`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-SOURCE-INVALIDATED |
| `Trigger` | 来源失效使 Relation 重新进入待核验 |
| `UserVisibleState` | 具体谓词/方向/条件附着“来源失效/待核验” |
| `CanonicalSavedBoundary` | Relation 当前版本仍保存；Evidence Binding 状态变化已保存或待处理 |
| `UnsavedBoundary` | 新的替代来源和核验裁决未保存 |
| `ReadingAllowed` | YES_WITH_STATUS |
| `CommitAllowed` | 核心关系失去唯一支持时结构提交受限 |
| `AvailableRecoveryActions` | 替换来源、降级确定性、保留历史引用、重新核验 |
| `RetryRule` | 来源重新抓取和核验可重试 |
| `RollbackRule` | 无需自动回滚 Relation；必要时用户发起修订 |
| `DuplicatePrevention` | Evidence Binding 版本化，重复失效事件幂等 |
| `FocusRecovery` | 保持 Relation Focus 和原阅读位置 |
| `AccessibilityAnnouncement` | “来源已失效，该关系需要重新核验” |

### 8.11 `EX-REFRESH-FOCUS-RESTORE-FAILED`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-REFRESH-FOCUS-RESTORE-FAILED |
| `Trigger` | 刷新后无法恢复稳定 Focus |
| `UserVisibleState` | 页面恢复到最近可用上级，显示原 Focus 失效说明 |
| `CanonicalSavedBoundary` | 无写操作；已有 Canonical 不变 |
| `UnsavedBoundary` | 临时恢复状态 |
| `ReadingAllowed` | YES |
| `CommitAllowed` | N/A |
| `AvailableRecoveryActions` | 搜索替代对象、返回上级、页面默认、重试 |
| `RetryRule` | 可按 ID/lineage 重试一次 |
| `RollbackRule` | 无需 Canonical 回退 |
| `DuplicatePrevention` | 恢复不创建版本 |
| `FocusRecovery` | 恢复最近上级或页面核心问题 |
| `AccessibilityAnnouncement` | “无法恢复原聚焦对象，已返回最近可用位置” |

### 8.12 `EX-SEMANTIC-ANCHOR-MOVED`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-SEMANTIC-ANCHOR-MOVED |
| `Trigger` | 原语义 Anchor 因结构更新移动 |
| `UserVisibleState` | 提示原位置已移动，滚动到同对象新 Anchor 或对象顶部 |
| `CanonicalSavedBoundary` | 结构变更已保存 |
| `UnsavedBoundary` | 旧滚动坐标无效 |
| `ReadingAllowed` | YES |
| `CommitAllowed` | YES_IF_VERSION_CURRENT |
| `AvailableRecoveryActions` | 接受新位置、查看结构变更、返回上级 |
| `RetryRule` | Anchor 映射可重试 |
| `RollbackRule` | 不回滚结构 |
| `DuplicatePrevention` | Anchor 只作定位，不参与版本创建 |
| `FocusRecovery` | objectId 不变；优先同语义段，失败到对象顶部 |
| `AccessibilityAnnouncement` | “原阅读位置已移动，已定位到同一对象的新位置” |

### 8.13 `EX-SMALL-SCREEN-PANEL-OVERFLOW`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-SMALL-SCREEN-PANEL-OVERFLOW |
| `Trigger` | 小屏无法容纳右侧/并列 Workspace |
| `UserVisibleState` | 辅助区转为临时全屏或底部层，正文 Anchor 保留 |
| `CanonicalSavedBoundary` | 无正式写入变化 |
| `UnsavedBoundary` | 仅布局状态 |
| `ReadingAllowed` | YES |
| `CommitAllowed` | 按当前 Workspace 规则 |
| `AvailableRecoveryActions` | 关闭、切换全屏层、返回原阅读 |
| `RetryRule` | 布局重算可重试 |
| `RollbackRule` | 无需回退 |
| `DuplicatePrevention` | 布局切换不创建版本 |
| `FocusRecovery` | 关闭后恢复原 Target 和 Anchor |
| `AccessibilityAnnouncement` | “已切换为小屏工作区，返回可恢复原阅读位置” |

### 8.14 `EX-TOUCH-NO-HOVER`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-TOUCH-NO-HOVER |
| `Trigger` | 触控设备不存在 Hover |
| `UserVisibleState` | 不提供 Hover 唯一能力；点击固定或显式预览入口 |
| `CanonicalSavedBoundary` | 无正式写入 |
| `UnsavedBoundary` | 临时 Preview 可选 |
| `ReadingAllowed` | YES |
| `CommitAllowed` | N/A |
| `AvailableRecoveryActions` | 点击固定、长按预览、显式关闭 |
| `RetryRule` | 无需重试 |
| `RollbackRule` | 无需回退 |
| `DuplicatePrevention` | 触控操作不创建重复 Focus 版本 |
| `FocusRecovery` | 点击后进入稳定 Focus |
| `AccessibilityAnnouncement` | “已选择对象；触控设备不依赖悬停” |

### 8.15 `EX-KEYBOARD-ENTERS-GRAPH`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-KEYBOARD-ENTERS-GRAPH |
| `Trigger` | 键盘焦点进入图形机制结构 |
| `UserVisibleState` | 提供可预测对象顺序、关系朗读和退出入口 |
| `CanonicalSavedBoundary` | 无正式写入 |
| `UnsavedBoundary` | 键盘游标为临时状态 |
| `ReadingAllowed` | YES |
| `CommitAllowed` | N/A |
| `AvailableRecoveryActions` | 方向键遍历、Enter 固定、Escape 退出、跳转正文等价内容 |
| `RetryRule` | 焦点映射失败可回退线性列表 |
| `RollbackRule` | 无需回退 |
| `DuplicatePrevention` | 键盘游标不创建 History/版本 |
| `FocusRecovery` | 退出后返回结构入口或当前 Focus |
| `AccessibilityAnnouncement` | “进入结构视图，共 N 个可导航对象；核心信息亦可在正文阅读” |

### 8.16 `EX-DUPLICATE-SUBMIT-CLICK`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-DUPLICATE-SUBMIT-CLICK |
| `Trigger` | 提交过程中重复点击 |
| `UserVisibleState` | 按钮保持禁用并显示同一提交进度 |
| `CanonicalSavedBoundary` | 第一次请求可能已处理 |
| `UnsavedBoundary` | 没有第二份合法草稿提交 |
| `ReadingAllowed` | YES_LIMITED |
| `CommitAllowed` | NO |
| `AvailableRecoveryActions` | 等待、查询状态、网络异常时安全重试 |
| `RetryRule` | 复用同一 idempotencyKey 查询/重试 |
| `RollbackRule` | 按最终结果决定是否 Revert |
| `DuplicatePrevention` | 服务端唯一幂等键+ChangeSet hash |
| `FocusRecovery` | 保持提交 Target 和原 Anchor |
| `AccessibilityAnnouncement` | “提交正在处理中，重复操作已忽略” |

### 8.17 `EX-NETWORK-TIMEOUT-SAVE-UNKNOWN`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-NETWORK-TIMEOUT-SAVE-UNKNOWN |
| `Trigger` | 网络超时但服务端可能已保存 |
| `UserVisibleState` | 显示“结果确认中”，不得直接称失败 |
| `CanonicalSavedBoundary` | UNKNOWN，必须查询 ChangeSet/idempotencyKey |
| `UnsavedBoundary` | 客户端草稿仍保留直到确认 |
| `ReadingAllowed` | YES |
| `CommitAllowed` | NO_NEW_SUBMISSION |
| `AvailableRecoveryActions` | 查询结果、恢复连接、查看服务器状态 |
| `RetryRule` | 只能使用同一幂等键重试查询/提交 |
| `RollbackRule` | 确认已保存后仅 Revert；未保存则可重试 |
| `DuplicatePrevention` | 幂等键和提交哈希阻止重复版本 |
| `FocusRecovery` | 保持 SUBMITTING Target；确认后回原 Focus |
| `AccessibilityAnnouncement` | “网络超时，正在确认是否已保存，请勿重复提交” |

### 8.18 `EX-UI-FAILED-CANONICAL-SAVED`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-UI-FAILED-CANONICAL-SAVED |
| `Trigger` | 页面显示失败但后端正式结构已保存 |
| `UserVisibleState` | 降级页面显示保存成功边界、版本和刷新/导出入口 |
| `CanonicalSavedBoundary` | Canonical Version/ChangeSet 已保存 |
| `UnsavedBoundary` | 当前 UI Projection 未显示 |
| `ReadingAllowed` | YES_WITH_DEGRADED_VIEW |
| `CommitAllowed` | 旧 UI 上进一步修订 BLOCKED |
| `AvailableRecoveryActions` | 刷新、打开纯文本差异、查看 ChangeSet、Revert |
| `RetryRule` | UI/Projection 可重试 |
| `RollbackRule` | 只通过 Revert ChangeSet |
| `DuplicatePrevention` | ChangeSet ID 查询确保不重复提交 |
| `FocusRecovery` | 恢复同一 Target 的 Canonical 文本页 |
| `AccessibilityAnnouncement` | “正式结构已保存，但页面显示失败” |

### 8.19 `EX-REVERT-AFFECTS-LATER-CHANGES`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-REVERT-AFFECTS-LATER-CHANGES |
| `Trigger` | 用户撤销会影响后续修订 |
| `UserVisibleState` | 显示依赖的后续 ChangeSet、冲突和新的三类影响 |
| `CanonicalSavedBoundary` | 原修订及后续修订均已保存 |
| `UnsavedBoundary` | Revert 草稿尚未提交 |
| `ReadingAllowed` | YES |
| `CommitAllowed` | NO_UNTIL_IMPACT_RESOLVED |
| `AvailableRecoveryActions` | 取消、调整撤销范围、创建补偿修订、人工合并 |
| `RetryRule` | 影响分析可重试 |
| `RollbackRule` | Revert 本身是新 ChangeSet，不物理删除历史 |
| `DuplicatePrevention` | baseVersion+dependentChangeSet 检查 |
| `FocusRecovery` | 保持原对象/Relation 和版本时间线 |
| `AccessibilityAnnouncement` | “撤销会影响后续修订，提交已阻止直到处理” |

### 8.20 `EX-WORKSPACE-SWITCH-WITH-DRAFT`

| Field | Contract |
|---|---|
| `ExceptionCode` | EX-WORKSPACE-SWITCH-WITH-DRAFT |
| `Trigger` | 切换 Workspace 或 Target 时存在脏草稿 |
| `UserVisibleState` | 草稿保护层显示保存、丢弃、继续编辑 |
| `CanonicalSavedBoundary` | 无新的正式保存 |
| `UnsavedBoundary` | 当前草稿未提交 |
| `ReadingAllowed` | YES |
| `CommitAllowed` | NO_ON_NEW_TARGET_UNTIL_DECISION |
| `AvailableRecoveryActions` | 保存草稿、丢弃、继续编辑、取消切换 |
| `RetryRule` | 保存失败可重试；切换请求不重复执行 |
| `RollbackRule` | 无需 Canonical 回退 |
| `DuplicatePrevention` | 待决切换使用单次 navigationIntent |
| `FocusRecovery` | 选择保存后切换并记录 ReturnToken；取消保持原 Focus |
| `AccessibilityAnnouncement` | “存在未提交草稿，请先选择处理方式” |

---

## 9. 零交互阅读完整性契约

### 9.1 P0 不变量

```text
DefaultReadingWithoutInteraction =
  COMPLETE

InteractionRequiredForCoreUnderstanding =
  NO

PrimaryContentHiddenBehindInteraction =
  FORBIDDEN
```

交互只能用于：

```text
REVEAL_SECONDARY_DETAIL
VERIFY_SOURCE
EXPLORE_LOCAL_RELATION
SWITCH_AUXILIARY_PERSPECTIVE
REVISE_FORMAL_STRUCTURE
```

交互不得用于：

```text
COMPLETE_MISSING_CORE_EXPLANATION
REVEAL_ONLY_CORE_CONCLUSION
REVEAL_ONLY_PRIMARY_RELATION
REVEAL_ONLY_BOUNDARY
REVEAL_ONLY_MODULE_CLOSURE
```

### 9.2 四层页面零交互最低内容矩阵

| 页面层级 | 不进行任何点击时必须直接看见 |
|---|---|
| Domain Panorama | 领域核心问题；Theme 主职责；Primary Cognitive Spine；主要问题—Theme 映射；领域主要边界 |
| Theme | Theme 核心问题；存在理由；Theme 边界；主要子问题；Module 分工；Module 主认知顺序；最重要协作、依赖或对比关系 |
| Module | 核心问题；核心结论；主要对象或概念；主机制、规则、因果、流程、对比或约束结构；成立条件；结果；边界和例外；一至三条关键 Relation；来源入口 |
| Element | 定义或核心陈述；当前认知职责；主归属；主要条件或边界；最重要直接 Relation；来源入口 |

### 9.3 核心信息直接可见规则

以下内容不得只存在于：

- Tab；
- Accordion；
- Hover；
- Tooltip；
- Popover；
- 右侧面板；
- 关系图；
- 视角切换；
- 来源 Workspace；
- 修订 Workspace。

```text
CoreQuestion
CoreConclusion
PrimaryMechanismOrRule
PrimaryBoundary
ModuleClosure
PrimaryRelation
```

### 9.4 Interaction Optionality

关闭或不实现所有非必要互动时，页面仍必须：

```text
ExplainWhatTheObjectIs
ExplainWhyItExistsHere
ExplainHowItWorksOrDiffers
ExplainConditionsAndResults
ExplainBoundaryAndException
ExposePrimaryRelations
ProvideSourceEntry
```

---

## 10. 文档连续性与认知叙事契约

### 10.1 解释性裁决

```text
MarkdownArticleModule = FORBIDDEN
```

不得被解释为：

```text
ContinuousExplanatoryText = FORBIDDEN
```

正式裁决：

```text
ContinuousExplanatoryNarrative =
  REQUIRED_WHEN_NEEDED_FOR_COGNITIVE_CLOSURE

EveryStatementAsIndependentCard =
  FORBIDDEN

EveryElementAsStandaloneVisualNode =
  FORBIDDEN

ListsReplacingNecessaryExplanation =
  FORBIDDEN

DiagramReplacingPreciseExplanation =
  FORBIDDEN
```

### 10.2 正文与视觉投影职责

```text
Text =
  PRECISE_EXPLANATION
  + CAUSAL_CONNECTION
  + CONDITION_AND_BOUNDARY
  + COGNITIVE_NARRATIVE

VisualProjection =
  STRUCTURE_COMPRESSION
  + POSITION_ORIENTATION
  + LOCAL_RELATION_VISIBILITY
  + FAST_CONTEXT_RECOVERY
```

正文负责连接：

```text
Problem
→ Object
→ MechanismOrRule
→ Relation
→ Condition
→ Result
→ Boundary
→ Exception
→ Conclusion
```

视觉投影不得代替正文对条件、因果强度、适用范围和例外的精确说明。

### 10.3 Module 默认阅读叙事

推荐顺序：

```text
CoreQuestion
→ CoreConclusion
→ ContinuousExplanation
→ PrimaryCognitiveProjection
→ ContinuedExplanation
→ ConditionsAndBoundaries
→ KeyRelations
→ SourceEntry
```

这是默认叙事骨架，不是要求每个 Module 使用相同栏目或组件。

### 10.4 Semantic Duplication Restraint

同一事实来自同一 Canonical Model，不表示可以在同一页面无意义重复。

```text
EachProjectionHasDistinctCognitiveFunction = YES
SameFactRepeatedOnlyForDecoration = FORBIDDEN
TextAndDiagramMirroringLineByLine = FORBIDDEN
DiagramAndStepListExpressingIdenticalStructure = FORBIDDEN
CardSummaryRepeatingAdjacentParagraph = FORBIDDEN
```

允许必要重复：

- 长页面上下文恢复；
- 跨视图身份确认；
- 无障碍和小屏降级；
- 静态导出无法保留交互语义；
- 复杂机制后的结论收束。

任何重复必须有明确认知作用。

---

## 11. 卡片、容器与视觉原语克制

### 11.1 卡片使用边界

```text
CardAsDefaultKnowledgeContainer =
  FORBIDDEN

SameShapePeerCardGridAsPrimaryBody =
  FORBIDDEN

NestedCardHierarchy =
  FORBIDDEN

EverySectionWrappedInCard =
  FORBIDDEN

EveryElementWrappedInCard =
  FORBIDDEN
```

卡片或独立容器只允许用于：

- 当前聚焦对象；
- 明确对比对象；
- 条件、状态、风险或例外；
- 与正文明确分离的可操作区域；
- 来源、核验、修订等辅助 Workspace；
- 具有真实语义边界的认知组合。

普通定义、解释、结论、关系陈述和上下文说明优先使用文档排版。

### 11.2 合法容器

```text
KnowledgeBoundary
CompositionGroup
ComparisonScope
RuleScope
FocusContext
AuxiliaryWorkspace
```

不得因视觉整齐创建无语义容器。

### 11.3 视觉原语预算

```text
PrimaryVisualPrimitiveFamiliesPerModule <= 4
PrimaryVisualProjectionPerCognitiveSection <= 1
SimultaneouslyEmphasizedVisualObjects <= 7

SpecialStatePrimitives =
  ATTACHED_ON_DEMAND

DecorativeSemanticShapes =
  FORBIDDEN
```

视觉语义词典是可选工具箱，不是必须全部展示的组件清单。

不得为了证明类型差异，在同一页面同时堆叠胶囊、菱形、六边形、旗标、托盘、楔形和对象板。

### 11.4 预算例外

以上属于默认硬预算。只有不突破预算会直接造成以下问题时才允许例外：

- 认知闭环无法表达；
- 关键条件或异常路径被遗漏；
- 本质不同的认知对象被错误合并；
- 视觉压缩反而降低关系可理解性。

例外必须满足：

```text
BudgetExceptionReason = EXPLICIT
AdditionalPrimitiveHasDistinctCognitiveRole = YES
DuplicateSemanticExpression = NO
AlternativeDocumentExpressionEvaluated = YES
AcceptanceReviewRequired = YES
```

视觉丰富、品牌展示、组件复用和设计系统展示不得作为例外理由。

---

## 12. 交互暴露预算

### 12.1 能力与控件分离

```text
AvailableInteractionCapability
  !=
VisibleInteractionControls
```

底层支持复杂状态，不代表默认页面显示全部按钮、筛选、模式、面板和图例。

### 12.2 预算统计口径

#### Cognitive Section

```text
CognitiveSection =
  ONE_CONTINUOUS_EXPLANATORY_UNIT
  WITH_ONE_PRIMARY_COGNITIVE_PURPOSE
```

`CognitiveSection` 由一个主要认知目的界定，例如解释一个机制、判断一组条件、比较一个固定维度或收束一个边界。它不是：

- 任意视觉容器；
- 每一个 Markdown 段落；
- 每一个标题；
- 每一个 Element；
- 为规避预算而人为切分的小块。

同一解释单元即使跨越多个自然段，只要仍服务同一认知目的，仍按一个 Cognitive Section 统计。

#### Primary Visual Projection

```text
PrimaryVisualProjection =
  ONE_HIGH_SALIENCE_STRUCTURE_VIEW
  THAT_SUMMARIZES_ORIENTS_THE_CURRENT_COGNITIVE_SECTION
```

计入：

- 当前 Section 的主机制结构；
- 主流程、主因果链、主规则判定结构；
- 承担主要定位作用的局部关系投影。

不单独计入：

- 辅助图标；
- 行内 Relation Cue；
- 来源标记；
- 状态附着；
- 低权重装饰；
- 文本中的简单方向符号。

同一 Section 中将一张结构图拆为多个容器，但共同承担一个主结构视图时，仍按一个 Primary Visual Projection 统计；不得通过拆容器规避预算。

#### Primary Visual Primitive Family

```text
PrimaryVisualPrimitiveFamily =
  ONE_HIGH_SALIENCE_SEMANTIC_SHAPE_FAMILY
  VISIBLE_IN_THE_SAME_PRIMARY_PROJECTION
```

同一语义形态的大小变化、弱化状态、聚焦状态、禁用状态和响应式变化仍属于同一 Family。

只有同时满足“高显著性”和“独立语义形态”才增加 Family 计数。来源图标、焦点环和状态附着不自动形成新的 Primary Family。

#### Simultaneously Emphasized Visual Objects

```text
SimultaneouslyEmphasizedVisualObjects =
  HIGH_CONTRAST_PRIMARY_OBJECTS
  VISIBLE_IN_ONE_PROJECTION_OR_VIEWPORT
```

必须计入：

- 当前主聚焦对象；
- 高权重 Relation 端点；
- 同级高对比对象；
- 与主聚焦处于相同视觉层级的条件、状态或结果对象。

不计入：

- 弱化背景对象；
- 仅用于位置感的 Spine 轨道；
- 低对比辅助标签；
- 非当前关系的淡化端点。

同一对象在同一视口中出现多个高亮实例时，按可被用户感知为多个竞争对象的实际实例计数；不得仅按 objectId 去重规避视觉负荷。

#### Primary Action

```text
PrimaryAction =
  HIGH_SALIENCE_ACTION
  THAT_CHANGES_MODE,
  OPENS_A_WORKSPACE,
  OR_COMMITS_A_FORMAL_CHANGE
```

计入：

- 进入完整核验；
- 进入完整修订；
- 切换主要模式；
- 打开完整关系 Workspace；
- 提交、确认、Revert 等正式变更动作。

普通文档锚点、轻量来源入口、关闭临时 Preview 和行内“查看说明”默认不计入 Primary Action，前提是其视觉显著性确实低于主要动作。

#### 统计视口与页面口径

```text
MeasurementViewport =
  DEFAULT_SUPPORTED_DESKTOP_VIEWPORT
  + REQUIRED_SMALL_SCREEN_VIEWPORT

DefaultReadingPersistentPrimaryActionsPerPage <= 2

SectionLevelActions =
  HIDDEN_UNTIL_SECTION_OR_OBJECT_FOCUS

DefaultReadingPersistentSidePanels = 0

DefaultReadingPermanentToolbars = 0
```

“每个 Section 最多两个主要动作”不能被解释为每个 Section 默认放置两个按钮。页面级持续可见 Primary Action 总数仍不得超过两个；Section 级动作必须等到 Section 或对象聚焦后按需出现。

### 12.3 默认预算

```text
DefaultReadingPersistentSidePanels = 0

DefaultReadingVisibleModeSwitches <= 1

DefaultReadingVisiblePrimaryActionsPerSection <= 2

DefaultReadingPersistentPrimaryActionsPerPage <= 2

SectionLevelActions =
  HIDDEN_UNTIL_SECTION_OR_OBJECT_FOCUS

DefaultReadingPermanentToolbars = 0

DefaultReadingVisibleRelationFilters = 0

DefaultReadingVisibleRevisionActions =
  HIDDEN_UNTIL_TARGET_FOCUS_OR_EXPLICIT_MODE

DefaultReadingVisibleSourceGovernanceStatus =
  ONLY_WHEN_IT_CHANGES_UNDERSTANDING

PermanentCognitivePerspectiveTabBar =
  FORBIDDEN

PermanentRelationFamilyToolbar =
  FORBIDDEN

PermanentGlobalLegend =
  FORBIDDEN

OneActionOpeningMultipleInteractionLayers =
  FORBIDDEN
```

HF-DG1 将本章的 `CognitiveSection`、`PrimaryVisualProjection`、
`PrimaryVisualPrimitiveFamily`、`SimultaneouslyEmphasizedVisualObject` 与
`PrimaryAction` 定义作为 Reading First 合同阶段的唯一统计口径。它们只约束
可见呈现与交互暴露，不推导新 Schema、物理对象或 Renderer 事实。

### 12.4 Cognitive Perspective 暴露规则

Cognitive Perspective 继续作为正式能力，但默认：

1. 先展示一个完整整体认知视角；
2. 最多暴露一至两个当前内容真正需要的辅助视角；
3. 其余放入按需入口；
4. 辅助视角不得替代或隐藏核心正文；
5. 不将所有 Perspective 渲染为常驻 Tab Bar。

### 12.5 动作显现顺序

```text
DefaultReading =
  READ + OPTIONAL_SOURCE_ENTRY

TargetFocused =
  LOCAL_RELATION + QUICK_ACTION

ExplicitVerificationMode =
  EVIDENCE_ACTIONS

ExplicitRevisionMode =
  REVISION_ACTIONS + IMPACT
```

默认阅读页面不得提前展示修订、锁定、合并、拆分、版本和影响控制。

---

## 13. 四层页面呈现克制规则

### 13.1 Domain Panorama

默认首屏只突出：

```text
CoreQuestion
PrimaryCognitiveSpine
ThemeResponsibilitySummary
```

默认正文还应直接说明：

- 主要问题如何被 Theme 分担；
- Theme 为什么处于该主线位置；
- 领域的主要边界。

禁止：

- Theme 同规格卡片网格；
- 多个指标区；
- 全量关系图；
- 常驻来源状态区；
- 常驻修订控制区；
- 并列仪表盘面板；
- 将最近访问 Theme 自动设置为主聚焦。

### 13.2 Theme

Theme 必须由问题和认知叙事组织 Module。

默认主体：

```text
ThemeCoreQuestion
→ WhyThisThemeExists
→ Boundary
→ SubQuestions
→ ModuleResponsibilities
→ PrimaryModuleOrder
→ MostImportantCooperationOrContrast
```

禁止：

- Module 卡片墙；
- 每个 Module 同时显示图标、状态、来源、按钮和统计；
- 固定右侧关系列表作为主要表达；
- 将子问题、Module 和关系拆成孤立容器；
- 把 Theme 页面做成 Module 目录。

### 13.3 Module

Module 是最主要的文档式阅读页面。

默认：

- 核心问题和结论直接可见；
- 连续解释连接主机制或规则；
- 每个认知段最多一个主要视觉投影；
- 条件、结果、边界和例外进入正文叙事；
- 一至三条关键 Relation 内嵌；
- 来源入口轻量附着。

禁止：

- 一屏大量小组件；
- 机制图、对象卡片、步骤列表和正文重复表达同一事实；
- 核心正文隐藏在 Tab、Accordion 或右侧面板；
- 所有 Element 图形化；
- 将 Perspective 做成主要导航；
- 默认常驻关系或治理面板。

### 13.4 Element

Element 默认是文档中的结构化认知小节。

默认直接显示：

- 定义或核心陈述；
- 当前职责；
- 主归属；
- 条件、边界或适用范围；
- 最重要 Relation；
- 来源入口。

只有以下场景使用明显独立容器：

```text
CURRENT_FOCUS
COMPARISON
CONDITION
STATE
RULE
RISK
EXCEPTION
```

---

## 14. 阅读、核验与修订的视觉分离

### 14.1 阅读模式

```text
PrimarySurface = DOCUMENT
GovernanceWorkspace = CLOSED
PersistentRightPanel = NO
RevisionControls = HIDDEN
```

只显示会改变理解的来源、冲突、推断或锁定状态。

### 14.2 核验模式

核验模式可使用 Workspace，但必须保持：

- 当前 Canonical Target；
- 原阅读位置；
- 当前 Relation 或 Statement；
- 返回路径；
- 证据支持范围。

核验 Workspace 不得变成全局来源治理后台。

### 14.3 修订模式

修订模式可显示正式字段、影响和历史，但必须保留：

- 当前问题；
- 当前对象在认知闭环中的职责；
- 修改前后语义；
- 原阅读 Anchor。

修订界面不得以拖拽和控制点遮蔽认知含义。

### 14.4 默认分离不等于功能删除

```text
ReadingGovernanceVisualSeparation = REQUIRED
SourceVerificationCapability = RETAINED
StructureRevisionCapability = RETAINED
```

---

## 15. Web、图片、Markdown 与 PDF 投影契约

### 15.1 统一投影链

```text
CanonicalObjectAndRelationModel
  → DocumentProjection
  → InteractiveVisualProjection
  → SourceProjection
  → StaticImageProjection
  → MarkdownProjection
  → PdfProjection
```

### 15.2 Canonical Model

唯一正式事实来源：

```text
KnowledgeObjectVersion
RelationVersion
ContextBinding
EvidenceBinding
PrimaryCognitiveSpine
QuestionMapping
Boundary
ChangeSet
```

不得：

- 单独生成正文事实；
- 单独生成图片事实；
- 单独生成关系事实；
- 让各投影独立维护条件、方向或边界；
- 将模型直接生成的位图作为正式知识结构。

### 15.3 稳定身份

同一个 Object 和 Relation 必须以稳定 ID 投影到：

- Web 正文；
- SVG 或 HTML 结构视图；
- 来源核验；
- 修订界面；
- PNG/SVG 导出；
- Markdown/PDF 导出。

```text
OneObjectOneIdentityAcrossProjection = REQUIRED
OneRelationOneIdentityAcrossProjection = REQUIRED
ProjectionSpecificIndependentFact = FORBIDDEN
```

#### 15.3.1 机器可读身份与普通阅读边界

```text
StableIdentityInMarkdownAndPdf =
  REQUIRED_AS_MACHINE_READABLE_ANCHOR_OR_METADATA

RawTechnicalIdVisibleToReader =
  OPTIONAL_AND_HIDDEN_BY_DEFAULT

StableIdentityInWeb =
  REQUIRED_IN_DOM_AND_ROUTE_STATE

StableIdentityInStaticImage =
  REQUIRED_IN_EXPORT_MANIFEST_OR_COMPANION_METADATA
```

稳定 ID 可以存在于：

- HTML `id`、`data-object-id`、`data-relation-id`；
- Markdown 属性、不可见 Anchor 或 Front Matter；
- PDF 元数据、结构标签或附带 Manifest；
- SVG 元素属性；
- PNG 导出 Manifest、版本快照清单或伴随 JSON；
- 内部来源映射；
- 可选开发者模式和诊断界面。

普通阅读页面默认只显示：

- 自然名称；
- 必要版本状态；
- 可理解的来源与加工状态；
- 用户确实需要辨认的修订差异。

不得：

```text
RawObjectIdAsLearningContent = FORBIDDEN
RawRelationIdAsPrimaryLabel = FORBIDDEN
TechnicalVersionIdInDefaultBody = FORBIDDEN
MachineAnchorRequiredToBeVisuallyPrinted = NO
```

用户需要复制链接、报告问题、比较版本或开启开发者模式时，可以按需显示技术 ID，但不得破坏正常阅读叙事。


### 15.4 静态图片职责

静态图片只负责：

```text
QUICK_PREVIEW
SHARING
OFFLINE_DEGRADATION
VERSION_SNAPSHOT
```

静态图片不是：

- Canonical Knowledge Source；
- 正文唯一承载体；
- 关系唯一承载体；
- 可编辑正式结构。

### 15.5 Markdown 与 PDF

Markdown/PDF 必须保留：

- 四层认知位置；
- 核心问题与结论；
- 连续解释性正文；
- 关键 Relation 的自然语言陈述；
- 条件、边界和例外；
- 对象与 Relation 的机器可读稳定 Anchor 或元数据；
- 来源脚注或引用映射；
- 静态结构投影的替代说明。

Markdown/PDF 不需要复制全部交互状态，但不能丢失核心理解。

---

## 16. 局部高保真状态证据输入

本轮不制作第三轮整体低保真。后续高保真阶段的八类证据使用 Cognitura 正式命名：

```text
HFD03EvidenceClass = CognitiveModuleDefaultReading
HFD03EvidenceClass = RelationFocus
HFD03EvidenceClass = SourceEvidenceVerification
HFD03EvidenceClass = RevisionAndImpact
HFD03EvidenceClass = Recovery
HFD03EvidenceClass = KnowledgeLandscapeAndKnowledgeTheme
HFD03EvidenceClass = SmallScreenSafeReadable
HFD03EvidenceClass = StaticExport
```

### 16.1 最重要状态

```text
PrimaryHighFidelityDesignTarget =
  CognitiveModuleDefaultReading
```

其验收优先于：

- 关系 Workspace；
- 来源核验 Workspace；
- 修订面板；
- 复杂二跳关系；
- 品牌和装饰。

### 16.2 CognitiveModuleDefaultReading 最低要求

不进行点击时直接显示：

```text
CoreQuestion
CoreConclusion
ContinuousExplanatoryNarrative
PrimaryCognitiveProjection
Conditions
Results
BoundariesAndExceptions
OneToThreeKeyRelations
SourceEntry
```

默认：

```text
PersistentSidePanel = 0
VisibleModeSwitches <= 1
VisiblePrimaryActionsPerSection <= 2
PrimaryVisualProjectionPerSection <= 1
```

### 16.3 RelationFocus

Relation 成为唯一主聚焦对象：

- 完整陈述；
- 起点与终点；
- 成立原因；
- 当前认知作用；
- 来源入口；
- 修订入口；
- 关闭后恢复原 Element 或 Module Anchor。

### 16.4 SourceEvidenceVerification

必须展示：

- 当前 Relation 或 Statement；
- 主体、谓词、客体、方向、条件和范围支持；
- 来源直接支持、结构重组、系统推断和冲突；
- 返回原阅读位置。

### 16.5 RevisionAndImpact

必须展示：

- Before/After；
- 快速或完整修订类型；
- 三类影响同屏；
- Blocker 默认展开；
- 提交后处理方式；
- 草稿和返回状态。

### 16.6 HF-D03 高保真证据输入合同

```text
HFD03EvidencePlan = docs/engineering/cognitura-high-fidelity-design-plan.md
HFD03EvidenceAcceptance = docs/engineering/cognitura-high-fidelity-design-acceptance.md
HFD03EvidenceContract = PASS
HFD03GateMeaning = EVIDENCE_INPUT_CONTRACT_COMPLETE_ONLY
```

八类证据按 `CognitiveModule` 默认阅读、Relation 聚焦、SourceEvidence 核验、
Revision/Impact、Recovery、KnowledgeLandscape/KnowledgeTheme、小屏安全可读和静态
导出依次规划。计划覆盖 KnowledgeElement 定位与展开、加载/空/错误/权限/不可用、
键盘焦点、无障碍、反馈、Desktop Web 和基础响应式；所有真实产物仍为 `NOT_RUN`。

```text
HFD03CrossDomainScenario = MECHANISM_DOMAIN|CanonicalProjection=KnowledgeLandscape>KnowledgeTheme>CognitiveModule>KnowledgeElement|Scenario=MVCC_CONSISTENT_READ_MECHANISM
HFD03CrossDomainScenario = RULE_POLICY_DOMAIN|CanonicalProjection=KnowledgeLandscape>KnowledgeTheme>CognitiveModule>KnowledgeElement|Scenario=PROCUREMENT_ACCEPTANCE_BEFORE_PAYMENT_POLICY
```

机制域与规则/政策域都只是 `CognitiveModule` 的认知内容类型，不创建新的正式层级、
产品对象、第二棵知识树或全局图谱。HF-DG3 PASS 不表示视觉或可用性 PASS。

---

## 17. 跨领域场景契约验证

```text
ValidationStage = CONTRACT
HighFidelityVisualValidation = NOT_RUN
HighFidelityUsabilityValidation = NOT_RUN
```

本章使用机制型与规则型案例验证“状态和呈现规则是否足以指导设计”，不声称任何真实高保真页面已经通过视觉或可用性验收。

### 17.1 案例 A：MVCC 一致性读机制

#### 默认阅读内容

```text
CoreQuestion =
  如何在并发写入存在时，为读事务选择一致且可见的数据版本？

CoreConclusion =
  Read View 与版本链共同确定当前事务能够看到的数据版本，
  其有效性受隔离级别、事务标识和当前读边界约束。

PrimaryNarrative =
  先解释一致性读目标，
  再说明 Read View 的可见性范围，
  连接版本标识、Undo 版本链和可见性判断，
  最后说明当前读、写写冲突和隔离级别边界。

PrimaryProjection =
  Read View
  → 可见性判断
  → 当前版本或 Undo 历史版本
  → 一致性读结果
```

#### 零交互验收

```text
CoreUnderstandingRequiresClick = NO
CoreConclusionVisible = YES
MechanismClosureVisible = YES
BoundaryVisible = YES
KeyRelationsVisible = YES
SourceEntryVisible = YES
```

#### 契约预算目标

```text
PrimaryVisualPrimitiveFamilies <= 4
PrimaryVisualProjectionPerSection <= 1
SimultaneouslyEmphasizedObjects <= 7
PersistentSidePanels = 0
```

契约结果：

```text
ValidationStage = CONTRACT
ZeroInteractionReadingContract = PASS
DocumentContinuityContract = PASS
CardAndContainerRestraintContract = PASS
VisualPrimitiveDensityContract = PASS
InteractionExposureContract = PASS
RelationUnderstandabilityContract = PASS

HighFidelityVisualResult = NOT_RUN
HighFidelityUsabilityResult = NOT_RUN
```

### 17.2 案例 B：采购验收后付款规则

#### 默认阅读内容

```text
CoreQuestion =
  在什么条件下允许进入付款，以及哪些职责不能由同一角色同时承担？

CoreConclusion =
  付款需要满足合同或订单、验收、审批和职责分离等前置条件，
  例外必须在明确授权和作用范围内成立。

PrimaryNarrative =
  先解释付款控制目标，
  再说明主条件与规则优先级，
  将验收、审批、职责分离和例外授权连接成判定逻辑，
  最后说明条件冲突、缺失材料和紧急例外边界。

PrimaryProjection =
  ApplicabilityScope
  → RequiredConditions
  → Decision
  → PaymentAllowedOrBlocked
  → ExceptionBoundary
```

#### 零交互验收

```text
RuleOnlyVisibleAfterTab = NO
ExceptionOnlyVisibleAfterInteraction = NO
PrimaryDependencyOnlyVisibleInPanel = NO
CoreRuleNarrativeVisible = YES
```

#### 契约预算目标

```text
PrimaryVisualPrimitiveFamilies <= 4
PermanentRuleToolbar = NO
PermanentRelationFilter = NO
CardGridAsPrimaryBody = NO
```

契约结果：

```text
ValidationStage = CONTRACT
ZeroInteractionReadingContract = PASS
DocumentContinuityContract = PASS
CardAndContainerRestraintContract = PASS
VisualPrimitiveDensityContract = PASS
InteractionExposureContract = PASS
RelationUnderstandabilityContract = PASS

HighFidelityVisualResult = NOT_RUN
HighFidelityUsabilityResult = NOT_RUN
```

### 17.3 跨领域结论

```text
ValidationStage = CONTRACT
MechanismTypeScenarioContract = PASS
RuleTypeScenarioContract = PASS
CrossDomainScenarioContractValidation = HF_DG3_EVIDENCE_INPUT_CONTRACT_PASS

SingleDomainPageModelRequired = NO
GlobalKnowledgeGraphRequired = NO
PureLongArticleRequired = NO
CardWallRequired = NO

CrossDomainVisualValidation = NOT_RUN
CrossDomainUsabilityValidation = NOT_RUN
```

以上只证明本文件的契约能够覆盖两类领域案例。字体、间距、视觉层级、真实操作成本
和跨领域视觉一致性必须在 HF-D04 固定候选审查通过后的独立 HV Gate，基于真实
高保真页面验收；不得与 HF-D03 证据输入合同同阶段执行。

---

## 18. 与已有正式规则的冲突裁决

### 18.1 MarkdownArticleModule

原规则禁止 Module 退化为只有连续 Markdown 的普通文章。

本文件补充：

```text
PureUnstructuredMarkdownArticle = FORBIDDEN
StructuredContinuousExplanation = REQUIRED_WHEN_NEEDED
```

### 18.2 Cognitive Perspective

前序设计将 Perspective 作为正式状态能力。

本文件补充：

```text
PerspectiveCapability = RETAINED
PermanentPerspectiveTabBar = FORBIDDEN
CoreContentHiddenByPerspective = FORBIDDEN
```

### 18.3 Local Relation Panel

前序设计保留按需 Local Relation Panel。

本文件补充：

```text
LocalRelationPanelCapability = RETAINED
PermanentRightPanelInReading = FORBIDDEN
PrimaryRelationOnlyInPanel = FORBIDDEN
```

### 18.4 视觉语义词典

前序设计定义完整视觉语义词典。

本文件补充：

```text
VisualSemanticDictionary = OPTIONAL_TOOLBOX
AllPrimitiveFamiliesOnEveryPage = FORBIDDEN
PrimitiveDensityBudget = REQUIRED
```

### 18.5 Overall、页面与 Renderer 稳定投影

以下非 Schema 投影是 HF-DG1 跨文件校验的唯一机器可读口径：

```text
PrimaryPresentationModel = INTERACTIVE_COGNITIVE_DOCUMENT
PrimaryExperienceModel = READING_FIRST
PureUnstructuredLongArticle = FORBIDDEN
StructuredContinuousCognitiveNarrative = REQUIRED_WHEN_NEEDED
DefaultReadingPersistentSidePanels = 0
KnowledgeHierarchyOrientation = RETAINED
QuickSourcePanel = ON_DEMAND_TRANSIENT
FullSourceEvidence = ON_DEMAND_WORKSPACE_OR_ROUTE
RelatedModules = INLINE_OR_ON_DEMAND
KnownGaps = INLINE_WHEN_UNDERSTANDING_CHANGES
DefaultReadingPersistentPrimaryActionsPerPage <= 2
PrimaryVisualPrimitiveFamiliesPerModule <= 4
PrimaryVisualProjectionPerCognitiveSection <= 1
SimultaneouslyEmphasizedVisualObjects <= 7
RendererCreatesIndependentFacts = NO
```

这组投影细化 Overall 的默认呈现，不改变 Overall 的产品权威、历史版本号或
`AppliedReverseMigration = 26/26`，也不推导 PageState、Schema 或物理对象。

### 18.6 Progressive Disclosure

前序设计要求 L0～L3 渐进展开。

本文件补充：

```text
ProgressiveDisclosure =
  SECONDARY_DETAIL_DISCLOSURE

ProgressiveDisclosureForCoreMeaning =
  FORBIDDEN
```

---

## 19. 高保真前验收硬门禁

以下任一成立时，不得开始最终高保真视觉与可用性设计：

```text
CoreUnderstandingRequiresClick
CoreConclusionHiddenBehindTab
ModuleClosureHiddenBehindPerspectiveSwitch
BoundaryOnlyVisibleAfterInteraction
PrimaryRelationOnlyVisibleInSidePanel
DefaultPageLooksLikeCardWall
DefaultPageLooksLikeComponentGallery
DefaultPageLooksLikeKnowledgeGraphWorkspace
DefaultPageLooksLikeGovernanceDashboard
EveryElementRenderedAsVisualNode
EverySectionWrappedInContainer
MoreThanOnePrimaryVisualPerCognitiveSection
TooManyVisibleShapeFamiliesInOneModule
PermanentRightPanelInReadingMode
PermanentRelationFilterToolbar
PermanentMultiPerspectiveTabBar
TextAndVisualProjectionContainIndependentFacts
StaticImageUsedAsCanonicalKnowledgeSource
```

### 19.1 验收阶段模型

```text
ValidationStage =
  CONTRACT
  | HIGH_FIDELITY_VISUAL
  | HIGH_FIDELITY_USABILITY
  | IMPLEMENTATION
```

```text
UnqualifiedPASSInThisDocument =
  CONTRACT_STAGE_PASS_UNLESS_AN_EXPLICIT_LATER_STAGE_IS_NAMED

ContractPASSDoesNotImplyVisualPASS = REQUIRED
ContractPASSDoesNotImplyUsabilityPASS = REQUIRED
```

阶段定义：

| 阶段 | 验收对象 | 当前状态 |
|---|---|---|
| `CONTRACT` | 规则、状态、字段、边界、矩阵和可执行验收输入是否完整 | HF-DG4_FIXED_DESIGN_REVIEW_PASS |
| `HIGH_FIDELITY_VISUAL` | 真实高保真页面是否满足层级、密度、连续性和状态表达 | NOT_RUN |
| `HIGH_FIDELITY_USABILITY` | 用户是否能在真实原型中理解、操作、返回和恢复 | NOT_RUN |
| `IMPLEMENTATION` | 前端代码是否实现并通过自动化与人工验收 | NOT_RUN |

```text
ContractDefined = FORMAL_SPECIALTY_BASELINE
ContractCompleteness = HF_DG4_FIXED_DESIGN_REVIEW_PASS
HighFidelityInputReady = CONTRACT_INPUT_COMPLETE

HighFidelityVisualDesign = NOT_RUN
HighFidelityVisualValidation = NOT_RUN
HighFidelityUsabilityValidation = NOT_RUN
CrossDomainVisualValidation = NOT_RUN
SmallScreenVisualValidation = NOT_RUN
HighFidelityStateAcceptance = NOT_RUN
```

### 19.2 RF-AC 分阶段验收矩阵

| ID | 验收动作 | 通过标准 | ValidationStage | Contract Result | High-Fidelity Result |
|---|---|---|---|---|---|
| RF-AC-01 | 关闭所有非必要交互 | 四层页面仍能完成主要认知任务 | CONTRACT | PASS | NOT_RUN |
| RF-AC-02 | 只阅读默认 Module | 获得完整认知闭环 | CONTRACT | PASS | NOT_RUN |
| RF-AC-03 | 删除右侧面板 | 关键 Relation 仍可理解 | CONTRACT | PASS | NOT_RUN |
| RF-AC-04 | 检查页面主体 | 禁止同规格卡片网格作为主体 | CONTRACT | PASS | NOT_RUN |
| RF-AC-05 | 检查视觉组件 | 禁止大量异形组件集合 | CONTRACT | PASS | NOT_RUN |
| RF-AC-06 | 阅读连续正文 | 必须连接机制、关系、条件和边界 | CONTRACT | PASS | NOT_RUN |
| RF-AC-07 | 检查默认状态 | 禁止常驻治理面板 | CONTRACT | PASS | NOT_RUN |
| RF-AC-08 | 统计默认控件 | 必须符合页面级与 Section 级预算 | CONTRACT | PASS | NOT_RUN |
| RF-AC-09 | 追溯事实来源 | 同一事实只来自 Canonical Model | CONTRACT | PASS | NOT_RUN |
| RF-AC-10 | 比较 Web/图片/Markdown/PDF | Object 和 Relation 身份一致 | CONTRACT | PASS | NOT_RUN |
| RF-AC-11 | 检查 Element 表达 | 普通 Element 不全部卡片化或节点化 | CONTRACT | PASS | NOT_RUN |
| RF-AC-12 | 检查 Perspective | 核心正文不依赖视角切换 | CONTRACT | PASS | NOT_RUN |
| RF-AC-13 | 检查 Revision | 高风险影响默认展开并阻断提交 | CONTRACT | PASS | NOT_RUN |
| RF-AC-14 | 检查提交后状态 | 四类处理、部分失败和撤销明确 | CONTRACT | PASS | NOT_RUN |
| RF-AC-15 | 检查小屏 | 默认仍为连续文档阅读 | CONTRACT | PASS | NOT_RUN |
| RF-AC-16 | 执行点击/Escape/空白区矩阵 | 所有切换结果唯一且不丢上下文 | CONTRACT | PASS | NOT_RUN |
| RF-AC-17 | 执行 URL/History/Refresh 矩阵 | 只恢复稳定语义状态和草稿 | CONTRACT | PASS | NOT_RUN |
| RF-AC-18 | 执行异常恢复矩阵 | 保存边界、重试、回退和去重明确 | CONTRACT | PASS | NOT_RUN |
| RF-AC-19 | 检查导出身份 | 稳定 ID 机器可读且默认不打扰读者 | CONTRACT | PASS | NOT_RUN |
| RF-AC-20 | 检查第二轮追溯 | 已接受结论与当前候选追溯位置可定位 | CONTRACT | PASS | NOT_RUN |

### 19.3 当前候选合同的分阶段状态

HF-D01、HF-D02 与 HF-D03 已依次使 Reading First、状态恢复和高保真证据输入
合同在 `CONTRACT` 阶段为 PASS；HF-D04 对固定准备提交完成两个独立
`gpt-5.6-sol/high` 零发现审查，并关闭合同设计 Gate。任何视觉、可用性或实现
PASS 声明仍被禁止。

```text
ReadingFirstPresentationContract = PASS
InteractiveCognitiveDocumentContract = PASS
ZeroInteractionReadingContract = PASS
DocumentContinuityContract = PASS
CardAndContainerRestraintContract = PASS
VisualPrimitiveDensityContract = PASS
InteractionExposureContract = PASS
ReadingGovernanceSeparationContract = PASS
StaticProjectionContract = PASS
CrossDomainScenarioContractValidation = HF_DG3_EVIDENCE_INPUT_CONTRACT_PASS

PreviewAndPinnedFocusContract = PASS
ElementRelationFocusPriorityContract = PASS
QuickFullRevisionRoutingContract = PASS
UnifiedImpactPreviewContract = PASS
PostCommitProcessingContract = PASS
DraftReturnAndRecoveryContract = PASS
HighFidelityInteractionStateMatrix = PASS
ExceptionAndRecoveryStateMatrix = PASS
URLHistoryAndRefreshContract = PASS
BudgetMeasurementDefinition = PASS
StableIdentityExportContract = PASS
SecondRoundLowFidelityTraceability = PASS
HighFidelityEvidenceContract = PASS

ContractP0Remaining = HF_DG4_FIXED_DESIGN_REVIEW_PASS
HighFidelityInputReady = CONTRACT_INPUT_COMPLETE
```

### 19.4 当前禁止声明为 PASS

```text
HighFidelityVisualDesign = NOT_RUN
HighFidelityVisualValidation = NOT_RUN
HighFidelityUsabilityValidation = NOT_RUN
CrossDomainVisualValidation = NOT_RUN
SmallScreenVisualValidation = NOT_RUN
HighFidelityStateAcceptance = NOT_RUN
ImplementationValidation = NOT_RUN
```

规则已经定义，不等于真实页面已经通过。只有真实高保真页面完成并按本文件逐项测试后，才允许更新对应视觉和可用性状态。

---

## 20. Reverse Migration Pack

```text
ISHFI-RM-01 =
  PreviewAndPinnedFocusContract

ISHFI-RM-02 =
  TouchKeyboardAndAccessibilityEquivalence

ISHFI-RM-03 =
  ElementAndRelationFocusPriority

ISHFI-RM-04 =
  QuickAndFullRevisionRouting

ISHFI-RM-05 =
  ThreeLaneImpactCoPresence

ISHFI-RM-06 =
  HighRiskImpactDefaultExpansion

ISHFI-RM-07 =
  PostCommitFourStateProcessing

ISHFI-RM-08 =
  PartialFailureStaleProjectionAndRetry

ISHFI-RM-09 =
  SoftBackRouteBackAndHardReset

ISHFI-RM-10 =
  DraftProtectionRecoveryAndRevert

ISHFI-RM-11 =
  SmallScreenReadingSafety

ISHFI-RM-12 =
  HighFidelityStateEvidenceInput

ISHFI-RM-13 =
  HighFidelityAcceptanceGate

ISHFI-RM-14 =
  InteractionStateCompletionBaseline

ISHFI-RM-15 =
  CrossDomainHighFidelityInputValidation

ISHFI-RM-16 =
  InteractiveCognitiveDocumentPresentation

ISHFI-RM-17 =
  ZeroInteractionReadingCompleteness

ISHFI-RM-18 =
  DocumentContinuityAndCognitiveNarrative

ISHFI-RM-19 =
  CardAndContainerRestraint

ISHFI-RM-20 =
  VisualPrimitiveDensityBudget

ISHFI-RM-21 =
  InteractionExposureBudget

ISHFI-RM-22 =
  ReadingAndGovernanceVisualSeparation

ISHFI-RM-23 =
  StaticImageMarkdownAndPdfProjection

ISHFI-RM-24 =
  ContractAndVisualAcceptanceStageBoundary

ISHFI-RM-25 =
  CompleteHighFidelityInteractionStateMatrix

ISHFI-RM-26 =
  ClickCloseFocusAndHistoryContract

ISHFI-RM-27 =
  CompleteExceptionAndRecoveryStateMatrix

ISHFI-RM-28 =
  VisualAndInteractionBudgetMeasurementDefinition

ISHFI-RM-29 =
  StableIdentityMachineReadableAndReaderVisibilityBoundary

ISHFI-RM-30 =
  SecondRoundLowFidelityAcceptanceTraceability
```

下一统一总体设计版本必须一次性回迁：

```text
CRPS-RM-01..14
+ CREI-RM-01..12
+ ISMVC-RM-01..16
+ ISHFI-RM-01..30
```

不得另起无必要的平行总体设计版本，也不得只回迁本文件最后八项而遗漏交互状态补齐条款。

---

## 21. 本次补丁变更摘要

### 21.1 新增

1. `INTERACTIVE_COGNITIVE_DOCUMENT` 正式总定位；
2. 零交互阅读完整性；
3. 四层页面默认最低内容矩阵；
4. 连续解释性正文与视觉投影职责；
5. 卡片、容器和视觉原语密度预算；
6. 交互能力与默认可见控件分离；
7. Domain、Theme、Module、Element 呈现克制规则；
8. 阅读、核验与修订的视觉分离；
9. Canonical Model 到 Web、图片、Markdown、PDF 的统一投影；
10. 局部高保真状态证据输入；
11. 机制型和规则型阅读验证；
12. `ISHFI-RM-16..23`。

### 21.2 吸收并正式化

1. Preview 与 Pinned Focus；
2. 触控和键盘等价；
3. Element 与 Relation 聚焦优先级；
4. 快速修订和完整修订分流；
5. 三类影响同屏；
6. 提交后四类处理；
7. 部分失败、刷新、回退和撤销；
8. 返回、重置、草稿与恢复；
9. 小屏阅读安全；
10. 高保真状态验收输入。

### 21.3 本轮状态矩阵最终补齐

1. 契约验收、高保真视觉验收、高保真可用性验收和实现验收四阶段分离；
2. 46 个高保真交互状态的完整字段矩阵；
3. 点击、关闭、Escape、空白区、触控和重复提交行为矩阵；
4. URL、浏览器 History 与刷新恢复边界；
5. 20 类异常与恢复状态矩阵；
6. Cognitive Section、Primary Visual Projection、Primitive Family、Emphasized Object 和 Primary Action 的统计定义；
7. 页面级持续主要动作与永久工具栏预算；
8. 导出稳定 ID 的机器可读与普通读者可见边界；
9. 第二轮低保真验收追溯附录；
10. `ISHFI-RM-24..30`。

### 21.4 未改变

```text
PageInformationArchitectureChanged = NO
CanonicalHierarchyChanged = NO
RelationSemanticDictionaryChanged = NO
PrimaryCognitiveSpineChanged = NO
KnowledgeGenerationContractChanged = NO
NewFormalPageTypeAdded = NO
NewPrimaryModeAdded = NO
```

---

## Appendix A. Second-Round Low-Fidelity Acceptance Trace

### A.1 追溯来源

```text
TraceEvidence =
  SECOND_ROUND_LOW_FIDELITY_INTERACTION_FLOW_BLUEPRINT
  + PREVIOUS_PAGE_STRUCTURE_SPECIALTY
  + PREVIOUS_INTERACTION_STATE_SPECIALTY_SECTION_19
  + CURRENT_READING_FIRST_PATCH
  + CURRENT_STATE_MATRIX_COMPLETION
```

第二轮低保真解决的是页面结构、局部聚焦、关系修订主链路和多视图方向是否成立；本文件解决的是高保真设计是否已经获得完整、无须猜测的状态输入。两者均不等同于真实高保真视觉与可用性验收。

### A.2 验收结论追溯矩阵

| 第二轮结论 | 历史低保真状态 | 候选追溯位置 | 当前阶段裁决 |
|---|---|---|---|
| Domain 页面结构成立 | ACCEPTED | 页面结构专项；本文件 Domain 零交互与呈现克制规则 | DEFERRED_TO_APPLICABLE_HF_GATE |
| Theme 页面结构成立 | ACCEPTED | 页面结构专项；本文件 Theme 零交互与呈现克制规则 | DEFERRED_TO_APPLICABLE_HF_GATE |
| Module 页面结构成立 | ACCEPTED | 页面结构专项；本文件 Module 默认阅读叙事与状态证据 | DEFERRED_TO_APPLICABLE_HF_GATE |
| Relation Revision 主流程成立 | ACCEPTED | 前序交互状态专项 R1～R6；本文件修订、提交后与异常矩阵 | DEFERRED_TO_APPLICABLE_HF_GATE |
| 渐进式关系展开成立 | ACCEPTED | 前序 `L0～L3` 契约；本文件状态矩阵继承 | DEFERRED_TO_APPLICABLE_HF_GATE |
| 当前对象中心化成立 | ACCEPTED | `One Primary Focus`；Element/Relation Focus Priority | DEFERRED_TO_APPLICABLE_HF_GATE |
| Relation 一等对象成立 | ACCEPTED | Relation Focus、Stable Identity、统一投影 | DEFERRED_TO_APPLICABLE_HF_GATE |
| 阅读、核验、修订闭环成立 | ACCEPTED | Mode、Workspace、URL/History/Refresh 和返回契约 | DEFERRED_TO_APPLICABLE_HF_GATE |
| 多视图一致性成立 | ACCEPTED | Canonical ID、Projection、机器可读导出身份 | DEFERRED_TO_APPLICABLE_HF_GATE |
| 六项交互状态缺口 | CANDIDATE_INVENTORIED | 本文件第 4～8 章及提交后处理状态 | DEFERRED_TO_APPLICABLE_HF_GATE |
| 过度交互与卡片化风险 | CANDIDATE_INVENTORIED | Reading First、Document Continuity、预算与呈现克制 | DEFERRED_TO_APPLICABLE_HF_GATE |
| 完整高保真状态输入缺口 | CANDIDATE_INVENTORIED | High-Fidelity Interaction State Matrix 与 Exception Matrix | DEFERRED_TO_APPLICABLE_HF_GATE |
| 高保真视觉验证 | NOT_RUN | HF-D04 后独立 HV Gate 的真实高保真页面 | NOT_RUN |
| 高保真可用性验证 | NOT_RUN | HF-D04 后独立 HV Gate 的真实交互原型 | NOT_RUN |
| 小屏视觉验证 | NOT_RUN | HF-D04 后独立 HV Gate 的 SmallScreenReadingState | NOT_RUN |

### A.3 第三轮整体低保真裁决

```text
SecondRoundLowFidelityDirectionRecord = HISTORICAL_ACCEPTANCE_RECORDED
ReadingFirstRiskDisposition = DEFERRED_TO_APPLICABLE_HF_GATE
StateInputGapDisposition = HF_DG2_ORTHOGONAL_STATE_AND_RECOVERY_PASS
ThirdRoundOverallLowFidelityRequired = NO

HighFidelityVisualValidationImplied = NO
HighFidelityUsabilityValidationImplied = NO
```

不制作第三轮整体低保真，不表示跳过状态合同设计。HF-D02 只完成正交状态分类、
恢复和持久化；针对局部高保真状态逐项形成视觉证据和可用性证据，必须延后到
HF-D04 固定候选审查通过后的独立 HV Gate。

---

## 22. ActualChangedFiles

```text
Modified =
  Cognitive-Knowledge-Atlas-
  Interaction-State-Completion-
  and-High-Fidelity-Input-Design-1.0.md

NewParallelAuthorityFileCreated =
  NO

IndependentAddendumCreated =
  NO

VersionChanged =
  NO

GitRepositoryConnected =
  YES

GitCommitPerformed = HF_D04_PROMOTION_CLOSURE
ActiveDesignTaskCard = NONE
ActiveDesignTaskCardStatus = NONE
RecommendedCommit = docs: close high fidelity contract design gate
```

本次产物级检查：

```text
MarkdownHeadingStructureCheck = CANDIDATE_SELF_CHECK_ONLY
CodeFenceBalanceCheck = CANDIDATE_SELF_CHECK_ONLY
DuplicateStateCodeCheck = CANDIDATE_SELF_CHECK_ONLY
RequiredInteractionStateCoverage = CANDIDATE_SELF_CHECK_ONLY
RequiredExceptionCoverage = CANDIDATE_SELF_CHECK_ONLY
ValidationStageBoundaryCheck = CANDIDATE_SELF_CHECK_ONLY
PrematureHighFidelityPassCheck = PASS_WITH_VISUAL_USABILITY_IMPLEMENTATION_NOT_RUN
FinalStatusConsistencyCheck = HF_DG4_PROMOTION_CLOSURE
ParallelAuthorityFileCheck = CANDIDATE_SELF_CHECK_ONLY
```

仓库落地后仍需执行：

1. 仓库内 Markdown 链接和相对路径检查；
2. 实际 Git diff 与工作区无关文件检查；
3. 被其他文件引用情况检查；
4. 独立文档提交；
5. 确认无意外格式化或其他设计文件修改。

---

## 23. 最新正式状态

```text
DesignVersion =
  Cognitive-Knowledge-Atlas-
  Interaction-State-Completion-
  and-High-Fidelity-Input-Design-1.0

Status =
  FORMAL_SPECIALTY_BASELINE

ReviewedPreparationSHA = 463fd4829e7c4bb8da071253e8ae9b15cee2a0cf
HF-DG4 FixedDesignReview = PASS

ReadingFirstPresentationContract = PASS
InteractiveCognitiveDocumentContract = PASS
ZeroInteractionReadingContract = PASS
DocumentContinuityContract = PASS
CardAndContainerRestraintContract = PASS
VisualPrimitiveDensityContract = PASS
InteractionExposureContract = PASS
ReadingGovernanceSeparationContract = PASS
StaticProjectionContract = PASS

PreviewAndPinnedFocusContract = PASS
ElementRelationFocusPriorityContract = PASS
QuickFullRevisionRoutingContract = PASS
UnifiedImpactPreviewContract = PASS
PostCommitProcessingContract = PASS
DraftReturnAndRecoveryContract = PASS
OrthogonalStateRecoveryContract = PASS

HighFidelityInteractionStateMatrix = PASS
ExceptionAndRecoveryStateMatrix = PASS
URLHistoryAndRefreshContract = PASS
BudgetMeasurementDefinition = PASS
StableIdentityExportContract = PASS
SecondRoundLowFidelityTraceability = PASS
CrossDomainScenarioContractValidation = HF_DG3_EVIDENCE_INPUT_CONTRACT_PASS

HighFidelityEvidenceContract = PASS
ContractP0Remaining = HF_DG4_FIXED_DESIGN_REVIEW_PASS
HighFidelityInputReady = CONTRACT_INPUT_COMPLETE

HighFidelityVisualDesign = NOT_RUN
HighFidelityVisualValidation = NOT_RUN
HighFidelityUsabilityValidation = NOT_RUN
CrossDomainVisualValidation = NOT_RUN
SmallScreenVisualValidation = NOT_RUN
HighFidelityStateAcceptance = NOT_RUN

PageInformationArchitectureChanged = NO
CanonicalHierarchyChanged = NO
RelationSemanticDictionaryChanged = NO
NewFormalPageTypeAdded = NO
ThirdRoundOverallLowFidelityRequired = NO

FrontendTechnologySelectionReady = NO
FrontendImplementationReady = NO

NextStage =
  HV_D00_VISUAL_FOUNDATION_TASK_CARD_CREATION
```

---

## 24. 下一阶段唯一入口

```text
NextStage =
  HV_D00_VISUAL_FOUNDATION_TASK_CARD_CREATION

HFD03Scope = HIGH_FIDELITY_EVIDENCE_INPUT_CONTRACT_ONLY
HFD03Status = DONE
HFD04Status = DONE
VisualDesignAfterHFD04Pass = READY_FOR_SEPARATE_HV_GATE
RealHighFidelityPageDesign = DEFERRED_UNTIL_HF_D04_PASS_AND_SEPARATE_HV_GATE
HighFidelityVisualAndUsabilityValidation = DEFERRED_UNTIL_SEPARATE_HV_GATE
```

HF-D03 只定义证据输入与验收合同；以下 HF-D02 已通过的状态范围继续作为输入：

```text
ModuleDefaultReadingState
OrthogonalStateClassification
ExceptionAndRecoveryState
URLHistoryAndRefreshPersistence
```

真实高保真页面设计必须等 HF-D04 固定候选审查通过后，再进入独立 HV Gate；
下列视觉与可用性验收不得与 HF-D03 同阶段执行：

```text
ZeroInteractionCompleteness
DocumentContinuity
CognitiveClosure
CardDensity
VisualPrimitiveDensity
InteractionExposure
TextVisualNonDuplication
KeyRelationVisibility
KeyboardAndTouchEquivalence
HistoryAndRefreshRecovery
```

在 Module 默认阅读状态未通过前，不得优先制作：

- 大型关系图；
- 来源治理工作台；
- 完整修订 Workspace；
- 品牌化视觉首页；
- 炫技型动效；
- 全局图谱页面；
- 前端技术选型；
- 正式页面代码。

```text
AdditionalDesignSpecialtyBeforeHighFidelity = FORBIDDEN
FormalDesignInputCompletion = COMPLETE
```

本文件现为 Cognitura 唯一已登记并经 HF-DG4 固定候选双阶段审查通过的高保真
交互正式专项基线。该晋级只关闭合同设计阶段；真实高保真视觉、可用性验收与
实现仍按后续独立 HV Gate 推进。
