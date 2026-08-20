# Cognitura W1-I05 Verifier Recovery Design

```text
RecoveryID = W1_I05_VERIFIER_RECOVERY
RecoveryKind = ONE_TIME_GOVERNANCE_RECOVERY
RecoveryOriginSHA = 01cc567f31c104da2cc5699f3cb487324fae7963
RequiredFirstRecoveryCommitSHA = ac42f26230cec348f3933400d8cd581c6e27970d
ActiveImplementationTaskCard = W1-I05
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. Purpose

The tracked-only Markdown gate repair is required because the former gate walked the
whole working tree and could consume non-authoritative untracked content. The repair
was correctly committed separately from W1-I05 product work, but the current Wave 1
verifier rejects every post-I04 path that is not in the I05 WriteSet.

This recovery admits exactly one fixed governance chain so the independent gate repair
can coexist with a pure I05 product candidate. It does not add a reusable maintenance
lane, relax the I05 WriteSet, or authorize another task card.

## 2. Exact recovery chain

The recovery chain starts at `RecoveryOriginSHA`. Its first commit must be
`RequiredFirstRecoveryCommitSHA`, whose parent must equal the origin. From the origin
through the unique recovery tip, the cumulative changed-path set must equal exactly:

```text
tests/ci/verify-markdown-links.sh
docs/superpowers/specs/2026-08-20-cognitura-w1-i05-verifier-recovery-design.md
docs/superpowers/plans/2026-08-20-cognitura-w1-i05-verifier-recovery.md
tests/task-cards/verify-wave1-implementation-cards.sh
scripts/verify-wave1-implementation-cards
```

Every path changes exactly once. Every commit is non-empty, single-parent, and
first-parent linear. Rename/copy records, NUL bytes, mode drift, extra paths, repeated
path changes, merges, and a different first recovery commit fail closed.

The recovery tip is the first descendant at which all five paths have changed exactly
once. It is discovered from Git history; no mutable projection or second execution
ledger is introduced.

## 3. Protected state

The recovery chain must not change:

- W1-I04 reviewed production or its closure projection paths;
- any W1-I05 production, test, or fixture path;
- W1-I02 state;
- formal database or remote-push authorization;
- `raw/**`, `.idea/**`, `temp-input/**`, image, persistence, API, or Web paths.

The Markdown repair remains independently testable: canonical validation reads only
Git-tracked Markdown; a broken untracked Markdown file cannot affect the result; a
broken tracked link still fails.

## 4. Post-recovery rule

After the unique recovery tip, every first-parent descendant before I05 closure must
again change only the exact W1-I05 WriteSet. Any recovery path changed a second time,
any unrelated maintenance path, any I04 closure projection, or any other product path
fails closed.

The verifier prints:

```text
W1I05VerifierRecoveryStatus = PASS
```

only when the recovery chain and the post-recovery history both satisfy this contract.

## 5. Verification and review

Public real-Git fixtures must prove the legal chain and reject at least: wrong first
commit, missing recovery path, extra path, repeated recovery path, merge, rename/copy,
mode drift, I05 work before the recovery tip, and an outside path after the recovery
tip. The ordinary task-card regression and unified Wave 1 implementation gate must
also pass.

The fixed recovery candidate receives one `deep_reviewer / gpt-5.6-sol / xhigh`
review. Ultra is not run. A zero-finding recovery review authorizes formation of a
separate pure I05 candidate; it does not close I05 or release I06.

## 6. Stop conditions

Stop without weakening the verifier if the fixed first recovery commit is not the
direct child of the origin, the exact path set cannot be reproduced, protected state
drifts, a public negative fixture passes, or the independent review reports a P0/P1
finding.
