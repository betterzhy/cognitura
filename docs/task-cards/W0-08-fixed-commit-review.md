# W0-08 固定提交复核与 Wave 1 准入

```text
TaskCardID = W0-08
Status = DONE
Gate = W0-G6 FixedCommitReview
Risk = HIGH
DependsOn = W0-07
ReviewRoute = SOL_HIGH_GENERAL_THEN_SOL_HIGH_FINAL_GATE
ExecutionStatus = DONE
CurrentBlocker = NONE
ReviewedCommit = 08ddc00907a6ead84a526c71a2c0802f363fe614
FixedCommitCI = PASS
CIURL = https://github.com/betterzhy/cognitura/actions/runs/30495773273
```

## 1. 目标

在干净工作树上固定 Wave 0 候选提交，完成一般深度审查和最终高风险准入复核，
基于全部 Gate 证据对 Wave 1 给出唯一的 GO/NO-GO 裁决。

## 2. 前置条件与输入

- `W0-G0`、`W0-G1`、`W0-G2`、`W0-G2A`、`W0-G3`、`W0-G4`、
  `W0-G4A`、`W0-G5` 全部为 `PASS`
- 工作树干净、候选 commit 固定
- 本地完整验证通过且 CI URL 可访问
- 原件哈希、设计来源、Schema 来源和 Golden Case 证据完整

任一前置 Gate 未通过时，本卡不得开始。

最终固定候选 `08ddc00907a6ead84a526c71a2c0802f363fe614` 的本地七阶段验证与
GitHub Actions
[run #4](https://github.com/betterzhy/cognitura/actions/runs/30495773273)
均已成功；第三轮一般审查达到 `P0=0/P1=0/P2=0`，独立最终门禁裁决为 GO。

## 3. 写集

- Modify: `docs/engineering/cognitura-wave-0-entry-decision.md`
- Create: `docs/engineering/cognitura-wave-1-entry-decision.md`
- Modify: `docs/task-cards/README.md`
- Modify: `docs/task-cards/W0-08-fixed-commit-review.md`
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `docs/engineering/cognitura-wave-0-plan.md`
- Modify: `scripts/verify-task-cards`
- Modify: `tests/task-cards/verify-task-cards.sh`

审查修复必须形成新的独立提交和新的固定候选；不得 amend 候选提交。
以上扩展写集已于 `2026-07-30` 获得用户明确授权。

## 4. 执行步骤

- [x] 运行完整 Wave 0 验证并记录命令、结果、原件哈希、CI URL 和候选 commit。
- [x] 确认干净审查工作树，将候选 commit 交给 `gpt-5.6-sol/high`
  做一般深度审查。
- [x] 将 P0/P1/P2 发现写入复核记录；存在发现时退出准入流程。
- [x] 在独立提交修复发现，重新运行全部 Gate 并生成新的固定候选。
- [x] 一般深度审查达到 `P0=0/P1=0/P2=0` 后，交给独立
  `gpt-5.6-sol/high` 最终门禁。
- [x] 最终复核历史设计未改写、原件哈希未漂移、Schema 来源可追溯、回归和 CI 可复现。
- [x] 根据最终门禁结果创建 Wave 1 准入裁决。
- [x] 最终结果为 GO，更新本卡和 Repository 的 Wave 1 准入状态。

## 5. 验证命令

```bash
git status --short --branch
git rev-parse HEAD
scripts/verify-wave0
git diff --check HEAD^ HEAD
bash tests/task-cards/verify-task-cards.sh
```

审查请求必须绑定 `git rev-parse HEAD` 返回的完整 commit，不接受浮动工作树。

### 第一轮一般审查记录

```text
ReviewDate = 2026-07-30
ReviewModel = gpt-5.6-sol
ReviewReasoningEffort = high
ReviewedCommit = 311b04093531f5c1032b08e42b50e6f04edb6f1a
GeneralReviewVerdict = NOT_READY
P0 = 0
P1 = 2
P2 = 0
```

- `P1-1`：任务卡校验器不能表达九卡全部 `DONE`、`ActiveTaskCard = NONE`
  的成功终态。
- `P1-2`：原写集未覆盖 `AGENTS.md`、Wave 0 计划以及成功终态校验器和测试。
- 处理：退出准入流程；扩展写集获批后以独立提交修复，并重新固定候选、运行
  全量 Gate 与 CI。

### 第二轮一般审查记录

```text
ReviewDate = 2026-07-30
ReviewModel = gpt-5.6-sol
ReviewReasoningEffort = high
ReviewedCommit = 5559243910c5613bc69b477d8e3f25fe32f5908c
GeneralReviewVerdict = NOT_READY
P0 = 0
P1 = 1
P2 = 0
```

- `P1-1`：契约测试从 canonical 状态直接派生 `QUEUED` 夹具，只在
  `READY_FOR_EXECUTION` 下合法；真实 `COMPLETE` canonical 状态会使测试脚本
  自身失败。
- 处理：从固定的合法 READY 基准派生全部变体，并分别在 READY 与 COMPLETE
  canonical 状态下执行同一契约测试。

### 第三轮一般审查记录

```text
ReviewDate = 2026-07-30
ReviewModel = gpt-5.6-sol
ReviewReasoningEffort = high
ReviewedCommit = 08ddc00907a6ead84a526c71a2c0802f363fe614
GeneralReviewVerdict = READY
P0 = 0
P1 = 0
P2 = 0
```

第三轮审查确认 READY、COMPLETE 与 BLOCKED 三种 canonical 状态均可运行同一
任务卡契约测试，允许进入独立最终门禁。

### 最终门禁记录

```text
GateDate = 2026-07-30
GateModel = gpt-5.6-sol
GateReasoningEffort = high
ReviewedCommit = 08ddc00907a6ead84a526c71a2c0802f363fe614
FinalGateVerdict = GO
P0 = 0
P1 = 0
P2 = 0
CIURL = https://github.com/betterzhy/cognitura/actions/runs/30495773273
CIJobURL = https://github.com/betterzhy/cognitura/actions/runs/30495773273/job/90724096530
```

最终门禁独立重跑 `scripts/verify-wave0` 与 W0-G2 专项契约验证，确认全部执行
Gate、正式来源哈希、Schema 来源、Golden Case、UI/Renderer、CI 与远端 SHA
一致，且不存在提前实现的 Wave 1 功能。

## 6. Gate 与完成定义

GO 的必要条件：

- 前八个执行 Gate 全部为 `PASS`；
- 固定提交 CI 全绿；
- `gpt-5.6-sol/high` 一般审查结果为 `P0=0/P1=0/P2=0`；
- 独立 `gpt-5.6-sol/high` 最终门禁裁决为 GO；
- Wave 1 准入文件绑定同一候选 commit。

```text
W0-G6 FixedCommitReview = PASS
Wave1FeatureDevelopmentEntry = GO
```

任一条件不满足时保持：

```text
Wave1FeatureDevelopmentEntry = NO_GO
```

## 7. 提交与审查

```text
CommitMessage = docs: record Cognitura Wave 1 entry decision
CommitReview = SOL_HIGH_GENERAL_THEN_SOL_HIGH_FINAL_GATE
TerminalDecision = GO_OR_NO_GO
```

本卡只负责准入封口，不实现任何 Wave 1 功能。
