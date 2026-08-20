# W1-I05 Verifier Recovery Test-Fixture Correction

```text
CorrectionKind = APPEND_ONLY_TEST_FIXTURE_CORRECTION
RejectedTestCandidateSHA = 4561f6de9bd61a85ad806f32608cd76288e9e9bc
RejectedTestCandidateVerdict = NO_GO
CorrectionScope = TEST_FIXTURE_FILE_MODE_ONLY
```

The rejected tests-only candidate copied
`tests/task-cards/verify-wave1-implementation-cards.sh` into its real-Git fixture and
forced mode `100644`. The canonical mode is `100755`, so the production verifier
correctly rejected the supposed positive fixture with
`W1-I05 verifier recovery path mode mismatch`.

History is not amended or reset. The accepted one-time recovery sequence is therefore
fixed to these seven commits and path roles:

```text
1. tests/ci/verify-markdown-links.sh
2. docs/superpowers/specs/2026-08-20-cognitura-w1-i05-verifier-recovery-design.md
3. docs/superpowers/plans/2026-08-20-cognitura-w1-i05-verifier-recovery.md
4. tests/task-cards/verify-wave1-implementation-cards.sh (rejected RED evidence)
5. docs/superpowers/specs/2026-08-20-cognitura-w1-i05-verifier-recovery-correction.md
6. tests/task-cards/verify-wave1-implementation-cards.sh (fixture-mode correction)
7. scripts/verify-wave1-implementation-cards
```

Step 4 must be the exact rejected SHA above and retain canonical repository mode
`100755`. Step 6 may change only the fixture materialization logic and must also retain
mode `100755`. In the simulated recovery chain, the first test commit is materialized
from the rejected SHA, then the corrected test blob is materialized as the second test
commit.

This is the sole exception to the original “each recovery path exactly once” rule. It
does not permit another correction, another repeated path, a mode exception, or an
additional recovery path. All non-test recovery paths still change exactly once. After
step 7, every descendant remains restricted to the exact W1-I05 WriteSet.
