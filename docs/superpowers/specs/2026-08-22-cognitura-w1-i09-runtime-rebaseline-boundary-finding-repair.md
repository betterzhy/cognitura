# W1-I09 运行时重基线边界 Finding 修复

```text
RepairStatus = APPROVED_APPEND_ONLY
RejectedCandidate = 1544af3407d94b57bc6390f3e8a6e55cd056abdf
RejectedParent = 390725450f4d52aa26a8d24eb100716d39b2b539
RejectedTree = a314a1e7678c317c6e209bea7df4e2a88bfd96bd
RejectedReviewVerdict = NO_GO
RejectedReviewP0 = 0
RejectedReviewP1 = 2
RejectedReviewP2 = 0
CorrectionChain = THIS_SPEC -> TEST -> VERIFIER
CorrectionReview = ONE_DEEP_REVIEWER_SOL_XHIGH
Ultra = NOT_RUN
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. Finding

被拒候选只在 `application.yaml` 中拒绝字面 `jdbc:postgresql://`，因此允许的 Java、
SQL、测试或 fixture 路径仍可携带正式／共享数据库位置并通过产品后代校验。

原 focused 合同虽然证明五路径投影会逐字拒绝部分漂移，但没有分别构造
`RemotePush = AUTHORIZED`、I09 不再唯一 `READY`、`TaskCardCount` 或
`ReadyTaskCardCount` 漂移的真实 Git 负例，不能以实现推断代替 R2 独立 oracle。

## 2. 根因与边界

根因不是 27 路径写集过宽，而是正式数据库位置检查错误地绑定到一个文件名；
`ForbiddenWriteSet = FORMAL_DATABASE_CONNECTION_OR_WRITE` 是整个 I09 产品后代的
内容边界。检查必须覆盖每个发生变化的允许产品 blob，不得只检查 YAML。

修复不扩大产品写集、不新增 Harness、不改写前序候选、不制作 Authority projection，
也不授权正式数据库、部署或远程推送。

## 3. 最小修复

1. 固定被拒候选的 Candidate/Parent/Tree，并证明它是当前修复链的直接起点。
2. 只允许本 spec、focused test、verifier 三个单父、非空、单路径、正确 mode、
   无 R/C/NUL 的 append-only 修复步骤；spec/test evidence blob 固定。
3. 产品后代的每个变化路径仍须属于原 exact 27；对每个变化后的 blob 搜索字面
   `jdbc:postgresql://`，任一命中均以
   `I09_RUNTIME_REBASELINE_FORMAL_DATABASE_LOCATION` fail closed。
4. focused 合同保留原 3 正／10 负，并新增五个独立真实 Git 负例：
   - 合法 Java 路径携带正式 JDBC 字面值；
   - `RemotePush = AUTHORIZED`；
   - I09 不再是唯一 `READY`；
   - `TaskCardCount` 漂移；
   - `ReadyTaskCardCount` 漂移。
5. 新 verifier 最终候选由一次 `deep_reviewer / sol xhigh` 绑定
   Candidate/Parent/Tree，作为非递归外部信任根；GO 前不得制作五路径投影。

## 4. 验证

```text
FocusedPositiveCases = 3
FocusedNegativeCases = 15
Bash32Syntax = PASS
CandidateStaticStatus = PENDING_PROJECTION
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

完整 Wave Gate 继续推迟到产品候选稳定后统一运行；本修复只运行能够证伪当前
边界的 focused、显式投影路由、static 和 `git diff --check`。
