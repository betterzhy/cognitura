# Cognitura W1-I06 Entry Repair and Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Repair the closed W1-I04 image-placeholder seam, implement the approved W1-I06 image/relationship projection, and close I06 into an explicit database-gated terminal state without inventing block identities or accessing external targets.

**Architecture:** An append-only governance successor admits one exact I04 repair chain while preserving the original I06 WriteSet. I04 emits genuine image placeholders and reserves global source-order slots; I06 resolves caller-owned block IDs, projects internal media through an immutable sink, and preserves external relationship literal digests without dereference. I06 closure does not release I07 because I02 still requires its independent database Gate.

**Tech Stack:** JDK 21, Maven 3.9.16, Java records, DOM over verified in-memory OOXML, SHA-256, Bash 3.2, Git object inspection.

**Spec:** `docs/superpowers/specs/2026-08-21-cognitura-w1-i06-entry-repair-design.md`

```text
EntryRepairOriginSHA = 5937fe6845f3cd7759dcaa5156bfc9f9060b5407
EntryRepairDesignSHA = d8c0614d736126cdb914508084d0c84c61420d88
ActiveTaskCard = W1-I06
```

## Global Constraints

- Keep W1-I06 as the sole `READY` card until its reviewed closure receipt is committed.
- Keep I02 `QUEUED`; do not set `FormalDatabaseGate = PASS` and do not write any database.
- Never read, stat, resolve DNS for, open, or request an external relationship target.
- Do not modify `raw/**`, `.idea/**`, Web, API, persistence, migration, deployment, or remote Git state.
- Do not reset, amend, squash, force-push, or rewrite the failed/repair history.
- Use separate RED and GREEN commits for the I04 seam and I06 product behavior.
- Use one `deep_reviewer / gpt-5.6-sol / xhigh / ONE` gate for the repaired I04 fixed candidate and one for the final I06 fixed candidate. Ultra stays `NOT_RUN` unless a new explicit escalation reason is recorded.
- Run focused tests during iteration; run the complete server and Wave 1 gates only at stable review candidates and final closure.

---

### Task 1: Admit the append-only entry-repair chain

**Files:**
- Create: `docs/superpowers/plans/2026-08-21-cognitura-w1-i06-entry-repair-and-implementation.md`
- Modify: `tests/task-cards/verify-wave1-implementation-cards.sh`
- Modify: `scripts/verify-wave1-implementation-cards`

**Interfaces:**
- Consumes: fixed origin `5937fe6`, design `d8c0614`, Git first-parent history.
- Produces: `W1I06EntryRepairStatus = PENDING|PASS` and a fail-closed exact path/order admission contract.

- [ ] **Step 1: Commit this plan as the second governance commit**

```bash
git add docs/superpowers/plans/2026-08-21-cognitura-w1-i06-entry-repair-and-implementation.md
git diff --cached --name-only
git commit -m "docs: plan W1-I06 entry repair"
```

- [ ] **Step 2: Write the real-Git RED contract**

Add `--w1-i06-entry-repair-contract-only`. Build isolated repositories from `5937fe6` and require:

```text
Governance prefix = design -> plan -> test -> verifier
Repair prefix = test+fixture -> production parser+cursor
Post-repair descendants = original W1-I06 WriteSet only
```

Positive fixtures cover the governance-only pending tip and a complete two-commit repair. Negative
fixtures replace the design commit, insert a merge/empty/extra commit, reorder repair commits,
change an undeclared I04/I05 path, or add a post-repair path outside I06.

Run:

```bash
bash tests/task-cards/verify-wave1-implementation-cards.sh --w1-i06-entry-repair-contract-only
```

Expected: nonzero exit from `post-I05-closure descendant changed a path outside the W1-I06 WriteSet`.

- [ ] **Step 3: Commit only the RED contract**

```bash
git add tests/task-cards/verify-wave1-implementation-cards.sh
git commit -m "test: define W1-I06 entry repair chain"
```

- [ ] **Step 4: Implement the minimal governance GREEN**

In `scripts/verify-wave1-implementation-cards`, bind the known design, plan, and test commit IDs;
require the fourth governance commit to change only the verifier; validate all commits as single
parent, nonempty, no rename/copy, correct mode, and NUL-free. After that prefix, accept only the
exact two repair commits in order and then the pre-existing I06 descendant paths.

