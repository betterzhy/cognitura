# Cognitura W1-I09 closure design

## 1. Decision

Close the already reviewed W1-I09 product candidate and release W1-I10 without
adding another reusable governance framework.

```text
ClosureOrigin = eab57ecc86b675b4b725d6d9506338282dbae9a7
ReviewedParent = bbd4c1c2b30af1efa03aea11c97b1b1a21b183cd
ReviewedTree = c16a5da8605949d29cd09e316a8be5434ab7f8f4
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewVerdict = GO
P0 = 0
P1 = 0
P2 = 0
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The closure is an R2 state transition. It does not change the reviewed I09
product, connect to a formal database, deploy, or push.

## 2. Append-only governance chain

Starting at `ClosureOrigin`, the closure authority consists of exactly three
non-empty, single-parent, single-path commits in this order:

1. this specification, mode `100644`;
2. `tests/task-cards/verify-wave1-implementation-cards.sh`, mode `100755`;
3. `scripts/verify-wave1-implementation-cards`, mode `100755`.

Rename/copy inference and NUL bytes are forbidden. The specification and test
blobs are fixed evidence. The third commit becomes the governance candidate
reviewed by the final independent gate; the following projection receipt binds
its candidate, parent, and tree. This external fixed-candidate review is the
trust root and is not recursively encoded by another verifier commit.

## 3. Exact closure projection

The projection is the direct child of the reviewed governance candidate and
changes exactly these eleven paths:

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
docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md
docs/task-cards/wave-1-implementation/W1-I10-source-preview-query-api.md
```

Every projected file is derived byte-for-byte from the governance candidate by
the prescribed state replacements. All other bytes remain frozen. The resulting
state is:

```text
TaskCardSetStatus = READY_FOR_EXECUTION
ActiveTaskCard = W1-I10
ReadyTaskCardCount = 1
W1-I09 = DONE
W1-I10 = READY
W1-I10.BusinessImplementationAuthorization = USER_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The implementation plan ends with one `## 19. I09 关闭收据` block. It records
the reviewed product identity, reviewed governance identity, `GO`, zero P0/P1/P2,
`Ultra = NOT_RUN`, and `I09ClosureReleasedTaskCard = W1-I10`.

## 4. Fail-closed rules

The focused real-Git contract must prove two legal paths (explicit transition
and static state) plus independent rejection of at least:

- wrong product or governance receipt identity;
- authorization drift;
- I09/I10 status or ready-count drift;
- extra projection path;
- governance path drift;
- reviewed I09 product drift;
- a post-closure descendant outside the exact I10 WriteSet.

After the receipt, non-empty descendants are allowed only within the eight
paths on the W1-I10 task card. I11 remains blocked. No product implementation
begins until the closure candidate passes the fixed-candidate `xhigh` review.
