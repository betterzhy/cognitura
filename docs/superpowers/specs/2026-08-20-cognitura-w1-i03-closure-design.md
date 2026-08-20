# Cognitura W1-I03 Closure Design

```text
CanonicalProjectName = Cognitura
DesignKind = ONE_TIME_GOVERNANCE_TRANSITION
TransitionKind = I03_CLOSE_ADVANCE
ClosureOriginSHA = cc25439de8019a4434c2ab5aba8b32927240d8b4
ReviewedCandidateSHA = 4e63936c631ab34807e714b90d30415a959bc13d
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
Ultra = NOT_RUN
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. 目的与边界

本设计只补足 `W1-I03 = DONE -> W1-I04 = READY` 的一次性、可重放关闭收据。
它不建立通用任务状态机、不建立第二份 execution ledger、不修改 W1-I03 production、
不授权 W1-I04 implementation、不释放 W1-I02，也不改变数据库、部署或 push 边界。

W1-I03 固定候选已在恢复收据之后完成一次适用的最高门禁：
`deep_reviewer / xhigh / ONE / GO / P0=0 / P1=0 / P2=0`。关闭动作只能机械投影
这项事实；不得重新解释、替换或堆叠 Ultra 审查。

## 2. 两阶段拓扑

### 2.1 Closure contract governance chain

从固定 `ClosureOriginSHA` 起，只允许以下四个治理路径各改变一次：

```text
docs/superpowers/specs/2026-08-20-cognitura-w1-i03-closure-design.md
docs/superpowers/plans/2026-08-20-cognitura-w1-i03-closure.md
tests/task-cards/verify-wave1-implementation-cards.sh
scripts/verify-wave1-implementation-cards
```

治理链的每个提交必须单父、非空；不得出现 rename/copy、NUL、mode 漂移或四路径外
变化。两个文档固定为 `100644`，production verifier 与 test 固定为 `100755`。
每个路径一旦首次出现新 blob，后续治理提交不得再次修改，防止 introduce-restore
隐藏漂移。整个治理链不得修改十一条 closure projection、W1-I03 production、ledger、
VSB、Wave1 I02 或任何后续业务卡。

治理链 tip 处仍必须是：`W1-I03 = READY`、`W1-I04 = BLOCKED_BY_DEPENDENCY`，并输出：

```text
W1I03ClosureStatus = PENDING
```

### 2.2 Projection-only closure receipt

closure receipt 必须是治理链 tip 的直接单父子提交，且只修改以下十一条路径：

```text
AGENTS.md
README.md
docs/design/wave-1/README.md
docs/engineering/cognitura-design-index.md
docs/engineering/cognitura-wave-1-design-plan.md
docs/engineering/cognitura-wave-1-design-acceptance.md
docs/engineering/cognitura-wave-1-implementation-plan.md
docs/task-cards/wave-1/README.md
docs/task-cards/wave-1-implementation/README.md
docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md
docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md
```

十一条路径必须全部保留 parent mode，receipt 不得包含 verifier、tests、production、
ledger、VSB 或其他路径。receipt 完成后只允许以下状态变化：

```text
TaskCardSetStatus = READY_FOR_EXECUTION
ActiveTaskCard = W1-I04
W1-I03 Status = DONE
W1-I04 Status = READY
ReadyTaskCardCount = 1
SuspendedTaskCardCount = 0
W1-I02 Status = QUEUED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

所有中央 `Active...TaskCard` 投影必须为 `W1-I04`；I03/I04 的卡身、索引表和实施计划
表必须逐字一致。所有 Ready 叙事必须从 “I03 唯一 READY” 原子变为
“I03 已零发现关闭，I04 唯一 READY”。

## 3. 固定审查收据

`docs/engineering/cognitura-wave-1-implementation-plan.md` 必须追加且仅追加一次以下闭集：

```text
W1-I03 = DONE
ReviewedCandidate = 4e63936c631ab34807e714b90d30415a959bc13d
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
Ultra = NOT_RUN
I03ClosureReleasedTaskCard = W1-I04
QueuedTaskCard = W1-I02
QueuedReason = INDEPENDENT_DATABASE_GATE_REQUIRED
```

该块必须按上述顺序连续、exact-once。缺失、重复、重排、未知 closure 字段、候选 SHA
错误、非零 finding、非 `GO`、Ultra 执行或释放非 I04 卡均 fail closed。

## 4. 固定 production 与授权边界

从 `ReviewedCandidateSHA` 到治理链 tip、closure receipt 和 working tree，W1-I03 卡片
WriteSet 的全部文件和目录必须 byte-identical。任何修改、删除、mode 漂移、rename/copy
均拒绝。`raw/**`、`.idea/**`、正式数据库和外部 relationship 目标始终禁止访问。

I02 必须保持 `QUEUED` 和 `INDEPENDENT_DATABASE_GATE_REQUIRED`；不得因 I03 关闭而
推断数据库 Gate。I04 只获得任务卡执行入口，不获得跨 WriteSet、数据库、部署或 push
权限。

## 5. Public verifier 合同

沿用现有公共入口，不新增通用 CLI：

```bash
scripts/verify-wave1-implementation-cards \
  --repo-root . \
  --cards-dir docs/task-cards/wave-1-implementation

scripts/verify-wave1-implementation-cards \
  --repo-root . \
  --cards-dir docs/task-cards/wave-1-implementation \
  --transition-base <governance-tip> \
  --transition-head <closure-receipt>
```

静态入口在治理 tip 输出 `PENDING`，在合法 receipt 输出：

```text
W1I03ClosureStatus = PASS
TaskCardSetStatus = READY_FOR_EXECUTION
ActiveTaskCard = W1-I04
```

transition 入口必须验证 direct-child、四路径治理 provenance、十一路径机械投影、固定
候选 identity 和审查收据闭集。现有 VSB restore transition 保持独立，禁止复用或放宽。

## 6. 必需测试矩阵

focused contract 至少包含：合法治理 `PENDING`、合法 explicit receipt、合法 static
receipt 三个正例；以及以下独立负例：治理链 merge/empty/outside/duplicate-path/
rename/copy/NUL/mode、候选 production drift、receipt 非 direct child、receipt 缺失或额外
路径、I03 非 DONE、I04 非 READY、两个 READY、释放 I02/错误后继、数据库或 push 授权
漂移、审查块缺失/重复/重排/错误 SHA/非零 finding/Ultra executed、叙事残留 I03 READY、
第二次 closure 和 working-tree masking。

所有 fixture 使用真实 Git commit/tree/blob，经公共 verifier 入口验证，并检查 invocation-
owned TMPDIR cleanup。测试不得读取 `raw/**`、`.idea/**` 或 `temp-input/**`。

## 7. 完成条件

1. Authority、tests-only RED、production GREEN 分别形成线性治理提交；
2. closure-contract focused、Wave1 task-card full、Bash 3.2、tracked-only Markdown 和
   `git diff --check` 全部 PASS；VSB static 必须在固定 `ClosureOriginSHA` tree 上 PASS，
   且 VSB execution ledger 的 blob/mode 从该 origin 到治理候选、closure receipt 与
   working tree 全程 byte-identical；不得为了让后续治理提交伪装成第二次 Wave1
   restore 而修改或放宽 VSB verifier；
3. 固定 closure-contract 候选完成一次 `deep_reviewer/xhigh/ONE` 零 finding GO；
4. 十一路径 closure receipt 完成 explicit 与 static replay；
5. 最终状态仅 `W1-I04` 为 READY，I03 production、I02、VSB、ledger、数据库与 push
   边界均未变化。
