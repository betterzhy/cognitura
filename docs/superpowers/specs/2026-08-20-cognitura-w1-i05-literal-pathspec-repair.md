# W1-I05 Literal Pathspec Review Repair

```text
RepairKind = APPEND_ONLY_LITERAL_PATHSPEC_REPAIR
RepairOriginSHA = 083a969b8a7d1468d0274e1ce227a46ceb16db30
RepairOriginReviewVerdict = NO_GO_P0_0_P1_1_P2_0
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

The tracked Markdown target check passes a user-controlled relative link target to
`git ls-files` as a pathspec. Git pathspec metacharacters can make an untracked target
such as `READM[E].md` match another tracked path such as `README.md`.

The repair must add a RED in which a tracked Markdown source links to an existing
untracked `READM[E].md` while tracked `README.md` also exists. The target must be
rejected as untracked. GREEN must invoke the target lookup with Git literal-pathspec
semantics for both files and directory prefixes; the source Markdown enumeration may
retain its intentional `*.md` pattern.

After `RepairOriginSHA`, the exact append-only sequence is:

```text
1. docs/superpowers/specs/2026-08-20-cognitura-w1-i05-literal-pathspec-repair.md
2. tests/ci/verify-markdown-links.sh (literal-pathspec RED)
3. tests/ci/verify-markdown-links.sh (literal-pathspec GREEN)
4. tests/task-cards/verify-wave1-implementation-cards.sh
5. scripts/verify-wave1-implementation-cards
```

The updated real-Git fixture must materialize the fixed `083a969` candidate before
this five-step sequence. The final verifier binds the first four evidence blobs, then
restores the exact I05-only descendant rule. No further maintenance path, I05 closure,
I06 release, database authorization, or remote push is permitted.
