package io.cognitura.source.api.query;

import static org.hamcrest.Matchers.hasSize;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import io.cognitura.source.application.command.TrustedRequestContext;
import io.cognitura.source.application.command.TrustedRequestContextProvider;
import io.cognitura.source.application.processing.BlockSetDigest;
import io.cognitura.source.application.processing.CandidateBlockSet;
import io.cognitura.source.docx.image.ExternalRelationshipLiteral;
import io.cognitura.source.docx.image.ImageAnchor;
import io.cognitura.source.docx.image.ImageRelationshipProjector;
import io.cognitura.source.docx.security.DocxRelationshipClassifier;
import io.cognitura.source.docx.table.TableBlockCandidate;
import io.cognitura.source.docx.table.TableCellCandidate;
import io.cognitura.source.docx.table.TableTextEvidence;
import io.cognitura.source.docx.text.DocumentBlockCandidate;
import io.cognitura.source.docx.text.ListSemantics;
import io.cognitura.source.domain.SourceHash;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;
import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.testcontainers.DockerClientFactory;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

class SourcePreviewControllerTest {

    private static final String POSTGRES_IMAGE =
            "postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a";
    private static final byte[] CURSOR_KEY =
            "preview-cursor-key-32-bytes-long!".getBytes(StandardCharsets.UTF_8);
    private static final String CONTENT_HASH = "a".repeat(64);
    private static final TrustedRequestContext CONTEXT =
            new TrustedRequestContext("workspace-a", "actor-a");

    private static PostgreSQLContainer postgres;
    private static DataSource dataSource;
    private static String containerId;

    private MockMvc mvc;

    @BeforeAll
    static void startIsolatedPostgres18() throws Exception {
        String suffix = UUID.randomUUID().toString().replace("-", "");
        DockerImageName image = DockerImageName.parse(POSTGRES_IMAGE)
                .asCompatibleSubstituteFor("postgres");
        postgres = new PostgreSQLContainer(image)
                .withDatabaseName("cognitura_i10_" + suffix)
                .withUsername("i10_" + suffix)
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
        assertThat(Flyway.configure().dataSource(dataSource).load().migrate().migrationsExecuted)
                .isEqualTo(2);
        System.out.println("W1I10PreviewContainerId = " + containerId);
        System.out.println("W1I10PreviewImage = " + POSTGRES_IMAGE);
        System.out.println("W1I10PreviewDatabaseName = " + postgres.getDatabaseName());
    }

    @AfterAll
    static void stopAndProveRemoval() {
        if (postgres == null) return;
        postgres.close();
        assertThatThrownBy(() -> DockerClientFactory.instance()
                        .client().inspectContainerCmd(containerId).exec())
                .isInstanceOf(com.github.dockerjava.api.exception.NotFoundException.class);
        System.out.println("W1I10PreviewContainerRemoval = PASS");
    }

    @BeforeEach
    void resetFactsAndController() throws SQLException {
        try (Connection connection = dataSource.getConnection();
                Statement statement = connection.createStatement()) {
            statement.execute("truncate table source_binary cascade");
        }
        SourcePreviewQuery query = new SourcePreviewQuery(
                dataSource, new SourcePreviewCursor(CURSOR_KEY));
        TrustedRequestContextProvider contexts = () -> CONTEXT;
        mvc = MockMvcBuilders.standaloneSetup(new SourcePreviewController(query, contexts))
                .setControllerAdvice(new SourcePreviewErrorAdvice())
                .build();
    }

