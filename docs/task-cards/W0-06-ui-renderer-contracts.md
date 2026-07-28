# W0-06 页面与 Renderer 契约

```text
TaskCardID = W0-06
Status = READY
Gate = W0-G4A UiContractValidation
Risk = MEDIUM
DependsOn = W0-02
ReviewRoute = MAIN_AGENT_GATE
```

## 1. 目标

从总体设计已回迁的 UI/UX 正式内容提取 Desktop Web 页面和 Renderer 验收契约，
确保前端只投影正式认知产物，不创造第二套事实。

## 2. 前置条件与输入

- `W0-G2 SpecialtyContractCoverage = PASS`
- 总体设计第 20～20.11 章及 `UI-RM-01～10`
- `docs/engineering/cognitura-specialty-contract-coverage.md`

`DOC-GAP-002` 不阻断已完整回迁的页面级契约，但缺少来源的字段不得新增。

## 3. 写集

- Create: `docs/contracts/cognitura-page-contracts.md`
- Create: `docs/contracts/cognitura-renderer-contract.md`
- Create: `tests/contracts/ui/`
- Create: `scripts/verify-ui-contracts`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/task-cards/README.md`
- Modify: `docs/task-cards/W0-06-ui-renderer-contracts.md`
- Modify: `docs/engineering/cognitura-wave-0-plan.md`
- Modify: `docs/engineering/cognitura-wave-0-entry-decision.md`

本卡不创建 React 页面、组件库、视觉稿或移动端工程。

## 4. 执行步骤

- [ ] 先编写页面职责、Renderer 类型、统一输入、状态和平台边界的失败验证。
- [ ] 运行测试并确认契约文档尚未存在时失败。
- [ ] 编码 Workspace、Upload、ParsingStatus、ThemeModel、SkeletonReview、Landscape、
  Theme、ModuleReading、SourceEvidence、Revision 和 History 页面职责。
- [ ] 编码 Skeleton Review 六类结构操作和 Desktop Web 三栏主布局。
- [ ] 编码九类 Renderer、统一输入和“Renderer 不创建事实”不变量。
- [ ] 编码页面状态、局部失败、最小重试和基础响应式安全边界。
- [ ] 加入禁止原生 App、自由画布、Card-only 和管理表格主体验的反例。
- [ ] 运行契约验证，更新任务卡状态并形成独立提交。

## 5. 验证命令

```bash
scripts/verify-ui-contracts
bash tests/contracts/ui/verify-ui-contracts.sh
bash tests/task-cards/verify-task-cards.sh
git diff --check
```

## 6. Gate 与完成定义

- 总体设计列出的页面、状态、核心操作和 Renderer 全部有来源映射；
- Desktop Web First、基础响应式和移动端非等价边界明确；
- Renderer 输入只引用正式认知 Schema，不复制或重定义事实；
- 禁止体验反例能够稳定失败；
- 契约与任务卡集合验证通过。

```text
W0-G4A UiContractValidation = PASS
```

## 7. 提交与审查

```text
CommitMessage = docs: add Cognitura page and renderer contracts
CommitReview = MAIN_AGENT_GATE
NextTaskCardOnPass = W0-07_WHEN_OTHER_DEPENDENCIES_PASS
```

本卡可在 `W0-05` 输入稳定后与其并行，但共享索引和状态文件由主 Agent 串行整合。
