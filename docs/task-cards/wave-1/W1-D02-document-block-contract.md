# W1-D02 DocumentBlock 保真与安全

```text
TaskCardID = W1-D02
CardKind = DESIGN
Status = BLOCKED_BY_DEPENDENCY
Gate = W1-DG2 DocumentBlockFidelityAndSafety
Risk = HIGH
DependsOn = W1-D01
ReviewRoute = SOL_HIGH_DESIGN_GATE
```

## 1. 目标

固定块类型、顺序、章节、页码、表格、图片引用、图注和 DOCX 安全边界。

## 2. 前置条件与输入

- 已通过 Gate 的 W1-D01 SourceDocument 契约。
- 总体设计 §13、§17、§24。
- 现有 Golden Case ZIP 与外链保护边界。

## 3. 写集

- Create: `docs/design/wave-1/cognitura-document-block-contract-1.0.md`
- Create: `tests/contracts/wave1-design/verify-document-block-contract.sh`
- Modify: `docs/design/wave-1/README.md`
- Modify: `docs/task-cards/wave-1/W1-D02-document-block-contract.md`
- Modify: `docs/task-cards/wave-1/W1-D03-reparse-reference-contract.md`
- Modify: `docs/task-cards/wave-1/README.md`
- Modify: `docs/engineering/cognitura-wave-1-design-plan.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `AGENTS.md`
- Modify: `README.md`

## 4. 执行步骤

1. 先写块类型、顺序、页码和安全限制的失败验证。
2. 固定公共 block envelope 与各类型 payload。
3. 固定 ZIP、XML、外部关系和部分解析裁决。
4. 通过 Gate 后关闭本卡并释放 W1-D03。

## 5. 验证命令

```bash
bash tests/contracts/wave1-design/verify-document-block-contract.sh
bash tests/contracts/wave1-design/verify-source-document-contract.sh
bash tests/task-cards/verify-wave1-design-cards.sh
git diff --check
```

## 6. Gate 与完成定义

`W1-DG2 = PASS` 要求来源顺序可复现、页码不被猜测、表格与图片引用保真，且
外部关系访问为零。

## 7. 提交与审查

使用 `gpt-5.6-sol/high` 进行设计 Gate；形成独立本地提交，不推送。
