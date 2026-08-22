package io.cognitura.source.api.acceptance;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.cognitura.source.application.command.TrustedRequestContext;
import io.cognitura.source.domain.SourceHash;
import io.cognitura.source.persistence.JdbcPartialAcceptancePort;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.testcontainers.DockerClientFactory;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

class PartialAcceptanceServiceTest {

    private static final String POSTGRES_IMAGE =
            "postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a";
    private static final String BLOCK_DIGEST = "a".repeat(64);
    private static final String OMISSIONS_DIGEST = "b".repeat(64);
    private static final Instant ACCEPTED_AT = Instant.parse("2026-08-22T08:09:10.123456Z");
    private static final TrustedRequestContext CONTEXT =
            new TrustedRequestContext("workspace-a", "actor-a");

    private static PostgreSQLContainer postgres;
    private static DataSource dataSource;
    private static String containerId;
    private static PartialAcceptanceService service;

    @BeforeAll
    static void startIsolatedPostgres() throws Exception {
        String suffix = UUID.randomUUID().toString().replace("-", "");
        DockerImageName image = DockerImageName.parse(POSTGRES_IMAGE)
                .asCompatibleSubstituteFor("postgres");
        postgres = new PostgreSQLContainer(image)
                .withDatabaseName("cognitura_i11_" + suffix)
                .withUsername("i11_" + suffix)
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
        Flyway flyway = Flyway.configure().dataSource(dataSource).load();
        assertThat(flyway.migrate().migrationsExecuted).isEqualTo(3);
        assertThat(flyway.migrate().migrationsExecuted).isZero();
        service = new PartialAcceptanceService(
                new JdbcPartialAcceptancePort(dataSource),
                Clock.fixed(ACCEPTED_AT, ZoneOffset.UTC));

        System.out.println("W1I11AcceptanceContainerId = " + containerId);
        System.out.println("W1I11AcceptanceImage = " + POSTGRES_IMAGE);
        System.out.println("W1I11AcceptanceDatabaseName = " + postgres.getDatabaseName());
        System.out.println("W1I11AcceptanceContainerReuse = false");
    }

    @AfterAll
    static void stopAndProveRemoval() {
        if (postgres == null) {
            return;
        }
        postgres.close();
        assertThatThrownBy(() -> DockerClientFactory.instance()
                        .client()
                        .inspectContainerCmd(containerId)
                        .exec())
                .isInstanceOf(com.github.dockerjava.api.exception.NotFoundException.class);
        System.out.println("W1I11AcceptanceContainerRemoval = PASS");
    }

    @BeforeEach
    void resetDatabase() throws SQLException {
        update("truncate table source_binary cascade");
    }

    @Test
    void createsOneImmutableAcceptanceAndReplaysTheExactTuple() throws Exception {
        seedRevision(
                "workspace-a", "source-a", "revision-a",
                "PREVIEW_READY", "PARTIAL", "PENDING",
                BLOCK_DIGEST, OMISSIONS_DIGEST);
        PartialAcceptanceCommand command = command(
                "source-a", "revision-a", BLOCK_DIGEST, OMISSIONS_DIGEST, "accept-key-a");

        PartialAcceptanceService.Result created = service.accept(CONTEXT, command);
        PartialAcceptanceService.Result replayed = service.accept(CONTEXT, command);

        assertThat(created).isEqualTo(new PartialAcceptanceService.Result(
                "source-a", "revision-a", "ACCEPTED", ACCEPTED_AT,
                "actor-a", true, false));
        assertThat(replayed).isEqualTo(new PartialAcceptanceService.Result(
                "source-a", "revision-a", "ACCEPTED", ACCEPTED_AT,
                "actor-a", true, true));
        assertThat(acceptanceFacts("revision-a")).isEqualTo(new AcceptanceFacts(
                "ACCEPTED", ACCEPTED_AT, "actor-a", "accept-key-a"));
    }

