# Cognitura W1-I11 关闭产品漂移证据修复

```text
ChangeRisk = R2
RepairOrigin = 82ea237577aa7f42913c3f51c8715c2c732be796
Finding = FOCUSED_CONTRACT_MISSING_REAL_PRODUCT_BYTE_DRIFT
Scope = CLOSURE_TEST_ORACLE_ONLY
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

固定关闭治理候选的产品冻结逻辑未发现功能旁路，但其 focused 合同只修改了收据中的
`ReviewedCandidate`，没有真实修改 W1-I11 exact16 产品字节，因而不能证明产品路径
无法混入关闭治理。

本修复采用三个 append-only 单路径提交：本说明、共享 focused 测试、生产验证器。
测试必须在完整合法三步关闭治理 fixture 的最后一步真实加入一个 I11 产品路径修改，
并断言精确治理路径守卫在进入关闭投影前拒绝该候选。负例总数从 8 调整为 9。

修复验证器必须：

- 先完整重验被拒候选的原三步链和两份 evidence blob；
- 再要求本修复恰为三个单父、非空、单路径、正确 mode、无 rename/copy/NUL 的提交；
- 固定本说明和修复测试 evidence blob；
- 冻结 I11 exact16、原关闭投影和既有授权边界；
- 只把修复后的 verifier tip 作为新的待审治理候选，不重写历史 Candidate 或收据。

只重跑 focused、Bash 3.2 syntax、static 和 `git diff --check`，随后对新候选执行一次
`deep_reviewer / xhigh` finding-closure 审查。不得重跑完整 Wave Gate，也不得为本证据
修复建立通用 Harness。
