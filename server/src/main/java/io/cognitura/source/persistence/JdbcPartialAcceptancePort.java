package io.cognitura.source.persistence;

import io.cognitura.source.api.acceptance.PartialAcceptanceCommand;
import io.cognitura.source.api.acceptance.PartialAcceptancePort;
import io.cognitura.source.application.command.TrustedRequestContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Objects;
import javax.sql.DataSource;

public final class JdbcPartialAcceptancePort implements PartialAcceptancePort {

    private final DataSource dataSource;

    public JdbcPartialAcceptancePort(DataSource dataSource) {
        this.dataSource = Objects.requireNonNull(dataSource, "dataSource");
    }

    @Override
    public Outcome accept(
            TrustedRequestContext context,
            PartialAcceptanceCommand command,
            Instant acceptedAt) {
        Objects.requireNonNull(context, "context");
        Objects.requireNonNull(command, "command");
        Objects.requireNonNull(acceptedAt, "acceptedAt");
        try (Connection connection = dataSource.getConnection()) {
            connection.setAutoCommit(false);
            connection.setTransactionIsolation(Connection.TRANSACTION_READ_COMMITTED);
            try {
                Accepted accepted = update(connection, context, command, acceptedAt);
                Outcome outcome = accepted != null
                        ? accepted
                        : classify(connection, context, command);
                connection.commit();
                return outcome;
            } catch (SQLException failure) {
                rollback(connection, failure);
                throw new PersistenceFailure(failure);
            }
        } catch (SQLException failure) {
            throw new PersistenceFailure(failure);
        }
    }

    private static Accepted update(
            Connection connection,
            TrustedRequestContext context,
            PartialAcceptanceCommand command,
            Instant acceptedAt) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("""
                update source_processing_revision as revision
                set partial_acceptance_status = 'ACCEPTED',
                    partial_accepted_at = ?,
                    partial_accepted_by = ?,
                    partial_acceptance_idempotency_key = ?
                from source_document as document
                where document.source_document_id = revision.source_document_id
                  and document.workspace_id = ?
                  and document.source_document_id = ?
                  and revision.source_processing_revision_id = ?
                  and revision.revision_status = 'PREVIEW_READY'
                  and revision.parse_completeness = 'PARTIAL'
                  and revision.partial_acceptance_status = 'PENDING'
                  and revision.published_digest = ?
                  and revision.omissions_digest = ?
                returning revision.partial_accepted_at, revision.partial_accepted_by
                """)) {
            statement.setObject(1, OffsetDateTime.ofInstant(acceptedAt, ZoneOffset.UTC));
            statement.setString(2, context.actorId());
            statement.setString(3, command.idempotencyKey());
            statement.setString(4, context.workspaceId());
            statement.setString(5, command.sourceDocumentId());
            statement.setString(6, command.sourceProcessingRevisionId());
            statement.setString(7, command.blockSetDigest());
            statement.setString(8, command.omissionsDigest());
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) {
                    return null;
                }
                Accepted accepted = new Accepted(
                        command.sourceDocumentId(),
                        command.sourceProcessingRevisionId(),
                        result.getObject(1, OffsetDateTime.class).toInstant(),
                        result.getString(2),
                        false);
                if (result.next()) {
                    throw new SQLException("PARTIAL_ACCEPTANCE_UPDATE_NOT_UNIQUE");
                }
                return accepted;
            }
        }
    }

    private static Outcome classify(
            Connection connection,
            TrustedRequestContext context,
            PartialAcceptanceCommand command) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("""
                select revision.revision_status, revision.parse_completeness,
                       revision.partial_acceptance_status,
                       revision.published_digest, revision.omissions_digest,
                       revision.partial_accepted_at, revision.partial_accepted_by,
                       revision.partial_acceptance_idempotency_key
                from source_document as document
                join source_processing_revision as revision
                  on revision.source_document_id = document.source_document_id
                where document.workspace_id = ?
                  and document.source_document_id = ?
                  and revision.source_processing_revision_id = ?
                """)) {
            statement.setString(1, context.workspaceId());
            statement.setString(2, command.sourceDocumentId());
            statement.setString(3, command.sourceProcessingRevisionId());
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) {
                    return new Rejected(Rejection.RESOURCE_NOT_FOUND);
                }
                String revisionStatus = result.getString(1);
                String parseCompleteness = result.getString(2);
                String acceptanceStatus = result.getString(3);
                String blockDigest = result.getString(4);
                String omissionsDigest = result.getString(5);
                OffsetDateTime storedAt = result.getObject(6, OffsetDateTime.class);
                String storedActor = result.getString(7);
                String storedKey = result.getString(8);
                if (result.next()) {
                    return new Rejected(Rejection.PARTIAL_ACCEPTANCE_CONFLICT);
                }
                if ("ACCEPTED".equals(acceptanceStatus)
                        && command.blockSetDigest().equals(blockDigest)
                        && command.omissionsDigest().equals(omissionsDigest)
                        && context.actorId().equals(storedActor)
                        && command.idempotencyKey().equals(storedKey)
                        && storedAt != null) {
                    return new Accepted(
                            command.sourceDocumentId(),
                            command.sourceProcessingRevisionId(),
                            storedAt.toInstant(), storedActor, true);
                }
                if (!"PREVIEW_READY".equals(revisionStatus)) {
                    return new Rejected(Rejection.PREVIEW_NOT_READY);
                }
                if (!"PARTIAL".equals(parseCompleteness)) {
                    return new Rejected(Rejection.PARTIAL_ACCEPTANCE_CONFLICT);
                }
                return new Rejected(Rejection.PARTIAL_ACCEPTANCE_CONFLICT);
            }
        }
    }

    private static void rollback(Connection connection, SQLException failure) {
        try {
            connection.rollback();
        } catch (SQLException rollbackFailure) {
            failure.addSuppressed(rollbackFailure);
        }
    }
}
