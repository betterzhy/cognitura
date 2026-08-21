package io.cognitura.source.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.cognitura.source.domain.ProcessingRevision;
import io.cognitura.source.domain.SourceBinary;
import io.cognitura.source.domain.SourceDocument;
import io.cognitura.source.domain.SourceDomainException;
import io.cognitura.source.domain.SourceHash;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.Instant;
import java.util.UUID;
import javax.sql.DataSource;
import org.apache.ibatis.mapping.Environment;
import org.apache.ibatis.session.Configuration;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.apache.ibatis.transaction.jdbc.JdbcTransactionFactory;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.jdbc.datasource.init.ScriptUtils;
import org.testcontainers.DockerClientFactory;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

class SourcePersistenceIntegrationTest {

    private static final String POSTGRES_IMAGE =
            "postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a";
    private static final String DOCX_MEDIA_TYPE =
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
    private static final SourceHash HASH_A = SourceHash.ofHex(
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    private static final SourceHash HASH_B = SourceHash.ofHex(
            "a52d159f262b2c6ddb724a61840befc36eb30c88877a4030b65cbe86298449c9");
    private static final Instant CREATED_AT = Instant.parse("2026-08-21T01:02:03.123456Z");

    private static PostgreSQLContainer postgres;
    private static DataSource dataSource;
    private static SqlSessionFactory sqlSessionFactory;
    private static Flyway flyway;
    private static String containerId;

    @BeforeAll
    static void startIsolatedDatabase() throws Exception {
        String suffix = UUID.randomUUID().toString().replace("-", "");
        DockerImageName image = DockerImageName.parse(POSTGRES_IMAGE)
                .asCompatibleSubstituteFor("postgres");
        postgres = new PostgreSQLContainer(image)
                .withDatabaseName("cognitura_i02_" + suffix)
                .withUsername("i02_" + suffix)
                .withPassword(UUID.randomUUID().toString() + UUID.randomUUID())
                .withReuse(false);
        postgres.start();
        containerId = postgres.getContainerId();

        try (Connection connection = postgres.createConnection("");
                Statement statement = connection.createStatement();
                var result = statement.executeQuery(
                        "select current_setting('server_version_num'), current_database()")) {
            assertThat(result.next()).isTrue();
            assertThat(result.getString(1)).startsWith("18");
            assertThat(result.getString(2)).isEqualTo(postgres.getDatabaseName());
        }

        var configuredDataSource = new DriverManagerDataSource(
                postgres.getJdbcUrl(), postgres.getUsername(), postgres.getPassword());
        dataSource = configuredDataSource;
        flyway = Flyway.configure().dataSource(dataSource).load();
        assertThat(flyway.migrate().migrationsExecuted).isEqualTo(1);

        Configuration configuration = new Configuration(new Environment(
                "w1-i02-isolated-postgres", new JdbcTransactionFactory(), dataSource));
        configuration.addMapper(SourceDocumentMapper.class);
        sqlSessionFactory = new SqlSessionFactoryBuilder().build(configuration);

        System.out.println("W1I02PersistenceContainerId = " + containerId);
        System.out.println("W1I02PersistenceImage = " + POSTGRES_IMAGE);
        System.out.println("W1I02PersistenceDatabaseName = " + postgres.getDatabaseName());
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
        System.out.println("W1I02PersistenceContainerRemoval = PASS");
    }

    @BeforeEach
    void resetFacts() throws SQLException {
        try (Connection connection = dataSource.getConnection()) {
            ScriptUtils.executeSqlScript(
                    connection, new ClassPathResource("db/source-persistence-fixture.sql"));
        }
    }

    @Test
    void appliesMigrationOnceAndRejectsManualReplay() throws Exception {
        assertThat(flyway.migrate().migrationsExecuted).isZero();

        String migration = new ClassPathResource("db/migration/V1__create_source_intake.sql")
                .getContentAsString(StandardCharsets.UTF_8);
        try (Connection connection = dataSource.getConnection();
                Statement statement = connection.createStatement()) {
            assertThatThrownBy(() -> statement.execute(migration))
                    .isInstanceOf(SQLException.class)
                    .hasMessageContaining("source_binary");
        }
    }

    @Test
    void roundTripsAllSourceFactsWithoutLosingInstantPrecision() {
        SourceBinary binary = binary("binary-a", HASH_A);
        SourceDocument document = acceptedDocument("document-a", "workspace-a", binary, "key-a");
        ProcessingRevision revision = ProcessingRevision.restore(
                "revision-a",
                document.sourceDocumentId(),
                document.contentSha256(),
                "docx-parser-v1",
                ProcessingRevision.Status.PARSED,
                null,
                null,
                CREATED_AT,
                CREATED_AT.plusSeconds(9));

        inTransaction(adapter -> {
            adapter.saveBinary(binary);
            adapter.saveDocument(document);
            adapter.saveRevision(revision);

            assertThat(adapter.findBinaryByHash(HASH_A)).contains(binary);
            assertThat(adapter.findDocument("workspace-a", "key-a")).contains(document);
            assertThat(adapter.findRevision("document-a", HASH_A, "docx-parser-v1"))
                    .contains(revision);
        });
    }

    @Test
    void roundTripsDocumentAndRevisionFailureFacts() {
        SourceBinary binary = binary("binary-a", HASH_A);
        SourceDocument rejected = receivedDocument("document-a", "workspace-a", binary, "key-a")
                .beginValidation()
                .reject(SourceDomainException.Code.DOCX_FORMAT_INVALID, "invalid package shape");
        SourceDocument accepted =
                acceptedDocument("document-b", "workspace-a", binary, "key-b");
        ProcessingRevision failed = ProcessingRevision.restore(
                "revision-a",
                accepted.sourceDocumentId(),
                accepted.contentSha256(),
                "docx-parser-v1",
                ProcessingRevision.Status.FAILED_TERMINAL,
                SourceDomainException.Code.PARSER_TERMINAL_FAILURE,
                "deterministic parser failure",
                CREATED_AT,
                CREATED_AT.plusSeconds(9));

        inTransaction(adapter -> {
            adapter.saveBinary(binary);
            adapter.saveDocument(rejected);
            adapter.saveDocument(accepted);
            adapter.saveRevision(failed);

            assertThat(adapter.findDocument("workspace-a", "key-a")).contains(rejected);
            assertThat(adapter.findRevision("document-b", HASH_A, "docx-parser-v1"))
                    .contains(failed);
        });
    }

    @Test
    void scopesIdempotencyLookupAndUniquenessToWorkspace() {
        SourceBinary binary = binary("binary-a", HASH_A);
        SourceDocument alpha = receivedDocument("document-a", "workspace-a", binary, "same-key");
        SourceDocument beta = receivedDocument("document-b", "workspace-b", binary, "same-key");

        inTransaction(adapter -> {
            adapter.saveBinary(binary);
            adapter.saveDocument(alpha);
            adapter.saveDocument(beta);

            assertThat(adapter.findDocument("workspace-a", "same-key")).contains(alpha);
            assertThat(adapter.findDocument("workspace-b", "same-key")).contains(beta);
            assertThat(adapter.findDocument("workspace-c", "same-key")).isEmpty();
        });
    }

    @Test
    void mapsKnownUniqueConstraintsToStablePersistenceErrors() {
        SourceBinary firstBinary = binary("binary-a", HASH_A);
        SourceBinary secondBinary = binary("binary-b", HASH_B);
        SourceDocument first = receivedDocument("document-a", "workspace-a", firstBinary, "key-a");
        SourceDocument conflicting =
                receivedDocument("document-b", "workspace-a", secondBinary, "key-a");

        inTransaction(adapter -> {
            adapter.saveBinary(firstBinary);
            adapter.saveBinary(secondBinary);
            adapter.saveDocument(first);

            assertThatThrownBy(() -> adapter.saveDocument(conflicting))
                    .isInstanceOf(SourcePersistenceAdapter.SourcePersistenceException.class)
                    .extracting(error -> ((SourcePersistenceAdapter.SourcePersistenceException) error)
                            .code())
                    .isEqualTo(SourcePersistenceAdapter.ErrorCode.IDEMPOTENCY_CONFLICT);
        });

        inTransaction(adapter -> {
            adapter.saveBinary(firstBinary);
            SourceBinary duplicateHash = binary("binary-c", HASH_A);
            assertThatThrownBy(() -> adapter.saveBinary(duplicateHash))
                    .isInstanceOf(SourcePersistenceAdapter.SourcePersistenceException.class)
                    .extracting(error -> ((SourcePersistenceAdapter.SourcePersistenceException) error)
                            .code())
                    .isEqualTo(SourcePersistenceAdapter.ErrorCode.SOURCE_BINARY_HASH_CONFLICT);
        });

        inTransaction(adapter -> {
            adapter.saveBinary(firstBinary);
            SourceDocument accepted =
                    acceptedDocument("document-a", "workspace-a", firstBinary, "key-a");
            adapter.saveDocument(accepted);
            ProcessingRevision firstRevision = ProcessingRevision.start(
                    "revision-a", accepted, HASH_A, "docx-parser-v1", CREATED_AT);
            ProcessingRevision duplicateIdentity = ProcessingRevision.start(
                    "revision-b", accepted, HASH_A, "docx-parser-v1", CREATED_AT);
            adapter.saveRevision(firstRevision);

            assertThatThrownBy(() -> adapter.saveRevision(duplicateIdentity))
                    .isInstanceOf(SourcePersistenceAdapter.SourcePersistenceException.class)
                    .extracting(error -> ((SourcePersistenceAdapter.SourcePersistenceException) error)
                            .code())
                    .isEqualTo(
                            SourcePersistenceAdapter.ErrorCode.PROCESSING_REVISION_IDENTITY_CONFLICT);
        });
    }

    @Test
    void rejectsDocumentFactsThatDoNotMatchTheirBinary() {
        SourceBinary binary = binary("binary-a", HASH_A);
        SourceDocument mismatched = new SourceDocument(
                "document-a",
                "workspace-a",
                binary.sourceBinaryId(),
                "mismatch.docx",
                DOCX_MEDIA_TYPE,
                binary.byteLength(),
                HASH_B,
                CREATED_AT,
                "key-a",
                SourceDocument.ValidationStatus.RECEIVED,
                null,
                null);

        inTransaction(adapter -> {
            adapter.saveBinary(binary);
            assertThatThrownBy(() -> adapter.saveDocument(mismatched))
                    .isInstanceOf(SourcePersistenceAdapter.SourcePersistenceException.class)
                    .extracting(error -> ((SourcePersistenceAdapter.SourcePersistenceException) error)
                            .code())
                    .isEqualTo(SourcePersistenceAdapter.ErrorCode.SOURCE_FACT_CONSTRAINT_VIOLATION);
        });
    }

    private void inTransaction(AdapterWork work) {
        try (SqlSession session = sqlSessionFactory.openSession(false)) {
            SourcePersistenceAdapter adapter =
                    new SourcePersistenceAdapter(session.getMapper(SourceDocumentMapper.class));
            work.run(adapter);
            session.commit();
        }
    }

    private static SourceBinary binary(String id, SourceHash hash) {
        return new SourceBinary(id, hash, 3, DOCX_MEDIA_TYPE, "object://source/" + id, CREATED_AT);
    }

    private static SourceDocument receivedDocument(
            String id, String workspaceId, SourceBinary binary, String idempotencyKey) {
        return SourceDocument.received(
                id,
                workspaceId,
                binary.sourceBinaryId(),
                id + ".docx",
                binary.mediaType(),
                binary.byteLength(),
                binary.contentSha256(),
                CREATED_AT,
                idempotencyKey);
    }

    private static SourceDocument acceptedDocument(
            String id, String workspaceId, SourceBinary binary, String idempotencyKey) {
        return receivedDocument(id, workspaceId, binary, idempotencyKey)
                .beginValidation()
                .accept();
    }

    @FunctionalInterface
    private interface AdapterWork {
        void run(SourcePersistenceAdapter adapter);
    }
}
