# W1-I07 关闭候选审查 Finding 修复

```text
RepairType = APPEND_ONLY_REVIEW_FINDING_REPAIR
RepairOrigin = a1312b46d42b53ac8bcaa9b38774a123932274b6
ReviewVerdict = NO_GO
ReviewFinding = P1_REQUIRED_NEGATIVE_MATRIX_INCOMPLETE
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. Finding

固定候选 `RepairOrigin` 的实现与现有 18 个负例均通过，但原关闭设计第 7 节要求的
完整独立负例矩阵没有全部落入公共 verifier 的真实 Git fixture。缺失项包括治理顺序、
重复/空提交、rename、mode/NUL、前置投影漂移、替代 origin、非直系收据、后继状态与
active/count、push、完整 Candidate/Parent/Tree、非零 finding、Ultra、重复/第二次关闭
以及投影 introduce-restore。

这是证据完整性 P1；在修复前不得制作十二路径关闭投影。

## 2. 精确修复链

从 `RepairOrigin` 只允许追加三步单父、非空、精确单路径链：

1. 本说明；
2. `tests/task-cards/verify-wave1-implementation-cards.sh`：把缺失类别加入真实共享 Git
   fixture，并固定为 `4` 个正例、`43` 个负例；
3. `scripts/verify-wave1-implementation-cards`：只把 I07 治理身份扩为十二步，并保持
   所有既有 fail-closed 检查不变；若新增 RED 暴露真实缺陷，可在同一路径内作最小
   GREEN 修复。

每步必须验证 mode、无 rename/copy/NUL；累计唯一治理写集只新增本文，重复 test 与
verifier 路径必须去重。不得改写既有九步历史、I07 产品候选或十二路径投影。

## 3. 必须新增的独立负例

- 治理：wrong order、repeated path、empty、rename、mode、NUL、predecessor projection
  drift、substituted origin；
- 收据/状态：non-direct、rename、I08 非 READY、I09 非 QUEUED、active mismatch、
  ready-count mismatch、push drift；
- 审查身份：wrong product Parent/Tree、wrong governance Candidate/Parent、nonzero finding、
  Ultra、duplicate receipt；
- 历史：second closure、post-receipt projection mutation、projection introduce-restore。

## 4. 完成条件

聚焦合同必须在 Bash 3.2 下输出 `4 positive / 43 negative` 并零退出；完整 Wave Gate
必须零退出。随后对新固定 Candidate/Parent/Tree 进行一次 `deep_reviewer / Sol xhigh`
复审；只有 P0/P1/P2 全零 `GO` 才允许制作正式关闭投影。Ultra 仍为 `NOT_RUN`。
