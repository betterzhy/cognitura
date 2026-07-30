#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
contract_file="${repo_root}/docs/design/wave-1/cognitura-document-block-contract-1.0.md"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-document-block-contract.XXXXXX")"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

fail() {
  printf 'DocumentBlockContractValidation = FAIL\n%s\n' "$1" >&2
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
    "DocumentBlockContractVersion = 1.0" \
    "ContractStatus = W1_DG2_PASS" \
    "BusinessImplementation = NOT_AUTHORIZED" \
    "ParserLibrary = NOT_SELECTED" \
    "SourceOrderBase = 0" \
    "SourceOrderRule = UNIQUE_CONTIGUOUS_WITHIN_PROCESSING_REVISION" \
    "SupportedFlowTraversal = EXPLICIT_CLOSED_SET" \
    "UnsupportedFlowPolicy = EXPLICIT_OMISSION_OR_TERMINAL" \
    "InlineObjectAnchor = PARENT_BLOCK_ID_TEXT_OFFSET_CHILD_ORDINAL" \
    "TableCellObjectAnchor = PARENT_TABLE_BLOCK_ID_ROW_COLUMN_TEXT_OFFSET_CHILD_ORDINAL" \
    "InlineImageOmission = FORBIDDEN" \
    "TableCellImageOmission = FORBIDDEN" \
    "ObjectReplacementCharacterBinding = ORDINAL_MATCHES_IMAGE_ANCHOR_CHILD_ORDINAL" \
    "InlinePlaceholderImageCardinality = BIJECTIVE" \
    "SupportedInlineImageBindingFailure = PARSE_FAILED_TERMINAL" \
    "SupportedTableCellImageBindingFailure = PARSE_FAILED_TERMINAL" \
    "SectionPathDerivation = PRECEDING_RECOGNIZED_HEADINGS_ONLY" \
    "HeadingLevelRange = 1..9" \
    "HeadingStyleGuessing = FORBIDDEN" \
    "PageNumberDefault = null" \
    "ExplicitPageBreakProvesPageNumber = NO" \
    "NonNullPageNumberRequires = APPROVED_DETERMINISTIC_LAYOUT_PROFILE_AND_PAGE_EVIDENCE" \
    "StablePublicReferenceFromSourcePartAndElementIndex = FORBIDDEN" \
    "ContentHashReplacesDocumentBlockId = NO" \
    "ListItemBlockCardinality = ONE_BLOCK_PER_ITEM" \
    "TableMergedCellPreservation = REQUIRED" \
    "InternalImageBytesRepresentation = IMMUTABLE_MEDIA_REF_AND_SHA256" \
    "ExternalImageBytesFetched = NO" \
    "ExternalRelationshipTargetCapture = SHA256_OF_LITERAL_WITHOUT_DEREFERENCE" \
    "ExternalRelationshipContentAccess = ZERO" \
    "ExternalTargetDigestPropagation = IMAGE_PAYLOAD_CONTENT_HASH_REVISION_DIAGNOSTICS" \
    "CaptionTextInference = FORBIDDEN" \
    "ExternalRelationshipDereference = FORBIDDEN" \
    "MacroExecution = FORBIDDEN" \
    "EmbeddedObjectExecution = FORBIDDEN" \
    "XmlExternalEntityResolution = FORBIDDEN" \
    "MAX_ZIP_ENTRY_COUNT = 4096" \
    "MAX_ZIP_ENTRY_BYTES = 16777216" \
    "MAX_ZIP_TOTAL_BYTES = 134217728" \
    "MAX_COMPRESSION_RATIO = 200" \
    "UnknownZipEntrySize = SECURITY_REJECTED" \
    "PartialParseOmissions = EXPLICIT_WITH_ERROR_LOCATIONS" \
    "PartialParsePreviewReady = FORBIDDEN_WITHOUT_USER_VISIBLE_INCOMPLETE_MARKER" \
    "DocumentBlockSetCandidateScope = SOURCE_PROCESSING_ATTEMPT" \
    "DocumentBlockSetBeforePublish = INVISIBLE" \
    "DocumentBlockSetPublicationOwner = D01_ATOMIC_FINALIZE" \
    "DocumentBlockSetIntegrity = VALID_ENVELOPES_UNIQUE_CONTIGUOUS_ORDER_AND_SET_DIGEST" \
    "PartialAcceptanceRequired = YES" \
    "PartialAcceptanceFactOwner = SOURCE_PROCESSING_REVISION" \
    "LLMUsage = NONE" \
    "FormalDatabaseWrite = NOT_AUTHORIZED"; do
    require_line "${file}" "${required_line}"
  done

  require_exact_prefixed_set \
    "${file}" \
    "BLOCK_TYPE:" \
    "BLOCK_TYPE: HEADING" \
    "BLOCK_TYPE: PARAGRAPH" \
    "BLOCK_TYPE: LIST" \
    "BLOCK_TYPE: TABLE" \
    "BLOCK_TYPE: IMAGE" \
    "BLOCK_TYPE: CAPTION" \
    "BLOCK_TYPE: OTHER"

  require_exact_prefixed_set \
    "${file}" \
    "ENVELOPE_FIELD:" \
    "ENVELOPE_FIELD: documentBlockId" \
    "ENVELOPE_FIELD: sourceDocumentId" \
    "ENVELOPE_FIELD: sourceProcessingRevisionId" \
    "ENVELOPE_FIELD: blockType" \
    "ENVELOPE_FIELD: sourceOrder" \
    "ENVELOPE_FIELD: sectionPath" \
    "ENVELOPE_FIELD: pageNumber" \
    "ENVELOPE_FIELD: pageEvidence" \
    "ENVELOPE_FIELD: sourceAnchor" \
    "ENVELOPE_FIELD: sourcePart" \
    "ENVELOPE_FIELD: sourceElementIndex" \
    "ENVELOPE_FIELD: contentHash" \
    "ENVELOPE_FIELD: payload"

  require_exact_prefixed_set \
    "${file}" \
    "SOURCE_ANCHOR_FIELD:" \
    "SOURCE_ANCHOR_FIELD: parentBlockId" \
    "SOURCE_ANCHOR_FIELD: anchorKind" \
    "SOURCE_ANCHOR_FIELD: textOffset" \
    "SOURCE_ANCHOR_FIELD: childOrdinal" \
    "SOURCE_ANCHOR_FIELD: rowIndex" \
    "SOURCE_ANCHOR_FIELD: columnIndex"

  require_exact_prefixed_set \
    "${file}" \
    "SUPPORTED_FLOW:" \
    "SUPPORTED_FLOW: MAIN_DOCUMENT_BODY_BLOCK" \
    "SUPPORTED_FLOW: PARAGRAPH_INLINE_IMAGE" \
    "SUPPORTED_FLOW: TABLE_ROW_CELL_CONTENT" \
    "SUPPORTED_FLOW: TABLE_CELL_INLINE_IMAGE" \
    "SUPPORTED_FLOW: EXPLICIT_CAPTION" \
    "SUPPORTED_FLOW: EXPLICIT_PAGE_BREAK"

  require_exact_prefixed_set \
    "${file}" \
    "PAYLOAD:" \
    "PAYLOAD: HEADING -> text,level,styleName" \
    "PAYLOAD: PARAGRAPH -> text,styleName" \
    "PAYLOAD: LIST -> listInstanceId,itemLevel,itemOrdinal,markerText,text" \
    "PAYLOAD: TABLE -> rows[{rowIndex,cells[{columnIndex,rowSpan,columnSpan,text}]}]" \
    "PAYLOAD: IMAGE -> relationshipId,relationshipMode,externalTargetLiteralSha256,mediaRef,mediaType,byteLength,contentSha256,securityDisclosure" \
    "PAYLOAD: CAPTION -> text,captionForBlockId" \
    "PAYLOAD: OTHER -> text,sourceKind"

  require_exact_prefixed_set \
    "${file}" \
    "SECURITY:" \
    "SECURITY: DUPLICATE_ZIP_ENTRY_NAME -> SECURITY_REJECTED" \
    "SECURITY: ABSOLUTE_ZIP_PATH -> SECURITY_REJECTED" \
    "SECURITY: ZIP_PARENT_TRAVERSAL -> SECURITY_REJECTED" \
    "SECURITY: UNKNOWN_ZIP_ENTRY_SIZE -> SECURITY_REJECTED" \
    "SECURITY: ZIP_LIMIT_EXCEEDED -> SECURITY_REJECTED" \
    "SECURITY: XML_EXTERNAL_ENTITY -> SECURITY_REJECTED" \
    "SECURITY: MACRO_REQUIRING_EXECUTION -> SECURITY_REJECTED" \
    "SECURITY: EXECUTABLE_EMBEDDED_OBJECT -> SECURITY_REJECTED" \
    "SECURITY: EXTERNAL_RELATIONSHIP_DEREFERENCE_REQUEST -> SECURITY_REJECTED"

  require_exact_prefixed_set \
    "${file}" \
    "PARSE_RESULT:" \
    "PARSE_RESULT: SECURITY_REJECTED" \
    "PARSE_RESULT: FORMAT_INVALID" \
    "PARSE_RESULT: PARTIAL_PARSE" \
    "PARSE_RESULT: PARSE_FAILED_RETRYABLE" \
    "PARSE_RESULT: PARSE_FAILED_TERMINAL"

  require_exact_prefixed_set \
    "${file}" \
    "HARD_FAILURE:" \
    "HARD_FAILURE: SECURITY_RULE -> NEVER_PARTIAL" \
    "HARD_FAILURE: MAIN_DOCUMENT_MISSING -> NEVER_PARTIAL" \
    "HARD_FAILURE: SOURCE_ORDER_UNDETERMINED -> NEVER_PARTIAL" \
    "HARD_FAILURE: ENVELOPE_INVALID -> NEVER_PARTIAL" \
    "HARD_FAILURE: PAYLOAD_INVALID -> NEVER_PARTIAL"

  require_exact_prefixed_set \
    "${file}" \
    "D01_MAPPING:" \
    "D01_MAPPING: SECURITY_REJECTED -> DOCUMENT_REJECTED" \
    "D01_MAPPING: FORMAT_INVALID -> DOCUMENT_REJECTED" \
    "D01_MAPPING: PARTIAL_PARSE -> REVISION_PARSED_WITH_PARTIAL_COMPLETENESS" \
    "D01_MAPPING: PARSE_FAILED_RETRYABLE -> ATTEMPT_AND_REVISION_FAILED_RETRYABLE" \
    "D01_MAPPING: PARSE_FAILED_TERMINAL -> ATTEMPT_AND_REVISION_FAILED_TERMINAL"
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

missing_block_type="${test_tmp_root}/missing-block-type.md"
cp "${contract_file}" "${missing_block_type}"
sed -i.bak '/^BLOCK_TYPE: TABLE$/d' "${missing_block_type}"
expect_failure "${missing_block_type}" "BLOCK_TYPE: contract set does not match"

invented_page_number="${test_tmp_root}/invented-page-number.md"
cp "${contract_file}" "${invented_page_number}"
sed -i.bak 's/^PageNumberDefault = null$/PageNumberDefault = 1/' "${invented_page_number}"
expect_failure "${invented_page_number}" "missing required contract line: PageNumberDefault = null"

external_dereference="${test_tmp_root}/external-dereference.md"
cp "${contract_file}" "${external_dereference}"
sed -i.bak \
  's/^ExternalRelationshipDereference = FORBIDDEN$/ExternalRelationshipDereference = ALLOWED/' \
  "${external_dereference}"
expect_failure \
  "${external_dereference}" \
  "missing required contract line: ExternalRelationshipDereference = FORBIDDEN"

loose_zip_limit="${test_tmp_root}/loose-zip-limit.md"
cp "${contract_file}" "${loose_zip_limit}"
sed -i.bak \
  's/^MAX_ZIP_TOTAL_BYTES = 134217728$/MAX_ZIP_TOTAL_BYTES = 268435456/' \
  "${loose_zip_limit}"
expect_failure \
  "${loose_zip_limit}" \
  "missing required contract line: MAX_ZIP_TOTAL_BYTES = 134217728"

non_contiguous_order="${test_tmp_root}/non-contiguous-order.md"
cp "${contract_file}" "${non_contiguous_order}"
sed -i.bak \
  's/^SourceOrderRule = UNIQUE_CONTIGUOUS_WITHIN_PROCESSING_REVISION$/SourceOrderRule = SPARSE/' \
  "${non_contiguous_order}"
expect_failure \
  "${non_contiguous_order}" \
  "missing required contract line: SourceOrderRule = UNIQUE_CONTIGUOUS_WITHIN_PROCESSING_REVISION"

guessed_heading="${test_tmp_root}/guessed-heading.md"
cp "${contract_file}" "${guessed_heading}"
sed -i.bak \
  's/^HeadingStyleGuessing = FORBIDDEN$/HeadingStyleGuessing = ALLOWED/' \
  "${guessed_heading}"
expect_failure \
  "${guessed_heading}" \
  "missing required contract line: HeadingStyleGuessing = FORBIDDEN"

dropped_merged_cells="${test_tmp_root}/dropped-merged-cells.md"
cp "${contract_file}" "${dropped_merged_cells}"
sed -i.bak \
  's/^TableMergedCellPreservation = REQUIRED$/TableMergedCellPreservation = OPTIONAL/' \
  "${dropped_merged_cells}"
expect_failure \
  "${dropped_merged_cells}" \
  "missing required contract line: TableMergedCellPreservation = REQUIRED"

fetched_external_image="${test_tmp_root}/fetched-external-image.md"
cp "${contract_file}" "${fetched_external_image}"
sed -i.bak \
  's/^ExternalImageBytesFetched = NO$/ExternalImageBytesFetched = YES/' \
  "${fetched_external_image}"
expect_failure \
  "${fetched_external_image}" \
  "missing required contract line: ExternalImageBytesFetched = NO"

partial_without_marker="${test_tmp_root}/partial-without-marker.md"
cp "${contract_file}" "${partial_without_marker}"
sed -i.bak \
  's/^PartialParsePreviewReady = FORBIDDEN_WITHOUT_USER_VISIBLE_INCOMPLETE_MARKER$/PartialParsePreviewReady = ALLOWED/' \
  "${partial_without_marker}"
expect_failure \
  "${partial_without_marker}" \
  "missing required contract line: PartialParsePreviewReady"

unknown_size_allowed="${test_tmp_root}/unknown-size-allowed.md"
cp "${contract_file}" "${unknown_size_allowed}"
sed -i.bak \
  's/^UnknownZipEntrySize = SECURITY_REJECTED$/UnknownZipEntrySize = ALLOWED/' \
  "${unknown_size_allowed}"
expect_failure \
  "${unknown_size_allowed}" \
  "missing required contract line: UnknownZipEntrySize = SECURITY_REJECTED"

xxe_allowed="${test_tmp_root}/xxe-allowed.md"
cp "${contract_file}" "${xxe_allowed}"
sed -i.bak \
  's/^XmlExternalEntityResolution = FORBIDDEN$/XmlExternalEntityResolution = ALLOWED/' \
  "${xxe_allowed}"
expect_failure \
  "${xxe_allowed}" \
  "missing required contract line: XmlExternalEntityResolution = FORBIDDEN"

hash_as_identity="${test_tmp_root}/hash-as-identity.md"
cp "${contract_file}" "${hash_as_identity}"
sed -i.bak \
  's/^ContentHashReplacesDocumentBlockId = NO$/ContentHashReplacesDocumentBlockId = YES/' \
  "${hash_as_identity}"
expect_failure \
  "${hash_as_identity}" \
  "missing required contract line: ContentHashReplacesDocumentBlockId = NO"

inline_image_omitted="${test_tmp_root}/inline-image-omitted.md"
cp "${contract_file}" "${inline_image_omitted}"
sed -i.bak \
  's/^InlineImageOmission = FORBIDDEN$/InlineImageOmission = ALLOWED/' \
  "${inline_image_omitted}"
expect_failure \
  "${inline_image_omitted}" \
  "missing required contract line: InlineImageOmission = FORBIDDEN"

table_cell_image_omitted="${test_tmp_root}/table-cell-image-omitted.md"
cp "${contract_file}" "${table_cell_image_omitted}"
sed -i.bak \
  's/^TableCellImageOmission = FORBIDDEN$/TableCellImageOmission = ALLOWED/' \
  "${table_cell_image_omitted}"
expect_failure \
  "${table_cell_image_omitted}" \
  "missing required contract line: TableCellImageOmission = FORBIDDEN"

external_target_ignored="${test_tmp_root}/external-target-ignored.md"
cp "${contract_file}" "${external_target_ignored}"
sed -i.bak \
  's/^ExternalRelationshipTargetCapture = SHA256_OF_LITERAL_WITHOUT_DEREFERENCE$/ExternalRelationshipTargetCapture = RELATIONSHIP_ID_ONLY/' \
  "${external_target_ignored}"
expect_failure \
  "${external_target_ignored}" \
  "missing required contract line: ExternalRelationshipTargetCapture"

external_target_accessed="${test_tmp_root}/external-target-accessed.md"
cp "${contract_file}" "${external_target_accessed}"
sed -i.bak \
  's/^ExternalRelationshipContentAccess = ZERO$/ExternalRelationshipContentAccess = ONE_OR_MORE/' \
  "${external_target_accessed}"
expect_failure \
  "${external_target_accessed}" \
  "missing required contract line: ExternalRelationshipContentAccess = ZERO"

security_as_partial="${test_tmp_root}/security-as-partial.md"
cp "${contract_file}" "${security_as_partial}"
sed -i.bak \
  's/^HARD_FAILURE: SECURITY_RULE -> NEVER_PARTIAL$/HARD_FAILURE: SECURITY_RULE -> PARTIAL_PARSE/' \
  "${security_as_partial}"
expect_failure \
  "${security_as_partial}" \
  "HARD_FAILURE: contract set does not match"

wrong_d01_mapping="${test_tmp_root}/wrong-d01-mapping.md"
cp "${contract_file}" "${wrong_d01_mapping}"
sed -i.bak \
  's/^D01_MAPPING: PARSE_FAILED_TERMINAL -> ATTEMPT_AND_REVISION_FAILED_TERMINAL$/D01_MAPPING: PARSE_FAILED_TERMINAL -> REVISION_PARSED/' \
  "${wrong_d01_mapping}"
expect_failure \
  "${wrong_d01_mapping}" \
  "D01_MAPPING: contract set does not match"

non_bijective_image_binding="${test_tmp_root}/non-bijective-image-binding.md"
cp "${contract_file}" "${non_bijective_image_binding}"
sed -i.bak \
  's/^InlinePlaceholderImageCardinality = BIJECTIVE$/InlinePlaceholderImageCardinality = MANY_TO_ONE/' \
  "${non_bijective_image_binding}"
expect_failure \
  "${non_bijective_image_binding}" \
  "missing required contract line: InlinePlaceholderImageCardinality = BIJECTIVE"

inline_binding_as_partial="${test_tmp_root}/inline-binding-as-partial.md"
cp "${contract_file}" "${inline_binding_as_partial}"
sed -i.bak \
  's/^SupportedInlineImageBindingFailure = PARSE_FAILED_TERMINAL$/SupportedInlineImageBindingFailure = PARTIAL_PARSE/' \
  "${inline_binding_as_partial}"
expect_failure \
  "${inline_binding_as_partial}" \
  "missing required contract line: SupportedInlineImageBindingFailure = PARSE_FAILED_TERMINAL"

table_binding_as_partial="${test_tmp_root}/table-binding-as-partial.md"
cp "${contract_file}" "${table_binding_as_partial}"
sed -i.bak \
  's/^SupportedTableCellImageBindingFailure = PARSE_FAILED_TERMINAL$/SupportedTableCellImageBindingFailure = PARTIAL_PARSE/' \
  "${table_binding_as_partial}"
expect_failure \
  "${table_binding_as_partial}" \
  "missing required contract line: SupportedTableCellImageBindingFailure = PARSE_FAILED_TERMINAL"

target_digest_not_propagated="${test_tmp_root}/target-digest-not-propagated.md"
cp "${contract_file}" "${target_digest_not_propagated}"
sed -i.bak \
  's/^ExternalTargetDigestPropagation = IMAGE_PAYLOAD_CONTENT_HASH_REVISION_DIAGNOSTICS$/ExternalTargetDigestPropagation = IMAGE_PAYLOAD_ONLY/' \
  "${target_digest_not_propagated}"
expect_failure \
  "${target_digest_not_propagated}" \
  "missing required contract line: ExternalTargetDigestPropagation"

business_implementation_authorized="${test_tmp_root}/business-implementation-authorized.md"
cp "${contract_file}" "${business_implementation_authorized}"
sed -i.bak \
  's/^BusinessImplementation = NOT_AUTHORIZED$/BusinessImplementation = AUTHORIZED/' \
  "${business_implementation_authorized}"
expect_failure \
  "${business_implementation_authorized}" \
  "missing required contract line: BusinessImplementation = NOT_AUTHORIZED"

parser_selected="${test_tmp_root}/parser-selected.md"
cp "${contract_file}" "${parser_selected}"
sed -i.bak \
  's/^ParserLibrary = NOT_SELECTED$/ParserLibrary = APACHE_POI/' \
  "${parser_selected}"
expect_failure \
  "${parser_selected}" \
  "missing required contract line: ParserLibrary = NOT_SELECTED"

printf '%s\n' \
  "DocumentBlockContractValidation = PASS" \
  "NegativeCases = 24"
