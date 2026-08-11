# Cognitura Wave 1 设计任务卡索引

```text
CanonicalProjectName = Cognitura
TaskCardSet = WAVE1_DESIGN
TaskCardIDs = W1-D00,W1-D01,W1-D02,W1-D03,W1-D04,W1-D05
TaskCardCount = 6
ActiveTaskCard = NONE
TaskCardSetStatus = COMPLETE
Wave1DesignStatus = USER_APPROVED
Wave1ImplementationPlanningStatus = TASK_CARD_SET_BOOTSTRAPPED
Wave1ImplementationTaskCardSet = READY_FOR_EXECUTION
ActiveImplementationGovernanceTaskCard = W1-I03
BusinessImplementation = USER_AUTHORIZED
```

本集合只完成 Wave 1 书面详细设计、设计验证和固定候选复核。复审修复候选已
通过两个独立 `gpt-5.6-sol/high` 阶段，六张设计卡均已完成且完整设计已获用户
批准，实现切片书面规格也已获用户批准。14 张实现卡已 bootstrap，非业务治理卡
I00 和 I01 已关闭；I02 等待独立数据库 Gate，W1-I03 为唯一 `READY` 业务卡。

## 1. 任务卡清单

| ID | 任务卡 | 状态 | 依赖 | Gate | 风险 |
|---|---|---|---|---|---|
| `W1-D00` | [设计治理](W1-D00-design-governance.md) | `DONE` | `NONE` | `W1-DG0` | `HIGH` |
| `W1-D01` | [SourceDocument 契约](W1-D01-source-document-contract.md) | `DONE` | `W1-D00` | `W1-DG1` | `HIGH` |
| `W1-D02` | [DocumentBlock 契约](W1-D02-document-block-contract.md) | `DONE` | `W1-D01` | `W1-DG2` | `HIGH` |
| `W1-D03` | [重解析与稳定引用](W1-D03-reparse-reference-contract.md) | `DONE` | `W1-D02` | `W1-DG3` | `HIGH` |
| `W1-D04` | [来源预览与验收](W1-D04-source-preview-acceptance.md) | `DONE` | `W1-D03` | `W1-DG4` | `HIGH` |
| `W1-D05` | [固定设计候选复核](W1-D05-fixed-design-review.md) | `DONE` | `W1-D04` | `W1-DG5` | `HIGH` |

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

- `READY_FOR_EXECUTION` 时恰有一张 `READY` 卡。
- `BLOCKED_BY_DOCUMENTATION_GAP` 时没有 `READY` 卡且
  `ActiveTaskCard = NONE`。
- `COMPLETE` 时六张设计卡均为 `DONE`，且 `ActiveTaskCard = NONE`。
- 实际写入期间卡片保持 `READY`；只有 Gate 和本地提交均完成后才能标记
  `DONE`。

## 3. 执行规则

1. 只执行唯一 `READY` 设计卡的精确写集。
2. 先观察失败验证，再完成最小设计与验证变更。
3. 每张卡必须通过 `gpt-5.6-sol/high` Gate；不使用 ultra 模型。
4. W1-D05 使用两个相互独立的 `gpt-5.6-sol/high` 审查阶段。
5. 不修改业务源码、数据库 migration、部署配置或 `raw/` 原件。
6. 不访问 Redis 原件中的遗留本地链接目标。
7. 每张卡形成独立本地提交；未获新授权时不推送。

## 4. 集合验证

```bash
bash tests/task-cards/verify-wave1-design-cards.sh
scripts/verify-wave1-design-cards --cards-dir docs/task-cards/wave-1
```

当前预期：

```text
ExpectedWave1DesignTaskCardContractTests = PASS
ExpectedWave1DesignTaskCardValidation = PASS
ExpectedTaskCardCount = 6
ExpectedTaskCardSetStatus = COMPLETE
ExpectedActiveTaskCard = NONE
```
