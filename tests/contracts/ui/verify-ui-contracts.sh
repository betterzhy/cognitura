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

  if output="$(
    "${verifier}" \
      --page-contracts "${fixture_root}/page-contracts.md" \
      --renderer-contract "${fixture_root}/renderer-contract.md" \
      2>&1
  )"; then
    fail "invalid fixture unexpectedly passed: ${fixture_root}"
  fi

  if [[ "${output}" != *"${expected_message}"* ]]; then
    fail "expected error '${expected_message}', got: ${output}"
  fi
}

[[ -x "${verifier}" ]] || fail "UI contract verifier is missing or not executable"
[[ -f "${page_contracts}" ]] || fail "page contract document is missing"
[[ -f "${renderer_contract}" ]] || fail "renderer contract document is missing"

if ! valid_output="$(
  "${verifier}" \
    --page-contracts "${page_contracts}" \
    --renderer-contract "${renderer_contract}" \
    2>&1
)"; then
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
  's/^FieldLevelSchemaAuthority = Cognitura-Schema-Baseline-1.0$/FieldLevelSchemaAuthority = NOT_PROVIDED/' \
  "${missing_schema_authority}/page-contracts.md"
rm "${missing_schema_authority}/page-contracts.md.bak"
expect_failure \
  "${missing_schema_authority}" \
  "MISSING_SCHEMA_REBASELINE_AUTHORITY: PAGE_STATE"

printf '%s\n' \
  "UiContractTests = PASS" \
  "PositiveContractSet = 1" \
  "NegativeCases = 9"
