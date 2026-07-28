# W0-03 技术栈与模块化单体骨架

```text
TaskCardID = W0-03
Status = BLOCKED_BY_DEPENDENCY
Gate = W0-G2A BuildBaseline
Risk = HIGH
DependsOn = W0-02
ReviewRoute = MAIN_AGENT_GATE
```

## 1. 目标

在不实现业务功能的前提下，固定完整前后端技术版本，建立可重复构建的模块化单体
与 Desktop Web 最小骨架，并用自动化验证阻止架构越界。

## 2. 前置条件与输入

- `W0-G2 SpecialtyContractCoverage = PASS`
- `docs/engineering/cognitura-technology-baseline.md`
- 总体设计第 22～26 章
- 已完成的局部进度：

```text
BackendTechnologySelection = PASS
BackendTechnologyCommit = 79fc305
FrontendTechnologySelection = NOT_STARTED
BuildSkeleton = NOT_STARTED
```

局部进度不构成本卡 Gate 通过。

## 3. 写集

- Modify: `docs/engineering/cognitura-technology-baseline.md`
- Create: `docs/engineering/cognitura-module-boundaries.md`
- Create: `server/`
- Create: `web/`
- Create: 根构建、版本锁、Maven Wrapper 和前端 lockfile
- Create: `scripts/verify-build-baseline`
- Create: `tests/build-baseline/`
- Modify: `README.md`
- Modify: `docs/task-cards/README.md`
- Modify: `docs/task-cards/W0-03-build-baseline.md`
- Modify: `docs/task-cards/W0-04-json-schema-source.md`
- Modify: `docs/engineering/cognitura-wave-0-plan.md`
- Modify: `docs/engineering/cognitura-wave-0-entry-decision.md`

禁止创建业务生成、文档解析、持久化用例或产品页面实现。

## 4. 执行步骤

- [x] 固定 JDK 21、Maven 3.9.16、Spring Boot 4.1.0、PostgreSQL 18 和 MyBatis 4.0.0。
- [ ] 形成前端技术裁决，固定 React、TypeScript、Node、构建工具和包管理器精确版本。
- [ ] 先编写 server/web 构建、健康检查、模块边界和禁用依赖的失败验证。
- [ ] 运行验证并确认因骨架和 lockfile 尚未存在而失败。
- [ ] 创建单 Spring Boot 部署单元、Maven Wrapper、健康检查和模块边界。
- [ ] 创建 Desktop Web 最小入口、前端 lockfile 和空模块边界，不实现产品页面。
- [ ] 固定 `source`、`cognition`、`generation`、`reading`、`llm` 以及九个 web 模块边界。
- [ ] 验证依赖树不含微服务、Kafka、Neo4j、Elasticsearch、JPA、MyBatis-Plus 或默认 WebFlux。
- [ ] 记录实际 BOM 解析版本、PostgreSQL 18 容器 tag/digest 和本地等价构建命令。
- [ ] 更新卡片状态并形成独立提交。

## 5. 验证命令

```bash
scripts/verify-build-baseline
./mvnw --version
./mvnw -q verify
bash tests/task-cards/verify-task-cards.sh
git diff --check
```

前端构建命令由本卡第二步正式记录到技术基线并由
`scripts/verify-build-baseline` 统一调用，本卡不得在裁决前假定包管理器。

## 6. Gate 与完成定义

- Java、Maven、Spring Boot、数据库、前端和包管理器版本全部固定；
- server/web 均可离线或按 lockfile 重复构建；
- Spring Boot 只提供启动和健康检查，web 只提供空入口；
- 模块边界验证通过，禁止依赖清单为空；
- 没有业务功能、微服务或越界基础设施；
- 本地构建、基线校验和任务卡集合校验全部通过。

```text
W0-G2A BuildBaseline = PASS
```

## 7. 提交与审查

```text
CommitMessage = build: establish Cognitura modular monolith baseline
CommitReview = MAIN_AGENT_GATE
NextTaskCardOnPass = W0-04
```

如果依赖解析与技术基线不一致，先更新裁决证据并重新验证，不得静默漂移版本。
