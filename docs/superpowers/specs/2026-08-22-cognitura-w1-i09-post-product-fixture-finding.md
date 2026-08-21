# W1-I09 post-product fixture finding closure

```text
Risk = R2
Origin = 0741e5349f3d93fa0e5606b9b7a0cb38e8ee0cf6
Finding1 = Focused legal product fixtures checked out HEAD and become non-replayable after the product commit lands
Finding2 = The I02 reset fixture cannot truncate V1 parent tables after V2 child foreign keys exist
RepairChain = EXACT_THREE_COMMITS
AddedWriteSet = NONE
ProductWriteSetCount = 29
ProductionFileLimit = 20
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

Canonical bridge product fixtures must start from fixed projection `90a77d7`; V2
compatibility product fixtures must start from their discovered fixed projection, never
from mutable `HEAD`. This keeps focused contracts replayable after product landing.

`SourcePersistenceIntegrationTest` may receive one final exact compatibility change:
its reset resource changes from `db/source-persistence-fixture.sql` to the already
declared I09 `db/source-command-runtime-fixture.sql`, whose `TRUNCATE ... CASCADE`
resets the complete migrated Schema. No other byte may change, and the path may not be
modified again. The existing isolated PostgreSQL/container-removal boundaries remain.

The fixed spec/test/verifier chain is single-parent, nonempty, exact-path,
rename/copy-free, NUL-free and mode-correct. Focused real-Git evidence must include the
legal reset successor, a second reset modification, extra reset semantics, and prove
the canonical/V2 product fixtures remain replayable after their real product commits.
