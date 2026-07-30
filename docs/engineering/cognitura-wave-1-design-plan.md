# Cognitura Wave 1 详细设计计划

```text
DecisionDate = 2026-07-30
CurrentStage = WAVE1_DESIGN_REVIEW_REPAIR_IN_PROGRESS
Wave1DesignStatus = REVIEW_REPAIR_IN_PROGRESS
ActiveDesignTaskCard = W1-D05
Wave1ImplementationTaskCardSet = NOT_CREATED
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
DeploymentAndRelease = NOT_AUTHORIZED
```

## 1. 目标

在任何 Wave 1 业务实现前，依次固定来源身份、块保真、稳定引用、来源预览和验收
契约，并对完整设计执行固定候选复核。

## 2. 设计切片

```text
W1-D00 DesignGovernance = DONE
W1-D01 SourceDocumentContract = DONE
W1-D02 DocumentBlockFidelityAndSafety = DONE
W1-D03 ReparseAndReferenceCompatibility = DONE
W1-D04 SourcePreviewAndAcceptance = DONE
W1-D05 FixedDesignReview = READY
```

唯一正式索引是
[`docs/task-cards/wave-1/README.md`](../task-cards/wave-1/README.md)。

## 3. Gate

```text
W1-DG0 DesignGovernance = REPAIR_CANDIDATE_AWAITING_FIXED_REVIEW
W1-DG1 SourceDocumentContract = REPAIR_CANDIDATE_AWAITING_FIXED_REVIEW
W1-DG2 DocumentBlockFidelityAndSafety = PASS
W1-DG3 ReparseAndReferenceCompatibility = REPAIR_CANDIDATE_AWAITING_FIXED_REVIEW
W1-DG4 SourcePreviewAndAcceptance = PASS
W1-DG5 FixedDesignReview = IN_PROGRESS
```

W1-D00 至 W1-D04 均使用 `gpt-5.6-sol/high` 设计 Gate；W1-D05 使用两个
相互独立的 `gpt-5.6-sol/high` 审查阶段，不使用 ultra。

## 4. 停止边界

- 设计集合完成前不得创建 `W1-Ixx`。
- 设计集合完成后仍需用户审阅完整书面设计。
- 用户审阅前不得编制或执行业务实现计划。
- 正式数据库、远程推送、部署与发布均不在本计划授权内。

固定候选 `3efe89fa532b7d58d7915dc891732dfdf5f4ee55` 的历史双阶段结论已被后续
用户审阅发现取代。当前只执行经批准的三个设计修复；新固定候选必须重新通过两个
独立 `gpt-5.6-sol/high` 阶段，完整证据持续记录在
[`cognitura-wave-1-design-acceptance.md`](cognitura-wave-1-design-acceptance.md)。
