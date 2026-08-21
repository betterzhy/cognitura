# W1-I09 canonical bridge projection freeze fix

```text
Risk = R2
Origin = 90a77d73f1389593930d8fbd468f0f06238b1c1b
RedEvidence = W1I09CanonicalBridgeContractTests rejected the exact three-path projection with I09_RUNTIME_REBASELINE_PRODUCT_INVALID:path:projection
Change = Freeze the I09 runtime projection paths from the canonical bridge projection commit after that projection has been validated byte-for-byte
GovernanceChain = EXACT_TWO_COMMITS
Commit1 = docs/superpowers/specs/2026-08-22-cognitura-w1-i09-canonical-bridge-projection-freeze-fix.md
Commit2 = scripts/verify-wave1-implementation-cards
ProductSemantics = UNCHANGED
ProductWriteSet = UNCHANGED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The existing canonical bridge contract is the RED oracle. The verifier correction must
bind this specification as the direct child of `Origin`, admit exactly one following
verifier commit, retain all existing chain, mode, NUL, rename/copy and byte-exact
projection checks, and use the validated bridge projection as the later projection
freeze baseline. No task-card, runtime product, database, deployment or push change is
authorized by this correction.
