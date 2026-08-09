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

hfd02_stage_fail() {
  printf 'HFD02StageSeparation = FAIL\n%s\n' "$1" >&2
  return 1
}

validate_hfd02_stage_separation() {
  local fixture="$1"

  [[ "$(grep -Fxc '  HF_D03_HIGH_FIDELITY_EVIDENCE_CONTRACT' "${fixture}" || true)" -eq 2 ]] ||
    { hfd02_stage_fail "HFD03_STAGE_ENTRY_MISMATCH"; return 1; }
  grep -Fqx \
    'HFD02Scope = ORTHOGONAL_STATE_CLASSIFICATION_RECOVERY_AND_PERSISTENCE_ONLY' \
    "${fixture}" || { hfd02_stage_fail "HFD02_STAGE_SCOPE_MISMATCH"; return 1; }
  grep -Fqx \
    'RealHighFidelityPageDesign = DEFERRED_UNTIL_HF_D04_PASS_AND_SEPARATE_HV_GATE' \
    "${fixture}" || { hfd02_stage_fail "REAL_HIGH_FIDELITY_PAGE_PREMATURE_IN_HFD02"; return 1; }
  grep -Fqx \
    'HighFidelityVisualAndUsabilityValidation = DEFERRED_UNTIL_SEPARATE_HV_GATE' \
    "${fixture}" || { hfd02_stage_fail "REAL_HIGH_FIDELITY_PAGE_PREMATURE_IN_HFD02"; return 1; }
}

run_validation() {
  local fixture="$1"
  "${verifier}" --document "${fixture}" || return 1
  validate_hfd02_stage_separation "${fixture}"
}

expect_failure() {
  local fixture="$1"
  local expected_message="$2"
  local output
  if output="$(run_validation "${fixture}" 2>&1)"; then
    fail "invalid fixture unexpectedly passed: ${fixture}"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected error '${expected_message}', got: ${output}"
}

expect_success() {
  local fixture="$1"
  local output
  output="$(run_validation "${fixture}")" ||
    fail "valid stage-aware fixture was rejected: ${fixture}"
  [[ "${output}" == *"InteractionStateContractValidation = PASS"* ]] ||
    fail "valid stage-aware fixture output is missing PASS: ${fixture}"
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
for forbidden_completion in \
  'ContractP0Remaining = 0' \
  'HighFidelityInputReady = YES' \
  'FormalDesignInputCompletion = CLOSED'; do
  [[ "$(grep -Fxc "${forbidden_completion}" "${document}" || true)" -eq 0 ]] ||
    fail "premature completion declaration remains: ${forbidden_completion}"
done
for required_deferred in \
  'ContractDefined = CANDIDATE_ONLY' \
  'FormalDesignInputCompletion = DEFERRED_TO_HF_D04'; do
  [[ "$(grep -Fxc "${required_deferred}" "${document}" || true)" -eq 1 ]] ||
    fail "candidate deferred state is missing: ${required_deferred}"
done
contract_completeness="$(sed -n 's/^ContractCompleteness = //p' "${document}")"
case "${contract_completeness}" in
  DEFERRED_TO_HF_D01_THROUGH_HF_D04|DEFERRED_TO_HF_D02_THROUGH_HF_D04|DEFERRED_TO_HF_D03_THROUGH_HF_D04|DEFERRED_TO_HF_D04) ;;
  *) fail "ContractCompleteness must remain stage-aware and deferred" ;;
esac
for forbidden_closure in \
  'CLOSED_BY_THIS_DOCUMENT' \
  'CONTRACT_CLOSED' \
  'CLOSED_AT_CONTRACT_LEVEL' \
  'ReadingFirstRiskClosedAtContractLevel' \
  'StateInputGapsClosed' \
  'COMPLETED_AS_CURRENT_INPUT' \
  'PASS_WITH_READING_FIRST_PRESENTATION_PATCH_REQUIRED' \
  'SecondRoundLowFidelityDirectionAccepted = YES' \
  '| CLOSED |'; do
  if grep -Fq "${forbidden_closure}" "${document}"; then
    fail "candidate must not claim closure before the applicable HF Gate: ${forbidden_closure}"
  fi
