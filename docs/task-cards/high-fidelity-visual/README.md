# Cognitura 高保真视觉设计任务卡索引

```text
CanonicalProjectName = Cognitura
TaskCardSet = HIGH_FIDELITY_VISUAL
TaskCardIDs = HV-D00,HV-D01,HV-D02,HV-D03,HV-D04,HV-D05
TaskCardCount = 6
ActiveTaskCard = NONE
TaskCardSetStatus = COMPLETE
HighFidelityContractGate = HF-DG4 PASS
HighFidelityVisualDesign = PASS
HighFidelityVisualValidation = PASS
HighFidelityModuleDefaultReading = PASS
HighFidelityFocusAndSource = PASS
HighFidelityRevisionAndRecovery = PASS
HighFidelityCrossLayerResponsiveAndExport = PASS
HighFidelityUsabilityValidation = PASS
HighFidelityStateAcceptance = PASS
ImplementationValidation = NOT_RUN
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
| `HV-D01` | [Module 默认阅读证据](HV-D01-module-default-reading.md) | `DONE` | `HV-D00` | `HV-D01 PASS` |
| `HV-D02` | [Relation 聚焦与来源核验](HV-D02-focus-and-source.md) | `DONE` | `HV-D01` | `HV-D02 PASS` |
| `HV-D03` | [修订、影响与恢复](HV-D03-revision-and-recovery.md) | `DONE` | `HV-D02` | `HV-D03 PASS` |
| `HV-D04` | [跨层、小屏与静态导出](HV-D04-cross-layer-responsive-export.md) | `DONE` | `HV-D03` | `HV-D04 PASS` |
| `HV-D05` | [固定视觉与可用性复核](HV-D05-fixed-visual-usability-review.md) | `DONE` | `HV-D04` | `HV-D05 PASS` |

## 2. 状态规则

卡片严格串行；任何时刻最多一张 `READY`。`HV-D00` 只建立视觉 token、静态
fixture 治理和基础截图；`HV-D01` 只关闭 Module 默认阅读的七项 RF Owner 视觉
结果，不把后续页面证据或可用性状态标为 PASS；`HV-D02` 只关闭
`RF-AC-03,07,09,16` 的视觉观察；`HV-D03` 只关闭 `RF-AC-13,14,17,18` 的视觉
观察；`HV-D04` 只关闭 `RF-AC-01,10,15,19`，并为 `RF-AC-20` 提供不关闭状态的
supporting evidence。`HV-D05` 已在固定候选双阶段零发现后关闭整套视觉任务卡。

## 3. 验证

```bash
bash tests/task-cards/verify-high-fidelity-visual-cards.sh
scripts/verify-high-fidelity-visual
```
