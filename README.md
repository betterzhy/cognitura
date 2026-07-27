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
```

当前 Repository 已在 `main` 建立 Git 基线，已落地总体设计 1.2 和 MySQL、Redis、英语学习三份 Golden Case 原始文档；尚无业务源码、构建系统、测试或 CI。

后端技术基线已经封口为 JDK 21、Maven 3.9.16、Spring Boot 4.1.0、
PostgreSQL 18 和 MyBatis Spring Boot Starter 4.0.0。构建骨架尚未创建，
`W0-G2A BuildBaseline` 仍为 `IN_PROGRESS`。

## 正式输入

- [总体设计 1.2](cognitive-knowledge-atlas-overall-design-1.2.md)：历史文件名保留，工程引用名为 `Cognitura-Overall-Design-1.2`。
- [MySQL Golden Case](raw/11-MySQL数据库.docx)
- [Redis Golden Case](raw/12-Redis中间件.docx)
- [英语学习 Golden Case](raw/40-英语学习.docx)

## 工程文档

- [Repository 基线复验](docs/engineering/cognitura-repository-baseline-review.md)
- [设计与输入索引](docs/engineering/cognitura-design-index.md)
- [命名迁移记录](docs/engineering/cognitura-naming-migration.md)
- [后端技术基线](docs/engineering/cognitura-technology-baseline.md)
- [Wave 0 实施计划](docs/engineering/cognitura-wave-0-plan.md)
- [Wave 0 开发准入裁决](docs/engineering/cognitura-wave-0-entry-decision.md)

## 当前准入

```text
Wave0ExecutionEntry = GO_WITH_GATES
Wave0ExecutionStatus = IN_PROGRESS
Wave1FeatureDevelopmentEntry = NO_GO
DirectFullImplementationStart = NO
```

`W0-G0 RepositoryBaseline = PASS`。下一步执行 `W0-01 DesignSourceRegistry`；在其余 Wave 0 门禁全部通过前，不进入 Wave 1 业务功能开发。
