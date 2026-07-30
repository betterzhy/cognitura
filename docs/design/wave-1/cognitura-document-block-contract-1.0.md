# Cognitura DocumentBlock 保真与安全契约 1.0

```text
CanonicalProjectName = Cognitura
DesignSliceID = W1-D02
DocumentBlockContractVersion = 1.0
ContractStatus = W1_DG2_PASS
AuthoritativeOverallDesign = Cognitura-Overall-Design-1.2
SchemaCompatibilityBaseline = Cognitura-Schema-Baseline-2.0
SourceDocumentContract = W1_DG1_PASS
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
ParserLibrary = NOT_SELECTED
LLMUsage = NONE
```

## 1. 目的与边界

本契约细化总体设计 §13、§17、§23、§24 对来源结构保真的要求，固定
`DocumentBlock` 的公共 envelope、类型 payload、顺序、章节、页码证据和 DOCX
安全分类。它从属于总体设计和 W1-D01，不创建运行时代码、数据库表、对象存储、
页面或第二套来源事实。

W1-D03 才固定跨 revision 稳定引用；W1-D04 才固定上传/状态/预览接口。本契约
不选择 DOCX 解析库或确定性布局引擎，也不打开、解包或转换 `raw/` 原件。

## 2. 块类型

每个块必须且只能使用下列一种类型：

```text
BLOCK_TYPE: HEADING
BLOCK_TYPE: PARAGRAPH
BLOCK_TYPE: LIST
BLOCK_TYPE: TABLE
BLOCK_TYPE: IMAGE
BLOCK_TYPE: CAPTION
BLOCK_TYPE: OTHER
```

不得把未知 OOXML 结构猜成标题、列表、图片或表格。无法无损映射到已知类型但仍
可安全提取的结构使用 `OTHER`，并以 `sourceKind` 暴露原始结构种类。

## 3. 公共 DocumentBlock envelope

```text
ENVELOPE_FIELD: documentBlockId
ENVELOPE_FIELD: sourceDocumentId
ENVELOPE_FIELD: sourceProcessingRevisionId
ENVELOPE_FIELD: blockType
ENVELOPE_FIELD: sourceOrder
ENVELOPE_FIELD: sectionPath
ENVELOPE_FIELD: pageNumber
ENVELOPE_FIELD: pageEvidence
ENVELOPE_FIELD: sourceAnchor
ENVELOPE_FIELD: sourcePart
ENVELOPE_FIELD: sourceElementIndex
ENVELOPE_FIELD: contentHash
ENVELOPE_FIELD: payload
```

字段职责：

- `documentBlockId`：一个 processing revision 内不可复用的块身份；不得由
  `contentHash` 取代。跨 revision 的兼容关系由 W1-D03 决定。
- `sourceDocumentId`、`sourceProcessingRevisionId`：必须与 W1-D01 已固定的
  来源和 revision 身份一致。
- `blockType`：决定且只决定一种 payload 结构。
- `sourceOrder`：该 revision 的全局来源顺序。
- `sectionPath`：进入当前块前已识别的标题路径。
- `pageNumber`、`pageEvidence`：可空的页码事实及其确定性证据。
- `sourceAnchor`：块在顶层流、段落文本或表格 cell 内的精确位置。
- `sourcePart`：规范化的 OOXML 包内 part 名称，例如
  `word/document.xml`，不是本地绝对路径。
- `sourceElementIndex`：在该 part 的安全 XML 事件流中从 0 开始的确定性前序
  序号；它与 `sourcePart` 只用于溯源和诊断。
- `contentHash`：规范化 payload 的 SHA-256，小写 64 位十六进制。
- `payload`：与 `blockType` 对应的唯一类型 payload。

## 4. 顺序、章节和页码

