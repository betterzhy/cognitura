# MDR-I03 Element and Boundary Reading

```text
TaskCardID = MDR-I03
CardKind = IMPLEMENTATION
Status = BLOCKED_BY_USER_APPROVAL
Gate = MDR-IG3 ElementBoundaryReading
Risk = HIGH
DependsOn = MDR-I02
PrimaryBoundary = WEB_MODULE_CLOSURE_PROJECTION
ProductionFileLimit = 3
BusinessImplementationAuthorization = REQUIRED_BEFORE_RELEASE
SchemaChange = FORBIDDEN
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
```

## 1. 目标

增加连续的 KnowledgeElement 与 CriticalBoundary 阅读段落；只显示已有正式字段，
不把 Element 猜测成 Condition 或 Result。

## 2. 前置条件与输入

`MDR-I02` 固定提交审查为零发现，且用户单独释放本卡。

## 3. 精确写集

```text
WriteSet = web/src/modules/module-reading/model.ts
WriteSet = web/src/modules/module-reading/projectModuleNarrative.ts
WriteSet = web/src/modules/module-reading/ModuleClosure.tsx
WriteSet = web/src/modules/module-reading/ModuleClosure.test.tsx
ForbiddenWriteSet = schemas/**,server/**,raw/**,.idea/**
ForbiddenSemanticLabel = Conditions,Results
```

## 4. RED -> GREEN

RED：

```tsx
render(<ModuleClosure elements={projection.knowledgeElements}
  boundaries={projection.criticalBoundaries} />);
const elements = screen.getByRole("list", { name: "Knowledge elements" });
const boundaries = screen.getByRole("list", { name: "Critical boundaries" });
expect(within(elements).getAllByRole("listitem").map((item) => item.textContent))
  .toEqual(projection.knowledgeElements.map((item) => `${item.title}${item.content}`));
expect(within(elements).getAllByRole("listitem").map((item) => item.dataset.elementId))
  .toEqual(projection.knowledgeElements.map((item) => item.artifactId));
expect(within(boundaries).getAllByRole("listitem").map((item) => item.textContent))
  .toEqual(projection.criticalBoundaries.map((item) => item.statement));
expect(within(boundaries).getAllByRole("listitem").map((item) => item.dataset.boundaryId))
  .toEqual(projection.criticalBoundaries.map((item) => item.boundaryId));
expect(screen.queryByRole("heading", { name: /Conditions|Results/ })).toBeNull();
```

先观察缺少字段/组件的 RED。GREEN 扩展纯投影以传递原始 Element 与 Boundary，再用
两个唯一的 `data-reading-section` 连续渲染全部输入；不得卡片墙化、摘要化或生成新
语义标签。

## 5. 验证命令

```bash
pnpm --dir web test -- src/modules/module-reading/ModuleClosure.test.tsx \
  src/modules/module-reading/projectModuleNarrative.test.ts
pnpm --dir web build
bash tests/contracts/schema/verify-json-schemas.sh
scripts/verify-high-fidelity-design
git diff --check
git status --short
```

## 6. Gate 与完成定义

每个显示文本都能追溯到 `knowledgeElements` 或 `criticalBoundaries`；没有 Condition/
Result 推断、卡片网格、交互或状态写入。

## 7. 提交与独立固定提交审查

```bash
git add web/src/modules/module-reading/model.ts \
  web/src/modules/module-reading/projectModuleNarrative.ts \
  web/src/modules/module-reading/ModuleClosure.tsx \
  web/src/modules/module-reading/ModuleClosure.test.tsx
git commit -m "feat: project module elements and boundaries"
```

新的 `deep_reviewer` 对固定 SHA 检查 Schema 追溯与禁止语义推断；零发现后才可关闭。
