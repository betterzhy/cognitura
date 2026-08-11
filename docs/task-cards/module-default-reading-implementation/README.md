# Cognitura ModuleDefaultReadingState 实现任务卡索引

```text
CanonicalProjectName = Cognitura
TaskCardSet = MODULE_DEFAULT_READING_IMPLEMENTATION
TaskCardIDs = MDR-I00,MDR-I01,MDR-I02,MDR-I03,MDR-I04,MDR-I05,MDR-I06,MDR-I07,MDR-I08
TaskCardCount = 9
TaskCardSetStatus = USER_APPROVED_AWAITING_IMPLEMENTATION_AUTHORIZATION
ActiveImplementationTaskCard = NONE
ReleasedTaskCard = NONE
DocumentationGap = DOC-GAP-MDR-001
WrittenTaskCardReview = USER_APPROVED
DesignAlignmentStatus = COMPLETE
DevelopmentPlanningEntry = READY_FOR_USER_AUTHORIZATION
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

本集合只规划首个 `ModuleDefaultReadingState` 的小型前端投影切片。它不替代已批准
但尚未执行的 Wave 1 source work，也不占用其 `W1-I00..W1-I13` 编号。所有卡均为
`BLOCKED_BY_BUSINESS_IMPLEMENTATION_AUTHORIZATION`，没有 `READY` 卡。卡片文本已经
获得用户批准；该批准本身不构成业务实现授权，用户另行明确授权并指定唯一卡前不得
释放。

## 1. 方案裁决

比较过三种路径：

1. 复用 `W1-I00..W1-I13`：会覆盖既有 source intake/Parser/API/Web preview 写集，
   因范围冲突排除。
2. 单张完整 Module 页面卡：会合并测试工具、Canonical 投影、Renderer、Relation、
   SourceEntry 和页面组合，因不可独立回滚排除。
3. 使用独立 `MDR-I00..MDR-I08`：逐卡固定一个投影或验证风险面，采用本方案。

本切片最终只产出可复用的 `ModuleDefaultReading` 组件，不修改 `App.tsx`，不接路由、
HTTP、后端或持久化，不声明完整页面、RF-AC-02 或 `ImplementationValidation` 已通过。

## 2. 卡片清单

| ID | 任务卡 | 状态 | 依赖 | Gate | 生产写集上限 |
|---|---|---|---|---|---|
| `MDR-I00` | [Web 测试基座](MDR-I00-web-test-foundation.md) | `BLOCKED_BY_BUSINESS_IMPLEMENTATION_AUTHORIZATION` | `NONE` | `MDR-IG0` | `2` |
| `MDR-I01` | [Canonical 叙事投影](MDR-I01-canonical-narrative-projection.md) | `BLOCKED_BY_BUSINESS_IMPLEMENTATION_AUTHORIZATION` | `MDR-I00` | `MDR-IG1` | `2` |
| `MDR-I02` | [问题、结论与主认知脊柱](MDR-I02-question-conclusion-spine.md) | `BLOCKED_BY_BUSINESS_IMPLEMENTATION_AUTHORIZATION` | `MDR-I01` | `MDR-IG2` | `1` |
| `MDR-I03` | [Element 与 Boundary 连续阅读](MDR-I03-element-boundary-reading.md) | `BLOCKED_BY_BUSINESS_IMPLEMENTATION_AUTHORIZATION` | `MDR-I02` | `MDR-IG3` | `3` |
| `MDR-I04` | [STAGE_CHAIN 主投影](MDR-I04-stage-chain-renderer-projection.md) | `BLOCKED_BY_BUSINESS_IMPLEMENTATION_AUTHORIZATION` | `MDR-I03` | `MDR-IG4` | `2` |
| `MDR-I05` | [关键 Relation 内联投影](MDR-I05-key-relation-projection.md) | `BLOCKED_BY_BUSINESS_IMPLEMENTATION_AUTHORIZATION` | `MDR-I04` | `MDR-IG5` | `2` |
| `MDR-I06` | [轻量来源入口](MDR-I06-source-entry-projection.md) | `BLOCKED_BY_BUSINESS_IMPLEMENTATION_AUTHORIZATION` | `MDR-I05` | `MDR-IG6` | `1` |
| `MDR-I07` | [Reading First 组件组合](MDR-I07-reading-first-composition.md) | `BLOCKED_BY_BUSINESS_IMPLEMENTATION_AUTHORIZATION` | `MDR-I06` | `MDR-IG7` | `3` |
| `MDR-I08` | [固定切片候选复核](MDR-I08-fixed-slice-review.md) | `BLOCKED_BY_BUSINESS_IMPLEMENTATION_AUTHORIZATION` | `MDR-I00..MDR-I07` | `MDR-IG8` | `0` |

依赖严格线性：

```text
MDR-I00 -> MDR-I01 -> MDR-I02 -> MDR-I03 -> MDR-I04
        -> MDR-I05 -> MDR-I06 -> MDR-I07 -> MDR-I08