```text
SourceOrderBase = 0
SourceOrderRule = UNIQUE_CONTIGUOUS_WITHIN_PROCESSING_REVISION
SupportedFlowTraversal = EXPLICIT_CLOSED_SET
UnsupportedFlowPolicy = EXPLICIT_OMISSION_OR_TERMINAL
InlineObjectAnchor = PARENT_BLOCK_ID_TEXT_OFFSET_CHILD_ORDINAL
TableCellObjectAnchor = PARENT_TABLE_BLOCK_ID_ROW_COLUMN_TEXT_OFFSET_CHILD_ORDINAL
InlineImageOmission = FORBIDDEN
TableCellImageOmission = FORBIDDEN
ObjectReplacementCharacterBinding = ORDINAL_MATCHES_IMAGE_ANCHOR_CHILD_ORDINAL
InlinePlaceholderImageCardinality = BIJECTIVE
SupportedInlineImageBindingFailure = PARSE_FAILED_TERMINAL
SupportedTableCellImageBindingFailure = PARSE_FAILED_TERMINAL
SectionPathDerivation = PRECEDING_RECOGNIZED_HEADINGS_ONLY
HeadingLevelRange = 1..9
HeadingStyleGuessing = FORBIDDEN
PageNumberDefault = null
ExplicitPageBreakProvesPageNumber = NO
NonNullPageNumberRequires = APPROVED_DETERMINISTIC_LAYOUT_PROFILE_AND_PAGE_EVIDENCE
StablePublicReferenceFromSourcePartAndElementIndex = FORBIDDEN
ContentHashReplacesDocumentBlockId = NO
```

### 4.1 sourceOrder

解析器只按以下闭合集合遍历和生成块：

```text
SUPPORTED_FLOW: MAIN_DOCUMENT_BODY_BLOCK
SUPPORTED_FLOW: PARAGRAPH_INLINE_IMAGE
SUPPORTED_FLOW: TABLE_ROW_CELL_CONTENT
SUPPORTED_FLOW: TABLE_CELL_INLINE_IMAGE
SUPPORTED_FLOW: EXPLICIT_CAPTION
SUPPORTED_FLOW: EXPLICIT_PAGE_BREAK
```

`word/document.xml` body child 按 XML 顺序遍历；段落 run/child 按 XML 顺序，
表格按 row、视觉网格 column、cell 内段落/child 顺序遍历。style、numbering 和
relationship part 只提供当前块的确定性元数据，不独立占用 `sourceOrder`；内部
media part 只由首次出现的受支持 image relationship 引用。header、footer、
footnote、endnote、comment、text box、custom XML 和嵌套表格不在闭合集合内，
发现时必须形成逐项 explicit omission；若它影响主流顺序或无法安全定位，则
终止解析，绝不静默忽略。

解析器按上述事件流生成块后一次性验证 `sourceOrder = 0..N-1`，不得重复、留洞
或按块类型重新分组。顶层 paragraph/table/caption/page-break 和独立图片依出现
顺序占一个序号；内联图片也占独立 `IMAGE` 块序号，并额外通过 `sourceAnchor`
保留其容器内部真实位置。`sourceOrder` 表达跨块序列，`sourceAnchor` 表达块内
位置，两者共同构成来源顺序事实，缺一即验证失败。

`sourceAnchor` 精确字段为：

```text
SOURCE_ANCHOR_FIELD: parentBlockId
SOURCE_ANCHOR_FIELD: anchorKind
SOURCE_ANCHOR_FIELD: textOffset
SOURCE_ANCHOR_FIELD: childOrdinal
SOURCE_ANCHOR_FIELD: rowIndex
SOURCE_ANCHOR_FIELD: columnIndex
```

- 顶层块：`anchorKind=FLOW`，其余字段为 `null`。
- 段内图片：`anchorKind=PARAGRAPH_INLINE`，`parentBlockId` 指向段落/列表/标题
  块；`textOffset` 是规范化文本中对应 `U+FFFC` 的 Unicode code-point offset，
  `childOrdinal` 是该容器中从 0 开始的 inline object 序号，row/column 为 null。
- 表格 cell 内图片：`anchorKind=TABLE_CELL_INLINE`，`parentBlockId` 指向 TABLE，
  row/column 指向锚点 cell，`textOffset` 指向 cell 规范化全文中的 `U+FFFC`，
  `childOrdinal` 是该 cell 中从 0 开始的 inline object 序号。

