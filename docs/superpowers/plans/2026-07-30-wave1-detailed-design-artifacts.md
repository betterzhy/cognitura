# Cognitura Wave 1 Detailed Design Artifacts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成并固定 Cognitura Wave 1 来源接入的全部书面详细设计、设计任务卡、设计验证器和固定候选审查，同时保持业务实现未授权。

**Architecture:** 先建立与 Wave 0 隔离的 Wave 1 设计卡集合和验证器，再按 `SourceDocument → DocumentBlock → 重解析与稳定引用 → 来源预览与验收` 的单向依赖逐张关闭设计卡。每张卡形成独立本地提交；W1-D05 对完整设计固定候选执行两个相互独立的 `gpt-5.6-sol/high` 审查阶段，且不创建任何 `W1-Ixx` 实现卡。

**Tech Stack:** Markdown、Bash 3.2 兼容脚本、Git、现有 Markdown/Wave 0 验证入口；本计划不新增 Java、TypeScript、数据库、DOCX 解析库或 LLM 依赖。

## Global Constraints

- 正式产品名称固定为 `Cognitura`。
- 正式来源优先级服从 `AGENTS.md`；总体设计 1.2 与 Schema Baseline 2.0 不得被工程文档覆盖。
- Wave 1 只设计 DOCX、`SourceDocument`、`DocumentBlock`、结构保真、稳定引用和来源预览。
- 设计任务不得修改 `server/src`、`web/src`、Flyway migration、部署配置或 `raw/` 原件。
- 不得访问 Redis 原件中的遗留本地链接目标。
- `BusinessImplementation = NOT_AUTHORIZED`、`FormalDatabaseWrite = NOT_AUTHORIZED`、`DeploymentAndRelease = NOT_AUTHORIZED`。
- W1-D00 至 W1-D04 的 Gate 使用 `gpt-5.6-sol/high`；W1-D05 使用两个独立 `gpt-5.6-sol/high` 审查阶段；不使用 ultra 模型。
- 仅做本地提交；未获得新的明确授权时不推送远端。
- 保留 `.idea/` 为未跟踪用户状态，不纳入任何提交。
- 后端技术边界仍为 JDK 21、Maven 3.9.16、Spring Boot 4.1.0、PostgreSQL 18、MyBatis Starter 4.0.0；本计划不改动这些依赖。
- 前端正式交付仍为 Desktop Web；本计划不创建产品页面。

---

## File Structure

本计划最终创建或修改的文件按职责分组如下。

### 设计治理与状态

- `docs/superpowers/specs/2026-07-30-wave1-source-ingestion-governance-design.md`
  - 将 `DesignStatus` 从 `PROPOSED_FOR_USER_REVIEW` 更新为 `APPROVED`。
- `docs/engineering/cognitura-wave-1-design-plan.md`
  - 记录设计切片、Gate、当前卡、完成证据和实现未授权状态。
- `docs/engineering/cognitura-design-index.md`
  - 登记 Wave 1 四份详细设计与固定审查记录，不复制设计正文。
- `AGENTS.md`
  - 同步唯一活动设计卡与 Wave 1 设计状态，保持直接完整实现为 `NO`。
- `README.md`
  - 同步用户可见设计进度和设计文档入口。

### Wave 1 设计任务卡

- `docs/task-cards/wave-1/README.md`
- `docs/task-cards/wave-1/W1-D00-design-governance.md`
- `docs/task-cards/wave-1/W1-D01-source-document-contract.md`
- `docs/task-cards/wave-1/W1-D02-document-block-contract.md`
- `docs/task-cards/wave-1/W1-D03-reparse-reference-contract.md`
- `docs/task-cards/wave-1/W1-D04-source-preview-acceptance.md`
- `docs/task-cards/wave-1/W1-D05-fixed-design-review.md`

### Wave 1 详细设计

- `docs/design/wave-1/README.md`
- `docs/design/wave-1/cognitura-source-document-contract-1.0.md`
- `docs/design/wave-1/cognitura-document-block-contract-1.0.md`
- `docs/design/wave-1/cognitura-reparse-reference-contract-1.0.md`
- `docs/design/wave-1/cognitura-source-preview-contract-1.0.md`
- `docs/engineering/cognitura-wave-1-design-acceptance.md`

### 设计验证

- `scripts/verify-wave1-design-cards`
- `scripts/verify-wave1-design`
- `tests/task-cards/verify-wave1-design-cards.sh`
- `tests/contracts/wave1-design/verify-source-document-contract.sh`
- `tests/contracts/wave1-design/verify-document-block-contract.sh`
- `tests/contracts/wave1-design/verify-reparse-reference-contract.sh`
- `tests/contracts/wave1-design/verify-source-preview-contract.sh`
- `tests/contracts/wave1-design/verify-wave1-design-contracts.sh`

任何任务都不得创建 `docs/task-cards/wave-1/W1-I*.md`。

---

### Task 1: W1-D00 — 建立设计卡集合与隔离验证器

**Files:**

