package io.cognitura.source.runtime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.github.dockerjava.api.exception.NotFoundException;
import io.cognitura.source.application.command.SourceCommandService;
import io.cognitura.source.application.command.TrustedRequestContextProvider;
import io.cognitura.source.application.processing.ProcessingAttempt;
import io.cognitura.source.application.processing.ProcessingPublicationService;
import io.cognitura.source.domain.SourceHash;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.time.Instant;
import java.util.Comparator;
import java.util.UUID;
import javax.sql.DataSource;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.DockerClientFactory;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

@SpringBootTest
class SourceCommandRuntimeIntegrationTest {

    private static final String POSTGRES_IMAGE =
            "postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a";
    private static final Instant STARTED = Instant.parse("2026-08-22T04:00:00Z");
    private static final PostgreSQLContainer postgres;
    private static final Path casRoot;
    private static final String containerId;

    static {
        try {
            casRoot = Files.createTempDirectory("cognitura-i09-runtime-");
        } catch (IOException error) {
            throw new ExceptionInInitializerError(error);
        }
        String suffix = UUID.randomUUID().toString().replace("-", "");
        DockerImageName image = DockerImageName.parse(POSTGRES_IMAGE)
                .asCompatibleSubstituteFor("postgres");
        postgres = new PostgreSQLContainer(image)
                .withDatabaseName("cognitura_i09_runtime_" + suffix)
                .withUsername("i09_runtime_" + suffix)
                .withPassword(UUID.randomUUID().toString() + UUID.randomUUID())
                .withReuse(false);
        postgres.start();
        containerId = postgres.getContainerId();
    }

    @DynamicPropertySource
    static void runtimeProperties(DynamicPropertyRegistry registry) {
        registry.add("cognitura.source-command.enabled", () -> "true");
        registry.add("cognitura.source-command.workspace-id", () -> "workspace-runtime");
        registry.add("cognitura.source-command.actor-id", () -> "actor-runtime");
        registry.add("cognitura.source-command.cas-root", casRoot::toString);
        registry.add("cognitura.source-command.max-upload-bytes", () -> "1048576");
        registry.add("cognitura.source-command.jdbc-url", postgres::getJdbcUrl);
        registry.add("cognitura.source-command.jdbc-username", postgres::getUsername);
        registry.add("cognitura.source-command.jdbc-password", postgres::getPassword);
    }

    @Autowired
    private SourceCommandService sourceCommands;

    @Autowired
    private ProcessingPublicationService processingCommands;

    @Autowired
    private TrustedRequestContextProvider trustedContext;

    @Autowired
    private DataSource dataSource;

    @Test
    void enabledRuntimeStreamsPersistsAndStartsARealProcessingAttempt() throws Exception {
        byte[] content = "runtime-docx-payload".getBytes(java.nio.charset.StandardCharsets.UTF_8);
        SourceHash hash = SourceHash.sha256(content);
        SourceCommandService.UploadResult upload = sourceCommands.upload(
                trustedContext.currentContext(),
                new SourceCommandService.UploadCommand(
                        "runtime.docx",
                        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                        new ByteArrayInputStream(content),
                        content.length,
                        hash,
                        "runtime-upload"));

        assertThat(upload.created()).isTrue();
        assertThat(upload.contentSha256()).isEqualTo(hash);
        assertThat(trustedContext.currentContext().workspaceId()).isEqualTo("workspace-runtime");
        assertThat(count("select count(*) from source_document")).isEqualTo(1);
        assertThat(count("select count(*) from source_binary")).isEqualTo(1);

        try (Connection connection = dataSource.getConnection();
                PreparedStatement accepted = connection.prepareStatement("""
                        update source_document set validation_status = 'ACCEPTED'
                        where source_document_id = ?
                        """)) {
            accepted.setString(1, upload.sourceDocumentId());
            assertThat(accepted.executeUpdate()).isEqualTo(1);
        }

        ProcessingAttempt attempt = processingCommands.beginInitial(
                upload.sourceDocumentId(),
                "runtime-revision",
                "runtime-attempt",
                hash.value(),
                "docx-v1",
                STARTED,
                STARTED.plusSeconds(30));
        assertThat(attempt.revisionId()).isEqualTo("runtime-revision");
        assertThat(attempt.attemptId()).isEqualTo("runtime-attempt");
        assertThat(count("select count(*) from source_processing_revision")).isEqualTo(1);
        assertThat(count("select count(*) from source_processing_attempt")).isEqualTo(1);

        try (Connection connection = dataSource.getConnection();
                Statement statement = connection.createStatement();
                ResultSet result = statement.executeQuery(
                        "select current_setting('server_version_num'), current_database()")) {
            assertThat(result.next()).isTrue();
            assertThat(result.getString(1)).startsWith("18");
            assertThat(result.getString(2)).isEqualTo(postgres.getDatabaseName());
        }
    }

    private long count(String sql) throws Exception {
        try (Connection connection = dataSource.getConnection();
                Statement statement = connection.createStatement();
                ResultSet result = statement.executeQuery(sql)) {
            assertThat(result.next()).isTrue();
            return result.getLong(1);
        }
    }

    @AfterAll
    static void stopAndProveIsolation() throws IOException {
        postgres.close();
        assertThatThrownBy(() -> DockerClientFactory.instance()
                        .client()
                        .inspectContainerCmd(containerId)
                        .exec())
                .isInstanceOf(NotFoundException.class);
        if (Files.exists(casRoot)) {
            try (var paths = Files.walk(casRoot)) {
                paths.sorted(Comparator.reverseOrder()).forEach(path -> {
                    try {
                        Files.delete(path);
                    } catch (IOException error) {
                        throw new IllegalStateException("RUNTIME_FIXTURE_CLEANUP_FAILED", error);
                    }
                });
            }
        }
        System.out.println("W1I09RuntimeContainerId = " + containerId);
        System.out.println("W1I09RuntimeImage = " + POSTGRES_IMAGE);
        System.out.println("W1I09RuntimeDatabaseName = " + postgres.getDatabaseName());
        System.out.println("W1I09RuntimeContainerRemoval = PASS");
    }
}
