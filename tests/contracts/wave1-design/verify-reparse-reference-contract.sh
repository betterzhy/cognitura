#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
contract_file="${repo_root}/docs/design/wave-1/cognitura-reparse-reference-contract-1.0.md"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-reparse-reference.XXXXXX")"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

fail() {
  printf 'ReparseReferenceContractValidation = FAIL\n%s\n' "$1" >&2
  exit 1
}

require_line() {
  local file="$1"
  local line="$2"
  grep -Fqx "${line}" "${file}" ||
    fail "$(basename "${file}"): missing required contract line: ${line}"
}

require_exact_prefixed_set() {
  local file="$1"
  local prefix="$2"
  shift 2
  local actual
  local expected

  actual="$(
    grep -E "^${prefix}" "${file}" || true
  )"
  actual="$(
    printf '%s\n' "${actual}" |
      sed '/^$/d' |
      LC_ALL=C sort
  )"
  expected="$(
    printf '%s\n' "$@" |
      LC_ALL=C sort
  )"
  [[ "${actual}" == "${expected}" ]] ||
    fail "$(basename "${file}"): ${prefix} contract set does not match"
}

validate_contract() {
  local file="$1"

  [[ -f "${file}" ]] ||
    fail "contract file is missing: ${file}"

  for required_line in \
    "ReparseReferenceContractVersion = 1.0" \
    "ContractStatus = W1_DG3_PASS" \
    "BusinessImplementation = NOT_AUTHORIZED" \
    "DocumentBlockRef = SOURCE_DOCUMENT_ID+PROCESSING_REVISION_ID+DOCUMENT_BLOCK_ID" \
    "DocumentBlockRefResolution = EXACT_IMMUTABLE_TUPLE" \
    "HistoricalReferenceRetargeting = FORBIDDEN" \
    "ActiveRevisionSelectorInEvidenceReference = FORBIDDEN" \
    "NewRevisionBlockIds = REQUIRED" \
    "EvidenceDocumentBlockArtifactRef = IMMUTABLE_ALIAS_TO_DOCUMENT_BLOCK_REF_TUPLE" \
    "AliasCanonicalizationVersion = DBR_ALIAS_V1" \
    "AliasCanonicalTupleEncoding = DOMAIN_TAG_UTF8+VERSION_U8+FIELD_COUNT_U8+EACH_FIELD_UINT32_BE_LENGTH_UTF8" \
    "AliasIdentifierByteNormalization = UTF8_EXACT_NO_CASE_OR_UNICODE_NORMALIZATION" \
    "AliasDigestAlgorithm = SHA256" \
    "AliasCollision = HARD_CONFLICT_NO_LAST_WRITE_WINS" \
    "AliasRegistryInsert = COMPARE_AND_SET_EMPTY_OR_SAME_TARGET" \
    "ReferenceAliasRetargeting = FORBIDDEN" \
    "AliasRegistryScope = SOURCE_DOCUMENT" \
    "AliasRegistryCognitionDependency = NONE" \
    "SourceDocumentAliasCreation = ATOMIC_WITH_SOURCE_DOCUMENT_CREATION" \
    "DocumentBlockAliasCreation = ATOMIC_WITH_BLOCK_SET_PUBLICATION" \
    "AliasCollisionCheck = BEFORE_FACT_PUBLICATION" \
    "AliasAvailability = BEFORE_SOURCE_OR_BLOCK_PREVIEW" \
    "AliasResolutionRequires = WORKSPACE_CONTEXT_SOURCE_DOCUMENT_REVISION_AND_EXACT_TUPLE" \
    "SameHashSameParserProfile = REUSE_SUCCESSFUL_REVISION" \
    "SameHashSameParserProfileFailed = RETRY_ATTEMPT_IN_EXISTING_REVISION" \
    "SameHashSameParserProfileTerminal = RETURN_EXISTING_TERMINAL_REQUIRE_NEW_PROFILE" \
    "SameHashNewParserProfile = CREATE_NEW_PROCESSING_REVISION" \
    "NewSourceBytes = CREATE_NEW_SOURCE_DOCUMENT" \
    "LineageStates = UNCHANGED,MOVED,MODIFIED,SPLIT,MERGED,REMOVED,ADDED,AMBIGUOUS" \
    "LineageMapMutation = FORBIDDEN" \
    "LineageCoverage = ALL_FROM_AND_TO_BLOCKS_EXACTLY_ONCE" \
    "LineageSourceScope = SAME_SOURCE_DOCUMENT_ONLY" \
    "LineageAlgorithmVersionCovers = HASH_CANONICALIZATION+ANCHOR_COMPARISON+CONCATENATION+AMBIGUITY_RULES" \
    "NewLineageAlgorithm = CREATE_NEW_IMMUTABLE_MAP" \
    "AmbiguousLineageAutoResolution = FORBIDDEN" \
    "LineageConfidenceBasis = DETERMINISTIC_EVIDENCE_NOT_LLM_SCORE" \
    "RemovedBlockHistoricalResolution = PRESERVED_WHILE_REVISION_RETAINED" \
    "Wave1BlocksMutableByConsumers = NO" \
    "Wave2RevisionSelector = EXPLICIT_NOT_ACTIVE" \
    "Wave2BlockRefScope = SAME_PROCESSING_REVISION" \
    "Wave2BlockOrder = EXACT_CONTIGUOUS_SOURCE_ORDER" \
    "Wave2DuplicateRefs = FORBIDDEN" \
    "Wave2PartialConsumptionGate = PARTIAL_ACCEPTANCE_STATUS_ACCEPTED" \
    "Wave2CompleteConsumptionGate = PARSE_COMPLETENESS_COMPLETE" \
    "EvidenceFullSourceCopy = FORBIDDEN" \
    "EvidenceSourceKindFromD02OtherPayload = FORBIDDEN" \
    "EvidenceSourceKind = SOURCE_EXPLICIT_OR_SOURCE_SYNTHESIZED_ONLY" \
    "EmptyBlockSectionPathMapping = DOCUMENT_ROOT_SENTINEL" \
    "DocumentRootSentinel = DOCUMENT_ROOT" \
    "LLMUsage = NONE" \
    "FormalDatabaseWrite = NOT_AUTHORIZED"; do
    require_line "${file}" "${required_line}"
  done

  require_exact_prefixed_set \
    "${file}" \
    "DOCUMENT_BLOCK_REF_FIELD:" \
    "DOCUMENT_BLOCK_REF_FIELD: sourceDocumentId" \
    "DOCUMENT_BLOCK_REF_FIELD: sourceProcessingRevisionId" \
    "DOCUMENT_BLOCK_REF_FIELD: documentBlockId"

  require_exact_prefixed_set \
    "${file}" \
    "LINEAGE_FIELD:" \
    "LINEAGE_FIELD: fromProcessingRevisionId" \
    "LINEAGE_FIELD: toProcessingRevisionId" \
    "LINEAGE_FIELD: entries[{fromBlockRefs,toBlockRefs,lineageState,confidenceBasis}]" \
    "LINEAGE_FIELD: createdAt" \
    "LINEAGE_FIELD: algorithmVersion"

  require_exact_prefixed_set \
    "${file}" \
    "LINEAGE_CARDINALITY:" \
    "LINEAGE_CARDINALITY: UNCHANGED -> 1_FROM,1_TO" \
    "LINEAGE_CARDINALITY: MOVED -> 1_FROM,1_TO" \
    "LINEAGE_CARDINALITY: MODIFIED -> 1_FROM,1_TO" \
    "LINEAGE_CARDINALITY: SPLIT -> 1_FROM,MANY_TO" \
    "LINEAGE_CARDINALITY: MERGED -> MANY_FROM,1_TO" \
    "LINEAGE_CARDINALITY: REMOVED -> ONE_OR_MORE_FROM,0_TO" \
    "LINEAGE_CARDINALITY: ADDED -> 0_FROM,ONE_OR_MORE_TO" \
    "LINEAGE_CARDINALITY: AMBIGUOUS -> ONE_OR_MORE_FROM,ONE_OR_MORE_TO"

  require_exact_prefixed_set \
    "${file}" \
    "EVIDENCE_MAP:" \
    "EVIDENCE_MAP: sourceDocumentRef -> IMMUTABLE_SOURCE_DOCUMENT_ALIAS" \
    "EVIDENCE_MAP: documentBlockRef -> IMMUTABLE_DOCUMENT_BLOCK_REF_ALIAS" \
    "EVIDENCE_MAP: sectionPath -> COPY_OR_DOCUMENT_ROOT_SENTINEL" \
    "EVIDENCE_MAP: pageNumber -> COPY_NULL_OR_PROVEN_PAGE_NUMBER" \
    "EVIDENCE_MAP: sourceOrder -> COPY_EXACT_SOURCE_ORDER" \
    "EVIDENCE_MAP: blockType -> COPY_EXACT_BLOCK_TYPE" \
    "EVIDENCE_MAP: contentSummary -> DERIVED_SUMMARY_NOT_FULL_SOURCE"

  require_exact_prefixed_set \
    "${file}" \
    "EVIDENCE_OWNER:" \
    "EVIDENCE_OWNER: schemaVersion -> WAVE3_COGNITION_CONTRACT" \
    "EVIDENCE_OWNER: artifactId -> WAVE3_EVIDENCE_IDENTITY" \
    "EVIDENCE_OWNER: revisionId -> WAVE3_COGNITION_REVISION_NOT_SOURCE_PROCESSING_REVISION" \
    "EVIDENCE_OWNER: publicationState -> WAVE3_EVIDENCE_LIFECYCLE" \
    "EVIDENCE_OWNER: sourceDocumentRef -> W1_IMMUTABLE_ALIAS" \
    "EVIDENCE_OWNER: documentBlockRef -> W1_IMMUTABLE_ALIAS" \
    "EVIDENCE_OWNER: sectionPath -> W1_BLOCK_MAPPING" \
    "EVIDENCE_OWNER: pageNumber -> W1_BLOCK" \
    "EVIDENCE_OWNER: sourceOrder -> W1_BLOCK" \
    "EVIDENCE_OWNER: blockType -> W1_BLOCK" \
    "EVIDENCE_OWNER: contentSummary -> WAVE3_DERIVED_CONTENT" \
    "EVIDENCE_OWNER: sourceKind -> WAVE3_EVIDENCE_SEMANTICS" \
    "EVIDENCE_OWNER: supports -> WAVE3_COGNITION_LINKS" \
    "EVIDENCE_OWNER: inferenceDisclosure -> WAVE3_INFERENCE_DISCLOSURE" \
    "EVIDENCE_OWNER: conflictState -> WAVE3_CONFLICT_MODEL" \
    "EVIDENCE_OWNER: conflictGroupId -> WAVE3_CONFLICT_MODEL" \
    "EVIDENCE_OWNER: resolutionDecision -> WAVE3_USER_DECISION"

  require_exact_prefixed_set \
    "${file}" \
    "CONSUMER:" \
    "CONSUMER: WAVE2_SECTION_UNDERSTANDING -> PROCESSING_REVISION_ID+ORDERED_DOCUMENT_BLOCK_REFS" \
    "CONSUMER: WAVE3_EVIDENCE_REFERENCE -> IMMUTABLE_SOURCE_AND_BLOCK_ALIASES+SOURCE_METADATA"
}