- Create: `docs/task-cards/wave-1/README.md`
- Create: `docs/task-cards/wave-1/W1-D00-design-governance.md`
- Create: `docs/task-cards/wave-1/W1-D01-source-document-contract.md`
- Create: `docs/task-cards/wave-1/W1-D02-document-block-contract.md`
- Create: `docs/task-cards/wave-1/W1-D03-reparse-reference-contract.md`
- Create: `docs/task-cards/wave-1/W1-D04-source-preview-acceptance.md`
- Create: `docs/task-cards/wave-1/W1-D05-fixed-design-review.md`
- Create: `docs/engineering/cognitura-wave-1-design-plan.md`
- Create: `scripts/verify-wave1-design-cards`
- Create: `tests/task-cards/verify-wave1-design-cards.sh`
- Modify: `docs/superpowers/specs/2026-07-30-wave1-source-ingestion-governance-design.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `AGENTS.md`
- Modify: `README.md`
- Test: `tests/task-cards/verify-wave1-design-cards.sh`
- Test: `tests/ci/verify-markdown-links.sh`

**Interfaces:**

- Consumes: 批准的 `W1-D00` 治理说明和现有 W0 任务卡状态模型。
- Produces: `scripts/verify-wave1-design-cards --cards-dir docs/task-cards/wave-1`；最终状态为 `W1-D00=DONE`、`W1-D01=READY`、`ActiveTaskCard=W1-D01`。

- [ ] **Step 1: 记录执行前边界**

Run:

```bash
git status --short --branch
git log -3 --oneline --decorate
test "$(git rev-parse HEAD)" = "f378f044311d6b8a276ced77b7173385c5679dd4"
```

Expected:

- 分支为 `main`；
- `HEAD` 以 `f378f04` 开头；
- 除 `.idea/` 外没有未提交用户修改。

如果 `HEAD` 已变化，重新读取 `AGENTS.md`、W1-D00 说明和变更文件，按实际固定
基线更新计划记录；不得 reset 或覆盖用户修改。

- [ ] **Step 2: 先写 W1 卡集合失败验证**

Create `tests/task-cards/verify-wave1-design-cards.sh`，测试入口必须先验证规范目录，
再复制到 `mktemp -d` 夹具中执行负例。首版至少包含：

```bash
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
verifier="${repo_root}/scripts/verify-wave1-design-cards"
cards_dir="${repo_root}/docs/task-cards/wave-1"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-w1-design-cards.XXXXXX")"
trap 'rm -rf "${test_tmp_root}"' EXIT

"${verifier}" --cards-dir "${cards_dir}"
```

在规范正例存在后，负例必须精确覆盖：

```text
missing required field: Gate
duplicate TaskCardID: W1-D01
expected exactly one READY task card
unknown dependency W1-D99
dependency cycle detected
ActiveTaskCard W1-D02 is not READY
Gate mismatch for W1-D03
design card write set contains forbidden path: server/src
implementation card is forbidden before W1-D05 completion
```

- [ ] **Step 3: 运行测试并观察预期失败**

Run:

```bash
bash tests/task-cards/verify-wave1-design-cards.sh
```

Expected: FAIL，因为 `scripts/verify-wave1-design-cards` 或 W1 卡目录尚不存在。

- [ ] **Step 4: 实现 Bash 3.2 兼容验证器**

Create executable `scripts/verify-wave1-design-cards`。参数只允许：

```text
--cards-dir PATH
```

必须从 `README.md` 读取：

```text
TaskCardSet = WAVE1_DESIGN
TaskCardIDs = W1-D00,W1-D01,W1-D02,W1-D03,W1-D04,W1-D05
TaskCardCount = 6
ActiveTaskCard
TaskCardSetStatus
```

核心扫描逻辑使用索引声明的 ID，而不是脚本内的 `W1-D*.md` 数量常量：

```bash
IFS=',' read -r -a declared_ids <<< "${declared_ids_value}"
for task_id in "${declared_ids[@]}"; do
  matches=("${cards_dir}/${task_id}-"*.md)
  [[ "${#matches[@]}" -eq 1 ]] ||
    fail "cannot resolve declared TaskCardID: ${task_id}"
done
```

每张卡精确要求：

```text
TaskCardID
CardKind = DESIGN
Status
Gate
Risk
DependsOn
ReviewRoute
```

允许状态：

```text
DONE
READY
QUEUED
BLOCKED_BY_DEPENDENCY
BLOCKED_BY_DOCUMENTATION_GAP
```

Gate 映射：

```text
W1-D00 = W1-DG0 DesignGovernance
W1-D01 = W1-DG1 SourceDocumentContract
W1-D02 = W1-DG2 DocumentBlockFidelityAndSafety
W1-D03 = W1-DG3 ReparseAndReferenceCompatibility
W1-D04 = W1-DG4 SourcePreviewAndAcceptance
W1-D05 = W1-DG5 FixedDesignReview
```

审查路线：

```text
W1-D00..W1-D04 = SOL_HIGH_DESIGN_GATE
W1-D05 = SOL_HIGH_GENERAL_THEN_SOL_HIGH_FINAL_GATE
```

循环检测使用迭代拓扑消除，不使用 Bash 4 associative array。每一轮从尚未消除的
卡中移除所有依赖均已消除的卡；一轮没有进展且仍有卡时报告
`dependency cycle detected`。

Write-set 扫描必须拒绝：

```text
server/src
web/src
db/migration
raw/
.github/
```

同时拒绝卡目录内任何 `W1-I*.md`。

- [ ] **Step 5: 创建六张设计卡与索引**

每张卡使用七个既有章节：

```text
## 1. 目标
## 2. 前置条件与输入
## 3. 写集
## 4. 执行步骤
## 5. 验证命令
## 6. Gate 与完成定义
## 7. 提交与审查
```

最终索引状态：

```text
CanonicalProjectName = Cognitura
TaskCardSet = WAVE1_DESIGN
TaskCardIDs = W1-D00,W1-D01,W1-D02,W1-D03,W1-D04,W1-D05
TaskCardCount = 6
ActiveTaskCard = W1-D01
TaskCardSetStatus = READY_FOR_EXECUTION
BusinessImplementation = NOT_AUTHORIZED
```

卡片依赖和最终状态：

```text
W1-D00 DONE                         DependsOn=NONE
W1-D01 READY                        DependsOn=W1-D00
W1-D02 BLOCKED_BY_DEPENDENCY        DependsOn=W1-D01
W1-D03 BLOCKED_BY_DEPENDENCY        DependsOn=W1-D02
W1-D04 BLOCKED_BY_DEPENDENCY        DependsOn=W1-D03
W1-D05 BLOCKED_BY_DEPENDENCY        DependsOn=W1-D04
```

W1-D00 的写集包含本任务列出的文件；W1-D01 至 W1-D05 的写集只包含各自的设计
文档、契约验证、卡片/索引/状态同步文件，不得包含业务源码。

- [ ] **Step 6: 创建正式 Wave 1 设计计划和同步状态**

Create `docs/engineering/cognitura-wave-1-design-plan.md`，固定：

```text
Wave1DesignStatus = IN_PROGRESS
ActiveDesignTaskCard = W1-D01
Wave1ImplementationTaskCardSet = NOT_CREATED
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
DeploymentAndRelease = NOT_AUTHORIZED
```

Update:

- W1-D00 spec `DesignStatus = APPROVED`；
- `docs/engineering/cognitura-design-index.md` 登记 W1-D00 和 Wave 1 设计计划；
- `AGENTS.md`、`README.md` 同步 `ActiveTaskCard = W1-D01` 和
  `ActiveTaskCardStatus = READY`；
- W0 根任务卡索引保持 `TaskCardSet=WAVE0`、`COMPLETE`、`ActiveTaskCard=NONE`。

- [ ] **Step 7: 运行 W1-D00 全量验证**

Run:

```bash
chmod +x scripts/verify-wave1-design-cards
bash tests/task-cards/verify-wave1-design-cards.sh
scripts/verify-wave1-design-cards --cards-dir docs/task-cards/wave-1
bash tests/task-cards/verify-task-cards.sh
bash tests/ci/verify-markdown-links.sh
git diff --check
```

Expected:

```text
Wave1DesignTaskCardContractTests = PASS
Wave1DesignTaskCardValidation = PASS
TaskCardCount = 6
TaskCardSetStatus = READY_FOR_EXECUTION
ActiveTaskCard = W1-D01
TaskCardContractTests = PASS
MarkdownLinkContractTests = PASS
```

- [ ] **Step 8: 以 `gpt-5.6-sol/high` 审查 W1-D00 写集**

审查必须核对：

- 没有业务源码、原件或远程配置变更；
- W0 历史验证器未被改写；
- 六张 W1 设计卡恰有一张 `READY`；
- `.idea/` 未暂存；
- W1-D01 至 D05 没有提前实施。

P0/P1/P2 任一非零时先修复、重新运行 Step 7，再重新审查。

- [ ] **Step 9: 本地提交 W1-D00**

Run:

```bash
git add \
  AGENTS.md \
  README.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-wave-1-design-plan.md \
  docs/superpowers/specs/2026-07-30-wave1-source-ingestion-governance-design.md \
  docs/task-cards/wave-1 \
  scripts/verify-wave1-design-cards \
  tests/task-cards/verify-wave1-design-cards.sh