    @Test
    void rejectsEveryTupleDriftWithoutOverwritingTheFirstAcceptance() throws Exception {
        seedRevision(
                "workspace-a", "source-a", "revision-a",
                "PREVIEW_READY", "PARTIAL", "PENDING",
                BLOCK_DIGEST, OMISSIONS_DIGEST);
        PartialAcceptanceCommand original = command(
                "source-a", "revision-a", BLOCK_DIGEST, OMISSIONS_DIGEST, "accept-key-a");
        service.accept(CONTEXT, original);

        assertRejected(
                CONTEXT,
                command("source-a", "revision-a", "d".repeat(64),
                        OMISSIONS_DIGEST, "accept-key-a"),
                PartialAcceptanceService.ErrorCode.PARTIAL_ACCEPTANCE_CONFLICT,
                "source-a", "revision-a");
        assertRejected(
                CONTEXT,
                command("source-a", "revision-a", BLOCK_DIGEST,
                        "e".repeat(64), "accept-key-a"),
                PartialAcceptanceService.ErrorCode.PARTIAL_ACCEPTANCE_CONFLICT,
                "source-a", "revision-a");
        assertRejected(
                CONTEXT,
                command("source-a", "revision-a", BLOCK_DIGEST,
                        OMISSIONS_DIGEST, "accept-key-b"),
                PartialAcceptanceService.ErrorCode.PARTIAL_ACCEPTANCE_CONFLICT,
                "source-a", "revision-a");
        assertRejected(
                new TrustedRequestContext("workspace-a", "actor-b"), original,
                PartialAcceptanceService.ErrorCode.PARTIAL_ACCEPTANCE_CONFLICT,
                "source-a", "revision-a");

        assertThat(acceptanceFacts("revision-a")).isEqualTo(new AcceptanceFacts(
                "ACCEPTED", ACCEPTED_AT, "actor-a", "accept-key-a"));
    }

    @Test
    void keepsInvisibleAndMismatchedIdentitiesIndistinguishable() throws Exception {
        seedRevision(
                "workspace-a", "source-a", "revision-a",
                "PREVIEW_READY", "PARTIAL", "PENDING",
                BLOCK_DIGEST, OMISSIONS_DIGEST);

        assertRejected(
                new TrustedRequestContext("workspace-b", "actor-a"),
                command("source-a", "revision-a", BLOCK_DIGEST,
                        OMISSIONS_DIGEST, "accept-key-a"),
                PartialAcceptanceService.ErrorCode.RESOURCE_NOT_FOUND, null, null);
        assertRejected(
                CONTEXT,
                command("source-missing", "revision-a", BLOCK_DIGEST,
                        OMISSIONS_DIGEST, "accept-key-a"),
                PartialAcceptanceService.ErrorCode.RESOURCE_NOT_FOUND, null, null);
        assertRejected(
                CONTEXT,
                command("source-a", "revision-missing", BLOCK_DIGEST,
                        OMISSIONS_DIGEST, "accept-key-a"),
                PartialAcceptanceService.ErrorCode.RESOURCE_NOT_FOUND, null, null);
        assertThat(acceptanceFacts("revision-a")).isEqualTo(new AcceptanceFacts(
                "PENDING", null, null, null));
    }

    @Test
    void rejectsCompleteAndNotPreviewReadyRevisions() throws Exception {
        seedRevision(
                "workspace-a", "source-complete", "revision-complete",
                "PREVIEW_READY", "COMPLETE", "NOT_APPLICABLE",
                BLOCK_DIGEST, OMISSIONS_DIGEST);
        seedRevision(
                "workspace-a", "source-parsed", "revision-parsed",
                "PARSED", "PARTIAL", "PENDING",
                BLOCK_DIGEST, OMISSIONS_DIGEST);

        assertRejected(
                CONTEXT,
                command("source-complete", "revision-complete", BLOCK_DIGEST,
                        OMISSIONS_DIGEST, "accept-complete"),
                PartialAcceptanceService.ErrorCode.PARTIAL_ACCEPTANCE_CONFLICT,
                "source-complete", "revision-complete");
        assertRejected(
                CONTEXT,
                command("source-parsed", "revision-parsed", BLOCK_DIGEST,
                        OMISSIONS_DIGEST, "accept-parsed"),
                PartialAcceptanceService.ErrorCode.PREVIEW_NOT_READY,
                "source-parsed", "revision-parsed");
    }

