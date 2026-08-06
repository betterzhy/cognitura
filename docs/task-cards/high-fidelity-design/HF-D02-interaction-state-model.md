# HF-D02 正交状态与恢复边界

```text
TaskCardID = HF-D02
CardKind = DESIGN
Status = BLOCKED_BY_DEPENDENCY
Gate = HF-DG2 OrthogonalStateAndRecoveryModel
Risk = HIGH
DependsOn = HF-D01
ReviewRoute = SOL_HIGH_DESIGN_GATE
DesignOwner = INTERACTION_STATE_AND_RECOVERY_AUTHORITY
LocalCommitBoundary = REQUIRED
WriteSetSource = APPROVED_TASK_PLAN_EXACT
WriteSetItemCount = 10
```

## 1. 目标

将 46 个历史代码一对一分类到正交轴、临时态、流程、事件和派生结果，并固定恢复边界。

## 2. 前置条件与输入

- HF-D01 已关闭页面呈现冲突。
- 候选原始 46 状态和 20 异常保持完整。

## 3. 写集

- Modify: `Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md`
- Modify: `docs/contracts/cognitura-page-contracts.md`
- Modify: `docs/engineering/cognitura-high-fidelity-design-manifest.yaml`
- Modify: `scripts/verify-high-fidelity-design-manifest`
- Modify: `tests/contracts/interaction-state/verify-high-fidelity-design-manifest.sh`
- Modify: `tests/contracts/interaction-state/verify-interaction-state-contracts.sh`
- Modify: `docs/task-cards/high-fidelity-design/HF-D02-interaction-state-model.md`
- Modify: `docs/task-cards/high-fidelity-design/README.md`
- Modify: `README.md`
- Modify: `AGENTS.md`

## 4. 禁止写集

- `server/**`, `web/**`, `raw/**`, `schemas/**`, `.idea/**` 和全部 `W1-I*`。
- Wave 0 固定 source manifest、specialty coverage 及其 validators/tests。

## 5. 执行步骤

先扩展分类 RED，再加入六轴、五级持久化、恢复与 Schema non-change 决议，刷新 HF
manifest，完成负例后释放 HF-D03。

## 6. 验证命令

运行 interaction-state、UI、Schema、HF manifest、卡集和 Wave 0 source manifest；
负例覆盖重复 owner、遗漏、事件持久化、Preview 入 URL 与命名碰撞。

## 7. Gate 与完成定义

`HF-DG2 = PASS` 要求 46 状态恰好一次分类且 PageState 12 值不变。

## 8. 提交与审查

使用 `gpt-5.6-sol/high` 形成一个本地提交，不推送。
