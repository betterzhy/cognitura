# HF-D00 设计治理与来源登记

```text
TaskCardID = HF-D00
CardKind = DESIGN
Status = DONE
Gate = HF-DG0 DesignGovernanceAndSourceRegistration
Risk = HIGH
DependsOn = NONE
ReviewRoute = SOL_HIGH_DESIGN_GATE
DesignOwner = PROJECT_IDENTITY_AND_SOURCE_AUTHORITY
LocalCommitBoundary = REQUIRED
WriteSetSource = APPROVED_TASK_PLAN_EXACT
WriteSetItemCount = 20
```

## 1. 目标

建立独立 HF 卡集、来源 manifest、合同覆盖与验证入口，并将候选身份降级到 Repository
Gate 前的真实状态。

## 2. 前置条件与输入

- 已批准整合规格 `docs/superpowers/specs/2026-08-06-high-fidelity-interaction-design-integration.md`。
- 用户提供且当前未跟踪的专项候选正文。
- Wave 0 固定来源和专项覆盖资产仅作只读回归。

## 3. 写集

- Create: `docs/task-cards/high-fidelity-design/README.md`
- Create: `docs/task-cards/high-fidelity-design/HF-D00-design-governance.md`
- Create: `docs/task-cards/high-fidelity-design/HF-D01-reading-presentation-contract.md`
- Create: `docs/task-cards/high-fidelity-design/HF-D02-interaction-state-model.md`
- Create: `docs/task-cards/high-fidelity-design/HF-D03-high-fidelity-evidence-contract.md`
- Create: `docs/task-cards/high-fidelity-design/HF-D04-fixed-design-review.md`
- Create: `scripts/verify-high-fidelity-design`
- Create: `tests/task-cards/verify-high-fidelity-design-cards.sh`
- Create: `scripts/verify-interaction-state-contracts`
- Create: `tests/contracts/interaction-state/verify-interaction-state-contracts.sh`
- Create: `docs/engineering/cognitura-high-fidelity-design-manifest.yaml`
- Create: `docs/engineering/cognitura-high-fidelity-contract-coverage.md`
- Create: `scripts/verify-high-fidelity-design-manifest`
- Create: `tests/contracts/interaction-state/verify-high-fidelity-design-manifest.sh`
- Create: `scripts/verify-high-fidelity-contract-coverage`
- Create: `tests/contracts/interaction-state/verify-high-fidelity-contract-coverage.sh`
- Modify: `Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `README.md`
- Modify: `AGENTS.md`

## 4. 禁止写集

- `server/**`, `web/**`, `raw/**`, `schemas/**`, migration 与部署配置。
- `.idea/**` 和任何 `W1-I00..W1-I13` 文件或 worktree。
- Wave 0 固定 source manifest、specialty coverage 及其 validators/tests。

## 5. 执行步骤

1. 先建立并观察四条失败验证。
2. 建立五卡集合与 Bash 3.2 兼容验证器。
3. 规范候选身份、层级、Git 事实与缺失权威。
4. 独立登记候选 hash/字节数及 deferred coverage。
5. 通过正反例和 Wave 0 回归后关闭本卡，只释放 HF-D01。

## 6. 验证命令

正例运行四条 HF 测试、两条 Wave 0 只读回归及 `git diff --check`。负例必须覆盖
缺失来源、错误 hash、缺失覆盖、缺失状态、错误层级、过早正式化和后继卡抢跑。

## 7. Gate 与完成定义

`HF-DG0 = PASS` 仅表示治理、候选登记和原始 `46/20/20/30` 清单可验证；不晋级
正式专项，不关闭后续合同 Gate，也不创建或释放 `W1-I00`。

## 8. 提交与审查

使用 `gpt-5.6-sol/high` 完成本卡自审，形成一个本地提交；禁止远程推送。

```text
HF-DG0 = PASS
PositiveValidation = PASS
NegativeValidation = PASS
Wave0Regression = PASS
BusinessImplementation = NOT_AUTHORIZED
W1-I00Release = FORBIDDEN
```
