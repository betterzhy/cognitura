# W1-I11 Partial Acceptance Command API

```text
TaskCardID = W1-I11
CardKind = IMPLEMENTATION
Status = BLOCKED_BY_DEPENDENCY
Gate = W1-IG11 PartialAcceptanceCommandApi
Risk = HIGH
DependsOn = W1-I10
PrimaryBoundary = SOURCE_HTTP_COMMAND
ProductionFileLimit = 8
ProductionWriteSetException = NONE
PositiveVerification = EXACT_REVISION_DIGEST_ACTOR_AND_IDEMPOTENCY_CONFIRMATION
NegativeVerification = DIGEST_ACTOR_KEY_AND_REPEAT_CONFLICT_REJECTED
BusinessImplementationAuthorization = REQUIRED_BEFORE_READY
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
```

## 1. 目标

实现绑定 exact revision、block-set digest、omissions digest、可信 actor 和幂等键的
不可逆 partial acceptance 命令。

## 2. 前置条件与输入

- I10 已 DONE，可读取 exact-revision preview 与正式 incomplete 元数据。
- actor/Workspace 来自可信上下文，不能由请求体覆盖。
- 本卡不修改 preview query 或 Web。

## 3. 写集

```text
WriteSet = server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceController.java
WriteSet = server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceRequest.java
WriteSet = server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceCommand.java
WriteSet = server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceService.java
WriteSet = server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptancePort.java
WriteSet = server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceResponse.java
WriteSet = server/src/test/java/io/cognitura/source/api/acceptance/PartialAcceptanceControllerTest.java
WriteSet = server/src/test/java/io/cognitura/source/api/acceptance/PartialAcceptanceServiceTest.java
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/api/query/**
ForbiddenWriteSet = server/src/main/resources/db/migration/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/docx/**
ForbiddenWriteSet = web/**,raw/**,.idea/**
```

## 4. 执行步骤

1. RED：revision、block digest、omissions digest、actor、Workspace 或幂等键漂移先失败。
2. GREEN：以完整 tuple 执行一次性确认；完全相同重放幂等返回原结果。
3. 已确认记录不可撤回或改写，冲突重放返回稳定错误码。

## 5. 验证命令

```bash
./mvnw -f server/pom.xml -Dtest='io.cognitura.source.api.acceptance.*Test' test
scripts/verify-wave1-implementation
git diff --check
git status --short
```

## 6. Gate 与完成定义

完整 digest/actor/idempotency tuple、不可逆性、相同重放和冲突拒绝全部通过；无 query、
Parser、migration 或 Web 改动。

## 7. 提交与审查

```bash
sed -n 's/^WriteSet = //p' \
  docs/task-cards/wave-1-implementation/W1-I11-partial-acceptance-command-api.md |
  git add --pathspec-from-file=-
git diff --cached --name-only
git commit -m "feat: confirm partial source acceptance"
```

暂存清单必须与本卡 WriteSet 双向精确一致；目录级 `git add` 禁止。固定提交由新的
`deep_reviewer` 审查；零发现 GO 前不得释放 I12。
