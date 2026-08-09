# HF-D03 高保真证据与验收

```text
TaskCardID = HF-D03
CardKind = DESIGN
Status = DONE
Gate = HF-DG3 HighFidelityEvidenceContract PASS
Risk = HIGH
DependsOn = HF-D02
ReviewRoute = SOL_HIGH_DESIGN_GATE
DesignOwner = HIGH_FIDELITY_EVIDENCE_AUTHORITY
LocalCommitBoundary = REQUIRED
WriteSetSource = APPROVED_TASK_PLAN_EXACT
WriteSetItemCount = 17
```

## 1. 目标

固定八类视觉证据、20 项 RF-AC、跨域场景和视觉/可用性阶段隔离。

## 2. 前置条件与输入

- HF-D02 的正交状态与恢复模型已通过 `HF-DG2`。
- 20 异常、20 RF-AC 与 30 反向迁移项保持一对一追溯。

## 3. 写集

- Create: `docs/engineering/cognitura-high-fidelity-design-plan.md`
- Create: `docs/engineering/cognitura-high-fidelity-design-acceptance.md`
- Modify: `Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/engineering/cognitura-high-fidelity-design-manifest.yaml`
- Modify: `docs/superpowers/plans/2026-08-06-high-fidelity-design-alignment.md`
- Modify: `docs/task-cards/high-fidelity-design/HF-D04-fixed-design-review.md`
- Modify: `scripts/verify-high-fidelity-design`
- Modify: `scripts/verify-high-fidelity-design-manifest`
- Modify: `scripts/verify-interaction-state-contracts`
- Modify: `tests/contracts/interaction-state/verify-high-fidelity-design-manifest.sh`
- Modify: `tests/contracts/interaction-state/verify-interaction-state-contracts.sh`
- Modify: `tests/task-cards/verify-high-fidelity-design-cards.sh`
- Modify: `docs/task-cards/high-fidelity-design/HF-D03-high-fidelity-evidence-contract.md`
- Modify: `docs/task-cards/high-fidelity-design/README.md`
- Modify: `README.md`
- Modify: `AGENTS.md`

## 4. 禁止写集

- `server/**`, `web/**`, `raw/**`, `schemas/**`, `.idea/**` 和全部 `W1-I*`。
- Wave 0 固定 source manifest、specialty coverage 及其 validators/tests。

## 5. 执行步骤

已先建立证据阶段 RED，再写计划与验收记录，刷新 HF manifest；八类证据、20 项
RF-AC、20 异常、30 RM、两类跨域场景与六项 HV 阻断序列均已 fail-closed，随后
释放 HF-D04。

## 6. 验证命令

运行 interaction-state、UI、Schema、HF manifest、卡集、Wave 0 来源/专项回归、
Markdown link、bash-n、diff 与 exact17；负例覆盖缺证据类、缺 RF-AC、异常遗漏、
跨域缺失、陈旧 metadata、阶段冒充和 HV 提前释放。

## 7. Gate 与完成定义

`HF-DG3 = PASS` 仅证明高保真证据输入合同完整；视觉和可用性仍为 `NOT_RUN`，
真实 HV 卡集、视觉页面、原型与截图均未创建。

## 8. 提交与审查

使用 `gpt-5.6-sol/high` 形成一个本地提交，不推送。
