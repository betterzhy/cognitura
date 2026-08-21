# W1-I09 canonical bridge review finding closure

```text
Risk = R2
Origin = 2c5f825edb1f959d9f2cb5d1daf3532b18654ebc
ReviewVerdict = NO_GO
P0 = 0
P1 = 1
P2 = 0
Finding = Focused bridge contract omitted missing projection, wrong 28/20 count, and extra WriteSet real-Git negatives required by Authority
RepairChain = EXACT_THREE_COMMITS
Commit1 = docs/superpowers/specs/2026-08-22-cognitura-w1-i09-canonical-bridge-review-finding.md
Commit2 = tests/task-cards/verify-wave1-implementation-cards.sh
Commit3 = scripts/verify-wave1-implementation-cards
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The focused contract must retain its existing two positive and four negative cases and
add three independent real-Git negatives: the fixed bridge verifier without its direct
projection, a direct exact-three-path projection whose `28/20` count is wrong, and a
direct projection that adds an undeclared WriteSet row. Each case must assert the
specific projection/bridge diagnostic and must pass through the production verifier.

The verifier change only admits this fixed finding-closure chain after the selector
candidate. It does not alter the canonical bridge product transform, projection bytes,
I09 product scope, formal database boundary, deployment, release or push authority.