git diff --cached --check
git status --short
git commit -m "docs: establish Wave 1 design task cards"
```

Do not stage `.idea/`. Do not push.

---

### Task 2: W1-D01 — 固定 SourceDocument 身份与生命周期

**Files:**

- Create: `docs/design/wave-1/README.md`
- Create: `docs/design/wave-1/cognitura-source-document-contract-1.0.md`
- Create: `tests/contracts/wave1-design/verify-source-document-contract.sh`
- Modify: `docs/task-cards/wave-1/W1-D01-source-document-contract.md`
- Modify: `docs/task-cards/wave-1/W1-D02-document-block-contract.md`
- Modify: `docs/task-cards/wave-1/README.md`
- Modify: `docs/engineering/cognitura-wave-1-design-plan.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `AGENTS.md`
- Modify: `README.md`
- Test: `tests/contracts/wave1-design/verify-source-document-contract.sh`

**Interfaces:**

- Consumes: W1-D00 Gate、总体设计 §13/§17/§23/§24、技术基线的端口边界。
- Produces: `SourceDocumentContractVersion = 1.0`、不可变来源身份、处理 revision、
  幂等上传和状态机；W1-D02 只消费这些已固定名词。

- [ ] **Step 1: 先写缺失契约的失败验证**

Create `tests/contracts/wave1-design/verify-source-document-contract.sh`，要求目标文档
精确包含：

```text
SourceDocumentContractVersion = 1.0
SourceDocumentIdentity = LOGICAL_UPLOAD
SourceBinaryIdentity = SHA256_RAW_BYTES
ProcessingRevisionIdentity = SOURCE_DOCUMENT_HASH_PARSER_PROFILE
DuplicateBytesAcrossDifferentRequests = DISTINCT_SOURCE_DOCUMENT_SHARED_BINARY
SameIdempotencyKeySameBytes = RETURN_EXISTING_SOURCE_DOCUMENT
SameIdempotencyKeyDifferentBytes = IDEMPOTENCY_CONFLICT
SourceOriginalMutation = FORBIDDEN
FormalDatabaseWrite = NOT_AUTHORIZED
```

状态必须形成：

```text
RECEIVED → VALIDATING → ACCEPTED → PARSING → PARSED → PREVIEW_READY
VALIDATING → REJECTED
PARSING → FAILED_RETRYABLE
PARSING → FAILED_TERMINAL
FAILED_RETRYABLE → PARSING
```

测试还必须复制文档到临时目录并通过删字段/篡改状态迁移构造至少 6 个负例。

- [ ] **Step 2: 运行验证并观察预期失败**

Run:

```bash
bash tests/contracts/wave1-design/verify-source-document-contract.sh
```

Expected: FAIL，报告缺少
`docs/design/wave-1/cognitura-source-document-contract-1.0.md`。

- [ ] **Step 3: 写 SourceDocument 正式工程契约**

Create document with these exact decisions:

1. `SourceDocumentId` 表示一次逻辑上传，不由文件名或哈希单独决定。
2. 原始字节以 `SHA-256` 标识；不同逻辑上传可共享同一只读二进制对象。
3. 相同 `Idempotency-Key + workspaceId + contentSha256` 返回原
   `SourceDocumentId`；相同 key 不同哈希返回 `IDEMPOTENCY_CONFLICT`。
4. `SourceProcessingRevisionId` 与
   `(sourceDocumentId, contentSha256, parserProfileVersion)` 唯一组合绑定。
