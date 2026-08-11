#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-wave1-implementation-cards"
cards_dir="${repo_root}/docs/task-cards/wave-1-implementation"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-wave1-implementation-cards.XXXXXX")"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local content="$1"
  local expected="$2"
  [[ "${content}" == *"${expected}"* ]] ||
    fail "validation output is missing: ${expected}"
}

set_field() {
  local file="$1"
  local field="$2"
  local value="$3"
  sed -i.bak "s#^${field} = .*\$#${field} = ${value}#" "${file}"
  rm "${file}.bak"
}

set_table_status() {
  local index_file="$1"
  local task_id="$2"
  local old_status="$3"
  local new_status="$4"
  sed -i.bak \
    "/^| \`${task_id}\` |/ s/| \`${old_status}\` |/| \`${new_status}\` |/" \
    "${index_file}"
  rm "${index_file}.bak"
}

expect_failure() {
  local fixture_dir="$1"
  local expected_message="$2"
  local output

  if output="$("${verifier}" --cards-dir "${fixture_dir}" 2>&1)"; then
    fail "invalid fixture unexpectedly passed: ${fixture_dir}"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected error '${expected_message}', got: ${output}"
  negative_cases=$((negative_cases + 1))
}

[[ -x "${verifier}" ]] || fail "Wave 1 implementation task-card verifier is missing or not executable"

validation_output="$(
  "${verifier}" \
    --cards-dir "${cards_dir}"
)"

assert_contains "${validation_output}" "Wave1ImplementationTaskCardValidation = PASS"
assert_contains "${validation_output}" "TaskCardCount = 14"
assert_contains "${validation_output}" "TaskCardSetStatus = READY_FOR_EXECUTION"
assert_contains "${validation_output}" "ActiveTaskCard = W1-I00"

negative_cases=0

second_ready_dir="${test_tmp_root}/second-ready"
cp -R "${cards_dir}" "${second_ready_dir}"
set_field "${second_ready_dir}/W1-I02-source-persistence.md" "Status" "READY"
set_table_status \
  "${second_ready_dir}/README.md" \
  "W1-I02" \
  "BLOCKED_BY_DEPENDENCY" \
  "READY"
expect_failure "${second_ready_dir}" "task card set must have exactly one READY card"

i00_business_write_dir="${test_tmp_root}/i00-business-write"
cp -R "${cards_dir}" "${i00_business_write_dir}"
printf '%s\n' \
  'WriteSet = server/src/main/java/io/cognitura/source/Forbidden.java' >> \
  "${i00_business_write_dir}/W1-I00-implementation-governance.md"
expect_failure \
  "${i00_business_write_dir}" \
  "W1-I00 governance card contains forbidden runtime write"

i01_without_approval_dir="${test_tmp_root}/i01-without-approval"
cp -R "${cards_dir}" "${i01_without_approval_dir}"
set_field "${i01_without_approval_dir}/W1-I00-implementation-governance.md" "Status" "DONE"
set_field "${i01_without_approval_dir}/W1-I01-source-ingestion-domain.md" "Status" "READY"
set_field "${i01_without_approval_dir}/README.md" "ActiveTaskCard" "W1-I01"
set_table_status "${i01_without_approval_dir}/README.md" "W1-I00" "READY" "DONE"
set_table_status \
  "${i01_without_approval_dir}/README.md" \
  "W1-I01" \
  "BLOCKED_BY_USER_AUTHORIZATION" \
  "READY"
expect_failure \
  "${i01_without_approval_dir}" \
  "W1-I01 requires explicit business implementation authorization"

i02_without_db_gate_dir="${test_tmp_root}/i02-without-db-gate"
cp -R "${cards_dir}" "${i02_without_db_gate_dir}"
set_field "${i02_without_db_gate_dir}/W1-I00-implementation-governance.md" "Status" "DONE"
set_field "${i02_without_db_gate_dir}/W1-I01-source-ingestion-domain.md" "Status" "DONE"
set_field "${i02_without_db_gate_dir}/W1-I01-source-ingestion-domain.md" \
  "BusinessImplementationAuthorization" "USER_AUTHORIZED"
