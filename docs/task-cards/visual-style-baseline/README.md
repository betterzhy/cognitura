# Cognitura Visual Style Baseline Task Cards

```text
CanonicalProjectName = Cognitura
TaskCardSet = VISUAL_STYLE_BASELINE
TaskCardIDs = VSB-00,VSB-01,VSB-02,VSB-03
TaskCardCount = 4
ExecutionStateAuthority = docs/task-cards/visual-style-baseline/execution-state.md
CardBodyStatus = GOVERNED_BY_EXECUTION_STATE
SetAuthorization = VSB-00..VSB-03_AUTOMATIC_SERIAL
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

本卡集只把批准的视觉样式规格拆成四张串行卡。唯一可变运行态在
[`execution-state.md`](execution-state.md)；本索引与四张卡正文不复制
Active、Released、Completed 或 READY 事实。

| ID | 任务卡 | 依赖 | Gate | ReviewRoute |
|---|---|---|---|---|
| `VSB-00` | [治理、参考图与正式样式参考](VSB-00-governance-reference.md) | `GOVERNANCE_BOOTSTRAP` | `VSB-G0 GOVERNANCE_AND_REFERENCE` | `deep_reviewer` |
| `VSB-01` | [语义 CSS token 投影](VSB-01-semantic-tokens.md) | `VSB-00` | `VSB-G1 SEMANTIC_TOKENS` | `deep_reviewer` |
| `VSB-02` | [Module 默认阅读视觉实现](VSB-02-module-default-reading-visual.md) | `VSB-01` | `VSB-G2 MODULE_DEFAULT_READING_VISUAL` | `deep_reviewer` |
| `VSB-03` | [固定视觉验收](VSB-03-fixed-visual-acceptance.md) | `VSB-02` | `VSB-G3 FIXED_VISUAL_ACCEPTANCE` | `deep_reviewer+ultra_gatekeeper` |

每张业务候选先通过本卡 Gate 和固定 SHA 独立审查，再由只改 execution-state 的
直接子提交推进。Finding 必须用 `RETURN_TO_OWNER` 回到事实 Owner；不得修改后继卡
来掩盖失败。正式数据库写入与远程推送始终不在本集合授权内。
