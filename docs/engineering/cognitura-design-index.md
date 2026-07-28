# Cognitura 设计与输入索引

```text
CanonicalProjectName = Cognitura
RepositoryName = cognitura
CurrentDesignBaseline = Cognitura-Overall-Design-1.2
```

本索引登记实际落地文件，不复制总体设计正文，也不改变历史设计名称。

## 1. 正式总体设计

| 工程引用名 | 实际路径 | 原始版本标识 | 状态 | SHA-256 |
|---|---|---|---|---|
| `Cognitura-Overall-Design-1.2` | `cognitive-knowledge-atlas-overall-design-1.2.md` | `Cognitive-Knowledge-Atlas-Overall-Design-1.2` | `FORMAL_BASELINE` | `806d1fb00288b918dc4859007599c5e5d2f9a44e617bfc07cd562b9812e9eb2b` |

该文件是当前 Cognitura 总体设计基线。历史名称和版本号必须保留。

## 2. 专项设计登记

| 专项设计 | 总体设计引用状态 | Repository 文件状态 | 工程处理 |
|---|---|---|---|
| `Cognitive-Knowledge-System-Construction-Design-1.0` | `RM-01～RM-11` 已回迁，`11/11` | `MISSING` | 记录 `DOC-GAP-001`；总体层契约可用，字段级 Schema 不得猜测 |
| `Cognitive-Knowledge-Atlas-UIUX-Design-1.0` | `UI-RM-01～10` 已回迁，`10/10` | `MISSING` | 记录 `DOC-GAP-002`；页面与 Renderer 正式契约已可从总体设计读取 |

```text
DocumentationGapCount = 2
SpecialtyBodyAbsenceBlocksWave0Planning = NO
SpecialtyBodyAbsenceBlocksFieldLevelSchemaClosure = YES
```

## 3. Golden Case 原始输入

| Case ID | 路径 | 类型 | SHA-256 | 关键验收职责 |
|---|---|---|---|---|
| `GC-MYSQL-001` | `raw/11-MySQL数据库.docx` | 技术机制/规则/存储 | `5a7adabb8d2769c422dd22ae43efe1deaf5efcf792b42b24be07da564aa97b50` | 跨锁、事务、数据行、Undo Log 形成闭环；不得把 MVCC 等全部提升为一级 Module |
| `GC-REDIS-001` | `raw/12-Redis中间件.docx` | 技术机制/工程场景 | `42fe82271b9f7a7c8aa956fd73486d7c8a9b7a5770780df03af306cfde41b72c` | 聚合事件循环、输出缓冲、Pending Writes、beforeSleep、写事件兜底和 IO 多线程边界；`beforeSleep` 不得升级 |
| `GC-ENGLISH-001` | `raw/40-英语学习.docx` | 规则体系/表格/例句 | `a35763c77d6d7f98e396a51ae97f258bdba5c9b3ac9525c0b18168ff3947d3c1` | 五大句型形成统一规则与判定路径；例句不得升级为 Module 或主导航 |

三份 DOCX 均为纯原始学习材料，不是设计契约来源。它们没有重复内容，也不包含 Cognitura 或历史项目名称。

## 4. 总体设计已落地的正式契约

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

## 5. 工程记录

- `docs/engineering/cognitura-repository-baseline-review.md`
- `docs/engineering/cognitura-naming-migration.md`
- `docs/engineering/cognitura-technology-baseline.md`
- `docs/engineering/cognitura-wave-0-plan.md`
- `docs/engineering/cognitura-wave-0-entry-decision.md`
- `docs/task-cards/README.md`

这些工程记录只描述当前落地事实、缺口、计划和门禁，不替代正式设计。
