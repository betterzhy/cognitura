package io.cognitura.source.reference;

import io.cognitura.source.domain.SourceHash;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.regex.Pattern;

public final class ReferenceResolutionService {

    private static final Pattern ALIAS = Pattern.compile("(?:sdr|dbr):[0-9a-f]{64}");

    public enum RevisionOutcome {
        SUCCESSFUL,
        FAILED_RETRYABLE,
        FAILED_TERMINAL
    }

    public enum ReparseAction {
        REUSE_SUCCESSFUL_REVISION,
        RETRY_EXISTING_REVISION,
        RETURN_TERMINAL_FAILURE,
        CREATE_NEW_REVISION
    }

    public record SourceDocumentSnapshot(String workspaceId, String sourceDocumentId) {
        public SourceDocumentSnapshot {
            workspaceId = StableSourceReference.requireIdentifier(workspaceId, "WORKSPACE_ID");
            sourceDocumentId = StableSourceReference.requireIdentifier(
                    sourceDocumentId, "SOURCE_DOCUMENT_ID");
        }
    }

    public record RevisionSnapshot(
            String workspaceId,
            String sourceDocumentId,
            String sourceProcessingRevisionId,
            SourceHash contentSha256,
            ReparseProfile profile,
            RevisionOutcome outcome,
            List<StableSourceReference> blocks) {

        public RevisionSnapshot {
            workspaceId = StableSourceReference.requireIdentifier(workspaceId, "WORKSPACE_ID");
            sourceDocumentId = StableSourceReference.requireIdentifier(
                    sourceDocumentId, "SOURCE_DOCUMENT_ID");
            sourceProcessingRevisionId = StableSourceReference.requireIdentifier(
                    sourceProcessingRevisionId, "PROCESSING_REVISION_ID");
            Objects.requireNonNull(contentSha256, "contentSha256");
            Objects.requireNonNull(profile, "profile");
            Objects.requireNonNull(outcome, "outcome");
            blocks = List.copyOf(Objects.requireNonNull(blocks, "blocks"));
            String context = revisionContext(
                    workspaceId, sourceDocumentId, sourceProcessingRevisionId);
            if (outcome != RevisionOutcome.SUCCESSFUL && !blocks.isEmpty()) {
                throw scope(blockTupleContext(
                        context + ",outcome=" + outcome, blocks.getFirst()));
            }
            HashSet<String> blockIds = new HashSet<>();
            for (StableSourceReference block : blocks) {
                Objects.requireNonNull(block, "block");
                String blockContext = blockTupleContext(context, block);
                if (!sourceDocumentId.equals(block.sourceDocumentId())
                        || !sourceProcessingRevisionId.equals(
                                block.sourceProcessingRevisionId())) {
                    throw scope(blockContext);
                }
                if (!blockIds.add(block.documentBlockId())) {
                    throw conflict(blockContext);
                }
            }
        }
    }

    public record Catalog(
            List<SourceDocumentSnapshot> sourceDocuments,
            List<RevisionSnapshot> revisions,
            List<SourceScopedAlias> aliases) {

        public Catalog {
            sourceDocuments = List.copyOf(Objects.requireNonNull(sourceDocuments, "sourceDocuments"));
            revisions = List.copyOf(Objects.requireNonNull(revisions, "revisions"));
            aliases = List.copyOf(Objects.requireNonNull(aliases, "aliases"));
            validateCatalog(sourceDocuments, revisions, aliases);
        }
    }

    public record ReparseDecision(ReparseAction action, String sourceProcessingRevisionId) {
        public ReparseDecision {
            Objects.requireNonNull(action, "action");
            if (action == ReparseAction.CREATE_NEW_REVISION) {
                if (sourceProcessingRevisionId != null) {
                    throw new IllegalArgumentException("NEW_REVISION_DECISION_CANNOT_HAVE_ID");
                }
            } else {
                sourceProcessingRevisionId = StableSourceReference.requireIdentifier(
                        sourceProcessingRevisionId, "PROCESSING_REVISION_ID");
            }
        }
    }

