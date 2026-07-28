# Cognitura 技术基线

```text
DecisionDate = 2026-07-28
CanonicalProjectName = Cognitura
BaselineScope = W0-03_FULL_STACK_BUILD_BASELINE
BackendTechnologyBaseline = FORMAL
FrontendTechnologyBaseline = FORMAL
W0-G2A BuildBaseline = PASS
Wave1FeatureDevelopmentEntry = NO_GO
```

本基线固定 Cognitura V1 前后端工程骨架所使用的技术与版本。它授权 `W0-03`
创建最小构建、模块边界和健康检查，不授权业务功能开发。

## 1. 正式版本裁决

| 范围 | 正式选择 | 版本策略 |
|---|---|---|
| Java | Eclipse Temurin 或等价 OpenJDK | `21` LTS；编译 `release=21` |
| 构建工具 | Apache Maven | `3.9.16` |
| 构建入口 | Maven Wrapper | `3.3.4`；Repository 中提交 wrapper 配置 |
| 应用框架 | Spring Boot | `4.1.0` |
| 模块化单体治理 | Spring Modulith | `2.1.0` |
| Web 运行模型 | Spring MVC | 版本由 Spring Boot `4.1.0` 管理 |
| 数据库 | PostgreSQL | `18`；开发、测试、生产保持相同主版本 |
| JDBC 驱动 | pgJDBC | `42.7.11` |
| 连接池 | HikariCP | 版本由 Spring Boot `4.1.0` 管理 |
| 数据访问 | MyBatis Spring Boot Starter | `4.0.0` |
| 数据库迁移 | Flyway | 由 Spring Boot BOM 管理；同时引入 PostgreSQL 数据库模块 |
| JSON | Jackson + PostgreSQL `jsonb` | 版本由 Spring Boot 管理；使用显式 MyBatis TypeHandler |
| AI 集成 | Spring AI BOM | `2.0.0`；仅在 `llm` 模块的 Provider Adapter 内使用 |
| 单元/集成测试 | JUnit 5、Spring Boot Test、Testcontainers | 版本由 Spring Boot BOM 管理 |

上述精确版本是后续生成构建文件时的唯一输入。被 Spring Boot BOM 管理的库
不得在子模块中任意覆盖版本；确需覆盖时必须记录兼容性或安全原因及依赖树证据。

### 1.1 前端正式版本

| 范围 | 正式选择 | 精确版本 |
|---|---|---|
| JavaScript 运行时 | Node.js LTS | `24.18.0` |
| 包管理器 | pnpm + Corepack | `11.17.0` |
| UI 框架 | React / React DOM | `19.2.8` |
| 类型系统 | TypeScript | `7.0.2` |
| 构建工具 | Vite | `8.1.5` |
| React 构建插件 | `@vitejs/plugin-react` | `6.0.4` |
| React 类型 | `@types/react` | `19.2.17` |
| React DOM 类型 | `@types/react-dom` | `19.2.3` |

Node 版本由根 `.node-version` 锁定，pnpm 版本同时由 `web/package.json` 的
`packageManager` 与 `engines` 锁定。所有直接依赖使用精确版本，不使用
`^`、`~`、动态标签或范围；传递依赖由 `web/pnpm-lock.yaml` 固定。

## 2. 选择依据与兼容性

- Spring Boot `4.1.0` 的最低 Java 版本为 17，并支持至 Java 26，因此与
  JDK 21 兼容；其 Maven 最低要求为 3.6.3。
- Apache Maven `3.9.16` 是 Maven 3 当前推荐稳定版；不采用 Maven 4 RC。
- MyBatis Spring Boot Starter `4.0.0` 面向 Spring Boot 4.0+ 和 Java 17+，
  与本基线兼容。
- Spring AI `2.0.x` 支持 Spring Boot 4.0.x 与 4.1.x。
- Spring Modulith `2.1.x` 与 Spring Boot 4.1 版本线对齐，用于验证模块依赖、
  编写模块集成测试和生成模块文档。
- PostgreSQL `18` 是当前稳定主版本；Flyway 的 PostgreSQL 支持通过独立
  `flyway-database-postgresql` 模块启用。
- Node `24.18.0` 属于 Node 24 LTS 版本线；生产构建不采用奇数版本线。
- React `19.2.8`、TypeScript `7.0.2`、Vite `8.1.5` 与
  `@vitejs/plugin-react 6.0.4` 已由实际 lockfile 安装和生产构建验证。
