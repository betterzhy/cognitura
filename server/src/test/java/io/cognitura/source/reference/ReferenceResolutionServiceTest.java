package io.cognitura.source.reference;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.cognitura.source.domain.SourceHash;
import java.util.List;
import org.junit.jupiter.api.Test;

class ReferenceResolutionServiceTest {

    private static final String WORKSPACE = "workspace-a";
    private static final String SOURCE = "source-document-a";
    private static final SourceHash CONTENT_HASH = SourceHash.ofHex("a".repeat(64));
    private static final ReparseProfile PROFILE_V1 = new ReparseProfile("docx-v1");

    private final ReferenceResolutionService service = new ReferenceResolutionService();

    @Test
    void resolvesOnlyTheExactImmutableTupleAndNeverFallsForward() {
        StableSourceReference oldBlock = ref(SOURCE, "revision-1", "block-1");
        StableSourceReference newBlock = ref(SOURCE, "revision-2", "block-2");
        ReferenceResolutionService.Catalog catalog = catalog(
                List.of(source(WORKSPACE, SOURCE)),
                List.of(
                        successful("revision-1", PROFILE_V1, oldBlock),
                        successful("revision-2", new ReparseProfile("docx-v2"), newBlock)),
                List.of());

        assertThat(service.resolveTuple(WORKSPACE, oldBlock, catalog)).isEqualTo(oldBlock);
        assertThat(service.resolveTuple(WORKSPACE, newBlock, catalog)).isEqualTo(newBlock);

        assertThatThrownBy(() -> service.resolveTuple(
                        WORKSPACE, ref(SOURCE, "revision-1", "block-2"), catalog))
                .isInstanceOf(ReferenceResolutionException.class)
                .hasMessageContaining("revision-1")
                .hasMessageContaining("block-2");
        assertCode(
                () -> service.resolveTuple(
                        WORKSPACE, ref(SOURCE, "revision-1", "block-2"), catalog),
                ReferenceResolutionException.Code.REFERENCE_NOT_FOUND);
        assertCode(
                () -> service.resolveTuple(
                        WORKSPACE, ref(SOURCE, "missing-revision", "block-2"), catalog),
                ReferenceResolutionException.Code.REFERENCE_NOT_FOUND);
        assertCode(
                () -> service.resolveTuple("workspace-b", oldBlock, catalog),
                ReferenceResolutionException.Code.REFERENCE_SCOPE_MISMATCH);
        assertThatThrownBy(() -> service.resolveTuple("workspace-b", oldBlock, catalog))
                .isInstanceOf(ReferenceResolutionException.class)
                .hasMessageContaining("workspace-b")
                .hasMessageContaining("revision-1")
                .hasMessageContaining("block-1");
        assertCode(
                () -> service.resolveTuple(
                        WORKSPACE, ref("source-document-b", "revision-1", "block-1"), catalog),
                ReferenceResolutionException.Code.REFERENCE_SCOPE_MISMATCH);
    }

