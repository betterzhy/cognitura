# W1-I09 产品 copy 修复 verifier 重入 Finding

日期：2026-08-22

## 1. Finding

`9d2ad2f2b58b8c2780f016c6404de1fd14db5aeb` 及其首轮 finding closure 允许在
`VERIFIER`／`FINDING_VERIFIER` 状态继续接受任意数量的 verifier-only 提交。虽然每步
仍受单父、单路径、mode、R/C/NUL 限制，但这违反“固定三步链”的闭集要求，也使审查
后的治理路径能够重新进入。

首轮 finding closure 候选固定为：

```text
RejectedCandidate = 1bfa84cd2bcd895ea946ca0f200354be251990f9
RejectedParent = 4fef5ed3f755c0d277b2b93a1bbae92e22a763a0
RejectedTree = 8a18e6d3dcc7ec8c4f4240c37550fc3920f38883
P0 = 0
P1 = 1
P2 = 0
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 2. 最小修复

从 RejectedCandidate 直接追加：

1. 本 spec；
2. `tests/task-cards/verify-wave1-implementation-cards.sh`；
3. `scripts/verify-wave1-implementation-cards`。

前两步固定 SHA/evidence blob；三步均单父、非空、精确单路径、正确 mode、无
R/C/NUL。最终状态机规则：

- `TEST` 只接受一个 verifier step；
- `FINDING_TEST` 只接受一个 verifier step；
- `REENTRY_TEST` 只接受一个 verifier step；
- 任一完成态遇到后继时先退出治理态，再按严格 I09 product WriteSet 校验；
- 因而任何再次修改 verifier/test/spec 都必须失败。

## 3. 独立 oracle

保留现有 2 正／7 负，并新增一个真实 Git 负例：从最终修复 tip 追加单路径、100755、
无 R/C/NUL 的 verifier-only 提交，production verifier 必须以
`I09_RUNTIME_REBASELINE_PRODUCT_INVALID:path` 拒绝。该用例不能依赖空提交、额外路径
或 mode/NUL 早退。

最终候选重新执行一次 `deep_reviewer / sol xhigh`；不使用 Ultra，不重复完整 Wave
Gate。本修复不改变产品、I08、五路径投影、数据库或 push 边界。
