#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
verifier="${repo_root}/scripts/verify-wave1-design-cards"
cards_dir="${repo_root}/docs/task-cards/wave-1"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-w1-design-cards.XXXXXX")"

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

  if [[ "${output}" != *"Wave1DesignTaskCardValidation = PASS"* ]]; then
    fail "valid fixture did not report PASS: ${output}"
  fi
}

[[ -x "${verifier}" ]] || fail "Wave 1 design card verifier is missing or not executable"
[[ -d "${cards_dir}" ]] || fail "Wave 1 design card directory is missing"

if ! canonical_output="$("${verifier}" --cards-dir "${cards_dir}" 2>&1)"; then
  fail "canonical Wave 1 design cards were rejected: ${canonical_output}"
fi

canonical_active_task_card="$(
  sed -n 's/^ActiveTaskCard = //p' "${cards_dir}/README.md"
)"
canonical_task_card_set_status="$(
  sed -n 's/^TaskCardSetStatus = //p' "${cards_dir}/README.md"
)"
for expected_line in \
  "Wave1DesignTaskCardValidation = PASS" \
  "TaskCardCount = 6" \
  "TaskCardSetStatus = ${canonical_task_card_set_status}" \
  "ActiveTaskCard = ${canonical_active_task_card}"; do
  if [[ "${canonical_output}" != *"${expected_line}"* ]]; then
    fail "canonical output is missing: ${expected_line}"
  fi
done

ready_baseline_dir="${test_tmp_root}/ready-baseline"
cp -R "${cards_dir}" "${ready_baseline_dir}"
for card_file in "${ready_baseline_dir}"/W1-D*.md; do
  task_card_id="$(sed -n 's/^TaskCardID = //p' "${card_file}")"
  case "${task_card_id}" in
    W1-D00)
      baseline_status="DONE"
      ;;
    W1-D01)
      baseline_status="READY"
      ;;
    *)
      baseline_status="BLOCKED_BY_DEPENDENCY"
      ;;
  esac
  sed -i.bak \
    -E "s/^Status = (DONE|READY|QUEUED|BLOCKED_BY_DEPENDENCY|BLOCKED_BY_DOCUMENTATION_GAP)$/Status = ${baseline_status}/" \
    "${card_file}"
  rm "${card_file}.bak"
done
sed -i.bak \
  -e 's/^ActiveTaskCard = .*$/ActiveTaskCard = W1-D01/' \
  -e 's/^TaskCardSetStatus = .*$/TaskCardSetStatus = READY_FOR_EXECUTION/' \
  "${ready_baseline_dir}/README.md"
rm "${ready_baseline_dir}/README.md.bak"
expect_success "${ready_baseline_dir}"

missing_field_dir="${test_tmp_root}/missing-field"
cp -R "${ready_baseline_dir}" "${missing_field_dir}"
sed -i.bak '/^Gate = /d' \
  "${missing_field_dir}/W1-D01-source-document-contract.md"
rm "${missing_field_dir}/W1-D01-source-document-contract.md.bak"
expect_failure "${missing_field_dir}" "missing required field: Gate"

duplicate_id_dir="${test_tmp_root}/duplicate-id"
cp -R "${ready_baseline_dir}" "${duplicate_id_dir}"
sed -i.bak \
  's/^TaskCardID = W1-D02$/TaskCardID = W1-D01/' \
  "${duplicate_id_dir}/W1-D02-document-block-contract.md"
rm "${duplicate_id_dir}/W1-D02-document-block-contract.md.bak"
expect_failure "${duplicate_id_dir}" "duplicate TaskCardID: W1-D01"

second_ready_dir="${test_tmp_root}/second-ready"
cp -R "${ready_baseline_dir}" "${second_ready_dir}"
sed -i.bak \
  's/^Status = BLOCKED_BY_DEPENDENCY$/Status = READY/' \
  "${second_ready_dir}/W1-D02-document-block-contract.md"
rm "${second_ready_dir}/W1-D02-document-block-contract.md.bak"
sed -i.bak \
  's/^DependsOn = W1-D01$/DependsOn = W1-D00/' \
  "${second_ready_dir}/W1-D02-document-block-contract.md"
rm "${second_ready_dir}/W1-D02-document-block-contract.md.bak"
expect_failure "${second_ready_dir}" "expected exactly one READY task card"

unknown_dependency_dir="${test_tmp_root}/unknown-dependency"
cp -R "${ready_baseline_dir}" "${unknown_dependency_dir}"
sed -i.bak \
  's/^DependsOn = W1-D01$/DependsOn = W1-D99/' \
  "${unknown_dependency_dir}/W1-D02-document-block-contract.md"
rm "${unknown_dependency_dir}/W1-D02-document-block-contract.md.bak"
expect_failure "${unknown_dependency_dir}" "unknown dependency W1-D99"

dependency_cycle_dir="${test_tmp_root}/dependency-cycle"
cp -R "${ready_baseline_dir}" "${dependency_cycle_dir}"
sed -i.bak \
  's/^DependsOn = NONE$/DependsOn = W1-D05/' \
  "${dependency_cycle_dir}/W1-D00-design-governance.md"
