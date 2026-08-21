# W1-I07 治理 Oracle 来源路径修复

```text
RepairType = APPEND_ONLY_TEST_FIXTURE_CORRECTION
RepairOrigin = 28698e70bb0c0d2af674fd98c0964abe77c2e17c
AffectedProductionSemantics = NONE
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

wrong-order variant 已交换来源 SHA 与目标治理路径，但 blob 读取仍错误使用交换前的数组
索引，导致 `git show SHA:path` 在 verifier 调用前失败。唯一修复是让 blob 来源路径等于
variant 选定的治理路径。

从 `RepairOrigin` 追加本文、修正后的测试、生产验证器三步，形成精确 21 步链。测试
必须先在未提交的组合树上跑通全部 `4 positive / 44 negative`，再分别固定 test 与
verifier 提交；不得减少 mutation 或放宽 token。完整 Wave Gate 与一次 Sol/xhigh
finding-closure 复审仍为关闭投影前置条件。数据库写入、push 和 Ultra 均不授权。
