# W1-I09 fixture diagnostic correction

```text
Risk = R2
Origin = 848f151a1248594f063a3f9665f1fecc0b42558c
RedEvidence = W1I09V2CompatibilityContractTests expects I09_V2_COMPATIBILITY_PRODUCT_INVALID before the post-product fixture governance exists
CorrectionChain = EXACT_TWO_COMMITS
Commit1 = docs/superpowers/specs/2026-08-22-cognitura-w1-i09-fixture-diagnostic-correction.md
Commit2 = scripts/verify-wave1-implementation-cards
ProductBehavior = UNCHANGED
ProductWriteSet = UNCHANGED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The rejected operation remains rejected. When the first V2 compatibility product has
already been observed but the fixed post-product fixture verifier has not been observed,
a further modification of `SourcePersistenceIntegrationTest` must retain the
`I09_V2_COMPATIBILITY_PRODUCT_INVALID` diagnostic family. Only after the fixed
post-product fixture verifier may the one exact reset-resource transformation be
accepted, with later changes reported as `I09_POST_PRODUCT_FIXTURE_INVALID`.

The final verifier must bind this specification as the direct child of `Origin`, admit
exactly one following verifier commit, and retain all existing product, projection,
mode, NUL, rename/copy, formal database and push guards. The committed focused test is
the RED oracle; no additional test commit is needed.
