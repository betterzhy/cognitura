# Cognitura SourceDocument 身份与生命周期契约 1.0

```text
CanonicalProjectName = Cognitura
DesignSliceID = W1-D01
SourceDocumentContractVersion = 1.0
ContractStatus = W1_DG1_PASS
AuthoritativeOverallDesign = Cognitura-Overall-Design-1.2
SchemaCompatibilityBaseline = Cognitura-Schema-Baseline-2.0
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
ObjectStorageProvider = NOT_SELECTED
LLMUsage = NONE
```

## 1. 目的与权威边界

本契约固定 Wave 1 中 `SourceDocument` 的身份、不可变来源事实、处理 revision、
幂等、状态、失败和抽象端口。它是总体设计 §13、§17、§23、§24 的工程细化，
不改写总体设计，也不冒充缺失的历史构造专项正文。

本契约只定义领域语义，不选择 DOCX 解析库、对象存储、数据库表、Web API 或页面。
`DocumentBlock` 字段和解析保真由 W1-D02 固定；跨 revision 引用由 W1-D03
固定；HTTP 与来源预览由 W1-D04 固定。

## 2. 核心身份裁决

```text
SourceDocumentIdentity = LOGICAL_UPLOAD
SourceBinaryIdentity = SHA256_RAW_BYTES
ProcessingRevisionIdentity = SOURCE_DOCUMENT_HASH_PARSER_PROFILE
DuplicateBytesAcrossDifferentRequests = DISTINCT_SOURCE_DOCUMENT_SHARED_BINARY
SameIdempotencyKeySameBytes = RETURN_EXISTING_SOURCE_DOCUMENT
SameIdempotencyKeyDifferentBytes = IDEMPOTENCY_CONFLICT
SourceOriginalMutation = FORBIDDEN
```

三类身份不得混用：

1. `SourceDocumentId` 标识某 Workspace 中一次有意的逻辑上传。它不由文件名或
   SHA-256 单独决定。
2. `SourceBinaryId` 标识只读原始字节，唯一内容身份是原始字节的 SHA-256。
   多个逻辑上传可以共享同一个二进制对象，但仍是不同 `SourceDocument`。
3. `SourceProcessingRevisionId` 标识一个不可变处理结果，其唯一键为
   `(sourceDocumentId, contentSha256, parserProfileVersion)`。

原始文件名只是显示元数据。不同内容使用相同文件名不会合并；相同内容使用不同
文件名也不会在没有相同幂等键时合并逻辑上传。

## 3. 对象职责

### 3.1 SourceDocument

`SourceDocument` 保存不可变上传事实：

```text
sourceDocumentId
workspaceId
sourceBinaryId
originalFileName
mediaType
byteLength
contentSha256
receivedAt
idempotencyKey
sourceDocumentValidationStatus
validationFailureCode
validationFailureDetail
```

约束：

- `sourceDocumentId` 在 Repository 内全局唯一。
- `workspaceId + idempotencyKey` 唯一。
- `contentSha256` 是 64 位小写十六进制 SHA-256。
- `byteLength` 是原始文件的字节数，必须大于 0。
- `mediaType` 在 Wave 1 只接受正式 DOCX media type；扩展名不构成格式证据。
- 原始事实创建后不可覆盖、换文件、改哈希或改 Workspace。

### 3.2 SourceBinary

`SourceBinary` 保存只读字节描述：

```text
sourceBinaryId
contentSha256
byteLength
mediaType
binaryLocation
createdAt
```

`binaryLocation` 只通过 `SourceBinaryStore` 内部解析，不得暴露给 Web DTO、
Renderer 或模型。`SourceBinary` 可以按哈希物理去重，但物理去重不得改变逻辑
上传数量。

### 3.3 SourceProcessingRevision

`SourceProcessingRevision` 保存一个解析配置下的不可变处理身份：

```text
sourceProcessingRevisionId
sourceDocumentId
contentSha256
parserProfileVersion
sourceProcessingRevisionStatus
activeAttemptId
currentAttemptGeneration
failureCode
failureDetail
startedAt
completedAt
createdAt
```

