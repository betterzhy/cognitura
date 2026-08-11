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

negative_cases=0

expect_failure_with_verifier() {
  local fixture_verifier="$1"
  local fixture_dir="$2"
  local expected_message="$3"
  local output

  if output="$("${fixture_verifier}" --cards-dir "${fixture_dir}" 2>&1)"; then
    fail "invalid fixture unexpectedly passed: ${fixture_dir}"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected error '${expected_message}', got: ${output}"
  negative_cases=$((negative_cases + 1))
}

expect_failure() {
  local fixture_dir="$1"
  local expected_message="$2"
  expect_failure_with_verifier "${verifier}" "${fixture_dir}" "${expected_message}"
}

set_state_field() {
  local state_file="$1"
  local field="$2"
  local value="$3"
  sed -i.bak "s#^${field} = .*\$#${field} = ${value}#" "${state_file}"
  rm "${state_file}.bak"
}

state_field_value() {
  local state_file="$1"
  local field="$2"
  sed -n "s/^${field} = //p" "${state_file}"
}

make_pending_governance_state() {
  local fixture_dir="$1"
  local state_file="${fixture_dir}/execution-state.md"

  set_state_field "${state_file}" "GovernanceBootstrapStatus" "AWAITING_FIXED_COMMIT_REVIEW"
  set_state_field "${state_file}" "GovernanceReviewedCandidateSHA" "NONE"
  set_state_field "${state_file}" "GovernanceReviewVerdict" "NOT_RUN"
  set_state_field "${state_file}" "SetAuthorizationStatus" "USER_AUTHORIZED_AWAITING_GOVERNANCE_BOOTSTRAP"
  set_state_field "${state_file}" "TaskCardSetStatus" "USER_AUTHORIZED_AWAITING_GOVERNANCE_REVIEW"
  set_state_field "${state_file}" "ActiveImplementationTaskCard" "NONE"
  set_state_field "${state_file}" "ReleasedTaskCard" "NONE"
  set_state_field "${state_file}" "CompletedTaskCards" "NONE"
  set_state_field "${state_file}" "CurrentCandidateSHA" "NONE"
  set_state_field "${state_file}" "CurrentGateStatus" "NOT_RUN"
  set_state_field "${state_file}" "CurrentReviewRoute" "NONE"
  set_state_field "${state_file}" "CurrentReviewVerdict" "NOT_RUN"
  set_state_field "${state_file}" "NextImplementationTaskCard" "MDR-I00"
  set_state_field "${state_file}" "TransitionSequence" "0"
  set_state_field "${state_file}" "TransitionKind" "BOOTSTRAP"
  set_state_field "${state_file}" "TransitionBaseSHA" "NONE"
  set_state_field "${state_file}" "BusinessImplementation" "NOT_AUTHORIZED"
}

make_activation_state() {
  local fixture_dir="$1"
  local state_file="${fixture_dir}/execution-state.md"
  local governance_sha="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

  set_state_field "${state_file}" "GovernanceBootstrapStatus" "PASS"
  set_state_field "${state_file}" "GovernanceReviewedCandidateSHA" "${governance_sha}"
  set_state_field "${state_file}" "GovernanceReviewVerdict" "GO_P0_0_P1_0_P2_0"
  set_state_field "${state_file}" "SetAuthorizationStatus" "USER_AUTHORIZED"
  set_state_field "${state_file}" "TaskCardSetStatus" "IN_PROGRESS"
  set_state_field "${state_file}" "ActiveImplementationTaskCard" "MDR-I00"
  set_state_field "${state_file}" "ReleasedTaskCard" "MDR-I00"
  set_state_field "${state_file}" "NextImplementationTaskCard" "MDR-I00"
  set_state_field "${state_file}" "TransitionSequence" "1"
  set_state_field "${state_file}" "TransitionKind" "ACTIVATE_SET"
  set_state_field "${state_file}" "TransitionBaseSHA" "${governance_sha}"
  set_state_field "${state_file}" "BusinessImplementation" "AUTHORIZED_FOR_MDR_I00_I08"
}

make_i00_advance_state() {
  local fixture_dir="$1"
  local state_file="${fixture_dir}/execution-state.md"
  local candidate_sha="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

  make_activation_state "${fixture_dir}"
  set_state_field "${state_file}" "CompletedTaskCards" "MDR-I00"
  set_state_field "${state_file}" "CurrentCandidateSHA" "${candidate_sha}"
  set_state_field "${state_file}" "CurrentGateStatus" "PASS"
  set_state_field "${state_file}" "CurrentReviewRoute" "deep_reviewer"
  set_state_field "${state_file}" "CurrentReviewVerdict" "GO_P0_0_P1_0_P2_0"
  set_state_field "${state_file}" "ActiveImplementationTaskCard" "MDR-I01"
  set_state_field "${state_file}" "ReleasedTaskCard" "MDR-I01"
  set_state_field "${state_file}" "NextImplementationTaskCard" "MDR-I01"
  set_state_field "${state_file}" "TransitionSequence" "2"
  set_state_field "${state_file}" "TransitionKind" "ADVANCE"
  set_state_field "${state_file}" "TransitionBaseSHA" "${candidate_sha}"
}

make_stopped_state() {
  local fixture_dir="$1"
  local transition_base_sha="${2:-dddddddddddddddddddddddddddddddddddddddd}"
  local state_file="${fixture_dir}/execution-state.md"

  make_activation_state "${fixture_dir}"
  set_state_field "${state_file}" "TaskCardSetStatus" "STOPPED_BY_USER"
  set_state_field "${state_file}" "ActiveImplementationTaskCard" "NONE"
  set_state_field "${state_file}" "ReleasedTaskCard" "NONE"
  set_state_field "${state_file}" "TransitionKind" "STOP"
  set_state_field "${state_file}" "TransitionBaseSHA" "${transition_base_sha}"
}

