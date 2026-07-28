# W0-04 JSON Schema Source

```text
TaskCardID = W0-04
Status = BLOCKED_BY_DOCUMENTATION_GAP
Gate = W0-G3 JsonSchemaValidation
Risk = HIGH
DependsOn = W0-02,W0-03
ReviewRoute = MAIN_AGENT_GATE
```

## 1. 目标

建立版本化、可引用、具有正反例验证的正式认知产物、生成记录和 Renderer 输入
JSON Schema，使生成、存储和展示共享同一机器契约。

## 2. 前置条件与输入

- `W0-G2 SpecialtyContractCoverage = PASS`
- `W0-G2A BuildBaseline = PASS`
- 权威专项正文已经落地并通过来源校验，或用户批准了明确的 Schema 重基线设计
- 当前额外阻断：

```text
ExternalBlocker = DOC-GAP-001
BlockedReason = FIELD_LEVEL_SCHEMA_SOURCE_MISSING
```

总体设计摘要不足以单独解除此阻断。

## 3. 写集

- Create: `schemas/cognition/*.schema.json`
- Create: `schemas/generation/*.schema.json`
- Create: `schemas/ui/renderer-input.schema.json`
- Create: `tests/contracts/schema/`
- Create: `scripts/verify-json-schemas`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/engineering/cognitura-specialty-contract-coverage.md`
- Modify: `docs/task-cards/README.md`
- Modify: `docs/task-cards/W0-04-json-schema-source.md`
- Modify: `docs/task-cards/W0-05-golden-case-regression.md`
- Modify: `docs/engineering/cognitura-wave-0-plan.md`
- Modify: `docs/engineering/cognitura-wave-0-entry-decision.md`

不得伪造历史专项文档，不得从常识推断 required、枚举、类型或关系约束。

## 4. 执行步骤

- [ ] 先解除 `DOC-GAP-001`，记录权威来源路径、版本、哈希或批准的重基线裁决。
- [ ] 为十项正式认知产物编写缺少 required、非法枚举和非法关系的失败样例。
- [ ] 为生成阶段记录和 Renderer 输入编写失败样例。
- [ ] 运行测试并确认 Schema 未实现时失败。
- [ ] 实现认知产物 Schema，所有字段都绑定来源证据。
- [ ] 实现生成阶段 Schema，覆盖输入哈希、Prompt、模型、来源块、验证与重试状态。
- [ ] 实现统一 Renderer 输入 Schema 和页面状态枚举。
- [ ] 运行正例与反例，确认缺少 thesis、spine、boundary 或 sourceRefs 的 Module 被拒绝。
- [ ] 更新设计索引、缺口状态和任务卡，并形成独立提交。

## 5. 验证命令

```bash
scripts/verify-json-schemas
bash tests/contracts/schema/verify-json-schemas.sh
bash tests/task-cards/verify-task-cards.sh
git diff --check
```

所有反例必须以契约不满足而失败，不能因解析器崩溃或文件路径错误失败。

## 6. Gate 与完成定义

- `DOC-GAP-001` 具有经验证的合法关闭证据；
- 十项认知产物、生成记录和 Renderer 输入 Schema 均可解析；
- 每个字段可追溯到权威来源；
- required、枚举、关系和来源引用正反例全部通过；
- 没有把第二棵个性化知识树写入契约。

```text
W0-G3 JsonSchemaValidation = PASS
```

## 7. 提交与审查

```text
CommitMessage = feat: add Cognitura canonical JSON schemas
CommitReview = MAIN_AGENT_GATE
NextTaskCardOnPass = W0-05
```

未获权威字段来源或明确重基线批准时，本卡保持阻断并停止执行。
