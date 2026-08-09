#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-ui-contracts"
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

reading_presentation_fail() {
  printf 'UiReadingPresentationContract = FAIL\n%s\n' "$1" >&2
  return 1
}

validate_reading_presentation_contract() {
  local page_file="$1"
  local renderer_file="$2"

  grep -Fqx \
    'ReadingPresentationContract = PRIMARY_PRESENTATION_MODEL|INTERACTIVE_COGNITIVE_DOCUMENT|HF-SPECIALTY§3,18' \
    "${page_file}" || { reading_presentation_fail "MISSING_INTERACTIVE_COGNITIVE_DOCUMENT"; return 1; }
  grep -Fqx \
    'ReadingPresentationContract = PRIMARY_EXPERIENCE_MODEL|READING_FIRST|HF-SPECIALTY§3,18' \
    "${page_file}" || { reading_presentation_fail "MISSING_READING_FIRST"; return 1; }
  grep -Fqx \
    'ReadingPresentationContract = PURE_UNSTRUCTURED_LONG_ARTICLE|FORBIDDEN|HF-SPECIALTY§10,18' \
    "${page_file}" || { reading_presentation_fail "PURE_UNSTRUCTURED_LONG_ARTICLE_FORBIDDEN"; return 1; }
  grep -Fqx \
    'ReadingPresentationContract = STRUCTURED_CONTINUOUS_COGNITIVE_NARRATIVE|REQUIRED_WHEN_NEEDED|HF-SPECIALTY§10,18' \
    "${page_file}" || { reading_presentation_fail "MISSING_STRUCTURED_CONTINUOUS_COGNITIVE_NARRATIVE"; return 1; }
  grep -Fqx \
    'ModuleReadingDefault = KNOWLEDGE_HIERARCHY_ORIENTATION|RETAINED|HF-SPECIALTY§13,14,16' \
    "${page_file}" || { reading_presentation_fail "MISSING_HIERARCHY_ORIENTATION"; return 1; }
  grep -Fqx \
    'ModuleReadingDefault = PERSISTENT_GOVERNANCE_SIDE_PANEL|0|HF-SPECIALTY§12,14,16' \
    "${page_file}" || { reading_presentation_fail "PERMANENT_GOVERNANCE_SIDE_PANEL_FORBIDDEN"; return 1; }
  grep -Fqx \
    'ModuleReadingDefault = QUICK_SOURCE_PANEL|ON_DEMAND_TRANSIENT|HF-SPECIALTY§12,14,16' \
    "${page_file}" || { reading_presentation_fail "MISSING_ON_DEMAND_QUICK_SOURCE"; return 1; }
  grep -Fqx \
    'ModuleReadingDefault = FULL_SOURCE_EVIDENCE|ON_DEMAND_WORKSPACE_OR_ROUTE|HF-SPECIALTY§14,16,18' \
    "${page_file}" || { reading_presentation_fail "MISSING_FULL_SOURCE_EVIDENCE_ROUTE"; return 1; }
  grep -Fqx \
    'ModuleReadingDefault = RELATED_MODULES|INLINE_OR_ON_DEMAND|HF-SPECIALTY§13,14,16' \
    "${page_file}" || { reading_presentation_fail "MISSING_RELATED_MODULE_CONTEXT"; return 1; }
  grep -Fqx \
    'ModuleReadingDefault = KNOWN_GAPS|INLINE_WHEN_UNDERSTANDING_CHANGES|HF-SPECIALTY§13,14,16' \
    "${page_file}" || { reading_presentation_fail "MISSING_KNOWN_GAPS_CONTEXT"; return 1; }
  grep -Fqx \
    'ReadingPresentationBudget = DEFAULT_READING_PERSISTENT_PRIMARY_ACTIONS_PER_PAGE|AT_MOST_2|HF-SPECIALTY§12' \
    "${page_file}" || { reading_presentation_fail "MISSING_PRIMARY_ACTION_BUDGET"; return 1; }
  grep -Fqx \
    'RendererPresentationBudget = PRIMARY_VISUAL_PRIMITIVE_FAMILIES_PER_MODULE|AT_MOST_4|HF-SPECIALTY§11,12' \
    "${renderer_file}" || { reading_presentation_fail "MISSING_VISUAL_PRIMITIVE_FAMILY_BUDGET"; return 1; }
  grep -Fqx \
    'RendererPresentationBudget = PRIMARY_VISUAL_PROJECTION_PER_COGNITIVE_SECTION|AT_MOST_1|HF-SPECIALTY§11,12' \
    "${renderer_file}" || { reading_presentation_fail "PRIMARY_VISUAL_BUDGET_EXCEEDED"; return 1; }
  grep -Fqx \
    'RendererPresentationBudget = SIMULTANEOUSLY_EMPHASIZED_VISUAL_OBJECTS|AT_MOST_7|HF-SPECIALTY§11,12' \
    "${renderer_file}" || { reading_presentation_fail "MISSING_EMPHASIZED_OBJECT_BUDGET"; return 1; }
  grep -Fqx \
    'RendererInvariant = CREATES_INDEPENDENT_FACTS|NO|OD1.2§20.8' \
    "${renderer_file}" || { reading_presentation_fail "RENDERER_FACT_CREATION_FORBIDDEN"; return 1; }
}

run_validation() {
  local page_file="$1"
  local renderer_file="$2"

  "${verifier}" \
    --page-contracts "${page_file}" \
    --renderer-contract "${renderer_file}" || return 1
  validate_reading_presentation_contract "${page_file}" "${renderer_file}"
}

make_fixture() {
  local fixture_name="$1"
  local fixture_root="${test_tmp_root}/${fixture_name}"

  mkdir -p "${fixture_root}"
  cp "${page_contracts}" "${fixture_root}/page-contracts.md"
  cp "${renderer_contract}" "${fixture_root}/renderer-contract.md"
  printf '%s\n' "${fixture_root}"
}

expect_failure() {
  local fixture_root="$1"
  local expected_message="$2"
  local output

  if output="$(run_validation \
    "${fixture_root}/page-contracts.md" \
    "${fixture_root}/renderer-contract.md" 2>&1)"; then
    fail "invalid fixture unexpectedly passed: ${fixture_root}"
  fi

  if [[ "${output}" != *"${expected_message}"* ]]; then
    fail "expected error '${expected_message}', got: ${output}"
  fi
}

[[ -x "${verifier}" ]] || fail "UI contract verifier is missing or not executable"
[[ -f "${page_contracts}" ]] || fail "page contract document is missing"
[[ -f "${renderer_contract}" ]] || fail "renderer contract document is missing"

if ! valid_output="$(run_validation "${page_contracts}" "${renderer_contract}" 2>&1)"; then
  fail "canonical UI contracts were rejected: ${valid_output}"
fi

for expected_line in \
  "UiContractValidation = PASS" \
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

printf '%s\n' \
  "UiContractTests = PASS" \
  "PositiveContractSet = 1" \
  "NegativeCases = 12"
