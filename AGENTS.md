# Cognitura Repository Instructions

## 1. 项目身份

```text
CanonicalProjectName = Cognitura
RepositoryName = cognitura
PrimaryPurpose = PERSONAL_COGNITIVE_STRUCTURE_BUILDING
```

所有新增工程产物、模块名、Schema 标题、测试说明和用户可见产品名称统一使用 `Cognitura`。`Cognitive Knowledge Atlas` 和 `Cognitive Knowledge Structure System` 仅作为历史设计名称保留，不重命名历史文件，不改写历史版本号，不制造总体设计副本。

## 2. 当前阶段与允许范围

```text
CurrentStage = WAVE1_IMPLEMENTATION_IN_PROGRESS
DesignAlignmentStatus = COMPLETE
DevelopmentPlanningEntry = AUTHORIZED_FOR_TASK_CARD_EXECUTION

Wave0ExecutionEntry = GO_WITH_GATES
Wave0ExecutionStatus = COMPLETE
ActiveTaskCard = NONE
ActiveTaskCardStatus = NONE
W0G3ReviewStatus = PASS
W0G4ReviewStatus = PASS
W0G5Status = PASS
W0G6ReviewStatus = PASS
Wave1FeatureDevelopmentEntry = GO
Wave1DesignStatus = USER_APPROVED
Wave1ImplementationPlanningStatus = TASK_CARD_SET_BOOTSTRAPPED
Wave1ImplementationTaskCardSet = SUSPENDED_BY_USER
ModuleDefaultReadingExecutionStateAuthority = docs/task-cards/module-default-reading-implementation/execution-state.md
ModuleDefaultReadingImplementationTaskCardSet = GOVERNED_BY_EXECUTION_STATE
ModuleDefaultReadingImplementationTaskCardCount = 9
ModuleDefaultReadingImplementationEntry = GOVERNED_BY_EXECUTION_STATE
ModuleDefaultReadingActiveImplementationTaskCard = SEE_MODULE_DEFAULT_READING_EXECUTION_STATE
ModuleDefaultReadingBusinessImplementation = SEE_MODULE_DEFAULT_READING_EXECUTION_STATE
ModuleDefaultReadingDocumentationGap = DOC-GAP-MDR-001
HighFidelityDesignTaskCardSet = COMPLETE
HighFidelityDesignStatus = COMPLETE
HighFidelityDesignGate = HF-DG4 PASS
HighFidelityReviewedPreparationSHA = 463fd4829e7c4bb8da071253e8ae9b15cee2a0cf
HighFidelityReadingPresentationContract = PASS
HighFidelityInteractionStateModel = PASS
HighFidelityEvidenceContract = PASS
HighFidelityVisualFoundation = PASS
HighFidelityModuleDefaultReading = PASS
HighFidelityFocusAndSource = PASS
HighFidelityRevisionAndRecovery = PASS
HighFidelityCrossLayerResponsiveAndExport = PASS
HighFidelityVisualDesign = PASS
HighFidelityVisualValidation = PASS
HighFidelityUsabilityValidation = PASS
HighFidelityStateAcceptance = PASS
ImplementationValidation = NOT_RUN
ActiveImplementationTaskCard = NONE
VisualStyleBaselineExecutionStateAuthority = docs/task-cards/visual-style-baseline/execution-state.md
VisualStyleBaselineTaskCardSet = GOVERNED_BY_EXECUTION_STATE
VisualStyleBaselineImplementationEntry = GOVERNED_BY_EXECUTION_STATE
HighFidelityVisualTaskCardSet = COMPLETE
HighFidelityVisualProjectedEntry = NONE
ActiveDesignTaskCard = NONE
W1-I00Creation = COMPLETE
W1-I00Release = CLOSED
BusinessImplementation = USER_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
DirectFullImplementationStart = NO
```

Wave 0 已完成 Repository、设计索引、专项契约覆盖、JSON Schema、Golden Case
回归资产、测试和 CI 基线以及页面/Renderer 契约。Wave 1 准入 GO 只允许按后续
任务卡受控推进，不授权直接开始完整业务实现。Wave 1 详细设计和 14 张中细粒度
实现切片书面规格均已获用户批准；14 张实现卡已经 bootstrap，非业务治理卡 I00
已完成固定候选零发现深审并关闭。用户已授权现有卡集持续串行实施；`W1-I01`
已对固定候选 `6796079de8c919055ddc6538234254b50630a491` 完成零发现深审并关闭，
`W1-I02` 等待独立数据库 Gate；`W1-I03` 已冻结在
`4e63936c631ab34807e714b90d30415a959bc13d`，当前没有 Wave 1 READY 卡。
Visual Style Baseline 的唯一可变运行态由
`docs/task-cards/visual-style-baseline/execution-state.md` 管理。

