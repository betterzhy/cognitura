# Cognitura Visual Style Baseline Evidence

```text
CanonicalProjectName = Cognitura
EvidenceSet = VISUAL_STYLE_BASELINE_VSB_03
EvidenceStatus = FIXED_CANDIDATE
CandidateSHA = SEE_VISUAL_STYLE_BASELINE_EXECUTION_STATE_AFTER_FIXED_REVIEW
CaptureInputSHA = efc763966d64fc808e9098bec52566edb7d15dc3
ReferenceSHA256 = a8446ea987f6a1710c3845f837e2776190997b77f81584cf7b667cbfebe2f95f
Node = 24.18.0
pnpm = 11.17.0
Chrome = Google Chrome 151.0.7922.138
CaptureToolBinding = FIXED_CANDIDATE_TREE
ProbeInput = tests/visual-style-baseline/browser-probe.html
RuntimeGuardInput = tests/visual-style-baseline/browser-runtime-guard.js
ComparisonInput = tests/visual-style-baseline/reference-comparison.html
HistoricalEvidenceOverwrite = FORBIDDEN
```

Capture command: `scripts/capture-visual-style-baseline --repo-root . --output-dir docs/design/visual-style-baseline/evidence`

| File | Viewport | Bytes | SHA-256 | Capture command | Real DOM probe | Computed style | Runtime guard | Comparison ready | Allowed requests | Freshness |
|---|---:|---:|---|---|---|---|---|---|---:|---|
| module-default-reading-1440x1100.png | 1440x1100 | 113892 | bf753320352d7c9aab7bc7c40d9f8b40e1f649c174684695e77d1f3223e65ab0 | fixed `.138` capture | PASS | PASS | PASS | PASS | 62 | PASS |
| module-default-reading-1280x960.png | 1280x960 | 88891 | a2fd1fbf5623fe8e2e28dc23317d3d6064102873bc2a050251657ca9d8b992fb | fixed `.138` capture | PASS | PASS | PASS | PASS | 62 | PASS |
| module-default-reading-1024x900.png | 1024x900 | 86766 | bc7ddbb666f6475ee1e114f76a79bd0920bd4ca94744aa559f9c5edb115c01ef | fixed `.138` capture | PASS | PASS | PASS | PASS | 62 | PASS |
| reference-comparison.png | 2560x1100 | 943719 | 46db84298c34a072ac6c48e079d4a48961b875a0ec8810b25075e1b3abe20b53 | fixed `.138` comparison | PASS | PASS | PASS | PASS | 62 | PASS |

The three candidate images are uninstrumented page captures. Before every
capture, the verifier runs an instrumented and an uninstrumented same-origin
probe at the same viewport. The comparison image is a style-family aid only;
it does not grant page-architecture or interaction authority to the historical
dashboard reference.