`parserProfileVersion` 是受版本控制的解析配置身份，至少覆盖解析器实现版本、
规范化规则版本、安全限制版本和 DocumentBlock 契约版本。W1-D01 不选择具体
解析器实现。

旧 revision 不得被新 revision 覆盖。活动 revision 只是读取投影中的显式选择，
不是对历史引用的静默重定向。

### 3.4 SourceProcessingAttempt

同一 processing revision 可以有多个顺序 attempt：

```text
sourceProcessingAttemptId
sourceProcessingRevisionId
attemptNumber
sourceProcessingAttemptStatus
attemptGeneration
fencingToken
leaseExpiresAt
heartbeatAt
failureCode
failureDetail
startedAt
completedAt
```

`activeAttemptId` 与 `currentAttemptGeneration` 是 revision 的协调字段。
`attemptNumber` 从 1 开始连续递增；attempt 上的 `attemptGeneration` 是取得活动权
时从 revision 原子递增并复制的围栏代次，`fencingToken` 由 revision 身份和该
代次确定。attempt 是运行记录，不改变 revision 身份。

## 4. 幂等与重复上传

幂等作用域是 `workspaceId + idempotencyKey`：

| 输入关系 | 裁决 |
|---|---|
| 相同 key、相同 SHA-256 | 返回已有 `SourceDocumentId`，不创建新逻辑上传 |
| 相同 key、不同 SHA-256 | 返回 `IDEMPOTENCY_CONFLICT`，不覆盖任何事实 |
| 不同 key、相同 SHA-256 | 创建不同 `SourceDocumentId`，允许共享 `SourceBinary` |
| 不同 key、不同 SHA-256 | 创建不同 `SourceDocumentId` 与二进制身份 |
| 相同文件名、不同 SHA-256 | 视为不同内容，文件名不参与身份合并 |

幂等重放必须返回首次成功创建的不可变上传事实。重放请求携带的文件名差异不能
修改已有记录；调用方需要新的显示名时必须创建新的逻辑上传意图。

## 5. 生命周期状态

### 5.1 状态所有权

```text
SourceDocumentValidationStatus = RECEIVED,VALIDATING,ACCEPTED,REJECTED
SourceProcessingRevisionStatus = PARSING,PARSED,PREVIEW_READY,FAILED_RETRYABLE,FAILED_TERMINAL
SourceIngestionDisplayStatus = READ_ONLY_PROJECTION
SourceIngestionDisplayStatusWritable = NO
AcceptedDocumentStartsRevision = CREATE_OR_REUSE_REVISION_IN_PARSING
```

- `sourceDocumentValidationStatus` 只属于 `SourceDocument`，描述上传接入校验。
- `sourceProcessingRevisionStatus` 只属于 `SourceProcessingRevision`，描述一个
  已创建 revision 的解析与预览准备。
- `sourceIngestionDisplayStatus` 由前两者组合计算，仅供查询和 UI 显示；它没有
  持久化字段、写命令或状态迁移 API，不得反向修改两个权威状态。
- `ACCEPTED` 不是 revision 状态。它只是编排创建或复用 revision 的前置条件；
  新 revision 直接以 `PARSING` 为初始状态，因此不存在跨对象
  `ACCEPTED -> PARSING` 状态迁移。

### 5.2 合法迁移

```text
DOCUMENT: RECEIVED -> VALIDATING
DOCUMENT: VALIDATING -> ACCEPTED
DOCUMENT: VALIDATING -> REJECTED
REVISION: PARSING -> PARSED
REVISION: PARSING -> FAILED_RETRYABLE
REVISION: PARSING -> FAILED_TERMINAL
REVISION: FAILED_RETRYABLE -> PARSING
REVISION: PARSED -> PREVIEW_READY
```

迁移语义：

- `RECEIVED`：逻辑身份和原始字节已登记，但格式/安全校验尚未结束。
- `VALIDATING`：执行哈希、长度、media type 和 DOCX 容器安全校验。
- `ACCEPTED`：来源通过接入校验，可以创建或复用 processing revision。
- `PARSING`：该 revision 可以获取一个活动 attempt；并发不变量见第 6 节。
- `PARSED`：DocumentBlock 候选集已经确定性解析并通过内部完整性校验。
- `PREVIEW_READY`：来源预览投影可读取；它不表示 Skeleton 或认知内容已生成。
- `REJECTED`：上传事实保留，但该来源不得进入解析。
- `FAILED_RETRYABLE`：同一 revision 可以创建下一个 attempt。
- `FAILED_TERMINAL`：相同 parser profile 下不得自动重试；只有变更
  `parserProfileVersion` 才能创建新 revision。

