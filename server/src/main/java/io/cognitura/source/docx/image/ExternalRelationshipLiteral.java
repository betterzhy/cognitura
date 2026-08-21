package io.cognitura.source.docx.image;

import io.cognitura.source.docx.security.DocxRelationshipClassifier;
import io.cognitura.source.domain.SourceHash;
import java.util.Objects;

public record ExternalRelationshipLiteral(
        String sourcePart,
        String relationshipId,
        String relationshipType,
        DocxRelationshipClassifier.Mode relationshipMode,
        SourceHash externalTargetLiteralSha256,
        String securityDisclosure) {

    public ExternalRelationshipLiteral {
        Objects.requireNonNull(sourcePart, "sourcePart");
        requireText(relationshipId, "EXTERNAL_RELATIONSHIP_ID_REQUIRED");
        requireText(relationshipType, "EXTERNAL_RELATIONSHIP_TYPE_REQUIRED");
        if (relationshipMode != DocxRelationshipClassifier.Mode.EXTERNAL) {
            throw new IllegalArgumentException("EXTERNAL_RELATIONSHIP_MODE_REQUIRED");
        }
        Objects.requireNonNull(externalTargetLiteralSha256, "externalTargetLiteralSha256");
        requireText(securityDisclosure, "EXTERNAL_RELATIONSHIP_DISCLOSURE_REQUIRED");
    }

    private static void requireText(String value, String message) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(message);
        }
    }
}
