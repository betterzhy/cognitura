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

[[ -x "${verifier}" ]] || fail "high-fidelity coverage verifier is missing or not executable"
[[ -f "${coverage}" ]] || fail "high-fidelity contract coverage is missing"

canonical_output="$("${verifier}" --coverage "${coverage}" --document "${document}")" ||
  fail "canonical high-fidelity coverage was rejected"
for expected_line in \
  "HighFidelityContractCoverageValidation = PASS" \
  "CoverageRowCount = 4" \
  "GateClosure = DEFERRED_UNTIL_HF_D04"; do
  [[ "${canonical_output}" == *"${expected_line}"* ]] ||
    fail "canonical output is missing: ${expected_line}"
done

missing_coverage="${test_tmp_root}/missing-coverage.md"
cp "${coverage}" "${missing_coverage}"
sed -i.bak '/^| STATE-CODES |/d' "${missing_coverage}"
rm "${missing_coverage}.bak"
expect_failure "${missing_coverage}" "missing coverage ID: STATE-CODES"

premature_gate="${test_tmp_root}/premature-gate.md"
cp "${coverage}" "${premature_gate}"
sed -i.bak 's/^GateClosure = DEFERRED_UNTIL_HF_D04$/GateClosure = PASS/' "${premature_gate}"
rm "${premature_gate}.bak"
expect_failure "${premature_gate}" "GateClosure must remain DEFERRED_UNTIL_HF_D04"

printf '%s\n' \
  "HighFidelityContractCoverageTests = PASS" \
  "NegativeCases = 2"
