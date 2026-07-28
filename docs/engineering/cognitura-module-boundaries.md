# Cognitura 模块边界基线

```text
DecisionDate = 2026-07-28
Architecture = MODULAR_MONOLITH
DeploymentUnits = 1
ServerModuleCount = 5
WebModuleCount = 9
BusinessImplementation = FORBIDDEN_IN_W0_03
```

本文件固定 `W0-03` 的空模块边界。它只建立可验证的工程分区，不实现文档解析、
认知生成、持久化用例或产品页面。

## 1. Server 边界

| 模块 | 包 | 当前职责边界 | Wave 0 状态 |
|---|---|---|---|
| source | `io.cognitura.source` | 来源接入与来源证据的未来归属边界 | EMPTY_BOUNDARY |
| cognition | `io.cognitura.cognition` | 正式认知结构的未来归属边界 | EMPTY_BOUNDARY |
| generation | `io.cognitura.generation` | 生成编排与状态的未来归属边界 | EMPTY_BOUNDARY |
| reading | `io.cognitura.reading` | 阅读投影的未来归属边界 | EMPTY_BOUNDARY |
| llm | `io.cognitura.llm` | Provider Adapter 的未来归属边界 | EMPTY_BOUNDARY |

五个模块共同位于 `cognitura-server` 单一 Spring Boot 部署单元中。模块间只能经
公开 API、领域事件或显式端口协作；当前没有内部类型或跨模块依赖，因此
Spring Modulith verification 必须报告无边界违规。

## 2. Web 边界

```text
workspace
document-ingestion
structure-review
landscape
theme
module-reading
source-evidence
generation-status
revision-history
```

九个目录仅是 Desktop Web 的空边界标记，不含路由、页面、状态管理、API 调用或
业务组件。`src/App.tsx` 只挂载一个无产品内容的 application shell。

## 3. 禁止边界

- 部署单元数必须保持为 `1`，不得创建独立服务或微服务通信契约。
- 不得引入 Spring Data JPA、Hibernate、MyBatis-Plus 或默认 WebFlux。
- 不得引入 Redis、Kafka、Neo4j、Elasticsearch。
- 不得创建生成、解析、Mapper、Repository、Controller 或产品页面实现。
- Renderer 未来只能投影正式认知产物，不能在 Web 模块中创建第二套事实。

## 4. 自动验证

```bash
scripts/verify-build-baseline
./mvnw -q verify
corepack pnpm --dir web install --frozen-lockfile
corepack pnpm --dir web build
```

`tests/build-baseline/verify-build-baseline.sh` 还必须证明缺失模块、禁用依赖、
未固定版本和业务实现能够被拒绝。
