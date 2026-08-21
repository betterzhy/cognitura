package io.cognitura.source.reference;

import java.time.Instant;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;

public final class ReparseLineage {

    public enum State {
        UNCHANGED,
        MOVED,
        MODIFIED,
        SPLIT,
        MERGED,
        REMOVED,
        ADDED,
        AMBIGUOUS
    }

    public record ConfidenceBasis(
            String hashCanonicalization,
            String anchorComparison,
            String concatenationRule,
            String ambiguityRule) {
        public ConfidenceBasis {
            hashCanonicalization = StableSourceReference.requireText(
                    hashCanonicalization, "LINEAGE_HASH_RULE_REQUIRED");
            anchorComparison = StableSourceReference.requireText(
                    anchorComparison, "LINEAGE_ANCHOR_RULE_REQUIRED");
            concatenationRule = StableSourceReference.requireText(
                    concatenationRule, "LINEAGE_CONCATENATION_RULE_REQUIRED");
            ambiguityRule = StableSourceReference.requireText(
                    ambiguityRule, "LINEAGE_AMBIGUITY_RULE_REQUIRED");
        }
    }

    public record Entry(
            List<StableSourceReference> fromBlockRefs,
            List<StableSourceReference> toBlockRefs,
            State lineageState,
            ConfidenceBasis confidenceBasis) {
        public Entry {
            fromBlockRefs = List.copyOf(Objects.requireNonNull(fromBlockRefs, "fromBlockRefs"));
            toBlockRefs = List.copyOf(Objects.requireNonNull(toBlockRefs, "toBlockRefs"));
            Objects.requireNonNull(lineageState, "lineageState");
            Objects.requireNonNull(confidenceBasis, "confidenceBasis");
            fromBlockRefs.forEach(ref -> Objects.requireNonNull(ref, "fromBlockRef"));
            toBlockRefs.forEach(ref -> Objects.requireNonNull(ref, "toBlockRef"));
        }
    }

    private final String sourceDocumentId;
    private final String fromProcessingRevisionId;
    private final String toProcessingRevisionId;
    private final List<Entry> entries;
    private final Instant createdAt;
    private final String algorithmVersion;

    private ReparseLineage(
            String sourceDocumentId,
            String fromProcessingRevisionId,
            String toProcessingRevisionId,
            List<Entry> entries,
            Instant createdAt,
            String algorithmVersion) {
        this.sourceDocumentId = sourceDocumentId;
        this.fromProcessingRevisionId = fromProcessingRevisionId;
        this.toProcessingRevisionId = toProcessingRevisionId;
        this.entries = List.copyOf(entries);
        this.createdAt = createdAt;
        this.algorithmVersion = algorithmVersion;
    }

    public static ReparseLineage create(
            String sourceDocumentId,
            String fromProcessingRevisionId,
            String toProcessingRevisionId,
            List<Entry> entries,
            Instant createdAt,
            String algorithmVersion,
            List<StableSourceReference> expectedFromBlocks,
            List<StableSourceReference> expectedToBlocks) {
        String source = StableSourceReference.requireIdentifier(
                sourceDocumentId, "SOURCE_DOCUMENT_ID");
        String fromRevision = StableSourceReference.requireIdentifier(
                fromProcessingRevisionId, "FROM_PROCESSING_REVISION_ID");
        String toRevision = StableSourceReference.requireIdentifier(
                toProcessingRevisionId, "TO_PROCESSING_REVISION_ID");
        String context = lineageContext(source, fromRevision, toRevision);
        if (fromRevision.equals(toRevision)) {
            throw scope(context);
        }
        List<Entry> immutableEntries = List.copyOf(Objects.requireNonNull(entries, "entries"));
        List<StableSourceReference> expectedFrom = List.copyOf(
                Objects.requireNonNull(expectedFromBlocks, "expectedFromBlocks"));
        List<StableSourceReference> expectedTo = List.copyOf(
                Objects.requireNonNull(expectedToBlocks, "expectedToBlocks"));
        validateExpectedScope(source, fromRevision, expectedFrom, "from", context);
        validateExpectedScope(source, toRevision, expectedTo, "to", context);
        validateCoverage(
                source,
                fromRevision,
                toRevision,
                immutableEntries,
                expectedFrom,
                expectedTo,
                context);
        return new ReparseLineage(
                source,
                fromRevision,
                toRevision,
                immutableEntries,
                Objects.requireNonNull(createdAt, "createdAt"),
                StableSourceReference.requireIdentifier(
                        algorithmVersion, "LINEAGE_ALGORITHM_VERSION"));
    }

