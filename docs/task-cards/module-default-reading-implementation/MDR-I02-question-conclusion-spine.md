# MDR-I02 Question Conclusion and Spine

```text
TaskCardID = MDR-I02
CardKind = IMPLEMENTATION
Status = BLOCKED_BY_BUSINESS_IMPLEMENTATION_AUTHORIZATION
Gate = MDR-IG2 QuestionConclusionSpine
Risk = MEDIUM
DependsOn = MDR-I01
PrimaryBoundary = WEB_READING_NARRATIVE
ProductionFileLimit = 1
BusinessImplementationAuthorization = REQUIRED_BEFORE_RELEASE
SchemaChange = FORBIDDEN
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
```

## 1. 目标

把 `MDR-I01` 的只读投影渲染成语义化的 CoreQuestion、CoreConclusion 和有序主认知
脊柱；不组合完整 Module 页面。

## 2. 前置条件与输入

`MDR-I01` 固定提交审查为零发现，且用户单独释放本卡。

## 3. 精确写集

```text
WriteSet = web/src/modules/module-reading/ModuleNarrative.tsx
WriteSet = web/src/modules/module-reading/ModuleNarrative.test.tsx
ForbiddenWriteSet = web/src/App.tsx
ForbiddenWriteSet = web/src/modules/module-reading/model.ts
ForbiddenWriteSet = schemas/**,server/**,raw/**,.idea/**
```

## 4. RED -> GREEN

RED：

```tsx
render(<ModuleNarrative projection={projection} />);
const questions = screen.getByRole("list", { name: "Core questions" });
const conclusion = screen.getByRole("region", { name: "Core conclusion" });
const spine = screen.getByRole("list", { name: "Primary cognitive spine" });
expect(within(questions).getAllByRole("listitem").map((item) => item.textContent))
  .toEqual(projection.coreQuestions);
expect(within(conclusion).getAllByText(projection.coreConclusion, { exact: true }))
  .toHaveLength(1);
expect(within(spine).getAllByRole("listitem").map((item) => item.textContent))
  .toEqual(projection.spineSteps.map((step) => step.statement));
expect(within(spine).getAllByRole("listitem").map((item) => item.dataset.stepId))
  .toEqual(projection.spineSteps.map((step) => step.stepId));
```

先运行测试，预期因组件不存在而失败。GREEN 只增加一个无本地 state 的语义组件；
Questions、Conclusion、Spine 分别投影为唯一的 `data-reading-section`，不得隐藏内容到
Tab/Accordion，不得改写句子或重新排序 Spine。

## 5. 验证命令

```bash
pnpm --dir web test -- src/modules/module-reading/ModuleNarrative.test.tsx
pnpm --dir web build
scripts/verify-high-fidelity-design
git diff --check
git status --short
```

## 6. Gate 与完成定义

零交互可见、DOM 顺序等于 Canonical 顺序、没有模式开关/侧栏/网络调用；生产文件 1 个。

## 7. 提交与独立固定提交审查

```bash
git add web/src/modules/module-reading/ModuleNarrative.tsx \
  web/src/modules/module-reading/ModuleNarrative.test.tsx
git commit -m "feat: render module question conclusion and spine"
```

新的 `deep_reviewer` 对固定 SHA 作独立零发现审查；不得自动释放 `MDR-I03`。
