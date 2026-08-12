#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-wave1-implementation-cards"
cards_dir="${repo_root}/docs/task-cards/wave-1-implementation"
canonical_cards_dir="${cards_dir}"
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

field_value() {
  local file="$1"
  local field="$2"
  sed -n "s/^${field} = //p" "${file}"
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
  if grep -q '^SuspendedTaskCard = ' "${destination_dir}/README.md"; then
    set_field "${destination_dir}/README.md" "SuspendedTaskCard" "NONE"
    set_field "${destination_dir}/README.md" "SuspendedCandidateSHA" "NONE"
    set_field "${destination_dir}/README.md" "SuspendedCandidateMutation" "NONE"
  fi
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

# The visual-style lane must atomically suspend exactly W1-I03 at its reviewed
# candidate. This positive case is deliberately executed before the mutations
# below so the pre-feature validator produces the required RED.
suspended_dir="${test_tmp_root}/suspended"
cp -R "${canonical_cards_dir}" "${suspended_dir}"
set_field "${suspended_dir}/README.md" "TaskCardSetStatus" "SUSPENDED_BY_USER"
set_field "${suspended_dir}/README.md" "ActiveTaskCard" "NONE"
set_field "${suspended_dir}/README.md" "BusinessImplementation" "USER_AUTHORIZED"
if grep -q '^SuspendedTaskCard = ' "${suspended_dir}/README.md"; then
  set_field "${suspended_dir}/README.md" "SuspendedTaskCard" "W1-I03"
  set_field "${suspended_dir}/README.md" "SuspendedCandidateSHA" \
    "4e63936c631ab34807e714b90d30415a959bc13d"
  set_field "${suspended_dir}/README.md" "SuspendedCandidateMutation" "FORBIDDEN"
else
  sed -i.bak \
    '/^TaskCardSetStatus = SUSPENDED_BY_USER$/a\
SuspendedTaskCard = W1-I03\
SuspendedCandidateSHA = 4e63936c631ab34807e714b90d30415a959bc13d\
SuspendedCandidateMutation = FORBIDDEN' \
    "${suspended_dir}/README.md"
  rm "${suspended_dir}/README.md.bak"
fi
set_field "${suspended_dir}/W1-I03-docx-security-gate.md" "Status" "SUSPENDED_BY_USER"
set_table_status \
  "${suspended_dir}/README.md" \
  "W1-I03" \
  "READY" \
  "SUSPENDED_BY_USER"
suspended_output="$(
  "${verifier}" \
    --repo-root "${repo_root}" \
    --cards-dir "${suspended_dir}"
)" || fail "valid W1-I03 suspension was rejected"
assert_contains "${suspended_output}" "TaskCardSetStatus = SUSPENDED_BY_USER"
assert_contains "${suspended_output}" "ActiveTaskCard = NONE"

suspended_ready_dir="${test_tmp_root}/suspended-ready"
cp -R "${suspended_dir}" "${suspended_ready_dir}"
set_field "${suspended_ready_dir}/W1-I02-source-persistence.md" "Status" "READY"
set_field "${suspended_ready_dir}/W1-I02-source-persistence.md" \
  "BusinessImplementationAuthorization" "USER_AUTHORIZED"
set_field "${suspended_ready_dir}/W1-I02-source-persistence.md" \
  "FormalDatabaseGate" "PASS"
set_table_status \
  "${suspended_ready_dir}/README.md" \
  "W1-I02" \
  "QUEUED" \
  "READY"
expect_failure "${suspended_ready_dir}" "suspended state cannot have a READY card"

suspended_active_dir="${test_tmp_root}/suspended-active"
cp -R "${suspended_dir}" "${suspended_active_dir}"
set_field "${suspended_active_dir}/README.md" "ActiveTaskCard" "W1-I03"
expect_failure "${suspended_active_dir}" "suspended state must have no active card"

