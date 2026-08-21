# Cognitura W1-I06 Entry Repair Design

```text
CanonicalProjectName = Cognitura
DesignKind = APPEND_ONLY_IMPLEMENTATION_ENTRY_REPAIR
RepairOriginSHA = 5937fe6845f3cd7759dcaa5156bfc9f9060b5407
ActiveTaskCard = W1-I06
AffectedClosedOwner = W1-I04
W1I05ProductionFrozen = YES
W1I06OriginalWriteSetPreserved = YES
BusinessImplementation = USER_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
ExternalRelationshipDereference = FORBIDDEN
```

## 1. Purpose

This design repairs one concrete seam that blocks the approved W1-I06 image projection card.
The formal DocumentBlock contract requires each supported inline or table-cell image to bind to
one real parent `documentBlockId`, while the closed W1-I04 text parser currently rejects
`w:drawing` and `w:pict` and does not reserve image positions in global `sourceOrder`.

The repair is not a new parser framework, lifecycle engine, execution ledger, or Omin Harness
integration. It adds the smallest compatibility behavior required for the existing I04 output to
be consumed by the existing I06 task, then leaves block publication and ID allocation to W1-I07.

## 2. Authority and non-negotiable contract

The following existing authorities remain unchanged:

- `docs/design/wave-1/cognitura-document-block-contract-1.0.md`
- `docs/design/wave-1/cognitura-reparse-reference-contract-1.0.md`
- `docs/task-cards/wave-1-implementation/W1-I06-image-anchor-relationship-projection.md`

This successor clarifies implementation sequencing only:

1. `sourcePart + sourceElementIndex` is an internal candidate join key, never a public block
   identity or stable reference.
2. W1-I07 allocates each revision-local `documentBlockId` before it invokes the I06 projector.
3. I06 resolves the internal join key through a caller-supplied resolver and stores only the real
   returned `parentBlockId` in `ImageAnchor`.
4. Missing, blank, duplicate, or inconsistent parent resolution is terminal. The projector must
   never synthesize a parent ID from a hash, OOXML location, relationship ID, or source order.

## 3. Alternatives considered

### 3.1 Selected: narrow I04 seam repair plus caller-bound I06 projection

The I04 parser preserves one real `U+FFFC` for each supported `w:drawing` or `w:pict`, rejects a
literal `U+FFFC` in source text, and reserves one global source-order slot per image. I06 then
parses the same verified package, resolves parent IDs supplied by its caller, and produces final
image anchors and payload facts.

This keeps text ownership in I04, table ownership in I05, image ownership in I06, and publication
ownership in I07.

### 3.2 Rejected: use OOXML position as `parentBlockId`

The formal contract explicitly prohibits treating `sourcePart + sourceElementIndex` as a stable
public reference. This would create a second identity system and make reparse behavior incorrect.

### 3.3 Rejected: rebuild text and table parsing inside the image package

An all-in-one image parser would duplicate closed I04/I05 behavior, create two sources of ordering
truth, and make later fixes diverge. It is unnecessary for the approved I06 scope.

## 4. Exact repair boundary

The temporary cross-owner production repair is limited to these existing I04 paths:

```text
RepairWriteSet = server/src/main/java/io/cognitura/source/docx/text/TextListSectionParser.java
RepairWriteSet = server/src/main/java/io/cognitura/source/docx/text/SourceOrderCursor.java
RepairWriteSet = server/src/test/java/io/cognitura/source/docx/text/TextListSectionParserTest.java
RepairWriteSet = server/src/test/resources/docx/text/inline-images.xml
```

No other I04 or I05 byte may change. In particular,
`DocumentBlockCandidate`, `TableFidelityParser`, `TableBlockCandidate`, and all reviewed W1-I05
production files remain byte-identical.

The original I06 WriteSet remains exactly the eight entries already declared by its task card:

