# Cognitura W1-I09 真实命令运行时重基线设计

```text
CanonicalProjectName = Cognitura
DesignDate = 2026-08-22
DesignStatus = APPROVED_FOR_IMPLEMENTATION_PLANNING
ChangeRisk = R2
ModelRoute = SOL_HIGH_IMPLEMENTATION_AND_SOL_XHIGH_FIXED_CANDIDATE_REVIEW
Authority = USER_AUTHORIZED_CONTINUOUS_EXECUTION
SupersedesI09ExactEight = YES_AFTER_REBASELINE_GATE
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
RawFormalInputAccess = FORBIDDEN
```

## 1. 问题与裁决

当前 `W1-I09` 的八文件 WriteSet 只能创建 Controller、DTO、Advice 和 MockMvc
测试。它无法履行 W1-D04 已固定的真实命令语义：

- Workspace/actor 必须来自服务器可信上下文，不能由 body、query 或任意 header
  自报；
- 上传输入必须被流式读取一次，由服务器计算真实长度和 SHA-256；
- 原始字节必须进入真实、不可变的二进制存储；
- SourceDocument、SourceBinary、revision 和 attempt 必须在 PostgreSQL 中按正式
  幂等、事务和 fencing 语义落地；
- HTTP 成功只能表示真实命令已经被原子接受，不能由测试 fake 或内存 map 伪造。

因此，不按原八文件 WriteSet 实施 I09。该做法会得到“HTTP 合同测试通过、生产命令
不可运行”的假完成。

本设计选择一个最小的、个人开发者友好的真实运行时：

```text
TrustedIdentityProvider = SERVER_OWNED_LOCAL_CONFIGURATION
BinaryStorageProvider = LOCAL_CONTENT_ADDRESSED_FILESYSTEM
CommandDatabase = POSTGRESQL_18
DatabaseVerification = EPHEMERAL_TESTCONTAINERS_ONLY
ApplicationShape = MODULAR_MONOLITH
I09GovernanceShape = ONE_CARD_FOUR_INTERNAL_BATCHES_ONE_FINAL_REVIEW
```

不引入 MinIO/S3、认证平台、微服务、消息总线、Outbox、调度器、通用 Harness、第二套
执行账本或 H2。以后若部署环境需要远程对象存储或用户认证，只替换端口适配器，不改
HTTP 与领域语义。

## 2. 为什么保持一张 I09 卡

I09 是“上传与处理命令”这一条完整用户旅程。可信上下文、二进制存储、事务命令和
HTTP 接口不是四个独立产品能力，而是同一个命令入口从不可信网络输入到权威事实的
连续安全边界。

为避免治理偏重：

- 不新增 I09A/I09B/I09C 卡，不修改 Wave 1 的 14 卡身份；
- 不创建子卡状态机、Registry 或第二套 Active/READY/DONE 事实；
- 只对现有 I09 做一次 append-only Authority 重基线；
- 重基线后的卡固定一个累计 Exact WriteSet，并按四个内部批次执行；
- 每批只跑最接近的 RED/GREEN 与受影响回归；稳定后只做一次完整 Gate 和一次
  `deep_reviewer / sol xhigh` 固定候选审查。

I09 在重基线 Gate 完成前不得编写业务代码。重基线完成后仍是唯一 READY 卡。

## 3. 可信本地请求上下文

新增一个小型应用边界：

```text
TrustedRequestContext = workspaceId + actorId
TrustedRequestContextSource = SERVER_CONFIGURATION_ONLY
ClientSuppliedWorkspaceContext = FORBIDDEN
ClientSuppliedActor = FORBIDDEN
PathWorkspaceMustEqualTrustedWorkspace = YES
```

V1 单用户本地部署从服务器配置读取固定 `workspaceId` 和 `actorId`。配置启动时完成
非空、长度和安全字符校验；请求期间只读取不可变对象。Controller 不接受 body/query/
任意 header 中的 actor 或可信 workspace 字段。

上传 URL 仍包含正式契约要求的 `{workspaceId}`，但它只是路由和显式 scope，必须与
可信上下文精确相等。其余 source/revision 路径先按可信 workspace 做作用域查询；
不可见与不存在返回同一 404 模板。

该边界刻意不实现登录、Session、JWT、RBAC 或多租户管理。未来认证实现只需提供同一
可信上下文接口。

## 4. 本地内容寻址二进制存储

V1 选择生产可用的本地文件系统 Provider：

