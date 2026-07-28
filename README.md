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
CurrentStage =
  WAVE0_EXECUTION

Wave0ExecutionStatus = IN_PROGRESS
ActiveTaskCard = W0-04
ActiveTaskCardStatus = READY
W0G3ReviewStatus = IN_REVIEW
```

当前 Repository 已在 `main` 建立 Git 基线，已落地总体设计 1.2 和 MySQL、Redis、
英语学习三份 Golden Case 原始文档；已有 Wave 0 来源、契约校验测试、不含业务
功能的模块化单体构建骨架，以及 W0-04 Schema 修复候选，尚无业务源码或 CI。

`W0-G1 DesignSourceRegistry = PASS`：四份正式输入已登记到机器可读 manifest，
并通过路径、角色、版本、字节数与 SHA-256 的正反例验证。

`W0-G2 SpecialtyContractCoverage = PASS`：总体设计中的非 Schema 构造与 UI
契约已建立机器可验证的覆盖矩阵。`DOC-GAP-001` 已取得正式 Schema 重基线
处置；W0-04 修复候选的本地验证已经通过，正在等待固定提交深审封口。
`DOC-GAP-002` 继续保持开放。

`W0-G2A BuildBaseline = PASS`：后端固定为 JDK 21、Maven 3.9.16、
Spring Boot 4.1.0、PostgreSQL 18 和 MyBatis Spring Boot Starter 4.0.0；
前端固定为 Node 24.18.0、pnpm 11.17.0、React 19.2.8、TypeScript 7.0.2
和 Vite 8.1.5。单部署 server、空 Desktop Web 入口、模块边界和 lockfile
已经通过在线及缓存离线构建验证。

`W0-G4A UiContractValidation = PASS`：12 个正式页面、Skeleton Review 三栏与
六类操作、9 个 Renderer、12 个页面状态和 Desktop Web 边界已形成可验证的
非 Schema 契约；两项历史专项正文缺失事实仍保持登记。

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
- [Wave 0 实施计划](docs/engineering/cognitura-wave-0-plan.md)
- [Wave 0 任务卡索引](docs/task-cards/README.md)
- [Wave 0 开发准入裁决](docs/engineering/cognitura-wave-0-entry-decision.md)

## 当前准入

```text
Wave0ExecutionEntry = GO_WITH_GATES
Wave0ExecutionStatus = IN_PROGRESS
Wave1FeatureDevelopmentEntry = NO_GO
DirectFullImplementationStart = NO
```

`W0-G0 RepositoryBaseline = PASS`，`W0-G1 DesignSourceRegistry = PASS`，
`W0-G2 SpecialtyContractCoverage = PASS`，`W0-G2A BuildBaseline = PASS`，
`W0-G4A UiContractValidation = PASS`。`Cognitura-Schema-Baseline-2.0`
已经获得批准并落地，`W0-04` 现为唯一 `READY` 卡；14 份 Schema、32 个语义
反例、617 个精确证据节点及其篡改反例已经在修复候选中通过，本轮
`W0-G3 JsonSchemaValidation = IN_REVIEW`。只有固定提交深审为 GO 后才允许
标记 `PASS` 并释放 W0-05；在其余 Wave 0 门禁全部通过前，不进入 Wave 1
业务功能开发。
