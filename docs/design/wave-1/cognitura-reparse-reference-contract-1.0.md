# Cognitura 重解析与稳定引用契约 1.0

```text
CanonicalProjectName = Cognitura
DesignSliceID = W1-D03
ReparseReferenceContractVersion = 1.0
ContractStatus = W1_DG3_PASS
AuthoritativeOverallDesign = Cognitura-Overall-Design-1.2
SchemaCompatibilityBaseline = Cognitura-Schema-Baseline-2.0
SourceDocumentContract = W1_DG1_PASS
DocumentBlockContract = W1_DG2_PASS
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
LLMUsage = NONE
```

## 1. 目的与边界

本契约固定 processing revision 之间的不可变 Block 引用、重解析复用、
`BlockLineageMap` 和 Wave 2/3 只读消费接口。它细化总体设计 §14、§17，并解决
W1-D02 留给本卡的两个兼容问题：

- `sourcePart + sourceElementIndex` 不是公开稳定引用；
- D02 根级 `sectionPath=[]` 不能直接满足 Schema Baseline 2.0 §6.8 的非空要求。

本契约不创建数据库、API、解析器、认知产物或自动迁移任务，不改变 Schema
Baseline 2.0，也不授权读取 `raw/` 原件、外部 relationship 或使用 LLM。

## 2. 不可变 DocumentBlockRef

```text
DocumentBlockRef = SOURCE_DOCUMENT_ID+PROCESSING_REVISION_ID+DOCUMENT_BLOCK_ID
DocumentBlockRefResolution = EXACT_IMMUTABLE_TUPLE
HistoricalReferenceRetargeting = FORBIDDEN
ActiveRevisionSelectorInEvidenceReference = FORBIDDEN
NewRevisionBlockIds = REQUIRED
```

逻辑结构为：

```text
DOCUMENT_BLOCK_REF_FIELD: sourceDocumentId
DOCUMENT_BLOCK_REF_FIELD: sourceProcessingRevisionId
DOCUMENT_BLOCK_REF_FIELD: documentBlockId
```

三个字段共同指向且只指向一个 W1-D02 不可变块：

- `sourceDocumentId` 必须等于目标 revision 的来源；
- `sourceProcessingRevisionId` 必须精确命中一个已保留 revision；
- `documentBlockId` 必须在该 revision 中唯一解析；
- 三者任一不匹配均返回 `REFERENCE_NOT_FOUND` 或
  `REFERENCE_SCOPE_MISMATCH`，不得改查 active revision。

新 processing revision 必须为全部块生成新 `documentBlockId`，即使 payload 与
旧 revision 完全相同。旧引用在旧 revision 仍被保留期间继续解析到旧块；
`REMOVED` lineage 也不删除或改写它。revision 保留/清除策略不属于 Wave 1，
但清除不得伪装成新 revision 重定向。

`activeSourceProcessingRevisionId` 只是查询/预览的便利 selector。调用方必须显式
选择它并取得该 revision 的新 refs；已保存的 EvidenceReference、lineage entry
或历史 URL 都不得包含“active/latest”语义。

## 3. ArtifactRef 字符串兼容

Schema Baseline 2.0 把 `EvidenceReference.sourceDocumentRef` 和
`documentBlockRef` 定义为最多 128 字符的 `ArtifactRef` 字符串，而本契约的
运行时 Block 引用是三段式逻辑对象。不得把三个可能各为 128 字符的 ID 直接拼接
进 `ArtifactRef`。

```text
EvidenceDocumentBlockArtifactRef = IMMUTABLE_ALIAS_TO_DOCUMENT_BLOCK_REF_TUPLE
AliasCanonicalizationVersion = DBR_ALIAS_V1
AliasCanonicalTupleEncoding = DOMAIN_TAG_UTF8+VERSION_U8+FIELD_COUNT_U8+EACH_FIELD_UINT32_BE_LENGTH_UTF8
AliasIdentifierByteNormalization = UTF8_EXACT_NO_CASE_OR_UNICODE_NORMALIZATION
AliasDigestAlgorithm = SHA256
AliasCollision = HARD_CONFLICT_NO_LAST_WRITE_WINS
AliasRegistryInsert = COMPARE_AND_SET_EMPTY_OR_SAME_TARGET
ReferenceAliasRetargeting = FORBIDDEN
AliasRegistryScope = SOURCE_DOCUMENT
AliasRegistryCognitionDependency = NONE
SourceDocumentAliasCreation = ATOMIC_WITH_SOURCE_DOCUMENT_CREATION
DocumentBlockAliasCreation = ATOMIC_WITH_BLOCK_SET_PUBLICATION
AliasCollisionCheck = BEFORE_FACT_PUBLICATION
AliasAvailability = BEFORE_SOURCE_OR_BLOCK_PREVIEW
AliasResolutionRequires = WORKSPACE_CONTEXT_SOURCE_DOCUMENT_REVISION_AND_EXACT_TUPLE
```

