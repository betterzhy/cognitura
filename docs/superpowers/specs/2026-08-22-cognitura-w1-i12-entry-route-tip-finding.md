# W1-I12 Entry Route Tip Finding Closure

```text
FindingOrigin = 99e027d
Finding = I11_POST_CLOSURE_PIN_SELECTED_LATEST_VERIFIER
CorrectionKind = APPEND_ONLY_EXACT_THREE
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The W1-I12 entry RED contract exposed that the I11 post-closure fixture-pin route located its tip
by selecting the latest verifier commit after the I11 receipt. A later I12 verifier therefore
became an accidental member of the historical I11 exact-three chain.

The correction must:

- bind the already reviewed I11 post-closure fixture-pin tip to
  `793790aa357ee56e5106893a7bcd0f6eefabd1f8`;
- validate the fixed I12 four-step entry before this correction;
- consist of exactly this specification, the shared real-Git contract, and the production
  verifier, with modes `100644/100755/100755`;
- keep every I11 product byte, I11 closure projection and I12 task-card projection frozen;
- continue allowing descendants only in the rebaselined thirteen-path I12 product WriteSet.

The existing focused contract remains the product oracle. It must materialize this exact-three
correction before running the corrected verifier, then retain its `2 positive / 4 negative`
result. No new task-card state, Schema, runtime behavior, deployment or push authority is added.
