#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-specialty-contract-coverage"
coverage_doc="${repo_root}/docs/engineering/cognitura-specialty-contract-coverage.md"
schema_rebaseline="${repo_root}/docs/design/cognitura-schema-baseline-2.0.md"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-specialty-coverage.XXXXXX")"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

make_fixture() {
  local fixture_name="$1"
  local fixture_path="${test_tmp_root}/${fixture_name}.md"

  cp "${coverage_doc}" "${fixture_path}"
  printf '%s\n' "${fixture_path}"
}

expect_failure() {
  local fixture_path="$1"
  local expected_message="$2"
  local output

  if output="$(
    "${verifier}" "${fixture_path}" "${schema_rebaseline}" 2>&1
  )"; then
    fail "invalid fixture unexpectedly passed: ${fixture_path}"
  fi

  if [[ "${output}" != *"${expected_message}"* ]]; then
    fail "expected error '${expected_message}', got: ${output}"
  fi
}

[[ -x "${verifier}" ]] || fail "specialty coverage verifier is missing or not executable"
[[ -f "${coverage_doc}" ]] || fail "specialty coverage document is missing"
[[ -f "${schema_rebaseline}" ]] ||
  fail "approved Schema rebaseline document is missing"

if ! valid_output="$(
  "${verifier}" "${coverage_doc}" "${schema_rebaseline}" 2>&1
)"; then
  fail "canonical specialty coverage was rejected: ${valid_output}"
fi

for expected_line in \
  "SpecialtyContractCoverageValidation = PASS" \
  "MigrationRecordCount = 26" \
  "ContractCoverageCount = 19" \
  "DocumentationGapCount = 2" \
  "EvidenceLimitCount = 1" \
  "SchemaRebaselineApprovalCount = 1" \
  "SchemaRebaselineSourceValidation = PASS" \
  "W0-G3 JsonSchemaValidation = READY"; do
  if [[ "${valid_output}" != *"${expected_line}"* ]]; then
    fail "canonical validation did not report '${expected_line}'"
  fi
done

missing_contract="$(make_fixture "missing-contract")"
sed -i.bak '/^ContractCoverageRecord = KSC-HIERARCHY|/d' "${missing_contract}"
rm "${missing_contract}.bak"
expect_failure "${missing_contract}" "MISSING_CONTRACT_ID: KSC-HIERARCHY"

missing_source="$(make_fixture "missing-source")"
sed -i.bak \
  's@^ContractCoverageRecord = KSC-HIERARCHY|CONSTRUCTION|OD1.2§5-7.1|COVERED_BY_REVERSE_MIGRATION|NONE$@ContractCoverageRecord = KSC-HIERARCHY|CONSTRUCTION||COVERED_BY_REVERSE_MIGRATION|NONE@' \
  "${missing_source}"
rm "${missing_source}.bak"
expect_failure "${missing_source}" "MISSING_SOURCE_SECTION: KSC-HIERARCHY"

invalid_coverage="$(make_fixture "invalid-coverage")"
sed -i.bak \
  's/^ContractCoverageRecord = KSC-HIERARCHY|CONSTRUCTION|OD1.2§5-7.1|COVERED_BY_REVERSE_MIGRATION|NONE$/ContractCoverageRecord = KSC-HIERARCHY|CONSTRUCTION|OD1.2§5-7.1|PARTIAL|NONE/' \
  "${invalid_coverage}"
rm "${invalid_coverage}.bak"
expect_failure "${invalid_coverage}" "INVALID_COVERAGE_STATUS: KSC-HIERARCHY"

missing_migration="$(make_fixture "missing-migration")"
sed -i.bak '/^MigrationRecord = RM-11|/d' "${missing_migration}"
rm "${missing_migration}.bak"
expect_failure "${missing_migration}" "MISSING_MIGRATION_ID: RM-11"

missing_evidence_limit="$(make_fixture "missing-evidence-limit")"
sed -i.bak \
  '/^EvidenceLimitRecord = RM_ID_TO_TOPIC_SOURCE_MISSING|/d' \
  "${missing_evidence_limit}"
rm "${missing_evidence_limit}.bak"
expect_failure \
  "${missing_evidence_limit}" \
  "MISSING_EVIDENCE_LIMIT: RM_ID_TO_TOPIC_SOURCE_MISSING"

