# W1-I11 Persistence Rebaseline Review Finding Repair

```text
RepairOrigin = f19e9b841802c3f69f95818eed2e013a65d54352
ReviewVerdict = NO_GO
P0 = 0
P1 = 2
P2 = 1
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. Findings

The first fixed governance candidate copied the current shared test and
verifier into its synthetic Git fixture. Later changes to either shared file
would make the fixed evidence drift. Its focused contract also omitted the
plan-required wrong-origin, count/order, merge/empty, rename/copy, NUL, and
obsolete-eight-path cases.

## 2. Exact correction

The append-only correction has exactly three direct, single-parent, non-empty,
single-path commits:

1. this specification;
2. `tests/task-cards/verify-wave1-implementation-cards.sh`;
3. `scripts/verify-wave1-implementation-cards`.

The test materializes the synthetic history from fixed blobs at
`8b5299332971aa85d3ed6563d0327c89136f05da` and
`f19e9b841802c3f69f95818eed2e013a65d54352`; it must not copy either current
working file. It adds real Git mutations for every missing oracle family and
asserts the specific production guard rather than only a generic failure.

The final verifier pins this specification and corrected test, validates the
three-step correction, freezes the original eight-step candidate, I10 product,
I10 closure projection, and the two I11 projection files, and then becomes the
single external xhigh review candidate. The task-card projection may be only
its direct child.

## 3. Complexity boundary

This correction may add no registry, generic transition engine, second
governance state, recovery protocol, or reusable Harness abstraction. It is a
one-time evidence pin and oracle completion. Product WriteSet and authorization
remain unchanged.
