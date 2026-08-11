#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-wave1-implementation-cards"
cards_dir="${repo_root}/docs/task-cards/wave-1-implementation"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-wave1-implementation-cards.XXXXXX")"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local content="$1"
  local expected="$2"
  [[ "${content}" == *"${expected}"* ]] ||
    fail "validation output is missing: ${expected}"
}

set_field() {
  local file="$1"
  local field="$2"
  local value="$3"
  sed -i.bak "s#^${field} = .*\$#${field} = ${value}#" "${file}"
  rm "${file}.bak"
}

set_table_status() {
  local index_file="$1"
  local task_id="$2"
  local old_status="$3"
  local new_status="$4"
  sed -i.bak \
    "/^| \`${task_id}\` |/ s/| \`${old_status}\` |/| \`${new_status}\` |/" \
    "${index_file}"
  rm "${index_file}.bak"
}

make_ready_i00_fixture() {
  local source_dir="$1"
  local destination_dir="$2"
  local card_file
  local task_id
  local old_status
  local expected_status
  local expected_authorization
  local expected_database_gate

  cp -R "${source_dir}" "${destination_dir}"

  for card_file in "${destination_dir}"/W1-I*.md; do
    task_id="$(sed -n 's/^TaskCardID = //p' "${card_file}")"
    old_status="$(sed -n 's/^Status = //p' "${card_file}")"

    case "${task_id}" in
      W1-I00)
        expected_status="READY"
        expected_authorization="NOT_REQUIRED_GOVERNANCE_ONLY"
        ;;
      W1-I01)
        expected_status="BLOCKED_BY_USER_AUTHORIZATION"
        expected_authorization="REQUIRED_BEFORE_READY"
        ;;
      *)
        expected_status="BLOCKED_BY_DEPENDENCY"
        expected_authorization="REQUIRED_BEFORE_READY"
        ;;
    esac

    case "${task_id}" in
      W1-I02)
        expected_database_gate="REQUIRED_BEFORE_READY"
        ;;
      W1-I07)
        expected_database_gate="REQUIRED_DEPENDENCY_I02_ONLY"
        ;;
      *)
        expected_database_gate="NOT_APPLICABLE"
        ;;
    esac

    set_field "${card_file}" "Status" "${expected_status}"
    set_field \
      "${card_file}" \
      "BusinessImplementationAuthorization" \
      "${expected_authorization}"
    set_field "${card_file}" "FormalDatabaseGate" "${expected_database_gate}"
    set_table_status \
      "${destination_dir}/README.md" \
      "${task_id}" \
      "${old_status}" \
      "${expected_status}"
  done

  set_field "${destination_dir}/README.md" "ActiveTaskCard" "W1-I00"
  set_field \
    "${destination_dir}/README.md" \
    "TaskCardSetStatus" \
    "READY_FOR_EXECUTION"
  set_field \
    "${destination_dir}/README.md" \
    "BusinessImplementation" \
    "NOT_AUTHORIZED"
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
  negative_cases=$((negative_cases + 1))
}

[[ -x "${verifier}" ]] || fail "Wave 1 implementation task-card verifier is missing or not executable"

validation_output="$(
  "${verifier}" \
    --cards-dir "${cards_dir}"
)"

assert_contains "${validation_output}" "Wave1ImplementationTaskCardValidation = PASS"
assert_contains "${validation_output}" "TaskCardCount = 14"

ready_i00_dir="${test_tmp_root}/ready-i00"
make_ready_i00_fixture "${cards_dir}" "${ready_i00_dir}"
ready_i00_output="$("${verifier}" --cards-dir "${ready_i00_dir}")" ||
  fail "valid I00 READY bootstrap state was rejected"
assert_contains "${ready_i00_output}" "TaskCardSetStatus = READY_FOR_EXECUTION"
assert_contains "${ready_i00_output}" "ActiveTaskCard = W1-I00"
bootstrap_normalization_cases=1

cards_dir="${ready_i00_dir}"

negative_cases=0

second_ready_dir="${test_tmp_root}/second-ready"
cp -R "${cards_dir}" "${second_ready_dir}"
set_field "${second_ready_dir}/W1-I02-source-persistence.md" "Status" "READY"
set_field \
  "${second_ready_dir}/W1-I02-source-persistence.md" \
  "BusinessImplementationAuthorization" \
  "USER_AUTHORIZED"
set_field \
  "${second_ready_dir}/W1-I02-source-persistence.md" \
  "FormalDatabaseGate" \
  "PASS"
set_table_status \
  "${second_ready_dir}/README.md" \
  "W1-I02" \
  "BLOCKED_BY_DEPENDENCY" \
  "READY"
expect_failure "${second_ready_dir}" "task card set must have exactly one READY card"

