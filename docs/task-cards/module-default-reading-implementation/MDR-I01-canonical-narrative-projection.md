# MDR-I01 Canonical Narrative Projection

```text
TaskCardID = MDR-I01
CardKind = IMPLEMENTATION
Status = BLOCKED_BY_BUSINESS_IMPLEMENTATION_AUTHORIZATION
Gate = MDR-IG1 CanonicalNarrativeProjection
Risk = HIGH
DependsOn = MDR-I00
PrimaryBoundary = WEB_CANONICAL_PROJECTION
ProductionFileLimit = 2
BusinessImplementationAuthorization = REQUIRED_BEFORE_RELEASE
SchemaChange = FORBIDDEN
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
```

## 1. 目标

实现首张业务卡：把已发布 `CognitiveModule` 的既有核心问题、结论和主认知脊柱
无重排地投影为只读前端模型。它不是 React 页面，也不接 Renderer、HTTP 或存储。

## 2. 前置条件与输入

- `MDR-I00` 固定提交审查为零发现。
- 用户另行明确授权并释放本卡。
- 字段唯一来源为 `schemas/cognition/cognitive-module.schema.json` 与
  `schemas/cognition/primary-cognitive-spine.schema.json`。

## 3. 精确写集

```text
WriteSet = web/src/modules/module-reading/model.ts
WriteSet = web/src/modules/module-reading/projectModuleNarrative.ts
WriteSet = web/src/modules/module-reading/projectModuleNarrative.test.ts
ForbiddenWriteSet = web/src/App.tsx,web/src/main.tsx
ForbiddenWriteSet = schemas/**,server/**,raw/**,.idea/**
```

## 4. RED -> GREEN

RED 使用能通过正式 Schema 的 Published 内存 fixture：其 `primaryCognitiveSpine.steps`
恰含四个完整 step。断言值、数量、顺序和对象身份均保持 Canonical 输入：

```ts
const schemaValidSteps = [firstStep, secondStep, thirdStep, fourthStep];
const projection = projectModuleNarrative({
  ...module,
  publicationState: "PUBLISHED",
  primaryCognitiveSpine: { ...spine, steps: schemaValidSteps },
});

expect(projection).toEqual({
  moduleRef: "module.mvcc",
  title: "MVCC",
  coreQuestions: ["How does a read choose a visible version?"],
  coreConclusion: "MVCC coordinates readers and writers.",
  spineSteps: schemaValidSteps,
});
expect(projection.spineSteps).toHaveLength(4);
projection.spineSteps.forEach((step, index) =>
  expect(step).toBe(schemaValidSteps[index]));
expect(() => projectModuleNarrative({ ...module, publicationState: "DRAFT" }))
  .toThrow("MODULE_READING_REQUIRES_PUBLISHED_CANONICAL_MODULE");
```

先运行目标测试，预期因 `projectModuleNarrative` 不存在而 RED。GREEN 仅定义与当前
Schema 同名的只读输入类型和纯函数；`coreConclusion` 只能引用 `thesis`，
`spineSteps` 必须保留输入顺序和对象身份，不生成或补写任何陈述。

## 5. 验证命令

```bash
pnpm --dir web test -- src/modules/module-reading/projectModuleNarrative.test.ts
pnpm --dir web build
bash tests/contracts/schema/verify-json-schemas.sh
scripts/verify-high-fidelity-design
git diff --check
git status --short
```

## 6. Gate 与完成定义

Schema-valid Published 正例 PASS 且 4..9 个 Spine step 全量保持身份和顺序；
Draft/Confirmed 负例 fail closed；无排序、摘要、Condition/Result 猜测或第二事实模型；
生产文件为 2 个。

## 7. 提交与独立固定提交审查

```bash
git add web/src/modules/module-reading/model.ts \
  web/src/modules/module-reading/projectModuleNarrative.ts \
  web/src/modules/module-reading/projectModuleNarrative.test.ts
git commit -m "feat: project canonical module reading narrative"
```

新的 `deep_reviewer` 对固定 SHA 审查 Canonical 来源、顺序和 fail-closed 边界；只有
零发现 GO 才能关闭本卡，不自动释放下一卡。
