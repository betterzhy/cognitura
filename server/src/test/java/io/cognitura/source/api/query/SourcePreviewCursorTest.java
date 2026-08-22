package io.cognitura.source.api.query;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

class SourcePreviewCursorTest {

    private static final byte[] SIGNING_KEY =
            "0123456789abcdef0123456789abcdef".getBytes(StandardCharsets.UTF_8);

    private final SourcePreviewCursor cursor = new SourcePreviewCursor(SIGNING_KEY);

    @Test
    void roundTripsExactRevisionKeysetPosition() {
        String token = cursor.encode("workspace-1", "source-1", "revision-1", 41);

        assertThat(cursor.decode(token, "workspace-1", "source-1", "revision-1"))
                .isEqualTo(41);
    }

    @Test
    void rejectsTamperingAndMalformedTokens() {
        String token = cursor.encode("workspace-1", "source-1", "revision-1", 3);
        char replacement = token.charAt(token.length() - 1) == 'A' ? 'B' : 'A';
        String tampered = token.substring(0, token.length() - 1) + replacement;

        assertPaginationInvalid(() -> cursor.decode(
                tampered, "workspace-1", "source-1", "revision-1"));
        assertPaginationInvalid(() -> cursor.decode(
                "not-a-cursor", "workspace-1", "source-1", "revision-1"));
        assertPaginationInvalid(() -> cursor.decode(
                "", "workspace-1", "source-1", "revision-1"));
    }

    @Test
    void rejectsWorkspaceSourceAndRevisionMismatch() {
        String token = cursor.encode("workspace-1", "source-1", "revision-1", 8);

        assertPaginationInvalid(() -> cursor.decode(
                token, "workspace-2", "source-1", "revision-1"));
        assertPaginationInvalid(() -> cursor.decode(
                token, "workspace-1", "source-2", "revision-1"));
        assertPaginationInvalid(() -> cursor.decode(
                token, "workspace-1", "source-1", "revision-2"));
    }

    @Test
    void rejectsInvalidInputAndWeakSigningKeys() {
        assertThatThrownBy(() -> new SourcePreviewCursor(new byte[31]))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("PREVIEW_CURSOR_SIGNING_KEY_INVALID");
        assertPaginationInvalid(() -> cursor.encode(
                "workspace-1", "source-1", "revision-1", -1));
        assertPaginationInvalid(() -> cursor.encode(
                "workspace/1", "source-1", "revision-1", 0));
    }

    private static void assertPaginationInvalid(Runnable action) {
        assertThatThrownBy(action::run)
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("PAGINATION_INVALID");
    }
}
