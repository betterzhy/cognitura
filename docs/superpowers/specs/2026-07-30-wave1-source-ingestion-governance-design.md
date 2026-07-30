# Cognitura Wave 1 来源接入设计治理说明

```text
DesignSliceID = W1-D00
DesignDate = 2026-07-30
CanonicalProjectName = Cognitura
GovernedStage = WAVE1_DETAILED_DESIGN
DesignStatus = APPROVED
DynamicExecutionStateSource = docs/task-cards/wave-1/README.md
W1-DG0 DesignGovernance = PASS
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
DeploymentAndRelease = NOT_AUTHORIZED
```

## 1. 目的

本说明固定 Cognitura Wave 1 详细设计阶段的治理边界、设计切片、任务卡模型、
Gate、验证器方案和从设计进入实现的授权条件。

Wave 1 已通过准入，W1-D00 治理切片已关闭。当前活动设计卡和卡集状态只以
`docs/task-cards/wave-1/README.md` 为动态事实来源，本治理说明不复制易漂移的
活动卡值。准入只允许按设计卡推进书面契约，不允许直接实现完整业务功能。
因此，本说明只建立设计阶段的可验证秩序，不创建 DOCX 解析器、页面、数据库
对象或 LLM 调用。

## 2. 正式来源与权威边界

本说明服从以下正式来源：

1. `Cognitura-Overall-Design-1.2`：
   - §13 固定来源块、章节、页码和原始顺序的保真要求；
   - §17 固定 `SourceParsing` 的两阶段生成上游位置、局部重试和幂等要求；
   - §20 固定 `DocumentUpload`、`DocumentParsingStatus` 和来源展示边界；
   - §23 固定 `SourceDocument`、`DocumentBlock` 为 V1 物理核心对象；
   - §24 固定 Wave 1 仅包含 DOCX、`DocumentBlock`、标题、段落、列表、表格、
     图片引用、页码和来源预览。
2. `Cognitura-Schema-Baseline-2.0` §6.8：
   - 固定后续 `EvidenceReference` 所需的 `sourceDocumentRef`、
     `documentBlockRef`、`sectionPath`、`pageNumber`、`sourceOrder` 和
     `blockType` 兼容边界；
   - 不等同于 `SourceDocument` 或 `DocumentBlock` 的运行时 Schema。
3. `docs/contracts/cognitura-page-contracts.md`：
   - 固定 `DocumentUpload`、`DocumentParsingStatus` 和 `SourceEvidence`
     的已有非 Schema 页面边界；
   - 不授权创建产品页面。
4. `docs/engineering/cognitura-technology-baseline.md`：
   - 固定模块化单体、JDK 21、Spring Boot 4.1.0、PostgreSQL 18、
     MyBatis Starter 4.0.0 和 Desktop Web 技术边界。
5. `docs/engineering/cognitura-wave-1-entry-decision.md`：
   - 固定 `Wave1FeatureDevelopmentEntry = GO`；
   - 同时固定 `DirectFullImplementationStart = NO`、正式数据库写入和部署仍
     未获授权。

本说明是从属于总体设计的工程治理说明，不冒充总体设计或缺失的历史专项正文，
也不创建第二份总体设计。

## 3. 设计范围

### 3.1 本切片负责

`W1-D00` 负责：

- 设计卡与实现卡的分离；
- Wave 1 设计切片及依赖顺序；
- Wave 1 任务卡目录和验证器演进策略；
- 设计阶段唯一 `READY`、固定写集、Gate 和审查路线；
- 设计完成后释放实现卡所需的显式授权条件；
- 设计缺口、来源冲突和安全阻断的记录方式。

### 3.2 本切片不负责

`W1-D00` 不负责：

- 定义 `SourceDocument`、`DocumentBlock` 的最终字段表；
- 选择 DOCX 解析库、对象存储或上传大小上限；
- 创建 API、Controller、Mapper、migration、React 页面或业务组件；
- 打开、解包或解析 `raw/` 下三份 Golden Case 原件；
- 访问 Redis 文档中的遗留本地链接；
- 创建 Skeleton、SectionUnderstanding、认知产物、Renderer 或问答能力；
- 调用 LLM 或设计 Prompt。