wrong_suspended_card_dir="${test_tmp_root}/wrong-suspended-card"
cp -R "${suspended_dir}" "${wrong_suspended_card_dir}"
set_field "${wrong_suspended_card_dir}/README.md" "SuspendedTaskCard" "W1-I04"
expect_failure "${wrong_suspended_card_dir}" "SuspendedTaskCard must be W1-I03"

two_suspended_cards_dir="${test_tmp_root}/two-suspended-cards"
cp -R "${suspended_dir}" "${two_suspended_cards_dir}"
set_field "${two_suspended_cards_dir}/W1-I04-text-list-section-parser.md" "Status" "SUSPENDED_BY_USER"
set_table_status \
  "${two_suspended_cards_dir}/README.md" \
  "W1-I04" \
  "BLOCKED_BY_DEPENDENCY" \
  "SUSPENDED_BY_USER"
expect_failure "${two_suspended_cards_dir}" "SUSPENDED_BY_USER is allowed only for W1-I03"

status_disagreement_dir="${test_tmp_root}/suspended-status-disagreement"
cp -R "${suspended_dir}" "${status_disagreement_dir}"
set_table_status \
  "${status_disagreement_dir}/README.md" \
  "W1-I03" \
  "SUSPENDED_BY_USER" \
  "READY"
expect_failure "${status_disagreement_dir}" "README.md: status mismatch for W1-I03"

for suspension_field in SuspendedTaskCard SuspendedCandidateSHA SuspendedCandidateMutation; do
  missing_field_dir="${test_tmp_root}/missing-${suspension_field}"
  cp -R "${suspended_dir}" "${missing_field_dir}"
  sed -i.bak "/^${suspension_field} = /d" "${missing_field_dir}/README.md"
  rm "${missing_field_dir}/README.md.bak"
  expect_failure "${missing_field_dir}" "${suspension_field} must occur exactly once"

  duplicate_field_dir="${test_tmp_root}/duplicate-${suspension_field}"
  cp -R "${suspended_dir}" "${duplicate_field_dir}"
  field_literal="$(field_value "${duplicate_field_dir}/README.md" "${suspension_field}")"
  printf '%s = %s\n' "${suspension_field}" "${field_literal}" >> \
    "${duplicate_field_dir}/README.md"
  expect_failure "${duplicate_field_dir}" "${suspension_field} must occur exactly once"
done

for invalid_sha in short zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz 70eefba5912e6884e4e7e1d6477a65f4091d6590; do
  invalid_sha_dir="${test_tmp_root}/invalid-suspended-sha-${invalid_sha}"
  cp -R "${suspended_dir}" "${invalid_sha_dir}"
  set_field "${invalid_sha_dir}/README.md" "SuspendedCandidateSHA" "${invalid_sha}"
  expect_failure "${invalid_sha_dir}" "SuspendedCandidateSHA must equal the frozen W1-I03 candidate"
done

mutation_policy_dir="${test_tmp_root}/wrong-suspended-mutation-policy"
cp -R "${suspended_dir}" "${mutation_policy_dir}"
set_field "${mutation_policy_dir}/README.md" "SuspendedCandidateMutation" "ALLOWED"
expect_failure "${mutation_policy_dir}" "SuspendedCandidateMutation must be FORBIDDEN"

suspended_business_dir="${test_tmp_root}/suspended-business-drift"
cp -R "${suspended_dir}" "${suspended_business_dir}"
set_field "${suspended_business_dir}/README.md" "BusinessImplementation" "NOT_AUTHORIZED"
expect_failure "${suspended_business_dir}" "README.md: BusinessImplementation projection mismatch"

