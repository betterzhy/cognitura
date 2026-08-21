# W1-I02 Source Persistence

```text
TaskCardID = W1-I02
CardKind = IMPLEMENTATION
Status = DONE
Gate = W1-IG2 SourcePersistence
Risk = HIGH
DependsOn = W1-I01
PrimaryBoundary = SOURCE_PERSISTENCE
ProductionFileLimit = 8
ProductionWriteSetException = NONE
PositiveVerification = ISOLATED_DATABASE_UNIQUE_AND_ROUND_TRIP
NegativeVerification = CONSTRAINT_MAPPING_AND_FORMAL_DATABASE_ACCESS_REJECTION
BusinessImplementationAuthorization = USER_AUTHORIZED
FormalDatabaseGate = PASS
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
```

## 1. 目标

在独立数据库 Gate 通过后，实现来源领域对象的 Flyway Schema、MyBatis Mapper 和
仓储端口适配；只负责持久化事实，不实现 Parser、attempt 并发或接口层。

## 2. 前置条件与输入

- I01 已 DONE 且其领域类型固定。
- 数据库 Gate 已对物理 Schema、migration 顺序和隔离测试库给出明确 PASS。
- 正式数据库写入仍未授权，测试仅使用隔离临时 PostgreSQL。

## 3. 写集

```text
WriteSet = server/src/main/resources/db/migration/V1__create_source_intake.sql
WriteSet = server/src/main/java/io/cognitura/source/persistence/SourceDocumentRow.java
WriteSet = server/src/main/java/io/cognitura/source/persistence/SourceBinaryRow.java
WriteSet = server/src/main/java/io/cognitura/source/persistence/ProcessingRevisionRow.java
WriteSet = server/src/main/java/io/cognitura/source/persistence/SourceDocumentMapper.java
WriteSet = server/src/main/java/io/cognitura/source/persistence/SourcePersistenceAdapter.java
WriteSet = server/src/test/java/io/cognitura/source/persistence/SourcePersistenceIntegrationTest.java
WriteSet = server/src/test/resources/db/source-persistence-fixture.sql
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/docx/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/api/**
ForbiddenWriteSet = web/**,raw/**,.idea/**
ForbiddenWriteSet = FORMAL_DATABASE_CONNECTION_OR_WRITE
```

## 4. 执行步骤

1. RED：唯一约束、Workspace 隔离、完整往返映射和重复 migration 负例先失败。
2. GREEN：实现最小 DDL、Mapper 和适配器；不加入 attempt lease 或发布事务。
3. 只在临时数据库运行；记录容器/实例身份和销毁证据。

## 5. 验证命令

```bash
./mvnw -f server/pom.xml -Dtest=SourcePersistenceIntegrationTest test
scripts/verify-wave1-implementation
git diff --check
git status --short
```

## 6. Gate 与完成定义

migration、唯一约束、Workspace 隔离和领域对象往返全部 PASS；无正式数据库副作用，
生产写集不超过 8，且未混入 Parser、HTTP 或 Web。

## 7. 提交与审查

FixedCommitReviewGate = NEW_DEEP_REVIEWER_ZERO_FINDING_BEFORE_SUCCESSOR_RELEASE

```bash
sed -n 's/^WriteSet = //p' \
  docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md |
  git add --pathspec-from-file=-
git diff --cached --name-only
git commit -m "feat: persist source intake records"
```

暂存清单必须与本卡 WriteSet 双向精确一致；目录级 `git add` 禁止。固定提交交给新的
`deep_reviewer`；数据库 Gate 和零发现审查缺一不可。
