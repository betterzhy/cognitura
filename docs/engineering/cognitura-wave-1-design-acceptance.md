# Cognitura Wave 1 详细设计验收记录

```text
DecisionDate = 2026-07-30
ReviewedCandidate = PENDING_NEW_FIXED_CANDIDATE
PriorReviewedCandidate = 3efe89fa532b7d58d7915dc891732dfdf5f4ee55
SupersededRepairCandidate = b1d4f78ed98fbe108358a8b07cc7681bea9ffd69
AcceptanceStatus = SUPERSEDED_BY_USER_REVIEW_FINDINGS
Wave1DesignVerification = PASS
Wave0Regression = PASS
W1-DG0 DesignGovernance = REPAIR_CANDIDATE_AWAITING_FIXED_REVIEW
W1-DG1 SourceDocumentContract = REPAIR_CANDIDATE_AWAITING_FIXED_REVIEW
W1-DG2 DocumentBlockFidelityAndSafety = PASS
W1-DG3 ReparseAndReferenceCompatibility = REPAIR_CANDIDATE_AWAITING_FIXED_REVIEW
W1-DG4 SourcePreviewAndAcceptance = PASS
W1-DG5 FixedDesignReview = IN_PROGRESS
Wave1DesignStatus = REVIEW_REPAIR_IN_PROGRESS
BusinessImplementation = NOT_AUTHORIZED
Wave1ImplementationTaskCardSet = NOT_CREATED
DirectFullImplementationStart = NO
RemotePush = NOT_PERFORMED
```

## 1. 固定候选

本记录接受的书面设计候选是
`3efe89fa532b7d58d7915dc891732dfdf5f4ee55`。候选包含 W1-D00 设计治理、
W1-D01 至 W1-D04 四份正式来源契约、任务卡和契约验证资产；不包含业务实现、
数据库 migration、Provider 选择、部署配置或 `raw/` 原件变更。

该候选的历史接受结论已被后续用户审阅发现取代。用户批准的修复只涉及 D00
候选完整性边界、D01 `PENDING` attempt 超时出口、D03 section-scoped consumer
边界及其验证资产；新固定候选产生前，本文件不得被解释为当前 `W1-DG5 PASS`。
原 D00 对“实现任务卡建议清单”的过早要求已删除；实现切片仍必须等完整设计重新
通过 Gate 并取得用户明确批准后才可编制。

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

该验证只允许形成新的固定候选，不等于一般深审或最终门禁已经通过。

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

## 7. 停止边界

本记录只关闭 Wave 1 书面详细设计 Gate。下一状态是用户审阅完整书面设计；
在用户再次明确批准前，不创建 `W1-Ixx`、不编制实现计划、不写业务代码或正式
数据库、不选择 Parser/Object Storage Provider，也不部署或远程推送。
