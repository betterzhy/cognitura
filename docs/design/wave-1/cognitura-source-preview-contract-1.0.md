# Cognitura 来源预览、接口与验收契约 1.0

```text
CanonicalProjectName = Cognitura
DesignSliceID = W1-D04
SourcePreviewContractVersion = 1.0
ContractStatus = W1_DG4_PASS
AuthoritativeOverallDesign = Cognitura-Overall-Design-1.2
SourceDocumentContract = W1_DG1_PASS
DocumentBlockContract = W1_DG2_PASS
ReparseReferenceContract = W1_DG3_PASS
DeliveryPlatform = DESKTOP_WEB
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
ParserProvider = NOT_SELECTED
RawFormalInputAccess = NOT_PERFORMED
LLMUsage = NONE
```

## 1. 目的与边界

本契约固定 Wave 1 的上传、来源状态、processing revision、块预览应用接口，
以及 Desktop Web 投影和后续实现验收层级。它消费 W1-D01 至 W1-D03 的正式
来源事实，不创建第二套来源模型，不生成认知内容。

本文是 API/体验设计，不创建 Controller、页面、Repository、Mapper、数据库表、
对象存储或认证实现。Workspace 身份来自以后获准的可信请求上下文，不能由查询
参数伪造。

## 2. 正式用例

```text
ENDPOINT: POST /api/v1/workspaces/{workspaceId}/source-documents
ENDPOINT: GET /api/v1/source-documents/{sourceDocumentId}
ENDPOINT: POST /api/v1/source-documents/{sourceDocumentId}/processing-revisions
ENDPOINT: GET /api/v1/source-documents/{sourceDocumentId}/processing-revisions/{sourceProcessingRevisionId}
ENDPOINT: GET /api/v1/source-documents/{sourceDocumentId}/processing-revisions/{sourceProcessingRevisionId}/blocks
ENDPOINT: POST /api/v1/source-documents/{sourceDocumentId}/processing-revisions/{sourceProcessingRevisionId}/partial-acceptance
```

所有 GET/POST 必须把路径对象解析到可信 `workspaceContext`。上传路径的
`workspaceId` 必须等于该上下文；其余路径对象必须属于该 Workspace。不存在与
不可见使用同一 `404`，不得泄露跨 Workspace ID 是否存在。

```text
WorkspaceScopeEnforcement = REQUIRED
CrossWorkspaceDisclosure = NOT_FOUND
NotFoundIdentityFields = ALWAYS_NULL
NotFoundExistenceOracle = FORBIDDEN
```

所有来源/ revision/blocks 的 `404` error body 中
`sourceDocumentId/sourceProcessingRevisionId` 统一为 `null`，无论路径 ID
真实不存在还是存在但属于其他 Workspace。响应时间、错误码和 message 也使用同一
模板；不得查到对象后再决定 error shape。客户端已持有请求路径，不需要 error body
回显它。

## 3. 上传命令与结果

`CreateSourceDocumentCommand`：

```text
UPLOAD_COMMAND_FIELD: workspaceId
UPLOAD_COMMAND_FIELD: idempotencyKey
UPLOAD_COMMAND_FIELD: originalFileName
UPLOAD_COMMAND_FIELD: declaredMediaType
UPLOAD_COMMAND_FIELD: declaredByteLength
UPLOAD_COMMAND_FIELD: contentSha256
UPLOAD_COMMAND_FIELD: binaryStream
```

- `idempotencyKey` 必填并服从 W1-D01 的 Workspace 作用域。
- `declared*` 只用于前置检查；服务器必须流式计算真实 byte length 和 SHA-256，
  不信任声明值。
- `binaryStream` 是一次性输入端口，不进入日志、DTO 回显或持久化字段。

`CreateSourceDocumentResult`：

```text
UPLOAD_RESULT_FIELD: sourceDocumentId
UPLOAD_RESULT_FIELD: sourceIngestionDisplayStatus
UPLOAD_RESULT_FIELD: contentSha256
UPLOAD_RESULT_FIELD: receivedAt
```