i00_business_write_dir="${test_tmp_root}/i00-business-write"
cp -R "${cards_dir}" "${i00_business_write_dir}"
printf '%s\n' \
  'WriteSet = server/src/main/java/io/cognitura/source/Forbidden.java' >> \
  "${i00_business_write_dir}/W1-I00-implementation-governance.md"
expect_failure \
  "${i00_business_write_dir}" \
  "WriteSet mismatch for W1-I00"

i01_without_approval_dir="${test_tmp_root}/i01-without-approval"
cp -R "${cards_dir}" "${i01_without_approval_dir}"
set_field "${i01_without_approval_dir}/W1-I00-implementation-governance.md" "Status" "DONE"
set_field "${i01_without_approval_dir}/W1-I01-source-ingestion-domain.md" "Status" "READY"
set_field "${i01_without_approval_dir}/README.md" "ActiveTaskCard" "W1-I01"
set_table_status "${i01_without_approval_dir}/README.md" "W1-I00" "READY" "DONE"
set_table_status \
  "${i01_without_approval_dir}/README.md" \
  "W1-I01" \
  "BLOCKED_BY_USER_AUTHORIZATION" \
  "READY"
expect_failure \
  "${i01_without_approval_dir}" \
  "W1-I01 requires explicit business implementation authorization"

i02_without_db_gate_dir="${test_tmp_root}/i02-without-db-gate"
cp -R "${cards_dir}" "${i02_without_db_gate_dir}"
set_field "${i02_without_db_gate_dir}/W1-I00-implementation-governance.md" "Status" "DONE"
set_field "${i02_without_db_gate_dir}/W1-I01-source-ingestion-domain.md" "Status" "DONE"
set_field "${i02_without_db_gate_dir}/W1-I01-source-ingestion-domain.md" \
  "BusinessImplementationAuthorization" "USER_AUTHORIZED"
set_field "${i02_without_db_gate_dir}/W1-I02-source-persistence.md" "Status" "READY"
set_field "${i02_without_db_gate_dir}/W1-I02-source-persistence.md" \
  "BusinessImplementationAuthorization" "USER_AUTHORIZED"
set_field "${i02_without_db_gate_dir}/README.md" "ActiveTaskCard" "W1-I02"
set_table_status "${i02_without_db_gate_dir}/README.md" "W1-I00" "READY" "DONE"
set_table_status \
  "${i02_without_db_gate_dir}/README.md" \
  "W1-I01" \
  "BLOCKED_BY_USER_AUTHORIZATION" \
  "DONE"
set_table_status \
  "${i02_without_db_gate_dir}/README.md" \
  "W1-I02" \
  "BLOCKED_BY_DEPENDENCY" \
  "READY"
expect_failure \
  "${i02_without_db_gate_dir}" \
  "W1-I02 requires DatabaseGate PASS before READY"

oversized_card_dir="${test_tmp_root}/oversized-card"
cp -R "${cards_dir}" "${oversized_card_dir}"
set_field "${oversized_card_dir}/W1-I03-docx-security-gate.md" "ProductionFileLimit" "9"
set_field \
  "${oversized_card_dir}/W1-I03-docx-security-gate.md" \
  "ProductionWriteSetException" \
  "BOGUS"
expect_failure \
  "${oversized_card_dir}" \
  "ProductionFileLimit must remain 8 for W1-I03"

duplicate_boundary_dir="${test_tmp_root}/duplicate-boundary"
cp -R "${cards_dir}" "${duplicate_boundary_dir}"
printf '%s\n' 'PrimaryBoundary = DOCX_PARSER' >> \
  "${duplicate_boundary_dir}/W1-I04-text-list-section-parser.md"
expect_failure "${duplicate_boundary_dir}" "PrimaryBoundary must occur exactly once"

i13_missing_dependency_dir="${test_tmp_root}/i13-missing-dependency"
cp -R "${cards_dir}" "${i13_missing_dependency_dir}"
set_field \
  "${i13_missing_dependency_dir}/W1-I13-fixed-implementation-review.md" \
  "DependsOn" \
  "W1-I00,W1-I01,W1-I02,W1-I03,W1-I04,W1-I05,W1-I06,W1-I07,W1-I08,W1-I09,W1-I10,W1-I11"
expect_failure \
  "${i13_missing_dependency_dir}" \
  "W1-I13 must depend on W1-I00 through W1-I12"

i13_wrong_route_dir="${test_tmp_root}/i13-wrong-route"
cp -R "${cards_dir}" "${i13_wrong_route_dir}"
set_field \
  "${i13_wrong_route_dir}/W1-I13-fixed-implementation-review.md" \
  "ReviewRoute" \
  "deep_reviewer"
expect_failure \
  "${i13_wrong_route_dir}" \
  "W1-I13 must use DEEP_REVIEWER_THEN_ULTRA_GATEKEEPER"

