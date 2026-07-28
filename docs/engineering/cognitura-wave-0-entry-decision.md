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
| `W0-G2A BuildBaseline` | `IN_PROGRESS` | 后端技术已封口；仍需前端版本、Java/React 最小构建骨架与版本锁 |
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
TechnologyStackDirection = APPROVED
TechnologyBaselineDecision = PARTIALLY_FORMALIZED
BackendTechnologyBaseline = FORMAL
FrontendTechnologyBaseline = PENDING_W0_03
```

已经封口的是模块化单体、Desktop Web，以及
`docs/engineering/cognitura-technology-baseline.md` 记录的 JDK 21、
Maven 3.9.16、Spring Boot 4.1.0、Spring Modulith 2.1.0、PostgreSQL 18、
MyBatis Starter 4.0.0、Flyway、Spring AI 2.0.0 和后端测试策略。

尚未封口的是 React/TypeScript/Node 精确版本、前端构建工具与包管理器、
对象存储实现、CI Provider、部署策略和精确容器 digest。后端构建骨架与依赖
解析尚未验证，因此 `W0-G2A BuildBaseline` 仍为 `IN_PROGRESS`，不得描述为
已经通过。

## 6. 任务卡状态

```text
TaskCardBreakdown = COMPLETE
TaskCardCount = 9
ActiveTaskCard = W0-01
ActiveTaskCardStatus = READY
TaskCardIndex = docs/task-cards/README.md
```

每张任务卡都固定前置依赖、写集、失败验证、Gate、提交和审查方式。只有唯一
`READY` 卡可以开始实施。

## 7. 下一动作

```text
NextAction = EXECUTE_W0_01_DESIGN_SOURCE_REGISTRY
W0-01 ExecutionStatus = NOT_STARTED
```

任务卡拆分不等同于执行 `W0-01`。下一轮应只处理该卡写集，不创建 server/web
业务骨架，不执行 Wave 1。
