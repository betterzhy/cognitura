#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
contract_file="${repo_root}/docs/design/wave-1/cognitura-source-document-contract-1.0.md"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-source-document-contract.XXXXXX")"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

fail() {
  printf 'SourceDocumentContractValidation = FAIL\n%s\n' "$1" >&2
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
    grep -E "^${prefix}" "${file}" |
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
    "SourceDocumentContractVersion = 1.0" \
    "ContractStatus = W1_DG1_PASS" \
    "BusinessImplementation = NOT_AUTHORIZED" \
    "SourceDocumentIdentity = LOGICAL_UPLOAD" \
    "SourceBinaryIdentity = SHA256_RAW_BYTES" \
    "ProcessingRevisionIdentity = SOURCE_DOCUMENT_HASH_PARSER_PROFILE" \
    "DuplicateBytesAcrossDifferentRequests = DISTINCT_SOURCE_DOCUMENT_SHARED_BINARY" \
    "SameIdempotencyKeySameBytes = RETURN_EXISTING_SOURCE_DOCUMENT" \
    "SameIdempotencyKeyDifferentBytes = IDEMPOTENCY_CONFLICT" \
    "SourceOriginalMutation = FORBIDDEN" \
    "FormalDatabaseWrite = NOT_AUTHORIZED" \
    "ObjectStorageProvider = NOT_SELECTED" \
    "LLMUsage = NONE" \
    "SourceDocumentValidationStatus = RECEIVED,VALIDATING,ACCEPTED,REJECTED" \
    "SourceProcessingRevisionStatus = PARSING,PARSED,PREVIEW_READY,FAILED_RETRYABLE,FAILED_TERMINAL" \
    "SourceIngestionDisplayStatus = READ_ONLY_PROJECTION" \
    "SourceIngestionDisplayStatusWritable = NO" \
    "AcceptedDocumentStartsRevision = CREATE_OR_REUSE_REVISION_IN_PARSING" \
    "SourceProcessingAttemptStatus = PENDING,RUNNING,SUCCEEDED,FAILED_RETRYABLE,FAILED_TERMINAL" \
    "ActiveAttemptStatuses = PENDING,RUNNING" \
    "MaximumActiveAttemptsPerRevision = 1" \
    "SuccessfulAttemptCardinality = AT_MOST_ONE_PER_REVISION" \
    "RevisionAttemptCoordinatorFields = ACTIVE_ATTEMPT_ID,CURRENT_ATTEMPT_GENERATION" \
    "AttemptFencingFields = ATTEMPT_GENERATION,FENCING_TOKEN" \
    "AttemptFencing = ATTEMPT_GENERATION_AND_ACTIVE_ATTEMPT_ID" \
    "BeginAttemptTransaction = ATOMIC_REVISION_ATTEMPT_GENERATION_ACTIVE_IDENTITY" \
    "AttemptCreationBeforeRevisionTransition = FORBIDDEN" \
    "RetryFailureHistory = PRESERVED_ON_PRIOR_ATTEMPT" \
    "RetryRevisionCurrentFailure = CLEARED" \
    "RetryRevisionCompletedAt = UNSET" \
    "RevisionCompletionCAS = ACTIVE_ATTEMPT_ID_AND_ATTEMPT_GENERATION_MATCH" \
    "AttemptCompletionTransaction = ATOMIC_ATTEMPT_REVISION_BLOCK_SET_STAGE_RECORD_ACTIVE_IDENTITY_AND_COMPLETED_AT" \
    "BlockSetStagingScope = SOURCE_PROCESSING_ATTEMPT" \
    "StagedBlockSetVisibility = PRIVATE_TO_ACTIVE_ATTEMPT" \
    "PublishedBlockSetCardinality = EXACTLY_ONE_PER_PARSED_REVISION" \
    "RevisionPartialConfirmationDigestFields = PUBLISHED_BLOCK_SET_DIGEST_AND_OMISSIONS_DIGEST" \
    "RevisionParseResultFieldsBeforeSuccessfulPublish = ALL_NULL" \
    "BlockSetPublicationCAS = ACTIVE_ATTEMPT_ID_AND_ATTEMPT_GENERATION_MATCH" \
    "BlockSetPublicationTransaction = ATOMIC_WITH_SUCCEEDED_ATTEMPT_PARSED_REVISION_AND_STAGE_RECORD" \
    "PreviewReadyRequiresPublishedBlockSet = YES" \
    "PublishedBlockSetMutation = FORBIDDEN" \
    "SourceParsingGenerationStageRecord = READ_ONLY_PROJECTION_FROM_SOURCE_FACTS" \
    "SourceParsingStageRecordFactOwner = SOURCE_INGESTION_AGGREGATE" \
    "SourceParsingStageRecordPersistence = NO_SECOND_WRITABLE_FACT" \
    "SourceParsingStageName = SOURCE_PARSING" \
    "SourceParsingNoModelProjection = PROMPT_VERSION_NOT_APPLICABLE_AND_MODEL_NOT_APPLICABLE" \
    "LeaseExpiredAttemptStatus = FAILED_RETRYABLE" \
    "LateCompletionAudit = APPEND_ONLY_RESULT_REJECTED_STALE_EVENT" \
    "LateCompletionAttemptMutation = FORBIDDEN"; do
    require_line "${file}" "${required_line}"
  done

  require_exact_prefixed_set \
    "${file}" \
    "DOCUMENT:" \
    "DOCUMENT: RECEIVED -> VALIDATING" \
    "DOCUMENT: VALIDATING -> ACCEPTED" \
    "DOCUMENT: VALIDATING -> REJECTED"

  require_exact_prefixed_set \
    "${file}" \
    "REVISION:" \
    "REVISION: PARSING -> PARSED" \
    "REVISION: PARSING -> FAILED_RETRYABLE" \
    "REVISION: PARSING -> FAILED_TERMINAL" \
    "REVISION: FAILED_RETRYABLE -> PARSING" \
    "REVISION: PARSED -> PREVIEW_READY"

  require_exact_prefixed_set \
    "${file}" \
    "ATTEMPT:" \
    "ATTEMPT: PENDING -> RUNNING" \
    "ATTEMPT: RUNNING -> SUCCEEDED" \
    "ATTEMPT: RUNNING -> FAILED_RETRYABLE" \
    "ATTEMPT: RUNNING -> FAILED_TERMINAL"

  require_exact_prefixed_set \
    "${file}" \
    "BEGIN_ATTEMPT:" \
    "BEGIN_ATTEMPT: INITIAL -> CREATE_PARSING_REVISION,CREATE_PENDING_ATTEMPT,SET_GENERATION_1,SET_ACTIVE_ATTEMPT" \
    "BEGIN_ATTEMPT: RETRY_FROM_FAILED_RETRYABLE -> PARSING,CREATE_PENDING_ATTEMPT,INCREMENT_GENERATION,SET_ACTIVE_ATTEMPT,CLEAR_CURRENT_FAILURE,UNSET_COMPLETED_AT"

  require_exact_prefixed_set \
    "${file}" \
    "FINALIZE:" \
    "FINALIZE: SUCCEEDED -> VALIDATE_AND_PUBLISH_BLOCK_SET,WRITE_SOURCE_PARSING_STAGE_RECORD,PARSED,CLEAR_ACTIVE_ATTEMPT,SET_COMPLETED_AT" \
    "FINALIZE: FAILED_RETRYABLE -> WRITE_SOURCE_PARSING_STAGE_RECORD,FAILED_RETRYABLE,CLEAR_ACTIVE_ATTEMPT,SET_COMPLETED_AT" \
    "FINALIZE: FAILED_TERMINAL -> WRITE_SOURCE_PARSING_STAGE_RECORD,FAILED_TERMINAL,CLEAR_ACTIVE_ATTEMPT,SET_COMPLETED_AT"

  require_exact_prefixed_set \
    "${file}" \
    "STAGE_RECORD_MAP:" \
    "STAGE_RECORD_MAP: schemaVersion -> GENERATION_STAGE_RECORD_SCHEMA_VERSION" \
    "STAGE_RECORD_MAP: runId -> SOURCE_PROCESSING_ATTEMPT_ID" \
    "STAGE_RECORD_MAP: stage -> SOURCE_PARSING" \
    "STAGE_RECORD_MAP: inputHash -> SOURCE_DOCUMENT_ID_PLUS_SHA256_RAW_BYTES_PLUS_PARSER_PROFILE" \
    "STAGE_RECORD_MAP: promptVersion -> NOT_APPLICABLE" \
    "STAGE_RECORD_MAP: model -> NOT_APPLICABLE" \
    "STAGE_RECORD_MAP: sourceBlockRefs -> EMPTY_BEFORE_SOURCE_PARSING" \
    "STAGE_RECORD_MAP: outputKind -> INTERMEDIATE_ON_SUCCESS_NONE_ON_FAILURE" \
    "STAGE_RECORD_MAP: outputSchemaId -> null" \
    "STAGE_RECORD_MAP: structuredOutput -> PUBLISHED_BLOCK_SET_REF_OR_NULL_ON_FAILURE" \
    "STAGE_RECORD_MAP: outputHash -> PUBLISHED_BLOCK_SET_DIGEST_OR_NULL_ON_FAILURE" \
    "STAGE_RECORD_MAP: validationResult -> BLOCK_SET_VALIDATION_OR_FAILURE_CLASSIFICATION" \
    "STAGE_RECORD_MAP: generationStatus -> SUCCEEDED_OR_FAILED_FROM_TERMINAL_ATTEMPT" \
    "STAGE_RECORD_MAP: retryCount -> ATTEMPT_NUMBER_MINUS_ONE" \
    "STAGE_RECORD_MAP: retryScopeRefs -> SOURCE_PROCESSING_REVISION_REF_ON_RETRYABLE_FAILURE_OR_EMPTY" \
    "STAGE_RECORD_MAP: failure -> NULL_ON_SUCCESS_OR_MAPPED_FAILURE_OBJECT"

  require_exact_prefixed_set \
    "${file}" \
    "ERROR:" \
    "ERROR: UNSUPPORTED_MEDIA_TYPE -> REJECTED,false,VALIDATION" \
    "ERROR: EMPTY_SOURCE_FILE -> REJECTED,false,VALIDATION" \
    "ERROR: SOURCE_SIZE_LIMIT -> REJECTED,false,VALIDATION" \
    "ERROR: SOURCE_HASH_MISMATCH -> REJECTED,false,VALIDATION" \
    "ERROR: IDEMPOTENCY_CONFLICT -> NO_NEW_STATE,false,COMMAND" \
    "ERROR: DOCX_SECURITY_REJECTED -> REJECTED,false,VALIDATION" \
    "ERROR: DOCX_FORMAT_INVALID -> REJECTED,false,VALIDATION" \
    "ERROR: DOCX_FORMAT_INVALID -> FAILED_TERMINAL,false,PARSING" \
    "ERROR: PARSER_RETRYABLE_FAILURE -> FAILED_RETRYABLE,true,PARSING" \
    "ERROR: PARSER_TERMINAL_FAILURE -> FAILED_TERMINAL,false,PARSING"

  for port_name in \
    "SourceBinaryStore" \
    "SourceDocumentStore" \
    "SourceProcessingRevisionStore" \
    "DocumentBlockSetStore" \
    "SourceIngestionClock" \
    "SourceIdGenerator"; do
    require_line "${file}" "${port_name}"
  done

  for error_code in \
    "UNSUPPORTED_MEDIA_TYPE" \
    "EMPTY_SOURCE_FILE" \
    "SOURCE_SIZE_LIMIT" \
    "SOURCE_HASH_MISMATCH" \
    "IDEMPOTENCY_CONFLICT" \
    "DOCX_SECURITY_REJECTED" \
    "DOCX_FORMAT_INVALID" \
    "PARSER_RETRYABLE_FAILURE" \
    "PARSER_TERMINAL_FAILURE"; do
    require_line "${file}" "${error_code}"
  done

  require_line \
    "${file}" \
    "SuccessfulRevisionCardinality = AT_MOST_ONE_PER_SOURCE_HASH_PARSER_PROFILE"
  require_line \
    "${file}" \
    "RetryableFailureCreatesNewRevision = NO"
}

