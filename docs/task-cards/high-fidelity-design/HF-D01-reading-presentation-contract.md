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
WriteSetItemCount = 21
```

## 1. 目标

统一 Reading First、连续叙事、默认右栏、SourceEvidence 和视觉预算的权威解释。

## 2. 前置条件与输入

- HF-D00 已完成并登记专项候选。
- Overall Design 1.2 的现有页面与 Renderer 权威。
- Overall Design 1.2 是正式产品权威；本卡仅获准最小协调 §20.7/20.8/20.9 和 §27 呈现细化，不修改历史版本或 `AppliedReverseMigration = 26/26`。

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
- Modify: `cognitive-knowledge-atlas-overall-design-1.2.md`
- Modify: `docs/engineering/cognitura-source-manifest.yaml`
- Modify: `docs/superpowers/specs/2026-08-06-high-fidelity-interaction-design-integration.md`
- Modify: `scripts/verify-ui-contracts`

## 4. 禁止写集

- `server/**`, `web/**`, `raw/**`, `schemas/**`, `.idea/**` 和全部 `W1-I*`。
- Wave 0 specialty coverage 与 source/specialty validators/tests。source manifest 只允许原子刷新已登记 `DESIGN-OVERALL-001` 的 `sizeBytes`/`sha256`；四来源身份、数量、type/order 语义不变，HF 候选不得登记。

## 5. 执行步骤

先写 UI 与 21 项累计写集合同 RED，再以 Overall 为产品权威、最小协调 Overall、专项、页面和 Renderer 投影，
原子刷新 Overall 的既有 source manifest 指纹与独立 HF manifest，完成负例、卡集 Gate 和活动卡投影同步后释放 HF-D02。

## 6. 验证命令

运行 UI、interaction-state、独立 HF manifest、高保真卡集、Markdown link 和 Wave 0 只读回归；
负例覆盖永久治理右栏、纯长文、Renderer 创造事实和陈旧 manifest。

## 7. Gate 与完成定义

`HF-DG1 = PASS` 不代表视觉、可用性或实现 PASS。

## 8. 提交与审查

使用 `gpt-5.6-sol/high` 形成一个本地提交，不推送。
