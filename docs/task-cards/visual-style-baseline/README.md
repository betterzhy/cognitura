# Cognitura Visual Style Baseline Task Cards

```text
CanonicalProjectName = Cognitura
TaskCardSet = VISUAL_STYLE_BASELINE
TaskCardIDs = VSB-00,VSB-01,VSB-02,VSB-03
TaskCardCount = 4
ExecutionStateAuthority = docs/task-cards/visual-style-baseline/execution-state.md
CardBodyStatus = GOVERNED_BY_EXECUTION_STATE
SetAuthorization = VSB-00..VSB-03_AUTOMATIC_SERIAL
ModelGateRouting = L3_DEEP_REVIEWER_XHIGH_ONE__L4_DEEP_REVIEWER_XHIGH_ONE
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

当前 verifier recovery Authority 是
[`2026-08-14-cognitura-vsb-copy-classification-recovery-design.md`](../../superpowers/specs/2026-08-14-cognitura-vsb-copy-classification-recovery-design.md)
及其同提交计划
[`2026-08-14-cognitura-vsb-copy-classification-recovery.md`](../../superpowers/plans/2026-08-14-cognitura-vsb-copy-classification-recovery.md)，
固定 SHA 为 `5799d873791694f7e4cb4a2dbe65c8fa27495beb`。它只允许 literal
`C053 web/index.html web/visual-reference.html` 的受约束分类，并以一次
`VERIFIER_RECOVERY` 将 version 3 升级至 version 4。`9904d3deb87e4a3e2820c5a12463929916057c36`
仍是 immutable invalid receipt evidence，不是普通 PASS 或 release anchor；只有完整验证的
ledger-only R3 才能成为新的 VSB-02 anchor。恢复不改变当前模型路由、finding、数据库或 push 边界。

当前 Chrome Authority Migration 的 append-only successor 由
[`2026-08-14-cognitura-vsb-chrome-authority-migration-design.md`](../../superpowers/specs/2026-08-14-cognitura-vsb-chrome-authority-migration-design.md)
及其实施计划
[`2026-08-14-cognitura-vsb-chrome-authority-migration.md`](../../superpowers/plans/2026-08-14-cognitura-vsb-chrome-authority-migration.md)
统一约束，固定 successor Authority SHA 为
`55857a7e02147c3a5ea8e632250862e38bd6457f`。被拒绝的两组 predecessor
Authority / candidate 分别为
`ce2a3ca466cc4df2ff077017f1ddb03cb285416f` /
`4a62647fdb8226cc5c0527c48f552ef553ff146e` 与
`a2d22c2e8218413d26f7d8940a9ea5564e59b7f0` /
`b0b77e878fd468f38d40ddd702c96ea8e7446658`；四者均保留为 immutable
`NO_GO / P1=1` 证据，不是当前 Authority、G4 或 R4 base。固定 origin 为
`7b7b9bcab8b372c66ebd0533cbfe3dca885d0f3d`。该 successor 只允许将 Chrome
`151.0.7922.109` 精确迁移到 `151.0.7922.138`；G4 从 origin 起的累计
WriteSet 必须精确为以下六路径：

```text
docs/superpowers/specs/2026-08-14-cognitura-vsb-chrome-authority-migration-design.md
docs/superpowers/plans/2026-08-14-cognitura-vsb-chrome-authority-migration.md
docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md
docs/task-cards/visual-style-baseline/README.md
scripts/verify-visual-style-baseline-cards
tests/task-cards/verify-visual-style-baseline-cards.sh
```

只有从 successor Authority 下降、已完整重放并通过
`L3 / deep_reviewer / xhigh / ONE` 零 finding 审查的 G4，才允许以
ledger-only 直接子提交 R4 记录唯一
`CHROME_AUTHORITY_MIGRATION`；完整验证的 R4 才是新的 VSB-03 release
anchor。Stage A 中实际 `scripts/capture-visual-style-baseline` 必须在 origin、
每个治理提交、G4、工作树和 R4 均不存在，只通过公共只读 source-contract checker
验证临时 canonical fixture；Stage B 的精确十二路径 VSB-03 候选一旦包含该路径，
必须校验 candidate Git blob，禁止 skip 或改验工作树副本。G4、原 origin 和未完整
重放的 receipt 都不是 Owner release anchor，也不会改变 VSB-03 当前
`L4 / deep_reviewer / xhigh / ONE` 的单次最终门禁。

当前 terminal historical HV replay repair 由
[`2026-08-15-cognitura-vsb-historical-hv-replay-repair-design.md`](../../superpowers/specs/2026-08-15-cognitura-vsb-historical-hv-replay-repair-design.md)
及其实施计划
[`2026-08-15-cognitura-vsb-historical-hv-replay-repair.md`](../../superpowers/plans/2026-08-15-cognitura-vsb-historical-hv-replay-repair.md)
统一约束。`2690ab9e6d0318c63deb56f86bc0b923ae845c04` 保留为 immutable
`NO_GO / P1=1` VSB-03 candidate；它不得 amend、重写或复用旧 verdict。
历史 HV Gate 只从固定 Git snapshot
`77d8c1e780f5cc4d209a56baff349135a3c04ee8` 的完整归档重放，当前树
`scripts/verify-high-fidelity-visual` 不构成历史重放。

repair Authority 结构绑定为：`2690ab9...` 后第一个同时包含上述设计、实施计划和
本次修订后的 2026-08-12 VSB 计划最终字节的提交。该提交固定后，README、生产
verifier 与测试再记录其 literal 40-hex SHA；Authority 三个文档 blob/mode 随后
保持不变。最终 repair candidate 从 `2690ab9...` 起累计 WriteSet 精确为：

```text
docs/superpowers/specs/2026-08-15-cognitura-vsb-historical-hv-replay-repair-design.md
docs/superpowers/plans/2026-08-15-cognitura-vsb-historical-hv-replay-repair.md
docs/superpowers/plans/2026-08-12-cognitura-visual-style-baseline.md
docs/task-cards/visual-style-baseline/README.md
scripts/verify-visual-style-baseline-cards
tests/task-cards/verify-visual-style-baseline-cards.sh
scripts/verify-visual-style-baseline
tests/visual-style-baseline/verify-visual-style-baseline.sh
```

其余十个原 VSB-03 Owner 路径必须与 `2690ab9...` byte/mode identical。
同一个 fixed repair SHA 依次取得 `L3 / deep_reviewer / xhigh / ONE` 治理 GO
和 `L4 / deep_reviewer / xhigh / ONE` 最终 GO；Ultra 保持 `NOT_RUN`。之后只允许
version 5、sequence 11、ledger-only 直接子提交记录 `COMPLETE`，不新增 G5、R5、
version 6、correction block 或通用 replay API。Wave 1 restore、数据库写入和 remote
push 均不属于该 exact-eight candidate 或终局 receipt。

当前模型路由 Authority 是
[`2026-08-13-cognitura-model-gate-routing-design.md`](../../superpowers/specs/2026-08-13-cognitura-model-gate-routing-design.md)
（固定 SHA `1199e76a18db1d168c67c328ce7f195f3cdac7d9`）及其 TDD 修订计划
[`2026-08-13-cognitura-model-gate-routing.md`](../../superpowers/plans/2026-08-13-cognitura-model-gate-routing.md)
（固定 SHA `fac5f50c6a3f1afb743f95f40ac6b7f5e4e888e1`）。它们只迁移当前路由；上述已完成
`GOVERNANCE_REPAIR` 的 stacked route 仍是历史事实，不追溯改写。

| ID | 任务卡 | 依赖 | Gate | ReviewRoute |
|---|---|---|---|---|
| `VSB-00` | [治理、参考图与正式样式参考](VSB-00-governance-reference.md) | `GOVERNANCE_BOOTSTRAP` | `VSB-G0 GOVERNANCE_AND_REFERENCE` | `deep_reviewer` |
| `VSB-01` | [语义 CSS token 投影](VSB-01-semantic-tokens.md) | `VSB-00` | `VSB-G1 SEMANTIC_TOKENS` | `deep_reviewer` |
| `VSB-02` | [Module 默认阅读视觉实现](VSB-02-module-default-reading-visual.md) | `VSB-01` | `VSB-G2 MODULE_DEFAULT_READING_VISUAL` | `deep_reviewer / L3 / xhigh / ONE` |
| `VSB-03` | [固定视觉验收](VSB-03-fixed-visual-acceptance.md) | `VSB-02` | `VSB-G3 FIXED_VISUAL_ACCEPTANCE` | `deep_reviewer / L4 / xhigh / ONE`（default） |

每张业务候选先通过本卡 Gate 和固定 SHA 独立审查，再由只改 execution-state 的
直接子提交推进。Finding 必须用 `RETURN_TO_OWNER` 回到事实 Owner；不得修改后继卡
来掩盖失败。正式数据库写入与远程推送始终不在本集合授权内。
