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

## Transition rules

- `execution-state.md` 是 Active、READY 和 completed 事实的唯一可变权威。
- 业务候选是从最近合法 Owner release receipt 到 reviewed tip 的单父、逐提交非空
  Owner WriteSet 子集链；release-to-tip 累计差异必须精确等于该 Owner 的完整 WriteSet。
- 普通 receipt 必须是 candidate tip 的 ledger-only 直接子提交。
- `d47c8c7bd7355947b5e8e1de6c264d80c2e27c9a` 仅保留为失败证据；它永远不是普通
  receipt，也不是 VSB-01 anchor。
- `GOVERNANCE_REPAIR` 只允许一次 version 1 到 version 2 的修复：它固定于上述
  origin、批准规格 `2123594540c91341c480f504949315a6abec316c` 和精确五路径治理链，
  并要求 `deep_reviewer` 零 finding GO 以及 `ultra_gatekeeper` 零 finding 最终 GO。
- 修复后，仅 G 的 ledger-only `GOVERNANCE_REPAIR` receipt R 可作为 VSB-01 release anchor。

| ID | 任务卡 | 依赖 | Gate | ReviewRoute |
|---|---|---|---|---|
| `VSB-00` | [治理、参考图与正式样式参考](VSB-00-governance-reference.md) | `GOVERNANCE_BOOTSTRAP` | `VSB-G0 GOVERNANCE_AND_REFERENCE` | `deep_reviewer` |
| `VSB-01` | [语义 CSS token 投影](VSB-01-semantic-tokens.md) | `VSB-00` | `VSB-G1 SEMANTIC_TOKENS` | `deep_reviewer` |
| `VSB-02` | [Module 默认阅读视觉实现](VSB-02-module-default-reading-visual.md) | `VSB-01` | `VSB-G2 MODULE_DEFAULT_READING_VISUAL` | `deep_reviewer` |
| `VSB-03` | [固定视觉验收](VSB-03-fixed-visual-acceptance.md) | `VSB-02` | `VSB-G3 FIXED_VISUAL_ACCEPTANCE` | `deep_reviewer+ultra_gatekeeper` |

每张业务候选先通过本卡 Gate 和固定 SHA 独立审查，再由只改 execution-state 的
直接子提交推进。Finding 必须用 `RETURN_TO_OWNER` 回到事实 Owner；不得修改后继卡
来掩盖失败。正式数据库写入与远程推送始终不在本集合授权内。