The current verifier candidate must report `PENDING` before the repair commits exist and must not
weaken the I05 reviewed-product freeze.

- [ ] **Step 5: Verify and commit governance GREEN**

```bash
bash -n scripts/verify-wave1-implementation-cards
bash -n tests/task-cards/verify-wave1-implementation-cards.sh
bash tests/task-cards/verify-wave1-implementation-cards.sh --w1-i06-entry-repair-contract-only
scripts/verify-wave1-implementation
git diff --check
git add scripts/verify-wave1-implementation-cards
git commit -m "feat: verify W1-I06 entry repair chain"
```

Record Candidate/Parent/Tree and obtain one xhigh zero-finding review before changing I04 bytes.

### Task 2: Repair I04 placeholder and source-order compatibility

**Files:**
- Create: `server/src/test/resources/docx/text/inline-images.xml`
- Modify: `server/src/test/java/io/cognitura/source/docx/text/TextListSectionParserTest.java`
- Modify: `server/src/main/java/io/cognitura/source/docx/text/TextListSectionParser.java`
- Modify: `server/src/main/java/io/cognitura/source/docx/text/SourceOrderCursor.java`

**Interfaces:**
- Consumes: verified `word/document.xml` and the existing text/list/section parsing rules.
- Produces: text candidates containing genuine `U+FFFC` placeholders and exact reserved image source-order slots.

- [ ] **Step 1: Create the fixture and failing behavioral test**

The XML fixture contains an astral code point before the first drawing, two supported images in one
paragraph, a following paragraph, and a literal-placeholder variant constructed in the test. Assert
literal expected values:

```java
assertThat(blocks).extracting(DocumentBlockCandidate::sourceOrder).containsExactly(0, 3);
assertThat(blocks.getFirst().text()).isEqualTo("😀￼￼");
```

The production mutations caught are: rejecting real drawing nodes, reserving zero/one instead of
two child positions, accepting literal `U+FFFC`, or reordering following text. The later I06 test
uses the astral prefix to prove Unicode code-point offset calculation.

- [ ] **Step 2: Run and commit RED**

```bash
./mvnw -f server/pom.xml -Dtest=io.cognitura.source.docx.text.TextListSectionParserTest test
git add server/src/test/java/io/cognitura/source/docx/text/TextListSectionParserTest.java server/src/test/resources/docx/text/inline-images.xml
git commit -m "test: define I04 image placeholder seam"
```

Expected: the new positive case fails with `UNSUPPORTED_DOCX_FLOW:run/drawing`.

- [ ] **Step 3: Implement minimal GREEN**

In `TextListSectionParser`, append one `U+FFFC` only for a direct supported `drawing` or `pict`,
reject literal placeholders inside `w:t`, count placeholders by Unicode code point, and reserve that
many child positions after the parent block.

In `SourceOrderCursor`, expose:

```java
int nextBlock()
void reserveChildren(int count)
void requireIssuedBlockOrder(List<DocumentBlockCandidate> blocks)
```

Use `Math.addExact`-equivalent checked arithmetic and reject negative reservations. Store the exact
issued block-order list so validation proves candidates match the cursor rather than merely being
monotonic.

- [ ] **Step 4: Run GREEN and regressions**

```bash
./mvnw -f server/pom.xml -Dtest='io.cognitura.source.docx.text.*Test,io.cognitura.source.docx.table.*Test' test
git diff --check
```

- [ ] **Step 5: Commit the exact repair production paths**

```bash
git add server/src/main/java/io/cognitura/source/docx/text/TextListSectionParser.java server/src/main/java/io/cognitura/source/docx/text/SourceOrderCursor.java
git diff --cached --name-only
git commit -m "fix: preserve I04 image placeholder order"
```

Run the focused entry-repair contract, complete server tests, and the full Wave 1 gate. Record the
repair Candidate/Parent/Tree and obtain one xhigh zero-finding review before Task 3.

### Task 3: Implement I06 anchors and internal media projection

