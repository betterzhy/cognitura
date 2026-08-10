# Cognitura

Cognitura 是一个面向个人阅读与知识学习的 AI 认知结构生成系统。它从一份或多份文档生成稳定的四层认知结构：

```text
KnowledgeLandscape
→ KnowledgeTheme
→ CognitiveModule
→ KnowledgeElement
```

项目不以个人知识库、文档管理、普通 RAG 问答、自由知识图谱或学习计划为产品目标。

## 当前阶段

```text
CurrentStage = HIGH_FIDELITY_VISUAL_AND_USABILITY_COMPLETE

Wave0ExecutionStatus = COMPLETE
ActiveTaskCard = NONE
ActiveTaskCardStatus = NONE
W0G3ReviewStatus = PASS
W0G4ReviewStatus = PASS
W0G5Status = PASS
W0G5LocalVerification = PASS
W0G5FixedCommitCI = PASS
W0G5CIURL = https://github.com/betterzhy/cognitura/actions/runs/30454379223
W0G6ReviewStatus = PASS
W0G6ReviewedCommit = 08ddc00907a6ead84a526c71a2c0802f363fe614
W0G6CIURL = https://github.com/betterzhy/cognitura/actions/runs/30495773273
Wave1FeatureDevelopmentEntry = GO
Wave1DesignStatus = USER_APPROVED
Wave1ImplementationPlanningStatus = TASK_CARD_CREATION_PLAN_READY
Wave1ImplementationTaskCardSet = NOT_CREATED
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
HighFidelityVisualTaskCardSet = COMPLETE
HighFidelityVisualProjectedEntry = NONE
ActiveDesignTaskCard = NONE
W1-I00Creation = FORBIDDEN
W1-I00Release = FORBIDDEN
BusinessImplementation = NOT_AUTHORIZED
DirectFullImplementationStart = NO
```

