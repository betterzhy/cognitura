# W1-D01 SourceDocument 身份与生命周期

```text
TaskCardID = W1-D01
CardKind = DESIGN
Status = READY
Gate = W1-DG1 SourceDocumentContract
Risk = HIGH
DependsOn = W1-D00
ReviewRoute = SOL_HIGH_DESIGN_GATE
```

## 1. 目标

固定逻辑上传身份、原始字节哈希、处理 revision、幂等、状态机和失败语义。

## 2. 前置条件与输入

- `Cognitura-Overall-Design-1.2` §13、§17、§23、§24。
- W1-D00 治理说明和执行计划。
- Wave 1 准入裁决及技术基线。

## 3. 写集

- Create: `docs/design/wave-1/README.md`
- Create: `docs/design/wave-1/cognitura-source-document-contract-1.0.md`
- Create: `tests/contracts/wave1-design/verify-source-document-contract.sh`
- Modify: `docs/task-cards/wave-1/W1-D01-source-document-contract.md`
- Modify: `docs/task-cards/wave-1/W1-D02-document-block-contract.md`
- Modify: `docs/task-cards/wave-1/README.md`
- Modify: `docs/engineering/cognitura-wave-1-design-plan.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `AGENTS.md`
- Modify: `README.md`

## 4. 执行步骤

1. 先写缺少正式契约时失败的验证。
2. 固定身份、版本、幂等、状态和错误码。
3. 验证正反例与跨文档状态一致性。
4. 通过 Gate 后关闭本卡并释放 W1-D02。

## 5. 验证命令

```bash
bash tests/contracts/wave1-design/verify-source-document-contract.sh
bash tests/task-cards/verify-wave1-design-cards.sh
bash tests/ci/verify-markdown-links.sh
git diff --check
```

## 6. Gate 与完成定义

`W1-DG1 = PASS` 要求逻辑上传、二进制身份和处理 revision 不混淆，重试不会
形成两个成功事实，且未选择存储 Provider 或写入数据库。

## 7. 提交与审查

使用 `gpt-5.6-sol/high` 进行设计 Gate；形成独立本地提交，不推送。