make_repo_fixture() {
  local fixture_root="$1"
  mkdir -p \
    "${fixture_root}/scripts" \
    "${fixture_root}/docs/engineering" \
    "${fixture_root}/docs/task-cards"
  cp "${verifier}" "${fixture_root}/scripts/verify-module-default-reading-implementation-cards"
  chmod +x "${fixture_root}/scripts/verify-module-default-reading-implementation-cards"
  cp "${repo_root}/AGENTS.md" "${fixture_root}/AGENTS.md"
  cp "${repo_root}/README.md" "${fixture_root}/README.md"
  cp "${repo_root}/docs/engineering/cognitura-design-index.md" \
    "${fixture_root}/docs/engineering/cognitura-design-index.md"
  cp "${repo_root}/docs/task-cards/README.md" "${fixture_root}/docs/task-cards/README.md"
  cp -R "${cards_dir}" \
    "${fixture_root}/docs/task-cards/module-default-reading-implementation"
}

[[ -x "${verifier}" ]] || fail "ModuleDefaultReading task-card verifier is missing or not executable"
[[ -d "${cards_dir}" ]] || fail "ModuleDefaultReading task-card directory is missing"

canonical_output="$("${verifier}" --cards-dir "${cards_dir}")" ||
  fail "canonical ModuleDefaultReading task cards were rejected"
for expected_line in \
  "ModuleDefaultReadingTaskCardValidation = PASS" \
  "TaskCardCount = 9" \
  "ExecutionStateAuthority = docs/task-cards/module-default-reading-implementation/execution-state.md"; do
  [[ "${canonical_output}" == *"${expected_line}"* ]] ||
    fail "canonical output is missing: ${expected_line}"
done
for state_field in \
  GovernanceBootstrapStatus \
  SetAuthorizationStatus \
  TaskCardSetStatus \
  ActiveImplementationTaskCard \
  ReleasedTaskCard \
  CompletedTaskCards \
  NextImplementationTaskCard \
  BusinessImplementation \
  FormalDatabaseWrite \
  RemotePush; do
  expected_line="${state_field} = $(state_field_value "${cards_dir}/execution-state.md" "${state_field}")"
  [[ "${canonical_output}" == *"${expected_line}"* ]] ||
    fail "canonical output is missing current ledger value: ${expected_line}"
done
canonical_task_set_status="$(state_field_value "${cards_dir}/execution-state.md" "TaskCardSetStatus")"
canonical_ready_count="0"
if [[ "${canonical_task_set_status}" == "IN_PROGRESS" ]]; then
  canonical_ready_count="1"
fi
[[ "${canonical_output}" == *"ReadyTaskCardCount = ${canonical_ready_count}"* ]] ||
  fail "canonical output has the wrong derived ReadyTaskCardCount"

pending_cards_dir="${test_tmp_root}/canonical-pending-governance"
cp -R "${cards_dir}" "${pending_cards_dir}"
make_pending_governance_state "${pending_cards_dir}"
pending_output="$("${verifier}" --cards-dir "${pending_cards_dir}")" ||
  fail "valid pending-governance terminal state was rejected"
for expected_line in \
  "GovernanceBootstrapStatus = AWAITING_FIXED_COMMIT_REVIEW" \
  "SetAuthorizationStatus = USER_AUTHORIZED_AWAITING_GOVERNANCE_BOOTSTRAP" \
  "TaskCardSetStatus = USER_AUTHORIZED_AWAITING_GOVERNANCE_REVIEW" \
  "ActiveImplementationTaskCard = NONE" \
  "ReleasedTaskCard = NONE" \
  "CompletedTaskCards = NONE" \
  "NextImplementationTaskCard = MDR-I00" \
  "ReadyTaskCardCount = 0"; do
  [[ "${pending_output}" == *"${expected_line}"* ]] ||
    fail "pending-governance output is missing: ${expected_line}"
done
cards_dir="${pending_cards_dir}"

second_status_dir="${test_tmp_root}/second-status"
cp -R "${cards_dir}" "${second_status_dir}"
sed -i.bak \
  's/^Status = GOVERNED_BY_EXECUTION_STATE$/Status = READY/' \
  "${second_status_dir}/MDR-I00-web-test-foundation.md"
rm "${second_status_dir}/MDR-I00-web-test-foundation.md.bak"
expect_failure \
  "${second_status_dir}" \
  "Status must be GOVERNED_BY_EXECUTION_STATE"

active_card_dir="${test_tmp_root}/active-card"
cp -R "${cards_dir}" "${active_card_dir}"
sed -i.bak \
  's/^ActiveImplementationTaskCard = NONE$/ActiveImplementationTaskCard = MDR-I00/' \
  "${active_card_dir}/execution-state.md"
rm "${active_card_dir}/execution-state.md.bak"
expect_failure \
  "${active_card_dir}" \
  "bootstrap pending state cannot release a card"

released_card_dir="${test_tmp_root}/released-card"
cp -R "${cards_dir}" "${released_card_dir}"
sed -i.bak 's/^ReleasedTaskCard = NONE$/ReleasedTaskCard = MDR-I00/' \
  "${released_card_dir}/execution-state.md"
rm "${released_card_dir}/execution-state.md.bak"
expect_failure \
  "${released_card_dir}" \
  "bootstrap pending state cannot release a card"

missing_gap_dir="${test_tmp_root}/missing-gap"
cp -R "${cards_dir}" "${missing_gap_dir}"
sed -i.bak '/^DocumentationGap = DOC-GAP-MDR-001$/d' "${missing_gap_dir}/README.md"
rm "${missing_gap_dir}/README.md.bak"
expect_failure "${missing_gap_dir}" "missing required field: DocumentationGap"

stale_set_approval_dir="${test_tmp_root}/stale-set-approval"
cp -R "${cards_dir}" "${stale_set_approval_dir}"
sed -i.bak \
  's/^TaskCardSetStatus = USER_AUTHORIZED_AWAITING_GOVERNANCE_REVIEW$/TaskCardSetStatus = PLANNED_AWAITING_USER_APPROVAL/' \
  "${stale_set_approval_dir}/execution-state.md"