expect_failure() {
  local fixture="$1"
  local expected_message="$2"
  local output

  if output="$(validate_contract "${fixture}" 2>&1)"; then
    fail "invalid fixture unexpectedly passed: ${fixture}"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected error '${expected_message}', got: ${output}"
}

validate_contract "${contract_file}"

silent_retarget="${test_tmp_root}/silent-retarget.md"
cp "${contract_file}" "${silent_retarget}"
sed -i.bak \
  's/^HistoricalReferenceRetargeting = FORBIDDEN$/HistoricalReferenceRetargeting = ACTIVE_REVISION/' \
  "${silent_retarget}"
expect_failure \
  "${silent_retarget}" \
  "missing required contract line: HistoricalReferenceRetargeting = FORBIDDEN"

missing_removed="${test_tmp_root}/missing-removed.md"
cp "${contract_file}" "${missing_removed}"
sed -i.bak \
  's/,REMOVED,ADDED,AMBIGUOUS$/,ADDED,AMBIGUOUS/' \
  "${missing_removed}"
expect_failure \
  "${missing_removed}" \
  "missing required contract line: LineageStates"

new_profile_reuses_revision="${test_tmp_root}/new-profile-reuses-revision.md"
cp "${contract_file}" "${new_profile_reuses_revision}"
sed -i.bak \
  's/^SameHashNewParserProfile = CREATE_NEW_PROCESSING_REVISION$/SameHashNewParserProfile = REUSE_SUCCESSFUL_REVISION/' \
  "${new_profile_reuses_revision}"
