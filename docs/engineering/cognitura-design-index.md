# Cognitura 设计与输入索引

```text
CanonicalProjectName = Cognitura
RepositoryName = cognitura
CurrentDesignBaseline = Cognitura-Overall-Design-1.2
CanonicalSourceManifest =
  docs/engineering/cognitura-source-manifest.yaml
W0-G1 DesignSourceRegistry = PASS
SpecialtyContractCoverage =
  docs/engineering/cognitura-specialty-contract-coverage.md
W0-G2 SpecialtyContractCoverage = PASS
PageContractBaseline =
  docs/contracts/cognitura-page-contracts.md
RendererContractBaseline =
  docs/contracts/cognitura-renderer-contract.md
W0-G4A UiContractValidation = PASS
SchemaDesignBaseline =
  docs/design/cognitura-schema-baseline-2.0.md
SchemaDesignBaselineStatus = FORMAL_SCHEMA_REBASELINE
SchemaCatalog = schemas/catalog.json
SchemaEvidenceMap = schemas/evidence-map.json
W0-G3 JsonSchemaValidation = PASS
```

本索引登记实际落地文件，不复制总体设计正文，也不改变历史设计名称。
正式原始输入的路径、角色、版本、字节数与 SHA-256 唯一机器清单是
[`cognitura-source-manifest.yaml`](cognitura-source-manifest.yaml)；经批准的
工程重基线由本索引、固定 Git 提交和对应 Gate 记录追踪，不混入只读原始输入
Manifest。

## 1. 正式总体设计

| 工程引用名 | 实际路径 | 原始版本标识 | 状态 | Manifest Source ID |
|---|---|---|---|---|
| `Cognitura-Overall-Design-1.2` | `cognitive-knowledge-atlas-overall-design-1.2.md` | `Cognitive-Knowledge-Atlas-Overall-Design-1.2` | `FORMAL_BASELINE` | `DESIGN-OVERALL-001` |

该文件是当前 Cognitura 总体设计基线。历史名称和版本号必须保留。

## 2. 专项设计登记

| 专项设计 | 总体设计引用状态 | Repository 文件状态 | 工程处理 |
|---|---|---|---|
| `Cognitive-Knowledge-System-Construction-Design-1.0` | `RM-01～RM-11` 已回迁，`11/11` | `MISSING` | 历史正文缺口继续登记；字段级契约由批准的 2.0 重基线与已验证 Schema 唯一承接 |
| `Cognitive-Knowledge-Atlas-UIUX-Design-1.0` | `UI-RM-01～10` 已回迁，`10/10` | `MISSING` | 页面与 Renderer 非 Schema 契约已验证；`DOC-GAP-002` 保持开放 |

```text
DocumentationGapCount = 2
SpecialtyBodyAbsenceBlocksWave0Planning = NO
SchemaRebaselineDisposition = APPROVED
SpecialtyBodyAbsenceBlocksFieldLevelSchemaClosure = NO
```

## 3. Schema 重基线

| 工程引用名 | 实际路径 | 状态 | 权威边界 |
|---|---|---|---|
| `Cognitura-Schema-Baseline-2.0` | `docs/design/cognitura-schema-baseline-2.0.md` | `FORMAL_SCHEMA_REBASELINE` | 从属于总体设计；按固定审查结果升级并补足字段级工程裁决；不冒充历史专项正文 |

该重基线是 `DOC-GAP-001` 的批准处置证据。W0-04 已将其投影为 14 份 Draft
2020-12 Schema 文档、13 个可实例化契约、Catalog 和逐约束节点 Evidence Map；
13 个正例、18 个结构反例、12 个严格对象未知字段反例、2 个合法非 Published
空值上下文、34 个跨对象语义反例、68 个运行时语义错误码、645 个精确 Schema
证据节点、16 个语义不变量证据、6 个证据映射篡改与全量渲染 round-trip
反例已通过，固定候选 `72b5ce7` 深审为 `GO / P0=0 / P1=0 / P2=0`，因此
`W0-G3 JsonSchemaValidation = PASS`。历史专项正文缺失事实仍登记为开放
缺口，但批准的重基线已解除其执行阻断。

## 4. Golden Case 原始输入

| Case ID | 路径 | 类型 | Manifest Source ID | 关键验收职责 |
|---|---|---|---|---|
| `GC-MYSQL-001` | `raw/11-MySQL数据库.docx` | 技术机制/规则/存储 | `GC-MYSQL-001` | 跨锁、事务、数据行、Undo Log 形成闭环；不得把 MVCC 等全部提升为一级 Module |
| `GC-REDIS-001` | `raw/12-Redis中间件.docx` | 技术机制/工程场景 | `GC-REDIS-001` | 聚合事件循环、输出缓冲、Pending Writes、beforeSleep、写事件兜底和 IO 多线程边界；`beforeSleep` 不得升级 |
| `GC-ENGLISH-001` | `raw/40-英语学习.docx` | 规则体系/表格/例句 | `GC-ENGLISH-001` | 五大句型形成统一规则与判定路径；例句不得升级为 Module 或主导航 |

三份 DOCX 均为纯原始学习材料，不是设计契约来源。它们没有重复内容，也不包含 Cognitura 或历史项目名称。

## 5. 总体设计已落地的正式契约

| 契约组 | 总体设计章节 |
|---|---|
| 产品定位、非目标、核心不变量 | 1–4 |
| 四层层级、边界、升降级、角色与 UnderstandingRoute | 5–7 |
| Primary Cognitive Spine、认知闭环与密度 | 8–10 |
| 阅读深度、关系、来源、多文档归并 | 11–14 |
| ThemeClosure、LandscapeClosure、ThemeModel | 15–16 |
| 两阶段生成与局部重生成 | 17–18 |
| 十项正式认知产物契约 | 19 |
| 页面、Renderer、Source Evidence、状态与 Desktop Web 边界 | 20–20.11 |
| 质量、Golden Case、模块化单体、Wave 0–5 | 21–26 |
| Reverse Migration 与正式状态 | 27–28 |

## 6. 工程记录

- `docs/engineering/cognitura-repository-baseline-review.md`
- `docs/engineering/cognitura-naming-migration.md`
- `docs/engineering/cognitura-technology-baseline.md`
- `docs/engineering/cognitura-source-manifest.yaml`
- `docs/engineering/cognitura-specialty-contract-coverage.md`
- `docs/design/cognitura-schema-baseline-2.0.md`
- `docs/contracts/cognitura-page-contracts.md`
- `docs/contracts/cognitura-renderer-contract.md`
- `docs/engineering/cognitura-wave-0-plan.md`
- `docs/engineering/cognitura-wave-0-entry-decision.md`
- `docs/task-cards/README.md`

这些工程记录只描述当前落地事实、缺口、计划和门禁，不替代正式设计。
