# W1-I11 Rebaseline Test Regex Repair

```text
RepairOrigin = 9d69d49f5a9ea830f81354a646a5e715e4668da7
ChangeRisk = R2
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The first RED contract used `#` as a Perl substitution delimiter while its
look-ahead contained the Markdown heading `## 6.`. Perl therefore terminated
the expression early before the production verifier could be exercised.

The append-only repair changes only that delimiter from `#` to `~`. It does not
change the replacement range, projection, WriteSet, positive/negative cases,
authorization, or product behavior. The final governance chain is the original
design, plan, RED test, this repair authority, the repaired test, and the
verifier, in that exact order.