rm "${stale_set_approval_dir}/execution-state.md.bak"
expect_failure \
  "${stale_set_approval_dir}" \
  "unsupported TaskCardSetStatus"

stale_written_review_dir="${test_tmp_root}/stale-written-review"
cp -R "${cards_dir}" "${stale_written_review_dir}"
sed -i.bak \
  's/^WrittenTaskCardReview = USER_APPROVED$/WrittenTaskCardReview = AWAITING_USER_APPROVAL/' \
  "${stale_written_review_dir}/README.md"
rm "${stale_written_review_dir}/README.md.bak"
expect_failure \
  "${stale_written_review_dir}" \
  "WrittenTaskCardReview must remain USER_APPROVED"

release_gate_drift_dir="${test_tmp_root}/release-gate-drift"
cp -R "${cards_dir}" "${release_gate_drift_dir}"
sed -i.bak 's/^TaskCardRelease = GOVERNED_BY_EXECUTION_STATE$/TaskCardRelease = ALLOWED/' \
  "${release_gate_drift_dir}/README.md"
rm "${release_gate_drift_dir}/README.md.bak"
expect_failure \
  "${release_gate_drift_dir}" \
  "TaskCardRelease must reference execution-state authority"

execution_gate_drift_dir="${test_tmp_root}/execution-gate-drift"
cp -R "${cards_dir}" "${execution_gate_drift_dir}"
sed -i.bak 's/^TaskCardExecution = GOVERNED_BY_EXECUTION_STATE$/TaskCardExecution = ALLOWED/' \
  "${execution_gate_drift_dir}/README.md"
rm "${execution_gate_drift_dir}/README.md.bak"
expect_failure \
  "${execution_gate_drift_dir}" \
  "TaskCardExecution must reference execution-state authority"

index_table_status_drift_dir="${test_tmp_root}/index-table-status-drift"
cp -R "${cards_dir}" "${index_table_status_drift_dir}"
sed -i.bak \
  's/| `MDR-I00` | \([^|]*\) | `GOVERNED_BY_EXECUTION_STATE` |/| `MDR-I00` | \1 | `BLOCKED_BY_USER_APPROVAL` |/' \
  "${index_table_status_drift_dir}/README.md"
rm "${index_table_status_drift_dir}/README.md.bak"
expect_failure \
  "${index_table_status_drift_dir}" \
  "README.md task-card table status mismatch for MDR-I00"

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
expect_failure "${remote_push_command_dir}" "amend or remote push command is forbidden"

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

renderer_input_assertion_drift_dir="${test_tmp_root}/renderer-input-assertion-drift"
cp -R "${cards_dir}" "${renderer_input_assertion_drift_dir}"
sed -i.bak '/^RendererInputAssertion = SAME_INPUT_IDENTITY_TYPE_ENDPOINTS$/d' \
  "${renderer_input_assertion_drift_dir}/MDR-I05-key-relation-projection.md"
rm "${renderer_input_assertion_drift_dir}/MDR-I05-key-relation-projection.md.bak"
expect_failure \
  "${renderer_input_assertion_drift_dir}" \
  "MDR-I05 must assert identity, type, and endpoints from the same RendererInput"

composition_order_drift_dir="${test_tmp_root}/composition-order-drift"
cp -R "${cards_dir}" "${composition_order_drift_dir}"
sed -i.bak \
  '/^CompositionOrder = CORE_THESIS_SPINE_RENDERER_BOUNDARIES_ELEMENTS_RELATIONS_SOURCES$/d' \
  "${composition_order_drift_dir}/MDR-I07-reading-first-composition.md"
rm "${composition_order_drift_dir}/MDR-I07-reading-first-composition.md.bak"
expect_failure \
  "${composition_order_drift_dir}" \
  "MDR-I07 must retain the formal ModuleReading projection order"

composition_section_identity_drift_dir="${test_tmp_root}/composition-section-identity-drift"
cp -R "${cards_dir}" "${composition_section_identity_drift_dir}"
sed -i.bak \
  's/^CompositionSectionIdentities = CORE_QUESTIONS_CORE_CONCLUSION_PRIMARY_SPINE_STAGE_CHAIN_BOUNDARIES_ELEMENTS_RELATIONS_SOURCE_ENTRY$/CompositionSectionIdentities = QUESTIONS_CONCLUSION_SPINE_STAGE_CHAIN_BOUNDARIES_ELEMENTS_RELATIONS_SOURCE_ENTRY/' \
  "${composition_section_identity_drift_dir}/MDR-I07-reading-first-composition.md"
rm "${composition_section_identity_drift_dir}/MDR-I07-reading-first-composition.md.bak"
expect_failure \
  "${composition_section_identity_drift_dir}" \
  "MDR-I07 section identities must match the fixed predecessor component contracts"

missing_state_dir="${test_tmp_root}/missing-execution-state"
cp -R "${cards_dir}" "${missing_state_dir}"
rm "${missing_state_dir}/execution-state.md"
expect_failure "${missing_state_dir}" "execution-state authority is missing"

duplicate_central_state_root="${test_tmp_root}/duplicate-central-state-root"
make_repo_fixture "${duplicate_central_state_root}"
sed -i.bak \
  's/^ModuleDefaultReadingActiveImplementationTaskCard = SEE_MODULE_DEFAULT_READING_EXECUTION_STATE$/ModuleDefaultReadingActiveImplementationTaskCard = MDR-I00/' \
  "${duplicate_central_state_root}/AGENTS.md"
rm "${duplicate_central_state_root}/AGENTS.md.bak"
expect_failure_with_verifier \
  "${duplicate_central_state_root}/scripts/verify-module-default-reading-implementation-cards" \
  "${duplicate_central_state_root}/docs/task-cards/module-default-reading-implementation" \
  "AGENTS.md: ModuleDefaultReadingActiveImplementationTaskCard must reference execution-state authority"

