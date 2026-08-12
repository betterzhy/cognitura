# VSB-03 Fixed Visual Acceptance

```text
TaskCardID = VSB-03
CardKind = FIXED_VISUAL_ACCEPTANCE
Status = GOVERNED_BY_EXECUTION_STATE
DependsOn = VSB-02
Gate = VSB-G3 FIXED_VISUAL_ACCEPTANCE
ReviewRoute = deep_reviewer+ultra_gatekeeper
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. 目标

以真实 DOM、computed style、运行时防护、三种 viewport、新鲜截图和并排参考图完成
固定候选视觉验收；不把局部页面验收扩大成完整产品实现结论。

## 2. 输入

- 消费已通过 `VSB-G0..G2` 的固定候选和 immutable receipts。
- 历史高保真证据与冻结的 W1-I03 production tree 只读保护。

## 3. 写集

```text
WriteSet = scripts/capture-visual-style-baseline
WriteSet = scripts/verify-visual-style-baseline
WriteSet = tests/visual-style-baseline/browser-probe.html
WriteSet = tests/visual-style-baseline/browser-runtime-guard.js
WriteSet = tests/visual-style-baseline/reference-comparison.html
WriteSet = tests/visual-style-baseline/verify-visual-style-baseline.sh
WriteSet = docs/design/visual-style-baseline/evidence/README.md
WriteSet = docs/design/visual-style-baseline/evidence/module-default-reading-1440x1100.png
WriteSet = docs/design/visual-style-baseline/evidence/module-default-reading-1280x960.png
WriteSet = docs/design/visual-style-baseline/evidence/module-default-reading-1024x900.png
WriteSet = docs/design/visual-style-baseline/evidence/reference-comparison.png
WriteSet = docs/engineering/cognitura-visual-style-baseline-acceptance.md
```

## 4. Gate

先写浏览器、证据、freshness、CSP、runtime API、overflow、冻结树和验收字段负例，再
实现 capture/verifier。`VSB-G3` 要求固定候选的全部机器 Gate、人工图像检查和证据
闭集 PASS。

## 5. 审查

同一未变候选依次取得 `deep_reviewer` 与 `ultra_gatekeeper` 零发现 GO。任一 finding
必须 `RETURN_TO_OWNER`；两阶段 GO 前不得 COMPLETE 或恢复 Wave 1。