    public static ReparseLineage register(
            List<ReparseLineage> existing, ReparseLineage candidate) {
        Objects.requireNonNull(existing, "existing");
        Objects.requireNonNull(candidate, "candidate");
        for (ReparseLineage lineage : existing) {
            Objects.requireNonNull(lineage, "lineage");
            if (!lineage.sameIdentity(candidate)) {
                continue;
            }
            if (!lineage.equals(candidate)) {
                throw coverage(candidate.context());
            }
            return lineage;
        }
        return candidate;
    }

    public String sourceDocumentId() {
        return sourceDocumentId;
    }

    public String fromProcessingRevisionId() {
        return fromProcessingRevisionId;
    }

    public String toProcessingRevisionId() {
        return toProcessingRevisionId;
    }

    public List<Entry> entries() {
        return entries;
    }

    public Instant createdAt() {
        return createdAt;
    }

    public String algorithmVersion() {
        return algorithmVersion;
    }

    public boolean hasAmbiguity() {
        return entries.stream().anyMatch(entry -> entry.lineageState() == State.AMBIGUOUS);
    }

    public List<StableSourceReference> resolvedTargets(StableSourceReference fromBlockRef) {
        Objects.requireNonNull(fromBlockRef, "fromBlockRef");
        String context = tupleContext(
                lineageContext(
                        sourceDocumentId,
                        fromProcessingRevisionId,
                        toProcessingRevisionId),
                "requested",
                fromBlockRef);
        if (!sourceDocumentId.equals(fromBlockRef.sourceDocumentId())
                || !fromProcessingRevisionId.equals(
                        fromBlockRef.sourceProcessingRevisionId())) {
            throw scope(context);
        }
        Entry match = entries.stream()
                .filter(entry -> entry.fromBlockRefs().contains(fromBlockRef))
                .findFirst()
                .orElseThrow(() -> ReferenceResolutionException.of(
                        ReferenceResolutionException.Code.REFERENCE_NOT_FOUND,
                        context));
        if (match.lineageState() == State.AMBIGUOUS) {
            throw ReferenceResolutionException.of(
                    ReferenceResolutionException.Code.LINEAGE_AMBIGUOUS,
                    context);
        }
        return match.toBlockRefs();
    }

    private static void validateExpectedScope(
            String sourceDocumentId,
            String revisionId,
            List<StableSourceReference> refs,
            String side,
            String context) {
        HashSet<StableSourceReference> unique = new HashSet<>();
        for (StableSourceReference ref : refs) {
            Objects.requireNonNull(ref, side + "BlockRef");
            if (!sourceDocumentId.equals(ref.sourceDocumentId())
                    || !revisionId.equals(ref.sourceProcessingRevisionId())) {
                throw scope(tupleContext(context, side, ref));
            }
            if (!unique.add(ref)) {
                throw coverage(tupleContext(context, side, ref));
            }
        }
    }

    private static void validateCoverage(
            String sourceDocumentId,
            String fromRevisionId,
            String toRevisionId,
            List<Entry> entries,
            List<StableSourceReference> expectedFrom,
            List<StableSourceReference> expectedTo,
            String context) {
        Map<StableSourceReference, Integer> fromCounts = new HashMap<>();
        Map<StableSourceReference, Integer> toCounts = new HashMap<>();
        for (Entry entry : entries) {
            Objects.requireNonNull(entry, "entry");
            validateCardinality(entry, context);
            for (StableSourceReference ref : entry.fromBlockRefs()) {
                if (!sourceDocumentId.equals(ref.sourceDocumentId())
                        || !fromRevisionId.equals(ref.sourceProcessingRevisionId())) {
                    throw scope(tupleContext(context, "from", ref));
                }
                fromCounts.merge(ref, 1, Integer::sum);
            }
            for (StableSourceReference ref : entry.toBlockRefs()) {
                if (!sourceDocumentId.equals(ref.sourceDocumentId())
                        || !toRevisionId.equals(ref.sourceProcessingRevisionId())) {
                    throw scope(tupleContext(context, "to", ref));
                }
                toCounts.merge(ref, 1, Integer::sum);
            }
        }
        requireExactCoverage(expectedFrom, fromCounts, "from", context);
        requireExactCoverage(expectedTo, toCounts, "to", context);
    }