5. `SourceDocument` 保存不可变上传事实；活动解析状态由当前 processing revision
   投影，不覆盖旧 revision。
6. 原始文件名是显示元数据，不参与身份比较。
7. 抽象端口固定为：

```text
SourceBinaryStore
SourceDocumentStore
SourceProcessingRevisionStore
SourceIngestionClock
SourceIdGenerator
```

这些端口是设计接口，不选择对象存储，不创建数据库表。

字段职责至少固定：

```text
sourceDocumentId
workspaceId
originalFileName
mediaType
byteLength
contentSha256
receivedAt
sourceProcessingRevisionId
parserProfileVersion
processingStatus
failureCode
failureDetail
startedAt
completedAt
```

错误码至少固定：

```text
UNSUPPORTED_MEDIA_TYPE
EMPTY_SOURCE_FILE
SOURCE_SIZE_LIMIT
SOURCE_HASH_MISMATCH
IDEMPOTENCY_CONFLICT
DOCX_SECURITY_REJECTED
DOCX_FORMAT_INVALID
PARSER_RETRYABLE_FAILURE
PARSER_TERMINAL_FAILURE
```

- [ ] **Step 4: 写状态机和并发裁决表**

文档必须明确：

- `REJECTED` 和 `FAILED_TERMINAL` 不可自动重试；
- `FAILED_RETRYABLE` 只能创建同 revision 的新 attempt，不创建第二个成功
  revision；
- 同一 `(sourceDocumentId, contentSha256, parserProfileVersion)` 同时最多一个
  活动 attempt；
- 第一个成功完成的 attempt 成为该 revision 的唯一成功结果，迟到结果被拒绝；
- 原件只读，重新解析只能创建或重用 processing revision；
- 删除、永久清除、配额和对象存储 Provider 不属于 Wave 1。

- [ ] **Step 5: 运行契约、链接和 W1 卡验证**

Run:

```bash
bash tests/contracts/wave1-design/verify-source-document-contract.sh
bash tests/task-cards/verify-wave1-design-cards.sh
bash tests/ci/verify-markdown-links.sh
git diff --check
```

Expected: all PASS。

- [ ] **Step 6: 以 `gpt-5.6-sol/high` 审查 W1-D01**

审查必须重点判断：

- 逻辑上传身份、二进制哈希和解析 revision 没有混为一个 ID；
- 重复文件不会静默合并用户的两次来源意图；
- 重试不会产生两个成功事实；
- 未选择对象存储或写入正式数据库；
- 没有引入用户级知识树或 LLM。

- [ ] **Step 7: 关闭 W1-D01 并释放 W1-D02**

Update:

```text
W1-D01 Status = DONE
W1-D02 Status = READY
ActiveTaskCard = W1-D02
W1-DG1 SourceDocumentContract = PASS
```

同步 W1 索引、工程设计计划、设计索引、`AGENTS.md` 和 `README.md`。W0 索引
保持不变。

- [ ] **Step 8: 本地提交 W1-D01**

Run:

```bash
git add \
  AGENTS.md \
  README.md \
  docs/design/wave-1/README.md \
  docs/design/wave-1/cognitura-source-document-contract-1.0.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-wave-1-design-plan.md \
  docs/task-cards/wave-1 \
  tests/contracts/wave1-design/verify-source-document-contract.sh
git diff --cached --check
git commit -m "docs: define SourceDocument lifecycle contract"
```

Do not push.

---

### Task 3: W1-D02 — 固定 DocumentBlock 保真与安全契约

**Files:**

