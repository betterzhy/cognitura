# W1-I07 审查负例 fixture staging 修复

```text
RepairType = APPEND_ONLY_TEST_FIXTURE_CORRECTION
RepairOrigin = d1b54a1aabc4982aeefd2749e5e85270947e4eb4
AffectedProductionSemantics = NONE
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. 失败事实

审查 Finding 修复的 43 负例矩阵在 receipt rename 用例中先执行 `git mv`，随后仍把
已不存在的原路径作为显式 `git add` pathspec，导致 fixture 在调用公共 verifier 前以
Git exit 128 中止。该失败不是产品或验证器行为证据。

## 2. 唯一修复

从 `RepairOrigin` 追加本文、测试修正、最终验证器三步单路径链。测试修正仅把该 rename
fixture 的 staging 改为仓库级 `git add -A`，以同时记录删除和新增；fixture 每次都从
固定干净提交重建，因此不会吸收额外状态。43 个负例、所有 mutation、预期 token 和
正式边界均不得减少或改变。

生产验证器只把 I07 治理身份扩为十五步，并继续验证每步单父、非空、精确路径、mode、
无 rename/copy/NUL，以及累计唯一写集。只有 4 正 / 43 负、完整 Wave Gate 和一次新的
Sol/xhigh 零 finding 复审全部通过后，才允许关闭投影。Ultra 仍不运行。
