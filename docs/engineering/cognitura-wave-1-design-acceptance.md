# Cognitura Wave 1 详细设计验收记录

```text
DecisionDate = 2026-07-30
ReviewedCandidate = 17dabff23b029e1a6fc7f47155f552ed3f16d775
PriorReviewedCandidate = 3efe89fa532b7d58d7915dc891732dfdf5f4ee55
SupersededRepairCandidate = b1d4f78ed98fbe108358a8b07cc7681bea9ffd69
AcceptanceStatus = USER_APPROVED
UserApprovalDate = 2026-07-30
UserApprovedCandidate = 17dabff23b029e1a6fc7f47155f552ed3f16d775
Wave1DesignVerification = PASS
Wave0Regression = PASS
W1-DG0 DesignGovernance = PASS
W1-DG1 SourceDocumentContract = PASS
W1-DG2 DocumentBlockFidelityAndSafety = PASS
W1-DG3 ReparseAndReferenceCompatibility = PASS
W1-DG4 SourcePreviewAndAcceptance = PASS
W1-DG5 FixedDesignReview = PASS
Wave1DesignStatus = USER_APPROVED
ImplementationSlicingStatus = USER_APPROVED
ImplementationSlicingApprovalDate = 2026-07-30
ImplementationTaskCardPlanStatus = I02_DONE_I07_READY
BusinessImplementation = USER_AUTHORIZED
Wave1ImplementationTaskCardSet = READY_FOR_EXECUTION
ActiveImplementationGovernanceTaskCard = W1-I07
VisualStyleBaselineExecutionStateAuthority = docs/task-cards/visual-style-baseline/execution-state.md
ImplementationGovernanceReviewedCandidate = 0211679431de535dd4d89a08257b54d8f4e0da82
ImplementationGovernanceReviewVerdict = GO_P0_0_P1_0_P2_0
DirectFullImplementationStart = NO
RemotePush = NOT_PERFORMED
```

## 1. 固定候选

本记录接受的书面设计候选是
`17dabff23b029e1a6fc7f47155f552ed3f16d775`。候选包含 W1-D00 设计治理、
W1-D01 至 W1-D04 四份正式来源契约、任务卡和契约验证资产；不包含业务实现、
数据库 migration、Provider 选择、部署配置或 `raw/` 原件变更。

该候选关闭了 D00 候选完整性边界、D01 `PENDING` attempt 超时出口、D03
section-scoped consumer 边界，以及 lease expiry stale-observation CAS 缺口。
原 D00 对“实现任务卡建议清单”的过早要求已删除；实现切片仍必须等用户明确
批准完整设计后才可编制。

## 2. 历史一般深审

```text
GeneralReviewModel = gpt-5.6-sol
GeneralReviewReasoningEffort = high
GeneralReviewVerdict = READY
GeneralReviewP0 = 0
GeneralReviewP1 = 0
GeneralReviewP2 = 0
ReviewedCandidate = 3efe89fa532b7d58d7915dc891732dfdf5f4ee55
```

一般深审在三轮非零发现和对应修复提交之后，对新固定候选重新独立取证。最终轮
未复用旧候选结论，确认历次身份、状态、原子发布、partial acceptance、API、
alias、授权边界和 Gate coverage 发现均已关闭。

## 3. 历史独立最终门禁

```text
FinalGateModel = gpt-5.6-sol
FinalGateReasoningEffort = high
FinalGateVerdict = GO
FinalGateP0 = 0
FinalGateP1 = 0
FinalGateP2 = 0
ReviewedCandidate = 3efe89fa532b7d58d7915dc891732dfdf5f4ee55
UltraModel = NOT_USED
```

最终门禁由不同 reviewer 独立完成，不使用一般深审结论作为证据。它独立核对正式
来源、D00-D04、验证器、Wave 0 基线差异和禁止范围，并确认未发现 P0/P1/P2。

## 4. 历史候选可复现验证