```text
BinaryIdentity = SHA256_OF_ACTUAL_BYTES
BinaryLocation = cas-file:sha256:<64-lowercase-hex>
StorageRoot = SERVER_CONFIGURATION_ONLY
StoragePath = <root>/sha256/<h0h1>/<h2h3>/<full-hash>.blob
TemporaryPath = SAME_FILESYSTEM_PRIVATE_TEMP_FILE
Finalization = ATOMIC_MOVE_NO_REPLACE
ExternalPathInput = FORBIDDEN
SymlinkTraversal = FORBIDDEN
```

写入算法：

1. 在配置根下受控临时目录创建仅当前进程可写的临时文件；
2. 从一次性输入流逐块复制，同时计算真实长度与 SHA-256，并在超过 raw byte limit 时
   立即终止；
3. 校验非空、媒体类型、声明长度和声明哈希；声明值不参与真实身份计算；
4. 关闭流和临时文件后，在同一文件系统内原子移动到 digest 路径；
5. 目标已存在时，只读校验其长度与摘要后复用；不覆盖、不修改；
6. 任意失败删除本次临时文件，保留已存在的不可变目标。

不接受调用方文件路径，不跟随 DOCX 外链，不把绝对路径、存储根或临时名写入 DTO、
日志和安全错误信息。读取只允许由经过校验的内部 `BinaryLocation`/digest 派生路径。

如果文件系统不支持同卷原子移动，启动或写入必须 fail closed；不以 copy+delete
伪装原子发布。

## 5. 上传应用事务

命令入口接收可信上下文、幂等键、文件名、声明 metadata 和一次性输入流。

流程：

1. 前置校验可信 workspace、canonical DOCX media type、幂等键和声明上限；
2. 流式写入内容寻址存储，得到服务器验证的 digest、长度和内部 location；
3. 在一个 PostgreSQL 事务中读取 `(workspaceId,idempotencyKey)`、digest 对应 binary，
   并按 W1-D01 创建或复用 `SourceBinary` 与 `SourceDocument`；
4. 同 key/同真实 hash 返回幂等 replay；同 key/不同真实 hash 返回冲突；
5. 提交后才生成 201/200 结果。

数据库是逻辑登记事实的 Authority；内容存储保存不可变字节。数据库事务失败时不删除
已经按 digest 完成的 blob，因为并发命令可能已经复用它。未被数据库引用的 blob 是
安全、无权威性的 orphan；本卡不为极低概率 orphan 引入引用计数、后台 scheduler 或
第二套恢复框架。未来如出现真实容量压力，再单独设计离线清理命令。

现有 `SourcePreRegistrationPolicy` 的 `byte[]` API 不用于新流式路径；不得先把整个
上传读进内存再调用它。新应用服务复用同一正式不变量，但以服务器验证后的二进制描述
和事务端口作为输入。旧策略保留供既有领域测试，不在 I09 中静默改写历史候选。

## 6. Processing 命令事务

I07 已固定 attempt/lease/fencing/publication 领域协议，但当前只有测试内 JDBC
适配器。I09 必须补齐生产 PostgreSQL Adapter 和 Flyway migration，HTTP 才能真实
接受 processing 命令。

Processing 命令在可信 workspace 内：

1. 以 workspace scope 查询 SourceDocument；不存在和跨 workspace 使用同一 404；
2. 要求来源已 `ACCEPTED`；
3. 对 `(sourceDocumentId,contentSha256,parserProfileVersion)` 执行事务判定；
4. 不存在时原子创建 revision 和 initial attempt，返回 202；
5. 已成功或 terminal 时返回相同 revision 的 200/reused；
6. retryable 时在同 revision 下创建 generation+1 的新 attempt，返回 202；
7. 并发命令只能产生一个获接受 attempt，失败竞争者读取并返回同一权威结果；
8. 503 只用于事务未接受任何 revision/attempt 的基础设施失败，不返回 poll revision。

生产 Adapter 实现 I07 的 fencing/CAS/lease/staging/publication 契约；不复制一套简化
状态机。migration 只增加实现该协议所需的 attempt、lease、staging、publication、
alias 和 stage-record 事实，并与既有 revision identity 关联。

## 7. 数据库 Gate

I09 重基线引入新 migration，属于 R2。它需要一个独立的 schema Gate，但不授权正式
数据库写入：

```text
I09FormalDatabaseGate = REQUIRED_BEFORE_PRODUCT_GREEN
AllowedDatabase = EPHEMERAL_POSTGRESQL_18_TESTCONTAINER
PinnedImage = TECHNOLOGY_BASELINE_POSTGRESQL_18_DIGEST
ContainerReuse = FALSE
H2 = FORBIDDEN
FormalDatabaseConnection = FORBIDDEN
DestructionProof = REQUIRED
```

