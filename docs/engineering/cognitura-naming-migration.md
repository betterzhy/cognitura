# Cognitura 命名迁移记录

```text
CanonicalProjectName = Cognitura
RepositoryName = cognitura

HistoricalProjectNames =
  Cognitive Knowledge Atlas
  Cognitive Knowledge Structure System

HistoricalDesignVersion =
  Cognitive-Knowledge-Atlas-Overall-Design-1.2

EngineeringReferenceName =
  Cognitura-Overall-Design-1.2
```

## 1. 迁移原则

1. 所有新增工程产物统一使用 `Cognitura`。
2. 历史设计文件保留原文件名、原标题、原版本号和演进记录。
3. 工程索引用别名指向唯一历史基线，不复制总体设计。
4. 不通过批量替换破坏历史可追溯性。
5. 原始 Golden Case 不写入项目名称。

## 2. 本轮命名落地

| 范围 | 结果 |
|---|---|
| README 标题 | `Cognitura` |
| Repository 规范 | `cognitura` |
| AGENTS.md | 使用 `Cognitura`，并保留历史名称规则 |
| 工程设计索引 | `Cognitura 设计与输入索引` |
| Repository 复验 | `Cognitura Repository 基线复验` |
| Wave 0 计划与准入 | 使用 `Cognitura` |
| 新增 Schema 标题 | 当前尚无 Schema；Wave 0 要求统一使用 `Cognitura` |
| 新增测试说明 | 当前尚无测试工程；Wave 0 测试资产统一使用 `Cognitura` |
| 前端工程名称 | 当前未创建；未来工程标识使用 `cognitura-web` |
| 后端工程名称 | 当前未创建；未来工程标识使用 `cognitura-server` |

## 3. 明确保留的历史命名

- `cognitive-knowledge-atlas-overall-design-1.2.md`
- 文档正文中的 `Cognitive Knowledge Atlas V1`
- `Cognitive-Knowledge-Atlas-Overall-Design-1.2`
- `Cognitive-Knowledge-System-Construction-Design-1.0`
- `Cognitive-Knowledge-Atlas-UIUX-Design-1.0`
- Reverse Migration 记录中的历史版本引用

## 4. 禁止模式

- 不创建内容相同的 `cognitura-overall-design-1.2.md` 副本。
- 不把历史设计版本号改成新的虚构版本。
- 不为了统一文件名删除历史设计名称。
- 不在代码、Schema、测试或 UI 中继续引入新的 `knowledge-atlas` 工程标识。
