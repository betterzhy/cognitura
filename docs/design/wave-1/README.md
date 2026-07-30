# Cognitura Wave 1 详细设计索引

```text
CanonicalProjectName = Cognitura
Wave1DesignStatus = REVIEW_REPAIR_IN_PROGRESS
ActiveDesignTaskCard = W1-D05
BusinessImplementation = NOT_AUTHORIZED
```

本目录保存 Wave 1 来源接入的字段级和运行时工程契约。所有文件均从属于
`Cognitura-Overall-Design-1.2` 与 `Cognitura-Schema-Baseline-2.0`，不替代
总体设计或缺失的历史专项正文。

## 设计清单

| 设计切片 | 文档 | 状态 | Gate |
|---|---|---|---|
| `W1-D01` | [SourceDocument 身份与生命周期](cognitura-source-document-contract-1.0.md) | `DONE` | `REPAIR_CANDIDATE_AWAITING_FIXED_REVIEW` |
| `W1-D02` | [DocumentBlock 保真与安全](cognitura-document-block-contract-1.0.md) | `DONE` | `W1-DG2 PASS` |
| `W1-D03` | [重解析与稳定引用](cognitura-reparse-reference-contract-1.0.md) | `DONE` | `REPAIR_CANDIDATE_AWAITING_FIXED_REVIEW` |
| `W1-D04` | [来源预览与验收](cognitura-source-preview-contract-1.0.md) | `DONE` | `W1-DG4 PASS` |

固定候选验收记录：
[Wave 1 详细设计验收](../../engineering/cognitura-wave-1-design-acceptance.md)。

## 设计阶段边界

- 不创建 DOCX 解析器、API、页面、Mapper、migration 或数据库对象。
- 不读取或改写 `raw/` 原件，不访问 Redis 遗留链接目标。
- Wave 1 不使用 LLM。
- 每份契约通过对应 sol/high Gate 后才成为后续设计切片的正式输入。
- 历史 W1-DG5 结论已由用户审阅发现取代；W1-D05 正在修复并将重新执行两个
  独立 `gpt-5.6-sol/high` 阶段。
