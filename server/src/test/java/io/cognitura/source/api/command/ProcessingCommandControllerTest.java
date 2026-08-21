package io.cognitura.source.api.command;

import static org.hamcrest.Matchers.hasSize;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import io.cognitura.source.application.command.SourceCommandException;
import io.cognitura.source.application.command.SourceCommandService;
import io.cognitura.source.application.command.TrustedRequestContext;
import io.cognitura.source.application.command.TrustedRequestContextProvider;
import io.cognitura.source.domain.ProcessingRevision;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class ProcessingCommandControllerTest {

    private SourceCommandService service;
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        service = mock(SourceCommandService.class);
        TrustedRequestContextProvider context =
                () -> new TrustedRequestContext("workspace-a", "actor-a");
        mvc = MockMvcBuilders.standaloneSetup(new ProcessingCommandController(service, context))
                .setControllerAdvice(new SourceCommandErrorAdvice())
                .build();
    }

    @Test
    void acceptedCommandReturnsExact202ShapeAndExactPollLocation() throws Exception {
        when(service.process(any(), any())).thenReturn(new SourceCommandService.ProcessingResult(
                "source-a", "revision-a", ProcessingRevision.Status.PARSING, false));

        mvc.perform(post("/api/v1/source-documents/source-a/processing-revisions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(command("source-a", "")))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.*", hasSize(6)))
                .andExpect(jsonPath("$.sourceDocumentId").value("source-a"))
                .andExpect(jsonPath("$.sourceProcessingRevisionId").value("revision-a"))
                .andExpect(jsonPath("$.sourceProcessingRevisionStatus").value("PARSING"))
                .andExpect(jsonPath("$.sourceIngestionDisplayStatus").value("PARSING"))
                .andExpect(jsonPath("$.pollLocation").value(
                        "/api/v1/source-documents/source-a/processing-revisions/revision-a"))
                .andExpect(jsonPath("$.reused").value(false))
                .andExpect(jsonPath("$.attemptId").doesNotExist())
                .andExpect(jsonPath("$.fencingToken").doesNotExist());
    }

    @Test
    void existingTerminalRevisionReturns200WithSameShape() throws Exception {
        when(service.process(any(), any())).thenReturn(new SourceCommandService.ProcessingResult(
                "source-a", "revision-a", ProcessingRevision.Status.FAILED_TERMINAL, true));
        mvc.perform(post("/api/v1/source-documents/source-a/processing-revisions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(command("source-a", "")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.*", hasSize(6)))
                .andExpect(jsonPath("$.reused").value(true))
                .andExpect(jsonPath("$.sourceIngestionDisplayStatus").value("TERMINAL_FAILURE"));
    }

    @Test
    void missingAndCrossWorkspaceSourcesUseTheSame404WithoutIdentities() throws Exception {
        when(service.process(any(), any())).thenThrow(SourceCommandException.resourceNotFound());
        mvc.perform(post("/api/v1/source-documents/source-missing/processing-revisions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(command("source-missing", "")))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.*", hasSize(5)))
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"))
                .andExpect(jsonPath("$.message").value("The requested resource was not found."))
                .andExpect(jsonPath("$.sourceDocumentId").isEmpty())
                .andExpect(jsonPath("$.sourceProcessingRevisionId").isEmpty());
    }

    @Test
    void receivedSourceReturns503WithoutPollOrRevisionIdentity() throws Exception {
        when(service.process(any(), any())).thenThrow(
                SourceCommandException.sourceNotAccepted("source-a"));
        mvc.perform(post("/api/v1/source-documents/source-a/processing-revisions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(command("source-a", "")))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.*", hasSize(5)))
                .andExpect(jsonPath("$.errorCode").value("SOURCE_NOT_ACCEPTED_YET"))
                .andExpect(jsonPath("$.retryable").value(true))
                .andExpect(jsonPath("$.sourceDocumentId").value("source-a"))
                .andExpect(jsonPath("$.sourceProcessingRevisionId").isEmpty())
                .andExpect(jsonPath("$.pollLocation").doesNotExist());
    }

    @Test
    void bodyPathMismatchAndUntrustedFieldsAreMalformed() throws Exception {
        mvc.perform(post("/api/v1/source-documents/source-a/processing-revisions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(command("source-b", "")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("MALFORMED_COMMAND"));
        mvc.perform(post("/api/v1/source-documents/source-a/processing-revisions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(command("source-a", ",\"actorId\":\"actor-a\"")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("MALFORMED_COMMAND"));
    }

    private static String command(String sourceDocumentId, String extraField) {
        return """
                {"sourceDocumentId":"%s","parserProfileVersion":"docx-v1"%s}
                """.formatted(sourceDocumentId, extraField);
    }
}