expect_failure() {
  local fixture="$1"
  local expected_message="$2"
  local output

  if output="$(validate_contract "${fixture}" 2>&1)"; then
    fail "invalid fixture unexpectedly passed: ${fixture}"
  fi

  if [[ "${output}" != *"${expected_message}"* ]]; then
    fail "expected error '${expected_message}', got: ${output}"
  fi
}

validate_contract "${contract_file}"

missing_identity="${test_tmp_root}/missing-identity.md"
cp "${contract_file}" "${missing_identity}"
sed -i.bak '/^SourceDocumentIdentity = /d' "${missing_identity}"
expect_failure "${missing_identity}" "missing required contract line: SourceDocumentIdentity"

hash_as_document_identity="${test_tmp_root}/hash-as-document-identity.md"
cp "${contract_file}" "${hash_as_document_identity}"
sed -i.bak \
  's/^SourceDocumentIdentity = LOGICAL_UPLOAD$/SourceDocumentIdentity = SHA256_RAW_BYTES/' \
  "${hash_as_document_identity}"
expect_failure \
  "${hash_as_document_identity}" \
  "missing required contract line: SourceDocumentIdentity = LOGICAL_UPLOAD"

silent_duplicate_merge="${test_tmp_root}/silent-duplicate-merge.md"
cp "${contract_file}" "${silent_duplicate_merge}"
sed -i.bak \
  's/^DuplicateBytesAcrossDifferentRequests = DISTINCT_SOURCE_DOCUMENT_SHARED_BINARY$/DuplicateBytesAcrossDifferentRequests = RETURN_EXISTING_SOURCE_DOCUMENT/' \
  "${silent_duplicate_merge}"
