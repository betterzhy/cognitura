package io.cognitura.source.application.command;

import java.util.regex.Pattern;

public record TrustedRequestContext(String workspaceId, String actorId) {

    private static final Pattern IDENTIFIER =
            Pattern.compile("[A-Za-z0-9][A-Za-z0-9._:-]{0,127}");

    public TrustedRequestContext {
        workspaceId = requireIdentifier(workspaceId, "TRUSTED_WORKSPACE_ID_INVALID");
        actorId = requireIdentifier(actorId, "TRUSTED_ACTOR_ID_INVALID");
    }

    public TrustedRequestContext requirePathWorkspace(String pathWorkspaceId) {
        if (!workspaceId.equals(pathWorkspaceId)) {
            throw new IllegalArgumentException("TRUSTED_WORKSPACE_SCOPE_MISMATCH");
        }
        return this;
    }

    private static String requireIdentifier(String value, String errorCode) {
        if (value == null || !IDENTIFIER.matcher(value).matches()) {
            throw new IllegalArgumentException(errorCode);
        }
        return value;
    }
}
