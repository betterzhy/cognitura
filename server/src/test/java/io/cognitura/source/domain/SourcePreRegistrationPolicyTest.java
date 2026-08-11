package io.cognitura.source.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.Test;

class SourcePreRegistrationPolicyTest {

    private static final String DOCX_MEDIA_TYPE =
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
    private static final SourceHash ABC_HASH = SourceHash.ofHex(
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    private static final SourceHash ABD_HASH = SourceHash.ofHex(
            "a52d159f262b2c6ddb724a61840befc36eb30c88877a4030b65cbe86298449c9");
    private static final Instant RECEIVED_AT = Instant.parse("2026-08-12T00:00:00Z");

    private final SourcePreRegistrationPolicy policy = new SourcePreRegistrationPolicy(3);

    @Test
    void registersValidatedDocxAsReceivedFacts() {
        var decision = policy.preRegister(
                request("document-1", "workspace-1", "binary-abc", "key-1", bytes("abc"), ABC_HASH),
                SourcePreRegistrationPolicy.ExistingFacts.empty());

        assertThat(decision.createdSourceDocument()).isTrue();
        assertThat(decision.createdSourceBinary()).isTrue();
        assertThat(decision.sourceDocument().sourceDocumentId()).isEqualTo("document-1");
        assertThat(decision.sourceDocument().workspaceId()).isEqualTo("workspace-1");
        assertThat(decision.sourceDocument().contentSha256()).isEqualTo(ABC_HASH);
        assertThat(decision.sourceDocument().validationStatus())
                .isEqualTo(SourceDocument.ValidationStatus.RECEIVED);
        assertThat(decision.sourceBinary().contentSha256()).isEqualTo(ABC_HASH);
        assertThat(decision.sourceBinary().byteLength()).isEqualTo(3);
    }

    @Test
    void replaysSameWorkspaceKeyAndDigestWithoutReplacingFirstUploadFacts() {
        var first = policy.preRegister(
                request("document-1", "workspace-1", "binary-abc", "key-1", bytes("abc"), ABC_HASH),
                SourcePreRegistrationPolicy.ExistingFacts.empty());
        var replay = request(
                "document-2", "workspace-1", "unused-binary", "key-1", bytes("abc"), ABC_HASH,
                "renamed.docx");

        var decision = policy.preRegister(
                replay,
                new SourcePreRegistrationPolicy.ExistingFacts(
                        Optional.empty(), Optional.of(first.sourceDocument()), Optional.of(first.sourceBinary())));

        assertThat(decision.createdSourceDocument()).isFalse();
        assertThat(decision.createdSourceBinary()).isFalse();
        assertThat(decision.sourceDocument()).isSameAs(first.sourceDocument());
        assertThat(decision.sourceDocument().originalFileName()).isEqualTo("source.docx");
        assertThat(decision.sourceBinary()).isSameAs(first.sourceBinary());
    }

    @Test
    void rejectsSameWorkspaceKeyWhenDigestChanges() {
        var first = policy.preRegister(
                request("document-1", "workspace-1", "binary-abc", "key-1", bytes("abc"), ABC_HASH),
                SourcePreRegistrationPolicy.ExistingFacts.empty());

        assertThatThrownBy(() -> policy.preRegister(
                        request("document-2", "workspace-1", "binary-abd", "key-1", bytes("abd"), ABD_HASH),
                        new SourcePreRegistrationPolicy.ExistingFacts(
                                Optional.empty(), Optional.of(first.sourceDocument()), Optional.empty())))
                .isInstanceOf(SourceDomainException.class)
                .extracting(error -> ((SourceDomainException) error).code())
                .isEqualTo(SourceDomainException.Code.IDEMPOTENCY_CONFLICT);
    }

    @Test
    void classifiesDigestChangeAsIdempotencyConflictWhenBothLookupsHitSameDocument() {
        var first = policy.preRegister(
                request("document-1", "workspace-1", "binary-abc", "key-1", bytes("abc"), ABC_HASH),
                SourcePreRegistrationPolicy.ExistingFacts.empty());

        assertThatThrownBy(() -> policy.preRegister(
                        request("document-1", "workspace-1", "binary-abd", "key-1", bytes("abd"), ABD_HASH),
                        new SourcePreRegistrationPolicy.ExistingFacts(
                                Optional.of(first.sourceDocument()),
                                Optional.of(first.sourceDocument()),
                                Optional.of(first.sourceBinary()))))
                .isInstanceOf(SourceDomainException.class)
                .satisfies(error -> {
                    var domainError = (SourceDomainException) error;
                    assertThat(domainError.code())
                            .isEqualTo(SourceDomainException.Code.IDEMPOTENCY_CONFLICT);
                    assertThat(domainError.retryable()).isFalse();
                });
    }

    @Test
    void createsDistinctLogicalUploadButSharesBinaryForDifferentKeyAndSameDigest() {
        var first = policy.preRegister(
                request("document-1", "workspace-1", "binary-abc", "key-1", bytes("abc"), ABC_HASH),
                SourcePreRegistrationPolicy.ExistingFacts.empty());

        var second = policy.preRegister(
                request("document-2", "workspace-1", "unused-binary", "key-2", bytes("abc"), ABC_HASH),
                new SourcePreRegistrationPolicy.ExistingFacts(
                        Optional.empty(), Optional.empty(), Optional.of(first.sourceBinary())));

        assertThat(second.createdSourceDocument()).isTrue();
        assertThat(second.createdSourceBinary()).isFalse();
        assertThat(second.sourceDocument().sourceDocumentId()).isEqualTo("document-2");
        assertThat(second.sourceDocument()).isNotEqualTo(first.sourceDocument());
        assertThat(second.sourceDocument().sourceBinaryId()).isEqualTo("binary-abc");
        assertThat(second.sourceBinary()).isSameAs(first.sourceBinary());
    }

    @Test
    void rejectsReusingSourceDocumentIdentityAcrossWorkspaces() {
        var first = policy.preRegister(
                request("document-1", "workspace-1", "binary-abc", "key-1", bytes("abc"), ABC_HASH),
                SourcePreRegistrationPolicy.ExistingFacts.empty());

        assertThatThrownBy(() -> policy.preRegister(
                        request("document-1", "workspace-2", "binary-abd", "key-1", bytes("abd"), ABD_HASH),
                        new SourcePreRegistrationPolicy.ExistingFacts(
                                Optional.of(first.sourceDocument()), Optional.empty(), Optional.empty())))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("SOURCE_DOCUMENT_WORKSPACE_IDENTITY_CONFLICT");
    }

    @Test
    void rejectsConflictingDocumentAndIdempotencyLookupFacts() {
        var first = policy.preRegister(
                request("document-1", "workspace-1", "binary-abc", "key-1", bytes("abc"), ABC_HASH),
                SourcePreRegistrationPolicy.ExistingFacts.empty());
        var conflictingDocument = SourceDocument.received(
                "document-2",
                "workspace-1",
                "binary-abc",
                "other.docx",
                DOCX_MEDIA_TYPE,
                3,
                ABC_HASH,
                RECEIVED_AT,
                "key-1");

        assertThatThrownBy(() -> policy.preRegister(
                        request("document-1", "workspace-1", "unused-binary", "key-1", bytes("abc"), ABC_HASH),
                        new SourcePreRegistrationPolicy.ExistingFacts(
                                Optional.of(first.sourceDocument()),
                                Optional.of(conflictingDocument),
                                Optional.of(first.sourceBinary()))))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("SOURCE_DOCUMENT_AND_IDEMPOTENCY_FACTS_CONFLICT");
    }

    @Test
    void rejectsUnsupportedMediaTypeWithoutProducingFacts() {
        var request = new SourcePreRegistrationPolicy.RegistrationRequest(
                "document-1", "workspace-1", "binary-abc", "source.docx", "application/zip",
                bytes("abc"), ABC_HASH, "key-1", "isolation://binary-abc", RECEIVED_AT);

        assertCode(request, SourceDomainException.Code.UNSUPPORTED_MEDIA_TYPE);
    }

    @Test
    void rejectsEmptySourceWithoutProducingFacts() {
        assertCode(
                request("document-1", "workspace-1", "binary-empty", "key-1", new byte[0], ABC_HASH),
                SourceDomainException.Code.EMPTY_SOURCE_FILE);
    }

    @Test
    void rejectsSourceAboveConfiguredRawLimitWithoutProducingFacts() {
        assertCode(
                request("document-1", "workspace-1", "binary-large", "key-1", bytes("abcd"), ABC_HASH),
                SourceDomainException.Code.SOURCE_SIZE_LIMIT);
    }

    @Test
    void rejectsDeclaredHashDriftWithoutProducingFacts() {
        assertCode(
                request("document-1", "workspace-1", "binary-abc", "key-1", bytes("abc"), ABD_HASH),
                SourceDomainException.Code.SOURCE_HASH_MISMATCH);
    }

    @Test
    void rejectsNonCanonicalSha256Text() {
        assertThatThrownBy(() -> SourceHash.ofHex(
                        "BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("SHA256_MUST_BE_64_LOWERCASE_HEX");
    }

    private void assertCode(
            SourcePreRegistrationPolicy.RegistrationRequest request, SourceDomainException.Code code) {
        assertThatThrownBy(() -> policy.preRegister(
                        request, SourcePreRegistrationPolicy.ExistingFacts.empty()))
                .isInstanceOf(SourceDomainException.class)
                .satisfies(error -> {
                    var domainError = (SourceDomainException) error;
                    assertThat(domainError.code()).isEqualTo(code);
                    assertThat(domainError.retryable()).isFalse();
                });
    }

    private static SourcePreRegistrationPolicy.RegistrationRequest request(
            String documentId,
            String workspaceId,
            String binaryId,
            String idempotencyKey,
            byte[] bytes,
            SourceHash declaredHash) {
        return request(
                documentId, workspaceId, binaryId, idempotencyKey, bytes, declaredHash, "source.docx");
    }

    private static SourcePreRegistrationPolicy.RegistrationRequest request(
            String documentId,
            String workspaceId,
            String binaryId,
            String idempotencyKey,
            byte[] bytes,
            SourceHash declaredHash,
            String fileName) {
        return new SourcePreRegistrationPolicy.RegistrationRequest(
                documentId,
                workspaceId,
                binaryId,
                fileName,
                DOCX_MEDIA_TYPE,
                bytes,
                declaredHash,
                idempotencyKey,
                "isolation://" + binaryId,
                RECEIVED_AT);
    }

    private static byte[] bytes(String value) {
        return value.getBytes(StandardCharsets.UTF_8);
    }
}