expect_failure \
  "${silent_duplicate_merge}" \
  "missing required contract line: DuplicateBytesAcrossDifferentRequests"

idempotency_overwrite="${test_tmp_root}/idempotency-overwrite.md"
cp "${contract_file}" "${idempotency_overwrite}"
sed -i.bak \
  's/^SameIdempotencyKeyDifferentBytes = IDEMPOTENCY_CONFLICT$/SameIdempotencyKeyDifferentBytes = OVERWRITE_EXISTING/' \
  "${idempotency_overwrite}"
expect_failure \
  "${idempotency_overwrite}" \
  "missing required contract line: SameIdempotencyKeyDifferentBytes"

retry_creates_revision="${test_tmp_root}/retry-creates-revision.md"
cp "${contract_file}" "${retry_creates_revision}"
sed -i.bak \
  's/^RetryableFailureCreatesNewRevision = NO$/RetryableFailureCreatesNewRevision = YES/' \
  "${retry_creates_revision}"
expect_failure \
  "${retry_creates_revision}" \
  "missing required contract line: RetryableFailureCreatesNewRevision = NO"

missing_document_transition="${test_tmp_root}/missing-document-transition.md"
cp "${contract_file}" "${missing_document_transition}"
sed -i.bak \
  '/^DOCUMENT: VALIDATING -> ACCEPTED$/d' \
  "${missing_document_transition}"
