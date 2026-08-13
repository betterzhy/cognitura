# VSB-02 Module Default Reading Visual

```text
TaskCardID = VSB-02
CardKind = BOUNDED_VISUAL_IMPLEMENTATION
Status = GOVERNED_BY_EXECUTION_STATE
DependsOn = VSB-01
Gate = VSB-G2 MODULE_DEFAULT_READING_VISUAL
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
ReviewVerdict = GO_P0_0_P1_0_P2_0
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

`ReviewVerdict` 仅定义 required acceptance，不是运行态或已执行事实。形成独立本地候选，
对同一固定 SHA 只执行一次 `L3 / deep_reviewer / xhigh` 零 finding 门禁；回执前不释放后继卡。
