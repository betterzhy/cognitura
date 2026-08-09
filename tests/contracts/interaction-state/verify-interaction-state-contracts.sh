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

for required_identity in \
  'PrimaryPurpose = PERSONAL_COGNITIVE_STRUCTURE_BUILDING' \
  'DesignPurpose =' \
  'V1Architecture = MODULAR_MONOLITH' \
  'HistoricalHierarchyCompositeAlias = DomainPanorama_Theme_Module_Element'; do
  [[ "$(grep -Fxc "${required_identity}" "${document}" || true)" -eq 1 ]] ||
    fail "candidate identity is missing: ${required_identity}"
done
[[ "$(grep -Fxc 'DomainPanorama_Theme_Module_Element' "${document}" || true)" -eq 0 ]] ||
  fail "legacy hierarchy composite must only be a historical alias"
if grep -Eq '= PASS$|\| PASS \|' "${document}"; then
  fail "candidate must not declare contract PASS before applicable HF Gates"
fi
for forbidden_completion in \
  'ContractP0Remaining = 0' \
  'HighFidelityInputReady = YES' \
  'FormalDesignInputCompletion = CLOSED'; do
  [[ "$(grep -Fxc "${forbidden_completion}" "${document}" || true)" -eq 0 ]] ||
    fail "premature completion declaration remains: ${forbidden_completion}"
done
for required_deferred in \
  'ContractDefined = CANDIDATE_ONLY' \
  'ContractCompleteness = DEFERRED_TO_HF_D01_THROUGH_HF_D04' \
  'FormalDesignInputCompletion = DEFERRED_TO_HF_D04'; do
  [[ "$(grep -Fxc "${required_deferred}" "${document}" || true)" -eq 1 ]] ||
    fail "candidate deferred state is missing: ${required_deferred}"
done

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

for gap_id in DOC-GAP-HF-002 DOC-GAP-HF-003; do
  missing_gap="${test_tmp_root}/missing-${gap_id}.md"
  cp "${document}" "${missing_gap}"
  sed -i.bak "/^DocumentationGap = ${gap_id}$/d" "${missing_gap}"
  rm "${missing_gap}.bak"
  expect_failure "${missing_gap}" "${gap_id} must appear exactly once"
done

for gap_id in DOC-GAP-HF-001 DOC-GAP-HF-002 DOC-GAP-HF-003; do
  duplicate_gap="${test_tmp_root}/duplicate-${gap_id}.md"
  cp "${document}" "${duplicate_gap}"
  sed -i.bak "/^DocumentationGap = ${gap_id}$/a\\
DocumentationGap = ${gap_id}" "${duplicate_gap}"
  rm "${duplicate_gap}.bak"
  expect_failure "${duplicate_gap}" "${gap_id} must appear exactly once"
done

duplicate_business_boundary="${test_tmp_root}/duplicate-BusinessImplementation.md"
cp "${document}" "${duplicate_business_boundary}"
sed -i.bak '/^BusinessImplementation = NOT_AUTHORIZED$/a\
BusinessImplementation = NOT_AUTHORIZED' "${duplicate_business_boundary}"
rm "${duplicate_business_boundary}.bak"
expect_failure "${duplicate_business_boundary}" \
  "BusinessImplementation must be exactly NOT_AUTHORIZED"

for boundary in FormalDatabaseWrite RemotePush; do
  authorized_boundary="${test_tmp_root}/authorized-${boundary}.md"
  cp "${document}" "${authorized_boundary}"
  sed -i.bak "s/^${boundary} = NOT_AUTHORIZED$/${boundary} = AUTHORIZED/" \
    "${authorized_boundary}"
  rm "${authorized_boundary}.bak"
  expect_failure "${authorized_boundary}" "${boundary} must be exactly NOT_AUTHORIZED"
done

wrong_primary_purpose="${test_tmp_root}/wrong-primary-purpose.md"
cp "${document}" "${wrong_primary_purpose}"
sed -i.bak \
  's/^PrimaryPurpose = PERSONAL_COGNITIVE_STRUCTURE_BUILDING$/PrimaryPurpose = HIGH_FIDELITY_DESIGN/' \
  "${wrong_primary_purpose}"