for released_id in W1-I02 W1-I04; do
  if [[ "${released_id}" == "W1-I02" ]]; then
    released_file="W1-I02-source-persistence.md"
  else
    released_file="W1-I04-text-list-section-parser.md"
  fi
  released_dir="${test_tmp_root}/suspended-released-${released_id}"
  cp -R "${suspended_dir}" "${released_dir}"
  old_status="$(field_value "${released_dir}/${released_file}" "Status")"
  set_field "${released_dir}/${released_file}" "Status" "READY"
  set_field "${released_dir}/${released_file}" \
    "BusinessImplementationAuthorization" "USER_AUTHORIZED"
  if [[ "${released_id}" == "W1-I02" ]]; then
    set_field "${released_dir}/${released_file}" "FormalDatabaseGate" "PASS"
  fi
  set_table_status "${released_dir}/README.md" "${released_id}" "${old_status}" "READY"
  if [[ "${released_id}" == "W1-I02" ]]; then
    expect_failure "${released_dir}" "suspended state cannot have a READY card"
  else
    expect_failure "${released_dir}" "must remain BLOCKED_BY_DEPENDENCY until dependencies are DONE"
  fi
done

suspension_mutation_cases=18

# Real Git fixtures prove the fixed production tree remains frozen and the
# eventual restore is an exact ten-path direct-child receipt.
transition_repo_root="${test_tmp_root}/transition-repo"
git clone --shared -q "${repo_root}" "${transition_repo_root}"
transition_paths=(
  AGENTS.md
  README.md
  docs/design/wave-1/README.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-plan.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1/README.md
  docs/task-cards/wave-1-implementation/README.md
  docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md
)
for transition_path in "${transition_paths[@]}"; do
  mkdir -p "${transition_repo_root}/$(dirname "${transition_path}")"
  cp "${repo_root}/${transition_path}" "${transition_repo_root}/${transition_path}"
done
mkdir -p "${transition_repo_root}/docs/task-cards/visual-style-baseline"
cp -R "${repo_root}/docs/task-cards/visual-style-baseline/." \
  "${transition_repo_root}/docs/task-cards/visual-style-baseline/"
transition_state="${transition_repo_root}/docs/task-cards/visual-style-baseline/execution-state.md"
set_field "${transition_state}" "TaskCardSetStatus" "STOPPED_BY_USER"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "CurrentGateStatus" "STOPPED_BY_USER"
set_field "${transition_state}" "CurrentReviewRoute" "NONE"
set_field "${transition_state}" "CurrentReviewVerdict" "NOT_APPLICABLE_USER_STOP"
set_field "${transition_state}" "TransitionSequence" "1"
set_field "${transition_state}" "TransitionKind" "STOP_BY_USER"
set_field "${transition_state}" "VisualImplementation" "STOPPED_BY_USER"
set_field "${transition_state}" "UserStopAuthorization" "EXPLICIT_USER_INSTRUCTION"
git -C "${transition_repo_root}" add "${transition_paths[@]}" \
  docs/task-cards/visual-style-baseline
git -C "${transition_repo_root}" commit -qm "test: suspend W1-I03 for visual lane"
suspension_git_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"

mkdir -p "${transition_repo_root}/docs/task-cards/visual-style-baseline"
printf '%s\n' 'allowed visual governance change' > \
  "${transition_repo_root}/docs/task-cards/visual-style-baseline/example.md"
git -C "${transition_repo_root}" add docs/task-cards/visual-style-baseline/example.md
git -C "${transition_repo_root}" commit -qm "docs: allowed VSB change"
allowed_visual_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" >/dev/null ||
  fail "allowed visual-lane commit invalidated the frozen W1-I03 candidate"

for projection_path in \
  docs/engineering/cognitura-wave-1-design-plan.md \
  docs/task-cards/wave-1/README.md; do
  set_field \
    "${transition_repo_root}/${projection_path}" \
    "ActiveImplementationGovernanceTaskCard" \
    "W1-I03"
  if projection_output="$(
    "${verifier}" \
      --repo-root "${transition_repo_root}" \
      --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" 2>&1
  )"; then
    fail "suspended projection ${projection_path} unexpectedly kept W1-I03 active"
  fi
  assert_contains "${projection_output}" "ActiveImplementationGovernanceTaskCard projection mismatch"
  git -C "${transition_repo_root}" restore "${projection_path}"
done

production_mutation_branch="production-mutation"
git -C "${transition_repo_root}" switch -qc "${production_mutation_branch}"
printf '\n// forbidden frozen mutation\n' >> \
  "${transition_repo_root}/server/src/main/java/io/cognitura/source/docx/security/DocxSecurityGate.java"