legacy_compatible_root="${test_tmp_root}/legacy-compatible-root"
make_repo_fixture "${legacy_compatible_root}"
"${legacy_compatible_root}/scripts/verify-module-default-reading-implementation-cards" \
  --cards-dir \
  "${legacy_compatible_root}/docs/task-cards/module-default-reading-implementation" >/dev/null ||
  fail "legacy visual terminal fields plus MDR namespaced authority pointers were rejected"

activation_dir="${test_tmp_root}/valid-activation"
cp -R "${cards_dir}" "${activation_dir}"
make_activation_state "${activation_dir}"
activation_output="$("${verifier}" --cards-dir "${activation_dir}")" ||
  fail "valid MDR-I00 activation state was rejected"
[[ "${activation_output}" == *"ActiveImplementationTaskCard = MDR-I00"* ]] ||
  fail "valid activation output did not expose MDR-I00"
[[ "${activation_output}" == *"ReadyTaskCardCount = 1"* ]] ||
  fail "valid activation output did not expose exactly one ready card"

missing_set_authorization_dir="${test_tmp_root}/missing-set-authorization"
cp -R "${activation_dir}" "${missing_set_authorization_dir}"
set_state_field \
  "${missing_set_authorization_dir}/execution-state.md" \
  "SetAuthorizationStatus" \
  "USER_AUTHORIZED_AWAITING_GOVERNANCE_BOOTSTRAP"
expect_failure "${missing_set_authorization_dir}" "set authorization is required before activation"

missing_bootstrap_review_dir="${test_tmp_root}/missing-bootstrap-review"
cp -R "${activation_dir}" "${missing_bootstrap_review_dir}"
set_state_field \
  "${missing_bootstrap_review_dir}/execution-state.md" \
  "GovernanceReviewVerdict" \
  "NOT_RUN"
expect_failure "${missing_bootstrap_review_dir}" "governance review must be zero-finding GO"

invalid_bootstrap_sha_dir="${test_tmp_root}/invalid-bootstrap-sha"
cp -R "${activation_dir}" "${invalid_bootstrap_sha_dir}"
set_state_field \
  "${invalid_bootstrap_sha_dir}/execution-state.md" \
  "GovernanceReviewedCandidateSHA" \
  "abc123"
expect_failure \
  "${invalid_bootstrap_sha_dir}" \
  "governance reviewed candidate must be a 40-character SHA"

second_active_dir="${test_tmp_root}/second-active"
cp -R "${activation_dir}" "${second_active_dir}"
set_state_field "${second_active_dir}/execution-state.md" "ReleasedTaskCard" "MDR-I01"
expect_failure \
  "${second_active_dir}" \
  "in-progress state must have exactly one identical active and released card"

advance_dir="${test_tmp_root}/valid-i00-advance"
cp -R "${cards_dir}" "${advance_dir}"
make_i00_advance_state "${advance_dir}"
advance_output="$("${verifier}" --cards-dir "${advance_dir}")" ||
  fail "valid MDR-I00 advance state was rejected"
[[ "${advance_output}" == *"ActiveImplementationTaskCard = MDR-I01"* ]] ||
  fail "valid advance output did not expose MDR-I01"

skipped_prefix_dir="${test_tmp_root}/skipped-prefix"
cp -R "${advance_dir}" "${skipped_prefix_dir}"
set_state_field \
  "${skipped_prefix_dir}/execution-state.md" \
  "CompletedTaskCards" \
  "MDR-I01"
expect_failure "${skipped_prefix_dir}" "CompletedTaskCards must be a strict MDR prefix"

review_finding_advance_dir="${test_tmp_root}/review-finding-advance"
cp -R "${advance_dir}" "${review_finding_advance_dir}"
set_state_field \
  "${review_finding_advance_dir}/execution-state.md" \
  "CurrentReviewVerdict" \
  "NO_GO_P1_1"
expect_failure \
  "${review_finding_advance_dir}" \
  "advance requires zero-finding review GO"

receipt_sha_mismatch_dir="${test_tmp_root}/receipt-sha-mismatch"
cp -R "${advance_dir}" "${receipt_sha_mismatch_dir}"
set_state_field \
  "${receipt_sha_mismatch_dir}/execution-state.md" \
  "TransitionBaseSHA" \
  "cccccccccccccccccccccccccccccccccccccccc"
expect_failure \
  "${receipt_sha_mismatch_dir}" \
  "review receipt candidate SHA must match TransitionBaseSHA"

push_in_state_dir="${test_tmp_root}/push-in-state"
cp -R "${cards_dir}" "${push_in_state_dir}"
printf '%s\n' 'git push origin HEAD' >> "${push_in_state_dir}/execution-state.md"
expect_failure "${push_in_state_dir}" "amend or remote push is forbidden"

forbidden_transition_path_dir="${test_tmp_root}/forbidden-transition-path"
cp -R "${cards_dir}" "${forbidden_transition_path_dir}"
printf '%s\n' \
  'TransitionWritePath = server/src/main/java/io/cognitura/Forbidden.java' >> \
  "${forbidden_transition_path_dir}/execution-state.md"
expect_failure \
  "${forbidden_transition_path_dir}" \
  "transition WriteSet must contain only execution-state.md"

stopped_active_dir="${test_tmp_root}/stopped-active"
cp -R "${activation_dir}" "${stopped_active_dir}"
set_state_field "${stopped_active_dir}/execution-state.md" "TaskCardSetStatus" "STOPPED_BY_USER"
expect_failure \
  "${stopped_active_dir}" \
  "blocked or stopped state cannot retain an active card"

valid_stopped_dir="${test_tmp_root}/valid-stopped"
cp -R "${cards_dir}" "${valid_stopped_dir}"
make_stopped_state "${valid_stopped_dir}"
"${verifier}" --cards-dir "${valid_stopped_dir}" >/dev/null ||
  fail "valid stopped recovery state was rejected"