done
for required_candidate_disposition in \
  'RemainingInteractionStateP0 = HF_DG2_ORTHOGONAL_STATE_AND_RECOVERY_PASS' \
  'SecondRoundLowFidelityPrototype = HISTORICAL_INPUT_RECORDED' \
  'SecondRoundLowFidelityAssessment = HISTORICAL_DIRECTION_RECORDED_READING_FIRST_PATCH_REQUIRED' \
  'SecondRoundLowFidelityDirectionRecord = HISTORICAL_ACCEPTANCE_RECORDED' \
  'ReadingFirstRiskDisposition = DEFERRED_TO_APPLICABLE_HF_GATE' \
  'StateInputGapDisposition = HF_DG2_ORTHOGONAL_STATE_AND_RECOVERY_PASS'; do
  [[ "$(grep -Fxc "${required_candidate_disposition}" "${document}" || true)" -eq 1 ]] ||
    fail "candidate disposition is missing: ${required_candidate_disposition}"
done
[[ "$(grep -c '| DEFERRED_TO_APPLICABLE_HF_GATE |$' "${document}" || true)" -eq 12 ]] ||
  fail "second-round trace rows must remain deferred to applicable HF Gates"

canonical_output="$(run_validation "${document}")" ||
  fail "canonical interaction-state candidate was rejected"
for expected_line in \
  "InteractionStateContractValidation = PASS" \
  "OriginalStateCodeCount = 46" \
  "ClassifiedOriginalStateCodeCount = 46" \
  "OrthogonalAxisCount = 6" \
  "PersistenceLedgerLevelCount = 5" \
  "PageStateMappingCount = 12" \
  "ExceptionCodeCount = 20" \
  "RFAcceptanceCount = 20" \
  "ReverseMigrationCount = 30"; do
  [[ "${canonical_output}" == *"${expected_line}"* ]] ||
    fail "canonical output is missing: ${expected_line}"
done

legal_hfdg1_pass="${test_tmp_root}/legal-hfdg1-pass.md"
cp "${document}" "${legal_hfdg1_pass}"
sed -i.bak \
  's/^ReadingFirstPresentationContract = CANDIDATE_AWAITING_APPLICABLE_HF_GATE$/ReadingFirstPresentationContract = PASS/' \
  "${legal_hfdg1_pass}"
rm "${legal_hfdg1_pass}.bak"
sed -i.bak \
  's/^ContractP0Remaining = DEFERRED_TO_HF_D01_THROUGH_HF_D04$/ContractP0Remaining = DEFERRED_TO_HF_D02_THROUGH_HF_D04/' \
  "${legal_hfdg1_pass}"
rm "${legal_hfdg1_pass}.bak"
sed -i.bak \
  's/^ContractCompleteness = DEFERRED_TO_HF_D01_THROUGH_HF_D04$/ContractCompleteness = DEFERRED_TO_HF_D02_THROUGH_HF_D04/' \
  "${legal_hfdg1_pass}"
rm "${legal_hfdg1_pass}.bak"
expect_success "${legal_hfdg1_pass}"

legal_rf_contract_pass="${test_tmp_root}/legal-rf-contract-pass.md"
cp "${document}" "${legal_rf_contract_pass}"
sed -i.bak \
  '/^| RF-AC-01 /s/| CONTRACT | DEFERRED | NOT_RUN |$/| CONTRACT | PASS | NOT_RUN |/' \
  "${legal_rf_contract_pass}"
rm "${legal_rf_contract_pass}.bak"
expect_success "${legal_rf_contract_pass}"

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

duplicate_owner="${test_tmp_root}/duplicate-owner.md"
cp "${document}" "${duplicate_owner}"
sed -i.bak '/^| CLOSE_AUXILIARY_PANEL | EVENT |/p' "${duplicate_owner}"
rm "${duplicate_owner}.bak"
expect_failure "${duplicate_owner}" "expected 46 unique classification rows"