i01_write_set_drift_dir="${test_tmp_root}/i01-write-set-drift"
cp -R "${cards_dir}" "${i01_write_set_drift_dir}"
sed -i.bak \
  's#SourceDocument.java#InventedDomainFact.java#' \
  "${i01_write_set_drift_dir}/W1-I01-source-ingestion-domain.md"
rm "${i01_write_set_drift_dir}/W1-I01-source-ingestion-domain.md.bak"
expect_failure \
  "${i01_write_set_drift_dir}" \
  "WriteSet mismatch for W1-I01"

i01_forbidden_set_drift_dir="${test_tmp_root}/i01-forbidden-set-drift"
cp -R "${cards_dir}" "${i01_forbidden_set_drift_dir}"
sed -i.bak \
  '/^ForbiddenWriteSet = web\/\*\*,raw\/\*\*,\.idea\/\*\*$/d' \
  "${i01_forbidden_set_drift_dir}/W1-I01-source-ingestion-domain.md"
rm "${i01_forbidden_set_drift_dir}/W1-I01-source-ingestion-domain.md.bak"
expect_failure \
  "${i01_forbidden_set_drift_dir}" \
  "ForbiddenWriteSet mismatch for W1-I01"

i01_missing_red_dir="${test_tmp_root}/i01-missing-red"
cp -R "${cards_dir}" "${i01_missing_red_dir}"
sed -i.bak 's/^1\. RED：/1. FAIL：/' \
  "${i01_missing_red_dir}/W1-I01-source-ingestion-domain.md"
rm "${i01_missing_red_dir}/W1-I01-source-ingestion-domain.md.bak"
expect_failure "${i01_missing_red_dir}" "W1-I01: missing RED-first instruction"

i01_missing_green_dir="${test_tmp_root}/i01-missing-green"
cp -R "${cards_dir}" "${i01_missing_green_dir}"
sed -i.bak 's/^2\. GREEN：/2. IMPLEMENT：/' \
  "${i01_missing_green_dir}/W1-I01-source-ingestion-domain.md"
rm "${i01_missing_green_dir}/W1-I01-source-ingestion-domain.md.bak"
expect_failure "${i01_missing_green_dir}" "W1-I01: missing GREEN instruction"

i00_missing_red_green_dir="${test_tmp_root}/i00-missing-red-green"
cp -R "${cards_dir}" "${i00_missing_red_green_dir}"
sed -i.bak \
  '/^1\. RED：先写会因验证器缺失而失败的正例合同。$/d; /^2\. GREEN：实现只接受闭集参数的最小验证器/d' \
  "${i00_missing_red_green_dir}/W1-I00-implementation-governance.md"
rm "${i00_missing_red_green_dir}/W1-I00-implementation-governance.md.bak"
expect_failure "${i00_missing_red_green_dir}" "W1-I00: missing RED-first instruction"

i01_red_green_decoy_dir="${test_tmp_root}/i01-red-green-decoy"
cp -R "${cards_dir}" "${i01_red_green_decoy_dir}"
sed -i.bak 's/^1\. RED：/1. REDACTED：/; s/^2\. GREEN：/2. EVERGREEN：/' \
  "${i01_red_green_decoy_dir}/W1-I01-source-ingestion-domain.md"
rm "${i01_red_green_decoy_dir}/W1-I01-source-ingestion-domain.md.bak"
expect_failure "${i01_red_green_decoy_dir}" "W1-I01: missing RED-first instruction"

i01_missing_target_gate_dir="${test_tmp_root}/i01-missing-target-gate"
cp -R "${cards_dir}" "${i01_missing_target_gate_dir}"
sed -i.bak \
  "/^\.\/mvnw -f server\/pom\.xml -Dtest='io\.cognitura\.source\.domain\.\*Test' test$/d" \
  "${i01_missing_target_gate_dir}/W1-I01-source-ingestion-domain.md"
rm "${i01_missing_target_gate_dir}/W1-I01-source-ingestion-domain.md.bak"
expect_failure \
  "${i01_missing_target_gate_dir}" \
  "W1-I01: validation Bash block mismatch"

i01_target_gate_decoy_dir="${test_tmp_root}/i01-target-gate-decoy"
cp -R "${cards_dir}" "${i01_target_gate_decoy_dir}"
sed -i.bak \
  "/^\.\/mvnw -f server\/pom\.xml -Dtest='io\.cognitura\.source\.domain\.\*Test' test$/d" \
  "${i01_target_gate_decoy_dir}/W1-I01-source-ingestion-domain.md"
rm "${i01_target_gate_decoy_dir}/W1-I01-source-ingestion-domain.md.bak"
printf '%s\n' \
  "./mvnw -f server/pom.xml -Dtest='io.cognitura.source.domain.*Test' test" >> \
  "${i01_target_gate_decoy_dir}/W1-I01-source-ingestion-domain.md"
