# W1-I05 Table Fidelity

```text
TaskCardID = W1-I05
CardKind = IMPLEMENTATION
Status = READY
Gate = W1-IG5 TableFidelity
Risk = HIGH
DependsOn = W1-I04
PrimaryBoundary = DOCX_TABLE_PARSER
ProductionFileLimit = 8
ProductionWriteSetException = NONE
PositiveVerification = TABLE_ROWS_CELLS_MERGES_AND_TEXT_EVIDENCE_PRESERVED
NegativeVerification = CELL_ORDER_MERGE_AND_TEXT_FIDELITY_DRIFT_REJECTED
BusinessImplementationAuthorization = USER_AUTHORIZED
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
```

## 1. 目标

独立实现 DOCX 表格行列、单元格文本、合并信息、确定性单元格顺序和表内文本证据，
不改变 I04 的文本块 Owner。

## 2. 前置条件与输入

- I04 已 DONE，DocumentBlock 候选和 sourceOrder 契约固定。
- 使用合成表格 fixture；不得读取 `raw/**`。
- 表格内图片只保留待 I06 解析的锚点位置，不读取图片内容。

## 3. 写集

```text
WriteSet = server/src/main/java/io/cognitura/source/docx/table/TableFidelityParser.java
WriteSet = server/src/main/java/io/cognitura/source/docx/table/TableBlockCandidate.java
WriteSet = server/src/main/java/io/cognitura/source/docx/table/TableCellCandidate.java
WriteSet = server/src/main/java/io/cognitura/source/docx/table/TableMergeProjection.java
WriteSet = server/src/main/java/io/cognitura/source/docx/table/TableTextEvidence.java
WriteSet = server/src/test/java/io/cognitura/source/docx/table/TableFidelityParserTest.java
WriteSet = server/src/test/java/io/cognitura/source/docx/table/TableMergeProjectionTest.java
WriteSet = server/src/test/resources/docx/table/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/docx/image/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/application/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/persistence/**
ForbiddenWriteSet = server/src/main/java/io/cognitura/source/api/**
ForbiddenWriteSet = web/**,raw/**,.idea/**
```

## 4. 执行步骤

1. RED：规则表、合并单元格、空单元格、嵌套文本和越界 merge 负例先失败。
2. GREEN：按 row-major 确定性顺序投影行列、文本和 merge 证据。
3. 不把视觉推断或空白补齐写成来源事实。

## 5. 验证命令

```bash
./mvnw -f server/pom.xml -Dtest='io.cognitura.source.docx.table.*Test' test
scripts/verify-wave1-implementation
git diff --check
git status --short
```

## 6. Gate 与完成定义

行列数、全部单元格文本、合并证据与 row-major 顺序精确通过；损坏 merge、遗漏单元格
和重排均 fail closed，且无图片、发布、Persistence、HTTP 或 Web 逻辑。

## 7. 提交与审查

FixedCommitReviewGate = NEW_DEEP_REVIEWER_ZERO_FINDING_BEFORE_SUCCESSOR_RELEASE

```bash
sed -n 's/^WriteSet = //p' \
  docs/task-cards/wave-1-implementation/W1-I05-table-fidelity.md |
  git add --pathspec-from-file=-
git diff --cached --name-only
git commit -m "feat: preserve DOCX table fidelity"
```

暂存清单必须与本卡 WriteSet 双向精确一致；目录级 `git add` 禁止。固定提交由新的
`deep_reviewer` 审查；零发现 GO 前不得释放 I06。
