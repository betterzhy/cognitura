# Cognitura Wave 0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立可追溯、可验证、可审查的 Cognitura 工程基线，并为 Wave 1 提供唯一的设计、Schema、Golden Case、测试与 CI 入口。

**Architecture:** Wave 0 不实现业务功能。它先固定原始输入与设计来源，再封口专项契约覆盖和 JSON Schema，随后建立 Golden Case 回归、页面/Renderer 契约验证、技术栈工程骨架和 CI。所有产物围绕模块化单体与 Desktop Web 边界组织。

**Tech Stack:** Java 21、Spring Boot、PostgreSQL、JSONB、对象存储、React、TypeScript、LLM Provider Adapter、JSON Schema；具体依赖版本在 `W0-03` 由可复现的版本锁定文件封口。

## Global Constraints

```text
CanonicalProjectName = Cognitura
CanonicalHierarchy =
  KnowledgeLandscape
  → KnowledgeTheme
  → CognitiveModule
  → KnowledgeElement
PrimaryReadingUnit = COGNITIVE_MODULE
DeliveryPlatform = WEB_BROWSER
PrimaryExperience = DESKTOP_WEB
V1Architecture = MODULAR_MONOLITH
DirectFullImplementationStart = NO
```

- 历史设计文件不重命名、不复制、不改写版本。
- 三份 `raw/*.docx` 是只读原件；所有回归结果必须绑定 SHA-256。
- 字段级 Schema 不得从提示词或常识猜测。
- Wave 0 期间不实现 Wave 1 及之后的业务功能。

---

## 0. 工作项与 Gate

| Task | 交付 | Gate |
|---|---|---|
| `W0-00` | Repository 与变更边界 | `W0-G0 RepositoryBaseline` |
| `W0-01` | 设计和输入来源登记 | `W0-G1 DesignSourceRegistry` |
| `W0-02` | 专项契约覆盖封口 | `W0-G2 SpecialtyContractCoverage` |
| `W0-03` | 技术栈与模块化单体骨架 | `W0-G2A BuildBaseline` |
| `W0-04` | JSON Schema Source | `W0-G3 JsonSchemaValidation` |
| `W0-05` | Golden Case 回归资产 | `W0-G4 GoldenCaseRegression` |
| `W0-06` | 页面与 Renderer 契约 | `W0-G4A UiContractValidation` |
| `W0-07` | 测试与 CI | `W0-G5 TestAndCI` |
| `W0-08` | 固定提交复核与 Wave 1 准入 | `W0-G6 FixedCommitReview` |

## Task W0-00：建立 Repository 基线

**Files:**

- Preserve: `cognitive-knowledge-atlas-overall-design-1.2.md`
- Preserve: `raw/11-MySQL数据库.docx`
- Preserve: `raw/12-Redis中间件.docx`
- Preserve: `raw/40-英语学习.docx`
- Verify: `README.md`
- Verify: `AGENTS.md`
- Verify: `.gitignore`
- Verify: `docs/engineering/*.md`

**Produces:** 可提交、可审查且不包含 `.DS_Store` 的 Git 基线。

- [ ] **Step 1:** 再次执行 `pwd`、目录清单和 SHA-256 校验，确认四个正式输入与本复验记录一致。
- [ ] **Step 2:** 确认当前目录仍无 `.git`；只在 Wave 0 执行获得授权后初始化 Repository，默认分支使用 `main`。
- [ ] **Step 3:** 将 `.DS_Store` 保留在磁盘但排除出版本控制；不得删除或移动任何原始输入。
- [ ] **Step 4:** 首次提交只包含四个正式输入、`.gitignore` 和本轮工程基线文件。
- [ ] **Step 5:** 验证 `git status --short` 为空，记录 HEAD，并将 Gate 标记为：

```text
W0-G0 RepositoryBaseline = PASS
```

## Task W0-01：封口设计和输入来源登记

**Files:**

- Modify: `docs/engineering/cognitura-design-index.md`
- Create: `docs/engineering/cognitura-source-manifest.yaml`
- Test: `scripts/verify-source-manifest`

**Produces:** 机器可读的唯一来源清单，含路径、版本、角色、大小和 SHA-256。

- [ ] **Step 1:** 先写校验失败用例：修改任一临时副本的一个字节时，验证器必须返回非零。
- [ ] **Step 2:** 在 manifest 登记总体设计和三份 DOCX，不复制文件。
- [ ] **Step 3:** 实现只读校验器，拒绝缺失文件、哈希漂移、重复 Case ID 和未知正式输入。
- [ ] **Step 4:** 运行验证并确认四个输入全部为 `MATCH`。
- [ ] **Step 5:** 提交并标记：

```text
W0-G1 DesignSourceRegistry = PASS
```

## Task W0-02：专项契约覆盖封口