Gate 必须验证 migration 从空库执行、约束/索引、事务 rollback、幂等 replay、并发
attempt、fencing CAS 和容器销毁。任何真实用户数据库、共享开发库或外部数据库连接
均不在授权范围。

## 8. HTTP 边界

真实应用服务和生产适配器存在后，才实现原 I09 的 Controller/DTO/Advice：

- multipart binary 直接传入一次性流式端口，不构造完整 `byte[]` DTO；
- body 只允许正式字段；出现 workspace/actor/internal ID/storage/fencing 字段即 400；
- 新来源 201，幂等 replay 200；新/retry attempt 202，既有成功/terminal 200；
- processing 的 pollLocation 绑定 exact revision；
- 错误响应精确为五字段 allowlist；
- 404 永远不回显 source/revision ID，且跨 workspace 与不存在 shape、code、message
  相同；
- DTO 和日志不得出现文件系统路径、binary location、attempt token、lease、SQL、
  stack trace 或原始字节。

MockMvc 合同测试可以在边界层使用受控 stub 来枚举 HTTP 分支，但不能作为产品完成
证据。完成证据必须额外包含同一生产应用服务连接真实临时目录与 PostgreSQL 18
容器的端到端集成测试。

## 9. I09 内部实施批次

```text
BatchA = TRUSTED_CONTEXT_AND_LOCAL_CAS
BatchB = STREAMING_UPLOAD_APPLICATION_TRANSACTION
BatchC = POSTGRES_PROCESSING_COMMAND_ADAPTER
BatchD = HTTP_COMMAND_BOUNDARY
```

每批先提交能证明正式失败模式的 RED，再写最小 GREEN；后批依赖前批。批次只是 I09
内的实现顺序，不拥有 READY/DONE 状态，不产生独立关闭回执。

累计 WriteSet 必须在实施计划中逐文件固定，并至少覆盖：

- `source/application/context/**`
- `source/storage/**`
- `source/application/command/**`
- `source/persistence/**` 中新增/明确修改的 mapper、adapter 与 transaction wiring
- `source/api/command/**`
- 新 Flyway migration
- 对应 unit、真实 filesystem、PostgreSQL Testcontainers 和 MockMvc 测试
- 最小 Spring 配置/wiring

不得使用目录级 wildcard 暂存；最终任务卡仍逐文件列出 Exact WriteSet。

## 10. 验收与停止条件

I09 只有同时满足以下条件才可关闭：

1. 可信 workspace/actor 无客户端自报入口；
2. 大于测试缓冲区的 DOCX 输入被一次流式消费，真实长度/SHA 与声明不一致时失败；
3. 本地 CAS 在真实临时目录验证原子发布、不可变复用、无路径穿越/符号链接逃逸和
   失败临时文件清理；
4. 上传幂等和 logical registration 在真实 PostgreSQL 18 事务中通过并发测试；
5. processing new/retry/reuse/terminal、lease/fencing/CAS/rollback 在生产 Adapter
   上通过真实 PostgreSQL 18 容器测试；
6. HTTP 状态、DTO allowlist、统一 404 和安全错误全部通过；
7. 完整 Wave Gate exit 0，固定 Candidate/Parent/Tree 完整；
8. 一次 `deep_reviewer / sol xhigh` 得到 `GO, P0=0, P1=0, P2=0`；
9. `FormalDatabaseWrite=NOT_AUTHORIZED`、`RemotePush=NOT_AUTHORIZED`、`raw/**` 和
   `.idea/**` 始终不变。

出现以下任一情况立即停止产品实现并回到设计：需要正式外部数据库、远程对象存储、
认证/授权平台、WriteSet 超出计划、必须修改 D01-D04 正式语义、无法在容器重现事务
行为，或需要把 test fake 当作生产 Adapter。

## 11. 明确不做

- 不接入 omini-harness 或新建项目级 Harness；
- 不引入 MinIO、S3、Redis、Kafka、Outbox、Worker 调度平台或微服务；
- 不实现查询、partial acceptance、Web 页面、Parser 编排或异步执行器；
- 不实现 blob 引用计数、垃圾回收服务、存储迁移框架或多 Provider registry；
- 不修改历史固定候选，不重写 I07 test-local 证据；
- 不访问 Golden Case 原件，不连接正式数据库，不 deploy，不 push。