rm "${wrong_primary_purpose}.bak"
expect_failure "${wrong_primary_purpose}" \
  "PrimaryPurpose must be PERSONAL_COGNITIVE_STRUCTURE_BUILDING"

missing_design_purpose="${test_tmp_root}/missing-design-purpose.md"
cp "${document}" "${missing_design_purpose}"
sed -i.bak '/^DesignPurpose =$/d' "${missing_design_purpose}"
rm "${missing_design_purpose}.bak"
expect_failure "${missing_design_purpose}" "DesignPurpose must be declared exactly once"

wrong_architecture="${test_tmp_root}/wrong-architecture.md"
cp "${document}" "${wrong_architecture}"
sed -i.bak \
  's/^V1Architecture = MODULAR_MONOLITH$/V1Architecture = MICROSERVICES/' \
  "${wrong_architecture}"
rm "${wrong_architecture}.bak"
expect_failure "${wrong_architecture}" "V1Architecture must be MODULAR_MONOLITH"

formal_legacy_hierarchy="${test_tmp_root}/formal-legacy-hierarchy.md"
cp "${document}" "${formal_legacy_hierarchy}"
sed -i.bak \
  's/^HistoricalHierarchyCompositeAlias = DomainPanorama_Theme_Module_Element$/DomainPanorama_Theme_Module_Element/' \
  "${formal_legacy_hierarchy}"
rm "${formal_legacy_hierarchy}.bak"
expect_failure "${formal_legacy_hierarchy}" \
  "legacy hierarchy composite must only be a historical alias"

premature_contract_pass="${test_tmp_root}/premature-contract-pass.md"
cp "${document}" "${premature_contract_pass}"
sed -i.bak \
  's/^ContractDefined = CANDIDATE_ONLY$/ContractDefined = PASS/' \
  "${premature_contract_pass}"
rm "${premature_contract_pass}.bak"
expect_failure "${premature_contract_pass}" \
  "candidate must not declare contract PASS before applicable HF Gates"

premature_p0_close="${test_tmp_root}/premature-p0-close.md"
cp "${document}" "${premature_p0_close}"
sed -i.bak \
  's/^ContractP0Remaining = DEFERRED_TO_HF_D01_THROUGH_HF_D04$/ContractP0Remaining = 0/' \
  "${premature_p0_close}"
rm "${premature_p0_close}.bak"
expect_failure "${premature_p0_close}" \
  "ContractP0Remaining must remain deferred through HF-D04"

premature_input_ready="${test_tmp_root}/premature-input-ready.md"
cp "${document}" "${premature_input_ready}"
sed -i.bak \
  's/^HighFidelityInputReady = CANDIDATE_ONLY$/HighFidelityInputReady = YES/' \
  "${premature_input_ready}"
rm "${premature_input_ready}.bak"
expect_failure "${premature_input_ready}" \
  "HighFidelityInputReady must remain CANDIDATE_ONLY"

premature_design_completion="${test_tmp_root}/premature-design-completion.md"
cp "${document}" "${premature_design_completion}"
sed -i.bak \
  's/^FormalDesignInputCompletion = DEFERRED_TO_HF_D04$/FormalDesignInputCompletion = CLOSED/' \
  "${premature_design_completion}"
rm "${premature_design_completion}.bak"
expect_failure "${premature_design_completion}" \
  "FormalDesignInputCompletion must remain deferred to HF-D04"

premature_specialty_baseline="${test_tmp_root}/premature-specialty-baseline.md"
cp "${document}" "${premature_specialty_baseline}"
sed -i.bak \
  's/CANDIDATE_AWAITING_REPOSITORY_GATE/FORMAL_SPECIALTY_BASELINE/' \
  "${premature_specialty_baseline}"
rm "${premature_specialty_baseline}.bak"
expect_failure "${premature_specialty_baseline}" \
  "candidate status must remain CANDIDATE_AWAITING_REPOSITORY_GATE"

printf '%s\n' \
  "InteractionStateContractTests = PASS" \
  "NegativeCases = 20"