段落或 cell 文本在每个内联图片位置保留一个 `U+FFFC`，第 N 个占位符必须精确
绑定 `childOrdinal=N` 的 IMAGE；每个占位符恰有一个 IMAGE，每个 anchored IMAGE
也恰有一个占位符。图片块可在其容器块后按 `childOrdinal` 排列，但不得因此丢失
原始 offset。任何受支持段内或 cell 内图片都不得省略；占位符、anchor 与 IMAGE
无法建立双射时属于 envelope/payload 硬失败，必须返回
`PARSE_FAILED_TERMINAL`，不得降级为 partial。只有闭集外且不破坏受支持主流顺序
的结构才可形成显式 partial omission。

### 4.2 sectionPath

识别到合法 `HEADING` 后，以其原始文本替换相同或更深层级路径；后续块复制当时的
完整路径。标题文本只做 Unicode NFC 和换行规范化，不摘要、不改写。首个标题前
`sectionPath=[]`；不得用文件名或模型生成标题补齐。W1-D03 必须显式处理它与
`EvidenceReference.sectionPath` 非空约束的兼容，W1-D02 不静默发明根章节。

### 4.3 pageNumber

普通 OOXML 结构解析一律产生 `pageNumber=null`、`pageEvidence=null`。DOCX 应用
页数元数据、`lastRenderedPageBreak` 和显式分页符都不能单独证明当前渲染页码。
显式分页符应作为 `OTHER(sourceKind=EXPLICIT_PAGE_BREAK)` 保留来源位置，但不能
把后续块页码猜成前一页加一。

只有以后另行批准的确定性布局 profile 才可产生非空页码；届时每个非空页码必须
同时记录 `pageEvidence = {layoutProfileVersion,layoutEngineVersion,pageIndex,
evidenceHash}`。当前 `ParserLibrary = NOT_SELECTED`，因此本契约没有已批准布局
profile。

## 5. 类型 payload

```text
PAYLOAD: HEADING -> text,level,styleName
PAYLOAD: PARAGRAPH -> text,styleName
PAYLOAD: LIST -> listInstanceId,itemLevel,itemOrdinal,markerText,text
PAYLOAD: TABLE -> rows[{rowIndex,cells[{columnIndex,rowSpan,columnSpan,text}]}]
PAYLOAD: IMAGE -> relationshipId,relationshipMode,externalTargetLiteralSha256,mediaRef,mediaType,byteLength,contentSha256,securityDisclosure
PAYLOAD: CAPTION -> text,captionForBlockId
PAYLOAD: OTHER -> text,sourceKind
```

### 5.1 HEADING 与 PARAGRAPH

- `HEADING.level` 只接受 `1..9`。
- 只有显式、已登记的 OOXML outline level 或 heading style 映射可生成
  `HEADING`；未识别的疑似标题样式保持 `PARAGRAPH` 或 `OTHER`。
- `text` 保留可见字符、段内换行与 tab；只允许 Unicode NFC、CRLF/CR 到 LF
  和无语义 XML 分片合并，不允许摘要、翻译或空白语义猜测。
- `styleName` 保留来源样式名；缺失时为 `null`，不得编造。

### 5.2 LIST

```text
ListItemBlockCardinality = ONE_BLOCK_PER_ITEM
```

每个列表项是一个 `LIST` 块。`listInstanceId` 由同一 numbering 实例和连续列表
区段决定；`itemLevel` 从 0 开始，`itemOrdinal` 是同一实例同一层级内从 0 开始
的来源顺序。`markerText` 仅在 OOXML 可确定时保留，否则为 `null`；不得猜测项目
符号或重新编号。

### 5.3 TABLE

```text
TableMergedCellPreservation = REQUIRED
```

一个来源表格对应一个 `TABLE` 块。`rowIndex`、`columnIndex` 从 0 开始并按视觉
网格位置排列；`rowSpan`、`columnSpan` 至少为 1。合并区域只在锚点 cell 记录，
被覆盖位置不得生成重复文本。cell 的 `text` 必须按段落/列表/换行的来源顺序合并，
保留完整可见文本；不得仅取首段、扁平排序或丢弃空 cell。嵌套表格无法由当前
payload 无损表示时必须进入显式 `PARTIAL_PARSE` omission，不得静默扁平化。

