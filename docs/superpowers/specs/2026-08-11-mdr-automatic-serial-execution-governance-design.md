# Cognitura MDR 自动串行执行治理设计

```text
DesignID = MDR-AUTO-EXEC-001
DesignDate = 2026-08-11
CanonicalProjectName = Cognitura
GovernedTaskCardSet = MDR-I00..MDR-I08
SelectedApproach = A
DesignDirectionStatus = USER_APPROVED
WrittenSpecReview = USER_APPROVED
ExecutionContinuationMode = AUTOMATIC_SERIAL_AFTER_EXPLICIT_SET_AUTHORIZATION
AutomaticSerialExecutionEntry = BLOCKED_BY_GOVERNANCE_BOOTSTRAP
ExecutionStateAuthority = NOT_CREATED
GovernanceImplementationAuthorization = USER_AUTHORIZED
SetBusinessImplementationAuthorization = USER_AUTHORIZED_PENDING_GOVERNANCE_BOOTSTRAP
HumanCheckpointRequirement = NONE_WITHIN_AUTHORIZED_SET
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
ActiveImplementationTaskCard = NONE
```

## 1. 目的

本设计固定 `MDR-I00..MDR-I08` 在未来获得明确业务实现授权后的自动持续执行方式。
它解决“每张卡完成后再次等待用户说继续”造成的停顿，同时保留任务卡的依赖、精确
写集、RED/GREEN、独立本地提交和固定提交审查。

本设计只建立执行治理，不释放任何卡，不授权业务实现，不修改 `web/**`、后端、
Schema、数据库或 `raw/**`。

## 2. 启动授权

自动串行执行只能由一次新的、明确的用户指令启动。该指令必须同时表达：

1. 授权执行 `ModuleDefaultReadingState` 的 MDR 卡集；
2. 从 `MDR-I00` 开始；
3. 允许在本卡集内按依赖自动推进。

书面卡片批准、设计 GO、“方案 A”选择或普通状态查询都不等同于启动授权。启动授权
不得推导出 Schema、数据库、后端、路由、正式数据库写入或远程推送权限。

### 2.1 治理 bootstrap 前置条件

现行 MDR 权威要求用户逐卡释放，部分卡片明文禁止自动释放后继卡，且卡内业务
`WriteSet` 不包含任务状态文件。因此，集合级启动授权在治理 bootstrap 固定候选取得
独立零发现审查前不得生效；不得直接用本规格覆盖现行权威。

后续治理实施计划必须为 bootstrap 固定以下完整 WriteSet，不得隐式增删：

```text
BootstrapWriteSet = AGENTS.md
BootstrapWriteSet = README.md
BootstrapWriteSet = docs/engineering/cognitura-design-index.md
BootstrapWriteSet = docs/task-cards/README.md
BootstrapWriteSet = docs/task-cards/module-default-reading-implementation/README.md
BootstrapWriteSet = docs/task-cards/module-default-reading-implementation/execution-state.md
BootstrapWriteSet = docs/task-cards/module-default-reading-implementation/MDR-I00-web-test-foundation.md
BootstrapWriteSet = docs/task-cards/module-default-reading-implementation/MDR-I01-canonical-narrative-projection.md
BootstrapWriteSet = docs/task-cards/module-default-reading-implementation/MDR-I02-question-conclusion-spine.md
BootstrapWriteSet = docs/task-cards/module-default-reading-implementation/MDR-I03-element-boundary-reading.md
BootstrapWriteSet = docs/task-cards/module-default-reading-implementation/MDR-I04-stage-chain-renderer-projection.md
BootstrapWriteSet = docs/task-cards/module-default-reading-implementation/MDR-I05-key-relation-projection.md
BootstrapWriteSet = docs/task-cards/module-default-reading-implementation/MDR-I06-source-entry-projection.md
BootstrapWriteSet = docs/task-cards/module-default-reading-implementation/MDR-I07-reading-first-composition.md
BootstrapWriteSet = docs/task-cards/module-default-reading-implementation/MDR-I08-fixed-slice-review.md
BootstrapWriteSet = scripts/verify-module-default-reading-implementation-cards
BootstrapWriteSet = tests/task-cards/verify-module-default-reading-implementation-cards.sh
```

