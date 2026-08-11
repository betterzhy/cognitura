#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-module-default-reading-implementation-cards"
cards_dir="${repo_root}/docs/task-cards/module-default-reading-implementation"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-mdr-cards.XXXXXX")"

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

[[ -x "${verifier}" ]] || fail "ModuleDefaultReading task-card verifier is missing or not executable"
[[ -d "${cards_dir}" ]] || fail "ModuleDefaultReading task-card directory is missing"

canonical_output="$("${verifier}" --cards-dir "${cards_dir}")" ||
  fail "canonical ModuleDefaultReading task cards were rejected"
for expected_line in \
  "ModuleDefaultReadingTaskCardValidation = PASS" \
  "TaskCardCount = 9" \
  "TaskCardSetStatus = PLANNED_AWAITING_USER_APPROVAL" \
  "ActiveImplementationTaskCard = NONE" \
  "ReleasedTaskCard = NONE" \
  "DocumentationGap = DOC-GAP-MDR-001" \
  "ReadyTaskCardCount = 0"; do
  [[ "${canonical_output}" == *"${expected_line}"* ]] ||
    fail "canonical output is missing: ${expected_line}"
done

second_status_dir="${test_tmp_root}/second-status"
cp -R "${cards_dir}" "${second_status_dir}"
sed -i.bak 's/^Status = BLOCKED_BY_USER_APPROVAL$/Status = READY/' \
  "${second_status_dir}/MDR-I00-web-test-foundation.md"
rm "${second_status_dir}/MDR-I00-web-test-foundation.md.bak"
expect_failure "${second_status_dir}" "all cards must remain BLOCKED_BY_USER_APPROVAL before written approval"

active_card_dir="${test_tmp_root}/active-card"
cp -R "${cards_dir}" "${active_card_dir}"
sed -i.bak \
  's/^ActiveImplementationTaskCard = NONE$/ActiveImplementationTaskCard = MDR-I00/' \
  "${active_card_dir}/README.md"
rm "${active_card_dir}/README.md.bak"
expect_failure "${active_card_dir}" "ActiveImplementationTaskCard must be NONE before written approval"

released_card_dir="${test_tmp_root}/released-card"
cp -R "${cards_dir}" "${released_card_dir}"
sed -i.bak 's/^ReleasedTaskCard = NONE$/ReleasedTaskCard = MDR-I00/' \
  "${released_card_dir}/README.md"
rm "${released_card_dir}/README.md.bak"
expect_failure "${released_card_dir}" "ReleasedTaskCard must be NONE before written approval"

missing_gap_dir="${test_tmp_root}/missing-gap"
cp -R "${cards_dir}" "${missing_gap_dir}"
sed -i.bak '/^DocumentationGap = DOC-GAP-MDR-001$/d' "${missing_gap_dir}/README.md"
rm "${missing_gap_dir}/README.md.bak"
expect_failure "${missing_gap_dir}" "missing required field: DocumentationGap"

missing_toolchain_owner_dir="${test_tmp_root}/missing-toolchain-owner"
cp -R "${cards_dir}" "${missing_toolchain_owner_dir}"
sed -i.bak '/^WriteSet = docs\/engineering\/cognitura-technology-baseline[.]md$/d' \
  "${missing_toolchain_owner_dir}/MDR-I00-web-test-foundation.md"
rm "${missing_toolchain_owner_dir}/MDR-I00-web-test-foundation.md.bak"
expect_failure \
  "${missing_toolchain_owner_dir}" \
  "WriteSet mismatch for MDR-I00"

missing_test_strategy_owner_dir="${test_tmp_root}/missing-test-strategy-owner"
cp -R "${cards_dir}" "${missing_test_strategy_owner_dir}"
sed -i.bak '/^WriteSet = docs\/engineering\/cognitura-test-strategy[.]md$/d' \
  "${missing_test_strategy_owner_dir}/MDR-I00-web-test-foundation.md"
rm "${missing_test_strategy_owner_dir}/MDR-I00-web-test-foundation.md.bak"
expect_failure \
  "${missing_test_strategy_owner_dir}" \
  "WriteSet mismatch for MDR-I00"

schema_leak_dir="${test_tmp_root}/schema-leak"
cp -R "${cards_dir}" "${schema_leak_dir}"
sed -i.bak '/^## 4[.] RED -> GREEN$/i\
WriteSet = schemas/cognition/cognitive-module.schema.json\
' "${schema_leak_dir}/MDR-I01-canonical-narrative-projection.md"
rm "${schema_leak_dir}/MDR-I01-canonical-narrative-projection.md.bak"
expect_failure "${schema_leak_dir}" "WriteSet mismatch for MDR-I01"