expect_failure \
  "${new_profile_reuses_revision}" \
  "missing required contract line: SameHashNewParserProfile"

active_selector_in_evidence="${test_tmp_root}/active-selector-in-evidence.md"
cp "${contract_file}" "${active_selector_in_evidence}"
sed -i.bak \
  's/^ActiveRevisionSelectorInEvidenceReference = FORBIDDEN$/ActiveRevisionSelectorInEvidenceReference = ALLOWED/' \
  "${active_selector_in_evidence}"
expect_failure \
  "${active_selector_in_evidence}" \
  "missing required contract line: ActiveRevisionSelectorInEvidenceReference = FORBIDDEN"

alias_retarget="${test_tmp_root}/alias-retarget.md"
cp "${contract_file}" "${alias_retarget}"
sed -i.bak \
  's/^ReferenceAliasRetargeting = FORBIDDEN$/ReferenceAliasRetargeting = ALLOWED/' \
  "${alias_retarget}"
expect_failure \
  "${alias_retarget}" \
  "missing required contract line: ReferenceAliasRetargeting = FORBIDDEN"

ambiguous_auto_resolved="${test_tmp_root}/ambiguous-auto-resolved.md"
cp "${contract_file}" "${ambiguous_auto_resolved}"
sed -i.bak \
  's/^AmbiguousLineageAutoResolution = FORBIDDEN$/AmbiguousLineageAutoResolution = HIGHEST_SCORE/' \
  "${ambiguous_auto_resolved}"
