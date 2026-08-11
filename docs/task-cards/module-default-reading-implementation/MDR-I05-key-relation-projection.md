# MDR-I05 Key Relation Projection

```text
TaskCardID = MDR-I05
CardKind = IMPLEMENTATION
Status = BLOCKED_BY_USER_APPROVAL
Gate = MDR-IG5 KeyRelationProjection
Risk = HIGH
DependsOn = MDR-I04
PrimaryBoundary = WEB_RELATION_PROJECTION
ProductionFileLimit = 2
BusinessImplementationAuthorization = REQUIRED_BEFORE_RELEASE
SchemaChange = FORBIDDEN
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
RelationDisplay = CANONICAL_TYPE_TOKEN
```

## 1. 目标

从同一个 `RendererInput` 内联显示一至三条已选 Relation；不从 `CognitiveModule` 的
最多五条 Relation 自行判断“关键性”。

## 2. 前置条件与输入

`MDR-I04` 固定提交审查为零发现；RendererInput 的 node 与 relation 引用完整。

## 3. 精确写集

```text
WriteSet = web/src/modules/module-reading/model.ts
WriteSet = web/src/modules/module-reading/KeyRelations.tsx
WriteSet = web/src/modules/module-reading/KeyRelations.test.tsx
ForbiddenWriteSet = schemas/**,server/**,raw/**,.idea/**
RelationSelection = RENDERER_INPUT_AUTHORITATIVE
```

## 4. RED -> GREEN

RED：

```tsx
render(<KeyRelations input={rendererInputWithTwoRelations} />);
const relationList = screen.getByRole("list", { name: "Key relations" });
const relationItems = within(relationList).getAllByRole("listitem");
const nodeById = new Map(rendererInput.nodes.map((node) => [node.nodeId, node]));
expect(relationItems).toHaveLength(rendererInput.relations.length);
expect(relationItems.map((item) => item.dataset.relationId))
  .toEqual(rendererInput.relations.map((relation) => relation.relationId));
expect(relationItems.map((item) =>
  Array.from(item.querySelectorAll("[data-relation-part]"), (part) => part.textContent)))
  .toEqual(rendererInput.relations.map((relation) => [
    nodeById.get(relation.sourceNodeRef)?.label,
    relation.type,
    nodeById.get(relation.targetNodeRef)?.label,
  ]));
expect(() => render(<KeyRelations input={rendererInputWithFourRelations} />))
  .toThrow("MODULE_DEFAULT_READING_RELATION_BUDGET_EXCEEDED");
```

GREEN 只能用 renderer node label 解析端点，并逐字投影正式 `RelationType` token；当前
没有获授权的本地化谓词映射，不得把 docs-only prototype 文本或自定义显示词带入生产。
每项保留 `relationId`、source/target node ref 与 type 的机器属性。缺失端点、未知 type、
0 条或超过 3 条均 fail closed，不把技术对象 ID 当成可见端点文本。

## 5. 验证命令

```bash
pnpm --dir web test -- src/modules/module-reading/KeyRelations.test.tsx
pnpm --dir web build
bash tests/contracts/schema/verify-json-schemas.sh
bash tests/contracts/ui/verify-ui-contracts.sh
scripts/verify-high-fidelity-design
git diff --check
git status --short
```

## 6. Gate 与完成定义

Relation 数量为 1..3，identity、type、方向和端点来自同一 RendererInput，技术 ID
默认静默，不出现本地化语义发明、自动排序、自动选 key relation 或第二事实。

## 7. 提交与独立固定提交审查

```bash
git add web/src/modules/module-reading/model.ts \
  web/src/modules/module-reading/KeyRelations.tsx \
  web/src/modules/module-reading/KeyRelations.test.tsx
git commit -m "feat: project key module relations inline"
```

新的 `deep_reviewer` 对固定 SHA 审查 Relation 身份、方向、预算和失败闭合。
