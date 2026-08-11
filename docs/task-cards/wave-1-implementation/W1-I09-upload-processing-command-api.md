# W1-I09 Upload and Processing Command API

```text
TaskCardID = W1-I09
CardKind = IMPLEMENTATION
Status = BLOCKED_BY_DEPENDENCY
Gate = W1-IG9 UploadProcessingCommandApi
Risk = HIGH
DependsOn = W1-I07
PrimaryBoundary = SOURCE_HTTP_COMMAND
ProductionFileLimit = 8
ProductionWriteSetException = NONE
PositiveVerification = AUTHORIZED_UPLOAD_AND_PROCESSING_COMMAND_ACCEPTED
NegativeVerification = WORKSPACE_ENUMERATION_INTERNAL_LEAK_AND_INVALID_COMMAND_REJECTED
BusinessImplementationAuthorization = REQUIRED_BEFORE_READY
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
```

## 1. 目标

实现上传与创建 processing revision 的命令 HTTP 边界、稳定接受结果和错误闭集；不实现
预览查询、partial acceptance 或 Web。

## 2. 前置条件与输入

- I07 已 DONE，应用服务和 publication 端口固定。
- Workspace/actor 必须来自可信上下文，不接受请求体自报。
- 遵循 404 防枚举和内部字段不泄漏合同。

## 3. 写集

```text
WriteSet = server/src/main/java/io/cognitura/source/api/command/SourceUploadController.java
WriteSet = server/src/main/java/io/cognitura/source/api/command/ProcessingCommandController.java
WriteSet = server/src/main/java/io/cognitura/source/api/command/SourceUploadRequest.java
WriteSet = server/src/main/java/io/cognitura/source/api/command/ProcessingCommandRequest.java
WriteSet = server/src/main/java/io/cognitura/source/api/command/CommandAcceptedResponse.java
WriteSet = server/src/main/java/io/cognitura/source/api/command/SourceCommandErrorAdvice.java
WriteSet = server/src/test/java/io/cognitura/source/api/command/SourceUploadControllerTest.java
WriteSet = server/src/test/java/io/cognitura/source/api/command/ProcessingCommandControllerTest.java
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/api/query/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/api/acceptance/**
ForbiddenWriteSet = server/src/main/resources/db/migration/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/docx/**
ForbiddenWriteSet = web/**,raw/**,.idea/**
```

## 4. 执行步骤

1. RED：伪造 Workspace、跨 Workspace ID、缺失文件、重复幂等键和内部字段泄漏先失败。
2. GREEN：只把可信上下文和 allowlisted payload 交给固定应用端口。
3. 对不可见与不存在资源统一 404；错误响应只使用正式错误码闭集。

## 5. 验证命令

```bash
./mvnw -f server/pom.xml -Dtest='io.cognitura.source.api.command.*Test' test
scripts/verify-wave1-implementation
git diff --check
git status --short
```

## 6. Gate 与完成定义

上传与 processing 命令正例、可信上下文、幂等、404 防枚举和字段 allowlist 全部通过；
无 query、partial acceptance、Parser、migration 或 Web 写入。

## 7. 提交与审查

```bash
sed -n 's/^WriteSet = //p' \
  docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md |
  git add --pathspec-from-file=-
git diff --cached --name-only
git commit -m "feat: add source processing commands"
```

暂存清单必须与本卡 WriteSet 双向精确一致；目录级 `git add` 禁止。固定提交由新的
`deep_reviewer` 审查；零发现 GO 前不得释放后继。