database_leak_dir="${test_tmp_root}/database-leak"
cp -R "${cards_dir}" "${database_leak_dir}"
sed -i.bak '/^## 4[.] RED -> GREEN$/i\
WriteSet = server/src/main/resources/db/migration/V1__module.sql\
' "${database_leak_dir}/MDR-I02-question-conclusion-spine.md"
rm "${database_leak_dir}/MDR-I02-question-conclusion-spine.md.bak"
expect_failure "${database_leak_dir}" "WriteSet mismatch for MDR-I02"

wrong_review_route_dir="${test_tmp_root}/wrong-review-route"
cp -R "${cards_dir}" "${wrong_review_route_dir}"
sed -i.bak 's/^ReviewRoute = deep_reviewer$/ReviewRoute = ultra_gatekeeper/' \
  "${wrong_review_route_dir}/MDR-I07-reading-first-composition.md"
rm "${wrong_review_route_dir}/MDR-I07-reading-first-composition.md.bak"
expect_failure "${wrong_review_route_dir}" "invalid ReviewRoute for MDR-I07"

missing_final_dependency_dir="${test_tmp_root}/missing-final-dependency"
cp -R "${cards_dir}" "${missing_final_dependency_dir}"
sed -i.bak 's/^DependsOn = MDR-I00,MDR-I01,MDR-I02,MDR-I03,MDR-I04,MDR-I05,MDR-I06,MDR-I07$/DependsOn = MDR-I00,MDR-I01,MDR-I02,MDR-I03,MDR-I04,MDR-I05,MDR-I06/' \
  "${missing_final_dependency_dir}/MDR-I08-fixed-slice-review.md"
rm "${missing_final_dependency_dir}/MDR-I08-fixed-slice-review.md.bak"
expect_failure "${missing_final_dependency_dir}" "dependency mismatch for MDR-I08"

unknown_dependency_dir="${test_tmp_root}/unknown-dependency"
cp -R "${cards_dir}" "${unknown_dependency_dir}"
sed -i.bak 's/^DependsOn = MDR-I02$/DependsOn = MDR-I99/' \
  "${unknown_dependency_dir}/MDR-I03-element-boundary-reading.md"
rm "${unknown_dependency_dir}/MDR-I03-element-boundary-reading.md.bak"
expect_failure "${unknown_dependency_dir}" "dependency mismatch for MDR-I03"

missing_red_green_dir="${test_tmp_root}/missing-red-green"
cp -R "${cards_dir}" "${missing_red_green_dir}"
sed -i.bak 's/^## 4[.] RED -> GREEN$/## 4. 执行步骤/' \
  "${missing_red_green_dir}/MDR-I04-stage-chain-renderer-projection.md"
rm "${missing_red_green_dir}/MDR-I04-stage-chain-renderer-projection.md.bak"
expect_failure "${missing_red_green_dir}" "missing required section: ## 4. RED -> GREEN"

app_write_leak_dir="${test_tmp_root}/app-write-leak"
cp -R "${cards_dir}" "${app_write_leak_dir}"
sed -i.bak \
  's#^WriteSet = web/src/modules/module-reading/projectModuleNarrative.ts$#WriteSet = web/src/App.tsx#' \
  "${app_write_leak_dir}/MDR-I01-canonical-narrative-projection.md"
rm "${app_write_leak_dir}/MDR-I01-canonical-narrative-projection.md.bak"
expect_failure "${app_write_leak_dir}" "WriteSet mismatch for MDR-I01"

schema_design_leak_dir="${test_tmp_root}/schema-design-leak"
cp -R "${cards_dir}" "${schema_design_leak_dir}"
sed -i.bak '/^## 4[.] RED -> GREEN$/i\
WriteSet = docs/design/cognitura-schema-baseline-2.0.md\
' "${schema_design_leak_dir}/MDR-I01-canonical-narrative-projection.md"
rm "${schema_design_leak_dir}/MDR-I01-canonical-narrative-projection.md.bak"
expect_failure "${schema_design_leak_dir}" "WriteSet mismatch for MDR-I01"

authorization_drift_dir="${test_tmp_root}/authorization-drift"
cp -R "${cards_dir}" "${authorization_drift_dir}"
sed -i.bak \
  's/^BusinessImplementationAuthorization = REQUIRED_BEFORE_RELEASE$/BusinessImplementationAuthorization = AUTHORIZED/' \
  "${authorization_drift_dir}/MDR-I01-canonical-narrative-projection.md"
rm "${authorization_drift_dir}/MDR-I01-canonical-narrative-projection.md.bak"
expect_failure \
  "${authorization_drift_dir}" \
  "BusinessImplementationAuthorization mismatch for MDR-I01"