- TypeScript 7 当前不提供稳定的 programmatic API，但 Cognitura Web 基线只通过
  `tsc` CLI 执行普通 React 类型检查，不依赖语言服务嵌入或编译器 API。

权威版本来源：

- [Spring Boot System Requirements](https://docs.spring.io/spring-boot/4.1/system-requirements.html)
- [Apache Maven Download](https://maven.apache.org/download.cgi)
- [Maven Wrapper](https://maven.apache.org/wrapper/)
- [MyBatis Spring Boot Starter](https://mybatis.org/spring-boot-starter/mybatis-spring-boot-autoconfigure/)
- [Spring Modulith](https://spring.io/projects/spring-modulith)
- [Spring AI Getting Started](https://docs.spring.io/spring-ai/reference/getting-started.html)
- [PostgreSQL Releases](https://www.postgresql.org/support/versioning/)
- [pgJDBC](https://jdbc.postgresql.org/)
- [Flyway PostgreSQL](https://documentation.red-gate.com/fd/postgresql-database-277579325.html)
- [Node.js Releases](https://nodejs.org/en/about/previous-releases)
- [React Versions](https://react.dev/versions)
- [TypeScript 7.0](https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/)
- [Vite Releases](https://vite.dev/releases)
- [Vite 8](https://vite.dev/blog/announcing-vite8)

## 3. 后端工程形态

V1 保持单进程、单部署单元的模块化单体。后续 `server/` 骨架至少明确以下
业务模块边界，但不得因此拆成微服务：

```text
source
cognition
generation
reading
llm
```

建议使用一个 Spring Boot 应用模块承载启动和配置，各业务模块以 Java 包和
Spring Modulith Application Module 约束依赖。模块只能通过公开 API、领域事件
或显式端口协作，禁止跨模块直接访问内部 Mapper。

生成过程的耗时与重试通过持久化的 `GenerationRun`/任务状态建模。V1 不引入
WebFlux 作为默认运行模型，也不因异步生成而提前引入 Kafka。

## 4. 数据持久化裁决

```text
PrimaryDatabase = PostgreSQL 18
DataAccess = MyBatis
ORM = NONE
MyBatisPlus = NOT_ADOPTED
SchemaMigration = Flyway
ProductionSchemaMutationOnStartup = FORBIDDEN
```

具体约束如下：

1. 使用 MyBatis Mapper 接口；复杂查询和动态 SQL 使用 XML Mapper，注解只用于
   简单、固定且易审查的 SQL。
2. 不引入 Spring Data JPA、Hibernate 或 MyBatis-Plus。领域模型不得继承持久化
   框架基类。
3. 事务边界由应用服务通过 Spring `@Transactional` 显式声明；禁止在 Controller
   或 Renderer 中开启业务事务。
4. 数据库结构变更只通过版本化 Flyway migration 进入 Repository。生产环境不得
   依赖 Hibernate DDL 或应用启动时的临时建表逻辑。
5. 正式认知产物、生成记录和来源引用可使用 PostgreSQL `jsonb`，但必须由显式
   TypeHandler 完成序列化，并在写入前通过正式 JSON Schema 校验。
6. 关键筛选、状态、版本、归属和外键字段必须是可索引的关系型列，不得把整个
   领域模型无差别塞入 JSONB。
7. Repository/Mapper 返回值不得直接暴露为 Web API DTO；Renderer 只能投影正式
   认知产物，不能从存储结构创建第二套事实。

## 5. 构建与依赖治理

后续根 `pom.xml` 必须：

- 使用 Spring Boot `4.1.0` 的 parent 或 dependency management；
- 导入 Spring Modulith BOM `2.1.0` 和 Spring AI BOM `2.0.0`；
- 显式声明 MyBatis Starter `4.0.0` 与 pgJDBC `42.7.11`；
- 配置 Maven Compiler Plugin 使用 `release=21`；
- 配置 Maven Enforcer，拒绝 JDK 非 21 和 Maven 低于 `3.9.16`；
- 提交 Maven Wrapper，并使本地和 CI 统一通过 `./mvnw` 执行；
- 输出并保存依赖树验证证据，禁止 milestone、RC、snapshot 和动态版本。

Flyway 应同时引入：

```text
org.flywaydb:flyway-core
org.flywaydb:flyway-database-postgresql
```

其精确解析版本由 Spring Boot `4.1.0` BOM 决定，并在创建骨架时以
`./mvnw dependency:tree` 记录，不在当前无 `pom.xml` 的状态下猜写解析结果。

## 6. 测试与数据库环境

- 单元测试使用 JUnit 5。
- 模块边界使用 Spring Modulith verification 和 module integration test 验证。
- Mapper、migration、事务和 JSONB 集成测试使用 Testcontainers PostgreSQL 18。
- 不使用 H2 代替 PostgreSQL 契约测试，避免 JSONB、SQL 方言、锁和事务行为失真。
- 测试容器必须固定到 PostgreSQL 18 的精确补丁 tag 或镜像 digest；具体 digest
  由本卡固定为：

```text
PostgreSQLTestImage =
  postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a
DigestScope = MULTI_PLATFORM_IMAGE_INDEX
```

- Testcontainers 2 的 PostgreSQL Maven 坐标为
  `org.testcontainers:testcontainers-postgresql`，不得退回已不受当前 BOM
  管理的旧模块坐标。
- 测试 migration 只能作用于临时容器，不得连接或写入正式数据库。

## 7. 明确不采用

以下内容不是当前基线的一部分：

- Maven 4 RC、Spring Boot milestone/snapshot；
- Gradle；
- Spring Data JPA、Hibernate、MyBatis-Plus；
- WebFlux 默认技术栈；
- Redis、Kafka、Neo4j、Elasticsearch；
- 微服务拆分；
- H2 作为 PostgreSQL 集成测试替身；
- 由 LLM 输出直接绕过 JSON Schema 写库。

这些排除项可避免在 Wave 0 引入与 Cognitura 核心问题无关的基础设施和第二套
事实模型。后续若有可验证需求，必须通过新的工程裁决变更本基线。

## 8. 实际解析与可重复构建证据

`./mvnw dependency:tree` 在 Maven `3.9.16`、Temurin JDK `21.0.7` 下解析出：

| 依赖 | 实际解析版本 | 管理来源 |
|---|---|---|
| Spring Framework Core / Web MVC | `7.0.8` | Spring Boot `4.1.0` |
| Jackson Databind | `3.1.4` | Spring Boot `4.1.0` |
| HikariCP | `7.0.2` | Spring Boot `4.1.0` |
| Flyway Core / PostgreSQL | `12.4.0` | Spring Boot `4.1.0` |
| Testcontainers / PostgreSQL | `2.0.5` | Spring Boot `4.1.0` |
| MyBatis Core | `3.5.19` | MyBatis Starter `4.0.0` |
| Spring Modulith Core | `2.1.0` | Spring Modulith BOM `2.1.0` |

前端生产构建的实际输入为 Node `24.18.0`、pnpm `11.17.0` 和已提交的
`web/pnpm-lock.yaml`。等价本地命令：

```bash
./mvnw --version
./mvnw -q verify
corepack pnpm --dir web install --frozen-lockfile
corepack pnpm --dir web build
scripts/verify-build-baseline
```

依赖已进入本地缓存后，还必须可用下列命令复验：

```bash
./mvnw -o -q verify
corepack pnpm --dir web install --offline --frozen-lockfile
```

对象存储实现、CI Provider 与部署环境仍未裁决；它们不属于 `W0-03` 构建基线，
也不影响当前空骨架的可重复构建。

当前卡内状态是：

```text
W0-03 BackendTechnologySelection = PASS
W0-03 FrontendTechnologySelection = PASS
W0-03 BuildSkeleton = PASS
W0-G2A BuildBaseline = PASS
Wave1FeatureDevelopmentEntry = NO_GO
```

## 9. 本基线验证

从 Repository 根目录执行：

```bash
rg -n \
  'Maven.*3\.9\.16|Spring Boot.*4\.1\.0|PostgreSQL.*18|MyBatis.*4\.0\.0' \
  AGENTS.md README.md docs/engineering
git diff --check
shasum -a 256 \
  cognitive-knowledge-atlas-overall-design-1.2.md \
  raw/11-MySQL数据库.docx \
  raw/12-Redis中间件.docx \
  raw/40-英语学习.docx
```

验收条件：

- 四项核心后端版本在本基线、Repository 指令、README 和 Wave 0 状态中一致；
- 前端直接依赖、Node 和 pnpm 版本在本基线、版本锁与 lockfile 中一致；
- Markdown 变更无空白错误；
- 总体设计和三份 Golden Case 的 SHA-256 与设计索引完全一致；
- `W0-G2A` 只允许在 server/web 构建、负例和任务卡集合验证全部通过后变更为
  `PASS`。
