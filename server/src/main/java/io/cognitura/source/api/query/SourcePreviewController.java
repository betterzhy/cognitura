package io.cognitura.source.api.query;

import io.cognitura.source.application.command.TrustedRequestContext;
import io.cognitura.source.application.command.TrustedRequestContextProvider;
import java.util.Objects;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@ConditionalOnBean({SourcePreviewQuery.class, TrustedRequestContextProvider.class})
@RequestMapping(
        "/api/v1/source-documents/{sourceDocumentId}/processing-revisions/"
                + "{sourceProcessingRevisionId}/blocks")
public final class SourcePreviewController {

    private final SourcePreviewQuery query;
    private final TrustedRequestContextProvider contexts;

    public SourcePreviewController(
            SourcePreviewQuery query, TrustedRequestContextProvider contexts) {
        this.query = Objects.requireNonNull(query, "query");
        this.contexts = Objects.requireNonNull(contexts, "contexts");
    }

    @GetMapping
    public SourcePreviewPage preview(
            @PathVariable String sourceDocumentId,
            @PathVariable String sourceProcessingRevisionId,
            @RequestParam(required = false) String after,
            @RequestParam(required = false) Integer limit) {
        TrustedRequestContext context = contexts.currentContext();
        return query.preview(
                context, sourceDocumentId, sourceProcessingRevisionId, after, limit);
    }
}
