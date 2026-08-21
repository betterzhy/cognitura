# W1-I07 fixture staging 修复链计数澄清

```text
ClarificationOrigin = b56b3abeedc60f9fd7a88e50bf6505cf6d8eb74e
PriorGovernanceCommitCount = 12
FinalGovernanceCommitCount = 15
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

`b56b3ab` 是从 I07 产品 origin 起算的第 12 个治理提交。为使其已声明的最终 15 步
身份与真实历史一致，后续恰为本文、第 14 步测试修正、第 15 步生产验证器。本文不改变
负例、产品、投影、状态或授权语义；只消除计数歧义。三步仍须单父、非空、精确单路径、
mode 正确且无 rename/copy/NUL。
