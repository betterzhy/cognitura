# MDR-I07 Reading First Composition

```text
TaskCardID = MDR-I07
CardKind = IMPLEMENTATION
Status = BLOCKED_BY_USER_APPROVAL
Gate = MDR-IG7 ReadingFirstComposition
Risk = HIGH
DependsOn = MDR-I06
PrimaryBoundary = WEB_MODULE_READING_COMPONENT
ProductionFileLimit = 3
BusinessImplementationAuthorization = REQUIRED_BEFORE_RELEASE
SchemaChange = FORBIDDEN
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
```

## 1. 目标

组合前序组件为可复用 `ModuleDefaultReading`；不挂载 `App.tsx`、路由或数据获取，
不声明完整页面或全部 Renderer 已实现。

## 2. 前置条件与输入

`MDR-I06` 固定提交审查为零发现；用户单独释放本卡。

## 3. 精确写集

```text
WriteSet = web/src/modules/module-reading/ModuleDefaultReading.tsx
WriteSet = web/src/modules/module-reading/module-default-reading.css
WriteSet = web/src/modules/module-reading/index.ts
WriteSet = web/src/modules/module-reading/ModuleDefaultReading.test.tsx
ForbiddenWriteSet = web/src/App.tsx,web/src/main.tsx,web/vite.config.mjs
ForbiddenWriteSet = server/**,schemas/**,raw/**,.idea/**
```

## 4. RED -> GREEN

RED：

```tsx
render(<ModuleDefaultReading module={module} rendererInput={rendererInput} />);
const main = screen.getByRole("main", { name: module.title });
const spine = within(main).getByRole("list", { name: "Primary cognitive spine" });
const stageChain = within(main).getByRole("list", { name: "Stage chain" });
const relations = within(main).getByRole("list", { name: "Key relations" });

expect(screen.getAllByRole("main")).toHaveLength(1);
expect(screen.queryByRole("complementary")).toBeNull();
expect(screen.getAllByRole("button")).toHaveLength(1);
expect(document.querySelectorAll("[data-primary-visual-projection]")).toHaveLength(1);
expect(within(spine).getAllByRole("listitem"))
  .toHaveLength(module.primaryCognitiveSpine.steps.length);
expect(within(stageChain).getAllByRole("listitem"))
  .toHaveLength(rendererInput.nodes.length);
expect(within(relations).getAllByRole("listitem"))
  .toHaveLength(rendererInput.relations.length);

const expectedRelationTexts = [
  "Read View 约束 记录版本可见性",
  "隔离级别 影响 快照创建时机",
];
const expectedDocumentOrder = [
  module.coreQuestions[0],
  module.thesis,
  ...module.primaryCognitiveSpine.steps.map((step) => step.statement),
  ...module.knowledgeElements.flatMap((element) => [element.title, element.content]),
  ...module.criticalBoundaries.map((boundary) => boundary.statement),
  ...rendererInput.nodes.flatMap((node) => [node.label, node.summary]),
  ...expectedRelationTexts,
  "查看 1 条来源证据",
];
let previousIndex = -1;
for (const canonicalText of expectedDocumentOrder) {
  const nextIndex = main.textContent?.indexOf(canonicalText) ?? -1;
  expect(nextIndex).toBeGreaterThan(previousIndex);
  previousIndex = nextIndex;
}
expect(document.body.textContent).not.toContain("evidence.mvcc");
```

先观察组合组件不存在的 RED。GREEN 按 Question/Conclusion/Spine、Element/Boundary、
单一 StageChain、Relation、SourceEntry 顺序组合，CSS 只实现连续文档、可见焦点和
安全单列降级。不得复制 docs-only prototype CSS/HTML 作为生产事实。

## 5. 验证命令

```bash
pnpm --dir web test -- src/modules/module-reading
pnpm --dir web build
bash tests/contracts/schema/verify-json-schemas.sh
bash tests/contracts/ui/verify-ui-contracts.sh
scripts/verify-wave0
scripts/verify-wave1-design
scripts/verify-high-fidelity-design
scripts/verify-high-fidelity-visual
git diff --check
git status --short
```

## 6. Gate 与完成定义

Question、Conclusion、全部 Spine steps、Element、Boundary、单一 StageChain、全部
已选 Relation 和 SourceEntry 均按固定文档顺序出现；连续文档、0 常驻侧栏、1 个主
投影、仅 1 个来源按钮、焦点可见、窄屏安全可读。`App.tsx` 不变，HTTP/后端/
持久化/Schema 均不存在。Condition/Result 显式栏目与其他八类 Renderer 继续未实现，
因此 `ImplementationValidation = NOT_RUN`。

## 7. 提交与独立固定提交审查

```bash
git add web/src/modules/module-reading/ModuleDefaultReading.tsx \
  web/src/modules/module-reading/module-default-reading.css \
  web/src/modules/module-reading/index.ts \
  web/src/modules/module-reading/ModuleDefaultReading.test.tsx
git commit -m "feat: compose module default reading slice"
```

新的 `deep_reviewer` 对固定 SHA 审查范围、DOM、预算、Schema/DB 零写入和回归；
零发现后仍不得跳过 `MDR-I08`。