    public StableSourceReference resolveTuple(
            String workspaceId, StableSourceReference requested, Catalog catalog) {
        Objects.requireNonNull(requested, "requested");
        Objects.requireNonNull(catalog, "catalog");
        String workspace = StableSourceReference.requireIdentifier(workspaceId, "WORKSPACE_ID");
        String context = tupleContext(workspace, requested);
        requireSourceScope(workspace, requested.sourceDocumentId(), catalog, context);
        RevisionSnapshot revision = uniqueRevision(
                workspace,
                requested.sourceDocumentId(),
                requested.sourceProcessingRevisionId(),
                catalog,
                context);
        requireSuccessful(revision, context);
        List<StableSourceReference> matches = revision.blocks().stream()
                .filter(requested::equals)
                .toList();
        if (matches.size() != 1) {
            throw notFound(context);
        }
        return matches.getFirst();
    }

    public String resolveSourceAlias(
            String workspaceId, String sourceDocumentId, String alias, Catalog catalog) {
        String workspace = StableSourceReference.requireIdentifier(workspaceId, "WORKSPACE_ID");
        String source = StableSourceReference.requireIdentifier(
                sourceDocumentId, "SOURCE_DOCUMENT_ID");
        String requestedAlias = requireAlias(alias);
        String context = "sourceAlias[workspaceId=" + workspace
                + ",sourceDocumentId=" + source
                + ",alias=" + requestedAlias + "]";
        requireSourceScope(workspace, source, catalog, context);
        SourceScopedAlias registration = uniqueAlias(
                requestedAlias,
                catalog,
                context);
        if (registration.kind() != SourceScopedAlias.Kind.SOURCE_DOCUMENT
                || !source.equals(registration.sourceDocumentId())) {
            throw scope(context);
        }
        return registration.sourceDocumentId();
    }

    public StableSourceReference resolveBlockAlias(
            String workspaceId,
            String sourceDocumentId,
            String sourceProcessingRevisionId,
            String alias,
            Catalog catalog) {
        String workspace = StableSourceReference.requireIdentifier(workspaceId, "WORKSPACE_ID");
        String source = StableSourceReference.requireIdentifier(
                sourceDocumentId, "SOURCE_DOCUMENT_ID");
        String revisionId = StableSourceReference.requireIdentifier(
                sourceProcessingRevisionId, "PROCESSING_REVISION_ID");
        String requestedAlias = requireAlias(alias);
        String context = "blockAlias[workspaceId=" + workspace
                + ",sourceDocumentId=" + source
                + ",revisionId=" + revisionId
                + ",alias=" + requestedAlias + "]";
        requireSourceScope(workspace, source, catalog, context);
        RevisionSnapshot revision = uniqueRevision(
                workspace, source, revisionId, catalog, context);
        requireSuccessful(revision, context);
        SourceScopedAlias registration = uniqueAlias(
                requestedAlias,
                catalog,
                context);
        if (registration.kind() != SourceScopedAlias.Kind.DOCUMENT_BLOCK
                || !source.equals(registration.sourceDocumentId())
                || !revisionId.equals(
                        registration.blockTarget().sourceProcessingRevisionId())) {
            throw scope(context);
        }
        return resolveTuple(workspace, registration.blockTarget(), catalog);
    }

    public SourceScopedAlias registerAlias(
            List<SourceScopedAlias> existing, SourceScopedAlias candidate) {
        Objects.requireNonNull(existing, "existing");
        Objects.requireNonNull(candidate, "candidate");
        String context = aliasRegistrationContext(candidate);
        if (!candidate.isCanonical()) {
            throw conflict(context);
        }
        SourceScopedAlias same = null;
        for (SourceScopedAlias registration : existing) {
            Objects.requireNonNull(registration, "registration");
            if (!registration.value().equals(candidate.value())) {
                continue;
            }
            if (!registration.isCanonical() || !registration.sameTarget(candidate)) {
                throw conflict(context);
            }
            same = registration;
        }
        return same == null ? candidate : same;
    }

