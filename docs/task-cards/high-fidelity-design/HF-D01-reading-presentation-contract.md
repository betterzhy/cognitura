# HF-D01 页面与呈现冲突裁决

```text
TaskCardID = HF-D01
CardKind = DESIGN
Status = READY
Gate = HF-DG1 ReadingPresentationContract
Risk = HIGH
DependsOn = HF-D00
ReviewRoute = SOL_HIGH_DESIGN_GATE
DesignOwner = READING_FIRST_PRESENTATION_AUTHORITY
LocalCommitBoundary = REQUIRED
WriteSetSource = APPROVED_TASK_PLAN_EXACT
WriteSetItemCount = 12
```

## 1. 目标

统一 Reading First、连续叙事、默认右栏、SourceEvidence 和视觉预算的权威解释。

## 2. 前置条件与输入

- HF-D00 已完成并登记专项候选。
- Overall Design 1.2 的现有页面与 Renderer 权威。

## 3. 写集

- Modify: `Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md`
- Modify: `cognitive-knowledge-atlas-overall-design-1.2.md`
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

## 4. 禁止写集

- `server/**`, `web/**`, `raw/**`, `schemas/**`, `.idea/**` 和全部 `W1-I*`。
- Wave 0 固定 source manifest、specialty coverage 及其 validators/tests。

## 5. 执行步骤

先写 UI 合同 RED，再最小协调专项、Overall、页面和 Renderer 投影，刷新独立 HF
manifest，完成负例后释放 HF-D02。

## 6. 验证命令

运行 UI、interaction-state、独立 HF manifest、Markdown link 和 Wave 0 只读回归；
负例覆盖永久治理右栏、纯长文、Renderer 创造事实和陈旧 manifest。

## 7. Gate 与完成定义

`HF-DG1 = PASS` 不代表视觉、可用性或实现 PASS。

## 8. 提交与审查

使用 `gpt-5.6-sol/high` 形成一个本地提交，不推送。