当前 Repository 已在 `main` 建立 Git 基线，已落地总体设计 1.2 和 MySQL、Redis、
英语学习三份 Golden Case 原始文档；已有 Wave 0 来源、契约校验测试、不含业务
功能的模块化单体构建骨架，以及已通过固定提交深审的 W0-04 Schema 基线，
尚无业务源码。W0-07 已形成 GitHub Actions workflow、测试策略和本地统一入口；
本地七阶段验证以及固定提交
`a332092ee1298c795d13de4af1fcab2e908aed9f` 的 GitHub Actions
[run #1](https://github.com/betterzhy/cognitura/actions/runs/30454379223)
均已通过，`W0-G5 = PASS`。W0-08 的固定候选
`08ddc00907a6ead84a526c71a2c0802f363fe614` 已通过一般审查和独立最终门禁，
两阶段均为 `P0=0/P1=0/P2=0`，因此 `W0-G6 = PASS`，Wave 0 已关闭。

Wave 1 详细设计复审修复候选
`17dabff23b029e1a6fc7f47155f552ed3f16d775` 已通过两个相互独立的
`gpt-5.6-sol/high` 阶段，均为 `P0=0/P1=0/P2=0`，因此 `W1-DG5 = PASS`。
用户已批准完整书面设计和 14 张中细粒度实现切片书面规格；任务卡 bootstrap
计划已落盘，当前等待选择执行方式。该计划只创建实现卡集并完成治理卡 I00，
仍不创建解析器、页面、数据库对象、LLM 调用或其他业务实现。

`W0-G1 DesignSourceRegistry = PASS`：四份正式输入已登记到机器可读 manifest，
并通过路径、角色、版本、字节数与 SHA-256 的正反例验证。

`W0-G2 SpecialtyContractCoverage = PASS`：总体设计中的非 Schema 构造与 UI
契约已建立机器可验证的覆盖矩阵。`DOC-GAP-001` 已取得正式 Schema 重基线
处置；W0-04 已通过本地 Gate 与固定提交深审，`W0-G3 = PASS`。
`DOC-GAP-002` 继续保持开放。

`W0-G2A BuildBaseline = PASS`：后端固定为 JDK 21、Maven 3.9.16、
Spring Boot 4.1.0、PostgreSQL 18 和 MyBatis Spring Boot Starter 4.0.0；
前端固定为 Node 24.18.0、pnpm 11.17.0、React 19.2.8、TypeScript 7.0.2
和 Vite 8.1.5。单部署 server、空 Desktop Web 入口、模块边界和 lockfile
已经通过在线及缓存离线构建验证。

`W0-G4A UiContractValidation = PASS`：12 个正式页面、Skeleton Review 三栏与
六类操作、9 个 Renderer、12 个页面状态和 Desktop Web 边界已形成可验证的
非 Schema 契约；两项历史专项正文缺失事实仍保持登记。

`W0-G4 GoldenCaseRegression = PASS`：三份原件及结果契约夹具、24 组结果断言、
结构与分页位置指纹、Redis 外链目标指纹和 JDK 21 I/O Guard 已通过 22 个隔离
负例；固定候选 `608a98c` 深审为 `GO / P0=0 / P1=0 / P2=0`。

## 正式输入

- [总体设计 1.2](cognitive-knowledge-atlas-overall-design-1.2.md)：历史文件名保留，工程引用名为 `Cognitura-Overall-Design-1.2`。
- [Schema Baseline 2.0](docs/design/cognitura-schema-baseline-2.0.md)：经批准并按固定审查结果升级的字段级工程重基线，不冒充历史专项正文。
- [MySQL Golden Case](raw/11-MySQL数据库.docx)
- [Redis Golden Case](raw/12-Redis中间件.docx)
- [英语学习 Golden Case](raw/40-英语学习.docx)

## 工程文档

- [Repository 基线复验](docs/engineering/cognitura-repository-baseline-review.md)
- [设计与输入索引](docs/engineering/cognitura-design-index.md)
- [正式来源 Manifest](docs/engineering/cognitura-source-manifest.yaml)
- [专项契约覆盖矩阵](docs/engineering/cognitura-specialty-contract-coverage.md)
- [命名迁移记录](docs/engineering/cognitura-naming-migration.md)
- [全栈技术基线](docs/engineering/cognitura-technology-baseline.md)
- [模块边界基线](docs/engineering/cognitura-module-boundaries.md)
- [页面契约](docs/contracts/cognitura-page-contracts.md)
- [Renderer 契约](docs/contracts/cognitura-renderer-contract.md)
- [测试与 CI 策略](docs/engineering/cognitura-test-strategy.md)
- [Wave 0 实施计划](docs/engineering/cognitura-wave-0-plan.md)
- [Wave 0 任务卡索引](docs/task-cards/README.md)
- [Wave 0 开发准入裁决](docs/engineering/cognitura-wave-0-entry-decision.md)
- [Wave 1 准入裁决](docs/engineering/cognitura-wave-1-entry-decision.md)
- [Wave 1 详细设计计划](docs/engineering/cognitura-wave-1-design-plan.md)
- [Wave 1 详细设计验收](docs/engineering/cognitura-wave-1-design-acceptance.md)
- [Wave 1 设计任务卡索引](docs/task-cards/wave-1/README.md)
- [Wave 1 设计治理说明](docs/superpowers/specs/2026-07-30-wave1-source-ingestion-governance-design.md)
- [Wave 1 实现切片设计](docs/superpowers/specs/2026-07-30-wave1-implementation-slicing-design.md)
- [Wave 1 实现任务卡 bootstrap 计划](docs/superpowers/plans/2026-07-30-wave1-implementation-task-card-bootstrap.md)
- [高保真交互设计整合规格](docs/superpowers/specs/2026-08-06-high-fidelity-interaction-design-integration.md)
- [高保真设计任务卡索引](docs/task-cards/high-fidelity-design/README.md)
- [高保真专项独立 Manifest](docs/engineering/cognitura-high-fidelity-design-manifest.yaml)
- [高保真专项合同覆盖](docs/engineering/cognitura-high-fidelity-contract-coverage.md)
- [高保真证据执行计划](docs/engineering/cognitura-high-fidelity-design-plan.md)
- [高保真证据验收台账](docs/engineering/cognitura-high-fidelity-design-acceptance.md)
- [高保真视觉设计基础](docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md)
- [高保真视觉任务卡索引](docs/task-cards/high-fidelity-visual/README.md)

当前分支的独立 `HIGH_FIDELITY_DESIGN` 卡集已经全部关闭；`HF-D01` 已通过页面与
呈现合同 Gate，`HF-D02` 已通过正交状态与恢复 Gate，`HF-D03` 已通过证据输入合同
Gate，`HF-D04` 已对准备提交
`463fd4829e7c4bb8da071253e8ae9b15cee2a0cf` 完成两个独立
`gpt-5.6-sol/high` 审查，均为 `GO / P0=0 / P1=0 / P2=0`。
新增交互状态正文现为 `FORMAL_SPECIALTY_BASELINE`；正文原有 46 个状态、
20 个异常、20 项 RF-AC 和 30 项反向迁移已登记；46 个原始状态已恰好一次分类到
六轴、临时 UI、流程、事件或派生结果，五级持久化与恢复边界已通过 `HF-DG2`。
八类 Canonical 证据路径、20 项 RF-AC、20 异常、30 RM、机制域/规则政策域场景和
六项 HV 序列的合同已通过 `HF-DG4`；`HV-D00` 已完成视觉 token、静态 docs-only
fixture 治理与 1440×1100 基础截图，`HV-D01` 已完成机制型 Module 默认阅读 DOM
和视觉证据；`HV-D02` 已完成 Relation 主聚焦与完整来源核验的两张桌面证据，仅推进
`RF-AC-03,07,09,16`；`HV-D03` 已完成修订影响、部分失败恢复和冲突草稿三张桌面
证据，仅推进 `RF-AC-13,14,17,18` 的视觉结果；`HV-D04` 已完成跨层、跨域、小屏与
静态导出证据，仅推进 `RF-AC-01,10,15,19`。`HV-D05` 已对固定候选
`62da1bc08a932bbfc76769a2add984dcec4160b7` 完成两个独立
`gpt-5.6-sol/high` 零发现审查；整体视觉设计与可用性为 `PASS`，实现仍为 `NOT_RUN`。
本轮不创建或释放 `W1-I00`，也不授权
业务实现、正式数据库写入或远程推送。

## 当前准入

```text
Wave0ExecutionEntry = GO_WITH_GATES
Wave0ExecutionStatus = COMPLETE
Wave1FeatureDevelopmentEntry = GO
Wave1DesignStatus = USER_APPROVED
Wave1ImplementationPlanningStatus = TASK_CARD_CREATION_PLAN_READY
DirectFullImplementationStart = NO
```

`W0-G0 RepositoryBaseline = PASS`，`W0-G1 DesignSourceRegistry = PASS`，
`W0-G2 SpecialtyContractCoverage = PASS`，`W0-G2A BuildBaseline = PASS`，
`W0-G4A UiContractValidation = PASS`。`Cognitura-Schema-Baseline-2.0`
已经获得批准并落地；14 份 Schema、34 个语义
反例、68 个运行时语义错误码、645 个精确 Schema 证据节点、16 个语义不变量
证据及其篡改反例已经通过，固定候选 `72b5ce7` 深审为
`GO / P0=0 / P1=0 / P2=0`，因此 `W0-G3 JsonSchemaValidation = PASS`。
W0-05 已关闭且 `W0-G4 = PASS`；W0-07 的本地统一入口已执行 source、
task-card、Schema、Golden Case、UI、server、web 七阶段并通过，固定提交
`a332092ee1298c795d13de4af1fcab2e908aed9f` 的 CI 也已成功并记录可追溯 URL，
因此 `W0-G5 = PASS`。W0-08 最终固定候选
`08ddc00907a6ead84a526c71a2c0802f363fe614` 的
[CI run #4](https://github.com/betterzhy/cognitura/actions/runs/30495773273)
成功，一般审查与最终门禁均清零并裁决 GO，故
`W0-G6 FixedCommitReview = PASS`、`Wave1FeatureDevelopmentEntry = GO`。
该 GO 仅开放后续受控任务卡，不授权直接实现 Wave 1。
Wave 1 书面详细设计和 14 张中细粒度实现切片规格均已获用户批准，任务卡
bootstrap 计划已准备完成；其执行仍不授权 W1-I01 业务实现。