未列出的迁移全部非法。`REJECTED`、`FAILED_TERMINAL` 和 `PREVIEW_READY`
在各自对象内是终态。display projection 不参与迁移。

## 6. 并发、重试与成功唯一性

```text
SuccessfulRevisionCardinality = AT_MOST_ONE_PER_SOURCE_HASH_PARSER_PROFILE
RetryableFailureCreatesNewRevision = NO
SourceProcessingAttemptStatus = PENDING,RUNNING,SUCCEEDED,FAILED_RETRYABLE,FAILED_TERMINAL
ActiveAttemptStatuses = PENDING,RUNNING
MaximumActiveAttemptsPerRevision = 1
SuccessfulAttemptCardinality = AT_MOST_ONE_PER_REVISION
RevisionAttemptCoordinatorFields = ACTIVE_ATTEMPT_ID,CURRENT_ATTEMPT_GENERATION
AttemptFencingFields = ATTEMPT_GENERATION,FENCING_TOKEN
AttemptFencing = ATTEMPT_GENERATION_AND_ACTIVE_ATTEMPT_ID
BeginAttemptTransaction = ATOMIC_REVISION_ATTEMPT_GENERATION_ACTIVE_IDENTITY
AttemptCreationBeforeRevisionTransition = FORBIDDEN
RetryFailureHistory = PRESERVED_ON_PRIOR_ATTEMPT
RetryRevisionCurrentFailure = CLEARED
RetryRevisionCompletedAt = UNSET
RevisionCompletionCAS = ACTIVE_ATTEMPT_ID_AND_ATTEMPT_GENERATION_MATCH
AttemptCompletionTransaction = ATOMIC_ATTEMPT_REVISION_ACTIVE_IDENTITY_AND_COMPLETED_AT
LeaseExpiredAttemptStatus = FAILED_RETRYABLE
LateCompletionAudit = APPEND_ONLY_RESULT_REJECTED_STALE_EVENT
LateCompletionAttemptMutation = FORBIDDEN
```

attempt 的合法迁移为：

```text
ATTEMPT: PENDING -> RUNNING
ATTEMPT: RUNNING -> SUCCEEDED
ATTEMPT: RUNNING -> FAILED_RETRYABLE
ATTEMPT: RUNNING -> FAILED_TERMINAL
```

首次开始和失败重试必须使用以下原子事务，不得先创建 attempt 再更新 revision：

```text
BEGIN_ATTEMPT: INITIAL -> CREATE_PARSING_REVISION,CREATE_PENDING_ATTEMPT,SET_GENERATION_1,SET_ACTIVE_ATTEMPT
BEGIN_ATTEMPT: RETRY_FROM_FAILED_RETRYABLE -> PARSING,CREATE_PENDING_ATTEMPT,INCREMENT_GENERATION,SET_ACTIVE_ATTEMPT,CLEAR_CURRENT_FAILURE,UNSET_COMPLETED_AT
```

attempt 完成和 revision 迁移必须由同一原子事务提交：

```text
FINALIZE: SUCCEEDED -> PARSED,CLEAR_ACTIVE_ATTEMPT,SET_COMPLETED_AT
FINALIZE: FAILED_RETRYABLE -> FAILED_RETRYABLE,CLEAR_ACTIVE_ATTEMPT,SET_COMPLETED_AT
FINALIZE: FAILED_TERMINAL -> FAILED_TERMINAL,CLEAR_ACTIVE_ATTEMPT,SET_COMPLETED_AT
```

- 相同 `(sourceDocumentId, contentSha256, parserProfileVersion)` 已存在成功
  revision 时，后续请求复用它，不创建第二个 revision。
- 同一组合只有一个 processing revision；retry 只创建新 attempt。
- 首次处理必须在一个事务中创建初始状态为 `PARSING` 的 revision、generation 1
  的 `PENDING` attempt，并设置 `activeAttemptId/currentAttemptGeneration`；
  不允许先暴露其中任一对象。
