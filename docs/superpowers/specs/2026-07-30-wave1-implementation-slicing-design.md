# Cognitura Wave 1 实现切片设计

```text
DesignDate = 2026-07-30
CanonicalProjectName = Cognitura
DesignScope = WAVE1_IMPLEMENTATION_SLICING
ApprovedDesignCandidate = 17dabff23b029e1a6fc7f47155f552ed3f16d775
CompleteWrittenDesignApproval = APPROVED_BY_USER
SlicingApproach = MEDIUM_FINE_GRAINED_RISK_SLICES
ProposedTaskCardCount = 14
SpecificationStatus = USER_APPROVED
UserWrittenReviewApprovalDate = 2026-07-30
ImplementationPlan =
  docs/superpowers/plans/2026-07-30-wave1-implementation-task-card-bootstrap.md
ImplementationPlanStatus = READY_AWAITING_EXECUTION_CHOICE
Wave1ImplementationTaskCardSet = NOT_CREATED
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. 目的与授权边界

本规格把已批准的 Wave 1 来源接入详细设计拆成可独立验证、独立提交和独立审查的
实现切片。它只定义任务卡大小、依赖、写集边界和 Gate，不创建 `W1-Ixx` 卡，
不授权业务代码、数据库 migration、Parser Provider、正式数据库写入、部署或推送。

用户已批准固定设计候选
`17dabff23b029e1a6fc7f47155f552ed3f16d775`，并批准采用 14 张中细粒度实现卡的
方向。本文写入后仍须由用户审阅书面规格；审阅通过后才允许编制实现计划并创建
任务卡集合。

## 2. 方案裁决

比较过三种粒度：

1. 9～10 张粗粒度卡：治理成本较低，但会把 Parser、持久化、API 或页面混入同一
   写集，失败原因和回滚边界不清晰。
2. 14 张中细粒度风险切片：每张卡只承担一个事实所有者或风险面，能够保持独立
   Gate，同时不把流程拆成大量机械小提交。
3. 18 张以上微卡：隔离最强，但依赖、状态同步和审查成本过高。

正式采用第 2 种。不得为了减少卡片数量重新合并数据库、Parser、安全、HTTP 和
Web UI 风险面，也不得为了满足数字机械拆分同一原子不变量。

## 3. 任务卡大小合同

每张实现卡必须同时满足：

```text
SingleFactOwnerOrRiskSurface = REQUIRED
PrimaryRuntimeBoundaryCount = 1
MaximumProductionFileCount = 8
DatabaseParserHttpWebCombination = FORBIDDEN
LocalCommitCount = 1
ReproducibleGateCount = 1
PositiveAndCriticalNegativeCoverage = REQUIRED
UnrelatedRefactor = FORBIDDEN
```

解释：

- `PrimaryRuntimeBoundaryCount = 1` 指卡片只能以 Domain、Persistence、Parser、
  HTTP 或 Web 中一个边界为主。
- 正式代码文件原则上不超过 8 个；测试、合成 fixture 和任务卡状态文件不计入
  该数字，但不得借此隐藏大规模生产写集。
- 超过 8 个正式代码文件时必须在卡片中声明
  `ProductionWriteSetException`、不可继续拆分的原子理由和独立 Gate 证据；否则
  validator 必须拒绝。
- 一张卡不得同时新增数据库 migration、Parser、Controller 和 Web 页面中的两个
  或更多边界。
- 每张卡只形成一个功能提交；Gate/状态关闭记录可以按固定候选复核要求形成后续
  独立提交。

出现以下任一信号必须拆卡：

- 同时拥有两个不同事实所有者；
- 同时需要单元测试、数据库集成测试和浏览器测试三种主 Gate；
- 任一子能力可以在不破坏契约的情况下独立回滚；
- 失败后无法从卡片名称判断应回退哪个边界；
- 写集需要跨 `source`、其他 server 模块和多个 Web 模块。

## 4. 任务卡集合

### W1-I00：实现准入与任务卡治理

```text
CardKind = GOVERNANCE
PrimaryBoundary = TASK_CARD_GOVERNANCE
DependsOn = USER_APPROVED_WRITTEN_SLICING_SPEC
BusinessCode = FORBIDDEN
```

经批准的 bootstrap 只创建实现卡索引和 14 张卡片文档，使 I00 成为唯一
`READY`。I00 随后负责完成实现卡 validator、负例夹具、统一验证入口、Gate
映射并复核 bootstrap 索引。它不修改 `server/`、`web/`、migration 或 `raw/`。

### W1-I01：来源接入领域内核

```text
CardKind = IMPLEMENTATION
PrimaryBoundary = SOURCE_DOMAIN
DependsOn = W1-I00
BusinessImplementationApproval = REQUIRED_BEFORE_READY
```

实现预注册校验、SHA-256、SourceDocument/SourceBinary/ProcessingRevision 身份、
幂等裁决和不可变领域状态。仅使用内存端口替身；不包含数据库、Parser、
Controller 或页面。

### W1-I02：来源持久化 Schema 与基础映射

```text
PrimaryBoundary = SOURCE_PERSISTENCE
DependsOn = W1-I01
DatabaseGate = REQUIRED_BEFORE_READY
```

实现 Flyway migration、MyBatis Mapper 和仓储端口适配，使用隔离的临时测试库
验证唯一约束与往返映射。不得连接或写入正式数据库，不实现 attempt 并发或
Parser。

### W1-I03：DOCX 安全闸

```text
PrimaryBoundary = DOCX_SECURITY
DependsOn = W1-I01
ExternalRelationshipAccessCount = 0
```

只实现 ZIP/XML/relationship 安全分类、资源上限和零外链访问保护。使用合成恶意
fixture；不生成 DocumentBlock，不读取 Golden Case 原件或 Redis 遗留链接目标。

### W1-I04：文本、列表与章节解析

```text
PrimaryBoundary = DOCX_PARSER
DependsOn = W1-I03
SupportedBlockTypes = HEADING,PARAGRAPH,LIST
```

实现闭集遍历、`sourceOrder`、标题层级、`sectionPath`、段落和列表规范化。只使用
合成 DOCX fixture，不处理表格、图片、发布或 HTTP。

### W1-I05：表格保真

```text
PrimaryBoundary = DOCX_TABLE_PARSER
DependsOn = W1-I04
```

实现表格行列、单元格文本、合并信息、单元格顺序和表格内文本证据。不得处理图片、
发布、持久化或页面。

### W1-I06：图片、锚点与外部关系投影

```text
PrimaryBoundary = DOCX_IMAGE_PARSER
DependsOn = W1-I04,W1-I05
ExternalRelationshipDereference = FORBIDDEN
```

实现 inline/table-cell 图片双射、锚点、不可变 media ref、图片 hash 和外部关系
字面值摘要。不得访问外部目标，不负责块集发布。

### W1-I07：revision/attempt fencing 与原子发布

```text
PrimaryBoundary = SOURCE_APPLICATION
DependsOn = W1-I02,W1-I04,W1-I05,W1-I06
```

实现 revision/attempt 生命周期、lease、generation、fenced CAS、候选块 staging、
block-set digest 和单事务发布。旧 lease 观察、迟到结果和部分写入必须由集成负例
拒绝。

### W1-I08：稳定引用、重解析与 lineage

```text
PrimaryBoundary = SOURCE_REFERENCE
DependsOn = W1-I07
```

实现 immutable reference tuple、source-scoped alias、profile 变更重解析和
lineage。禁止 alias retarget、跨 revision 静默替换和歧义自动裁决。

### W1-I09：上传与 processing 命令 API

```text
PrimaryBoundary = SOURCE_HTTP_COMMAND
DependsOn = W1-I07
```

实现上传、创建 processing revision、查询命令接受结果和稳定错误闭集。验证可信
Workspace 上下文、404 防枚举和内部字段不泄漏；不包含预览页面。

### W1-I10：来源预览查询 API

```text
PrimaryBoundary = SOURCE_HTTP_QUERY
DependsOn = W1-I08,W1-I09
```

实现 exact-revision keyset 查询、cursor revision 绑定、typed payload allowlist
和 partial 标识。Renderer、摘要和第二来源事实均禁止。

### W1-I11：Partial acceptance 命令 API

```text
PrimaryBoundary = SOURCE_HTTP_COMMAND
DependsOn = W1-I10
```

实现 exact revision、block-set digest、omissions digest、可信 actor 和幂等键绑定
的不可逆确认命令。不得夹带 Web 页面修改。

### W1-I12：Desktop Web 来源预览

```text
PrimaryBoundary = WEB_DOCUMENT_INGESTION
DependsOn = W1-I10,W1-I11
```

实现最小上传/processing/preview/partial-confirmation 投影，只消费正式 API。
必须显示 incomplete 顶部警告和受影响块标记；不得生成摘要、Renderer 或重写
来源事实。

### W1-I13：固定实现候选复核

```text
CardKind = FIXED_CANDIDATE_REVIEW
PrimaryBoundary = WAVE1_IMPLEMENTATION_GATE
DependsOn = W1-I00,W1-I01,W1-I02,W1-I03,W1-I04,W1-I05,W1-I06,W1-I07,W1-I08,W1-I09,W1-I10,W1-I11,W1-I12
```

冻结完整实现候选，运行 Wave 0、Wave 1 设计、实现合同、数据库集成、Parser
安全/保真、API 与 Web 回归。一般审查使用 `deep_reviewer`；最终 GO/NO-GO 按
当前 Repository 路由使用 `ultra_gatekeeper`。该 Gate 不得夹带修复，发现必须
返回对应实现卡形成新候选。

## 5. 依赖与释放规则

1. 书面规格经用户审阅批准后，才允许编制实现计划。
2. 实现计划通过后先 bootstrap `W1-I00` 至 `W1-I13` 的卡片文档和索引，仅
   `W1-I00` 为 `READY`；bootstrap 本身不实现 validator 或业务代码。
3. `W1-I00` 完成只证明卡集可执行；`W1-I01` 变为 `READY` 前必须取得用户对
   业务实现的明确授权。
4. `W1-I02` 变为 `READY` 前必须单独通过数据库 Gate；隔离临时测试库不等于
   正式数据库写入授权。
5. 任一时刻最多一张 `READY` 卡。依赖满足但未被选择的卡保持 `QUEUED`。
6. 卡片出现 P0/P1/P2 发现时不得释放下一卡。
7. 远程推送、正式数据库、部署和发布始终需要独立授权。

允许的主依赖路径为：

```text
I00 -> I01
I01 -> I02
I01 -> I03 -> I04 -> I05 -> I06
I02 + I04 + I05 + I06 -> I07 -> I08 -> I09 -> I10 -> I11
I10 + I11 -> I12
I00..I12 -> I13
```

该图表达依赖，不授权并行写入；主 Agent 仍维持唯一 `READY`。

## 6. 任务卡合同与验证

每张卡必须声明：

```text
TaskCardID
CardKind
Status
Gate
Risk
DependsOn
PrimaryBoundary
ProductionFileLimit
WriteSet
ForbiddenWriteSet
PositiveVerification
NegativeVerification
ReviewRoute
BusinessImplementationAuthorization
FormalDatabaseGate
RemotePush
```

实现卡 validator 至少验证：

- ID 闭集为 `W1-I00` 至 `W1-I13`，数量为 14；
- 唯一 `READY`、依赖闭合、COMPLETE 终态；
- `ProductionFileLimit = 8` 或存在严格异常说明；
- 每卡恰有一个 `PrimaryBoundary`；
- I00 不含业务写集；
- I02 未取得 Database Gate 时不得为 `READY`；
- I01 未取得业务实现授权时不得为 `READY`；
- server、Parser、HTTP、Web 的禁止组合；
- I13 必须依赖 I00 至 I12 且使用适用的两阶段固定候选复核。

## 7. 错误与回退

- 设计契约歧义：卡片转为 `BLOCKED_BY_DOCUMENTATION_GAP`，不得猜测实现。
- 写集超限：拆分任务卡；只有不可分原子事务才允许书面异常。
- 测试失败：保持当前卡为唯一活动卡，不释放依赖卡。
- 数据库 Gate 缺失：选择另一张依赖已满足的非数据库卡，仍只允许一张 READY。
- 固定候选发现：回到拥有该事实的最早卡修复，不在 I13 内修改。

## 8. 规格验收

本规格的验收条件：

```text
TaskCardCount = 14
SingleFactOwnerOrRiskSurface = REQUIRED
ProductionFileLimit = 8
OnlyI00InitiallyReady = REQUIRED
BusinessImplementation = NOT_AUTHORIZED
Wave1ImplementationTaskCardSet = NOT_CREATED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

验证命令：

```bash
rg -n '[T]BD|[T]ODO|[待]定' \
  docs/superpowers/specs/2026-07-30-wave1-implementation-slicing-design.md
bash tests/ci/verify-markdown-links.sh
bash tests/task-cards/verify-wave1-design-cards.sh
git diff --check
git status --short
```

用户已审阅并批准本书面规格。下一步只能按已落盘的 `writing-plans` 计划选择执行
方式，bootstrap 任务卡并完成治理卡 I00；仍不得直接创建业务代码。
