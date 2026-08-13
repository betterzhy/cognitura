# Cognitura Visual Style Baseline Governance Repair Design

## 1. Authority and scope

```text
CanonicalProjectName = Cognitura
DesignKind = ONE_TIME_GOVERNANCE_REPAIR
Status = DRAFT_PENDING_USER_REVIEW
OriginalVisualStyleSpecSHA = 70eefba5912e6884e4e7e1d6477a65f4091d6590
VisualStyleExecutionStateAuthority = docs/task-cards/visual-style-baseline/execution-state.md
GovernanceRepairOriginReceiptSHA = d47c8c7bd7355947b5e8e1de6c264d80c2e27c9a
ReviewedVSB00CandidateSHA = 737c053483d1f3d084d5f90d5c36f76b0ae8f5a3
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

本设计只修复 Visual Style Baseline 任务卡治理器中“审查修复提交无法形成合法候选”
的状态机矛盾。它不修改视觉产品要求、VSB-00 已审查业务树、VSB-01..03 的业务
范围、正式数据库授权或远端推送边界。

## 2. Confirmed problem

原规则同时要求：

1. finding 修复必须形成新的 non-amend commit 和新的 fixed SHA；
2. 最终业务候选相对其直接父提交必须恰好包含整张卡的完整 WriteSet；
3. release receipt 必须是最终候选的 ledger-only 直接子提交。

VSB-00 的合法历史为：

```text
c9fe3d6  ACTIVATE_SET receipt, releases VSB-00
47f4883  initial exact-nine-path business candidate
a0dc20b  reviewed correction, subset of the same VSB-00 WriteSet
737c053  reviewed correction, subset of the same VSB-00 WriteSet, final GO
d47c8c7  attempted ledger-only ADVANCE receipt, preserved as failed evidence
```

`c9fe3d6..737c053` 的累计差异恰好是 VSB-00 的九路径 WriteSet，但
`a0dc20b..737c053` 只包含最后一轮修复的四条路径。直接父差异规则因此拒绝了一个
由批准的 non-amend review loop 必然产生的合法最终候选。

禁止通过 reset、amend、squash、merge、force-push 或伪造重复九路径提交消除该矛盾。
`d47c8c7` 必须保留在 Git 历史中，不得被追认为普通 `ADVANCE` receipt。

## 3. Decision

采用两部分、一次性的治理修复：

1. 正常业务候选改为从当前 Owner 最近一次合法 release receipt 到最终 reviewed tip
   的线性累计候选；
2. 在失败 receipt 之后，以固定治理修复候选和 ledger-only
   `GOVERNANCE_REPAIR` receipt 建立新的 VSB-01 release anchor。

该方案同时保留 non-amend 审计历史、精确 WriteSet、单父链和下一张卡的干净起点。

## 4. Linear cumulative business candidate

### 4.1 Candidate start

对 `ADVANCE`、`RETURN_TO_OWNER`、`COMPLETE` 和 `FINAL_NO_GO`，验证器必须从最终
candidate 沿 first-parent 向前寻找当前 Owner 最近一次已通过完整 transition replay
的 ledger-only release receipt。该 receipt 必须：

- 恰有一个父提交；
- 只修改 `docs/task-cards/visual-style-baseline/execution-state.md`；
- 释放的 `ActiveTaskCard` 和 `ReleasedTaskCard` 等于 candidate Owner；
- 拥有正确的 completed prefix、next card、sequence 和不可变授权字段；
- 是该 candidate chain 上最近的合法 release/return/governance-repair receipt。

不得通过字段相似、提交信息、tag、branch name 或外部缓存识别起点。

### 4.2 Candidate chain

从 release receipt 的直接子提交到最终 reviewed candidate 的每个提交必须：

- 恰有一个父提交；
- 是前一提交的直接子提交；
- 至少修改一条路径；
- 使用 `git diff --no-renames` 后，其路径集合是当前 Owner WriteSet 的非空子集；
- 不修改 execution ledger、其他 VSB 卡的 WriteSet、Wave 1 projection、`server/**`、
  `schemas/**`、`raw/**`、historical evidence、`.idea/**` 或任何未授权路径。

最终 reviewed candidate 必须是该线性链的 tip。链内不得出现 merge commit、ledger
commit、空提交或另一张卡的 release receipt。

### 4.3 Cumulative exactness

验证器必须同时证明：

```text
git diff --no-renames <release-receipt>..<reviewed-candidate>
  path set == exact Owner WriteSet
```

路径集合必须 exact：missing、extra、rename/copy、mode-only hidden source、删除后换名、
跨卡路径和临时越权提交均 fail closed。每提交 subset 校验与最终累计 exact 校验缺一
不可。

review verdict 绑定最终 tip，而不是链中的初始候选或某个修复提交。每次 finding 继续
产生新的 non-amend tip，并重新取得 fixed-SHA review。

## 5. One-time GOVERNANCE_REPAIR

### 5.1 Repair governance candidate

从固定失败 receipt `d47c8c7bd7355947b5e8e1de6c264d80c2e27c9a` 到治理修复
candidate `G` 必须是线性单父链。该链的累计 WriteSet 只能包含：

```text
docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md
docs/superpowers/plans/2026-08-13-cognitura-vsb-governance-repair.md
docs/task-cards/visual-style-baseline/README.md
scripts/verify-visual-style-baseline-cards
tests/task-cards/verify-visual-style-baseline-cards.sh
```

每个提交仍须是该治理 WriteSet 的非空子集，且不得修改 execution ledger。`G` 必须对
完整累计治理 WriteSet 取得：

```text
deep_reviewer = GO / P0=0 / P1=0 / P2=0
ultra_gatekeeper = FINAL_GO / P0=0 / P1=0 / P2=0
```

一般 VSB 卡仍只需要原计划规定的 review route；双重 review 只适用于这次高风险治理
恢复和最终 VSB-03 Gate。

### 5.2 Repair receipt

`R` 必须是 `G` 的直接单父、ledger-only 子提交。`R` 不重新执行 VSB-00 业务审查，
而是记录已经完成的 `737c053...` 固定候选 review，并为 VSB-01 建立新 release anchor。

`R` 将 execution state 升级为 version 2，并新增以下唯一字段：

```text
ExecutionStateVersion = 2
GovernanceRepairStatus = PASS
GovernanceRepairSpecSHA = <this approved design commit SHA>
GovernanceRepairOriginReceiptSHA = d47c8c7bd7355947b5e8e1de6c264d80c2e27c9a
GovernanceRepairReviewedCandidateSHA = <G exact 40-character SHA>
GovernanceRepairReviewRoute = deep_reviewer+ultra_gatekeeper
GovernanceRepairReviewVerdict = FINAL_GO_P0_0_P1_0_P2_0
TransitionKind = GOVERNANCE_REPAIR
TransitionBaseSHA = <G exact 40-character SHA>
TransitionSequence = 3
```

以下业务状态必须精确保留：

```text
TaskCardSetStatus = IN_PROGRESS
ActiveTaskCard = VSB-01
ReleasedTaskCard = VSB-01
CompletedTaskCards = VSB-00
CurrentCandidateSHA = 737c053483d1f3d084d5f90d5c36f76b0ae8f5a3
CurrentGateStatus = VSB-G0_PASS
CurrentReviewRoute = deep_reviewer
CurrentReviewVerdict = GO_P0_0_P1_0_P2_0
VSB00CandidateSHA = 737c053483d1f3d084d5f90d5c36f76b0ae8f5a3
VSB00GateStatus = VSB-G0_PASS
VSB00ReviewRoute = deep_reviewer
VSB00ReviewVerdict = GO_P0_0_P1_0_P2_0
NextTaskCard = VSB-02
VisualImplementation = USER_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

VSB-01..03 的未完成 receipts 必须继续为 `NONE/NOT_RUN`。原视觉样式 spec SHA、冻结
W1-I03 SHA、historical evidence SHA 和所有授权边界保持不变。

### 5.3 One-time restriction

`GOVERNANCE_REPAIR` 只允许：

- 从 execution-state version 1 升级到 version 2；
- origin 精确等于 `d47c8c7...`；
- base tree 中 ledger 字节精确等于失败 receipt 的 ledger；
- transition base 精确等于已双重审查的 `G`；
- head 精确满足本节字段；
- diff 仅含 execution ledger。

version 2、`GovernanceRepairStatus = PASS` 或 sequence 大于等于 3 时，第二次
`GOVERNANCE_REPAIR` 必须 fail closed。后续所有 receipt 必须逐字保留全部 governance
repair 字段。

## 6. Failed receipt treatment

`d47c8c7...` 的 ledger 内容记录了正确的 VSB-00 review 事实，但它没有通过当时的
transition validator，因此：

- 不标记为合法 `ADVANCE`；
- 不作为 VSB-01 candidate start；
- 不删除、不改写、不 cherry-pick 为新事实；
- 只作为 `GovernanceRepairOriginReceiptSHA` 的固定审计证据。

`R` 才是 VSB-01 的合法 release receipt。VSB-01 的累计候选必须从 `R` 开始，不得把
设计、计划或治理修复代码透明地算入 VSB-01 WriteSet。

## 7. Validation requirements

真实 Git fixture 至少覆盖：

- VSB-00 的三提交累计候选 `c9fe3d6..737c053` 通过；
- 最后一提交只是 WriteSet 子集仍通过，但累计缺一条路径失败；
- 链中任一提交含 extra path、ledger、其他 Owner path、rename、merge 或空提交失败；
- 中间提交先越权后恢复最终 tree 仍失败；
- review SHA 不是 chain tip 失败；
- release receipt 不是最近合法 Owner receipt 失败；
- 固定 `d47c8c7` 不能作为普通 ADVANCE 或 VSB-01 anchor；
- governance repair chain 缺任一治理路径、含 extra path、修改 ledger 或非单父失败；
- repair 缺 deep/ultra 任一 GO、错误 spec/origin/base SHA、错误 preserved state 失败；
- 第二次 governance repair 失败；
- `R` 后 VSB-01 的单提交和多提交 exact WriteSet candidate 都通过；
- VSB-01 链试图吸收治理修复路径失败；
- STOP、RETURN、FINAL_NO_GO、COMPLETE、terminal restore 和 Wave 1 exact restore 保持兼容。

验证器必须继续使用 Git object/blob、`--no-renames`、单父检查和 byte-safe ledger读取；
不得引入用户可控 skip flag、信任 commit message、外部缓存或第二份状态权威。

## 8. Implementation and review sequence

```text
approved design commit
→ approved implementation plan commit
→ RED fixtures
→ minimal validator and task-card README change
→ focused/static/Markdown/Bash/diff Gates
→ governance repair candidate G
→ deep_reviewer zero-finding review
→ ultra_gatekeeper final zero-finding review
→ ledger-only GOVERNANCE_REPAIR receipt R
→ explicit transition verification
→ VSB-01 implementation resumes from R
```

任何 review finding 都在治理修复 WriteSet 内生成新的 non-amend tip，并重新进行两级
review；不得先写 `R` 再修复治理代码。

## 9. Acceptance

```text
HistoryRewrite = FORBIDDEN
FailedReceiptPreserved = PASS
VSB00ReviewedCandidatePreserved = PASS
MultiCommitCandidateExactWriteSet = PASS
PerCommitWriteSetSubset = PASS
LedgerInsideBusinessCandidateChain = ZERO
MergeInsideCandidateChain = ZERO
UnauthorizedPathInsideCandidateChain = ZERO
GovernanceRepairCount = EXACTLY_ONE
GovernanceRepairDeepReview = GO_P0_0_P1_0_P2_0
GovernanceRepairUltraReview = FINAL_GO_P0_0_P1_0_P2_0
VSB01ReleaseAnchor = GOVERNANCE_REPAIR_RECEIPT
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```
