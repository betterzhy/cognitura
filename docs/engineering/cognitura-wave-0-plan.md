# Cognitura Wave 0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立可追溯、可验证、可审查的 Cognitura 工程基线，并为 Wave 1 提供唯一的设计、Schema、Golden Case、测试与 CI 入口。

**Architecture:** Wave 0 不实现业务功能。它先固定原始输入与设计来源，再封口专项契约覆盖和 JSON Schema，随后建立 Golden Case 回归、页面/Renderer 契约验证、技术栈工程骨架和 CI。所有产物围绕模块化单体与 Desktop Web 边界组织。

**Tech Stack:** 后端正式选择 Java 21、Maven 3.9.16、Spring Boot 4.1.0、
Spring Modulith 2.1.0、PostgreSQL 18、MyBatis Spring Boot Starter 4.0.0、
Flyway 和 Spring AI 2.0.0；前端正式选择 Node 24.18.0、pnpm 11.17.0、
React 19.2.8、TypeScript 7.0.2 和 Vite 8.1.5。对象存储仍未裁决。

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

## 执行任务卡

本计划定义 Wave 0 的总体工作分解；可执行写集、依赖、验证命令和提交边界以
[`docs/task-cards/README.md`](../task-cards/README.md) 及其九张独立任务卡为准。
任务卡不得扩大本计划或总体设计的范围。

```text
TaskCardBreakdown = COMPLETE
TaskCardCount = 9
ActiveTaskCard = W0-08
ActiveTaskCardStatus = READY
```

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

- [x] **Step 1:** 再次执行 `pwd`、目录清单和 SHA-256 校验，确认四个正式输入与本复验记录一致。
- [x] **Step 2:** 确认当前目录仍无 `.git`；获得用户授权后初始化 Repository，默认分支使用 `main`。
- [x] **Step 3:** 将 `.DS_Store` 保留在磁盘但排除出版本控制；未删除或移动任何原始输入。
- [x] **Step 4:** 首次提交只包含四个正式输入、`.gitignore` 和本轮工程基线文件。
- [x] **Step 5:** 验证 `git status --short` 为空，记录 Repository 基线内容提交并标记：

```text
RepositoryBranch = main
RepositoryBaselineContentCommit =
  2047a80dde53e1a9b8b460f2ef9230df7f2bca22
W0-G0 RepositoryBaseline = PASS
```

## Task W0-01：封口设计和输入来源登记

**Files:**

- Modify: `docs/engineering/cognitura-design-index.md`
- Create: `docs/engineering/cognitura-source-manifest.yaml`
- Test: `scripts/verify-source-manifest`

**Produces:** 机器可读的唯一来源清单，含路径、版本、角色、大小和 SHA-256。

- [x] **Step 1:** 先写校验失败用例：修改任一临时副本的一个字节时，验证器必须返回非零。
- [x] **Step 2:** 在 manifest 登记总体设计和三份 DOCX，不复制文件。
- [x] **Step 3:** 实现只读校验器，拒绝缺失文件、哈希漂移、重复 Case ID 和未知正式输入。
- [x] **Step 4:** 运行验证并确认四个输入全部为 `MATCH`。
- [x] **Step 5:** 提交并标记：

```text
W0-G1 DesignSourceRegistry = PASS
```

## Task W0-02：专项契约覆盖封口

**Files:**

- Create: `docs/engineering/cognitura-specialty-contract-coverage.md`
- Modify: `docs/engineering/cognitura-design-index.md`

**Produces:** 每个正式契约对应的权威来源、总体设计回迁证据和字段级缺口。

- [x] **Step 1:** 对构造专项的层级、十项产物、生成阶段、密度、修订和 Golden Case 建立逐项覆盖矩阵。
- [x] **Step 2:** 对 UI/UX 专项的页面、Renderer、Source Evidence、状态模型和 Desktop Web 边界建立逐项覆盖矩阵。
- [x] **Step 3:** 将总体设计已完整覆盖的条目标记为 `COVERED_BY_REVERSE_MIGRATION`。
- [x] **Step 4:** 将缺少字段、类型、required、枚举、约束或示例的条目标记为 `SCHEMA_SOURCE_MISSING`，不得补写虚构字段。
- [x] **Step 5:** 只有当所有非 Schema 契约有正式证据、所有 Schema 缺口都有唯一处置时，标记：

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