valid_documentation_gap_dir="${test_tmp_root}/valid-documentation-gap"
cp -R "${valid_stopped_dir}" "${valid_documentation_gap_dir}"
set_state_field "${valid_documentation_gap_dir}/execution-state.md" "TaskCardSetStatus" "BLOCKED_BY_DOCUMENTATION_GAP"
set_state_field "${valid_documentation_gap_dir}/execution-state.md" "TransitionKind" "BLOCK_DOCUMENTATION_GAP"
"${verifier}" --cards-dir "${valid_documentation_gap_dir}" >/dev/null ||
  fail "valid documentation-gap recovery state was rejected"

valid_documentation_gap_resume_dir="${test_tmp_root}/valid-documentation-gap-resume"
cp -R "${valid_documentation_gap_dir}" "${valid_documentation_gap_resume_dir}"
set_state_field \
  "${valid_documentation_gap_resume_dir}/execution-state.md" \
  "TaskCardSetStatus" \
  "IN_PROGRESS"
set_state_field \
  "${valid_documentation_gap_resume_dir}/execution-state.md" \
  "ActiveImplementationTaskCard" \
  "MDR-I00"
set_state_field \
  "${valid_documentation_gap_resume_dir}/execution-state.md" \
  "ReleasedTaskCard" \
  "MDR-I00"
set_state_field \
  "${valid_documentation_gap_resume_dir}/execution-state.md" \
  "TransitionKind" \
  "RESUME_DOCUMENTATION_GAP"
set_state_field \
  "${valid_documentation_gap_resume_dir}/execution-state.md" \
  "TransitionBaseSHA" \
  "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
resume_output="$(${verifier} --cards-dir "${valid_documentation_gap_resume_dir}")" ||
  fail "valid documentation-gap resume state was rejected"
[[ "${resume_output}" == *"ActiveImplementationTaskCard = MDR-I00"* ]] ||
  fail "valid documentation-gap resume output did not restore MDR-I00"
[[ "${resume_output}" == *"ReadyTaskCardCount = 1"* ]] ||
  fail "valid documentation-gap resume output did not expose exactly one ready card"

valid_authority_block_dir="${test_tmp_root}/valid-authority-block"
cp -R "${valid_stopped_dir}" "${valid_authority_block_dir}"
set_state_field "${valid_authority_block_dir}/execution-state.md" "TaskCardSetStatus" "BLOCKED_BY_AUTHORITY_EXPANSION"
set_state_field "${valid_authority_block_dir}/execution-state.md" "TransitionKind" "BLOCK_AUTHORITY_EXPANSION"
"${verifier}" --cards-dir "${valid_authority_block_dir}" >/dev/null ||
  fail "valid authority-expansion recovery state was rejected"

stopped_downstream_next_dir="${test_tmp_root}/stopped-downstream-next"
cp -R "${valid_stopped_dir}" "${stopped_downstream_next_dir}"
set_state_field \
  "${stopped_downstream_next_dir}/execution-state.md" \
  "CompletedTaskCards" \
  "MDR-I00,MDR-I01,MDR-I02,MDR-I03,MDR-I04,MDR-I05,MDR-I06,MDR-I07,MDR-I08"
set_state_field \
  "${stopped_downstream_next_dir}/execution-state.md" \
  "NextImplementationTaskCard" \
  "W1-I00"
expect_failure \
  "${stopped_downstream_next_dir}" \
  "blocked or stopped state must retain the exact recoverable MDR card"

stopped_metadata_drift_dir="${test_tmp_root}/stopped-metadata-drift"
cp -R "${valid_stopped_dir}" "${stopped_metadata_drift_dir}"
set_state_field \
  "${stopped_metadata_drift_dir}/execution-state.md" \
  "TransitionKind" \
  "ADVANCE"
expect_failure \
  "${stopped_metadata_drift_dir}" \
  "stopped state transition metadata mismatch"

gap_active_dir="${test_tmp_root}/gap-active"
cp -R "${activation_dir}" "${gap_active_dir}"
set_state_field \
  "${gap_active_dir}/execution-state.md" \
  "TaskCardSetStatus" \
  "BLOCKED_BY_DOCUMENTATION_GAP"
expect_failure \
  "${gap_active_dir}" \
  "blocked or stopped state cannot retain an active card"

final_no_go_successor_dir="${test_tmp_root}/final-no-go-successor"
cp -R "${advance_dir}" "${final_no_go_successor_dir}"
set_state_field \
  "${final_no_go_successor_dir}/execution-state.md" \
  "CompletedTaskCards" \
  "MDR-I00,MDR-I01,MDR-I02,MDR-I03,MDR-I04,MDR-I05,MDR-I06,MDR-I07"
set_state_field "${final_no_go_successor_dir}/execution-state.md" "TaskCardSetStatus" "FINAL_NO_GO"
set_state_field "${final_no_go_successor_dir}/execution-state.md" "CurrentGateStatus" "NO_GO"
set_state_field "${final_no_go_successor_dir}/execution-state.md" "CurrentReviewRoute" "ultra_gatekeeper"
set_state_field "${final_no_go_successor_dir}/execution-state.md" "CurrentReviewVerdict" "NO_GO"
set_state_field "${final_no_go_successor_dir}/execution-state.md" "TransitionSequence" "10"
set_state_field "${final_no_go_successor_dir}/execution-state.md" "TransitionKind" "FINAL_NO_GO"
expect_failure \
  "${final_no_go_successor_dir}" \
  "FINAL_NO_GO cannot release a successor"

complete_downstream_release_dir="${test_tmp_root}/complete-downstream-release"
cp -R "${cards_dir}" "${complete_downstream_release_dir}"
printf '%s\n' \
  'TransitionWritePath = docs/task-cards/wave-1-implementation/W1-I00-implementation-governance.md' >> \
  "${complete_downstream_release_dir}/execution-state.md"
expect_failure \
  "${complete_downstream_release_dir}" \
  "transition WriteSet must contain only execution-state.md"

