package io.cognitura.source.application.processing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.github.dockerjava.api.exception.NotFoundException;
import io.cognitura.source.docx.image.ImageAnchor;
import io.cognitura.source.docx.image.ImageRelationshipProjector;
import io.cognitura.source.docx.image.ExternalRelationshipLiteral;
import io.cognitura.source.docx.security.DocxRelationshipClassifier;
import io.cognitura.source.docx.table.TableBlockCandidate;
import io.cognitura.source.docx.table.TableCellCandidate;
import io.cognitura.source.docx.table.TableTextEvidence;
import io.cognitura.source.docx.text.DocumentBlockCandidate;
import io.cognitura.source.domain.SourceDomainException;
import io.cognitura.source.domain.SourceHash;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.testcontainers.DockerClientFactory;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

class ProcessingPublicationIntegrationTest {

    private static final String POSTGRES_IMAGE =
            "postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a";
    private static final Instant STARTED_AT = Instant.parse("2026-08-21T02:00:00Z");
    private static final Instant CLAIM_DEADLINE = STARTED_AT.plusSeconds(30);
    private static final Instant RUNNING_LEASE = CLAIM_DEADLINE.plusSeconds(60);
    private static final String SOURCE_DOCUMENT_ID = "source-document-a";
    private static final String CONTENT_SHA256 = "a".repeat(64);
    private static final String PARSER_PROFILE_VERSION = "docx-v1";

    private static PostgreSQLContainer postgres;
    private static String containerId;

    private TestLocalJdbcProcessingPublicationPort adapter;
    private ProcessingPublicationService service;

    @BeforeAll
    static void startRealPostgres() throws Exception {
        String suffix = UUID.randomUUID().toString().replace("-", "");
        DockerImageName image = DockerImageName.parse(POSTGRES_IMAGE)
                .asCompatibleSubstituteFor("postgres");
        postgres = new PostgreSQLContainer(image)
                .withDatabaseName("cognitura_i07_" + suffix)
                .withUsername("i07_" + suffix)
                .withPassword(UUID.randomUUID().toString() + UUID.randomUUID())
                .withReuse(false);
        postgres.start();
        containerId = postgres.getContainerId();

        try (Connection connection = connection();
                Statement statement = connection.createStatement();
                var result = statement.executeQuery(
                        "select current_setting('server_version_num'), current_database()")) {
            assertThat(result.next()).isTrue();
            assertThat(result.getString(1)).startsWith("18");
            assertThat(result.getString(2)).isEqualTo(postgres.getDatabaseName());
        }
        TestLocalJdbcProcessingPublicationPort.createSchema(connection());
        System.out.println("W1I07PublicationContainerId = " + containerId);
        System.out.println("W1I07PublicationImage = " + POSTGRES_IMAGE);
        System.out.println("W1I07PublicationDatabaseName = " + postgres.getDatabaseName());
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
                .isInstanceOf(NotFoundException.class);
        System.out.println("W1I07PublicationContainerRemoval = PASS");
    }

    @BeforeEach
    void resetDatabase() throws Exception {
        adapter = new TestLocalJdbcProcessingPublicationPort(
                postgres.getJdbcUrl(), postgres.getUsername(), postgres.getPassword());
        adapter.reset();
        service = new ProcessingPublicationService(adapter);
    }