- retry 只能从 `FAILED_RETRYABLE` 且 `activeAttemptId` 为空的 revision 开始。
  Store 必须用 CAS 在同一事务中把 revision 迁移回 `PARSING`、递增
  `currentAttemptGeneration`、创建对应 generation 的 `PENDING` attempt、
  设置 `activeAttemptId`，并清空 revision 当前 `failureCode/failureDetail`、
  将 `completedAt` 置为未设置。上一次失败事实保留在旧 attempt，不得删除或
  改写。禁止先创建 attempt 再另行更新 revision。
- attempt 复制 revision 的 generation 并取得相同代次的 `fencingToken`。
  `PENDING` 与 `RUNNING` 均属于活动状态，同一 revision 最多一个活动 attempt。
- attempt 心跳只可在 `activeAttemptId + attemptGeneration` 同时匹配且 lease
  未过期时延长 `leaseExpiresAt`。监督器发现 lease 过期后，必须以相同 CAS
  在同一事务中将旧 attempt 和 revision 都标记为 `FAILED_RETRYABLE`、清除
  revision 的活动身份并设置完成时间，之后才能创建下一 attempt；不能先并行
  启动替代 attempt。
- attempt 完成必须以 `activeAttemptId + attemptGeneration` 双条件 CAS。
  成功 CAS 必须在同一事务中更新 attempt 终态、revision 对应状态、清除
  `activeAttemptId` 并写入完成时间：成功映射 `PARSED`，可重试失败映射
  `FAILED_RETRYABLE`，终止失败映射 `FAILED_TERMINAL`。因此不得出现
  `attempt=SUCCEEDED` 而 `revision=PARSING` 的分裂事实。
- 第一条完成全部块校验并成功 CAS 的 attempt 成为该 revision 唯一
  `SUCCEEDED` 结果。
- token 不匹配、lease 已由监督器终结或旧 attempt 迟到时，完成请求不得发布
  DocumentBlock、不得推进 revision，也不得覆盖当前或旧 attempt 的终态。
  Store 追加独立的 `RESULT_REJECTED_STALE` completion-rejection 审计事件，
  记录 attempt ID、提交 generation、当前 generation、拒绝时间和原因；该事件
  不属于 attempt 状态机。
- `SUCCEEDED`、`FAILED_RETRYABLE` 和 `FAILED_TERMINAL` 都是 attempt 终态。
  只有 revision 进入 `FAILED_RETRYABLE` 后才能在同一 revision 创建新 attempt。
- 失败 attempt 保持可审计；retry 不删除、改写或复用旧 attempt ID。
- `FAILED_RETRYABLE` 只有明确可重试的基础设施或瞬态读取失败才合法；确定性格式
  或安全拒绝不得伪装为可重试。

## 7. 抽象端口

本设计只固定以下端口名称和职责：

```text
SourceBinaryStore
SourceDocumentStore
SourceProcessingRevisionStore
SourceIngestionClock
SourceIdGenerator
```

- `SourceBinaryStore`：按只读二进制身份保存和读取原始字节；不得跟随文档外链。
- `SourceDocumentStore`：保存和按 Workspace/幂等键读取逻辑上传事实。
- `SourceProcessingRevisionStore`：原子创建 revision/attempt、执行状态迁移并保证
  成功唯一性。
- `SourceIngestionClock`：提供可测试的 UTC 时间。
- `SourceIdGenerator`：生成不依赖文件内容、文件名或模型输出的唯一 ID。

端口实现、表结构、事务 SQL、对象存储 Provider 和生产凭据均不属于本卡。

## 8. 错误分类

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

| 错误码 | 状态 | retryable |
|---|---|---|
| `UNSUPPORTED_MEDIA_TYPE` | `REJECTED` | `false` |
| `EMPTY_SOURCE_FILE` | `REJECTED` | `false` |
| `SOURCE_SIZE_LIMIT` | `REJECTED` | `false` |
| `SOURCE_HASH_MISMATCH` | `REJECTED` | `false` |
| `IDEMPOTENCY_CONFLICT` | 不产生新状态 | `false` |
| `DOCX_SECURITY_REJECTED` | `REJECTED` | `false` |
| `DOCX_FORMAT_INVALID` | `REJECTED` 或 `FAILED_TERMINAL` | `false` |
| `PARSER_RETRYABLE_FAILURE` | `FAILED_RETRYABLE` | `true` |
| `PARSER_TERMINAL_FAILURE` | `FAILED_TERMINAL` | `false` |