bootstrap 必须同步删除或替换逐卡释放和“不得自动释放”条款，把
`execution-state.md` 建立为唯一可变运行态权威；AGENTS、中央索引、卡集索引和九卡正文
只能引用该权威，不得各自维护第二份 Active/READY/DONE 事实。bootstrap 初始账本仍为
九卡全部阻断、Active/Released 均为 `NONE`、业务实现未授权。

bootstrap 必须先 RED 后 GREEN，形成独立非 amend 本地固定提交并取得新的
`deep_reviewer = GO / P0=0 / P1=0 / P2=0`。该 GO 只证明自动执行治理可用，不释放
`MDR-I00`；之后仍须第 2 节定义的集合级启动授权。

## 3. 自动执行状态机

启动授权生效后，状态机按唯一串行路径运行：

```text
MDR-I00 READY/ACTIVE
  -> RED
  -> GREEN
  -> Gate PASS
  -> local fixed commit
  -> deep_reviewer GO
  -> MDR-I00 DONE
  -> MDR-I01 READY/ACTIVE
  -> ...
  -> MDR-I07 DONE
  -> MDR-I08 READY/ACTIVE
  -> ultra_gatekeeper GO|NO-GO
```

`MDR-I00..MDR-I07` 每卡只有在依赖为 `DONE`、精确写集验证通过且固定提交取得
`deep_reviewer = GO / P0=0 / P1=0 / P2=0` 后，才能自动关闭并释放下一卡。
`MDR-I08` 继续使用 `ultra_gatekeeper` 作整个固定切片的最终 GO/NO-GO。

任何时刻最多一张卡为 `READY/ACTIVE`。禁止跨卡并行、跳过依赖、把多卡混入同一提交
或提前修改下一卡写集。

## 4. 自动推进与恢复

以下活动属于已授权卡的正常执行，不需要再次请求用户确认：

- 写入并运行卡内 RED 测试；
- 在精确 WriteSet 内完成最小 GREEN；
- 修复普通测试、构建、静态检查或审查发现；
- 产生新的非 amend 本地候选提交；
- 对新固定 SHA 重新运行适用 Gate 和独立审查；
- 当前卡零发现关闭后自动把唯一后继卡转为 `READY/ACTIVE`。

业务提交和状态提交必须分离：

1. 当前卡的 RED/GREEN 候选只允许写该卡正文固定的业务 `WriteSet`；
2. 候选固定 SHA 取得零发现审查后，另建状态转换本地提交；
3. 状态转换提交的精确 WriteSet 只有
   `docs/task-cards/module-default-reading-implementation/execution-state.md`；
4. 该账本必须记录已关闭卡、业务候选 SHA、Gate 结果、审查角色与零发现收据、唯一
   后继卡及其新状态；缺少任一项时验证器拒绝转换；
5. 状态转换提交禁止 amend 和 push，并在提交前运行状态机负例、Canonical 验证器与
   `git diff --check`；它不得修改业务文件、卡片正文或中央索引。

由此，业务候选的精确写集和独立固定提交审查保持不变，而 `DONE -> READY/ACTIVE`
通过独立治理提交持久化，不会越过当前卡的业务 WriteSet。中央文档和逐卡正文只引用
同一运行态权威，恢复时不得从多个自报字段推断状态。

会话中断或上下文压缩后，执行者必须从磁盘重新读取 AGENTS、任务卡索引、唯一活动
卡、HEAD、工作区和最近 Gate 证据，然后继续该卡；不得另建并行计划或重复已关闭卡。

## 5. 停止条件

只有以下条件可以中断自动串行执行：

1. 用户明确要求暂停或停止；
2. 继续处理需要超出当前业务卡 WriteSet 或上述状态转换 WriteSet；
3. 需要新增或修改 Schema、数据库、后端、路由、`raw/**` 或正式事实 Owner；
4. 需要正式数据库写入、迁移、远程推送、部署或其他未授权外部副作用；
5. 出现真实 DocumentationGap，且无法在当前正式来源和卡片范围内裁决；
6. 同一真实 Gate 或审查阻断连续三轮复现，已完成系统化定位并穷尽卡内修复，且继续
   处理必须等待用户输入、外部状态变化或新增授权；
