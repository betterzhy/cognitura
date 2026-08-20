# W1-I04 Text, List and Section Parser

```text
TaskCardID = W1-I04
CardKind = IMPLEMENTATION
Status = READY
Gate = W1-IG4 TextListSectionParser
Risk = HIGH
DependsOn = W1-I03
PrimaryBoundary = DOCX_PARSER
ProductionFileLimit = 8
ProductionWriteSetException = NONE
PositiveVerification = HEADING_PARAGRAPH_LIST_ORDER_AND_SECTION_PATH_PRESERVED
NegativeVerification = UNSUPPORTED_BLOCK_ORDER_AND_HIERARCHY_DRIFT_REJECTED
BusinessImplementationAuthorization = USER_AUTHORIZED
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
SupportedBlockTypes = HEADING,PARAGRAPH,LIST
```

## 1. 目标

把已通过安全闸的 DOCX 包投影为 HEADING、PARAGRAPH、LIST 三类 `DocumentBlock`
候选，保留 `sourceOrder`、标题层级、`sectionPath` 和列表语义。

## 2. 前置条件与输入

- I03 已 DONE，只接收 `SafeDocxPackage`。
- 服从正式 DocumentBlock 合同；只使用合成 fixture。
- 不处理表格、图片、发布、持久化或 HTTP。

## 3. 写集

```text
WriteSet = server/src/main/java/io/cognitura/source/docx/text/TextListSectionParser.java
WriteSet = server/src/main/java/io/cognitura/source/docx/text/DocumentBlockCandidate.java
WriteSet = server/src/main/java/io/cognitura/source/docx/text/SectionPathTracker.java
WriteSet = server/src/main/java/io/cognitura/source/docx/text/ListSemantics.java
WriteSet = server/src/main/java/io/cognitura/source/docx/text/SourceOrderCursor.java
WriteSet = server/src/test/java/io/cognitura/source/docx/text/TextListSectionParserTest.java
WriteSet = server/src/test/java/io/cognitura/source/docx/text/SectionPathTrackerTest.java
WriteSet = server/src/test/resources/docx/text/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/docx/table/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/docx/image/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/application/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/api/**
ForbiddenWriteSet = web/**,raw/**,.idea/**
```

## 4. 执行步骤

1. RED：混合标题/段落/列表的 sourceOrder、sectionPath、列表层级和空标题负例先失败。
2. GREEN：按文档顺序单遍遍历，生成闭集候选，不重排或摘要文本。
3. 未支持节点必须显式拒绝或交由后继 Owner，禁止静默丢弃。

## 5. 验证命令

```bash
./mvnw -f server/pom.xml -Dtest='io.cognitura.source.docx.text.*Test' test
scripts/verify-wave1-implementation
git diff --check
git status --short
```

## 6. Gate 与完成定义

三类块内容、顺序、标题层级、sectionPath 和列表语义均由正例及关键负例锁定；未引入
表格、图片、发布、Persistence、HTTP 或 Web 边界。

## 7. 提交与审查

FixedCommitReviewGate = NEW_DEEP_REVIEWER_ZERO_FINDING_BEFORE_SUCCESSOR_RELEASE

```bash
sed -n 's/^WriteSet = //p' \
  docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md |
  git add --pathspec-from-file=-
git diff --cached --name-only
git commit -m "feat: parse DOCX text lists and sections"
```

暂存清单必须与本卡 WriteSet 双向精确一致；目录级 `git add` 禁止。固定提交由新的
`deep_reviewer` 审查；零发现 GO 前不得释放 I05。
