# Cognitura 专项契约覆盖矩阵

```text
CanonicalProjectName = Cognitura
CoverageBaseline = Cognitura-Overall-Design-1.2
CoverageScope = NON_SCHEMA_CONTRACTS_AND_SCHEMA_SOURCE_GAPS
ConstructionReverseMigration = 11/11
UIReverseMigration = 10/10
PlatformScopeMigration = 5/5
DocumentationGapCount = 2
W0-G2 SpecialtyContractCoverage = PASS
```

本矩阵只登记总体设计 1.2 已经落地的正式证据及仍然存在的来源缺口，不复制专项
正文，不把工程归纳伪装成历史专项设计。字段级 Schema 已取得
`Cognitura-Schema-Baseline-2.0` 的明确重基线处置；W0-04 已完成机器 Schema、
逐字段 Evidence Map、结构正反例和跨对象语义反例验证。

## 1. 证据规则

- `COVERED_BY_REVERSE_MIGRATION` 只表示非 Schema 产品或交互契约已在总体设计
  正文中出现。
- `SCHEMA_SOURCE_MISSING` 表示字段、类型、required/optional、枚举、约束、
  示例或逐阶段细则缺少权威专项正文。
- 总体设计明确记录构造专项 `RM-01～RM-11 = APPLIED`，但没有给出单个 RM
  编号的官方名称或逐编号章节绑定。因此本矩阵分别登记迁移清单与主题契约，
  不制造一一对应关系。
- UI 与平台范围迁移在总体设计 27.2～27.3 节给出了名称，可以逐项绑定正文。

## 2. 构造专项迁移清单

| 迁移 ID | 正式状态 | 正式证据 | 逐 ID 主题绑定 |
|---|---|---|---|
| `RM-01` | `APPLIED` | 总体设计 27.1 | `NOT_EXPOSED_BY_OVERALL_DESIGN` |
| `RM-02` | `APPLIED` | 总体设计 27.1 | `NOT_EXPOSED_BY_OVERALL_DESIGN` |
| `RM-03` | `APPLIED` | 总体设计 27.1 | `NOT_EXPOSED_BY_OVERALL_DESIGN` |
| `RM-04` | `APPLIED` | 总体设计 27.1 | `NOT_EXPOSED_BY_OVERALL_DESIGN` |
| `RM-05` | `APPLIED` | 总体设计 27.1 | `NOT_EXPOSED_BY_OVERALL_DESIGN` |
| `RM-06` | `APPLIED` | 总体设计 27.1 | `NOT_EXPOSED_BY_OVERALL_DESIGN` |
| `RM-07` | `APPLIED` | 总体设计 27.1 | `NOT_EXPOSED_BY_OVERALL_DESIGN` |
| `RM-08` | `APPLIED` | 总体设计 27.1 | `NOT_EXPOSED_BY_OVERALL_DESIGN` |
| `RM-09` | `APPLIED` | 总体设计 27.1 | `NOT_EXPOSED_BY_OVERALL_DESIGN` |
| `RM-10` | `APPLIED` | 总体设计 27.1 | `NOT_EXPOSED_BY_OVERALL_DESIGN` |
| `RM-11` | `APPLIED` | 总体设计 27.1 | `NOT_EXPOSED_BY_OVERALL_DESIGN` |

总体设计 1.1 节给出构造专项的聚合回迁范围，27.1 节给出 11/11 应用状态。
`RM_ID_TO_TOPIC_SOURCE_MISSING` 是证据精度限制，不代表非 Schema 契约缺失。

## 3. 构造专项主题契约覆盖

| 契约 ID | 契约组 | 总体设计证据 | 覆盖状态 | Schema 缺口 |
|---|---|---|---|---|
| `KSC-HIERARCHY` | 四层层级、升降级、角色、UnderstandingRoute | 5～7.1 | `COVERED_BY_REVERSE_MIGRATION` | `NONE` |
| `KSC-SPINE-AND-CLOSURE` | PrimaryCognitiveSpine、Module/Theme/Landscape Closure | 8～9、15～16 | `COVERED_BY_REVERSE_MIGRATION` | `NONE` |
| `KSC-SOURCE-AND-MERGE` | 来源忠实重构、多文档归并、唯一主归属 | 12～14 | `COVERED_BY_REVERSE_MIGRATION` | `NONE` |
| `KSC-TEN-ARTIFACTS` | 十项正式认知产物总体契约 | 19 | `COVERED_BY_REVERSE_MIGRATION` | `DOC-GAP-001` |
| `KSC-GENERATION` | 两阶段生成、阶段保存、局部失败和重试 | 17 | `COVERED_BY_REVERSE_MIGRATION` | `DOC-GAP-001` |
| `KSC-DENSITY-AND-RENDERING` | 认知密度、阅读投影、表达形式选择 | 10～11、20 | `COVERED_BY_REVERSE_MIGRATION` | `NONE` |
| `KSC-REVISION` | 结构操作、版本状态、最小重生成范围 | 18 | `COVERED_BY_REVERSE_MIGRATION` | `NONE` |
| `KSC-GOLDEN-CASE` | 质量维度、硬失败、三份 Golden Case | 21 | `COVERED_BY_REVERSE_MIGRATION` | `DOC-GAP-001` |

