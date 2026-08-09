#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-ui-contracts"
candidate="${repo_root}/Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md"
overall="${repo_root}/cognitive-knowledge-atlas-overall-design-1.2.md"
page_contracts="${repo_root}/docs/contracts/cognitura-page-contracts.md"
renderer_contract="${repo_root}/docs/contracts/cognitura-renderer-contract.md"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-ui-contracts.XXXXXX")"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

run_validation() {
  local candidate_file="$1"
  local overall_file="$2"
  local page_file="$3"
  local renderer_file="$4"

  "${verifier}" \
    --candidate "${candidate_file}" \
    --overall "${overall_file}" \
    --page-contracts "${page_file}" \
    --renderer-contract "${renderer_file}"
}

make_fixture() {
  local fixture_name="$1"
  local fixture_root="${test_tmp_root}/${fixture_name}"

  mkdir -p "${fixture_root}"
  cp "${candidate}" "${fixture_root}/candidate.md"
  cp "${overall}" "${fixture_root}/overall.md"
  cp "${page_contracts}" "${fixture_root}/page-contracts.md"
  cp "${renderer_contract}" "${fixture_root}/renderer-contract.md"
  printf '%s\n' "${fixture_root}"
}

expect_failure() {
  local fixture_root="$1"
  local expected_message="$2"
  local output

  if output="$(run_validation \
    "${fixture_root}/candidate.md" \
    "${fixture_root}/overall.md" \
    "${fixture_root}/page-contracts.md" \
    "${fixture_root}/renderer-contract.md" 2>&1)"; then
    fail "invalid fixture unexpectedly passed: ${fixture_root}"
  fi

  if [[ "${output}" != *"${expected_message}"* ]]; then
    fail "expected error '${expected_message}', got: ${output}"
  fi
}

[[ -x "${verifier}" ]] || fail "UI contract verifier is missing or not executable"
[[ -f "${candidate}" ]] || fail "high-fidelity specialty candidate is missing"
[[ -f "${overall}" ]] || fail "overall design is missing"
[[ -f "${page_contracts}" ]] || fail "page contract document is missing"
[[ -f "${renderer_contract}" ]] || fail "renderer contract document is missing"

if ! valid_output="$(run_validation \
  "${candidate}" \
  "${overall}" \
  "${page_contracts}" \
  "${renderer_contract}" 2>&1)"; then
  fail "canonical UI contracts were rejected: ${valid_output}"
fi

for expected_line in \
  "UiContractValidation = PASS" \
  "ReadingPresentationCrossDocumentProjection = PASS" \
  "PageContractCount = 12" \
  "SkeletonOperationCount = 6" \
  "RendererContractCount = 9" \
  "ForbiddenExperienceCount = 4" \
  "W0-G4A UiContractValidation = PASS"; do
  if [[ "${valid_output}" != *"${expected_line}"* ]]; then
    fail "canonical validation did not report '${expected_line}'"
  fi
done

missing_page="$(make_fixture "missing-page")"
sed -i.bak '/^PageContract = SKELETON_REVIEW|/d' "${missing_page}/page-contracts.md"
rm "${missing_page}/page-contracts.md.bak"
expect_failure "${missing_page}" "MISSING_PAGE_CONTRACT: SKELETON_REVIEW"

missing_operation="$(make_fixture "missing-operation")"
sed -i.bak '/^SkeletonOperation = SPLIT|/d' "${missing_operation}/page-contracts.md"
rm "${missing_operation}/page-contracts.md.bak"
expect_failure "${missing_operation}" "MISSING_SKELETON_OPERATION: SPLIT"

missing_renderer="$(make_fixture "missing-renderer")"
sed -i.bak '/^RendererContract = COMPARISON|/d' "${missing_renderer}/renderer-contract.md"
rm "${missing_renderer}/renderer-contract.md.bak"
expect_failure "${missing_renderer}" "MISSING_RENDERER_CONTRACT: COMPARISON"