transition_repo_root="${test_tmp_root}/fixed-transition-repo"
make_repo_fixture "${transition_repo_root}"
git -C "${transition_repo_root}" init -q
git -C "${transition_repo_root}" config user.name "Cognitura Contract Test"
git -C "${transition_repo_root}" config user.email "contract-test@cognitura.invalid"
git -C "${transition_repo_root}" add .
git -C "${transition_repo_root}" commit -qm "test: fix pending governance state"
bootstrap_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"

transition_cards_dir="${transition_repo_root}/docs/task-cards/module-default-reading-implementation"
transition_verifier="${transition_repo_root}/scripts/verify-module-default-reading-implementation-cards"
make_activation_state "${transition_cards_dir}"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "GovernanceReviewedCandidateSHA" \
  "${bootstrap_sha}"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "TransitionBaseSHA" \
  "${bootstrap_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/module-default-reading-implementation/execution-state.md
git -C "${transition_repo_root}" commit -qm "docs: activate test MDR set"
activation_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${transition_verifier}" \
  --cards-dir "${transition_cards_dir}" \
  --transition-base "${bootstrap_sha}" \
  --transition-head "${activation_sha}" >/dev/null ||
  fail "valid fixed activation transition was rejected"

mkdir -p "${transition_repo_root}/web"
printf '%s\n' '{"private":true}' > "${transition_repo_root}/web/package.json"
git -C "${transition_repo_root}" add web/package.json
git -C "${transition_repo_root}" commit -qm "test: fix MDR-I00 business candidate"
business_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"

make_i00_advance_state "${transition_cards_dir}"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "GovernanceReviewedCandidateSHA" \
  "${bootstrap_sha}"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "CurrentCandidateSHA" \
  "${business_candidate_sha}"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "TransitionBaseSHA" \
  "${business_candidate_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/module-default-reading-implementation/execution-state.md
git -C "${transition_repo_root}" commit -qm "docs: advance test MDR state"
advance_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${transition_verifier}" \
  --cards-dir "${transition_cards_dir}" \
  --transition-base "${business_candidate_sha}" \
  --transition-head "${advance_sha}" >/dev/null ||
  fail "valid fixed advance transition was rejected"

printf '%s\n' 'UncommittedDriftProbe = PRESENT' >> "${transition_cards_dir}/execution-state.md"
transition_output="$(
  "${transition_verifier}" \
    --cards-dir "${transition_cards_dir}" \
    --transition-base "${business_candidate_sha}" \
    --transition-head "${advance_sha}" 2>&1
)" && fail "worktree ledger drift from fixed transition HEAD unexpectedly passed"
[[ "${transition_output}" == *"validated execution-state.md must match the fixed transition HEAD tree"* ]] ||
  fail "fixed transition HEAD binding returned the wrong failure: ${transition_output}"
negative_cases=$((negative_cases + 1))
git -C "${transition_repo_root}" show \
  "${advance_sha}:docs/task-cards/module-default-reading-implementation/execution-state.md" > \
  "${transition_cards_dir}/execution-state.md"

git -C "${transition_repo_root}" switch -qc candidate-writeset-leak "${activation_sha}"
mkdir -p "${transition_repo_root}/schemas"
printf '%s\n' '{"forbidden":true}' > "${transition_repo_root}/schemas/forbidden.json"
git -C "${transition_repo_root}" add schemas/forbidden.json
git -C "${transition_repo_root}" commit -qm "test: leak forbidden path into MDR-I00 candidate"
leaked_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
make_i00_advance_state "${transition_cards_dir}"
set_state_field "${transition_cards_dir}/execution-state.md" "GovernanceReviewedCandidateSHA" "${bootstrap_sha}"
set_state_field "${transition_cards_dir}/execution-state.md" "CurrentCandidateSHA" "${leaked_candidate_sha}"
set_state_field "${transition_cards_dir}/execution-state.md" "TransitionBaseSHA" "${leaked_candidate_sha}"
git -C "${transition_repo_root}" add docs/task-cards/module-default-reading-implementation/execution-state.md
git -C "${transition_repo_root}" commit -qm "docs: advance leaked MDR-I00 candidate"
leaked_candidate_transition_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
transition_output="$(
  "${transition_verifier}" \
    --cards-dir "${transition_cards_dir}" \
    --transition-base "${leaked_candidate_sha}" \
    --transition-head "${leaked_candidate_transition_sha}" 2>&1
)" && fail "forbidden path in business candidate unexpectedly passed"
[[ "${transition_output}" == *"business candidate path is outside MDR-I00 WriteSet: schemas/forbidden.json"* ]] ||
  fail "business candidate WriteSet leak returned the wrong failure: ${transition_output}"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -qc skipped-prefix-transition "${activation_sha}"
mkdir -p "${transition_repo_root}/web"
printf '%s\n' '{"private":true,"name":"skip-probe"}' > "${transition_repo_root}/web/package.json"
git -C "${transition_repo_root}" add web/package.json
git -C "${transition_repo_root}" commit -qm "test: fix one MDR-I00 candidate before illegal skip"
skip_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
make_i00_advance_state "${transition_cards_dir}"
set_state_field "${transition_cards_dir}/execution-state.md" "GovernanceReviewedCandidateSHA" "${bootstrap_sha}"
set_state_field "${transition_cards_dir}/execution-state.md" "CompletedTaskCards" "MDR-I00,MDR-I01,MDR-I02,MDR-I03,MDR-I04,MDR-I05,MDR-I06,MDR-I07"
set_state_field "${transition_cards_dir}/execution-state.md" "ActiveImplementationTaskCard" "MDR-I08"
set_state_field "${transition_cards_dir}/execution-state.md" "ReleasedTaskCard" "MDR-I08"
set_state_field "${transition_cards_dir}/execution-state.md" "NextImplementationTaskCard" "MDR-I08"
set_state_field "${transition_cards_dir}/execution-state.md" "CurrentCandidateSHA" "${skip_candidate_sha}"
set_state_field "${transition_cards_dir}/execution-state.md" "TransitionSequence" "9"
set_state_field "${transition_cards_dir}/execution-state.md" "TransitionBaseSHA" "${skip_candidate_sha}"
git -C "${transition_repo_root}" add docs/task-cards/module-default-reading-implementation/execution-state.md
git -C "${transition_repo_root}" commit -qm "docs: illegally skip MDR prefix"
skip_transition_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
transition_output="$(
  "${transition_verifier}" \
    --cards-dir "${transition_cards_dir}" \
    --transition-base "${skip_candidate_sha}" \
    --transition-head "${skip_transition_sha}" 2>&1
)" && fail "multi-card completed-prefix jump unexpectedly passed"
[[ "${transition_output}" == *"advance must complete exactly the previously active card"* ]] ||
  fail "multi-card completed-prefix jump returned the wrong failure: ${transition_output}"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -qc indirect-transition "${business_candidate_sha}"
