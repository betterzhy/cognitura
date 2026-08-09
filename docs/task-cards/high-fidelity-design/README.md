# Cognitura 高保真设计任务卡索引

```text
CanonicalProjectName = Cognitura
TaskCardSet = HIGH_FIDELITY_DESIGN
TaskCardIDs = HF-D00,HF-D01,HF-D02,HF-D03,HF-D04
TaskCardCount = 5
ActiveTaskCard = NONE
TaskCardSetStatus = COMPLETE
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
| `HF-D01` | [页面与呈现冲突裁决](HF-D01-reading-presentation-contract.md) | `DONE` | `HF-D00` | `HF-DG1 PASS` |
| `HF-D02` | [正交状态与恢复边界](HF-D02-interaction-state-model.md) | `DONE` | `HF-D01` | `HF-DG2 PASS` |
| `HF-D03` | [高保真证据与验收](HF-D03-high-fidelity-evidence-contract.md) | `DONE` | `HF-D02` | `HF-DG3 PASS` |
| `HF-D04` | [固定设计候选复核](HF-D04-fixed-design-review.md) | `DONE` | `HF-D03` | `HF-DG4 PASS` |

## 2. 状态规则

卡片严格串行。五张卡现已全部 `DONE`，没有活动卡或 `READY` 卡。HF-D04 审查的
准备 SHA 为 `463fd4829e7c4bb8da071253e8ae9b15cee2a0cf`，两个独立
`gpt-5.6-sol/high` 阶段均为 `GO / P0=0 / P1=0 / P2=0`。每卡仍只按批准计划的
精确写集形成一个本地提交。

## 3. 验证

```bash
bash tests/task-cards/verify-high-fidelity-design-cards.sh
scripts/verify-high-fidelity-design --cards-dir docs/task-cards/high-fidelity-design
```
