#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-interaction-state-contracts"
document="${repo_root}/Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md"
plan="${repo_root}/docs/engineering/cognitura-high-fidelity-design-plan.md"
acceptance="${repo_root}/docs/engineering/cognitura-high-fidelity-design-acceptance.md"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-interaction-state.XXXXXX")"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

hfd03_stage_fail() {
  printf 'HFD03StageSeparation = FAIL\n%s\n' "$1" >&2
  return 1
}

validate_hfd03_stage_separation() {
  local fixture="$1"

  [[ "$(grep -Fxc '  HF_D04_FIXED_DESIGN_REVIEW' "${fixture}" || true)" -eq 2 ]] ||
    { hfd03_stage_fail "HFD04_STAGE_ENTRY_MISMATCH"; return 1; }
  grep -Fqx \
    'HFD03Scope = HIGH_FIDELITY_EVIDENCE_INPUT_CONTRACT_ONLY' \
    "${fixture}" || { hfd03_stage_fail "HFD03_STAGE_SCOPE_MISMATCH"; return 1; }
  grep -Fqx \
    'RealHighFidelityPageDesign = DEFERRED_UNTIL_HF_D04_PASS_AND_SEPARATE_HV_GATE' \
    "${fixture}" || { hfd03_stage_fail "REAL_HIGH_FIDELITY_PAGE_PREMATURE_IN_HFD03"; return 1; }
  grep -Fqx \
    'HighFidelityVisualAndUsabilityValidation = DEFERRED_UNTIL_SEPARATE_HV_GATE' \
    "${fixture}" || { hfd03_stage_fail "REAL_HIGH_FIDELITY_PAGE_PREMATURE_IN_HFD03"; return 1; }
}

