# W1-D05 固定设计候选复核

```text
TaskCardID = W1-D05
CardKind = DESIGN
Status = READY
Gate = W1-DG5 FixedDesignReview
Risk = HIGH
DependsOn = W1-D04
ReviewRoute = SOL_HIGH_GENERAL_THEN_SOL_HIGH_FINAL_GATE
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