expect_failure \
  "${ambiguous_auto_resolved}" \
  "missing required contract line: AmbiguousLineageAutoResolution = FORBIDDEN"

removed_reference_deleted="${test_tmp_root}/removed-reference-deleted.md"
cp "${contract_file}" "${removed_reference_deleted}"
sed -i.bak \
  's/^RemovedBlockHistoricalResolution = PRESERVED_WHILE_REVISION_RETAINED$/RemovedBlockHistoricalResolution = DELETED/' \
  "${removed_reference_deleted}"
expect_failure \
  "${removed_reference_deleted}" \
  "missing required contract line: RemovedBlockHistoricalResolution"

bad_split_cardinality="${test_tmp_root}/bad-split-cardinality.md"
cp "${contract_file}" "${bad_split_cardinality}"
sed -i.bak \
  's/^LINEAGE_CARDINALITY: SPLIT -> 1_FROM,MANY_TO$/LINEAGE_CARDINALITY: SPLIT -> MANY_FROM,1_TO/' \
  "${bad_split_cardinality}"
expect_failure \
  "${bad_split_cardinality}" \
  "LINEAGE_CARDINALITY: contract set does not match"

mutable_consumer="${test_tmp_root}/mutable-consumer.md"
cp "${contract_file}" "${mutable_consumer}"
sed -i.bak \
  's/^Wave1BlocksMutableByConsumers = NO$/Wave1BlocksMutableByConsumers = YES/' \
  "${mutable_consumer}"
expect_failure \
  "${mutable_consumer}" \
  "missing required contract line: Wave1BlocksMutableByConsumers = NO"

full_source_copied="${test_tmp_root}/full-source-copied.md"
cp "${contract_file}" "${full_source_copied}"
sed -i.bak \
  's/^EvidenceFullSourceCopy = FORBIDDEN$/EvidenceFullSourceCopy = ALLOWED/' \
  "${full_source_copied}"
