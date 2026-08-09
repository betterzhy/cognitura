# Cognitura 高保真交互设计整合规格

```text
DesignDate = 2026-08-06
CanonicalProjectName = Cognitura
DesignScope = HIGH_FIDELITY_INTERACTION_DESIGN_INTEGRATION
SourceCandidate =
  Cognitive-Knowledge-Atlas-Interaction-State-Completion-
  and-High-Fidelity-Input-Design-1.0.md
IntegrationTarget = EXISTING_COGNITURA_REPOSITORY
NewRepository = FORBIDDEN
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. 目的

本规格定义如何将用户新增的交互状态补齐与高保真输入设计完整吸收到现有
Cognitura 正式设计体系中，同时保持以下边界：

- 不创建第二个产品或 Repository；
- 不改变个人认知结构构建的产品目标；
- 不建立第二棵知识树或第二套 Renderer 事实；
- 不把设计补齐解释为业务实现授权；
- 不把 46 个状态机械实现为单一互斥枚举；
- 不从逻辑设计名称直接推导物理表、Entity、Mapper 或 API；
- 不扩大或改写当前 Wave 1 来源接入实现卡的业务写集。

本轮完成的是专项设计治理、冲突裁决、状态模型整理、高保真证据合同和后续任务卡。
真实高保真视觉稿、可操作原型和业务代码仍须在后续独立 Gate 下推进。

本轮用户授权在当前分支上建立独立 `HIGH_FIDELITY_DESIGN` 集合，并使
`HF-D00` 成为唯一活动设计卡。该授权不创建或释放 `W1-I00`，不修改独立的
`wave1-implementation-card-bootstrap` worktree，也不改变
`BusinessImplementation = NOT_AUTHORIZED`。

## 2. 产品与权威裁决

### 2.1 产品归属

新增设计属于 Cognitura 的后续交互与呈现专项，不构成新产品。其历史文件名可以
保留，但正文中的新增工程身份必须使用：

```text
CanonicalProjectName = Cognitura
HistoricalDesignName = Cognitive Knowledge Atlas V1
PrimaryPurpose = PERSONAL_COGNITIVE_STRUCTURE_BUILDING
DeliveryPlatform = WEB_BROWSER
PrimaryExperience = DESKTOP_WEB
V1Architecture = MODULAR_MONOLITH
```

### 2.2 正式层级

文件中的旧显示词只允许作为人类可读别名：

| 历史/显示词 | Cognitura 正式对象 |
|---|---|
| `DomainPanorama` | `KnowledgeLandscape` 的全景投影，不是独立层级 |
| `Theme` | `KnowledgeTheme` |
| `Module` | `CognitiveModule` |
| `Element` | `KnowledgeElement` |

正式层级始终是：

```text
KnowledgeLandscape
→ KnowledgeTheme
→ CognitiveModule
→ KnowledgeElement
```

### 2.3 权威链

整合后的权威顺序为：

1. `Cognitura-Overall-Design-1.2` 继续承担产品目标、范围与不可变约束；
2. `Cognitura-Schema-Baseline-2.0` 继续承担现有字段级 Schema 权威；
3. 新增专项正文承担阅读优先、交互状态、恢复语义和高保真验收输入；
4. 页面和 Renderer 合同投影专项正文中可机器验证的非 Schema 规则；
5. 工程索引、计划和任务卡只记录落地状态，不覆盖前三项设计事实。

新增专项只有在来源登记、冲突裁决、验证和固定候选审查全部通过后，才能从
`CANDIDATE` 变为 `FORMAL_SPECIALTY_BASELINE`。文件内自声明的
`FORMAL_HIGH_FIDELITY_INPUT_BASELINE` 不单独构成正式证据。

新增文件提到但 Repository 中不存在的三份专项正文不得被列为已核验权威：

```text
Cognitive-Knowledge-Atlas-
  Cognitive-Relationship-and-Page-Structure-Design-1.0
