# Cognitura Wave 1 Implementation Plan

```text
CanonicalProjectName = Cognitura
PlanKind = EXECUTION_PROJECTION
FormalDesignAuthority = docs/design/wave-1/README.md
TaskCardAuthority = docs/task-cards/wave-1-implementation/README.md
TaskCardCount = 14
TaskCardSetStatus = READY_FOR_EXECUTION
ActiveTaskCard = W1-I06
SuspendedTaskCard = NONE
SuspendedCandidateSHA = NONE
SuspendedCandidateMutation = NONE
BusinessImplementation = USER_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
ImplementationGovernanceReviewedCandidate = 0211679431de535dd4d89a08257b54d8f4e0da82
ImplementationGovernanceReviewVerdict = GO_P0_0_P1_0_P2_0
```

本文只投影已经批准的 Wave 1 来源接入设计和实现切片，不覆盖正式合同、总体设计或
Schema 基线。非业务治理卡 I00 和来源领域卡 I01 已关闭；I02 等待独立数据库 Gate，
I03、I04 和 I05 已关闭，I06 为唯一 `READY` 卡。

## 1. 实现卡

| 卡片 | Owner / 风险面 | 依赖 | 当前状态 |
|---|---|---|---|
| `W1-I00` | Task-card governance | `NONE` | `DONE` |
| `W1-I01` | Source domain | `I00` | `DONE` |
| `W1-I02` | Source persistence | `I01` | `QUEUED` |
| `W1-I03` | DOCX security | `I01` | `DONE` |
| `W1-I04` | Text/list/section parser | `I03` | `DONE` |
| `W1-I05` | Table fidelity | `I04` | `DONE` |
| `W1-I06` | Image/relationship projection | `I04,I05` | `READY` |
| `W1-I07` | Attempt fencing/publication | `I02,I04,I05,I06` | `BLOCKED_BY_DEPENDENCY` |
| `W1-I08` | Stable reference/lineage | `I07` | `BLOCKED_BY_DEPENDENCY` |
| `W1-I09` | Upload/processing command API | `I07` | `BLOCKED_BY_DEPENDENCY` |
| `W1-I10` | Preview query API | `I08,I09` | `BLOCKED_BY_DEPENDENCY` |
| `W1-I11` | Partial acceptance command | `I10` | `BLOCKED_BY_DEPENDENCY` |
| `W1-I12` | Desktop Web source preview | `I10,I11` | `BLOCKED_BY_DEPENDENCY` |
| `W1-I13` | Fixed implementation review | `I00..I12` | `BLOCKED_BY_DEPENDENCY` |

## 2. 依赖图

```text
I00 -> I01
I01 -> I02
I01 -> I03 -> I04 -> I05 -> I06
I02 + I04 + I05 + I06 -> I07
I07 -> I08 + I09 -> I10 -> I11
I10 + I11 -> I12
I00..I12 -> I13
```

依赖图不授权并行执行；任一时刻最多一张 READY。

## 3. 授权 Gate

```text
I01BusinessImplementationAuthorization = REQUIRED_BEFORE_READY
I02DatabaseGate = REQUIRED_BEFORE_READY
FormalDatabaseWrite = NOT_AUTHORIZED
DeploymentAndRelease = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

I02 的临时数据库测试授权与正式数据库写入授权严格分离。`raw/**` 原件只读，外部
relationship 目标禁止访问。

## 4. 统一验证

```bash
scripts/verify-wave1-implementation
```

当前入口只运行：

```text
Wave1DesignVerification
Wave1ImplementationTaskCardContractTests
Wave1ImplementationTaskCardValidation
```

后续业务卡只能在各自 Owner 内增加测试阶段，不得提前把未实现边界伪装为 PASS。

## 5. I00 完成条件

- 14 卡闭集、依赖、状态和写集边界通过 Bash 3.2 验证。
- 45 个 mutation 负例、合法 I01 授权态、COMPLETE 终态和业务授权阻断终态通过。
- Wave 0、Wave 1 design 与统一入口全部 PASS。
- 固定 I00 候选取得新的 `deep_reviewer` 零发现 GO。
- 关闭后 `ActiveTaskCard = NONE`、I01 保持 `BLOCKED_BY_USER_AUTHORIZATION`。

## 6. I00 关闭收据

```text
W1-I00 = DONE
ReviewedCandidate = 0211679431de535dd4d89a08257b54d8f4e0da82
GeneralReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
I00ClosureActiveTaskCard = NONE
NextTaskCard = W1-I01
NextTaskCardStatus = BLOCKED_BY_USER_AUTHORIZATION
```

## 7. I01 关闭收据

```text
W1-I01 = DONE
ReviewedCandidate = 6796079de8c919055ddc6538234254b50630a491
GeneralReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
I01ClosureReleasedTaskCard = W1-I03
QueuedTaskCard = W1-I02
QueuedReason = INDEPENDENT_DATABASE_GATE_REQUIRED
```

## 10. I05 关闭收据

```text
W1-I05 = DONE
ReviewedCandidate = b4132e988cd88dce74ae026a1b52a496188452fc
ReviewedGovernanceCandidate = e7b1d0750a96037410b94778f84512a123a970f0
ReviewedGovernanceParent = c8e850f17e580ead5ce8f4d6dc5a92fcbfc1cda9
ReviewedGovernanceTree = 9ddc2d0e616b385ceb3099307840129b1868ca4e
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
Ultra = NOT_RUN
I05ClosureReleasedTaskCard = W1-I06
QueuedTaskCard = W1-I02
QueuedReason = INDEPENDENT_DATABASE_GATE_REQUIRED
```

## 8. I03 关闭收据

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

## 9. I04 关闭收据

```text
W1-I04 = DONE
ReviewedCandidate = 4594406e9fd8a9ac380c3b2b880fda67271790bc
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
Ultra = NOT_RUN
I04ClosureReleasedTaskCard = W1-I05
QueuedTaskCard = W1-I02
QueuedReason = INDEPENDENT_DATABASE_GATE_REQUIRED
```
