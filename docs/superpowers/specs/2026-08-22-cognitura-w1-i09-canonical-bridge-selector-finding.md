# W1-I09 canonical bridge selector finding

```text
Risk = R2
Origin = 2ce9f2d44f08421e886b09f3d52b3c673924d928
Finding = The legal bridge fixture selected both Omission.canonicalBytes and Block.canonicalBytes by indentation
RequiredBehavior = Only Block.canonicalBytes becomes public; Omission.canonicalBytes remains package-private
RepairChain = EXACT_THREE_COMMITS
Commit1 = docs/superpowers/specs/2026-08-22-cognitura-w1-i09-canonical-bridge-selector-finding.md
Commit2 = tests/task-cards/verify-wave1-implementation-cards.sh
Commit3 = scripts/verify-wave1-implementation-cards
ProductSemantics = UNCHANGED
ProductWriteSet = UNCHANGED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The repair must scope the test and verifier transformation to the existing
`public static final class Block` body. It must keep `Omission.canonicalBytes()`
package-private, preserve the exact three-method Authority, and retain every existing
negative case. The three commits are single-parent, nonempty, exact-path, correct-mode,
NUL-free and rename/copy-free. The final fixed candidate receives the one applicable
independent `sol/xhigh` review; no additional projection is required because counts and
the declared WriteSet do not change.