这里使用 W1-D01 的只读 `sourceIngestionDisplayStatus`，不重新引入模糊可写
`processingStatus`。结果只返回已登记的不可变来源事实。

`GET /api/v1/source-documents/{sourceDocumentId}` 的成功 DTO 精确包含：

```text
SOURCE_QUERY_FIELD: sourceDocumentId
SOURCE_QUERY_FIELD: originalFileName
SOURCE_QUERY_FIELD: mediaType
SOURCE_QUERY_FIELD: byteLength
SOURCE_QUERY_FIELD: contentSha256
SOURCE_QUERY_FIELD: receivedAt
SOURCE_QUERY_FIELD: sourceDocumentValidationStatus
SOURCE_QUERY_FIELD: sourceIngestionDisplayStatus
SOURCE_QUERY_FIELD: validationFailureCode
SOURCE_QUERY_FIELD: validationFailureDetail
```

两个 failure 字段仅在 `REJECTED` 时非 null；其他状态必须同时为 null。该 DTO
不返回 `sourceBinaryId`、`binaryLocation`、幂等键、active/latest revision 或
任何存储事实。

## 4. Processing revision 命令与查询

`CreateProcessingRevisionCommand`：

```text
PROCESSING_COMMAND_FIELD: sourceDocumentId
PROCESSING_COMMAND_FIELD: parserProfileVersion
```

命令同时验证路径 ID、body ID 和 Workspace：

- D01 同 hash/同 profile 成功 revision：`200` 返回既有 revision；
- retryable revision：原子创建同 revision 新 attempt，`202`；
- terminal revision：`200` 返回既有 terminal 状态，并提示必须选择新 profile；
- 新 profile：原子创建新 revision/attempt，`202`。

成功响应精确包含：

```text
PROCESSING_RESULT_FIELD: sourceDocumentId
PROCESSING_RESULT_FIELD: sourceProcessingRevisionId
PROCESSING_RESULT_FIELD: sourceProcessingRevisionStatus
PROCESSING_RESULT_FIELD: sourceIngestionDisplayStatus
PROCESSING_RESULT_FIELD: pollLocation
PROCESSING_RESULT_FIELD: reused
```

`pollLocation` 必须是该 exact revision 的 GET endpoint，不是 active/latest URL；
200/202 都返回相同 shape。`reused=true` 只用于既有成功或 terminal revision。

```text
PROCESSING_HTTP: NEW_REVISION_OR_RETRY_ATTEMPT -> 202_ACCEPTED_WITH_EXACT_REVISION_AND_POLL_LOCATION
PROCESSING_HTTP: EXISTING_SUCCESS_OR_TERMINAL -> 200_OK_WITH_EXACT_REVISION_AND_POLL_LOCATION
PROCESSING_HTTP: COMMAND_NOT_ACCEPTED_INFRA_FAILURE -> 503_SERVICE_UNAVAILABLE
PROCESSING_HTTP: ACCEPTED_RETRYABLE_FAILURE -> STATUS_GET_200_WITH_RETRYABLE_FAILURE
ProcessingPost503Means = COMMAND_NOT_ACCEPTED
AcceptedRetryableFailureTransport = STATUS_GET_200_NOT_POST_503
```

revision 查询直接返回：

```text
REVISION_QUERY_FIELD: sourceDocumentId
REVISION_QUERY_FIELD: sourceProcessingRevisionId
REVISION_QUERY_FIELD: parserProfileVersion
REVISION_QUERY_FIELD: sourceProcessingRevisionStatus
REVISION_QUERY_FIELD: sourceIngestionDisplayStatus
REVISION_QUERY_FIELD: parseCompleteness
REVISION_QUERY_FIELD: omissions
REVISION_QUERY_FIELD: publishedBlockSetDigest
REVISION_QUERY_FIELD: omissionsDigest
REVISION_QUERY_FIELD: partialAcceptanceStatus
REVISION_QUERY_FIELD: failureCode
REVISION_QUERY_FIELD: failureDetail
REVISION_QUERY_FIELD: startedAt
REVISION_QUERY_FIELD: completedAt
```

