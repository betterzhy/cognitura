# Cognitura Wave 1 详细设计计划

```text
DecisionDate = 2026-07-30
CurrentStage = WAVE1_IMPLEMENTATION_IN_PROGRESS
Wave1DesignStatus = USER_APPROVED
Wave1ImplementationPlanningStatus = TASK_CARD_SET_BOOTSTRAPPED
ActiveDesignTaskCard = NONE
Wave1ImplementationTaskCardSet = READY_FOR_EXECUTION
ActiveImplementationGovernanceTaskCard = W1-I13
VisualStyleBaselineExecutionStateAuthority = docs/task-cards/visual-style-baseline/execution-state.md
BusinessImplementation = USER_AUTHORIZED
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
W1-D05 FixedDesignReview = DONE
```

唯一正式索引是
[`docs/task-cards/wave-1/README.md`](../task-cards/wave-1/README.md)。

## 3. Gate

```text
W1-DG0 DesignGovernance = PASS
W1-DG1 SourceDocumentContract = PASS
W1-DG2 DocumentBlockFidelityAndSafety = PASS
W1-DG3 ReparseAndReferenceCompatibility = PASS
W1-DG4 SourcePreviewAndAcceptance = PASS
W1-DG5 FixedDesignReview = PASS
```

W1-D00 至 W1-D04 均使用 `gpt-5.6-sol/high` 设计 Gate；W1-D05 使用两个
相互独立的 `gpt-5.6-sol/high` 审查阶段，不使用 ultra。

## 4. 停止边界

- 设计集合完成前不得创建 `W1-Ixx`。
- 设计集合完成后仍需用户审阅完整书面设计。
- 用户审阅前不得编制或执行业务实现计划。
- 正式数据库、远程推送、部署与发布均不在本计划授权内。

修复固定候选 `17dabff23b029e1a6fc7f47155f552ed3f16d775` 已重新通过两个
独立 `gpt-5.6-sol/high` 阶段并获得用户完整设计批准，实现切片书面规格也已获
批准。14 张实现卡已经 bootstrap，非业务治理卡 I00 和来源领域卡 I01 已完成零发现
固定候选深审并关闭；I02、I03、I04、I05、I06、I07、I08、I09、I10、I11 和 I12 已关闭，I13 已释放为唯一 `READY` 卡，完整证据记录在
[`cognitura-wave-1-design-acceptance.md`](cognitura-wave-1-design-acceptance.md)。