closed_gap="$(make_fixture "closed-gap")"
sed -i.bak \
  's/^\(DocumentationGapRecord = DOC-GAP-001|CONSTRUCTION_SPECIALTY_BODY|\)OPEN|/\1CLOSED|/' \
  "${closed_gap}"
rm "${closed_gap}.bak"
expect_failure "${closed_gap}" "DOCUMENTATION_GAP_MUST_REMAIN_OPEN: DOC-GAP-001"

missing_schema_marker="$(make_fixture "missing-schema-marker")"
sed -i.bak \
  's/^\(DocumentationGapRecord = DOC-GAP-001|CONSTRUCTION_SPECIALTY_BODY|OPEN|\)SCHEMA_SOURCE_MISSING|/\1COVERED|/' \
  "${missing_schema_marker}"
rm "${missing_schema_marker}.bak"
expect_failure "${missing_schema_marker}" "SCHEMA_GAP_MARKER_MISSING: DOC-GAP-001"

invalid_disposition="$(make_fixture "invalid-disposition")"
sed -i.bak \
  's/|AUTHORITATIVE_BODY_OR_APPROVED_SCHEMA_REBASELINE|BLOCKS_W0-G3$/|ACCEPT_OVERALL_SUMMARY|BLOCKS_W0-G3/' \
  "${invalid_disposition}"
rm "${invalid_disposition}.bak"
expect_failure "${invalid_disposition}" "INVALID_GAP_DISPOSITION: DOC-GAP-001"

missing_rebaseline_approval="$(make_fixture "missing-rebaseline-approval")"
sed -i.bak \
  '/^SchemaRebaselineApprovalRecord = /d' \
  "${missing_rebaseline_approval}"
rm "${missing_rebaseline_approval}.bak"
expect_failure \
  "${missing_rebaseline_approval}" \
  "MISSING_SCHEMA_REBASELINE_APPROVAL: DOC-GAP-001"

invalid_rebaseline_status="$(make_fixture "invalid-rebaseline-status")"
sed -i.bak \
  's/|APPROVED|W0-04_READY$/|PROPOSED|W0-04_READY/' \
  "${invalid_rebaseline_status}"
rm "${invalid_rebaseline_status}.bak"
expect_failure \
  "${invalid_rebaseline_status}" \
  "INVALID_SCHEMA_REBASELINE_APPROVAL: DOC-GAP-001"

invalid_rebaseline_hash="$(make_fixture "invalid-rebaseline-hash")"
sed -i.bak \
  's/|[a-f0-9]\{64\}|APPROVED|W0-04_READY$/|0000000000000000000000000000000000000000000000000000000000000000|APPROVED|W0-04_READY/' \
  "${invalid_rebaseline_hash}"
rm "${invalid_rebaseline_hash}.bak"
expect_failure \
  "${invalid_rebaseline_hash}" \
  "INVALID_SCHEMA_REBASELINE_HASH: DOC-GAP-001"

missing_schema_rebaseline="${test_tmp_root}/missing-schema-rebaseline.md"
if output="$(
  "${verifier}" "${coverage_doc}" "${missing_schema_rebaseline}" 2>&1
)"; then
  fail "missing Schema rebaseline source unexpectedly passed"
fi
if [[ "${output}" != *"MISSING_SCHEMA_REBASELINE_SOURCE"* ]]; then
  fail "missing Schema rebaseline source returned wrong error: ${output}"
fi

noncanonical_schema_rebaseline="${test_tmp_root}/cognitura-schema-baseline-2.0.md"
cp "${schema_rebaseline}" "${noncanonical_schema_rebaseline}"
if output="$(
  "${verifier}" "${coverage_doc}" "${noncanonical_schema_rebaseline}" 2>&1
)"; then
  fail "non-canonical Schema rebaseline source unexpectedly passed"
fi
if [[ "${output}" != *"NON_CANONICAL_SCHEMA_REBASELINE_SOURCE"* ]]; then
  fail "non-canonical Schema rebaseline source returned wrong error: ${output}"
fi

printf '%s\n' \
  "SpecialtyContractCoverageTests = PASS" \
  "PositiveCoverageDocument = 1" \
  "NegativeCases = 13"