```text
I06WriteSet = server/src/main/java/io/cognitura/source/docx/image/ImageRelationshipProjector.java
I06WriteSet = server/src/main/java/io/cognitura/source/docx/image/ImageAnchor.java
I06WriteSet = server/src/main/java/io/cognitura/source/docx/image/ImmutableMediaRef.java
I06WriteSet = server/src/main/java/io/cognitura/source/docx/image/MediaDigest.java
I06WriteSet = server/src/main/java/io/cognitura/source/docx/image/ExternalRelationshipLiteral.java
I06WriteSet = server/src/test/java/io/cognitura/source/docx/image/ImageRelationshipProjectorTest.java
I06WriteSet = server/src/test/java/io/cognitura/source/docx/image/ExternalRelationshipNoAccessTest.java
I06WriteSet = server/src/test/resources/docx/image/**
```

Governance admission may modify only this design, its implementation plan, the Wave 1 task-card
verifier, and the verifier contract test. Governance commits do not authorize product files.

## 5. I04 compatibility behavior

`TextListSectionParser` retains its existing heading, paragraph, list, section-path, normalization,
and error behavior. It adds only these rules:

1. A direct supported run child `w:drawing` or `w:pict` appends one `U+FFFC` to the containing
   block text.
2. A literal `U+FFFC` appearing inside `w:t` is rejected with
   `TEXT_LITERAL_IMAGE_PLACEHOLDER_FORBIDDEN`.
3. Placeholder offsets use Unicode code-point positions, not UTF-16 char indexes.
4. After allocating the containing text block's source order, the cursor reserves one consecutive
   child slot per placeholder. The next top-level text block therefore starts after all images of
   the previous container.
5. `SourceOrderCursor` records the exact block orders it issued and the number of reserved child
   slots. Its terminal validation accepts only the exact issued block-order sequence and rejects
   overflow, missing reservation, duplicate allocation, or reordering.

This repair does not inspect relationship XML, read media, create IMAGE payloads, or allocate block
IDs. Those responsibilities remain in I06 and I07.

## 6. I06 runtime interfaces

`ImageRelationshipProjector` consumes only an already-open `SafeDocxPackage`, a parent ID resolver,
and an immutable derived-media sink:

```java
Projection project(
    SafeDocxPackage safePackage,
    ParentBlockIdResolver parentBlockIds,
    ImmutableMediaSink mediaSink)
```

The two nested functional ports have these responsibilities:

```java
String ParentBlockIdResolver.resolve(
    String sourcePart,
    int parentSourceElementIndex,
    ImageAnchor.Kind kind,
    Integer rowIndex,
    Integer columnIndex)

ImmutableMediaRef ImmutableMediaSink.store(
    String sourcePart,
    String relationshipId,
    String mediaType,
    byte[] verifiedBytes,
    MediaDigest digest)
```

The resolver receives an internal join key and returns a real revision-local block ID. The sink
copies verified internal media bytes to its read-only derived-media implementation and returns an
opaque immutable reference. I06 has no filesystem, object-storage, database, HTTP, or Web adapter.

`Projection` contains immutable ordered lists of projected images and external relationship
diagnostics. Each projected image contains:

```text
relationshipId
relationshipMode
ImageAnchor
externalTargetLiteralSha256
ImmutableMediaRef
mediaType
byteLength
contentSha256
securityDisclosure
payloadContentHash
```

## 7. Anchor and traversal rules

I06 supports only the existing closed flow set:

- top-level paragraph inline images;
- table row/cell paragraph inline images;
- DrawingML `a:blip` using `r:embed` or `r:link`;
- legacy VML `v:imagedata` using `r:id`.

For a paragraph image, `ImageAnchor` stores kind `PARAGRAPH_INLINE`, the resolver-provided parent
ID, Unicode code-point `textOffset`, and zero-based `childOrdinal`; row and column are null.

For a table-cell image, it stores kind `TABLE_CELL_INLINE`, the table parent ID, visual grid row and
column, cell-wide Unicode code-point `textOffset`, and zero-based child ordinal within that cell.
Merged-cell coordinates follow the existing W1-I05 table projection. Unsupported nested tables or
ambiguous cell ownership remain terminal rather than guessed.