这些章节足以继续非 Schema Wave 0 工作；它们不足以自行扩写十项产物、生成记录
或 Renderer 输入的完整字段级 Schema。

## 4. UI/UX 与平台范围覆盖

| 迁移 ID | 正式主题 | 总体设计证据 | 覆盖状态 |
|---|---|---|---|
| `UI-RM-01` | 页面信息架构 | 20.2、27.2 | `COVERED_BY_REVERSE_MIGRATION` |
| `UI-RM-02` | 核心用户流程 | 20.3、27.2 | `COVERED_BY_REVERSE_MIGRATION` |
| `UI-RM-03` | Skeleton Review | 20.4、27.2 | `COVERED_BY_REVERSE_MIGRATION` |
| `UI-RM-04` | Landscape 页面 | 20.5、27.2 | `COVERED_BY_REVERSE_MIGRATION` |
| `UI-RM-05` | Theme Detail 页面 | 20.6、27.2 | `COVERED_BY_REVERSE_MIGRATION` |
| `UI-RM-06` | Module Reading 页面 | 20.7、27.2 | `COVERED_BY_REVERSE_MIGRATION` |
| `UI-RM-07` | Renderer 组件体系 | 20.8、27.2 | `COVERED_BY_REVERSE_MIGRATION` |
| `UI-RM-08` | Source Evidence 交互 | 20.9、27.2 | `COVERED_BY_REVERSE_MIGRATION` |
| `UI-RM-09` | 页面状态与错误模型 | 20.10、27.2 | `COVERED_BY_REVERSE_MIGRATION` |
| `UI-RM-10` | MVP 页面范围 | 24～25、27.2 | `COVERED_BY_REVERSE_MIGRATION` |
| `UI-SCOPE-RM-01` | Web Browser 交付 | 20.11、27.3 | `COVERED_BY_REVERSE_MIGRATION` |
| `UI-SCOPE-RM-02` | Desktop Web 正式体验 | 20.11、27.3 | `COVERED_BY_REVERSE_MIGRATION` |
| `UI-SCOPE-RM-03` | 基础响应式安全 | 20.11、27.3 | `COVERED_BY_REVERSE_MIGRATION` |
| `UI-SCOPE-RM-04` | 原生 App 与专用移动端延后 | 20.11、27.3 | `COVERED_BY_REVERSE_MIGRATION` |
| `UI-SCOPE-RM-05` | 移动端不要求功能等价 | 20.11、27.3 | `COVERED_BY_REVERSE_MIGRATION` |

UI 主题契约按页面、Renderer、Source Evidence、状态、MVP 范围和 Desktop Web
边界拆成 11 个机器校验记录。Renderer 的非 Schema 投影约束已覆盖；字段级
Renderer Schema 已由批准的 2.0 重基线投影，W0-04 修复候选本地验证已通过，
但 W0-G3 仍等待固定提交深审；历史专项正文缺失事实仍关联 `DOC-GAP-001`。

## 5. DocumentationGap

| Gap ID | 状态 | 影响 | 唯一合法处置策略 | Gate 影响 |
|---|---|---|---|---|
| `DOC-GAP-001` | `OPEN` | 构造专项正文缺失；字段、类型、required/optional、枚举、约束、示例、生成阶段输入输出和质量细则为 `SCHEMA_SOURCE_MISSING` | 落地并校验权威构造专项正文，或取得明确批准的 Schema 重基线设计 | 阻断 `W0-G3` |
| `DOC-GAP-002` | `OPEN` | UI/UX 专项正文缺失；页面、Renderer、Source Evidence、状态和 Desktop Web 非 Schema 契约已由回迁正文覆盖 | 落地并校验权威 UI/UX 正文，或取得明确批准的重基线记录 | 不阻断 `W0-G2` 或页面契约基线 |

