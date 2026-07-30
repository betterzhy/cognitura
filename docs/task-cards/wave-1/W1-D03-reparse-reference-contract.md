# W1-D03 重解析、幂等与稳定引用

```text
TaskCardID = W1-D03
CardKind = DESIGN
Status = BLOCKED_BY_DEPENDENCY
Gate = W1-DG3 ReparseAndReferenceCompatibility
Risk = HIGH
DependsOn = W1-D02
ReviewRoute = SOL_HIGH_DESIGN_GATE
```

## 1. 目标

固定不可变 Block 引用、重新解析复用规则、revision lineage 和 Wave 2/3 兼容接口。

## 2. 前置条件与输入

- 已通过 Gate 的 W1-D01、W1-D02 契约。
- Schema Baseline 2.0 §6.8。
- 总体设计 §14、§17。

## 3. 写集

- Create: `docs/design/wave-1/cognitura-reparse-reference-contract-1.0.md`
- Create: `tests/contracts/wave1-design/verify-reparse-reference-contract.sh`
- Modify: `docs/design/wave-1/README.md`
- Modify: `docs/task-cards/wave-1/W1-D03-reparse-reference-contract.md`
- Modify: `docs/task-cards/wave-1/W1-D04-source-preview-acceptance.md`
- Modify: `docs/task-cards/wave-1/README.md`
- Modify: `docs/engineering/cognitura-wave-1-design-plan.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `AGENTS.md`
- Modify: `README.md`

## 4. 执行步骤

1. 先写禁止静默重定向的失败验证。
2. 固定三段式 `DocumentBlockRef`。
3. 固定 reparse 幂等和 lineage 状态。
4. 固定 Wave 2/3 只读消费边界。
5. 通过 Gate 后关闭本卡并释放 W1-D04。

## 5. 验证命令

```bash
bash tests/contracts/wave1-design/verify-reparse-reference-contract.sh
bash tests/contracts/wave1-design/verify-document-block-contract.sh
bash tests/task-cards/verify-wave1-design-cards.sh
git diff --check
```

## 6. Gate 与完成定义

`W1-DG3 = PASS` 要求历史引用永不静默重定向，歧义 lineage 不自动裁决，且
EvidenceReference 所需字段保持兼容。

## 7. 提交与审查

使用 `gpt-5.6-sol/high` 进行设计 Gate；形成独立本地提交，不推送。
