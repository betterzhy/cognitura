# W0-07 测试与 CI 基线

```text
TaskCardID = W0-07
Status = READY
Gate = W0-G5 TestAndCI
Risk = HIGH
DependsOn = W0-03,W0-04,W0-05,W0-06
ReviewRoute = MAIN_AGENT_GATE
ExecutionStatus = IN_PROGRESS
CIProvider = GITHUB_ACTIONS
LocalVerification = PASS
FixedCommitCI = NOT_RUN
CIURL = NOT_AVAILABLE
```

## 1. 目标

将全部 Wave 0 校验统一纳入本地可重复入口和 CI，使来源、任务卡、Markdown
链接、Schema、Golden Case、页面契约、server 与 web 构建在每次提交上自动执行。

## 2. 前置条件与输入

- `W0-G2A BuildBaseline = PASS`
- `W0-G3 JsonSchemaValidation = PASS`
- `W0-G4 GoldenCaseRegression = PASS`
- `W0-G4A UiContractValidation = PASS`
- 所有 Wave 0 校验脚本和 lockfile

CI Provider 必须在本卡执行时形成明确工程裁决，且不得获得正式数据库写权限。

## 3. 写集

- Create: CI workflow
- Create: `docs/engineering/cognitura-test-strategy.md`
- Create: `scripts/verify-wave0`
- Create: `tests/ci/`
- Modify: dependency cache and lock configuration
- Modify: `README.md`
- Modify: `docs/task-cards/README.md`
- Modify: `docs/task-cards/W0-07-test-and-ci.md`
- Modify: `docs/task-cards/W0-08-fixed-commit-review.md`
- Modify: `docs/engineering/cognitura-wave-0-plan.md`
- Modify: `docs/engineering/cognitura-wave-0-entry-decision.md`

不得在 CI 中配置正式数据库、生产对象存储或发布凭据。

## 4. 执行步骤

- [x] 先编写 CI 等价测试，故意破坏临时 source hash 并要求总入口失败。
- [x] 运行测试，确认统一入口或 workflow 不存在时失败。
- [x] 创建 `scripts/verify-wave0`，按固定顺序运行来源、任务卡、Schema、Golden Case、
  UI、server 和 web 校验。
- [x] 创建 CI job，使用 lockfile 缓存键且不使用浮动依赖。
- [x] 配置 PostgreSQL 18 临时测试容器，不连接正式数据库。
- [x] 验证 workflow 不修改 `raw/`、不访问 Redis 遗留链接、不执行正式数据库写入。
- [x] 运行本地完整入口并核对日志和失败传播。
- [ ] 将候选提交推送到关联 remote，取得固定提交 CI 成功结果和可追溯 URL。
- [ ] 在真实 CI 通过后更新 Gate、关闭本卡并形成独立状态提交。

## 5. 验证命令

```bash
bash tests/ci/verify-markdown-links.sh
bash tests/ci/verify-ci-contract.sh
scripts/verify-wave0
bash tests/task-cards/verify-task-cards.sh
git diff --check
```

CI 使用与 `scripts/verify-wave0` 相同的命令入口，禁止维护第二套隐式验证流程。

## 6. Gate 与完成定义

- source、task-card、Schema、Golden Case、UI、server、web 七组验证均被执行；
- 任一子验证失败会使本地总入口和 CI 返回非零；
- 缓存键绑定 lockfile；
- CI 无正式环境写权限且不访问遗留链接；
- 本地等价命令和固定提交 CI 全绿。

当前执行证据：

```text
MarkdownLinkContractTests = PASS
CiContractTests = PASS
SourceFailurePropagation = PASS
Wave0Verification = PASS
ExecutedStageCount = 7
W0-G5 TestAndCI = IN_PROGRESS
FixedCommitCI = NOT_RUN
CIURL = NOT_AVAILABLE
```

本地通过不构成 Gate 关闭。只有固定提交 CI 成功并记录可访问 URL 后，才允许
把当前状态替换为：

```text
W0-G5 TestAndCI = PASS
```

## 7. 提交与审查

```text
CommitMessage = ci: establish Cognitura Wave 0 quality gates
CommitReview = MAIN_AGENT_GATE
NextTaskCardOnPass = W0-08
```

CI 未实际运行或缺少可追溯 URL 时不得标记本卡完成。