    public ReparseDecision decideReparse(
            String workspaceId,
            String sourceDocumentId,
            SourceHash contentSha256,
            ReparseProfile profile,
            Catalog catalog) {
        Objects.requireNonNull(contentSha256, "contentSha256");
        Objects.requireNonNull(profile, "profile");
        String workspace = StableSourceReference.requireIdentifier(workspaceId, "WORKSPACE_ID");
        String source = StableSourceReference.requireIdentifier(
                sourceDocumentId, "SOURCE_DOCUMENT_ID");
        String context = "reparse[workspaceId=" + workspace
                + ",sourceDocumentId=" + source + "]";
        context += ",contentSha256=" + contentSha256.value()
                + ",parserProfileVersion=" + profile.parserProfileVersion();
        requireSourceScope(workspace, source, catalog, context);
        List<RevisionSnapshot> scoped = catalog.revisions().stream()
                .filter(revision -> workspace.equals(revision.workspaceId()))
                .filter(revision -> source.equals(revision.sourceDocumentId()))
                .toList();
        if (scoped.stream().anyMatch(revision -> !contentSha256.equals(revision.contentSha256()))) {
            throw new ReferenceResolutionException(
                    ReferenceResolutionException.Code.HISTORICAL_RETARGET_FORBIDDEN,
                    context);
        }
        List<RevisionSnapshot> matches = scoped.stream()
                .filter(revision -> contentSha256.equals(revision.contentSha256()))
                .filter(revision -> profile.equals(revision.profile()))
                .toList();
        if (matches.size() > 1) {
            throw conflict(context);
        }
        if (matches.isEmpty()) {
            return new ReparseDecision(ReparseAction.CREATE_NEW_REVISION, null);
        }
        RevisionSnapshot existing = matches.getFirst();
        ReparseAction action = switch (existing.outcome()) {
            case SUCCESSFUL -> ReparseAction.REUSE_SUCCESSFUL_REVISION;
            case FAILED_RETRYABLE -> ReparseAction.RETRY_EXISTING_REVISION;
            case FAILED_TERMINAL -> ReparseAction.RETURN_TERMINAL_FAILURE;
        };
        return new ReparseDecision(action, existing.sourceProcessingRevisionId());
    }

    private static void validateCatalog(
            List<SourceDocumentSnapshot> sources,
            List<RevisionSnapshot> revisions,
            List<SourceScopedAlias> aliases) {
        Set<String> sourceScopes = new HashSet<>();
        for (SourceDocumentSnapshot source : sources) {
            Objects.requireNonNull(source, "source");
            sourceScopes.add(scopeKey(source.workspaceId(), source.sourceDocumentId()));
        }
        Map<String, RevisionSnapshot> revisionIdentities = new HashMap<>();
        Map<String, String> blockOwners = new HashMap<>();
        for (RevisionSnapshot revision : revisions) {
            Objects.requireNonNull(revision, "revision");
            String context = revisionContext(
                    revision.workspaceId(),
                    revision.sourceDocumentId(),
                    revision.sourceProcessingRevisionId());
            if (!sourceScopes.contains(scopeKey(
                    revision.workspaceId(), revision.sourceDocumentId()))) {
                throw scope(context);
            }
            String revisionKey = scopeKey(revision.workspaceId(), revision.sourceDocumentId())
                    + "\u0000" + revision.sourceProcessingRevisionId();
            RevisionSnapshot priorRevision = revisionIdentities.putIfAbsent(revisionKey, revision);
            if (priorRevision != null && !priorRevision.equals(revision)) {
                throw conflict(context);
            }
            for (StableSourceReference block : revision.blocks()) {
                String blockKey = revision.workspaceId() + "\u0000" + revision.sourceDocumentId()
                        + "\u0000" + block.documentBlockId();
                String priorOwner = blockOwners.putIfAbsent(
                        blockKey, revision.sourceProcessingRevisionId());
                if (priorOwner != null
                        && !priorOwner.equals(revision.sourceProcessingRevisionId())) {
                    throw new ReferenceResolutionException(
                            ReferenceResolutionException.Code.HISTORICAL_RETARGET_FORBIDDEN,
                            blockTupleContext(context, block)
                                    + ",priorRevisionId=" + priorOwner);
                }
            }
        }
        Map<String, SourceScopedAlias> registrations = new HashMap<>();
        for (SourceScopedAlias alias : aliases) {
            Objects.requireNonNull(alias, "alias");
            String context = aliasRegistrationContext(alias);
            if (!alias.isCanonical()) {
                throw conflict(context);
            }
            SourceScopedAlias prior = registrations.putIfAbsent(alias.value(), alias);
            if (prior != null && !prior.sameTarget(alias)) {
                throw conflict(context);
            }
        }
    }

