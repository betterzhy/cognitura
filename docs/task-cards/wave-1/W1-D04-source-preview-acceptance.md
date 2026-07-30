# W1-D04 来源预览、接口与验收

```text
TaskCardID = W1-D04
CardKind = DESIGN
Status = BLOCKED_BY_DEPENDENCY
Gate = W1-DG4 SourcePreviewAndAcceptance
Risk = HIGH
DependsOn = W1-D03
ReviewRoute = SOL_HIGH_DESIGN_GATE
```

## 1. 目标

固定上传、处理状态、来源预览 API、Desktop Web 投影和分层验收。

## 2. 前置条件与输入

- 已通过 Gate 的 W1-D01 至 W1-D03 契约。
- 页面契约中的 DocumentUpload、DocumentParsingStatus 和 SourceEvidence。
- 技术基线的 Spring MVC 与 Desktop Web 边界。

## 3. 写集

- Create: `docs/design/wave-1/cognitura-source-preview-contract-1.0.md`
- Create: `scripts/verify-wave1-design`
- Create: `tests/contracts/wave1-design/verify-source-preview-contract.sh`
- Create: `tests/contracts/wave1-design/verify-wave1-design-contracts.sh`
- Modify: `docs/design/wave-1/README.md`
- Modify: `docs/task-cards/wave-1/W1-D04-source-preview-acceptance.md`
- Modify: `docs/task-cards/wave-1/W1-D05-fixed-design-review.md`
- Modify: `docs/task-cards/wave-1/README.md`
- Modify: `docs/engineering/cognitura-wave-1-design-plan.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `AGENTS.md`
- Modify: `README.md`

## 4. 执行步骤

1. 先写 API、分页、事实来源和 LLM 禁用的失败验证。
2. 固定命令、查询、HTTP 状态与错误 DTO。
3. 固定 Desktop Web 状态投影。
4. 固定单元、契约、集成、安全与 Golden 验收层级。
5. 创建 Wave 1 设计统一验证入口。
6. 通过 Gate 后关闭本卡并释放 W1-D05。

## 5. 验证命令

```bash
bash tests/contracts/wave1-design/verify-source-preview-contract.sh
bash tests/contracts/wave1-design/verify-wave1-design-contracts.sh
scripts/verify-wave1-design
git diff --check
```

## 6. Gate 与完成定义

`W1-DG4 = PASS` 要求预览只投影来源事实、使用固定 revision 的 keyset 分页、
外链访问为零且 Wave 1 不使用 LLM。

## 7. 提交与审查

使用 `gpt-5.6-sol/high` 进行设计 Gate；形成独立本地提交，不推送。
