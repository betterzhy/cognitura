# W1-I10 Closure Design

```text
ChangeRisk = R2
ProductCandidate = 9eb48f18b8c0ab3552a3f52cfe3a6f5e61db51ad
ProductParent = f4b22f1d5be85e8c9847399fab5d4490056d4e1f
ProductTree = a227ce11facc84b0be56d65f459a8d6005e16bb3
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
ReleasedTaskCard = W1-I11
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. Purpose

Close only W1-I10 after its fixed-candidate zero-finding review and release only
W1-I11. W1-I12 remains `BLOCKED_BY_DEPENDENCY` because it depends on both I10
and I11. This change does not modify product code, database state, deployment,
or remote branches.

## 2. Fixed boundaries

The product candidate is the literal commit above. Its cumulative product diff
from the I09 closure receipt is exactly the eight W1-I10 WriteSet paths. Closure
governance must not change those bytes.

The governance chain is append-only and contains exactly three direct,
single-parent, non-empty commits in this order:

1. this specification;
2. `tests/task-cards/verify-wave1-implementation-cards.sh`;
3. `scripts/verify-wave1-implementation-cards`.

Every commit changes exactly its declared path, preserves the expected mode,
contains no NUL byte, and has no rename/copy inference. The first two evidence
blobs are fixed by commit identity. The final verifier tip is the external
fixed candidate for one `deep_reviewer / xhigh` review; no recursive in-repo
claim can prove that review occurred.

## 3. Atomic closure projection

The reviewed verifier tip may have exactly one direct closure child changing
these eleven paths and no others:

```text
AGENTS.md
README.md
docs/design/wave-1/README.md
docs/engineering/cognitura-design-index.md
docs/engineering/cognitura-wave-1-design-plan.md
docs/engineering/cognitura-wave-1-design-acceptance.md
docs/engineering/cognitura-wave-1-implementation-plan.md
docs/task-cards/wave-1/README.md
docs/task-cards/wave-1-implementation/README.md
docs/task-cards/wave-1-implementation/W1-I10-source-preview-query-api.md
docs/task-cards/wave-1-implementation/W1-I11-partial-acceptance-command-api.md
```

The projection must be a deterministic full-file transformation from the
reviewed verifier tip. It sets I10 `DONE`, I11 `READY`, I11 business
authorization `USER_AUTHORIZED`, one and only one READY card, and preserves I12
as blocked. All database, deployment, release, and push authorization text is
byte-preserved except for the exact status/narrative replacements defined by
the verifier.

## 4. Review receipt

The implementation plan ends with exactly one `I10` receipt containing the
fixed product Candidate/Parent/Tree, the reviewed governance
Candidate/Parent/Tree, `L3/deep_reviewer/xhigh/ONE/GO`, zero P0/P1/P2,
`Ultra=NOT_RUN`, `I10ClosureReleasedTaskCard=W1-I11`, and unchanged database
and push boundaries.

## 5. Required contract

The real-Git focused contract has two positive cases: explicit closure
transition and static closed state. It rejects at least:

- wrong product or governance receipt identity;
- non-zero finding or non-GO receipt;
- missing/extra/rename/copy projection paths;
- any full-file projection drift, READY count drift, or authorization drift;
- I10 not DONE, I11 not READY, I12 prematurely READY;
- product-byte drift during governance or closure;
- any post-receipt descendant outside the exact W1-I11 WriteSet.

After closure, descendants are limited to W1-I11's eight task-card paths.
There is no generic Harness, registry, recovery framework, or parallel release.
