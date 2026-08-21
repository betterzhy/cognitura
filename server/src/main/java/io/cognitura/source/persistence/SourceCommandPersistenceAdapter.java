package io.cognitura.source.persistence;

import io.cognitura.source.application.command.SourceCommandException;
import io.cognitura.source.application.command.SourceCommandPersistencePort;
import io.cognitura.source.domain.SourceBinary;
import io.cognitura.source.domain.SourceDocument;
import io.cognitura.source.domain.SourceHash;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Objects;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;

public final class SourceCommandPersistenceAdapter implements SourceCommandPersistencePort {

    private final SqlSessionFactory sessionFactory;

    public SourceCommandPersistenceAdapter(SqlSessionFactory sessionFactory) {
        this.sessionFactory = Objects.requireNonNull(sessionFactory, "sessionFactory");
    }

    @Override
    public RegistrationOutcome registerUpload(UploadRegistration registration) {
        Objects.requireNonNull(registration, "registration");
        try (SqlSession session = sessionFactory.openSession(false)) {
            try {
                acquireIdempotencyLock(session, registration.workspaceId(), registration.idempotencyKey());
                SourceCommandMapper mapper = session.getMapper(SourceCommandMapper.class);
                SourceCommandMapper.DocumentRow existing = mapper.selectDocumentByIdempotencyKey(
                        registration.workspaceId(), registration.idempotencyKey());
                if (existing != null) {
                    if (!existing.contentSha256().equals(registration.contentSha256().value())) {
                        throw SourceCommandException.idempotencyConflict();
                    }
                    SourceCommandMapper.BinaryRow binary =
                            mapper.selectBinaryByHash(existing.contentSha256());
                    RegistrationOutcome replay = new RegistrationOutcome(
                            toDomain(existing), requireMatchingBinary(binary, registration), false, false);
                    session.commit();
                    return replay;
                }

                SourceCommandMapper.BinaryRow proposedBinary = new SourceCommandMapper.BinaryRow(
                        registration.sourceBinaryId(),
                        registration.contentSha256().value(),
                        registration.byteLength(),
                        registration.mediaType(),
                        registration.binaryLocation(),
                        registration.receivedAt());
                boolean createdBinary = mapper.insertBinaryIfAbsent(proposedBinary) == 1;
                SourceCommandMapper.BinaryRow binary =
                        mapper.selectBinaryByHash(registration.contentSha256().value());
                SourceBinary sourceBinary = requireMatchingBinary(binary, registration);

                SourceCommandMapper.DocumentRow document = new SourceCommandMapper.DocumentRow(
                        registration.sourceDocumentId(),
                        registration.workspaceId(),
                        sourceBinary.sourceBinaryId(),
                        registration.originalFileName(),
                        registration.mediaType(),
                        registration.byteLength(),
                        registration.contentSha256().value(),
                        registration.receivedAt(),
                        registration.idempotencyKey(),
                        SourceDocument.ValidationStatus.RECEIVED.name());
                if (mapper.insertDocument(document) != 1) {
                    throw new IllegalStateException("SOURCE_DOCUMENT_INSERT_COUNT_INVALID");
                }
                session.commit();
                return new RegistrationOutcome(
                        toDomain(document), sourceBinary, true, createdBinary);
            } catch (SourceCommandException error) {
                session.rollback();
                throw error;
            } catch (RuntimeException | SQLException error) {
                session.rollback();
                throw SourceCommandException.persistenceFailure(error);
            }
        }
    }

    private static void acquireIdempotencyLock(
            SqlSession session, String workspaceId, String idempotencyKey) throws SQLException {
        try (PreparedStatement statement = session.getConnection().prepareStatement(
                "select pg_advisory_xact_lock(hashtextextended(?, 0))")) {
            statement.setString(1, workspaceId + '\u001f' + idempotencyKey);
            statement.execute();
        }
    }

    private static SourceBinary requireMatchingBinary(
            SourceCommandMapper.BinaryRow row, UploadRegistration registration) {
        if (row == null
                || !row.contentSha256().equals(registration.contentSha256().value())
                || row.byteLength() != registration.byteLength()
                || !row.mediaType().equals(registration.mediaType())
                || !row.binaryLocation().equals(registration.binaryLocation())) {
            throw SourceCommandException.persistenceFailure(
                    new IllegalStateException("SOURCE_BINARY_FACT_MISMATCH"));
        }
        return new SourceBinary(
                row.sourceBinaryId(),
                SourceHash.ofHex(row.contentSha256()),
                row.byteLength(),
                row.mediaType(),
                row.binaryLocation(),
                row.createdAt());
    }

    private static SourceDocument toDomain(SourceCommandMapper.DocumentRow row) {
        return SourceDocument.received(
                row.sourceDocumentId(),
                row.workspaceId(),
                row.sourceBinaryId(),
                row.originalFileName(),
                row.mediaType(),
                row.byteLength(),
                SourceHash.ofHex(row.contentSha256()),
                row.receivedAt(),
                row.idempotencyKey());
    }
}
