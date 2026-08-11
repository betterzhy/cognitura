# W1-I10 Source Preview Query API

```text
TaskCardID = W1-I10
CardKind = IMPLEMENTATION
Status = BLOCKED_BY_DEPENDENCY
Gate = W1-IG10 SourcePreviewQueryApi
Risk = HIGH
DependsOn = W1-I08,W1-I09
PrimaryBoundary = SOURCE_HTTP_QUERY
ProductionFileLimit = 8
ProductionWriteSetException = NONE
BusinessImplementationAuthorization = REQUIRED_BEFORE_READY
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
```

## 1. 目标

实现 exact-revision keyset 来源预览查询、revision-bound cursor、typed payload allowlist
和 partial 标识；查询层只投影正式来源事实。

## 2. 前置条件与输入

- I08、I09 均 DONE，稳定引用和命令边界固定。
- 服从正式 source preview 合同与 Workspace 防枚举规则。
- 不创建 Renderer、摘要、来源推断或 Web 页面。

## 3. 写集

```text
WriteSet = server/src/main/java/io/cognitura/source/api/query/SourcePreviewController.java
WriteSet = server/src/main/java/io/cognitura/source/api/query/SourcePreviewQuery.java
WriteSet = server/src/main/java/io/cognitura/source/api/query/SourcePreviewCursor.java
WriteSet = server/src/main/java/io/cognitura/source/api/query/SourcePreviewPage.java
WriteSet = server/src/main/java/io/cognitura/source/api/query/SourceBlockPayload.java
WriteSet = server/src/main/java/io/cognitura/source/api/query/SourcePreviewErrorAdvice.java
WriteSet = server/src/test/java/io/cognitura/source/api/query/SourcePreviewControllerTest.java
WriteSet = server/src/test/java/io/cognitura/source/api/query/SourcePreviewCursorTest.java
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/api/command/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/api/acceptance/**
ForbiddenWriteSet = server/src/main/resources/db/migration/**
ForbiddenWriteSet = web/**,raw/**,.idea/**
ForbiddenWriteSet = RENDERER_SUMMARY_OR_SECOND_SOURCE_FACTS
```

## 4. 执行步骤

1. RED：跨 revision cursor、伪造 Workspace、未知 payload type、错序 keyset 和 stale digest 先失败。
2. GREEN：cursor 绑定 revision 与稳定 sort key，只输出 typed allowlist 字段。
3. incomplete/partial 必须来自正式 published revision，不由查询层推断。

## 5. 验证命令

```bash
./mvnw -f server/pom.xml -Dtest='io.cognitura.source.api.query.*Test' test
scripts/verify-wave1-implementation
git diff --check
git status --short
```

## 6. Gate 与完成定义

exact revision、keyset 顺序、cursor 绑定、typed payload、partial 标识和 404 防枚举通过；
不存在命令、acceptance、Renderer、摘要或 Web 写入。

## 7. 提交与审查

```bash
git add server/src/main/java/io/cognitura/source/api/query \
  server/src/test/java/io/cognitura/source/api/query
git commit -m "feat: query exact source previews"
```

固定提交由新的 `deep_reviewer` 审查；零发现 GO 前不得释放 I11/I12。
