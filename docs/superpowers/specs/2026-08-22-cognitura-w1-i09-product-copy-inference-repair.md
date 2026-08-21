# W1-I09 产品提交 Git copy 推断修复

日期：2026-08-22

## 1. 结论

`c934ff7a10a30ed58584d2e5eb0654d2161add70` 是已通过真实 PostgreSQL 18.4
容器聚焦回归的 I09 upload 产品提交。普通 Git diff 将它记录为七个新增文件；
`--find-copies-harder` 仅因内容相似度，把其中两个新增文件推断成未变历史文件的
`C051`／`C077` copy。源文件没有删除、改名或修改，目标在父提交中不存在并且属于
I09 Exact 27 WriteSet。

不得重写产品提交。以固定身份和精确 copy pair 增加一次最窄的 append-only verifier
修复；不得把例外泛化成 I09 目录级、文件类型级或相似度阈值级许可。

## 2. 固定身份

```text
ProductCandidate = c934ff7a10a30ed58584d2e5eb0654d2161add70
ProductParent = 1732c6821d93bcc9f121ba221adff2d137ffd6d0
ProductTree = 2ca9c7169d6d3586d39721d7f1874a0dd491df98
ProjectionAncestor = 3c6acb87b85141792361fc5d915ee9951c6c99e4
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

唯一允许的推断 pair：

```text
server/src/main/java/io/cognitura/source/persistence/SourceDocumentMapper.java
  -> server/src/main/java/io/cognitura/source/persistence/SourceCommandMapper.java

server/src/test/resources/db/source-persistence-fixture.sql
  -> server/src/test/resources/db/source-command-runtime-fixture.sql
```

## 3. 必须同时成立的不变量

对固定 ProductCandidate：

1. Parent 与 Tree 必须逐字等于固定身份；
2. `R*` 永远拒绝；
3. `C*` 集合必须恰好等于上述两对，不以 `C051`／`C077` 分数作为许可条件；
4. 每个 source 在 Parent 与 Candidate 中 blob、mode 必须相同；
5. 每个 target 在 Parent 中不存在，在 Candidate 中为 `100644`；
6. Candidate 的实际 changed-path 集仍必须全部属于 I09 Exact 27 WriteSet；
7. 其他 I09 产品提交继续使用严格 no rename/copy；
8. I08 冻结产品、五路径 Authority projection、正式数据库和远程推送边界不变。

## 4. 修复链

从 ProductCandidate 直接追加三步单路径链：

1. 本 Authority spec；
2. `tests/task-cards/verify-wave1-implementation-cards.sh` 的真实 Git RED；
3. `scripts/verify-wave1-implementation-cards` 的 GREEN。

前两步由固定 SHA 绑定 evidence blob；三步均要求单父、非空、精确单路径、正确
mode、无 R/C/NUL。第三步稳定后只执行一次 `deep_reviewer / sol xhigh` 固定候选
门禁；该外部审查是最终 trust root，不继续递归增加“验证 verifier 的 verifier”。

## 5. RED / GREEN 证据

聚焦合同至少证明：

- 固定提交与三步修复链通过；
- 修复后合法 I09 产品后继通过；
- 替换 ProductCandidate 身份、增加额外 copy、制造 rename、漂移 source、错误治理
  evidence 或修复后写入非 I09 路径均失败。

本修复不授权新增产品路径、不授权正式数据库连接或写入、不授权 deployment、release
或 remote push。