### 5.4 IMAGE

```text
InternalImageBytesRepresentation = IMMUTABLE_MEDIA_REF_AND_SHA256
ExternalImageBytesFetched = NO
ExternalRelationshipTargetCapture = SHA256_OF_LITERAL_WITHOUT_DEREFERENCE
ExternalRelationshipContentAccess = ZERO
ExternalTargetDigestPropagation = IMAGE_PAYLOAD_CONTENT_HASH_REVISION_DIAGNOSTICS
```

- 内部 relationship：`relationshipMode=INTERNAL`，解析器只把已验证的包内媒体
  复制到只读派生媒体端口，记录不可变 `mediaRef`、media type、字节数和 SHA-256。
  `externalTargetLiteralSha256=null`。不允许将二进制内联到块或通过文件路径暴露。
- 外部 relationship：`relationshipMode=EXTERNAL`，保留 relationship ID，
  `externalTargetLiteralSha256` 是 relationship XML 中 target 属性解析后字面值的
  UTF-8 SHA-256；它必须纳入 payload `contentHash`，所以 target 字面值变化而
  relationship ID 不变时仍形成可见回归。`mediaRef/mediaType/byteLength/
  contentSha256` 全为 `null`，`securityDisclosure=
  EXTERNAL_RELATIONSHIP_NOT_DEREFERENCED`。只对已在内存中的 XML 属性字面值
  计算 hash，不读取、探测、stat、DNS 解析或请求 target；target 内容不属于输入。
- 每个 external relationship（不仅限图片）还必须进入 revision 解析诊断，记录
  source part、relationship ID/type/mode 和相同 target literal digest。诊断不保存
  可点击 target，也不得触发文件或网络访问；这保持现有 Golden Case 对 target
  改写的回归可见性。

同一个 digest 值必须原样传播到 IMAGE payload、该 payload 的 canonical
`contentHash` 输入以及 revision diagnostics；三处任一缺失或不一致均使解析
验证失败，不得以“只影响诊断”为由忽略 target 漂移。
- relationship 缺失、重复或指向越界包路径时不能伪装成内部图片；按安全或格式
  分类明确失败。

### 5.5 CAPTION 与 OTHER

```text
CaptionTextInference = FORBIDDEN
```

只有来源中的显式 caption style/结构才生成 `CAPTION`；`captionForBlockId` 只能
指向同 revision 中相邻且关系可确定的 `IMAGE`，否则为 `null` 并记录 omission，
不得从图片、文件名或邻近段落生成图注。

`OTHER.text` 保存安全可提取文本，`sourceKind` 使用稳定枚举式标识原始结构，
例如 `EXPLICIT_PAGE_BREAK` 或 `UNSUPPORTED_SAFE_OOXML`；不得用 `OTHER` 隐藏
安全拒绝或解析错误。

## 6. DOCX 安全边界

安全扫描在创建 processing revision 前完成；命中安全拒绝规则时沿用 W1-D01
`DOCX_SECURITY_REJECTED -> SourceDocument REJECTED`，不创建可预览 revision。

```text
ExternalRelationshipDereference = FORBIDDEN
MacroExecution = FORBIDDEN
EmbeddedObjectExecution = FORBIDDEN
XmlExternalEntityResolution = FORBIDDEN
MAX_ZIP_ENTRY_COUNT = 4096
MAX_ZIP_ENTRY_BYTES = 16777216
MAX_ZIP_TOTAL_BYTES = 134217728
MAX_COMPRESSION_RATIO = 200
UnknownZipEntrySize = SECURITY_REJECTED
```

计数和大小检查必须在读取 entry 内容前完成，并在流式读取时再次限制实际解压
字节数。压缩比按 `uncompressedBytes / max(1, compressedBytes)` 计算，超过
200 即拒绝；零压缩字节但非空内容同样拒绝。entry 名先按 ZIP 原始名称检查，
禁止重复名称、绝对路径、反斜线逃逸、NUL、盘符和任意 `..` path segment。
必需 DOCX part 必须各出现一次。

