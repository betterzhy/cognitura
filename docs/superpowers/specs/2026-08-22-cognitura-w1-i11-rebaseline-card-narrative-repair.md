# W1-I11 Rebaseline Card Narrative Repair

```text
RepairOrigin = a6bf632cb884b1537db18ab55183466f877cacbf
ChangeRisk = R2
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The corrected WriteSet intentionally includes one migration and one preview
compatibility change, but the projection helper still left the old completion
sentence saying that neither path changed. The focused contract passed because
both producer and verifier reproduced that stale sentence.

The repair changes the projection helper and expected projection together so
the card states the real boundary: real PostgreSQL CAS evidence, no Web or
Parser change, and no formal database write. It changes no WriteSet path,
runtime behavior, authorization, or test count.