```

## 3. 全局边界

```text
ExistingWave1SourceWork = PRESERVE_UNCHANGED
SchemaChange = FORBIDDEN_IN_THIS_SET
DatabaseChange = FORBIDDEN_IN_THIS_SET
DatabaseMigrationExecution = FORBIDDEN
DatabaseWriteBoundary = FORMAL_DATABASE_WRITE_NOT_AUTHORIZED
BackendChange = FORBIDDEN_IN_THIS_SET
RouteAndAppIntegration = FORBIDDEN_IN_THIS_SET
RawWrite = FORBIDDEN
RendererCreatesIndependentFacts = NO
PushBoundary = REMOTE_PUSH_NOT_AUTHORIZED
```

```text
GapID = DOC-GAP-MDR-001
GapSubject = CONDITIONS_RESULTS_CANONICAL_PROJECTION_MAPPING
GapStatus = OPEN
GapBlocks = FULL_MODULE_DEFAULT_READING_ACCEPTANCE
GapDoesNotBlock = MDR_LIMITED_CANONICAL_PROJECTION_SLICE
GapDisposition = SEPARATE_SCHEMA_DESIGN_AND_IMPLEMENTATION_CARD_IF_FIELD_CHANGE_IS_REQUIRED
```

当前正式 Schema 没有独立的 `Conditions` 或 `Results` 字段。本切片不得把任意
`KnowledgeElement` 或 Spine Step 擅自重命名为这两类语义，也不得从视觉 fixture
反向制造 Canonical 数据。若完整 Module 默认阅读验收需要新增字段，必须先转为
`BLOCKED_BY_DOCUMENTATION_GAP`，另建并单独批准 Schema 设计/实现卡；物理数据库
同理必须另建数据库卡，且仍不得写正式数据库。

## 4. RED、GREEN、提交与审查规则

1. 每卡先添加卡内给出的精确失败测试并运行，保存预期失败原因；没有观察到 RED
   不得写 GREEN。
2. GREEN 只修改该卡 `WriteSet`；不得因测试方便读取 `raw/**` 或复制 docs-only
   高保真 fixture 成为生产事实。
3. 每卡运行目标测试、`pnpm --dir web build`、全部适用既有 Gate、
   `git diff --check` 和精确写集检查。
4. 每卡形成一个独立本地候选提交；禁止 amend、push 或混入 `.idea/`。
5. `MDR-I00..MDR-I07` 的候选 SHA 各自交给新的 `deep_reviewer` 独立审查；只有
   `GO / P0=0 / P1=0 / P2=0` 才可关闭该卡。发现必须回到同一卡修复并产生新 SHA。
6. `MDR-I08` 使用 `ultra_gatekeeper` 对固定完整切片候选作最终 GO/NO-GO；审查卡
   内不得夹带修复。
7. 即使卡片文本获批，也必须由用户另行明确授权业务实现并指定唯一卡，才可把任何
   卡改为 `READY`。

本卡集的当前规划状态使用专用 Bash 3.2 验证器：

```bash
bash tests/task-cards/verify-module-default-reading-implementation-cards.sh
scripts/verify-module-default-reading-implementation-cards \
  --cards-dir docs/task-cards/module-default-reading-implementation
```

## 5. 当前批准门

```text
TaskCardRelease = FORBIDDEN
TaskCardExecution = FORBIDDEN
ImplementationValidation = NOT_RUN
```