git -C "${transition_repo_root}" add \
  server/src/main/java/io/cognitura/source/docx/security/DocxSecurityGate.java
git -C "${transition_repo_root}" commit -qm "test: mutate frozen W1-I03 path"
if production_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" 2>&1
)"; then
  fail "frozen W1-I03 production mutation unexpectedly passed"
fi
assert_contains "${production_output}" "frozen W1-I03 production paths changed"

make_restore_projection() {
  local fixture_root="$1"
  set_field "${fixture_root}/AGENTS.md" "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/AGENTS.md" "ActiveImplementationTaskCard" "W1-I03"
  set_field "${fixture_root}/README.md" "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/README.md" "ActiveImplementationTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/design/wave-1/README.md" "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/design/wave-1/README.md" "ActiveImplementationGovernanceTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" "ActiveTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" "ActiveTaskCardStatus" "READY"
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" "ActiveImplementationTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" "ActiveImplementationGovernanceTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" "ImplementationTaskCardPlanStatus" "I01_COMPLETE_I03_READY"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" "ActiveImplementationGovernanceTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" "TaskCardSetStatus" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" "ActiveTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" "SuspendedTaskCard" "NONE"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" "SuspendedCandidateSHA" "NONE"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" "SuspendedCandidateMutation" "NONE"
  set_table_status \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    "W1-I03" \
    "SUSPENDED_BY_USER" \
    "READY"
  set_field "${fixture_root}/docs/task-cards/wave-1/README.md" "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/task-cards/wave-1/README.md" "ActiveImplementationGovernanceTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" "TaskCardSetStatus" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" "ActiveTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" "SuspendedTaskCard" "NONE"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" "SuspendedCandidateSHA" "NONE"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" "SuspendedCandidateMutation" "NONE"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" "ReadyTaskCardCount" "1"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" "SuspendedTaskCardCount" "0"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md" "Status" "READY"
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "W1-I03" \
    "SUSPENDED_BY_USER" \
    "READY"
}

git -C "${transition_repo_root}" switch -q --detach "${allowed_visual_sha}"
make_restore_projection "${transition_repo_root}"
git -C "${transition_repo_root}" add "${transition_paths[@]}"
git -C "${transition_repo_root}" commit -qm "test: restore W1-I03"
restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
restore_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${allowed_visual_sha}" \
    --transition-head "${restore_sha}"
)" || fail "valid stopped-state W1-I03 restore was rejected"
assert_contains "${restore_output}" "TaskCardSetStatus = READY_FOR_EXECUTION"
assert_contains "${restore_output}" "ActiveTaskCard = W1-I03"

git -C "${transition_repo_root}" switch -q --detach "${allowed_visual_sha}"
set_field \
  "${transition_repo_root}/docs/design/wave-1/README.md" \
  "ActiveImplementationGovernanceTaskCard" \
  "W1-I03"
git -C "${transition_repo_root}" add \
  docs/design/wave-1/README.md
git -C "${transition_repo_root}" commit -qm \
  "test: drift a central suspension projection before restore"
base_projection_drift_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
make_restore_projection "${transition_repo_root}"
git -C "${transition_repo_root}" add "${transition_paths[@]}"
git -C "${transition_repo_root}" commit -qm \
  "test: restore over a drifted central suspension projection"
base_projection_drift_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if base_projection_drift_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${base_projection_drift_sha}" \
    --transition-head "${base_projection_drift_restore_sha}" 2>&1
)"; then
  fail "restore from a drifted central suspension projection unexpectedly passed"
fi
assert_contains "${base_projection_drift_output}" \
  "restore transition BASE must preserve exact suspended projection"

git -C "${transition_repo_root}" switch -q --detach "${allowed_visual_sha}"
make_restore_projection "${transition_repo_root}"
set_field \
  "${transition_repo_root}/docs/task-cards/wave-1-implementation/README.md" \
  "SuspendedTaskCard" \
  "W1-I03"
