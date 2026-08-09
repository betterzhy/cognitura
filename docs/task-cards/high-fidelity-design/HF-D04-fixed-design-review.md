# HF-D04 固定设计候选复核

```text
TaskCardID = HF-D04
CardKind = DESIGN
Status = READY
Gate = HF-DG4 FixedDesignReview
Risk = HIGH
DependsOn = HF-D03
ReviewRoute = SOL_HIGH_GENERAL_THEN_SOL_HIGH_FINAL_GATE
DesignOwner = FIXED_CANDIDATE_PROMOTION_AUTHORITY
LocalCommitBoundary = REQUIRED
WriteSetSource = APPROVED_TASK_PLAN_EXACT
WriteSetItemCount = 13
```

## 1. 目标

对固定候选执行两个独立 `gpt-5.6-sol/high` 阶段，并仅在零发现时同步正式晋级三联。

## 2. 前置条件与输入

- HF-D00 至 HF-D03 全部关闭。
- 固定候选 SHA 的完整本地验证证据。

## 3. 写集

- Modify: `Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md`
- Modify: `docs/engineering/cognitura-high-fidelity-design-manifest.yaml`
- Modify: `docs/engineering/cognitura-high-fidelity-contract-coverage.md`
- Modify: `scripts/verify-high-fidelity-design-manifest`
- Modify: `tests/contracts/interaction-state/verify-high-fidelity-design-manifest.sh`
- Modify: `scripts/verify-high-fidelity-contract-coverage`
- Modify: `tests/contracts/interaction-state/verify-high-fidelity-contract-coverage.sh`
- Modify: `docs/engineering/cognitura-high-fidelity-design-acceptance.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/task-cards/high-fidelity-design/HF-D04-fixed-design-review.md`
- Modify: `docs/task-cards/high-fidelity-design/README.md`
- Modify: `README.md`
- Modify: `AGENTS.md`

## 4. 禁止写集

- `server/**`, `web/**`, `raw/**`, `schemas/**`, `.idea/**` 和全部 `W1-I*`。
- Wave 0 固定 source manifest、specialty coverage 及其 validators/tests。

## 5. 执行步骤

固定候选后先一般深审，再执行相互独立的最终门禁；任何 P0/P1/P2 都禁止晋级。

## 6. 验证命令

运行全部 HF 合同、独立 manifest/coverage、UI、Schema、Wave 0、Markdown 和 diff
验证；负例覆盖 SHA 三联不一致、过早晋级、陈旧 hash 与任一审查非零。

## 7. Gate 与完成定义

`HF-DG4 = PASS` 才允许专项正文、独立 manifest 和 coverage 以同一 reviewed SHA
晋级；仍不授权业务实现、正式数据库写入或远程推送。

## 8. 提交与审查

两阶段均使用 `gpt-5.6-sol/high`，相互独立；形成一个本地封口提交，不推送。
