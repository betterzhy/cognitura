package io.cognitura.source.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.github.dockerjava.api.exception.NotFoundException;
import io.cognitura.source.application.processing.AttemptFence;
import io.cognitura.source.application.processing.AttemptLease;
import io.cognitura.source.application.processing.BlockSetDigest;
import io.cognitura.source.application.processing.CandidateBlockSet;
import io.cognitura.source.application.processing.ProcessingAttempt;
import io.cognitura.source.application.processing.ProcessingPublicationPort;
import io.cognitura.source.application.processing.ProcessingPublicationService;
import io.cognitura.source.docx.text.DocumentBlockCandidate;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
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

class JdbcProcessingPublicationPortIntegrationTest {

    private static final String POSTGRES_IMAGE =
            "postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a";
    private static final String SOURCE_ID = "source-document-a";
    private static final String CONTENT_HASH = "a".repeat(64);
    private static final String PROFILE = "docx-v1";
    private static final Instant STARTED = Instant.parse("2026-08-22T03:00:00Z");
    private static final Instant CLAIM_DEADLINE = STARTED.plusSeconds(30);
    private static final Instant RUNNING_LEASE = CLAIM_DEADLINE.plusSeconds(60);

    private static PostgreSQLContainer postgres;
    private static DataSource dataSource;
    private static String containerId;

    private JdbcProcessingPublicationPort port;
    private ProcessingPublicationService service;

    @BeforeAll
    static void startRealPostgres18AndMigrate() throws Exception {
        String suffix = UUID.randomUUID().toString().replace("-", "");
        DockerImageName image = DockerImageName.parse(POSTGRES_IMAGE)
                .asCompatibleSubstituteFor("postgres");
        postgres = new PostgreSQLContainer(image)
                .withDatabaseName("cognitura_i09_processing_" + suffix)
                .withUsername("i09_processing_" + suffix)
                .withPassword(UUID.randomUUID().toString() + UUID.randomUUID())
                .withReuse(false);
        postgres.start();
        containerId = postgres.getContainerId();
        dataSource = new DriverManagerDataSource(
                postgres.getJdbcUrl(), postgres.getUsername(), postgres.getPassword());

        try (Connection connection = dataSource.getConnection();
                Statement statement = connection.createStatement();
                ResultSet result = statement.executeQuery(
                        "select current_setting('server_version_num'), current_database()")) {
            assertThat(result.next()).isTrue();
            assertThat(result.getString(1)).startsWith("18");
            assertThat(result.getString(2)).isEqualTo(postgres.getDatabaseName());
        }
        Flyway flyway = Flyway.configure().dataSource(dataSource).load();
        assertThat(flyway.migrate().migrationsExecuted).isEqualTo(2);
        assertThat(flyway.migrate().migrationsExecuted).isZero();

        System.out.println("W1I09ProcessingContainerId = " + containerId);
        System.out.println("W1I09ProcessingImage = " + POSTGRES_IMAGE);
        System.out.println("W1I09ProcessingDatabaseName = " + postgres.getDatabaseName());
    }

    @AfterAll
    static void stopAndProveRemoval() {
        if (postgres == null) return;
        postgres.close();
        assertThatThrownBy(() -> DockerClientFactory.instance()
                        .client()
                        .inspectContainerCmd(containerId)
                        .exec())
                .isInstanceOf(NotFoundException.class);
        System.out.println("W1I09ProcessingContainerRemoval = PASS");
    }

