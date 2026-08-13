# Cognitura VSB Copy Classification Recovery Implementation Plan

> Execute with subagent-driven development, RED before GREEN, and fixed
> review checkpoints.  Do not amend or delete failed history.

**Goal:** restore a legal VSB-02 release anchor after Git's copy similarity
heuristic rejected the Authority-required independent HTML entry.

**Authority:** the newest fixed non-amend successor commit containing
`2026-08-14-cognitura-vsb-copy-classification-recovery-design.md`.

## Task 1 — Freeze evidence and RED

1. Assert origin `9904d3deb87e4a3e2820c5a12463929916057c36`, failed
   candidate `b16f867bfb951bf969ac8c4a8697c8b8913325bd`, their direct-parent
   relationship, and the exact `C053` classification.
2. Add a public G3/PENDING positive and a public explicit positive for the
   fixed pair; observe the current
   `candidate chain commit must not rename or copy paths` RED.
3. Require literal `C053`; add negatives for `R*`, every non-053 C score
   including `C100`, alternate source/target, changed source,
   Owner-internal copy, mode, merge, ledger, extra path, and low rename limit.
4. Add a static mutate/nominal-receipt case proving ordinary static validation currently
   accepts a receipt whose explicit replay fails.
5. Add G3 chain negatives for parent count, empty commit, outside path, ledger,
   reverted intermediate drift, authority blob/mode, rename/copy, NUL, and
   incomplete cumulative WriteSet.

## Task 2 — GREEN verifier semantics

1. Implement the literal HTML-entry classification predicate from the design.
2. Keep exact paths, single-parent, non-empty commits, mode, NUL, ledger, and
   rename/copy checks fail-closed.
3. Reuse explicit replay for the latest ordinary non-terminal receipt in static
   mode; admit only exact G3/PENDING via the fixed recovery-chain validator.
4. Add version-4 `VERIFIER_RECOVERY` parsing, exact block construction,
   explicit/static validation, exactly-once history replay, and ordinary
   transition byte preservation.
5. Recognize only a validated recovery receipt as the VSB-02 release anchor.

## Task 3 — Verify and fix G3

1. Run the focused recovery matrix.
2. Run the full VSB contract exactly once after the candidate is stable.
3. Run static VSB, Wave 1 suspended-state verification, Bash 3.2 syntax, and
   `git diff --check`.
4. Prove the cumulative origin-to-G3 WriteSet is the exact five paths and the
   ledger/W1-I03 blobs are unchanged.
5. Commit G3 and execute one `L3 / deep_reviewer / xhigh / ONE` fixed review.

## Task 4 — Create and validate R3

1. From the fixed G3, use `apply_patch` to create the exact version-4 ledger.
2. Generate it mechanically from `9904d3d...`; prove byte-for-byte equality,
   mode `100644`, NUL absence, exact insertion, Owner deletion, and final
   newline preservation.
3. Commit only `execution-state.md` as the direct child R3.
4. Validate G3→R3 explicitly and validate R3 statically.
5. Re-run the Wave 1 suspended-state verifier and `git diff --check`.

## Task 5 — Resume VSB-02

Only after R3 passes may a new VSB-02 candidate start.  It must be a real
single-parent Owner chain from R3, cumulatively cover the complete 20-path
WriteSet, fix the recorded P1/P2, and receive a new single L3 xhigh review.