expect_failure \
  "${i01_target_gate_decoy_dir}" \
  "W1-I01: validation Bash block mismatch"

i01_target_outside_fence_dir="${test_tmp_root}/i01-target-outside-fence"
cp -R "${cards_dir}" "${i01_target_outside_fence_dir}"
sed -i.bak \
  "/^\.\/mvnw -f server\/pom\.xml -Dtest='io\.cognitura\.source\.domain\.\*Test' test$/d; /^## 6\. Gate 与完成定义$/i\\
./mvnw -f server/pom.xml -Dtest='io.cognitura.source.domain.*Test' test
" \
  "${i01_target_outside_fence_dir}/W1-I01-source-ingestion-domain.md"
rm "${i01_target_outside_fence_dir}/W1-I01-source-ingestion-domain.md.bak"
expect_failure \
  "${i01_target_outside_fence_dir}" \
  "W1-I01: validation Bash block mismatch"

i01_missing_commit_dir="${test_tmp_root}/i01-missing-commit"
cp -R "${cards_dir}" "${i01_missing_commit_dir}"
sed -i.bak '/^git commit -m "feat: add source ingestion domain"$/d' \
  "${i01_missing_commit_dir}/W1-I01-source-ingestion-domain.md"
rm "${i01_missing_commit_dir}/W1-I01-source-ingestion-domain.md.bak"
expect_failure "${i01_missing_commit_dir}" "W1-I01: commit Bash block mismatch"

i01_missing_fixed_review_dir="${test_tmp_root}/i01-missing-fixed-review"
cp -R "${cards_dir}" "${i01_missing_fixed_review_dir}"
sed -i.bak '/^`deep_reviewer`/d' \
  "${i01_missing_fixed_review_dir}/W1-I01-source-ingestion-domain.md"
rm "${i01_missing_fixed_review_dir}/W1-I01-source-ingestion-domain.md.bak"
sed -i.bak '/^FixedCommitReviewGate = /d' \
  "${i01_missing_fixed_review_dir}/W1-I01-source-ingestion-domain.md"
rm "${i01_missing_fixed_review_dir}/W1-I01-source-ingestion-domain.md.bak"
printf '%s\n' 'deep_reviewer decoy' >> \
  "${i01_missing_fixed_review_dir}/W1-I01-source-ingestion-domain.md"
expect_failure "${i01_missing_fixed_review_dir}" "W1-I01: missing fixed-commit review route"

i01_missing_positive_verification_dir="${test_tmp_root}/i01-missing-positive-verification"
cp -R "${cards_dir}" "${i01_missing_positive_verification_dir}"
sed -i.bak '/^PositiveVerification = /d' \
  "${i01_missing_positive_verification_dir}/W1-I01-source-ingestion-domain.md"
rm "${i01_missing_positive_verification_dir}/W1-I01-source-ingestion-domain.md.bak"
expect_failure \
  "${i01_missing_positive_verification_dir}" \
  "PositiveVerification must occur exactly once"

i01_broad_stage_dir="${test_tmp_root}/i01-broad-stage"
cp -R "${cards_dir}" "${i01_broad_stage_dir}"
sed -i.bak \
  's#^  git add --pathspec-from-file=-$#  git add server/src/main/java/io/cognitura/source/domain#' \
  "${i01_broad_stage_dir}/W1-I01-source-ingestion-domain.md"
rm "${i01_broad_stage_dir}/W1-I01-source-ingestion-domain.md.bak"
expect_failure "${i01_broad_stage_dir}" "W1-I01: commit Bash block mismatch"

i01_stage_order_dir="${test_tmp_root}/i01-stage-order"
cp -R "${cards_dir}" "${i01_stage_order_dir}"
sed -i.bak \
  's#^  git add --pathspec-from-file=-$#  __STAGE_ORDER_PLACEHOLDER__#; s#^git diff --cached --name-only$#  git add --pathspec-from-file=-#; s#^  __STAGE_ORDER_PLACEHOLDER__$#git diff --cached --name-only#' \
  "${i01_stage_order_dir}/W1-I01-source-ingestion-domain.md"
rm "${i01_stage_order_dir}/W1-I01-source-ingestion-domain.md.bak"
expect_failure "${i01_stage_order_dir}" "W1-I01: commit Bash block mismatch"

i01_git_c_add_dir="${test_tmp_root}/i01-git-c-add"
cp -R "${cards_dir}" "${i01_git_c_add_dir}"
printf '%s\n' 'git -C . add server/src/main/java/io/cognitura/source/domain' >> \
  "${i01_git_c_add_dir}/W1-I01-source-ingestion-domain.md"