    @BeforeEach
    void resetAndSeedAcceptedSource() throws Exception {
        try (Connection connection = dataSource.getConnection();
                Statement statement = connection.createStatement()) {
            statement.execute("""
                    truncate table
                      source_processing_rejection_event,
                      source_generation_stage_record,
                      source_reference_alias,
                      source_document_block,
                      source_processing_staged_block,
                      source_processing_staged_set,
                      source_processing_attempt,
                      source_processing_revision,
                      source_document,
                      source_binary
                    restart identity cascade
                    """);
            statement.execute("""
                    insert into source_binary(
                      source_binary_id, content_sha256, byte_length,
                      media_type, binary_location, created_at)
                    values (
                      'source-binary-a', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                      10, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                      'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                      timestamptz '2026-08-22 03:00:00+00')
                    """);
            statement.execute("""
                    insert into source_document(
                      source_document_id, workspace_id, source_binary_id, original_file_name,
                      media_type, byte_length, content_sha256, received_at,
                      idempotency_key, validation_status)
                    values (
                      'source-document-a', 'workspace-a', 'source-binary-a', 'source.docx',
                      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                      10, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                      timestamptz '2026-08-22 03:00:00+00', 'upload-a', 'ACCEPTED')
                    """);
        }
        port = new JdbcProcessingPublicationPort(dataSource);
        service = new ProcessingPublicationService(port);
    }

    @Test
    void initialLeaseTimeoutAndRetryPersistCanonicalGenerationFacts() {
        ProcessingAttempt first = service.beginInitial(
                SOURCE_ID, "revision-a", "attempt-a", CONTENT_HASH, PROFILE,
                STARTED, CLAIM_DEADLINE);
        assertThat(first.attemptNumber()).isEqualTo(1);
        assertThat(first.generation()).isEqualTo(1);
        assertThat(first.fencingToken())
                .isEqualTo(AttemptFence.fencingTokenFor("revision-a", 1));

        service.claim(first.fence(), CLAIM_DEADLINE, RUNNING_LEASE, STARTED.plusSeconds(1));
        Instant extended = RUNNING_LEASE.plusSeconds(60);
        service.heartbeat(
                first.fence(), RUNNING_LEASE, extended, STARTED.plusSeconds(10));
        assertThat(queryInstant(
                "select heartbeat_at from source_processing_attempt where attempt_id = 'attempt-a'"))
                .isEqualTo(STARTED.plusSeconds(10));
        service.timeout(
                first.fence(), ProcessingAttempt.Status.RUNNING,
                extended, extended.plusSeconds(1));

        ProcessingAttempt retry = service.retry(
                SOURCE_ID, "revision-a", "attempt-b", CONTENT_HASH, PROFILE,
                extended.plusSeconds(2), extended.plusSeconds(32));
        assertThat(retry.attemptNumber()).isEqualTo(2);
        assertThat(retry.generation()).isEqualTo(2);
        assertThat(queryLong("select count(*) from source_generation_stage_record"))
                .isEqualTo(1);
    }

    @Test
    void concurrentInitialBeginCreatesOneRevisionAndOneActiveAttempt() throws Exception {
        ExecutorService executor = Executors.newFixedThreadPool(2);
        CountDownLatch ready = new CountDownLatch(2);
        CountDownLatch start = new CountDownLatch(1);
        try {
            Future<ProcessingPublicationPort.Outcome> first = executor.submit(
                    () -> beginOutcome("attempt-a", ready, start));
            Future<ProcessingPublicationPort.Outcome> second = executor.submit(
                    () -> beginOutcome("attempt-b", ready, start));
            ready.await();
            start.countDown();
            assertThat(List.of(first.get(), second.get()))
                    .containsExactlyInAnyOrder(
                            ProcessingPublicationPort.Outcome.APPLIED,
                            ProcessingPublicationPort.Outcome.ACTIVE_ATTEMPT_EXISTS);
            assertThat(queryLong("select count(*) from source_processing_revision")).isEqualTo(1);
            assertThat(queryLong("select count(*) from source_processing_attempt")).isEqualTo(1);
        } finally {
            executor.shutdownNow();
        }
    }

