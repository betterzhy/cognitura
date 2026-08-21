package io.cognitura.source.reference;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

class ReparseLineageTest {

    private static final String SOURCE = "source-document-a";
    private static final String FROM_REVISION = "revision-1";
    private static final String TO_REVISION = "revision-2";
    private static final Instant CREATED_AT = Instant.parse("2026-08-22T00:00:00Z");
    private static final ReparseLineage.ConfidenceBasis BASIS =
            new ReparseLineage.ConfidenceBasis(
                    "canonical-block-v1", "source-anchor-v1", "concat-v1", "ambiguity-v1");

    @Test
    void preservesAllFormalStatesWithExactCoverageAndNoAmbiguousAutoResolution() {
        List<StableSourceReference> from = refs(FROM_REVISION, "f", 8);
        List<StableSourceReference> to = refs(TO_REVISION, "t", 8);
        List<ReparseLineage.Entry> entries = List.of(
                entry(ReparseLineage.State.UNCHANGED, List.of(from.get(0)), List.of(to.get(0))),
                entry(ReparseLineage.State.MOVED, List.of(from.get(1)), List.of(to.get(1))),
                entry(ReparseLineage.State.MODIFIED, List.of(from.get(2)), List.of(to.get(2))),
                entry(
                        ReparseLineage.State.SPLIT,
                        List.of(from.get(3)),
                        List.of(to.get(3), to.get(4))),
                entry(
                        ReparseLineage.State.MERGED,
                        List.of(from.get(4), from.get(5)),
                        List.of(to.get(5))),
                entry(ReparseLineage.State.REMOVED, List.of(from.get(6)), List.of()),
                entry(ReparseLineage.State.ADDED, List.of(), List.of(to.get(6))),
                entry(ReparseLineage.State.AMBIGUOUS, List.of(from.get(7)), List.of(to.get(7))));

        ReparseLineage lineage = ReparseLineage.create(
                SOURCE,
                FROM_REVISION,
                TO_REVISION,
                entries,
                CREATED_AT,
                "lineage-v1",
                from,
                to);

        assertThat(lineage.entries()).hasSize(8);
        assertThat(lineage.resolvedTargets(from.get(0))).containsExactly(to.get(0));
        assertThat(lineage.resolvedTargets(from.get(6))).isEmpty();
        assertCode(
                () -> lineage.resolvedTargets(from.get(7)),
                ReferenceResolutionException.Code.LINEAGE_AMBIGUOUS);
        assertThat(lineage.hasAmbiguity()).isTrue();
    }

    @Test
    void rejectsInvalidStateCardinality() {
        StableSourceReference from = ref(FROM_REVISION, "from");
        StableSourceReference to = ref(TO_REVISION, "to");

        assertCode(
                () -> create(
                        List.of(from),
                        List.of(to),
                        List.of(entry(
                                ReparseLineage.State.SPLIT, List.of(from), List.of(to)))),
                ReferenceResolutionException.Code.LINEAGE_CARDINALITY_INVALID);
        assertCode(
                () -> create(
                        List.of(from),
                        List.of(to),
                        List.of(entry(
                                ReparseLineage.State.ADDED, List.of(from), List.of(to)))),
                ReferenceResolutionException.Code.LINEAGE_CARDINALITY_INVALID);
        assertCode(
                () -> create(
                        List.of(from),
                        List.of(to),
                        List.of(entry(
                                ReparseLineage.State.REMOVED, List.of(from), List.of(to)))),
                ReferenceResolutionException.Code.LINEAGE_CARDINALITY_INVALID);
    }

    @Test
    void rejectsMissingDuplicateAndOverlappingCoverage() {
        StableSourceReference fromA = ref(FROM_REVISION, "from-a");
        StableSourceReference fromB = ref(FROM_REVISION, "from-b");
        StableSourceReference toA = ref(TO_REVISION, "to-a");
        StableSourceReference toB = ref(TO_REVISION, "to-b");

        assertCode(
                () -> create(
                        List.of(fromA, fromB),
                        List.of(toA),
                        List.of(entry(
                                ReparseLineage.State.UNCHANGED,
                                List.of(fromA),
                                List.of(toA)))),
                ReferenceResolutionException.Code.LINEAGE_COVERAGE_INVALID);
        assertCode(
                () -> create(
                        List.of(fromA),
                        List.of(toA, toB),
                        List.of(
                                entry(
                                        ReparseLineage.State.UNCHANGED,
                                        List.of(fromA),
                                        List.of(toA)),
                                entry(
                                        ReparseLineage.State.AMBIGUOUS,
                                        List.of(fromA),
                                        List.of(toB)))),
                ReferenceResolutionException.Code.LINEAGE_COVERAGE_INVALID);
        assertCode(
                () -> create(
                        List.of(fromA, fromA),
                        List.of(toA),
                        List.of(entry(
                                ReparseLineage.State.UNCHANGED,
                                List.of(fromA),
                                List.of(toA)))),
                ReferenceResolutionException.Code.LINEAGE_COVERAGE_INVALID);
    }