- [x] **Step 1a:** 在技术基线中固定 Java 21、Maven 3.9.16、Spring Boot 4.1.0、PostgreSQL 18、MyBatis 4.0.0、迁移、模块治理、AI Adapter 和后端测试工具链。
- [x] **Step 1b:** 固定 React、TypeScript、Node、前端构建工具、包管理器及精确版本。
- [x] **Step 2:** 记录 server 的 `source`、`cognition`、`generation`、`reading`、`llm` 模块边界。
- [x] **Step 3:** 记录 web 的 `workspace`、`document-ingestion`、`structure-review`、`landscape`、`theme`、`module-reading`、`source-evidence`、`generation-status`、`revision-history` 边界。
- [x] **Step 4:** 先写最小构建与健康检查失败验证，再创建只包含启动/健康检查的骨架。
- [x] **Step 5:** 验证没有微服务、Kafka、Neo4j、Elasticsearch、原生 App 或业务生成代码。
- [x] **Step 6:** 提交并标记：

```text
W0-G2A BuildBaseline = PASS
```

完成状态：

```text
W0-03 BackendTechnologySelection = PASS
W0-03 FrontendTechnologySelection = PASS
W0-03 BuildSkeleton = PASS
W0-G2A BuildBaseline = PASS
```

## Task W0-04：建立 JSON Schema Source

**Files:**

- Create: `schemas/cognition/*.schema.json`
- Create: `schemas/generation/*.schema.json`
- Create: `schemas/ui/renderer-input.schema.json`
- Create: `schemas/ui/page-state.schema.json`
- Create: `schemas/catalog.json`
- Create: `schemas/evidence-map.json`
- Test: `tests/contracts/schema/`

**Produces:** 版本化、可引用、可验证的 Cognitura 正式 Schema 集。

- [x] **Step 1:** 以批准并落地的 `Cognitura-Schema-Baseline-2.0` 解除执行
  阻断，不从总体摘要或常识继续猜测字段。
- [x] **Step 2:** 为十项正式认知产物逐一写缺失 required 字段、非法枚举和非法关系类型的失败样例。
- [x] **Step 3:** 实现 `KnowledgeSkeleton`、`KnowledgeTheme`、`CognitiveModule`、`PrimaryCognitiveSpine`、`KnowledgeElement`、`ThemeClosure`、`LandscapeClosure`、`EvidenceReference`、`StructureAmbiguity`、`QualityAssessment` Schema。
- [x] **Step 4:** 实现生成阶段记录 Schema，覆盖 `inputHash`、`promptVersion`、`model`、`sourceBlockRefs`、`structuredOutput`、`validationResult`、`generationStatus`、`retryCount`。
- [x] **Step 5:** 实现统一 Renderer 输入 Schema 和页面状态枚举。
- [x] **Step 6:** 运行正例与反例验证，确认缺少 thesis、spine、boundary 或 sourceRefs 的 Module 被拒绝。
- [x] **Step 7:** 形成不改写历史的修复提交，通过固定提交深审后标记：

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

- [x] **Step 1:** 先写哈希漂移、外链访问与目标变化、ZIP/路径逃逸、丢失表格、丢失图片引用、标题、段落和分页位置变化的失败测试，并观察缺少验证器时的预期失败。
- [x] **Step 2:** MySQL Case 编码“事务可见性与幻读控制”闭环，并以 `NOT_ALL` 集合语义禁止把 MVCC、Read View 字段、隐藏列和单锁类型全部升级为一级 Module。
- [x] **Step 3:** Redis Case 编码“请求处理与高性能线程模型”聚合，并将 `beforeSleep` 标为 `MustNotPromote`。
- [x] **Step 4:** 英语 Case 编码“谓语动词类型 → 必要成分 → 五大句型 → 判定路径 → SVOO/SVOC 辨析”，并禁止例句升级。
- [x] **Step 5:** 运行离线回归，确认 Redis 的 4 个 `file:///` 链接仅被计数且没有网络或文件访问。
- [x] **Step 5a:** 将八组断言实际应用到三份候选结果契约夹具，并以 8 个逐组
  反例证明任一结果违约都会使 Gate 失败；夹具不冒充业务生成结果。
- [x] **Step 6:** 固定候选 `608a98c` 通过深审后提交并标记：

```text
W0-G4 GoldenCaseRegression = PASS
```

## Task W0-06：页面与 Renderer 契约基线

**Files:**

- Create: `docs/contracts/cognitura-page-contracts.md`
- Create: `docs/contracts/cognitura-renderer-contract.md`
- Test: `tests/contracts/ui/`

**Produces:** 从总体设计回迁内容抽取的 Desktop Web 页面和 Renderer 验收契约，不重写产品设计。