    @Test
    void stagedBlockSetPublishesBlocksAliasesStageRecordAndRevisionAtomically() {
        ProcessingAttempt attempt = beginAndClaim();
        CandidateBlockSet blocks = blockSet();
        service.stage(attempt.fence(), blocks);
        BlockSetDigest digest = service.publish(
                attempt.fence(), blocks, STARTED.plusSeconds(120));

        assertThat(digest).isEqualTo(BlockSetDigest.compute(blocks));
        assertThat(queryLong("select count(*) from source_document_block")).isEqualTo(2);
        assertThat(queryLong("select count(*) from source_reference_alias")).isEqualTo(2);
        assertThat(queryText("""
                select revision_status from source_processing_revision
                where source_processing_revision_id = 'revision-a'
                """)).isEqualTo("PARSED");
        assertThat(queryLong("select count(*) from source_generation_stage_record")).isEqualTo(1);

        assertThat(port.publish(
                        attempt.fence(), blocks, digest, STARTED.plusSeconds(121)))
                .isEqualTo(ProcessingPublicationPort.Outcome.ALREADY_PUBLISHED);
        assertThat(queryLong("select count(*) from source_processing_rejection_event"))
                .isEqualTo(1);
    }

    @Test
    void aliasCollisionRollsBackWholePublication() throws Exception {
        ProcessingAttempt attempt = beginAndClaim();
        CandidateBlockSet blocks = blockSet();
        service.stage(attempt.fence(), blocks);
        try (Connection connection = dataSource.getConnection();
                PreparedStatement statement = connection.prepareStatement("""
                        insert into source_reference_alias(
                          alias_identifier, source_document_id,
                          source_processing_revision_id, document_block_id)
                        values (?, 'source-document-other', 'revision-a', 'block-other')
                        """)) {
            statement.setString(1, blocks.blocks().getFirst().documentBlockAlias());
            statement.executeUpdate();
        }

        assertThatThrownBy(() -> service.publish(
                        attempt.fence(), blocks, STARTED.plusSeconds(120)))
                .isInstanceOf(ProcessingPublicationPort.StorageException.class)
                .hasMessageStartingWith("PROCESSING_PUBLICATION_STORAGE_FAILURE");
        assertThat(queryLong("select count(*) from source_document_block")).isZero();
        assertThat(queryLong("select count(*) from source_generation_stage_record")).isZero();
        assertThat(queryText("""
                select attempt_status from source_processing_attempt
                where attempt_id = 'attempt-a'
                """)).isEqualTo("RUNNING");
    }

    @Test
    void foreignBlockSetAndLateCompletionFailClosedWithAuditOnly() {
        ProcessingAttempt attempt = beginAndClaim();
        CandidateBlockSet foreign = blockSet(
                "source-document-other", "revision-other", "attempt-other");
        assertThat(port.stage(attempt.fence(), foreign))
                .isEqualTo(ProcessingPublicationPort.Outcome.BLOCK_SET_MISMATCH);
        assertThat(queryLong("select count(*) from source_processing_staged_set")).isZero();

        service.timeout(
                attempt.fence(), ProcessingAttempt.Status.RUNNING,
                RUNNING_LEASE, RUNNING_LEASE.plusSeconds(1));
        CandidateBlockSet blocks = blockSet();
        assertThat(port.publish(
                        attempt.fence(), blocks, BlockSetDigest.compute(blocks),
                        RUNNING_LEASE.plusSeconds(2)))
                .isEqualTo(ProcessingPublicationPort.Outcome.STALE_FENCE);
        assertThat(queryLong("select count(*) from source_document_block")).isZero();
        assertThat(queryLong("select count(*) from source_processing_rejection_event"))
                .isEqualTo(1);
    }

    @Test
    void publishAndTimeoutRaceHasExactlyOneTerminalWinner() throws Exception {
        ProcessingAttempt attempt = beginAndClaim();
        CandidateBlockSet blocks = blockSet();
        service.stage(attempt.fence(), blocks);
        ExecutorService executor = Executors.newFixedThreadPool(2);
        CountDownLatch start = new CountDownLatch(1);
        try {
            Future<ProcessingPublicationPort.Outcome> publish = executor.submit(() -> {
                start.await();
                return port.publish(
                        attempt.fence(), blocks, BlockSetDigest.compute(blocks),
                        RUNNING_LEASE.plusSeconds(1));
            });
            Future<ProcessingPublicationPort.Outcome> timeout = executor.submit(() -> {
                start.await();
                return port.timeout(
                        attempt.fence(),
                        AttemptLease.timeout(ProcessingAttempt.Status.RUNNING, RUNNING_LEASE),
                        RUNNING_LEASE.plusSeconds(1));
            });
            start.countDown();
            List<ProcessingPublicationPort.Outcome> outcomes = List.of(publish.get(), timeout.get());
            assertThat(outcomes).contains(ProcessingPublicationPort.Outcome.APPLIED);
            assertThat(outcomes.stream()
                    .filter(value -> value == ProcessingPublicationPort.Outcome.APPLIED).count())
                    .isEqualTo(1);
            assertThat(queryLong("select count(*) from source_generation_stage_record"))
                    .isEqualTo(1);
        } finally {
            executor.shutdownNow();
        }
    }