git -C "${transition_repo_root}" add "${transition_paths[@]}"
git -C "${transition_repo_root}" commit -qm "test: retain suspended field during restore"
residual_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if residual_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${allowed_visual_sha}" \
    --transition-head "${residual_restore_sha}" 2>&1
)"; then
  fail "restore with a residual suspended field unexpectedly passed"
fi
assert_contains "${residual_output}" "clear suspended fields"

git -C "${transition_repo_root}" switch -q --detach "${allowed_visual_sha}"
make_restore_projection "${transition_repo_root}"
set_field \
  "${transition_repo_root}/docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md" \
  "Status" \
  "QUEUED"
set_table_status \
  "${transition_repo_root}/docs/task-cards/wave-1-implementation/README.md" \
  "W1-I03" \
  "READY" \
  "QUEUED"
set_field \
  "${transition_repo_root}/docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md" \
  "Status" \
  "READY"
set_field \
  "${transition_repo_root}/docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md" \
  "BusinessImplementationAuthorization" \
  "USER_AUTHORIZED"
set_field \
  "${transition_repo_root}/docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md" \
  "FormalDatabaseGate" \
  "PASS"
set_table_status \
  "${transition_repo_root}/docs/task-cards/wave-1-implementation/README.md" \
  "W1-I02" \
  "QUEUED" \
  "READY"
set_field \
  "${transition_repo_root}/docs/task-cards/wave-1-implementation/README.md" \
  "ActiveTaskCard" \
  "W1-I02"
git -C "${transition_repo_root}" add "${transition_paths[@]}" \
  docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md
git -C "${transition_repo_root}" commit -qm "test: restore the wrong Wave 1 card"
wrong_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if wrong_restore_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${allowed_visual_sha}" \
    --transition-head "${wrong_restore_sha}" 2>&1
)"; then
  fail "restore releasing W1-I02 unexpectedly passed"
fi
assert_contains "${wrong_restore_output}" "exact ten projection paths"

git -C "${transition_repo_root}" switch -q --detach "${allowed_visual_sha}"
make_restore_projection "${transition_repo_root}"
printf '\n// forbidden restore mutation\n' >> \
  "${transition_repo_root}/server/src/main/java/io/cognitura/source/docx/security/DocxSecurityGate.java"
git -C "${transition_repo_root}" add "${transition_paths[@]}" \
  server/src/main/java/io/cognitura/source/docx/security/DocxSecurityGate.java
git -C "${transition_repo_root}" commit -qm "test: mix production path into restore"
production_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if production_restore_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${allowed_visual_sha}" \
    --transition-head "${production_restore_sha}" 2>&1
)"; then
  fail "restore containing a production path unexpectedly passed"
fi
assert_contains "${production_restore_output}" "exact ten projection paths"

git -C "${transition_repo_root}" switch -q --detach "${allowed_visual_sha}"
set_field "${transition_state}" "UserStopAuthorization" "NONE"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm "test: remove stop authorization"
unauthorized_stop_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
make_restore_projection "${transition_repo_root}"
git -C "${transition_repo_root}" add "${transition_paths[@]}"
git -C "${transition_repo_root}" commit -qm "test: restore after unauthorized stop"
unauthorized_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if unauthorized_restore_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${unauthorized_stop_sha}" \
    --transition-head "${unauthorized_restore_sha}" 2>&1
)"; then
  fail "restore after a stop without explicit authorization unexpectedly passed"
fi
assert_contains "${unauthorized_restore_output}" "explicit user-stop authorization"

git -C "${transition_repo_root}" switch -q --detach "${allowed_visual_sha}"
make_restore_projection "${transition_repo_root}"
set_field "${transition_repo_root}/AGENTS.md" \
  "FormalDatabaseWrite" "AUTHORIZED"
git -C "${transition_repo_root}" add "${transition_paths[@]}"
git -C "${transition_repo_root}" commit -qm \
  "test: alter database authorization during restore"
authorization_drift_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if authorization_drift_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${allowed_visual_sha}" \
    --transition-head "${authorization_drift_sha}" 2>&1
)"; then
  fail "restore altering FormalDatabaseWrite unexpectedly passed"