expect_failure \
  "${missing_document_transition}" \
  "DOCUMENT: contract set does not match"

illegal_document_transition="${test_tmp_root}/illegal-document-transition.md"
cp "${contract_file}" "${illegal_document_transition}"
sed -i.bak \
  '/^DOCUMENT: VALIDATING -> REJECTED$/a\
DOCUMENT: ACCEPTED -> REJECTED\
' \
  "${illegal_document_transition}"
expect_failure \
  "${illegal_document_transition}" \
  "DOCUMENT: contract set does not match"

second_active_attempt="${test_tmp_root}/second-active-attempt.md"
cp "${contract_file}" "${second_active_attempt}"
sed -i.bak \
  's/^MaximumActiveAttemptsPerRevision = 1$/MaximumActiveAttemptsPerRevision = 2/' \
  "${second_active_attempt}"
expect_failure \
  "${second_active_attempt}" \
  "missing required contract line: MaximumActiveAttemptsPerRevision = 1"

two_successful_attempts="${test_tmp_root}/two-successful-attempts.md"
cp "${contract_file}" "${two_successful_attempts}"
sed -i.bak \
  's/^SuccessfulAttemptCardinality = AT_MOST_ONE_PER_REVISION$/SuccessfulAttemptCardinality = MULTIPLE_PER_REVISION/' \
  "${two_successful_attempts}"
