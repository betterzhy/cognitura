# Cognitura Wave 0 任务卡索引

```text
CanonicalProjectName = Cognitura
TaskCardSet = WAVE0
TaskCardCount = 9
ActiveTaskCard = W0-07
TaskCardSetStatus = READY_FOR_EXECUTION
Wave1FeatureDevelopmentEntry = NO_GO
```

本目录将
[`cognitura-wave-0-plan.md`](../engineering/cognitura-wave-0-plan.md)
拆成可独立执行、验证和提交的任务卡。任务卡只解释工程执行边界，不覆盖总体设计、
专项设计或 Gate 裁决。

## 1. 任务卡清单

| ID | 任务卡 | 状态 | 依赖 | Gate | 风险 |
|---|---|---|---|---|---|
| `W0-00` | [Repository 基线](W0-00-repository-baseline.md) | `DONE` | `NONE` | `W0-G0` | `LOW` |
| `W0-01` | [设计和输入来源登记](W0-01-design-source-registry.md) | `DONE` | `W0-00` | `W0-G1` | `MEDIUM` |
| `W0-02` | [专项契约覆盖封口](W0-02-specialty-contract-coverage.md) | `DONE` | `W0-01` | `W0-G2` | `HIGH` |
| `W0-03` | [技术栈与模块化单体骨架](W0-03-build-baseline.md) | `DONE` | `W0-02` | `W0-G2A` | `HIGH` |
| `W0-04` | [JSON Schema Source](W0-04-json-schema-source.md) | `DONE` | `W0-02,W0-03` | `W0-G3` | `HIGH` |
| `W0-05` | [Golden Case 回归资产](W0-05-golden-case-regression.md) | `DONE` | `W0-01,W0-04` | `W0-G4` | `HIGH` |
| `W0-06` | [页面与 Renderer 契约](W0-06-ui-renderer-contracts.md) | `DONE` | `W0-02` | `W0-G4A` | `MEDIUM` |
| `W0-07` | [测试与 CI 基线](W0-07-test-and-ci.md) | `READY` | `W0-03,W0-04,W0-05,W0-06` | `W0-G5` | `HIGH` |
| `W0-08` | [固定提交复核与 Wave 1 准入](W0-08-fixed-commit-review.md) | `BLOCKED_BY_DEPENDENCY` | `W0-07` | `W0-G6` | `HIGH` |

`W0-03`、`W0-04`、`W0-05` 与 `W0-06` 已完成，`W0-G2A`、`W0-G3`、
`W0-G4`、`W0-G4A` 均为 `PASS`。W0-05 固定候选 `608a98c` 深审为
`GO / P0=0 / P1=0 / P2=0`；W0-07 已解除全部依赖并成为唯一 `READY` 卡，
其本地七阶段统一验证和 CI 契约测试已经通过。由于 Repository 尚无 remote，
固定提交 CI 与可追溯 URL 仍缺失，`W0-G5` 保持 `IN_PROGRESS`，W0-08 继续受
依赖阻断。

## 2. 状态模型

```text
BLOCKED_BY_DEPENDENCY
  → QUEUED
  → READY
  → DONE

BLOCKED_BY_DOCUMENTATION_GAP
  → QUEUED
  → READY
  → DONE
```

- `READY`：所有前置依赖已经满足，是唯一允许开始执行的当前任务卡。
- `QUEUED`：前置依赖已经满足，但尚未被主 Agent 选为唯一当前任务卡。
- `DONE`：任务卡的全部验证通过、Gate 记录完成并已形成独立提交。
- `BLOCKED_BY_DEPENDENCY`：必须等待所列任务卡完成。
- `BLOCKED_BY_DOCUMENTATION_GAP`：除依赖外还有明确文档缺口，禁止猜测补齐。
- `TaskCardSetStatus = READY_FOR_EXECUTION` 时必须恰有一张卡为 `READY`；
  `TaskCardSetStatus = BLOCKED_BY_DOCUMENTATION_GAP` 时必须没有 `READY` 卡，
  且 `ActiveTaskCard = NONE`。
- 进入实际写入后在执行记录中标记 `IN_PROGRESS`，但 Repository 卡片状态直到
  Gate 封口前保持 `READY`。

## 3. 执行规则

1. 执行前读取 `AGENTS.md`、本索引、当前任务卡及卡片列出的正式输入。
2. 检查分支、HEAD、工作树和未提交修改；只处理任务卡写集。
3. 先完成卡片中的失败验证并观察预期失败，再实现最小变更。
4. 不得越过依赖，不得因局部验证通过提前标记 Gate。
5. 每张卡形成独立提交；提交前运行卡片验证、任务卡集合校验和
   `git diff --check`。
6. 完成当前卡后更新本索引、Wave 0 计划和准入记录，再释放下一张卡。
7. `W0-08` 必须按固定候选提交依次经过 `deep_reviewer` 和
   `ultra_gatekeeper`；其他卡默认由主 Agent 完成 Gate 验证。
8. 自驱循环遇到名义下一卡受真实 Gate 阻断时，可以选择另一张依赖已满足的卡，
   但必须保持唯一 `READY`，不得解除文档缺口或扩大写集。

## 4. 集合验证

```bash
bash tests/task-cards/verify-task-cards.sh
scripts/verify-task-cards --cards-dir docs/task-cards
```

验收结果必须同时包含：

```text
TaskCardContractTests = PASS
TaskCardValidation = PASS
ExpectedTaskCardCount = 9
ExpectedTaskCardSetStatus = READY_FOR_EXECUTION
ExpectedActiveTaskCard = W0-07
```