以上内容只有在对应后续设计切片完成并通过 Gate 后，才能进入实现任务卡规划。

## 4. 方案裁决

Wave 1 采用“分层设计、统一封口”的方案：

```text
W1-D00 设计治理
  → W1-D01 SourceDocument 与来源生命周期
  → W1-D02 DocumentBlock 与 DOCX 解析保真/安全
  → W1-D03 重解析、幂等与稳定引用
  → W1-D04 来源预览、接口与验收
  → W1-D05 固定设计候选复核
  → 用户确认 Wave 1 书面设计
  → 准备 Wave 1 实现任务卡
```

不采用以下方案：

- 一篇大文档同时冻结全部 Wave 1 细节：单次审查范围过大，无法为身份、解析、
  兼容性和预览分别形成可拒绝的 Gate。
- 先完成 Wave 1–5 全部详细设计：会把尚未获得实现反馈的 Skeleton、深度生成、
  Renderer、问答和外部校验提前固化，扩大当前准入边界。
- 先写解析原型再补设计：违反用户确认的设计优先边界，也会在来源身份、失败语义
  和稳定引用尚未固定时形成事实代码。

## 5. 设计切片

### 5.1 W1-D00：设计治理

输入：

- Wave 1 准入裁决；
- Wave 0 已完成任务卡集合；
- 现有 W0 专用任务卡验证器；
- 总体设计的 Wave 1 范围。

输出：

- 本治理说明；
- 设计卡与实现卡的授权隔离；
- W1 任务卡验证器方案；
- W1-D01 至 W1-D05 的依赖与 Gate。

Gate：

```text
W1-DG0 DesignGovernance = PASS
```

完成条件：

- 本说明不存在占位符、相互冲突的状态或越界实现授权；
- 用户审阅并明确批准本说明；
- 后续计划只创建设计产物与设计验证，不包含业务实现。

### 5.2 W1-D01：SourceDocument 与来源生命周期

必须一次性固定：

- 来源身份、不可变原件身份和可变处理版本之间的区别；
- 内容哈希、格式、文件名、大小、接收时间和解析器版本的职责；
- 接收、校验、解析、可预览、失败和重新解析的状态及合法迁移；
- 重复上传、同内容不同文件名、不同内容同文件名的幂等裁决；
- 原始来源只读、不覆盖和派生物独立存放的约束；
- 正式数据库和对象存储尚未获授权时的端口边界。

不得在该切片中创建 DDL、migration、Mapper 或正式存储。

Gate：

```text
W1-DG1 SourceDocumentContract = PASS
```

### 5.3 W1-D02：DocumentBlock 与解析保真/安全

必须一次性固定：

- `HEADING/PARAGRAPH/LIST/TABLE/IMAGE/CAPTION/OTHER` 的规范化语义；
- 全文唯一顺序、章节路径、标题层级、页码可用性和原始位置证据；
- 列表层级、表格行列及单元格文本、图片引用和图注关联；
- 无可靠页码时以 `sourceOrder` 保持可追溯性的规则；
- DOCX ZIP 数量、展开大小、压缩比、路径穿越、外部关系、宏和嵌入对象的安全
  分类；
- 解析失败、部分解析、格式不支持、内容损坏和安全拒绝的错误分类；
- 不得跟随 Redis 遗留本地链接或任何外部关系读取目标内容。

Gate：

```text
W1-DG2 DocumentBlockFidelityAndSafety = PASS
```

### 5.4 W1-D03：重解析、幂等与稳定引用

必须一次性固定：

- `DocumentBlock` 身份与解析运行身份的分离；
- 相同内容、相同解析器版本和相同配置下不重复解析的判定；
- 解析器版本变化时的新 revision 产生规则；
- 块的增加、删除、移动、拆分、合并后的引用稳定性和失效表达；
- Wave 2 `SectionUnderstanding` 和 Wave 3 `EvidenceReference` 只能消费的公开只读
  引用；
