# Cognitura 高保真设计任务卡索引

```text
CanonicalProjectName = Cognitura
TaskCardSet = HIGH_FIDELITY_DESIGN
TaskCardIDs = HF-D00,HF-D01,HF-D02,HF-D03,HF-D04
TaskCardCount = 5
ActiveTaskCard = HF-D01
TaskCardSetStatus = READY_FOR_EXECUTION
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
W1-I00Creation = FORBIDDEN
W1-I00Release = FORBIDDEN
```

本集合只治理交互状态专项与高保真验收输入，不重开已完成的 Wave 1 设计卡，
也不创建或释放 `W1-I00`。任何 HF Gate 都不构成业务实现授权。

## 1. 任务卡清单

| ID | 单一职责 | 状态 | 依赖 | Gate |
|---|---|---|---|---|
| `HF-D00` | [设计治理与来源登记](HF-D00-design-governance.md) | `DONE` | `NONE` | `HF-DG0 PASS` |
| `HF-D01` | [页面与呈现冲突裁决](HF-D01-reading-presentation-contract.md) | `READY` | `HF-D00` | `HF-DG1` |
| `HF-D02` | [正交状态与恢复边界](HF-D02-interaction-state-model.md) | `BLOCKED_BY_DEPENDENCY` | `HF-D01` | `HF-DG2` |
| `HF-D03` | [高保真证据与验收](HF-D03-high-fidelity-evidence-contract.md) | `BLOCKED_BY_DEPENDENCY` | `HF-D02` | `HF-DG3` |
| `HF-D04` | [固定设计候选复核](HF-D04-fixed-design-review.md) | `BLOCKED_BY_DEPENDENCY` | `HF-D03` | `HF-DG4` |

## 2. 状态规则

卡片严格串行。活动卡之前必须为 `DONE`，活动卡必须是唯一 `READY`，后续卡必须
是 `BLOCKED_BY_DEPENDENCY`。每卡只能按批准计划中的精确写集形成一个本地提交。

## 3. 验证

```bash
bash tests/task-cards/verify-high-fidelity-design-cards.sh
scripts/verify-high-fidelity-design --cards-dir docs/task-cards/high-fidelity-design
```