renderer_creates_fact="$(make_fixture "renderer-creates-fact")"
sed -i.bak \
  's/^RendererInvariant = CREATES_INDEPENDENT_FACTS|NO|/RendererInvariant = CREATES_INDEPENDENT_FACTS|YES|/' \
  "${renderer_creates_fact}/renderer-contract.md"
rm "${renderer_creates_fact}/renderer-contract.md.bak"
expect_failure "${renderer_creates_fact}" "RENDERER_FACT_CREATION_FORBIDDEN"

mobile_feature_parity="$(make_fixture "mobile-feature-parity")"
sed -i.bak \
  's/^PlatformContract = MOBILE_FEATURE_PARITY|NOT_REQUIRED|/PlatformContract = MOBILE_FEATURE_PARITY|REQUIRED|/' \
  "${mobile_feature_parity}/page-contracts.md"
rm "${mobile_feature_parity}/page-contracts.md.bak"
expect_failure "${mobile_feature_parity}" "MOBILE_FEATURE_PARITY_FORBIDDEN"

missing_failure_state="$(make_fixture "missing-failure-state")"
sed -i.bak '/^PageState = FAILED|/d' "${missing_failure_state}/page-contracts.md"
rm "${missing_failure_state}/page-contracts.md.bak"
expect_failure "${missing_failure_state}" "MISSING_PAGE_STATE: FAILED"

card_only_experience="$(make_fixture "card-only-experience")"
sed -i.bak \
  's/^ForbiddenExperience = CARD_ONLY_LAYOUT|NO|/ForbiddenExperience = CARD_ONLY_LAYOUT|YES|/' \
  "${card_only_experience}/page-contracts.md"
rm "${card_only_experience}/page-contracts.md.bak"
expect_failure "${card_only_experience}" "FORBIDDEN_EXPERIENCE_ENABLED: CARD_ONLY_LAYOUT"

invented_schema_semantics="$(make_fixture "invented-schema-semantics")"
sed -i.bak \
  's/^RendererInputCapability = TITLE|CONCEPT_ONLY|/RendererInputCapability = TITLE|REQUIRED_STRING|/' \
  "${invented_schema_semantics}/renderer-contract.md"
rm "${invented_schema_semantics}/renderer-contract.md.bak"
expect_failure "${invented_schema_semantics}" "SCHEMA_SEMANTICS_FORBIDDEN: TITLE"

missing_schema_authority="$(make_fixture "missing-schema-authority")"
sed -i.bak \
  's/^FieldLevelSchemaAuthority = Cognitura-Schema-Baseline-2.0$/FieldLevelSchemaAuthority = NOT_PROVIDED/' \
  "${missing_schema_authority}/page-contracts.md"
rm "${missing_schema_authority}/page-contracts.md.bak"
expect_failure \
  "${missing_schema_authority}" \
  "MISSING_SCHEMA_REBASELINE_AUTHORITY: PAGE_STATE"

permanent_governance_rail="$(make_fixture "permanent-governance-rail")"
sed -i.bak \
  's/^ModuleReadingDefault = PERSISTENT_GOVERNANCE_SIDE_PANEL|0|/ModuleReadingDefault = PERSISTENT_GOVERNANCE_SIDE_PANEL|1|/' \
  "${permanent_governance_rail}/page-contracts.md"
rm "${permanent_governance_rail}/page-contracts.md.bak"
expect_failure \
  "${permanent_governance_rail}" \
  "PERMANENT_GOVERNANCE_SIDE_PANEL_FORBIDDEN"

pure_long_article="$(make_fixture "pure-long-article")"
sed -i.bak \
  's/^ReadingPresentationContract = PURE_UNSTRUCTURED_LONG_ARTICLE|FORBIDDEN|/ReadingPresentationContract = PURE_UNSTRUCTURED_LONG_ARTICLE|REQUIRED|/' \
  "${pure_long_article}/page-contracts.md"
rm "${pure_long_article}/page-contracts.md.bak"
expect_failure \
  "${pure_long_article}" \
  "PURE_UNSTRUCTURED_LONG_ARTICLE_FORBIDDEN"