- 旧 revision 可追溯、当前 revision 可选择且不得静默改写历史引用。

Gate：

```text
W1-DG3 ReparseAndReferenceCompatibility = PASS
```

### 5.5 W1-D04：来源预览、接口与验收

必须一次性固定：

- 上传、解析状态查询、来源预览读取三个用例的边界；
- Desktop Web 中的文档级状态、块级顺序、章节、表格、图片引用和错误展示；
- 预览只投影 `SourceDocument` 与 `DocumentBlock`，不得建立第二套来源事实；
- API 输入输出、分页或流式读取、错误响应、重试入口和只读权限边界；
- 单元、契约、集成、安全和 Golden Case 回归的验收层级；
- 测试只能通过受控路径读取原件，必须验证 SHA-256，且外部链接访问数必须为零。

Gate：

```text
W1-DG4 SourcePreviewAndAcceptance = PASS
```

### 5.6 W1-D05：固定设计候选复核

固定候选必须同时包含：

- W1-D00 至 W1-D04 的全部批准设计；
- 设计来源映射；
- 设计验证命令及正反例；
- 无占位符、无未登记冲突、无隐式实现授权的证据；
- 用户可审阅的设计变化与仍未授权范围说明。

```text
ImplementationSlicing = AFTER_EXPLICIT_USER_APPROVAL
ImplementationTaskCardRecommendationsInFixedDesignCandidate = FORBIDDEN
```

固定候选不得提前列出 `W1-Ixx`、实现切片、Provider 选择或写集建议。只有完整书面
设计通过本 Gate 且取得用户明确批准后，才允许另行编制实现计划并释放一张最小
实现卡。

审查路线固定为两个独立阶段：

```text
GeneralReviewModel = gpt-5.6-sol
GeneralReviewReasoningEffort = high
FinalGateModel = gpt-5.6-sol
FinalGateReasoningEffort = high
UltraModel = NOT_USED
```

Gate：

```text
W1-DG5 FixedDesignReview = PASS
```

## 6. 任务卡集合模型

### 6.1 目录与历史保护

Wave 0 文件保持原路径和历史语义，不移动、不重命名：

```text
docs/task-cards/README.md
docs/task-cards/W0-00-*.md
...
docs/task-cards/W0-08-*.md
```

Wave 1 使用独立子目录：

```text
docs/task-cards/wave-1/README.md
docs/task-cards/wave-1/W1-D00-*.md
...
docs/task-cards/wave-1/W1-D05-*.md
```

在设计 Gate 关闭前，不创建 `W1-Ixx` 实现卡。这样可以从文件集合层面证明
“设计批准不等于开发授权”。

### 6.2 卡片状态

单卡继续使用 Wave 0 已验证状态：

```text
BLOCKED_BY_DEPENDENCY
  → QUEUED
  → READY
  → DONE

BLOCKED_BY_DOCUMENTATION_GAP
  → QUEUED
  → READY
  → DONE
```

约束：

- 一个 Wave 1 卡集至多一张 `READY`；
- 只有索引中的 `ActiveTaskCard` 可以为 `READY`；
- `DONE` 表示该设计切片的文档、验证、Gate 和独立提交全部完成；
- 实际写入期间卡片仍保持 `READY`，执行记录可标记 `IN_PROGRESS`；
- 文档缺口不得用常识、Prompt 或原型代码填补。

### 6.3 卡集状态

Wave 1 设计卡集使用：

```text
READY_FOR_EXECUTION
BLOCKED_BY_DOCUMENTATION_GAP
COMPLETE
```

规则：

- `READY_FOR_EXECUTION`：恰有一张设计卡为 `READY`；
- `BLOCKED_BY_DOCUMENTATION_GAP`：没有 `READY`，至少一张卡为
  `BLOCKED_BY_DOCUMENTATION_GAP`，`ActiveTaskCard = NONE`；
- `COMPLETE`：全部设计卡为 `DONE`，没有 `READY`，
  `ActiveTaskCard = NONE`。