XML parser 必须禁用 DOCTYPE、XInclude、外部 general/parameter entity，以及
外部 DTD/Schema 访问。宏不得执行；包含需执行宏的包、可执行 OLE/ActiveX 或
其他活动嵌入对象直接安全拒绝。安全扫描可以识别并记录外部 relationship 元数据，
但任何调用方要求跟随它都必须拒绝。

机器可验证分类：

```text
SECURITY: DUPLICATE_ZIP_ENTRY_NAME -> SECURITY_REJECTED
SECURITY: ABSOLUTE_ZIP_PATH -> SECURITY_REJECTED
SECURITY: ZIP_PARENT_TRAVERSAL -> SECURITY_REJECTED
SECURITY: UNKNOWN_ZIP_ENTRY_SIZE -> SECURITY_REJECTED
SECURITY: ZIP_LIMIT_EXCEEDED -> SECURITY_REJECTED
SECURITY: XML_EXTERNAL_ENTITY -> SECURITY_REJECTED
SECURITY: MACRO_REQUIRING_EXECUTION -> SECURITY_REJECTED
SECURITY: EXECUTABLE_EMBEDDED_OBJECT -> SECURITY_REJECTED
SECURITY: EXTERNAL_RELATIONSHIP_DEREFERENCE_REQUEST -> SECURITY_REJECTED
```

## 7. 解析结果与 D01 状态衔接

```text
PARSE_RESULT: SECURITY_REJECTED
PARSE_RESULT: FORMAT_INVALID
PARSE_RESULT: PARTIAL_PARSE
PARSE_RESULT: PARSE_FAILED_RETRYABLE
PARSE_RESULT: PARSE_FAILED_TERMINAL
PartialParseOmissions = EXPLICIT_WITH_ERROR_LOCATIONS
PartialParsePreviewReady = FORBIDDEN_WITHOUT_USER_VISIBLE_INCOMPLETE_MARKER
DocumentBlockSetCandidateScope = SOURCE_PROCESSING_ATTEMPT
DocumentBlockSetBeforePublish = INVISIBLE
DocumentBlockSetPublicationOwner = D01_ATOMIC_FINALIZE
DocumentBlockSetIntegrity = VALID_ENVELOPES_UNIQUE_CONTIGUOUS_ORDER_AND_SET_DIGEST
PartialAcceptanceRequired = YES
PartialAcceptanceFactOwner = SOURCE_PROCESSING_REVISION
```

硬失败不得降级为 partial：

```text
HARD_FAILURE: SECURITY_RULE -> NEVER_PARTIAL
HARD_FAILURE: MAIN_DOCUMENT_MISSING -> NEVER_PARTIAL
HARD_FAILURE: SOURCE_ORDER_UNDETERMINED -> NEVER_PARTIAL
HARD_FAILURE: ENVELOPE_INVALID -> NEVER_PARTIAL
HARD_FAILURE: PAYLOAD_INVALID -> NEVER_PARTIAL
```

与 W1-D01 的机器可验证映射为：

```text
D01_MAPPING: SECURITY_REJECTED -> DOCUMENT_REJECTED
D01_MAPPING: FORMAT_INVALID -> DOCUMENT_REJECTED
D01_MAPPING: PARTIAL_PARSE -> REVISION_PARSED_WITH_PARTIAL_COMPLETENESS
D01_MAPPING: PARSE_FAILED_RETRYABLE -> ATTEMPT_AND_REVISION_FAILED_RETRYABLE
D01_MAPPING: PARSE_FAILED_TERMINAL -> ATTEMPT_AND_REVISION_FAILED_TERMINAL
```