rm "${dependency_cycle_dir}/W1-D00-design-governance.md.bak"
expect_failure "${dependency_cycle_dir}" "dependency cycle detected"

active_mismatch_dir="${test_tmp_root}/active-mismatch"
cp -R "${ready_baseline_dir}" "${active_mismatch_dir}"
sed -i.bak \
  's/^ActiveTaskCard = W1-D01$/ActiveTaskCard = W1-D02/' \
  "${active_mismatch_dir}/README.md"
rm "${active_mismatch_dir}/README.md.bak"
expect_failure "${active_mismatch_dir}" "ActiveTaskCard W1-D02 is not READY"

gate_mismatch_dir="${test_tmp_root}/gate-mismatch"
cp -R "${ready_baseline_dir}" "${gate_mismatch_dir}"
sed -i.bak \
  's/^Gate = W1-DG3 ReparseAndReferenceCompatibility$/Gate = W1-DG9 Invalid/' \
  "${gate_mismatch_dir}/W1-D03-reparse-reference-contract.md"
rm "${gate_mismatch_dir}/W1-D03-reparse-reference-contract.md.bak"
expect_failure "${gate_mismatch_dir}" "Gate mismatch for W1-D03"

forbidden_write_dir="${test_tmp_root}/forbidden-write"
cp -R "${ready_baseline_dir}" "${forbidden_write_dir}"
sed -i.bak \
  '/^## 4[.] 执行步骤$/i\
- Modify: `server/src/forbidden.java`\
' \
  "${forbidden_write_dir}/W1-D01-source-document-contract.md"
rm "${forbidden_write_dir}/W1-D01-source-document-contract.md.bak"
expect_failure \
  "${forbidden_write_dir}" \
  "design card write set contains forbidden path: server/src"

implementation_card_dir="${test_tmp_root}/implementation-card"
cp -R "${ready_baseline_dir}" "${implementation_card_dir}"
cp \
  "${implementation_card_dir}/W1-D05-fixed-design-review.md" \
  "${implementation_card_dir}/W1-I01-forbidden.md"
expect_failure \
  "${implementation_card_dir}" \
  "implementation card is forbidden before explicit post-design user approval"

undeclared_card_dir="${test_tmp_root}/undeclared-card"
cp -R "${ready_baseline_dir}" "${undeclared_card_dir}"
cp \
  "${undeclared_card_dir}/W1-D05-fixed-design-review.md" \
  "${undeclared_card_dir}/W1-D99-undeclared.md"
sed -i.bak \
  's/^TaskCardID = W1-D05$/TaskCardID = W1-D99/' \
  "${undeclared_card_dir}/W1-D99-undeclared.md"
rm "${undeclared_card_dir}/W1-D99-undeclared.md.bak"
expect_failure \
  "${undeclared_card_dir}" \
  "undeclared design task card: W1-D99-undeclared.md"

complete_dir="${test_tmp_root}/complete"
cp -R "${ready_baseline_dir}" "${complete_dir}"
for card_file in "${complete_dir}"/W1-D*.md; do
  sed -i.bak \
    -E 's/^Status = (DONE|READY|QUEUED|BLOCKED_BY_DEPENDENCY|BLOCKED_BY_DOCUMENTATION_GAP)$/Status = DONE/' \
    "${card_file}"
  rm "${card_file}.bak"
done
sed -i.bak \
  -e 's/^ActiveTaskCard = .*$/ActiveTaskCard = NONE/' \
  -e 's/^TaskCardSetStatus = .*$/TaskCardSetStatus = COMPLETE/' \
  "${complete_dir}/README.md"
rm "${complete_dir}/README.md.bak"
expect_success "${complete_dir}"

complete_with_implementation_dir="${test_tmp_root}/complete-with-implementation"
cp -R "${complete_dir}" "${complete_with_implementation_dir}"
cp \
  "${complete_with_implementation_dir}/W1-D05-fixed-design-review.md" \
  "${complete_with_implementation_dir}/W1-I01-forbidden.md"
expect_failure \
  "${complete_with_implementation_dir}" \
  "implementation card is forbidden before explicit post-design user approval"

premature_implementation_slicing_dir="${test_tmp_root}/premature-implementation-slicing"
cp -R "${ready_baseline_dir}" "${premature_implementation_slicing_dir}"
sed -i.bak \
  's/^ImplementationSlicing = AFTER_EXPLICIT_USER_APPROVAL$/ImplementationSlicing = BEFORE_USER_APPROVAL/' \
  "${premature_implementation_slicing_dir}/W1-D05-fixed-design-review.md"
rm "${premature_implementation_slicing_dir}/W1-D05-fixed-design-review.md.bak"
expect_failure \
  "${premature_implementation_slicing_dir}" \
  "W1-D05-fixed-design-review.md: ImplementationSlicing must be AFTER_EXPLICIT_USER_APPROVAL"

printf '%s\n' \
  "Wave1DesignTaskCardContractTests = PASS" \
  "NegativeCases = 12" \
  "CompleteTerminalCases = 1"
