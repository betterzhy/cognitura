#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-high-fidelity-design"
cards_dir="${repo_root}/docs/task-cards/high-fidelity-design"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-hf-design-cards.XXXXXX")"

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
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected error '${expected_message}', got: ${output}"
}

[[ -x "${verifier}" ]] || fail "high-fidelity design verifier is missing or not executable"
[[ -d "${cards_dir}" ]] || fail "high-fidelity design card directory is missing"

canonical_output="$("${verifier}" --cards-dir "${cards_dir}")" ||
  fail "canonical high-fidelity design cards were rejected"
canonical_active="$(sed -n 's/^ActiveTaskCard = //p' "${cards_dir}/README.md")"
for expected_line in \
  "HighFidelityDesignTaskCardValidation = PASS" \
  "TaskCardCount = 5" \
  "TaskCardSetStatus = READY_FOR_EXECUTION" \
  "ActiveTaskCard = ${canonical_active}" \
  "BusinessImplementation = NOT_AUTHORIZED" \
  "W1-I00Release = FORBIDDEN"; do
  [[ "${canonical_output}" == *"${expected_line}"* ]] ||
    fail "canonical output is missing: ${expected_line}"
done

baseline_dir="${test_tmp_root}/baseline"
cp -R "${cards_dir}" "${baseline_dir}"

initial_d00_dir="${test_tmp_root}/initial-d00"
cp -R "${baseline_dir}" "${initial_d00_dir}"
for card_file in "${initial_d00_dir}"/HF-D*.md; do
  task_id="$(sed -n 's/^TaskCardID = //p' "${card_file}")"
  if [[ "${task_id}" == "HF-D00" ]]; then
    initial_status="READY"
  else
    initial_status="BLOCKED_BY_DEPENDENCY"
  fi
  sed -i.bak -E \
    "s/^Status = (DONE|READY|BLOCKED_BY_DEPENDENCY)$/Status = ${initial_status}/" \
    "${card_file}"
  rm "${card_file}.bak"
done
sed -i.bak 's/^ActiveTaskCard = .*$/ActiveTaskCard = HF-D00/' "${initial_d00_dir}/README.md"
rm "${initial_d00_dir}/README.md.bak"
initial_output="$("${verifier}" --cards-dir "${initial_d00_dir}")" ||
  fail "HF-D00 initial governance snapshot was rejected"
[[ "${initial_output}" == *"ActiveTaskCard = HF-D00"* ]] ||
  fail "initial snapshot did not retain HF-D00 as the only READY card"

missing_owner_dir="${test_tmp_root}/missing-owner"
cp -R "${baseline_dir}" "${missing_owner_dir}"
sed -i.bak '/^DesignOwner = /d' \
  "${missing_owner_dir}/HF-D02-interaction-state-model.md"
rm "${missing_owner_dir}/HF-D02-interaction-state-model.md.bak"
expect_failure "${missing_owner_dir}" "missing required field: DesignOwner"

second_ready_dir="${test_tmp_root}/second-ready"
cp -R "${baseline_dir}" "${second_ready_dir}"
sed -i.bak 's/^Status = BLOCKED_BY_DEPENDENCY$/Status = READY/' \
  "${second_ready_dir}/HF-D02-interaction-state-model.md"
rm "${second_ready_dir}/HF-D02-interaction-state-model.md.bak"
expect_failure "${second_ready_dir}" "expected exactly one READY task card"

forbidden_write_dir="${test_tmp_root}/forbidden-write"
cp -R "${baseline_dir}" "${forbidden_write_dir}"
sed -i.bak '/^## 4[.] 禁止写集$/i\
- Modify: `server/src/forbidden.java`\
' "${forbidden_write_dir}/HF-D01-reading-presentation-contract.md"
rm "${forbidden_write_dir}/HF-D01-reading-presentation-contract.md.bak"
expect_failure "${forbidden_write_dir}" "write set contains forbidden path: server/"

w1_release_dir="${test_tmp_root}/w1-release"
cp -R "${baseline_dir}" "${w1_release_dir}"
sed -i.bak 's/^W1-I00Release = FORBIDDEN$/W1-I00Release = READY/' \
  "${w1_release_dir}/README.md"
rm "${w1_release_dir}/README.md.bak"
expect_failure "${w1_release_dir}" "W1-I00Release must be FORBIDDEN"

printf '%s\n' \
  "HighFidelityDesignTaskCardContractTests = PASS" \
  "NegativeCases = 4"