missing_classification="${test_tmp_root}/missing-classification.md"
cp "${document}" "${missing_classification}"
sed -i.bak '/^| IDLE | AXIS_VALUE |/d' "${missing_classification}"
rm "${missing_classification}.bak"
expect_failure "${missing_classification}" "expected 46 unique classification rows"

unknown_classification="${test_tmp_root}/unknown-classification.md"
cp "${document}" "${unknown_classification}"
sed -i.bak 's/^| IDLE | AXIS_VALUE |/| UNKNOWN_STATE | AXIS_VALUE |/' "${unknown_classification}"
rm "${unknown_classification}.bak"
expect_failure "${unknown_classification}" "classification contains unknown OriginalStateCode"

event_persisted="${test_tmp_root}/event-persisted.md"
cp "${document}" "${event_persisted}"
sed -i.bak \
  's/^| CLOSE_AUXILIARY_PANEL | EVENT | NavigationEventFlow | EPHEMERAL_UI | NOT_PERSISTED | NO_CANONICAL_WRITE |$/| CLOSE_AUXILIARY_PANEL | EVENT | NavigationEventFlow | CANONICAL_SERVER_STATE | DERIVED_FROM_CANONICAL_RESULT | CANONICAL_WRITE_RESULT |/' \
  "${event_persisted}"
rm "${event_persisted}.bak"
expect_failure "${event_persisted}" "event must not be persisted as state"

preview_in_url="${test_tmp_root}/preview-in-url.md"
cp "${document}" "${preview_in_url}"
sed -i.bak \
  's/^| PREVIEW | TRANSIENT_UI | PreviewFlow | EPHEMERAL_UI | NOT_PERSISTED | NO_CANONICAL_WRITE |$/| PREVIEW | TRANSIENT_UI | PreviewFlow | URL | URL_AND_HISTORY | NO_CANONICAL_WRITE |/' \
  "${preview_in_url}"
rm "${preview_in_url}.bak"
expect_failure "${preview_in_url}" "PREVIEW must not enter URL or History"

generating_collision="${test_tmp_root}/generating-collision.md"
cp "${document}" "${generating_collision}"
sed -i.bak 's/PROJECTION_GENERATING/GENERATING/g' "${generating_collision}"
rm "${generating_collision}.bak"
expect_failure "${generating_collision}" "historical GENERATING must map to PROJECTION_GENERATING"

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
  "ContractDefined must remain CANDIDATE_ONLY"

premature_p0_close="${test_tmp_root}/premature-p0-close.md"
cp "${document}" "${premature_p0_close}"
sed -i.bak -E \
  's/^ContractP0Remaining = DEFERRED_TO_HF_D0(1|2|3)_THROUGH_HF_D04$/ContractP0Remaining = 0/' \
  "${premature_p0_close}"
rm "${premature_p0_close}.bak"
expect_failure "${premature_p0_close}" \
  "ContractP0Remaining must remain deferred to an applicable HF Gate"

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

closed_interaction_p0="${test_tmp_root}/closed-interaction-p0.md"
cp "${document}" "${closed_interaction_p0}"
sed -i.bak \
  's/^RemainingInteractionStateP0 = HF_DG2_ORTHOGONAL_STATE_AND_RECOVERY_PASS$/RemainingInteractionStateP0 = CLOSED_BY_THIS_DOCUMENT/' \
  "${closed_interaction_p0}"
rm "${closed_interaction_p0}.bak"
expect_failure "${closed_interaction_p0}" \
  "candidate must not claim closure before the applicable HF Gate"

closed_trace_rows="${test_tmp_root}/closed-trace-rows.md"
cp "${document}" "${closed_trace_rows}"
sed -i.bak \
  's/| DEFERRED_TO_APPLICABLE_HF_GATE |$/| CONTRACT_CLOSED |/' \
  "${closed_trace_rows}"
rm "${closed_trace_rows}.bak"
expect_failure "${closed_trace_rows}" \
  "candidate must not claim closure before the applicable HF Gate"

completed_historical_input="${test_tmp_root}/completed-historical-input.md"
cp "${document}" "${completed_historical_input}"
sed -i.bak \
  's/^SecondRoundLowFidelityPrototype = HISTORICAL_INPUT_RECORDED$/SecondRoundLowFidelityPrototype = COMPLETED_AS_CURRENT_INPUT/' \
  "${completed_historical_input}"