| 结果 | 条件 | W1-D01 衔接 |
|---|---|---|
| `SECURITY_REJECTED` | 安全扫描命中硬拒绝 | validation 阶段 `SourceDocument.REJECTED`，不创建 revision |
| `FORMAT_INVALID` | validation 阶段确定不是合法 DOCX | `SourceDocument.REJECTED` |
| `PARTIAL_PARSE` | 非安全关键、非必需结构可安全解析但有明确遗漏 | 候选块验证通过后 revision 可进入 `PARSED`，同时 `parseCompleteness=PARTIAL` |
| `PARSE_FAILED_RETRYABLE` | 瞬态 I/O 或基础设施失败 | attempt/revision 原子进入 `FAILED_RETRYABLE` |
| `PARSE_FAILED_TERMINAL` | revision 创建后出现确定性格式/必需 part/结构失败 | attempt/revision 原子进入 `FAILED_TERMINAL` |

`PARTIAL_PARSE` 必须记录每项 omission 的 `sourcePart`、`sourceElementIndex`、
稳定错误码和用户可见说明。安全规则命中、主文档缺失、顺序无法确定、块 envelope
无效或 payload 校验失败都不能降级为 partial。partial revision 只有在预览响应
显式携带 `incomplete=true`、完整 omission 列表和固定警示文案时才可进入
`PREVIEW_READY`；用户未确认前不得作为后续认知生成的正式来源。

所有候选块先写入 `sourceProcessingAttemptId` 隔离的 staging set。集合完整性验证
必须覆盖：每个 envelope/payload 合法、`sourceDocumentId`/revision/attempt
作用域一致、`sourceOrder` 从 0 唯一连续、所有受支持 inline/table image 绑定闭合，
并对按 `sourceOrder` 排序的 canonical block bytes 计算不可变 block-set digest。
只有 W1-D01 fenced success transaction 可同时发布该集合、alias、stage record 和
`PARSED` revision；在此之前任何查询或 consumer 都看不到候选块。

完整集合发布时 `parseCompleteness=COMPLETE`，revision 的
`partialAcceptanceStatus=NOT_APPLICABLE`。partial 集合发布时
`parseCompleteness=PARTIAL`、`partialAcceptanceStatus=PENDING`；omissions digest
与 block-set digest 一起绑定确认事实。W1-D04 只可把 exact revision 从
`PENDING` 幂等确认为 `ACCEPTED`，不得改写块、omission 或 completeness。

## 8. 确定性与模型边界

后续实现获准时，确定性代码负责 ZIP/XML 安全、结构遍历、类型识别、顺序、哈希、
payload 校验、错误分类和 D01 原子状态调用。所有规范化规则和 style 映射必须带
版本并纳入 `parserProfileVersion`。

Wave 1 不调用 LLM。模型不得识别标题、补正文、猜页码、生成图注、解释外部链接、
修复表格或决定 partial 是否可发布。

## 9. 下游兼容边界

W1-D03 可消费本契约的：

```text
documentBlockId
sourceDocumentId
sourceProcessingRevisionId
blockType
sourceOrder
sectionPath
pageNumber
sourceAnchor
sourcePart
sourceElementIndex
contentHash
```

`sourcePart + sourceElementIndex` 不是公开稳定引用；`contentHash` 也不是身份。
W1-D03 必须固定跨 revision 匹配、歧义和 tombstone 语义，并处理根级
`sectionPath=[]` 与现有 `EvidenceReference` 非空约束，不能在本卡提前发明
跨 revision 身份。

## 10. 不变量与验收

以下任一情况必须使契约 Gate 或后续实现失败：

1. 块类型缺失、payload 与类型不匹配或来源顺序不连续。
2. 从应用页数、分页符或模型猜测 `pageNumber`。
3. 把疑似标题样式直接升级为 `HEADING`。
4. 丢弃表格合并跨度、cell 全文、图片引用或 caption 来源关系。
5. 读取外部 relationship、Redis 遗留链接目标或执行活动内容。
6. 放宽 ZIP/XML 限制、把未知大小当作安全输入或隐藏 partial omission。
7. 用 hash 或 OOXML 位置替代正式块身份。
8. 写入正式数据库、选择 Parser Provider、调用 LLM 或创建业务页面。

验收命令：

```bash
bash tests/contracts/wave1-design/verify-document-block-contract.sh
bash tests/contracts/wave1-design/verify-source-document-contract.sh
bash tests/task-cards/verify-wave1-design-cards.sh
bash tests/ci/verify-markdown-links.sh
git diff --check
```
