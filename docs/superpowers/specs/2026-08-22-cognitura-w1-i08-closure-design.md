# Cognitura W1-I08 最小关闭设计

```text
Status = APPROVED_FOR_EXECUTION
Risk = R2_GOVERNANCE_TRANSITION
ClosureOrigin = 4890c8ec6af72e57e696845e8fc06a5552aafd45
ReviewedCandidate = 4890c8ec6af72e57e696845e8fc06a5552aafd45
ReviewedParent = c06ea6ed7efcb2ef04c085e3976d42814af0b3ea
ReviewedTree = 7db68e968432b8b7218a63aba9ea06d6a93a5782
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
Ultra = NOT_RUN
BusinessImplementationAuthorization = USER_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. 目的

W1-I08 的 Exact8 产品候选已经完成 RED→GREEN、真实 PostgreSQL 回归和一次适用的
固定候选 `deep_reviewer/xhigh` 零 finding 审查。本设计只负责把该已审事实原子投影为
`W1-I08 = DONE`，并把依赖已满足的 `W1-I09` 释放为唯一 `READY` 卡。

本次不新增通用 Harness、registry、checkpoint、恢复框架或第二套运行态事实；也不复制
W1-I07 的历史 21 步修复链。

## 2. 最小治理链

从 `ClosureOrigin` 起只允许三个连续、单父、非空、单路径提交：

1. 本设计：
   `docs/superpowers/specs/2026-08-22-cognitura-w1-i08-closure-design.md`，mode `100644`；
2. 关闭合同测试：
   `tests/task-cards/verify-wave1-implementation-cards.sh`，mode `100755`；
3. 生产 verifier：
   `scripts/verify-wave1-implementation-cards`，mode `100755`。

三步均禁止 merge、空提交、rename/copy、NUL、额外路径和 mode 漂移。第三步必须绑定前
两步 evidence blob；最终组合候选只做一次 `deep_reviewer/xhigh` 审查。

## 3. 原子关闭投影

治理候选取得 GO 后，只允许一个直接子提交修改以下 11 个既有权威投影：

```text
AGENTS.md
README.md
docs/design/wave-1/README.md
docs/engineering/cognitura-design-index.md
docs/engineering/cognitura-wave-1-design-plan.md
docs/engineering/cognitura-wave-1-design-acceptance.md
docs/engineering/cognitura-wave-1-implementation-plan.md
docs/task-cards/wave-1/README.md
docs/task-cards/wave-1-implementation/README.md
docs/task-cards/wave-1-implementation/W1-I08-stable-reference-reparse-lineage.md
docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md
```

投影后的唯一状态向量为：

```text
TaskCardSetStatus = READY_FOR_EXECUTION
ActiveTaskCard = W1-I09
ReadyTaskCardCount = 1
W1-I07 = DONE
W1-I08 = DONE
W1-I09 = READY
W1-I10 = BLOCKED_BY_DEPENDENCY
W1-I09.BusinessImplementationAuthorization = USER_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

实施计划末尾必须追加唯一且位于 EOF 的 `## 15. I08 关闭收据`，逐字绑定本设计顶部的
Candidate/Parent/Tree、审查 route/effort/multiplicity/verdict/findings，并记录：

```text
W1-I08 = DONE
I08ClosureReleasedTaskCard = W1-I09
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

I08 产品 Exact8 必须从 `ReviewedCandidate` 起保持字节冻结；关闭投影不得改 I07、I10
或任何产品文件。关闭提交之后只允许 W1-I09 任务卡声明的 Exact WriteSet 后继。

## 4. 合同测试

聚焦合同只保留能够证伪关闭不变量的最小矩阵：

- 正例 2 个：合法直接关闭的显式 transition；合法关闭后的静态状态；
- 负例 6 个：错误 review receipt；不完整/多 READY 状态向量；治理链额外路径或
  rename/copy/空提交；投影额外路径；I08 产品漂移；关闭后越过 I09 WriteSet。

每个负例必须越过无关的 commit-count 早退并命中相应生产 guard；不得用 fixture 自身
判断代替 production verifier。

## 5. 完成条件

```text
FocusedClosureContract = PASS
Bash32Syntax = PASS
StaticAndExplicitRoute = PASS
GitDiffCheck = PASS
FixedGovernanceCandidateReview = GO_WITH_P0_P1_P2_ZERO
Exact11Projection = PASS
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```