expect_failure \
  "${full_source_copied}" \
  "missing required contract line: EvidenceFullSourceCopy = FORBIDDEN"

empty_section_path="${test_tmp_root}/empty-section-path.md"
cp "${contract_file}" "${empty_section_path}"
sed -i.bak \
  's/^EmptyBlockSectionPathMapping = DOCUMENT_ROOT_SENTINEL$/EmptyBlockSectionPathMapping = EMPTY_ARRAY/' \
  "${empty_section_path}"
expect_failure \
  "${empty_section_path}" \
  "missing required contract line: EmptyBlockSectionPathMapping"

llm_confidence="${test_tmp_root}/llm-confidence.md"
cp "${contract_file}" "${llm_confidence}"
sed -i.bak \
  's/^LineageConfidenceBasis = DETERMINISTIC_EVIDENCE_NOT_LLM_SCORE$/LineageConfidenceBasis = LLM_SCORE/' \
  "${llm_confidence}"
expect_failure \
  "${llm_confidence}" \
  "missing required contract line: LineageConfidenceBasis"

noncanonical_alias="${test_tmp_root}/noncanonical-alias.md"
cp "${contract_file}" "${noncanonical_alias}"
sed -i.bak \
  's/^AliasCanonicalTupleEncoding = DOMAIN_TAG_UTF8+VERSION_U8+FIELD_COUNT_U8+EACH_FIELD_UINT32_BE_LENGTH_UTF8$/AliasCanonicalTupleEncoding = DIRECT_CONCATENATION/' \
  "${noncanonical_alias}"
expect_failure \
  "${noncanonical_alias}" \
  "missing required contract line: AliasCanonicalTupleEncoding"

collision_overwrite="${test_tmp_root}/collision-overwrite.md"
cp "${contract_file}" "${collision_overwrite}"
sed -i.bak \
  's/^AliasCollision = HARD_CONFLICT_NO_LAST_WRITE_WINS$/AliasCollision = LAST_WRITE_WINS/' \
  "${collision_overwrite}"
expect_failure \
  "${collision_overwrite}" \
  "missing required contract line: AliasCollision = HARD_CONFLICT_NO_LAST_WRITE_WINS"

terminal_retries="${test_tmp_root}/terminal-retries.md"
cp "${contract_file}" "${terminal_retries}"
sed -i.bak \
  's/^SameHashSameParserProfileTerminal = RETURN_EXISTING_TERMINAL_REQUIRE_NEW_PROFILE$/SameHashSameParserProfileTerminal = RETRY_ATTEMPT/' \
  "${terminal_retries}"
expect_failure \
  "${terminal_retries}" \
  "missing required contract line: SameHashSameParserProfileTerminal"

cross_source_lineage="${test_tmp_root}/cross-source-lineage.md"
cp "${contract_file}" "${cross_source_lineage}"
sed -i.bak \
  's/^LineageSourceScope = SAME_SOURCE_DOCUMENT_ONLY$/LineageSourceScope = CROSS_SOURCE_ALLOWED/' \
  "${cross_source_lineage}"
expect_failure \
  "${cross_source_lineage}" \
  "missing required contract line: LineageSourceScope = SAME_SOURCE_DOCUMENT_ONLY"

algorithm_overwrites_map="${test_tmp_root}/algorithm-overwrites-map.md"
cp "${contract_file}" "${algorithm_overwrites_map}"
sed -i.bak \
  's/^NewLineageAlgorithm = CREATE_NEW_IMMUTABLE_MAP$/NewLineageAlgorithm = OVERWRITE_OLD_MAP/' \
  "${algorithm_overwrites_map}"
expect_failure \
  "${algorithm_overwrites_map}" \
  "missing required contract line: NewLineageAlgorithm = CREATE_NEW_IMMUTABLE_MAP"

wave2_uses_active="${test_tmp_root}/wave2-uses-active.md"
cp "${contract_file}" "${wave2_uses_active}"
sed -i.bak \
  's/^Wave2RevisionSelector = EXPLICIT_NOT_ACTIVE$/Wave2RevisionSelector = ACTIVE/' \
  "${wave2_uses_active}"
