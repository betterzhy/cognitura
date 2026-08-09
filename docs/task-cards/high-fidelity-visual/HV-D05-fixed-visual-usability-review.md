# HV-D05 Fixed Visual and Usability Review

```text
TaskCardID = HV-D05
CardKind = HIGH_FIDELITY_VISUAL_DESIGN
Status = BLOCKED_BY_DEPENDENCY
Gate = HV-D05 NOT_RUN
Risk = HIGH
DependsOn = HV-D04
ReviewRoute = TWO_INDEPENDENT_gpt-5.6-sol/high_STAGES
DesignOwner = FIXED_VISUAL_AND_USABILITY_REVIEW
LocalCommitBoundary = docs: close high fidelity visual design gate
WriteSetSource = MASTER_PLAN_TASK_11_CORRECTED
WriteSetItemCount = 6
```

## 1. 目标

对同一固定候选完成视觉层级/无障碍审查与可用性/恢复审查，零发现后才关闭视觉和
可用性阶段，且不授权实现。

## 2. 前置条件与输入

等待 `HV-D04 PASS`；消费全部八类截图、DOM 夹具、转换观察和 RF/Exception 台账。

## 3. 写集

- `docs/engineering/cognitura-high-fidelity-design-acceptance.md`
- `docs/engineering/cognitura-design-index.md`
- `docs/task-cards/high-fidelity-visual/HV-D05-fixed-visual-usability-review.md`
- `docs/task-cards/high-fidelity-visual/README.md`
- `README.md`
- `AGENTS.md`

## 4. 禁止写集

审查阶段只读固定候选；修复必须返回 `HV-D01..D04` Owner，禁止直接在审查卡修图。

## 5. 执行步骤

运行完整验证，冻结 SHA，执行两个相互独立的 `gpt-5.6-sol/high` 阶段；发现问题则
回到 Owner 卡补失败验证、重捕证据并重新冻结。

## 6. 验证命令

```bash
scripts/verify-high-fidelity-design
scripts/verify-high-fidelity-visual
scripts/verify-wave0
git diff --check
```

## 7. Gate 与完成定义

两个阶段对同一 SHA 均 `GO / P0=0 / P1=0 / P2=0` 后才允许视觉/可用性 PASS；
`ImplementationValidation` 保持 `NOT_RUN`。

## 8. 提交与审查

形成独立本地提交 `docs: close high fidelity visual design gate`；不 push。