expect_failure "${i01_git_c_add_dir}" "W1-I01: unexpected Git invocation"

i01_git_c_push_dir="${test_tmp_root}/i01-git-c-push"
cp -R "${cards_dir}" "${i01_git_c_push_dir}"
printf '%s\n' 'git -C . push' >> \
  "${i01_git_c_push_dir}/W1-I01-source-ingestion-domain.md"
expect_failure "${i01_git_c_push_dir}" "W1-I01: unexpected Git invocation"

i01_git_c_commit_dir="${test_tmp_root}/i01-git-c-commit"
cp -R "${cards_dir}" "${i01_git_c_commit_dir}"
printf '%s\n' 'git -C . commit -m "second local commit"' >> \
  "${i01_git_c_commit_dir}/W1-I01-source-ingestion-domain.md"
expect_failure "${i01_git_c_commit_dir}" "W1-I01: unexpected Git invocation"

i01_command_git_push_dir="${test_tmp_root}/i01-command-git-push"
cp -R "${cards_dir}" "${i01_command_git_push_dir}"
printf '%s\n' 'command git push' >> \
  "${i01_command_git_push_dir}/W1-I01-source-ingestion-domain.md"
expect_failure "${i01_command_git_push_dir}" "W1-I01: unexpected Git invocation"

i01_usr_bin_env_git_push_dir="${test_tmp_root}/i01-usr-bin-env-git-push"
cp -R "${cards_dir}" "${i01_usr_bin_env_git_push_dir}"
printf '%s\n' '/usr/bin/env git push' >> \
  "${i01_usr_bin_env_git_push_dir}/W1-I01-source-ingestion-domain.md"
expect_failure "${i01_usr_bin_env_git_push_dir}" "W1-I01: unexpected Git invocation"

i01_env_assignment_git_push_dir="${test_tmp_root}/i01-env-assignment-git-push"
cp -R "${cards_dir}" "${i01_env_assignment_git_push_dir}"
printf '%s\n' 'env GIT_DIR=.git git push' >> \
  "${i01_env_assignment_git_push_dir}/W1-I01-source-ingestion-domain.md"
expect_failure "${i01_env_assignment_git_push_dir}" "W1-I01: unexpected Git invocation"

i01_assignment_git_push_dir="${test_tmp_root}/i01-assignment-git-push"
cp -R "${cards_dir}" "${i01_assignment_git_push_dir}"
printf '%s\n' 'GIT_DIR=.git git push' >> \
  "${i01_assignment_git_push_dir}/W1-I01-source-ingestion-domain.md"
expect_failure "${i01_assignment_git_push_dir}" "W1-I01: unexpected Git invocation"

i01_conflicting_review_gate_dir="${test_tmp_root}/i01-conflicting-review-gate"
cp -R "${cards_dir}" "${i01_conflicting_review_gate_dir}"
printf '%s\n' 'FixedCommitReviewGate = SKIP_REVIEW' >> \
  "${i01_conflicting_review_gate_dir}/W1-I01-source-ingestion-domain.md"
expect_failure \
  "${i01_conflicting_review_gate_dir}" \
  "W1-I01: FixedCommitReviewGate must occur exactly once"

i01_split_git_token_dir="${test_tmp_root}/i01-split-git-token"
cp -R "${cards_dir}" "${i01_split_git_token_dir}"
printf '%s\n' 'g""it push' >> \
  "${i01_split_git_token_dir}/W1-I01-source-ingestion-domain.md"
expect_failure "${i01_split_git_token_dir}" "W1-I01: card body contract digest mismatch"

i01_variable_git_dir="${test_tmp_root}/i01-variable-git"
cp -R "${cards_dir}" "${i01_variable_git_dir}"
printf '%s\n' 'GIT_COMMAND=git' '"$GIT_COMMAND" push' >> \
  "${i01_variable_git_dir}/W1-I01-source-ingestion-domain.md"
expect_failure "${i01_variable_git_dir}" "W1-I01: card body contract digest mismatch"

i01_tilde_bash_dir="${test_tmp_root}/i01-tilde-bash"
cp -R "${cards_dir}" "${i01_tilde_bash_dir}"
printf '%s\n' '~~~bash' 'g""it push' '~~~' >> \
  "${i01_tilde_bash_dir}/W1-I01-source-ingestion-domain.md"
expect_failure "${i01_tilde_bash_dir}" "W1-I01: card body contract digest mismatch"

i00_bogus_authorization_dir="${test_tmp_root}/i00-bogus-authorization"
cp -R "${cards_dir}" "${i00_bogus_authorization_dir}"
set_field \
  "${i00_bogus_authorization_dir}/W1-I00-implementation-governance.md" \
  "BusinessImplementationAuthorization" \
  "BOGUS_AUTHORIZATION"
