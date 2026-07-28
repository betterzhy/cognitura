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

field_value() {
  local file="$1"
  local field="$2"

  sed -n "s/^${field} = //p" "${file}"
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

active_task_card="$(field_value "${cards_dir}/README.md" "ActiveTaskCard")"
task_card_set_status="$(field_value "${cards_dir}/README.md" "TaskCardSetStatus")"
inactive_card_file=""
for card_file in "${cards_dir}"/W0-*.md; do
  if [[ "$(field_value "${card_file}" "TaskCardID")" != "${active_task_card}" ]]; then
    inactive_card_file="${card_file}"
    break
  fi
done

[[ -n "${inactive_card_file}" ]] || fail "could not find an inactive task card"
inactive_task_card="$(field_value "${inactive_card_file}" "TaskCardID")"
inactive_status="$(field_value "${inactive_card_file}" "Status")"

queued_card_dir="${test_tmp_root}/queued-card"
cp -R "${cards_dir}" "${queued_card_dir}"
sed -i.bak \
  "s/^Status = ${inactive_status}$/Status = QUEUED/" \
  "${queued_card_dir}/$(basename "${inactive_card_file}")"
rm "${queued_card_dir}/$(basename "${inactive_card_file}").bak"
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
  "s/^Status = ${inactive_status}$/Status = READY/" \
  "${second_ready_dir}/$(basename "${inactive_card_file}")"
rm "${second_ready_dir}/$(basename "${inactive_card_file}").bak"
if [[ "${task_card_set_status}" == "BLOCKED_BY_DOCUMENTATION_GAP" ]]; then
  expect_failure \
    "${second_ready_dir}" \
    "blocked task card set must have zero READY task cards"
else
  expect_failure "${second_ready_dir}" "expected exactly one READY task card"
fi

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
  "s/^ActiveTaskCard = ${active_task_card}$/ActiveTaskCard = ${inactive_task_card}/" \
  "${active_mismatch_dir}/README.md"
rm "${active_mismatch_dir}/README.md.bak"
if [[ "${task_card_set_status}" == "BLOCKED_BY_DOCUMENTATION_GAP" ]]; then
  expect_failure \
    "${active_mismatch_dir}" \
    "blocked task card set must use ActiveTaskCard NONE"
else
  expect_failure \
    "${active_mismatch_dir}" \
    "ActiveTaskCard ${inactive_task_card} is not READY"
fi

blocked_terminal_dir="${test_tmp_root}/blocked-terminal"
cp -R "${cards_dir}" "${blocked_terminal_dir}"
blocked_active_file=("${blocked_terminal_dir}/${active_task_card}-"*.md)
[[ "${#blocked_active_file[@]}" -eq 1 ]] ||
  fail "could not resolve active task card fixture: ${active_task_card}"
sed -i.bak \
  -E 's/^Status = (DONE|READY|QUEUED)$/Status = BLOCKED_BY_DOCUMENTATION_GAP/' \
  "${blocked_active_file[0]}"
rm "${blocked_active_file[0]}.bak"
sed -i.bak \
  -e 's/^ActiveTaskCard = .*$/ActiveTaskCard = NONE/' \
  -e 's/^TaskCardSetStatus = .*$/TaskCardSetStatus = BLOCKED_BY_DOCUMENTATION_GAP/' \
  "${blocked_terminal_dir}/README.md"
rm "${blocked_terminal_dir}/README.md.bak"
expect_success "${blocked_terminal_dir}"

blocked_with_ready_dir="${test_tmp_root}/blocked-with-ready"
cp -R "${blocked_terminal_dir}" "${blocked_with_ready_dir}"
blocked_with_ready_active_file=("${blocked_with_ready_dir}/${active_task_card}-"*.md)
[[ "${#blocked_with_ready_active_file[@]}" -eq 1 ]] ||
  fail "could not resolve blocked active task card fixture: ${active_task_card}"
sed -i.bak \
  's/^Status = BLOCKED_BY_DOCUMENTATION_GAP$/Status = READY/' \
  "${blocked_with_ready_active_file[0]}"
rm "${blocked_with_ready_active_file[0]}.bak"
expect_failure \
  "${blocked_with_ready_dir}" \
  "blocked task card set must have zero READY task cards"

printf '%s\n' \
  "TaskCardContractTests = PASS" \
  "NegativeCases = 8" \
  "BlockedTerminalCases = 1"