兼容方式：

- `documentBlockRef` 使用 `dbr:<sha256(canonicalTuple)>`。`DBR_ALIAS_V1`
  canonical bytes 依次是：ASCII/UTF-8 domain tag `cognitura:dbr`、单字节版本
  `0x01`、单字节 field count `0x03`，随后按
  `sourceDocumentId/sourceProcessingRevisionId/documentBlockId` 固定顺序写入每个
 字段的 unsigned 32-bit big-endian UTF-8 byte length 和原始 UTF-8 bytes。
  ID 字节不做大小写折叠、Unicode normalization、trim 或分隔符转义。
- `sourceDocumentRef` 使用 domain tag `cognitura:sdr`、版本 `0x01`、field count
  `0x01` 和同样的 uint32 big-endian length + exact UTF-8 bytes。
- 两类 canonical bytes 使用 SHA-256，alias 保存 64 位小写 hex digest；
  `dbr:`/`sdr:` 加 digest 均为 68 字符，符合 ArtifactRef 约束。domain separation
  保证 source alias 与 block alias 不共享 digest namespace。
- 不可变 alias registry 属于 `SourceDocument` scope，不依赖尚未存在的
  cognition revision。source alias 与 SourceDocument 创建在同一事务写入；
  block alias 与 D01 block set 发布在同一 fenced transaction 写入。任何碰撞必须
  在 source/block 事实可见前检查：目标为空则创建，已为同 tuple 则幂等返回；
  同 alias/不同 tuple 是 `REFERENCE_ALIAS_CONFLICT` 硬冲突，整笔事实发布失败，
  禁止 last-write-wins、覆盖或重新 hash 尝试隐藏碰撞。
- hash alias 是受限标识，不替代 tuple 的作用域校验；解析必须同时验证 alias
  类型、可信 Workspace context、`sourceDocumentId`、exact processing revision、
  registry target/tuple 和目标对象存在性。alias 必须先于来源/块预览可用，读取
  预览不得懒创建或修复 registry。

这样保持 `ArtifactRef` 的既有 JSON Schema，不把“当前块”或数据库主键当成
第二套来源事实。

## 4. 重解析幂等

```text
SameHashSameParserProfile = REUSE_SUCCESSFUL_REVISION
SameHashSameParserProfileFailed = RETRY_ATTEMPT_IN_EXISTING_REVISION
SameHashSameParserProfileTerminal = RETURN_EXISTING_TERMINAL_REQUIRE_NEW_PROFILE
SameHashNewParserProfile = CREATE_NEW_PROCESSING_REVISION
NewSourceBytes = CREATE_NEW_SOURCE_DOCUMENT
```

裁决顺序：

1. 相同 `sourceDocumentId + contentSha256 + parserProfileVersion` 已有成功 revision：
   返回原 revision 和原 blocks，不运行解析、不创建 alias 副本。
2. 相同组合只有 retryable failure：遵循 W1-D01，在原 revision 创建新 attempt；
   不创建第二 revision。
3. 相同组合已有 `FAILED_TERMINAL`：返回该 terminal revision 和错误，禁止在
   相同 profile retry 或另建 revision；只有调用方显式使用新的
   `parserProfileVersion` 才能进入下一分支。
4. 相同来源 hash、不同 `parserProfileVersion`：创建新 processing revision、
   新 block IDs 和新 lineage map。
5. 同一上传意图出现新来源字节：不得修改原 SourceDocument；调用方必须以新
   idempotency key 创建新 `SourceDocument`。不同 SourceDocument 之间不自动
   建立 block lineage。

