# Cognitura ModuleDefaultReadingState Execution State

```text
CanonicalProjectName = Cognitura
TaskCardSet = MODULE_DEFAULT_READING_IMPLEMENTATION
ExecutionStateVersion = 1
ExecutionStateAuthority = THIS_DOCUMENT
GovernanceBootstrapStatus = AWAITING_FIXED_COMMIT_REVIEW
GovernanceReviewedCandidateSHA = NONE
GovernanceReviewRoute = deep_reviewer
GovernanceReviewVerdict = NOT_RUN
SetAuthorizationStatus = USER_AUTHORIZED_AWAITING_GOVERNANCE_BOOTSTRAP
SetAuthorizationScope = MDR-I00..MDR-I08_AUTOMATIC_SERIAL
HumanCheckpointRequirement = NONE_WITHIN_AUTHORIZED_SET
TaskCardSetStatus = USER_AUTHORIZED_AWAITING_GOVERNANCE_REVIEW
ActiveImplementationTaskCard = NONE
ReleasedTaskCard = NONE
CompletedTaskCards = NONE
CurrentCandidateSHA = NONE
CurrentGateStatus = NOT_RUN
CurrentReviewRoute = NONE
CurrentReviewVerdict = NOT_RUN
NextImplementationTaskCard = MDR-I00
TransitionSequence = 0
TransitionKind = BOOTSTRAP
TransitionBaseSHA = NONE
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

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
