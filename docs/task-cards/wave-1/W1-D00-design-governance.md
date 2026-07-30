# W1-D00 Wave 1 设计治理

```text
TaskCardID = W1-D00
CardKind = DESIGN
Status = DONE
Gate = W1-DG0 DesignGovernance
Risk = HIGH
DependsOn = NONE
ReviewRoute = SOL_HIGH_DESIGN_GATE
```

## 1. 目标

建立 Wave 1 设计卡集合、独立验证器、状态同步和设计/实现授权隔离。

## 2. 前置条件与输入

- 已批准的 W1-D00 治理说明。
- Wave 1 准入裁决。
- 已完成的 W0 任务卡集合与验证器。

## 3. 写集

- Create: `docs/task-cards/wave-1/`
- Create: `docs/engineering/cognitura-wave-1-design-plan.md`
- Create: `scripts/verify-wave1-design-cards`
- Create: `tests/task-cards/verify-wave1-design-cards.sh`
- Modify: `docs/superpowers/plans/2026-07-30-wave1-detailed-design-artifacts.md`
- Modify: `docs/superpowers/specs/2026-07-30-wave1-source-ingestion-governance-design.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `AGENTS.md`
- Modify: `README.md`

## 4. 执行步骤

1. 先建立缺失验证器时失败的测试。
2. 实现 Bash 3.2 兼容验证器及负例。
3. 创建六张串行设计卡。
4. 同步唯一活动设计卡和禁止业务实现状态。

## 5. 验证命令

```bash
bash tests/task-cards/verify-wave1-design-cards.sh
scripts/verify-wave1-design-cards --cards-dir docs/task-cards/wave-1
bash tests/task-cards/verify-task-cards.sh
bash tests/ci/verify-markdown-links.sh
git diff --check
```

## 6. Gate 与完成定义

`W1-DG0 = PASS` 要求六张设计卡可验证、恰有 W1-D01 为 `READY`、W0 历史
集合仍通过，且没有实现卡或业务源码变更。

## 7. 提交与审查

```text
ReviewModel = gpt-5.6-sol
ReviewReasoningEffort = high
ReviewVerdict = READY
ReviewP0 = 0
ReviewP1 = 0
ReviewP2 = 0
```

审查首轮发现实现卡授权、未声明设计卡和 spec 状态三项 P1；复审发现执行计划未
进入写集一项 P1。以上发现均已通过新负例、写集同步和全量回归关闭；第三轮复核
为零发现。形成独立本地提交，不推送。