processing revision 成功唯一性和 attempt fencing 完全服从 W1-D01。重解析不得
通过删除旧 revision、覆盖旧 block 或重绑 alias 达到“复用”。

## 5. BlockLineageMap

`BlockLineageMap` 是同一 `SourceDocument` 的两个成功 processing revision 之间
的不可变、方向性映射：

```text
LINEAGE_FIELD: fromProcessingRevisionId
LINEAGE_FIELD: toProcessingRevisionId
LINEAGE_FIELD: entries[{fromBlockRefs,toBlockRefs,lineageState,confidenceBasis}]
LINEAGE_FIELD: createdAt
LINEAGE_FIELD: algorithmVersion
```

```text
LineageStates = UNCHANGED,MOVED,MODIFIED,SPLIT,MERGED,REMOVED,ADDED,AMBIGUOUS
LineageMapMutation = FORBIDDEN
LineageCoverage = ALL_FROM_AND_TO_BLOCKS_EXACTLY_ONCE
LineageSourceScope = SAME_SOURCE_DOCUMENT_ONLY
LineageAlgorithmVersionCovers = HASH_CANONICALIZATION+ANCHOR_COMPARISON+CONCATENATION+AMBIGUITY_RULES
NewLineageAlgorithm = CREATE_NEW_IMMUTABLE_MAP
AmbiguousLineageAutoResolution = FORBIDDEN
LineageConfidenceBasis = DETERMINISTIC_EVIDENCE_NOT_LLM_SCORE
RemovedBlockHistoricalResolution = PRESERVED_WHILE_REVISION_RETAINED
```

每个 from block 和 to block 必须在整张 map 的 entries 中恰好出现一次，不得漏掉、
重复归类或同时进入确定项和 `AMBIGUOUS`。每个 ref 必须属于对应 from/to revision，
两端 revision 必须属于同一个 SourceDocument 且方向不得反转；跨 SourceDocument
即 `LINEAGE_REVISION_SCOPE_MISMATCH`，不能以相同 hash 放宽。

各状态基数为：

```text
LINEAGE_CARDINALITY: UNCHANGED -> 1_FROM,1_TO
LINEAGE_CARDINALITY: MOVED -> 1_FROM,1_TO
LINEAGE_CARDINALITY: MODIFIED -> 1_FROM,1_TO
LINEAGE_CARDINALITY: SPLIT -> 1_FROM,MANY_TO
LINEAGE_CARDINALITY: MERGED -> MANY_FROM,1_TO
LINEAGE_CARDINALITY: REMOVED -> ONE_OR_MORE_FROM,0_TO
LINEAGE_CARDINALITY: ADDED -> 0_FROM,ONE_OR_MORE_TO
LINEAGE_CARDINALITY: AMBIGUOUS -> ONE_OR_MORE_FROM,ONE_OR_MORE_TO
```

`MANY` 至少为 2。`REMOVED` 是 lineage tombstone：to revision 中没有替代块，
但 from refs 仍指向旧块。`ADDED` 不伪造 from ref。

### 5.1 确定性分类

`confidenceBasis` 是结构化确定性证据，不是 0–1 分数：

- 相同 canonical payload hash 且 anchor/source position 唯一对应：
  `UNCHANGED`；
- 相同 hash 但 anchor/sourceOrder 唯一变化：`MOVED`；
- 唯一 anchor 对应且 canonical payload hash 改变：`MODIFIED`；
- 多块规范化 payload 的精确、无重叠串接与单块相等且参与者唯一：
  `SPLIT` 或 `MERGED`；
- 只在一端存在且无候选：`REMOVED` 或 `ADDED`；
- 多候选、证据冲突、覆盖重叠或无法证明唯一：`AMBIGUOUS`。

`algorithmVersion` 必须覆盖 hash canonicalization、anchor 比较、串接规则和歧义
规则。map 幂等键为 `(fromRevisionId,toRevisionId,algorithmVersion)`；同键同内容
复用，同键不同内容是硬冲突。新算法版本必须创建新的不可变 map，不得覆盖、
删除或把旧 map 标为指向新结果。

`AMBIGUOUS` 不得按“最高分”、当前 revision 或首个候选自动选取。以后若有明确
用户决定，只能创建带用户决定引用的新 lineage map/overlay；不得修改旧 map，
也不得直接重绑任何 EvidenceReference。

