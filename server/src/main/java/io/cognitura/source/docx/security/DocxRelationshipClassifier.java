package io.cognitura.source.docx.security;

import io.cognitura.source.domain.SourceDomainException;
import io.cognitura.source.domain.SourceHash;
import java.nio.charset.StandardCharsets;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;

public final class DocxRelationshipClassifier {

    private static final String RELATIONSHIP_NAMESPACE =
            "http://schemas.openxmlformats.org/package/2006/relationships";

    public enum Mode {
        INTERNAL,
        EXTERNAL
    }

    public record RelationshipMetadata(
            String sourcePart,
            String relationshipId,
            String relationshipType,
            Mode mode,
            Optional<String> internalTargetPart,
            Optional<SourceHash> externalTargetLiteralSha256,
            Optional<String> securityDisclosure) {

        public RelationshipMetadata {
            Objects.requireNonNull(sourcePart, "sourcePart");
            requireText(relationshipId, "RELATIONSHIP_ID_REQUIRED");
            requireText(relationshipType, "RELATIONSHIP_TYPE_REQUIRED");
            Objects.requireNonNull(mode, "mode");
            Objects.requireNonNull(internalTargetPart, "internalTargetPart");
            Objects.requireNonNull(externalTargetLiteralSha256, "externalTargetLiteralSha256");
            Objects.requireNonNull(securityDisclosure, "securityDisclosure");
            if (mode == Mode.INTERNAL
                    && (internalTargetPart.isEmpty()
                            || externalTargetLiteralSha256.isPresent()
                            || securityDisclosure.isPresent())) {
                throw new IllegalArgumentException("INTERNAL_RELATIONSHIP_METADATA_INVALID");
            }
            if (mode == Mode.EXTERNAL
                    && (internalTargetPart.isPresent()
                            || externalTargetLiteralSha256.isEmpty()
                            || securityDisclosure.isEmpty())) {
                throw new IllegalArgumentException("EXTERNAL_RELATIONSHIP_METADATA_INVALID");
            }
        }
    }

    public List<RelationshipMetadata> classify(
            String relationshipPart, Document document, Set<String> verifiedParts) {
        Objects.requireNonNull(relationshipPart, "relationshipPart");
        Objects.requireNonNull(document, "document");
        Objects.requireNonNull(verifiedParts, "verifiedParts");
        String sourcePart = sourcePartFor(relationshipPart);
        Element root = document.getDocumentElement();
        if (root == null
                || !"Relationships".equals(root.getLocalName())
                || !RELATIONSHIP_NAMESPACE.equals(root.getNamespaceURI())) {
            throw formatInvalid("relationship part root element is invalid");
        }
        List<RelationshipMetadata> relationships = new ArrayList<>();
        Set<String> relationshipIds = new HashSet<>();
        for (Node node = root.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (!(node instanceof Element relationship)) {
                continue;
            }
            if (!"Relationship".equals(relationship.getLocalName())
                    || !RELATIONSHIP_NAMESPACE.equals(relationship.getNamespaceURI())) {
                throw formatInvalid("relationship part contains an unknown element");
            }
            String id = requiredAttribute(relationship, "Id");
            String type = requiredAttribute(relationship, "Type");
            String target = requiredAttribute(relationship, "Target");
            if (!relationshipIds.add(id)) {
                throw formatInvalid("relationship identifiers must be unique within a part");
            }
            String targetMode = relationship.getAttribute("TargetMode");
            if (targetMode.isEmpty()) {
                String internalTarget = resolveInternalTarget(sourcePart, target);
                if (!verifiedParts.contains(internalTarget)) {
                    throw formatInvalid("internal relationship target is absent from the verified package");
                }
                relationships.add(new RelationshipMetadata(
                        sourcePart,
                        id,
                        type,
                        Mode.INTERNAL,
                        Optional.of(internalTarget),
                        Optional.empty(),
                        Optional.empty()));
            } else if (targetMode.equals("External")) {
                relationships.add(new RelationshipMetadata(
                        sourcePart,
                        id,
                        type,
                        Mode.EXTERNAL,
                        Optional.empty(),
                        Optional.of(SourceHash.sha256(target.getBytes(StandardCharsets.UTF_8))),
                        Optional.of("EXTERNAL_RELATIONSHIP_NOT_DEREFERENCED")));
            } else {
                throw formatInvalid("relationship target mode is not supported");
            }
        }
        return List.copyOf(relationships);
    }

    private static String sourcePartFor(String relationshipPart) {
        if (relationshipPart.equals("_rels/.rels")) {
            return "";
        }
        int marker = relationshipPart.lastIndexOf("/_rels/");
        if (marker < 0 || !relationshipPart.endsWith(".rels")) {
            throw formatInvalid("relationship part name is invalid");
        }
        String directory = relationshipPart.substring(0, marker + 1);
        String relatedName = relationshipPart.substring(marker + "/_rels/".length());
        return directory + relatedName.substring(0, relatedName.length() - ".rels".length());
    }

    private static String resolveInternalTarget(String sourcePart, String target) {
        if (target.indexOf('\0') >= 0
                || target.indexOf('\\') >= 0
                || target.startsWith("/")
                || target.matches("^[A-Za-z]:.*")) {
            throw new DocxSecurityViolation(
                    DocxSecurityViolation.Rule.ABSOLUTE_ZIP_PATH,
                    "internal relationship target is not a package-relative path");
        }
        Deque<String> segments = new ArrayDeque<>();
        int sourceSeparator = sourcePart.lastIndexOf('/');
        if (sourceSeparator >= 0) {
            for (String segment : sourcePart.substring(0, sourceSeparator).split("/")) {
                if (!segment.isEmpty()) {
                    segments.addLast(segment);
                }
            }
        }
        for (String segment : target.split("/", -1)) {
            if (segment.isEmpty() || segment.equals(".")) {
                continue;
            }
            if (segment.equals("..")) {
                if (segments.isEmpty()) {
                    throw new DocxSecurityViolation(
                            DocxSecurityViolation.Rule.ZIP_PARENT_TRAVERSAL,
                            "internal relationship target escapes the package root");
                }
                segments.removeLast();
            } else {
                segments.addLast(segment);
            }
        }
        if (segments.isEmpty()) {
            throw formatInvalid("internal relationship target is empty");
        }
        return String.join("/", segments);
    }

    private static String requiredAttribute(Element element, String name) {
        String value = element.getAttribute(name);
        if (value == null || value.isBlank()) {
            throw formatInvalid("relationship attribute is missing");
        }
        return value;
    }

    private static SourceDomainException formatInvalid(String detail) {
        return new SourceDomainException(SourceDomainException.Code.DOCX_FORMAT_INVALID, detail);
    }

    private static void requireText(String value, String error) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(error);
        }
    }
}
