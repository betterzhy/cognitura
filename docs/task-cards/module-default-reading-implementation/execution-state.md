# Cognitura ModuleDefaultReadingState Execution State

```text
CanonicalProjectName = Cognitura
TaskCardSet = MODULE_DEFAULT_READING_IMPLEMENTATION
ExecutionStateVersion = 1
ExecutionStateAuthority = THIS_DOCUMENT
GovernanceBootstrapStatus = PASS
GovernanceReviewedCandidateSHA = 07f8e588f9bbf69689b64e235a23eb3959824436
GovernanceReviewRoute = deep_reviewer
GovernanceReviewVerdict = GO_P0_0_P1_0_P2_0
SetAuthorizationStatus = USER_AUTHORIZED
SetAuthorizationScope = MDR-I00..MDR-I08_AUTOMATIC_SERIAL
HumanCheckpointRequirement = NONE_WITHIN_AUTHORIZED_SET
TaskCardSetStatus = BLOCKED_BY_DOCUMENTATION_GAP
ActiveImplementationTaskCard = NONE
ReleasedTaskCard = NONE
CompletedTaskCards = MDR-I00,MDR-I01,MDR-I02,MDR-I03,MDR-I04,MDR-I05,MDR-I06
CurrentCandidateSHA = 637cad53069cf417cbaa2a2bc8029d601bd972a4
CurrentGateStatus = PASS
CurrentReviewRoute = deep_reviewer
CurrentReviewVerdict = GO_P0_0_P1_0_P2_0
NextImplementationTaskCard = MDR-I07
TransitionSequence = 8
TransitionKind = BLOCK_DOCUMENTATION_GAP
TransitionBaseSHA = 92a0cfdcdde7c4fdaf7b3e1349f52f5fb069ac32
BusinessImplementation = AUTHORIZED_FOR_MDR_I00_I08
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

当前恢复点为 `MDR-I07`。其 RED 要求 `data-reading-section` 前缀为
`questions → conclusion → spine`，但已经固定审查通过的 `MDR-I02` 组件及测试使用
`core-questions → core-conclusion → primary-spine`；`MDR-I07` 精确写集不包含前序组件，
不能同时保持前序唯一 section 与当前 exact-order 断言。恢复前必须先形成获授权的任务卡
裁决，统一这三个 section identity；不得通过重复包装、越界修改前序卡或复制认知投影绕过。

本文件是 `MDR-I00..MDR-I08` 唯一可变运行态权威。AGENTS、中央索引、卡集索引和
逐卡正文只能引用本文件，不得复制 Active、READY、DONE、授权或审查收据事实。

允许的集合状态只有：

```text
USER_AUTHORIZED_AWAITING_GOVERNANCE_REVIEW
IN_PROGRESS
STOPPED_BY_USER
BLOCKED_BY_DOCUMENTATION_GAP
BLOCKED_BY_AUTHORITY_EXPANSION
FINAL_NO_GO
COMPLETE
```

bootstrap 固定提交取得 `deep_reviewer = GO / P0=0 / P1=0 / P2=0` 前，本账本必须
保持九卡阻断、Active/Released 为 `NONE`、业务实现未授权。bootstrap 通过后，用户
已给出的集合级授权只允许从 `MDR-I00` 开始，按严格前缀依赖串行推进。

每个业务候选只能修改当前卡精确 `WriteSet`。候选通过 Gate 和固定 SHA 独立审查后，
另建只修改本文件的状态提交，记录业务候选 SHA、Gate、审查路由、审查裁决、完成
前缀和唯一后继。状态提交禁止 amend、push、Schema/数据库/后端/路由/`raw/**` 写入。

`STOPPED_BY_USER`、`BLOCKED_BY_DOCUMENTATION_GAP`、
`BLOCKED_BY_AUTHORITY_EXPANSION` 和 `FINAL_NO_GO` 均不得保留活动或已释放卡。
`COMPLETE` 必须恰好完成九卡且不得释放任何后续 Schema、数据库、页面或 Wave 1
source 卡。