设计卡集 `COMPLETE` 仍不自动创建或释放实现卡。

### 6.4 卡片契约与审查路线

每张 Wave 1 设计卡必须且只能声明一次：

```text
TaskCardID
CardKind
Status
Gate
Risk
DependsOn
ReviewRoute
```

其中：

- `CardKind` 固定为 `DESIGN`；
- `TaskCardID` 只允许 `W1-D00` 至 `W1-D05`；
- `Gate` 必须与 §8.1 的对应 Gate 精确一致；
- `Risk` 只允许 `LOW/MEDIUM/HIGH`；
- `DependsOn` 使用逗号分隔的已存在设计卡 ID，首卡使用 `NONE`；
- `ReviewRoute` 对 W1-D00 至 W1-D04 固定为
  `SOL_HIGH_DESIGN_GATE`，对 W1-D05 固定为
  `SOL_HIGH_GENERAL_THEN_SOL_HIGH_FINAL_GATE`；
- 所有审查使用 `gpt-5.6-sol/high`，不得路由至 ultra 模型。

每张卡继续使用 Wave 0 已验证的七个章节：

```text
## 1. 目标
## 2. 前置条件与输入
## 3. 写集
## 4. 执行步骤
## 5. 验证命令
## 6. Gate 与完成定义
## 7. 提交与审查
```

卡片的“写集”必须列出精确 Repository 路径；未列出的路径均为禁止写集。
设计卡不得把 `server/src`、`web/src`、数据库 migration、原件或部署配置列入
写集。

## 7. 验证器方案

### 7.1 裁决

不直接泛化或替换已经封口的 W0 验证器。Wave 1 新增独立验证入口，避免 W1
规则回归时破坏 W0 的历史复现：

```text
scripts/verify-wave1-design-cards
tests/task-cards/verify-wave1-design-cards.sh
```

W0 入口继续保持：

```text
scripts/verify-task-cards --cards-dir docs/task-cards
bash tests/task-cards/verify-task-cards.sh
```

只有在 W1 设计卡验证稳定后，才可以通过单独设计裁决评估是否抽取共享验证库。

### 7.2 W1 验证内容

W1 验证器必须检查：

- 只扫描 `docs/task-cards/wave-1/W1-D*.md`；
- 卡片数量和允许 ID 由 W1 索引显式声明，不在脚本中复制隐式数量；
- 目录中的实际 `W1-D*.md` 集合必须与索引声明一一相等，任何未声明设计卡
  都必须失败；
- ID、文件名、必填字段、必填章节、依赖、Gate、风险和审查路线一致；
- 依赖形成有向无环图；
- 不允许依赖不存在的卡、依赖自身或形成循环；
- 唯一 `READY`、`ActiveTaskCard` 与卡集状态一致；
- `DONE` 卡的依赖必须全部为 `DONE`；
- `READY` 卡的依赖必须全部为 `DONE`；
- 设计卡写集不得包含 `server/src`、`web/src`、Flyway migration 或正式数据库
  配置；
- 无论 W1-D05 是否完成，在完整书面设计取得后续用户明确批准前，都不存在
  `W1-I*.md`；本设计验证器始终无条件拒绝实现卡；
- 负例至少覆盖重复 ID、未声明设计卡、未知依赖、循环依赖、第二张 READY、
  活动卡不一致、非法 Gate、越界写集、设计完成但未获用户批准即创建实现卡。

### 7.3 与统一质量门的关系

W1 设计验证可以新增独立入口，但在 W1-D05 关闭前不得把它伪装成 Wave 1
业务实现质量门。W0 的 `scripts/verify-wave0` 继续只证明 Wave 0 基线。

## 8. Gate 与授权边界

### 8.1 设计 Gate

```text
W1-DG0 DesignGovernance
W1-DG1 SourceDocumentContract
W1-DG2 DocumentBlockFidelityAndSafety
W1-DG3 ReparseAndReferenceCompatibility
W1-DG4 SourcePreviewAndAcceptance
W1-DG5 FixedDesignReview
```

