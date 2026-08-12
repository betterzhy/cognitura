# VSB-00 Governance and Visual Style Reference

```text
TaskCardID = VSB-00
CardKind = GOVERNANCE_AND_REFERENCE
Status = GOVERNED_BY_EXECUTION_STATE
DependsOn = GOVERNANCE_BOOTSTRAP
Gate = VSB-G0 GOVERNANCE_AND_REFERENCE
ReviewRoute = deep_reviewer
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. 目标

无损导入批准的历史参考图，建立仅拥有 Visual DNA 的正式 Style Reference、来源
Manifest、权威桥接和可复现校验器；不得改变 Reading First 页面结构所有权。

## 2. 输入

- 批准规格固定于 `70eefba5912e6884e4e7e1d6477a65f4091d6590`。
- 原始 JPEG 只从批准附件读取，PNG 必须像素等价且可由 manifest 追溯。

## 3. 写集

```text
WriteSet = AGENTS.md
WriteSet = docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png
WriteSet = docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md
WriteSet = docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md
WriteSet = docs/engineering/cognitura-design-index.md
WriteSet = docs/engineering/cognitura-visual-style-baseline-manifest.yaml
WriteSet = scripts/import-visual-style-reference
WriteSet = scripts/verify-visual-style-baseline-reference
WriteSet = tests/visual-style-baseline/verify-reference.sh
```

## 4. Gate

先以缺失 importer/verifier/reference 观察 RED，再实现最小无损导入与闭集来源验证。
`VSB-G0` 只在像素、尺寸、SHA、权威边界、无重复事实与历史证据保护全部通过后 PASS。

## 5. 审查

形成独立本地候选，执行 `deep_reviewer` 固定 SHA 零发现审查；回执前不释放后继卡。
