# W1-I06 Image Anchor and Relationship Projection

```text
TaskCardID = W1-I06
CardKind = IMPLEMENTATION
Status = BLOCKED_BY_DEPENDENCY
Gate = W1-IG6 ImageRelationshipProjection
Risk = HIGH
DependsOn = W1-I04,W1-I05
PrimaryBoundary = DOCX_IMAGE_PARSER
ProductionFileLimit = 8
ProductionWriteSetException = NONE
PositiveVerification = IMAGE_ANCHOR_MEDIA_REF_AND_LITERAL_RELATIONSHIP_PRESERVED
NegativeVerification = MISSING_MEDIA_HASH_AND_EXTERNAL_TARGET_ACCESS_REJECTED
BusinessImplementationAuthorization = REQUIRED_BEFORE_READY
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
ExternalRelationshipDereference = FORBIDDEN
```

## 1. 目标

实现 inline/table-cell 图片双射、稳定锚点、不可变 media ref、图片 SHA-256 和外部关系
字面值摘要；不负责发布块集。

## 2. 前置条件与输入

- I04、I05 均 DONE，文本与表格锚点顺序固定。
- 只从已安全打开的包读取内嵌 media；外部关系目标永不访问。
- 不把图片 OCR、描述或视觉推断制造成来源事实。

## 3. 写集

```text
WriteSet = server/src/main/java/io/cognitura/source/docx/image/ImageRelationshipProjector.java
WriteSet = server/src/main/java/io/cognitura/source/docx/image/ImageAnchor.java
WriteSet = server/src/main/java/io/cognitura/source/docx/image/ImmutableMediaRef.java
WriteSet = server/src/main/java/io/cognitura/source/docx/image/MediaDigest.java
WriteSet = server/src/main/java/io/cognitura/source/docx/image/ExternalRelationshipLiteral.java
WriteSet = server/src/test/java/io/cognitura/source/docx/image/ImageRelationshipProjectorTest.java
WriteSet = server/src/test/java/io/cognitura/source/docx/image/ExternalRelationshipNoAccessTest.java
WriteSet = server/src/test/resources/docx/image/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/application/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/persistence/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/api/**
ForbiddenWriteSet = web/**,raw/**,.idea/**
ForbiddenWriteSet = EXTERNAL_RELATIONSHIP_TARGET_ACCESS
```

## 4. 执行步骤

1. RED：inline、table-cell、多图片、缺失 media、digest 漂移和外链 canary 先失败。
2. GREEN：按 relationship ID 和 source anchor 建立双射，计算内嵌 media hash。
3. 对外链只保留合同允许的字面元数据，观测 stat/DNS/file-read/network 均为 0。

## 5. 验证命令

```bash
./mvnw -f server/pom.xml -Dtest='io.cognitura.source.docx.image.*Test' test
scripts/verify-wave1-implementation
git diff --check
git status --short
```

## 6. Gate 与完成定义

inline/table-cell 锚点、media ref、hash 和字面关系保序通过；缺失、重复、漂移及外部访问
全部 fail closed，`ExternalRelationshipDereference = FORBIDDEN` 得到运行时 canary 证明。

## 7. 提交与审查

FixedCommitReviewGate = NEW_DEEP_REVIEWER_ZERO_FINDING_BEFORE_SUCCESSOR_RELEASE

```bash
sed -n 's/^WriteSet = //p' \
  docs/task-cards/wave-1-implementation/W1-I06-image-anchor-relationship-projection.md |
  git add --pathspec-from-file=-
git diff --cached --name-only
git commit -m "feat: project DOCX image relationships"
```

暂存清单必须与本卡 WriteSet 双向精确一致；目录级 `git add` 禁止。固定提交由新的
`deep_reviewer` 审查；零发现 GO 前不得释放 I07。