expect_failure \
  "${two_successful_attempts}" \
  "missing required contract line: SuccessfulAttemptCardinality"

writable_display_status="${test_tmp_root}/writable-display-status.md"
cp "${contract_file}" "${writable_display_status}"
sed -i.bak \
  's/^SourceIngestionDisplayStatusWritable = NO$/SourceIngestionDisplayStatusWritable = YES/' \
  "${writable_display_status}"
expect_failure \
  "${writable_display_status}" \
  "missing required contract line: SourceIngestionDisplayStatusWritable = NO"

invalid_error_mapping="${test_tmp_root}/invalid-error-mapping.md"
cp "${contract_file}" "${invalid_error_mapping}"
sed -i.bak \
  's/^ERROR: DOCX_FORMAT_INVALID -> FAILED_TERMINAL,false,PARSING$/ERROR: DOCX_FORMAT_INVALID -> PREVIEW_READY,true,PARSING/' \
  "${invalid_error_mapping}"
expect_failure \
  "${invalid_error_mapping}" \
  "ERROR: contract set does not match"

late_result_succeeds="${test_tmp_root}/late-result-succeeds.md"
cp "${contract_file}" "${late_result_succeeds}"
sed -i.bak \
  's/^LateCompletionAudit = APPEND_ONLY_RESULT_REJECTED_STALE_EVENT$/LateCompletionAudit = ACCEPT_AS_SUCCEEDED/' \
  "${late_result_succeeds}"
expect_failure \
  "${late_result_succeeds}" \
  "missing required contract line: LateCompletionAudit = APPEND_ONLY_RESULT_REJECTED_STALE_EVENT"

late_completion_mutates_terminal_attempt="${test_tmp_root}/late-completion-mutates-terminal-attempt.md"
cp "${contract_file}" "${late_completion_mutates_terminal_attempt}"
sed -i.bak \
  's/^LateCompletionAttemptMutation = FORBIDDEN$/LateCompletionAttemptMutation = RESULT_REJECTED_STALE/' \
  "${late_completion_mutates_terminal_attempt}"
expect_failure \
  "${late_completion_mutates_terminal_attempt}" \
  "missing required contract line: LateCompletionAttemptMutation = FORBIDDEN"

retry_keeps_failed_revision="${test_tmp_root}/retry-keeps-failed-revision.md"
cp "${contract_file}" "${retry_keeps_failed_revision}"
sed -i.bak \
  's/^BEGIN_ATTEMPT: RETRY_FROM_FAILED_RETRYABLE -> PARSING,/BEGIN_ATTEMPT: RETRY_FROM_FAILED_RETRYABLE -> FAILED_RETRYABLE,/' \
  "${retry_keeps_failed_revision}"
expect_failure \
  "${retry_keeps_failed_revision}" \
  "BEGIN_ATTEMPT: contract set does not match"

retry_keeps_completed_at="${test_tmp_root}/retry-keeps-completed-at.md"
cp "${contract_file}" "${retry_keeps_completed_at}"
sed -i.bak \
  's/^RetryRevisionCompletedAt = UNSET$/RetryRevisionCompletedAt = PRESERVED/' \
  "${retry_keeps_completed_at}"
expect_failure \
  "${retry_keeps_completed_at}" \
  "missing required contract line: RetryRevisionCompletedAt = UNSET"

non_atomic_attempt_start="${test_tmp_root}/non-atomic-attempt-start.md"
cp "${contract_file}" "${non_atomic_attempt_start}"
sed -i.bak \
  's/^BeginAttemptTransaction = ATOMIC_REVISION_ATTEMPT_GENERATION_ACTIVE_IDENTITY$/BeginAttemptTransaction = SEPARATE_WRITES/' \
  "${non_atomic_attempt_start}"