`omissions` 只在 partial 时非空；错误细节必须服从 D01 的敏感信息约束。
在 `PARSING` 或失败状态，`parseCompleteness`、两个 digest 和
`partialAcceptanceStatus` 均为 null，`omissions=[]`；`PARSED/PREVIEW_READY`
才按 D01 原子发布结果返回非 null 值。查询不能返回 attempt fencing token、lease、
存储路径或内部异常。

### 4.1 Partial 来源确认命令

```text
PartialAcceptanceCommand = ACCEPT_EXACT_PARTIAL_REVISION
PartialAcceptanceActorSource = TRUSTED_WORKSPACE_CONTEXT
PartialAcceptanceIdempotency = WORKSPACE_REVISION_AND_IDEMPOTENCY_KEY
PartialAcceptanceRevocation = FORBIDDEN
PARTIAL_ACCEPTANCE_COMMAND_FIELD: sourceDocumentId
PARTIAL_ACCEPTANCE_COMMAND_FIELD: sourceProcessingRevisionId
PARTIAL_ACCEPTANCE_COMMAND_FIELD: blockSetDigest
PARTIAL_ACCEPTANCE_COMMAND_FIELD: omissionsDigest
PARTIAL_ACCEPTANCE_COMMAND_FIELD: idempotencyKey
PARTIAL_ACCEPTANCE_COMMAND_FIELD: decision
PARTIAL_ACCEPTANCE_RESULT_FIELD: sourceDocumentId
PARTIAL_ACCEPTANCE_RESULT_FIELD: sourceProcessingRevisionId
PARTIAL_ACCEPTANCE_RESULT_FIELD: partialAcceptanceStatus
PARTIAL_ACCEPTANCE_RESULT_FIELD: partialAcceptedAt
PARTIAL_ACCEPTANCE_RESULT_FIELD: acceptedBy
PARTIAL_ACCEPTANCE_RESULT_FIELD: consumptionEligible
PARTIAL_ACCEPTANCE_RESULT_FIELD: idempotentReplay
PARTIAL_ACCEPTANCE_HTTP: NEW_ACCEPTANCE -> 200_OK
PARTIAL_ACCEPTANCE_HTTP: IDEMPOTENT_REPLAY -> 200_OK
PARTIAL_ACCEPTANCE_HTTP: COMPLETE_REVISION -> 409_CONFLICT
PARTIAL_ACCEPTANCE_HTTP: WRONG_DIGEST_OR_REVISION -> 409_CONFLICT
PARTIAL_ACCEPTANCE_HTTP: NOT_PREVIEW_READY -> 409_CONFLICT
```

`decision` 唯一合法值是 `ACCEPT_PARTIAL`；不接受即保持 `PENDING`，不是写入
“拒绝”或删除来源。服务端从可信 Workspace context 取得 actor，禁止 body 伪造。
命令只接受 `PREVIEW_READY + PARTIAL + PENDING` 的 exact revision，并 CAS 校验
当前 `publishedBlockSetDigest` 和 omissions digest。相同 Workspace/revision/key
与相同 digest 幂等返回；相同 key 不同 digest、过期预览、complete revision 或
非当前 block set 均冲突。成功只写 D01 的不可变确认事实，不改写 block/omission；
结果 `consumptionEligible=true`。确认不可撤回，需要不同解析结果时必须创建新的
parser profile revision。

## 5. 块预览和分页

```text
PreviewPagination = KEYSET_BY_SOURCE_ORDER
PreviewCursor = PROCESSING_REVISION_ID+LAST_SOURCE_ORDER
PreviewCursorRevisionMismatch = REJECT_BAD_REQUEST
PreviewOffsetPagination = FORBIDDEN
PreviewDefaultLimit = 100
PreviewMaximumLimit = 500
PreviewFactSource = SOURCE_DOCUMENT_DOCUMENT_BLOCK_AND_IMMUTABLE_REFERENCE_ALIAS
PreviewAliasFactSource = D03_SOURCE_SCOPED_REGISTRY
PreviewAliasCreation = BEFORE_PREVIEW_READY
PreviewAliasCollision = HARD_FAILURE_BEFORE_FACT_PUBLICATION
PreviewRevisionSelector = EXPLICIT_FIXED_REVISION
RendererFactCreation = FORBIDDEN
```

