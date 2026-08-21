# Cognitura 设计与输入索引

```text
CanonicalProjectName = Cognitura
RepositoryName = cognitura
CurrentStage = WAVE1_IMPLEMENTATION_IN_PROGRESS
DesignAlignmentStatus = COMPLETE
DevelopmentPlanningEntry = AUTHORIZED_FOR_TASK_CARD_EXECUTION
CurrentDesignBaseline = Cognitura-Overall-Design-1.2
CanonicalSourceManifest =
  docs/engineering/cognitura-source-manifest.yaml
W0-G1 DesignSourceRegistry = PASS
SpecialtyContractCoverage =
  docs/engineering/cognitura-specialty-contract-coverage.md
W0-G2 SpecialtyContractCoverage = PASS
PageContractBaseline =
  docs/contracts/cognitura-page-contracts.md
RendererContractBaseline =
  docs/contracts/cognitura-renderer-contract.md
W0-G4A UiContractValidation = PASS
SchemaDesignBaseline =
  docs/design/cognitura-schema-baseline-2.0.md
SchemaDesignBaselineStatus = FORMAL_SCHEMA_REBASELINE
SchemaCatalog = schemas/catalog.json
SchemaEvidenceMap = schemas/evidence-map.json
W0-G3 JsonSchemaValidation = PASS
Wave1DesignGovernance =
  docs/superpowers/specs/2026-07-30-wave1-source-ingestion-governance-design.md
Wave1DesignPlan =
  docs/engineering/cognitura-wave-1-design-plan.md
Wave1ImplementationSlicingDesign =
  docs/superpowers/specs/2026-07-30-wave1-implementation-slicing-design.md
Wave1DesignStatus = USER_APPROVED
Wave1ImplementationTaskCardPlan =
  docs/superpowers/plans/2026-07-30-wave1-implementation-task-card-bootstrap.md
Wave1ImplementationPlanningStatus = TASK_CARD_SET_BOOTSTRAPPED
Wave1ImplementationTaskCards =
  docs/task-cards/wave-1-implementation/README.md
Wave1ImplementationPlan =
  docs/engineering/cognitura-wave-1-implementation-plan.md
Wave1ImplementationVerification =
  scripts/verify-wave1-implementation
Wave1ImplementationTaskCardSet = BLOCKED_BY_DATABASE_GATE
ActiveTaskCard = NONE
ActiveTaskCardStatus = NONE
VisualStyleBaselineTaskCards =
  docs/task-cards/visual-style-baseline/README.md
VisualStyleBaselineExecutionStateAuthority = docs/task-cards/visual-style-baseline/execution-state.md
VisualStyleBaselineTaskCardSet = GOVERNED_BY_EXECUTION_STATE
ModuleDefaultReadingImplementationTaskCards =
  docs/task-cards/module-default-reading-implementation/README.md
ModuleDefaultReadingExecutionStateAuthority = docs/task-cards/module-default-reading-implementation/execution-state.md
ModuleDefaultReadingImplementationTaskCardSet = GOVERNED_BY_EXECUTION_STATE
ModuleDefaultReadingImplementationTaskCardCount = 9
ModuleDefaultReadingImplementationEntry = GOVERNED_BY_EXECUTION_STATE
ModuleDefaultReadingActiveImplementationTaskCard = SEE_MODULE_DEFAULT_READING_EXECUTION_STATE
ModuleDefaultReadingBusinessImplementation = SEE_MODULE_DEFAULT_READING_EXECUTION_STATE
ModuleDefaultReadingDocumentationGap = DOC-GAP-MDR-001
HighFidelityDesignManifest =
  docs/engineering/cognitura-high-fidelity-design-manifest.yaml
VisualStyleReferenceAuthority = docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md
VisualStyleReferenceManifest = docs/engineering/cognitura-visual-style-baseline-manifest.yaml
VisualStyleReferenceScope = VISUAL_DNA_AND_SEMANTIC_TOKENS_ONLY
VisualStylePageArchitectureAuthority = NO
VisualStyleInteractionAuthority = NO
VisualStyleInformationArchitectureAuthority = NO
VisualStyleComponentHierarchyAuthority = NO
VisualStyleCardQuantityAuthority = NO
VisualStyleDashboardLayoutAuthority = NO
HighFidelityContractCoverage =
  docs/engineering/cognitura-high-fidelity-contract-coverage.md
HighFidelityDesignStatus = COMPLETE
HighFidelityDesignGate = HF-DG4 PASS
HighFidelityReviewedPreparationSHA = 463fd4829e7c4bb8da071253e8ae9b15cee2a0cf
HighFidelityReadingPresentationContract = PASS
HighFidelityInteractionStateModel = PASS
HighFidelityEvidencePlan =
  docs/engineering/cognitura-high-fidelity-design-plan.md
HighFidelityEvidenceAcceptance =
  docs/engineering/cognitura-high-fidelity-design-acceptance.md
HighFidelityEvidenceContract = PASS
HighFidelityVisualBaseline =
  docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md
HighFidelityVisualTaskCardSet = COMPLETE
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
DevelopmentEntryPrompt =
  docs/engineering/cognitura-development-entry-prompt.md
ActiveDesignTaskCard = NONE
ActiveImplementationTaskCard = NONE
BusinessImplementation = USER_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

本索引登记实际落地文件，不复制总体设计正文，也不改变历史设计名称。
正式原始输入的路径、角色、版本、字节数与 SHA-256 唯一机器清单是
[`cognitura-source-manifest.yaml`](cognitura-source-manifest.yaml)；经批准的
工程重基线由本索引、固定 Git 提交和对应 Gate 记录追踪，不混入只读原始输入
Manifest。

## 1. 正式总体设计

| 工程引用名 | 实际路径 | 原始版本标识 | 状态 | Manifest Source ID |
|---|---|---|---|---|
| `Cognitura-Overall-Design-1.2` | `cognitive-knowledge-atlas-overall-design-1.2.md` | `Cognitive-Knowledge-Atlas-Overall-Design-1.2` | `FORMAL_BASELINE` | `DESIGN-OVERALL-001` |

该文件是当前 Cognitura 总体设计基线。历史名称和版本号必须保留。

## 2. 专项设计登记

| 专项设计 | 总体设计引用状态 | Repository 文件状态 | 工程处理 |
|---|---|---|---|
| `Cognitive-Knowledge-System-Construction-Design-1.0` | `RM-01～RM-11` 已回迁，`11/11` | `MISSING` | 历史正文缺口继续登记；字段级契约由批准的 2.0 重基线与已验证 Schema 唯一承接 |
| `Cognitive-Knowledge-Atlas-UIUX-Design-1.0` | `UI-RM-01～10` 已回迁，`10/10` | `MISSING` | 页面与 Renderer 非 Schema 契约已验证；`DOC-GAP-002` 保持开放 |

```text
DocumentationGapCount = 2
SpecialtyBodyAbsenceBlocksWave0Planning = NO
SchemaRebaselineDisposition = APPROVED
SpecialtyBodyAbsenceBlocksFieldLevelSchemaClosure = NO
```

## 3. Schema 重基线

| 工程引用名 | 实际路径 | 状态 | 权威边界 |
|---|---|---|---|
| `Cognitura-Schema-Baseline-2.0` | `docs/design/cognitura-schema-baseline-2.0.md` | `FORMAL_SCHEMA_REBASELINE` | 从属于总体设计；按固定审查结果升级并补足字段级工程裁决；不冒充历史专项正文 |

该重基线是 `DOC-GAP-001` 的批准处置证据。W0-04 已将其投影为 14 份 Draft
2020-12 Schema 文档、13 个可实例化契约、Catalog 和逐约束节点 Evidence Map；
13 个正例、18 个结构反例、12 个严格对象未知字段反例、2 个合法非 Published
空值上下文、34 个跨对象语义反例、68 个运行时语义错误码、645 个精确 Schema
证据节点、16 个语义不变量证据、6 个证据映射篡改与全量渲染 round-trip
反例已通过，固定候选 `72b5ce7` 深审为 `GO / P0=0 / P1=0 / P2=0`，因此
`W0-G3 JsonSchemaValidation = PASS`。历史专项正文缺失事实仍登记为开放
缺口，但批准的重基线已解除其执行阻断。

## 4. Golden Case 原始输入

| Case ID | 路径 | 类型 | Manifest Source ID | 关键验收职责 |
|---|---|---|---|---|
| `GC-MYSQL-001` | `raw/11-MySQL数据库.docx` | 技术机制/规则/存储 | `GC-MYSQL-001` | 跨锁、事务、数据行、Undo Log 形成闭环；不得把 MVCC 等全部提升为一级 Module |
| `GC-REDIS-001` | `raw/12-Redis中间件.docx` | 技术机制/工程场景 | `GC-REDIS-001` | 聚合事件循环、输出缓冲、Pending Writes、beforeSleep、写事件兜底和 IO 多线程边界；`beforeSleep` 不得升级 |
| `GC-ENGLISH-001` | `raw/40-英语学习.docx` | 规则体系/表格/例句 | `GC-ENGLISH-001` | 五大句型形成统一规则与判定路径；例句不得升级为 Module 或主导航 |

三份 DOCX 均为纯原始学习材料，不是设计契约来源。它们没有重复内容，也不包含 Cognitura 或历史项目名称。

## 5. 总体设计已落地的正式契约

| 契约组 | 总体设计章节 |
|---|---|
| 产品定位、非目标、核心不变量 | 1–4 |
| 四层层级、边界、升降级、角色与 UnderstandingRoute | 5–7 |
| Primary Cognitive Spine、认知闭环与密度 | 8–10 |
| 阅读深度、关系、来源、多文档归并 | 11–14 |
| ThemeClosure、LandscapeClosure、ThemeModel | 15–16 |
| 两阶段生成与局部重生成 | 17–18 |
| 十项正式认知产物契约 | 19 |
| 页面、Renderer、Source Evidence、状态与 Desktop Web 边界 | 20–20.11 |
| 质量、Golden Case、模块化单体、Wave 0–5 | 21–26 |
| Reverse Migration 与正式状态 | 27–28 |

## 6. 工程记录

- `docs/engineering/cognitura-repository-baseline-review.md`
- `docs/engineering/cognitura-naming-migration.md`
- `docs/engineering/cognitura-technology-baseline.md`
- `docs/engineering/cognitura-source-manifest.yaml`
- `docs/engineering/cognitura-specialty-contract-coverage.md`
- `docs/design/cognitura-schema-baseline-2.0.md`
- `docs/contracts/cognitura-page-contracts.md`
- `docs/contracts/cognitura-renderer-contract.md`
- `docs/engineering/cognitura-wave-0-plan.md`
- `docs/engineering/cognitura-wave-0-entry-decision.md`
- `docs/task-cards/README.md`
- `docs/superpowers/specs/2026-07-30-wave1-source-ingestion-governance-design.md`
- `docs/engineering/cognitura-wave-1-design-plan.md`
- `docs/engineering/cognitura-wave-1-design-acceptance.md`
- `docs/task-cards/wave-1/README.md`
- `docs/superpowers/specs/2026-07-30-wave1-implementation-slicing-design.md`
- `docs/superpowers/plans/2026-07-30-wave1-implementation-task-card-bootstrap.md`
- `docs/task-cards/module-default-reading-implementation/README.md`
- `scripts/verify-module-default-reading-implementation-cards`
- `tests/task-cards/verify-module-default-reading-implementation-cards.sh`
- `docs/engineering/cognitura-high-fidelity-design-plan.md`
- `docs/engineering/cognitura-high-fidelity-design-acceptance.md`
- `docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md`
- `docs/task-cards/high-fidelity-visual/README.md`

这些工程记录只描述当前落地事实、缺口、计划和门禁，不替代正式设计。

## 7. Wave 1 详细设计登记

| 设计切片 | 产物 | 状态 | Gate |
|---|---|---|---|
| `W1-D00` | `docs/superpowers/specs/2026-07-30-wave1-source-ingestion-governance-design.md` | `DONE` | `W1-DG0 PASS` |
| `W1-D01` | `docs/design/wave-1/cognitura-source-document-contract-1.0.md` | `DONE` | `W1-DG1 PASS` |
| `W1-D02` | `docs/design/wave-1/cognitura-document-block-contract-1.0.md` | `DONE` | `W1-DG2 PASS` |
| `W1-D03` | `docs/design/wave-1/cognitura-reparse-reference-contract-1.0.md` | `DONE` | `W1-DG3 PASS` |
| `W1-D04` | `docs/design/wave-1/cognitura-source-preview-contract-1.0.md` | `DONE` | `W1-DG4 PASS` |
| `W1-D05` | `docs/engineering/cognitura-wave-1-design-acceptance.md` | `DONE` | `W1-DG5 PASS` |

W1-D00 治理说明、W1-D01 至 W1-D04 四份来源设计契约和验收记录均已落地。
修复固定候选 `17dabff23b029e1a6fc7f47155f552ed3f16d775` 已通过两个独立
`gpt-5.6-sol/high` 阶段，`W1-DG5 = PASS`，且完整设计与 14 张中细粒度实现
切片书面规格均已获用户批准。任务卡 bootstrap 计划已完成；用户已授权持续执行
现有卡集。`W1-I01` 已完成固定候选零发现深审并关闭，I02 等待独立数据库 Gate，
`W1-I05` 和 `W1-I06` 已零发现关闭；当前无 `READY` 卡，`W1-I07` 未释放。

`ModuleDefaultReadingState` 的首个实现切片另建 `MDR-I00..MDR-I08` 书面卡集，
不复用或改写上述 source 卡编号与写集。该集合当前为
`GOVERNED_BY_EXECUTION_STATE`；当前状态、集合级授权和唯一活动卡只从
`docs/task-cards/module-default-reading-implementation/execution-state.md` 读取。其
首张业务卡仅做 Published `CognitiveModule` 到只读阅读模型的纯投影，Schema、
数据库、后端、路由和完整页面均在写集之外。

`DOC-GAP-MDR-001` 记录 Conditions/Results 缺少独立 Canonical 投影映射；它阻断
完整 `ModuleDefaultReadingState` 实现验收，不阻断当前明确缩小的投影切片。任何字段
变更必须先形成独立 Schema 设计/实现卡，不得由 Renderer 或任务卡猜测补齐。

## 8. 高保真交互正式专项登记

| 工程引用名 | 实际路径 | 状态 | 独立来源 ID | Gate |
|---|---|---|---|---|
| `Cognitura-High-Fidelity-Interaction-Specialty-1.0` | `Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md` | `FORMAL_SPECIALTY_BASELINE` | `HF-DESIGN-001` | `HF-DG4 PASS` |

正式专项的路径、版本、字节数和 SHA-256 由
[`cognitura-high-fidelity-design-manifest.yaml`](cognitura-high-fidelity-design-manifest.yaml)
独立登记；`46` 个 StateCode 已恰好一次分类到六轴、临时 UI、流程、事件或派生
结果，五级持久化、submit-unknown、显式 stale projection、Revert-as-new-ChangeSet
与 12 个既有 PageState non-change 边界已通过 `HF-DG2`。八类 Canonical 证据、
`20` 项 RF-AC、`20` 个异常、`30` 项反向迁移追溯与机制域/规则政策域场景的
输入合同已通过 `HF-DG3`，固定准备提交又通过 `HF-DG4` 双阶段零发现审查；执行计划与验收台账分别由
[`cognitura-high-fidelity-design-plan.md`](cognitura-high-fidelity-design-plan.md) 和
[`cognitura-high-fidelity-design-acceptance.md`](cognitura-high-fidelity-design-acceptance.md)
承担，所有 Artifact、视觉和可用性结果仍为 `NOT_RUN`。原始 deferred 追溯由
[`cognitura-high-fidelity-contract-coverage.md`](cognitura-high-fidelity-contract-coverage.md)
承担。它们不修改 Wave 0 固定 manifest/coverage；本轮只关闭合同设计阶段，视觉、
可用性与实现仍未执行。

候选声明的三份前序专项正文在 Repository 中不存在，登记为
`DOC-GAP-HF-001..003`，不得作为已核验权威。HF-D01 已关闭页面与呈现冲突，
HF-D02 已关闭正交状态与恢复边界，HF-D03 已关闭证据输入合同，HF-D04 已完成
固定候选双阶段审查并将专项晋级正式基线；视觉、可用性与实现均未验收，当前没有
活动设计卡；
该高保真专项本身未创建或释放 `W1-I00`；后续 bootstrap 已独立完成并关闭 I00。
当前业务授权已按既定卡集串行推进并关闭 `W1-I06`；后续等待 I02 独立数据库 Gate，正式数据库
写入和远程推送仍未授权。

### 8.1 当前视觉样式参考登记

| 工程引用名 | 实际路径 | Manifest | 状态 | 权威边界 |
|---|---|---|---|---|
| `Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0` | `docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md` | `docs/engineering/cognitura-visual-style-baseline-manifest.yaml` | `FORMAL_VISUAL_STYLE_BASELINE` | `VISUAL_DNA_AND_SEMANTIC_TOKENS_ONLY` |

该参考图和正文从属于总体设计与高保真交互专项。它们不拥有页面架构、信息架构、
交互、组件层级、卡片数量或 dashboard 布局权威；正式 Reading First 与 Continuous
Document 合同优先。历史专项正文候选所声明的 `DOC-GAP-HF-001..003` 继续开放，
不会因视觉参考落地而被补写或关闭。

## 9. 高保真视觉基础登记

| 工程引用名 | 实际路径 | 状态 | Gate |
|---|---|---|---|
| `Cognitura-High-Fidelity-Visual-Design-1.0` | `docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md` | `CROSS_LAYER_RESPONSIVE_EXPORT_EVIDENCE_ESTABLISHED` | `HV-D04 PASS` |

`HV-D00` 只建立视觉 token、桌面/小屏阈值、a11y focus、Reading First 零常驻治理
侧栏、按需 SourceEvidence、确定性 URL fixture 和 1440×1100 foundation 截图。
`HV-D01` 已建立 Module 默认阅读的确定性 DOM 与 1440×1100 证据；`HV-D02` 已建立
Relation 主聚焦与完整来源核验的两张 1440×1100 证据，仅关闭各卡 Owner 的
`HIGH_FIDELITY_VISUAL` 观察；`HV-D03` 已建立修订影响、部分失败恢复与冲突草稿
三张 1440×1100 证据；`HV-D04` 已建立四层、跨域、390×844 小屏与 1200×1600
静态导出证据并释放 `HV-D05` 为唯一 `READY`。正式 HF 专项与
`HF-DG4 PASS` 不变；整体视觉设计、可用性、实现、正式数据库写入和远程推送仍未执行。
