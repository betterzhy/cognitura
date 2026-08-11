# Cognitura MDR 自动串行执行治理设计

```text
DesignID = MDR-AUTO-EXEC-001
DesignDate = 2026-08-11
CanonicalProjectName = Cognitura
GovernedTaskCardSet = MDR-I00..MDR-I08
SelectedApproach = A
DesignDirectionStatus = USER_APPROVED
WrittenSpecReview = AWAITING_USER_REVIEW
ExecutionContinuationMode = AUTOMATIC_SERIAL_AFTER_EXPLICIT_SET_AUTHORIZATION
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

会话中断或上下文压缩后，执行者必须从磁盘重新读取 AGENTS、任务卡索引、唯一活动
卡、HEAD、工作区和最近 Gate 证据，然后继续该卡；不得另建并行计划或重复已关闭卡。

## 5. 停止条件

只有以下条件可以中断自动串行执行：

1. 用户明确要求暂停或停止；
2. 继续处理需要超出当前卡精确 WriteSet；
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
- 启动后恰有一张 READY/ACTIVE 卡；
- 依赖未 DONE 时拒绝释放后继卡；
- 当前卡未取得固定提交零发现 GO 时拒绝自动推进；
- 卡关闭后自动后继必须是依赖图中的唯一下一卡；
- 第二张 READY、跨卡 WriteSet、跳卡、amend、push 和禁区路径全部 fail closed；
- review finding 返回当前卡修复，而不是继续下一卡；
- 用户停止、DocumentationGap、权限扩张和 I08 NO-GO 都能保持可恢复状态；
- I08 GO 后卡集关闭，且不自动创建 Schema、数据库、页面或 Wave 1 source 卡。

验证入口必须继续兼容系统 Bash 3.2，并把状态索引、逐卡正文、提交写集和审查收据视为
同一合同，而不是依赖自报字段。

## 8. 完成定义

本治理设计只有在以下条件全部满足后才能进入实施计划：

- 用户审阅并批准本书面规格；
- 自动执行状态、停止条件和授权边界在卡集索引中有唯一投影；
- 任务卡验证器存在上述 RED 负例路线；
- 仍保持 `BusinessImplementation = NOT_AUTHORIZED` 和
  `ActiveImplementationTaskCard = NONE`，直到新的实现启动授权到达。

本规格获批也只授权编写治理实施计划，不授权执行 `MDR-I00`。
