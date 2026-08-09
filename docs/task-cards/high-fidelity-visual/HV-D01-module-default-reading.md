# HV-D01 Module Default Reading Evidence

```text
TaskCardID = HV-D01
CardKind = HIGH_FIDELITY_VISUAL_DESIGN
Status = DONE
Gate = HV-D01 PASS
Risk = MEDIUM
DependsOn = HV-D00
ReviewRoute = MAIN_AGENT_LOCAL_GATE
DesignOwner = MODULE_DEFAULT_READING_EVIDENCE
LocalCommitBoundary = docs: design module default reading evidence
WriteSetSource = MASTER_PLAN_TASK_7_CORRECTED
WriteSetItemCount = 17
```

## 1. 目标

以确定性机制型合成内容证明 Module 默认阅读无需交互即可形成完整认知闭环。

## 2. 前置条件与输入

只消费 `HV-D00 PASS`、正式 HF 合同和计划中的 `CognitiveModuleDefaultReading` 路径。

## 3. 写集

- `docs/design/high-fidelity/prototype/index.html`
- `docs/design/high-fidelity/prototype/styles.css`
- `docs/design/high-fidelity/prototype/prototype.js`
- `docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md`
- `docs/design/high-fidelity/evidence/module-default-reading-desktop.png`
- `docs/design/high-fidelity/evidence/README.md`
- `docs/engineering/cognitura-high-fidelity-design-plan.md`
- `docs/engineering/cognitura-high-fidelity-design-acceptance.md`
- `docs/task-cards/high-fidelity-visual/HV-D01-module-default-reading.md`
- `docs/task-cards/high-fidelity-visual/HV-D02-focus-and-source.md`
- `docs/task-cards/high-fidelity-visual/README.md`
- `tests/task-cards/verify-high-fidelity-visual-cards.sh`
- `scripts/verify-high-fidelity-visual`
- `docs/engineering/cognitura-design-index.md`
- `README.md`
- `AGENTS.md`
- `docs/task-cards/README.md`

## 4. 禁止写集

禁止读取 Golden Case DOCX 作为运行输入；禁止业务代码、HTTP、持久化和正式状态写入。

## 5. 执行步骤

先写 DOM/截图失败断言，再实现 `state=module-default`，捕获并检查 1440×1100 证据，
仅记录 Owner 集 `RF-AC-02,04,05,06,08,11,12` 的视觉结果，最后在上述状态同步文件中
关闭 `HV-D01` 并释放 `HV-D02`。不得提前改写其他 RF-AC。

## 6. 验证命令

```bash
bash tests/task-cards/verify-high-fidelity-visual-cards.sh
scripts/verify-high-fidelity-visual
bash tests/contracts/interaction-state/verify-interaction-state-contracts.sh
git diff --check
```

## 7. Gate 与完成定义

默认阅读截图与 DOM 同时证明零交互闭环后才允许 `HV-D01 PASS`；可用性仍为 `NOT_RUN`。

```text
ModuleDefaultReadingArtifact = docs/design/high-fidelity/evidence/module-default-reading-desktop.png
ModuleDefaultReadingViewport = DESKTOP_1440x1100
ModuleDefaultReadingState = module-default
ModuleDefaultReadingVisualResult = PASS
RFOwnerVisualPass = RF-AC-02,04,05,06,08,11,12
HighFidelityUsabilityValidation = NOT_RUN
ImplementationValidation = NOT_RUN
```

## 8. 提交与审查

形成独立本地提交 `docs: design module default reading evidence`；不 push。