## 6. Wave 2/3 只读消费

```text
Wave1BlocksMutableByConsumers = NO
Wave2RevisionSelector = EXPLICIT_NOT_ACTIVE
Wave2BlockRefScope = SAME_PROCESSING_REVISION
Wave2BlockOrder = EXACT_CONTIGUOUS_SOURCE_ORDER
Wave2DuplicateRefs = FORBIDDEN
Wave2PartialConsumptionGate = PARTIAL_ACCEPTANCE_STATUS_ACCEPTED
Wave2CompleteConsumptionGate = PARSE_COMPLETENESS_COMPLETE
EvidenceFullSourceCopy = FORBIDDEN
EvidenceSourceKindFromD02OtherPayload = FORBIDDEN
EvidenceSourceKind = SOURCE_EXPLICIT_OR_SOURCE_SYNTHESIZED_ONLY
CONSUMER: WAVE2_SECTION_UNDERSTANDING -> PROCESSING_REVISION_ID+ORDERED_DOCUMENT_BLOCK_REFS
CONSUMER: WAVE3_EVIDENCE_REFERENCE -> IMMUTABLE_SOURCE_AND_BLOCK_ALIASES+SOURCE_METADATA
```

Wave 2 只能提交显式 `sourceProcessingRevisionId` 和按 D02 `sourceOrder` 排序的
`DocumentBlockRef[]`。列表中所有 ref 必须属于同一 revision、无重复且 order
从 0 连续；不得使用 active selector、混合 revision、按 consumer 偏好重排或
跳过块。消费入口必须读取 D01 的 exact revision：`COMPLETE` 可直接进入；
`PARTIAL` 只有 `partialAcceptanceStatus=ACCEPTED` 且确认绑定的 block-set/omissions
digest 仍精确匹配时才可进入。`PENDING`、digest 不匹配或其他状态一律拒绝为
`PARTIAL_ACCEPTANCE_REQUIRED`。消费过程不得写回 block、alias 或 lineage。

Wave 3 `EvidenceReference` 映射为：

```text
EVIDENCE_MAP: sourceDocumentRef -> IMMUTABLE_SOURCE_DOCUMENT_ALIAS
EVIDENCE_MAP: documentBlockRef -> IMMUTABLE_DOCUMENT_BLOCK_REF_ALIAS
EVIDENCE_MAP: sectionPath -> COPY_OR_DOCUMENT_ROOT_SENTINEL
EVIDENCE_MAP: pageNumber -> COPY_NULL_OR_PROVEN_PAGE_NUMBER
EVIDENCE_MAP: sourceOrder -> COPY_EXACT_SOURCE_ORDER
EVIDENCE_MAP: blockType -> COPY_EXACT_BLOCK_TYPE
EVIDENCE_MAP: contentSummary -> DERIVED_SUMMARY_NOT_FULL_SOURCE
```

全部必填字段的所有权为：

```text
EVIDENCE_OWNER: schemaVersion -> WAVE3_COGNITION_CONTRACT
EVIDENCE_OWNER: artifactId -> WAVE3_EVIDENCE_IDENTITY
EVIDENCE_OWNER: revisionId -> WAVE3_COGNITION_REVISION_NOT_SOURCE_PROCESSING_REVISION
EVIDENCE_OWNER: publicationState -> WAVE3_EVIDENCE_LIFECYCLE
EVIDENCE_OWNER: sourceDocumentRef -> W1_IMMUTABLE_ALIAS
EVIDENCE_OWNER: documentBlockRef -> W1_IMMUTABLE_ALIAS
EVIDENCE_OWNER: sectionPath -> W1_BLOCK_MAPPING
EVIDENCE_OWNER: pageNumber -> W1_BLOCK
EVIDENCE_OWNER: sourceOrder -> W1_BLOCK
EVIDENCE_OWNER: blockType -> W1_BLOCK
EVIDENCE_OWNER: contentSummary -> WAVE3_DERIVED_CONTENT
EVIDENCE_OWNER: sourceKind -> WAVE3_EVIDENCE_SEMANTICS
EVIDENCE_OWNER: supports -> WAVE3_COGNITION_LINKS
EVIDENCE_OWNER: inferenceDisclosure -> WAVE3_INFERENCE_DISCLOSURE
EVIDENCE_OWNER: conflictState -> WAVE3_CONFLICT_MODEL
EVIDENCE_OWNER: conflictGroupId -> WAVE3_CONFLICT_MODEL
EVIDENCE_OWNER: resolutionDecision -> WAVE3_USER_DECISION
```

