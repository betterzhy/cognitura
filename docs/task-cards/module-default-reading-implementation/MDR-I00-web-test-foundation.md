# MDR-I00 Web Test Foundation

```text
TaskCardID = MDR-I00
CardKind = IMPLEMENTATION_FOUNDATION
Status = BLOCKED_BY_BUSINESS_IMPLEMENTATION_AUTHORIZATION
Gate = MDR-IG0 WebTestFoundation
Risk = HIGH
DependsOn = NONE
PrimaryBoundary = WEB_TEST_TOOLING
ProductionFileLimit = 2
BusinessImplementationAuthorization = NOT_APPLICABLE_TOOLING_ONLY
SchemaChange = FORBIDDEN
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
```

## 1. 目标

建立 React 组件测试基座，不新增 Module 阅读行为，不修改应用入口。

## 2. 前置条件与输入

- 用户已批准本卡集文本并另行释放 `MDR-I00`。
- Node `24.18.0`、pnpm `11.17.0` 与现有 React/Vite 版本保持不变。
- 新测试依赖必须先由技术基线记录“选什么和精确版本”，并由测试策略记录测试层级、
  统一入口、CI 阶段与隔离边界；任务卡不能成为独立技术权威。

## 3. 精确写集

```text
WriteSet = web/package.json
WriteSet = web/pnpm-lock.yaml
WriteSet = web/vite.config.mjs
WriteSet = web/src/test/setup.ts
WriteSet = web/src/test/test-environment.test.tsx
WriteSet = docs/engineering/cognitura-technology-baseline.md
WriteSet = docs/engineering/cognitura-test-strategy.md
WriteSet = scripts/verify-module-default-reading
WriteSet = tests/ci/verify-ci-contract.sh
WriteSet = .github/workflows/wave0.yml
ForbiddenWriteSet = web/src/App.tsx
ForbiddenWriteSet = web/src/modules/**
ForbiddenWriteSet = server/**,schemas/**,raw/**,.idea/**
```

## 4. RED -> GREEN

RED 先创建测试：

```tsx
import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

describe("web test environment", () => {
  it("exposes accessible DOM assertions", () => {
    render(<main aria-label="Cognitura test probe" />);
    expect(screen.getByRole("main", { name: "Cognitura test probe" })).toBeInTheDocument();
  });
});
```

运行 `pnpm --dir web exec vitest run src/test/test-environment.test.tsx`；预期因 Vitest/
Testing Library 尚未安装或 `toBeInTheDocument` 未配置而失败。

GREEN 先在 `docs/engineering/cognitura-technology-baseline.md` 登记测试工具的精确
版本和锁定规则，在 `docs/engineering/cognitura-test-strategy.md` 登记 component
test 层级、统一入口、CI 阶段和无生产凭据/数据库边界；随后在 `web/package.json`
固定 `vitest=4.1.10`、
`@testing-library/react=16.3.2`、`@testing-library/jest-dom=7.0.1`、
`@testing-library/user-event=14.6.3`、`jsdom=30.0.1`，增加 `test` 脚本；
`vite.config.mjs` 配置 `environment: "jsdom"` 和 `setupFiles`，`setup.ts` 只导入
`@testing-library/jest-dom/vitest`，随后刷新 lockfile。新增统一入口
`scripts/verify-module-default-reading`，固定执行 Module reading component tests 与
`pnpm --dir web build`；CI workflow 增加该入口的独立 step，CI contract 必须断言该
step 存在且错误会向上传播。不得把组件测试仅留在本地 package script 中。

## 5. 验证命令

```bash
pnpm --dir web test -- src/test/test-environment.test.tsx
pnpm --dir web build
scripts/verify-module-default-reading
bash tests/ci/verify-ci-contract.sh
scripts/verify-wave0
scripts/verify-wave1-design
scripts/verify-high-fidelity-design
scripts/verify-high-fidelity-visual
git diff --check
git status --short
```

## 6. Gate 与完成定义

目标测试、统一入口、CI contract 和既有 Gate 全部 PASS；写集只含上述十个路径；
技术选择与测试执行职责分别回写其正式 Owner，workflow 真实执行统一入口；`.idea/`
仍未跟踪且未暂存。

## 7. 提交与独立固定提交审查

```bash
git add web/package.json web/pnpm-lock.yaml web/vite.config.mjs \
  web/src/test/setup.ts web/src/test/test-environment.test.tsx \
  docs/engineering/cognitura-technology-baseline.md \
  docs/engineering/cognitura-test-strategy.md \
  scripts/verify-module-default-reading tests/ci/verify-ci-contract.sh \
  .github/workflows/wave0.yml
git commit -m "test: establish module reading web test foundation"
```

将该提交的固定 SHA 交给新的 `deep_reviewer`；审查范围只含本卡写集，要求
`GO / P0=0 / P1=0 / P2=0`。不得自动释放 `MDR-I01`。
