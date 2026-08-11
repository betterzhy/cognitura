package io.cognitura.source.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Instant;
import org.junit.jupiter.api.Test;

class SourceLifecycleTest {

    private static final String DOCX_MEDIA_TYPE =
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
    private static final SourceHash ABC_HASH = SourceHash.ofHex(
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    private static final SourceHash ABD_HASH = SourceHash.ofHex(
            "a52d159f262b2c6ddb724a61840befc36eb30c88877a4030b65cbe86298449c9");
    private static final Instant RECEIVED_AT = Instant.parse("2026-08-12T00:00:00Z");

    @Test
    void advancesDocumentOnlyThroughReceivedValidatingAccepted() {
        var received = receivedDocument();

        var validating = received.beginValidation();
        var accepted = validating.accept();

        assertThat(received.validationStatus()).isEqualTo(SourceDocument.ValidationStatus.RECEIVED);
        assertThat(validating.validationStatus()).isEqualTo(SourceDocument.ValidationStatus.VALIDATING);
        assertThat(accepted.validationStatus()).isEqualTo(SourceDocument.ValidationStatus.ACCEPTED);
        assertThat(accepted.sourceDocumentId()).isEqualTo(received.sourceDocumentId());
        assertThat(accepted.workspaceId()).isEqualTo(received.workspaceId());
        assertThat(accepted.contentSha256()).isSameAs(received.contentSha256());
        assertThat(accepted.failureCode()).isNull();
    }

    @Test
    void rejectsUnlistedDocumentTransition() {
        var received = receivedDocument();

        assertThatThrownBy(received::accept)
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("SOURCE_DOCUMENT_TRANSITION_NOT_ALLOWED:RECEIVED->ACCEPTED");
    }

    @Test
    void preservesRejectedUploadFactsAsTerminal() {
        var rejected = receivedDocument()
                .beginValidation()
                .reject(SourceDomainException.Code.DOCX_SECURITY_REJECTED, "active content detected");

        assertThat(rejected.validationStatus()).isEqualTo(SourceDocument.ValidationStatus.REJECTED);
        assertThat(rejected.failureCode()).isEqualTo(SourceDomainException.Code.DOCX_SECURITY_REJECTED);
        assertThat(rejected.failureDetail()).isEqualTo("active content detected");
        assertThatThrownBy(rejected::beginValidation)
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("SOURCE_DOCUMENT_TRANSITION_NOT_ALLOWED:REJECTED->VALIDATING");
    }

    @Test
    void startsRevisionOnlyForAcceptedDocumentAndExactHash() {
        var received = receivedDocument();

        assertThatThrownBy(() -> ProcessingRevision.start(
                        "revision-1", received, ABC_HASH, "docx-parser-v1", RECEIVED_AT))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("SOURCE_DOCUMENT_MUST_BE_ACCEPTED_FOR_REVISION");

        var accepted = received.beginValidation().accept();
        assertThatThrownBy(() -> ProcessingRevision.start(
                        "revision-1", accepted, ABD_HASH, "docx-parser-v1", RECEIVED_AT))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("PROCESSING_REVISION_CONTENT_HASH_MISMATCH");

        var revision = ProcessingRevision.start(
                "revision-1", accepted, ABC_HASH, "docx-parser-v1", RECEIVED_AT);
        assertThat(revision.status()).isEqualTo(ProcessingRevision.Status.PARSING);
        assertThat(revision.sourceDocumentId()).isEqualTo("document-1");
        assertThat(revision.contentSha256()).isSameAs(ABC_HASH);
        assertThat(revision.parserProfileVersion()).isEqualTo("docx-parser-v1");
    }

    @Test
    void allowsOnlyListedRevisionTransitionsWithoutPublishingState() {
        var revision = acceptedRevision();

        revision.requireTransitionAllowed(ProcessingRevision.Status.PARSED);
        assertThatThrownBy(() -> revision.requireTransitionAllowed(
                        ProcessingRevision.Status.PREVIEW_READY))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("PROCESSING_REVISION_TRANSITION_NOT_ALLOWED:PARSING->PREVIEW_READY");
    }

    @Test
    void allowsRetryOnlyFromRetryableFailure() {
        var failed = ProcessingRevision.restore(
                "revision-1",
                "document-1",
                ABC_HASH,
                "docx-parser-v1",
                ProcessingRevision.Status.FAILED_RETRYABLE,
                SourceDomainException.Code.PARSER_RETRYABLE_FAILURE,
                "transient isolated read failure",
                RECEIVED_AT,
                Instant.parse("2026-08-12T00:01:00Z"));

        assertThat(failed.status()).isEqualTo(ProcessingRevision.Status.FAILED_RETRYABLE);
        failed.requireTransitionAllowed(ProcessingRevision.Status.PARSING);
    }

    @Test
    void keepsTerminalRevisionTerminal() {
        var failed = ProcessingRevision.restore(
                "revision-1",
                "document-1",
                ABC_HASH,
                "docx-parser-v1",
                ProcessingRevision.Status.FAILED_TERMINAL,
                SourceDomainException.Code.PARSER_TERMINAL_FAILURE,
                "deterministic parser rejection",
                RECEIVED_AT,
                Instant.parse("2026-08-12T00:01:00Z"));

        assertThatThrownBy(() -> failed.requireTransitionAllowed(ProcessingRevision.Status.PARSING))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("PROCESSING_REVISION_TRANSITION_NOT_ALLOWED:FAILED_TERMINAL->PARSING");
    }

    @Test
    void rejectsFailureCodeFromWrongLifecycleStage() {
        assertThatThrownBy(() -> ProcessingRevision.restore(
                        "revision-1",
                        "document-1",
                        ABC_HASH,
                        "docx-parser-v1",
                        ProcessingRevision.Status.FAILED_RETRYABLE,
                        SourceDomainException.Code.DOCX_FORMAT_INVALID,
                        "wrong stage mapping",
                        RECEIVED_AT,
                        Instant.parse("2026-08-12T00:01:00Z")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("RETRYABLE_REVISION_FAILURE_REQUIRES_PARSER_RETRYABLE_FAILURE");
    }

    private static SourceDocument receivedDocument() {
        return SourceDocument.received(
                "document-1",
                "workspace-1",
                "binary-abc",
                "source.docx",
                DOCX_MEDIA_TYPE,
                3,
                ABC_HASH,
                RECEIVED_AT,
                "key-1");
    }

    private static ProcessingRevision acceptedRevision() {
        var accepted = receivedDocument().beginValidation().accept();
        return ProcessingRevision.start(
                "revision-1", accepted, ABC_HASH, "docx-parser-v1", RECEIVED_AT);
    }
}