请求参数只有 `after` 与 `limit`：

- 首屏 `after=null`，从 `sourceOrder=0` 开始；
- 后续页严格查询 `sourceOrder > cursor.lastSourceOrder`，按 sourceOrder 升序；
- cursor 是带版本、固定 revision ID 和 last sourceOrder 的不透明认证 token；
  服务端验证 token 完整性、Workspace、路径 revision 和 order 范围；
- cursor revision 与路径不一致、篡改、limit 非整数或超范围均为 `400`；
- 禁止 offset、默认 active/latest revision、跨 revision cursor 和不稳定排序。

每页返回：

```text
PREVIEW_RESULT_FIELD: sourceDocumentId
PREVIEW_RESULT_FIELD: sourceProcessingRevisionId
PREVIEW_RESULT_FIELD: originalFileName
PREVIEW_RESULT_FIELD: parseCompleteness
PREVIEW_RESULT_FIELD: publishedBlockSetDigest
PREVIEW_RESULT_FIELD: omissionsDigest
PREVIEW_RESULT_FIELD: incomplete
PREVIEW_RESULT_FIELD: omissions
PREVIEW_RESULT_FIELD: items[]
PREVIEW_RESULT_FIELD: nextCursor
```

两个 digest 在同一 exact revision 的所有分页响应中恒定，供 partial acceptance
命令回传并执行 CAS；客户端不得从单页 `items[]` 或显示文本自行计算完整集合 digest。

`items[]` 是 D01 SourceDocument、D02 envelope/payload 和 D03 immutable alias
的类型化 Web allowlist 投影，包括
`documentBlockId`、三段式 `DocumentBlockRef` alias、`blockType`、
`sourceOrder`、`sectionPath`、nullable `pageNumber/pageEvidence`、
`sourceAnchor`、`contentHash` 和允许的 payload 字段。它不复制 D02 的全部内部
对象。

D03 alias 不是 preview DTO 临时生成物。source alias 必须已随 SourceDocument
创建，block alias 必须已随 D01 block set 原子发布；碰撞会使相应事实发布失败，
因此 revision 不得进入 `PARSED/PREVIEW_READY`。预览只从 source-scoped registry
读取 exact tuple 的现有 alias，禁止依赖 cognition revision、懒创建、重绑或
以当前 revision selector 修复缺失 alias。

```text
PartialPreviewMarker = REQUIRED
PartialPreviewInvariant = INCOMPLETE_TRUE+NONEMPTY_OMISSIONS+TOP_WARNING+AFFECTED_MARKERS
CompletePreviewInvariant = INCOMPLETE_FALSE+EMPTY_OMISSIONS+NO_PARTIAL_WARNING
PreviewGeneratedSummary = FORBIDDEN
PreviewTypedPayloadProjection = TYPE_SPECIFIC_WEB_ALLOWLIST
PreviewImageMediaRef = FORBIDDEN
ExternalRelationshipAccessCount = 0
ExternalRelationshipOperations = NO_STAT_NO_DNS_NO_FILE_READ_NO_NETWORK
```

partial 预览必须同时满足 `incomplete=true`、非空 omissions、固定顶部警示和每个
受影响位置 marker。complete 预览为 `incomplete=false`、omissions 空。预览读取
不得 stat、DNS、打开文件或请求任何 external relationship。

`PreviewImageDTO` 只允许：

```text
PREVIEW_IMAGE_FIELD: relationshipMode
PREVIEW_IMAGE_FIELD: externalTargetLiteralSha256
PREVIEW_IMAGE_FIELD: mediaType
PREVIEW_IMAGE_FIELD: byteLength
PREVIEW_IMAGE_FIELD: contentSha256
PREVIEW_IMAGE_FIELD: securityDisclosure
```

内部 `mediaRef` 是派生媒体端口引用，不得进入 Web DTO；本设计也不定义媒体下载
endpoint。`relationshipId`、外部 target literal、bucket/key 和文件路径同样不
输出。未来如需安全媒体读取，必须另行设计授权 endpoint，不得把 `mediaRef`
当 URL。

