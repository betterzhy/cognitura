# Cognitura Renderer 契约

```text
DecisionDate = 2026-07-28
CanonicalProjectName = Cognitura
ContractScope = W0-06_NON_SCHEMA_RENDERER_CONTRACT
AuthoritativeSource = Cognitura-Overall-Design-1.2§20.8
RendererCreatesIndependentFacts = NO
RendererSchemaStatus = READY_UNDER_COGNITURA_SCHEMA_BASELINE_2_0
FieldLevelSchemaAuthority = Cognitura-Schema-Baseline-2.0
HighFidelityReadingPresentationGate = HF-DG1 PASS
HighFidelityRefinementSource = Cognitura-High-Fidelity-Interaction-Specialty-1.0§11-12
HighFidelityRefinementBoundary = PRESENTATION_BUDGET_ONLY_RENDERER_FACT_MODEL_UNCHANGED
```

Renderer 只投影正式 CognitiveModule 内容，不创建第二套事实。本文件固定组件
类型、概念输入能力和验收不变量；它不是 Renderer 输入 JSON Schema。
高保真专项候选只细化默认呈现预算，Overall 1.2 仍作为 Wave 0 manifest 固定的只读
产品权威；本卡不改写其历史反向迁移记录。

## 1. 正式 Renderer

```text
RendererContract = HIERARCHY|HierarchyRenderer|OD1.2§20.8|PROJECTS_COGNITIVE_MODULE
RendererContract = MATRIX|MatrixRenderer|OD1.2§20.8|PROJECTS_COGNITIVE_MODULE
RendererContract = STAGE_CHAIN|StageChainRenderer|OD1.2§20.8|PROJECTS_COGNITIVE_MODULE
RendererContract = DECISION_PATH|DecisionPathRenderer|OD1.2§20.8|PROJECTS_COGNITIVE_MODULE
RendererContract = STATE_TRANSITION|StateTransitionRenderer|OD1.2§20.8|PROJECTS_COGNITIVE_MODULE
RendererContract = COMPARISON|ComparisonRenderer|OD1.2§20.8|PROJECTS_COGNITIVE_MODULE
RendererContract = CAUSAL_CHAIN|CausalChainRenderer|OD1.2§20.8|PROJECTS_COGNITIVE_MODULE
RendererContract = LAYERED_STRUCTURE|LayeredStructureRenderer|OD1.2§20.8|PROJECTS_COGNITIVE_MODULE
RendererContract = STRUCTURED_PANEL|StructuredPanelRenderer|OD1.2§20.8|PROJECTS_COGNITIVE_MODULE
```

## 2. 统一输入能力

总体设计只给出下列概念字段名，没有给出类型、必填性、枚举、对象层次、关系约束
或示例。因此每项都标记为 `CONCEPT_ONLY`：

```text
RendererInputCapability = RENDERER_TYPE|CONCEPT_ONLY|OD1.2§20.8
RendererInputCapability = TITLE|CONCEPT_ONLY|OD1.2§20.8
RendererInputCapability = SUMMARY|CONCEPT_ONLY|OD1.2§20.8
RendererInputCapability = NODES|CONCEPT_ONLY|OD1.2§20.8
RendererInputCapability = GROUPS|CONCEPT_ONLY|OD1.2§20.8
RendererInputCapability = RELATIONS|CONCEPT_ONLY|OD1.2§20.8
RendererInputCapability = SOURCE_REFS|CONCEPT_ONLY|OD1.2§20.8
RendererInputCapability = INCOMPLETE_STATE|CONCEPT_ONLY|OD1.2§20.8
RendererInputCapability = INTERACTION_HINTS|CONCEPT_ONLY|OD1.2§20.8
```

W0-06 不得从这些名称推断 JSON Schema。上述历史缺口已由用户批准的
`Cognitura-Schema-Baseline-2.0` 形成字段级工程裁决；W0-04 只能按该正式
重基线实施，不得从本文件的概念字段另行推断。

## 3. 投影不变量

```text
RendererInvariant = CREATES_INDEPENDENT_FACTS|NO|OD1.2§20.8
RendererInvariant = PROJECTION_SOURCE|COGNITIVE_MODULE|OD1.2§20.8
RendererInvariant = SEMANTIC_REORDERING|FORBIDDEN|OD1.2§20.8
RendererInvariant = DENSITY_OVERFLOW_HANDLING|GROUP_FOLD_OR_STAGE|OD1.2§20.8
RendererInvariant = NARROW_SCREEN_FEATURE_PARITY|NOT_REQUIRED|OD1.2§20.8
```

高显著性视觉投影的稳定非 Schema 预算为：

```text
RendererPresentationBudget = PRIMARY_VISUAL_PRIMITIVE_FAMILIES_PER_MODULE|AT_MOST_4|HF-SPECIALTY§11,12
RendererPresentationBudget = PRIMARY_VISUAL_PROJECTION_PER_COGNITIVE_SECTION|AT_MOST_1|HF-SPECIALTY§11,12
RendererPresentationBudget = SIMULTANEOUSLY_EMPHASIZED_VISUAL_OBJECTS|AT_MOST_7|HF-SPECIALTY§11,12
```

`CognitiveSection`、`PrimaryVisualProjection`、`PrimaryVisualPrimitiveFamily`、
`SimultaneouslyEmphasizedVisualObject` 和 `PrimaryAction` 的统计口径由高保真交互
专项候选定义。本文仅投影上限与不创造事实的稳定不变量，不由这些名称
推导字段、枚举、JSON Schema 或物理对象。

- 节点超过认知密度上限时必须分组、折叠或拆成阶段。
- 节点可以展开详情并显示来源标记。
- 不得为了图形美观改变认知顺序或语义关系。
- 大型 Matrix、LayeredStructure 和 StateTransition 以桌面浏览器验收。
- 窄屏只保证可读、横向滚动或纵向降级，不要求功能等价。

## 4. 来源与缺口边界

```text
ContractCoverage = UI-RENDERER|COVERED_BY_REVERSE_MIGRATION|OD1.2§20.8
DocumentationGapRecord = DOC-GAP-001|OPEN|HISTORICAL_RENDERER_SPECIALTY_BODY_MISSING|EXECUTION_DISPOSITION_REBASELINED
DocumentationGapRecord = DOC-GAP-002|OPEN|UIUX_SPECIALTY_BODY_MISSING|NON_SCHEMA_CONTRACTS_ONLY
SchemaRebaselineDisposition = DOC-GAP-001|RESOLVED_FOR_W0-G3_EXECUTION|Cognitura-Schema-Baseline-2.0
```

`DOC-GAP-001` 和 `DOC-GAP-002` 作为缺失历史专项正文的事实记录继续保持
开放；其中 `DOC-GAP-001` 的 W0-G3 执行阻断已由正式重基线解除，
`DOC-GAP-002` 未解除。本文不替代缺失专项正文，也不授权实现 React Renderer、
产品页面或业务数据转换。
