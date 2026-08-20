# W1-I05 XML Copy-Inference Admission Repair

```text
RepairKind = APPEND_ONLY_I05_XML_COPY_INFERENCE_REPAIR
RepairOriginSHA = f25b392edfb71ba634aa96ad815816eb7a8658fa
FixedI05ImplementationSHA = 0e56cc854052b175f9389f7461912dab5b296c10
FixedI05FixtureCorrectionSHA = 0f28f0802a894d3e3af127751b3ddddaab8ee840
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The post-I04 descendant validator uses Git similarity detection with
`--find-copies-harder`. The original seven-line `invalid-vmerge.xml` was a new I05
fixture, but Git inferred it as a `C051` copy of the unchanged tracked
`server/src/test/resources/docx/security/minimal-document.xml`. No source path was
deleted or modified, and the target was inside the exact I05 fixture WriteSet.

The implementation response strengthened the negative fixture in the append-only
`FixedI05FixtureCorrectionSHA`. The original inference remains visible when the fixed
implementation commit is validated independently, so the admission rule requires a
bounded semantic exception rather than history rewriting.

The verifier may accept an inferred `C*` status only when all of these conditions hold:

1. the source path exists with the same blob and mode in the commit parent and child;
2. the target did not exist in the parent and is a regular `100644` XML file in
   `server/src/test/resources/docx/table/*.xml`;
3. the target is already inside the exact W1-I05 WriteSet;
4. rename statuses remain forbidden;
5. the two fixed I05 commits above retain their exact identities and single-parent
   order.

After `FixedI05FixtureCorrectionSHA`, the exact append-only repair sequence is:

```text
1. docs/superpowers/specs/2026-08-20-cognitura-w1-i05-xml-copy-inference-repair.md
2. tests/task-cards/verify-wave1-implementation-cards.sh
3. scripts/verify-wave1-implementation-cards
```

The test must use a real Git fixture rooted at the fixed I05 correction candidate and
must cover the legal chain, a legal post-repair I05 descendant, wrong evidence, merge,
and post-repair outside-WriteSet mutation. The final verifier binds the specification
and test blobs, then restores the I05-only descendant rule. No generic maintenance
lane, I05 closure, I06 release, database authorization, history rewrite, or remote
push is permitted.