    @Test
    void canonicalAliasesAreDomainSeparatedSourceScopedAndImmutable() {
        StableSourceReference block = ref(SOURCE, "revision-a", "block-a");
        SourceScopedAlias sourceAlias = SourceScopedAlias.sourceDocument(SOURCE);
        SourceScopedAlias blockAlias = SourceScopedAlias.documentBlock(block);
        StableSourceReference nextRevisionBlock = ref(SOURCE, "revision-b", "block-b");

        assertThat(sourceAlias.value()).startsWith("sdr:").hasSize(68);
        assertThat(blockAlias.value())
                .isEqualTo("dbr:587fd6e4a13ecee166aaee248268fe2d4849201076785728a54553a5c18ea32d");
        assertThat(sourceAlias.value().substring(4)).isNotEqualTo(blockAlias.value().substring(4));

        ReferenceResolutionService.Catalog catalog = catalog(
                List.of(source(WORKSPACE, SOURCE)),
                List.of(
                        successful("revision-a", PROFILE_V1, block),
                        successful(
                                "revision-b",
                                new ReparseProfile("docx-v2"),
                                nextRevisionBlock)),
                List.of(sourceAlias, blockAlias));

        assertThat(service.resolveSourceAlias(WORKSPACE, SOURCE, sourceAlias.value(), catalog))
                .isEqualTo(SOURCE);
        assertThat(service.resolveBlockAlias(
                        WORKSPACE, SOURCE, "revision-a", blockAlias.value(), catalog))
                .isEqualTo(block);

        assertCode(
                () -> service.resolveSourceAlias(
                        WORKSPACE, SOURCE, blockAlias.value(), catalog),
                ReferenceResolutionException.Code.REFERENCE_SCOPE_MISMATCH);
        assertThatThrownBy(() -> service.resolveSourceAlias(
                        WORKSPACE, SOURCE, blockAlias.value(), catalog))
                .isInstanceOf(ReferenceResolutionException.class)
                .hasMessageContaining(WORKSPACE)
                .hasMessageContaining(SOURCE)
                .hasMessageContaining(blockAlias.value());
        assertCode(
                () -> service.resolveBlockAlias(
                        WORKSPACE, SOURCE, "revision-b", blockAlias.value(), catalog),
                ReferenceResolutionException.Code.REFERENCE_SCOPE_MISMATCH);
        assertThatThrownBy(() -> service.resolveBlockAlias(
                        WORKSPACE, SOURCE, "revision-b", blockAlias.value(), catalog))
                .isInstanceOf(ReferenceResolutionException.class)
                .hasMessageContaining("revision-b")
                .hasMessageContaining(blockAlias.value());
        assertCode(
                () -> service.resolveBlockAlias(
                        WORKSPACE, SOURCE, "missing-revision", blockAlias.value(), catalog),
                ReferenceResolutionException.Code.REFERENCE_NOT_FOUND);
        assertCode(
                () -> service.resolveBlockAlias(
                        "workspace-b", SOURCE, "revision-a", blockAlias.value(), catalog),
                ReferenceResolutionException.Code.REFERENCE_SCOPE_MISMATCH);

        String missingAlias = "dbr:" + "f".repeat(64);
        assertThatThrownBy(() -> service.resolveBlockAlias(
                        WORKSPACE, SOURCE, "revision-a", missingAlias, catalog))
                .isInstanceOf(ReferenceResolutionException.class)
                .hasMessageContaining(missingAlias)
                .hasMessageContaining("revision-a");
    }

    @Test
    void rejectsAliasRetargetCollisionAndNonCanonicalRegistryFacts() {
        StableSourceReference original = ref(SOURCE, "revision-a", "block-a");
        StableSourceReference retarget = ref(SOURCE, "revision-a", "block-b");
        SourceScopedAlias canonical = SourceScopedAlias.documentBlock(original);
        SourceScopedAlias forged = SourceScopedAlias.registeredDocumentBlock(
                canonical.value(), retarget);

        assertCode(
                () -> new ReferenceResolutionService.Catalog(
                        List.of(source(WORKSPACE, SOURCE)),
                        List.of(successful("revision-a", PROFILE_V1, original, retarget)),
                        List.of(canonical, forged)),
                ReferenceResolutionException.Code.REFERENCE_ALIAS_CONFLICT);
        assertCode(
                () -> service.registerAlias(List.of(), forged),
                ReferenceResolutionException.Code.REFERENCE_ALIAS_CONFLICT);

        assertThat(service.registerAlias(List.of(canonical), canonical)).isSameAs(canonical);
        SourceScopedAlias newAlias = SourceScopedAlias.documentBlock(retarget);
        assertThat(service.registerAlias(List.of(canonical), newAlias)).isEqualTo(newAlias);
    }

