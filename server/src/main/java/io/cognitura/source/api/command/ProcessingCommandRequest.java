package io.cognitura.source.api.command;

import com.fasterxml.jackson.annotation.JsonCreator;
import tools.jackson.databind.JsonNode;
import io.cognitura.source.application.command.SourceCommandService;
import java.util.Map;
import java.util.Set;

public final class ProcessingCommandRequest {

    private static final Set<String> FIELDS =
            Set.of("sourceDocumentId", "parserProfileVersion");

    private final String sourceDocumentId;
    private final String parserProfileVersion;

    @JsonCreator(mode = JsonCreator.Mode.DELEGATING)
    public ProcessingCommandRequest(Map<String, JsonNode> fields) {
        if (fields == null || !fields.keySet().equals(FIELDS)) {
            throw new IllegalArgumentException("MALFORMED_COMMAND");
        }
        sourceDocumentId = text(fields, "sourceDocumentId");
        parserProfileVersion = text(fields, "parserProfileVersion");
    }

    public String sourceDocumentId() {
        return sourceDocumentId;
    }

    public SourceCommandService.ProcessingCommand toCommand() {
        return new SourceCommandService.ProcessingCommand(
                sourceDocumentId, parserProfileVersion);
    }

    private static String text(Map<String, JsonNode> fields, String name) {
        JsonNode value = fields.get(name);
        if (value == null || !value.isTextual() || value.textValue().isBlank()) {
            throw new IllegalArgumentException("MALFORMED_COMMAND");
        }
        return value.textValue();
    }
}
