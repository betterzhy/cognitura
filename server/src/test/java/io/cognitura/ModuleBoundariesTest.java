package io.cognitura;

import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModules;

class ModuleBoundariesTest {

    @Test
    void modularMonolithBoundariesAreValid() {
        ApplicationModules.of(CognituraApplication.class).verify();
    }
}
