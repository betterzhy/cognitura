# MDR-I08 Fixed Slice Review

```text
TaskCardID = MDR-I08
CardKind = FIXED_CANDIDATE_REVIEW
Status = GOVERNED_BY_EXECUTION_STATE
ExecutionStateAuthority = docs/task-cards/module-default-reading-implementation/execution-state.md
Gate = MDR-IG8 FixedSliceReview
Risk = HIGH
DependsOn = MDR-I00,MDR-I01,MDR-I02,MDR-I03,MDR-I04,MDR-I05,MDR-I06,MDR-I07
PrimaryBoundary = MODULE_DEFAULT_READING_FIXED_GATE
ProductionFileLimit = 0
BusinessImplementationAuthorization = REQUIRED_BEFORE_RELEASE
SchemaChange = FORBIDDEN
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = ultra_gatekeeper
```

## 1. 目标

对 `MDR-I00..MDR-I07` 的固定完整切片候选作最终 GO/NO-GO；本卡不修代码。

## 2. 前置条件与输入

前八卡各自的固定提交均已由独立 `deep_reviewer` 给出
`GO / P0=0 / P1=0 / P2=0`，execution-state 账本已记录完整严格前缀并把本卡投影为
唯一活动且已释放卡，工作区只保留 `.idea/`。

## 3. 精确写集

```text
WriteSet = docs/task-cards/module-default-reading-implementation/README.md
WriteSet = docs/task-cards/module-default-reading-implementation/MDR-I08-fixed-slice-review.md
WriteSet = docs/engineering/cognitura-module-default-reading-implementation-acceptance.md
ForbiddenWriteSet = web/**,server/**,schemas/**,raw/**,.idea/**
```

## 4. RED -> GREEN

RED 先运行 `candidate_sha="$(git rev-parse HEAD)"`，把实际输出写入验收记录并保持：

```text
MDRFixedCandidate = 实际的 candidate_sha 输出
MDRFixedReview = NOT_RUN
ImplementationValidation = NOT_RUN
```

运行验收检查，预期因 `MDRFixedReview = NOT_RUN` 而失败。随后由新的
`ultra_gatekeeper` 在该固定 SHA 上检查精确树和完整 Gate。只有审查真实返回零发现
GO，才把验收记录改为 `MDRFixedReview = GO`；任何发现都返回事实 Owner 卡形成新
候选，本卡内禁止修复。

## 5. 验证命令

```bash
pnpm --dir web test -- src/modules/module-reading
pnpm --dir web build
scripts/verify-wave0
scripts/verify-wave1-design
scripts/verify-high-fidelity-design
scripts/verify-high-fidelity-visual
git diff --check
git status --short
first_slice_commit="$(git log --reverse --format=%H -- \
  web/src/test/test-environment.test.tsx | head -1)"
slice_base_sha="$(git rev-parse "${first_slice_commit}^")"
fixed_candidate_sha="$(git rev-parse HEAD)"
git diff --name-only "${slice_base_sha}..${fixed_candidate_sha}"
```

## 6. Gate 与完成定义

`ultra_gatekeeper = GO / P0=0 / P1=0 / P2=0`，候选写集恰等于前八卡并排除
`.idea/`、`raw/**`、Schema、数据库、后端、路由和 App 集成。Gate 只关闭首个可复用
前端投影切片，不关闭完整 Module 页面或总体 `ImplementationValidation`。

## 7. 提交与独立固定提交审查

审查前固定候选，不提交修复。审查 GO 后，验收记录形成独立治理提交：

```bash
git add docs/task-cards/module-default-reading-implementation/README.md \
  docs/task-cards/module-default-reading-implementation/MDR-I08-fixed-slice-review.md \
  docs/engineering/cognitura-module-default-reading-implementation-acceptance.md
git commit -m "docs: record module default reading slice review"
```

不远程推送，不自动释放任何后续 Schema、数据库、页面或 source 卡。