    private static void requireSourceScope(
            String workspaceId, String sourceDocumentId, Catalog catalog, String context) {
        long matches = catalog.sourceDocuments().stream()
                .filter(snapshot -> workspaceId.equals(snapshot.workspaceId()))
                .filter(snapshot -> sourceDocumentId.equals(snapshot.sourceDocumentId()))
                .count();
        if (matches != 1) {
            throw scope(context);
        }
    }

    private static RevisionSnapshot uniqueRevision(
            String workspaceId,
            String sourceDocumentId,
            String sourceProcessingRevisionId,
            Catalog catalog,
            String context) {
        List<RevisionSnapshot> matches = catalog.revisions().stream()
                .filter(revision -> workspaceId.equals(revision.workspaceId()))
                .filter(revision -> sourceDocumentId.equals(revision.sourceDocumentId()))
                .filter(revision -> sourceProcessingRevisionId.equals(
                        revision.sourceProcessingRevisionId()))
                .toList();
        if (matches.isEmpty()) {
            throw notFound(context);
        }
        RevisionSnapshot first = matches.getFirst();
        if (matches.stream().anyMatch(revision -> !first.equals(revision))) {
            throw conflict(context);
        }
        return first;
    }

    private static SourceScopedAlias uniqueAlias(
            String alias, Catalog catalog, String notFoundContext) {
        List<SourceScopedAlias> matches = catalog.aliases().stream()
                .filter(registration -> alias.equals(registration.value()))
                .toList();
        if (matches.isEmpty()) {
            throw notFound(notFoundContext);
        }
        SourceScopedAlias first = matches.getFirst();
        if (matches.stream().anyMatch(registration -> !first.sameTarget(registration))) {
            throw conflict(notFoundContext);
        }
        return first;
    }

    private static String requireAlias(String value) {
        String alias = StableSourceReference.requireText(value, "REFERENCE_ALIAS_REQUIRED");
        if (!ALIAS.matcher(alias).matches()) {
            throw scope("alias format");
        }
        return alias;
    }

    private static void requireSuccessful(RevisionSnapshot revision, String context) {
        if (revision.outcome() != RevisionOutcome.SUCCESSFUL) {
            throw notFound(context + ",revisionOutcome=" + revision.outcome());
        }
    }

    private static String tupleContext(
            String workspaceId, StableSourceReference reference) {
        return "tuple[workspaceId=" + workspaceId
                + ",sourceDocumentId=" + reference.sourceDocumentId()
                + ",revisionId=" + reference.sourceProcessingRevisionId()
                + ",blockId=" + reference.documentBlockId() + "]";
    }

    private static String revisionContext(
            String workspaceId, String sourceDocumentId, String revisionId) {
        return "revision[workspaceId=" + workspaceId
                + ",sourceDocumentId=" + sourceDocumentId
                + ",revisionId=" + revisionId + "]";
    }

    private static String blockTupleContext(
            String context, StableSourceReference reference) {
        return context + ",blockTuple[sourceDocumentId=" + reference.sourceDocumentId()
                + ",revisionId=" + reference.sourceProcessingRevisionId()
                + ",blockId=" + reference.documentBlockId() + "]";
    }

    private static String aliasRegistrationContext(SourceScopedAlias alias) {
        String context = "aliasRegistration[kind=" + alias.kind()
                + ",alias=" + alias.value()
                + ",sourceDocumentId=" + alias.sourceDocumentId();
        if (alias.blockTarget() != null) {
            context += ",targetRevisionId="
                    + alias.blockTarget().sourceProcessingRevisionId()
                    + ",targetBlockId=" + alias.blockTarget().documentBlockId();
        }
        return context + "]";
    }

    private static String scopeKey(String workspaceId, String sourceDocumentId) {
        return workspaceId + "\u0000" + sourceDocumentId;
    }

    private static ReferenceResolutionException notFound(String detail) {
        return new ReferenceResolutionException(
                ReferenceResolutionException.Code.REFERENCE_NOT_FOUND, detail);
    }

    private static ReferenceResolutionException scope(String detail) {
        return new ReferenceResolutionException(
                ReferenceResolutionException.Code.REFERENCE_SCOPE_MISMATCH, detail);
    }

    private static ReferenceResolutionException conflict(String detail) {
        return new ReferenceResolutionException(
                ReferenceResolutionException.Code.REFERENCE_ALIAS_CONFLICT, detail);
    }
}