**Files:**

- Create: `docs/engineering/cognitura-specialty-contract-coverage.md`
- Modify: `docs/engineering/cognitura-design-index.md`

**Produces:** 每个正式契约对应的权威来源、总体设计回迁证据和字段级缺口。

- [ ] **Step 1:** 对构造专项的层级、十项产物、生成阶段、密度、修订和 Golden Case 建立逐项覆盖矩阵。
- [ ] **Step 2:** 对 UI/UX 专项的页面、Renderer、Source Evidence、状态模型和 Desktop Web 边界建立逐项覆盖矩阵。
- [ ] **Step 3:** 将总体设计已完整覆盖的条目标记为 `COVERED_BY_REVERSE_MIGRATION`。
- [ ] **Step 4:** 将缺少字段、类型、required、枚举、约束或示例的条目标记为 `SCHEMA_SOURCE_MISSING`，不得补写虚构字段。
- [ ] **Step 5:** 只有当所有非 Schema 契约有正式证据、所有 Schema 缺口都有唯一处置时，标记：

```text
W0-G2 SpecialtyContractCoverage = PASS
```

字段级 Schema 的唯一合法处置是：落地可验证的权威专项正文，或形成明确批准的 Schema 重基线设计；不得伪造历史专项文档。

## Task W0-03：封口技术栈与模块化单体骨架

**Files:**

- Create: `docs/engineering/cognitura-technology-baseline.md`
- Create: `server/`
- Create: `web/`
- Create: 根构建与版本锁定文件

**Produces:** 只有构建、模块边界和健康检查的最小骨架，不含业务功能。

- [ ] **Step 1:** 在技术基线中固定 Java 21、Spring Boot、PostgreSQL、React、TypeScript、包管理器、构建工具及精确版本。
- [ ] **Step 2:** 记录 server 的 `source`、`cognition`、`generation`、`reading`、`llm` 模块边界。
- [ ] **Step 3:** 记录 web 的 `workspace`、`document-ingestion`、`structure-review`、`landscape`、`theme`、`module-reading`、`source-evidence`、`generation-status`、`revision-history` 边界。
- [ ] **Step 4:** 先写最小构建与健康检查失败验证，再创建只包含启动/健康检查的骨架。
- [ ] **Step 5:** 验证没有微服务、Kafka、Neo4j、Elasticsearch、原生 App 或业务生成代码。
- [ ] **Step 6:** 提交并标记：

```text
W0-G2A BuildBaseline = PASS
```

## Task W0-04：建立 JSON Schema Source

**Files:**

- Create: `schemas/cognition/*.schema.json`
- Create: `schemas/generation/*.schema.json`
- Create: `schemas/ui/renderer-input.schema.json`
- Test: `tests/contracts/schema/`

**Produces:** 版本化、可引用、可验证的 Cognitura 正式 Schema 集。

- [ ] **Step 1:** 在 `W0-G2` 通过前保持本任务阻断，不从总体摘要猜测字段。
- [ ] **Step 2:** 为十项正式认知产物逐一写缺失 required 字段、非法枚举和非法关系类型的失败样例。
- [ ] **Step 3:** 实现 `KnowledgeSkeleton`、`KnowledgeTheme`、`CognitiveModule`、`PrimaryCognitiveSpine`、`KnowledgeElement`、`ThemeClosure`、`LandscapeClosure`、`EvidenceReference`、`StructureAmbiguity`、`QualityAssessment` Schema。
- [ ] **Step 4:** 实现生成阶段记录 Schema，覆盖 `inputHash`、`promptVersion`、`model`、`sourceBlockRefs`、`structuredOutput`、`validationResult`、`generationStatus`、`retryCount`。
- [ ] **Step 5:** 实现统一 Renderer 输入 Schema 和页面状态枚举。
- [ ] **Step 6:** 运行正例与反例验证，确认缺少 thesis、spine、boundary 或 sourceRefs 的 Module 被拒绝。
- [ ] **Step 7:** 提交并标记：

```text
W0-G3 JsonSchemaValidation = PASS
```

## Task W0-05：建立 Golden Case 回归资产

**Files:**

- Create: `test-data/golden-cases/manifest.yaml`
- Create: `test-data/golden-cases/mysql.expected.yaml`
- Create: `test-data/golden-cases/redis.expected.yaml`
- Create: `test-data/golden-cases/english.expected.yaml`
- Test: `tests/golden-cases/`

**Produces:** 绑定原件哈希的 MustInclude/MustMerge/MustNotSplit/MustNotPromote/ExpectedRole/ExpectedSpine/ExpectedThemeClosure/KnownSourceGaps。

