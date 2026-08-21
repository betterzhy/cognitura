package io.cognitura.source.application.command;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.cognitura.source.domain.SourceHash;
import io.cognitura.source.persistence.SourceCommandMapper;
import io.cognitura.source.persistence.SourceCommandPersistenceAdapter;
import io.cognitura.source.storage.LocalContentAddressedSourceBinaryStore;
import java.io.ByteArrayInputStream;
import java.lang.reflect.Field;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Arrays;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Supplier;
import javax.sql.DataSource;
import org.apache.ibatis.mapping.Environment;
import org.apache.ibatis.session.Configuration;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.apache.ibatis.transaction.jdbc.JdbcTransactionFactory;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.jdbc.datasource.init.ScriptUtils;
import org.testcontainers.DockerClientFactory;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

class SourceUploadCommandIntegrationTest {

    private static final String POSTGRES_IMAGE =
            "postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a";
    private static final String DOCX =
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
    private static final Instant RECEIVED_AT = Instant.parse("2026-08-22T01:02:03.123456Z");
    private static final Clock CLOCK = Clock.fixed(RECEIVED_AT, ZoneOffset.UTC);
    private static final TrustedRequestContext CONTEXT =
            new TrustedRequestContext("workspace-a", "actor-a");

    private static PostgreSQLContainer postgres;
    private static DataSource dataSource;
    private static SqlSessionFactory sqlSessionFactory;
    private static String containerId;

    @TempDir
    Path temporaryDirectory;

    @BeforeAll
    static void startIsolatedPostgres18() throws Exception {
        String suffix = UUID.randomUUID().toString().replace("-", "");
        DockerImageName image = DockerImageName.parse(POSTGRES_IMAGE)
                .asCompatibleSubstituteFor("postgres");
        postgres = new PostgreSQLContainer(image)
                .withDatabaseName("cognitura_i09_" + suffix)
                .withUsername("i09_" + suffix)
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

        dataSource = new DriverManagerDataSource(
                postgres.getJdbcUrl(), postgres.getUsername(), postgres.getPassword());
        Flyway flyway = Flyway.configure().dataSource(dataSource).load();
        assertThat(flyway.migrate().migrationsExecuted).isEqualTo(2);

        Configuration configuration = new Configuration(new Environment(
                "w1-i09-isolated-postgres", new JdbcTransactionFactory(), dataSource));
        configuration.addMapper(SourceCommandMapper.class);
        sqlSessionFactory = new SqlSessionFactoryBuilder().build(configuration);

        System.out.println("W1I09UploadContainerId = " + containerId);
        System.out.println("W1I09UploadImage = " + POSTGRES_IMAGE);
        System.out.println("W1I09UploadDatabaseName = " + postgres.getDatabaseName());
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
        System.out.println("W1I09UploadContainerRemoval = PASS");
    }

    @BeforeEach
    void resetFacts() throws SQLException {
        try (Connection connection = dataSource.getConnection()) {
            ScriptUtils.executeSqlScript(
                    connection, new ClassPathResource("db/source-command-runtime-fixture.sql"));
        }
    }

    @Test
    void persistsNewUploadReplaysExactKeyAndReusesDigestAcrossDocuments() throws Exception {
        byte[] contentA = bytes("source-a", 48_000);
        byte[] contentB = bytes("source-b", 32_000);
        AtomicInteger ids = new AtomicInteger();
        SourceCommandService service = service(
                () -> "source-document-" + ids.incrementAndGet(), "cas-primary");

        SourceCommandService.UploadResult created =
                service.upload(CONTEXT, command("key-a", "a.docx", contentA));
        SourceCommandService.UploadResult replay =
                service.upload(CONTEXT, command("key-a", "replay-name.docx", contentA));

        assertThat(created.created()).isTrue();
        assertThat(replay.created()).isFalse();
        assertThat(replay.sourceDocumentId()).isEqualTo(created.sourceDocumentId());
        assertThat(replay.contentSha256()).isEqualTo(created.contentSha256());
        assertThat(replay.receivedAt()).isEqualTo(created.receivedAt());

        assertThatThrownBy(() -> service.upload(
                        CONTEXT, command("key-a", "conflict.docx", contentB)))
                .isInstanceOf(SourceCommandException.class)
                .extracting(error -> ((SourceCommandException) error).code())
                .isEqualTo(SourceCommandException.Code.IDEMPOTENCY_CONFLICT);

        SourceCommandService.UploadResult secondDocument =
                service.upload(CONTEXT, command("key-b", "b.docx", contentA));
        assertThat(secondDocument.created()).isTrue();
        assertThat(secondDocument.sourceDocumentId()).isNotEqualTo(created.sourceDocumentId());
        assertThat(count("source_document")).isEqualTo(2);
        assertThat(count("source_binary")).isEqualTo(1);
        assertThat(countByHash("source_binary", SourceHash.sha256(contentB))).isZero();
    }

    @Test
    void declarationFailureCreatesNeitherCasTargetNorDatabaseFacts() throws Exception {
        byte[] content = bytes("declared", 16_000);
        SourceCommandService service = service(() -> "source-document-declared", "cas-declared");
        SourceCommandService.UploadCommand mismatched = new SourceCommandService.UploadCommand(
                "declared.docx",
                DOCX,
                new ByteArrayInputStream(content),
                content.length + 1L,
                SourceHash.sha256(content),
                "key-declared");

        assertThatThrownBy(() -> service.upload(CONTEXT, mismatched))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("SOURCE_BINARY_DECLARED_LENGTH_MISMATCH");
        assertThat(count("source_document")).isZero();
        assertThat(count("source_binary")).isZero();
        assertThat(Files.walk(temporaryDirectory)
                .filter(Files::isRegularFile)
                .toList()).isEmpty();
    }