expect_failure \
  "${i00_bogus_authorization_dir}" \
  "BusinessImplementationAuthorization mismatch for W1-I00"

i00_bogus_database_gate_dir="${test_tmp_root}/i00-bogus-database-gate"
cp -R "${cards_dir}" "${i00_bogus_database_gate_dir}"
set_field \
  "${i00_bogus_database_gate_dir}/W1-I00-implementation-governance.md" \
  "FormalDatabaseGate" \
  "BOGUS_DATABASE_GATE"
expect_failure \
  "${i00_bogus_database_gate_dir}" \
  "FormalDatabaseGate mismatch for W1-I00"

i01_bogus_blocked_authorization_dir="${test_tmp_root}/i01-bogus-blocked-authorization"
cp -R "${cards_dir}" "${i01_bogus_blocked_authorization_dir}"
set_field \
  "${i01_bogus_blocked_authorization_dir}/W1-I01-source-ingestion-domain.md" \
  "BusinessImplementationAuthorization" \
  "BOGUS_AUTHORIZATION"
expect_failure \
  "${i01_bogus_blocked_authorization_dir}" \
  "BusinessImplementationAuthorization mismatch for W1-I01"

i02_bogus_blocked_database_gate_dir="${test_tmp_root}/i02-bogus-blocked-database-gate"
cp -R "${cards_dir}" "${i02_bogus_blocked_database_gate_dir}"
set_field \
  "${i02_bogus_blocked_database_gate_dir}/W1-I02-source-persistence.md" \
  "FormalDatabaseGate" \
  "BOGUS_DATABASE_GATE"
expect_failure \
  "${i02_bogus_blocked_database_gate_dir}" \
  "FormalDatabaseGate mismatch for W1-I02"

i02_premature_queued_dir="${test_tmp_root}/i02-premature-queued"
cp -R "${cards_dir}" "${i02_premature_queued_dir}"
set_field "${i02_premature_queued_dir}/W1-I02-source-persistence.md" "Status" "QUEUED"
set_table_status \
  "${i02_premature_queued_dir}/README.md" \
  "W1-I02" \
  "BLOCKED_BY_DEPENDENCY" \
  "QUEUED"
expect_failure \
  "${i02_premature_queued_dir}" \
  "W1-I02 must remain BLOCKED_BY_DEPENDENCY until dependencies are DONE"

terminal_i02_premature_queued_dir="${test_tmp_root}/terminal-i02-premature-queued"
cp -R "${cards_dir}" "${terminal_i02_premature_queued_dir}"
set_field \
  "${terminal_i02_premature_queued_dir}/W1-I00-implementation-governance.md" \
  "Status" \
  "DONE"
set_field "${terminal_i02_premature_queued_dir}/README.md" "ActiveTaskCard" "NONE"
set_field \
  "${terminal_i02_premature_queued_dir}/README.md" \
  "TaskCardSetStatus" \
  "BLOCKED_BY_USER_AUTHORIZATION"
set_table_status \
  "${terminal_i02_premature_queued_dir}/README.md" \
  "W1-I00" \
  "READY" \
  "DONE"
set_field \
  "${terminal_i02_premature_queued_dir}/W1-I02-source-persistence.md" \
  "Status" \
  "QUEUED"
set_table_status \
  "${terminal_i02_premature_queued_dir}/README.md" \
  "W1-I02" \
  "BLOCKED_BY_DEPENDENCY" \
  "QUEUED"
expect_failure \
  "${terminal_i02_premature_queued_dir}" \
  "W1-I02 must remain BLOCKED_BY_DEPENDENCY until dependencies are DONE"

i03_stale_dependency_block_dir="${test_tmp_root}/i03-stale-dependency-block"
cp -R "${cards_dir}" "${i03_stale_dependency_block_dir}"
set_field "${i03_stale_dependency_block_dir}/W1-I00-implementation-governance.md" "Status" "DONE"
set_field "${i03_stale_dependency_block_dir}/W1-I01-source-ingestion-domain.md" "Status" "DONE"
set_field \
  "${i03_stale_dependency_block_dir}/W1-I01-source-ingestion-domain.md" \
  "BusinessImplementationAuthorization" \
  "USER_AUTHORIZED"
set_field "${i03_stale_dependency_block_dir}/W1-I02-source-persistence.md" "Status" "READY"
set_field \
  "${i03_stale_dependency_block_dir}/W1-I02-source-persistence.md" \
  "BusinessImplementationAuthorization" \
  "USER_AUTHORIZED"
set_field \
  "${i03_stale_dependency_block_dir}/W1-I02-source-persistence.md" \
  "FormalDatabaseGate" \
  "PASS"
