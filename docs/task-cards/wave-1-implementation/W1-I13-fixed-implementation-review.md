# W1-I13 Fixed Implementation Review

```text
TaskCardID = W1-I13
CardKind = FIXED_CANDIDATE_REVIEW
Status = BLOCKED_BY_DEPENDENCY
Gate = W1-IG13 FixedImplementationReview
Risk = HIGH
DependsOn = W1-I00,W1-I01,W1-I02,W1-I03,W1-I04,W1-I05,W1-I06,W1-I07,W1-I08,W1-I09,W1-I10,W1-I11,W1-I12
PrimaryBoundary = WAVE1_IMPLEMENTATION_GATE
ProductionFileLimit = 8
ProductionWriteSetException = NONE
PositiveVerification = FIXED_CANDIDATE_TWO_STAGE_ZERO_FINDING_REVIEW
NegativeVerification = NONZERO_FINDING_SHA_DRIFT_AND_SCOPE_EXPANSION_REJECTED
BusinessImplementationAuthorization = REQUIRED_BEFORE_READY
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = DEEP_REVIEWER_THEN_ULTRA_GATEKEEPER
```

## 1. 目标

冻结 Wave 1 完整实现候选，先作一般深审，再作最终 ultra GO/NO-GO；本卡内禁止修复。

## 2. 前置条件与输入

- I00..I12 全部 DONE 且各自有固定 SHA 零发现审查收据。
- 数据库集成仅使用隔离测试库；正式数据库仍无写入授权。
- 固定候选必须包含完整依赖历史且工作区只保留用户 `.idea/`。

## 3. 写集

```text
WriteSet = docs/engineering/cognitura-wave-1-implementation-acceptance.md
WriteSet = docs/engineering/cognitura-wave-1-implementation-plan.md
WriteSet = docs/task-cards/wave-1-implementation/README.md
WriteSet = docs/task-cards/wave-1-implementation/W1-I13-fixed-implementation-review.md
WriteSet = AGENTS.md
WriteSet = README.md
WriteSet = docs/engineering/cognitura-design-index.md
WriteSet = docs/design/wave-1/README.md
ForbiddenWriteSet = server/**,web/**,schemas/**,raw/**,.idea/**
```

## 4. 执行步骤

1. RED：验收记录先固定真实候选并保持两阶段审查为 NOT_RUN。
2. 新的 `deep_reviewer` 对固定 SHA 一般深审；任何 finding 返回最早事实 Owner 卡。
3. 一般审查零发现后，由新的 `ultra_gatekeeper` 作最终 GO/NO-GO。
4. GREEN：只有两阶段均零发现，才写验收和 COMPLETE 投影；本卡内不修代码。

## 5. 验证命令

```bash
scripts/verify-wave0
scripts/verify-wave1-design
scripts/verify-wave1-implementation
git diff --check
git status --short
```

## 6. Gate 与完成定义

所有单卡 Gate、数据库隔离、Parser 安全/保真、API、Web、完整回归及固定范围通过，且
`deep_reviewer` 与 `ultra_gatekeeper` 均为 `GO / P0=0 / P1=0 / P2=0`。发现不得在
I13 修复，必须回 Owner 卡形成新候选。

## 7. 提交与审查

```bash
sed -n 's/^WriteSet = //p' \
  docs/task-cards/wave-1-implementation/W1-I13-fixed-implementation-review.md |
  git add --pathspec-from-file=-
git diff --cached --name-only
git commit -m "docs: record Wave 1 implementation review"
```

暂存清单必须与本卡 WriteSet 双向精确一致；目录级 `git add` 禁止。不 amend、
不 push；固定提交依次交给新的 `deep_reviewer` 和新的 `ultra_gatekeeper`。本卡完成
不等于正式数据库写入、部署或发布授权。
