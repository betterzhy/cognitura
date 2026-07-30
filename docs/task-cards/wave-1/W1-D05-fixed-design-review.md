# W1-D05 固定设计候选复核

```text
TaskCardID = W1-D05
CardKind = DESIGN
Status = READY
Gate = W1-DG5 FixedDesignReview
Risk = HIGH
DependsOn = W1-D04
ReviewRoute = SOL_HIGH_GENERAL_THEN_SOL_HIGH_FINAL_GATE
ImplementationSlicing = AFTER_EXPLICIT_USER_APPROVAL
```

## 1. 目标

对 W1-D00 至 W1-D04 的固定设计候选执行两个独立 sol/high 审查阶段并封口。

## 2. 前置条件与输入

- W1-D00 至 W1-D04 全部 `DONE`。
- `scripts/verify-wave1-design` 与 `scripts/verify-wave0` 全部通过。
- 候选工作树除 `.idea/` 外干净。

## 3. 写集

- Create: `docs/engineering/cognitura-wave-1-design-acceptance.md`
- Modify: `docs/design/wave-1/README.md`
- Modify: `docs/task-cards/wave-1/W1-D05-fixed-design-review.md`
- Modify: `docs/task-cards/wave-1/README.md`
- Modify: `docs/engineering/cognitura-wave-1-design-plan.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `AGENTS.md`
- Modify: `README.md`
- Modify: `docs/design/wave-1/cognitura-source-document-contract-1.0.md`
- Modify: `docs/design/wave-1/cognitura-document-block-contract-1.0.md`
- Modify: `docs/design/wave-1/cognitura-reparse-reference-contract-1.0.md`
- Modify: `docs/design/wave-1/cognitura-source-preview-contract-1.0.md`
- Modify: `tests/contracts/wave1-design/verify-source-document-contract.sh`
- Modify: `tests/contracts/wave1-design/verify-document-block-contract.sh`
- Modify: `tests/contracts/wave1-design/verify-reparse-reference-contract.sh`
- Modify: `tests/contracts/wave1-design/verify-source-preview-contract.sh`
- Modify: `docs/superpowers/plans/2026-07-30-wave1-detailed-design-artifacts.md`
- Modify: `docs/superpowers/specs/2026-07-30-wave1-source-ingestion-governance-design.md`
- Create: `docs/superpowers/plans/2026-07-30-wave1-design-review-repairs.md`
- Modify: `tests/task-cards/verify-wave1-design-cards.sh`
- Modify: `scripts/verify-wave1-design-cards`

以上附加写集只用于修复固定候选审查发现；不得借此扩展产品范围或创建实现资产。

## 4. 执行步骤

1. 固定完整 40 字符候选 SHA 并运行全部验证。
2. 由独立 `gpt-5.6-sol/high` Agent 执行一般审查。
3. 由另一独立 `gpt-5.6-sol/high` Agent 执行最终门禁。
4. 任一发现均生成新修复提交并重新走两阶段。
5. 双零发现后记录接受证据并关闭设计卡集合。
6. 停止在用户完整书面设计审阅 Gate。

## 5. 验证命令

```bash
scripts/verify-wave1-design
scripts/verify-wave0
git diff --check
git status --short
```

## 6. Gate 与完成定义

`W1-DG5 = PASS` 要求两个独立 `gpt-5.6-sol/high` 阶段均为
`P0=0/P1=0/P2=0`，且不使用 ultra、不创建实现卡、不授权业务实现。

## 7. 提交与审查

固定候选与关闭记录分别保持可追溯；只做本地提交，不推送。

## 8. 固定候选审查循环

第一轮固定候选：

```text
GeneralReviewModel = gpt-5.6-sol
GeneralReviewReasoningEffort = high
GeneralReviewVerdict = NOT_READY
GeneralReviewP0 = 0
GeneralReviewP1 = 5
GeneralReviewP2 = 1
ReviewedCandidate = b7043d072db621200b4c7cfa99d7bca95d8d1ddf
FinalGateStarted = NO
```

第一轮发现覆盖 `SOURCE_PARSING` 审计投影、attempt/block-set 原子发布、partial
确认与下游消费门、查询 DTO/error/alias 生命周期、核心授权 Gate 和执行计划残留
冲突。修复循环新增验证负例：

```text
SourceDocumentContractNegativeCases = 21
DocumentBlockContractNegativeCases = 24
ReparseReferenceContractNegativeCases = 25
SourcePreviewContractNegativeCases = 25
```

修复完成后必须形成新的本地固定提交，重新运行全量验证，并从一般审查重新开始；
第一轮结论不得作为最终门禁证据。

第二轮固定候选：

```text
GeneralReviewModel = gpt-5.6-sol
GeneralReviewReasoningEffort = high
GeneralReviewVerdict = NOT_READY
GeneralReviewP0 = 0
GeneralReviewP1 = 3
GeneralReviewP2 = 0
ReviewedCandidate = 82715141fe6900ec88c96d8977a4a20fb22c4909
FinalGateStarted = NO
```

第二轮发现要求：`SOURCE_PARSING.inputHash` 纳入逻辑 SourceDocument identity；
revision/preview DTO 公开 exact block-set/omissions digest 以构造 partial confirmation；
稳定 API 闭集覆盖 `EMPTY_SOURCE_FILE` 和 `SOURCE_HASH_MISMATCH`。第二轮修复后的
验证负例目标为：

```text
SourceDocumentContractNegativeCases = 23
DocumentBlockContractNegativeCases = 24
ReparseReferenceContractNegativeCases = 25
SourcePreviewContractNegativeCases = 28
```

第二轮结论同样不得作为最终门禁证据；必须再次形成新固定提交并从一般审查开始。

第三轮固定候选：

```text
GeneralReviewModel = gpt-5.6-sol
GeneralReviewReasoningEffort = high
GeneralReviewVerdict = NOT_READY
GeneralReviewP0 = 0
GeneralReviewP1 = 2
GeneralReviewP2 = 0
ReviewedCandidate = 731d5bd8eafce06a2ee6a7f556945c02022f5da8
FinalGateStarted = NO
```

第三轮发现要求 Gate 直接验证 D01 revision 的两个 digest owner 字段，并统一基础
validation rejection 的身份边界。修复裁决为：media type、非空、raw size 和声明
hash 均在正式注册前验证，失败不创建 SourceDocument/SourceBinary/幂等事实；
注册后的 DOCX 安全/格式拒绝才产生 `REJECTED` SourceDocument。第三轮修复后的
验证负例目标为：

```text
SourceDocumentContractNegativeCases = 24
DocumentBlockContractNegativeCases = 24
ReparseReferenceContractNegativeCases = 25
SourcePreviewContractNegativeCases = 28
```

第三轮结论不得作为最终门禁证据；必须形成新固定提交并从一般审查重新开始。

第四轮固定候选与双阶段结论：

```text
ReviewedCandidate = 3efe89fa532b7d58d7915dc891732dfdf5f4ee55
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
Wave1DesignVerification = PASS
Wave0Regression = PASS
NodeVersion = 24.18.0
PnpmVersion = 11.17.0
W1-DG5 FixedDesignReview = PASS
BusinessImplementation = NOT_AUTHORIZED
Wave1ImplementationTaskCardSet = NOT_CREATED
```

两个 reviewer 相互独立并绑定同一固定候选；最终 reviewer 未使用一般审查结论
作为证据。完整验收记录见
[`cognitura-wave-1-design-acceptance.md`](../../engineering/cognitura-wave-1-design-acceptance.md)。

第五轮用户审阅修复循环：

```text
ReviewSource = USER_APPROVED_DESIGN_OPTIMIZATION_REVIEW
ReviewedCandidate = 3efe89fa532b7d58d7915dc891732dfdf5f4ee55
ReviewVerdict = NOT_READY
ReviewP0 = 0
ReviewP1 = 3
ReviewP2 = 0
W1-DG5 FixedDesignReview = IN_PROGRESS
GeneralReviewStarted = NO
FinalGateStarted = NO
BusinessImplementation = NOT_AUTHORIZED
Wave1ImplementationTaskCardSet = NOT_CREATED
```

三个发现仅允许以下最小修复：

1. D03 的 Wave 2 消费边界允许显式 `DocumentSectionScope`，不再强制从
   `sourceOrder=0` 消费整份 revision。
2. D01 为未被 worker claim 的 `PENDING` attempt 补充合法的超时失败出口。
3. D00 删除在完整设计用户批准前产生实现任务卡建议清单的过早要求。

修复必须先增加可观察失败的契约负例，再形成新固定候选，并从一般审查重新开始。

第六轮修复候选一般审查：

```text
ReviewedCandidate = b1d4f78ed98fbe108358a8b07cc7681bea9ffd69
GeneralReviewModel = gpt-5.6-sol
GeneralReviewReasoningEffort = high
GeneralReviewVerdict = NOT_READY
GeneralReviewP0 = 0
GeneralReviewP1 = 1
GeneralReviewP2 = 0
FinalGateStarted = NO
W1-DG5 FixedDesignReview = IN_PROGRESS
```

一般审查发现 lease 超时监督只绑定 active identity/generation，无法拒绝 worker
claim 或 heartbeat 后的 stale expiry observation。修复必须把
`expectedAttemptStatus + observedLeaseExpiresAt` 纳入超时 CAS，并新增
identity-only 退化负例；随后形成新固定候选并从一般审查重新开始。
