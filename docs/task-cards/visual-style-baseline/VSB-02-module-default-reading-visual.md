# VSB-02 Module Default Reading Visual

```text
TaskCardID = VSB-02
CardKind = BOUNDED_VISUAL_IMPLEMENTATION
Status = GOVERNED_BY_EXECUTION_STATE
DependsOn = VSB-01
Gate = VSB-G2 MODULE_DEFAULT_READING_VISUAL
ReviewRoute = deep_reviewer
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. 目标

只重绘既有 Module 默认阅读语义投影，并以独立 Vite entry 提供离线视觉 fixture；
不接产品入口、路由、后端、持久化或新事实字段。

## 2. 输入

- 消费 `VSB-G1` 的五文件 token authority。
- 保持八段 DOM 顺序、单主投影、来源入口和正式高保真交互合同。

## 3. 写集

```text
WriteSet = web/src/modules/module-reading/ModuleDefaultReading.tsx
WriteSet = web/src/modules/module-reading/ModuleDefaultReading.test.tsx
WriteSet = web/src/modules/module-reading/ModuleNarrative.tsx
WriteSet = web/src/modules/module-reading/ModuleNarrative.test.tsx
WriteSet = web/src/modules/module-reading/StageChainProjection.tsx
WriteSet = web/src/modules/module-reading/StageChainProjection.test.tsx
WriteSet = web/src/modules/module-reading/ModuleClosure.tsx
WriteSet = web/src/modules/module-reading/ModuleClosure.test.tsx
WriteSet = web/src/modules/module-reading/KeyRelations.tsx
WriteSet = web/src/modules/module-reading/KeyRelations.test.tsx
WriteSet = web/src/modules/module-reading/SourceEntry.tsx
WriteSet = web/src/modules/module-reading/SourceEntry.test.tsx
WriteSet = web/src/modules/module-reading/module-default-reading.css
WriteSet = web/vite.config.mjs
WriteSet = web/visual-reference.html
WriteSet = web/src/visual-reference/main.tsx
WriteSet = web/src/visual-reference/VisualReference.tsx
WriteSet = web/src/visual-reference/VisualReference.test.tsx
WriteSet = web/src/visual-reference/module-default-reading.fixture.ts
WriteSet = web/src/visual-reference/visual-reference.css
```

## 4. Gate

先写组件、DOM 顺序、来源入口、响应式和独立 entry 失败用例，再最小重绘。`VSB-G2`
要求既有语义测试、视觉 entry 测试、构建和默认阅读 verifier 全部通过。

## 5. 审查

形成独立本地候选，执行 `deep_reviewer` 固定 SHA 零发现审查；回执前不释放后继卡。