set_field "${i03_stale_dependency_block_dir}/README.md" "ActiveTaskCard" "W1-I02"
set_field "${i03_stale_dependency_block_dir}/README.md" "BusinessImplementation" "USER_AUTHORIZED"
set_table_status "${i03_stale_dependency_block_dir}/README.md" "W1-I00" "READY" "DONE"
set_table_status \
  "${i03_stale_dependency_block_dir}/README.md" \
  "W1-I01" \
  "BLOCKED_BY_USER_AUTHORIZATION" \
  "DONE"
set_table_status \
  "${i03_stale_dependency_block_dir}/README.md" \
  "W1-I02" \
  "BLOCKED_BY_DEPENDENCY" \
  "READY"
expect_failure \
  "${i03_stale_dependency_block_dir}" \
  "W1-I03 must be QUEUED, READY, or DONE after dependencies are satisfied"

authorized_i01_dir="${test_tmp_root}/authorized-i01"
cp -R "${cards_dir}" "${authorized_i01_dir}"
set_field "${authorized_i01_dir}/W1-I00-implementation-governance.md" "Status" "DONE"
set_field "${authorized_i01_dir}/W1-I01-source-ingestion-domain.md" "Status" "READY"
set_field \
  "${authorized_i01_dir}/W1-I01-source-ingestion-domain.md" \
  "BusinessImplementationAuthorization" \
  "USER_AUTHORIZED"
set_field "${authorized_i01_dir}/README.md" "ActiveTaskCard" "W1-I01"
set_field "${authorized_i01_dir}/README.md" "BusinessImplementation" "USER_AUTHORIZED"
set_table_status "${authorized_i01_dir}/README.md" "W1-I00" "READY" "DONE"
set_table_status \
  "${authorized_i01_dir}/README.md" \
  "W1-I01" \
  "BLOCKED_BY_USER_AUTHORIZATION" \
  "READY"
authorized_i01_output="$("${verifier}" --cards-dir "${authorized_i01_dir}")" ||
  fail "valid authorized I01 state was rejected"
assert_contains "${authorized_i01_output}" "ActiveTaskCard = W1-I01"

i01_projection_conflict_dir="${test_tmp_root}/i01-projection-conflict"
cp -R "${authorized_i01_dir}" "${i01_projection_conflict_dir}"
set_field \
  "${i01_projection_conflict_dir}/README.md" \
  "BusinessImplementation" \
  "NOT_AUTHORIZED"
expect_failure \
  "${i01_projection_conflict_dir}" \
  "README.md: BusinessImplementation projection mismatch"

i01_early_authorization_dir="${test_tmp_root}/i01-early-authorization"
cp -R "${cards_dir}" "${i01_early_authorization_dir}"
set_field \
  "${i01_early_authorization_dir}/W1-I01-source-ingestion-domain.md" \
  "BusinessImplementationAuthorization" \
  "USER_AUTHORIZED"
set_field \
  "${i01_early_authorization_dir}/README.md" \
  "BusinessImplementation" \
  "USER_AUTHORIZED"
expect_failure \
  "${i01_early_authorization_dir}" \
  "W1-I01 cannot be authorized before W1-I00 is DONE"

i01_unreachable_queued_dir="${test_tmp_root}/i01-unreachable-queued"
cp -R "${cards_dir}" "${i01_unreachable_queued_dir}"
set_field "${i01_unreachable_queued_dir}/W1-I00-implementation-governance.md" "Status" "DONE"
set_field "${i01_unreachable_queued_dir}/W1-I01-source-ingestion-domain.md" "Status" "QUEUED"
set_field \
  "${i01_unreachable_queued_dir}/W1-I01-source-ingestion-domain.md" \
  "BusinessImplementationAuthorization" \
  "USER_AUTHORIZED"
set_field "${i01_unreachable_queued_dir}/README.md" "ActiveTaskCard" "NONE"
set_field "${i01_unreachable_queued_dir}/README.md" "BusinessImplementation" "USER_AUTHORIZED"
set_table_status "${i01_unreachable_queued_dir}/README.md" "W1-I00" "READY" "DONE"
set_table_status \
  "${i01_unreachable_queued_dir}/README.md" \
  "W1-I01" \
  "BLOCKED_BY_USER_AUTHORIZATION" \
  "QUEUED"
expect_failure \
  "${i01_unreachable_queued_dir}" \
  "W1-I01 must be READY or DONE after authorization"

complete_dir="${test_tmp_root}/complete"
cp -R "${cards_dir}" "${complete_dir}"
for complete_card in "${complete_dir}"/W1-I*.md; do
  complete_task_id="$(sed -n 's/^TaskCardID = //p' "${complete_card}")"
  complete_old_status="$(sed -n 's/^Status = //p' "${complete_card}")"
  set_field "${complete_card}" "Status" "DONE"
  set_table_status \
    "${complete_dir}/README.md" \
    "${complete_task_id}" \
    "${complete_old_status}" \
    "DONE"
  if [[ "${complete_task_id}" != "W1-I00" ]]; then
    set_field "${complete_card}" "BusinessImplementationAuthorization" "USER_AUTHORIZED"
  fi