Cognitive-Knowledge-Atlas-
  Cognitive-Relationship-Expression-and-Interaction-Design-1.0
Cognitive-Knowledge-Atlas-
  Interaction-State-and-Multi-View-Consistency-Design-1.0
```

它们只能登记为 `DocumentationGap` 或“候选文件的历史输入声明”，直到正文实际
落地并通过来源校验。新增专项中已经完整写出的规则可以作为本专项自身规则接受，
但不得伪称已从缺失文件核验。

## 3. 页面与呈现冲突裁决

### 3.1 Interactive Cognitive Document

正式采用：

```text
PrimaryPresentationModel = INTERACTIVE_COGNITIVE_DOCUMENT
PrimaryExperienceModel = READING_FIRST
PrimaryReadingUnit = COGNITIVE_MODULE
```

`READING_FIRST` 表示核心问题、结论、机制、条件、边界、例外、主要 Relation 和
来源入口在零交互时可理解；它不删除层级导航、PrimaryCognitiveSpine、Renderer、
Source Evidence 或结构修订能力。

### 3.2 连续叙事与“不得退化为连续长文”

两项旧新规则按以下方式同时成立：

```text
PureUnstructuredLongArticle = FORBIDDEN
StructuredContinuousCognitiveNarrative = REQUIRED_WHEN_NEEDED
```

ModuleReading 必须由 CoreThesis、PrimaryCognitiveSpine、认知正文、有限主投影、
CriticalBoundaries、KnowledgeElements、Relations 和 SourceReferences 构成。
不得把所有事实放进卡片，也不得用纯 Markdown 长文取代结构投影。

### 3.3 ModuleReading 右栏

旧的“三栏永久布局”和新的“阅读态永久侧栏为 0”不能同时作为默认硬约束。
正式采用以下最小修订：

```text
ModuleReadingDefaultPersistentSidePanel = 0
KnowledgeHierarchyOrientation = RETAINED
QuickSourcePanel = ON_DEMAND_TRANSIENT
FullSourceEvidence = ON_DEMAND_WORKSPACE_OR_ROUTE
RelatedModules = INLINE_OR_ON_DEMAND
KnownGaps = INLINE_WHEN_UNDERSTANDING_CHANGES
```

桌面端可以保留层级定位区，但 Source Evidence、Related Modules 和治理状态不得
组成默认常驻右侧工作台。完整 `SourceEvidence` 页面职责和可直接路由能力保留；
它在 ModuleReading 中以轻量入口、临时面板或完整 Workspace 打开。

### 3.4 小屏

小屏继续只承诺响应式安全：连续文本、主路径和核心关系可读；辅助 Workspace
可以转为临时全屏层或底部层。不得据此承诺移动端功能等价、原生手势或专属编辑器。

## 4. 交互状态模型

### 4.1 设计原则

新增文件的 46 个 `StateCode` 全部保留可追溯性，但不作为一个互斥状态枚举。
它们被整理为六个正交状态轴、事件/命令和派生结果。任一可恢复页面状态由多个轴
组合而成：

```text
InteractionSnapshot =
  ModeAxis
  + FocusAxis
  + AuxiliarySurfaceAxis
  + DraftAxis
  + ProcessingAxis
  + RecoveryAxis
  + StableSemanticAnchor
