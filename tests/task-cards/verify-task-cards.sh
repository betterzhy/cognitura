#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
verifier="${repo_root}/scripts/verify-task-cards"
cards_dir="${repo_root}/docs/task-cards"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-task-cards.XXXXXX")"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

expect_failure() {
  local fixture_dir="$1"
  local expected_message="$2"
  local output

  if output="$("${verifier}" --cards-dir "${fixture_dir}" 2>&1)"; then
    fail "invalid fixture unexpectedly passed: ${fixture_dir}"
  fi

  if [[ "${output}" != *"${expected_message}"* ]]; then
    fail "expected error '${expected_message}', got: ${output}"
  fi
}

expect_success() {
  local fixture_dir="$1"
  local output

  if ! output="$("${verifier}" --cards-dir "${fixture_dir}" 2>&1)"; then
    fail "valid fixture was rejected: ${output}"
  fi

  if [[ "${output}" != *"TaskCardValidation = PASS"* ]]; then
    fail "valid fixture did not report PASS: ${output}"
  fi
}

if ! valid_output="$("${verifier}" --cards-dir "${cards_dir}" 2>&1)"; then
  fail "canonical task cards were rejected: ${valid_output}"
fi

if [[ "${valid_output}" != *"TaskCardValidation = PASS"* ]]; then
  fail "canonical validation did not report PASS: ${valid_output}"
fi

queued_card_dir="${test_tmp_root}/queued-card"
cp -R "${cards_dir}" "${queued_card_dir}"
sed -i.bak \
  's/^Status = BLOCKED_BY_DEPENDENCY$/Status = QUEUED/' \
  "${queued_card_dir}/W0-06-ui-renderer-contracts.md"
rm "${queued_card_dir}/W0-06-ui-renderer-contracts.md.bak"
expect_success "${queued_card_dir}"

missing_field_dir="${test_tmp_root}/missing-field"
cp -R "${cards_dir}" "${missing_field_dir}"
sed -i.bak '/^Gate = /d' "${missing_field_dir}/W0-02-specialty-contract-coverage.md"
rm "${missing_field_dir}/W0-02-specialty-contract-coverage.md.bak"
expect_failure "${missing_field_dir}" "missing required field: Gate"

duplicate_id_dir="${test_tmp_root}/duplicate-id"
cp -R "${cards_dir}" "${duplicate_id_dir}"
sed -i.bak \
  's/^TaskCardID = W0-02$/TaskCardID = W0-01/' \
  "${duplicate_id_dir}/W0-02-specialty-contract-coverage.md"
rm "${duplicate_id_dir}/W0-02-specialty-contract-coverage.md.bak"
expect_failure "${duplicate_id_dir}" "duplicate TaskCardID: W0-01"

second_ready_dir="${test_tmp_root}/second-ready"
cp -R "${cards_dir}" "${second_ready_dir}"
sed -i.bak \
  's/^Status = BLOCKED_BY_DEPENDENCY$/Status = READY/' \
  "${second_ready_dir}/W0-02-specialty-contract-coverage.md"
rm "${second_ready_dir}/W0-02-specialty-contract-coverage.md.bak"
expect_failure "${second_ready_dir}" "expected exactly one READY task card"

unknown_dependency_dir="${test_tmp_root}/unknown-dependency"
cp -R "${cards_dir}" "${unknown_dependency_dir}"
sed -i.bak \
  's/^DependsOn = W0-01$/DependsOn = W0-99/' \
  "${unknown_dependency_dir}/W0-02-specialty-contract-coverage.md"
rm "${unknown_dependency_dir}/W0-02-specialty-contract-coverage.md.bak"
expect_failure "${unknown_dependency_dir}" "unknown dependency W0-99"

missing_section_dir="${test_tmp_root}/missing-section"
cp -R "${cards_dir}" "${missing_section_dir}"
sed -i.bak \
  '/^## 4[.] 执行步骤$/d' \
  "${missing_section_dir}/W0-02-specialty-contract-coverage.md"
rm "${missing_section_dir}/W0-02-specialty-contract-coverage.md.bak"
expect_failure "${missing_section_dir}" "missing required section: ## 4. 执行步骤"

missing_card_dir="${test_tmp_root}/missing-card"
cp -R "${cards_dir}" "${missing_card_dir}"
rm "${missing_card_dir}/W0-08-fixed-commit-review.md"
expect_failure "${missing_card_dir}" "expected 9 task cards"

active_mismatch_dir="${test_tmp_root}/active-mismatch"
cp -R "${cards_dir}" "${active_mismatch_dir}"
sed -i.bak \
  's/^ActiveTaskCard = W0-01$/ActiveTaskCard = W0-02/' \
  "${active_mismatch_dir}/README.md"
rm "${active_mismatch_dir}/README.md.bak"
expect_failure "${active_mismatch_dir}" "ActiveTaskCard W0-02 is not READY"

printf '%s\n' \
  "TaskCardContractTests = PASS" \
  "NegativeCases = 7"
