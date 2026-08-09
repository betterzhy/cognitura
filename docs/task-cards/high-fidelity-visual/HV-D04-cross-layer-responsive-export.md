# HV-D04 Cross-Layer, Responsive, and Export Evidence

```text
TaskCardID = HV-D04
CardKind = HIGH_FIDELITY_VISUAL_DESIGN
Status = DONE
Gate = HV-D04 PASS
Risk = HIGH
DependsOn = HV-D03
ReviewRoute = MAIN_AGENT_LOCAL_GATE
DesignOwner = CROSS_LAYER_RESPONSIVE_AND_EXPORT
LocalCommitBoundary = docs: complete cross layer visual evidence
WriteSetSource = MASTER_PLAN_TASK_10_CORRECTED
WriteSetItemCount = 21
```

## 1. 目标

证明四层一致性、小屏安全阅读与静态导出稳定身份边界。

## 2. 前置条件与输入

等待 `HV-D03 PASS`；消费跨领域、小屏与 StaticExport 证据合同。

## 3. 写集

- `docs/design/high-fidelity/prototype/index.html`
- `docs/design/high-fidelity/prototype/styles.css`
- `docs/design/high-fidelity/prototype/prototype.js`
- `docs/design/high-fidelity/evidence/knowledge-landscape-theme-desktop.png`
- `docs/design/high-fidelity/evidence/cross-domain-reading-desktop.png`
- `docs/design/high-fidelity/evidence/module-default-reading-small-screen.png`
- `docs/design/high-fidelity/evidence/static-export-example.png`
- `docs/design/high-fidelity/evidence/static-export-manifest.json`
- `docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md`
- `docs/design/high-fidelity/evidence/README.md`
- `docs/engineering/cognitura-high-fidelity-design-plan.md`
- `docs/engineering/cognitura-high-fidelity-design-acceptance.md`
- `docs/task-cards/high-fidelity-visual/HV-D04-cross-layer-responsive-export.md`
- `docs/task-cards/high-fidelity-visual/HV-D05-fixed-visual-usability-review.md`
- `docs/task-cards/high-fidelity-visual/README.md`
- `tests/task-cards/verify-high-fidelity-visual-cards.sh`
- `scripts/verify-high-fidelity-visual`
- `docs/engineering/cognitura-design-index.md`
- `README.md`
- `AGENTS.md`
- `docs/task-cards/README.md`

## 4. 禁止写集

禁止第二棵知识树、全局图谱、卡片墙、常驻小屏侧栏和图片作为正式事实。

## 5. 执行步骤

先写跨层/导出失败断言，以 `knowledge-landscape-theme-desktop.png` 作为跨层唯一主证据，
以 `cross-domain-reading-desktop.png` 证明机制型/规则型内容仍服从同一层级；补充小屏
Module 与静态导出证据并校验 manifest 稳定 ID。只关闭 Owner 集
`RF-AC-01,10,15,19`；`RF-AC-20` 仅记录 supporting visual evidence，仍保持
`NOT_RUN` 并留给 `HV-D05` 固定候选复核关闭，最后释放 `HV-D05`。

## 6. 验证命令

```bash
bash tests/task-cards/verify-high-fidelity-visual-cards.sh
scripts/verify-high-fidelity-visual
bash tests/contracts/interaction-state/verify-interaction-state-contracts.sh
git diff --check
```

## 7. Gate 与完成定义

四类证据、响应式安全和机器身份全部通过后才允许 `HV-D04 PASS`。

## 8. 提交与审查

形成独立本地提交 `docs: complete cross layer visual evidence`；不 push。

```text
ExecutionResult = PASS
EvidenceArtifacts = knowledge-landscape-theme-desktop.png,cross-domain-reading-desktop.png,module-default-reading-small-screen.png,static-export-example.png,static-export-manifest.json
RFOwnerVisualPass = RF-AC-01,10,15,19
RF-AC-20SupportingEvidence = CAPTURED_NOT_CLOSED
Usability = NOT_RUN
Implementation = NOT_RUN
```
