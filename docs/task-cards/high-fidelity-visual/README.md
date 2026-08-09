# Cognitura 高保真视觉设计任务卡索引

```text
CanonicalProjectName = Cognitura
TaskCardSet = HIGH_FIDELITY_VISUAL
TaskCardIDs = HV-D00,HV-D01,HV-D02,HV-D03,HV-D04,HV-D05
TaskCardCount = 6
ActiveTaskCard = HV-D01
TaskCardSetStatus = READY_FOR_EXECUTION
HighFidelityContractGate = HF-DG4 PASS
HighFidelityVisualDesign = NOT_RUN
HighFidelityUsabilityValidation = NOT_RUN
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
W1-I00Creation = FORBIDDEN
W1-I00Release = FORBIDDEN
```

本集合只治理 `docs/` 下的非生产视觉原型、确定性状态夹具、截图证据与最终视觉/
可用性审查。它消费已经通过 `HF-DG4` 的正式专项合同，不修改该专项正文，不创建
前端业务实现、API、数据库对象或实现任务卡。

## 1. 任务卡清单

| ID | 单一职责 | 状态 | 依赖 | Gate |
|---|---|---|---|---|
| `HV-D00` | [视觉基础与原型治理](HV-D00-visual-foundation.md) | `DONE` | `NONE` | `HV-D00 PASS` |
| `HV-D01` | [Module 默认阅读证据](HV-D01-module-default-reading.md) | `READY` | `HV-D00` | `HV-D01 NOT_RUN` |
| `HV-D02` | [Relation 聚焦与来源核验](HV-D02-focus-and-source.md) | `BLOCKED_BY_DEPENDENCY` | `HV-D01` | `HV-D02 NOT_RUN` |
| `HV-D03` | [修订、影响与恢复](HV-D03-revision-and-recovery.md) | `BLOCKED_BY_DEPENDENCY` | `HV-D02` | `HV-D03 NOT_RUN` |
| `HV-D04` | [跨层、小屏与静态导出](HV-D04-cross-layer-responsive-export.md) | `BLOCKED_BY_DEPENDENCY` | `HV-D03` | `HV-D04 NOT_RUN` |
| `HV-D05` | [固定视觉与可用性复核](HV-D05-fixed-visual-usability-review.md) | `BLOCKED_BY_DEPENDENCY` | `HV-D04` | `HV-D05 NOT_RUN` |

## 2. 状态规则

卡片严格串行；任何时刻最多一张 `READY`。`HV-D00` 只建立视觉 token、静态
fixture 治理和基础截图，不把后续页面证据或可用性状态标为 PASS。当前唯一允许
执行的卡是 `HV-D01`，其余四卡不得提前修改。

## 3. 验证

```bash
bash tests/task-cards/verify-high-fidelity-visual-cards.sh
scripts/verify-high-fidelity-visual
```