## 6. Web DTO 禁止泄漏

```text
FORBIDDEN_WEB_FIELD: repository
FORBIDDEN_WEB_FIELD: mapper
FORBIDDEN_WEB_FIELD: storageKey
FORBIDDEN_WEB_FIELD: rawXml
FORBIDDEN_WEB_FIELD: internalException
FORBIDDEN_WEB_FIELD: binaryFilesystemPath
```

DTO 还不得包含数据库行版本、attempt fencing token、对象存储 bucket/key、凭据、
本地绝对路径、完整外部 target 或原始二进制。错误 `message` 是安全用户文案，
诊断 correlation ID 可另行设计但不能替代稳定 `errorCode`。

## 7. HTTP 语义

```text
HTTP: 201_CREATED -> NEW_SOURCE_DOCUMENT
HTTP: 200_OK -> IDEMPOTENT_REPLAY_OR_EXISTING_REVISION
HTTP: 202_ACCEPTED -> NEW_PROCESSING_REVISION_OR_RETRY_ATTEMPT_ACCEPTED
HTTP: 400_BAD_REQUEST -> MALFORMED_COMMAND_OR_UNSUPPORTED_PAGINATION
HTTP: 404_NOT_FOUND -> SOURCE_OR_REVISION_NOT_VISIBLE_IN_WORKSPACE
HTTP: 409_CONFLICT -> IDEMPOTENCY_CONCURRENT_COMPLETION_PARTIAL_ACCEPTANCE_OR_PREVIEW_STATE_CONFLICT
HTTP: 413_CONTENT_TOO_LARGE -> RAW_UPLOAD_LIMIT_BEFORE_DOCX_SECURITY_SCAN
HTTP: 415_UNSUPPORTED_MEDIA_TYPE -> NON_DOCX_INPUT
HTTP: 422_UNPROCESSABLE_CONTENT -> EMPTY_HASH_MISMATCH_TERMINAL_FORMAT_SECURITY_OR_EXPANDED_ZIP_LIMIT
HTTP: 503_SERVICE_UNAVAILABLE -> SOURCE_NOT_ACCEPTED_OR_PROCESSING_COMMAND_NOT_ACCEPTED
```

语义说明：

- 新 SourceDocument 完成不可变登记返回 `201`；同 key/同 hash 重放为 `200`。
- processing 命令只在 revision/attempt 已原子接受后返回 `202`；轮询 GET 获取
  后续状态。
- D01 CAS 发现请求参数或既有成功事实不能按本请求安全复用、partial 确认绑定
  不匹配或 preview 状态尚不满足读取条件时返回 `409`；正常并发命中同一成功
  revision 或同一 partial confirmation 应返回幂等 `200`，不得制造第二事实。
- `413` 只用于接入前 raw upload byte limit。D02 entry/expanded ZIP count、size、
  total bytes 或 ratio 命中 `SECURITY_REJECTED`，统一为 `422`，不得同时映射 413。
- processing POST 的 `503` 只表示 revision/attempt 命令尚未被原子接受；此时
  不返回 poll revision。已接受后发生 retryable parser failure，由 revision GET
  以 `200` 返回 `FAILED_RETRYABLE`，不把异步结果伪装成 POST 503。
- validation 已建立 SourceDocument 后发现格式/安全硬拒绝，状态 GET 显示
  `REJECTED`；同步完成校验的命令可以返回 `422` 和既有 source ID。

每个错误响应精确包含：

```text
ERROR_FIELD: errorCode
ERROR_FIELD: message
ERROR_FIELD: retryable
ERROR_FIELD: sourceDocumentId
ERROR_FIELD: sourceProcessingRevisionId
```

除 `404` 防枚举例外外，两个 ID 只在对应身份尚未创建时为 null；一旦创建就必须
返回。所有 404 两个 ID 始终为 null，不得依据对象存在性变化。`retryable` 必须
与 D01/D02 分类一致，不能由 HTTP 状态码临时猜测。

稳定 API 错误闭集为：

