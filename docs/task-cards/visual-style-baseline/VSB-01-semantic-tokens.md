# VSB-01 Semantic Style Tokens

```text
TaskCardID = VSB-01
CardKind = SEMANTIC_TOKEN_PROJECTION
Status = GOVERNED_BY_EXECUTION_STATE
DependsOn = VSB-00
Gate = VSB-G1 SEMANTIC_TOKENS
ReviewRoute = deep_reviewer
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. 目标

把正式视觉语言投影为唯一的五文件语义 CSS authority，并修复默认阅读校验器对固定
Node/pnpm 工具链的调用；本卡不修改页面组件。

## 2. 输入

- 只消费已通过 `VSB-G0` 的 Visual Style Reference。
- 继续服从正式高保真交互与 Reading First 合同。

## 3. 写集

```text
WriteSet = web/src/styles/tokens.css
WriteSet = web/src/styles/typography.css
WriteSet = web/src/styles/surfaces.css
WriteSet = web/src/styles/cognitive-visual.css
WriteSet = web/src/styles/cognitura.css
WriteSet = web/src/styles/style-contract.test.ts
WriteSet = scripts/verify-module-default-reading
WriteSet = tests/visual-style-baseline/verify-module-default-reading-toolchain.sh
```

## 4. Gate

先以缺失样式合同与错误工具链调用观察 RED，再实现最小 token 投影。`VSB-G1` 要求
闭集 import 图、语义命名、禁止模板化视觉、准确 Node 24.18.0 与 pnpm 11.17.0。

## 5. 审查

形成独立本地候选，执行 `deep_reviewer` 固定 SHA 零发现审查；回执前不释放后继卡。
