# W1-I11 Migration Count Test Evidence Correction

The first focused-contract commit encoded a nonexistent expanded SHA for the
already committed migration-count specification. Preserve that commit and
correct the literal to the actual immutable specification identity:

```text
Specification = eaaa00b97c79e8ffb7c087a45dd6af394ef09057
FaultyTest = f26190513813ebfc45b16ea515affb9d89f7823b
CorrectionScope = tests/task-cards/verify-wave1-implementation-cards.sh
ProductWriteSetChange = NONE
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The final verifier must recognize the append-only
`spec -> faulty test -> correction spec -> corrected test -> verifier` chain
and bind all four evidence blobs. No history rewrite or generic exception is
authorized.
