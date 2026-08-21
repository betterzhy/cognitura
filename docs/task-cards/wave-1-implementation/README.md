# Cognitura Wave 1 Implementation Task Cards

```text
CanonicalProjectName = Cognitura
TaskCardSet = WAVE1_IMPLEMENTATION
TaskCardIDs = W1-I00,W1-I01,W1-I02,W1-I03,W1-I04,W1-I05,W1-I06,W1-I07,W1-I08,W1-I09,W1-I10,W1-I11,W1-I12,W1-I13
TaskCardCount = 14
ActiveTaskCard = W1-I06
TaskCardSetStatus = READY_FOR_EXECUTION
SuspendedTaskCard = NONE
SuspendedCandidateSHA = NONE
SuspendedCandidateMutation = NONE
ReadyTaskCardCount = 1
SuspendedTaskCardCount = 0
BusinessImplementation = USER_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
ImplementationGovernanceReviewedCandidate = 0211679431de535dd4d89a08257b54d8f4e0da82
ImplementationGovernanceReviewVerdict = GO_P0_0_P1_0_P2_0
```

本集合落实已批准的 Wave 1 来源接入实现切片规格。bootstrap 已创建书面卡集并完成
治理卡 I00。I01 已对固定候选 `6796079de8c919055ddc6538234254b50630a491`
完成零发现深审并关闭；I02 等待独立数据库 Gate，I03、I04 和 I05 已关闭且 I06 已原子释放为唯一 `READY` 卡。

## 1. 任务卡清单

| ID | 任务卡 | 状态 | 依赖 | Gate | 风险 |
|---|---|---|---|---|---|
| `W1-I00` | [实现治理](W1-I00-implementation-governance.md) | `DONE` | `NONE` | `W1-IG0` | `HIGH` |
| `W1-I01` | [来源领域内核](W1-I01-source-ingestion-domain.md) | `DONE` | `W1-I00` | `W1-IG1` | `HIGH` |
| `W1-I02` | [来源持久化](W1-I02-source-persistence.md) | `QUEUED` | `W1-I01` | `W1-IG2` | `HIGH` |
| `W1-I03` | [DOCX 安全闸](W1-I03-docx-security-gate.md) | `DONE` | `W1-I01` | `W1-IG3` | `HIGH` |
| `W1-I04` | [文本、列表与章节](W1-I04-text-list-section-parser.md) | `DONE` | `W1-I03` | `W1-IG4` | `HIGH` |
| `W1-I05` | [表格保真](W1-I05-table-fidelity.md) | `DONE` | `W1-I04` | `W1-IG5` | `HIGH` |
| `W1-I06` | [图片与关系](W1-I06-image-anchor-relationship-projection.md) | `READY` | `W1-I04,W1-I05` | `W1-IG6` | `HIGH` |
| `W1-I07` | [处理发布](W1-I07-revision-attempt-fencing-publication.md) | `BLOCKED_BY_DEPENDENCY` | `W1-I02,W1-I04,W1-I05,W1-I06` | `W1-IG7` | `HIGH` |
| `W1-I08` | [稳定引用与 lineage](W1-I08-stable-reference-reparse-lineage.md) | `BLOCKED_BY_DEPENDENCY` | `W1-I07` | `W1-IG8` | `HIGH` |
| `W1-I09` | [上传与处理命令](W1-I09-upload-processing-command-api.md) | `BLOCKED_BY_DEPENDENCY` | `W1-I07` | `W1-IG9` | `HIGH` |
| `W1-I10` | [来源预览查询](W1-I10-source-preview-query-api.md) | `BLOCKED_BY_DEPENDENCY` | `W1-I08,W1-I09` | `W1-IG10` | `HIGH` |
| `W1-I11` | [Partial acceptance](W1-I11-partial-acceptance-command-api.md) | `BLOCKED_BY_DEPENDENCY` | `W1-I10` | `W1-IG11` | `HIGH` |
| `W1-I12` | [Desktop Web 预览](W1-I12-desktop-web-source-preview.md) | `BLOCKED_BY_DEPENDENCY` | `W1-I10,W1-I11` | `W1-IG12` | `MEDIUM` |
| `W1-I13` | [固定实现复核](W1-I13-fixed-implementation-review.md) | `BLOCKED_BY_DEPENDENCY` | `W1-I00..W1-I12` | `W1-IG13` | `HIGH` |

## 2. 依赖与授权

```text
W1-I00 -> W1-I01
W1-I01 -> W1-I02
W1-I01 -> W1-I03 -> W1-I04 -> W1-I05 -> W1-I06
W1-I02 + W1-I04 + W1-I05 + W1-I06 -> W1-I07
W1-I07 -> W1-I08 + W1-I09 -> W1-I10 -> W1-I11
W1-I10 + W1-I11 -> W1-I12
W1-I00..W1-I12 -> W1-I13
```

任一时刻最多一张 READY。I01 需要单独业务授权，I02 还需要单独数据库 Gate；
隔离测试库不等于正式数据库写入授权。

## 3. 执行规则

1. 只执行唯一 READY 卡的精确 WriteSet，先 RED 后 GREEN。
2. 每张实现卡形成独立本地候选并由新的 reviewer 审查固定 SHA。
3. `raw/**`、`.idea/**`、正式数据库写入和远程推送始终禁止。
4. finding 返回事实 Owner 卡；I13 内不得修复。

## 4. 验证

```bash
bash tests/task-cards/verify-wave1-implementation-cards.sh
scripts/verify-wave1-implementation-cards \
  --cards-dir docs/task-cards/wave-1-implementation
scripts/verify-wave1-implementation
```
