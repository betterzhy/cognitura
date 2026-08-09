# HF-D01 页面与呈现冲突裁决

```text
TaskCardID = HF-D01
CardKind = DESIGN
Status = DONE
Gate = HF-DG1 ReadingPresentationContract PASS
Risk = HIGH
DependsOn = HF-D00
ReviewRoute = SOL_HIGH_DESIGN_GATE
DesignOwner = READING_FIRST_PRESENTATION_AUTHORITY
LocalCommitBoundary = REQUIRED
WriteSetSource = APPROVED_TASK_PLAN_EXACT
WriteSetItemCount = 17
```

## 1. 目标

统一 Reading First、连续叙事、默认右栏、SourceEvidence 和视觉预算的权威解释。

## 2. 前置条件与输入

- HF-D00 已完成并登记专项候选。
- Overall Design 1.2 的现有页面与 Renderer 权威。
- Overall Design 1.2 是受 Wave 0 source manifest 固定的只读权威输入；本卡不修改其字节、历史版本或 `AppliedReverseMigration = 26/26`。

## 3. 写集

- Modify: `Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md`
- Modify: `docs/contracts/cognitura-page-contracts.md`
- Modify: `docs/contracts/cognitura-renderer-contract.md`
- Modify: `docs/engineering/cognitura-high-fidelity-design-manifest.yaml`
- Modify: `scripts/verify-high-fidelity-design-manifest`
- Modify: `tests/contracts/interaction-state/verify-high-fidelity-design-manifest.sh`
- Modify: `tests/contracts/ui/verify-ui-contracts.sh`
- Modify: `docs/task-cards/high-fidelity-design/HF-D01-reading-presentation-contract.md`
- Modify: `docs/task-cards/high-fidelity-design/README.md`
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `docs/task-cards/high-fidelity-design/HF-D02-interaction-state-model.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/superpowers/plans/2026-08-06-high-fidelity-design-alignment.md`
- Modify: `scripts/verify-high-fidelity-design`
- Modify: `tests/task-cards/verify-high-fidelity-design-cards.sh`
- Modify: `tests/contracts/interaction-state/verify-interaction-state-contracts.sh`

## 4. 禁止写集

- `server/**`, `web/**`, `raw/**`, `schemas/**`, `.idea/**` 和全部 `W1-I*`。
- Wave 0 固定 source manifest、specialty coverage 及其 validators/tests。

## 5. 执行步骤

先写 UI 与 17 项写集合同 RED，再以只读 Overall 为产品权威、最小协调专项、页面和 Renderer 投影，
刷新独立 HF manifest，完成负例、卡集 Gate 和活动卡投影同步后释放 HF-D02。

## 6. 验证命令

运行 UI、interaction-state、独立 HF manifest、高保真卡集、Markdown link 和 Wave 0 只读回归；
负例覆盖永久治理右栏、纯长文、Renderer 创造事实和陈旧 manifest。

## 7. Gate 与完成定义

`HF-DG1 = PASS` 不代表视觉、可用性或实现 PASS。

## 8. 提交与审查

使用 `gpt-5.6-sol/high` 形成一个本地提交，不推送。
