# Cognitura 最小开发任务卡启动提示词

此文件只提供下一会话可复制的书面规划提示词。用户实际发送该提示词时，仅授权创建
和评审实现任务卡，不授权释放任务卡、编写业务代码、修改 Schema、执行数据库迁移、
正式数据库写入或远程推送。

## 可复制提示词

```text
请在 /Users/yuzhuangzhuang/Projects/cognitura 继续 Cognitura 工作，但本轮只做实现任务卡规划，不写业务代码。

开始前重新读取 AGENTS.md、README.md、docs/engineering/cognitura-design-index.md、正式高保真设计/验收/计划、docs/task-cards/README.md、Wave 1 既有设计与任务卡 bootstrap 计划；重新检查当前分支、HEAD、工作区、最近提交和全部适用 Gate。以实时状态为准，保留所有用户修改和未跟踪 .idea/，不得 reset、amend 或远程 push。

唯一目标：为首个 ModuleDefaultReadingState 实现切片创建小而独立、可按顺序验证的书面实现任务卡。每张卡必须固定依赖、精确逐文件写集、先 RED 后 GREEN 的测试、验证命令、完成 Gate、独立本地提交和独立固定提交审查；不得把完整页面、后端、持久化或 Schema 一次性合并进首卡。

边界：保留既有 Wave 1 source work；Schema 变更与数据库变更必须拆成独立后续卡，不得在首个 ModuleDefaultReadingState 卡中夹带；不得修改 raw/**，不得执行数据库迁移或正式数据库写入，不得远程推送。Renderer 只能投影正式认知产物，不得创造第二套事实。

先完成任务卡文本、索引、依赖、写集、RED/GREEN 验证和审查路线，并向用户汇报拟创建的卡集、首卡范围及所有授权边界。用户明确批准这些书面实现任务卡前立即停止：不得释放或执行任何实现卡，不得编写业务代码。

最终保持并输出：
DesignAlignmentStatus = COMPLETE
DevelopmentPlanningEntry = READY_FOR_USER_AUTHORIZATION
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
ActiveImplementationTaskCard = NONE
```
