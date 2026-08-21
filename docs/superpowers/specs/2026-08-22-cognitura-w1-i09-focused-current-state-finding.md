# W1-I09 focused current-state finding closure

```text
Risk = R2
Origin = 3b480adb23986b69b098cc0863c3dcae7824831f
RedEvidence = Canonical bridge focused contract rejects the valid current Exact29 state because its current-HEAD positive hard-codes Exact28
RepairChain = EXACT_THREE_COMMITS
Commit1 = docs/superpowers/specs/2026-08-22-cognitura-w1-i09-focused-current-state-finding.md
Commit2 = tests/task-cards/verify-wave1-implementation-cards.sh
Commit3 = scripts/verify-wave1-implementation-cards
ProductBehavior = UNCHANGED
ProductWriteSet = UNCHANGED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

Current-repository positives in the canonical bridge and V2 compatibility focused
contracts must assert `W1I09RuntimeRebaselineStatus = PASS`, not a historical product
count. Their fixed historical projection/product fixtures continue to assert the exact
local counts `28` and `29`, respectively. This separates current aggregate readiness
from the fixed local projection contracts and prevents later authorized additions from
invalidating earlier focused tests.

The verifier change only admits this fixed spec/test/verifier chain after the rejected
diagnostic candidate. All product, projection, mode, NUL, rename/copy, formal database
and push guards remain unchanged.
