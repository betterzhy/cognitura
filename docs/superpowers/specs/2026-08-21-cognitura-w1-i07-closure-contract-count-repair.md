# W1-I07 关闭契约计数修复

```text
RepairType = APPEND_ONLY_GOVERNANCE_CORRECTION
RepairOrigin = bc2bdac50b1118e457af431e51c6d2e1dcaeb3ff
AffectedRuntimeBehavior = NONE
AffectedAuthorityMeaning = NONE
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. 事实

`RepairOrigin` 中的 I07 关闭契约实际执行了 18 个相互独立的负例，但终端完整性断言
误写为 17。所有 18 个负例在验证器 GREEN 过程中均已逐一返回预期的 fail-closed
错误；唯一剩余失败是计数断言本身。

## 2. 唯一允许的修复

1. 不改写、amend 或替换 `RepairOrigin`。
2. 追加本说明后，只允许再追加一次
   `tests/task-cards/verify-wave1-implementation-cards.sh` 修正：把 I07 负例总数固定为
   18，并让真实 Git fixture 重放下列六步单父链：原设计、原计划、原 RED、本文、
   修正后的 RED、生产验证器 GREEN。
3. 随后的生产验证器提交只允许修改
   `scripts/verify-wave1-implementation-cards`；它必须逐提交验证六步路径、mode、非空、
   无 rename/copy/NUL，并把重复出现的测试路径按累计唯一写集处理。
4. I07 产品固定候选、十二路径关闭投影、I08 WriteSet、正式数据库与远程推送边界
   均保持不变。

## 3. 门禁

修复后的聚焦契约必须输出 `4` 个正例和 `18` 个负例并以零退出；随后执行完整 Wave 1
门禁。只有固定 GREEN 候选取得一次 `deep_reviewer / Sol xhigh` 零发现 `GO`，才允许
制作 I07 十二路径关闭投影。
