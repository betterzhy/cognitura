# W0-08 固定提交复核与 Wave 1 准入

```text
TaskCardID = W0-08
Status = BLOCKED_BY_DEPENDENCY
Gate = W0-G6 FixedCommitReview
Risk = HIGH
DependsOn = W0-07
ReviewRoute = DEEP_REVIEWER_THEN_ULTRA_GATEKEEPER
CurrentBlocker = W0_G5_FIXED_COMMIT_CI_URL_MISSING
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

当前 `W0-G5` 只有本地七阶段 PASS；Repository 尚无 remote，固定提交 CI 与
可访问 URL 尚不存在。因此本卡继续保持 `BLOCKED_BY_DEPENDENCY`，不得提前进入
固定候选审查。

## 3. 写集

- Modify: `docs/engineering/cognitura-wave-0-entry-decision.md`
- Create: `docs/engineering/cognitura-wave-1-entry-decision.md`
- Modify: `docs/task-cards/README.md`
- Modify: `docs/task-cards/W0-08-fixed-commit-review.md`
- Modify: `README.md`

审查修复必须形成新的独立提交和新的固定候选；不得 amend 候选提交。

## 4. 执行步骤

- [ ] 运行完整 Wave 0 验证并记录命令、结果、原件哈希、CI URL 和候选 commit。
- [ ] 确认工作树干净，将候选 commit 交给 `deep_reviewer` 做一般深度审查。
- [ ] 将 P0/P1/P2 发现写入复核记录；存在发现时退出准入流程。
- [ ] 在独立提交修复发现，重新运行全部 Gate 并生成新的固定候选。
- [ ] 一般深度审查达到 `P0=0/P1=0/P2=0` 后，交给 `ultra_gatekeeper`。
- [ ] 最终复核历史设计未改写、原件哈希未漂移、Schema 来源可追溯、回归和 CI 可复现。
- [ ] 根据最终门禁结果创建 Wave 1 准入裁决。
- [ ] 只有最终结果为 GO 时更新本卡和 Repository 的 Wave 1 状态。

## 5. 验证命令

```bash
git status --short --branch
git rev-parse HEAD
scripts/verify-wave0
git diff --check HEAD^ HEAD
bash tests/task-cards/verify-task-cards.sh
```

审查请求必须绑定 `git rev-parse HEAD` 返回的完整 commit，不接受浮动工作树。

## 6. Gate 与完成定义

GO 的必要条件：

- 前八个执行 Gate 全部为 `PASS`；
- 固定提交 CI 全绿；
- `deep_reviewer` 结果为 `P0=0/P1=0/P2=0`；
- `ultra_gatekeeper` 最终裁决为 GO；
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
CommitReview = DEEP_REVIEWER_THEN_ULTRA_GATEKEEPER
TerminalDecision = GO_OR_NO_GO
```

本卡只负责准入封口，不实现任何 Wave 1 功能。