    private ProcessingAttempt beginAndClaim() {
        ProcessingAttempt attempt = service.beginInitial(
                SOURCE_ID, "revision-a", "attempt-a", CONTENT_HASH, PROFILE,
                STARTED, CLAIM_DEADLINE);
        service.claim(attempt.fence(), CLAIM_DEADLINE, RUNNING_LEASE, STARTED.plusSeconds(1));
        return attempt;
    }

    private ProcessingPublicationPort.Outcome beginOutcome(
            String attemptId, CountDownLatch ready, CountDownLatch start) throws Exception {
        ready.countDown();
        start.await();
        return port.beginInitial(new ProcessingPublicationPort.BeginAttempt(
                SOURCE_ID, "revision-a", attemptId, CONTENT_HASH, PROFILE,
                STARTED, CLAIM_DEADLINE)).outcome();
    }

    private static CandidateBlockSet blockSet() {
        return blockSet(SOURCE_ID, "revision-a", "attempt-a");
    }

    private static CandidateBlockSet blockSet(
            String sourceId, String revisionId, String attemptId) {
        return new CandidateBlockSet(
                sourceId,
                revisionId,
                attemptId,
                CandidateBlockSet.ParseCompleteness.COMPLETE,
                CandidateBlockSet.PartialAcceptanceStatus.NOT_APPLICABLE,
                List.of(
                        block("block-a", sourceId, revisionId, attemptId, 0, "first"),
                        block("block-b", sourceId, revisionId, attemptId, 1, "second")),
                List.of());
    }

    private static CandidateBlockSet.Block block(
            String blockId,
            String sourceId,
            String revisionId,
            String attemptId,
            int sourceOrder,
            String payload) {
        DocumentBlockCandidate text = new DocumentBlockCandidate(
                DocumentBlockCandidate.BlockType.PARAGRAPH,
                sourceOrder,
                List.of(),
                "word/document.xml",
                sourceOrder,
                payload,
                null,
                null,
                null);
        return CandidateBlockSet.Block.fromText(
                blockId, sourceId, revisionId, attemptId, text, null);
    }

    private static long queryLong(String sql) {
        try (Connection connection = dataSource.getConnection();
                Statement statement = connection.createStatement();
                ResultSet result = statement.executeQuery(sql)) {
            if (!result.next()) throw new SQLException("QUERY_RESULT_REQUIRED");
            return result.getLong(1);
        } catch (SQLException error) {
            throw new AssertionError(error);
        }
    }

    private static String queryText(String sql) {
        try (Connection connection = dataSource.getConnection();
                Statement statement = connection.createStatement();
                ResultSet result = statement.executeQuery(sql)) {
            if (!result.next()) throw new SQLException("QUERY_RESULT_REQUIRED");
            return result.getString(1);
        } catch (SQLException error) {
            throw new AssertionError(error);
        }
    }

    private static Instant queryInstant(String sql) {
        try (Connection connection = dataSource.getConnection();
                Statement statement = connection.createStatement();
                ResultSet result = statement.executeQuery(sql)) {
            if (!result.next()) throw new SQLException("QUERY_RESULT_REQUIRED");
            return result.getTimestamp(1).toInstant();
        } catch (SQLException error) {
            throw new AssertionError(error);
        }
    }
}
