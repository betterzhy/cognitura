# W1-I07 关闭链历史 Gate fixture 修复

```text
RepairType = APPEND_ONLY_GOVERNANCE_COMPATIBILITY_CORRECTION
RepairOrigin = e0b7c302011b4a84f04ebdd7f88393af76d3d973
HistoricalI02GateTip = 042a039f8582a51e501530b629fb24fdb3b74c45
AffectedRuntimeBehavior = NONE
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. 失败事实

`RepairOrigin` 的 I07 聚焦合同通过，但完整 Wave 门禁中的历史 I02 数据库 Gate 合同
错误地把“从 I02 RED 之后最后一个只改生产验证器的提交”当成 I02 Gate tip。I07
关闭验证器恰好也是这种提交，因此 fixture 被错误定位到 `RepairOrigin`，输出当前 I07
PENDING 状态而非历史 I02 PENDING_REVIEW 状态。

真实 I02 Gate tip 是 I02 release `525e75efe99ad91419c4d455c04bf3744abc7490`
的直接父提交 `HistoricalI02GateTip`。该身份已经由 I02 关闭链固定，不应由未来提交形状
重新推断。

## 2. 唯一允许的修复

1. 不改写既有 I07 六步治理链。
2. 测试只把 I02 fixture 的 Gate tip 解析改为上述固定 SHA，并保留真实 PG18 容器、
   release 正反例和销毁证明不变。
3. 生产验证器只把 I07 治理链追加为九步：既有六步、本说明、修正后的测试、最终
   验证器。每步仍须单父、非空、精确单路径、mode 正确、无 rename/copy/NUL；累计
   写集对重复测试和验证器路径去重。
4. I07 产品候选、关闭投影、I08 WriteSet、Authority 语义和授权边界均不得变化。

## 3. 接受条件

- I02 数据库 Gate 聚焦合同：真实 PG18 probe、`4` 正例、`13` 负例全部通过。
- I07 关闭聚焦合同：`4` 正例、`18` 负例全部通过。
- 完整 `scripts/verify-wave1-implementation` 零退出。
- 最终九步固定候选只执行一次 `deep_reviewer / Sol xhigh` 门禁；不使用 Ultra。
