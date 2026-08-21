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
            workspaceId = StableSourceReference.requireText(workspaceId, "WORKSPACE_ID_REQUIRED");
            sourceDocumentId = StableSourceReference.requireText(
                    sourceDocumentId, "SOURCE_DOCUMENT_ID_REQUIRED");
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
            workspaceId = StableSourceReference.requireText(workspaceId, "WORKSPACE_ID_REQUIRED");
            sourceDocumentId = StableSourceReference.requireText(
                    sourceDocumentId, "SOURCE_DOCUMENT_ID_REQUIRED");
            sourceProcessingRevisionId = StableSourceReference.requireText(
                    sourceProcessingRevisionId, "PROCESSING_REVISION_ID_REQUIRED");
            Objects.requireNonNull(contentSha256, "contentSha256");
            Objects.requireNonNull(profile, "profile");
            Objects.requireNonNull(outcome, "outcome");
            blocks = List.copyOf(Objects.requireNonNull(blocks, "blocks"));
            HashSet<String> blockIds = new HashSet<>();
            for (StableSourceReference block : blocks) {
                Objects.requireNonNull(block, "block");
                if (!sourceDocumentId.equals(block.sourceDocumentId())
                        || !sourceProcessingRevisionId.equals(
                                block.sourceProcessingRevisionId())) {
                    throw scope("revision block scope");
                }
                if (!blockIds.add(block.documentBlockId())) {
                    throw conflict("duplicate block identity in revision");
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
                sourceProcessingRevisionId = StableSourceReference.requireText(
                        sourceProcessingRevisionId, "PROCESSING_REVISION_ID_REQUIRED");
            }
        }
    }

    public StableSourceReference resolveTuple(
            String workspaceId, StableSourceReference requested, Catalog catalog) {
        Objects.requireNonNull(requested, "requested");
        Objects.requireNonNull(catalog, "catalog");
        requireSourceScope(workspaceId, requested.sourceDocumentId(), catalog);
        RevisionSnapshot revision = uniqueRevision(
                workspaceId,
                requested.sourceDocumentId(),
                requested.sourceProcessingRevisionId(),
                catalog);
        List<StableSourceReference> matches = revision.blocks().stream()
                .filter(requested::equals)
                .toList();
        if (matches.size() != 1) {
            throw notFound(tupleContext(requested));
        }
        return matches.getFirst();
    }

    public String resolveSourceAlias(
            String workspaceId, String sourceDocumentId, String alias, Catalog catalog) {
        requireSourceScope(workspaceId, sourceDocumentId, catalog);
        String requestedAlias = requireAlias(alias);
        SourceScopedAlias registration = uniqueAlias(
                requestedAlias,
                catalog,
                "sourceAlias[alias=" + requestedAlias
                        + ",sourceDocumentId=" + sourceDocumentId + "]");
        if (registration.kind() != SourceScopedAlias.Kind.SOURCE_DOCUMENT
                || !sourceDocumentId.equals(registration.sourceDocumentId())) {
            throw scope("source alias context");
        }
        return registration.sourceDocumentId();
    }

    public StableSourceReference resolveBlockAlias(
            String workspaceId,
            String sourceDocumentId,
            String sourceProcessingRevisionId,
            String alias,
            Catalog catalog) {
        requireSourceScope(workspaceId, sourceDocumentId, catalog);
        uniqueRevision(workspaceId, sourceDocumentId, sourceProcessingRevisionId, catalog);
        String requestedAlias = requireAlias(alias);
        SourceScopedAlias registration = uniqueAlias(
                requestedAlias,
                catalog,
                "blockAlias[alias=" + requestedAlias
                        + ",sourceDocumentId=" + sourceDocumentId
                        + ",revisionId=" + sourceProcessingRevisionId + "]");
        if (registration.kind() != SourceScopedAlias.Kind.DOCUMENT_BLOCK
                || !sourceDocumentId.equals(registration.sourceDocumentId())
                || !sourceProcessingRevisionId.equals(
                        registration.blockTarget().sourceProcessingRevisionId())) {
            throw scope("block alias context");
        }
        return resolveTuple(workspaceId, registration.blockTarget(), catalog);
    }

    public SourceScopedAlias registerAlias(
            List<SourceScopedAlias> existing, SourceScopedAlias candidate) {
        Objects.requireNonNull(existing, "existing");
        Objects.requireNonNull(candidate, "candidate");
        if (!candidate.isCanonical()) {
            throw conflict("non-canonical alias target");
        }
        SourceScopedAlias same = null;
        for (SourceScopedAlias registration : existing) {
            Objects.requireNonNull(registration, "registration");
            if (!registration.value().equals(candidate.value())) {
                continue;
            }
            if (!registration.isCanonical() || !registration.sameTarget(candidate)) {
                throw conflict("alias retarget");
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
        requireSourceScope(workspaceId, sourceDocumentId, catalog);
        List<RevisionSnapshot> scoped = catalog.revisions().stream()
                .filter(revision -> workspaceId.equals(revision.workspaceId()))
                .filter(revision -> sourceDocumentId.equals(revision.sourceDocumentId()))
                .toList();
        if (scoped.stream().anyMatch(revision -> !contentSha256.equals(revision.contentSha256()))) {
            throw new ReferenceResolutionException(
                    ReferenceResolutionException.Code.HISTORICAL_RETARGET_FORBIDDEN,
                    "source content identity");
        }
        List<RevisionSnapshot> matches = scoped.stream()
                .filter(revision -> contentSha256.equals(revision.contentSha256()))
                .filter(revision -> profile.equals(revision.profile()))
                .toList();
        if (matches.size() > 1) {
            throw conflict("ambiguous revision identity");
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
            if (!sourceScopes.contains(scopeKey(
                    revision.workspaceId(), revision.sourceDocumentId()))) {
                throw scope("revision source scope");
            }
            String revisionKey = scopeKey(revision.workspaceId(), revision.sourceDocumentId())
                    + "\u0000" + revision.sourceProcessingRevisionId();
            RevisionSnapshot priorRevision = revisionIdentities.putIfAbsent(revisionKey, revision);
            if (priorRevision != null && !priorRevision.equals(revision)) {
                throw conflict("revision identity collision");
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
                            "document block identity reused across revisions");
                }
            }
        }
        Map<String, SourceScopedAlias> registrations = new HashMap<>();
        for (SourceScopedAlias alias : aliases) {
            Objects.requireNonNull(alias, "alias");
            if (!alias.isCanonical()) {
                throw conflict("non-canonical alias target");
            }
            SourceScopedAlias prior = registrations.putIfAbsent(alias.value(), alias);
            if (prior != null && !prior.sameTarget(alias)) {
                throw conflict("alias retarget");
            }
        }
    }

    private static void requireSourceScope(
            String workspaceId, String sourceDocumentId, Catalog catalog) {
        String workspace = StableSourceReference.requireText(workspaceId, "WORKSPACE_ID_REQUIRED");
        String source = StableSourceReference.requireText(
                sourceDocumentId, "SOURCE_DOCUMENT_ID_REQUIRED");
        long matches = catalog.sourceDocuments().stream()
                .filter(snapshot -> workspace.equals(snapshot.workspaceId()))
                .filter(snapshot -> source.equals(snapshot.sourceDocumentId()))
                .count();
        if (matches != 1) {
            throw scope("workspace source context");
        }
    }

    private static RevisionSnapshot uniqueRevision(
            String workspaceId,
            String sourceDocumentId,
            String sourceProcessingRevisionId,
            Catalog catalog) {
        List<RevisionSnapshot> matches = catalog.revisions().stream()
                .filter(revision -> workspaceId.equals(revision.workspaceId()))
                .filter(revision -> sourceDocumentId.equals(revision.sourceDocumentId()))
                .filter(revision -> sourceProcessingRevisionId.equals(
                        revision.sourceProcessingRevisionId()))
                .toList();
        if (matches.isEmpty()) {
            throw notFound("revision[sourceDocumentId=" + sourceDocumentId
                    + ",revisionId=" + sourceProcessingRevisionId + "]");
        }
        RevisionSnapshot first = matches.getFirst();
        if (matches.stream().anyMatch(revision -> !first.equals(revision))) {
            throw conflict("ambiguous revision identity");
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
            throw conflict("alias registry collision");
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

    private static String tupleContext(StableSourceReference reference) {
        return "tuple[sourceDocumentId=" + reference.sourceDocumentId()
                + ",revisionId=" + reference.sourceProcessingRevisionId()
                + ",blockId=" + reference.documentBlockId() + "]";
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
