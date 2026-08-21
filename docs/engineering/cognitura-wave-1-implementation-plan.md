# Cognitura Wave 1 Implementation Plan

```text
CanonicalProjectName = Cognitura
PlanKind = EXECUTION_PROJECTION
FormalDesignAuthority = docs/design/wave-1/README.md
TaskCardAuthority = docs/task-cards/wave-1-implementation/README.md
TaskCardCount = 14
TaskCardSetStatus = READY_FOR_EXECUTION
ActiveTaskCard = W1-I09
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
Schema 基线。非业务治理卡 I00 和来源领域卡 I01 已关闭；I02、I03、I04、I05、I06 和 I07 已完成固定候选
零发现深审并关闭；I08 已关闭，I09 已释放为唯一 `READY` 卡。

## 1. 实现卡

| 卡片 | Owner / 风险面 | 依赖 | 当前状态 |
|---|---|---|---|
| `W1-I00` | Task-card governance | `NONE` | `DONE` |
| `W1-I01` | Source domain | `I00` | `DONE` |
| `W1-I02` | Source persistence | `I01` | `DONE` |
| `W1-I03` | DOCX security | `I01` | `DONE` |
| `W1-I04` | Text/list/section parser | `I03` | `DONE` |
| `W1-I05` | Table fidelity | `I04` | `DONE` |
| `W1-I06` | Image/relationship projection | `I04,I05` | `DONE` |
| `W1-I07` | Attempt fencing/publication | `I02,I04,I05,I06` | `DONE` |
| `W1-I08` | Stable reference/lineage | `I07` | `DONE` |
| `W1-I09` | Upload/processing command API | `I07` | `READY` |
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
I02DatabaseGate = PASS
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

## 10. I05 关闭收据

```text
W1-I05 = DONE
ReviewedCandidate = b4132e988cd88dce74ae026a1b52a496188452fc
ReviewedGovernanceCandidate = 244963db83f927d9bec1c01d15bbc1bed1f874b5
ReviewedGovernanceParent = 98d8c6939279c1cb76254771e393649e38b2b317
ReviewedGovernanceTree = e2c3050ad8134651fd168857f911c5af455e2a2b
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

## 11. I06 关闭收据

```text
W1-I06 = DONE
ReviewedCandidate = 2a7e1cec184ea50d9e0a5c37d6f3acfa63c955ea
ReviewedGovernanceCandidate = 2a7e1cec184ea50d9e0a5c37d6f3acfa63c955ea
ReviewedGovernanceParent = 091cccd28216dc9d69588874d82a65548e8a389a
ReviewedGovernanceTree = d87740229c75f8411347f291abdc2a5faf44e9cf
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
Ultra = NOT_RUN
I06ClosureTaskCardSetStatus = BLOCKED_BY_DATABASE_GATE
BlockedTaskCard = W1-I02
BlockedReason = INDEPENDENT_DATABASE_GATE_REQUIRED
ReleasedTaskCard = NONE
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 12. I02 Database Gate Admission Receipt

```text
W1-I02DatabaseGate = PASS
ReviewedGateCandidate = 042a039f8582a51e501530b629fb24fdb3b74c45
ReviewedGateParent = 3bc773b0ba78662b5be370d54536f8650b205085
ReviewedGateTree = 398b5eef25f7eddca01b3cad97a6df2acf3f0141
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
ReviewVerdict = GO
P0Findings = 0
P1Findings = 0
P2Findings = 0
Ultra = NOT_RUN
PostgreSQLTestImage = postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a
ExpectedPostgreSQLMajor = 18
IsolatedContainerLifecycle = PASS
ReleasedTaskCard = W1-I02
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 13. I02 关闭收据

```text
W1-I02 = DONE
ReviewedCandidate = 59144c9dfca4abacce62de41c7306021bf5b83f8
ReviewedParent = 525e75efe99ad91419c4d455c04bf3744abc7490
ReviewedTree = 592a1b5d427f61e24e7687a532ca8562070c0a8f
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
Ultra = NOT_RUN
I02ClosureReleasedTaskCard = W1-I07
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 14. I07 关闭收据

```text
W1-I07 = DONE
ReviewedCandidate = 094f62546cf7a13435c5d61f2a7bede21b86f099
ReviewedParent = 5433485e8f88f3846cbda722282223a3c8274b14
ReviewedTree = d82ece96e0e3dabdfef64a766179b711ea6d557f
ReviewedGovernanceCandidate = cee6ec623217efd845e5a7d96990c503f280c68c
ReviewedGovernanceParent = 5592e12b459614c189c44b3b1368d7109a6ffd00
ReviewedGovernanceTree = 170cde2a823a80a1fe4adb6fd346258b8fb93add
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
Ultra = NOT_RUN
I07ClosureReleasedTaskCard = W1-I08
QueuedTaskCard = W1-I09
QueuedReason = SERIAL_EXECUTION_ORDER
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 15. I08 关闭收据

```text
W1-I08 = DONE
ReviewedCandidate = 4890c8ec6af72e57e696845e8fc06a5552aafd45
ReviewedParent = c06ea6ed7efcb2ef04c085e3976d42814af0b3ea
ReviewedTree = 7db68e968432b8b7218a63aba9ea06d6a93a5782
ReviewedGovernanceCandidate = 6dfc075be803277c695b729001997345c512c34d
ReviewedVerifierCorrectionCandidate = 4c41a5e2b9360020487c6ae64c093d0d099f7222
ReviewedVerifierCorrectionParent = ad2f6224f75caf2b439b3c46bcfb9cd4da6b7357
ReviewedVerifierCorrectionTree = 26ec290170b196e4a057cbf4b849dc231503de5f
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
Ultra = NOT_RUN
I08ClosureReleasedTaskCard = W1-I09
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 16. W1-I09 runtime rebaseline receipt

```text
W1I09RuntimeRebaseline = PASS
ReviewedRejectedCandidate = 40bd055047479db91d618320f1ff569e3c651c77
ReviewedVerifierCorrectionCandidate = fc7dae8166b90ca5fb5f67e481140eceea20c564
ReviewedVerifierCorrectionParent = cd4d1b2b2ee0ce05d017f00899245c037a82577e
ReviewedVerifierCorrectionTree = 5ce3a4422c4e3721c7c09a10dfded7fdb0818e65
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
Ultra = NOT_RUN
ActiveTaskCard = W1-I09
TaskCardCount = 14
ReadyTaskCardCount = 1
I09ProductWriteSetCount = 27
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```
