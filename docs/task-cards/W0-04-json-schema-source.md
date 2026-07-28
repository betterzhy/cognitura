# W0-04 JSON Schema Source

```text
TaskCardID = W0-04
Status = DONE
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
- `Cognitura-Schema-Baseline-2.0 = FORMAL_SCHEMA_REBASELINE`
- Schema 重基线来源：
  `docs/design/cognitura-schema-baseline-2.0.md`
- 文档缺口处置：

```text
ExternalBlocker = RESOLVED_BY_APPROVED_SCHEMA_REBASELINE
DocumentationGap = DOC-GAP-001
SchemaRebaselineDisposition = APPROVED
DependencyState = SATISFIED
```

总体设计摘要本身仍不足以生成字段级 Schema；本卡只能实现已经批准的
`Cognitura-Schema-Baseline-2.0`，不得继续补写未裁决语义。

## 3. 写集

- Create: `schemas/cognition/*.schema.json`
- Create: `schemas/generation/*.schema.json`
- Create: `schemas/ui/renderer-input.schema.json`
- Create: `schemas/ui/page-state.schema.json`
- Create: `schemas/catalog.json`
- Create: `schemas/evidence-map.json`
- Create: `tests/contracts/schema/`
- Create: `scripts/verify-json-schemas`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/engineering/cognitura-specialty-contract-coverage.md`
- Modify: `docs/task-cards/README.md`
- Modify: `docs/task-cards/W0-04-json-schema-source.md`
- Modify: `docs/task-cards/W0-05-golden-case-regression.md`
- Modify: `docs/engineering/cognitura-wave-0-plan.md`
- Modify: `docs/engineering/cognitura-wave-0-entry-decision.md`
- Modify（用户补充授权）: `tests/task-cards/verify-task-cards.sh`
- Modify（用户补充授权）: `AGENTS.md`
- Modify（用户补充授权）: `README.md`

不得伪造历史专项文档，不得从常识推断 required、枚举、类型或关系约束。

## 4. 执行步骤

- [x] 解除 `DOC-GAP-001` 执行阻断，记录批准的
  `Cognitura-Schema-Baseline-2.0`。
- [x] 为十项正式认知产物编写缺少 required、非法枚举和非法关系的失败样例。
- [x] 为生成阶段记录和 Renderer 输入编写失败样例。
- [x] 运行测试并确认 Schema 未实现时失败。
- [x] 实现认知产物 Schema，所有字段都绑定来源证据。
- [x] 实现生成阶段 Schema，覆盖输入哈希、Prompt、模型、来源块、验证与重试状态。
- [x] 实现统一 Renderer 输入 Schema 和页面状态枚举。
- [x] 运行正例与反例，确认缺少 thesis、spine、boundary 或 sourceRefs 的 Module 被拒绝。
- [x] 更新设计索引、缺口状态和任务卡，形成不改写历史的修复提交并通过固定提交深审。

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

完成证据：

```text
SchemaDraft = 2020-12
SchemaDocumentCount = 14
InstantiableSchemaCount = 13
ValidFixtureCount = 13
InvalidFixtureCount = 18
StrictObjectNegativeCaseCount = 12
SemanticValidContextCount = 2
NonPublishedModuleNullability = PASS
SemanticNegativeCaseCount = 34
SemanticViolationCodeCount = 68
EvidenceMapSchemaEntryCount = 645
EvidenceMapSemanticEntryCount = 16
EvidenceMapEntryCount = 661
EvidenceMapNegativeCaseCount = 6
EvidenceMapRenderRoundTrip = PASS
Validator = Ajv-8.20.0
NetworkResolution = FORBIDDEN
ObservedRedBoundary =
  missing verifier
  → missing catalog
  → missing Schema documents
  → missing evidence mapping
  → PASS
```

```text
W0-G3 JsonSchemaValidation = PASS
```

## 7. 提交与审查

```text
PreviousRemediationReview = 8cfd056|NO_GO|P0=0|P1=2|P2=0
PreviousEvidenceReview = c15a005|NO_GO|P0=0|P1=0|P2=1
PreviousRenderReview = e79e69c|NO_GO|P0=0|P1=0|P2=1
CommitMessage = fix: keep Cognitura schema verification self-contained
CommitReview = DEEP_REVIEWER_FIXED_COMMIT
FixedImplementationReview = 72b5ce7ee4805c52afd48070c4bb93699e96a381|GO|P0=0|P1=0|P2=0
NextTaskCardOnPass = W0-05
```

本卡只实施已经固定的重基线。实施中发现设计矛盾时必须停止并形成版本化设计
变更，不得边写 Schema 边静默改变本基线。
