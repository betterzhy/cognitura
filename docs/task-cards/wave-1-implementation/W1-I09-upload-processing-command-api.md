# W1-I09 Real Upload and Processing Command Runtime

```text
TaskCardID = W1-I09
CardKind = IMPLEMENTATION
Status = READY
Gate = W1-IG9 UploadProcessingCommandApi
Risk = HIGH
DependsOn = W1-I07
PrimaryBoundary = SOURCE_COMMAND_RUNTIME
ProductionFileLimit = 20
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
WriteSet = server/src/main/java/io/cognitura/source/application/processing/CandidateBlockSet.java
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

暂存清单必须与 28 路径双向一致。只进行一次适用的 `deep_reviewer / sol xhigh`；
零 finding GO 前不关闭 I09、不释放 I10。
