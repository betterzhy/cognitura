#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-interaction-state-contracts"
document="${repo_root}/Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-interaction-state.XXXXXX")"

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
  if output="$("${verifier}" --document "${fixture}" 2>&1)"; then
    fail "invalid fixture unexpectedly passed: ${fixture}"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected error '${expected_message}', got: ${output}"
}

[[ -x "${verifier}" ]] || fail "interaction-state verifier is missing or not executable"
[[ -f "${document}" ]] || fail "interaction-state specialty candidate is missing"

canonical_output="$("${verifier}" --document "${document}")" ||
  fail "canonical interaction-state candidate was rejected"
for expected_line in \
  "InteractionStateContractValidation = PASS" \
  "OriginalStateCodeCount = 46" \
  "ExceptionCodeCount = 20" \
  "RFAcceptanceCount = 20" \
  "ReverseMigrationCount = 30"; do
  [[ "${canonical_output}" == *"${expected_line}"* ]] ||
    fail "canonical output is missing: ${expected_line}"
done

wrong_hierarchy="${test_tmp_root}/wrong-hierarchy.md"
cp "${document}" "${wrong_hierarchy}"
sed -i.bak 's/^  KnowledgeLandscape$/  DomainPanorama/' "${wrong_hierarchy}"
rm "${wrong_hierarchy}.bak"
expect_failure "${wrong_hierarchy}" "CanonicalHierarchy must use Cognitura four-layer names"

missing_state="${test_tmp_root}/missing-state.md"
cp "${document}" "${missing_state}"
sed -i.bak '/^| `StateCode` | IDLE |$/d' "${missing_state}"
rm "${missing_state}.bak"
expect_failure "${missing_state}" "expected 46 unique original StateCode rows"

premature_formal="${test_tmp_root}/premature-formal.md"
cp "${document}" "${premature_formal}"
sed -i.bak 's/CANDIDATE_AWAITING_REPOSITORY_GATE/FORMAL_HIGH_FIDELITY_INPUT_BASELINE/' \
  "${premature_formal}"
rm "${premature_formal}.bak"
expect_failure "${premature_formal}" "candidate status must remain CANDIDATE_AWAITING_REPOSITORY_GATE"

printf '%s\n' \
  "InteractionStateContractTests = PASS" \
  "NegativeCases = 3"
