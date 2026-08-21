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
        String source = StableSourceReference.requireText(
                sourceDocumentId, "SOURCE_DOCUMENT_ID_REQUIRED");
        String fromRevision = StableSourceReference.requireText(
                fromProcessingRevisionId, "FROM_PROCESSING_REVISION_ID_REQUIRED");
        String toRevision = StableSourceReference.requireText(
                toProcessingRevisionId, "TO_PROCESSING_REVISION_ID_REQUIRED");
        if (fromRevision.equals(toRevision)) {
            throw scope("lineage revisions must be directional and distinct");
        }
        List<Entry> immutableEntries = List.copyOf(Objects.requireNonNull(entries, "entries"));
        List<StableSourceReference> expectedFrom = List.copyOf(
                Objects.requireNonNull(expectedFromBlocks, "expectedFromBlocks"));
        List<StableSourceReference> expectedTo = List.copyOf(
                Objects.requireNonNull(expectedToBlocks, "expectedToBlocks"));
        validateExpectedScope(source, fromRevision, expectedFrom, "from");
        validateExpectedScope(source, toRevision, expectedTo, "to");
        validateCoverage(source, fromRevision, toRevision, immutableEntries, expectedFrom, expectedTo);
        return new ReparseLineage(
                source,
                fromRevision,
                toRevision,
                immutableEntries,
                Objects.requireNonNull(createdAt, "createdAt"),
                StableSourceReference.requireText(algorithmVersion, "LINEAGE_ALGORITHM_VERSION_REQUIRED"));
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
                throw coverage("same lineage identity has different content");
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
        Entry match = entries.stream()
                .filter(entry -> entry.fromBlockRefs().contains(fromBlockRef))
                .findFirst()
                .orElseThrow(() -> new ReferenceResolutionException(
                        ReferenceResolutionException.Code.REFERENCE_NOT_FOUND,
                        "lineage source block"));
        if (match.lineageState() == State.AMBIGUOUS) {
            throw new ReferenceResolutionException(
                    ReferenceResolutionException.Code.LINEAGE_AMBIGUOUS,
                    "lineage source block remains unresolved");
        }
        return match.toBlockRefs();
    }

    private static void validateExpectedScope(
            String sourceDocumentId,
            String revisionId,
            List<StableSourceReference> refs,
            String side) {
        HashSet<StableSourceReference> unique = new HashSet<>();
        for (StableSourceReference ref : refs) {
            Objects.requireNonNull(ref, side + "BlockRef");
            if (!sourceDocumentId.equals(ref.sourceDocumentId())
                    || !revisionId.equals(ref.sourceProcessingRevisionId())) {
                throw scope(side + " revision scope");
            }
            if (!unique.add(ref)) {
                throw coverage(side + " expected block duplicated");
            }
        }
    }

    private static void validateCoverage(
            String sourceDocumentId,
            String fromRevisionId,
            String toRevisionId,
            List<Entry> entries,
            List<StableSourceReference> expectedFrom,
            List<StableSourceReference> expectedTo) {
        Map<StableSourceReference, Integer> fromCounts = new HashMap<>();
        Map<StableSourceReference, Integer> toCounts = new HashMap<>();
        for (Entry entry : entries) {
            Objects.requireNonNull(entry, "entry");
            validateCardinality(entry);
            for (StableSourceReference ref : entry.fromBlockRefs()) {
                if (!sourceDocumentId.equals(ref.sourceDocumentId())
                        || !fromRevisionId.equals(ref.sourceProcessingRevisionId())) {
                    throw scope("from entry revision scope");
                }
                fromCounts.merge(ref, 1, Integer::sum);
            }
            for (StableSourceReference ref : entry.toBlockRefs()) {
                if (!sourceDocumentId.equals(ref.sourceDocumentId())
                        || !toRevisionId.equals(ref.sourceProcessingRevisionId())) {
                    throw scope("to entry revision scope");
                }
                toCounts.merge(ref, 1, Integer::sum);
            }
        }
        requireExactCoverage(expectedFrom, fromCounts, "from");
        requireExactCoverage(expectedTo, toCounts, "to");
    }

    private static void validateCardinality(Entry entry) {
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
            throw new ReferenceResolutionException(
                    ReferenceResolutionException.Code.LINEAGE_CARDINALITY_INVALID,
                    "lineage state cardinality");
        }
    }

    private static void requireExactCoverage(
            List<StableSourceReference> expected,
            Map<StableSourceReference, Integer> actual,
            String side) {
        if (actual.size() != expected.size()) {
            throw coverage(side + " block coverage size");
        }
        for (StableSourceReference ref : expected) {
            if (actual.getOrDefault(ref, 0) != 1) {
                throw coverage(side + " block coverage count");
            }
        }
    }

    private boolean sameIdentity(ReparseLineage other) {
        return sourceDocumentId.equals(other.sourceDocumentId)
                && fromProcessingRevisionId.equals(other.fromProcessingRevisionId)
                && toProcessingRevisionId.equals(other.toProcessingRevisionId)
                && algorithmVersion.equals(other.algorithmVersion);
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
        return new ReferenceResolutionException(
                ReferenceResolutionException.Code.LINEAGE_REVISION_SCOPE_MISMATCH,
                detail);
    }

    private static ReferenceResolutionException coverage(String detail) {
        return new ReferenceResolutionException(
                ReferenceResolutionException.Code.LINEAGE_COVERAGE_INVALID,
                detail);
    }
}