    @Test
    void rejectsCrossSourceWrongRevisionAndReverseDirectionReferences() {
        StableSourceReference validFrom = ref(FROM_REVISION, "from");
        StableSourceReference validTo = ref(TO_REVISION, "to");
        StableSourceReference foreignSource =
                new StableSourceReference("source-document-b", FROM_REVISION, "foreign");
        StableSourceReference reversedFrom = ref(TO_REVISION, "reversed");

        assertCode(
                () -> create(
                        List.of(foreignSource),
                        List.of(validTo),
                        List.of(entry(
                                ReparseLineage.State.UNCHANGED,
                                List.of(foreignSource),
                                List.of(validTo)))),
                ReferenceResolutionException.Code.LINEAGE_REVISION_SCOPE_MISMATCH);
        assertCode(
                () -> create(
                        List.of(reversedFrom),
                        List.of(validTo),
                        List.of(entry(
                                ReparseLineage.State.UNCHANGED,
                                List.of(reversedFrom),
                                List.of(validTo)))),
                ReferenceResolutionException.Code.LINEAGE_REVISION_SCOPE_MISMATCH);
        assertCode(
                () -> ReparseLineage.create(
                        SOURCE,
                        FROM_REVISION,
                        FROM_REVISION,
                        List.of(entry(
                                ReparseLineage.State.UNCHANGED,
                                List.of(validFrom),
                                List.of(validTo))),
                        CREATED_AT,
                        "lineage-v1",
                        List.of(validFrom),
                        List.of(validTo)),
                ReferenceResolutionException.Code.LINEAGE_REVISION_SCOPE_MISMATCH);
    }

    @Test
    void snapshotsInputsAndRejectsSameIdentityWithDifferentContent() {
        StableSourceReference from = ref(FROM_REVISION, "from");
        StableSourceReference to = ref(TO_REVISION, "to");
        ArrayList<ReparseLineage.Entry> mutableEntries = new ArrayList<>();
        mutableEntries.add(entry(
                ReparseLineage.State.UNCHANGED, List.of(from), List.of(to)));
        ReparseLineage original = ReparseLineage.create(
                SOURCE,
                FROM_REVISION,
                TO_REVISION,
                mutableEntries,
                CREATED_AT,
                "lineage-v1",
                List.of(from),
                List.of(to));
        mutableEntries.clear();

        assertThat(original.entries()).hasSize(1);
        assertThatThrownBy(() -> original.entries().add(entry(
                        ReparseLineage.State.UNCHANGED, List.of(from), List.of(to))))
                .isInstanceOf(UnsupportedOperationException.class);
        assertThat(ReparseLineage.register(List.of(original), original)).isSameAs(original);

        ReparseLineage drifted = ReparseLineage.create(
                SOURCE,
                FROM_REVISION,
                TO_REVISION,
                List.of(entry(ReparseLineage.State.MOVED, List.of(from), List.of(to))),
                CREATED_AT,
                "lineage-v1",
                List.of(from),
                List.of(to));
        assertCode(
                () -> ReparseLineage.register(List.of(original), drifted),
                ReferenceResolutionException.Code.LINEAGE_COVERAGE_INVALID);

        ReparseLineage newAlgorithm = ReparseLineage.create(
                SOURCE,
                FROM_REVISION,
                TO_REVISION,
                List.of(entry(ReparseLineage.State.MOVED, List.of(from), List.of(to))),
                CREATED_AT,
                "lineage-v2",
                List.of(from),
                List.of(to));
        assertThat(ReparseLineage.register(List.of(original), newAlgorithm))
                .isEqualTo(newAlgorithm);
    }

    private static ReparseLineage create(
            List<StableSourceReference> from,
            List<StableSourceReference> to,
            List<ReparseLineage.Entry> entries) {
        return ReparseLineage.create(
                SOURCE,
                FROM_REVISION,
                TO_REVISION,
                entries,
                CREATED_AT,
                "lineage-v1",
                from,
                to);
    }

    private static ReparseLineage.Entry entry(
            ReparseLineage.State state,
            List<StableSourceReference> from,
            List<StableSourceReference> to) {
        return new ReparseLineage.Entry(from, to, state, BASIS);
    }

    private static List<StableSourceReference> refs(String revisionId, String prefix, int count) {
        ArrayList<StableSourceReference> refs = new ArrayList<>();
        for (int index = 1; index <= count; index++) {
            refs.add(ref(revisionId, prefix + index));
        }
        return List.copyOf(refs);
    }

    private static StableSourceReference ref(String revisionId, String blockId) {
        return new StableSourceReference(SOURCE, revisionId, blockId);
    }

    private static void assertCode(
            org.assertj.core.api.ThrowableAssert.ThrowingCallable call,
            ReferenceResolutionException.Code code) {
        assertThatThrownBy(call)
                .isInstanceOfSatisfying(
                        ReferenceResolutionException.class,
                        error -> assertThat(error.code()).isEqualTo(code));
    }
}
