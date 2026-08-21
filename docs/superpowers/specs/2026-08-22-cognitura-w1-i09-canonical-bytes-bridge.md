# W1-I09 canonical bytes 生产桥接 Authority

日期：2026-08-22

## 1. 裁决

I09 的生产 `JdbcProcessingPublicationPort` 必须持久化 I07 已定义并已审查的 block、
omission 与 revision-diagnostic canonical bytes。`CandidateBlockSet` 当前只向同包测试
adapter 暴露这三个只读编码方法；persistence adapter 无法调用。

禁止以下替代：反射访问、`toString()`、只持久化 hash、复制第二套 canonical 编码，
或把 JDBC adapter 声明成 application package。最小正确桥接是仅把现有三个方法从
package-private 改为 `public`，方法体与编码字节保持不变。

## 2. 固定入口与范围

```text
BridgeOrigin = 3fccd70661333115703205d8217ced77171c98a7
BridgePath = server/src/main/java/io/cognitura/source/application/processing/CandidateBlockSet.java
I09ProductWriteSetCountBefore = 27
I09ProductWriteSetCountAfter = 28
ProductionFileLimitBefore = 19
ProductionFileLimitAfter = 20
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

I09 新增唯一产品路径：

```text
server/src/main/java/io/cognitura/source/application/processing/CandidateBlockSet.java
```

除把 `canonicalOmissionsBytes()`、`canonicalRevisionDiagnosticsBytes()` 和
`Block.canonicalBytes()` 声明为 `public` 外，该文件相对 Bridge projection 必须无其他
字节变化。I07 canonical digest、状态机、构造校验和所有历史 receipt 保持不变。

## 3. append-only 准入

从 BridgeOrigin 追加：

1. 本 spec；
2. `tests/task-cards/verify-wave1-implementation-cards.sh` RED；
3. `scripts/verify-wave1-implementation-cards` GREEN；
4. 直接三路径 Authority projection：
   - `docs/engineering/cognitura-design-index.md`
   - `docs/engineering/cognitura-wave-1-implementation-plan.md`
   - `docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md`

前三步均单父、非空、单路径、正确 mode、无 R/C/NUL；spec/test evidence 固定。投影
必须把 27/19 精确改为 28/20并增加唯一 WriteSet 行，其余字节逐字冻结。

projection 后只允许 Exact 28 产品路径；BridgePath 的首个产品提交只能做三个
`public` 修饰符变换，后续不得再次修改 BridgePath。

## 4. 证据与门禁

focused 真实 Git 合同至少覆盖：合法三步+投影、合法精确 bridge 后继、缺 projection、
错误计数、额外 WriteSet、bridge 额外语义漂移、bridge 二次修改、投影后治理重入和
产品越界。

最终治理候选执行一次 `deep_reviewer / sol xhigh`；projection 后继续产品 TDD。
本桥接不授权正式数据库连接、deployment、release 或 remote push。
