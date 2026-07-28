# W0-05 Golden Case 回归资产

```text
TaskCardID = W0-05
Status = READY
Gate = W0-G4 GoldenCaseRegression
Risk = HIGH
DependsOn = W0-01,W0-04
ReviewRoute = MAIN_AGENT_GATE
```

## 1. 目标

把 MySQL、Redis 和英语三份 Golden Case 的结构质量要求变成绑定原件哈希、
可离线执行的回归断言，同时保护标题、段落、表格、图片引用和原始顺序。

## 2. 前置条件与输入

- `W0-G1 DesignSourceRegistry = PASS`
- `W0-G3 JsonSchemaValidation = PASS`
- `raw/11-MySQL数据库.docx`
- `raw/12-Redis中间件.docx`
- `raw/40-英语学习.docx`
- 总体设计 Golden Case 与质量章节

三份 DOCX 是只读原件；Redis 遗留 `file:///` 链接目标不是输入。

## 3. 写集

- Create: `test-data/golden-cases/manifest.yaml`
- Create: `test-data/golden-cases/mysql.expected.yaml`
- Create: `test-data/golden-cases/redis.expected.yaml`
- Create: `test-data/golden-cases/english.expected.yaml`
- Create: `tests/golden-cases/`
- Create: `scripts/verify-golden-cases`
- Modify: `docs/task-cards/README.md`
- Modify: `docs/task-cards/W0-05-golden-case-regression.md`
- Modify: `docs/engineering/cognitura-wave-0-plan.md`
- Modify: `docs/engineering/cognitura-wave-0-entry-decision.md`

所有解析派生物必须位于 `test-data/` 或测试临时目录，不得回写 `raw/`。

## 4. 执行步骤

- [ ] 编写原件哈希漂移、标题顺序变化、表格丢失、图片引用丢失和链接访问失败测试。
- [ ] 运行测试并确认回归资产未实现时失败。
- [ ] 建立绑定源 manifest SHA-256 的三份 expected 文件。
- [ ] 编码 MySQL 闭环及 MVCC、Read View、隐藏列和单锁类型不得全部升级的断言。
- [ ] 编码 Redis 线程模型聚合及 `beforeSleep = MustNotPromote`。
- [ ] 编码英语五大句型判定路径及例句不得升级的断言。
- [ ] 验证解析保留标题、段落、表格单元格、图片引用和原始顺序。
- [ ] 在隔离环境运行离线回归，证明没有访问 Redis 遗留本地链接。
- [ ] 更新任务卡状态并形成独立提交。

## 5. 验证命令

```bash
scripts/verify-golden-cases
bash tests/golden-cases/verify-golden-cases.sh
bash tests/task-cards/verify-task-cards.sh
git diff --check
```

测试必须使用临时目录，并在退出时删除派生物；正式原件哈希在测试前后必须相同。

## 6. Gate 与完成定义

- 三个 Case ID 唯一且绑定来源 manifest；
- MustInclude、MustMerge、MustNotSplit、MustNotPromote、ExpectedRole、
  ExpectedSpine、ExpectedThemeClosure、KnownSourceGaps 均可执行；
- 原始结构保存验证通过；
- Redis 链接没有发生网络或本地文件访问；
- 正例、反例、任务卡集合验证全部通过。

```text
W0-G4 GoldenCaseRegression = PASS
```

## 7. 提交与审查

```text
CommitMessage = test: add Cognitura golden case regression baseline
CommitReview = MAIN_AGENT_GATE
NextTaskCardOnPass = W0-07
```

原件内容与总体设计预期冲突时记录 `KnownSourceGap`，不得静默补写原文。