固定候选使用 Node `24.18.0`、pnpm `11.17.0` 和 JDK `21.0.7` 完成：

```text
scripts/verify-wave1-design = PASS
SourceDocumentContractNegativeCases = 24
DocumentBlockContractNegativeCases = 24
ReparseReferenceContractNegativeCases = 25
SourcePreviewContractNegativeCases = 28
Wave1DesignTaskCardNegativeCases = 11
scripts/verify-wave0 = PASS
Wave0ExecutedStageCount = 7
GoldenCaseNegativeCases = 22
FormalInputsUnchanged = PASS
git diff --check = PASS
```

工作树在审查时仅保留用户未跟踪的 `.idea/`。本地提交未推送；远端 CI 不属于
本轮 D05 的验收前置。

## 5. 用户审阅修复候选验证

修复候选在固定提交前已使用 Node `24.18.0`、pnpm `11.17.0` 和 JDK `21.0.7`
完成：

```text
scripts/verify-wave1-design = PASS
SourceDocumentContractNegativeCases = 26
DocumentBlockContractNegativeCases = 24
ReparseReferenceContractNegativeCases = 27
SourcePreviewContractNegativeCases = 28
Wave1DesignTaskCardNegativeCases = 12
scripts/verify-wave0 = PASS
Wave0ExecutedStageCount = 7
GoldenCaseNegativeCases = 22
FormalInputsUnchanged = PASS
git diff --check = PASS
```

该验证形成了固定候选；其后的两阶段审查结果见下一节。

## 6. 修复候选审查循环

第一份修复候选的一般审查结果：

```text
ReviewedCandidate = b1d4f78ed98fbe108358a8b07cc7681bea9ffd69
GeneralReviewModel = gpt-5.6-sol
GeneralReviewReasoningEffort = high
GeneralReviewVerdict = NOT_READY
GeneralReviewP0 = 0
GeneralReviewP1 = 1
GeneralReviewP2 = 0
FinalGateStarted = NO
```

发现要求 lease expiry CAS 同时绑定 active attempt identity、generation、观察到的
attempt status 和 `leaseExpiresAt`；worker claim 或 heartbeat 改变 status/lease
后，旧超时决定必须失败并重新读取。该发现已进入下一修复候选，旧候选不得进入
最终 Gate。

第二份修复候选的双阶段结果：

```text
ReviewedCandidate = 17dabff23b029e1a6fc7f47155f552ed3f16d775
GeneralReviewModel = gpt-5.6-sol
GeneralReviewReasoningEffort = high
GeneralReviewVerdict = READY
GeneralReviewP0 = 0
GeneralReviewP1 = 0
GeneralReviewP2 = 0
FinalGateModel = gpt-5.6-sol
FinalGateReasoningEffort = high
FinalGateVerdict = GO
FinalGateP0 = 0
FinalGateP1 = 0
FinalGateP2 = 0
UltraModel = NOT_USED
```

两个 reviewer 相互独立并绑定同一固定候选。一般审查确认四项修复和对应负例均
闭合；最终 Gate 未复用一般审查结论，独立确认 W1-DG0 至 W1-DG5 可关闭。

## 7. 停止边界

用户已于 `2026-07-30` 明确批准本记录绑定的完整 Wave 1 书面设计候选，并批准
采用 14 张中细粒度任务卡方向，并已批准
[`Wave 1 实现切片设计`](../superpowers/specs/2026-07-30-wave1-implementation-slicing-design.md)。
任务卡 bootstrap 计划已完成；治理卡 I00 已对固定候选
`0211679431de535dd4d89a08257b54d8f4e0da82` 取得零发现深审并关闭。I01 已对固定候选
`6796079de8c919055ddc6538234254b50630a491` 取得零发现深审并关闭；I02 的独立
数据库 Gate 和固定候选深审均已通过，I02、I03、I04、I05 和 I06 已关闭；I07 为唯一 `READY` 卡。正式数据库、Parser/Object Storage Provider、
部署和远程推送均未授权。
