# W1-I08 Stable Reference, Reparse and Lineage

```text
TaskCardID = W1-I08
CardKind = IMPLEMENTATION
Status = BLOCKED_BY_DEPENDENCY
Gate = W1-IG8 StableReferenceReparse
Risk = HIGH
DependsOn = W1-I07
PrimaryBoundary = SOURCE_REFERENCE
ProductionFileLimit = 8
ProductionWriteSetException = NONE
BusinessImplementationAuthorization = REQUIRED_BEFORE_READY
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
```

## 1. 目标

实现 immutable reference tuple、source-scoped alias、profile 变更重解析与 lineage；
引用解析必须保留历史并拒绝静默替换。

## 2. 前置条件与输入

- I07 已 DONE，published revision 与 block-set digest 可稳定引用。
- 服从正式 reparse/reference 合同；不得从相似文本猜测唯一引用。
- 本卡不修改 Parser、持久化 Schema、HTTP 或页面。

## 3. 写集

```text
WriteSet = server/src/main/java/io/cognitura/source/reference/StableSourceReference.java
WriteSet = server/src/main/java/io/cognitura/source/reference/SourceScopedAlias.java
WriteSet = server/src/main/java/io/cognitura/source/reference/ReparseProfile.java
WriteSet = server/src/main/java/io/cognitura/source/reference/ReparseLineage.java
WriteSet = server/src/main/java/io/cognitura/source/reference/ReferenceResolutionService.java
WriteSet = server/src/main/java/io/cognitura/source/reference/ReferenceResolutionException.java
WriteSet = server/src/test/java/io/cognitura/source/reference/ReferenceResolutionServiceTest.java
WriteSet = server/src/test/java/io/cognitura/source/reference/ReparseLineageTest.java
ForbiddenWriteSet = server/src/main/resources/db/migration/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/docx/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/api/**
ForbiddenWriteSet = web/**,raw/**,.idea/**
ForbiddenWriteSet = ALIAS_RETARGET_OR_CROSS_REVISION_SILENT_REPLACEMENT
```

## 4. 执行步骤

1. RED：alias retarget、跨 source alias、跨 revision 静默替换、歧义自动裁决先失败。
2. GREEN：固定 immutable tuple 和 lineage edge，只允许 source-scoped 显式解析。
3. profile 变更必须创建新 revision/lineage，不覆盖历史引用。

## 5. 验证命令

```bash
./mvnw -f server/pom.xml -Dtest='io.cognitura.source.reference.*Test' test
scripts/verify-wave1-implementation
git diff --check
git status --short
```

## 6. Gate 与完成定义

稳定 tuple、alias scope、profile lineage 与历史保留全部通过；retarget、静默替换和歧义
自动决策均 fail closed，不含 Schema、Parser、HTTP 或 Web 改动。

## 7. 提交与审查

```bash
git add server/src/main/java/io/cognitura/source/reference \
  server/src/test/java/io/cognitura/source/reference
git commit -m "feat: preserve source reference lineage"
```

固定提交由新的 `deep_reviewer` 审查；零发现 GO 前不得释放依赖卡。
