# W1-I11 Migration Count Regression Rebaseline

```text
ChangeRisk = R2
Origin = 35393f6e73a0e2299d92c64c783b152b4190ca59
ActiveTaskCard = W1-I11
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. Finding

The approved I11 V3 migration necessarily changes a fresh Flyway run from two
to three migrations. Three existing real-PostgreSQL integration tests pin the
old literal count and fail before their business assertions run. They were
omitted from the I11 persistence rebaseline WriteSet.

## 2. Minimal correction

Add exactly these three test paths to the I11 product WriteSet:

```text
server/src/test/java/io/cognitura/source/application/command/SourceUploadCommandIntegrationTest.java
server/src/test/java/io/cognitura/source/persistence/JdbcProcessingPublicationPortIntegrationTest.java
server/src/test/java/io/cognitura/source/persistence/SourcePersistenceIntegrationTest.java
```

In each file, the only permitted product change is the unique fresh-migration
assertion from `migrationsExecuted == 2` to `migrationsExecuted == 3`. No test
logic, fixture, production path, schema behavior, authorization, or completion
state changes.

The resulting I11 product WriteSet is exact16: the already approved exact13
plus these three regression-test paths. `ProductionFileLimit=10` is unchanged
because all three additions are tests.

## 3. One-time admission

Use one append-only `spec -> focused real-Git test -> verifier -> card
projection` chain rooted at the literal Origin. The verifier must freeze the
existing rebaseline projection and all predecessor product/closure bytes,
materialize the I11 card by adding only the three WriteSet lines, and allow
descendants only inside exact16.

Focused evidence must prove the legal chain and exact16 descendant pass, while
wrong origin/evidence, non-direct or extra projection, migration-count changes
outside the three literal assertions, and post-projection paths outside exact16
fail closed. This is not a reusable Harness or a general WriteSet expansion.
