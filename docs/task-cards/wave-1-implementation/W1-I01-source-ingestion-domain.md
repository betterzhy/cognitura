# W1-I01 Source Ingestion Domain

```text
TaskCardID = W1-I01
CardKind = IMPLEMENTATION
Status = DONE
Gate = W1-IG1 SourceIntakeDomain
Risk = HIGH
DependsOn = W1-I00
PrimaryBoundary = SOURCE_DOMAIN
ProductionFileLimit = 8
ProductionWriteSetException = NONE
PositiveVerification = IDEMPOTENT_SAME_WORKSPACE_SAME_DIGEST
NegativeVerification = DIGEST_IDENTITY_LIFECYCLE_AND_WORKSPACE_CONFLICTS
BusinessImplementationAuthorization = USER_AUTHORIZED
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
```

## 1. 目标

实现来源预注册、SHA-256、`SourceDocument`、`SourceBinary`、`ProcessingRevision` 身份、
幂等裁决和不可变领域状态；本卡只拥有领域内核。

## 2. 前置条件与输入

- I00 已 DONE，用户另行明确授权 I01。
- 服从 `cognitura-source-document-contract-1.0.md`。
- 只使用内存端口替身，不读取 Golden Case 原件或外部关系目标。

## 3. 写集

```text
WriteSet = server/src/main/java/io/cognitura/source/domain/SourceDocument.java
WriteSet = server/src/main/java/io/cognitura/source/domain/SourceBinary.java
WriteSet = server/src/main/java/io/cognitura/source/domain/ProcessingRevision.java
WriteSet = server/src/main/java/io/cognitura/source/domain/SourcePreRegistrationPolicy.java
WriteSet = server/src/main/java/io/cognitura/source/domain/SourceHash.java
WriteSet = server/src/main/java/io/cognitura/source/domain/SourceDomainException.java
WriteSet = server/src/test/java/io/cognitura/source/domain/SourcePreRegistrationPolicyTest.java
WriteSet = server/src/test/java/io/cognitura/source/domain/SourceLifecycleTest.java
ForbiddenWriteSet = server/src/main/resources/db/migration/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/persistence/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/docx/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/api/**
ForbiddenWriteSet = web/**,raw/**,.idea/**
```

## 4. 执行步骤

1. RED：先写重复 binary、hash 漂移、非法 revision 转换和跨 Workspace 身份冲突测试。
2. GREEN：实现最小不可变类型和预注册裁决，不引入存储或框架注解。
3. 固定领域异常码；不得把数据库错误或 HTTP 状态带入领域层。

## 5. 验证命令

```bash
./mvnw -f server/pom.xml -Dtest='io.cognitura.source.domain.*Test' test
scripts/verify-wave1-implementation
git diff --check
git status --short
```

## 6. Gate 与完成定义

正例证明同一 Workspace/同一 digest 幂等，关键负例证明 digest、身份、生命周期和
Workspace 边界 fail closed；生产文件不超过 8，且无 Persistence、Parser、HTTP、Web。

## 7. 提交与审查

FixedCommitReviewGate = NEW_DEEP_REVIEWER_ZERO_FINDING_BEFORE_SUCCESSOR_RELEASE

```bash
sed -n 's/^WriteSet = //p' \
  docs/task-cards/wave-1-implementation/W1-I01-source-ingestion-domain.md |
  git add --pathspec-from-file=-
git diff --cached --name-only
git commit -m "feat: add source ingestion domain"
```

暂存清单必须与本卡 WriteSet 双向精确一致；目录级 `git add` 禁止。固定提交交给新的
`deep_reviewer`；零发现 GO 前不得释放后继。
