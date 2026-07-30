#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
contract_file="${repo_root}/docs/design/wave-1/cognitura-source-preview-contract-1.0.md"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-source-preview.XXXXXX")"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

fail() {
  printf 'SourcePreviewContractValidation = FAIL\n%s\n' "$1" >&2
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
  actual="$(grep -E "^${prefix}" "${file}" || true)"
  actual="$(printf '%s\n' "${actual}" | sed '/^$/d' | LC_ALL=C sort)"
  expected="$(printf '%s\n' "$@" | LC_ALL=C sort)"
  [[ "${actual}" == "${expected}" ]] ||
    fail "$(basename "${file}"): ${prefix} contract set does not match"
}

validate_contract() {
  local file="$1"

  [[ -f "${file}" ]] ||
    fail "contract file is missing: ${file}"

  for required_line in \
    "SourcePreviewContractVersion = 1.0" \
    "ContractStatus = W1_DG4_PASS" \
    "BusinessImplementation = NOT_AUTHORIZED" \
    "PreviewPagination = KEYSET_BY_SOURCE_ORDER" \
    "PreviewCursor = PROCESSING_REVISION_ID+LAST_SOURCE_ORDER" \
    "PreviewCursorRevisionMismatch = REJECT_BAD_REQUEST" \
    "PreviewOffsetPagination = FORBIDDEN" \
    "PreviewDefaultLimit = 100" \
    "PreviewMaximumLimit = 500" \
    "PreviewFactSource = SOURCE_DOCUMENT_DOCUMENT_BLOCK_AND_IMMUTABLE_REFERENCE_ALIAS" \
    "PreviewAliasFactSource = D03_SOURCE_SCOPED_REGISTRY" \
    "PreviewAliasCreation = BEFORE_PREVIEW_READY" \
    "PreviewAliasCollision = HARD_FAILURE_BEFORE_FACT_PUBLICATION" \
    "PreviewRevisionSelector = EXPLICIT_FIXED_REVISION" \
    "RendererFactCreation = FORBIDDEN" \
    "LLMUsage = NONE" \
    "ExternalRelationshipAccessCount = 0" \
    "ExternalRelationshipOperations = NO_STAT_NO_DNS_NO_FILE_READ_NO_NETWORK" \
    "PartialPreviewMarker = REQUIRED" \
    "PartialPreviewInvariant = INCOMPLETE_TRUE+NONEMPTY_OMISSIONS+TOP_WARNING+AFFECTED_MARKERS" \
    "CompletePreviewInvariant = INCOMPLETE_FALSE+EMPTY_OMISSIONS+NO_PARTIAL_WARNING" \
    "PreviewGeneratedSummary = FORBIDDEN" \
    "PreviewTypedPayloadProjection = TYPE_SPECIFIC_WEB_ALLOWLIST" \
    "PreviewImageMediaRef = FORBIDDEN" \
    "WorkspaceScopeEnforcement = REQUIRED" \
    "CrossWorkspaceDisclosure = NOT_FOUND" \
    "NotFoundIdentityFields = ALWAYS_NULL" \
    "NotFoundExistenceOracle = FORBIDDEN" \
    "PartialAcceptanceCommand = ACCEPT_EXACT_PARTIAL_REVISION" \
    "PartialAcceptanceActorSource = TRUSTED_WORKSPACE_CONTEXT" \
    "PartialAcceptanceIdempotency = WORKSPACE_REVISION_AND_IDEMPOTENCY_KEY" \
    "PartialAcceptanceRevocation = FORBIDDEN" \
    "ProcessingPost503Means = COMMAND_NOT_ACCEPTED" \
    "AcceptedRetryableFailureTransport = STATUS_GET_200_NOT_POST_503" \
    "ParserProvider = NOT_SELECTED" \
    "RawFormalInputAccess = NOT_PERFORMED" \
    "FormalDatabaseWrite = NOT_AUTHORIZED"; do
    require_line "${file}" "${required_line}"
  done

  require_exact_prefixed_set \
    "${file}" \
    "ENDPOINT:" \
    "ENDPOINT: POST /api/v1/workspaces/{workspaceId}/source-documents" \
    "ENDPOINT: GET /api/v1/source-documents/{sourceDocumentId}" \
    "ENDPOINT: POST /api/v1/source-documents/{sourceDocumentId}/processing-revisions" \
    "ENDPOINT: GET /api/v1/source-documents/{sourceDocumentId}/processing-revisions/{sourceProcessingRevisionId}" \
    "ENDPOINT: GET /api/v1/source-documents/{sourceDocumentId}/processing-revisions/{sourceProcessingRevisionId}/blocks" \
    "ENDPOINT: POST /api/v1/source-documents/{sourceDocumentId}/processing-revisions/{sourceProcessingRevisionId}/partial-acceptance"

  require_exact_prefixed_set \
    "${file}" \
    "UPLOAD_COMMAND_FIELD:" \
    "UPLOAD_COMMAND_FIELD: workspaceId" \
    "UPLOAD_COMMAND_FIELD: idempotencyKey" \
    "UPLOAD_COMMAND_FIELD: originalFileName" \
    "UPLOAD_COMMAND_FIELD: declaredMediaType" \
    "UPLOAD_COMMAND_FIELD: declaredByteLength" \
    "UPLOAD_COMMAND_FIELD: contentSha256" \
    "UPLOAD_COMMAND_FIELD: binaryStream"

  require_exact_prefixed_set \
    "${file}" \
    "UPLOAD_RESULT_FIELD:" \
    "UPLOAD_RESULT_FIELD: sourceDocumentId" \
    "UPLOAD_RESULT_FIELD: sourceIngestionDisplayStatus" \
    "UPLOAD_RESULT_FIELD: contentSha256" \
    "UPLOAD_RESULT_FIELD: receivedAt"

  require_exact_prefixed_set \
    "${file}" \
    "SOURCE_QUERY_FIELD:" \
    "SOURCE_QUERY_FIELD: sourceDocumentId" \
    "SOURCE_QUERY_FIELD: originalFileName" \
    "SOURCE_QUERY_FIELD: mediaType" \
    "SOURCE_QUERY_FIELD: byteLength" \
    "SOURCE_QUERY_FIELD: contentSha256" \
    "SOURCE_QUERY_FIELD: receivedAt" \
    "SOURCE_QUERY_FIELD: sourceDocumentValidationStatus" \
    "SOURCE_QUERY_FIELD: sourceIngestionDisplayStatus" \
    "SOURCE_QUERY_FIELD: validationFailureCode" \
    "SOURCE_QUERY_FIELD: validationFailureDetail"

  require_exact_prefixed_set \
    "${file}" \
    "PROCESSING_COMMAND_FIELD:" \
    "PROCESSING_COMMAND_FIELD: sourceDocumentId" \
    "PROCESSING_COMMAND_FIELD: parserProfileVersion"

  require_exact_prefixed_set \
    "${file}" \
    "PROCESSING_RESULT_FIELD:" \
    "PROCESSING_RESULT_FIELD: sourceDocumentId" \
    "PROCESSING_RESULT_FIELD: sourceProcessingRevisionId" \
    "PROCESSING_RESULT_FIELD: sourceProcessingRevisionStatus" \
    "PROCESSING_RESULT_FIELD: sourceIngestionDisplayStatus" \
    "PROCESSING_RESULT_FIELD: pollLocation" \
    "PROCESSING_RESULT_FIELD: reused"

  require_exact_prefixed_set \
    "${file}" \
    "REVISION_QUERY_FIELD:" \
    "REVISION_QUERY_FIELD: sourceDocumentId" \
    "REVISION_QUERY_FIELD: sourceProcessingRevisionId" \
    "REVISION_QUERY_FIELD: parserProfileVersion" \
    "REVISION_QUERY_FIELD: sourceProcessingRevisionStatus" \
    "REVISION_QUERY_FIELD: sourceIngestionDisplayStatus" \
    "REVISION_QUERY_FIELD: parseCompleteness" \
    "REVISION_QUERY_FIELD: omissions" \
    "REVISION_QUERY_FIELD: publishedBlockSetDigest" \
    "REVISION_QUERY_FIELD: omissionsDigest" \
    "REVISION_QUERY_FIELD: partialAcceptanceStatus" \
    "REVISION_QUERY_FIELD: failureCode" \
    "REVISION_QUERY_FIELD: failureDetail" \
    "REVISION_QUERY_FIELD: startedAt" \
    "REVISION_QUERY_FIELD: completedAt"

  require_exact_prefixed_set \
    "${file}" \
    "PARTIAL_ACCEPTANCE_COMMAND_FIELD:" \
    "PARTIAL_ACCEPTANCE_COMMAND_FIELD: sourceDocumentId" \
    "PARTIAL_ACCEPTANCE_COMMAND_FIELD: sourceProcessingRevisionId" \
    "PARTIAL_ACCEPTANCE_COMMAND_FIELD: blockSetDigest" \
    "PARTIAL_ACCEPTANCE_COMMAND_FIELD: omissionsDigest" \
    "PARTIAL_ACCEPTANCE_COMMAND_FIELD: idempotencyKey" \
    "PARTIAL_ACCEPTANCE_COMMAND_FIELD: decision"

  require_exact_prefixed_set \
    "${file}" \
    "PARTIAL_ACCEPTANCE_RESULT_FIELD:" \
    "PARTIAL_ACCEPTANCE_RESULT_FIELD: sourceDocumentId" \
    "PARTIAL_ACCEPTANCE_RESULT_FIELD: sourceProcessingRevisionId" \
    "PARTIAL_ACCEPTANCE_RESULT_FIELD: partialAcceptanceStatus" \
    "PARTIAL_ACCEPTANCE_RESULT_FIELD: partialAcceptedAt" \
    "PARTIAL_ACCEPTANCE_RESULT_FIELD: acceptedBy" \
    "PARTIAL_ACCEPTANCE_RESULT_FIELD: consumptionEligible" \
    "PARTIAL_ACCEPTANCE_RESULT_FIELD: idempotentReplay"

  require_exact_prefixed_set \
    "${file}" \
    "PARTIAL_ACCEPTANCE_HTTP:" \
    "PARTIAL_ACCEPTANCE_HTTP: NEW_ACCEPTANCE -> 200_OK" \
    "PARTIAL_ACCEPTANCE_HTTP: IDEMPOTENT_REPLAY -> 200_OK" \
    "PARTIAL_ACCEPTANCE_HTTP: COMPLETE_REVISION -> 409_CONFLICT" \
    "PARTIAL_ACCEPTANCE_HTTP: WRONG_DIGEST_OR_REVISION -> 409_CONFLICT" \
    "PARTIAL_ACCEPTANCE_HTTP: NOT_PREVIEW_READY -> 409_CONFLICT"

  require_exact_prefixed_set \
    "${file}" \
    "PREVIEW_RESULT_FIELD:" \
    "PREVIEW_RESULT_FIELD: sourceDocumentId" \
    "PREVIEW_RESULT_FIELD: sourceProcessingRevisionId" \
    "PREVIEW_RESULT_FIELD: originalFileName" \
    "PREVIEW_RESULT_FIELD: parseCompleteness" \
    "PREVIEW_RESULT_FIELD: publishedBlockSetDigest" \
    "PREVIEW_RESULT_FIELD: omissionsDigest" \
    "PREVIEW_RESULT_FIELD: incomplete" \
    "PREVIEW_RESULT_FIELD: omissions" \
    "PREVIEW_RESULT_FIELD: items[]" \
    "PREVIEW_RESULT_FIELD: nextCursor"

  require_exact_prefixed_set \
    "${file}" \
    "PROCESSING_HTTP:" \
    "PROCESSING_HTTP: NEW_REVISION_OR_RETRY_ATTEMPT -> 202_ACCEPTED_WITH_EXACT_REVISION_AND_POLL_LOCATION" \
    "PROCESSING_HTTP: EXISTING_SUCCESS_OR_TERMINAL -> 200_OK_WITH_EXACT_REVISION_AND_POLL_LOCATION" \
    "PROCESSING_HTTP: COMMAND_NOT_ACCEPTED_INFRA_FAILURE -> 503_SERVICE_UNAVAILABLE" \
    "PROCESSING_HTTP: ACCEPTED_RETRYABLE_FAILURE -> STATUS_GET_200_WITH_RETRYABLE_FAILURE"

  require_exact_prefixed_set \
    "${file}" \
    "HTTP:" \
    "HTTP: 201_CREATED -> NEW_SOURCE_DOCUMENT" \
    "HTTP: 200_OK -> IDEMPOTENT_REPLAY_OR_EXISTING_REVISION" \
    "HTTP: 202_ACCEPTED -> NEW_PROCESSING_REVISION_OR_RETRY_ATTEMPT_ACCEPTED" \
    "HTTP: 400_BAD_REQUEST -> MALFORMED_COMMAND_OR_UNSUPPORTED_PAGINATION" \
    "HTTP: 404_NOT_FOUND -> SOURCE_OR_REVISION_NOT_VISIBLE_IN_WORKSPACE" \
    "HTTP: 409_CONFLICT -> IDEMPOTENCY_CONCURRENT_COMPLETION_PARTIAL_ACCEPTANCE_OR_PREVIEW_STATE_CONFLICT" \
    "HTTP: 413_CONTENT_TOO_LARGE -> RAW_UPLOAD_LIMIT_BEFORE_DOCX_SECURITY_SCAN" \
    "HTTP: 415_UNSUPPORTED_MEDIA_TYPE -> NON_DOCX_INPUT" \
    "HTTP: 422_UNPROCESSABLE_CONTENT -> EMPTY_HASH_MISMATCH_TERMINAL_FORMAT_SECURITY_OR_EXPANDED_ZIP_LIMIT" \
    "HTTP: 503_SERVICE_UNAVAILABLE -> SOURCE_NOT_ACCEPTED_OR_PROCESSING_COMMAND_NOT_ACCEPTED"

  require_exact_prefixed_set \
    "${file}" \
    "ERROR_FIELD:" \
    "ERROR_FIELD: errorCode" \
    "ERROR_FIELD: message" \
    "ERROR_FIELD: retryable" \
    "ERROR_FIELD: sourceDocumentId" \
    "ERROR_FIELD: sourceProcessingRevisionId"

  require_exact_prefixed_set \
    "${file}" \
    "API_ERROR:" \
    "API_ERROR: MALFORMED_COMMAND -> 400,false,IDENTITIES_NULL" \
    "API_ERROR: PAGINATION_INVALID -> 400,false,SOURCE_AND_REVISION_IF_RESOLVED" \
    "API_ERROR: RESOURCE_NOT_FOUND -> 404,false,IDENTITIES_ALWAYS_NULL" \
    "API_ERROR: IDEMPOTENCY_CONFLICT -> 409,false,SOURCE_IF_RESOLVED" \
    "API_ERROR: CONCURRENT_COMPLETION_CONFLICT -> 409,true,SOURCE_AND_REVISION_IF_RESOLVED" \
    "API_ERROR: PARTIAL_ACCEPTANCE_CONFLICT -> 409,false,SOURCE_AND_REVISION_IF_RESOLVED" \
    "API_ERROR: PREVIEW_NOT_READY -> 409,true,SOURCE_AND_REVISION_IF_RESOLVED" \
    "API_ERROR: SOURCE_SIZE_LIMIT -> 413,false,IDENTITIES_NULL" \
    "API_ERROR: UNSUPPORTED_MEDIA_TYPE -> 415,false,IDENTITIES_NULL" \
    "API_ERROR: EMPTY_SOURCE_FILE -> 422,false,CREATED_IDENTITIES_ONLY" \
    "API_ERROR: SOURCE_HASH_MISMATCH -> 422,false,CREATED_IDENTITIES_ONLY" \
    "API_ERROR: DOCX_SECURITY_REJECTED -> 422,false,CREATED_IDENTITIES_ONLY" \
    "API_ERROR: DOCX_FORMAT_INVALID -> 422,false,CREATED_IDENTITIES_ONLY" \
    "API_ERROR: SOURCE_NOT_ACCEPTED_YET -> 503,true,SOURCE_IF_RESOLVED" \
    "API_ERROR: PROCESSING_COMMAND_NOT_ACCEPTED -> 503,true,SOURCE_IF_RESOLVED"

  require_exact_prefixed_set \
    "${file}" \
    "API_STATUS_FAILURE:" \
    "API_STATUS_FAILURE: PARSER_RETRYABLE_FAILURE -> 200,true,SOURCE_AND_REVISION" \
    "API_STATUS_FAILURE: PARSER_TERMINAL_FAILURE -> 200,false,SOURCE_AND_REVISION" \
    "API_STATUS_FAILURE: DOCX_FORMAT_INVALID -> 200,false,SOURCE_AND_REVISION"

  require_exact_prefixed_set \
    "${file}" \
    "WEB_STATE:" \
    "WEB_STATE: UPLOAD_IDLE" \
    "WEB_STATE: UPLOAD_IN_PROGRESS" \
    "WEB_STATE: VALIDATING" \
    "WEB_STATE: PARSING" \
    "WEB_STATE: PREVIEW_READY" \
    "WEB_STATE: PARTIAL_PREVIEW" \
    "WEB_STATE: RETRYABLE_FAILURE" \
    "WEB_STATE: TERMINAL_FAILURE"

  require_exact_prefixed_set \
    "${file}" \
    "STATE_MAP:" \
    "STATE_MAP: LOCAL_IDLE -> UPLOAD_IDLE" \
    "STATE_MAP: LOCAL_UPLOAD -> UPLOAD_IN_PROGRESS" \
    "STATE_MAP: DOCUMENT_RECEIVED_OR_VALIDATING -> VALIDATING" \
    "STATE_MAP: DOCUMENT_REJECTED -> TERMINAL_FAILURE" \
    "STATE_MAP: REVISION_PARSING_OR_PARSED -> PARSING" \
    "STATE_MAP: REVISION_PREVIEW_READY_COMPLETE -> PREVIEW_READY" \
    "STATE_MAP: REVISION_PREVIEW_READY_PARTIAL -> PARTIAL_PREVIEW" \
    "STATE_MAP: REVISION_FAILED_RETRYABLE -> RETRYABLE_FAILURE" \
    "STATE_MAP: REVISION_FAILED_TERMINAL -> TERMINAL_FAILURE"

  require_exact_prefixed_set \
    "${file}" \
    "ACCEPTANCE:" \
    "ACCEPTANCE: UNIT -> IDENTITY+TRANSITION+NORMALIZATION+LINEAGE+PAGINATION" \
    "ACCEPTANCE: CONTRACT -> API_DTO+ERROR_CODE+STATE_PROJECTION+EXTERNAL_ACCESS_ZERO" \
    "ACCEPTANCE: INTEGRATION -> POSTGRESQL18_TESTCONTAINERS_AFTER_DATABASE_GATE" \
    "ACCEPTANCE: SECURITY -> ZIP_LIMITS+TRAVERSAL+DUPLICATE_ENTRY+XXE+EXTERNAL_RELATIONSHIP" \
    "ACCEPTANCE: GOLDEN -> THREE_MANIFEST_DOCX+UNCHANGED_SHA256+ORDER_AND_STRUCTURE_FINGERPRINTS"

  require_exact_prefixed_set \
    "${file}" \
    "FORBIDDEN_WEB_FIELD:" \
    "FORBIDDEN_WEB_FIELD: repository" \
    "FORBIDDEN_WEB_FIELD: mapper" \
    "FORBIDDEN_WEB_FIELD: storageKey" \
    "FORBIDDEN_WEB_FIELD: rawXml" \
    "FORBIDDEN_WEB_FIELD: internalException" \
    "FORBIDDEN_WEB_FIELD: binaryFilesystemPath"

  require_exact_prefixed_set \
    "${file}" \
    "PREVIEW_IMAGE_FIELD:" \
    "PREVIEW_IMAGE_FIELD: relationshipMode" \
    "PREVIEW_IMAGE_FIELD: externalTargetLiteralSha256" \
    "PREVIEW_IMAGE_FIELD: mediaType" \
    "PREVIEW_IMAGE_FIELD: byteLength" \
    "PREVIEW_IMAGE_FIELD: contentSha256" \
    "PREVIEW_IMAGE_FIELD: securityDisclosure"
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

offset_pagination="${test_tmp_root}/offset-pagination.md"
cp "${contract_file}" "${offset_pagination}"
sed -i.bak 's/^PreviewOffsetPagination = FORBIDDEN$/PreviewOffsetPagination = ALLOWED/' "${offset_pagination}"
expect_failure "${offset_pagination}" "missing required contract line: PreviewOffsetPagination = FORBIDDEN"

active_revision="${test_tmp_root}/active-revision.md"
cp "${contract_file}" "${active_revision}"
sed -i.bak 's/^PreviewRevisionSelector = EXPLICIT_FIXED_REVISION$/PreviewRevisionSelector = ACTIVE/' "${active_revision}"
expect_failure "${active_revision}" "missing required contract line: PreviewRevisionSelector"

preview_fact="${test_tmp_root}/preview-fact.md"
cp "${contract_file}" "${preview_fact}"
sed -i.bak 's/^RendererFactCreation = FORBIDDEN$/RendererFactCreation = ALLOWED/' "${preview_fact}"
expect_failure "${preview_fact}" "missing required contract line: RendererFactCreation = FORBIDDEN"

llm_summary="${test_tmp_root}/llm-summary.md"
cp "${contract_file}" "${llm_summary}"
sed -i.bak 's/^PreviewGeneratedSummary = FORBIDDEN$/PreviewGeneratedSummary = LLM/' "${llm_summary}"
expect_failure "${llm_summary}" "missing required contract line: PreviewGeneratedSummary = FORBIDDEN"

external_access="${test_tmp_root}/external-access.md"
cp "${contract_file}" "${external_access}"
sed -i.bak 's/^ExternalRelationshipAccessCount = 0$/ExternalRelationshipAccessCount = 1/' "${external_access}"
expect_failure "${external_access}" "missing required contract line: ExternalRelationshipAccessCount = 0"

missing_partial_marker="${test_tmp_root}/missing-partial-marker.md"
cp "${contract_file}" "${missing_partial_marker}"
sed -i.bak 's/^PartialPreviewMarker = REQUIRED$/PartialPreviewMarker = OPTIONAL/' "${missing_partial_marker}"
expect_failure "${missing_partial_marker}" "missing required contract line: PartialPreviewMarker = REQUIRED"

loose_limit="${test_tmp_root}/loose-limit.md"
cp "${contract_file}" "${loose_limit}"
sed -i.bak 's/^PreviewMaximumLimit = 500$/PreviewMaximumLimit = 5000/' "${loose_limit}"
expect_failure "${loose_limit}" "missing required contract line: PreviewMaximumLimit = 500"

cursor_cross_revision="${test_tmp_root}/cursor-cross-revision.md"
cp "${contract_file}" "${cursor_cross_revision}"
sed -i.bak 's/^PreviewCursorRevisionMismatch = REJECT_BAD_REQUEST$/PreviewCursorRevisionMismatch = ACCEPT/' "${cursor_cross_revision}"
expect_failure "${cursor_cross_revision}" "missing required contract line: PreviewCursorRevisionMismatch"

cross_workspace="${test_tmp_root}/cross-workspace.md"
cp "${contract_file}" "${cross_workspace}"
sed -i.bak 's/^CrossWorkspaceDisclosure = NOT_FOUND$/CrossWorkspaceDisclosure = FORBIDDEN_DETAIL/' "${cross_workspace}"
expect_failure "${cross_workspace}" "missing required contract line: CrossWorkspaceDisclosure = NOT_FOUND"

wrong_error_shape="${test_tmp_root}/wrong-error-shape.md"
cp "${contract_file}" "${wrong_error_shape}"
sed -i.bak '/^ERROR_FIELD: retryable$/d' "${wrong_error_shape}"
expect_failure "${wrong_error_shape}" "ERROR_FIELD: contract set does not match"

wrong_partial_state="${test_tmp_root}/wrong-partial-state.md"
cp "${contract_file}" "${wrong_partial_state}"
sed -i.bak 's/^STATE_MAP: REVISION_PREVIEW_READY_PARTIAL -> PARTIAL_PREVIEW$/STATE_MAP: REVISION_PREVIEW_READY_PARTIAL -> PREVIEW_READY/' "${wrong_partial_state}"
expect_failure "${wrong_partial_state}" "STATE_MAP: contract set does not match"

database_before_gate="${test_tmp_root}/database-before-gate.md"
cp "${contract_file}" "${database_before_gate}"
sed -i.bak 's/^FormalDatabaseWrite = NOT_AUTHORIZED$/FormalDatabaseWrite = AUTHORIZED/' "${database_before_gate}"
expect_failure "${database_before_gate}" "missing required contract line: FormalDatabaseWrite = NOT_AUTHORIZED"

not_found_leaks_identity="${test_tmp_root}/not-found-leaks-identity.md"
cp "${contract_file}" "${not_found_leaks_identity}"
sed -i.bak 's/^NotFoundIdentityFields = ALWAYS_NULL$/NotFoundIdentityFields = REAL_ID_IF_EXISTS/' "${not_found_leaks_identity}"
expect_failure "${not_found_leaks_identity}" "missing required contract line: NotFoundIdentityFields = ALWAYS_NULL"

processing_missing_location="${test_tmp_root}/processing-missing-location.md"
cp "${contract_file}" "${processing_missing_location}"
sed -i.bak '/^PROCESSING_RESULT_FIELD: pollLocation$/d' "${processing_missing_location}"
expect_failure "${processing_missing_location}" "PROCESSING_RESULT_FIELD: contract set does not match"

expanded_zip_as_413="${test_tmp_root}/expanded-zip-as-413.md"
cp "${contract_file}" "${expanded_zip_as_413}"
sed -i.bak 's/^HTTP: 422_UNPROCESSABLE_CONTENT -> EMPTY_HASH_MISMATCH_TERMINAL_FORMAT_SECURITY_OR_EXPANDED_ZIP_LIMIT$/HTTP: 422_UNPROCESSABLE_CONTENT -> TERMINAL_FORMAT_OR_SECURITY/' "${expanded_zip_as_413}"
expect_failure "${expanded_zip_as_413}" "HTTP: contract set does not match"

accepted_failure_as_503="${test_tmp_root}/accepted-failure-as-503.md"
cp "${contract_file}" "${accepted_failure_as_503}"
sed -i.bak 's/^AcceptedRetryableFailureTransport = STATUS_GET_200_NOT_POST_503$/AcceptedRetryableFailureTransport = POST_503/' "${accepted_failure_as_503}"
expect_failure "${accepted_failure_as_503}" "missing required contract line: AcceptedRetryableFailureTransport"

empty_partial="${test_tmp_root}/empty-partial.md"
cp "${contract_file}" "${empty_partial}"
sed -i.bak 's/^PartialPreviewInvariant = INCOMPLETE_TRUE+NONEMPTY_OMISSIONS+TOP_WARNING+AFFECTED_MARKERS$/PartialPreviewInvariant = INCOMPLETE_FALSE+EMPTY_OMISSIONS/' "${empty_partial}"
expect_failure "${empty_partial}" "missing required contract line: PartialPreviewInvariant"

media_ref_exposed="${test_tmp_root}/media-ref-exposed.md"
cp "${contract_file}" "${media_ref_exposed}"
sed -i.bak 's/^PreviewImageMediaRef = FORBIDDEN$/PreviewImageMediaRef = EXPOSED/' "${media_ref_exposed}"
expect_failure "${media_ref_exposed}" "missing required contract line: PreviewImageMediaRef = FORBIDDEN"

external_file_read="${test_tmp_root}/external-file-read.md"
cp "${contract_file}" "${external_file_read}"
sed -i.bak 's/^ExternalRelationshipOperations = NO_STAT_NO_DNS_NO_FILE_READ_NO_NETWORK$/ExternalRelationshipOperations = FILE_READ_ALLOWED/' "${external_file_read}"
expect_failure "${external_file_read}" "missing required contract line: ExternalRelationshipOperations"

parser_selected="${test_tmp_root}/parser-selected.md"
cp "${contract_file}" "${parser_selected}"
sed -i.bak 's/^ParserProvider = NOT_SELECTED$/ParserProvider = APACHE_POI/' "${parser_selected}"
expect_failure "${parser_selected}" "missing required contract line: ParserProvider = NOT_SELECTED"

business_implementation_authorized="${test_tmp_root}/business-implementation-authorized.md"
cp "${contract_file}" "${business_implementation_authorized}"
sed -i.bak 's/^BusinessImplementation = NOT_AUTHORIZED$/BusinessImplementation = AUTHORIZED/' "${business_implementation_authorized}"
expect_failure "${business_implementation_authorized}" "missing required contract line: BusinessImplementation = NOT_AUTHORIZED"

source_query_incomplete="${test_tmp_root}/source-query-incomplete.md"
cp "${contract_file}" "${source_query_incomplete}"
sed -i.bak '/^SOURCE_QUERY_FIELD: byteLength$/d' "${source_query_incomplete}"
expect_failure "${source_query_incomplete}" "SOURCE_QUERY_FIELD: contract set does not match"

error_matrix_incomplete="${test_tmp_root}/error-matrix-incomplete.md"
cp "${contract_file}" "${error_matrix_incomplete}"
sed -i.bak '/^API_ERROR: SOURCE_NOT_ACCEPTED_YET -> /d' "${error_matrix_incomplete}"
expect_failure "${error_matrix_incomplete}" "API_ERROR: contract set does not match"

partial_acceptance_missing="${test_tmp_root}/partial-acceptance-missing.md"
cp "${contract_file}" "${partial_acceptance_missing}"
sed -i.bak '/^ENDPOINT: POST .*partial-acceptance$/d' "${partial_acceptance_missing}"
expect_failure "${partial_acceptance_missing}" "ENDPOINT: contract set does not match"

alias_created_after_preview="${test_tmp_root}/alias-created-after-preview.md"
cp "${contract_file}" "${alias_created_after_preview}"
sed -i.bak 's/^PreviewAliasCreation = BEFORE_PREVIEW_READY$/PreviewAliasCreation = ON_PREVIEW_READ/' "${alias_created_after_preview}"
expect_failure "${alias_created_after_preview}" "missing required contract line: PreviewAliasCreation = BEFORE_PREVIEW_READY"

revision_digest_missing="${test_tmp_root}/revision-digest-missing.md"
cp "${contract_file}" "${revision_digest_missing}"
sed -i.bak '/^REVISION_QUERY_FIELD: omissionsDigest$/d' "${revision_digest_missing}"
expect_failure "${revision_digest_missing}" "REVISION_QUERY_FIELD: contract set does not match"

preview_digest_missing="${test_tmp_root}/preview-digest-missing.md"
cp "${contract_file}" "${preview_digest_missing}"
sed -i.bak '/^PREVIEW_RESULT_FIELD: publishedBlockSetDigest$/d' "${preview_digest_missing}"
expect_failure "${preview_digest_missing}" "PREVIEW_RESULT_FIELD: contract set does not match"

empty_source_error_missing="${test_tmp_root}/empty-source-error-missing.md"
cp "${contract_file}" "${empty_source_error_missing}"
sed -i.bak '/^API_ERROR: EMPTY_SOURCE_FILE -> /d' "${empty_source_error_missing}"
expect_failure "${empty_source_error_missing}" "API_ERROR: contract set does not match"

printf '%s\n' \
  "SourcePreviewContractValidation = PASS" \
  "NegativeCases = 28"