本分支另有经用户授权的独立 `HIGH_FIDELITY_DESIGN` 集合；`HF-D01` 至 `HF-D04`
现已全部关闭。HF-D04 已对准备提交
`463fd4829e7c4bb8da071253e8ae9b15cee2a0cf` 完成两个独立
`gpt-5.6-sol/high` 零发现审查并把专项晋级 `FORMAL_SPECIALTY_BASELINE`。该晋级只
关闭合同设计阶段，不制作视觉页面、原型或截图；该历史晋级本身未授权创建或释放
`W1-I00`。当前 I00 的创建和释放来自后续用户授权的 bootstrap；当前用户
授权只按已批准卡集串行推进，I02 的独立数据库 Gate、正式数据库写入和远程推送
边界保持不变。
`HF-D01` 仅关闭 Reading First 页面与呈现合同，`HF-D02` 仅关闭正交状态、持久化
与恢复边界，`HF-D03` 仅关闭八类证据、20 项 RF-AC、20 异常、30 RM 和跨域场景
的输入合同，`HF-D04` 仅关闭固定合同候选审查。`HV-D00` 已建立 docs-only
非生产视觉 token、确定性 URL fixture、基础截图和六卡串行治理；`HV-D01` 已以
机制型合成内容和 1440×1100 证据关闭 Module 默认阅读视觉 Owner 集；`HV-D02`
已以 Relation 主聚焦与完整来源核验的两张桌面证据关闭其四项视觉 Owner；`HV-D03`
已以修订影响、正式保存后部分失败和冲突草稿三张证据关闭其四项视觉 Owner；`HV-D04`
已建立四层、跨域、小屏和静态导出证据；`HV-D05` 已对固定候选
`62da1bc08a932bbfc76769a2add984dcec4160b7` 完成两个独立
`gpt-5.6-sol/high` 零发现审查并关闭整体视觉与可用性阶段。其视觉晋级未授权业务
实现、正式数据库写入或远程推送；后续 bootstrap 授权已完成并关闭非业务治理卡
I00；I01 已关闭，I02 保持等待独立数据库 Gate；I03 在 Visual Style Baseline
执行期间冻结为 `SUSPENDED_BY_USER`。
开发入口仅由 `docs/engineering/cognitura-development-entry-prompt.md` 提供下一会话的
书面任务卡规划提示。该提示现已用于建立独立的 `MDR-I00..MDR-I08` 书面卡集；
卡片文本和自动串行治理规格现已获用户批准；唯一可变运行态由
`docs/task-cards/module-default-reading-implementation/execution-state.md` 管理，中央索引
和逐卡正文不得维护第二份 Active/READY/DONE 事实。该卡集不替代既有 Wave 1 source
work；只有账本记录治理 bootstrap 固定提交零发现 GO 和集合级授权后，才允许按唯一
活动卡编写代码。

## 3. 正式事实来源

按以下优先级读取，不得凭对话记忆补写：

1. `cognitive-knowledge-atlas-overall-design-1.2.md`：当前总体正式基线；工程引用名 `Cognitura-Overall-Design-1.2`。
2. `docs/design/cognitura-schema-baseline-2.0.md`：经用户明确批准的字段级
   工程重基线；工程引用名 `Cognitura-Schema-Baseline-2.0`。它从属于总体设计，
   不冒充或替代历史专项正文。
3. 后续实际落地且通过来源校验的专项设计正文：
   - `Cognitive-Knowledge-System-Construction-Design-1.0`
   - `Cognitive-Knowledge-Atlas-UIUX-Design-1.0`
   当前视觉样式参考从属于总体设计与高保真交互专项，仅拥有视觉 DNA 与语义 token：
   ```text
   VisualStyleReferenceAuthority = docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md
   VisualStyleReferenceManifest = docs/engineering/cognitura-visual-style-baseline-manifest.yaml
   VisualStyleReferenceScope = VISUAL_DNA_AND_SEMANTIC_TOKENS_ONLY
   VisualStyleReferencePageArchitectureAuthority = NO
   VisualStyleReferenceInteractionAuthority = NO
   VisualStyleReferenceDashboardLayoutAuthority = NO
   ```
4. `raw/` 下三份 Golden Case 原始 DOCX。
5. `docs/engineering/` 下的工程索引、计划和准入记录；这些文件解释落地状态，不覆盖正式设计。
6. `docs/task-cards/` 下的执行卡和索引；这些文件固定写集、依赖、验证和 Gate，
   不覆盖总体设计或工程裁决。

后端工程选择以
`docs/engineering/cognitura-technology-baseline.md` 为唯一技术基线；不得在
子模块中另行选择 Java、Spring Boot、数据库或数据访问框架版本。

专项正文缺失时，使用总体设计中已经回迁的正式契约继续 Wave 0 非 Schema 工作；
字段级 JSON Schema 必须服从 `Cognitura-Schema-Baseline-2.0`，不得从常识或提示词
继续扩写。缺口必须记录为 `DocumentationGap`，直到权威来源落地或形成明确的
工程裁决。

## 4. 不可修改的产品裁决

