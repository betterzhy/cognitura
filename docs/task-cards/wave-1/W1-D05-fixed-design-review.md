# W1-D05 固定设计候选复核

```text
TaskCardID = W1-D05
CardKind = DESIGN
Status = BLOCKED_BY_DEPENDENCY
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
