# W1-I05 Recovery Review Repair

```text
RepairKind = APPEND_ONLY_FIXED_CANDIDATE_REPAIR
RepairOriginSHA = 2fa4e067a213be03660384b4b32a9cb73c0ad64d
RepairOriginReviewVerdict = NO_GO_P0_0_P1_3_P2_0
ActiveImplementationTaskCard = W1-I05
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. Repair scope

This repair closes the three P1 findings from the independent L3 review of the fixed
recovery candidate. It does not amend the rejected candidate, introduce a generic
maintenance lane, close I05, or release I06.

The repaired verifier must bind the original recovery to this exact ordered commit
sequence, not merely to equivalent blobs:

```text
ac42f26230cec348f3933400d8cd581c6e27970d
87a352fe7c6ebd23bed915de81ef072b28c4e104
cbf7fe6c37f3912b30562bcfce0da9c93e070fcc
4561f6de9bd61a85ad806f32608cd76288e9e9bc
348201e7a37ac07102d5dda78a20a37dd8e74eb4
dabb7d88de90b28e0cc7c1d99227427308edf717
2fa4e067a213be03660384b4b32a9cb73c0ad64d
```

Any substitute commit, parent, order, tree, or tip fails closed.

## 2. Exact repair sequence

After `RepairOriginSHA`, the one-time repair changes paths in this exact order:

```text
1. docs/superpowers/specs/2026-08-20-cognitura-w1-i05-recovery-review-repair.md
2. tests/ci/verify-markdown-links.sh (masked-target RED)
3. tests/ci/verify-markdown-links.sh (tracked-target GREEN)
4. tests/task-cards/verify-wave1-implementation-cards.sh
5. scripts/verify-wave1-implementation-cards
```

Every commit is single-parent and non-empty. Rename/copy, NUL, mode drift, an extra
path, a missing step, or another repeated path fails. Step 2 is fixed as the rejected
Markdown RED evidence; step 3 may change only the target-authority behavior and its
self-test. Step 4 supplies the public real-Git adversarial matrix; step 5 is the only
production verifier change.

The first complete five-step prefix is the repair tip. Every later descendant is again
restricted to the exact W1-I05 WriteSet.

## 3. Markdown target authority

In `tracked` scope, both the source Markdown and every local link target must be Git
tracked. Worktree existence alone is insufficient. A tracked Markdown file pointing to
an untracked same-name target must fail even when that target exists on disk. A tracked
target must also exist in the working tree. Filesystem-scope negative fixtures retain
their existing behavior.

## 4. Required real-Git evidence

The focused verifier-repair contract must include:

- the exact fixed original recovery candidate;
- a legal five-step repair chain;
- a legal post-tip I05 table descendant;
- wrong first repair path;
- missing, extra, or repeated repair path;
- merge and rename/copy commits;
- mode drift and NUL;
- an I05 path before repair completion;
- an outside path after the repair tip.

Each negative must call the public verifier and assert a stable diagnostic. The ordinary
task-card regression, Markdown contract, unified Wave 1 implementation Gate, and
`git diff --check` must pass.

## 5. Review and stop conditions

The repaired fixed candidate receives one new
`deep_reviewer / gpt-5.6-sol / xhigh / ONE` review. Ultra is not run. Any P0/P1 finding,
missing negative evidence, fixed-candidate identity mismatch, protected I04 drift, or
authorization drift stops before I05 staging.