- Create: `docs/design/wave-1/cognitura-document-block-contract-1.0.md`
- Create: `tests/contracts/wave1-design/verify-document-block-contract.sh`
- Modify: `docs/design/wave-1/README.md`
- Modify: `docs/task-cards/wave-1/W1-D02-document-block-contract.md`
- Modify: `docs/task-cards/wave-1/W1-D03-reparse-reference-contract.md`
- Modify: `docs/task-cards/wave-1/README.md`
- Modify: `docs/engineering/cognitura-wave-1-design-plan.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `AGENTS.md`
- Modify: `README.md`
- Test: `tests/contracts/wave1-design/verify-document-block-contract.sh`

**Interfaces:**

- Consumes: `SourceDocumentId`、`SourceProcessingRevisionId` 和 D01 状态机。
- Produces: `DocumentBlockContractVersion = 1.0`、块类型 union、顺序/页码规则、
  DOCX 安全分类；W1-D03 只引用这些字段名。

- [ ] **Step 1: 先写缺失契约的失败验证**

The test must require:

```text
DocumentBlockContractVersion = 1.0
SourceOrderBase = 0
SourceOrderRule = UNIQUE_CONTIGUOUS_WITHIN_PROCESSING_REVISION
PageNumberDefault = null
ExternalRelationshipDereference = FORBIDDEN
MacroExecution = FORBIDDEN
EmbeddedObjectExecution = FORBIDDEN
MAX_ZIP_ENTRY_COUNT = 4096
MAX_ZIP_ENTRY_BYTES = 16777216
MAX_ZIP_TOTAL_BYTES = 134217728
MAX_COMPRESSION_RATIO = 200
```

It must require all block types:

```text
HEADING
PARAGRAPH
LIST
TABLE
IMAGE
CAPTION
OTHER
```

负例至少删除一种 block type、把 `PageNumberDefault` 改为 `1`、允许外链读取、
放宽一个 ZIP 限额。

- [ ] **Step 2: 运行验证并观察预期失败**

Run:

```bash
bash tests/contracts/wave1-design/verify-document-block-contract.sh
```

Expected: FAIL because the D02 contract is missing.

- [ ] **Step 3: 定义公共 DocumentBlock envelope**

Every block must contain:

```text
documentBlockId
sourceDocumentId
sourceProcessingRevisionId
blockType
sourceOrder
sectionPath
pageNumber
sourcePart
sourceElementIndex
contentHash
payload
```

Exact rules:

- `sourceOrder` is zero-based, unique, contiguous across every block in one processing revision.
- `sectionPath` is derived only from preceding heading blocks and preserves heading text.
- `pageNumber` is nullable and must remain `null` for ordinary DOCX XML parsing.
- A non-null page number requires a separately approved deterministic layout profile and
  recorded `pageEvidence`; explicit page breaks alone do not prove a rendered page number.
- `sourcePart + sourceElementIndex` is provenance, not a public stable reference.
- `contentHash` hashes the canonical payload and never replaces `documentBlockId`.

- [ ] **Step 4: Define each payload exactly**

The contract must define:

```text
HeadingPayload = text,level,styleName
ParagraphPayload = text,styleName
ListPayload = listInstanceId,itemLevel,itemOrdinal,markerText,text
TablePayload = rows[{rowIndex,cells[{columnIndex,rowSpan,columnSpan,text}]}]
ImagePayload = relationshipId,relationshipMode,mediaRef,mediaType,byteLength,contentSha256
CaptionPayload = text,captionForBlockId
OtherPayload = text,sourceKind
```

Rules:

- Heading level accepts only `1..9`; unrecognized heading-like styles remain paragraph or
  `OTHER` and may not be guessed into a heading.
- Each list item is one `LIST` block; list nesting is represented by `itemLevel`.
- Tables preserve row order, column position, merged-cell spans, and full cell text.
- Internal image bytes may be represented only by an immutable `mediaRef` and SHA-256.
- External image relationships produce metadata with no fetched bytes and a security
  disclosure; target content is never read.
- Captions are separate blocks linked to an image; no caption text is invented.

- [ ] **Step 5: Define deterministic safety rejection**

Reuse the existing Golden Case guard limits:

```text
MAX_ZIP_ENTRY_COUNT = 4096
MAX_ZIP_ENTRY_BYTES = 16 MiB
MAX_ZIP_TOTAL_BYTES = 128 MiB
MAX_COMPRESSION_RATIO = 200
```

Reject duplicate ZIP entry names, absolute paths, `..` traversal, unknown sizes, XML external
entities, macros requiring execution, executable embedded objects, and any request to follow an
external relationship. Classify results as:

```text
SECURITY_REJECTED
FORMAT_INVALID
PARTIAL_PARSE
PARSE_FAILED_RETRYABLE
PARSE_FAILED_TERMINAL
```

`PARTIAL_PARSE` is only legal when all omitted components and error locations are explicit;
it cannot become `PREVIEW_READY` without an explicit user-visible incomplete marker.

- [ ] **Step 6: Run focused verification**

Run:

```bash
bash tests/contracts/wave1-design/verify-document-block-contract.sh
bash tests/contracts/wave1-design/verify-source-document-contract.sh
bash tests/task-cards/verify-wave1-design-cards.sh
bash tests/ci/verify-markdown-links.sh
git diff --check
```

Expected: all PASS.

- [ ] **Step 7: Sol/high review, state transition, and local commit**

Review with `gpt-5.6-sol/high`, require P0/P1/P2 = 0, then update:

```text
W1-D02 Status = DONE
W1-D03 Status = READY
ActiveTaskCard = W1-D03
W1-DG2 DocumentBlockFidelityAndSafety = PASS
```

Commit:

```bash
git add \
  AGENTS.md \
  README.md \
  docs/design/wave-1/README.md \
  docs/design/wave-1/cognitura-document-block-contract-1.0.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-wave-1-design-plan.md \
  docs/task-cards/wave-1 \
  tests/contracts/wave1-design/verify-document-block-contract.sh
git diff --cached --check
git commit -m "docs: define DocumentBlock fidelity contract"
```

Do not push.

---

### Task 4: W1-D03 — 固定重解析、幂等与稳定引用

**Files:**

- Create: `docs/design/wave-1/cognitura-reparse-reference-contract-1.0.md`
- Create: `tests/contracts/wave1-design/verify-reparse-reference-contract.sh`
- Modify: `docs/design/wave-1/README.md`
- Modify: `docs/task-cards/wave-1/W1-D03-reparse-reference-contract.md`
- Modify: `docs/task-cards/wave-1/W1-D04-source-preview-acceptance.md`
- Modify: `docs/task-cards/wave-1/README.md`
- Modify: `docs/engineering/cognitura-wave-1-design-plan.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `AGENTS.md`
- Modify: `README.md`
- Test: `tests/contracts/wave1-design/verify-reparse-reference-contract.sh`

**Interfaces:**

- Consumes: D01 processing revision and D02 block envelope.
- Produces: immutable `DocumentBlockRef` and `BlockLineageMap` contract for Wave 2/3 consumers.

- [ ] **Step 1: Write the failing contract test**

Require:

```text
ReparseReferenceContractVersion = 1.0
DocumentBlockRef = SOURCE_DOCUMENT_ID+PROCESSING_REVISION_ID+DOCUMENT_BLOCK_ID
HistoricalReferenceRetargeting = FORBIDDEN
SameHashSameParserProfile = REUSE_SUCCESSFUL_REVISION
SameHashNewParserProfile = CREATE_NEW_PROCESSING_REVISION
LineageStates = UNCHANGED,MOVED,MODIFIED,SPLIT,MERGED,REMOVED,ADDED,AMBIGUOUS
AmbiguousLineageAutoResolution = FORBIDDEN
```

Negative fixtures must allow silent retargeting, omit `REMOVED`, or claim a new parser profile
reuses the old revision; each must fail.

- [ ] **Step 2: Run and observe failure**

Run:

```bash
bash tests/contracts/wave1-design/verify-reparse-reference-contract.sh
```

Expected: FAIL because the D03 contract is missing.

- [ ] **Step 3: Define immutable references**

Exact public reference:

```text
DocumentBlockRef {
  sourceDocumentId
  sourceProcessingRevisionId
  documentBlockId
}
```

Rules:

