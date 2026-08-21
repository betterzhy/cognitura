# W1-I09 大 Blob JDBC Finding 修复

```text
RepairStatus = APPROVED_APPEND_ONLY
RejectedCandidate = 0a0c92b6357d07178c2e0c06d66388c61bd9a659
RejectedParent = 4b314aae4da6b1527af37f30fdeb1c7de08be636
RejectedTree = 482a2f3ac69359bb0c060da95fc68bcaa311437c
RejectedReviewVerdict = NO_GO
RejectedReviewP0 = 0
RejectedReviewP1 = 1
RejectedReviewP2 = 0
CorrectionChain = THIS_SPEC -> TEST -> VERIFIER
CorrectionReview = ONE_DEEP_REVIEWER_SOL_XHIGH
Ultra = NOT_RUN
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. Finding 与根因

被拒候选用 `git show ... | grep -Fq ...` 扫描合法产品 blob。脚本启用
`pipefail`；当大 blob 首部命中时，`grep -q` 提前退出，`git show` 因 SIGPIPE 非零，
整个 pipeline 被 `if` 误判为未命中。因此合法路径中的正式 JDBC 字面值仍可绕过。

## 2. 最小修复

1. 固定被拒 Candidate/Parent/Tree，只允许本 spec、test、verifier 三个单父、
   非空、单路径、正确 mode、无 R/C/NUL 的追加步骤；spec/test evidence 固定。
2. 保留 exact 27 路径检查；formal JDBC 扫描必须完整消费目标 blob，同时保留
   “任一命中即拒绝”的语义，不能依赖会让上游 SIGPIPE 的早停 pipeline。
3. focused 合同保留 3 正／15 负，并新增一个真实 Git 大 blob 负例：在允许的
   `SourceCommandRuntimeConfiguration.java` 首部写入正式 JDBC 字面值，再追加至少
   200,000 行 padding；必须命中
   `I09_RUNTIME_REBASELINE_FORMAL_DATABASE_LOCATION`。
4. 最终 verifier 候选由一次新的 `deep_reviewer / sol xhigh` 绑定为非递归信任根；
   GO 前不制作五路径 Authority projection。

## 3. 验证

```text
FocusedPositiveCases = 3
FocusedNegativeCases = 16
Bash32Syntax = PASS
CandidateStaticStatus = PENDING_PROJECTION
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

完整 Wave Gate 仍推迟到产品候选稳定后统一运行；本修复不授权正式数据库、部署、
远程推送，也不新增 Harness 或产品路径。