done
set_field "${complete_dir}/W1-I02-source-persistence.md" "FormalDatabaseGate" "PASS"
set_field "${complete_dir}/README.md" "TaskCardSetStatus" "COMPLETE"
set_field "${complete_dir}/README.md" "ActiveTaskCard" "NONE"
set_field "${complete_dir}/README.md" "BusinessImplementation" "USER_AUTHORIZED"
complete_output="$("${verifier}" --cards-dir "${complete_dir}")" ||
  fail "valid complete state was rejected"
assert_contains "${complete_output}" "TaskCardSetStatus = COMPLETE"

ready_from_authorized_dir="${test_tmp_root}/ready-from-authorized"
make_ready_i00_fixture "${authorized_i01_dir}" "${ready_from_authorized_dir}"
ready_from_authorized_output="$(
  "${verifier}" --cards-dir "${ready_from_authorized_dir}"
)" || fail "I01-authorized state did not normalize to the I00 READY bootstrap state"
assert_contains \
  "${ready_from_authorized_output}" \
  "TaskCardSetStatus = READY_FOR_EXECUTION"
assert_contains "${ready_from_authorized_output}" "ActiveTaskCard = W1-I00"
bootstrap_normalization_cases=$((bootstrap_normalization_cases + 1))

ready_from_complete_dir="${test_tmp_root}/ready-from-complete"
make_ready_i00_fixture "${complete_dir}" "${ready_from_complete_dir}"
ready_from_complete_output="$(
  "${verifier}" --cards-dir "${ready_from_complete_dir}"
)" || fail "complete state did not normalize to the I00 READY bootstrap state"
assert_contains \
  "${ready_from_complete_output}" \
  "TaskCardSetStatus = READY_FOR_EXECUTION"
assert_contains "${ready_from_complete_output}" "ActiveTaskCard = W1-I00"
bootstrap_normalization_cases=$((bootstrap_normalization_cases + 1))

incomplete_complete_dir="${test_tmp_root}/incomplete-complete"
cp -R "${complete_dir}" "${incomplete_complete_dir}"
set_field \
  "${incomplete_complete_dir}/W1-I13-fixed-implementation-review.md" \
  "Status" \
  "QUEUED"
set_table_status \
  "${incomplete_complete_dir}/README.md" \
  "W1-I13" \
  "DONE" \
  "QUEUED"
expect_failure \
  "${incomplete_complete_dir}" \
  "complete state requires all cards DONE"

i01_authorization_block_drift_dir="${test_tmp_root}/i01-authorization-block-drift"
cp -R "${cards_dir}" "${i01_authorization_block_drift_dir}"
set_field \
  "${i01_authorization_block_drift_dir}/W1-I01-source-ingestion-domain.md" \
  "Status" \
  "BLOCKED_BY_DEPENDENCY"
set_table_status \
  "${i01_authorization_block_drift_dir}/README.md" \
  "W1-I01" \
  "BLOCKED_BY_USER_AUTHORIZATION" \
  "BLOCKED_BY_DEPENDENCY"
expect_failure \
  "${i01_authorization_block_drift_dir}" \
  "W1-I01 must remain blocked by user authorization"

blocked_authorization_dir="${test_tmp_root}/blocked-authorization-terminal"
cp -R "${cards_dir}" "${blocked_authorization_dir}"
set_field "${blocked_authorization_dir}/W1-I00-implementation-governance.md" "Status" "DONE"
set_field "${blocked_authorization_dir}/README.md" "ActiveTaskCard" "NONE"
set_field "${blocked_authorization_dir}/README.md" \
  "TaskCardSetStatus" "BLOCKED_BY_USER_AUTHORIZATION"
set_table_status "${blocked_authorization_dir}/README.md" "W1-I00" "READY" "DONE"
blocked_output="$("${verifier}" --cards-dir "${blocked_authorization_dir}")" ||
  fail "valid blocked authorization terminal state was rejected"
assert_contains "${blocked_output}" "TaskCardSetStatus = BLOCKED_BY_USER_AUTHORIZATION"
assert_contains "${blocked_output}" "ActiveTaskCard = NONE"

printf '%s\n' \
  "Wave1ImplementationTaskCardContractTests = PASS" \
  "PositiveCases = 2" \
  "CanonicalStateCases = 1" \
  "NegativeCases = ${negative_cases}" \
  "BootstrapNormalizationCases = ${bootstrap_normalization_cases}" \
  "AuthorizedI01Cases = 1" \
  "CompleteTerminalCases = 1" \
  "BlockedAuthorizationTerminalCases = 1"
