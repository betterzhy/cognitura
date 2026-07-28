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
| `W0-G1 DesignSourceRegistry` | `PASS` | manifest 的 4 项正例与 5 项反例通过，正式输入保持不变 |
| `W0-G2 SpecialtyContractCoverage` | `PASS` | 26 项迁移、19 项契约、2 个开放缺口和 1 个证据限制通过验证 |
| `W0-G2A BuildBaseline` | `PASS` | 精确全栈版本、单部署 server、空 web 入口、模块边界与在线/离线构建验证通过 |
| `W0-G3 JsonSchemaValidation` | `PASS` | 14 份 Schema、2 个合法空值上下文、34 个语义反例、68 个运行时语义错误码、645 条精确 Schema 证据映射、16 条语义不变量证据、6 个映射篡改反例和全量渲染 round-trip 通过；固定候选 `72b5ce7` 深审 GO |
| `W0-G4 GoldenCaseRegression` | `IN_REVIEW` | 3 个原件正例、3 个结果契约正例、22 个隔离负例、24 组结果断言、结构/分页/外链目标指纹与 I/O Guard 本地通过；候选 `a613db3`、`1edca85` 深审问题均已整改，等待新候选深审 |
| `W0-G4A UiContractValidation` | `PASS` | 12 页面、6 结构操作、9 Renderer、12 页面状态与 9 个负例通过 |
| `W0-G5 TestAndCI` | `NOT_STARTED` | 本地和 CI 全绿 |
| `W0-G6 FixedCommitReview` | `NOT_STARTED` | 固定提交深度审查无 P0/P1/P2 |

## 4. 当前阻断边界

`DOC-GAP-001` 的历史专项正文缺失事实继续登记，但经用户明确批准的
`Cognitura-Schema-Baseline-2.0` 已作为正式字段级工程来源落地，W0-04 的执行
阻断已经解除。Schema、证据映射和正反例已通过本地验证，固定候选 `72b5ce7`
深审为 `GO / P0=0 / P1=0 / P2=0`；当前
`W0-G3 JsonSchemaValidation = PASS`，W0-05 已解除依赖阻断。

不得把该重基线声称为历史专项正文，也不得在 W0-04 实施中继续补写未裁决语义。

## 5. 技术选择状态

```text
ArchitectureAndPlatformDecision = FINAL
TechnologyStackDirection = APPROVED
TechnologyBaselineDecision = FORMAL
BackendTechnologyBaseline = FORMAL
FrontendTechnologyBaseline = FORMAL
```

已经封口的是模块化单体、Desktop Web，以及
`docs/engineering/cognitura-technology-baseline.md` 记录的 JDK 21、
Maven 3.9.16、Spring Boot 4.1.0、Spring Modulith 2.1.0、PostgreSQL 18、
MyBatis Starter 4.0.0、Flyway、Spring AI 2.0.0、Node 24.18.0、
pnpm 11.17.0、React 19.2.8、TypeScript 7.0.2 和 Vite 8.1.5。

对象存储实现、CI Provider 和部署策略尚未封口；它们不属于 `W0-03`。
PostgreSQL 18.4 容器 tag/digest、Spring Boot BOM 实际解析版本、后端健康检查、
模块边界和前端冻结 lockfile 已验证，因此 `W0-G2A BuildBaseline = PASS`。

## 6. 任务卡状态

```text
TaskCardBreakdown = COMPLETE
TaskCardCount = 9
ActiveTaskCard = W0-05
ActiveTaskCardStatus = READY
TaskCardIndex = docs/task-cards/README.md
```

每张任务卡都固定前置依赖、写集、失败验证、Gate、提交和审查方式。W0-04
已经关闭；W0-05 的本地回归已通过并进入固定候选复核，但在深审封口前仍是唯一
`READY` 卡；W0-07 及其后继仍受依赖阻断。

## 7. 下一动作

```text
NextAction = REVIEW_W0_05_FIXED_CANDIDATE
W0-01 ExecutionStatus = DONE
W0-G1 DesignSourceRegistry = PASS
W0-02 ExecutionStatus = DONE
W0-G2 SpecialtyContractCoverage = PASS
W0-03 ExecutionStatus = DONE
W0-G2A BuildBaseline = PASS
SchemaRebaseline = Cognitura-Schema-Baseline-2.0
SchemaRebaselineStatus = FORMAL_SCHEMA_REBASELINE
W0-04 ExecutionStatus = DONE
W0-G3 JsonSchemaValidation = PASS
W0-05 ExecutionStatus = IN_REVIEW
W0-06 ExecutionStatus = DONE
W0-G4A UiContractValidation = PASS
```

下一步只允许固定 W0-05 候选并完成深审；三份只读 Golden Case 原件继续保持不变。
`DOC-GAP-002` 继续保持开放，但不回滚已经验证的非 Schema UI 契约；
Wave 1 仍为 `NO_GO`。