    @Test
    void concurrentIdenticalCommandsCreateExactlyOneNewFact() throws Exception {
        seedRevision(
                "workspace-a", "source-a", "revision-a",
                "PREVIEW_READY", "PARTIAL", "PENDING",
                BLOCK_DIGEST, OMISSIONS_DIGEST);
        PartialAcceptanceCommand command = command(
                "source-a", "revision-a", BLOCK_DIGEST, OMISSIONS_DIGEST, "accept-key-a");

        List<Object> outcomes = race(
                () -> service.accept(CONTEXT, command),
                () -> service.accept(CONTEXT, command));

        assertThat(outcomes).allSatisfy(
                outcome -> assertThat(outcome).isInstanceOf(PartialAcceptanceService.Result.class));
        assertThat(outcomes.stream()
                        .map(PartialAcceptanceService.Result.class::cast)
                        .filter(result -> !result.idempotentReplay())
                        .count())
                .isEqualTo(1);
        assertThat(outcomes.stream()
                        .map(PartialAcceptanceService.Result.class::cast)
                        .filter(PartialAcceptanceService.Result::idempotentReplay)
                        .count())
                .isEqualTo(1);
        assertThat(acceptanceFacts("revision-a")).isEqualTo(new AcceptanceFacts(
                "ACCEPTED", ACCEPTED_AT, "actor-a", "accept-key-a"));
    }

    @Test
    void concurrentConflictingCommandsNeverOverwriteTheWinner() throws Exception {
        seedRevision(
                "workspace-a", "source-a", "revision-a",
                "PREVIEW_READY", "PARTIAL", "PENDING",
                BLOCK_DIGEST, OMISSIONS_DIGEST);
        PartialAcceptanceCommand first = command(
                "source-a", "revision-a", BLOCK_DIGEST, OMISSIONS_DIGEST, "accept-key-a");
        PartialAcceptanceCommand second = command(
                "source-a", "revision-a", BLOCK_DIGEST, OMISSIONS_DIGEST, "accept-key-b");

        List<Object> outcomes = race(
                () -> service.accept(CONTEXT, first),
                () -> service.accept(CONTEXT, second));

        assertThat(outcomes.stream()
                        .filter(PartialAcceptanceService.Result.class::isInstance)
                        .count())
                .isEqualTo(1);
        assertThat(outcomes.stream()
                        .filter(PartialAcceptanceService.PartialAcceptanceException.class::isInstance)
                        .map(PartialAcceptanceService.PartialAcceptanceException.class::cast)
                        .map(PartialAcceptanceService.PartialAcceptanceException::code))
                .containsExactly(PartialAcceptanceService.ErrorCode.PARTIAL_ACCEPTANCE_CONFLICT);
        AcceptanceFacts stored = acceptanceFacts("revision-a");
        assertThat(stored.status()).isEqualTo("ACCEPTED");
        assertThat(stored.acceptedAt()).isEqualTo(ACCEPTED_AT);
        assertThat(stored.actorId()).isEqualTo("actor-a");
        assertThat(stored.idempotencyKey()).isIn("accept-key-a", "accept-key-b");
    }

    @Test
    void sqlFailureRollsBackWithoutLeavingAnAcceptanceFact() throws Exception {
        seedRevision(
                "workspace-a", "source-a", "revision-a",
                "PREVIEW_READY", "PARTIAL", "PENDING",
                BLOCK_DIGEST, OMISSIONS_DIGEST);
        update("""
                alter table source_processing_revision
                add constraint test_i11_reject_actor
                check (partial_accepted_by is null or partial_accepted_by <> 'actor-a')
                """);
        try {
            assertRejected(
                    CONTEXT,
                    command("source-a", "revision-a", BLOCK_DIGEST,
                            OMISSIONS_DIGEST, "accept-key-a"),
                    PartialAcceptanceService.ErrorCode.CONCURRENT_COMPLETION_CONFLICT,
                    "source-a", "revision-a");
            assertThat(acceptanceFacts("revision-a")).isEqualTo(new AcceptanceFacts(
                    "PENDING", null, null, null));
        } finally {
            update("""
                    alter table source_processing_revision
                    drop constraint if exists test_i11_reject_actor
                    """);
        }
    }

    private static void assertRejected(
            TrustedRequestContext context,
            PartialAcceptanceCommand command,
            PartialAcceptanceService.ErrorCode code,
            String sourceId,
            String revisionId) {
        assertThatThrownBy(() -> service.accept(context, command))
                .isInstanceOfSatisfying(
                        PartialAcceptanceService.PartialAcceptanceException.class,
                        error -> {
                            assertThat(error.code()).isEqualTo(code);
                            assertThat(error.sourceDocumentId()).isEqualTo(sourceId);
                            assertThat(error.sourceProcessingRevisionId()).isEqualTo(revisionId);
                        });
    }

