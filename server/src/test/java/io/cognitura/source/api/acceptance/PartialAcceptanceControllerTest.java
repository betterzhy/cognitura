package io.cognitura.source.api.acceptance;

import static org.hamcrest.Matchers.hasSize;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import io.cognitura.source.application.command.TrustedRequestContext;
import io.cognitura.source.application.command.TrustedRequestContextProvider;
import io.cognitura.source.persistence.JdbcPartialAcceptancePort;
import io.cognitura.source.runtime.SourceCommandRuntimeConfiguration;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.UUID;
import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.http.MediaType;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.testcontainers.DockerClientFactory;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

class PartialAcceptanceControllerTest {

    private static final String POSTGRES_IMAGE =
            "postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a";
    private static final String BLOCK_DIGEST = "a".repeat(64);
    private static final String OMISSIONS_DIGEST = "b".repeat(64);
    private static final Instant ACCEPTED_AT = Instant.parse("2026-08-22T09:10:11.123456Z");

    private static PostgreSQLContainer postgres;
    private static DataSource dataSource;
    private static String containerId;

    private MockMvc mvc;

    @TempDir
    Path runtimeCasRoot;

    @BeforeAll
    static void startIsolatedPostgres() throws Exception {
        String suffix = UUID.randomUUID().toString().replace("-", "");
        DockerImageName image = DockerImageName.parse(POSTGRES_IMAGE)
                .asCompatibleSubstituteFor("postgres");
        postgres = new PostgreSQLContainer(image)
                .withDatabaseName("cognitura_i11_http_" + suffix)
                .withUsername("i11_http_" + suffix)
                .withPassword(UUID.randomUUID().toString() + UUID.randomUUID())
                .withReuse(false);
        postgres.start();
        containerId = postgres.getContainerId();
        try (Connection connection = postgres.createConnection("");
                Statement statement = connection.createStatement();
                ResultSet result = statement.executeQuery(
                        "select current_setting('server_version_num'), current_database()")) {
            assertThat(result.next()).isTrue();
            assertThat(result.getString(1)).startsWith("18");
            assertThat(result.getString(2)).isEqualTo(postgres.getDatabaseName());
        }
        dataSource = new DriverManagerDataSource(
                postgres.getJdbcUrl(), postgres.getUsername(), postgres.getPassword());
        assertThat(Flyway.configure().dataSource(dataSource).load().migrate().migrationsExecuted)
                .isEqualTo(3);
    }

    @AfterAll
    static void stopAndProveRemoval() {
        if (postgres == null) return;
        postgres.close();
        assertThatThrownBy(() -> DockerClientFactory.instance()
                        .client().inspectContainerCmd(containerId).exec())
                .isInstanceOf(com.github.dockerjava.api.exception.NotFoundException.class);
        System.out.println("W1I11AcceptanceHttpContainerRemoval = PASS");
    }

    @BeforeEach
    void resetAndWireRealJdbcService() throws Exception {
        update("truncate table source_binary cascade");
        wire("workspace-a", "actor-a");
    }

    private void wire(String workspaceId, String actorId) {
        PartialAcceptanceService service = new PartialAcceptanceService(
                new JdbcPartialAcceptancePort(dataSource),
                Clock.fixed(ACCEPTED_AT, ZoneOffset.UTC));
        TrustedRequestContextProvider contexts =
                () -> new TrustedRequestContext(workspaceId, actorId);
        mvc = MockMvcBuilders.standaloneSetup(
                        new PartialAcceptanceController(service, contexts))
                .setControllerAdvice(new PartialAcceptanceErrorAdvice())
                .build();
    }

