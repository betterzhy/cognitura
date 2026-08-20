# W1-I05 Review-Repair Fixture Correction

```text
CorrectionKind = APPEND_ONLY_TEST_HELPER_CORRECTION
RejectedTestCandidateSHA = 72a1d243ff93053ad5e254c7e7de280904bb903f
RejectedTestCandidateVerdict = NO_GO
CorrectionScope = UNTRACKED_PATH_CHANGE_DETECTION
```

The rejected test candidate used `git diff --quiet -- <path>` to decide whether a
fixture materialization was empty. Git does not report an untracked new path, so the
helper appended `# fixture-only repair RED` to the newly created repair specification
and broke its fixed evidence blob.

History remains append-only. The accepted review-repair sequence extends the first four
steps with:

```text
5. docs/superpowers/specs/2026-08-20-cognitura-w1-i05-review-repair-fixture-correction.md
6. tests/task-cards/verify-wave1-implementation-cards.sh (corrected helper)
7. scripts/verify-wave1-implementation-cards
```

The simulated chain must materialize step 4 from the exact rejected test blob, then
materialize this correction authority, then materialize the corrected test blob. The
helper may append a fixture-only marker only when the path is already tracked and its
tracked content is unchanged. An untracked new path must be committed byte-identically
to its authority source.

No other repeated path or additional correction is authorized. After step 7, only the
exact W1-I05 WriteSet is permitted.