printf '\n' >> "${transition_cards_dir}/execution-state.md"
git -C "${transition_repo_root}" add docs/task-cards/module-default-reading-implementation/execution-state.md
git -C "${transition_repo_root}" commit -qm "docs: insert an intermediate ledger commit"
make_i00_advance_state "${transition_cards_dir}"
set_state_field "${transition_cards_dir}/execution-state.md" "GovernanceReviewedCandidateSHA" "${bootstrap_sha}"
set_state_field "${transition_cards_dir}/execution-state.md" "CurrentCandidateSHA" "${business_candidate_sha}"
set_state_field "${transition_cards_dir}/execution-state.md" "TransitionBaseSHA" "${business_candidate_sha}"
git -C "${transition_repo_root}" add docs/task-cards/module-default-reading-implementation/execution-state.md
git -C "${transition_repo_root}" commit -qm "docs: hide intermediate ledger commit"
indirect_transition_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
transition_output="$(
  "${transition_verifier}" \
    --cards-dir "${transition_cards_dir}" \
    --transition-base "${business_candidate_sha}" \
    --transition-head "${indirect_transition_sha}" 2>&1
)" && fail "non-direct state transition unexpectedly passed"
[[ "${transition_output}" == *"transition HEAD must be the direct child of BASE"* ]] ||
  fail "non-direct state transition returned the wrong failure: ${transition_output}"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -qc stopped-transition "${activation_sha}"
make_stopped_state "${transition_cards_dir}" "${activation_sha}"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "GovernanceReviewedCandidateSHA" \
  "${bootstrap_sha}"
git -C "${transition_repo_root}" add docs/task-cards/module-default-reading-implementation/execution-state.md
git -C "${transition_repo_root}" commit -qm "docs: stop active MDR set"
stopped_transition_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${transition_verifier}" \
  --cards-dir "${transition_cards_dir}" \
  --transition-base "${activation_sha}" \
  --transition-head "${stopped_transition_sha}" >/dev/null ||
  fail "valid fixed STOP transition was rejected"

git -C "${transition_repo_root}" switch -qc documentation-gap-resume "${advance_sha}"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "TaskCardSetStatus" \
  "BLOCKED_BY_DOCUMENTATION_GAP"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "ActiveImplementationTaskCard" \
  "NONE"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "ReleasedTaskCard" \
  "NONE"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "TransitionKind" \
  "BLOCK_DOCUMENTATION_GAP"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "TransitionBaseSHA" \
  "${advance_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/module-default-reading-implementation/execution-state.md
git -C "${transition_repo_root}" commit -qm "docs: block test MDR set on documentation gap"
documentation_gap_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${transition_verifier}" \
  --cards-dir "${transition_cards_dir}" \
  --transition-base "${advance_sha}" \
  --transition-head "${documentation_gap_sha}" >/dev/null ||
  fail "valid fixed documentation-gap block transition was rejected"

printf '\n' >> "${transition_cards_dir}/MDR-I07-reading-first-composition.md"
git -C "${transition_repo_root}" add \
  docs/task-cards/module-default-reading-implementation/MDR-I07-reading-first-composition.md
git -C "${transition_repo_root}" commit -qm "docs: repair test MDR-I07 governance"
documentation_repair_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"

set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "TaskCardSetStatus" \
  "IN_PROGRESS"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "ActiveImplementationTaskCard" \
  "MDR-I01"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "ReleasedTaskCard" \
  "MDR-I01"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "TransitionKind" \
  "RESUME_DOCUMENTATION_GAP"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "TransitionBaseSHA" \
  "${documentation_repair_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/module-default-reading-implementation/execution-state.md
git -C "${transition_repo_root}" commit -qm "docs: resume test MDR set after documentation repair"
documentation_resume_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${transition_verifier}" \
  --cards-dir "${transition_cards_dir}" \
  --transition-base "${documentation_repair_sha}" \
  --transition-head "${documentation_resume_sha}" >/dev/null ||
  fail "valid fixed documentation-gap resume transition was rejected"

git -C "${transition_repo_root}" switch -qc invalid-resume-base "${advance_sha}"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "TransitionKind" \
  "RESUME_DOCUMENTATION_GAP"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "TransitionBaseSHA" \
  "${advance_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/module-default-reading-implementation/execution-state.md
git -C "${transition_repo_root}" commit -qm "docs: illegally resume an in-progress MDR set"
invalid_resume_base_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
transition_output="$(
  "${transition_verifier}" \
    --cards-dir "${transition_cards_dir}" \
    --transition-base "${advance_sha}" \
    --transition-head "${invalid_resume_base_sha}" 2>&1
)" && fail "documentation-gap resume from IN_PROGRESS unexpectedly passed"
[[ "${transition_output}" == *"documentation-gap resume must start from BLOCKED_BY_DOCUMENTATION_GAP"* ]] ||
  fail "wrong-base documentation-gap resume returned the wrong failure: ${transition_output}"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -qc invalid-resume-receipt "${documentation_repair_sha}"