- [ ] **Step 1:** 先写哈希漂移、链接访问、丢失表格、丢失图片引用和标题顺序变化的失败测试。
- [ ] **Step 2:** MySQL Case 编码“事务可见性与幻读控制”闭环，并禁止把 MVCC、Read View 字段、隐藏列或单锁类型全部升级为一级 Module。
- [ ] **Step 3:** Redis Case 编码“请求处理与高性能线程模型”聚合，并将 `beforeSleep` 标为 `MustNotPromote`。
- [ ] **Step 4:** 英语 Case 编码“谓语动词类型 → 必要成分 → 五大句型 → 判定路径 → SVOO/SVOC 辨析”，并禁止例句升级。
- [ ] **Step 5:** 运行离线回归，确认 Redis 的 `file:///` 链接没有网络或文件访问。
- [ ] **Step 6:** 提交并标记：

```text
W0-G4 GoldenCaseRegression = PASS
```

## Task W0-06：页面与 Renderer 契约基线

**Files:**

- Create: `docs/contracts/cognitura-page-contracts.md`
- Create: `docs/contracts/cognitura-renderer-contract.md`
- Test: `tests/contracts/ui/`

**Produces:** 从总体设计回迁内容抽取的 Desktop Web 页面和 Renderer 验收契约，不重写产品设计。

- [ ] **Step 1:** 编码 Workspace、Upload、ParsingStatus、ThemeModel、SkeletonReview、Landscape、Theme、ModuleReading、SourceEvidence、Revision 和 History 页面职责。
- [ ] **Step 2:** 编码 Skeleton Review 六类结构操作和三栏 Desktop Web 契约。
- [ ] **Step 3:** 编码九类 Renderer、统一输入和“Renderer 不创建事实”的不变量。
- [ ] **Step 4:** 编码页面状态、局部失败、最小重试、基础响应式和移动端非等价边界。
- [ ] **Step 5:** 验证不存在原生 App、自由画布、Card-only 或普通管理表格主体验。
- [ ] **Step 6:** 提交并标记：

```text
W0-G4A UiContractValidation = PASS
```

## Task W0-07：测试与 CI 基线

**Files:**

- Create: CI workflow
- Create: `docs/engineering/cognitura-test-strategy.md`
- Test: all Wave 0 validators

**Produces:** 每次提交自动执行来源哈希、Markdown 链接、Schema、Golden Case、server 构建和 web 构建验证。

- [ ] **Step 1:** 先建立一个故意破坏 source hash 的临时 CI 验证，确认流水线失败。
- [ ] **Step 2:** 添加 source manifest、Schema 正反例、Golden Case、页面契约、server、web 六组 job。
- [ ] **Step 3:** 固定依赖缓存键到 lockfile，不使用浮动依赖。
- [ ] **Step 4:** 确认 CI 不访问 Redis 遗留本地链接，不修改 `raw/`，不执行正式数据库写入。
- [ ] **Step 5:** 运行本地等价命令和 CI，全部通过后标记：

```text
W0-G5 TestAndCI = PASS
```

## Task W0-08：固定提交复核与 Wave 1 准入

**Files:**

- Modify: `docs/engineering/cognitura-wave-0-entry-decision.md`
- Create: `docs/engineering/cognitura-wave-1-entry-decision.md`

**Produces:** 绑定固定 commit 的独立审查和明确 GO/NO-GO。

- [ ] **Step 1:** 在干净工作树记录固定候选 commit、全部 Gate 结果和 CI URL。
- [ ] **Step 2:** 使用 `deep_reviewer` 对固定提交做一般深度审查，要求 P0/P1/P2 全部为 0。
- [ ] **Step 3:** 修复并重新验证一般深度审查发现；在新的固定候选提交上复核历史设计未被改写、原件哈希未漂移、Schema 来源可追溯、Golden Case 断言完整、CI 可复现。
- [ ] **Step 4:** 使用 `ultra_gatekeeper` 对最终固定候选做 Wave 1 GO/NO-GO 门禁复核。
- [ ] **Step 5:** 只有 `W0-G0`、`W0-G1`、`W0-G2`、`W0-G2A`、`W0-G3`、`W0-G4`、`W0-G4A`、`W0-G5` 全部 `PASS`，且最终门禁结果为 GO 时，标记：

```text
W0-G6 FixedCommitReview = PASS
Wave1FeatureDevelopmentEntry = GO
```

- [ ] **Step 6:** 任一 Gate 未通过或最终门禁为 NO-GO 时保持：

```text
Wave1FeatureDevelopmentEntry = NO_GO
```

## 1. 执行顺序

```text
W0-00
→ W0-01
→ W0-02
→ W0-03
→ W0-04
→ W0-05
→ W0-06
→ W0-07
→ W0-08
```

`W0-05` 和 `W0-06` 在各自输入稳定后可以并行；`W0-04` 必须等待字段级来源封口；`W0-08` 必须最后执行。