fi
assert_contains "${authorization_drift_output}" \
  "restore transition must preserve authorization and non-restored content"

git -C "${transition_repo_root}" switch -q --detach "${allowed_visual_sha}"
for forged_index in 0 1 2; do
  set_field "${transition_state}" "VSB0${forged_index}CandidateSHA" \
    "${allowed_visual_sha}"
  set_field "${transition_state}" "VSB0${forged_index}GateStatus" \
    "VSB-G${forged_index}_PASS"
  set_field "${transition_state}" "VSB0${forged_index}ReviewVerdict" \
    "GO_P0_0_P1_0_P2_0"
done
set_field "${transition_state}" "VSB03CandidateSHA" "${allowed_visual_sha}"
set_field "${transition_state}" "VSB03GateStatus" "VSB-G3_PASS"
set_field "${transition_state}" "VSB03DeepReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB03UltraReviewVerdict" "FINAL_GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "TaskCardSetStatus" "COMPLETE"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00,VSB-01,VSB-02,VSB-03"
set_field "${transition_state}" "CurrentCandidateSHA" "${allowed_visual_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G3_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer+ultra_gatekeeper"
set_field "${transition_state}" "CurrentReviewVerdict" "FINAL_GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "TransitionSequence" "5"
set_field "${transition_state}" "TransitionKind" "COMPLETE"
set_field "${transition_state}" "TransitionBaseSHA" "${allowed_visual_sha}"
set_field "${transition_state}" "VisualImplementation" "COMPLETE"
set_field "${transition_state}" "UserStopAuthorization" "NONE"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm "test: forge VSB COMPLETE ledger"
forged_complete_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
make_restore_projection "${transition_repo_root}"
git -C "${transition_repo_root}" add "${transition_paths[@]}"
git -C "${transition_repo_root}" commit -qm \
  "test: restore from forged VSB COMPLETE ledger"
forged_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if forged_restore_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${forged_complete_sha}" \
    --transition-head "${forged_restore_sha}" 2>&1
)"; then
  fail "restore from a forged COMPLETE VSB ledger unexpectedly passed"
fi
assert_contains "${forged_restore_output}" "VSB base tree validation failed"

nonancestor_repo_root="${test_tmp_root}/nonancestor-repo"
git clone --shared -q "${repo_root}" "${nonancestor_repo_root}"
git -C "${nonancestor_repo_root}" switch -q --detach \
  4e63936c631ab34807e714b90d30415a959bc13d^
for transition_path in "${transition_paths[@]}"; do
  mkdir -p "${nonancestor_repo_root}/$(dirname "${transition_path}")"
  cp "${repo_root}/${transition_path}" "${nonancestor_repo_root}/${transition_path}"
done
git -C "${nonancestor_repo_root}" add "${transition_paths[@]}"
git -C "${nonancestor_repo_root}" commit -qm "test: suspend from unrelated history"
if nonancestor_output="$(
  "${verifier}" \
    --repo-root "${nonancestor_repo_root}" \
    --cards-dir "${nonancestor_repo_root}/docs/task-cards/wave-1-implementation" 2>&1
)"; then
  fail "non-ancestor frozen W1-I03 candidate unexpectedly passed"
fi
assert_contains "${nonancestor_output}" "SuspendedCandidateSHA must be an ancestor of HEAD"

git_transition_cases=10

printf '%s\n' \
  "Wave1ImplementationTaskCardContractTests = PASS" \
  "PositiveCases = 2" \
  "CanonicalStateCases = 1" \
  "NegativeCases = ${negative_cases}" \
  "BootstrapNormalizationCases = ${bootstrap_normalization_cases}" \
  "AuthorizedI01Cases = 1" \
  "CompleteTerminalCases = 1" \
  "BlockedAuthorizationTerminalCases = 1" \
  "SuspensionMutationCases = ${suspension_mutation_cases}" \
  "GitTransitionCases = ${git_transition_cases}"
