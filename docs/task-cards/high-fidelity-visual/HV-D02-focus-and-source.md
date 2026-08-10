# HV-D02 Relation Focus and Source Verification Evidence

```text
TaskCardID = HV-D02
CardKind = HIGH_FIDELITY_VISUAL_DESIGN
Status = DONE
Gate = HV-D02 PASS
Risk = HIGH
DependsOn = HV-D01
ReviewRoute = MAIN_AGENT_LOCAL_GATE
DesignOwner = RELATION_FOCUS_AND_SOURCE_VERIFICATION
LocalCommitBoundary = docs: design focus and source verification evidence
WriteSetSource = MASTER_PLAN_TASK_8_CORRECTED
WriteSetItemCount = 18
```

## 1. 目标

证明单一 Relation 主聚焦、端点层级、Quick Source、完整核验与焦点恢复。

## 2. 前置条件与输入

`HV-D01 PASS` 已满足；消费正式 RelationFocus 与 SourceEvidenceVerification 合同。

## 3. 写集

- `docs/design/high-fidelity/prototype/index.html`
- `docs/design/high-fidelity/prototype/styles.css`
- `docs/design/high-fidelity/prototype/prototype.js`
- `docs/design/high-fidelity/evidence/module-relation-focus-desktop.png`
- `docs/design/high-fidelity/evidence/module-source-verification-desktop.png`
- `docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md`
- `docs/design/high-fidelity/evidence/README.md`
- `docs/engineering/cognitura-high-fidelity-design-plan.md`
- `docs/engineering/cognitura-high-fidelity-design-acceptance.md`
- `docs/task-cards/high-fidelity-visual/HV-D02-focus-and-source.md`
- `docs/task-cards/high-fidelity-visual/HV-D03-revision-and-recovery.md`
- `docs/task-cards/high-fidelity-visual/README.md`
- `tests/task-cards/verify-high-fidelity-visual-cards.sh`
- `scripts/verify-high-fidelity-visual`
- `docs/engineering/cognitura-design-index.md`
- `README.md`
- `AGENTS.md`
- `docs/task-cards/README.md`

## 4. 禁止写集

禁止提前实施修订/恢复卡；禁止独立事实、常驻治理侧栏、HTTP 和持久化。

## 5. 执行步骤

先写状态夹具失败断言，分别实现并捕获 `relation-focus` 与 `source-verification`，
验证键盘/触控等价与 Escape 焦点归还，只评估 Owner 集
`RF-AC-03,07,09,16`，再关闭 `HV-D02` 并释放 `HV-D03`。

## 6. 验证命令

```bash
bash tests/task-cards/verify-high-fidelity-visual-cards.sh
scripts/verify-high-fidelity-visual
bash tests/contracts/interaction-state/verify-interaction-state-contracts.sh
git diff --check
```

## 7. Gate 与完成定义

两张桌面证据和确定性转换全部通过后才允许 `HV-D02 PASS`。

## 8. 提交与审查

形成独立本地提交 `docs: design focus and source verification evidence`；不 push。

```text
ExecutionResult = PASS
RelationFocusArtifact = docs/design/high-fidelity/evidence/module-relation-focus-desktop.png
SourceVerificationArtifact = docs/design/high-fidelity/evidence/module-source-verification-desktop.png
ArtifactViewport = 1440x1100
BrowserSelectorValidation = PASS
KeyboardTouchEscapeTransitionValidation = PASS
RFOwnerVisualPass = RF-AC-03,07,09,16
UsabilityValidation = NOT_RUN
ImplementationValidation = NOT_RUN
FixedReviewRepair = HV-D05-STAGE2|REAL_HISTORY_NAVIGATION_AND_VERIFICATION_DOM_TRANSITION|PASS_HIGH_FIDELITY_USABILITY_ONLY
```
