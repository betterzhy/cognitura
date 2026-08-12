package io.cognitura.source.docx.security;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

public final class SafeDocxPackage implements AutoCloseable {

    private final Set<String> partNames;
    private final List<DocxRelationshipClassifier.RelationshipMetadata> relationships;
    private Map<String, byte[]> verifiedEntryContents;
    private boolean closed;

    SafeDocxPackage(
            Set<String> partNames,
            List<DocxRelationshipClassifier.RelationshipMetadata> relationships,
            Map<String, byte[]> verifiedEntryContents) {
        this.partNames = Set.copyOf(partNames);
        this.relationships = List.copyOf(relationships);
        this.verifiedEntryContents = Objects.requireNonNull(
                verifiedEntryContents, "verifiedEntryContents");
        if (!this.partNames.containsAll(this.verifiedEntryContents.keySet())) {
            throw new IllegalArgumentException("VERIFIED_ENTRY_CONTENT_OUTSIDE_PART_NAMES");
        }
    }

    public Set<String> partNames() {
        requireOpen();
        return partNames;
    }

    public List<DocxRelationshipClassifier.RelationshipMetadata> relationships() {
        requireOpen();
        return relationships;
    }

    public byte[] readVerifiedEntry(String partName) {
        requireOpen();
        if (!partNames.contains(partName)) {
            throw new IllegalArgumentException("DOCX_PART_IS_NOT_VERIFIED");
        }
        byte[] content = verifiedEntryContents.get(partName);
        if (content == null) {
            throw new IllegalArgumentException("DOCX_VERIFIED_FILE_PART_REQUIRED");
        }
        return content.clone();
    }

    public byte[] readRelationshipTarget(
            DocxRelationshipClassifier.RelationshipMetadata relationship) {
        requireOpen();
        Objects.requireNonNull(relationship, "relationship");
        if (!relationships.contains(relationship)) {
            throw new IllegalArgumentException("RELATIONSHIP_IS_NOT_FROM_THIS_PACKAGE");
        }
        if (relationship.mode() == DocxRelationshipClassifier.Mode.EXTERNAL) {
            throw new DocxSecurityViolation(
                    DocxSecurityViolation.Rule.EXTERNAL_RELATIONSHIP_DEREFERENCE_REQUEST,
                    "external relationship targets must never be dereferenced");
        }
        return readVerifiedEntry(relationship.internalTargetPart().orElseThrow());
    }

    @Override
    public void close() {
        if (closed) {
            return;
        }
        closed = true;
        verifiedEntryContents = Map.of();
    }

    private void requireOpen() {
        if (closed) {
            throw new IllegalStateException("SAFE_DOCX_PACKAGE_CLOSED");
        }
    }
}