**Files:**
- Create: `server/src/main/java/io/cognitura/source/docx/image/ImageRelationshipProjector.java`
- Create: `server/src/main/java/io/cognitura/source/docx/image/ImageAnchor.java`
- Create: `server/src/main/java/io/cognitura/source/docx/image/ImmutableMediaRef.java`
- Create: `server/src/main/java/io/cognitura/source/docx/image/MediaDigest.java`
- Create: `server/src/test/java/io/cognitura/source/docx/image/ImageRelationshipProjectorTest.java`
- Create: `server/src/test/resources/docx/image/internal-images-document.xml`
- Create: `server/src/test/resources/docx/image/internal-images-document.xml.rels`
- Create: `server/src/test/resources/docx/image/internal-images-content-types.xml`

**Interfaces:**
- Consumes: `SafeDocxPackage`, `ParentBlockIdResolver`, `ImmutableMediaSink`.
- Produces: immutable `Projection`, `ProjectedImage`, `ImageAnchor`, `MediaDigest`, and `ImmutableMediaRef` values.

- [ ] **Step 1: Write internal-image RED tests**

Use a real synthetic DOCX package containing paragraph and table-cell images; the test packages
literal independent byte arrays as the two verified media parts. The parent resolver
returns literal IDs `block-paragraph-1` and `block-table-1`; the in-memory sink returns
`media:test:<sha256>`. Assert exact source order, code-point offsets, child ordinals, table row/column,
media types, byte lengths, hand-computed SHA-256 values, and defensive-copy behavior.

Add negative cases for missing/duplicate relationship IDs, absent media parts, missing/ambiguous
content types, blank parent resolution, duplicate binding, literal placeholder mismatch, and a sink
returning a blank/path-like ref.

- [ ] **Step 2: Run and commit RED**

```bash
./mvnw -f server/pom.xml -Dtest=io.cognitura.source.docx.image.ImageRelationshipProjectorTest test
git add server/src/test/java/io/cognitura/source/docx/image/ImageRelationshipProjectorTest.java server/src/test/resources/docx/image
git commit -m "test: define DOCX image projection"
```

Expected: test compilation fails because the five I06 production types do not exist.

- [ ] **Step 3: Implement the value types**

Create `ImageAnchor` with `Kind.PARAGRAPH_INLINE|TABLE_CELL_INLINE`, real parent ID, code-point
offset, child ordinal, and nullable row/column validation. Create `MediaDigest` with media type,
nonnegative byte length, and `SourceHash`; create `ImmutableMediaRef` that rejects blank, absolute
path, `file:`, `http:`, and `https:` values.

- [ ] **Step 4: Implement internal projection**

Securely parse only verified in-memory XML, traverse the closed paragraph/table-cell flow, resolve
DrawingML/VML relationship IDs, map verified content types, read only internal relationship bytes,
compute the digest, call the sink with a defensive copy, resolve the real parent block ID, and build
the canonical payload hash from length-prefixed UTF-8 fields.

- [ ] **Step 5: Run GREEN and commit production**

```bash
./mvnw -f server/pom.xml -Dtest=io.cognitura.source.docx.image.ImageRelationshipProjectorTest test
git add server/src/main/java/io/cognitura/source/docx/image/ImageRelationshipProjector.java server/src/main/java/io/cognitura/source/docx/image/ImageAnchor.java server/src/main/java/io/cognitura/source/docx/image/ImmutableMediaRef.java server/src/main/java/io/cognitura/source/docx/image/MediaDigest.java
git commit -m "feat: project internal DOCX images"
```

### Task 4: Preserve external literals with zero target access

**Files:**
- Create: `server/src/main/java/io/cognitura/source/docx/image/ExternalRelationshipLiteral.java`
- Create: `server/src/test/java/io/cognitura/source/docx/image/ExternalRelationshipNoAccessTest.java`
- Create: `server/src/test/resources/docx/image/external-images-document.xml`
- Create: `server/src/test/resources/docx/image/external-images-document.xml.rels`

**Interfaces:**
- Consumes: external `RelationshipMetadata` already classified by I03.
- Produces: identical literal SHA-256 in image payload, payload content hash input, and external diagnostics with zero target operations.

- [ ] **Step 1: Write the calibrated no-access RED test**

Start file, HTTP, and DNS canaries in a child JVM. Calibrate that each observer blocks its channel,
then run the real I06 projector and assert:

