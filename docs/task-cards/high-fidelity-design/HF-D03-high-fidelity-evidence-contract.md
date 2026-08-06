# HF-D03 高保真证据与验收

```text
TaskCardID = HF-D03
CardKind = DESIGN
Status = BLOCKED_BY_DEPENDENCY
Gate = HF-DG3 HighFidelityEvidenceContract
Risk = HIGH
DependsOn = HF-D02
ReviewRoute = SOL_HIGH_DESIGN_GATE
DesignOwner = HIGH_FIDELITY_EVIDENCE_AUTHORITY
LocalCommitBoundary = REQUIRED
WriteSetSource = APPROVED_TASK_PLAN_EXACT
WriteSetItemCount = 12
```

## 1. 目标

固定八类视觉证据、20 项 RF-AC、跨域场景和视觉/可用性阶段隔离。

## 2. 前置条件与输入

- HF-D02 的正交状态与恢复模型通过。
- 20 异常、20 RF-AC 与 30 反向迁移项保持一对一追溯。

## 3. 写集

- Create: `docs/engineering/cognitura-high-fidelity-design-plan.md`
- Create: `docs/engineering/cognitura-high-fidelity-design-acceptance.md`
- Modify: `Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/engineering/cognitura-high-fidelity-design-manifest.yaml`
- Modify: `scripts/verify-high-fidelity-design-manifest`
- Modify: `tests/contracts/interaction-state/verify-high-fidelity-design-manifest.sh`
- Modify: `tests/contracts/interaction-state/verify-interaction-state-contracts.sh`
- Modify: `docs/task-cards/high-fidelity-design/HF-D03-high-fidelity-evidence-contract.md`
- Modify: `docs/task-cards/high-fidelity-design/README.md`
- Modify: `README.md`
- Modify: `AGENTS.md`

## 4. 禁止写集

- `server/**`, `web/**`, `raw/**`, `schemas/**`, `.idea/**` 和全部 `W1-I*`。
- Wave 0 固定 source manifest、specialty coverage 及其 validators/tests。

## 5. 执行步骤

先建立证据阶段 RED，再写计划与验收记录，刷新 HF manifest，完成负例后释放 HF-D04。

## 6. 验证命令

运行 interaction-state、HF manifest、卡集与 Markdown link；负例覆盖缺证据类、缺
RF-AC、异常遗漏、跨域缺失和阶段冒充。

## 7. Gate 与完成定义

`HF-DG3 = PASS` 仅证明高保真证据输入完整；视觉和可用性仍为 `NOT_RUN`。

## 8. 提交与审查

使用 `gpt-5.6-sol/high` 形成一个本地提交，不推送。