    @Test
    void returnsTheFormalResultForNewAcceptanceAndReplay() throws Exception {
        seedPartialRevision("workspace-a", "source-a", "revision-a");

        mvc.perform(post(endpoint("source-a", "revision-a"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validBody("accept-key-a")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.*", hasSize(7)))
                .andExpect(jsonPath("$.sourceDocumentId").value("source-a"))
                .andExpect(jsonPath("$.sourceProcessingRevisionId").value("revision-a"))
                .andExpect(jsonPath("$.partialAcceptanceStatus").value("ACCEPTED"))
                .andExpect(jsonPath("$.partialAcceptedAt").value(ACCEPTED_AT.toString()))
                .andExpect(jsonPath("$.acceptedBy").value("actor-a"))
                .andExpect(jsonPath("$.consumptionEligible").value(true))
                .andExpect(jsonPath("$.idempotentReplay").value(false));

        mvc.perform(post(endpoint("source-a", "revision-a"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validBody("accept-key-a")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.partialAcceptedAt").value(ACCEPTED_AT.toString()))
                .andExpect(jsonPath("$.acceptedBy").value("actor-a"))
                .andExpect(jsonPath("$.idempotentReplay").value(true));
    }

    @Test
    void rejectsBodyOwnedWorkspaceActorAndIdentitiesAsMalformed() throws Exception {
        String injected = """
                {"blockSetDigest":"%s","omissionsDigest":"%s",
                 "idempotencyKey":"accept-key-a","decision":"ACCEPT_PARTIAL",
                 "workspaceId":"workspace-b","actorId":"actor-b",
                 "sourceDocumentId":"source-b","sourceProcessingRevisionId":"revision-b"}
                """.formatted(BLOCK_DIGEST, OMISSIONS_DIGEST);

        mvc.perform(post(endpoint("source-a", "revision-a"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(injected))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.*", hasSize(5)))
                .andExpect(jsonPath("$.errorCode").value("MALFORMED_COMMAND"))
                .andExpect(jsonPath("$.retryable").value(false))
                .andExpect(jsonPath("$.sourceDocumentId").isEmpty())
                .andExpect(jsonPath("$.sourceProcessingRevisionId").isEmpty());
    }

    @Test
    void foreignWorkspaceAndMissingIdentityShareTheUniform404Shape() throws Exception {
        seedPartialRevision("workspace-a", "source-a", "revision-a");
        wire("workspace-b", "actor-a");
        String foreign = mvc.perform(post(endpoint("source-a", "revision-a"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validBody("accept-key-a")))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.*", hasSize(5)))
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"))
                .andExpect(jsonPath("$.sourceDocumentId").isEmpty())
                .andExpect(jsonPath("$.sourceProcessingRevisionId").isEmpty())
                .andReturn().getResponse().getContentAsString();

        wire("workspace-a", "actor-a");
        String missing = mvc.perform(post(endpoint("missing", "missing"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validBody("accept-key-a")))
                .andExpect(status().isNotFound())
                .andReturn().getResponse().getContentAsString();
        assertThat(missing).isEqualTo(foreign);
    }

    @Test
    void mapsResolvedConflictAndNotReadyWithoutLeakingStorageFacts() throws Exception {
        seedPartialRevision("workspace-a", "source-a", "revision-a");
        mvc.perform(post(endpoint("source-a", "revision-a"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validBody("accept-key-a")))
                .andExpect(status().isOk());
        mvc.perform(post(endpoint("source-a", "revision-a"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validBody("accept-key-b")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.*", hasSize(5)))
                .andExpect(jsonPath("$.errorCode").value("PARTIAL_ACCEPTANCE_CONFLICT"))
                .andExpect(jsonPath("$.retryable").value(false))
                .andExpect(jsonPath("$.sourceDocumentId").value("source-a"))
                .andExpect(jsonPath("$.sourceProcessingRevisionId").value("revision-a"));

        resetAndWireRealJdbcService();
        seedPartialRevision("workspace-a", "source-a", "revision-a");
        update("update source_processing_revision set revision_status = 'PARSED' "
                + "where source_processing_revision_id = ?", "revision-a");
        mvc.perform(post(endpoint("source-a", "revision-a"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validBody("accept-key-a")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.errorCode").value("PREVIEW_NOT_READY"))
                .andExpect(jsonPath("$.retryable").value(true))
                .andExpect(jsonPath("$.sourceDocumentId").value("source-a"))
                .andExpect(jsonPath("$.sourceProcessingRevisionId").value("revision-a"));
    }

    @Test
    void runtimeWiresTheRealJdbcAcceptanceBoundaryOnlyWhenEnabled() {
        ApplicationContextRunner runner = new ApplicationContextRunner()
                .withUserConfiguration(
                        SourceCommandRuntimeConfiguration.class,
                        PartialAcceptanceController.class)
                .withPropertyValues(
                        "cognitura.source-command.enabled=true",
                        "cognitura.source-command.jdbc-url=" + postgres.getJdbcUrl(),
                        "cognitura.source-command.jdbc-username=" + postgres.getUsername(),
                        "cognitura.source-command.jdbc-password=" + postgres.getPassword(),
                        "cognitura.source-command.workspace-id=workspace-a",
                        "cognitura.source-command.actor-id=actor-a",
                        "cognitura.source-command.max-upload-bytes=1024",
                        "cognitura.source-command.cas-root=" + runtimeCasRoot);

        runner.run(context -> {
            assertThat(context).hasNotFailed();
            assertThat(context.getBeansOfType(PartialAcceptancePort.class)).hasSize(1);
            assertThat(context.getBeansOfType(PartialAcceptanceService.class)).hasSize(1);
            assertThat(context.getBeansOfType(PartialAcceptanceController.class)).hasSize(1);
        });

        new ApplicationContextRunner()
                .withUserConfiguration(
                        SourceCommandRuntimeConfiguration.class,
                        PartialAcceptanceController.class)
                .run(context -> {
                    assertThat(context.getBeansOfType(PartialAcceptancePort.class)).isEmpty();
                    assertThat(context.getBeansOfType(PartialAcceptanceService.class)).isEmpty();
                    assertThat(context.getBeansOfType(PartialAcceptanceController.class)).isEmpty();
                });
    }

    private static String endpoint(String sourceId, String revisionId) {
        return "/api/v1/source-documents/" + sourceId
                + "/processing-revisions/" + revisionId + "/partial-acceptance";
    }

    private static String validBody(String key) {
        return """
                {"blockSetDigest":"%s","omissionsDigest":"%s",
                 "idempotencyKey":"%s","decision":"ACCEPT_PARTIAL"}
                """.formatted(BLOCK_DIGEST, OMISSIONS_DIGEST, key);
    }

    private static void seedPartialRevision(
            String workspaceId, String sourceId, String revisionId) throws SQLException {
        String contentHash = "c".repeat(64);
        update("""
                insert into source_binary(
                  source_binary_id, content_sha256, byte_length, media_type,
                  binary_location, created_at)
                values (?, ?, 1, 'application/test', 'cas:test', ?)
                """, "binary-a", contentHash, ACCEPTED_AT.minusSeconds(2));
        update("""
                insert into source_document(
                  source_document_id, workspace_id, source_binary_id,
                  original_file_name, media_type, byte_length, content_sha256,
                  received_at, idempotency_key, validation_status)
                values (?, ?, 'binary-a', 'source.docx', 'application/test', 1, ?, ?,
                        'upload-key-a', 'ACCEPTED')
                """, sourceId, workspaceId, contentHash, ACCEPTED_AT.minusSeconds(2));
        update("""
                insert into source_processing_revision(
                  source_processing_revision_id, source_document_id, content_sha256,
                  parser_profile_version, revision_status, started_at, completed_at,
                  published_digest, omissions_digest, parse_completeness,
                  partial_acceptance_status)
                values (?, ?, ?, 'parser-v1', 'PREVIEW_READY', ?, ?, ?, ?, 'PARTIAL', 'PENDING')
                """, revisionId, sourceId, contentHash,
                ACCEPTED_AT.minusSeconds(2), ACCEPTED_AT.minusSeconds(1),
                BLOCK_DIGEST, OMISSIONS_DIGEST);
    }

    private static int update(String sql, Object... parameters) throws SQLException {
        try (Connection connection = dataSource.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            for (int index = 0; index < parameters.length; index++) {
                Object value = parameters[index];
                if (value instanceof Instant instant) {
                    statement.setTimestamp(index + 1, java.sql.Timestamp.from(instant));
                } else {
                    statement.setObject(index + 1, value);
                }
            }
            return statement.executeUpdate();
        }
    }
}