    @Test
    void canonicalBlockSetRequiresContinuousOrderAndDetectsPayloadDrift() {
        assertThatThrownBy(() -> new CandidateBlockSet(
                        SOURCE_DOCUMENT_ID,
                        "revision-a",
                        "attempt-a",
                        CandidateBlockSet.ParseCompleteness.COMPLETE,
                        CandidateBlockSet.PartialAcceptanceStatus.NOT_APPLICABLE,
                        List.of(
                                block("block-a", 0, "PARAGRAPH", "first"),
                                block("block-b", 2, "PARAGRAPH", "second")),
                        List.of()))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("CANDIDATE_BLOCK_SOURCE_ORDER_MUST_BE_CONTINUOUS");

        CandidateBlockSet original = blockSet("second");
        CandidateBlockSet same = blockSet("second");
        CandidateBlockSet drifted = blockSet("changed");

        assertThat(BlockSetDigest.compute(original)).isEqualTo(BlockSetDigest.compute(same));
        assertThat(BlockSetDigest.compute(original).value())
                .isEqualTo("650dbef325ea91333283eec6a26d0548d2c7fc448c1b88755ad6e90340f3e580");
        assertThat(BlockSetDigest.compute(drifted)).isNotEqualTo(BlockSetDigest.compute(original));
        assertThat(original.blocks().getFirst().documentBlockAlias())
                .isEqualTo("dbr:587fd6e4a13ecee166aaee248268fe2d4849201076785728a54553a5c18ea32d");

        CandidateBlockSet.Block foreignScope = block(
                "block-a", "source-document-b", "revision-a", "attempt-a",
                0, "PARAGRAPH", "first", 0, 0);
        assertThatThrownBy(() -> new CandidateBlockSet(
                        SOURCE_DOCUMENT_ID,
                        "revision-a",
                        "attempt-a",
                        CandidateBlockSet.ParseCompleteness.COMPLETE,
                        CandidateBlockSet.PartialAcceptanceStatus.NOT_APPLICABLE,
                        List.of(foreignScope),
                        List.of()))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("CANDIDATE_BLOCK_SCOPE_MISMATCH");

        CandidateBlockSet.Block parent = block(
                "parent-a", 0, "PARAGRAPH", "before\uFFFCafter");
        CandidateBlockSet.Block image = imageBlock("image-a", "parent-a", 1, 6, 0);
        assertThat(new CandidateBlockSet(
                        SOURCE_DOCUMENT_ID,
                        "revision-a",
                        "attempt-a",
                        CandidateBlockSet.ParseCompleteness.COMPLETE,
                        CandidateBlockSet.PartialAcceptanceStatus.NOT_APPLICABLE,
                        List.of(parent, image),
                        List.of(),
                        List.of(externalDiagnostic(1))).blocks())
                .containsExactly(parent, image);
        ImageRelationshipProjector.ProjectedImage validImage = image.imageCandidate();
        ImageRelationshipProjector.ProjectedImage forgedHash =
                new ImageRelationshipProjector.ProjectedImage(
                        validImage.sourceOrder(), validImage.sourcePart(),
                        validImage.sourceElementIndex(), validImage.anchor(),
                        validImage.relationshipId(), validImage.relationshipMode(),
                        validImage.externalTargetLiteralSha256(), validImage.mediaRef(),
                        validImage.mediaType(), validImage.byteLength(),
                        validImage.contentSha256(), validImage.securityDisclosure(),
                        SourceHash.ofHex("c".repeat(64)));
        assertThatThrownBy(() -> CandidateBlockSet.Block.fromImage(
                        "forged-image", SOURCE_DOCUMENT_ID, "revision-a", "attempt-a",
                        List.of(), forgedHash, null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("IMAGE_CONTENT_HASH_MISMATCH");
        ExternalRelationshipLiteral mismatchedDiagnostic = new ExternalRelationshipLiteral(
                "word/document.xml", "rId-image-1",
                "http://schemas.openxmlformats.org/officeDocument/2006/relationships/image",
                DocxRelationshipClassifier.Mode.EXTERNAL,
                SourceHash.ofHex("e".repeat(64)),
                "EXTERNAL_RELATIONSHIP_NOT_DEREFERENCED");
        assertThatThrownBy(() -> new CandidateBlockSet(
                        SOURCE_DOCUMENT_ID, "revision-a", "attempt-a",
                        CandidateBlockSet.ParseCompleteness.COMPLETE,
                        CandidateBlockSet.PartialAcceptanceStatus.NOT_APPLICABLE,
                        List.of(parent, image), List.of(), List.of(mismatchedDiagnostic)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("EXTERNAL_IMAGE_DIAGNOSTIC_MISMATCH");
        CandidateBlockSet.Block wrongImage = imageBlock("image-a", "parent-a", 1, 5, 0);
        assertThatThrownBy(() -> new CandidateBlockSet(
                        SOURCE_DOCUMENT_ID,
                        "revision-a",
                        "attempt-a",
                        CandidateBlockSet.ParseCompleteness.COMPLETE,
                        CandidateBlockSet.PartialAcceptanceStatus.NOT_APPLICABLE,
                        List.of(parent, wrongImage),
                        List.of(),
                        List.of(externalDiagnostic(1))))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("CANDIDATE_PARAGRAPH_IMAGE_BINDING_INVALID");

        CandidateBlockSet.Block tableParent = block(
                "table-a", 0, "TABLE", "left￼right");
        CandidateBlockSet.Block tableImage = tableImageBlock(
                "image-table-a", "table-a", 1, 4, 0, 0, 0);
        assertThat(new CandidateBlockSet(
                        SOURCE_DOCUMENT_ID, "revision-a", "attempt-a",
                        CandidateBlockSet.ParseCompleteness.COMPLETE,
                        CandidateBlockSet.PartialAcceptanceStatus.NOT_APPLICABLE,
                        List.of(tableParent, tableImage), List.of(),
                        List.of(externalDiagnostic(1))).blocks())
                .containsExactly(tableParent, tableImage);
        CandidateBlockSet.Block wrongCellImage = tableImageBlock(
                "image-table-a", "table-a", 1, 4, 0, 0, 1);
        assertThatThrownBy(() -> new CandidateBlockSet(
                        SOURCE_DOCUMENT_ID, "revision-a", "attempt-a",
                        CandidateBlockSet.ParseCompleteness.COMPLETE,
                        CandidateBlockSet.PartialAcceptanceStatus.NOT_APPLICABLE,
                        List.of(tableParent, wrongCellImage), List.of(),
                        List.of(externalDiagnostic(1))))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("CANDIDATE_TABLE_IMAGE_BINDING_INVALID");

        CandidateBlockSet.Omission later = new CandidateBlockSet.Omission(
                "word/document.xml", 8, "UNSUPPORTED_DOCX_FLOW", "unsupported drawing");
        CandidateBlockSet.Omission earlier = new CandidateBlockSet.Omission(
                "word/document.xml", 3, "UNSUPPORTED_DOCX_FLOW", "unsupported field");
        CandidateBlockSet partial = new CandidateBlockSet(
                SOURCE_DOCUMENT_ID, "revision-a", "attempt-a",
                CandidateBlockSet.ParseCompleteness.PARTIAL,
                CandidateBlockSet.PartialAcceptanceStatus.PENDING,
                List.of(block("block-a", 0, "PARAGRAPH", "first")),
                List.of(later, earlier));
        CandidateBlockSet reorderedPartial = new CandidateBlockSet(
                SOURCE_DOCUMENT_ID, "revision-a", "attempt-a",
                CandidateBlockSet.ParseCompleteness.PARTIAL,
                CandidateBlockSet.PartialAcceptanceStatus.PENDING,
                List.of(block("block-a", 0, "PARAGRAPH", "first")),
                List.of(earlier, later));
        assertThat(partial.omissions()).containsExactly(earlier, later);
        assertThat(partial.omissionsDigest()).isEqualTo(reorderedPartial.omissionsDigest());
        CandidateBlockSet completeSameBlocks = new CandidateBlockSet(
                SOURCE_DOCUMENT_ID, "revision-a", "attempt-a",
                CandidateBlockSet.ParseCompleteness.COMPLETE,
                CandidateBlockSet.PartialAcceptanceStatus.NOT_APPLICABLE,
                partial.blocks(), List.of());
        assertThat(BlockSetDigest.compute(partial))
                .isEqualTo(BlockSetDigest.compute(completeSameBlocks));

        assertThat(block("same-payload-a", 0, "PARAGRAPH", "same payload").contentHash())
                .isEqualTo(block("same-payload-b", 7, "PARAGRAPH", "same payload").contentHash());
        assertThatThrownBy(() -> CandidateBlockSet.Block.fromText(
                        "page-block", SOURCE_DOCUMENT_ID, "revision-a", "attempt-a",
                        new DocumentBlockCandidate(
                                DocumentBlockCandidate.BlockType.PARAGRAPH,
                                0, List.of(), "word/document.xml", 0,
                                "page text", null, null, null),
                        new CandidateBlockSet.PageEvidence(
                                "layout-v1", "engine-v1", 0, "d".repeat(64))))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("PAGE_EVIDENCE_PROFILE_NOT_AUTHORIZED");
        assertThatThrownBy(() -> new CandidateBlockSet(
                        SOURCE_DOCUMENT_ID, "revision-a", "attempt-a",
                        CandidateBlockSet.ParseCompleteness.COMPLETE,
                        CandidateBlockSet.PartialAcceptanceStatus.NOT_APPLICABLE,
                        List.of(block("block-a", 0, "PARAGRAPH", "first")),
                        List.of(earlier)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("COMPLETE_BLOCK_SET_MUST_HAVE_NO_OMISSIONS");
        assertThatThrownBy(() -> new CandidateBlockSet(
                        SOURCE_DOCUMENT_ID, "revision-a", "attempt-a",
                        CandidateBlockSet.ParseCompleteness.PARTIAL,
                        CandidateBlockSet.PartialAcceptanceStatus.PENDING,
                        List.of(block("block-a", 0, "PARAGRAPH", "first")),
                        List.of()))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("PARTIAL_BLOCK_SET_REQUIRES_PENDING_OMISSIONS");
    }

    @Test
    void attemptFenceAndLeaseBindActiveIdentityStatusAndObservedExpiry() {
        ProcessingAttempt attempt = ProcessingAttempt.pending(
                "revision-a",
                "attempt-a",
                1,
                1,
                CLAIM_DEADLINE,
                STARTED_AT);

        assertThat(attempt.fence())
                .isEqualTo(AttemptFence.forGeneration("revision-a", "attempt-a", 1));
        assertThat(AttemptLease.claim(CLAIM_DEADLINE, RUNNING_LEASE).expectedStatus())
                .isEqualTo(ProcessingAttempt.Status.PENDING);
        assertThat(AttemptLease.heartbeat(RUNNING_LEASE, RUNNING_LEASE.plusSeconds(60))
                        .expectedStatus())
                .isEqualTo(ProcessingAttempt.Status.RUNNING);
        assertThat(AttemptLease.timeout(
                                ProcessingAttempt.Status.RUNNING, RUNNING_LEASE)
                        .observedLeaseExpiresAt())
                .isEqualTo(RUNNING_LEASE);

        assertThatThrownBy(() -> AttemptLease.timeout(
                        ProcessingAttempt.Status.SUCCEEDED, RUNNING_LEASE))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("TIMEOUT_EXPECTED_STATUS_MUST_BE_ACTIVE");

        BlockSetDigest digest = BlockSetDigest.compute(blockSet("second"));
        assertThatThrownBy(() -> ProcessingPublicationPort.GenerationStageRecord.succeeded(
                        SOURCE_DOCUMENT_ID, CONTENT_SHA256, PARSER_PROFILE_VERSION,
                        "revision-a", "bad run id", 1, digest))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("STAGE_RUN_ID_INVALID");
        assertThatThrownBy(() -> new ProcessingPublicationPort.GenerationStageRecord.ValidationResult(
                        ProcessingPublicationPort.GenerationStageRecord.ValidationResult
                                .ValidationStatus.PASS,
                        List.of("not-a-schema-urn"),
                        List.of()))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("VALIDATED_SCHEMA_ID_INVALID");
        ProcessingPublicationPort.GenerationStageRecord valid =
                ProcessingPublicationPort.GenerationStageRecord.succeeded(
                        SOURCE_DOCUMENT_ID, CONTENT_SHA256, PARSER_PROFILE_VERSION,
                        "revision-a", "attempt-a", 1, digest);
        assertThatThrownBy(() -> new ProcessingPublicationPort.GenerationStageRecord(
                        valid.schemaVersion(), valid.runId(), "UNKNOWN_STAGE", valid.inputHash(),
                        valid.promptVersion(), valid.model(), valid.sourceBlockRefs(),
                        valid.outputKind(), valid.outputSchemaId(), valid.structuredOutput(),
                        valid.outputHash(), valid.validationResult(), valid.generationStatus(),
                        valid.retryCount(), valid.retryScopeRefs(), valid.failure()))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("SOURCE_PARSING_STAGE_REQUIRED");
    }

    @Test
    void exactLeaseAndStatusCasRejectsStaleClaimHeartbeatAndTimeout() {
        ProcessingAttempt attempt = beginAndClaim("revision-a", "attempt-a");

        expectRejected(
                ProcessingPublicationPort.Outcome.STALE_LEASE,
                () -> service.claim(
                        attempt.fence(), CLAIM_DEADLINE, RUNNING_LEASE, STARTED_AT.plusSeconds(5)));

        service.heartbeat(
                attempt.fence(),
                RUNNING_LEASE,
                RUNNING_LEASE.plusSeconds(60),
                STARTED_AT.plusSeconds(20));
        assertThat(adapter.heartbeatAt("attempt-a")).isEqualTo(STARTED_AT.plusSeconds(20));
        expectRejected(
                ProcessingPublicationPort.Outcome.STALE_LEASE,
                () -> service.timeout(
                        attempt.fence(),
                        ProcessingAttempt.Status.RUNNING,
                        RUNNING_LEASE,
                        RUNNING_LEASE.plusSeconds(1)));

        Instant extendedLease = RUNNING_LEASE.plusSeconds(60);
        service.timeout(
                attempt.fence(),
                ProcessingAttempt.Status.RUNNING,
                extendedLease,
                extendedLease.plusSeconds(1));

        assertThat(adapter.attemptStatus("attempt-a"))
                .isEqualTo(ProcessingAttempt.Status.FAILED_RETRYABLE);
        assertThat(adapter.revisionStatus("revision-a")).isEqualTo("FAILED_RETRYABLE");
        assertThat(adapter.activeAttemptId("revision-a")).isNull();
        assertThat(adapter.stageProjection("attempt-a"))
                .isEqualTo(projectionString(ProcessingPublicationPort.GenerationStageRecord.failed(
                        SOURCE_DOCUMENT_ID, CONTENT_SHA256, PARSER_PROFILE_VERSION,
                        "revision-a", "attempt-a", 1,
                        SourceDomainException.Code.PARSER_RETRYABLE_FAILURE,
                        "LEASE_EXPIRED:observed active lease expired")));
    }

    @Test
    void portRejectsLeaseCommandWithWrongExpectedStatus() {
        ProcessingAttempt pending = service.beginInitial(
                SOURCE_DOCUMENT_ID, "revision-a", "attempt-a", CONTENT_SHA256,
                PARSER_PROFILE_VERSION, STARTED_AT, CLAIM_DEADLINE);

        assertThat(adapter.claim(
                        pending.fence(),
                        AttemptLease.heartbeat(CLAIM_DEADLINE, RUNNING_LEASE),
                        STARTED_AT.plusSeconds(1)))
                .isEqualTo(ProcessingPublicationPort.Outcome.STALE_LEASE);
        assertThat(adapter.attemptStatus("attempt-a")).isEqualTo(ProcessingAttempt.Status.PENDING);

        service.claim(
                pending.fence(), CLAIM_DEADLINE, RUNNING_LEASE, STARTED_AT.plusSeconds(2));
        assertThat(adapter.heartbeat(
                        pending.fence(),
                        AttemptLease.claim(RUNNING_LEASE, RUNNING_LEASE.plusSeconds(60)),
                        STARTED_AT.plusSeconds(3)))
                .isEqualTo(ProcessingPublicationPort.Outcome.STALE_LEASE);
        assertThat(adapter.attemptStatus("attempt-a")).isEqualTo(ProcessingAttempt.Status.RUNNING);
    }

    @Test
    void invalidArtifactIdentityIsRejectedBeforeAnyDatabaseFact() {
        assertThatThrownBy(() -> service.beginInitial(
                        "bad source id", "revision-a", "attempt-a", CONTENT_SHA256,
                        PARSER_PROFILE_VERSION, STARTED_AT, CLAIM_DEADLINE))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("SOURCE_DOCUMENT_ID_INVALID");
        assertThatThrownBy(() -> service.beginInitial(
                        SOURCE_DOCUMENT_ID, "bad revision id", "attempt-a", CONTENT_SHA256,
                        PARSER_PROFILE_VERSION, STARTED_AT, CLAIM_DEADLINE))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("REVISION_ID_INVALID");
        assertThatThrownBy(() -> service.beginInitial(
                        SOURCE_DOCUMENT_ID, "revision-a", "bad attempt id", CONTENT_SHA256,
                        PARSER_PROFILE_VERSION, STARTED_AT, CLAIM_DEADLINE))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("ATTEMPT_ID_INVALID");

        assertThat(adapter.revisionCount()).isZero();
        assertThat(adapter.totalAttemptCount()).isZero();
    }

    @Test
    void concurrentInitialBeginCreatesExactlyOneActiveAttempt() throws Exception {
        ExecutorService executor = Executors.newFixedThreadPool(2);
        CountDownLatch ready = new CountDownLatch(2);
        CountDownLatch start = new CountDownLatch(1);
        try {
            Future<ProcessingPublicationPort.Outcome> first = executor.submit(
                    () -> concurrentBeginOutcome("attempt-a", ready, start));
            Future<ProcessingPublicationPort.Outcome> second = executor.submit(
                    () -> concurrentBeginOutcome("attempt-b", ready, start));
            ready.await();
            start.countDown();

            assertThat(List.of(first.get(), second.get()))
                    .containsExactlyInAnyOrder(
                            ProcessingPublicationPort.Outcome.APPLIED,
                            ProcessingPublicationPort.Outcome.ACTIVE_ATTEMPT_EXISTS);
            assertThat(adapter.attemptCount("revision-a")).isEqualTo(1);
            assertThat(adapter.currentGeneration("revision-a")).isEqualTo(1);
        } finally {
            executor.shutdownNow();
        }
    }

    @Test
    void publishesCompleteDigestBoundBlockSetInOneRealTransaction() {
        ProcessingAttempt attempt = beginAndClaim("revision-a", "attempt-a");
        CandidateBlockSet blocks = blockSet("second");

        service.stage(attempt.fence(), blocks);
        assertThat(adapter.publishedBlockCount("revision-a")).isZero();

        BlockSetDigest digest = service.publish(
                attempt.fence(), blocks, STARTED_AT.plusSeconds(120));

        assertThat(digest).isEqualTo(BlockSetDigest.compute(blocks));
        assertThat(adapter.publishedBlockCount("revision-a")).isEqualTo(2);
        assertThat(adapter.aliasCount("revision-a")).isEqualTo(2);
        assertThat(adapter.aliasIdentifiers("revision-a"))
                .containsExactlyElementsOf(blocks.blocks().stream()
                        .map(CandidateBlockSet.Block::documentBlockAlias)
                        .sorted()
                        .toList());
        assertThat(adapter.successStageRecordCount("revision-a")).isEqualTo(1);
        assertThat(adapter.stageProjection("attempt-a"))
                .isEqualTo(projectionString(ProcessingPublicationPort.GenerationStageRecord.succeeded(
                        SOURCE_DOCUMENT_ID, CONTENT_SHA256, PARSER_PROFILE_VERSION,
                        "revision-a", "attempt-a", 1, digest)));
        assertThat(adapter.parseCompleteness("revision-a")).isEqualTo("COMPLETE");
        assertThat(adapter.revisionStatus("revision-a")).isEqualTo("PARSED");
        assertThat(adapter.attemptStatus("attempt-a"))
                .isEqualTo(ProcessingAttempt.Status.SUCCEEDED);
        assertThat(adapter.publishedDigest("revision-a")).isEqualTo(digest.value());
        assertThat(adapter.activeAttemptId("revision-a")).isNull();

        expectRejected(
                ProcessingPublicationPort.Outcome.ALREADY_PUBLISHED,
                () -> service.publish(
                        attempt.fence(), blocks, STARTED_AT.plusSeconds(121)));
        assertThat(adapter.publishedBlockCount("revision-a")).isEqualTo(2);
        assertThat(adapter.successStageRecordCount("revision-a")).isEqualTo(1);
        assertThat(adapter.rejectionAuditCount("attempt-a")).isEqualTo(1);
    }

    @Test
    void publishesVerifiedExternalImageDiagnosticWithoutDigestDrift() {
        ProcessingAttempt attempt = beginAndClaim("revision-a", "attempt-a");
        CandidateBlockSet.Block parent = block(
                "parent-a", 0, "PARAGRAPH", "before\uFFFCafter");
        CandidateBlockSet.Block image = imageBlock("image-a", "parent-a", 1, 6, 0);
        CandidateBlockSet blocks = new CandidateBlockSet(
                SOURCE_DOCUMENT_ID, "revision-a", "attempt-a",
                CandidateBlockSet.ParseCompleteness.COMPLETE,
                CandidateBlockSet.PartialAcceptanceStatus.NOT_APPLICABLE,
                List.of(parent, image), List.of(), List.of(externalDiagnostic(1)));

        service.stage(attempt.fence(), blocks);
        service.publish(attempt.fence(), blocks, STARTED_AT.plusSeconds(120));

        assertThat(adapter.publishedRevisionDiagnostics("revision-a"))
                .isEqualTo(blocks.canonicalRevisionDiagnosticsBytes());
    }

    @Test
    void portRejectsForeignBlockSetBeforeAnyStagingFact() {
        ProcessingAttempt attempt = beginAndClaim("revision-a", "attempt-a");
        CandidateBlockSet foreign = new CandidateBlockSet(
                SOURCE_DOCUMENT_ID,
                "revision-b",
                "attempt-b",
                CandidateBlockSet.ParseCompleteness.COMPLETE,
                CandidateBlockSet.PartialAcceptanceStatus.NOT_APPLICABLE,
                List.of(
                        block("block-a", SOURCE_DOCUMENT_ID, "revision-b", "attempt-b",
                                0, "PARAGRAPH", "first", 0, 0),
                        block("block-b", SOURCE_DOCUMENT_ID, "revision-b", "attempt-b",
                                1, "TABLE", "second", 0, 0)),
                List.of());

        assertThat(adapter.stage(attempt.fence(), foreign))
                .isEqualTo(ProcessingPublicationPort.Outcome.BLOCK_SET_MISMATCH);
        assertThat(adapter.stagedBlockCount("attempt-a")).isZero();
        assertThat(adapter.publishedBlockCount("revision-a")).isZero();
    }

    @Test
    void callerCannotSelectCanonicalFencingToken() {
        ProcessingAttempt first = service.beginInitial(
                SOURCE_DOCUMENT_ID, "revision-a", "attempt-a", CONTENT_SHA256,
                PARSER_PROFILE_VERSION, STARTED_AT, CLAIM_DEADLINE);
        String canonical = first.fencingToken();
        assertThat(canonical).isEqualTo(AttemptFence.fencingTokenFor("revision-a", 1));

        adapter.reset();
        ProcessingAttempt replay = service.beginInitial(
                SOURCE_DOCUMENT_ID, "revision-a", "attempt-b", CONTENT_SHA256,
                PARSER_PROFILE_VERSION, STARTED_AT, CLAIM_DEADLINE);
        assertThat(replay.fencingToken()).isEqualTo(canonical);
    }

    @Test
    void pendingAttemptCannotFailTerminal() {
        ProcessingAttempt pending = service.beginInitial(
                SOURCE_DOCUMENT_ID, "revision-a", "attempt-a", CONTENT_SHA256,
                PARSER_PROFILE_VERSION, STARTED_AT, CLAIM_DEADLINE);

        assertThat(adapter.fail(
                        pending.fence(),
                        new ProcessingPublicationPort.Failure(
                                ProcessingAttempt.Status.FAILED_TERMINAL,
                                SourceDomainException.Code.DOCX_FORMAT_INVALID,
                                "deterministic invalid format",
                                STARTED_AT.plusSeconds(1))))
                .isEqualTo(ProcessingPublicationPort.Outcome.STALE_FENCE);
        assertThat(adapter.attemptStatus("attempt-a"))
                .isEqualTo(ProcessingAttempt.Status.PENDING);
        assertThat(adapter.revisionStatus("revision-a")).isEqualTo("PARSING");
        assertThat(adapter.stageRecordCount("revision-a")).isZero();

        assertThatThrownBy(() -> new ProcessingPublicationPort.Failure(
                        ProcessingAttempt.Status.FAILED_RETRYABLE,
                        SourceDomainException.Code.DOCX_FORMAT_INVALID,
                        "wrong mapping",
                        STARTED_AT.plusSeconds(1)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("RETRYABLE_FAILURE_REQUIRES_PARSER_RETRYABLE_FAILURE");
        assertThatThrownBy(() -> new ProcessingPublicationPort.Failure(
                        ProcessingAttempt.Status.FAILED_TERMINAL,
                        SourceDomainException.Code.PARSER_RETRYABLE_FAILURE,
                        "wrong mapping",
                        STARTED_AT.plusSeconds(1)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("TERMINAL_FAILURE_REQUIRES_TERMINAL_FAILURE_CODE");
    }

    @Test
    void terminalFailurePersistsCompleteFailedStageProjection() {
        ProcessingAttempt attempt = beginAndClaim("revision-a", "attempt-a");
        service.fail(
                attempt.fence(),
                ProcessingAttempt.Status.FAILED_TERMINAL,
                SourceDomainException.Code.DOCX_FORMAT_INVALID,
                "deterministic invalid format",
                STARTED_AT.plusSeconds(40));

        assertThat(adapter.stageProjection("attempt-a"))
                .isEqualTo(projectionString(ProcessingPublicationPort.GenerationStageRecord.failed(
                        SOURCE_DOCUMENT_ID, CONTENT_SHA256, PARSER_PROFILE_VERSION,
                        "revision-a", "attempt-a", 1,
                        SourceDomainException.Code.DOCX_FORMAT_INVALID,
                        "deterministic invalid format")));
        assertThat(adapter.revisionStatus("revision-a")).isEqualTo("FAILED_TERMINAL");
    }

    @Test
    void partialStagingAndDigestDriftRemainInvisible() {
        ProcessingAttempt attempt = beginAndClaim("revision-a", "attempt-a");
        CandidateBlockSet blocks = blockSet("second");
        service.stage(attempt.fence(), blocks);

        adapter.deleteStagedBlock("attempt-a", 1);
        expectRejected(
                ProcessingPublicationPort.Outcome.BLOCK_SET_MISMATCH,
                () -> service.publish(
                        attempt.fence(), blocks, STARTED_AT.plusSeconds(120)));
        assertUnpublished("revision-a", "attempt-a");

        adapter.restoreStagedBlock(blocks.blocks().get(1), "attempt-a");
        CandidateBlockSet drifted = blockSet("changed");
        expectRejected(
                ProcessingPublicationPort.Outcome.BLOCK_SET_MISMATCH,
                () -> service.publish(
                        attempt.fence(), drifted, STARTED_AT.plusSeconds(121)));
        assertUnpublished("revision-a", "attempt-a");
    }

    @Test
    void databaseFailureRollsBackBlocksAliasesStageAndTerminalStates() {
        ProcessingAttempt attempt = beginAndClaim("revision-a", "attempt-a");
        CandidateBlockSet blocks = blockSet("second");
        service.stage(attempt.fence(), blocks);
        adapter.failDuringPublish();

        assertThatThrownBy(() -> service.publish(
                        attempt.fence(), blocks, STARTED_AT.plusSeconds(120)))
                .isInstanceOf(ProcessingPublicationPort.StorageException.class)
                .hasMessageContaining("I07_TEST_FORCED_DATABASE_FAILURE");

        assertUnpublished("revision-a", "attempt-a");
        assertThat(adapter.aliasCount("revision-a")).isZero();
        assertThat(adapter.successStageRecordCount("revision-a")).isZero();
    }

    @Test
    void aliasCollisionRollsBackEntirePublication() {
        ProcessingAttempt attempt = beginAndClaim("revision-a", "attempt-a");
        CandidateBlockSet blocks = blockSet("second");
        service.stage(attempt.fence(), blocks);
        adapter.forceAliasCollision(blocks.blocks().getFirst().documentBlockAlias());

        assertThatThrownBy(() -> service.publish(
                        attempt.fence(), blocks, STARTED_AT.plusSeconds(120)))
                .isInstanceOf(ProcessingPublicationPort.StorageException.class)
                .hasMessageContaining("REFERENCE_ALIAS_CONFLICT");

        assertUnpublished("revision-a", "attempt-a");
        assertThat(adapter.aliasCount("revision-a")).isZero();
        assertThat(adapter.successStageRecordCount("revision-a")).isZero();
    }

    @Test
    void publishAndTimeoutRaceHasExactlyOneAtomicTerminalResult() throws Exception {
        ProcessingAttempt attempt = beginAndClaim("revision-a", "attempt-a");
        CandidateBlockSet blocks = blockSet("second");
        service.stage(attempt.fence(), blocks);
        ExecutorService executor = Executors.newFixedThreadPool(2);
        CountDownLatch ready = new CountDownLatch(2);
        CountDownLatch start = new CountDownLatch(1);
        try {
            Future<ProcessingPublicationPort.Outcome> publish = executor.submit(() -> {
                ready.countDown();
                start.await();
                return adapter.publish(
                        attempt.fence(),
                        blocks,
                        BlockSetDigest.compute(blocks),
                        STARTED_AT.plusSeconds(120));
            });
            Future<ProcessingPublicationPort.Outcome> timeout = executor.submit(() -> {
                ready.countDown();
                start.await();
                return adapter.timeout(
                        attempt.fence(),
                        AttemptLease.timeout(ProcessingAttempt.Status.RUNNING, RUNNING_LEASE),
                        RUNNING_LEASE.plusSeconds(1));
            });
            ready.await();
            start.countDown();

            assertThat(List.of(publish.get(), timeout.get()))
                    .containsExactlyInAnyOrder(
                            ProcessingPublicationPort.Outcome.APPLIED,
                            ProcessingPublicationPort.Outcome.STALE_FENCE);
            assertThat(adapter.stageRecordCount("revision-a")).isEqualTo(1);
            if ("PARSED".equals(adapter.revisionStatus("revision-a"))) {
                assertThat(adapter.publishedBlockCount("revision-a")).isEqualTo(2);
                assertThat(adapter.attemptStatus("attempt-a"))
                        .isEqualTo(ProcessingAttempt.Status.SUCCEEDED);
            } else {
                assertThat(adapter.revisionStatus("revision-a")).isEqualTo("FAILED_RETRYABLE");
                assertThat(adapter.publishedBlockCount("revision-a")).isZero();
                assertThat(adapter.attemptStatus("attempt-a"))
                        .isEqualTo(ProcessingAttempt.Status.FAILED_RETRYABLE);
            }
        } finally {
            executor.shutdownNow();
        }
    }

    @Test
    void retryIncrementsGenerationAndLateOldResultOnlyAppendsRejectionAudit() {
        ProcessingAttempt first = beginAndClaim("revision-a", "attempt-a");
        service.fail(
                first.fence(),
                ProcessingAttempt.Status.FAILED_RETRYABLE,
                SourceDomainException.Code.PARSER_RETRYABLE_FAILURE,
                "transient source read",
                STARTED_AT.plusSeconds(40));
        assertThat(adapter.stageProjection("attempt-a"))
                .isEqualTo(projectionString(ProcessingPublicationPort.GenerationStageRecord.failed(
                        SOURCE_DOCUMENT_ID, CONTENT_SHA256, PARSER_PROFILE_VERSION,
                        "revision-a", "attempt-a", 1,
                        SourceDomainException.Code.PARSER_RETRYABLE_FAILURE,
                        "transient source read")));

        ProcessingAttempt second = service.retry(
                SOURCE_DOCUMENT_ID,
                "revision-a",
                "attempt-b",
                CONTENT_SHA256,
                PARSER_PROFILE_VERSION,
                STARTED_AT.plusSeconds(41),
                STARTED_AT.plusSeconds(71));
        assertThat(second.generation()).isEqualTo(2);
        assertThat(second.attemptNumber()).isEqualTo(2);
        assertThat(adapter.attemptNumber("attempt-b")).isEqualTo(2);
        service.claim(
                second.fence(),
                STARTED_AT.plusSeconds(71),
                STARTED_AT.plusSeconds(131),
                STARTED_AT.plusSeconds(42));
        CandidateBlockSet secondBlocks = new CandidateBlockSet(
                SOURCE_DOCUMENT_ID,
                "revision-a",
                "attempt-b",
                CandidateBlockSet.ParseCompleteness.COMPLETE,
                CandidateBlockSet.PartialAcceptanceStatus.NOT_APPLICABLE,
                List.of(
                        block("block-a", SOURCE_DOCUMENT_ID, "revision-a", "attempt-b",
                                0, "PARAGRAPH", "first", 0, 0),
                        block("block-b", SOURCE_DOCUMENT_ID, "revision-a", "attempt-b",
                                1, "TABLE", "second", 0, 0)),
                List.of());
        assertThat(BlockSetDigest.compute(secondBlocks))
                .isEqualTo(BlockSetDigest.compute(blockSet("second")));
        service.stage(second.fence(), secondBlocks);

        CandidateBlockSet staleBlocks = blockSet("second");
        expectRejected(
                ProcessingPublicationPort.Outcome.STALE_FENCE,
                () -> service.publish(
                        first.fence(), staleBlocks, STARTED_AT.plusSeconds(132)));

        assertThat(adapter.rejectionAuditCount("attempt-a")).isEqualTo(1);
        assertThat(adapter.attemptStatus("attempt-a"))
                .isEqualTo(ProcessingAttempt.Status.FAILED_RETRYABLE);
        assertThat(adapter.attemptStatus("attempt-b"))
                .isEqualTo(ProcessingAttempt.Status.RUNNING);
        assertThat(adapter.activeAttemptId("revision-a")).isEqualTo("attempt-b");
        assertThat(adapter.publishedBlockCount("revision-a")).isZero();
    }

    @Test
    void forgedFencingTokenCannotPublishMatchingAttemptAndGeneration() {
        ProcessingAttempt attempt = beginAndClaim("revision-a", "attempt-a");
        CandidateBlockSet blocks = blockSet("second");
        service.stage(attempt.fence(), blocks);
        AttemptFence forged = new AttemptFence("revision-a", "attempt-a", 1, "forged-token");

        expectRejected(
                ProcessingPublicationPort.Outcome.STALE_FENCE,
                () -> service.publish(forged, blocks, STARTED_AT.plusSeconds(120)));

        assertThat(adapter.rejectionAuditCount("attempt-a")).isEqualTo(1);
        assertUnpublished("revision-a", "attempt-a");
    }

    private ProcessingAttempt beginAndClaim(String revisionId, String attemptId) {
        ProcessingAttempt attempt = service.beginInitial(
                SOURCE_DOCUMENT_ID,
                revisionId,
                attemptId,
                CONTENT_SHA256,
                PARSER_PROFILE_VERSION,
                STARTED_AT,
                CLAIM_DEADLINE);
        service.claim(
                attempt.fence(), CLAIM_DEADLINE, RUNNING_LEASE, STARTED_AT.plusSeconds(5));
        return attempt;
    }

    private ProcessingPublicationPort.Outcome concurrentBeginOutcome(
            String attemptId,
            CountDownLatch ready,
            CountDownLatch start)
            throws InterruptedException {
        ready.countDown();
        start.await();
        try {
            service.beginInitial(
                    SOURCE_DOCUMENT_ID,
                    "revision-a",
                    attemptId,
                    CONTENT_SHA256,
                    PARSER_PROFILE_VERSION,
                    STARTED_AT,
                    CLAIM_DEADLINE);
            return ProcessingPublicationPort.Outcome.APPLIED;
        } catch (ProcessingPublicationService.Rejected rejected) {
            return rejected.outcome();
        }
    }

    private void assertUnpublished(String revisionId, String attemptId) {
        assertThat(adapter.publishedBlockCount(revisionId)).isZero();
        assertThat(adapter.revisionStatus(revisionId)).isEqualTo("PARSING");
        assertThat(adapter.attemptStatus(attemptId)).isEqualTo(ProcessingAttempt.Status.RUNNING);
        assertThat(adapter.activeAttemptId(revisionId)).isEqualTo(attemptId);
    }

    private static void expectRejected(
            ProcessingPublicationPort.Outcome outcome, Runnable operation) {
        assertThatThrownBy(operation::run)
                .isInstanceOf(ProcessingPublicationService.Rejected.class)
                .extracting(error -> ((ProcessingPublicationService.Rejected) error).outcome())
                .isEqualTo(outcome);
    }

    private static String projectionString(
            ProcessingPublicationPort.GenerationStageRecord projection) {
        ProcessingPublicationPort.GenerationStageRecord.FailureProjection failure =
                projection.failure();
        return String.join("|",
                projection.schemaVersion(), projection.runId(), projection.stage(),
                projection.inputHash(), projection.promptVersion(), projection.model(),
                projection.sourceBlockRefs().toString(), projection.outputKind().name(),
                nullable(projection.outputSchemaId()),
                projection.structuredOutput() == null
                        ? "<null>" : projection.structuredOutput().canonicalJson(),
                projection.outputHash() == null ? "<null>" : projection.outputHash().value(),
                projection.validationResult().canonicalJson(), projection.generationStatus().name(),
                Long.toString(projection.retryCount()), projection.retryScopeRefs().toString(),
                failure == null ? "<null>" : failure.code().name(),
                failure == null ? "<null>" : failure.message(),
                failure == null ? "<null>" : Boolean.toString(failure.retryable()),
                failure == null ? "<null>" : failure.failedScopeRefs().toString());
    }

    private static String nullable(String value) {
        return value == null ? "<null>" : value;
    }

    private static Connection connection() throws SQLException {
        return DriverManager.getConnection(
                postgres.getJdbcUrl(), postgres.getUsername(), postgres.getPassword());
    }

    private static CandidateBlockSet blockSet(String secondPayload) {
        return new CandidateBlockSet(
                SOURCE_DOCUMENT_ID,
                "revision-a",
                "attempt-a",
                CandidateBlockSet.ParseCompleteness.COMPLETE,
                CandidateBlockSet.PartialAcceptanceStatus.NOT_APPLICABLE,
                List.of(
                        block("block-a", 0, "PARAGRAPH", "first"),
                        block("block-b", 1, "TABLE", secondPayload)),
                List.of());
    }

    private static CandidateBlockSet.Block block(
            String blockId, int sourceOrder, String blockType, String payload) {
        return block(
                blockId,
                SOURCE_DOCUMENT_ID,
                "revision-a",
                "attempt-a",
                sourceOrder,
                blockType,
                payload,
                0,
                0);
    }

    private static CandidateBlockSet.Block block(
            String blockId,
            String sourceDocumentId,
            String revisionId,
            String attemptId,
            int sourceOrder,
            String blockType,
            String payload,
            int placeholders,
            int imageBindings) {
        if (placeholders != 0 || imageBindings != 0) {
            throw new IllegalArgumentException("TEST_HELPER_IMAGE_COUNTS_UNSUPPORTED");
        }
        if ("TABLE".equals(blockType)) {
            List<Integer> offsets = replacementOffsets(payload);
            TableTextEvidence evidence = new TableTextEvidence(0, payload, offsets);
            TableCellCandidate cell = new TableCellCandidate(
                    0, 0, 1, 1, payload, List.of(evidence));
            TableBlockCandidate table = new TableBlockCandidate(
                    sourceOrder,
                    "word/document.xml",
                    sourceOrder,
                    1,
                    1,
                    List.of(cell),
                    List.of());
            return CandidateBlockSet.Block.fromTable(
                    blockId, sourceDocumentId, revisionId, attemptId, List.of(), table, null);
        }
        DocumentBlockCandidate text = new DocumentBlockCandidate(
                DocumentBlockCandidate.BlockType.valueOf(blockType),
                sourceOrder,
                List.of(),
                "word/document.xml",
                sourceOrder,
                payload,
                null,
                null,
                null);
        return CandidateBlockSet.Block.fromText(
                blockId, sourceDocumentId, revisionId, attemptId, text, null);
    }

    private static CandidateBlockSet.Block imageBlock(
            String blockId,
            String parentBlockId,
            int sourceOrder,
            int textOffset,
            int childOrdinal) {
        String relationshipId = "rId-image-" + sourceOrder;
        SourceHash externalDigest = SourceHash.ofHex("b".repeat(64));
        String disclosure = "EXTERNAL_RELATIONSHIP_NOT_DEREFERENCED";
        ImageRelationshipProjector.ProjectedImage image = new ImageRelationshipProjector.ProjectedImage(
                        sourceOrder,
                        "word/document.xml",
                        sourceOrder,
                        new ImageAnchor(
                                parentBlockId,
                                ImageAnchor.AnchorKind.PARAGRAPH_INLINE,
                                textOffset,
                                childOrdinal,
                                null,
                                null),
                        relationshipId,
                        DocxRelationshipClassifier.Mode.EXTERNAL,
                        externalDigest,
                        null,
                        null,
                        null,
                        null,
                        disclosure,
                        externalImageContentHash(relationshipId, externalDigest, disclosure));
        return CandidateBlockSet.Block.fromImage(
                blockId,
                SOURCE_DOCUMENT_ID,
                "revision-a",
                "attempt-a",
                List.of(),
                image,
                null);
    }

    private static CandidateBlockSet.Block tableImageBlock(
            String blockId,
            String parentBlockId,
            int sourceOrder,
            int textOffset,
            int childOrdinal,
            int rowIndex,
            int columnIndex) {
        String relationshipId = "rId-image-" + sourceOrder;
        SourceHash externalDigest = SourceHash.ofHex("b".repeat(64));
        String disclosure = "EXTERNAL_RELATIONSHIP_NOT_DEREFERENCED";
        ImageRelationshipProjector.ProjectedImage image = new ImageRelationshipProjector.ProjectedImage(
                        sourceOrder,
                        "word/document.xml",
                        sourceOrder,
                        new ImageAnchor(
                                parentBlockId,
                                ImageAnchor.AnchorKind.TABLE_CELL_INLINE,
                                textOffset,
                                childOrdinal,
                                rowIndex,
                                columnIndex),
                        relationshipId,
                        DocxRelationshipClassifier.Mode.EXTERNAL,
                        externalDigest,
                        null,
                        null,
                        null,
                        null,
                        disclosure,
                        externalImageContentHash(relationshipId, externalDigest, disclosure));
        return CandidateBlockSet.Block.fromImage(
                blockId,
                SOURCE_DOCUMENT_ID,
                "revision-a",
                "attempt-a",
                List.of(),
                image,
                null);
    }

    private static ExternalRelationshipLiteral externalDiagnostic(int sourceOrder) {
        return new ExternalRelationshipLiteral(
                "word/document.xml",
                "rId-image-" + sourceOrder,
                "http://schemas.openxmlformats.org/officeDocument/2006/relationships/image",
                DocxRelationshipClassifier.Mode.EXTERNAL,
                SourceHash.ofHex("b".repeat(64)),
                "EXTERNAL_RELATIONSHIP_NOT_DEREFERENCED");
    }

    private static SourceHash externalImageContentHash(
            String relationshipId, SourceHash externalDigest, String disclosure) {
        StringBuilder canonical = new StringBuilder("IMAGE_PAYLOAD_V1");
        appendImageCanonical(canonical, relationshipId);
        appendImageCanonical(canonical, "EXTERNAL");
        appendImageCanonical(canonical, externalDigest.value());
        appendImageCanonical(canonical, null);
        appendImageCanonical(canonical, null);
        appendImageCanonical(canonical, null);
        appendImageCanonical(canonical, null);
        appendImageCanonical(canonical, disclosure);
        return SourceHash.sha256(canonical.toString().getBytes(StandardCharsets.UTF_8));
    }

    private static void appendImageCanonical(StringBuilder target, String value) {
        target.append('|');
        if (value == null) {
            target.append("-1:");
            return;
        }
        target.append(value.getBytes(StandardCharsets.UTF_8).length).append(':').append(value);
    }

    private static List<Integer> replacementOffsets(String text) {
        List<Integer> offsets = new ArrayList<>();
        int codePointOffset = 0;
        for (int charOffset = 0; charOffset < text.length(); codePointOffset++) {
            int codePoint = text.codePointAt(charOffset);
            if (codePoint == 0xFFFC) offsets.add(codePointOffset);
            charOffset += Character.charCount(codePoint);
        }
        return List.copyOf(offsets);
    }

    private static final class TestLocalJdbcProcessingPublicationPort
            implements ProcessingPublicationPort {

        // Contract-only PostgreSQL schema. It is never a production migration or adapter.
        private static final String SCHEMA = """
                create table i07_revision (
                  revision_id text primary key,
                  source_document_id text not null,
                  content_sha256 char(64) not null,
                  parser_profile_version text not null,
                  revision_status text not null,
                  active_attempt_id text null,
                  current_generation bigint not null,
                  published_digest char(64) null,
                  omissions_digest char(64) null,
                  revision_diagnostics bytea null,
                  parse_completeness text null,
                  partial_acceptance_status text null,
                  failure_code text null,
                  failure_detail text null,
                  completed_at timestamptz null
                  ,check (failure_code is null or failure_code in (
                    'PARSER_RETRYABLE_FAILURE',
                    'PARSER_TERMINAL_FAILURE',
                    'DOCX_FORMAT_INVALID'))
                );
                create table i07_attempt (
                  attempt_id text primary key,
                  revision_id text not null references i07_revision(revision_id),
                  attempt_number bigint not null,
                  generation bigint not null,
                  fencing_token text not null,
                  attempt_status text not null,
                  lease_expires_at timestamptz null,
                  heartbeat_at timestamptz null,
                  failure_code text null,
                  failure_detail text null,
                  started_at timestamptz not null,
                  completed_at timestamptz null,
                  unique (revision_id, generation),
                  check (failure_code is null or failure_code in (
                    'PARSER_RETRYABLE_FAILURE',
                    'PARSER_TERMINAL_FAILURE',
                    'DOCX_FORMAT_INVALID'))
                );
                create table i07_staged_set (
                  attempt_id text primary key references i07_attempt(attempt_id),
                  source_document_id text not null,
                  revision_id text not null references i07_revision(revision_id),
                  parse_completeness text not null,
                  partial_acceptance_status text not null,
                  block_set_digest char(64) not null,
                  omissions_digest char(64) not null,
                  omissions_canonical bytea not null,
                  revision_diagnostics bytea not null
                );
                create table i07_staged_block (
                  attempt_id text not null references i07_attempt(attempt_id),
                  source_order integer not null,
                  block_id text not null,
                  canonical_block bytea not null,
                  primary key (attempt_id, source_order),
                  unique (attempt_id, block_id)
                );
                create table i07_published_block (
                  revision_id text not null references i07_revision(revision_id),
                  source_order integer not null,
                  block_id text not null,
                  canonical_block bytea not null,
                  primary key (revision_id, source_order),
                  unique (revision_id, block_id)
                );
                create table i07_block_alias (
                  alias_identifier varchar(68) primary key,
                  source_document_id text not null,
                  revision_id text not null,
                  block_id text not null,
                  unique (source_document_id, revision_id, block_id)
                );
                create table i07_stage_record (
                  stage_record_id bigserial primary key,
                  revision_id text not null references i07_revision(revision_id),
                  attempt_id text not null references i07_attempt(attempt_id),
                  terminal_status text not null,
                  block_set_digest char(64) null,
                  schema_version text not null,
                  run_id text not null,
                  stage_name text not null,
                  input_hash text not null,
                  prompt_version text not null,
                  model text not null,
                  source_block_refs text not null,
                  output_kind text not null,
                  output_schema_id text null,
                  structured_output text null,
                  output_hash char(64) null,
                  validation_result text not null,
                  generation_status text not null,
                  retry_count bigint not null,
                  retry_scope_refs text not null,
                  failure_code text null,
                  failure_detail text null,
                  failure_retryable boolean null,
                  failure_revision_scope text null,
                  created_at timestamptz not null,
                  check (input_hash ~ '^[0-9a-f]{64}$'),
                  check (validation_result::jsonb is not null),
                  check (structured_output is null or structured_output::jsonb is not null),
                  check (generation_status in ('SUCCEEDED', 'FAILED')),
                  check ((generation_status = 'SUCCEEDED'
                          and failure_code is null and failure_detail is null
                          and failure_retryable is null and failure_revision_scope is null)
                      or (generation_status = 'FAILED'
                          and failure_code is not null and failure_detail is not null
                          and failure_retryable is not null
                          and failure_revision_scope is not null))
                );
                create table i07_rejection_event (
                  rejection_event_id bigserial primary key,
                  revision_id text not null,
                  attempt_id text not null,
                  submitted_generation bigint not null,
                  current_generation bigint not null,
                  reason text not null,
                  rejected_at timestamptz not null default clock_timestamp()
                );
                """;

        private final String jdbcUrl;
        private final String username;
        private final String password;
        private boolean failDuringPublish;

        private TestLocalJdbcProcessingPublicationPort(
                String jdbcUrl, String username, String password) {
            this.jdbcUrl = jdbcUrl;
            this.username = username;
            this.password = password;
        }

        static void createSchema(Connection suppliedConnection) throws SQLException {
            try (Connection connection = suppliedConnection;
                    Statement statement = connection.createStatement()) {
                statement.execute(SCHEMA);
            }
        }

        void reset() {
            executeStatement("""
                    truncate table
                      i07_rejection_event,
                      i07_stage_record,
                      i07_block_alias,
                      i07_published_block,
                      i07_staged_block,
                      i07_staged_set,
                      i07_attempt,
                      i07_revision
                    restart identity cascade
                    """);
            failDuringPublish = false;
        }

        void failDuringPublish() {
            failDuringPublish = true;
        }

        void forceAliasCollision(String aliasIdentifier) {
            update("""
                    insert into i07_block_alias(
                      alias_identifier, source_document_id, revision_id, block_id)
                    values (?, 'source-document-other', 'revision-other', 'block-other')
                    """, statement -> statement.setString(1, aliasIdentifier));
        }

        @Override
        public BeginResult beginInitial(BeginAttempt command) {
            try {
                return transaction(connection -> {
                    try (PreparedStatement query = connection.prepareStatement(
                            "select active_attempt_id, published_digest "
                                    + "from i07_revision where revision_id = ? for update")) {
                        query.setString(1, command.revisionId());
                        try (ResultSet result = query.executeQuery()) {
                            if (result.next()) {
                                return BeginResult.rejected(
                                        result.getString("published_digest") == null
                                                ? Outcome.ACTIVE_ATTEMPT_EXISTS
                                                : Outcome.ALREADY_PUBLISHED);
                            }
                        }
                    }
                    try (PreparedStatement insertRevision = connection.prepareStatement("""
                                    insert into i07_revision(
                                      revision_id, source_document_id, content_sha256,
                                      parser_profile_version, revision_status,
                                      active_attempt_id, current_generation)
                                    values (?, ?, ?, ?, 'PARSING', ?, 1)
                                    """);
                            PreparedStatement insertAttempt = connection.prepareStatement("""
                                    insert into i07_attempt(
                                      attempt_id, revision_id, attempt_number,
                                      generation, fencing_token,
                                      attempt_status, lease_expires_at, started_at)
                                    values (?, ?, ?, ?, ?, 'PENDING', ?, ?)
                                    """)) {
                        insertRevision.setString(1, command.revisionId());
                        insertRevision.setString(2, command.sourceDocumentId());
                        insertRevision.setString(3, command.contentSha256());
                        insertRevision.setString(4, command.parserProfileVersion());
                        insertRevision.setString(5, command.attemptId());
                        requireOne(insertRevision.executeUpdate(), "INITIAL_REVISION_INSERT");
                        bindPendingAttempt(insertAttempt, command, 1, 1);
                        requireOne(insertAttempt.executeUpdate(), "INITIAL_ATTEMPT_INSERT");
                    }
                    return BeginResult.applied(ProcessingAttempt.pending(
                            command.revisionId(),
                            command.attemptId(),
                            1,
                            1,
                            command.claimDeadline(),
                            command.startedAt()));
                });
            } catch (StorageException error) {
                if (hasSqlState(error, "23505")) {
                    return BeginResult.rejected(Outcome.ACTIVE_ATTEMPT_EXISTS);
                }
                throw error;
            }
        }

        @Override
        public BeginResult beginRetry(BeginAttempt command) {
            return transaction(connection -> {
                long nextGeneration;
                try (PreparedStatement query = connection.prepareStatement("""
                                select revision_status, active_attempt_id,
                                       current_generation, published_digest,
                                       source_document_id, content_sha256,
                                       parser_profile_version
                                from i07_revision where revision_id = ? for update
                                """)) {
                    query.setString(1, command.revisionId());
                    try (ResultSet result = query.executeQuery()) {
                        if (!result.next()) {
                            return BeginResult.rejected(Outcome.RETRY_NOT_ALLOWED);
                        }
                        if (result.getString("published_digest") != null) {
                            return BeginResult.rejected(Outcome.ALREADY_PUBLISHED);
                        }
                        if (!"FAILED_RETRYABLE".equals(result.getString("revision_status"))
                                || result.getString("active_attempt_id") != null
                                || !command.sourceDocumentId().equals(
                                        result.getString("source_document_id"))
                                || !command.contentSha256().equals(
                                        result.getString("content_sha256"))
                                || !command.parserProfileVersion().equals(
                                        result.getString("parser_profile_version"))) {
                            return BeginResult.rejected(Outcome.RETRY_NOT_ALLOWED);
                        }
                        nextGeneration = result.getLong("current_generation") + 1;
                    }
                }
                try (PreparedStatement insertAttempt = connection.prepareStatement("""
                                insert into i07_attempt(
                                  attempt_id, revision_id, attempt_number,
                                  generation, fencing_token,
                                  attempt_status, lease_expires_at, started_at)
                                values (?, ?, ?, ?, ?, 'PENDING', ?, ?)
                                """);
                        PreparedStatement updateRevision = connection.prepareStatement("""
                                update i07_revision
                                set revision_status = 'PARSING', active_attempt_id = ?,
                                    current_generation = ?, failure_code = null,
                                    failure_detail = null, completed_at = null
                                where revision_id = ? and revision_status = 'FAILED_RETRYABLE'
                                  and active_attempt_id is null
                                """)) {
                    bindPendingAttempt(insertAttempt, command, nextGeneration, nextGeneration);
                    requireOne(insertAttempt.executeUpdate(), "RETRY_ATTEMPT_INSERT");
                    updateRevision.setString(1, command.attemptId());
                    updateRevision.setLong(2, nextGeneration);
                    updateRevision.setString(3, command.revisionId());
                    requireOne(updateRevision.executeUpdate(), "RETRY_REVISION_UPDATE");
                }
                return BeginResult.applied(ProcessingAttempt.pending(
                        command.revisionId(),
                        command.attemptId(),
                        nextGeneration,
                        nextGeneration,
                        command.claimDeadline(),
                        command.startedAt()));
            });
        }

        @Override
        public Outcome claim(AttemptFence fence, AttemptLease lease, Instant observedAt) {
            if (lease.expectedStatus() != ProcessingAttempt.Status.PENDING) {
                return Outcome.STALE_LEASE;
            }
            return extendLease(fence, lease, observedAt, "RUNNING");
        }

        @Override
        public Outcome heartbeat(AttemptFence fence, AttemptLease lease, Instant observedAt) {
            if (lease.expectedStatus() != ProcessingAttempt.Status.RUNNING) {
                return Outcome.STALE_LEASE;
            }
            return extendLease(fence, lease, observedAt, "RUNNING");
        }

        private Outcome extendLease(
                AttemptFence fence,
                AttemptLease lease,
                Instant observedAt,
                String targetStatus) {
            return transaction(connection -> {
                if (!fenceMatches(connection, fence)) {
                    return Outcome.STALE_FENCE;
                }
                try (PreparedStatement update = connection.prepareStatement("""
                                update i07_attempt
                                set attempt_status = ?, lease_expires_at = ?, heartbeat_at = ?
                                where attempt_id = ? and revision_id = ? and generation = ?
                                  and fencing_token = ? and attempt_status = ?
                                  and lease_expires_at = ? and lease_expires_at > ?
                                """)) {
                    update.setString(1, targetStatus);
                    setInstant(update, 2, lease.nextLeaseExpiresAt());
                    setInstant(update, 3, observedAt);
                    update.setString(4, fence.attemptId());
                    update.setString(5, fence.revisionId());
                    update.setLong(6, fence.generation());
                    update.setString(7, fence.fencingToken());
                    update.setString(8, lease.expectedStatus().name());
                    setInstant(update, 9, lease.observedLeaseExpiresAt());
                    setInstant(update, 10, observedAt);
                    return update.executeUpdate() == 1 ? Outcome.APPLIED : Outcome.STALE_LEASE;
                }
            });
        }

        @Override
        public Outcome timeout(AttemptFence fence, AttemptLease lease, Instant timedOutAt) {
            return transaction(connection -> {
                RevisionLock revision = lockRevision(connection, fence.revisionId());
                if (revision == null || !revision.matches(fence)
                        || !fenceMatches(connection, fence)) {
                    return Outcome.STALE_FENCE;
                }
                try (PreparedStatement updateAttempt = connection.prepareStatement("""
                                update i07_attempt
                                set attempt_status = 'FAILED_RETRYABLE', lease_expires_at = null,
                                    failure_code = 'PARSER_RETRYABLE_FAILURE',
                                    failure_detail = 'LEASE_EXPIRED:observed active lease expired',
                                    completed_at = ?
                                where attempt_id = ? and revision_id = ? and generation = ?
                                  and fencing_token = ? and attempt_status = ?
                                  and lease_expires_at = ? and lease_expires_at <= ?
                                """)) {
                    setInstant(updateAttempt, 1, timedOutAt);
                    updateAttempt.setString(2, fence.attemptId());
                    updateAttempt.setString(3, fence.revisionId());
                    updateAttempt.setLong(4, fence.generation());
                    updateAttempt.setString(5, fence.fencingToken());
                    updateAttempt.setString(6, lease.expectedStatus().name());
                    setInstant(updateAttempt, 7, lease.observedLeaseExpiresAt());
                    setInstant(updateAttempt, 8, timedOutAt);
                    if (updateAttempt.executeUpdate() != 1) {
                        return Outcome.STALE_LEASE;
                    }
                }
                updateRevisionFailure(
                        connection,
                        fence,
                        ProcessingAttempt.Status.FAILED_RETRYABLE,
                        SourceDomainException.Code.PARSER_RETRYABLE_FAILURE,
                        "LEASE_EXPIRED:observed active lease expired",
                        timedOutAt);
                insertStageRecord(
                        connection,
                        fence,
                        "FAILED_RETRYABLE",
                        null,
                        SourceDomainException.Code.PARSER_RETRYABLE_FAILURE,
                        "LEASE_EXPIRED:observed active lease expired",
                        timedOutAt);
                return Outcome.APPLIED;
            });
        }

        @Override
        public Outcome stage(AttemptFence fence, CandidateBlockSet blockSet) {
            return transaction(connection -> {
                if (!fence.revisionId().equals(blockSet.revisionId())
                        || !fence.attemptId().equals(blockSet.attemptId())) {
                    return Outcome.BLOCK_SET_MISMATCH;
                }
                if (!revisionSourceMatches(connection, blockSet)) {
                    return Outcome.BLOCK_SET_MISMATCH;
                }
                if (!fenceMatches(connection, fence)
                        || attemptStatus(connection, fence.attemptId())
                                != ProcessingAttempt.Status.RUNNING) {
                    return Outcome.STALE_FENCE;
                }
                BlockSetDigest digest = BlockSetDigest.compute(blockSet);
                try (PreparedStatement header = connection.prepareStatement("""
                                insert into i07_staged_set(
                                  attempt_id, source_document_id, revision_id,
                                  parse_completeness, partial_acceptance_status,
                                  block_set_digest, omissions_digest, omissions_canonical,
                                  revision_diagnostics)
                                values (?, ?, ?, ?, ?, ?, ?, ?, ?)
                                """);
                        PreparedStatement block = connection.prepareStatement("""
                                insert into i07_staged_block(
                                  attempt_id, source_order, block_id, canonical_block)
                                values (?, ?, ?, ?)
                                """)) {
                    header.setString(1, fence.attemptId());
                    header.setString(2, blockSet.sourceDocumentId());
                    header.setString(3, blockSet.revisionId());
                    header.setString(4, blockSet.parseCompleteness().name());
                    header.setString(5, blockSet.partialAcceptanceStatus().name());
                    header.setString(6, digest.value());
                    header.setString(7, blockSet.omissionsDigest().value());
                    header.setBytes(8, blockSet.canonicalOmissionsBytes());
                    header.setBytes(9, blockSet.canonicalRevisionDiagnosticsBytes());
                    requireOne(header.executeUpdate(), "STAGED_SET_INSERT");
                    for (CandidateBlockSet.Block candidate : blockSet.blocks()) {
                        bindBlock(block, fence.attemptId(), candidate);
                        requireOne(block.executeUpdate(), "STAGED_BLOCK_INSERT");
                    }
                }
                return Outcome.APPLIED;
            });
        }

        @Override
        public Outcome publish(
                AttemptFence fence,
                CandidateBlockSet blockSet,
                BlockSetDigest blockSetDigest,
                Instant completedAt) {
            return transaction(connection -> {
                RevisionLock revision = lockRevision(connection, fence.revisionId());
                if (revision == null) {
                    appendRejection(connection, fence, 0, "REVISION_MISSING");
                    return Outcome.STALE_FENCE;
                }
                if (revision.publishedDigest() != null) {
                    appendRejection(
                            connection,
                            fence,
                            revision.currentGeneration(),
                            "RESULT_AFTER_PUBLICATION");
                    return Outcome.ALREADY_PUBLISHED;
                }
                if (!fence.revisionId().equals(blockSet.revisionId())
                        || !fence.attemptId().equals(blockSet.attemptId())) {
                    return Outcome.BLOCK_SET_MISMATCH;
                }
                if (!revision.matches(fence)
                        || !fenceMatches(connection, fence)
                        || attemptStatus(connection, fence.attemptId())
                                != ProcessingAttempt.Status.RUNNING) {
                    appendRejection(
                            connection, fence, revision.currentGeneration(), "STALE_FENCE");
                    return Outcome.STALE_FENCE;
                }
                CandidateBlockSet staged = loadStaged(connection, blockSet, fence.attemptId());
                if (staged == null
                        || !staged.equals(blockSet)
                        || !BlockSetDigest.compute(staged).equals(blockSetDigest)) {
                    return Outcome.BLOCK_SET_MISMATCH;
                }
                insertPublishedFacts(connection, blockSet);
                insertStageRecord(
                        connection,
                        fence,
                        "SUCCEEDED",
                        blockSetDigest.value(),
                        null,
                        null,
                        completedAt);
                if (failDuringPublish) {
                    try (Statement statement = connection.createStatement()) {
                        statement.execute("""
                                do $$ begin
                                  raise exception 'I07_TEST_FORCED_DATABASE_FAILURE';
                                end $$
                                """);
                    }
                }
                try (PreparedStatement updateAttempt = connection.prepareStatement("""
                                update i07_attempt
                                set attempt_status = 'SUCCEEDED', lease_expires_at = null,
                                    completed_at = ?
                                where attempt_id = ? and attempt_status = 'RUNNING'
                                """);
                        PreparedStatement updateRevision = connection.prepareStatement("""
                                update i07_revision
                                set revision_status = 'PARSED', active_attempt_id = null,
                                    published_digest = ?, omissions_digest = ?,
                                    revision_diagnostics = ?,
                                    parse_completeness = ?, partial_acceptance_status = ?,
                                    completed_at = ?
                                where revision_id = ? and active_attempt_id = ?
                                  and current_generation = ?
                                """)) {
                    setInstant(updateAttempt, 1, completedAt);
                    updateAttempt.setString(2, fence.attemptId());
                    requireOne(updateAttempt.executeUpdate(), "PUBLISH_ATTEMPT_UPDATE");
                    updateRevision.setString(1, blockSetDigest.value());
                    updateRevision.setString(2, blockSet.omissionsDigest().value());
                    updateRevision.setBytes(3, blockSet.canonicalRevisionDiagnosticsBytes());
                    updateRevision.setString(4, blockSet.parseCompleteness().name());
                    updateRevision.setString(5, blockSet.partialAcceptanceStatus().name());
                    setInstant(updateRevision, 6, completedAt);
                    updateRevision.setString(7, fence.revisionId());
                    updateRevision.setString(8, fence.attemptId());
                    updateRevision.setLong(9, fence.generation());
                    requireOne(updateRevision.executeUpdate(), "PUBLISH_REVISION_UPDATE");
                }
                return Outcome.APPLIED;
            });
        }

        @Override
        public Outcome fail(AttemptFence fence, Failure failure) {
            return transaction(connection -> {
                RevisionLock revision = lockRevision(connection, fence.revisionId());
                if (revision == null || !revision.matches(fence)
                        || !fenceMatches(connection, fence)) {
                    return Outcome.STALE_FENCE;
                }
                try (PreparedStatement updateAttempt = connection.prepareStatement("""
                                update i07_attempt
                                set attempt_status = ?, lease_expires_at = null,
                                    failure_code = ?, failure_detail = ?, completed_at = ?
                                where attempt_id = ? and revision_id = ? and generation = ?
                                  and fencing_token = ?
                                  and ((? = 'FAILED_RETRYABLE'
                                        and attempt_status in ('PENDING', 'RUNNING'))
                                    or (? = 'FAILED_TERMINAL'
                                        and attempt_status = 'RUNNING'))
                                """)) {
                    updateAttempt.setString(1, failure.terminalStatus().name());
                    updateAttempt.setString(2, failure.failureCode().name());
                    updateAttempt.setString(3, failure.failureDetail());
                    setInstant(updateAttempt, 4, failure.completedAt());
                    updateAttempt.setString(5, fence.attemptId());
                    updateAttempt.setString(6, fence.revisionId());
                    updateAttempt.setLong(7, fence.generation());
                    updateAttempt.setString(8, fence.fencingToken());
                    updateAttempt.setString(9, failure.terminalStatus().name());
                    updateAttempt.setString(10, failure.terminalStatus().name());
                    if (updateAttempt.executeUpdate() != 1) {
                        return Outcome.STALE_FENCE;
                    }
                }
                updateRevisionFailure(
                        connection,
                        fence,
                        failure.terminalStatus(),
                        failure.failureCode(),
                        failure.failureDetail(),
                        failure.completedAt());
                insertStageRecord(
                        connection,
                        fence,
                        failure.terminalStatus().name(),
                        null,
                        failure.failureCode(),
                        failure.failureDetail(),
                        failure.completedAt());
                return Outcome.APPLIED;
            });
        }

        void deleteStagedBlock(String attemptId, int sourceOrder) {
            update("delete from i07_staged_block where attempt_id = ? and source_order = ?", statement -> {
                statement.setString(1, attemptId);
                statement.setInt(2, sourceOrder);
            });
        }

        void restoreStagedBlock(CandidateBlockSet.Block block, String attemptId) {
            update("""
                    insert into i07_staged_block(
                      attempt_id, source_order, block_id, canonical_block)
                    values (?, ?, ?, ?)
                    """, statement -> bindBlock(statement, attemptId, block));
        }

        ProcessingAttempt.Status attemptStatus(String attemptId) {
            return queryText(
                            "select attempt_status from i07_attempt where attempt_id = ?",
                            attemptId)
                    .map(ProcessingAttempt.Status::valueOf)
                    .orElse(null);
        }

        String revisionStatus(String revisionId) {
            return queryText(
                            "select revision_status from i07_revision where revision_id = ?",
                            revisionId)
                    .orElse(null);
        }

        String activeAttemptId(String revisionId) {
            return queryNullableText(
                    "select active_attempt_id from i07_revision where revision_id = ?",
                    revisionId);
        }

        String publishedDigest(String revisionId) {
            return queryNullableText(
                    "select published_digest from i07_revision where revision_id = ?",
                    revisionId);
        }

        String parseCompleteness(String revisionId) {
            return queryNullableText(
                    "select parse_completeness from i07_revision where revision_id = ?",
                    revisionId);
        }

        Instant heartbeatAt(String attemptId) {
            try (Connection connection = openConnection();
                    PreparedStatement query = connection.prepareStatement(
                            "select heartbeat_at from i07_attempt where attempt_id = ?")) {
                query.setString(1, attemptId);
                try (ResultSet result = query.executeQuery()) {
                    if (!result.next() || result.getTimestamp(1) == null) return null;
                    return result.getTimestamp(1).toInstant();
                }
            } catch (SQLException error) {
                throw new StorageException("I07_STORAGE_FAILURE:" + error.getMessage(), error);
            }
        }

        long attemptNumber(String attemptId) {
            return Long.parseLong(queryText(
                            "select attempt_number::text from i07_attempt where attempt_id = ?",
                            attemptId)
                    .orElseThrow());
        }

        List<String> aliasIdentifiers(String revisionId) {
            try (Connection connection = openConnection();
                    PreparedStatement query = connection.prepareStatement("""
                            select alias_identifier from i07_block_alias
                            where revision_id = ? order by alias_identifier
                            """)) {
                query.setString(1, revisionId);
                List<String> aliases = new ArrayList<>();
                try (ResultSet result = query.executeQuery()) {
                    while (result.next()) aliases.add(result.getString(1));
                }
                return List.copyOf(aliases);
            } catch (SQLException error) {
                throw new StorageException("I07_STORAGE_FAILURE:" + error.getMessage(), error);
            }
        }

        String stageProjection(String attemptId) {
            return queryText("""
                            select schema_version || '|' || run_id || '|' || stage_name || '|' ||
                                   input_hash || '|' || prompt_version || '|' || model || '|' ||
                                   source_block_refs || '|' || output_kind || '|' ||
                                   coalesce(output_schema_id, '<null>') || '|' ||
                                   coalesce(structured_output, '<null>') || '|' ||
                                   coalesce(output_hash, '<null>') || '|' || validation_result || '|' ||
                                   generation_status || '|' || retry_count::text || '|' ||
                                   retry_scope_refs || '|' || coalesce(failure_code, '<null>') || '|' ||
                                   coalesce(failure_detail, '<null>') || '|' ||
                                   coalesce(failure_retryable::text, '<null>') || '|' ||
                                   coalesce(failure_revision_scope, '<null>')
                            from i07_stage_record where attempt_id = ?
                            """, attemptId)
                    .orElse(null);
        }

        int publishedBlockCount(String revisionId) {
            return count(
                    "select count(*) from i07_published_block where revision_id = ?",
                    revisionId);
        }

        byte[] publishedRevisionDiagnostics(String revisionId) {
            try (Connection connection = openConnection();
                    PreparedStatement query = connection.prepareStatement(
                            "select revision_diagnostics from i07_revision where revision_id = ?")) {
                query.setString(1, revisionId);
                try (ResultSet result = query.executeQuery()) {
                    if (!result.next()) return null;
                    return result.getBytes(1);
                }
            } catch (SQLException error) {
                throw new StorageException("I07_STORAGE_FAILURE:" + error.getMessage(), error);
            }
        }

        int stagedBlockCount(String attemptId) {
            return count(
                    "select count(*) from i07_staged_block where attempt_id = ?",
                    attemptId);
        }

        int aliasCount(String revisionId) {
            return count(
                    "select count(*) from i07_block_alias where revision_id = ?",
                    revisionId);
        }

        int successStageRecordCount(String revisionId) {
            return count(
                    "select count(*) from i07_stage_record "
                            + "where revision_id = ? and terminal_status = 'SUCCEEDED'",
                    revisionId);
        }

        int stageRecordCount(String revisionId) {
            return count(
                    "select count(*) from i07_stage_record where revision_id = ?",
                    revisionId);
        }

        int rejectionAuditCount(String attemptId) {
            return count(
                    "select count(*) from i07_rejection_event where attempt_id = ?",
                    attemptId);
        }

        int attemptCount(String revisionId) {
            return count(
                    "select count(*) from i07_attempt where revision_id = ?",
                    revisionId);
        }

        int revisionCount() {
            return count("select count(*) from i07_revision", null);
        }

        int totalAttemptCount() {
            return count("select count(*) from i07_attempt", null);
        }

        long currentGeneration(String revisionId) {
            return Long.parseLong(queryText(
                            "select current_generation::text from i07_revision where revision_id = ?",
                            revisionId)
                    .orElseThrow());
        }

        private CandidateBlockSet loadStaged(
                Connection connection, CandidateBlockSet expected, String attemptId)
                throws SQLException {
            String declaredDigest;
            try (PreparedStatement header = connection.prepareStatement("""
                            select source_document_id, revision_id, parse_completeness,
                                   partial_acceptance_status, block_set_digest, omissions_digest,
                                   omissions_canonical, revision_diagnostics
                            from i07_staged_set where attempt_id = ?
                            """)) {
                header.setString(1, attemptId);
                try (ResultSet result = header.executeQuery()) {
                    if (!result.next()) {
                        return null;
                    }
                    if (!expected.sourceDocumentId().equals(result.getString(1))
                            || !expected.revisionId().equals(result.getString(2))
                            || !expected.parseCompleteness().name().equals(result.getString(3))
                            || !expected.partialAcceptanceStatus().name().equals(result.getString(4))
                            || !expected.omissionsDigest().value().equals(result.getString(6))
                            || !java.util.Arrays.equals(
                                    expected.canonicalOmissionsBytes(), result.getBytes(7))
                            || !java.util.Arrays.equals(
                                    expected.canonicalRevisionDiagnosticsBytes(),
                                    result.getBytes(8))) {
                        return null;
                    }
                    declaredDigest = result.getString(5);
                }
            }
            try (PreparedStatement query = connection.prepareStatement("""
                            select block_id, source_order, canonical_block
                            from i07_staged_block where attempt_id = ? order by source_order
                            """)) {
                query.setString(1, attemptId);
                try (ResultSet result = query.executeQuery()) {
                    for (CandidateBlockSet.Block expectedBlock : expected.blocks()) {
                        if (!result.next()
                                || !expectedBlock.documentBlockId().equals(result.getString(1))
                                || expectedBlock.sourceOrder() != result.getInt(2)
                                || !java.util.Arrays.equals(
                                        expectedBlock.canonicalBytes(), result.getBytes(3))) {
                            return null;
                        }
                    }
                    if (result.next()) return null;
                }
            }
            return BlockSetDigest.compute(expected).value().equals(declaredDigest) ? expected : null;
        }

        private void insertPublishedFacts(Connection connection, CandidateBlockSet blockSet)
                throws SQLException {
            try (PreparedStatement block = connection.prepareStatement("""
                            insert into i07_published_block(
                              revision_id, source_order, block_id, canonical_block)
                            values (?, ?, ?, ?)
                            """);
                    PreparedStatement alias = connection.prepareStatement("""
                            insert into i07_block_alias(
                              alias_identifier, source_document_id, revision_id, block_id)
                            values (?, ?, ?, ?)
                            on conflict (alias_identifier) do nothing
                            """);
                    PreparedStatement aliasTarget = connection.prepareStatement("""
                            select source_document_id, revision_id, block_id
                            from i07_block_alias where alias_identifier = ?
                            """)) {
                for (CandidateBlockSet.Block candidate : blockSet.blocks()) {
                    block.setString(1, blockSet.revisionId());
                    block.setInt(2, candidate.sourceOrder());
                    block.setString(3, candidate.documentBlockId());
                    block.setBytes(4, candidate.canonicalBytes());
                    requireOne(block.executeUpdate(), "PUBLISHED_BLOCK_INSERT");
                    String identifier = candidate.documentBlockAlias();
                    alias.setString(1, identifier);
                    alias.setString(2, blockSet.sourceDocumentId());
                    alias.setString(3, blockSet.revisionId());
                    alias.setString(4, candidate.documentBlockId());
                    if (alias.executeUpdate() == 0) {
                        aliasTarget.setString(1, identifier);
                        try (ResultSet result = aliasTarget.executeQuery()) {
                            if (!result.next()
                                    || !blockSet.sourceDocumentId().equals(result.getString(1))
                                    || !blockSet.revisionId().equals(result.getString(2))
                                    || !candidate.documentBlockId().equals(result.getString(3))) {
                                throw new SQLException("REFERENCE_ALIAS_CONFLICT");
                            }
                        }
                    }
                }
            }
        }

        private static void insertStageRecord(
                Connection connection,
                AttemptFence fence,
                String status,
                String digest,
                SourceDomainException.Code failureCode,
                String failureDetail,
                Instant createdAt)
                throws SQLException {
            StageFacts facts = loadStageFacts(connection, fence);
            ProcessingPublicationPort.GenerationStageRecord projection = "SUCCEEDED".equals(status)
                    ? ProcessingPublicationPort.GenerationStageRecord.succeeded(
                            facts.sourceDocumentId(),
                            facts.contentSha256(),
                            facts.parserProfileVersion(),
                            fence.revisionId(),
                            fence.attemptId(),
                            facts.attemptNumber(),
                            new BlockSetDigest(digest))
                    : ProcessingPublicationPort.GenerationStageRecord.failed(
                            facts.sourceDocumentId(),
                            facts.contentSha256(),
                            facts.parserProfileVersion(),
                            fence.revisionId(),
                            fence.attemptId(),
                            facts.attemptNumber(),
                            failureCode,
                            failureDetail);
            try (PreparedStatement insert = connection.prepareStatement("""
                            insert into i07_stage_record(
                              revision_id, attempt_id, terminal_status,
                              block_set_digest, schema_version, run_id, stage_name,
                              input_hash, prompt_version, model, source_block_refs,
                              output_kind, output_schema_id, structured_output,
                              output_hash, validation_result, generation_status,
                              retry_count, retry_scope_refs, failure_code,
                              failure_detail, failure_retryable,
                              failure_revision_scope, created_at)
                            values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                                    ?, ?, ?, ?)
                            """)) {
                insert.setString(1, fence.revisionId());
                insert.setString(2, fence.attemptId());
                insert.setString(3, status);
                insert.setString(4, digest);
                insert.setString(5, projection.schemaVersion());
                insert.setString(6, projection.runId());
                insert.setString(7, projection.stage());
                insert.setString(8, projection.inputHash());
                insert.setString(9, projection.promptVersion());
                insert.setString(10, projection.model());
                insert.setString(11, projection.sourceBlockRefs().toString());
                insert.setString(12, projection.outputKind().name());
                insert.setString(13, projection.outputSchemaId());
                insert.setString(14, projection.structuredOutput() == null
                        ? null : projection.structuredOutput().canonicalJson());
                insert.setString(15, projection.outputHash() == null
                        ? null : projection.outputHash().value());
                insert.setString(16, projection.validationResult().canonicalJson());
                insert.setString(17, projection.generationStatus().name());
                insert.setLong(18, projection.retryCount());
                insert.setString(19, projection.retryScopeRefs().toString());
                insert.setString(20, projection.failure() == null
                        ? null : projection.failure().code().name());
                insert.setString(21, projection.failure() == null
                        ? null : projection.failure().message());
                if (projection.failure() == null) insert.setObject(22, null);
                else insert.setBoolean(22, projection.failure().retryable());
                insert.setString(23, projection.failure() == null
                        ? null : projection.failure().failedScopeRefs().toString());
                setInstant(insert, 24, createdAt);
                requireOne(insert.executeUpdate(), "STAGE_RECORD_INSERT");
            }
        }

        private static StageFacts loadStageFacts(Connection connection, AttemptFence fence)
                throws SQLException {
            try (PreparedStatement query = connection.prepareStatement("""
                            select revision.source_document_id, revision.content_sha256,
                                   revision.parser_profile_version, attempt.attempt_number
                            from i07_revision revision
                            join i07_attempt attempt on attempt.revision_id = revision.revision_id
                            where revision.revision_id = ? and attempt.attempt_id = ?
                            """)) {
                query.setString(1, fence.revisionId());
                query.setString(2, fence.attemptId());
                try (ResultSet result = query.executeQuery()) {
                    if (!result.next()) throw new SQLException("STAGE_FACTS_REQUIRED");
                    return new StageFacts(
                            result.getString(1),
                            result.getString(2),
                            result.getString(3),
                            result.getLong(4));
                }
            }
        }

        private static void updateRevisionFailure(
                Connection connection,
                AttemptFence fence,
                ProcessingAttempt.Status status,
                SourceDomainException.Code code,
                String detail,
                Instant completedAt)
                throws SQLException {
            try (PreparedStatement update = connection.prepareStatement("""
                            update i07_revision
                            set revision_status = ?, active_attempt_id = null,
                                failure_code = ?, failure_detail = ?, completed_at = ?
                            where revision_id = ? and active_attempt_id = ?
                              and current_generation = ?
                            """)) {
                update.setString(1, status.name());
                update.setString(2, code.name());
                update.setString(3, detail);
                setInstant(update, 4, completedAt);
                update.setString(5, fence.revisionId());
                update.setString(6, fence.attemptId());
                update.setLong(7, fence.generation());
                requireOne(update.executeUpdate(), "FAILURE_REVISION_UPDATE");
            }
        }

        private static void appendRejection(
                Connection connection, AttemptFence fence, long currentGeneration, String reason)
                throws SQLException {
            try (PreparedStatement insert = connection.prepareStatement("""
                            insert into i07_rejection_event(
                              revision_id, attempt_id, submitted_generation,
                              current_generation, reason)
                            values (?, ?, ?, ?, ?)
                            """)) {
                insert.setString(1, fence.revisionId());
                insert.setString(2, fence.attemptId());
                insert.setLong(3, fence.generation());
                insert.setLong(4, currentGeneration);
                insert.setString(5, reason);
                requireOne(insert.executeUpdate(), "REJECTION_EVENT_INSERT");
            }
        }

        private static RevisionLock lockRevision(Connection connection, String revisionId)
                throws SQLException {
            try (PreparedStatement query = connection.prepareStatement("""
                            select active_attempt_id, current_generation, published_digest
                            from i07_revision where revision_id = ? for update
                            """)) {
                query.setString(1, revisionId);
                try (ResultSet result = query.executeQuery()) {
                    return result.next()
                            ? new RevisionLock(
                                    result.getString(1), result.getLong(2), result.getString(3))
                            : null;
                }
            }
        }

        private static boolean fenceMatches(Connection connection, AttemptFence fence)
                throws SQLException {
            try (PreparedStatement query = connection.prepareStatement("""
                            select 1
                            from i07_revision revision
                            join i07_attempt attempt
                              on attempt.attempt_id = revision.active_attempt_id
                            where revision.revision_id = ?
                              and revision.active_attempt_id = ?
                              and revision.current_generation = ?
                              and attempt.revision_id = revision.revision_id
                              and attempt.generation = revision.current_generation
                              and attempt.fencing_token = ?
                            """)) {
                query.setString(1, fence.revisionId());
                query.setString(2, fence.attemptId());
                query.setLong(3, fence.generation());
                query.setString(4, fence.fencingToken());
                try (ResultSet result = query.executeQuery()) {
                    return result.next();
                }
            }
        }

        private static boolean revisionSourceMatches(
                Connection connection, CandidateBlockSet blockSet) throws SQLException {
            try (PreparedStatement query = connection.prepareStatement("""
                            select 1 from i07_revision
                            where revision_id = ? and source_document_id = ?
                            """)) {
                query.setString(1, blockSet.revisionId());
                query.setString(2, blockSet.sourceDocumentId());
                try (ResultSet result = query.executeQuery()) {
                    return result.next();
                }
            }
        }

        private static ProcessingAttempt.Status attemptStatus(Connection connection, String attemptId)
                throws SQLException {
            try (PreparedStatement query = connection.prepareStatement(
                    "select attempt_status from i07_attempt where attempt_id = ?")) {
                query.setString(1, attemptId);
                try (ResultSet result = query.executeQuery()) {
                    return result.next()
                            ? ProcessingAttempt.Status.valueOf(result.getString(1))
                            : null;
                }
            }
        }

        private static void bindPendingAttempt(
                PreparedStatement statement,
                BeginAttempt command,
                long attemptNumber,
                long generation)
                throws SQLException {
            statement.setString(1, command.attemptId());
            statement.setString(2, command.revisionId());
            statement.setLong(3, attemptNumber);
            statement.setLong(4, generation);
            statement.setString(5, AttemptFence.fencingTokenFor(command.revisionId(), generation));
            setInstant(statement, 6, command.claimDeadline());
            setInstant(statement, 7, command.startedAt());
        }

        private static void bindBlock(
                PreparedStatement statement,
                String attemptId,
                CandidateBlockSet.Block block)
                throws SQLException {
            statement.setString(1, attemptId);
            statement.setInt(2, block.sourceOrder());
            statement.setString(3, block.documentBlockId());
            statement.setBytes(4, block.canonicalBytes());
        }

        private static void setInstant(PreparedStatement statement, int index, Instant instant)
                throws SQLException {
            statement.setTimestamp(index, Timestamp.from(instant));
        }

        private static void requireOne(int affectedRows, String operation) throws SQLException {
            if (affectedRows != 1) {
                throw new SQLException(operation + "_COUNT_MUST_BE_ONE");
            }
        }

        private static boolean hasSqlState(Throwable error, String sqlState) {
            Throwable current = error;
            while (current != null) {
                if (current instanceof SQLException sqlException
                        && sqlState.equals(sqlException.getSQLState())) {
                    return true;
                }
                current = current.getCause();
            }
            return false;
        }

        private Connection openConnection() throws SQLException {
            return DriverManager.getConnection(jdbcUrl, username, password);
        }

        private <T> T transaction(SqlTransaction<T> transaction) {
            try (Connection connection = openConnection()) {
                connection.setAutoCommit(false);
                try {
                    T result = transaction.execute(connection);
                    connection.commit();
                    return result;
                } catch (SQLException | RuntimeException error) {
                    connection.rollback();
                    throw error;
                }
            } catch (SQLException error) {
                throw new StorageException("I07_STORAGE_FAILURE:" + error.getMessage(), error);
            }
        }

        private void executeStatement(String sql) {
            try (Connection connection = openConnection();
                    Statement statement = connection.createStatement()) {
                statement.execute(sql);
            } catch (SQLException error) {
                throw new StorageException("I07_STORAGE_FAILURE:" + error.getMessage(), error);
            }
        }

        private void update(String sql, SqlBinder binder) {
            try (Connection connection = openConnection();
                    PreparedStatement statement = connection.prepareStatement(sql)) {
                binder.bind(statement);
                statement.executeUpdate();
            } catch (SQLException error) {
                throw new StorageException("I07_STORAGE_FAILURE:" + error.getMessage(), error);
            }
        }

        private java.util.Optional<String> queryText(String sql, String identity) {
            try (Connection connection = openConnection();
                    PreparedStatement statement = connection.prepareStatement(sql)) {
                if (identity != null) statement.setString(1, identity);
                try (ResultSet result = statement.executeQuery()) {
                    return result.next()
                            ? java.util.Optional.ofNullable(result.getString(1))
                            : java.util.Optional.empty();
                }
            } catch (SQLException error) {
                throw new StorageException("I07_STORAGE_FAILURE:" + error.getMessage(), error);
            }
        }

        private String queryNullableText(String sql, String identity) {
            return queryText(sql, identity).orElse(null);
        }

        private int count(String sql, String identity) {
            try (Connection connection = openConnection();
                    PreparedStatement statement = connection.prepareStatement(sql)) {
                if (identity != null) statement.setString(1, identity);
                try (ResultSet result = statement.executeQuery()) {
                    if (!result.next()) {
                        throw new SQLException("COUNT_RESULT_REQUIRED");
                    }
                    return result.getInt(1);
                }
            } catch (SQLException error) {
                throw new StorageException("I07_STORAGE_FAILURE:" + error.getMessage(), error);
            }
        }

        private record RevisionLock(
                String activeAttemptId, long currentGeneration, String publishedDigest) {

            boolean matches(AttemptFence fence) {
                return fence.attemptId().equals(activeAttemptId)
                        && fence.generation() == currentGeneration;
            }
        }

        private record StageFacts(
                String sourceDocumentId,
                String contentSha256,
                String parserProfileVersion,
                long attemptNumber) {}

        @FunctionalInterface
        private interface SqlTransaction<T> {
            T execute(Connection connection) throws SQLException;
        }

        @FunctionalInterface
        private interface SqlBinder {
            void bind(PreparedStatement statement) throws SQLException;
        }
    }
}