- The tuple points to exactly one immutable block.
- A new processing revision creates new block IDs.
- Old references remain resolvable while their source revision is retained.
- `activeSourceProcessingRevisionId` is a convenience selector, never part of an
  `EvidenceReference`.
- Consumers must opt into a new revision; no query may silently substitute an active block for
  an historical block.

- [ ] **Step 4: Define idempotency and lineage**

Exact reparse decisions:

```text
same source hash + same parserProfileVersion + successful revision
  → reuse the successful revision

same source hash + different parserProfileVersion
  → create a new processing revision

same source document + new source bytes
  → create a new SourceDocument; do not mutate the existing upload fact
```

`BlockLineageMap` contains:

```text
fromProcessingRevisionId
toProcessingRevisionId
entries[{fromBlockRefs,toBlockRefs,lineageState,confidenceBasis}]
createdAt
algorithmVersion
```

`confidenceBasis` is deterministic evidence such as exact canonical payload hash, anchored
source position, or explicit user decision. It is not an LLM confidence score.

`AMBIGUOUS` must remain unresolved until a later user or authorized design decision; it may not
retarget EvidenceReference automatically.

- [ ] **Step 5: Define Wave 2/3 read-only compatibility**

Allowed consumers:

```text
Wave2 SectionUnderstanding:
  sourceProcessingRevisionId + ordered DocumentBlockRef[]

Wave3 EvidenceReference:
  sourceDocumentRef + documentBlockRef + sectionPath +
  pageNumber/sourceOrder + blockType
```

No consumer may update Wave 1 blocks. The contract must explicitly map D02 fields to Schema
Baseline 2.0 §6.8 and document that `EvidenceReference` stores summaries/metadata rather than
copying the full source.

- [ ] **Step 6: Verify all three source contracts**

Run:

```bash
bash tests/contracts/wave1-design/verify-source-document-contract.sh
bash tests/contracts/wave1-design/verify-document-block-contract.sh
bash tests/contracts/wave1-design/verify-reparse-reference-contract.sh
bash tests/task-cards/verify-wave1-design-cards.sh
bash tests/ci/verify-markdown-links.sh
git diff --check
```

Expected: all PASS.

- [ ] **Step 7: Sol/high review, state transition, and local commit**

Review with `gpt-5.6-sol/high`, require P0/P1/P2 = 0, then update:

```text
W1-D03 Status = DONE
W1-D04 Status = READY
ActiveTaskCard = W1-D04
W1-DG3 ReparseAndReferenceCompatibility = PASS
```

Commit:

```bash
git add \
  AGENTS.md \
  README.md \
  docs/design/wave-1/README.md \
  docs/design/wave-1/cognitura-reparse-reference-contract-1.0.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-wave-1-design-plan.md \
  docs/task-cards/wave-1 \
  tests/contracts/wave1-design/verify-reparse-reference-contract.sh
git diff --cached --check
git commit -m "docs: define source reparse reference contract"
```

Do not push.

---

### Task 5: W1-D04 — 固定来源预览、接口与验收

**Files:**

- Create: `docs/design/wave-1/cognitura-source-preview-contract-1.0.md`
- Create: `tests/contracts/wave1-design/verify-source-preview-contract.sh`
- Create: `tests/contracts/wave1-design/verify-wave1-design-contracts.sh`
- Create: `scripts/verify-wave1-design`
- Modify: `docs/design/wave-1/README.md`
- Modify: `docs/task-cards/wave-1/W1-D04-source-preview-acceptance.md`
- Modify: `docs/task-cards/wave-1/W1-D05-fixed-design-review.md`
- Modify: `docs/task-cards/wave-1/README.md`
- Modify: `docs/engineering/cognitura-wave-1-design-plan.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `AGENTS.md`
- Modify: `README.md`
- Test: `tests/contracts/wave1-design/verify-source-preview-contract.sh`
- Test: `tests/contracts/wave1-design/verify-wave1-design-contracts.sh`

**Interfaces:**

- Consumes: D01 status, D02 blocks, D03 immutable references.
- Produces: upload/status/preview application contract and `scripts/verify-wave1-design`.

- [ ] **Step 1: Write failing source-preview contract verification**

Require exact use cases:

```text
POST /api/v1/workspaces/{workspaceId}/source-documents
GET /api/v1/source-documents/{sourceDocumentId}
POST /api/v1/source-documents/{sourceDocumentId}/processing-revisions
GET /api/v1/source-documents/{sourceDocumentId}/processing-revisions/{sourceProcessingRevisionId}
GET /api/v1/source-documents/{sourceDocumentId}/processing-revisions/{sourceProcessingRevisionId}/blocks
```

Require:

```text
PreviewPagination = KEYSET_BY_SOURCE_ORDER
PreviewDefaultLimit = 100
PreviewMaximumLimit = 500
PreviewFactSource = SOURCE_DOCUMENT_AND_DOCUMENT_BLOCK_ONLY
RendererFactCreation = FORBIDDEN
LLMUsage = NONE
ExternalRelationshipAccessCount = 0
```

Negative fixtures must accept offset pagination without stable revision, create preview-only
content, allow an LLM summary, or permit external relationship access; each must fail.

- [ ] **Step 2: Run and observe failure**

Run:

```bash
bash tests/contracts/wave1-design/verify-source-preview-contract.sh
```

Expected: FAIL because the D04 contract is missing.

- [ ] **Step 3: Define command and query DTOs**

Upload command:

```text
CreateSourceDocumentCommand {
  workspaceId
  idempotencyKey
  originalFileName
  declaredMediaType
  declaredByteLength
  contentSha256
  binaryStream
}
```

Upload response:

```text
CreateSourceDocumentResult {
  sourceDocumentId
  processingStatus
  contentSha256
  receivedAt
}
```

Processing request:

```text
CreateProcessingRevisionCommand {
  sourceDocumentId
  parserProfileVersion
}
```

Preview block DTO must be a direct projection of the D02 envelope and typed payload. Repository,
Mapper, storage key, raw XML, internal exception and binary filesystem path must never appear in
Web DTOs.

- [ ] **Step 4: Define HTTP semantics and error mapping**

Exact decisions:

```text
201 Created = new SourceDocument
200 OK = idempotent replay returning the existing SourceDocument
202 Accepted = new processing revision accepted
400 Bad Request = malformed command or unsupported pagination
404 Not Found = source document/revision not visible in the requested workspace context
409 Conflict = idempotency conflict or concurrent successful revision conflict
413 Content Too Large = upload or expanded DOCX limit
415 Unsupported Media Type = non-DOCX input
422 Unprocessable Content = terminal DOCX format/security rejection
503 Service Unavailable = retryable parser infrastructure failure
```

Every error response contains:

```text
errorCode
message
retryable
sourceDocumentId
sourceProcessingRevisionId
```

The last two fields are nullable only before their identities exist.

- [ ] **Step 5: Define Desktop Web state projection**

The contract must map backend state to:

```text
UPLOAD_IDLE
UPLOAD_IN_PROGRESS
VALIDATING
PARSING
PREVIEW_READY
PARTIAL_PREVIEW
RETRYABLE_FAILURE
TERMINAL_FAILURE
```

The preview shows original file name, processing revision, section path, source order, nullable
page number, block type, original text/table cells/image metadata/caption, and explicit incomplete
or external-reference markers.

It must not show generated summaries, inferred headings, fetched external images, Skeleton,
KnowledgeTheme, CognitiveModule, or KnowledgeElement.

- [ ] **Step 6: Define acceptance layers**

The design must require later implementation to provide:

```text
Unit:
  identity, transition, normalization, lineage, pagination
