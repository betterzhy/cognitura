# MDR-I06 Source Entry Projection

```text
TaskCardID = MDR-I06
CardKind = IMPLEMENTATION
Status = GOVERNED_BY_EXECUTION_STATE
ExecutionStateAuthority = docs/task-cards/module-default-reading-implementation/execution-state.md
Gate = MDR-IG6 SourceEntryProjection
Risk = MEDIUM
DependsOn = MDR-I05
PrimaryBoundary = WEB_SOURCE_ENTRY_PROJECTION
ProductionFileLimit = 1
BusinessImplementationAuthorization = REQUIRED_BEFORE_RELEASE
SchemaChange = FORBIDDEN
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
```

## 1. 目标

增加轻量、按需的来源入口；不实现 QuickSourcePanel、SourceEvidence 路由或来源内容。

## 2. 前置条件与输入

execution-state 账本已记录 `MDR-I05` 固定提交零发现收据，并把本卡投影为唯一活动且
已释放卡；来源 ID 来自 RendererInput `sourceRefs`。

## 3. 精确写集

```text
WriteSet = web/src/modules/module-reading/SourceEntry.tsx
WriteSet = web/src/modules/module-reading/SourceEntry.test.tsx
ForbiddenWriteSet = web/src/modules/source-evidence/**
ForbiddenWriteSet = schemas/**,server/**,raw/**,.idea/**
```

## 4. RED -> GREEN

RED：

```tsx
render(<SourceEntry sourceRefs={["evidence.mvcc"]} />);
const button = screen.getByRole("button", { name: "查看 1 条来源证据" });
expect(button).toBeVisible();
expect(button).toHaveAttribute("data-source-refs", '["evidence.mvcc"]');
expect(screen.queryByText("evidence.mvcc")).toBeNull();
expect(screen.queryByRole("complementary")).toBeNull();
```

GREEN 只渲染一个语义 button，把 refs 作为机器属性供后续路由消费；不得读取来源、
联网、展开侧栏、显示原始 ID 或持久化状态，并输出唯一
`data-reading-section="source-entry"`。空 refs 必须 fail closed。

## 5. 验证命令

```bash
pnpm --dir web test -- src/modules/module-reading/SourceEntry.test.tsx
pnpm --dir web build
bash tests/contracts/ui/verify-ui-contracts.sh
scripts/verify-high-fidelity-design
git diff --check
git status --short
```

## 6. Gate 与完成定义

来源入口可键盘聚焦、默认不展开、无 `aside`/网络/存储，且没有原始来源 ID 可见文本。

## 7. 提交与独立固定提交审查

```bash
git add web/src/modules/module-reading/SourceEntry.tsx \
  web/src/modules/module-reading/SourceEntry.test.tsx
git commit -m "feat: add on-demand module source entry"
```

新的 `deep_reviewer` 对固定 SHA 审查来源边界、可访问性和零副作用。
