# W1-I00 Implementation Governance

```text
TaskCardID = W1-I00
CardKind = GOVERNANCE
Status = READY
Gate = W1-IG0 ImplementationGovernance
Risk = HIGH
DependsOn = NONE
PrimaryBoundary = TASK_CARD_GOVERNANCE
ProductionFileLimit = 8
ProductionWriteSetException = NONE
PositiveVerification = VALID_BOOTSTRAP_AND_AUTHORIZATION_TERMINAL
NegativeVerification = CLOSED_SET_STATUS_WRITESET_AND_GATE_MUTATIONS
BusinessImplementationAuthorization = NOT_REQUIRED_GOVERNANCE_ONLY
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
```

## 1. 目标

建立 Wave 1 实现卡闭集、Bash 3.2 验证器、mutation 合同、统一验证入口和工程计划，
并在固定提交独立审查后关闭治理卡。本卡不实现任何产品运行时能力。

## 2. 前置条件与输入

- `Cognitura-Overall-Design-1.2` 与 `Cognitura-Schema-Baseline-2.0`。
- 已批准 Wave 1 四份正式合同、设计验收和实现切片规格。
- `MDR-I00..MDR-I08` 已完成但不替代本卡集；其运行态权威保持不变。

## 3. 写集

```text
WriteSet = scripts/verify-wave1-implementation-cards
WriteSet = tests/task-cards/verify-wave1-implementation-cards.sh
WriteSet = scripts/verify-wave1-implementation
WriteSet = docs/engineering/cognitura-wave-1-implementation-plan.md
WriteSet = docs/task-cards/wave-1-implementation/README.md
WriteSet = docs/task-cards/wave-1-implementation/W1-I00-implementation-governance.md
WriteSet = docs/task-cards/wave-1-implementation/W1-I01-source-ingestion-domain.md
WriteSet = AGENTS.md
WriteSet = README.md
WriteSet = docs/design/wave-1/README.md
WriteSet = docs/engineering/cognitura-design-index.md
WriteSet = docs/engineering/cognitura-wave-1-design-plan.md
WriteSet = docs/engineering/cognitura-wave-1-design-acceptance.md
WriteSet = docs/task-cards/wave-1/README.md
WriteSet = docs/superpowers/specs/2026-07-30-wave1-implementation-slicing-design.md
ForbiddenWriteSet = ALL_PRODUCT_RUNTIME_PATHS
ForbiddenWriteSet = FORMAL_DATABASE_AND_SOURCE_INPUTS
```

## 4. 执行步骤

1. 先写会因验证器缺失而失败的正例合同。
2. 实现只接受闭集参数的最小验证器，再逐项添加 18 个 mutation 负例。
3. 建立只组合既有设计 Gate 和卡集 Gate 的统一入口。
4. 固定候选并由新的 `deep_reviewer` 作零发现审查。
5. 审查 GO 后关闭 I00；I01 保持用户业务授权阻断。

## 5. 验证命令

```bash
bash tests/task-cards/verify-wave1-implementation-cards.sh
scripts/verify-wave1-implementation
bash -n scripts/verify-wave1-implementation \
  scripts/verify-wave1-implementation-cards \
  tests/task-cards/verify-wave1-implementation-cards.sh
npm exec --yes --package=node@24.18.0 -- sh -c 'scripts/verify-wave0'
git diff --check
git status --short
```

## 6. Gate 与完成定义

14 张卡闭集、依赖、单一 READY、授权和大小合同全部 fail closed；18 个负例与一个
合法授权阻断终态通过；固定候选取得 `deep_reviewer = GO / P0=0 / P1=0 / P2=0`。
完成时不得释放 I01。

## 7. 提交与审查

```bash
sed -n 's/^WriteSet = //p' \
  docs/task-cards/wave-1-implementation/W1-I00-implementation-governance.md |
  git add --pathspec-from-file=-
git diff --cached --name-only
git commit -m "build: establish Wave 1 implementation governance"
```

暂存清单必须与本卡 WriteSet 双向精确一致；目录级 `git add` 禁止。提交后由新的
`deep_reviewer` 只读审查固定 SHA；禁止 amend 和远程推送。
