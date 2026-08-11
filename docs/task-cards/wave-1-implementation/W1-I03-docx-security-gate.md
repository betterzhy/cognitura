# W1-I03 DOCX Security Gate

```text
TaskCardID = W1-I03
CardKind = IMPLEMENTATION
Status = BLOCKED_BY_DEPENDENCY
Gate = W1-IG3 DocxSecurity
Risk = HIGH
DependsOn = W1-I01
PrimaryBoundary = DOCX_SECURITY
ProductionFileLimit = 8
ProductionWriteSetException = NONE
PositiveVerification = SAFE_SYNTHETIC_DOCX_PACKAGE_ACCEPTED
NegativeVerification = ZIP_XML_LIMIT_AND_EXTERNAL_RELATIONSHIP_REJECTION
BusinessImplementationAuthorization = REQUIRED_BEFORE_READY
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
ExternalRelationshipAccessCount = 0
```

## 1. 目标

实现 DOCX ZIP/XML/relationship 安全分类、资源上限和外部关系零访问保护；本卡只负责
拒绝或安全分类输入，不生成 `DocumentBlock`。

## 2. 前置条件与输入

- I01 已 DONE，且业务实现授权仍有效。
- 使用合成 DOCX/ZIP 恶意 fixture；不得打开 `raw/**` 原件。
- 不访问 Redis 文档遗留链接或任何外部 relationship 目标。

## 3. 写集

```text
WriteSet = server/src/main/java/io/cognitura/source/docx/security/DocxSecurityGate.java
WriteSet = server/src/main/java/io/cognitura/source/docx/security/DocxPackageLimits.java
WriteSet = server/src/main/java/io/cognitura/source/docx/security/DocxRelationshipClassifier.java
WriteSet = server/src/main/java/io/cognitura/source/docx/security/DocxSecurityViolation.java
WriteSet = server/src/main/java/io/cognitura/source/docx/security/SafeDocxPackage.java
WriteSet = server/src/test/java/io/cognitura/source/docx/security/DocxSecurityGateTest.java
WriteSet = server/src/test/java/io/cognitura/source/docx/security/ExternalRelationshipIsolationTest.java
WriteSet = server/src/test/resources/docx/security/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/docx/text/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/docx/table/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/docx/image/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/persistence/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/api/**
ForbiddenWriteSet = web/**,raw/**,.idea/**
```

## 4. 执行步骤

1. RED：ZIP bomb、超限 entry、DTD/XXE、路径穿越、外链 file/http 和未知关系先失败。
2. GREEN：实现闭集资源预算、禁用外部实体和只投影 relationship 字面元数据。
3. 用 stat/DNS/file-read/network canary 证明外部目标访问次数为 0。

## 5. 验证命令

```bash
./mvnw -f server/pom.xml -Dtest='io.cognitura.source.docx.security.*Test' test
scripts/verify-wave1-implementation
git diff --check
git status --short
```

## 6. Gate 与完成定义

所有恶意 fixture 确定性拒绝，合法合成包安全开放，外部目标观测访问数严格为 0；
不生成块、不访问原件、不混入 Persistence、HTTP 或 Web。

## 7. 提交与审查

```bash
sed -n 's/^WriteSet = //p' \
  docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md |
  git add --pathspec-from-file=-
git diff --cached --name-only
git commit -m "feat: enforce DOCX package security"
```

暂存清单必须与本卡 WriteSet 双向精确一致；目录级 `git add` 禁止。固定提交交给新的
`deep_reviewer`；零发现 GO 前不得释放 Parser 卡。
