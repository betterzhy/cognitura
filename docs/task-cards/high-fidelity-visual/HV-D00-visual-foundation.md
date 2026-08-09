# HV-D00 Visual Foundation and Prototype Governance

```text
TaskCardID = HV-D00
CardKind = HIGH_FIDELITY_VISUAL_DESIGN
Status = DONE
Gate = HV-D00 PASS
Risk = MEDIUM
DependsOn = NONE
ReviewRoute = MAIN_AGENT_LOCAL_GATE
DesignOwner = VISUAL_FOUNDATION_AND_PROTOTYPE_GOVERNANCE
LocalCommitBoundary = docs: establish high fidelity visual foundation
WriteSetSource = MASTER_PLAN_TASK_6_MAIN_AGENT_CORRECTED
WriteSetItemCount = 22
```

## 1. 目标

建立非生产视觉 token、静态原型治理、确定性 URL 状态夹具和 1440×1100 基础截图，
创建六卡串行状态机，并在不宣称视觉/可用性完成的前提下释放 `HV-D01`。

## 2. 前置条件与输入

- `HF-DG4 FixedDesignReview = PASS`。
- 正式 HF 专项保持 `FORMAL_SPECIALTY_BASELINE` 且不修改。
- 基线提交为 `6940ff686721d140ae2ef40a1c6027c6a3d8734d`。

## 3. 写集

- `docs/task-cards/high-fidelity-visual/README.md`
- `docs/task-cards/high-fidelity-visual/HV-D00-visual-foundation.md`
- `docs/task-cards/high-fidelity-visual/HV-D01-module-default-reading.md`
- `docs/task-cards/high-fidelity-visual/HV-D02-focus-and-source.md`
- `docs/task-cards/high-fidelity-visual/HV-D03-revision-and-recovery.md`
- `docs/task-cards/high-fidelity-visual/HV-D04-cross-layer-responsive-export.md`
- `docs/task-cards/high-fidelity-visual/HV-D05-fixed-visual-usability-review.md`
- `tests/task-cards/verify-high-fidelity-visual-cards.sh`
- `scripts/verify-high-fidelity-visual`
- `docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md`
- `docs/design/high-fidelity/prototype/index.html`
- `docs/design/high-fidelity/prototype/styles.css`
- `docs/design/high-fidelity/prototype/prototype.js`
- `docs/design/high-fidelity/evidence/README.md`
- `docs/engineering/cognitura-high-fidelity-design-plan.md`
- `README.md`
- `AGENTS.md`
- `docs/design/high-fidelity/evidence/visual-foundation-desktop.png`
- `docs/engineering/cognitura-design-index.md`
- `docs/engineering/cognitura-high-fidelity-design-acceptance.md`
- `docs/superpowers/plans/2026-08-06-high-fidelity-design-alignment.md`
- `docs/task-cards/README.md`

## 4. 禁止写集

- 正式 HF 专项正文、Wave 0 固定资产、`web/`、`server/`、Schema、`raw/`。
- `W1-I00`、业务实现、正式数据库写入和远程推送。

## 5. 执行步骤

1. 先创建验证并观察视觉卡集/原型缺失的预期失败。
2. 建立六卡精确写集、视觉 token、URL-only 静态原型与证据合同。
3. 生成并人工检查 `visual-foundation-desktop.png`。
4. 同步所有状态投影，只释放 `HV-D01`。

## 6. 验证命令

```bash
bash tests/task-cards/verify-high-fidelity-visual-cards.sh
scripts/verify-high-fidelity-visual
bash tests/contracts/interaction-state/verify-interaction-state-contracts.sh
bash tests/task-cards/verify-high-fidelity-design-cards.sh
scripts/verify-wave0
git diff --check
```

## 7. Gate 与完成定义

`HV-D00 PASS` 只表示视觉基础、原型治理与基础证据存在且可验证；
`HighFidelityVisualDesign`、`HighFidelityUsabilityValidation` 继续为 `NOT_RUN`。

## 8. 提交与审查

逐文件暂存精确 22 项并本地提交 `docs: establish high fidelity visual foundation`；
不 amend、不 push。