```text
API_ERROR: MALFORMED_COMMAND -> 400,false,IDENTITIES_NULL
API_ERROR: PAGINATION_INVALID -> 400,false,SOURCE_AND_REVISION_IF_RESOLVED
API_ERROR: RESOURCE_NOT_FOUND -> 404,false,IDENTITIES_ALWAYS_NULL
API_ERROR: IDEMPOTENCY_CONFLICT -> 409,false,SOURCE_IF_RESOLVED
API_ERROR: CONCURRENT_COMPLETION_CONFLICT -> 409,true,SOURCE_AND_REVISION_IF_RESOLVED
API_ERROR: PARTIAL_ACCEPTANCE_CONFLICT -> 409,false,SOURCE_AND_REVISION_IF_RESOLVED
API_ERROR: PREVIEW_NOT_READY -> 409,true,SOURCE_AND_REVISION_IF_RESOLVED
API_ERROR: SOURCE_SIZE_LIMIT -> 413,false,IDENTITIES_NULL
API_ERROR: UNSUPPORTED_MEDIA_TYPE -> 415,false,IDENTITIES_NULL
API_ERROR: EMPTY_SOURCE_FILE -> 422,false,CREATED_IDENTITIES_ONLY
API_ERROR: SOURCE_HASH_MISMATCH -> 422,false,CREATED_IDENTITIES_ONLY
API_ERROR: DOCX_SECURITY_REJECTED -> 422,false,CREATED_IDENTITIES_ONLY
API_ERROR: DOCX_FORMAT_INVALID -> 422,false,CREATED_IDENTITIES_ONLY
API_ERROR: SOURCE_NOT_ACCEPTED_YET -> 503,true,SOURCE_IF_RESOLVED
API_ERROR: PROCESSING_COMMAND_NOT_ACCEPTED -> 503,true,SOURCE_IF_RESOLVED
API_STATUS_FAILURE: PARSER_RETRYABLE_FAILURE -> 200,true,SOURCE_AND_REVISION
API_STATUS_FAILURE: PARSER_TERMINAL_FAILURE -> 200,false,SOURCE_AND_REVISION
API_STATUS_FAILURE: DOCX_FORMAT_INVALID -> 200,false,SOURCE_AND_REVISION
```

映射第三项决定两个 identity 字段：`IDENTITIES_NULL`/`IDENTITIES_ALWAYS_NULL`
均为二者 null；`SOURCE_IF_RESOLVED` 只回显已在可信 Workspace 内解析的 source；
`SOURCE_AND_REVISION_IF_RESOLVED` 只回显已经同域解析的 exact identities；
`CREATED_IDENTITIES_ONLY` 只回显拒绝发生前已原子创建的身份。Workspace 不可见、
真实不存在、revision 不属于 source 和跨 Workspace 统一使用
`RESOURCE_NOT_FOUND` 同一模板，禁止细分错误码形成 oracle。

cursor 篡改、revision mismatch、limit 非法都使用 `PAGINATION_INVALID`。接入校验
尚处于 `RECEIVED/VALIDATING` 时 processing 命令未被接受，返回
`SOURCE_NOT_ACCEPTED_YET/503/retryable=true`；已 `REJECTED` 则使用 422。基础设施
导致 processing 命令尚未原子接受时返回
`PROCESSING_COMMAND_NOT_ACCEPTED/503/retryable=true`。已接受 attempt 的后续失败
仍按第 4 节通过 GET 200 暴露，不回溯成 POST 503。`API_STATUS_FAILURE` 是
revision 查询 DTO 内的 `failureCode/retryable` 语义，不是非 2xx error body；
解析阶段的 `DOCX_FORMAT_INVALID` 因而与接入校验阶段的同码 422 保持阶段可区分。

## 8. Desktop Web 状态投影

```text
WEB_STATE: UPLOAD_IDLE
WEB_STATE: UPLOAD_IN_PROGRESS
WEB_STATE: VALIDATING
WEB_STATE: PARSING
WEB_STATE: PREVIEW_READY
WEB_STATE: PARTIAL_PREVIEW
WEB_STATE: RETRYABLE_FAILURE
WEB_STATE: TERMINAL_FAILURE
```

唯一映射：

