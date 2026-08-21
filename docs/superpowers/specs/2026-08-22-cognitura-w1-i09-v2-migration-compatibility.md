# W1-I09 V2 migration compatibility Authority

```text
Risk = R2
Origin = 22c0ff2e0dde71fa71a5e6a030f841c99ac4b655
RedEvidence = SourcePersistenceIntegrationTest and SourceUploadCommandIntegrationTest expected one initial Flyway migration but V2 correctly applies two
AddedWriteSet = server/src/test/java/io/cognitura/source/persistence/SourcePersistenceIntegrationTest.java
AllowedChange = Exactly one migrationsExecuted assertion changes from 1 to 2
I09ProductWriteSetCountBefore = 28
I09ProductWriteSetCountAfter = 29
ProductionFileLimit = 20
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The normal `db/migration` location remains authoritative; V2 must not be hidden in a
test-only Flyway location to preserve an obsolete migration-count assertion. The I02
test continues using an isolated PostgreSQL 18.4 Testcontainer with reuse disabled and
continues to validate V1 replay rejection and all existing source-persistence facts.

From `Origin`, append a single-parent spec/test/verifier governance chain, followed by
an exact three-path projection of the design index, Wave 1 implementation plan and I09
task card. The focused real-Git contract must cover the exact legal assertion update,
a second modification, extra semantics, wrong 29 count, extra WriteSet and governance
reentry. The production path may change once and only by replacing the single existing
`isEqualTo(1)` migration-count assertion with `isEqualTo(2)`; all other bytes are frozen.

This compatibility bridge changes no DDL, production behavior, database location,
formal database authority, deployment, release or push boundary. Its final governance
candidate receives the applicable independent `sol/xhigh` review before the test path
is modified.
