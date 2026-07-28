# W0-01 设计和输入来源登记

```text
TaskCardID = W0-01
Status = DONE
Gate = W0-G1 DesignSourceRegistry
Risk = MEDIUM
DependsOn = W0-00
ReviewRoute = MAIN_AGENT_GATE
```

## 1. 目标

建立机器可读、可重复验证的唯一来源清单，使总体设计和三份 Golden Case 的路径、
角色、版本、大小与 SHA-256 成为后续 Wave 0 资产的可信输入。

## 2. 前置条件与输入

- `W0-G0 RepositoryBaseline = PASS`
- `cognitive-knowledge-atlas-overall-design-1.2.md`
- `raw/11-MySQL数据库.docx`
- `raw/12-Redis中间件.docx`
- `raw/40-英语学习.docx`
- `docs/engineering/cognitura-design-index.md`

执行前必须再次确认工作树没有用户未提交修改。四份正式输入只读。

## 3. 写集

- Create: `docs/engineering/cognitura-source-manifest.yaml`
- Create: `scripts/verify-source-manifest`
- Create: `tests/source-manifest/verify-source-manifest.sh`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/task-cards/README.md`
- Modify: `docs/task-cards/W0-01-design-source-registry.md`
- Modify: `docs/task-cards/W0-02-specialty-contract-coverage.md`
- Modify: `docs/engineering/cognitura-wave-0-plan.md`
- Modify: `docs/engineering/cognitura-wave-0-entry-decision.md`
- Modify (user-authorized write-set correction): `tests/task-cards/verify-task-cards.sh`
- Modify (user-authorized status sync): `AGENTS.md`
- Modify (user-authorized status sync): `README.md`

不得修改 `raw/`、总体设计或创建它们的副本。

## 4. 执行步骤

- [x] 编写校验测试，覆盖哈希漂移、文件缺失、重复 Case ID 和未知正式输入。
- [x] 运行测试并确认因 manifest/校验器尚未实现而失败。
- [x] 创建 manifest，登记四个正式输入的规范路径、角色、版本、字节数和 SHA-256。
- [x] 实现只读校验器；校验器不得访问 DOCX 内的外部或本地链接。
- [x] 运行正例和全部反例，确认只有规范输入集合能够通过。
- [x] 更新设计索引，使其引用 manifest 但不复制总体设计正文。
- [x] 将本卡标为 `DONE`，把 `W0-02` 从依赖阻断改为 `READY`。
- [x] 提交本卡的唯一写集并记录固定提交。

## 5. 验证命令

```bash
bash tests/source-manifest/verify-source-manifest.sh
scripts/verify-source-manifest \
  --manifest docs/engineering/cognitura-source-manifest.yaml
bash tests/task-cards/verify-task-cards.sh
git diff --check
```

预期正例输出必须逐项报告四个输入为 `MATCH`；所有反例必须返回非零。

## 6. Gate 与完成定义

以下条件必须全部满足：

- manifest 只登记一份总体设计和三份 Golden Case；
- 路径、字节数与 SHA-256 与磁盘一致；
- Case ID 唯一，未知正式输入被拒绝；
- 校验过程不修改正式输入、不解析遗留链接；
- 测试与任务卡集合验证全部通过。

```text
W0-G1 DesignSourceRegistry = PASS
PositiveSourceMatches = 4
NegativeCases = 5
FormalInputsUnchanged = PASS
```

## 7. 提交与审查

```text
CommitMessage = chore: add Cognitura design source registry
CommitReview = MAIN_AGENT_GATE
ReviewResult = MAIN_AGENT_VERIFIED
NextTaskCardOnPass = W0-02
```

只提交本卡写集；发现正式输入哈希漂移时停止，不得自行接受新哈希。
