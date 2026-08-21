# W1-I09 产品 copy 推断审查 Finding 修复

日期：2026-08-22

## 1. Finding

固定候选 `9d2ad2f2b58b8c2780f016c6404de1fd14db5aeb` 的最窄 copy 许可逻辑静态
边界成立，但 focused 合同只覆盖修复后的额外 copy、rename 与 WriteSet 越界，未按
Authority 实际构造以下三个真实 Git 变体：

1. 用相同产品树替换固定 `c934ff7` identity；
2. 在复制目标生成的同一提交中漂移两个 source；
3. 替换 repair spec 或 repair test 的 evidence blob。

因此固定候选为 `NO_GO / P1=1`；不得制作乐观收据或继续产品实现。

## 2. 最小 append-only 修复

```text
RejectedCandidate = 9d2ad2f2b58b8c2780f016c6404de1fd14db5aeb
RejectedParent = bd5f49fa62e47c45559feb0b64ea73a5c3ee0532
RejectedTree = 27dbab6a6bba8eb90b80324bb9e31deb4df7cbd0
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

从 RejectedCandidate 直接追加精确三步：

1. 本 spec；
2. `tests/task-cards/verify-wave1-implementation-cards.sh`；
3. `scripts/verify-wave1-implementation-cards`。

前两步固定 SHA/evidence blob。三步均单父、非空、单路径、正确 mode、无 R/C/NUL。
第三步稳定后重新执行一次 `deep_reviewer / sol xhigh`；不使用 Ultra，不重跑未变化
的完整 Wave Gate。

## 3. 独立 oracle

新增负例必须使用真实 Git object/commit，而不是字符串自证：

- 从固定 ProductParent 物化相同七路径产品树但以不同提交身份提交，必须被拒绝；
- 从固定 ProductParent 物化七路径，同时修改两条历史 source，必须被拒绝；
- 从固定 ProductCandidate 构造内容漂移的 repair spec，必须被拒绝；
- 从固定 repair spec 构造内容漂移的 repair test，必须被拒绝。

每个 fixture 都直接调用 production verifier，并断言稳定的 fail-closed 诊断。原 2 正／
3 负继续保留；新增后至少达到 2 正／7 负。

## 4. 边界

本修复不改变两条允许 pair、不新增 I09 product path、不修改 I08 或五路径投影，且不
授权正式数据库、部署、发布或远程推送。
