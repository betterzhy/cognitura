# W1-I11 Obsolete WriteSet Oracle Repair

```text
RepairOrigin = eb77596e7e78ee64d8f39c92b87b5af9519cd16f
ReviewVerdict = NO_GO
P0 = 0
P1 = 1
P2 = 1
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The obsolete-eight-path fixture changed `ProductionFileLimit` to 9, so the
state guard rejected it before the WriteSet content comparison. It therefore
did not prove the promised oracle.

The replacement fixture keeps `PrimaryBoundary`, `ProductionFileLimit`,
`ProductionWriteSetException`, authorization, modes, and both projection paths
legal. It restores only the old eight-path WriteSet/forbidden content and must
fail specifically at
`I11_PERSISTENCE_REBASELINE_PROJECTION_MISMATCH:content:` for the I11 card.

The append-only correction is exactly this specification, the shared contract
test, and the verifier. It freezes the prior correction candidate and does not
add a new product path, state, framework, or authorization.
