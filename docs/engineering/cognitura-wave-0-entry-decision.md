# Cognitura Wave 0 开发准入裁决

```text
DecisionDate = 2026-07-27
CurrentStage =
  EXISTING_REPOSITORY_BASELINE_REVIEW_AND_WAVE0_PLANNING

Wave0ExecutionEntry = GO_WITH_GATES
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
| `W0-G0 RepositoryBaseline` | `NOT_STARTED` | Git、main、干净工作树、固定 HEAD |
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

## 5. 下一动作

```text
NextAction = W0-00 RepositoryBaseline
StopAfterThisRound = YES
```

本轮停在“基线复验、命名落地、工程索引、Wave 0 计划和准入裁决均已形成”的干净文档检查点；不在本轮初始化 Git，不创建 server/web/test-data 业务骨架，不执行 Wave 1。