设计 Gate 只证明书面契约完整、相容、可验证，不证明业务代码、数据库或页面已经
存在。

### 8.2 实现卡释放条件

只有同时满足以下条件，才允许准备 Wave 1 实现任务卡：

1. W1-D00 至 W1-D04 全部为 `DONE`；
2. W1-DG0 至 W1-DG4 全部为 `PASS`；
3. 固定设计候选通过两个独立 `gpt-5.6-sol/high` 审查阶段；
4. W1-DG5 为 `PASS`；
5. 用户审阅并明确批准完整 Wave 1 书面设计；
6. 新的实现计划和任务卡只释放一张最小 `READY` 卡；
7. 涉及正式数据库写入、部署或发布时另行获得 Gate 和用户授权。

不允许使用以下信号替代上述条件：

- 局部 Markdown 校验通过；
- 空工程构建成功；
- 已存在接口草图；
- 模型或 Agent 判断“设计足够”；
- Wave 1 总体准入为 `GO`。

## 9. 代码与模型职责边界

Wave 1 的运行时目标是确定性来源接入，不需要 LLM 参与。

后续获准实现时，代码负责：

- 文件格式和安全校验；
- 哈希、身份、版本和状态迁移；
- DOCX 结构解析与块规范化；
- 顺序、章节、页码、表格、图片引用和图注证据；
- 幂等、重试、错误分类和来源预览投影；
- 可复现测试和外部链接零访问保护。

模型在 Wave 1 不负责：

- 判断块类型或修复损坏 DOCX；
- 猜测标题层级、页码或缺失内容；
- 补齐表格、图片、链接目标或来源事实；
- 生成 Skeleton、认知正文或来源摘要。

模型能力从 Wave 2 的 `SectionUnderstanding` 和 Skeleton 候选开始进入，但只能
消费 Wave 1 已固定的只读块引用。

## 10. 错误、缺口与阻断

设计过程中遇到以下情况必须显式阻断：

- 总体设计与 Schema 重基线对同一字段产生不可调和冲突；
- 历史专项正文缺失导致运行时字段无法由已批准来源裁决；
- DOCX 特性要求读取外部关系或本地链接目标；
- 设计要求引入第二棵来源事实或在预览层重写原始内容；
- 需要正式数据库写入、生产凭据、部署或发布；
- 需要越过唯一 `READY` 卡修改其他切片写集。

阻断记录必须包含：

```text
DocumentationGapID
AffectedDesignSlice
AuthoritativeSourceConflict
ForbiddenAssumption
RequiredDecision
CurrentStatus
```

缺口解除只能来自新的权威来源或用户明确批准的工程裁决。

## 11. W1-D00 验收

本说明的验收命令为：

```bash
rg -n '[T]BD|[T]ODO|[待]定|BusinessImplementation = [A]UTHORIZED' \
  docs/superpowers/specs/2026-07-30-wave1-source-ingestion-governance-design.md
bash tests/task-cards/verify-wave1-design-cards.sh
scripts/verify-wave1-design-cards --cards-dir docs/task-cards/wave-1
bash tests/task-cards/verify-task-cards.sh
bash tests/ci/verify-markdown-links.sh
git diff --check
git status --short
```

预期结果：

- 占位符与越界授权扫描无匹配；
- W1 设计卡正例、11 个负例与 COMPLETE 终态通过；
- W0 历史任务卡和 Markdown 链接回归通过；
- `git diff --check` 退出码为 0；
- 工作树只包含 W1-D00 任务卡写集和原有未跟踪用户目录 `.idea/`；
- W0 任务卡/验证器、业务源码、原件和正式数据库配置均未修改；
- 动态活动卡、卡集状态和依赖释放与任务卡索引一致。

## 12. 本切片之后

本说明和只覆盖 Wave 1 设计产物的详细执行计划已经用户批准。执行时只处理任务卡
索引声明的唯一 `READY` 卡，并按依赖依次完成 W1-D01 至 W1-D05；执行过程不得
包含业务实现步骤。

完整 Wave 1 书面设计再次经用户批准后，才能另行编制业务实现计划。