```

### 4.2 ModeAxis

```text
READING
VERIFICATION
REVISION
```

`READING_MODE`、`VERIFICATION_MODE`、`REVISION_MODE` 映射到本轴。
`COGNITIVE_PERSPECTIVE_OVERRIDE` 是 Projection 参数，不新增第四主模式。

### 4.3 FocusAxis

```text
IDLE
ELEMENT_PINNED
RELATION_PINNED
```

`PREVIEW` 和 `INPUT_FOCUS` 是临时 UI 状态，不替代稳定主聚焦。任何时刻只能有一个
稳定主聚焦；Relation 聚焦时端点和来源对象只作为次级上下文。

### 4.4 AuxiliarySurfaceAxis

```text
NONE
QUICK_SOURCE
FULL_VERIFICATION
FULL_REVISION
```

`QUICK_SOURCE_PANEL` 不进入 URL、不跨刷新；完整核验和完整修订可以进入 History，
但必须保存原 Canonical Target 与阅读 Anchor。

### 4.5 DraftAxis

```text
NO_DRAFT
CLEAN_DRAFT
DIRTY_DRAFT
SAVED_DRAFT
RECOVERABLE_DRAFT
CONFLICTED_DRAFT
```

`QUICK_REVISION`、`AUTO_UPGRADING`、`FULL_REVISION` 是修订流程阶段，不替代
DraftAxis。快速修订触及语义、结构、来源充分性、锁定内容或身份时，必须显式升级
到完整修订并保留草稿。

### 4.6 ProcessingAxis

```text
IDLE
IMPACT_ANALYZING
COMMIT_ALLOWED
COMMIT_BLOCKED
SUBMITTING
CANONICAL_SAVED
RECOMPUTING
LOCAL_REGENERATING
PENDING_VERIFICATION
PARTIAL_FAILURE
FAILED
COMPLETE
```

原状态中的 `IMPACT_ANALYSIS_FAILED`、`COMMIT_FAILED`、`RECOMPUTE_FAILED`、
`GENERATION_FAILED` 保留为带 `failureStage` 的失败结果；`RECOMPUTED`、
`GENERATED_CANDIDATE`、`VERIFIED` 等保留为带 `resultKind` 的阶段结果。
不得为每一种组合创建独立全局枚举。

### 4.7 RecoveryAxis 与事件

```text
RecoveryAxis =
  STABLE
  | HISTORY_RESTORING
  | REFRESH_RESTORING
  | RESTORE_FAILED

NavigationEvent =
  CLOSE_AUXILIARY_PANEL
  | CLOSE_RELATION_FOCUS
  | RESTORE_ORIGIN_OBJECT
  | RESTORE_COGNITIVE_PERSPECTIVE
  | SOFT_RETURN
  | HARD_RESET
  | ROUTE_RETURN
