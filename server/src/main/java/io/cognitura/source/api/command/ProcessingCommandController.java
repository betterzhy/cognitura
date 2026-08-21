package io.cognitura.source.api.command;

import io.cognitura.source.application.command.SourceCommandService;
import io.cognitura.source.application.command.TrustedRequestContext;
import io.cognitura.source.application.command.TrustedRequestContextProvider;
import java.util.Objects;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@ConditionalOnBean({SourceCommandService.class, TrustedRequestContextProvider.class})
@RequestMapping("/api/v1/source-documents/{sourceDocumentId}/processing-revisions")
public final class ProcessingCommandController {

    private final SourceCommandService service;
    private final TrustedRequestContextProvider contexts;

    public ProcessingCommandController(
            SourceCommandService service, TrustedRequestContextProvider contexts) {
        this.service = Objects.requireNonNull(service, "service");
        this.contexts = Objects.requireNonNull(contexts, "contexts");
    }

    @PostMapping
    public ResponseEntity<CommandAcceptedResponse.Processing> process(
            @PathVariable String sourceDocumentId,
            @RequestBody ProcessingCommandRequest request) {
        if (!sourceDocumentId.equals(request.sourceDocumentId())) {
            throw new IllegalArgumentException("PROCESSING_SOURCE_PATH_BODY_MISMATCH");
        }
        TrustedRequestContext context = contexts.currentContext();
        SourceCommandService.ProcessingResult result = service.process(context, request.toCommand());
        return ResponseEntity.status(result.reused() ? HttpStatus.OK : HttpStatus.ACCEPTED)
                .body(CommandAcceptedResponse.Processing.from(result));
    }
}