rm "${completed_historical_input}.bak"
expect_failure "${completed_historical_input}" \
  "candidate must not claim closure before the applicable HF Gate"

complete_design_input="${test_tmp_root}/complete-design-input.md"
cp "${document}" "${complete_design_input}"
sed -i.bak \
  's/^FormalDesignInputCompletion = DEFERRED_TO_HF_D04$/FormalDesignInputCompletion = COMPLETE/' \
  "${complete_design_input}"
rm "${complete_design_input}.bak"
expect_failure "${complete_design_input}" \
  "FormalDesignInputCompletion must remain deferred to HF-D04"

premature_visual_pass="${test_tmp_root}/premature-visual-pass.md"
cp "${document}" "${premature_visual_pass}"
sed -i.bak \
  's/^HighFidelityVisualDesign = NOT_RUN$/HighFidelityVisualDesign = PASS/' \
  "${premature_visual_pass}"
rm "${premature_visual_pass}.bak"
expect_failure "${premature_visual_pass}" \
  "HighFidelityVisualDesign must remain NOT_RUN"

premature_usability_pass="${test_tmp_root}/premature-usability-pass.md"
cp "${document}" "${premature_usability_pass}"
sed -i.bak \
  's/^HighFidelityUsabilityValidation = NOT_RUN$/HighFidelityUsabilityValidation = PASS/' \
  "${premature_usability_pass}"
rm "${premature_usability_pass}.bak"
expect_failure "${premature_usability_pass}" \
  "HighFidelityUsabilityValidation must remain NOT_RUN"

premature_implementation_pass="${test_tmp_root}/premature-implementation-pass.md"
cp "${document}" "${premature_implementation_pass}"
sed -i.bak \
  's/^ImplementationValidation = NOT_RUN$/ImplementationValidation = PASS/' \
  "${premature_implementation_pass}"
rm "${premature_implementation_pass}.bak"
expect_failure "${premature_implementation_pass}" \
  "ImplementationValidation must remain NOT_RUN"

premature_rf_visual_pass="${test_tmp_root}/premature-rf-visual-pass.md"
cp "${document}" "${premature_rf_visual_pass}"
sed -i.bak \
  '/^| RF-AC-01 /s/| CONTRACT | DEFERRED | NOT_RUN |$/| CONTRACT | DEFERRED | PASS |/' \
  "${premature_rf_visual_pass}"
rm "${premature_rf_visual_pass}.bak"
expect_failure "${premature_rf_visual_pass}" \
  "high-fidelity RF-AC results must remain NOT_RUN"

for later_stage in HIGH_FIDELITY_VISUAL HIGH_FIDELITY_USABILITY IMPLEMENTATION; do
  premature_stage_pass="${test_tmp_root}/premature-${later_stage}-stage-pass.md"
  cp "${document}" "${premature_stage_pass}"
  sed -i.bak \
    "/^| \`${later_stage}\` /s/| NOT_RUN |$/| PASS |/" \
    "${premature_stage_pass}"
  rm "${premature_stage_pass}.bak"
  expect_failure "${premature_stage_pass}" \
    "${later_stage} stage must remain NOT_RUN"
done

premature_real_high_fidelity_page="${test_tmp_root}/premature-real-high-fidelity-page.md"
cp "${document}" "${premature_real_high_fidelity_page}"
sed -i.bak \
  's/^RealHighFidelityPageDesign = DEFERRED_UNTIL_HF_D04_PASS_AND_SEPARATE_HV_GATE$/RealHighFidelityPageDesign = CONCURRENT_WITH_HF_D02/' \
  "${premature_real_high_fidelity_page}"
rm "${premature_real_high_fidelity_page}.bak"
expect_failure "${premature_real_high_fidelity_page}" \
  "REAL_HIGH_FIDELITY_PAGE_PREMATURE_IN_HFD02"

printf '%s\n' \
  "InteractionStateContractTests = PASS" \
  "StageAwarePositiveCases = 2" \
  "NegativeCases = 38"