7. `MDR-I08` 返回最终 NO-GO，或返回 GO 并完成本卡集。

普通 RED、测试失败、构建失败、review finding 或需要在当前卡内形成新 SHA，不是暂停
理由；这些情况必须自动修复并重验。

## 6. 不可扩张边界

```text
ExistingWave1SourceWork = PRESERVE_UNCHANGED
SchemaChange = FORBIDDEN_IN_MDR_SET
DatabaseChange = FORBIDDEN_IN_MDR_SET
FormalDatabaseWrite = NOT_AUTHORIZED
BackendChange = FORBIDDEN_IN_MDR_SET
RouteAndAppIntegration = FORBIDDEN_IN_MDR_SET
RawWrite = FORBIDDEN
RendererCreatesIndependentFacts = NO
RemotePush = NOT_AUTHORIZED
IdeaDirectory = PRESERVE_UNTRACKED
```

`DOC-GAP-MDR-001` 继续阻断完整 Conditions/Results 验收，但不授权 Renderer 进行语义
猜测。若该缺口要求字段变更，自动执行必须停止并转入独立 Schema 设计/任务卡授权。

## 7. 验证设计

后续治理实现必须先增加失败合同，再更新状态机。至少覆盖：

- 没有明确启动授权时拒绝把 `MDR-I00` 转为 READY；
- bootstrap 未取得固定提交零发现 GO 时，即使出现集合级启动授权也拒绝 READY；
- 启动后恰有一张 READY/ACTIVE 卡；
- 依赖未 DONE 时拒绝释放后继卡；
- 当前卡未取得固定提交零发现 GO 时拒绝自动推进；
- 卡关闭后自动后继必须是依赖图中的唯一下一卡；
- 第二张 READY、跨卡 WriteSet、跳卡、amend、push 和禁区路径全部 fail closed；
- review finding 返回当前卡修复，而不是继续下一卡；
- 业务候选夹带状态文件、状态提交夹带业务文件或审查收据不匹配固定 SHA 时 fail closed；
- AGENTS、中央索引、卡集索引或任一卡重新维护第二份可变状态时 fail closed；
- 用户停止、DocumentationGap、权限扩张和 I08 NO-GO 都能保持可恢复状态；
- I08 GO 后卡集关闭，且不自动创建 Schema、数据库、页面或 Wave 1 source 卡。

验证入口必须继续兼容系统 Bash 3.2，并把状态索引、逐卡正文、提交写集和审查收据视为
同一合同，而不是依赖自报字段。

## 8. 完成定义

用户审阅并批准本书面规格后，才允许编写治理实施计划；规格批准本身不授权执行该
计划。治理实施计划只有在以下条件全部满足后才能进入执行：

- 上述 17 路径 bootstrap WriteSet 被该实施计划逐项固定；
- 实施计划明确先写 bootstrap RED 负例，再修改运行态权威和验证器；

自动串行执行入口只有在以下条件全部满足后才能打开：

- 自动执行状态、停止条件和授权边界在 `execution-state.md` 中有唯一投影，其他权威
  只保留引用；
- 任务卡验证器存在上述 RED 负例路线；
- bootstrap 独立固定提交取得 `deep_reviewer` 零发现 GO；
- 仍保持 `BusinessImplementation = NOT_AUTHORIZED` 和
  `ActiveImplementationTaskCard = NONE`，直到新的实现启动授权到达。

本规格获批也只授权编写治理实施计划，不授权执行 `MDR-I00`。

用户随后于 `2026-08-11` 另行明确要求“编写后自动执行，无需人工审核”。该后续指令
独立授权治理计划执行，并把第 2 节的集合级授权登记为
`USER_AUTHORIZED_PENDING_GOVERNANCE_BOOTSTRAP`；它只移除逐卡用户确认，不移除固定提交
独立审查，也不扩张 Schema、数据库、后端、路由、正式库写入或远程推送边界。