```text
PrimaryPurpose = PERSONAL_COGNITIVE_STRUCTURE_BUILDING

CanonicalHierarchy =
  KnowledgeLandscape
  → KnowledgeTheme
  → CognitiveModule
  → KnowledgeElement

PrimaryReadingUnit = COGNITIVE_MODULE
KnowledgeCardIsCoreObject = NO
CanonicalKnowledgeStructureIsUserIndependent = YES
UserLevelModel = NOT_REQUIRED
PrimaryNavigation = HIERARCHY
KnowledgeBaseManagement = OUT_OF_SCOPE
ComplexFreeKnowledgeGraph = OUT_OF_SCOPE
DeliveryPlatform = WEB_BROWSER
PrimaryExperience = DESKTOP_WEB
NativeApp = DEFERRED
V1Architecture = MODULAR_MONOLITH
```

不得把系统退化为“文档切块 + 向量检索 + 普通 RAG + AI 摘要”，也不得引入第二棵个性化知识树。

## 5. 原始输入保护

- `raw/11-MySQL数据库.docx`
- `raw/12-Redis中间件.docx`
- `raw/40-英语学习.docx`

以上文件是只读 Golden Case 原件。不得改写、转换后覆盖、删除或静默替换。派生物必须放在独立路径，并通过 SHA-256 将结果追溯到原件。

解析必须保留标题层级、段落顺序、表格行列与单元格文本、图片引用、页码或原始顺序。不得访问 Redis 文档中的遗留本地文件链接，也不得把链接目标当成输入内容。

## 6. 工程边界

- V1 使用模块化单体；禁止擅自拆成微服务。
- 正式交付是 Desktop Web；基础响应式只保证安全可读，不承诺移动端功能等价。
- 先生成并确认 KnowledgeSkeleton，再生成 Module 深度内容；禁止整份文档一次性生成全部深度内容。
- 每个 CognitiveModule 必须有唯一主归属和唯一 `PrimaryCognitiveSpine`。
- Theme 必须形成 `ThemeClosure`，Landscape 必须形成 `LandscapeClosure`。
- 关键认知必须可回溯到来源；不得静默补齐来源缺口。
- Renderer 只能投影正式认知产物，不得创造第二套事实。
- 后端固定使用 JDK 21、Maven 3.9.16、Spring Boot 4.1.0、PostgreSQL 18
  和 MyBatis Starter 4.0.0；不引入 JPA、MyBatis-Plus 或默认 WebFlux。

## 7. 工作方式

开始任何任务前：

1. 读取本文件、`README.md`、设计索引、`docs/task-cards/README.md`、当前
   `READY` 任务卡和相关正式设计章节。
2. 检查真实目录、Git 状态、当前分支、最近提交和未提交修改。
3. 保留用户修改；不得 reset、覆盖、amend 或把无关修改混入当前提交。
4. 先写失败的验证或契约测试，再实现最小变更。
5. 每项 Wave 资产必须有可复现的验证命令和明确 Gate 结果。
6. 只执行唯一 `READY` 卡的写集；依赖阻断、文档缺口或排队卡不得提前实施。
7. 完成卡片时同步对应任务卡索引、工程计划和准入记录；Wave 0 运行
   `bash tests/task-cards/verify-task-cards.sh`，Wave 1 设计运行
   `bash tests/task-cards/verify-wave1-design-cards.sh`。

## 8. Agent 路由

- 主 Agent 负责共享写集、实现决策、最终整合与用户授权边界。
- 只读代码搜索、大文件扫描、日志与测试输出归纳使用 `fast_explorer`。
- 固定提交的一般深度审查默认使用 `deep_reviewer`。
- 固定候选最终 GO/NO-GO、正式数据库写入前复核或同等级高风险门禁默认使用
  `ultra_gatekeeper`。
- W0-08 采用用户于 `2026-07-30` 明确指定的例外：一般审查与最终门禁均使用
  `gpt-5.6-sol/high`，不使用 ultra 模型，但必须保持两个独立审查阶段。
- Wave 1 详细设计采用用户批准的路由：W1-D00 至 W1-D04 使用
  `gpt-5.6-sol/high` 设计 Gate；W1-D05 使用两个相互独立的
  `gpt-5.6-sol/high` 审查阶段，不使用 ultra 模型。
- 没有独立、边界清晰的子任务时保持 Solo。

## 9. 准入门禁

```text
W0-G0 RepositoryBaseline
W0-G1 DesignSourceRegistry
W0-G2 SpecialtyContractCoverage
W0-G2A BuildBaseline
W0-G3 JsonSchemaValidation
W0-G4 GoldenCaseRegression
W0-G4A UiContractValidation
W0-G5 TestAndCI
W0-G6 FixedCommitReview
W1-DG0 DesignGovernance
W1-DG1 SourceDocumentContract
W1-DG2 DocumentBlockFidelityAndSafety
W1-DG3 ReparseAndReferenceCompatibility
W1-DG4 SourcePreviewAndAcceptance
W1-DG5 FixedDesignReview
```

只有以上 Gate 全部为 `PASS`，且固定候选提交通过适用的独立最终准入复核，
才允许把 `Wave1FeatureDevelopmentEntry` 改为 `GO`。W0-08 的适用模型例外
以第 8 节为准。

Wave 1 设计 Gate 只授权书面设计推进，不授权业务实现。只有 W1-DG0 至 W1-DG5
全部 `PASS`，完整书面设计再次取得用户批准，并另行建立实现任务卡后，才允许
讨论最小实现卡的 `READY` 状态。
