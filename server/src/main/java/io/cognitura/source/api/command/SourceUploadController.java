package io.cognitura.source.api.command;

import io.cognitura.source.application.command.SourceCommandService;
import io.cognitura.source.application.command.TrustedRequestContext;
import io.cognitura.source.application.command.TrustedRequestContextProvider;
import java.io.IOException;
import java.util.Objects;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@ConditionalOnBean({SourceCommandService.class, TrustedRequestContextProvider.class})
@RequestMapping("/api/v1/workspaces/{workspaceId}/source-documents")
public final class SourceUploadController {

    private final SourceCommandService service;
    private final TrustedRequestContextProvider contexts;

    public SourceUploadController(
            SourceCommandService service, TrustedRequestContextProvider contexts) {
        this.service = Objects.requireNonNull(service, "service");
        this.contexts = Objects.requireNonNull(contexts, "contexts");
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<CommandAcceptedResponse.Upload> upload(
            @PathVariable String workspaceId,
            @RequestPart("command") SourceUploadRequest request,
            @RequestPart("file") MultipartFile file) {
        TrustedRequestContext context = contexts.currentContext();
        try {
            context.requirePathWorkspace(workspaceId);
        } catch (IllegalArgumentException error) {
            throw io.cognitura.source.application.command.SourceCommandException.resourceNotFound();
        }
        try {
            SourceCommandService.UploadResult result =
                    service.upload(context, request.toCommand(file.getInputStream()));
            return ResponseEntity.status(result.created() ? HttpStatus.CREATED : HttpStatus.OK)
                    .body(CommandAcceptedResponse.Upload.from(result));
        } catch (IOException error) {
            throw new IllegalStateException("SOURCE_BINARY_STREAM_UNAVAILABLE");
        }
    }
}