    @Test
    void appliesTheFormalReparseDecisionOrderWithoutReplacingHistory() {
        StableSourceReference successBlock = ref(SOURCE, "revision-success", "block-success");
        ReferenceResolutionService.Catalog catalog = catalog(
                List.of(source(WORKSPACE, SOURCE)),
                List.of(
                        successful("revision-success", PROFILE_V1, successBlock),
                        retryable("revision-retry", new ReparseProfile("docx-retry")),
                        terminal("revision-terminal", new ReparseProfile("docx-terminal"))),
                List.of());

        assertThat(service.decideReparse(WORKSPACE, SOURCE, CONTENT_HASH, PROFILE_V1, catalog))
                .isEqualTo(new ReferenceResolutionService.ReparseDecision(
                        ReferenceResolutionService.ReparseAction.REUSE_SUCCESSFUL_REVISION,
                        "revision-success"));
        assertThat(service.decideReparse(
                        WORKSPACE, SOURCE, CONTENT_HASH, new ReparseProfile("docx-retry"), catalog))
                .isEqualTo(new ReferenceResolutionService.ReparseDecision(
                        ReferenceResolutionService.ReparseAction.RETRY_EXISTING_REVISION,
                        "revision-retry"));
        assertThat(service.decideReparse(
                        WORKSPACE, SOURCE, CONTENT_HASH, new ReparseProfile("docx-terminal"), catalog))
                .isEqualTo(new ReferenceResolutionService.ReparseDecision(
                        ReferenceResolutionService.ReparseAction.RETURN_TERMINAL_FAILURE,
                        "revision-terminal"));
        assertThat(service.decideReparse(
                        WORKSPACE, SOURCE, CONTENT_HASH, new ReparseProfile("docx-v2"), catalog))
                .isEqualTo(new ReferenceResolutionService.ReparseDecision(
                        ReferenceResolutionService.ReparseAction.CREATE_NEW_REVISION, null));

        assertCode(
                () -> service.decideReparse(
                        WORKSPACE,
                        SOURCE,
                        SourceHash.ofHex("b".repeat(64)),
                        new ReparseProfile("docx-v2"),
                        catalog),
                ReferenceResolutionException.Code.HISTORICAL_RETARGET_FORBIDDEN);
    }

    @Test
    void refusesAmbiguousRevisionFactsInsteadOfSelectingFirstOrLatest() {
        StableSourceReference first = ref(SOURCE, "revision-a", "block-a");
        StableSourceReference second = ref(SOURCE, "revision-b", "block-b");
        ReferenceResolutionService.Catalog catalog = catalog(
                List.of(source(WORKSPACE, SOURCE)),
                List.of(
                        successful("revision-a", PROFILE_V1, first),
                        successful("revision-b", PROFILE_V1, second)),
                List.of());

        assertCode(
                () -> service.decideReparse(WORKSPACE, SOURCE, CONTENT_HASH, PROFILE_V1, catalog),
                ReferenceResolutionException.Code.REFERENCE_ALIAS_CONFLICT);
    }

    @Test
    void newRevisionCannotReuseHistoricalBlockIdentityAndProfileMatchingIsExact() {
        StableSourceReference oldBlock = ref(SOURCE, "revision-a", "shared-block");
        StableSourceReference reusedBlock = ref(SOURCE, "revision-b", "shared-block");

        assertCode(
                () -> catalog(
                        List.of(source(WORKSPACE, SOURCE)),
                        List.of(
                                successful("revision-a", PROFILE_V1, oldBlock),
                                successful(
                                        "revision-b",
                                        new ReparseProfile("docx-v2"),
                                        reusedBlock)),
                        List.of()),
                ReferenceResolutionException.Code.HISTORICAL_RETARGET_FORBIDDEN);

        ReferenceResolutionService.Catalog catalog = catalog(
                List.of(source(WORKSPACE, SOURCE)),
                List.of(successful("revision-a", PROFILE_V1, oldBlock)),
                List.of());
        assertThat(service.decideReparse(
                        WORKSPACE,
                        SOURCE,
                        CONTENT_HASH,
                        new ReparseProfile("DOCX-V1"),
                        catalog))
                .isEqualTo(new ReferenceResolutionService.ReparseDecision(
                        ReferenceResolutionService.ReparseAction.CREATE_NEW_REVISION, null));
    }