    private static void validateCardinality(Entry entry, String context) {
        int from = entry.fromBlockRefs().size();
        int to = entry.toBlockRefs().size();
        boolean valid = switch (entry.lineageState()) {
            case UNCHANGED, MOVED, MODIFIED -> from == 1 && to == 1;
            case SPLIT -> from == 1 && to >= 2;
            case MERGED -> from >= 2 && to == 1;
            case REMOVED -> from >= 1 && to == 0;
            case ADDED -> from == 0 && to >= 1;
            case AMBIGUOUS -> from >= 1 && to >= 1;
        };
        if (!valid) {
            throw ReferenceResolutionException.of(
                    ReferenceResolutionException.Code.LINEAGE_CARDINALITY_INVALID,
                    entryContext(context, entry));
        }
    }

    private static void requireExactCoverage(
            List<StableSourceReference> expected,
            Map<StableSourceReference, Integer> actual,
            String side,
            String context) {
        if (actual.size() != expected.size()) {
            throw coverage(coverageContext(context, side, expected, actual));
        }
        for (StableSourceReference ref : expected) {
            if (actual.getOrDefault(ref, 0) != 1) {
                throw coverage(coverageContext(context, side, expected, actual));
            }
        }
    }

    private boolean sameIdentity(ReparseLineage other) {
        return sourceDocumentId.equals(other.sourceDocumentId)
                && fromProcessingRevisionId.equals(other.fromProcessingRevisionId)
                && toProcessingRevisionId.equals(other.toProcessingRevisionId)
                && algorithmVersion.equals(other.algorithmVersion);
    }

    private String context() {
        return lineageContext(
                sourceDocumentId, fromProcessingRevisionId, toProcessingRevisionId)
                + ",algorithmVersion=" + algorithmVersion;
    }

    private static String lineageContext(
            String sourceDocumentId, String fromRevisionId, String toRevisionId) {
        return "lineage[sourceDocumentId=" + sourceDocumentId
                + ",fromRevisionId=" + fromRevisionId
                + ",toRevisionId=" + toRevisionId + "]";
    }

    private static String tupleContext(
            String context, String side, StableSourceReference reference) {
        return context + "," + side + "Tuple[sourceDocumentId="
                + reference.sourceDocumentId()
                + ",revisionId=" + reference.sourceProcessingRevisionId()
                + ",blockId=" + reference.documentBlockId() + "]";
    }

    private static String entryContext(String context, Entry entry) {
        return context + ",state=" + entry.lineageState()
                + ",fromBlockIds=" + blockIds(entry.fromBlockRefs())
                + ",toBlockIds=" + blockIds(entry.toBlockRefs());
    }

    private static String coverageContext(
            String context,
            String side,
            List<StableSourceReference> expected,
            Map<StableSourceReference, Integer> actual) {
        return context + ",side=" + side
                + ",expectedBlockIds=" + blockIds(expected)
                + ",actualBlockIds=" + blockIds(List.copyOf(actual.keySet()));
    }

    private static List<String> blockIds(List<StableSourceReference> references) {
        return references.stream()
                .map(StableSourceReference::documentBlockId)
                .sorted()
                .toList();
    }

    @Override
    public boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (!(other instanceof ReparseLineage lineage)) {
            return false;
        }
        return sourceDocumentId.equals(lineage.sourceDocumentId)
                && fromProcessingRevisionId.equals(lineage.fromProcessingRevisionId)
                && toProcessingRevisionId.equals(lineage.toProcessingRevisionId)
                && entries.equals(lineage.entries)
                && createdAt.equals(lineage.createdAt)
                && algorithmVersion.equals(lineage.algorithmVersion);
    }

    @Override
    public int hashCode() {
        return Objects.hash(
                sourceDocumentId,
                fromProcessingRevisionId,
                toProcessingRevisionId,
                entries,
                createdAt,
                algorithmVersion);
    }

    private static ReferenceResolutionException scope(String detail) {
        return ReferenceResolutionException.of(
                ReferenceResolutionException.Code.LINEAGE_REVISION_SCOPE_MISMATCH,
                detail);
    }

    private static ReferenceResolutionException coverage(String detail) {
        return ReferenceResolutionException.of(
                ReferenceResolutionException.Code.LINEAGE_COVERAGE_INVALID,
                detail);
    }
}
