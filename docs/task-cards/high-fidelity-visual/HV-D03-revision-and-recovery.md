# HV-D03 Revision, Impact, and Recovery Evidence

```text
TaskCardID = HV-D03
CardKind = HIGH_FIDELITY_VISUAL_DESIGN
Status = BLOCKED_BY_DEPENDENCY
Gate = HV-D03 NOT_RUN
Risk = HIGH
DependsOn = HV-D02
ReviewRoute = MAIN_AGENT_LOCAL_GATE
DesignOwner = REVISION_IMPACT_AND_RECOVERY
LocalCommitBoundary = docs: design revision and recovery evidence
WriteSetSource = MASTER_PLAN_TASK_9_CORRECTED
WriteSetItemCount = 10
```

## 1. 目标

证明三类影响、提交阻断、正式保存边界、过期投影、冲突草稿与 Revert-as-new-change。

## 2. 前置条件与输入

等待 `HV-D02 PASS`；消费状态六轴、20 异常与 Recovery 证据合同。

## 3. 写集

- `docs/design/high-fidelity/prototype/index.html`
- `docs/design/high-fidelity/prototype/styles.css`
- `docs/design/high-fidelity/prototype/prototype.js`
- `docs/design/high-fidelity/evidence/module-revision-impact-desktop.png`
- `docs/design/high-fidelity/evidence/module-partial-failure-desktop.png`
- `docs/design/high-fidelity/evidence/module-conflicted-draft-desktop.png`
- `docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md`
- `docs/engineering/cognitura-high-fidelity-design-acceptance.md`
- `docs/task-cards/high-fidelity-visual/HV-D03-revision-and-recovery.md`
- `docs/task-cards/high-fidelity-visual/README.md`

## 4. 禁止写集

禁止真实提交、数据库写入、API 调用、静默恢复或物理回滚历史。

## 5. 执行步骤

先写修订/恢复断言，再实现三种确定性状态，捕获 1440×1100 证据并验证重复提交、
刷新、冲突重新基线化和 Escape 层级，最后释放 `HV-D04`。

## 6. 验证命令

```bash
bash tests/task-cards/verify-high-fidelity-visual-cards.sh
scripts/verify-high-fidelity-visual
bash tests/contracts/interaction-state/verify-interaction-state-contracts.sh
git diff --check
```

## 7. Gate 与完成定义

三张高风险状态证据与恢复转换全部通过后才允许 `HV-D03 PASS`。

## 8. 提交与审查

形成独立本地提交 `docs: design revision and recovery evidence`；不 push。