    @Test
    void readsTypedExactRevisionPagesFromPublishedPostgresFacts() throws Exception {
        CandidateBlockSet blockSet = completeBlockSet("source-a", "revision-a", "attempt-a");
        publish("workspace-a", "source-a", "revision-a", "profile-a", blockSet);

        String first = mvc.perform(get(
                        "/api/v1/source-documents/source-a/processing-revisions/revision-a/blocks")
                        .param("limit", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.sourceDocumentId").value("source-a"))
                .andExpect(jsonPath("$.sourceProcessingRevisionId").value("revision-a"))
                .andExpect(jsonPath("$.parseCompleteness").value("COMPLETE"))
                .andExpect(jsonPath("$.incomplete").value(false))
                .andExpect(jsonPath("$.omissions", hasSize(0)))
                .andExpect(jsonPath("$.items", hasSize(2)))
                .andExpect(jsonPath("$.items[0].blockType").value("HEADING"))
                .andExpect(jsonPath("$.items[0].payload.text").value("Heading"))
                .andExpect(jsonPath("$.items[0].payload.level").value(1))
                .andExpect(jsonPath("$.items[1].blockType").value("PARAGRAPH"))
                .andExpect(jsonPath("$.items[1].payload.text").value("Paragraph"))
                .andExpect(jsonPath("$.items[0].documentBlockRef").value(
                        blockSet.blocks().get(0).documentBlockAlias()))
                .andExpect(jsonPath("$.items[0].sourcePart").doesNotExist())
                .andExpect(jsonPath("$.items[0].attemptId").doesNotExist())
                .andExpect(jsonPath("$.nextCursor").isString())
                .andReturn().getResponse().getContentAsString();

        String after = JsonPath.read(first, "$.nextCursor");
        mvc.perform(get(
                        "/api/v1/source-documents/source-a/processing-revisions/revision-a/blocks")
                        .param("limit", "2")
                        .param("after", after))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)))
                .andExpect(jsonPath("$.items[0].blockType").value("LIST"))
                .andExpect(jsonPath("$.items[0].sourceOrder").value(2))
                .andExpect(jsonPath("$.nextCursor").isEmpty());
    }

    @Test
    void registersTheProductionPreviewEndpointOnlyWhenExplicitlyEnabled() {
        ApplicationContextRunner runner = new ApplicationContextRunner()
                .withBean(DataSource.class, () -> dataSource)
                .withBean(TrustedRequestContextProvider.class, () -> () -> CONTEXT)
                .withUserConfiguration(SourcePreviewQuery.class, SourcePreviewController.class);

        runner.withPropertyValues(
                        "cognitura.source-command.preview-enabled=true",
                        "cognitura.source-command.preview-cursor-signing-key="
                                + Base64.getEncoder().encodeToString(CURSOR_KEY))
                .run(context -> {
                    assertThat(context.getBeansOfType(SourcePreviewQuery.class)).hasSize(1);
                    assertThat(context.getBeansOfType(SourcePreviewController.class)).hasSize(1);
                });
        runner.run(context -> {
            assertThat(context.getBeansOfType(SourcePreviewQuery.class)).isEmpty();
            assertThat(context.getBeansOfType(SourcePreviewController.class)).isEmpty();
        });
    }

    @Test
    void rejectsCrossRevisionTamperedAndInvalidPagination() throws Exception {
        CandidateBlockSet first = completeBlockSet("source-a", "revision-a", "attempt-a");
        CandidateBlockSet second = completeBlockSet("source-a", "revision-b", "attempt-b");
        publish("workspace-a", "source-a", "revision-a", "profile-a", first);
        publishRevisionOnly("source-a", "revision-b", "profile-b", second);
        String token = new SourcePreviewCursor(CURSOR_KEY)
                .encode("workspace-a", "source-a", "revision-a", 0);

        assertPaginationInvalid("revision-b", token);
        assertPaginationInvalid("revision-a", token.substring(0, token.length() - 1) + "A");
        mvc.perform(get(
                        "/api/v1/source-documents/source-a/processing-revisions/revision-a/blocks")
                        .param("limit", "501"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("PAGINATION_INVALID"))
                .andExpect(jsonPath("$.sourceDocumentId").isEmpty())
                .andExpect(jsonPath("$.sourceProcessingRevisionId").isEmpty());
    }

    @Test
    void foreignWorkspaceAndMissingRevisionShareUniform404() throws Exception {
        CandidateBlockSet blockSet = completeBlockSet("source-a", "revision-a", "attempt-a");
        publish("workspace-b", "source-a", "revision-a", "profile-a", blockSet);

        String foreign = mvc.perform(get(
                        "/api/v1/source-documents/source-a/processing-revisions/revision-a/blocks"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.*", hasSize(5)))
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"))
                .andExpect(jsonPath("$.sourceDocumentId").isEmpty())
                .andExpect(jsonPath("$.sourceProcessingRevisionId").isEmpty())
                .andReturn().getResponse().getContentAsString();
        String missing = mvc.perform(get(
                        "/api/v1/source-documents/missing/processing-revisions/missing/blocks"))
                .andExpect(status().isNotFound())
                .andReturn().getResponse().getContentAsString();

        assertThat(missing).isEqualTo(foreign);
    }

    @Test
    void partialPreviewCarriesCompleteOmissionsWarningAndAffectedMarker() throws Exception {
        CandidateBlockSet blockSet = partialBlockSet("source-a", "revision-a", "attempt-a");
        publish("workspace-a", "source-a", "revision-a", "profile-a", blockSet);

        mvc.perform(get(
                        "/api/v1/source-documents/source-a/processing-revisions/revision-a/blocks"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.parseCompleteness").value("PARTIAL"))
                .andExpect(jsonPath("$.incomplete").value(true))
                .andExpect(jsonPath("$.partialWarning").value(
                        "This preview is incomplete. Review all listed omissions before acceptance."))
                .andExpect(jsonPath("$.omissions", hasSize(1)))
                .andExpect(jsonPath("$.omissions[0].errorCode").value("UNSUPPORTED_SAFE_OOXML"))
                .andExpect(jsonPath("$.items[0].affectedByOmission").value(false))
                .andExpect(jsonPath("$.items[1].affectedByOmission").value(true));
    }

    @Test
    void projectsTableAndExternalImageThroughTheTypedWebAllowlist() throws Exception {
        CandidateBlockSet blockSet = tableAndExternalImageBlockSet();
        publish("workspace-a", "source-a", "revision-a", "profile-a", blockSet);

        mvc.perform(get(
                        "/api/v1/source-documents/source-a/processing-revisions/revision-a/blocks"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(3)))
                .andExpect(jsonPath("$.items[0].blockType").value("TABLE"))
                .andExpect(jsonPath("$.items[0].payload.rows[0].cells[0].text")
                        .value("cell"))
                .andExpect(jsonPath("$.items[2].blockType").value("IMAGE"))
                .andExpect(jsonPath("$.items[2].sourceAnchor.anchorKind")
                        .value("PARAGRAPH_INLINE"))
                .andExpect(jsonPath("$.items[2].payload.relationshipMode").value("EXTERNAL"))
                .andExpect(jsonPath("$.items[2].payload.externalTargetLiteralSha256")
                        .value("b".repeat(64)))
                .andExpect(jsonPath("$.items[2].payload.securityDisclosure")
                        .value("EXTERNAL_RELATIONSHIP_NOT_DEREFERENCED"))
                .andExpect(jsonPath("$.items[2].payload.relationshipId").doesNotExist())
                .andExpect(jsonPath("$.items[2].payload.mediaRef").doesNotExist());
    }

    @Test
    void rejectsStaleDigestUnknownPayloadAndDiscontinuousOrder() throws Exception {
        CandidateBlockSet blockSet = completeBlockSet("source-a", "revision-a", "attempt-a");
        publish("workspace-a", "source-a", "revision-a", "profile-a", blockSet);
        update("update source_processing_revision set published_digest = ? "
                + "where source_processing_revision_id = ?", "f".repeat(64), "revision-a");
        assertPreviewFactsInvalid();

        resetFactsAndController();
        publish("workspace-a", "source-a", "revision-a", "profile-a", blockSet);
        byte[] unknownType = replaceFirstAscii(
                blockSet.blocks().get(0).canonicalBytes(), "HEADING", "UNKNOWN");
        update("update source_document_block set canonical_block = ? "
                + "where source_processing_revision_id = ? and source_order = 0",
                unknownType, "revision-a");
        refreshPublishedDigest("revision-a");
        assertPreviewFactsInvalid();

        resetFactsAndController();
        publish("workspace-a", "source-a", "revision-a", "profile-a", blockSet);
        update("update source_document_block set source_order = 9 "
                + "where source_processing_revision_id = ? and source_order = 2", "revision-a");
        assertPreviewFactsInvalid();
    }

    @Test
    void rejectsAliasRetargetMalformedUtf8AndInvalidCompletenessFacts() throws Exception {
        CandidateBlockSet blockSet = completeBlockSet("source-a", "revision-a", "attempt-a");
        publish("workspace-a", "source-a", "revision-a", "profile-a", blockSet);
        update("update source_reference_alias set alias_identifier = ? "
                        + "where source_processing_revision_id = ? and document_block_id = ?",
                "dbr:" + "f".repeat(64), "revision-a", "block-0");
        assertPreviewFactsInvalid();

        resetFactsAndController();
        publish("workspace-a", "source-a", "revision-a", "profile-a", blockSet);
        byte[] malformed = blockSet.blocks().get(0).canonicalBytes();
        malformed[4] = (byte) 0xc3;
        update("update source_document_block set canonical_block = ? "
                        + "where source_processing_revision_id = ? and source_order = 0",
                malformed, "revision-a");
        refreshPublishedDigest("revision-a");
        assertPreviewFactsInvalid();

        resetFactsAndController();
        publish("workspace-a", "source-a", "revision-a", "profile-a", blockSet);
        update("update source_processing_revision set partial_acceptance_status = 'PENDING' "
                + "where source_processing_revision_id = ?", "revision-a");
        assertPreviewFactsInvalid();
    }

    private void assertPaginationInvalid(String revisionId, String after) throws Exception {
        mvc.perform(get(
                        "/api/v1/source-documents/source-a/processing-revisions/"
                                + revisionId + "/blocks")
                        .param("after", after))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("PAGINATION_INVALID"));
    }

    private void assertPreviewFactsInvalid() throws Exception {
        mvc.perform(get(
                        "/api/v1/source-documents/source-a/processing-revisions/revision-a/blocks"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.errorCode").value("PREVIEW_NOT_READY"))
                .andExpect(jsonPath("$.retryable").value(true))
                .andExpect(jsonPath("$.sourceDocumentId").value("source-a"))
                .andExpect(jsonPath("$.sourceProcessingRevisionId").value("revision-a"));
    }

    private static CandidateBlockSet completeBlockSet(
            String sourceDocumentId, String revisionId, String attemptId) {
        return blockSet(sourceDocumentId, revisionId, attemptId,
                CandidateBlockSet.ParseCompleteness.COMPLETE,
                CandidateBlockSet.PartialAcceptanceStatus.NOT_APPLICABLE,
                List.of());
    }

    private static CandidateBlockSet partialBlockSet(
            String sourceDocumentId, String revisionId, String attemptId) {
        return blockSet(sourceDocumentId, revisionId, attemptId,
                CandidateBlockSet.ParseCompleteness.PARTIAL,
                CandidateBlockSet.PartialAcceptanceStatus.PENDING,
                List.of(new CandidateBlockSet.Omission(
                        "word/document.xml", 1, "UNSUPPORTED_SAFE_OOXML",
                        "A safe source structure could not be represented.")));
    }

    private static CandidateBlockSet blockSet(
            String sourceDocumentId,
            String revisionId,
            String attemptId,
            CandidateBlockSet.ParseCompleteness completeness,
            CandidateBlockSet.PartialAcceptanceStatus acceptance,
            List<CandidateBlockSet.Omission> omissions) {
        DocumentBlockCandidate heading = new DocumentBlockCandidate(
                DocumentBlockCandidate.BlockType.HEADING, 0, List.of(),
                "word/document.xml", 0, "Heading", 1, "Heading 1", null);
        DocumentBlockCandidate paragraph = new DocumentBlockCandidate(
                DocumentBlockCandidate.BlockType.PARAGRAPH, 1, List.of("Heading"),
                "word/document.xml", 1, "Paragraph", null, "Normal", null);
        DocumentBlockCandidate list = new DocumentBlockCandidate(
                DocumentBlockCandidate.BlockType.LIST, 2, List.of("Heading"),
                "word/document.xml", 2, "List item", null, "List Paragraph",
                new ListSemantics("list-1", 0, 0, "1."));
        List<CandidateBlockSet.Block> blocks = List.of(
                CandidateBlockSet.Block.fromText(
                        "block-0", sourceDocumentId, revisionId, attemptId, heading),
                CandidateBlockSet.Block.fromText(
                        "block-1", sourceDocumentId, revisionId, attemptId, paragraph),
                CandidateBlockSet.Block.fromText(
                        "block-2", sourceDocumentId, revisionId, attemptId, list));
        return new CandidateBlockSet(
                sourceDocumentId, revisionId, attemptId,
                completeness, acceptance, blocks, omissions);
    }

    private static CandidateBlockSet tableAndExternalImageBlockSet() {
        TableCellCandidate cell = new TableCellCandidate(
                0, 0, 1, 1, "cell", List.of(new TableTextEvidence(0, "cell", List.of())));
        TableBlockCandidate table = new TableBlockCandidate(
                0, "word/document.xml", 0, 1, 1, List.of(cell), List.of());
        CandidateBlockSet.Block tableBlock = CandidateBlockSet.Block.fromTable(
                "block-table", "source-a", "revision-a", "attempt-a", List.of(), table);
        DocumentBlockCandidate paragraph = new DocumentBlockCandidate(
                DocumentBlockCandidate.BlockType.PARAGRAPH, 1, List.of(),
                "word/document.xml", 1, "Before\uFFFCAfter", null, "Normal", null);
        CandidateBlockSet.Block parent = CandidateBlockSet.Block.fromText(
                "block-parent", "source-a", "revision-a", "attempt-a", paragraph);
        String relationshipId = "rId-external";
        String disclosure = "EXTERNAL_RELATIONSHIP_NOT_DEREFERENCED";
        SourceHash targetDigest = SourceHash.ofHex("b".repeat(64));
        SourceHash contentHash = externalImageContentHash(
                relationshipId, targetDigest.value(), disclosure);
        ImageRelationshipProjector.ProjectedImage image =
                new ImageRelationshipProjector.ProjectedImage(
                        2, "word/document.xml", 2,
                        new ImageAnchor(
                                "block-parent", ImageAnchor.AnchorKind.PARAGRAPH_INLINE,
                                6, 0, null, null),
                        relationshipId, DocxRelationshipClassifier.Mode.EXTERNAL,
                        targetDigest, null, null, null, null, disclosure, contentHash);
        CandidateBlockSet.Block imageBlock = CandidateBlockSet.Block.fromImage(
                "block-image", "source-a", "revision-a", "attempt-a", List.of(), image);
        ExternalRelationshipLiteral diagnostic = new ExternalRelationshipLiteral(
                "word/document.xml", relationshipId,
                "http://schemas.openxmlformats.org/officeDocument/2006/relationships/image",
                DocxRelationshipClassifier.Mode.EXTERNAL, targetDigest, disclosure);
        return new CandidateBlockSet(
                "source-a", "revision-a", "attempt-a",
                CandidateBlockSet.ParseCompleteness.COMPLETE,
                CandidateBlockSet.PartialAcceptanceStatus.NOT_APPLICABLE,
                List.of(tableBlock, parent, imageBlock), List.of(), List.of(diagnostic));
    }

    private static SourceHash externalImageContentHash(
            String relationshipId, String targetDigest, String disclosure) {
        StringBuilder canonical = new StringBuilder("IMAGE_PAYLOAD_V1");
        appendImageField(canonical, relationshipId);
        appendImageField(canonical, "EXTERNAL");
        appendImageField(canonical, targetDigest);
        appendImageField(canonical, null);
        appendImageField(canonical, null);
        appendImageField(canonical, null);
        appendImageField(canonical, null);
        appendImageField(canonical, disclosure);
        return SourceHash.sha256(canonical.toString().getBytes(StandardCharsets.UTF_8));
    }

    private static void appendImageField(StringBuilder target, String value) {
        target.append('|');
        if (value == null) {
            target.append("-1:");
        } else {
            target.append(value.getBytes(StandardCharsets.UTF_8).length).append(':').append(value);
        }
    }

    private void publish(
            String workspaceId,
            String sourceDocumentId,
            String revisionId,
            String profile,
            CandidateBlockSet blockSet) throws SQLException {
        execute("""
                insert into source_binary(
                  source_binary_id, content_sha256, byte_length,
                  media_type, binary_location, created_at)
                values (?, ?, ?, ?, ?, ?)
                """, "binary-" + sourceDocumentId, CONTENT_HASH, 1024L,
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                "cas:" + CONTENT_HASH, Instant.parse("2026-08-22T04:00:00Z"));
        execute("""
                insert into source_document(
                  source_document_id, workspace_id, source_binary_id,
                  original_file_name, media_type, byte_length, content_sha256,
                  received_at, idempotency_key, validation_status)
                values (?, ?, ?, ?, ?, ?, ?, ?, ?, 'ACCEPTED')
                """, sourceDocumentId, workspaceId, "binary-" + sourceDocumentId,
                "source.docx",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                1024L, CONTENT_HASH, Instant.parse("2026-08-22T04:00:00Z"),
                "key-" + sourceDocumentId);
        publishRevisionOnly(sourceDocumentId, revisionId, profile, blockSet);
    }

    private void publishRevisionOnly(
            String sourceDocumentId,
            String revisionId,
            String profile,
            CandidateBlockSet blockSet) throws SQLException {
        String blockSetDigest = BlockSetDigest.compute(blockSet).value();
        Instant completedAt = Instant.parse("2026-08-22T04:01:00Z");
        execute("""
                insert into source_processing_revision(
                  source_processing_revision_id, source_document_id, content_sha256,
                  parser_profile_version, revision_status, started_at, completed_at,
                  published_digest, omissions_digest, parse_completeness,
                  partial_acceptance_status)
                values (?, ?, ?, ?, 'PREVIEW_READY', ?, ?, ?, ?, ?, ?)
                """, revisionId, sourceDocumentId, CONTENT_HASH, profile,
                completedAt.minusSeconds(1), completedAt, blockSetDigest,
                blockSet.omissionsDigest().value(), blockSet.parseCompleteness().name(),
                blockSet.partialAcceptanceStatus().name());
        execute("""
                insert into source_processing_attempt(
                  attempt_id, source_processing_revision_id, attempt_number, generation,
                  fencing_token, attempt_status, started_at, completed_at)
                values (?, ?, 1, 1, ?, 'SUCCEEDED', ?, ?)
                """, blockSet.attemptId(), revisionId, "fence-" + revisionId,
                completedAt.minusSeconds(1), completedAt);
        execute("""
                insert into source_processing_staged_set(
                  attempt_id, source_document_id, source_processing_revision_id,
                  parse_completeness, partial_acceptance_status, block_set_digest,
                  omissions_digest, omissions_canonical, revision_diagnostics)
                values (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, blockSet.attemptId(), sourceDocumentId, revisionId,
                blockSet.parseCompleteness().name(),
                blockSet.partialAcceptanceStatus().name(), blockSetDigest,
                blockSet.omissionsDigest().value(), blockSet.canonicalOmissionsBytes(),
                blockSet.canonicalRevisionDiagnosticsBytes());
        for (CandidateBlockSet.Block block : blockSet.blocks()) {
            execute("""
                    insert into source_document_block(
                      source_processing_revision_id, source_order,
                      document_block_id, canonical_block)
                    values (?, ?, ?, ?)
                    """, revisionId, block.sourceOrder(),
                    block.documentBlockId(), block.canonicalBytes());
            execute("""
                    insert into source_reference_alias(
                      alias_identifier, source_document_id,
                      source_processing_revision_id, document_block_id)
                    values (?, ?, ?, ?)
                    """, block.documentBlockAlias(), sourceDocumentId,
                    revisionId, block.documentBlockId());
        }
    }

    private void update(String sql, Object... parameters) throws SQLException {
        execute(sql, parameters);
    }

    private void refreshPublishedDigest(String revisionId) throws SQLException {
        List<byte[]> canonicalBlocks = new ArrayList<>();
        try (Connection connection = dataSource.getConnection();
                PreparedStatement query = connection.prepareStatement("""
                        select canonical_block from source_document_block
                        where source_processing_revision_id = ? order by source_order
                        """)) {
            query.setString(1, revisionId);
            try (ResultSet result = query.executeQuery()) {
                while (result.next()) canonicalBlocks.add(result.getBytes(1));
            }
        }
        try {
            ByteArrayOutputStream bytes = new ByteArrayOutputStream();
            try (DataOutputStream output = new DataOutputStream(bytes)) {
                output.writeInt(canonicalBlocks.size());
                for (byte[] canonical : canonicalBlocks) {
                    output.writeInt(canonical.length);
                    output.write(canonical);
                }
            }
            String digest = sha256(bytes.toByteArray());
            update("update source_processing_revision set published_digest = ? "
                    + "where source_processing_revision_id = ?", digest, revisionId);
            update("update source_processing_staged_set set block_set_digest = ? "
                    + "where source_processing_revision_id = ?", digest, revisionId);
        } catch (IOException error) {
            throw new IllegalStateException("TEST_BLOCK_DIGEST_ENCODING_FAILED", error);
        }
    }

    private void execute(String sql, Object... parameters) throws SQLException {
        try (Connection connection = dataSource.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            for (int index = 0; index < parameters.length; index++) {
                Object value = parameters[index];
                if (value instanceof Instant instant) {
                    statement.setTimestamp(index + 1, Timestamp.from(instant));
                } else {
                    statement.setObject(index + 1, value);
                }
            }
            assertThat(statement.executeUpdate()).isEqualTo(1);
        }
    }

    private static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException("SHA_256_ALGORITHM_UNAVAILABLE", error);
        }
    }

    private static byte[] replaceFirstAscii(byte[] source, String before, String after) {
        byte[] expected = before.getBytes(StandardCharsets.US_ASCII);
        byte[] replacement = after.getBytes(StandardCharsets.US_ASCII);
        assertThat(replacement).hasSameSizeAs(expected);
        byte[] result = source.clone();
        outer:
        for (int offset = 0; offset <= result.length - expected.length; offset++) {
            for (int index = 0; index < expected.length; index++) {
                if (result[offset + index] != expected[index]) continue outer;
            }
            System.arraycopy(replacement, 0, result, offset, replacement.length);
            return result;
        }
        throw new AssertionError("TEST_CANONICAL_TOKEN_NOT_FOUND:" + before);
    }
}