机器可验证映射为：

```text
ERROR: UNSUPPORTED_MEDIA_TYPE -> REJECTED,false,VALIDATION
ERROR: EMPTY_SOURCE_FILE -> REJECTED,false,VALIDATION
ERROR: SOURCE_SIZE_LIMIT -> REJECTED,false,VALIDATION
ERROR: SOURCE_HASH_MISMATCH -> REJECTED,false,VALIDATION
ERROR: IDEMPOTENCY_CONFLICT -> NO_NEW_STATE,false,COMMAND
ERROR: DOCX_SECURITY_REJECTED -> REJECTED,false,VALIDATION
ERROR: DOCX_FORMAT_INVALID -> REJECTED,false,VALIDATION
ERROR: DOCX_FORMAT_INVALID -> FAILED_TERMINAL,false,PARSING
ERROR: PARSER_RETRYABLE_FAILURE -> FAILED_RETRYABLE,true,PARSING
ERROR: PARSER_TERMINAL_FAILURE -> FAILED_TERMINAL,false,PARSING
```

`DOCX_FORMAT_INVALID` 在接入校验阶段发现时使 `SourceDocument` 进入 `REJECTED`，
不会创建 revision；若容器已通过校验、revision 已创建，而解析阶段发现确定性
格式错误，则使该 revision 进入 `FAILED_TERMINAL`。阶段必须随错误记录保存，
不得由调用方任意选择结果状态。

`failureDetail` 必须是可审计的确定性描述，不得包含原始全文、凭据、本地绝对路径
或外部链接目标内容。

## 9. 安全与原件保护

- 原始字节一经哈希登记即只读；重新解析不能覆盖原件。
- 不读取 DOCX 外部 relationship 目标，不访问 Redis 遗留本地链接。
- 不执行宏、嵌入对象或活动内容。
- 派生物必须绑定 `sourceDocumentId + contentSha256 + parserProfileVersion`。
- W1-D02 才固定 ZIP、XML、图片和表格的精确安全限制。
- 本设计不读取、解包或转换 `raw/` 下三份 Golden Case 原件。

## 10. 代码与模型职责

后续实现获准时，确定性代码负责 ID、SHA-256、幂等、状态迁移、并发唯一性、
失败分类和端口调用。

Wave 1 不调用 LLM。模型不得判断格式是否合法、生成状态、改写原始事实、合并
用户的两次上传意图或修复损坏 DOCX。

## 11. 下游接口边界

W1-D02 可以消费：

```text
sourceDocumentId
sourceProcessingRevisionId
contentSha256
parserProfileVersion
```

W1-D02 不得改变上述身份语义。W1-D03 负责固定不可变 block reference；W1-D04
负责把本契约投影为应用命令和查询。任何下游设计都不得以“当前 revision”静默
替换历史 revision。

## 12. 不变量与验收

以下任一情况必须使契约验证或后续实现 Gate 失败：

1. 用 SHA-256 直接充当一次逻辑上传 ID。
2. 不同幂等键的相同字节被静默合并为同一 `SourceDocument`。
3. 相同幂等键的新字节覆盖旧来源。
4. retry 创建第二个 processing revision 或两个成功结果。
5. 同一 revision 出现两个活动 attempt，或迟到 attempt 发布结果。
6. display projection 被持久化为可写状态或反向驱动权威状态。
7. 新 parser profile 改写旧 revision。
8. 原始字节、哈希、Workspace 或历史失败被覆盖。
9. 正式数据库、对象存储 Provider、LLM 或业务页面被本设计擅自授权。

验收命令：

```bash
bash tests/contracts/wave1-design/verify-source-document-contract.sh
bash tests/task-cards/verify-wave1-design-cards.sh
bash tests/ci/verify-markdown-links.sh
git diff --check
```
