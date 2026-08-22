# Cognitura W1-I11 关闭后历史 fixture 固定修复

```text
ChangeRisk = R2
RepairOrigin = 33922db113024338d742aa1fc2d7ef43e3701b99
Failure = I11_MIGRATION_COUNT_REBASELINE_INVALID:evidence
Scope = SHARED_TEST_FIXTURE_PIN_ONLY
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

I11 关闭后的完整 Gate 发现，历史 migration-count focused fixture 通过 `HEAD` 动态选择
共享测试脚本的最后一次修改。I11 关闭合同追加测试后，该 fixture 把新脚本错误当成历史
`d50964535dd928abdbe077198d4108e8982eba5d` evidence，导致合法历史治理链被拒绝。

本修复只把 `i11_migration_count_test_sha()` 固定返回上述已审历史提交，不修改产品、
关闭投影或正式状态。修复使用三个 append-only 单路径提交：本说明、共享测试脚本、
生产验证器；每步要求单父、非空、正确 mode、无 rename/copy/NUL，前两步绑定 evidence
blob。生产验证器必须先重验 I11 关闭治理与 exact11 收据，再验证本 exact3 修复，随后
继续只允许 I12 exact WriteSet。

验证只运行：Bash 3.2 syntax、I11 migration-count focused 2+/6-、I11 closure focused
2+/9-、静态状态、`git diff --check`，然后对固定修复候选执行一次 xhigh 审查。完整 Wave
Gate 只在修复候选通过后从头重跑一次；不得把失败的中断输出计为证据，不得引入通用
Harness、正式数据库写入或远程推送。
