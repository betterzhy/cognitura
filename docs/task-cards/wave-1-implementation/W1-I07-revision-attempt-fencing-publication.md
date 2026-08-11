# W1-I07 Revision Attempt Fencing and Publication

```text
TaskCardID = W1-I07
CardKind = IMPLEMENTATION
Status = BLOCKED_BY_DEPENDENCY
Gate = W1-IG7 ProcessingPublication
Risk = HIGH
DependsOn = W1-I02,W1-I04,W1-I05,W1-I06
PrimaryBoundary = SOURCE_APPLICATION
ProductionFileLimit = 8
ProductionWriteSetException = NONE
BusinessImplementationAuthorization = REQUIRED_BEFORE_READY
FormalDatabaseGate = REQUIRED_DEPENDENCY_I02_ONLY
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
TimeoutCasExpectedAttemptStatus = RUNNING
TimeoutCasObservedLeaseExpiry = REQUIRED
```

## 1. 目标

实现 processing revision/attempt 生命周期、lease generation、fenced CAS、候选块 staging、
block-set digest 和单事务发布；本卡是原子发布事实 Owner。

## 2. 前置条件与输入

- I02、I04、I05、I06 全部 DONE。
- 只消费已经固定的持久化端口和 Parser 候选，不修改其实现。
- 正式数据库写入仍未授权；集成测试只使用隔离临时数据库。

## 3. 写集

```text
WriteSet = server/src/main/java/io/cognitura/source/application/processing/ProcessingAttempt.java
WriteSet = server/src/main/java/io/cognitura/source/application/processing/AttemptLease.java
WriteSet = server/src/main/java/io/cognitura/source/application/processing/AttemptFence.java
WriteSet = server/src/main/java/io/cognitura/source/application/processing/CandidateBlockSet.java
WriteSet = server/src/main/java/io/cognitura/source/application/processing/BlockSetDigest.java
WriteSet = server/src/main/java/io/cognitura/source/application/processing/ProcessingPublicationService.java
WriteSet = server/src/main/java/io/cognitura/source/application/processing/ProcessingPublicationPort.java
WriteSet = server/src/test/java/io/cognitura/source/application/processing/ProcessingPublicationIntegrationTest.java
ForbiddenWriteSet = server/src/main/resources/db/migration/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/docx/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/api/**
ForbiddenWriteSet = web/**,raw/**,.idea/**
ForbiddenWriteSet = FORMAL_DATABASE_CONNECTION_OR_WRITE
```

## 4. 执行步骤

1. RED：迟到 attempt、旧 generation、旧 lease、digest 漂移、部分 staging 和重复发布先失败。
2. timeout CAS 负例必须同时固定 `expectedAttemptStatus=RUNNING` 与实际观察的 lease expiry。
3. GREEN：以 fenced CAS 和单事务 publication 使旧结果、部分写和重复提交不可见。

## 5. 验证命令

```bash
./mvnw -f server/pom.xml -Dtest=ProcessingPublicationIntegrationTest test
scripts/verify-wave1-implementation
git diff --check
git status --short
```

## 6. Gate 与完成定义

仅当前 lease/generation 可发布完整 digest-bound block set；迟到、超时、部分写、旧 fence
和 digest 漂移全部 fail closed，且未修改 migration、Parser、HTTP 或 Web。

## 7. 提交与审查

```bash
git add server/src/main/java/io/cognitura/source/application/processing \
  server/src/test/java/io/cognitura/source/application/processing
git commit -m "feat: fence processing publication"
```

固定提交由新的 `deep_reviewer` 审查；零发现 GO 前不得释放引用或 API 卡。
