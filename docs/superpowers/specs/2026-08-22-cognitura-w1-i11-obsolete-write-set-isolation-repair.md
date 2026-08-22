# W1-I11 Obsolete WriteSet Isolation Repair

```text
RepairOrigin = 9f0ae38fa79b46ad7bcf0d26c3baf3dfdb1aa01d
ReviewVerdict = NO_GO
P0 = 0
P1 = 1
P2 = 1
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The preceding oracle restored the whole old I11 card, so its content failure
could also be caused by old narrative and validation text. This repair starts
from the legal exact13 projection and replaces only the contiguous `WriteSet`
and `ForbiddenWriteSet` blocks with their origin values. Every other projected
byte remains unchanged.

The focused test must still reach the exact card content guard. The append-only
correction is exactly this specification, the shared contract test, and the
verifier. It adds no product path, state, framework, or authorization.
