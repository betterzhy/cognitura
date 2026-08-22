# Cognitura W1-I09 最终审查 Finding 修复

```text
Status = APPROVED_FOR_EXECUTION
Risk = R2_FIXED_CANDIDATE_FINDING_CLOSURE
RejectedCandidate = f0fa4aaee25b66d0e916683e2ed938dac5305c85
RejectedParent = 665fbdb7929441afd0b81635e2ea5855ee86272f
RejectedTree = 313f075aa4876bbe0f8e3cbdd9cb1d654cde634b
RejectedVerdict = NO_GO
RejectedP0 = 0
RejectedP1 = 2
RejectedP2 = 0
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. Findings

最终固定候选审查确认两条 P1：

1. I08 historical fixture pin 与 V2 post-product fixture pin 只限制路径、mode、NUL
   和后继 test evidence，没有绑定各自 verifier commit identity；替代 verifier 可在受限
   位置被接纳。
2. 本地 CAS 使用 `exists + Files.move(ATOMIC_MOVE)`，而 JDK 对原子移动到已存在目标
   的 replace/fail 行为不作跨实现保证；同 digest 并发写入可能替换不可变目标。

I09 保持唯一 `READY`，不得制作 I09 关闭投影或释放 I10。

## 2. 最小治理修复链

从 `RejectedCandidate` 起只允许三个连续、单父、非空、单路径提交：

1. 本文件，mode `100644`；
2. `tests/task-cards/verify-wave1-implementation-cards.sh`，mode `100755`；
3. `scripts/verify-wave1-implementation-cards`，mode `100755`。

三步禁止 merge、rename/copy、NUL、额外路径和 mode 漂移。第三步必须绑定前两步的
完整 commit identity 与 evidence blob。完成后只恢复 I09 Exact29 产品写集；不得开放
通用治理脚本后继。

聚焦真实 Git 合同至少包含两个 substituted-verifier 负例：

- 固定 I08 test commit 后替换 verifier；
- 固定 V2 origin 后替换 verifier，再提交合法 fixed test blob。

二者必须分别命中稳定的 verifier identity 诊断；不能被路径、计数或其他无关早退吸收。

## 3. CAS no-replace 修复

CAS 先完整流式写入并关闭同文件系统临时文件，再通过原子 create-if-absent 发布完整
文件。发布操作必须满足：

- 目标不存在时恰有一个 winner；
- 目标已存在时绝不替换，只读校验长度与 digest 后复用；
- 并发同 digest 写入恰有一个 `reused=false`，其余均为 `reused=true`；
- 不支持原子 no-replace 的文件系统 fail closed；
- 任意失败清理本次临时文件，不泄漏绝对路径。

允许使用同文件系统 hard-link 创建目标目录项：临时文件在发布前已关闭且内容完整，
`createLink(target, temporary)` 对目标执行原子 create-if-absent，不依赖
`ATOMIC_MOVE` 的实现相关 replace 语义；成功后删除临时路径。禁止 copy+delete、覆盖
rename 或先创建可观察的空目标。

RED 必须在旧实现上稳定证明并发同 digest 出现多个非复用 winner；GREEN 必须证明
唯一 winner、字节不变和临时文件清理。

## 4. 完成条件

```text
SubstitutedVerifierNegatives = PASS
ConcurrentCasNoReplace = PASS
FocusedI09 = PASS
ServerRegression = PASS
Wave1ImplementationGate = PASS
FixedCandidateReview = GO_WITH_P0_P1_P2_ZERO
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```