Every placeholder and projected image must form a bijection. Missing or duplicate relationship IDs,
multiple IDs on one image node, unsupported target mode, unresolved parent ID, missing verified
media, duplicate image binding, or anchor count mismatch returns
`SourceDomainException.Code.PARSER_TERMINAL_FAILURE`.

## 8. Internal media rules

For an internal image relationship:

1. Read bytes only through `SafeDocxPackage.readRelationshipTarget`.
2. Resolve media type from the verified `[Content_Types].xml` default or override entry; absence or
   ambiguity is terminal.
3. Compute SHA-256 and byte length before calling the media sink.
4. Pass a defensive byte copy to the sink.
5. Require a nonblank opaque `ImmutableMediaRef` and preserve the computed digest unchanged.
6. Set external digest and security disclosure to null.

The projector never treats an internal package part name, local path, bucket/key, or URL as the
immutable media reference.

## 9. External relationship rules

For an external relationship:

- consume only the `DocxRelationshipClassifier.RelationshipMetadata` already held in memory;
- preserve relationship ID, type, mode, literal-target SHA-256, and
  `EXTERNAL_RELATIONSHIP_NOT_DEREFERENCED`;
- keep media ref, media type, byte length, and media content hash null;
- propagate the identical literal digest into the image payload and
  `ExternalRelationshipLiteral` diagnostic;
- include that digest in deterministic `payloadContentHash` canonical bytes;
- never call `readRelationshipTarget` for an external relationship.

The I06 no-access test calibrates file-read, stat, DNS, and network canaries, runs the real projector,
and requires operation attempts to remain exactly zero. A target literal change with unchanged
relationship ID must change both the diagnostic digest and payload content hash.

## 10. TDD and acceptance

The repair and I06 implementation use separate RED -> GREEN loops.

### 10.1 I04 seam repair

RED proves the current parser rejects a real inline image. GREEN must prove:

- paragraph/list/heading placeholders are preserved;
- astral Unicode before an image yields the correct code-point offset;
- multiple images reserve consecutive global source-order positions;
- a following text block starts after those positions;
- literal `U+FFFC`, malformed image placement, and source-order overflow fail terminally;
- all existing I04 and I05 tests remain green.

### 10.2 I06 projection

RED names the absent `ImageRelationshipProjector` behavior. GREEN must prove:

- internal paragraph and table-cell images bind to caller-supplied parent IDs;
- multiple images preserve source order, offset, ordinal, row, and column;
- media type, byte length, digest, opaque ref, and payload hash are immutable;
- external literal digest is identical in payload and diagnostics;
- missing/duplicate relationships, missing media, digest drift, resolver failure, placeholder
  mismatch, and target access attempts fail closed;
- calibrated file/stat/DNS/network canaries observe zero projector operations.

Required final commands are:

```bash
./mvnw -f server/pom.xml -Dtest='io.cognitura.source.docx.text.*Test,io.cognitura.source.docx.table.*Test,io.cognitura.source.docx.image.*Test' test
./mvnw -f server/pom.xml test
scripts/verify-wave1-implementation
git diff --check
git status --short --branch
```

## 11. Governance and closure

This is R2 because it repairs a closed Owner and changes task-card admission semantics. The
implementation plan must define an exact append-only commit chain from `RepairOriginSHA`, bind every
governance and repair commit by Candidate/Parent/Tree, and reject equivalent-content substitute,
merge, empty, reordered, extra-path, and post-candidate mutation histories.

The original W1-I04 and W1-I05 review receipts remain immutable historical facts. The new repair
receipt records that only the declared I04 seam bytes changed. W1-I06 stays the sole READY card and
may form its product candidate only after the repair candidate receives one
`deep_reviewer / gpt-5.6-sol / xhigh / ONE` zero-finding GO. Ultra remains `NOT_RUN` unless a new
explicit escalation reason appears.

W1-I06 itself still requires its own fixed-candidate zero-finding review before any successor is
released. I02 remains queued behind its independent database Gate; formal database writes, remote
push, deployment, `raw/**`, and `.idea/**` remain outside authority.