production_limit_drift_dir="${test_tmp_root}/production-limit-drift"
cp -R "${cards_dir}" "${production_limit_drift_dir}"
sed -i.bak 's/^ProductionFileLimit = 2$/ProductionFileLimit = 99/' \
  "${production_limit_drift_dir}/MDR-I01-canonical-narrative-projection.md"
rm "${production_limit_drift_dir}/MDR-I01-canonical-narrative-projection.md.bak"
expect_failure \
  "${production_limit_drift_dir}" \
  "ProductionFileLimit mismatch for MDR-I01"

remote_push_command_dir="${test_tmp_root}/remote-push-command"
cp -R "${cards_dir}" "${remote_push_command_dir}"
sed -i.bak '/^git commit -m /a\
git push origin HEAD\
' "${remote_push_command_dir}/MDR-I01-canonical-narrative-projection.md"
rm "${remote_push_command_dir}/MDR-I01-canonical-narrative-projection.md.bak"
expect_failure "${remote_push_command_dir}" "remote push command is forbidden"

missing_unified_entry_dir="${test_tmp_root}/missing-unified-entry"
cp -R "${cards_dir}" "${missing_unified_entry_dir}"
sed -i.bak '/^WriteSet = scripts\/verify-module-default-reading$/d' \
  "${missing_unified_entry_dir}/MDR-I00-web-test-foundation.md"
rm "${missing_unified_entry_dir}/MDR-I00-web-test-foundation.md.bak"
expect_failure "${missing_unified_entry_dir}" "WriteSet mismatch for MDR-I00"

missing_ci_workflow_dir="${test_tmp_root}/missing-ci-workflow"
cp -R "${cards_dir}" "${missing_ci_workflow_dir}"
sed -i.bak '/^WriteSet = [.]github\/workflows\/wave0[.]yml$/d' \
  "${missing_ci_workflow_dir}/MDR-I00-web-test-foundation.md"
rm "${missing_ci_workflow_dir}/MDR-I00-web-test-foundation.md.bak"
expect_failure "${missing_ci_workflow_dir}" "WriteSet mismatch for MDR-I00"

missing_ci_contract_dir="${test_tmp_root}/missing-ci-contract"
cp -R "${cards_dir}" "${missing_ci_contract_dir}"
sed -i.bak '/^WriteSet = tests\/ci\/verify-ci-contract[.]sh$/d' \
  "${missing_ci_contract_dir}/MDR-I00-web-test-foundation.md"
rm "${missing_ci_contract_dir}/MDR-I00-web-test-foundation.md.bak"
expect_failure "${missing_ci_contract_dir}" "WriteSet mismatch for MDR-I00"

commit_write_set_drift_dir="${test_tmp_root}/commit-write-set-drift"
cp -R "${cards_dir}" "${commit_write_set_drift_dir}"
sed -i.bak \
  's#^  web/src/modules/module-reading/projectModuleNarrative.ts \\$#  web/src/App.tsx \\#' \
  "${commit_write_set_drift_dir}/MDR-I01-canonical-narrative-projection.md"
rm "${commit_write_set_drift_dir}/MDR-I01-canonical-narrative-projection.md.bak"
expect_failure "${commit_write_set_drift_dir}" "commit WriteSet mismatch for MDR-I01"

relation_projection_drift_dir="${test_tmp_root}/relation-projection-drift"
cp -R "${cards_dir}" "${relation_projection_drift_dir}"
sed -i.bak '/^RelationDisplay = CANONICAL_TYPE_TOKEN$/d' \
  "${relation_projection_drift_dir}/MDR-I05-key-relation-projection.md"
rm "${relation_projection_drift_dir}/MDR-I05-key-relation-projection.md.bak"
expect_failure \
  "${relation_projection_drift_dir}" \
  "MDR-I05 must project the canonical RelationType token without invented semantics"

composition_assertion_drift_dir="${test_tmp_root}/composition-assertion-drift"
cp -R "${cards_dir}" "${composition_assertion_drift_dir}"
sed -i.bak '/^CompositionAssertion = EXACT_SCOPED_IDENTITY_COUNT_CONTENT_ORDER$/d' \
  "${composition_assertion_drift_dir}/MDR-I07-reading-first-composition.md"
rm "${composition_assertion_drift_dir}/MDR-I07-reading-first-composition.md.bak"
expect_failure \
  "${composition_assertion_drift_dir}" \
  "MDR-I07 must assert exact scoped identity, count, content, and order"

printf '%s\n' \
  "ModuleDefaultReadingTaskCardContractTests = PASS" \
  "NegativeCases = 22" \
  "PreApprovalTerminalCases = 1"