    @Test
    void concurrentSameKeyCreatesOneDocumentAndOneDeterministicReplay() throws Exception {
        byte[] content = bytes("concurrent", 96_000);
        AtomicInteger ids = new AtomicInteger();
        SourceCommandService service = service(
                () -> "source-document-concurrent-" + ids.incrementAndGet(), "cas-concurrent");
        CyclicBarrier start = new CyclicBarrier(2);
        Callable<SourceCommandService.UploadResult> upload = () -> {
            start.await(10, TimeUnit.SECONDS);
            return service.upload(CONTEXT, command("key-concurrent", "same.docx", content));
        };

        try (var executor = Executors.newFixedThreadPool(2)) {
            var first = executor.submit(upload);
            var second = executor.submit(upload);
            SourceCommandService.UploadResult firstResult = first.get(30, TimeUnit.SECONDS);
            SourceCommandService.UploadResult secondResult = second.get(30, TimeUnit.SECONDS);

            assertThat(Set.of(firstResult.created(), secondResult.created()))
                    .containsExactlyInAnyOrder(true, false);
            assertThat(firstResult.sourceDocumentId())
                    .isEqualTo(secondResult.sourceDocumentId());
        }
        assertThat(count("source_document")).isEqualTo(1);
        assertThat(count("source_binary")).isEqualTo(1);
    }

    @Test
    void databaseRollbackLeavesOnlyAnImmutableHarmlessCasOrphan() throws Exception {
        byte[] firstBytes = bytes("first", 8_000);
        byte[] orphanBytes = bytes("orphan", 8_001);
        SourceCommandService service = service(() -> "source-document-fixed", "cas-rollback");
        service.upload(CONTEXT, command("key-first", "first.docx", firstBytes));

        assertThatThrownBy(() -> service.upload(
                        CONTEXT, command("key-orphan", "orphan.docx", orphanBytes)))
                .isInstanceOf(SourceCommandException.class)
                .extracting(error -> ((SourceCommandException) error).code())
                .isEqualTo(SourceCommandException.Code.PERSISTENCE_FAILURE);

        SourceHash orphanHash = SourceHash.sha256(orphanBytes);
        assertThat(count("source_document")).isEqualTo(1);
        assertThat(count("source_binary")).isEqualTo(1);
        assertThat(countByHash("source_binary", orphanHash)).isZero();
        Path orphan = casTarget("cas-rollback", orphanHash);
        assertThat(Files.readAllBytes(orphan)).containsExactly(orphanBytes);

        Files.setLastModifiedTime(orphan, java.nio.file.attribute.FileTime.fromMillis(123_000));
        assertThatThrownBy(() -> service.upload(
                        CONTEXT, command("key-orphan", "orphan.docx", orphanBytes)))
                .isInstanceOf(SourceCommandException.class);
        assertThat(Files.getLastModifiedTime(orphan).toMillis()).isEqualTo(123_000);
        assertThat(Files.readAllBytes(orphan)).containsExactly(orphanBytes);
    }

    @Test
    void commandBoundaryRetainsNoFullUploadByteArray() {
        assertThat(Arrays.stream(SourceCommandService.class.getDeclaredFields())
                .map(Field::getType)
                .noneMatch(byte[].class::equals)).isTrue();
        assertThat(Arrays.stream(SourceCommandService.UploadCommand.class.getRecordComponents())
                .map(component -> component.getType())
                .noneMatch(byte[].class::equals)).isTrue();
        assertThat(SourceCommandService.UploadCommand.class.getRecordComponents())
                .anySatisfy(component -> assertThat(component.getType())
                        .isEqualTo(java.io.InputStream.class));
    }

    private SourceCommandService service(Supplier<String> ids, String casDirectory) {
        var store = new LocalContentAddressedSourceBinaryStore(
                temporaryDirectory.resolve(casDirectory), 2_000_000, Set.of(DOCX));
        var persistence = new SourceCommandPersistenceAdapter(sqlSessionFactory);
        return new SourceCommandService(store, persistence, ids, CLOCK);
    }

    private static SourceCommandService.UploadCommand command(
            String key, String fileName, byte[] content) {
        return new SourceCommandService.UploadCommand(
                fileName,
                DOCX,
                new ByteArrayInputStream(content),
                content.length,
                SourceHash.sha256(content),
                key);
    }

    private Path casTarget(String casDirectory, SourceHash hash) {
        return temporaryDirectory.resolve(casDirectory).resolve("sha256")
                .resolve(hash.value().substring(0, 2))
                .resolve(hash.value().substring(2, 4))
                .resolve(hash.value());
    }

    private static byte[] bytes(String seed, int length) {
        byte[] seedBytes = seed.getBytes(StandardCharsets.UTF_8);
        byte[] result = new byte[length];
        for (int index = 0; index < result.length; index++) {
            result[index] = (byte) (seedBytes[index % seedBytes.length] + index * 17);
        }
        return result;
    }

    private static long count(String table) throws SQLException {
        try (Connection connection = dataSource.getConnection();
                Statement statement = connection.createStatement();
                var result = statement.executeQuery("select count(*) from " + table)) {
            assertThat(result.next()).isTrue();
            return result.getLong(1);
        }
    }

    private static long countByHash(String table, SourceHash hash) throws SQLException {
        try (Connection connection = dataSource.getConnection();
                var statement = connection.prepareStatement(
                        "select count(*) from " + table + " where content_sha256 = ?")) {
            statement.setString(1, hash.value());
            try (var result = statement.executeQuery()) {
                assertThat(result.next()).isTrue();
                return result.getLong(1);
            }
        }
    }
}