- `pageNumber` 原样复制 D02 的 null 或有 `pageEvidence` 的值；`sourceOrder`
  始终原样复制，因此满足 Schema Baseline “pageNumber/sourceOrder 至少一个非空”。
- `blockType` 只使用 D02 七项 enum。
- `contentSummary` 是后续受约束派生摘要，不复制完整原始正文；引用仍解析回只读块。
- Evidence `sourceKind` 只使用 Schema Baseline 的
  `SOURCE_EXPLICIT/SOURCE_SYNTHESIZED`，由 Wave 3 根据摘要/推断语义决定。
  D02 `OTHER.payload.sourceKind` 是 OOXML 结构种类，字段同名但语义不同，绝对
  禁止复制到 Evidence `sourceKind`。
- 任何 consumer 若要迁移到新 revision，必须创建新的 EvidenceReference revision
  并显式记录用户/授权决策；旧 EvidenceReference 保持原 alias。

### 6.1 根级 sectionPath

```text
EmptyBlockSectionPathMapping = DOCUMENT_ROOT_SENTINEL
DocumentRootSentinel = DOCUMENT_ROOT
```

D02 `sectionPath` 非空时逐项原样复制。D02 `sectionPath=[]` 时，
EvidenceReference 写入唯一系统 sentinel `["DOCUMENT_ROOT"]`。该 token 只表示
“首个来源标题之前的文档根”，不是来源标题、摘要或模型生成文本；UI 必须展示为
本地化“文档根”标签，不能冒充原文。这样在不修改 D02 block 的前提下满足现有
EvidenceReference `minItems=1`。

## 7. 错误与拒绝

```text
REFERENCE_NOT_FOUND
REFERENCE_SCOPE_MISMATCH
REFERENCE_ALIAS_CONFLICT
PARTIAL_ACCEPTANCE_REQUIRED
LINEAGE_REVISION_SCOPE_MISMATCH
LINEAGE_COVERAGE_INVALID
LINEAGE_CARDINALITY_INVALID
LINEAGE_AMBIGUOUS
HISTORICAL_RETARGET_FORBIDDEN
```

错误必须包含请求的 alias/tuple、固定 revision context 和稳定错误码，但不得包含
原始全文、外部 target 或本地绝对路径。`LINEAGE_AMBIGUOUS` 是可见未决结果，
不是系统异常，也不能触发自动 retarget。

## 8. 代码与模型职责

后续实现获准时，确定性代码负责 tuple/alias、作用域解析、revision 幂等、hash 与
anchor 对比、lineage 基数/覆盖和 Schema 兼容验证。

Wave 1 不调用 LLM。模型不得生成引用、决定 lineage、打置信分、解决歧义、迁移
EvidenceReference 或补齐根章节。

## 9. 不变量与验收

以下任一情况必须使 Gate 或后续实现失败：

1. 历史 alias/tuple 被 active revision 静默替换。
2. 新 parser profile 覆盖或复用旧 revision 身份。
3. 新 revision 复用旧 `documentBlockId`。
4. lineage 漏块、重复块、基数错误或跨 SourceDocument。
5. `AMBIGUOUS` 被模型、分数或 selector 自动裁决。
6. `REMOVED` 删除旧块或使旧引用转向新块。
7. EvidenceReference 复制全文、使用 active selector 或写回 Wave 1 block。
8. 空 section path 被静默编造为来源标题。
9. 正式数据库、业务代码、LLM 或远程写入被本设计授权。

验收命令：

```bash
bash tests/contracts/wave1-design/verify-reparse-reference-contract.sh
bash tests/contracts/wave1-design/verify-document-block-contract.sh
bash tests/contracts/wave1-design/verify-source-document-contract.sh
bash tests/task-cards/verify-wave1-design-cards.sh
bash tests/ci/verify-markdown-links.sh
git diff --check
```
