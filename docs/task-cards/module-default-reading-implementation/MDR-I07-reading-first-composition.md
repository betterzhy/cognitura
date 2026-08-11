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
CompositionAssertion = EXACT_SCOPED_IDENTITY_COUNT_CONTENT_ORDER
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
const questions = within(main).getByRole("list", { name: "Core questions" });
const conclusion = within(main).getByRole("region", { name: "Core conclusion" });
const spine = within(main).getByRole("list", { name: "Primary cognitive spine" });
const elements = within(main).getByRole("list", { name: "Knowledge elements" });
const boundaries = within(main).getByRole("list", { name: "Critical boundaries" });
const stageChain = within(main).getByRole("list", { name: "Stage chain" });
const relations = within(main).getByRole("list", { name: "Key relations" });
const sourceEntry = within(main).getByRole("button", {
  name: `查看 ${rendererInput.sourceRefs.length} 条来源证据`,
});
const nodeById = new Map(rendererInput.nodes.map((node) => [node.nodeId, node]));

expect(screen.getAllByRole("main")).toHaveLength(1);
expect(screen.queryByRole("complementary")).toBeNull();
expect(screen.getAllByRole("button")).toHaveLength(1);
expect(document.querySelectorAll("[data-primary-visual-projection]")).toHaveLength(1);
expect(within(questions).getAllByRole("listitem").map((item) => item.textContent))
  .toEqual(module.coreQuestions);
expect(within(conclusion).getAllByText(module.thesis, { exact: true })).toHaveLength(1);
expect(within(spine).getAllByRole("listitem").map((item) =>
  [item.dataset.stepId, item.textContent]))
  .toEqual(module.primaryCognitiveSpine.steps.map((step) => [step.stepId, step.statement]));
expect(within(elements).getAllByRole("listitem").map((item) =>
  [item.dataset.elementId, item.textContent]))
  .toEqual(module.knowledgeElements.map((element) =>
    [element.artifactId, `${element.title}${element.content}`]));
expect(within(boundaries).getAllByRole("listitem").map((item) =>
  [item.dataset.boundaryId, item.textContent]))
  .toEqual(module.criticalBoundaries.map((boundary) =>
    [boundary.boundaryId, boundary.statement]));
expect(within(stageChain).getAllByRole("listitem").map((item) =>
  [item.dataset.nodeId, item.textContent]))
  .toEqual(rendererInput.nodes.map((node) =>
    [node.nodeId, `${node.label}${node.summary}`]));
expect(within(relations).getAllByRole("listitem").map((item) => [
  item.dataset.relationId,
  ...Array.from(item.querySelectorAll("[data-relation-part]"),
    (part) => part.textContent),
])).toEqual(rendererInput.relations.map((relation) => [
  relation.relationId,
  nodeById.get(relation.sourceNodeRef)?.label,
  relation.type,
  nodeById.get(relation.targetNodeRef)?.label,
]));
expect(sourceEntry).toHaveAttribute(
  "data-source-refs", JSON.stringify(rendererInput.sourceRefs));
const sectionOrder = Array.from(
  main.querySelectorAll("[data-reading-section]"),
  (section) => section.getAttribute("data-reading-section"),
);
expect(sectionOrder).toEqual([
  "questions", "conclusion", "spine", "elements", "boundaries",
  "stage-chain", "relations", "source-entry",
]);
expect(new Set(sectionOrder).size).toBe(sectionOrder.length);
expect(document.body.textContent).not.toContain("evidence.mvcc");
```

先观察组合组件不存在的 RED；随后分别删除、重复、重排每类 section，并更改一项
Canonical identity/type/source/target，四组 mutation 必须保持 RED。GREEN 按
Question/Conclusion/Spine、Element/Boundary、单一 StageChain、Relation、SourceEntry
顺序组合，CSS 只实现连续文档、可见焦点和安全单列降级。不得复制 docs-only
prototype CSS/HTML 或谓词文本作为生产事实。

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