expect_failure \
  "${wave2_uses_active}" \
  "missing required contract line: Wave2RevisionSelector = EXPLICIT_NOT_ACTIVE"

wave2_cross_revision="${test_tmp_root}/wave2-cross-revision.md"
cp "${contract_file}" "${wave2_cross_revision}"
sed -i.bak \
  's/^Wave2BlockRefScope = SAME_PROCESSING_REVISION$/Wave2BlockRefScope = MULTIPLE_REVISIONS/' \
  "${wave2_cross_revision}"
expect_failure \
  "${wave2_cross_revision}" \
  "missing required contract line: Wave2BlockRefScope"

wave2_reorders="${test_tmp_root}/wave2-reorders.md"
cp "${contract_file}" "${wave2_reorders}"
sed -i.bak \
  's/^Wave2BlockOrder = EXACT_CONTIGUOUS_SOURCE_ORDER$/Wave2BlockOrder = CONSUMER_SELECTED/' \
  "${wave2_reorders}"
expect_failure \
  "${wave2_reorders}" \
  "missing required contract line: Wave2BlockOrder"

other_source_kind_copied="${test_tmp_root}/other-source-kind-copied.md"
cp "${contract_file}" "${other_source_kind_copied}"
sed -i.bak \
  's/^EvidenceSourceKindFromD02OtherPayload = FORBIDDEN$/EvidenceSourceKindFromD02OtherPayload = COPIED/' \
  "${other_source_kind_copied}"
expect_failure \
  "${other_source_kind_copied}" \
  "missing required contract line: EvidenceSourceKindFromD02OtherPayload = FORBIDDEN"

wrong_evidence_revision_owner="${test_tmp_root}/wrong-evidence-revision-owner.md"
cp "${contract_file}" "${wrong_evidence_revision_owner}"
sed -i.bak \
  's/^EVIDENCE_OWNER: revisionId -> WAVE3_COGNITION_REVISION_NOT_SOURCE_PROCESSING_REVISION$/EVIDENCE_OWNER: revisionId -> W1_SOURCE_PROCESSING_REVISION/' \
  "${wrong_evidence_revision_owner}"
expect_failure \
  "${wrong_evidence_revision_owner}" \
  "EVIDENCE_OWNER: contract set does not match"

business_implementation_authorized="${test_tmp_root}/business-implementation-authorized.md"
cp "${contract_file}" "${business_implementation_authorized}"
sed -i.bak \
  's/^BusinessImplementation = NOT_AUTHORIZED$/BusinessImplementation = AUTHORIZED/' \
  "${business_implementation_authorized}"
expect_failure \
  "${business_implementation_authorized}" \
  "missing required contract line: BusinessImplementation = NOT_AUTHORIZED"

cognition_scoped_alias_registry="${test_tmp_root}/cognition-scoped-alias-registry.md"
cp "${contract_file}" "${cognition_scoped_alias_registry}"
sed -i.bak \
  's/^AliasRegistryScope = SOURCE_DOCUMENT$/AliasRegistryScope = COGNITION_REVISION/' \
  "${cognition_scoped_alias_registry}"
expect_failure \
  "${cognition_scoped_alias_registry}" \
  "missing required contract line: AliasRegistryScope = SOURCE_DOCUMENT"

partial_without_acceptance_gate="${test_tmp_root}/partial-without-acceptance-gate.md"
cp "${contract_file}" "${partial_without_acceptance_gate}"
sed -i.bak \
  's/^Wave2PartialConsumptionGate = PARTIAL_ACCEPTANCE_STATUS_ACCEPTED$/Wave2PartialConsumptionGate = PREVIEW_READY/' \
  "${partial_without_acceptance_gate}"
expect_failure \
  "${partial_without_acceptance_gate}" \
  "missing required contract line: Wave2PartialConsumptionGate"

printf '%s\n' \
  "ReparseReferenceContractValidation = PASS" \
  "NegativeCases = 25"