```

原第 5.4 章中的关闭、返回和重置代码主要是事件或恢复动作，不应与页面稳定状态
混为同一枚举。`HISTORY_RESTORE` 和 `REFRESH_RESTORE` 映射 RecoveryAxis。

### 4.8 46 状态完整性

专项正文必须保留原 46 个代码的逐项合同，并新增一张机器可验证的分类表，为每个
代码标明：

```text
OriginalStateCode
Classification = AXIS_VALUE|TRANSIENT_UI|FLOW_PHASE|EVENT|DERIVED_RESULT
OwningAxisOrFlow
PersistenceBoundary
URLHistoryDisposition
CanonicalWriteBoundary
```

验证必须拒绝：遗漏、重复分类、同一代码多 Owner、临时状态进入公开 URL、事件被
当作可持久状态，以及 PageState 生命周期枚举被静默扩写。

## 5. 持久化与恢复边界

### 5.1 五级边界

| 边界 | 允许内容 | 禁止内容 |
|---|---|---|
| Ephemeral UI | Hover、Tooltip、Preview、临时键盘游标 | URL、服务端持久化 |
| URL | 页面、稳定对象、主模式、稳定 Relation、可分享 Perspective | draftId、技术版本 ID、提交过程 |
| Browser History | 稳定 Focus、Workspace、Perspective、语义 Anchor | Canonical 事实副本 |
| Session/Draft Store | 草稿、恢复 Guard、未确认 ChangeSet 引用 | 已发布认知事实 |
| Canonical Server State | 已确认 Revision、来源、处理结果和版本指针 | 纯视觉状态、Hover、滚动坐标 |

### 5.2 刷新恢复

刷新按“路由 → 当前正式版本 → 稳定 ID → 模式/Workspace → 草稿 → 语义 Anchor”
恢复。正式版本变化时必须重新基线化或进入冲突草稿；无法恢复时返回最近可用上级并
显式说明，禁止静默落回默认页。

### 5.3 提交不确定性

网络超时不能直接等同失败。客户端必须使用同一幂等键查询原提交结果；Canonical
保存成功后只能通过新 Revert ChangeSet 撤销，不能物理删除历史或伪装为未提交。

## 6. 与现有领域及 Schema 的映射

新增文件中的下列名称先作为逻辑概念映射，不直接创建物理对象：

| 候选名称 | 当前 Cognitura 承接方式 |
|---|---|
| `KnowledgeObjectVersion` | 十项正式认知产物各自的 revision 身份 |
| `RelationVersion` | owning artifact revision 内的正式 Relation |
| `ContextBinding` | 当前层级、主归属、ReturnToken 和语义 Anchor 的投影合同 |
| `EvidenceBinding` | `EvidenceReference` 与认知产物/Relation 的来源引用 |
| `ChangeSet` | `CognitiveStructureRevision` 或 `CognitiveModuleRevision` 的变更封装概念 |

本轮不得修改 `Cognitura-Schema-Baseline-2.0` 或 JSON Schema 来猜测新字段。
只有后续字段级专项回答以下问题后，才允许建立 Schema 变更卡：

- 哪些状态必须跨设备或跨会话恢复；
- Draft 和 ChangeSet 的事实 Owner；
- Revision、幂等键和处理任务的唯一性；
- 投影新鲜度与 Canonical 保存边界；
- ACL、保留期和删除语义；
- 是否需要新的物理对象，还是现有 revision JSON 足以承载。

现有 `PageState` 的 12 个值继续表示页面/生成生命周期，不与 46 个交互代码合并。
Renderer Input 继续只允许投影正式 CognitiveModule；视觉预算与焦点状态优先作为
页面验收合同，不扩写 Renderer 事实模型。

## 7. 高保真证据范围

### 7.1 必须覆盖的八类证据

```text
DomainDefaultReadingState
ThemeDefaultReadingState
ModuleDefaultReadingState
ModuleFocusedRelationState
ModuleSourceVerificationState
ModuleRevisionState
SmallScreenReadingState
StaticExportExample
```

其中 `ModuleDefaultReadingState` 是首个且最高优先级目标。它未通过前，不开始大型
关系图、完整治理后台、品牌首页、复杂动效或前端技术选型。

### 7.2 分阶段验收

```text
CONTRACT
→ HIGH_FIDELITY_VISUAL
→ HIGH_FIDELITY_USABILITY
→ IMPLEMENTATION
```

合同 PASS 只证明状态、规则、边界和验收输入完整，不表示视觉、可用性或实现 PASS。
专项正文中的 20 项 RF-AC 和 20 类异常必须保留；视觉阶段使用真实页面证据，
可用性阶段验证理解、操作、返回、恢复和错误判断。

### 7.3 最小原型顺序

1. Module 默认阅读；
2. Relation Focus；
3. Quick Source 与完整 Source Verification；
4. Revision、三类影响和提交结果；
5. Refresh、History、冲突草稿和部分失败；
6. Domain、Theme、小屏与静态导出抽样。

这不是删除其余状态；它是用最少原型覆盖最高风险状态族，避免把 46 个合同机械
绘制为 46 张重复页面。

## 8. 设计任务卡拆分

建立独立集合 `HIGH_FIDELITY_DESIGN`，不得重开已完成的 Wave 1 设计卡，也不得
修改独立 worktree 中的 W1-I00～W1-I13。

本分支的执行拓扑固定为：`HF-D00` 是唯一活动设计卡；`W1-I00` 不存在于本分支
活动卡集合中，不因 HF/HV 设计推进而创建、释放或变为 `READY`。HF/HV 的任何
Gate 结果均不构成 Wave 1 业务实现授权。

| ID | 单一职责 | 主要产物 | Gate |
|---|---|---|---|
| `HF-D00` | 设计治理与来源登记 | 权威链、命名、索引、缺口、卡集合同 | `HF-DG0` |
| `HF-D01` | 页面与呈现冲突裁决 | Reading First、右栏、连续叙事、预算、页面/Renderer 合同 | `HF-DG1` |
| `HF-D02` | 正交状态与恢复边界 | 46 状态分类、URL/History/Draft/Canonical 边界、异常矩阵 | `HF-DG2` |
| `HF-D03` | 高保真证据与验收 | 八类证据、20 项 RF-AC、视觉/可用性阶段合同 | `HF-DG3` |
| `HF-D04` | 固定设计候选复核 | 全量追溯、冲突清零、独立双阶段审查 | `HF-DG4` |

任务卡大小合同：

```text
SingleDesignDecisionOwner = REQUIRED
BusinessCode = FORBIDDEN
DatabaseMigration = FORBIDDEN
RawInputReadOrWrite = FORBIDDEN
OneLocalCommitPerCard = REQUIRED
PositiveAndNegativeValidation = REQUIRED
ExactlyOneReadyCard = REQUIRED
```

`HF-D04` 使用两个相互独立的 `gpt-5.6-sol/high` 审查阶段，不使用 ultra 模型。
任一阶段存在 P0/P1/P2 时不得关闭设计集合或授权实现。

## 9. 文件职责

### 9.1 专项正文

`Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md`
保留完整交互内容，同时修正项目身份、权威状态、缺失来源、冲突裁决、正交状态分类
和 Schema 边界。它是唯一专项正文，不再创建平行 addendum 或第二份同主题基线。

### 9.2 现有权威投影

- `docs/engineering/cognitura-design-index.md`：登记候选/正式状态和 Gate；
- `docs/contracts/cognitura-page-contracts.md`：投影页面职责、默认侧栏和交互边界；
- `docs/contracts/cognitura-renderer-contract.md`：投影视觉预算与 Renderer 非事实边界；
- `cognitive-knowledge-atlas-overall-design-1.2.md`：只追加可追溯的反向迁移记录，并
  对 ModuleReading/Page/Renderer 合同作最小协调；不重写现有产品权威，不改历史
  版本号；
- `README.md`、`AGENTS.md`：仅同步当前设计阶段、准入和授权边界。

### 9.3 新增治理资产

- `docs/engineering/cognitura-high-fidelity-design-manifest.yaml`；
- `docs/engineering/cognitura-high-fidelity-contract-coverage.md`；
- `scripts/verify-high-fidelity-design-manifest`；
- `tests/contracts/interaction-state/verify-high-fidelity-design-manifest.sh`；
- `scripts/verify-high-fidelity-contract-coverage`；
- `tests/contracts/interaction-state/verify-high-fidelity-contract-coverage.sh`；
- `docs/task-cards/high-fidelity-design/README.md`；
- `docs/task-cards/high-fidelity-design/HF-D00..HF-D04`；
- `tests/task-cards/verify-high-fidelity-design-cards.sh`；
- `scripts/verify-high-fidelity-design`；
- 必要的合成负例 fixture；
- `docs/engineering/cognitura-high-fidelity-design-plan.md`；
- `docs/engineering/cognitura-high-fidelity-design-acceptance.md`。

专项正文是独立 HF design manifest 的哈希输入。`HF-D00` 至 `HF-D04` 中任何修改
专项正文的卡，都必须在同一张卡、同一本地提交内重新计算并更新 manifest 的精确
字节数与 SHA-256，将 manifest、`scripts/verify-high-fidelity-design-manifest` 和
`tests/contracts/interaction-state/verify-high-fidelity-design-manifest.sh` 纳入该卡
Files、验证与暂存清单，并在提交前运行独立 HF manifest 验证。不得把 Wave 0
source manifest 用作该同步目标。

`HF-D04` 只有在同一封口写集中完成以下三项后才能把专项提升为
`FORMAL_SPECIALTY_BASELINE`：专项正文写入正式状态和 reviewed candidate SHA；
独立 HF design manifest 同步正式状态、精确字节数、SHA-256 和 reviewed candidate
SHA；独立 HF contract coverage 从 deferred 更新为已审查覆盖状态并记录相同 SHA。
封口必须分别运行 HF design manifest 与 HF contract coverage 两套独立验证器及其
测试；任一失败都禁止晋级。

Wave 0 source manifest 的四个既有来源身份、数量、`sourceId`、`caseId`、路径、
角色、版本及顺序固定，source validator 的 fail-closed 语义也固定。只有同一已登记
正式权威在获准写集内发生变更时，才必须在同一提交原子刷新该来源的 `sizeBytes`
和 `sha256`；这不是新增来源或改变来源语义。HF 候选永不登记到 Wave 0 source
manifest，继续只由独立 HF design manifest 管理。

以下 Wave 0 专项合同资产与两套 Wave 0 validators/tests 是已通过 Gate 的固定历史
合同，保持不变并位于全部 HF/HV 写集之外：

```text
docs/engineering/cognitura-specialty-contract-coverage.md
scripts/verify-source-manifest
tests/source-manifest/verify-source-manifest.sh
scripts/verify-specialty-contract-coverage
tests/contracts/specialty-coverage/verify-specialty-contract-coverage.sh
```

source manifest 仅可按上述原子指纹刷新规则进入获准写集；specialty coverage 与
两套 validators/tests 只能作为未变更的 Wave 0 回归检查运行，不承担 HF 来源登记、
合同覆盖或 Gate 投影职责。

## 10. 验证合同

统一设计验证必须证明：

- 专项正文存在且独立 HF design manifest 中的路径、版本、字节数、SHA-256 一致；
- 每个修改专项正文的 HF 卡都在同一提交中刷新 HF manifest，并运行 manifest
  wrapper 与对应测试；
- 独立 HF contract coverage 完整覆盖本专项合同，且不改写 Wave 0 来源或专项覆盖；
- HF-D04 晋级时专项正文、HF manifest 和 HF contract coverage 记录同一 reviewed
  candidate SHA，且两套独立 HF 验证器均通过；
- CanonicalProjectName 和四层正式名称正确；
- 缺失专项不得显示为已核验权威；
- 46 个原状态代码恰好一次分类；
- 20 类异常和 20 项 RF-AC 无遗漏、无重复；
- 临时状态不进入 URL，事件不成为稳定状态；
- PageState 12 值未被静默修改；
- Renderer 仍只投影 CognitiveModule；
- 候选、Overall、页面与 Renderer 对默认侧栏、按需 SourceEvidence、层级定位、
  主要动作与视觉预算以及 Renderer 不造事实的投影完全一致；
- 默认 ModuleReading 不存在永久治理右栏，同时保留 SourceEvidence 能力；
- 20 个异常的 Canonical 保存边界、重试、Revert 和焦点恢复均明确；
- 合同 PASS、视觉 PASS、可用性 PASS、实现 PASS 不互相冒充；
- 当前 Wave 1 implementation worktree、业务源码、migration、`raw/` 和 `.idea/`
  均不在写集。
- Wave 0 source manifest 与 specialty coverage 及其脚本/测试保持逐字节不变，只作为
  回归检查；HF/HV 登记和覆盖仅写入独立 HF 治理资产。

## 11. 完成边界

本设计整合集合完成只代表：

```text
HighFidelityInteractionDesign = USER_APPROVED_AND_FIXED_REVIEWED
HighFidelityContractInput = COMPLETE
HighFidelityVisualDesign = NOT_RUN
HighFidelityUsabilityValidation = NOT_RUN
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

下一阶段只能建立 `ModuleDefaultReadingState` 高保真设计任务卡。真实高保真视觉与
可用性验收通过后，才能编制 Wave 3+ 的 Schema、后端、前端实现切片；不得把这些
工作并入当前 Wave 1 来源接入卡。
