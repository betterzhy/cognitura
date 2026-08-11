# MDR-I04 Stage Chain Renderer Projection

```text
TaskCardID = MDR-I04
CardKind = IMPLEMENTATION
Status = GOVERNED_BY_EXECUTION_STATE
ExecutionStateAuthority = docs/task-cards/module-default-reading-implementation/execution-state.md
Gate = MDR-IG4 StageChainRendererProjection
Risk = HIGH
DependsOn = MDR-I03
PrimaryBoundary = WEB_RENDERER_PROJECTION
ProductionFileLimit = 2
BusinessImplementationAuthorization = REQUIRED_BEFORE_RELEASE
SchemaChange = FORBIDDEN
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
```

## 1. 目标

只实现 `RendererInput.rendererType = STAGE_CHAIN` 的单一主视觉投影，验证 Renderer
不创建事实。其他八种 Renderer 和动态选择留给后续独立卡。

## 2. 前置条件与输入

execution-state 账本已记录 `MDR-I03` 固定提交零发现收据，并把本卡投影为唯一活动且
已释放卡；输入服从现有
`schemas/ui/renderer-input.schema.json`。

## 3. 精确写集

```text
WriteSet = web/src/modules/module-reading/model.ts
WriteSet = web/src/modules/module-reading/StageChainProjection.tsx
WriteSet = web/src/modules/module-reading/StageChainProjection.test.tsx
ForbiddenWriteSet = schemas/**,server/**,raw/**,.idea/**
ForbiddenRendererType = HIERARCHY,MATRIX,DECISION_PATH,STATE_TRANSITION,COMPARISON,CAUSAL_CHAIN,LAYERED_STRUCTURE,STRUCTURED_PANEL
```

## 4. RED -> GREEN

RED：

```tsx
render(<StageChainProjection moduleRef="module.mvcc" input={rendererInput} />);
const stageChain = screen.getByRole("list", { name: "Stage chain" });
expect(within(stageChain).getAllByRole("listitem").map((item) => item.textContent))
  .toEqual(rendererInput.nodes.map((node) => `${node.label}${node.summary}`));
expect(within(stageChain).getAllByRole("listitem").map((item) => item.dataset.nodeId))
  .toEqual(rendererInput.nodes.map((node) => node.nodeId));
expect(() => render(<StageChainProjection moduleRef="module.other" input={rendererInput} />))
  .toThrow("RENDERER_MODULE_REF_MISMATCH");
```

先观察组件缺失的 RED。GREEN 只按输入顺序显示 node label/summary，并验证
`rendererType` 与 `moduleRef`，并输出唯一 `data-reading-section="stage-chain"`；不得补边、
改序、总结或从 docs-only fixture 取数据。

## 5. 验证命令

```bash
pnpm --dir web test -- src/modules/module-reading/StageChainProjection.test.tsx
pnpm --dir web build
bash tests/contracts/schema/verify-json-schemas.sh
bash tests/contracts/ui/verify-ui-contracts.sh
scripts/verify-high-fidelity-design
git diff --check
git status --short
```

## 6. Gate 与完成定义

仅 `STAGE_CHAIN` 正例 PASS；类型和 moduleRef 错配均 fail closed；所有可见文本来自
RendererInput，`RendererCreatesIndependentFacts = NO`。

## 7. 提交与独立固定提交审查

```bash
git add web/src/modules/module-reading/model.ts \
  web/src/modules/module-reading/StageChainProjection.tsx \
  web/src/modules/module-reading/StageChainProjection.test.tsx
git commit -m "feat: project stage chain renderer input"
```

新的 `deep_reviewer` 对固定 SHA 审查投影同一性与 fail-closed 路径；零发现后关闭。
