# W0-02 专项契约覆盖封口

```text
TaskCardID = W0-02
Status = DONE
Gate = W0-G2 SpecialtyContractCoverage
Risk = HIGH
DependsOn = W0-01
ReviewRoute = MAIN_AGENT_GATE
```

## 1. 目标

逐项证明构造专项与 UI/UX 专项的正式契约在总体设计 1.2 中是否已回迁，并把所有
字段级缺口固定为可审查的 `DocumentationGap`，禁止凭经验补写 Schema。

## 2. 前置条件与输入

- `W0-G1 DesignSourceRegistry = PASS`
- `cognitive-knowledge-atlas-overall-design-1.2.md`
- `docs/engineering/cognitura-design-index.md`
- 总体设计 Reverse Migration 记录 `RM-01～RM-11`、`UI-RM-01～10`

专项正文若仍未落地，只能使用总体设计中的回迁证据。

## 3. 写集

- Create: `docs/engineering/cognitura-specialty-contract-coverage.md`
- Create: `scripts/verify-specialty-contract-coverage`
- Create: `tests/contracts/specialty-coverage/verify-specialty-contract-coverage.sh`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/task-cards/README.md`
- Modify: `docs/task-cards/W0-02-specialty-contract-coverage.md`
- Modify: `docs/task-cards/W0-03-build-baseline.md`
- Modify: `docs/engineering/cognitura-wave-0-plan.md`
- Modify: `docs/engineering/cognitura-wave-0-entry-decision.md`
- Modify (user-directed execution-loop status sync): `AGENTS.md`
- Modify (user-directed execution-loop status sync): `README.md`

不得创建伪造的专项正文或完整字段 Schema。

## 4. 执行步骤

- [x] 先编写覆盖矩阵校验测试，要求契约 ID、来源章节、覆盖状态和缺口处置完整。
- [x] 运行测试并确认覆盖文档不存在时失败。
- [x] 建立构造专项矩阵：层级、十项产物、生成阶段、认知密度、修订和 Golden Case。
- [x] 建立 UI/UX 矩阵：页面、Renderer、Source Evidence、状态和 Desktop Web 边界。
- [x] 对已回迁条目标记 `COVERED_BY_REVERSE_MIGRATION` 并给出总体设计章节。
- [x] 对字段、类型、required、枚举、约束或示例缺口标记 `SCHEMA_SOURCE_MISSING`。
- [x] 为每个缺口指定唯一处置：权威正文落地或经批准的 Schema 重基线设计。
- [x] 运行校验，更新本卡和下一张卡状态并形成独立提交。

## 5. 验证命令

```bash
bash tests/contracts/specialty-coverage/verify-specialty-contract-coverage.sh
scripts/verify-specialty-contract-coverage \
  docs/engineering/cognitura-specialty-contract-coverage.md
bash tests/task-cards/verify-task-cards.sh
git diff --check
```

## 6. Gate 与完成定义

- 所有非 Schema 契约都有总体设计正式证据；
- 所有 Schema 缺口都有唯一 ID、影响范围和合法处置；
- `DOC-GAP-001`、`DOC-GAP-002` 没有被静默关闭；
- 覆盖矩阵校验和任务卡集合校验通过。

```text
W0-G2 SpecialtyContractCoverage = PASS
MigrationRecordCount = 26
ContractCoverageCount = 19
DocumentationGapCount = 2
EvidenceLimitCount = 1
```

该 Gate 允许继续非 Schema 工程工作，不自动解除 `W0-04` 的字段来源阻断。

## 7. 提交与审查

```text
CommitMessage = docs: close Cognitura specialty contract coverage
CommitReview = MAIN_AGENT_GATE
ReviewResult = MAIN_AGENT_VERIFIED
NextTaskCardOnPass = W0-03
```

如发现总体设计没有覆盖某项非 Schema P0 契约，停止并记录新缺口，不得扩大写集。