Contract:
  API DTO, error code, state projection, external-link zero access
Integration:
  PostgreSQL 18 Testcontainers only after database Gate
Security:
  ZIP count/size/ratio, traversal, duplicate entries, XXE, external relationships
Golden:
  three manifest-tracked DOCX files, SHA-256 unchanged, source order and structure fingerprints
```

This design task does not run a new parser against the three originals. It may run existing W0
guarded regression during final fixed-candidate verification.

- [ ] **Step 7: Create the aggregate design verifier**

Create executable `scripts/verify-wave1-design`:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "${repo_root}/tests/task-cards/verify-wave1-design-cards.sh"
bash "${repo_root}/tests/contracts/wave1-design/verify-wave1-design-contracts.sh"
bash "${repo_root}/tests/ci/verify-markdown-links.sh"
```

Create `verify-wave1-design-contracts.sh` to invoke the four contract tests in D01→D04 order and
print:

```text
Wave1SourceDocumentContract = PASS
Wave1DocumentBlockContract = PASS
Wave1ReparseReferenceContract = PASS
Wave1SourcePreviewContract = PASS
Wave1DesignContracts = PASS
```

- [ ] **Step 8: Verify W1-D04**

Run:

```bash
chmod +x scripts/verify-wave1-design
bash tests/contracts/wave1-design/verify-source-preview-contract.sh
bash tests/contracts/wave1-design/verify-wave1-design-contracts.sh
scripts/verify-wave1-design
git diff --check
```

Expected: all PASS.

- [ ] **Step 9: Sol/high review, state transition, and local commit**

Review with `gpt-5.6-sol/high`, require P0/P1/P2 = 0, then update:

```text
W1-D04 Status = DONE
W1-D05 Status = READY
ActiveTaskCard = W1-D05
W1-DG4 SourcePreviewAndAcceptance = PASS
```

Commit:

```bash
git add \
  AGENTS.md \
  README.md \
  docs/design/wave-1/README.md \
  docs/design/wave-1/cognitura-source-preview-contract-1.0.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-wave-1-design-plan.md \
  docs/task-cards/wave-1 \
  scripts/verify-wave1-design \
  tests/contracts/wave1-design/verify-source-preview-contract.sh \
  tests/contracts/wave1-design/verify-wave1-design-contracts.sh
git diff --cached --check
git commit -m "docs: define source preview acceptance contract"
```

Do not push.

---

### Task 6: W1-D05 — 固定设计候选、双阶段复核与设计封口

**Files:**