expect_failure \
  "${non_atomic_attempt_start}" \
  "missing required contract line: BeginAttemptTransaction = ATOMIC_REVISION_ATTEMPT_GENERATION_ACTIVE_IDENTITY"

database_authorized="${test_tmp_root}/database-authorized.md"
cp "${contract_file}" "${database_authorized}"
sed -i.bak \
  's/^FormalDatabaseWrite = NOT_AUTHORIZED$/FormalDatabaseWrite = AUTHORIZED/' \
  "${database_authorized}"
expect_failure \
  "${database_authorized}" \
  "missing required contract line: FormalDatabaseWrite = NOT_AUTHORIZED"

contract_status_downgraded="${test_tmp_root}/contract-status-downgraded.md"
cp "${contract_file}" "${contract_status_downgraded}"
sed -i.bak \
  's/^ContractStatus = W1_DG1_PASS$/ContractStatus = CANDIDATE/' \
  "${contract_status_downgraded}"
expect_failure \
  "${contract_status_downgraded}" \
  "missing required contract line: ContractStatus = W1_DG1_PASS"

business_implementation_authorized="${test_tmp_root}/business-implementation-authorized.md"
cp "${contract_file}" "${business_implementation_authorized}"
sed -i.bak \
  's/^BusinessImplementation = NOT_AUTHORIZED$/BusinessImplementation = AUTHORIZED/' \
  "${business_implementation_authorized}"
expect_failure \
  "${business_implementation_authorized}" \
  "missing required contract line: BusinessImplementation = NOT_AUTHORIZED"

missing_stage_record_mapping="${test_tmp_root}/missing-stage-record-mapping.md"
cp "${contract_file}" "${missing_stage_record_mapping}"
sed -i.bak \
  '/^STAGE_RECORD_MAP: model -> NOT_APPLICABLE$/d' \
  "${missing_stage_record_mapping}"
expect_failure \
  "${missing_stage_record_mapping}" \
  "STAGE_RECORD_MAP: contract set does not match"

non_atomic_block_set_publication="${test_tmp_root}/non-atomic-block-set-publication.md"
cp "${contract_file}" "${non_atomic_block_set_publication}"
sed -i.bak \
  's/^BlockSetPublicationTransaction = ATOMIC_WITH_SUCCEEDED_ATTEMPT_PARSED_REVISION_AND_STAGE_RECORD$/BlockSetPublicationTransaction = SEPARATE_WRITE_AFTER_REVISION_PARSED/' \
  "${non_atomic_block_set_publication}"
expect_failure \
  "${non_atomic_block_set_publication}" \
  "missing required contract line: BlockSetPublicationTransaction"

input_hash_without_source_identity="${test_tmp_root}/input-hash-without-source-identity.md"
cp "${contract_file}" "${input_hash_without_source_identity}"
sed -i.bak \
  's/^STAGE_RECORD_MAP: inputHash -> SOURCE_DOCUMENT_ID_PLUS_SHA256_RAW_BYTES_PLUS_PARSER_PROFILE$/STAGE_RECORD_MAP: inputHash -> SHA256_RAW_BYTES_PLUS_PARSER_PROFILE/' \
  "${input_hash_without_source_identity}"
expect_failure \
  "${input_hash_without_source_identity}" \
  "STAGE_RECORD_MAP: contract set does not match"

missing_omissions_digest_fact="${test_tmp_root}/missing-omissions-digest-fact.md"
cp "${contract_file}" "${missing_omissions_digest_fact}"
sed -i.bak \
  's/^RevisionPartialConfirmationDigestFields = PUBLISHED_BLOCK_SET_DIGEST_AND_OMISSIONS_DIGEST$/RevisionPartialConfirmationDigestFields = PUBLISHED_BLOCK_SET_DIGEST_ONLY/' \
  "${missing_omissions_digest_fact}"
expect_failure \
  "${missing_omissions_digest_fact}" \
  "missing required contract line: RevisionPartialConfirmationDigestFields"

printf '%s\n' \
  "SourceDocumentContractValidation = PASS" \
  "NegativeCases = 23"
