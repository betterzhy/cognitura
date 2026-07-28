# W0-05 Golden Case 回归资产

```text
TaskCardID = W0-05
Status = DONE
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
- Modify（用户持续执行授权的生命周期同步）:
  `docs/task-cards/W0-07-test-and-ci.md`
- Modify（用户持续执行授权的根状态同步）: `AGENTS.md`
- Modify（用户持续执行授权的根状态同步）: `README.md`

所有解析派生物必须位于 `test-data/` 或测试临时目录，不得回写 `raw/`。

## 4. 执行步骤

- [x] 编写原件哈希漂移、标题顺序变化、段落顺序变化、分页位置变化、表格丢失、
  图片引用丢失、外链目标变化、外链访问、符号链接逃逸、ZIP 资源越界和断言
  策略弱化测试。
- [x] 运行测试并确认回归资产未实现时因缺少可执行验证器而失败。
- [x] 建立绑定来源 manifest SHA-256 的三份 expected 文件。
- [x] 编码 MySQL 闭环及 MVCC、Read View、隐藏列和单锁类型不得全部升级的断言。
- [x] 编码 Redis 线程模型聚合及 `beforeSleep = MustNotPromote`。
- [x] 编码英语五大句型判定路径及例句不得升级的断言。
- [x] 将八组 expected 断言应用到三份候选结果契约夹具，并为每组断言建立
  独立失败样例；契约夹具只验证回归引擎，不冒充 Wave 1 生成产物。
- [x] 验证解析保留标题、段落、表格行列与单元格、图片引用、分页符和原始顺序。
- [x] 在隔离临时目录运行离线回归，证明 Redis 的 4 个遗留外链仅被计数且
  目标指纹保持一致，JDK 21 I/O Guard 报告 `ExternalLinksAccessed = 0`，
  且 canary 访问探针被拒绝。
- [x] 更新任务卡状态，记录固定候选深审 GO，并形成独立生命周期提交。

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

固定候选前执行证据：

```text
ObservedRedBoundary = missing executable verifier
  → missing result assertion mode
  → external access guard inactive
  → symlink escape accepted
  → repository-internal raw symlink escape accepted
  → PASS
CaseCount = 3
ExecutableAssertionGroupCount = 24
StructuralBaselineCount = 3
PositiveCases = 3
PositiveResultFixtures = 3
AssertionNegativeCases = 8
BaselineNegativeCases = 13
AccessIsolationNegativeCases = 1
NegativeCases = 22
ExternalLinksObserved = 4
ExternalLinksAccessed = 0
ExternalAccessGuard = ACTIVE
FormalInputsUnchanged = PASS
W0-G4 CandidateStatus = PASS
```

总体设计没有为三个 Case 分别指定 `ExpectedRole` 和
`ExpectedThemeClosure` 的具体值，也没有给出 MySQL、Redis 的 case 级
`ExpectedSpine` 路径。因此对应字段以
`SOURCE_GAP / NOT_ASSERTED` 作为可执行预期，并在每个 Case 的
`KnownSourceGaps` 中显式登记；英语 `ExpectedSpine` 保留总体设计明确给出的
判定路径。MySQL 的 promotion 约束使用 `NOT_ALL` 集合语义，没有把它错误解释为
四项分别绝对禁止。

```text
W0-G4 GoldenCaseRegression = PASS
```

## 7. 提交与审查

```text
CommitMessage = test: add Cognitura golden case regression baseline
CommitReview = MAIN_AGENT_GATE
AdditionalFixedCommitReview = DEEP_REVIEWER_FIXED_COMMIT
PreviousFixedImplementationReview = a613db348bd312a73b34c924d270778f7c93a92f|NO_GO|P0=0|P1=4|P2=2
PreviousRealpathReview = 1edca85f52f344035056be6b56ae485abdb7b8f1|NO_GO|P0=0|P1=1|P2=0
FixedImplementationReview = 608a98cdfc6353084798f0c6a3e131ec2a9e32ea|GO|P0=0|P1=0|P2=0
NextTaskCardOnPass = W0-07
```

原件内容与总体设计预期冲突时记录 `KnownSourceGap`，不得静默补写原文。
