# Cognitura 测试与 CI 策略

```text
DecisionDate = 2026-07-28
CanonicalProjectName = Cognitura
Scope = W0-07_TEST_AND_CI
CIProvider = GITHUB_ACTIONS
CanonicalVerificationEntry = scripts/verify-wave0
ModuleDefaultReadingVerificationEntry = scripts/verify-module-default-reading
WebComponentTestLayer = VITEST_REACT_TESTING_LIBRARY_JSDOM
WebComponentTestCIStage = INDEPENDENT_BEFORE_WAVE0
Workflow = .github/workflows/wave0.yml
ProductionCredentialAccess = FORBIDDEN
ProductionDatabaseWrite = FORBIDDEN
RedisLegacyLinkAccess = FORBIDDEN
LocalWave0Verification = PASS
FixedCommit = a332092ee1298c795d13de4af1fcab2e908aed9f
FixedCommitCI = PASS
CIURL = https://github.com/betterzhy/cognitura/actions/runs/30454379223
W0-G5 TestAndCI = PASS
```

本策略将已通过的 Wave 0 校验收敛到一个本地与 CI 共用的入口。它只建立质量
门禁，不承担部署、发布、正式数据库迁移或 Wave 1 业务验证。

## 1. Provider 裁决

W0-07 选择 GitHub Actions 作为 CI Provider。该裁决仅覆盖 Repository
提交和 Pull Request 的自动验证，不选择部署平台、对象存储或正式环境。

选择边界：

- Workflow 保存在 `.github/workflows/wave0.yml`；
- 使用 `push`、`pull_request` 和人工触发，不使用 `pull_request_target`；
- 默认权限缩减为 `contents: read`，checkout 不持久化凭据；
- 不读取 Repository secret，不申请写权限，不上传或发布产物；
- Action 依赖固定到完整 Git commit，不使用 `main`、大版本标签或浮动标签。

## 2. 统一验证顺序

`scripts/verify-wave0` 按以下固定顺序串行执行；任一阶段非零退出后立即停止，并将
总入口标记为 `Wave0Verification = FAIL`。

| 顺序 | Stage | 验证内容 | 既有权威入口 |
|---|---|---|---|
| 1 | `source` | 正式来源哈希、大小、角色与只读保护正反例 | `tests/source-manifest/verify-source-manifest.sh` |
| 2 | `task-card` | 任务卡状态机、Markdown 链接及 CI workflow 安全契约 | `tests/task-cards/verify-task-cards.sh`、`tests/ci/verify-markdown-links.sh`、`tests/ci/verify-ci-contract.sh` |
| 3 | `schema` | Schema、语义不变量、Evidence Map 与正反例 | `scripts/verify-json-schemas` |
| 4 | `golden` | 原件结构指纹、结果契约、隔离负例与 I/O Guard | `tests/golden-cases/verify-golden-cases.sh` |
| 5 | `ui` | 页面、Renderer、状态与 Desktop Web 契约 | `tests/contracts/ui/verify-ui-contracts.sh` |
| 6 | `server` | JDK 21 下 Maven verify 与模块边界测试 | `./mvnw -q verify` |
| 7 | `web` | 构建基线、依赖禁用项、冻结安装与生产构建 | `scripts/verify-build-baseline` |

Schema 与 Web 安装都使用提交的 pnpm lockfile 和 `--frozen-lockfile`。Maven 只通过
提交的 Maven Wrapper 运行，版本仍由技术基线和 wrapper 配置锁定。

## 3. CI 运行环境

```text
Runner = ubuntu-24.04
Java = TEMURIN_21
Node = 24.18.0
pnpm = 11.17.0
Maven = WRAPPER_3.9.16
PostgreSQLTestContainer =
  postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a
```

PostgreSQL 服务只存在于单次 CI job，使用专用临时名称和凭据。当前 Wave 0
空骨架不向该容器写业务数据，也不向应用注入数据库连接；后续数据库集成测试只能
显式连接该临时服务，禁止复用正式环境变量。

## 4. 缓存与依赖完整性

- Maven cache 的输入绑定根 `pom.xml`、`server/pom.xml` 和 Maven Wrapper 配置；
- pnpm cache 的输入绑定 Web 与 Schema 测试两个 `pnpm-lock.yaml`；
- 所有直接依赖继续使用精确版本，传递依赖由 lockfile 或 Maven BOM 固定；
- 缓存只加速下载，不替代 frozen lockfile、Maven verify 或任何契约测试。

## 5. 保护边界

CI 和本地总入口必须满足：

- 三份 `raw/*.docx` 和总体设计在运行前后哈希一致；
- Redis 原件中的遗留 `file:///` 目标只按归档结构验证，不跟随、不读取；
- 不配置正式数据库、生产对象存储、发布 token 或云厂商凭据；
- Renderer、Schema 与 Golden Case 校验只读取正式资产和临时夹具；
- Workflow 不维护第二套验证命令，唯一执行命令为 `scripts/verify-wave0`。

`tests/ci/verify-ci-contract.sh` 对以上静态边界做正例验证，并通过临时正式来源副本
制造哈希漂移，确认失败会传播到统一入口。临时夹具不得修改 Repository 原件。

## 6. Module 默认阅读组件测试层级

`ModuleDefaultReading` 使用 Vitest、React Testing Library、jest-dom、user-event 与
jsdom 组成 Web component test 层级。测试只从正式输入或测试内最小 fixture 投影
可访问 DOM，不访问生产凭据、不连接任何数据库，也不读取 `raw/**`。统一入口
`scripts/verify-module-default-reading` 先运行该切片全部组件测试，再运行 Web 生产
构建；任一步非零退出必须直接向本地调用方和 CI 传播。

GitHub Actions 在完整 Wave 0 Gate 前用独立 step 调用该入口。Workflow 不复制
Vitest 或 Vite 子命令，`tests/ci/verify-ci-contract.sh` 同时验证 step 唯一存在、未
设置 `continue-on-error`，并用临时失败 package 证明统一入口保留非零退出码。

## 7. Gate 证据

W0-G5 只有在以下证据同时存在时才可改为 `PASS`：

1. `bash tests/ci/verify-markdown-links.sh` 和
   `bash tests/ci/verify-ci-contract.sh` 通过；
2. `scripts/verify-wave0` 完整七阶段通过；
3. `bash tests/task-cards/verify-task-cards.sh` 和 `git diff --check` 通过；
4. 固定提交的 GitHub Actions 运行成功；
5. 任务卡记录可访问的固定提交 CI URL。

固定提交 `a332092ee1298c795d13de4af1fcab2e908aed9f` 已通过 GitHub Actions
[run #1](https://github.com/betterzhy/cognitura/actions/runs/30454379223)，且本地
七阶段入口保持通过，因此 `W0-G5 TestAndCI = PASS`。