```text
STATE_MAP: LOCAL_IDLE -> UPLOAD_IDLE
STATE_MAP: LOCAL_UPLOAD -> UPLOAD_IN_PROGRESS
STATE_MAP: DOCUMENT_RECEIVED_OR_VALIDATING -> VALIDATING
STATE_MAP: DOCUMENT_REJECTED -> TERMINAL_FAILURE
STATE_MAP: REVISION_PARSING_OR_PARSED -> PARSING
STATE_MAP: REVISION_PREVIEW_READY_COMPLETE -> PREVIEW_READY
STATE_MAP: REVISION_PREVIEW_READY_PARTIAL -> PARTIAL_PREVIEW
STATE_MAP: REVISION_FAILED_RETRYABLE -> RETRYABLE_FAILURE
STATE_MAP: REVISION_FAILED_TERMINAL -> TERMINAL_FAILURE
```

`ACCEPTED` 且 revision 创建尚未完成仍展示 `VALIDATING`；revision 原子创建后才
展示 `PARSING`。Web state 是只读投影，不写回 D01 状态。

预览显示原文件名、固定 processing revision、section path、source order、
nullable page number、block type、原始文本、表格 cell、内部图片 metadata、
caption、external marker 和 partial marker。

不得显示或生成：

- LLM summary、推断标题、猜测页码或自动图注；
- fetched external image/链接目标内容；
- Skeleton、KnowledgeTheme、CognitiveModule、KnowledgeElement；
- Renderer 新节点/关系或任何“预览专用事实”。

## 9. 分层验收

```text
ACCEPTANCE: UNIT -> IDENTITY+TRANSITION+NORMALIZATION+LINEAGE+PAGINATION
ACCEPTANCE: CONTRACT -> API_DTO+ERROR_CODE+STATE_PROJECTION+EXTERNAL_ACCESS_ZERO
ACCEPTANCE: INTEGRATION -> POSTGRESQL18_TESTCONTAINERS_AFTER_DATABASE_GATE
ACCEPTANCE: SECURITY -> ZIP_LIMITS+TRAVERSAL+DUPLICATE_ENTRY+XXE+EXTERNAL_RELATIONSHIP
ACCEPTANCE: GOLDEN -> THREE_MANIFEST_DOCX+UNCHANGED_SHA256+ORDER_AND_STRUCTURE_FINGERPRINTS
```

- Unit：D01 identity/state/CAS，D02 normalization/order/anchor，D03 alias/lineage，
  本契约 cursor/state mapping。
- Contract：命令/结果/错误 shape、Workspace 404、keyset、partial marker、禁止
  DTO 字段和 external access zero。
- Integration：只有正式数据库 Gate 后才可用 PostgreSQL 18 Testcontainers；
  本设计不创建 DB，也不允许用 H2 替代正式语义。
- Security：复用 D02 ZIP/XML/activity/external hard limits，并验证预览路径不会
  绕过安全扫描。
- Golden：以后实现获准后使用 manifest 跟踪的三份 DOCX、原 SHA-256、来源顺序、
  标题/段落/表格/图片/分页位置 fingerprint；必须通过已有 I/O guard。

本设计卡不对三份原件运行新 parser。W1-D05 可以只运行既有 W0 guarded Golden
regression，证明 SHA-256 未变和 external access 为零。

## 10. 不变量与验收命令

以下任一情况必须使 Gate 失败：

1. 使用 offset 或 active revision 进行块预览。
2. cursor 跨 revision、篡改或跳过 sourceOrder。
3. 预览生成 summary、标题、图注、Renderer 或认知对象。
4. partial 没有显式 marker/omissions，或被显示为 complete。
5. Web DTO 泄漏存储、Mapper、raw XML、内部异常或路径。
6. external relationship access count 非零。
7. 跨 Workspace 返回 403/详情而泄漏对象存在性。
8. 在数据库 Gate 前授权正式 DB，或在 Wave 1 调用 LLM。

验收命令：

```bash
bash tests/contracts/wave1-design/verify-source-preview-contract.sh
bash tests/contracts/wave1-design/verify-wave1-design-contracts.sh
scripts/verify-wave1-design
git diff --check
```
