# Cognitura Wave 0 开发准入裁决

```text
DecisionDate = 2026-07-28
CurrentStage =
  WAVE0_EXECUTION

Wave0ExecutionEntry = GO_WITH_GATES
Wave0ExecutionStatus = IN_PROGRESS
Wave1FeatureDevelopmentEntry = NO_GO
DirectFullImplementationStart = NO
```

## 1. 裁决

Cognitura 可以进入 Wave 0 执行。

这里的 `GO_WITH_GATES` 只授权按 `cognitura-wave-0-plan.md` 建立工程基线，不代表业务功能开发已经准入。Wave 1、完整业务实现、正式数据库写入和产品发布均保持 `NO_GO`。

## 2. GO 依据

- 总体设计 1.2 已落地，状态为 `FORMAL_BASELINE`。
- 总体设计 Reverse Migration 为 `26/26 PASS`。
- `RemainingDesignP0 = 0`，`RemainingUIP0 = 0`。
- 四层认知结构、Primary Cognitive Spine、Closure、两阶段生成、用户修订、页面、Desktop Web、模块化单体和实施波次均已在正文出现。
- 三份 Golden Case 原件已落地、可读取、互不重复且哈希已记录。
- 当前没有遗留业务代码，不存在需要先拆除的冲突实现。

## 3. Gate 条件

| Gate | 当前状态 | Wave 0 退出要求 |
|---|---|---|
| `W0-G0 RepositoryBaseline` | `PASS` | `main`、原件哈希匹配、Repository 基线内容提交 `2047a80` |
| `W0-G1 DesignSourceRegistry` | `PARTIAL` | 机器可读 manifest 与哈希验证 |
| `W0-G2 SpecialtyContractCoverage` | `PARTIAL` | 回迁覆盖矩阵与字段级缺口唯一处置 |
| `W0-G2A BuildBaseline` | `NOT_STARTED` | Java/React 最小构建骨架与版本锁 |
| `W0-G3 JsonSchemaValidation` | `BLOCKED_BY_DOC_GAP_001` | 权威字段来源和 Schema 正反例 |
| `W0-G4 GoldenCaseRegression` | `PARTIAL` | 机器可执行断言与离线回归 |
| `W0-G4A UiContractValidation` | `PARTIAL` | 页面/Renderer 契约验证 |
| `W0-G5 TestAndCI` | `NOT_STARTED` | 本地和 CI 全绿 |
| `W0-G6 FixedCommitReview` | `NOT_STARTED` | 固定提交深度审查无 P0/P1/P2 |

## 4. 当前阻断边界

`DOC-GAP-001` 不阻断 Wave 0 开始，但阻断 `W0-G3 JsonSchemaValidation` 完成。允许先执行 Repository、来源清单、覆盖矩阵、技术骨架、Golden Case 和 UI 契约任务；字段级 Schema 必须等待权威专项正文落地，或等待一个明确批准的 Schema 重基线设计。

不得把总体设计中的字段摘要扩写成声称来自历史专项的完整 Schema。

## 5. 技术选择状态

```text
ArchitectureAndPlatformDecision = FINAL
TechnologyStackDirection = DESIGN_RECOMMENDATION
TechnologyBaselineDecision = PENDING_W0_03
```

已经封口的是模块化单体、Desktop Web、Java 21 方向、Spring Boot、PostgreSQL/JSONB、对象存储、React + TypeScript、LLM Provider Adapter 和 JSON Schema。

尚未封口的是 Spring Boot 精确版本、Maven 或 Gradle、前端应用框架与构建工具、Node/包管理器版本、PostgreSQL 主版本、数据库迁移工具、对象存储实现、测试工具链、CI Provider 和本地开发/容器策略。不得在 `W0-G2A BuildBaseline` 通过前把这些选择描述为正式技术基线。

## 6. 下一动作

```text
NextAction = W0-01 DesignSourceRegistry
StopAfterThisRound = YES
```

本轮已完成 `W0-00 RepositoryBaseline`，并停在状态记录后的干净提交检查点；不创建 server/web/test-data 业务骨架，不执行 Wave 1。
