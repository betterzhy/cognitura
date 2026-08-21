# W1-I09 运行时重基线审查 Finding 修复

```text
RepairStatus = APPROVED_APPEND_ONLY
RejectedCandidate = 40bd055047479db91d618320f1ff569e3c651c77
RejectedParent = 3f27cec841ef6b781e70af4b6581cfbb12c2a5c3
RejectedTree = 48b60d01cfe8a7b5334d4614420a67446d776790
RejectedReviewVerdict = NO_GO
RejectedReviewP0 = 0
RejectedReviewP1 = 2
RejectedReviewP2 = 0
CorrectionChain = THIS_SPEC -> TEST -> VERIFIER
CorrectionReview = ONE_DEEP_REVIEWER_SOL_XHIGH
Ultra = NOT_RUN
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. Finding

被拒候选只验证到 `PENDING_PROJECTION`，没有可达的五路径 Authority projection
或投影后的 27 路径产品后代；两个正例也都是待投影链。它还允许未绑定的任意
test/verifier 尾提交，不能证明 successor 继承被审 Candidate/Parent/Tree。

## 2. 最小修复

1. 把 `40bd055...` 的 Candidate/Parent/Tree 固定为拒绝历史，不接受等价替代。
2. 从该候选只允许本 spec、测试、verifier 三个单父、非空、单路径、正确 mode、
   无 R/C/NUL 的修复步骤；spec/test evidence blob 固定。
3. 最终 verifier correction 由新的 `deep_reviewer / sol xhigh` 绑定
   Candidate/Parent/Tree。普通仓内 receipt 不自证审查真实性；该外部审查是非递归
   信任根。
4. GO 后只允许 correction tip 的一个直接五路径 projection；其余字节由从
   correction tip 物化的确定性变换逐字比较。
5. projection 后只允许任务卡下列 27 个精确路径的单父、非空、无 R/C/NUL 后代。
6. focused 合同至少覆盖：待投影、合法投影、合法产品后代，以及错误收据、投影路径、
   READY/card count、DB/push、I08 漂移、WriteSet 漂移、产品越界和 formal/raw/.idea
   越界。

## 3. Authority projection

精确五路径：

```text
docs/engineering/cognitura-technology-baseline.md
docs/engineering/cognitura-design-index.md
docs/engineering/cognitura-wave-1-design-acceptance.md
docs/engineering/cognitura-wave-1-implementation-plan.md
docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md
```

前四个文件只在 correction tip 的原字节后追加一个唯一终端块。I09 卡必须逐字等于
下方 canonical card（不含 `I09_CANONICAL_CARD_BEGIN/END` 标记）。

I09_CANONICAL_CARD_BEGIN
# W1-I09 Real Upload and Processing Command Runtime

```text
TaskCardID = W1-I09
CardKind = IMPLEMENTATION
Status = READY
Gate = W1-IG9 UploadProcessingCommandApi
Risk = HIGH
DependsOn = W1-I07
PrimaryBoundary = SOURCE_COMMAND_RUNTIME
ProductionFileLimit = 19
ProductionWriteSetException = EXACT_REBASELINED_VERTICAL_SLICE
PositiveVerification = REAL_STREAMING_UPLOAD_AND_PROCESSING_COMMAND_ACCEPTED
NegativeVerification = TRUST_STORAGE_TRANSACTION_ENUMERATION_AND_INTERNAL_LEAK_REJECTED
BusinessImplementationAuthorization = USER_AUTHORIZED
FormalDatabaseGate = PASS
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
```

## 1. 目标

实现一个真实可运行的本地优先上传与 processing 命令纵向切片：服务器可信上下文、
一次性流式输入、本地内容寻址存储、PostgreSQL 18 事务与 fencing/publication 端口，
以及 W1-D04 HTTP 边界。不以 fake、内存 map 或仅 MockMvc 通过冒充产品完成。

## 2. 前置条件与输入

- I07、I08 已 DONE；本卡是唯一 READY。
- 本地文件系统 Provider 只保存 immutable digest bytes；客户端不提供路径。
- PostgreSQL 仅使用固定 digest、reuse=false 的隔离 Testcontainer 验证；正式数据库
  写入仍未授权。
- Workspace/actor 只来自服务器配置的可信上下文。

## 3. 写集

```text
WriteSet = server/src/main/java/io/cognitura/source/application/command/TrustedRequestContext.java
WriteSet = server/src/main/java/io/cognitura/source/application/command/TrustedRequestContextProvider.java
WriteSet = server/src/main/java/io/cognitura/source/application/command/SourceBinaryStore.java
WriteSet = server/src/main/java/io/cognitura/source/application/command/SourceCommandPersistencePort.java
WriteSet = server/src/main/java/io/cognitura/source/application/command/SourceCommandService.java
WriteSet = server/src/main/java/io/cognitura/source/application/command/SourceCommandException.java
WriteSet = server/src/main/java/io/cognitura/source/storage/LocalContentAddressedSourceBinaryStore.java
WriteSet = server/src/main/java/io/cognitura/source/persistence/SourceCommandMapper.java
WriteSet = server/src/main/java/io/cognitura/source/persistence/SourceCommandPersistenceAdapter.java
WriteSet = server/src/main/java/io/cognitura/source/persistence/JdbcProcessingPublicationPort.java
WriteSet = server/src/main/java/io/cognitura/source/runtime/SourceCommandRuntimeConfiguration.java
WriteSet = server/src/main/resources/db/migration/V2__create_source_command_runtime.sql
WriteSet = server/src/main/resources/application.yaml
WriteSet = server/src/main/java/io/cognitura/source/api/command/SourceUploadController.java
WriteSet = server/src/main/java/io/cognitura/source/api/command/ProcessingCommandController.java
WriteSet = server/src/main/java/io/cognitura/source/api/command/SourceUploadRequest.java
WriteSet = server/src/main/java/io/cognitura/source/api/command/ProcessingCommandRequest.java
WriteSet = server/src/main/java/io/cognitura/source/api/command/CommandAcceptedResponse.java
WriteSet = server/src/main/java/io/cognitura/source/api/command/SourceCommandErrorAdvice.java
WriteSet = server/src/test/java/io/cognitura/source/application/command/TrustedRequestContextTest.java
WriteSet = server/src/test/java/io/cognitura/source/storage/LocalContentAddressedSourceBinaryStoreTest.java
WriteSet = server/src/test/java/io/cognitura/source/application/command/SourceUploadCommandIntegrationTest.java
WriteSet = server/src/test/java/io/cognitura/source/persistence/JdbcProcessingPublicationPortIntegrationTest.java
WriteSet = server/src/test/java/io/cognitura/source/runtime/SourceCommandRuntimeIntegrationTest.java
WriteSet = server/src/test/java/io/cognitura/source/api/command/SourceUploadControllerTest.java
WriteSet = server/src/test/java/io/cognitura/source/api/command/ProcessingCommandControllerTest.java
WriteSet = server/src/test/resources/db/source-command-runtime-fixture.sql
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/api/query/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/api/acceptance/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/docx/**
ForbiddenWriteSet = web/**,raw/**,.idea/**
ForbiddenWriteSet = FORMAL_DATABASE_CONNECTION_OR_WRITE
```

## 4. 执行步骤

1. RED/GREEN：可信 context 与真实临时目录 CAS。
2. RED/GREEN：流式上传与 PostgreSQL 事务幂等。
3. RED/GREEN：生产 JDBC/MyBatis publication port、lease/fencing/CAS/rollback。
4. RED/GREEN：真实 runtime wiring 后实现 HTTP allowlist 与统一 404。

## 5. 验证命令

```bash
./mvnw -f server/pom.xml -Dtest='io.cognitura.source.*.*Test' test
./mvnw -f server/pom.xml test
scripts/verify-wave1-implementation
git diff --check
git status --short
```

## 6. Gate 与完成定义

真实 filesystem、PostgreSQL 18 container、streaming、transaction、concurrency、HTTP
合同与完整 Wave Gate 全部完整退出 0；固定候选取得一次 xhigh 零 finding GO。正式
数据库、部署、push、query/acceptance/Web/Parser 编排不在本卡。

## 7. 提交与审查

FixedCommitReviewGate = NEW_DEEP_REVIEWER_ZERO_FINDING_BEFORE_SUCCESSOR_RELEASE

```bash
sed -n 's/^WriteSet = //p' \
  docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md |
  git add --pathspec-from-file=-
git diff --cached --name-only
git commit -m "feat: add real source command runtime"
```

暂存清单必须与 27 路径双向一致。只进行一次适用的 `deep_reviewer / sol xhigh`；
零 finding GO 前不关闭 I09、不释放 I10。
I09_CANONICAL_CARD_END

## 4. 非递归审查边界

最终 correction verifier 无法在自身内部证明自身已被人类/模型审查。新的 xhigh
审查绑定该 Candidate/Parent/Tree 后即形成外部信任根；projection receipt 记录
`ReviewedRejectedCandidate` 与 `ReviewedVerifierCorrectionCandidate` 两组身份。
不再增加“验证 correction verifier 的 verifier”。