`DOC-GAP-001` 的历史正文缺失事实继续保持 `OPEN`，但其唯一合法处置已经由
`Cognitura-Schema-Baseline-2.0` 满足；其对 W0-04 执行的来源阻断已经关闭，
机器实现修复候选正在固定提交审查，尚未据此关闭 `W0-G3`。
`DOC-GAP-002` 继续开放。

```text
SchemaImplementationRecord = W0-04|Draft2020-12|14|13|18|12-STRICT|2-VALID-CONTEXT|32-SEMANTIC|617-EVIDENCE|3-EVIDENCE-NEGATIVE|Ajv-8.20.0|IN_REVIEW
```

```text
SchemaRebaselineApprovalRecord = DOC-GAP-001|Cognitura-Schema-Baseline-2.0|docs/design/cognitura-schema-baseline-2.0.md|d7f2a83ea2c0252478341d5e2cb37df1ee38798d1b7b4b5a8f96f9b3ef0cc1d4|APPROVED|W0-04_READY
```

## 6. 机器校验记录

以下记录是本矩阵的机器入口。字段顺序固定为：

```text
MigrationRecord =
  migrationId|domain|sourceSection|status

ContractCoverageRecord =
  contractId|domain|sourceSection|coverageStatus|schemaGap

DocumentationGapRecord =
  gapId|missingBody|state|impact|disposition|gateEffect

EvidenceLimitRecord =
  limitId|state|sourceSection|limitation|handling
```

