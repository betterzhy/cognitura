package io.cognitura.source.persistence;

import io.cognitura.source.application.processing.AttemptFence;
import io.cognitura.source.application.processing.AttemptLease;
import io.cognitura.source.application.processing.BlockSetDigest;
import io.cognitura.source.application.processing.CandidateBlockSet;
import io.cognitura.source.application.processing.ProcessingAttempt;
import io.cognitura.source.application.processing.ProcessingPublicationPort;
import io.cognitura.source.domain.SourceDomainException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.Arrays;
import java.util.Objects;
import javax.sql.DataSource;

public final class JdbcProcessingPublicationPort implements ProcessingPublicationPort {

    private final DataSource dataSource;

    public JdbcProcessingPublicationPort(DataSource dataSource) {
        this.dataSource = Objects.requireNonNull(dataSource, "dataSource");
    }

    @Override
    public BeginResult beginInitial(BeginAttempt command) {
        Objects.requireNonNull(command, "command");
        try {
            return transaction(connection -> {
                if (!acceptedSourceMatches(connection, command)) {
                    return BeginResult.rejected(Outcome.RETRY_NOT_ALLOWED);
                }
                try (PreparedStatement existing = connection.prepareStatement("""
                                select active_attempt_id, published_digest
                                from source_processing_revision
                                where source_processing_revision_id = ? for update
                                """)) {
                    existing.setString(1, command.revisionId());
                    try (ResultSet result = existing.executeQuery()) {
                        if (result.next()) {
                            return BeginResult.rejected(
                                    result.getString("published_digest") == null
                                            ? Outcome.ACTIVE_ATTEMPT_EXISTS
                                            : Outcome.ALREADY_PUBLISHED);
                        }
                    }
                }
                try (PreparedStatement revision = connection.prepareStatement("""
                                insert into source_processing_revision(
                                  source_processing_revision_id, source_document_id,
                                  content_sha256, parser_profile_version, revision_status,
                                  started_at, active_attempt_id, current_generation)
                                values (?, ?, ?, ?, 'PARSING', ?, ?, 1)
                                """);
                        PreparedStatement attempt = connection.prepareStatement("""
                                insert into source_processing_attempt(
                                  attempt_id, source_processing_revision_id, attempt_number,
                                  generation, fencing_token, attempt_status,
                                  lease_expires_at, started_at)
                                values (?, ?, 1, 1, ?, 'PENDING', ?, ?)
                                """)) {
                    revision.setString(1, command.revisionId());
                    revision.setString(2, command.sourceDocumentId());
                    revision.setString(3, command.contentSha256());
                    revision.setString(4, command.parserProfileVersion());
                    setInstant(revision, 5, command.startedAt());
                    revision.setString(6, command.attemptId());
                    requireOne(revision.executeUpdate(), "INITIAL_REVISION_INSERT");

                    attempt.setString(1, command.attemptId());
                    attempt.setString(2, command.revisionId());
                    attempt.setString(3, AttemptFence.fencingTokenFor(command.revisionId(), 1));
                    setInstant(attempt, 4, command.claimDeadline());
                    setInstant(attempt, 5, command.startedAt());
                    requireOne(attempt.executeUpdate(), "INITIAL_ATTEMPT_INSERT");
                }
                return BeginResult.applied(ProcessingAttempt.pending(
                        command.revisionId(), command.attemptId(), 1, 1,
                        command.claimDeadline(), command.startedAt()));
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
        Objects.requireNonNull(command, "command");
        return transaction(connection -> {
            long nextGeneration;
            try (PreparedStatement query = connection.prepareStatement("""
                            select revision_status, active_attempt_id, current_generation,
                                   published_digest, source_document_id, content_sha256,
                                   parser_profile_version
                            from source_processing_revision
                            where source_processing_revision_id = ? for update
                            """)) {
                query.setString(1, command.revisionId());
                try (ResultSet result = query.executeQuery()) {
                    if (!result.next()) return BeginResult.rejected(Outcome.RETRY_NOT_ALLOWED);
                    if (result.getString("published_digest") != null) {
                        return BeginResult.rejected(Outcome.ALREADY_PUBLISHED);
                    }
                    if (!"FAILED_RETRYABLE".equals(result.getString("revision_status"))
                            || result.getString("active_attempt_id") != null
                            || !command.sourceDocumentId().equals(
                                    result.getString("source_document_id"))
                            || !command.contentSha256().equals(result.getString("content_sha256"))
                            || !command.parserProfileVersion().equals(
                                    result.getString("parser_profile_version"))) {
                        return BeginResult.rejected(Outcome.RETRY_NOT_ALLOWED);
                    }
                    nextGeneration = result.getLong("current_generation") + 1;
                }
            }
            try (PreparedStatement attempt = connection.prepareStatement("""
                            insert into source_processing_attempt(
                              attempt_id, source_processing_revision_id, attempt_number,
                              generation, fencing_token, attempt_status,
                              lease_expires_at, started_at)
                            values (?, ?, ?, ?, ?, 'PENDING', ?, ?)
                            """);
                    PreparedStatement revision = connection.prepareStatement("""
                            update source_processing_revision
                            set revision_status = 'PARSING', active_attempt_id = ?,
                                current_generation = ?, failure_code = null,
                                failure_detail = null, completed_at = null
                            where source_processing_revision_id = ?
                              and revision_status = 'FAILED_RETRYABLE'
                              and active_attempt_id is null
                            """)) {
                bindPendingAttempt(attempt, command, nextGeneration, nextGeneration);
                requireOne(attempt.executeUpdate(), "RETRY_ATTEMPT_INSERT");
                revision.setString(1, command.attemptId());
                revision.setLong(2, nextGeneration);
                revision.setString(3, command.revisionId());
                requireOne(revision.executeUpdate(), "RETRY_REVISION_UPDATE");
            }
            return BeginResult.applied(ProcessingAttempt.pending(
                    command.revisionId(), command.attemptId(), nextGeneration, nextGeneration,
                    command.claimDeadline(), command.startedAt()));
        });
    }

    @Override
    public Outcome claim(AttemptFence fence, AttemptLease lease, Instant observedAt) {
        Objects.requireNonNull(fence, "fence");
        Objects.requireNonNull(lease, "lease");
        Objects.requireNonNull(observedAt, "observedAt");
        if (lease.expectedStatus() != ProcessingAttempt.Status.PENDING) return Outcome.STALE_LEASE;
        return extendLease(fence, lease, observedAt, "RUNNING");
    }

    @Override
    public Outcome heartbeat(AttemptFence fence, AttemptLease lease, Instant observedAt) {
        Objects.requireNonNull(fence, "fence");
        Objects.requireNonNull(lease, "lease");
        Objects.requireNonNull(observedAt, "observedAt");
        if (lease.expectedStatus() != ProcessingAttempt.Status.RUNNING) return Outcome.STALE_LEASE;
        return extendLease(fence, lease, observedAt, "RUNNING");
    }

    private Outcome extendLease(
            AttemptFence fence, AttemptLease lease, Instant observedAt, String targetStatus) {
        return transaction(connection -> {
            if (!fenceMatches(connection, fence)) return Outcome.STALE_FENCE;
            try (PreparedStatement update = connection.prepareStatement("""
                            update source_processing_attempt
                            set attempt_status = ?, lease_expires_at = ?, heartbeat_at = ?
                            where attempt_id = ? and source_processing_revision_id = ?
                              and generation = ? and fencing_token = ?
                              and attempt_status = ? and lease_expires_at = ?
                              and lease_expires_at > ?
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
        Objects.requireNonNull(fence, "fence");
        Objects.requireNonNull(lease, "lease");
        Objects.requireNonNull(timedOutAt, "timedOutAt");
        return transaction(connection -> {
            RevisionLock revision = lockRevision(connection, fence.revisionId());
            if (revision == null || !revision.matches(fence) || !fenceMatches(connection, fence)) {
                return Outcome.STALE_FENCE;
            }
            String detail = "LEASE_EXPIRED:observed active lease expired";
            try (PreparedStatement attempt = connection.prepareStatement("""
                            update source_processing_attempt
                            set attempt_status = 'FAILED_RETRYABLE', lease_expires_at = null,
                                failure_code = 'PARSER_RETRYABLE_FAILURE',
                                failure_detail = ?, completed_at = ?
                            where attempt_id = ? and source_processing_revision_id = ?
                              and generation = ? and fencing_token = ?
                              and attempt_status = ? and lease_expires_at = ?
                              and lease_expires_at <= ?
                            """)) {
                attempt.setString(1, detail);
                setInstant(attempt, 2, timedOutAt);
                attempt.setString(3, fence.attemptId());
                attempt.setString(4, fence.revisionId());
                attempt.setLong(5, fence.generation());
                attempt.setString(6, fence.fencingToken());
                attempt.setString(7, lease.expectedStatus().name());
                setInstant(attempt, 8, lease.observedLeaseExpiresAt());
                setInstant(attempt, 9, timedOutAt);
                if (attempt.executeUpdate() != 1) return Outcome.STALE_LEASE;
            }
            updateRevisionFailure(
                    connection, fence, ProcessingAttempt.Status.FAILED_RETRYABLE,
                    SourceDomainException.Code.PARSER_RETRYABLE_FAILURE, detail, timedOutAt);
            insertStageRecord(
                    connection, fence, "FAILED_RETRYABLE", null,
                    SourceDomainException.Code.PARSER_RETRYABLE_FAILURE, detail, timedOutAt);
            return Outcome.APPLIED;
        });
    }

    @Override
    public Outcome stage(AttemptFence fence, CandidateBlockSet blockSet) {
        Objects.requireNonNull(fence, "fence");
        Objects.requireNonNull(blockSet, "blockSet");
        return transaction(connection -> {
            if (!fence.revisionId().equals(blockSet.revisionId())
                    || !fence.attemptId().equals(blockSet.attemptId())
                    || !revisionSourceMatches(connection, blockSet)) {
                return Outcome.BLOCK_SET_MISMATCH;
            }
            if (!fenceMatches(connection, fence)
                    || attemptStatus(connection, fence.attemptId())
                            != ProcessingAttempt.Status.RUNNING) {
                return Outcome.STALE_FENCE;
            }
            BlockSetDigest digest = BlockSetDigest.compute(blockSet);
            try (PreparedStatement header = connection.prepareStatement("""
                            insert into source_processing_staged_set(
                              attempt_id, source_document_id,
                              source_processing_revision_id, parse_completeness,
                              partial_acceptance_status, block_set_digest,
                              omissions_digest, omissions_canonical, revision_diagnostics)
                            values (?, ?, ?, ?, ?, ?, ?, ?, ?)
                            """);
                    PreparedStatement block = connection.prepareStatement("""
                            insert into source_processing_staged_block(
                              attempt_id, source_order, document_block_id, canonical_block)
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
        Objects.requireNonNull(fence, "fence");
        Objects.requireNonNull(blockSet, "blockSet");
        Objects.requireNonNull(blockSetDigest, "blockSetDigest");
        Objects.requireNonNull(completedAt, "completedAt");
        return transaction(connection -> {
            RevisionLock revision = lockRevision(connection, fence.revisionId());
            if (revision == null) {
                appendRejection(connection, fence, 0, "REVISION_MISSING");
                return Outcome.STALE_FENCE;
            }
            if (revision.publishedDigest() != null) {
                appendRejection(
                        connection, fence, revision.currentGeneration(),
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
                    connection, fence, "SUCCEEDED", blockSetDigest.value(),
                    null, null, completedAt);
            try (PreparedStatement attempt = connection.prepareStatement("""
                            update source_processing_attempt
                            set attempt_status = 'SUCCEEDED', lease_expires_at = null,
                                completed_at = ?
                            where attempt_id = ? and attempt_status = 'RUNNING'
                            """);
                    PreparedStatement revisionUpdate = connection.prepareStatement("""
                            update source_processing_revision
                            set revision_status = 'PARSED', active_attempt_id = null,
                                published_digest = ?, omissions_digest = ?,
                                revision_diagnostics = ?, parse_completeness = ?,
                                partial_acceptance_status = ?, completed_at = ?
                            where source_processing_revision_id = ?
                              and active_attempt_id = ? and current_generation = ?
                            """)) {
                setInstant(attempt, 1, completedAt);
                attempt.setString(2, fence.attemptId());
                requireOne(attempt.executeUpdate(), "PUBLISH_ATTEMPT_UPDATE");
                revisionUpdate.setString(1, blockSetDigest.value());
                revisionUpdate.setString(2, blockSet.omissionsDigest().value());
                revisionUpdate.setBytes(3, blockSet.canonicalRevisionDiagnosticsBytes());
                revisionUpdate.setString(4, blockSet.parseCompleteness().name());
                revisionUpdate.setString(5, blockSet.partialAcceptanceStatus().name());
                setInstant(revisionUpdate, 6, completedAt);
                revisionUpdate.setString(7, fence.revisionId());
                revisionUpdate.setString(8, fence.attemptId());
                revisionUpdate.setLong(9, fence.generation());
                requireOne(revisionUpdate.executeUpdate(), "PUBLISH_REVISION_UPDATE");
            }
            return Outcome.APPLIED;
        });
    }

    @Override
    public Outcome fail(AttemptFence fence, Failure failure) {
        Objects.requireNonNull(fence, "fence");
        Objects.requireNonNull(failure, "failure");
        return transaction(connection -> {
            RevisionLock revision = lockRevision(connection, fence.revisionId());
            if (revision == null || !revision.matches(fence) || !fenceMatches(connection, fence)) {
                return Outcome.STALE_FENCE;
            }
            try (PreparedStatement attempt = connection.prepareStatement("""
                            update source_processing_attempt
                            set attempt_status = ?, lease_expires_at = null,
                                failure_code = ?, failure_detail = ?, completed_at = ?
                            where attempt_id = ? and source_processing_revision_id = ?
                              and generation = ? and fencing_token = ?
                              and ((? = 'FAILED_RETRYABLE'
                                    and attempt_status in ('PENDING', 'RUNNING'))
                                or (? = 'FAILED_TERMINAL'
                                    and attempt_status = 'RUNNING'))
                            """)) {
                attempt.setString(1, failure.terminalStatus().name());
                attempt.setString(2, failure.failureCode().name());
                attempt.setString(3, failure.failureDetail());
                setInstant(attempt, 4, failure.completedAt());
                attempt.setString(5, fence.attemptId());
                attempt.setString(6, fence.revisionId());
                attempt.setLong(7, fence.generation());
                attempt.setString(8, fence.fencingToken());
                attempt.setString(9, failure.terminalStatus().name());
                attempt.setString(10, failure.terminalStatus().name());
                if (attempt.executeUpdate() != 1) return Outcome.STALE_FENCE;
            }
            updateRevisionFailure(
                    connection, fence, failure.terminalStatus(), failure.failureCode(),
                    failure.failureDetail(), failure.completedAt());
            insertStageRecord(
                    connection, fence, failure.terminalStatus().name(), null,
                    failure.failureCode(), failure.failureDetail(), failure.completedAt());
            return Outcome.APPLIED;
        });
    }

    private static boolean acceptedSourceMatches(Connection connection, BeginAttempt command)
            throws SQLException {
        try (PreparedStatement query = connection.prepareStatement("""
                        select validation_status, content_sha256
                        from source_document where source_document_id = ? for share
                        """)) {
            query.setString(1, command.sourceDocumentId());
            try (ResultSet result = query.executeQuery()) {
                return result.next()
                        && "ACCEPTED".equals(result.getString(1))
                        && command.contentSha256().equals(result.getString(2));
            }
        }
    }

    private static CandidateBlockSet loadStaged(
            Connection connection, CandidateBlockSet expected, String attemptId)
            throws SQLException {
        String declaredDigest;
        try (PreparedStatement header = connection.prepareStatement("""
                        select source_document_id, source_processing_revision_id,
                               parse_completeness, partial_acceptance_status,
                               block_set_digest, omissions_digest,
                               omissions_canonical, revision_diagnostics
                        from source_processing_staged_set where attempt_id = ?
                        """)) {
            header.setString(1, attemptId);
            try (ResultSet result = header.executeQuery()) {
                if (!result.next()) return null;
                if (!expected.sourceDocumentId().equals(result.getString(1))
                        || !expected.revisionId().equals(result.getString(2))
                        || !expected.parseCompleteness().name().equals(result.getString(3))
                        || !expected.partialAcceptanceStatus().name().equals(result.getString(4))
                        || !expected.omissionsDigest().value().equals(result.getString(6))
                        || !Arrays.equals(expected.canonicalOmissionsBytes(), result.getBytes(7))
                        || !Arrays.equals(
                                expected.canonicalRevisionDiagnosticsBytes(), result.getBytes(8))) {
                    return null;
                }
                declaredDigest = result.getString(5);
            }
        }
        try (PreparedStatement blocks = connection.prepareStatement("""
                        select document_block_id, source_order, canonical_block
                        from source_processing_staged_block
                        where attempt_id = ? order by source_order
                        """)) {
            blocks.setString(1, attemptId);
            try (ResultSet result = blocks.executeQuery()) {
                for (CandidateBlockSet.Block expectedBlock : expected.blocks()) {
                    if (!result.next()
                            || !expectedBlock.documentBlockId().equals(result.getString(1))
                            || expectedBlock.sourceOrder() != result.getInt(2)
                            || !Arrays.equals(expectedBlock.canonicalBytes(), result.getBytes(3))) {
                        return null;
                    }
                }
                if (result.next()) return null;
            }
        }
        return BlockSetDigest.compute(expected).value().equals(declaredDigest) ? expected : null;
    }

    private static void insertPublishedFacts(Connection connection, CandidateBlockSet blockSet)
            throws SQLException {
        try (PreparedStatement block = connection.prepareStatement("""
                        insert into source_document_block(
                          source_processing_revision_id, source_order,
                          document_block_id, canonical_block)
                        values (?, ?, ?, ?)
                        """);
                PreparedStatement alias = connection.prepareStatement("""
                        insert into source_reference_alias(
                          alias_identifier, source_document_id,
                          source_processing_revision_id, document_block_id)
                        values (?, ?, ?, ?)
                        on conflict (alias_identifier) do nothing
                        """);
                PreparedStatement target = connection.prepareStatement("""
                        select source_document_id, source_processing_revision_id,
                               document_block_id
                        from source_reference_alias where alias_identifier = ?
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
                    target.setString(1, identifier);
                    try (ResultSet result = target.executeQuery()) {
                        if (!result.next()
                                || !blockSet.sourceDocumentId().equals(result.getString(1))
                                || !blockSet.revisionId().equals(result.getString(2))
                                || !candidate.documentBlockId().equals(result.getString(3))) {
                            throw new SQLException("REFERENCE_ALIAS_CONFLICT", "23505");
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
        GenerationStageRecord projection = "SUCCEEDED".equals(status)
                ? GenerationStageRecord.succeeded(
                        facts.sourceDocumentId(), facts.contentSha256(),
                        facts.parserProfileVersion(), fence.revisionId(), fence.attemptId(),
                        facts.attemptNumber(), new BlockSetDigest(digest))
                : GenerationStageRecord.failed(
                        facts.sourceDocumentId(), facts.contentSha256(),
                        facts.parserProfileVersion(), fence.revisionId(), fence.attemptId(),
                        facts.attemptNumber(), failureCode, failureDetail);
        try (PreparedStatement insert = connection.prepareStatement("""
                        insert into source_generation_stage_record(
                          source_processing_revision_id, attempt_id, terminal_status,
                          block_set_digest, schema_version, run_id, stage_name,
                          input_hash, prompt_version, model, source_block_refs,
                          output_kind, output_schema_id, structured_output,
                          output_hash, validation_result, generation_status,
                          retry_count, retry_scope_refs, failure_code,
                          failure_detail, failure_retryable,
                          failure_revision_scope, created_at)
                        values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?::jsonb, ?, ?::jsonb,
                                ?, ?, ?, ?, ?, ?, ?, ?)
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
                        from source_processing_revision revision
                        join source_processing_attempt attempt
                          on attempt.source_processing_revision_id =
                             revision.source_processing_revision_id
                        where revision.source_processing_revision_id = ?
                          and attempt.attempt_id = ?
                        """)) {
            query.setString(1, fence.revisionId());
            query.setString(2, fence.attemptId());
            try (ResultSet result = query.executeQuery()) {
                if (!result.next()) throw new SQLException("STAGE_FACTS_REQUIRED");
                return new StageFacts(
                        result.getString(1), result.getString(2),
                        result.getString(3), result.getLong(4));
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
                        update source_processing_revision
                        set revision_status = ?, active_attempt_id = null,
                            failure_code = ?, failure_detail = ?, completed_at = ?
                        where source_processing_revision_id = ?
                          and active_attempt_id = ? and current_generation = ?
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
                        insert into source_processing_rejection_event(
                          source_processing_revision_id, attempt_id,
                          submitted_generation, current_generation, reason)
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
                        from source_processing_revision
                        where source_processing_revision_id = ? for update
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
                        from source_processing_revision revision
                        join source_processing_attempt attempt
                          on attempt.attempt_id = revision.active_attempt_id
                        where revision.source_processing_revision_id = ?
                          and revision.active_attempt_id = ?
                          and revision.current_generation = ?
                          and attempt.source_processing_revision_id =
                              revision.source_processing_revision_id
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
                        select 1 from source_processing_revision
                        where source_processing_revision_id = ? and source_document_id = ?
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
        try (PreparedStatement query = connection.prepareStatement("""
                        select attempt_status from source_processing_attempt
                        where attempt_id = ?
                        """)) {
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
            PreparedStatement statement, String attemptId, CandidateBlockSet.Block block)
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
        if (affectedRows != 1) throw new SQLException(operation + "_COUNT_MUST_BE_ONE");
    }

    private static boolean hasSqlState(Throwable error, String sqlState) {
        Throwable current = error;
        while (current != null) {
            if (current instanceof SQLException sql && sqlState.equals(sql.getSQLState())) {
                return true;
            }
            current = current.getCause();
        }
        return false;
    }

    private <T> T transaction(SqlTransaction<T> transaction) {
        try (Connection connection = dataSource.getConnection()) {
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
            throw new StorageException("PROCESSING_PUBLICATION_STORAGE_FAILURE", error);
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
}
