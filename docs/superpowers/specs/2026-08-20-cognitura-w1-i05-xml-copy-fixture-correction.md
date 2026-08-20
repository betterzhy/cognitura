# W1-I05 XML Copy Repair Fixture Correction

```text
CorrectionKind = APPEND_ONLY_TEST_FIXTURE_CORRECTION
RejectedTestSHA = 803642d1a4b1172f8c48df98b3dfb9c36e646c49
RejectedFailure = GIT_CHERRY_PICK_UNSUPPORTED_Q_OPTION
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The rejected test correctly established the XML copy-admission scenarios, but its
candidate-substitution fixture invoked `git cherry-pick -q`. The repository's Git
version does not support `-q` for `cherry-pick`, so the focused contract exited 129
before reaching the verifier assertion.

The correction removes only that unsupported option. The fixed repair sequence is now:

```text
1. docs/superpowers/specs/2026-08-20-cognitura-w1-i05-xml-copy-inference-repair.md
2. tests/task-cards/verify-wave1-implementation-cards.sh (rejected fixture)
3. docs/superpowers/specs/2026-08-20-cognitura-w1-i05-xml-copy-fixture-correction.md
4. tests/task-cards/verify-wave1-implementation-cards.sh (corrected fixture)
5. scripts/verify-wave1-implementation-cards
```

The verifier must bind the first four evidence blobs. All other authority and stop
conditions from the original repair remain unchanged.
