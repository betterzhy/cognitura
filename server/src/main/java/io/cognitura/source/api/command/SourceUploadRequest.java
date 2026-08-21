package io.cognitura.source.api.command;

import com.fasterxml.jackson.annotation.JsonCreator;
import tools.jackson.databind.JsonNode;
import io.cognitura.source.application.command.SourceCommandService;
import io.cognitura.source.domain.SourceHash;
import java.io.InputStream;
import java.util.Map;
import java.util.Set;

public final class SourceUploadRequest {

    private static final Set<String> FIELDS = Set.of(
            "idempotencyKey", "originalFileName", "declaredMediaType",
            "declaredByteLength", "contentSha256");

    private final String idempotencyKey;
    private final String originalFileName;
    private final String declaredMediaType;
    private final long declaredByteLength;
    private final SourceHash contentSha256;

    @JsonCreator(mode = JsonCreator.Mode.DELEGATING)
    public SourceUploadRequest(Map<String, JsonNode> fields) {
        if (fields == null || !fields.keySet().equals(FIELDS)) {
            throw new IllegalArgumentException("MALFORMED_COMMAND");
        }
        idempotencyKey = text(fields, "idempotencyKey");
        originalFileName = text(fields, "originalFileName");
        declaredMediaType = text(fields, "declaredMediaType");
        JsonNode length = fields.get("declaredByteLength");
        if (length == null || !length.isIntegralNumber() || !length.canConvertToLong()) {
            throw new IllegalArgumentException("MALFORMED_COMMAND");
        }
        declaredByteLength = length.longValue();
        try {
            contentSha256 = SourceHash.ofHex(text(fields, "contentSha256"));
        } catch (IllegalArgumentException error) {
            throw new IllegalArgumentException("MALFORMED_COMMAND");
        }
    }

    public SourceCommandService.UploadCommand toCommand(InputStream content) {
        return new SourceCommandService.UploadCommand(
                originalFileName,
                declaredMediaType,
                content,
                declaredByteLength,
                contentSha256,
                idempotencyKey);
    }

    private static String text(Map<String, JsonNode> fields, String name) {
        JsonNode value = fields.get(name);
        if (value == null || !value.isTextual() || value.textValue().isBlank()) {
            throw new IllegalArgumentException("MALFORMED_COMMAND");
        }
        return value.textValue();
    }
}