    @Test
    void failedRevisionCannotCarryOrResolveUnpublishedBlocks() {
        StableSourceReference unpublished = ref(SOURCE, "revision-failed", "block-failed");

        assertCode(
                () -> new ReferenceResolutionService.RevisionSnapshot(
                        WORKSPACE,
                        SOURCE,
                        "revision-failed",
                        CONTENT_HASH,
                        PROFILE_V1,
                        ReferenceResolutionService.RevisionOutcome.FAILED_RETRYABLE,
                        List.of(unpublished)),
                ReferenceResolutionException.Code.REFERENCE_SCOPE_MISMATCH);

        SourceScopedAlias alias = SourceScopedAlias.documentBlock(unpublished);
        ReferenceResolutionService.Catalog failedCatalog = catalog(
                List.of(source(WORKSPACE, SOURCE)),
                List.of(retryable("revision-failed", PROFILE_V1)),
                List.of(alias));
        assertCode(
                () -> service.resolveTuple(WORKSPACE, unpublished, failedCatalog),
                ReferenceResolutionException.Code.REFERENCE_NOT_FOUND);
        assertCode(
                () -> service.resolveBlockAlias(
                        WORKSPACE, SOURCE, "revision-failed", alias.value(), failedCatalog),
                ReferenceResolutionException.Code.REFERENCE_NOT_FOUND);
    }

    @Test
    void referenceIdentitiesRejectAbsolutePathAndControlCharacterShapes() {
        assertThatThrownBy(() -> new StableSourceReference(
                        "/Users/private/source", "revision-a", "block-a"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("SOURCE_DOCUMENT_ID_INVALID");
        assertThatThrownBy(() -> new StableSourceReference(
                        SOURCE, "revision-a\nsecret", "block-a"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("PROCESSING_REVISION_ID_INVALID");
    }

    private static ReferenceResolutionService.Catalog catalog(
            List<ReferenceResolutionService.SourceDocumentSnapshot> sources,
            List<ReferenceResolutionService.RevisionSnapshot> revisions,
            List<SourceScopedAlias> aliases) {
        return new ReferenceResolutionService.Catalog(sources, revisions, aliases);
    }

    private static ReferenceResolutionService.SourceDocumentSnapshot source(
            String workspaceId, String sourceDocumentId) {
        return new ReferenceResolutionService.SourceDocumentSnapshot(workspaceId, sourceDocumentId);
    }

    private static ReferenceResolutionService.RevisionSnapshot successful(
            String revisionId, ReparseProfile profile, StableSourceReference... blocks) {
        return revision(
                revisionId,
                profile,
                ReferenceResolutionService.RevisionOutcome.SUCCESSFUL,
                List.of(blocks));
    }

    private static ReferenceResolutionService.RevisionSnapshot retryable(
            String revisionId, ReparseProfile profile) {
        return revision(
                revisionId,
                profile,
                ReferenceResolutionService.RevisionOutcome.FAILED_RETRYABLE,
                List.of());
    }

    private static ReferenceResolutionService.RevisionSnapshot terminal(
            String revisionId, ReparseProfile profile) {
        return revision(
                revisionId,
                profile,
                ReferenceResolutionService.RevisionOutcome.FAILED_TERMINAL,
                List.of());
    }

    private static ReferenceResolutionService.RevisionSnapshot revision(
            String revisionId,
            ReparseProfile profile,
            ReferenceResolutionService.RevisionOutcome outcome,
            List<StableSourceReference> blocks) {
        return new ReferenceResolutionService.RevisionSnapshot(
                WORKSPACE, SOURCE, revisionId, CONTENT_HASH, profile, outcome, blocks);
    }

    private static StableSourceReference ref(
            String sourceDocumentId, String revisionId, String blockId) {
        return new StableSourceReference(sourceDocumentId, revisionId, blockId);
    }

    private static void assertCode(
            org.assertj.core.api.ThrowableAssert.ThrowingCallable call,
            ReferenceResolutionException.Code code) {
        assertThatThrownBy(call)
                .isInstanceOfSatisfying(
                        ReferenceResolutionException.class,
                        error -> assertThat(error.code()).isEqualTo(code));
    }
}