run_validation() {
  local fixture="$1"
  local fixture_plan="${2:-${plan}}"
  local fixture_acceptance="${3:-${acceptance}}"
  "${verifier}" \
    --document "${fixture}" \
    --plan "${fixture_plan}" \
    --acceptance "${fixture_acceptance}" || return 1
  validate_hfd03_stage_separation "${fixture}"
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

expect_evidence_failure() {
  local fixture_document="$1"
  local fixture_plan="$2"
  local fixture_acceptance="$3"
  local expected_message="$4"
  local output
  if output="$(run_validation \
    "${fixture_document}" "${fixture_plan}" "${fixture_acceptance}" 2>&1)"; then
    fail "invalid evidence fixture unexpectedly passed: ${fixture_document}"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected evidence error '${expected_message}', got: ${output}"
}

make_evidence_fixture() {
  local fixture_root="$1"
  mkdir -p "${fixture_root}/docs/engineering"
  cp "${document}" "${fixture_root}/candidate.md"
  cp "${plan}" "${fixture_root}/docs/engineering/plan.md"
  cp "${acceptance}" "${fixture_root}/docs/engineering/acceptance.md"
}

[[ -x "${verifier}" ]] || fail "interaction-state verifier is missing or not executable"
[[ -f "${document}" ]] || fail "interaction-state specialty candidate is missing"
[[ -f "${plan}" ]] || fail "high-fidelity evidence plan is missing"
[[ -f "${acceptance}" ]] || fail "high-fidelity evidence acceptance is missing"

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
  "ReverseMigrationCount = 30" \
  "EvidenceClassCount = 8" \
  "RFAcceptanceEvidenceCount = 20" \
  "ExceptionAcceptanceEvidenceCount = 20" \
  "ReverseMigrationTraceCount = 30" \
  "CrossDomainScenarioCount = 2" \
  "VisualDesignTaskCount = 6" \
  "HighFidelityVisualDesign = NOT_RUN" \
  "HighFidelityUsabilityValidation = NOT_RUN"; do
  [[ "${canonical_output}" == *"${expected_line}"* ]] ||
    fail "canonical output is missing: ${expected_line}"
done

missing_evidence_class_root="${test_tmp_root}/missing-evidence-class"
make_evidence_fixture "${missing_evidence_class_root}"
sed -i.bak '/^EvidencePath = 08|StaticExport|/d' \
  "${missing_evidence_class_root}/docs/engineering/plan.md"
rm "${missing_evidence_class_root}/docs/engineering/plan.md.bak"
expect_evidence_failure \
  "${missing_evidence_class_root}/candidate.md" \
  "${missing_evidence_class_root}/docs/engineering/plan.md" \
  "${missing_evidence_class_root}/docs/engineering/acceptance.md" \
  "evidence path contract mismatch"

legacy_evidence_name_root="${test_tmp_root}/legacy-evidence-name"
make_evidence_fixture "${legacy_evidence_name_root}"
sed -i.bak \
  's/^EvidencePath = 06|KnowledgeLandscapeAndKnowledgeTheme|/EvidencePath = 06|DomainAndTheme|/' \
  "${legacy_evidence_name_root}/docs/engineering/plan.md"
rm "${legacy_evidence_name_root}/docs/engineering/plan.md.bak"
expect_evidence_failure \
  "${legacy_evidence_name_root}/candidate.md" \
  "${legacy_evidence_name_root}/docs/engineering/plan.md" \
  "${legacy_evidence_name_root}/docs/engineering/acceptance.md" \
  "evidence path contract mismatch"

missing_rf_acceptance_root="${test_tmp_root}/missing-rf-acceptance"
make_evidence_fixture "${missing_rf_acceptance_root}"
sed -i.bak '/^RFAcceptance = RF-AC-20|/d' \
  "${missing_rf_acceptance_root}/docs/engineering/acceptance.md"
rm "${missing_rf_acceptance_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${missing_rf_acceptance_root}/candidate.md" \
  "${missing_rf_acceptance_root}/docs/engineering/plan.md" \
  "${missing_rf_acceptance_root}/docs/engineering/acceptance.md" \
  "expected exact RF-AC-01..20 acceptance set"

wrong_rf_acceptance_root="${test_tmp_root}/wrong-rf-acceptance"
make_evidence_fixture "${wrong_rf_acceptance_root}"
sed -i.bak 's/^RFAcceptance = RF-AC-20|/RFAcceptance = RF-AC-21|/' \
  "${wrong_rf_acceptance_root}/docs/engineering/acceptance.md"
rm "${wrong_rf_acceptance_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${wrong_rf_acceptance_root}/candidate.md" \
  "${wrong_rf_acceptance_root}/docs/engineering/plan.md" \
  "${wrong_rf_acceptance_root}/docs/engineering/acceptance.md" \
  "expected exact RF-AC-01..20 acceptance set"

missing_exception_acceptance_root="${test_tmp_root}/missing-exception-acceptance"
make_evidence_fixture "${missing_exception_acceptance_root}"
sed -i.bak '/^ExceptionAcceptance = EX-WORKSPACE-SWITCH-WITH-DRAFT|/d' \
  "${missing_exception_acceptance_root}/docs/engineering/acceptance.md"
rm "${missing_exception_acceptance_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${missing_exception_acceptance_root}/candidate.md" \
  "${missing_exception_acceptance_root}/docs/engineering/plan.md" \
  "${missing_exception_acceptance_root}/docs/engineering/acceptance.md" \
  "expected exact 20 exception acceptance set"

missing_rm_trace_root="${test_tmp_root}/missing-rm-trace"
make_evidence_fixture "${missing_rm_trace_root}"
sed -i.bak '/^ReverseMigrationTrace = ISHFI-RM-30|/d' \
  "${missing_rm_trace_root}/docs/engineering/acceptance.md"
rm "${missing_rm_trace_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${missing_rm_trace_root}/candidate.md" \
  "${missing_rm_trace_root}/docs/engineering/plan.md" \
  "${missing_rm_trace_root}/docs/engineering/acceptance.md" \
  "expected exact ISHFI-RM-01..30 trace set"

missing_cross_domain_root="${test_tmp_root}/missing-cross-domain"
make_evidence_fixture "${missing_cross_domain_root}"
sed -i.bak '/^CrossDomainScenario = RULE_POLICY_DOMAIN|/d' \
  "${missing_cross_domain_root}/docs/engineering/plan.md"
rm "${missing_cross_domain_root}/docs/engineering/plan.md.bak"
expect_evidence_failure \
  "${missing_cross_domain_root}/candidate.md" \
  "${missing_cross_domain_root}/docs/engineering/plan.md" \
  "${missing_cross_domain_root}/docs/engineering/acceptance.md" \
  "mechanism and rule-policy cross-domain scenarios required"

extra_cross_domain_root="${test_tmp_root}/extra-cross-domain"
make_evidence_fixture "${extra_cross_domain_root}"
sed -i.bak '/^HFD03CrossDomainScenario = RULE_POLICY_DOMAIN|/a\
HFD03CrossDomainScenario = UNAUTHORIZED_DOMAIN|CanonicalProjection=KnowledgeLandscape>KnowledgeTheme>CognitiveModule>KnowledgeElement|Scenario=UNAUTHORIZED' \
  "${extra_cross_domain_root}/candidate.md"
rm "${extra_cross_domain_root}/candidate.md.bak"
expect_evidence_failure \
  "${extra_cross_domain_root}/candidate.md" \
  "${extra_cross_domain_root}/docs/engineering/plan.md" \
  "${extra_cross_domain_root}/docs/engineering/acceptance.md" \
  "candidate must contain exactly two cross-domain scenarios"

premature_acceptance_pass_root="${test_tmp_root}/premature-acceptance-pass"
make_evidence_fixture "${premature_acceptance_pass_root}"
sed -i.bak \
  '/^RFAcceptance = RF-AC-01|/s/|Status=NOT_RUN|/|Status=PASS|/' \
  "${premature_acceptance_pass_root}/docs/engineering/acceptance.md"
rm "${premature_acceptance_pass_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${premature_acceptance_pass_root}/candidate.md" \
  "${premature_acceptance_pass_root}/docs/engineering/plan.md" \
  "${premature_acceptance_pass_root}/docs/engineering/acceptance.md" \
  "acceptance evidence status must remain NOT_RUN"

missing_acceptance_field_root="${test_tmp_root}/missing-acceptance-field"
make_evidence_fixture "${missing_acceptance_field_root}"
sed -i.bak \
  '/^RFAcceptance = RF-AC-02|/s/|Expected=[^|]*|/|/' \
  "${missing_acceptance_field_root}/docs/engineering/acceptance.md"
rm "${missing_acceptance_field_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${missing_acceptance_field_root}/candidate.md" \
  "${missing_acceptance_field_root}/docs/engineering/plan.md" \
  "${missing_acceptance_field_root}/docs/engineering/acceptance.md" \
  "acceptance evidence row field mismatch"

fabricated_artifact_root="${test_tmp_root}/fabricated-artifact"
make_evidence_fixture "${fabricated_artifact_root}"
sed -i.bak \
  '/^RFAcceptance = RF-AC-03|/s/|Artifact=PLANNED:/|Artifact=CAPTURED:/' \
  "${fabricated_artifact_root}/docs/engineering/acceptance.md"
rm "${fabricated_artifact_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${fabricated_artifact_root}/candidate.md" \
  "${fabricated_artifact_root}/docs/engineering/plan.md" \
  "${fabricated_artifact_root}/docs/engineering/acceptance.md" \
  "acceptance artifacts must remain PLANNED"

premature_hv_ready_root="${test_tmp_root}/premature-hv-ready"
make_evidence_fixture "${premature_hv_ready_root}"
sed -i.bak \
  's/^HVDesignTask = HV-D00|VisualFoundation|BLOCKED|NOT_RELEASED$/HVDesignTask = HV-D00|VisualFoundation|READY|RELEASED/' \
  "${premature_hv_ready_root}/docs/engineering/plan.md"
rm "${premature_hv_ready_root}/docs/engineering/plan.md.bak"
expect_evidence_failure \
  "${premature_hv_ready_root}/candidate.md" \
  "${premature_hv_ready_root}/docs/engineering/plan.md" \
  "${premature_hv_ready_root}/docs/engineering/acceptance.md" \
  "visual design tasks must remain BLOCKED and NOT_RELEASED"

evidence_path_captured_root="${test_tmp_root}/evidence-path-captured"
make_evidence_fixture "${evidence_path_captured_root}"
sed -i.bak '/^EvidencePath = 01|/s/Artifact=PLANNED:/Artifact=CAPTURED:/' \
  "${evidence_path_captured_root}/docs/engineering/plan.md"
rm "${evidence_path_captured_root}/docs/engineering/plan.md.bak"
expect_evidence_failure \
  "${evidence_path_captured_root}/candidate.md" \
  "${evidence_path_captured_root}/docs/engineering/plan.md" \
  "${evidence_path_captured_root}/docs/engineering/acceptance.md" \
  "evidence path contract mismatch"

evidence_path_pass_root="${test_tmp_root}/evidence-path-pass"
make_evidence_fixture "${evidence_path_pass_root}"
sed -i.bak '/^EvidencePath = 01|/s/Status=NOT_RUN/Status=PASS/' \
  "${evidence_path_pass_root}/docs/engineering/plan.md"
rm "${evidence_path_pass_root}/docs/engineering/plan.md.bak"
expect_evidence_failure \
  "${evidence_path_pass_root}/candidate.md" \
  "${evidence_path_pass_root}/docs/engineering/plan.md" \
  "${evidence_path_pass_root}/docs/engineering/acceptance.md" \
  "evidence path contract mismatch"

evidence_path_missing_field_root="${test_tmp_root}/evidence-path-missing-field"
make_evidence_fixture "${evidence_path_missing_field_root}"
sed -i.bak '/^EvidencePath = 02|/s/|Scenario=[^|]*|/||/' \
  "${evidence_path_missing_field_root}/docs/engineering/plan.md"
rm "${evidence_path_missing_field_root}/docs/engineering/plan.md.bak"
expect_evidence_failure \
  "${evidence_path_missing_field_root}/candidate.md" \
  "${evidence_path_missing_field_root}/docs/engineering/plan.md" \
  "${evidence_path_missing_field_root}/docs/engineering/acceptance.md" \
  "evidence path contract mismatch"

evidence_path_wrong_gate_root="${test_tmp_root}/evidence-path-wrong-gate"
make_evidence_fixture "${evidence_path_wrong_gate_root}"
sed -i.bak '/^EvidencePath = 03|/s/Gate=HV-D02/Gate=HV-D03/' \
  "${evidence_path_wrong_gate_root}/docs/engineering/plan.md"
rm "${evidence_path_wrong_gate_root}/docs/engineering/plan.md.bak"
expect_evidence_failure \
  "${evidence_path_wrong_gate_root}/candidate.md" \
  "${evidence_path_wrong_gate_root}/docs/engineering/plan.md" \
  "${evidence_path_wrong_gate_root}/docs/engineering/acceptance.md" \
  "evidence path contract mismatch"

duplicate_evidence_path_root="${test_tmp_root}/duplicate-evidence-path"
make_evidence_fixture "${duplicate_evidence_path_root}"
sed -i.bak '/^EvidencePath = 04|/p' \
  "${duplicate_evidence_path_root}/docs/engineering/plan.md"
rm "${duplicate_evidence_path_root}/docs/engineering/plan.md.bak"
expect_evidence_failure \
  "${duplicate_evidence_path_root}/candidate.md" \
  "${duplicate_evidence_path_root}/docs/engineering/plan.md" \
  "${duplicate_evidence_path_root}/docs/engineering/acceptance.md" \
  "evidence path contract mismatch"

appended_evidence_path_root="${test_tmp_root}/appended-evidence-path"
make_evidence_fixture "${appended_evidence_path_root}"
sed -i.bak '/^EvidencePath = 08|/a\
EvidencePath = 09|StaticExport|Scenario=CONFLICT|Viewport=DESKTOP_WEB|InputState=READING_MODE+IDLE|Coverage=Conflict|Artifact=PLANNED:conflict.png|Status=NOT_RUN|Gate=HV-D04' \
  "${appended_evidence_path_root}/docs/engineering/plan.md"
rm "${appended_evidence_path_root}/docs/engineering/plan.md.bak"
expect_evidence_failure \
  "${appended_evidence_path_root}/candidate.md" \
  "${appended_evidence_path_root}/docs/engineering/plan.md" \
  "${appended_evidence_path_root}/docs/engineering/acceptance.md" \
  "evidence path contract mismatch"

rf_expected_swap_root="${test_tmp_root}/rf-expected-swap"
make_evidence_fixture "${rf_expected_swap_root}"
sed -i.bak '/^RFAcceptance = RF-AC-01|/s/Expected=FourLayerPrimaryCognitiveTaskCompletes/Expected=CompleteCognitiveClosureWithoutInteraction/' \
  "${rf_expected_swap_root}/docs/engineering/acceptance.md"
rm "${rf_expected_swap_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${rf_expected_swap_root}/candidate.md" \
  "${rf_expected_swap_root}/docs/engineering/plan.md" \
  "${rf_expected_swap_root}/docs/engineering/acceptance.md" \
  "RF acceptance binding mismatch"

rf_scenario_swap_root="${test_tmp_root}/rf-scenario-swap"
make_evidence_fixture "${rf_scenario_swap_root}"
sed -i.bak '/^RFAcceptance = RF-AC-01|/s/Scenario=FOUR_LAYER_ZERO_INTERACTION_TASK/Scenario=MODULE_DEFAULT_READING/' \
  "${rf_scenario_swap_root}/docs/engineering/acceptance.md"
rm "${rf_scenario_swap_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${rf_scenario_swap_root}/candidate.md" \
  "${rf_scenario_swap_root}/docs/engineering/plan.md" \
  "${rf_scenario_swap_root}/docs/engineering/acceptance.md" \
  "RF acceptance binding mismatch"

rf_wrong_class_root="${test_tmp_root}/rf-wrong-class"
make_evidence_fixture "${rf_wrong_class_root}"
sed -i.bak '/^RFAcceptance = RF-AC-01|/s/EvidenceClass=KnowledgeLandscapeAndKnowledgeTheme/EvidenceClass=CognitiveModuleDefaultReading/' \
  "${rf_wrong_class_root}/docs/engineering/acceptance.md"
rm "${rf_wrong_class_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${rf_wrong_class_root}/candidate.md" \
  "${rf_wrong_class_root}/docs/engineering/plan.md" \
  "${rf_wrong_class_root}/docs/engineering/acceptance.md" \
  "RF acceptance binding mismatch"

duplicate_rf_binding_root="${test_tmp_root}/duplicate-rf-binding"
make_evidence_fixture "${duplicate_rf_binding_root}"
sed -i.bak '/^RFAcceptance = RF-AC-02|/p' \
  "${duplicate_rf_binding_root}/docs/engineering/acceptance.md"
rm "${duplicate_rf_binding_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${duplicate_rf_binding_root}/candidate.md" \
  "${duplicate_rf_binding_root}/docs/engineering/plan.md" \
  "${duplicate_rf_binding_root}/docs/engineering/acceptance.md" \
  "expected exact RF-AC-01..20 acceptance set"

appended_rf_conflict_root="${test_tmp_root}/appended-rf-conflict"
make_evidence_fixture "${appended_rf_conflict_root}"
sed -i.bak '/^RFAcceptance = RF-AC-20|/a\
RFAcceptance = RF-AC-01|EvidenceClass=CognitiveModuleDefaultReading|Scenario=CONFLICT|Viewport=DESKTOP_1440x1100|InputState=READING_MODE+IDLE|Expected=Conflict|Artifact=PLANNED:conflict.png|Status=NOT_RUN|Gate=HV-D01' \
  "${appended_rf_conflict_root}/docs/engineering/acceptance.md"
rm "${appended_rf_conflict_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${appended_rf_conflict_root}/candidate.md" \
  "${appended_rf_conflict_root}/docs/engineering/plan.md" \
  "${appended_rf_conflict_root}/docs/engineering/acceptance.md" \
  "expected exact RF-AC-01..20 acceptance set"

exception_expected_swap_root="${test_tmp_root}/exception-expected-swap"
make_evidence_fixture "${exception_expected_swap_root}"
sed -i.bak '/^ExceptionAcceptance = EX-PREVIEW-TARGET-DELETED|/s/Expected=PreviewClosesAndStableFocusReturnsWithFeedback/Expected=SupersededRelationExplainedAndOriginRestored/' \
  "${exception_expected_swap_root}/docs/engineering/acceptance.md"
rm "${exception_expected_swap_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${exception_expected_swap_root}/candidate.md" \
  "${exception_expected_swap_root}/docs/engineering/plan.md" \
  "${exception_expected_swap_root}/docs/engineering/acceptance.md" \
  "exception acceptance binding mismatch"

exception_scenario_swap_root="${test_tmp_root}/exception-scenario-swap"
make_evidence_fixture "${exception_scenario_swap_root}"
sed -i.bak '/^ExceptionAcceptance = EX-PREVIEW-TARGET-DELETED|/s/Scenario=PREVIEW_TARGET_DELETED/Scenario=RELATION_SUPERSEDED/' \
  "${exception_scenario_swap_root}/docs/engineering/acceptance.md"
rm "${exception_scenario_swap_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${exception_scenario_swap_root}/candidate.md" \
  "${exception_scenario_swap_root}/docs/engineering/plan.md" \
  "${exception_scenario_swap_root}/docs/engineering/acceptance.md" \
  "exception acceptance binding mismatch"

exception_wrong_class_root="${test_tmp_root}/exception-wrong-class"
make_evidence_fixture "${exception_wrong_class_root}"
sed -i.bak '/^ExceptionAcceptance = EX-PREVIEW-TARGET-DELETED|/s/EvidenceClass=RelationFocus/EvidenceClass=Recovery/' \
  "${exception_wrong_class_root}/docs/engineering/acceptance.md"
rm "${exception_wrong_class_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${exception_wrong_class_root}/candidate.md" \
  "${exception_wrong_class_root}/docs/engineering/plan.md" \
  "${exception_wrong_class_root}/docs/engineering/acceptance.md" \
  "exception acceptance binding mismatch"

duplicate_exception_binding_root="${test_tmp_root}/duplicate-exception-binding"
make_evidence_fixture "${duplicate_exception_binding_root}"
sed -i.bak '/^ExceptionAcceptance = EX-RELATION-SUPERSEDED|/p' \
  "${duplicate_exception_binding_root}/docs/engineering/acceptance.md"
rm "${duplicate_exception_binding_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${duplicate_exception_binding_root}/candidate.md" \
  "${duplicate_exception_binding_root}/docs/engineering/plan.md" \
  "${duplicate_exception_binding_root}/docs/engineering/acceptance.md" \
  "expected exact 20 exception acceptance set"

appended_exception_conflict_root="${test_tmp_root}/appended-exception-conflict"
make_evidence_fixture "${appended_exception_conflict_root}"
sed -i.bak '/^ExceptionAcceptance = EX-WORKSPACE-SWITCH-WITH-DRAFT|/a\
ExceptionAcceptance = EX-PREVIEW-TARGET-DELETED|EvidenceClass=Recovery|Scenario=CONFLICT|Viewport=DESKTOP_1440x1100|InputState=FAILED|Expected=Conflict|Artifact=PLANNED:conflict.png|Status=NOT_RUN|Gate=HV-D03' \
  "${appended_exception_conflict_root}/docs/engineering/acceptance.md"
rm "${appended_exception_conflict_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${appended_exception_conflict_root}/candidate.md" \
  "${appended_exception_conflict_root}/docs/engineering/plan.md" \
  "${appended_exception_conflict_root}/docs/engineering/acceptance.md" \
  "expected exact 20 exception acceptance set"

rm_candidate_cross_link_root="${test_tmp_root}/rm-candidate-cross-link"
make_evidence_fixture "${rm_candidate_cross_link_root}"
sed -i.bak '/^ReverseMigrationTrace = ISHFI-RM-01|/s/Candidate=ISHFI-RM-01/Candidate=ISHFI-RM-02/' \
  "${rm_candidate_cross_link_root}/docs/engineering/acceptance.md"
rm "${rm_candidate_cross_link_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${rm_candidate_cross_link_root}/candidate.md" \
  "${rm_candidate_cross_link_root}/docs/engineering/plan.md" \
  "${rm_candidate_cross_link_root}/docs/engineering/acceptance.md" \
  "reverse-migration trace binding mismatch"

rm_empty_acceptance_root="${test_tmp_root}/rm-empty-acceptance"
make_evidence_fixture "${rm_empty_acceptance_root}"
sed -i.bak '/^ReverseMigrationTrace = ISHFI-RM-02|/s/AcceptanceIds=[^|]*/AcceptanceIds=/' \
  "${rm_empty_acceptance_root}/docs/engineering/acceptance.md"
rm "${rm_empty_acceptance_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${rm_empty_acceptance_root}/candidate.md" \
  "${rm_empty_acceptance_root}/docs/engineering/plan.md" \
  "${rm_empty_acceptance_root}/docs/engineering/acceptance.md" \
  "reverse-migration trace binding mismatch"

rm_unknown_acceptance_root="${test_tmp_root}/rm-unknown-acceptance"
make_evidence_fixture "${rm_unknown_acceptance_root}"
sed -i.bak '/^ReverseMigrationTrace = ISHFI-RM-03|/s/AcceptanceIds=[^|]*/AcceptanceIds=RF-AC-99/' \
  "${rm_unknown_acceptance_root}/docs/engineering/acceptance.md"
rm "${rm_unknown_acceptance_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${rm_unknown_acceptance_root}/candidate.md" \
  "${rm_unknown_acceptance_root}/docs/engineering/plan.md" \
  "${rm_unknown_acceptance_root}/docs/engineering/acceptance.md" \
  "reverse-migration trace binding mismatch"

rm_wrong_path_root="${test_tmp_root}/rm-wrong-path"
make_evidence_fixture "${rm_wrong_path_root}"
sed -i.bak '/^ReverseMigrationTrace = ISHFI-RM-04|/s/EvidencePath=04/EvidencePath=05/' \
  "${rm_wrong_path_root}/docs/engineering/acceptance.md"
rm "${rm_wrong_path_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${rm_wrong_path_root}/candidate.md" \
  "${rm_wrong_path_root}/docs/engineering/plan.md" \
  "${rm_wrong_path_root}/docs/engineering/acceptance.md" \
  "reverse-migration trace binding mismatch"

appended_rm_conflict_root="${test_tmp_root}/appended-rm-conflict"
make_evidence_fixture "${appended_rm_conflict_root}"
sed -i.bak '/^ReverseMigrationTrace = ISHFI-RM-01|/p' \
  "${appended_rm_conflict_root}/docs/engineering/acceptance.md"
rm "${appended_rm_conflict_root}/docs/engineering/acceptance.md.bak"
expect_evidence_failure \
  "${appended_rm_conflict_root}/candidate.md" \
  "${appended_rm_conflict_root}/docs/engineering/plan.md" \
  "${appended_rm_conflict_root}/docs/engineering/acceptance.md" \
  "expected exact ISHFI-RM-01..30 trace set"

cross_domain_binding_root="${test_tmp_root}/cross-domain-binding"
make_evidence_fixture "${cross_domain_binding_root}"
sed -i.bak '/^CrossDomainScenario = MECHANISM_DOMAIN|/s/EvidenceClass=CognitiveModuleDefaultReading/EvidenceClass=KnowledgeLandscapeAndKnowledgeTheme/' \
  "${cross_domain_binding_root}/docs/engineering/plan.md"
sed -i.bak '/^CrossDomainScenario = MECHANISM_DOMAIN|/s/Scenario=MVCC_CONSISTENT_READ_MECHANISM/Scenario=PROCUREMENT_ACCEPTANCE_BEFORE_PAYMENT_POLICY/' \
  "${cross_domain_binding_root}/docs/engineering/plan.md"
rm "${cross_domain_binding_root}/docs/engineering/plan.md.bak"
expect_evidence_failure \
  "${cross_domain_binding_root}/candidate.md" \
  "${cross_domain_binding_root}/docs/engineering/plan.md" \
  "${cross_domain_binding_root}/docs/engineering/acceptance.md" \
  "cross-domain scenario contract mismatch"

cross_domain_rule_swap_root="${test_tmp_root}/cross-domain-rule-swap"
make_evidence_fixture "${cross_domain_rule_swap_root}"
sed -i.bak '/^CrossDomainScenario = RULE_POLICY_DOMAIN|/s/Scenario=PROCUREMENT_ACCEPTANCE_BEFORE_PAYMENT_POLICY/Scenario=MVCC_CONSISTENT_READ_MECHANISM/' \
  "${cross_domain_rule_swap_root}/docs/engineering/plan.md"
rm "${cross_domain_rule_swap_root}/docs/engineering/plan.md.bak"
expect_evidence_failure \
  "${cross_domain_rule_swap_root}/candidate.md" \
  "${cross_domain_rule_swap_root}/docs/engineering/plan.md" \
  "${cross_domain_rule_swap_root}/docs/engineering/acceptance.md" \
  "cross-domain scenario contract mismatch"

appended_cross_domain_root="${test_tmp_root}/appended-cross-domain"
make_evidence_fixture "${appended_cross_domain_root}"
sed -i.bak '/^CrossDomainScenario = RULE_POLICY_DOMAIN|/a\
CrossDomainScenario = MECHANISM_DOMAIN|EvidenceClass=KnowledgeLandscapeAndKnowledgeTheme|CanonicalProjection=KnowledgeLandscape>KnowledgeTheme>CognitiveModule>KnowledgeElement|Scenario=CONFLICT|Status=NOT_RUN|Gate=HV-D04' \
  "${appended_cross_domain_root}/docs/engineering/plan.md"
rm "${appended_cross_domain_root}/docs/engineering/plan.md.bak"
expect_evidence_failure \
  "${appended_cross_domain_root}/candidate.md" \
  "${appended_cross_domain_root}/docs/engineering/plan.md" \
  "${appended_cross_domain_root}/docs/engineering/acceptance.md" \
  "cross-domain scenario contract mismatch"

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

mode_axis_contaminated="${test_tmp_root}/mode-axis-contaminated.md"
cp "${document}" "${mode_axis_contaminated}"
sed -i.bak \
  's/^OrthogonalAxis = ModeAxis|READING,VERIFICATION,REVISION$/OrthogonalAxis = ModeAxis|READING,VERIFICATION,REVISION,DIRTY_DRAFT/' \
  "${mode_axis_contaminated}"
rm "${mode_axis_contaminated}.bak"
expect_failure "${mode_axis_contaminated}" "ModeAxis value set mismatch"

input_focus_in_history="${test_tmp_root}/input-focus-in-history.md"
cp "${document}" "${input_focus_in_history}"
sed -i.bak \
  's/^| INPUT_FOCUS | TRANSIENT_UI | InputFocusFlow | EPHEMERAL_UI | NOT_PERSISTED | NO_CANONICAL_WRITE |$/| INPUT_FOCUS | TRANSIENT_UI | InputFocusFlow | BROWSER_HISTORY | URL_AND_HISTORY | NO_CANONICAL_WRITE |/' \
  "${input_focus_in_history}"
rm "${input_focus_in_history}.bak"
expect_failure "${input_focus_in_history}" \
  "TRANSIENT_UI must be EPHEMERAL_UI and not persisted"

page_state_generating_collision="${test_tmp_root}/page-state-generating-collision.md"
cp "${document}" "${page_state_generating_collision}"
sed -i.bak \
  's/^PageStateMapping = GENERATING|ProcessingAxis.PROJECTION_GENERATING$/PageStateMapping = GENERATING|ProcessingAxis.GENERATING/' \
  "${page_state_generating_collision}"
rm "${page_state_generating_collision}.bak"
expect_failure "${page_state_generating_collision}" \
  "GENERATING PageState mapping mismatch"

appended_stable_parameter="${test_tmp_root}/appended-stable-parameter.md"
cp "${document}" "${appended_stable_parameter}"
sed -i.bak '/^| PREVIEW | TRANSIENT_UI |/a\
| STABLE_PARAMETER | STABLE_PARAMETER | StableProjectionParameter:CognitivePerspective | URL | URL_AND_HISTORY | NO_CANONICAL_WRITE |' \
  "${appended_stable_parameter}"
rm "${appended_stable_parameter}.bak"
expect_failure "${appended_stable_parameter}" "invalid Classification"

url_ledger_contains_draft="${test_tmp_root}/url-ledger-contains-draft.md"
cp "${document}" "${url_ledger_contains_draft}"
sed -i.bak \
  's/^PersistenceLedger = URL|Page,StableObject,Mode,StableRelation,ShareablePerspective|NO_DRAFT_ID_NO_TECHNICAL_VERSION_NO_PROCESS_PHASE$/PersistenceLedger = URL|Page,StableObject,Mode,StableRelation,ShareablePerspective,DraftId,ProcessPhase|NO_TECHNICAL_VERSION/' \
  "${url_ledger_contains_draft}"
rm "${url_ledger_contains_draft}.bak"
expect_failure "${url_ledger_contains_draft}" "URL persistence ledger mismatch"

projection_parameter_misclassified="${test_tmp_root}/projection-parameter-misclassified.md"
cp "${document}" "${projection_parameter_misclassified}"
sed -i.bak \
  's/^| COGNITIVE_PERSPECTIVE_OVERRIDE | AXIS_VALUE | StableProjectionParameter:CognitivePerspective |/| COGNITIVE_PERSPECTIVE_OVERRIDE | FLOW_PHASE | StableProjectionParameter:CognitivePerspective |/' \
  "${projection_parameter_misclassified}"
rm "${projection_parameter_misclassified}.bak"
expect_failure "${projection_parameter_misclassified}" \
  "CognitivePerspective must be a stable Projection parameter AXIS_VALUE"

contrary_non_change="${test_tmp_root}/contrary-non-change.md"
cp "${document}" "${contrary_non_change}"
sed -i.bak '/^PageStateEnumChange = NO$/a\
PageStateEnumChange = YES' "${contrary_non_change}"
rm "${contrary_non_change}.bak"
expect_failure "${contrary_non_change}" "PageStateEnumChange must be declared exactly once"

changed_relation_mapping="${test_tmp_root}/changed-relation-mapping.md"
cp "${document}" "${changed_relation_mapping}"
sed -i.bak \
  's/^LogicalObjectMapping = RelationVersion|EXISTING_RELATION_WITHIN_OWNING_ARTIFACT_REVISION$/LogicalObjectMapping = RelationVersion|NEW_PHYSICAL_RELATION_TABLE/' \
  "${changed_relation_mapping}"
rm "${changed_relation_mapping}.bak"
expect_failure "${changed_relation_mapping}" \
  "logical revision Relation Evidence mapping mismatch"

changed_submit_unknown="${test_tmp_root}/changed-submit-unknown.md"
cp "${document}" "${changed_submit_unknown}"
sed -i.bak \
  's/^SubmitUnknownDisposition = QUERY_RESULT_WITH_SAME_IDEMPOTENCY_KEY$/SubmitUnknownDisposition = RETRY_WITH_NEW_IDEMPOTENCY_KEY/' \
  "${changed_submit_unknown}"
rm "${changed_submit_unknown}.bak"
expect_failure "${changed_submit_unknown}" \
  "persistence recovery invariant is missing or duplicated"

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
  's/^ContractP0Remaining = (DEFERRED_TO_HF_D0(1|2|3)_THROUGH_HF_D04|DEFERRED_TO_HF_D04)$/ContractP0Remaining = 0/' \
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
  '/^| RF-AC-01 /s/| CONTRACT | PASS | NOT_RUN |$/| CONTRACT | PASS | PASS |/' \
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
  "REAL_HIGH_FIDELITY_PAGE_PREMATURE_IN_HFD03"

printf '%s\n' \
  "InteractionStateContractTests = PASS" \
  "StageAwarePositiveCases = 2" \
  "NegativeCases = 84"
