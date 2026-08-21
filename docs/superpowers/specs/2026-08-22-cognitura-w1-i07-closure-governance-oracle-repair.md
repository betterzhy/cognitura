# W1-I07 关闭治理负例 Oracle 修复

```text
RepairType = APPEND_ONLY_REVIEW_FINDING_REPAIR
RepairOrigin = d59f444ad2d874d8d9dc10c3ade332c8da4ba0ae
ReviewFinding = P1_GOVERNANCE_NEGATIVES_SHORT_CIRCUIT_ON_COMMIT_COUNT
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. Finding

43 个负例的数量已完整，但 wrong-order、repeated、empty、rename、mode、NUL 和
predecessor-projection mutation 不是有效独立 oracle：部分 fixture 只构造两步，部分在
合法 15 步 tip 后追加第 16 步，因此统一在“提交数必须为 15”处提前退出，没有触达
后续专用守卫；copy mutation 也尚未独立覆盖。

## 2. 唯一修复

从 `RepairOrigin` 追加本文、测试、生产验证器三步，形成精确 18 步治理链：

1. 测试以同一固定 18 步路径/来源表构造 legal fixture 和单点 variant；
2. wrong-order/repeated/projection-drift 必须保持完整 18 步并命中 `path order`；
3. empty 必须保持完整 18 步并命中 `empty commit`；
4. rename 与新增 copy 必须保持完整 18 步并命中 `rename or copy`；
5. mode、NUL 必须保持完整 18 步并分别命中 `mode`、`NUL`；
6. substituted-origin 必须从固定 origin 的父提交构造完整 18 步，并被现有 predecessor/
   post-closure边界拒绝；不得以 PASS 或宽泛计数替代。

新增 copy 后聚焦矩阵固定为 `4 positive / 44 negative`。不得删除其余 43 个 mutation。
生产验证器仅扩展固定治理身份至 18 步；若精确 oracle 暴露真实检查缺陷，只允许在同一
验证器路径内作最小 GREEN。

## 3. 完成条件

Bash 3.2 聚焦 4/44、完整 Wave Gate 和新固定 Candidate 的一次 Sol/xhigh finding-closure
复审必须全部通过，P0/P1/P2=0 后方可制作十二路径正式投影。Ultra 仍为 NOT_RUN。
