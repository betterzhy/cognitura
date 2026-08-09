#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-high-fidelity-contract-coverage"
coverage="${repo_root}/docs/engineering/cognitura-high-fidelity-contract-coverage.md"
document="${repo_root}/Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-hf-coverage.XXXXXX")"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

expect_failure() {
  local fixture="$1"
  local expected_message="$2"
  local output
  if output="$("${verifier}" --coverage "${fixture}" --document "${document}" 2>&1)"; then
    fail "invalid fixture unexpectedly passed: ${fixture}"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected error '${expected_message}', got: ${output}"
}

expect_document_failure() {
  local fixture="$1"
  local expected_message="$2"
  local output
  if output="$("${verifier}" --coverage "${coverage}" --document "${fixture}" 2>&1)"; then
    fail "invalid candidate document unexpectedly passed: ${fixture}"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected error '${expected_message}', got: ${output}"
}

[[ -x "${verifier}" ]] || fail "high-fidelity coverage verifier is missing or not executable"
[[ -f "${coverage}" ]] || fail "high-fidelity contract coverage is missing"

canonical_output="$("${verifier}" --coverage "${coverage}" --document "${document}")" ||
  fail "canonical high-fidelity coverage was rejected"
for expected_line in \
  "HighFidelityContractCoverageValidation = PASS" \
  "CoverageRowCount = 4" \
  "CoverageStatus = REVIEWED_CLOSED" \
  "GateClosure = HF-DG4 PASS" \
  "ReviewedPreparationSHA = 463fd4829e7c4bb8da071253e8ae9b15cee2a0cf"; do
  [[ "${canonical_output}" == *"${expected_line}"* ]] ||
    fail "canonical output is missing: ${expected_line}"
done

missing_coverage="${test_tmp_root}/missing-coverage.md"
cp "${coverage}" "${missing_coverage}"
sed -i.bak '/^| STATE-CODES |/d' "${missing_coverage}"
rm "${missing_coverage}.bak"
expect_failure "${missing_coverage}" "missing coverage ID: STATE-CODES"

stale_gate="${test_tmp_root}/stale-gate.md"
cp "${coverage}" "${stale_gate}"
sed -i.bak 's/^GateClosure = HF-DG4 PASS$/GateClosure = DEFERRED_UNTIL_HF_D04/' "${stale_gate}"
rm "${stale_gate}.bak"
expect_failure "${stale_gate}" "GateClosure must be HF-DG4 PASS"

stale_status="${test_tmp_root}/stale-status.md"
cp "${coverage}" "${stale_status}"
sed -i.bak 's/^CoverageStatus = REVIEWED_CLOSED$/CoverageStatus = CANDIDATE_TRACE_REGISTERED/' "${stale_status}"
rm "${stale_status}.bak"
expect_failure "${stale_status}" "CoverageStatus must be REVIEWED_CLOSED"

missing_reviewed_sha="${test_tmp_root}/missing-reviewed-sha.md"
cp "${coverage}" "${missing_reviewed_sha}"
sed -i.bak '/^ReviewedPreparationSHA = /d' "${missing_reviewed_sha}"
rm "${missing_reviewed_sha}.bak"
expect_failure "${missing_reviewed_sha}" "ReviewedPreparationSHA must match promoted document"

mismatched_reviewed_sha="${test_tmp_root}/mismatched-reviewed-sha.md"
cp "${coverage}" "${mismatched_reviewed_sha}"
sed -i.bak -E 's/^ReviewedPreparationSHA = [0-9a-f]{40}$/ReviewedPreparationSHA = 0000000000000000000000000000000000000000/' \
  "${mismatched_reviewed_sha}"
rm "${mismatched_reviewed_sha}.bak"
expect_failure "${mismatched_reviewed_sha}" "ReviewedPreparationSHA must match promoted document"

empty_document="${test_tmp_root}/empty-candidate.md"
: >"${empty_document}"
expect_document_failure "${empty_document}" "expected 46 unique original StateCode rows"

printf '%s\n' \
  "HighFidelityContractCoverageTests = PASS" \
  "NegativeCases = 6"