visual_budget_exceeded="$(make_fixture "visual-budget-exceeded")"
sed -i.bak \
  's/^RendererPresentationBudget = PRIMARY_VISUAL_PROJECTION_PER_COGNITIVE_SECTION|AT_MOST_1|/RendererPresentationBudget = PRIMARY_VISUAL_PROJECTION_PER_COGNITIVE_SECTION|AT_MOST_2|/' \
  "${visual_budget_exceeded}/renderer-contract.md"
rm "${visual_budget_exceeded}/renderer-contract.md.bak"
expect_failure \
  "${visual_budget_exceeded}" \
  "PRIMARY_VISUAL_BUDGET_EXCEEDED"

candidate_projection_drift="$(make_fixture "candidate-projection-drift")"
sed -i.bak \
  's/^DefaultReadingPersistentSidePanels = 0$/DefaultReadingPersistentSidePanels = 1/' \
  "${candidate_projection_drift}/candidate.md"
rm "${candidate_projection_drift}/candidate.md.bak"
expect_failure \
  "${candidate_projection_drift}" \
  "CANDIDATE_PRESENTATION_PROJECTION_MISMATCH"

overall_projection_drift="$(make_fixture "overall-projection-drift")"
sed -i.bak \
  's/^ModuleReadingDefaultPersistentSidePanel = 0$/ModuleReadingDefaultPersistentSidePanel = 1/' \
  "${overall_projection_drift}/overall.md"
rm "${overall_projection_drift}/overall.md.bak"
expect_failure \
  "${overall_projection_drift}" \
  "OVERALL_PRESENTATION_PROJECTION_MISMATCH"

overall_historical_three_column_capability="$(make_fixture "overall-historical-three-column-capability")"
printf '%s\n' '- 三栏 Module Reading；' \
  >>"${overall_historical_three_column_capability}/overall.md"
expect_failure \
  "${overall_historical_three_column_capability}" \
  "OVERALL_THREE_COLUMN_READING_RESIDUE"

overall_historical_three_column_wave="$(make_fixture "overall-historical-three-column-wave")"
printf '%s\n' 'ModuleReading 三栏页面' \
  >>"${overall_historical_three_column_wave}/overall.md"
expect_failure \
  "${overall_historical_three_column_wave}" \
  "OVERALL_THREE_COLUMN_READING_RESIDUE"

candidate_conflicting_projection="$(make_fixture "candidate-conflicting-projection")"
printf '%s\n' 'DefaultReadingPersistentSidePanels = 1' \
  >>"${candidate_conflicting_projection}/candidate.md"
expect_failure \
  "${candidate_conflicting_projection}" \
  "CANDIDATE_PRESENTATION_PROJECTION_CONFLICT"

overall_conflicting_projection="$(make_fixture "overall-conflicting-projection")"
printf '%s\n' 'ModuleReadingDefaultPersistentSidePanel = 1' \
  >>"${overall_conflicting_projection}/overall.md"
expect_failure \
  "${overall_conflicting_projection}" \
  "OVERALL_PRESENTATION_PROJECTION_CONFLICT"

page_conflicting_projection="$(make_fixture "page-conflicting-projection")"
printf '%s\n' \
  'ModuleReadingDefault = PERSISTENT_GOVERNANCE_SIDE_PANEL|1|HF-SPECIALTY§12,14,16' \
  >>"${page_conflicting_projection}/page-contracts.md"
expect_failure \
  "${page_conflicting_projection}" \
  "PAGE_PRESENTATION_PROJECTION_CONFLICT"

renderer_conflicting_projection="$(make_fixture "renderer-conflicting-projection")"
printf '%s\n' \
  'RendererPresentationBudget = PRIMARY_VISUAL_PROJECTION_PER_COGNITIVE_SECTION|AT_MOST_2|HF-SPECIALTY§11,12' \
  >>"${renderer_conflicting_projection}/renderer-contract.md"
expect_failure \
  "${renderer_conflicting_projection}" \
  "RENDERER_PRESENTATION_PROJECTION_CONFLICT"

printf '%s\n' \
  "UiContractTests = PASS" \
  "PositiveContractSet = 1" \
  "NegativeCases = 20"
