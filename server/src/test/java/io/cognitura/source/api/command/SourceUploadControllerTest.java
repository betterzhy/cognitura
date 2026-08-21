package io.cognitura.source.api.command;

import static org.hamcrest.Matchers.hasSize;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import io.cognitura.source.application.command.SourceCommandService;
import io.cognitura.source.application.command.TrustedRequestContext;
import io.cognitura.source.application.command.TrustedRequestContextProvider;
import io.cognitura.source.domain.SourceDocument;
import io.cognitura.source.domain.SourceHash;
import java.time.Instant;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class SourceUploadControllerTest {

    private static final String HASH = "a".repeat(64);
    private SourceCommandService service;
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        service = mock(SourceCommandService.class);
        TrustedRequestContextProvider context =
                () -> new TrustedRequestContext("workspace-a", "actor-a");
        mvc = MockMvcBuilders.standaloneSetup(new SourceUploadController(service, context))
                .setControllerAdvice(new SourceCommandErrorAdvice())
                .build();
    }

    @Test
    void newUploadReturnsExactFourField201Shape() throws Exception {
        when(service.upload(any(), any())).thenReturn(new SourceCommandService.UploadResult(
                "source-a",
                SourceDocument.ValidationStatus.RECEIVED,
                SourceHash.ofHex(HASH),
                Instant.parse("2026-08-22T04:00:00Z"),
                true));

        mvc.perform(multipart("/api/v1/workspaces/workspace-a/source-documents")
                        .file(command(""))
                        .file(content()))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.*", hasSize(4)))
                .andExpect(jsonPath("$.sourceDocumentId").value("source-a"))
                .andExpect(jsonPath("$.sourceIngestionDisplayStatus").value("VALIDATING"))
                .andExpect(jsonPath("$.contentSha256").value(HASH))
                .andExpect(jsonPath("$.receivedAt").value("2026-08-22T04:00:00Z"))
                .andExpect(jsonPath("$.binaryLocation").doesNotExist())
                .andExpect(jsonPath("$.sourceBinaryId").doesNotExist());
    }

    @Test
    void replayReturns200AndForeignWorkspaceUsesUniform404() throws Exception {
        when(service.upload(any(), any())).thenReturn(new SourceCommandService.UploadResult(
                "source-a",
                SourceDocument.ValidationStatus.RECEIVED,
                SourceHash.ofHex(HASH),
                Instant.parse("2026-08-22T04:00:00Z"),
                false));
        mvc.perform(multipart("/api/v1/workspaces/workspace-a/source-documents")
                        .file(command(""))
                        .file(content()))
                .andExpect(status().isOk());

        service = mock(SourceCommandService.class);
        mvc = MockMvcBuilders.standaloneSetup(new SourceUploadController(
                        service,
                        () -> new TrustedRequestContext("workspace-a", "actor-a")))
                .setControllerAdvice(new SourceCommandErrorAdvice())
                .build();
        mvc.perform(multipart("/api/v1/workspaces/workspace-foreign/source-documents")
                        .file(command(""))
                        .file(content()))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.*", hasSize(5)))
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"))
                .andExpect(jsonPath("$.retryable").value(false))
                .andExpect(jsonPath("$.sourceDocumentId").isEmpty())
                .andExpect(jsonPath("$.sourceProcessingRevisionId").isEmpty());
        verifyNoInteractions(service);
    }

    @Test
    void bodyWorkspaceOrActorFieldsAreRejectedAsMalformed() throws Exception {
        mvc.perform(multipart("/api/v1/workspaces/workspace-a/source-documents")
                        .file(command(",\"workspaceId\":\"workspace-a\""))
                        .file(content()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("MALFORMED_COMMAND"));
        mvc.perform(multipart("/api/v1/workspaces/workspace-a/source-documents")
                        .file(command(",\"actorId\":\"actor-a\""))
                        .file(content()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("MALFORMED_COMMAND"));
        verifyNoInteractions(service);
    }

    @Test
    void unsupportedMediaTypeMapsTo415WithoutInternalDetail() throws Exception {
        when(service.upload(any(), any())).thenThrow(
                new IllegalArgumentException("SOURCE_BINARY_MEDIA_TYPE_UNSUPPORTED"));
        mvc.perform(multipart("/api/v1/workspaces/workspace-a/source-documents")
                        .file(command(""))
                        .file(content()))
                .andExpect(status().isUnsupportedMediaType())
                .andExpect(jsonPath("$.*", hasSize(5)))
                .andExpect(jsonPath("$.errorCode").value("UNSUPPORTED_MEDIA_TYPE"))
                .andExpect(jsonPath("$.message").value("The source media type is unsupported."))
                .andExpect(jsonPath("$.sourceDocumentId").isEmpty());
    }

    private static MockMultipartFile command(String extraField) {
        String json = """
                {"idempotencyKey":"upload-a","originalFileName":"source.docx",
                 "declaredMediaType":"application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                 "declaredByteLength":7,"contentSha256":"%s"%s}
                """.formatted(HASH, extraField);
        return new MockMultipartFile(
                "command", "command.json", MediaType.APPLICATION_JSON_VALUE, json.getBytes());
    }

    private static MockMultipartFile content() {
        return new MockMultipartFile(
                "file", "source.docx",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                "content".getBytes());
    }
}
