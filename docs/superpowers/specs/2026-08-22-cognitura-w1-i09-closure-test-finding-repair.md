# Cognitura W1-I09 closure test finding repair

The first RED contract used the generic `set_field` helper for active-task
fields. That helper replaces every matching line and therefore rewrote the
historical W1-I09 runtime receipt as well as the live top-level field. A closure
projection must preserve historical receipts byte-for-byte.

The append-only closure governance sequence is corrected to:

1. original closure specification;
2. original RED contract;
3. this finding record;
4. corrected RED contract using first-occurrence field replacement;
5. closure verifier.

The two test commits are distinct evidence. The verifier must bind both blobs,
and the corrected real-Git fixture must keep prior receipts unchanged. No I09
product path, formal database authority, deployment, or remote push is changed.