```text
MigrationRecord = RM-01|CONSTRUCTION|OD1.2§27.1|APPLIED
MigrationRecord = RM-02|CONSTRUCTION|OD1.2§27.1|APPLIED
MigrationRecord = RM-03|CONSTRUCTION|OD1.2§27.1|APPLIED
MigrationRecord = RM-04|CONSTRUCTION|OD1.2§27.1|APPLIED
MigrationRecord = RM-05|CONSTRUCTION|OD1.2§27.1|APPLIED
MigrationRecord = RM-06|CONSTRUCTION|OD1.2§27.1|APPLIED
MigrationRecord = RM-07|CONSTRUCTION|OD1.2§27.1|APPLIED
MigrationRecord = RM-08|CONSTRUCTION|OD1.2§27.1|APPLIED
MigrationRecord = RM-09|CONSTRUCTION|OD1.2§27.1|APPLIED
MigrationRecord = RM-10|CONSTRUCTION|OD1.2§27.1|APPLIED
MigrationRecord = RM-11|CONSTRUCTION|OD1.2§27.1|APPLIED
MigrationRecord = UI-RM-01|UIUX|OD1.2§20.2,27.2|APPLIED
MigrationRecord = UI-RM-02|UIUX|OD1.2§20.3,27.2|APPLIED
MigrationRecord = UI-RM-03|UIUX|OD1.2§20.4,27.2|APPLIED
MigrationRecord = UI-RM-04|UIUX|OD1.2§20.5,27.2|APPLIED
MigrationRecord = UI-RM-05|UIUX|OD1.2§20.6,27.2|APPLIED
MigrationRecord = UI-RM-06|UIUX|OD1.2§20.7,27.2|APPLIED
MigrationRecord = UI-RM-07|UIUX|OD1.2§20.8,27.2|APPLIED
MigrationRecord = UI-RM-08|UIUX|OD1.2§20.9,27.2|APPLIED
MigrationRecord = UI-RM-09|UIUX|OD1.2§20.10,27.2|APPLIED
MigrationRecord = UI-RM-10|UIUX|OD1.2§24-25,27.2|APPLIED
MigrationRecord = UI-SCOPE-RM-01|UI_SCOPE|OD1.2§20.11,27.3|APPLIED
MigrationRecord = UI-SCOPE-RM-02|UI_SCOPE|OD1.2§20.11,27.3|APPLIED
MigrationRecord = UI-SCOPE-RM-03|UI_SCOPE|OD1.2§20.11,27.3|APPLIED
MigrationRecord = UI-SCOPE-RM-04|UI_SCOPE|OD1.2§20.11,27.3|APPLIED
MigrationRecord = UI-SCOPE-RM-05|UI_SCOPE|OD1.2§20.11,27.3|APPLIED

ContractCoverageRecord = KSC-HIERARCHY|CONSTRUCTION|OD1.2§5-7.1|COVERED_BY_REVERSE_MIGRATION|NONE
ContractCoverageRecord = KSC-SPINE-AND-CLOSURE|CONSTRUCTION|OD1.2§8-9,15-16|COVERED_BY_REVERSE_MIGRATION|NONE
ContractCoverageRecord = KSC-SOURCE-AND-MERGE|CONSTRUCTION|OD1.2§12-14|COVERED_BY_REVERSE_MIGRATION|NONE
ContractCoverageRecord = KSC-TEN-ARTIFACTS|CONSTRUCTION|OD1.2§19|COVERED_BY_REVERSE_MIGRATION|DOC-GAP-001
ContractCoverageRecord = KSC-GENERATION|CONSTRUCTION|OD1.2§17|COVERED_BY_REVERSE_MIGRATION|DOC-GAP-001
ContractCoverageRecord = KSC-DENSITY-AND-RENDERING|CONSTRUCTION|OD1.2§10-11,20|COVERED_BY_REVERSE_MIGRATION|NONE
ContractCoverageRecord = KSC-REVISION|CONSTRUCTION|OD1.2§18|COVERED_BY_REVERSE_MIGRATION|NONE
ContractCoverageRecord = KSC-GOLDEN-CASE|CONSTRUCTION|OD1.2§21|COVERED_BY_REVERSE_MIGRATION|DOC-GAP-001
ContractCoverageRecord = UI-PAGE-IA|UIUX|OD1.2§20.2|COVERED_BY_REVERSE_MIGRATION|NONE
ContractCoverageRecord = UI-CORE-FLOW|UIUX|OD1.2§20.3|COVERED_BY_REVERSE_MIGRATION|NONE
ContractCoverageRecord = UI-SKELETON-REVIEW|UIUX|OD1.2§20.4|COVERED_BY_REVERSE_MIGRATION|NONE
ContractCoverageRecord = UI-LANDSCAPE|UIUX|OD1.2§20.5|COVERED_BY_REVERSE_MIGRATION|NONE
ContractCoverageRecord = UI-THEME-DETAIL|UIUX|OD1.2§20.6|COVERED_BY_REVERSE_MIGRATION|NONE
ContractCoverageRecord = UI-MODULE-READING|UIUX|OD1.2§20.7|COVERED_BY_REVERSE_MIGRATION|NONE
ContractCoverageRecord = UI-RENDERER|UIUX|OD1.2§20.8|COVERED_BY_REVERSE_MIGRATION|DOC-GAP-001
ContractCoverageRecord = UI-SOURCE-EVIDENCE|UIUX|OD1.2§20.9|COVERED_BY_REVERSE_MIGRATION|NONE
ContractCoverageRecord = UI-PAGE-STATE|UIUX|OD1.2§20.10|COVERED_BY_REVERSE_MIGRATION|NONE
ContractCoverageRecord = UI-MVP-SCOPE|UIUX|OD1.2§24-25|COVERED_BY_REVERSE_MIGRATION|NONE
ContractCoverageRecord = UI-DESKTOP-WEB|UI_SCOPE|OD1.2§20.11|COVERED_BY_REVERSE_MIGRATION|NONE

DocumentationGapRecord = DOC-GAP-001|CONSTRUCTION_SPECIALTY_BODY|OPEN|SCHEMA_SOURCE_MISSING|AUTHORITATIVE_BODY_OR_APPROVED_SCHEMA_REBASELINE|BLOCKS_W0-G3
DocumentationGapRecord = DOC-GAP-002|UIUX_SPECIALTY_BODY|OPEN|NON_SCHEMA_UI_CONTRACTS_COVERED|AUTHORITATIVE_BODY_OR_APPROVED_REBASELINE|DOES_NOT_BLOCK_W0-G2

EvidenceLimitRecord = RM_ID_TO_TOPIC_SOURCE_MISSING|OPEN|OD1.2§1.1,27.1|NO_OFFICIAL_PER_ID_TOPIC_MAPPING|USE_AGGREGATE_MIGRATION_PLUS_TOPIC_EVIDENCE
```

## 7. Gate 结论

全部非 Schema 契约具有总体设计正式证据，Schema 来源缺口及其处置已唯一化。
`DOC-GAP-001` 的历史正文缺失事实继续登记，但批准的正式重基线已经解除 W0-04
执行阻断；W0-04 的机器实现修复候选已通过本地验证，固定提交深审尚未封口。
`DOC-GAP-002` 和构造专项逐 RM 语义映射的证据限制继续保持开放。下列 `READY`
是本 W0-G2 矩阵向 W0-04 交接时的历史门禁输出；当前 W0-G3 状态以设计索引和
准入裁决中的 `IN_REVIEW` 为准。

```text
W0-G2 SpecialtyContractCoverage = PASS
W0-G3 JsonSchemaValidation = READY
```