- Create: `docs/engineering/cognitura-wave-1-design-acceptance.md`
- Modify: `docs/design/wave-1/README.md`
- Modify: `docs/task-cards/wave-1/W1-D05-fixed-design-review.md`
- Modify: `docs/task-cards/wave-1/README.md`
- Modify: `docs/engineering/cognitura-wave-1-design-plan.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `AGENTS.md`
- Modify: `README.md`
- Test: `scripts/verify-wave1-design`
- Test: `scripts/verify-wave0`

**Interfaces:**

- Consumes: fixed commits for W1-D00 through W1-D04 and all design verification.
- Produces: `W1-DG5 FixedDesignReview = PASS` or a concrete NO-GO finding list; does not produce
  implementation cards.

- [ ] **Step 1: Verify the pre-review candidate**

Run:

```bash
git status --short --branch
scripts/verify-wave1-design
scripts/verify-wave0
git diff --check
git log -6 --oneline --decorate
```

Expected:

- only `.idea/` is untracked;
- Wave 1 design verifier passes;
- all seven existing Wave 0 stages pass;
- W1-D00 through W1-D04 are separate local commits;
- W1-D05 is the sole `READY` card.

- [ ] **Step 2: Freeze the exact design candidate**

Run:

```bash
git rev-parse HEAD
git status --short
```

The full 40-character SHA printed here is the fixed design candidate. The worktree must contain
only untracked `.idea/`; otherwise do not start review. Record the SHA in the execution notes and
pass the same literal SHA to both reviewers.

Do not create the acceptance record before the reviews. This avoids a self-referential commit SHA:
the acceptance record will be a later closure artifact that names the already fixed and reviewed
design candidate.

- [ ] **Step 3: Run independent general review with `gpt-5.6-sol/high`**

The reviewer receives the exact fixed SHA and reads:

- overall design §13, §17, §20, §23, §24;
- Schema Baseline 2.0 §6.8;
- W1-D00 spec;
- four Wave 1 contracts;
- design cards and verification scripts;
- candidate diff from the W0 completion baseline.

Required output:

```text
GeneralReviewModel = gpt-5.6-sol
GeneralReviewReasoningEffort = high
GeneralReviewVerdict = READY or NOT_READY
GeneralReviewP0 = non-negative integer
GeneralReviewP1 = non-negative integer
GeneralReviewP2 = non-negative integer
ReviewedCandidate = the exact 40-character SHA from Step 2
```

Any finding requires a new fix commit, fresh full verification, a new candidate SHA, and a new
general review.

- [ ] **Step 4: Run independent final gate with a separate `gpt-5.6-sol/high` reviewer**

The final reviewer must not reuse the general review conclusion as evidence. It independently
checks:

- formal-source traceability;
- complete state/error/identity/reference decisions;
- no second source fact model in preview;
- no LLM in Wave 1;
- no raw mutation or external relationship access;
- no business code or implementation card;
- full verification output bound to the exact candidate.

Required output:

```text
FinalGateModel = gpt-5.6-sol
FinalGateReasoningEffort = high
FinalGateVerdict = GO or NO_GO
FinalGateP0 = non-negative integer
FinalGateP1 = non-negative integer
FinalGateP2 = non-negative integer
ReviewedCandidate = the exact 40-character SHA from Step 2
UltraModel = NOT_USED
```

Any finding repeats the fixed-candidate cycle from Step 1.

- [ ] **Step 5: Create the acceptance record and close W1-D05 without releasing implementation**

After both independent reviews are zero-finding, update:

```text
W1-D05 Status = DONE
ActiveTaskCard = NONE
TaskCardSetStatus = COMPLETE
Wave1DesignStatus = FIXED_REVIEW_PASS_AWAITING_USER_APPROVAL
W1-DG5 FixedDesignReview = PASS
Wave1ImplementationTaskCardSet = NOT_CREATED
BusinessImplementation = NOT_AUTHORIZED
DirectFullImplementationStart = NO
```

Create `docs/engineering/cognitura-wave-1-design-acceptance.md` with:

```text
DecisionDate = 2026-07-30
ReviewedCandidate = the literal 40-character SHA reviewed in Steps 3 and 4
Wave1DesignVerification = PASS
Wave0Regression = PASS
W1-DG0 DesignGovernance = PASS
W1-DG1 SourceDocumentContract = PASS
W1-DG2 DocumentBlockFidelityAndSafety = PASS
W1-DG3 ReparseAndReferenceCompatibility = PASS
W1-DG4 SourcePreviewAndAcceptance = PASS
W1-DG5 FixedDesignReview = PASS
BusinessImplementation = NOT_AUTHORIZED
Wave1ImplementationTaskCardSet = NOT_CREATED
```

Copy the actual SHA and both complete review outputs; do not write explanatory placeholder text
such as “the literal 40-character SHA” into the artifact. Update
`AGENTS.md`, `README.md`, design index, Wave 1 design plan, task-card index and D05 card.

- [ ] **Step 6: Run final closure verification**

Run:

```bash
scripts/verify-wave1-design
scripts/verify-wave0
git diff --check
git status --short
```

Expected:

```text
Wave1DesignTaskCardValidation = PASS
TaskCardSetStatus = COMPLETE
ActiveTaskCard = NONE
Wave1DesignContracts = PASS
VerifyWave0 = PASS
```

Only `.idea/` may remain untracked.

- [ ] **Step 7: Commit the design closure**

Run:

```bash
git add \
  AGENTS.md \
  README.md \
  docs/design/wave-1/README.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-wave-1-design-acceptance.md \
  docs/engineering/cognitura-wave-1-design-plan.md \
  docs/task-cards/wave-1
git diff --cached --check
git commit -m "docs: close Wave 1 detailed design gate"
git status --short --branch
```

Do not push.

- [ ] **Step 8: Stop at the user review gate**

Report:

- all local commit SHAs;
- W1-DG0 through W1-DG5 results;
- both independent `gpt-5.6-sol/high` review results;
- current worktree and remote divergence;
- exact design files for user review.

Do not create an implementation plan, `W1-Ixx` cards, Java/TypeScript code, database migration,
remote push or deployment. Wait for the user to approve the complete Wave 1 written design.

---

## Plan Self-Review Checklist

Before presenting this plan:

```bash
plan='docs/superpowers/plans/2026-07-30-wave1-detailed-design-artifacts.md'

if rg -n '[T]BD|[T]ODO|[待]定|implement [后]续|[f]ill in' "${plan}"; then
  exit 1
fi

for id in W1-D00 W1-D01 W1-D02 W1-D03 W1-D04 W1-D05; do
  rg -q "${id}" "${plan}" || exit 1
done

for gate in W1-DG0 W1-DG1 W1-DG2 W1-DG3 W1-DG4 W1-DG5; do
  rg -q "${gate}" "${plan}" || exit 1
done

if rg -n '[g]it push|W1-I[0-9].*Status = READY|[u]ltra_gatekeeper' "${plan}"; then
  exit 1
fi

bash tests/ci/verify-markdown-links.sh
bash tests/task-cards/verify-task-cards.sh
git diff --check
```

Coverage mapping:

```text
W1-D00 spec §5.1,§6,§7,§8 → Task 1
W1-D00 spec §5.2             → Task 2
W1-D00 spec §5.3             → Task 3
W1-D00 spec §5.4             → Task 4
W1-D00 spec §5.5             → Task 5
W1-D00 spec §5.6             → Task 6
W1-D00 spec §9               → Global Constraints + Tasks 2–5
W1-D00 spec §10              → every card Gate + Task 6 review
W1-D00 spec §12              → Task 6 Step 8
```
