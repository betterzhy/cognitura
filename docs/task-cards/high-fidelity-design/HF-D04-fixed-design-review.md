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
WriteSetItemCount = 19
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
- Modify: `docs/engineering/cognitura-high-fidelity-design-plan.md`
- Modify: `docs/superpowers/plans/2026-08-06-high-fidelity-design-alignment.md`
- Modify: `scripts/verify-high-fidelity-design`
- Modify: `scripts/verify-interaction-state-contracts`
- Modify: `tests/contracts/interaction-state/verify-interaction-state-contracts.sh`
- Modify: `tests/task-cards/verify-high-fidelity-design-cards.sh`

## 4. 禁止写集

- `server/**`, `web/**`, `raw/**`, `schemas/**`, `.idea/**` 和全部 `W1-I*`。
- Wave 0 固定 source manifest、specialty coverage 及其 validators/tests。
- 禁止目录级 `git add`；准备提交和封口提交都必须逐文件暂存精确写集。

## 5. 执行步骤

先形成只包含本卡准备治理变更的本地提交并冻结准备 SHA；该准备提交不得修改专项
候选正文、独立 manifest 或 coverage。两个相互独立的 `gpt-5.6-sol/high`
reviewer 必须审查同一个准备 SHA，顺序固定为一般深审后最终门禁；两阶段均返回
`GO / P0=0 / P1=0 / P2=0` 才允许进入 promotion closure，不使用 ultra。

任一阶段产生 finding 时，必须回到 finding 的 owner card，先增加失败回归断言，
再修复并重跑全部适用 Gate；随后冻结新的准备 SHA，并从一般深审开始完整重跑
两个独立阶段。审查期间不得修改固定候选。

## 6. 验证命令

运行全部 HF 合同、interaction-state、独立 manifest/coverage、UI、Schema、
Wave 0、source/specialty、Markdown、Bash syntax 和 diff 验证；负例覆盖 reviewed
candidate SHA 三联不一致、候选正文与 manifest 精确指纹不一致、coverage 未关闭、
过早晋级、陈旧 hash 与任一审查非零。

## 7. Gate 与完成定义

只有双阶段均为 `GO / P0=0 / P1=0 / P2=0`，封口提交才允许把专项正文、独立
manifest 和 coverage 记录为同一 reviewed candidate SHA，同时要求 manifest 的
字节数和 SHA-256 与晋级后的专项正文精确一致，并把 coverage 置为 reviewed/closed。
`HV-D00` 只在 `docs/engineering/cognitura-high-fidelity-design-plan.md` 中投影为
`READY`；实际 HV 卡集由 Task 6 创建。本卡不得创建或释放 `W1-I00`，也不授权
业务实现、正式数据库写入或远程推送。

## 8. 提交与审查

准备提交逐文件暂存本次四个治理文件并使用
`docs: prepare fixed high fidelity candidate review`；不得 amend 或推送。两阶段均
使用 `gpt-5.6-sol/high` 且相互独立，不使用 ultra。审查清零后另形成一个本地
promotion closure 提交；封口提交必须逐文件暂存第 3 节的 19 项精确写集，不得
使用 `git add docs/task-cards/high-fidelity-design` 等目录级暂存，不推送。
