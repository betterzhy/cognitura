# W0-00 Repository 基线

```text
TaskCardID = W0-00
Status = DONE
Gate = W0-G0 RepositoryBaseline
Risk = LOW
DependsOn = NONE
ReviewRoute = MAIN_AGENT_GATE
```

## 1. 目标

建立可追溯、不会污染正式输入的 Cognitura Git Repository 基线。

## 2. 前置条件与输入

- `cognitive-knowledge-atlas-overall-design-1.2.md`
- `raw/11-MySQL数据库.docx`
- `raw/12-Redis中间件.docx`
- `raw/40-英语学习.docx`
- 用户对初始化 Git 和提交的明确授权

## 3. 写集

- `.gitignore`
- `AGENTS.md`
- `README.md`
- `docs/engineering/*.md`
- Git Repository 元数据和本任务独立提交

禁止修改、重命名、复制或重新编码总体设计和三份 Golden Case 原件。

## 4. 执行步骤

- [x] 核对真实目录、Git 状态、正式输入路径、大小和 SHA-256。
- [x] 初始化 `main` 分支并排除 `.DS_Store`。
- [x] 提交正式输入和工程基线。
- [x] 规范 Golden Case 文件模式，保持内容哈希不变。
- [x] 记录 Repository 基线内容提交和 Gate 结果。

## 5. 验证命令

```bash
git status --short --branch
git log --oneline -5
shasum -a 256 \
  cognitive-knowledge-atlas-overall-design-1.2.md \
  raw/11-MySQL数据库.docx \
  raw/12-Redis中间件.docx \
  raw/40-英语学习.docx
```

## 6. Gate 与完成定义

```text
RepositoryBranch = main
RepositoryBaselineContentCommit =
  2047a80dde53e1a9b8b460f2ef9230df7f2bca22
W0-G0 RepositoryBaseline = PASS
```

完成依据：四份正式输入哈希与设计索引一致，Repository 基线内容已提交，工作树
在记录检查点保持干净。

## 7. 提交与审查

```text
PrimaryBaselineCommit = 8b2ac16
ContentNormalizationCommit = 2047a80
StatusRecordCommit = c4424e9
ReviewResult = MAIN_AGENT_VERIFIED
```

本卡是历史完成卡，不得 amend 或重写已有提交。
