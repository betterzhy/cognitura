package io.cognitura;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.health.actuate.endpoint.HealthEndpoint;
import org.springframework.boot.health.contributor.Status;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class HealthBaselineTest {

    @Autowired
    private HealthEndpoint healthEndpoint;

    @Test
    void applicationHealthIsUpWithoutBusinessInfrastructure() {
        assertThat(healthEndpoint.health().getStatus()).isEqualTo(Status.UP);
    }
}
