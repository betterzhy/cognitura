# Cognitura W1-I11 关闭与 W1-I12 释放设计

```text
ChangeRisk = R2
Scope = W1_I11_FIXED_CANDIDATE_CLOSURE_ONLY
ProductCandidate = bc617d1d3c21c13b81d8fb17e23cf26f2d003606
ProductParent = 612616c65309da837cfea9aa3b60dae4f2f1dad3
ProductTree = 26f72cbfb57fde2830cfa664bb2aea1ef7b242cd
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. 目标与边界

本切片只把已经通过固定候选 `deep_reviewer / xhigh` 零 finding 审查的
W1-I11 投影为 `DONE`，并把依赖 `W1-I10,W1-I11` 均已满足的 W1-I12
释放为唯一 `READY` 卡。

本切片不修改 I11 产品字节，不重跑或替代产品审查，不释放 W1-I13，不授权正式数据库
写入、部署或远程推送，也不建立通用 Harness、通用状态机或第二份运行态事实。

## 2. 固定产品证据

- Candidate、Parent、Tree 必须逐字等于头部固定值。
- 从 I11 持久化重基线投影到 ProductCandidate 的累计产品差异必须恰好等于当前
  W1-I11 卡片的 16 条 `WriteSet`。
- 关闭治理链和关闭投影不得修改任一 I11 产品路径。
- 已有同候选证据可复用：I11 聚焦 21/21、旧迁移回归 17/17、server 179/179、
  完整 Wave Gate exit 0。

## 3. 最小治理链

关闭治理使用三个 append-only 单路径提交：

1. 本设计文件；
2. `tests/task-cards/verify-wave1-implementation-cards.sh` 的真实 Git 聚焦合同；
3. `scripts/verify-wave1-implementation-cards` 的生产验证路由。

每步必须单父、非空、精确单路径、正确 mode、无 rename/copy、无 NUL。前两步固定
evidence blob；第三步作为待审治理候选，由一次新的 `deep_reviewer / xhigh` 结果作为
仓库外信任根。关闭收据必须记录该治理候选及其 Parent/Tree，且关闭投影必须是它的
直接子提交。不得再为“让脚本自证自身审查”追加递归验证器。

## 4. 精确关闭投影

关闭投影恰好修改以下 11 个路径：

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
docs/task-cards/wave-1-implementation/W1-I11-partial-acceptance-command-api.md
docs/task-cards/wave-1-implementation/W1-I12-desktop-web-source-preview.md
```

投影后的正式状态必须同时满足：

```text
TaskCardSetStatus = READY_FOR_EXECUTION
ActiveTaskCard = W1-I12
ReadyTaskCardCount = 1
W1-I11 = DONE
W1-I12 = READY
W1-I12.BusinessImplementationAuthorization = USER_AUTHORIZED
W1-I13 = BLOCKED_BY_DEPENDENCY
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

11 个文件只能发生为上述状态转换预定义的字段、表格、叙述和终端收据变化；其余字节
必须相对治理候选冻结。implementation plan 末尾追加唯一且终端的
`## 21. I11 关闭收据`，记录产品候选、治理候选、审查路由、零 finding、释放 W1-I12
以及未授权边界。

## 5. 后继边界

关闭收据之后，只允许 W1-I12 卡片列出的 10 条 `WriteSet` 作为产品后继路径；仍要求
单父、非空、无 rename/copy、正确 mode 和无 NUL。任何治理重入、I11 产品漂移、
W1-I13 提前释放或 I12 WriteSet 外写入必须 fail closed。

## 6. 聚焦合同

聚焦合同至少包含 2 个正例：合法显式转换、合法静态状态；以及以下真实 Git 负例：

1. 错误 Product Candidate/Parent/Tree 或非零 finding；
2. 错误治理 Candidate/Parent/Tree；
3. 第二张 READY 卡或 W1-I13 提前释放；
4. W1-I12 未授权或 Active/ReadyCount 漂移；
5. 正式数据库或远程推送被授权；
6. 关闭投影缺少、增加、rename/copy 路径；
7. I11 产品字节漂移；
8. 收据后写入超出 W1-I12 WriteSet。

只运行能证伪本切片的聚焦合同、Bash 3.2 syntax、静态验证与 `git diff --check`；候选
稳定后执行一次治理候选 xhigh 审查。不得因本关闭切片重复产品全量门禁。