```text
OPERATION_ATTEMPTS=0
EXTERNAL_IMAGES=3
DIGESTS_VERIFIED=3
```

Also assert that changing only the target literal changes both the external diagnostic digest and
the image payload content hash while never exposing the literal.

- [ ] **Step 2: Run and commit RED**

```bash
./mvnw -f server/pom.xml -Dtest=io.cognitura.source.docx.image.ExternalRelationshipNoAccessTest test
git add server/src/test/java/io/cognitura/source/docx/image/ExternalRelationshipNoAccessTest.java server/src/test/resources/docx/image/external-images-document.xml server/src/test/resources/docx/image/external-images-document.xml.rels
git commit -m "test: prove external image target isolation"
```

- [ ] **Step 3: Implement external projection GREEN**

Create `ExternalRelationshipLiteral` from the classifier metadata only. Update the projector to
skip the media sink for external mode, require null media fields, propagate the exact digest and
security disclosure, and include the digest in canonical payload bytes. Never call
`readRelationshipTarget` in the external branch.

- [ ] **Step 4: Verify and commit**

```bash
./mvnw -f server/pom.xml -Dtest='io.cognitura.source.docx.image.*Test' test
git add server/src/main/java/io/cognitura/source/docx/image/ExternalRelationshipLiteral.java server/src/main/java/io/cognitura/source/docx/image/ImageRelationshipProjector.java
git commit -m "feat: preserve external image literals"
```

### Task 5: Fix the I06 candidate, review, and close into the database gate

**Files:**
- Modify only if a finding requires same-scope repair: original I06 WriteSet paths.
- Modify for closure contract: `tests/task-cards/verify-wave1-implementation-cards.sh`
- Modify for closure contract: `scripts/verify-wave1-implementation-cards`
- Modify for the final projection: the same eleven authority/index/card paths used by the I05 closure, with I06 set `DONE`, no `READY` card, and I02 still `QUEUED`.

**Interfaces:**
- Consumes: reviewed I04 repair candidate and reviewed cumulative I06 candidate.
- Produces: `W1I06ClosureStatus = PASS`, `TaskCardSetStatus = BLOCKED_BY_DATABASE_GATE`, `ActiveTaskCard = NONE`.

- [ ] **Step 1: Verify and review the cumulative I06 candidate**

```bash
./mvnw -f server/pom.xml -Dtest='io.cognitura.source.docx.text.*Test,io.cognitura.source.docx.table.*Test,io.cognitura.source.docx.image.*Test' test
./mvnw -f server/pom.xml test
scripts/verify-wave1-implementation
git diff --check
git status --short --branch
```

Freeze Candidate/Parent/Tree and obtain one xhigh review with P0/P1/P2 all zero. Same-scope findings
return to RED/GREEN; new Owner/contract/write-envelope findings stop and require re-intake.

- [ ] **Step 2: Define the closure RED**

Add real-Git fixtures that accept only one direct-child authority projection from I06 `READY` to
I06 `DONE`, I02 `QUEUED`, no READY card, and `BLOCKED_BY_DATABASE_GATE`. Reject releasing I07,
setting I02 READY/PASS, changing product bytes, missing review identities, extra paths, or any
database/push authorization.

- [ ] **Step 3: Implement closure GREEN**

Add `BLOCKED_BY_DATABASE_GATE` as a narrowly defined task-set state requiring:

```text
ActiveTaskCard = NONE
ReadyTaskCardCount = 0
W1-I02 = QUEUED
W1-I06 = DONE
W1-I07 = BLOCKED_BY_DEPENDENCY
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

Bind the repair and I06 review receipts to exact Candidate/Parent/Tree values and preserve all
reviewed product bytes after the receipt.

- [ ] **Step 4: Commit the exact closure projection and verify**

Commit the verifier/test candidate, obtain the applicable single xhigh gate if the final closure
tree differs materially, then commit the exact authority projection. Re-run explicit transition,
static verification, the full server suite, the full Wave 1 gate, Markdown links, Bash syntax,
`git diff --check`, and final status.

Stop with I06 closed and the repository explicitly waiting for the separately authorized I02
database Gate. Do not start I02, I07, migrations, persistence, deployment, or push.