set_field "${i02_without_db_gate_dir}/W1-I02-source-persistence.md" "Status" "READY"
set_field "${i02_without_db_gate_dir}/W1-I02-source-persistence.md" \
  "BusinessImplementationAuthorization" "USER_AUTHORIZED"
set_field "${i02_without_db_gate_dir}/README.md" "ActiveTaskCard" "W1-I02"
set_table_status "${i02_without_db_gate_dir}/README.md" "W1-I00" "READY" "DONE"
set_table_status \
  "${i02_without_db_gate_dir}/README.md" \
  "W1-I01" \
  "BLOCKED_BY_USER_AUTHORIZATION" \
  "DONE"
set_table_status \
  "${i02_without_db_gate_dir}/README.md" \
  "W1-I02" \
  "BLOCKED_BY_DEPENDENCY" \
  "READY"
expect_failure \
  "${i02_without_db_gate_dir}" \
  "W1-I02 requires DatabaseGate PASS before READY"

oversized_card_dir="${test_tmp_root}/oversized-card"
cp -R "${cards_dir}" "${oversized_card_dir}"
set_field "${oversized_card_dir}/W1-I03-docx-security-gate.md" "ProductionFileLimit" "9"
expect_failure \
  "${oversized_card_dir}" \
  "ProductionFileLimit exceeds 8 without atomic exception"

duplicate_boundary_dir="${test_tmp_root}/duplicate-boundary"
cp -R "${cards_dir}" "${duplicate_boundary_dir}"
printf '%s\n' 'PrimaryBoundary = DOCX_PARSER' >> \
  "${duplicate_boundary_dir}/W1-I04-text-list-section-parser.md"
expect_failure "${duplicate_boundary_dir}" "PrimaryBoundary must occur exactly once"

i13_missing_dependency_dir="${test_tmp_root}/i13-missing-dependency"
cp -R "${cards_dir}" "${i13_missing_dependency_dir}"
set_field \
  "${i13_missing_dependency_dir}/W1-I13-fixed-implementation-review.md" \
  "DependsOn" \
  "W1-I00,W1-I01,W1-I02,W1-I03,W1-I04,W1-I05,W1-I06,W1-I07,W1-I08,W1-I09,W1-I10,W1-I11"
expect_failure \
  "${i13_missing_dependency_dir}" \
  "W1-I13 must depend on W1-I00 through W1-I12"

i13_wrong_route_dir="${test_tmp_root}/i13-wrong-route"
cp -R "${cards_dir}" "${i13_wrong_route_dir}"
set_field \
  "${i13_wrong_route_dir}/W1-I13-fixed-implementation-review.md" \
  "ReviewRoute" \
  "deep_reviewer"
expect_failure \
  "${i13_wrong_route_dir}" \
  "W1-I13 must use DEEP_REVIEWER_THEN_ULTRA_GATEKEEPER"

blocked_authorization_dir="${test_tmp_root}/blocked-authorization-terminal"
cp -R "${cards_dir}" "${blocked_authorization_dir}"
set_field "${blocked_authorization_dir}/W1-I00-implementation-governance.md" "Status" "DONE"
set_field "${blocked_authorization_dir}/README.md" "ActiveTaskCard" "NONE"
set_field "${blocked_authorization_dir}/README.md" \
  "TaskCardSetStatus" "BLOCKED_BY_USER_AUTHORIZATION"
set_table_status "${blocked_authorization_dir}/README.md" "W1-I00" "READY" "DONE"
blocked_output="$("${verifier}" --cards-dir "${blocked_authorization_dir}")" ||
  fail "valid blocked authorization terminal state was rejected"
assert_contains "${blocked_output}" "TaskCardSetStatus = BLOCKED_BY_USER_AUTHORIZATION"
assert_contains "${blocked_output}" "ActiveTaskCard = NONE"

printf '%s\n' \
  "Wave1ImplementationTaskCardContractTests = PASS" \
  "PositiveCases = 1" \
  "NegativeCases = ${negative_cases}" \
  "BlockedAuthorizationTerminalCases = 1"