set_state_field "${transition_cards_dir}/execution-state.md" "TaskCardSetStatus" "IN_PROGRESS"
set_state_field "${transition_cards_dir}/execution-state.md" "ActiveImplementationTaskCard" "MDR-I01"
set_state_field "${transition_cards_dir}/execution-state.md" "ReleasedTaskCard" "MDR-I01"
set_state_field "${transition_cards_dir}/execution-state.md" "TransitionKind" "RESUME_DOCUMENTATION_GAP"
set_state_field "${transition_cards_dir}/execution-state.md" "TransitionBaseSHA" "${documentation_repair_sha}"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "CurrentCandidateSHA" \
  "ffffffffffffffffffffffffffffffffffffffff"
git -C "${transition_repo_root}" add \
  docs/task-cards/module-default-reading-implementation/execution-state.md
git -C "${transition_repo_root}" commit -qm "docs: drift receipt while resuming MDR set"
invalid_resume_receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
transition_output="$(
  "${transition_verifier}" \
    --cards-dir "${transition_cards_dir}" \
    --transition-base "${documentation_repair_sha}" \
    --transition-head "${invalid_resume_receipt_sha}" 2>&1
)" && fail "documentation-gap resume with receipt drift unexpectedly passed"
[[ "${transition_output}" == *"state transition must preserve CurrentCandidateSHA"* ]] ||
  fail "receipt-drift documentation-gap resume returned the wrong failure: ${transition_output}"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -qc invalid-resume-prefix "${documentation_repair_sha}"
set_state_field "${transition_cards_dir}/execution-state.md" "TaskCardSetStatus" "IN_PROGRESS"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "CompletedTaskCards" \
  "MDR-I00,MDR-I01"
set_state_field "${transition_cards_dir}/execution-state.md" "ActiveImplementationTaskCard" "MDR-I02"
set_state_field "${transition_cards_dir}/execution-state.md" "ReleasedTaskCard" "MDR-I02"
set_state_field "${transition_cards_dir}/execution-state.md" "NextImplementationTaskCard" "MDR-I02"
set_state_field "${transition_cards_dir}/execution-state.md" "TransitionSequence" "3"
set_state_field "${transition_cards_dir}/execution-state.md" "TransitionKind" "RESUME_DOCUMENTATION_GAP"
set_state_field "${transition_cards_dir}/execution-state.md" "TransitionBaseSHA" "${documentation_repair_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/module-default-reading-implementation/execution-state.md
git -C "${transition_repo_root}" commit -qm "docs: skip prefix while resuming MDR set"
invalid_resume_prefix_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
transition_output="$(
  "${transition_verifier}" \
    --cards-dir "${transition_cards_dir}" \
    --transition-base "${documentation_repair_sha}" \
    --transition-head "${invalid_resume_prefix_sha}" 2>&1
)" && fail "documentation-gap resume with prefix drift unexpectedly passed"
[[ "${transition_output}" == *"documentation-gap resume cannot change the completed prefix or sequence"* ]] ||
  fail "prefix-drift documentation-gap resume returned the wrong failure: ${transition_output}"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -qc invalid-business-transition "${business_candidate_sha}"
make_i00_advance_state "${transition_cards_dir}"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "GovernanceReviewedCandidateSHA" \
  "${bootstrap_sha}"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "CurrentCandidateSHA" \
  "${business_candidate_sha}"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "TransitionBaseSHA" \
  "${business_candidate_sha}"
mkdir -p "${transition_repo_root}/web/src"
printf '%s\n' 'export const leaked = true;' > "${transition_repo_root}/web/src/leaked.ts"
git -C "${transition_repo_root}" add \
  docs/task-cards/module-default-reading-implementation/execution-state.md \
  web/src/leaked.ts
git -C "${transition_repo_root}" commit -qm "test: leak business file into transition"
invalid_business_transition_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
transition_output="$(
  "${transition_verifier}" \
    --cards-dir "${transition_cards_dir}" \
    --transition-base "${business_candidate_sha}" \
    --transition-head "${invalid_business_transition_sha}" 2>&1
)" && fail "business-file transition unexpectedly passed"
[[ "${transition_output}" == *"state transition fixed diff must contain only execution-state.md"* ]] ||
  fail "business-file transition returned the wrong failure: ${transition_output}"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -qc invalid-card-transition "${business_candidate_sha}"
make_i00_advance_state "${transition_cards_dir}"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "GovernanceReviewedCandidateSHA" \
  "${bootstrap_sha}"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "CurrentCandidateSHA" \
  "${business_candidate_sha}"
set_state_field \
  "${transition_cards_dir}/execution-state.md" \
  "TransitionBaseSHA" \
  "${business_candidate_sha}"
printf '\n' >> "${transition_cards_dir}/MDR-I00-web-test-foundation.md"
git -C "${transition_repo_root}" add \
  docs/task-cards/module-default-reading-implementation/execution-state.md \
  docs/task-cards/module-default-reading-implementation/MDR-I00-web-test-foundation.md
git -C "${transition_repo_root}" commit -qm "test: leak card file into transition"
invalid_card_transition_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
transition_output="$(
  "${transition_verifier}" \
    --cards-dir "${transition_cards_dir}" \
    --transition-base "${business_candidate_sha}" \
    --transition-head "${invalid_card_transition_sha}" 2>&1
)" && fail "card-file transition unexpectedly passed"
[[ "${transition_output}" == *"state transition fixed diff must contain only execution-state.md"* ]] ||
  fail "card-file transition returned the wrong failure: ${transition_output}"
negative_cases=$((negative_cases + 1))

printf '%s\n' \
  "ModuleDefaultReadingTaskCardContractTests = PASS" \
  "NegativeCases = ${negative_cases}" \
  "PendingGovernanceTerminalCases = 1" \
  "ValidRecoveryStateCases = 3" \
  "ValidResumeStateCases = 1" \
  "ValidActivationCases = 1" \
  "ValidAdvanceCases = 1" \
  "ValidFixedTransitionCases = 5"