- [x] **Step 1:** 编码 Workspace、Upload、ParsingStatus、ThemeModel、SkeletonReview、Landscape、Theme、ModuleReading、SourceEvidence、Revision 和 History 页面职责。
- [x] **Step 2:** 编码 Skeleton Review 六类结构操作和三栏 Desktop Web 契约。
- [x] **Step 3:** 编码九类 Renderer、统一输入和“Renderer 不创建事实”的不变量。
- [x] **Step 4:** 编码页面状态、局部失败、最小重试、基础响应式和移动端非等价边界。
- [x] **Step 5:** 验证不存在原生 App、自由画布、Card-only 或普通管理表格主体验。
- [x] **Step 6:** 提交并标记：

```text
W0-G4A UiContractValidation = PASS
```

## Task W0-07：测试与 CI 基线

**Files:**

- Create: CI workflow
- Create: `docs/engineering/cognitura-test-strategy.md`
- Test: all Wave 0 validators

**Produces:** 每次提交自动执行来源哈希、Markdown 链接、Schema、Golden Case、server 构建和 web 构建验证。

- [x] **Step 1:** 先建立一个故意破坏 source hash 的临时 CI 验证，确认统一入口向上失败。
- [x] **Step 2:** 将 source manifest、task-card、Markdown 链接、Schema 正反例、Golden Case、页面契约、server、web 七阶段接入同一入口和 GitHub Actions job。
- [x] **Step 3:** 固定 Action 到完整提交，并将 Maven/pnpm 缓存输入绑定 pom、wrapper 和 lockfile。
- [x] **Step 4:** 通过 CI 契约测试确认 workflow 不访问 Redis 遗留本地链接、不修改 `raw/`，不执行正式数据库写入。
- [x] **Step 5:** 本地等价命令与固定提交 CI 已通过，并记录可追溯 URL：

```text
W0-G5 TestAndCI = PASS
```

当前状态：

```text
W0-07 ExecutionStatus = DONE
CIProvider = GITHUB_ACTIONS
LocalWave0Verification = PASS
FixedCommit = a332092ee1298c795d13de4af1fcab2e908aed9f
FixedCommitCI = PASS
CIURL = https://github.com/betterzhy/cognitura/actions/runs/30454379223
W0-G5 TestAndCI = PASS
```

## Task W0-08：固定提交复核与 Wave 1 准入

**Files:**

- Modify: `docs/engineering/cognitura-wave-0-entry-decision.md`
- Create: `docs/engineering/cognitura-wave-1-entry-decision.md`
- Modify: `docs/task-cards/README.md`
- Modify: `docs/task-cards/W0-08-fixed-commit-review.md`
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `docs/engineering/cognitura-wave-0-plan.md`
- Modify: `scripts/verify-task-cards`
- Modify: `tests/task-cards/verify-task-cards.sh`

**Produces:** 绑定固定 commit 的独立审查和明确 GO/NO-GO。

- [x] **Step 1:** 在干净工作树记录固定候选 `311b04093531f5c1032b08e42b50e6f04edb6f1a`、
  全部 Gate 结果和成功的 GitHub Actions
  [run #2](https://github.com/betterzhy/cognitura/actions/runs/30459392177)。
- [x] **Step 2:** 使用 `gpt-5.6-sol/high` 对固定提交做一般深度审查；第一轮结果为
  `NOT_READY / P0=0 / P1=2 / P2=0`，已退出准入流程。
- [ ] **Step 3:** 修复并重新验证一般深度审查发现；在新的固定候选提交上复核历史设计未被改写、原件哈希未漂移、Schema 来源可追溯、Golden Case 断言完整、CI 可复现。
- [ ] **Step 4:** 一般审查清零后，使用独立 `gpt-5.6-sol/high` 对最终固定候选做
  Wave 1 GO/NO-GO 门禁复核。
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
W0-00 → W0-01 → W0-02 → W0-03
                       ├→ W0-04 [DONE/PASS] → W0-05 [DONE/PASS] ──────┐
                       └→ W0-06 [DONE] ─────────────────────────┤
                                                               └→ W0-07 [DONE/PASS] → W0-08 [READY]
```

`W0-06` 已在等待字段级来源期间完成。`Cognitura-Schema-Baseline-2.0`
已经投影为机器 Schema，W0-04 固定候选 `72b5ce7` 通过本地 Gate 与深审，
`W0-G3 = PASS`；W0-05 的 3 个原件正例、3 个结果正例、22 个负例和 24 组
结果断言已经通过，固定候选 `608a98c` 深审为 `GO / P0=0 / P1=0 / P2=0`，
因此 `W0-G4 = PASS`。W0-07 的本地七阶段统一入口与固定提交
`a332092ee1298c795d13de4af1fcab2e908aed9f` 的 GitHub Actions
[run #1](https://github.com/betterzhy/cognitura/actions/runs/30454379223)
均已通过，`W0-G5 = PASS`。W0-07 已关闭，W0-08 已成为唯一 `READY` 卡。
`W0-08` 必须最后执行。
