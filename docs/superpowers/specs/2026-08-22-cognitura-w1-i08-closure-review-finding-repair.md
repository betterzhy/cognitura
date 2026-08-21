# Cognitura W1-I08 关闭审查 Finding 修复

```text
Status = APPROVED_FOR_EXECUTION
Risk = R2_GOVERNANCE_TRANSITION
RejectedGovernanceCandidate = 6dfc075be803277c695b729001997345c512c34d
RejectedGovernanceParent = a5bd6d1d57a8d1f009817038b2ccdd38afe63587
RejectedGovernanceTree = 8e82c17c1c21c0cc8bd4a88a17d4ecfe640f3252
RejectedVerdict = NO_GO
RejectedP0 = 0
RejectedP1 = 2
RejectedP2 = 1
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. Finding

固定候选 `6dfc075...` 的一次适用 `deep_reviewer/xhigh` 审查确认：三步链、Exact8
冻结、Bash 3.2 和既有 2+/6- 合同均有效，但存在两条 P1：

1. Exact11 只限制文件路径，没有证明每个 Authority 文件只发生预定状态投影；
2. 第三步 verifier tip 未固定，等价路径链可复用动态 GO 收据。

另有一条 P2：关闭实现累计过重，不得继续复制 I07 结构或引入通用 Harness。

## 2. 非递归信任边界

原三步治理 tip 必须精确等于 `6dfc075...`。从该提交起只允许三个连续、单父、非空、
单路径修复提交：

1. 本 finding 修复，mode `100644`；
2. `tests/task-cards/verify-wave1-implementation-cards.sh`，mode `100755`；
3. `scripts/verify-wave1-implementation-cards`，mode `100755`。

三步均禁止 merge、空提交、rename/copy、NUL、额外路径和 mode 漂移。最终 correction
tip 必须再接受一次 `deep_reviewer/xhigh` 固定候选审查。获授权操作者只落地该固定 SHA
是仓库外信任根；仓库内 verifier 只证明链、内容变化和收据自洽，不伪称能够证明外部
审查真实性，也不追加递归的“绑定最终 verifier”提交。

## 3. Exact11 内容闭集

关闭投影仍严格为原设计的 11 个文件，但必须从 correction tip 物化唯一预期内容并逐字
比较。只允许以下变化：

- Active 卡从 I08 改为 I09；
- I08 状态从 READY 改为 DONE；
- I09 状态从 QUEUED 改为 READY，BusinessImplementationAuthorization 改为
  USER_AUTHORIZED；
- 实施计划末尾追加唯一 I08 收据；
- 与上述状态等价的既有叙述只做固定字面替换。

其余内容全部字节冻结，尤其禁止改变 FormalDatabaseWrite、RemotePush、部署授权、I09
WriteSet、ForbiddenWriteSet、安全合同、I10 状态或任何产品文件。

## 4. 修复合同

在原 2+/6- 矩阵上至少新增两个能够越过路径检查的真实 Git 负例：

- 在 Exact11 内把 FormalDatabaseWrite 或 DeploymentAndRelease 改为 AUTHORIZED；
- 在 I09 卡内修改 WriteSet 或安全约束。

二者都必须命中 `I08_CLOSURE_PROJECTION_MISMATCH`。合法显式与静态关闭继续通过。

## 5. 收据

关闭投影必须是最终 correction tip 的直接子提交。EOF 收据同时记录：

```text
ReviewedGovernanceCandidate = 6dfc075be803277c695b729001997345c512c34d
ReviewedVerifierCorrectionCandidate = <FINAL_CORRECTION_TIP>
ReviewedVerifierCorrectionParent = <FINAL_CORRECTION_PARENT>
ReviewedVerifierCorrectionTree = <FINAL_CORRECTION_TREE>
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
```

正式数据库写入和远程推送继续保持未授权。