    private static List<Object> race(Callable<Object> first, Callable<Object> second)
            throws Exception {
        CountDownLatch ready = new CountDownLatch(2);
        CountDownLatch start = new CountDownLatch(1);
        try (var executor = Executors.newFixedThreadPool(2)) {
            List<java.util.concurrent.Future<Object>> futures = List.of(
                    executor.submit(racingCall(ready, start, first)),
                    executor.submit(racingCall(ready, start, second)));
            assertThat(ready.await(5, java.util.concurrent.TimeUnit.SECONDS)).isTrue();
            start.countDown();
            return futures.stream().map(future -> {
                try {
                    return future.get();
                } catch (Exception failure) {
                    throw new AssertionError(failure);
                }
            }).toList();
        }
    }

    private static Callable<Object> racingCall(
            CountDownLatch ready, CountDownLatch start, Callable<Object> call) {
        return () -> {
            ready.countDown();
            start.await();
            try {
                return call.call();
            } catch (PartialAcceptanceService.PartialAcceptanceException rejection) {
                return rejection;
            }
        };
    }

    private static PartialAcceptanceCommand command(
            String sourceId,
            String revisionId,
            String blockDigest,
            String omissionsDigest,
            String idempotencyKey) {
        return new PartialAcceptanceCommand(
                sourceId, revisionId, blockDigest, omissionsDigest,
                idempotencyKey, "ACCEPT_PARTIAL");
    }

    private static void seedRevision(
            String workspaceId,
            String sourceId,
            String revisionId,
            String revisionStatus,
            String parseCompleteness,
            String acceptanceStatus,
            String blockDigest,
            String omissionsDigest) throws SQLException {
        String contentHash = SourceHash.sha256(sourceId.getBytes(StandardCharsets.UTF_8)).value();
        update("""
                insert into source_binary(
                  source_binary_id, content_sha256, byte_length, media_type,
                  binary_location, created_at)
                values (?, ?, 1, 'application/test', 'cas:test', ?)
                """, "binary-" + sourceId, contentHash, ACCEPTED_AT.minusSeconds(2));
        update("""
                insert into source_document(
                  source_document_id, workspace_id, source_binary_id,
                  original_file_name, media_type, byte_length, content_sha256,
                  received_at, idempotency_key, validation_status)
                values (?, ?, ?, 'source.docx', 'application/test', 1, ?, ?, ?, 'ACCEPTED')
                """, sourceId, workspaceId, "binary-" + sourceId, contentHash,
                ACCEPTED_AT.minusSeconds(2), "upload-" + sourceId);
        update("""
                insert into source_processing_revision(
                  source_processing_revision_id, source_document_id, content_sha256,
                  parser_profile_version, revision_status, started_at, completed_at,
                  published_digest, omissions_digest, parse_completeness,
                  partial_acceptance_status)
                values (?, ?, ?, 'parser-v1', ?, ?, ?, ?, ?, ?, ?)
                """, revisionId, sourceId, contentHash, revisionStatus,
                ACCEPTED_AT.minusSeconds(2), ACCEPTED_AT.minusSeconds(1),
                blockDigest, omissionsDigest, parseCompleteness, acceptanceStatus);
    }

    private static AcceptanceFacts acceptanceFacts(String revisionId) throws SQLException {
        try (Connection connection = dataSource.getConnection();
                PreparedStatement statement = connection.prepareStatement("""
                        select partial_acceptance_status, partial_accepted_at,
                               partial_accepted_by, partial_acceptance_idempotency_key
                        from source_processing_revision
                        where source_processing_revision_id = ?
                        """)) {
            statement.setString(1, revisionId);
            try (ResultSet result = statement.executeQuery()) {
                assertThat(result.next()).isTrue();
                return new AcceptanceFacts(
                        result.getString(1),
                        result.getTimestamp(2) == null ? null : result.getTimestamp(2).toInstant(),
                        result.getString(3), result.getString(4));
            }
        }
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

    private record AcceptanceFacts(
            String status, Instant acceptedAt, String actorId, String idempotencyKey) {}
}
