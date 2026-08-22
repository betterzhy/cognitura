# W1-I10 Post-Closure Fixture Pin

```text
CorrectionOrigin = 1a7c0e6d690419c7e21a39d20f652e9817d08ab5
Scope = HISTORICAL_CLOSURE_TEST_FIXTURE_PIN_ONLY
ProductWrite = NOT_AUTHORIZED
ProjectionWrite = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The I09 closure fixture reconstructed its fixed fourth governance commit by
copying the current task-card test script. Adding the I10 contract changed that
blob, so the I09 focused contract failed its own fixed evidence guard. The I10
fixture used the same mutable-current pattern and would fail after the next test
addition.

Append exactly three direct, single-parent, non-empty commits after the fixed
I10 closure receipt:

1. this specification;
2. `tests/task-cards/verify-wave1-implementation-cards.sh`;
3. `scripts/verify-wave1-implementation-cards`.

The test commit changes only the two fixture materialization sources:

- I09 repaired-test materialization reads the test blob from fixed commit
  `cd6ef36bb20663c2b6465c43f2dbee01269e694c`;
- I10 repaired-test materialization reads the test blob from fixed commit
  `f2c22d2ed5ee90e1447ef1609b7b7037bd052bad`.

The final verifier admits this exact correction chain before applying the
normal I11 descendant rule. It fixes the spec/test evidence blobs, requires
correct modes, no rename/copy, no NUL, freezes all I10 product and eleven
closure projection bytes, and then restores the exact I11 WriteSet boundary.

Required RED/GREEN evidence is the I09 and I10 focused closure contracts:
before the test change I09 fails `I09_CLOSURE_GOVERNANCE_CHAIN_INVALID:evidence`;
after it, I09 remains `2+/8-` and I10 remains `2+/8-`. Static validation must
still report I10 closed, I11 uniquely READY, I12 blocked, and database/push
unauthorized. This is not a general repair registry or Harness exception.
