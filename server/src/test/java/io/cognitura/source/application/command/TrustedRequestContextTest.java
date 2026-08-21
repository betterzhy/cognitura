package io.cognitura.source.application.command;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.lang.reflect.Modifier;
import java.util.List;
import org.junit.jupiter.api.Test;

class TrustedRequestContextTest {

    @Test
    void acceptsOnlyBoundedSafeServerOwnedIdentifiers() {
        TrustedRequestContext context = new TrustedRequestContext("workspace-a", "actor-a");

        assertThat(context.workspaceId()).isEqualTo("workspace-a");
        assertThat(context.actorId()).isEqualTo("actor-a");
        assertThat(Modifier.isFinal(TrustedRequestContext.class.getModifiers())).isTrue();
        assertThat(TrustedRequestContext.class.getDeclaredConstructors())
                .singleElement()
                .satisfies(constructor -> assertThat(constructor.getParameterTypes())
                        .containsExactly(String.class, String.class));

        for (String invalid : List.of("", " ", "../workspace", "/workspace", "workspace/path",
                "workspace\nother", "x".repeat(129))) {
            assertThatThrownBy(() -> new TrustedRequestContext(invalid, "actor-a"))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessage("TRUSTED_WORKSPACE_ID_INVALID");
            assertThatThrownBy(() -> new TrustedRequestContext("workspace-a", invalid))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessage("TRUSTED_ACTOR_ID_INVALID");
        }
        assertThatThrownBy(() -> new TrustedRequestContext(null, "actor-a"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("TRUSTED_WORKSPACE_ID_INVALID");
        assertThatThrownBy(() -> new TrustedRequestContext("workspace-a", null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("TRUSTED_ACTOR_ID_INVALID");
    }

    @Test
    void providerReturnsOnlyItsConfiguredImmutablePair() {
        TrustedRequestContext configured = new TrustedRequestContext("workspace-a", "actor-a");
        TrustedRequestContextProvider provider = () -> configured;

        assertThat(provider.currentContext()).isSameAs(configured);
        assertThat(provider.currentContext()).isEqualTo(
                new TrustedRequestContext("workspace-a", "actor-a"));
    }

    @Test
    void rejectsPathWorkspaceMismatchWithoutEchoingForeignInput() {
        TrustedRequestContext context = new TrustedRequestContext("workspace-a", "actor-a");

        assertThat(context.requirePathWorkspace("workspace-a")).isSameAs(context);
        assertThatThrownBy(() -> context.requirePathWorkspace("foreign-secret-workspace"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("TRUSTED_WORKSPACE_SCOPE_MISMATCH")
                .hasMessageNotContaining("foreign-secret-workspace");
        assertThatThrownBy(() -> context.requirePathWorkspace("../workspace-a"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("TRUSTED_WORKSPACE_SCOPE_MISMATCH")
                .hasMessageNotContaining("../workspace-a");
    }
}
