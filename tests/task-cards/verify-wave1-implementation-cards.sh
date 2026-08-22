#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-wave1-implementation-cards"
cards_dir="${repo_root}/docs/task-cards/wave-1-implementation"
canonical_cards_dir="${cards_dir}"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-wave1-implementation-cards.XXXXXX")"
fixed_lifecycle_fixture_sha="c4d1f4342b16d2110369c4eefea5665edce0614d"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

w1_i03_closure_contract_only=0
w1_i04_closure_contract_only=0
w1_i05_verifier_recovery_contract_only=0
w1_i05_closure_contract_only=0
w1_i06_entry_repair_contract_only=0
w1_i06_copy_inference_repair_contract_only=0
w1_i06_closure_contract_only=0
w1_i02_database_gate_contract_only=0
w1_i02_closure_contract_only=0
w1_i07_closure_contract_only=0
w1_i08_closure_contract_only=0
w1_i09_runtime_rebaseline_contract_only=0
w1_i09_product_copy_inference_contract_only=0
w1_i09_canonical_bridge_contract_only=0
w1_i09_v2_compatibility_contract_only=0
w1_i09_final_review_finding_contract_only=0
w1_i09_closure_contract_only=0
w1_i10_closure_contract_only=0
w1_i11_persistence_rebaseline_contract_only=0
w1_i11_migration_count_rebaseline_contract_only=0
terra_first_routing_contract_only=0
case "${1:-}" in
  "") ;;
  --w1-i03-closure-contract-only)
    w1_i03_closure_contract_only=1
    ;;
  --w1-i04-closure-contract-only)
    w1_i04_closure_contract_only=1
    ;;
  --w1-i05-verifier-recovery-contract-only)
    w1_i05_verifier_recovery_contract_only=1
    ;;
  --w1-i05-closure-contract-only)
    w1_i05_closure_contract_only=1
    ;;
  --w1-i06-entry-repair-contract-only)
    w1_i06_entry_repair_contract_only=1
    ;;
  --w1-i06-copy-inference-repair-contract-only)
    w1_i06_copy_inference_repair_contract_only=1
    ;;
  --w1-i06-closure-contract-only)
    w1_i06_closure_contract_only=1
    ;;
  --w1-i02-database-gate-contract-only)
    w1_i02_database_gate_contract_only=1
    ;;
  --w1-i02-closure-contract-only)
    w1_i02_closure_contract_only=1
    ;;
  --w1-i07-closure-contract-only)
    w1_i07_closure_contract_only=1
    ;;
  --w1-i08-closure-contract-only)
    w1_i08_closure_contract_only=1
    ;;
  --w1-i09-runtime-rebaseline-contract-only)
    w1_i09_runtime_rebaseline_contract_only=1
    ;;
  --w1-i09-product-copy-inference-contract-only)
    w1_i09_product_copy_inference_contract_only=1
    ;;
  --w1-i09-canonical-bridge-contract-only)
    w1_i09_canonical_bridge_contract_only=1
    ;;
  --w1-i09-v2-compatibility-contract-only)
    w1_i09_v2_compatibility_contract_only=1
    ;;
  --w1-i09-final-review-finding-contract-only)
    w1_i09_final_review_finding_contract_only=1
    ;;
  --w1-i09-closure-contract-only)
    w1_i09_closure_contract_only=1
    ;;
  --w1-i10-closure-contract-only)
    w1_i10_closure_contract_only=1
    ;;
  --w1-i11-persistence-rebaseline-contract-only)
    w1_i11_persistence_rebaseline_contract_only=1
    ;;
  --w1-i11-migration-count-rebaseline-contract-only)
    w1_i11_migration_count_rebaseline_contract_only=1
    ;;
  --terra-first-routing-contract-only)
    terra_first_routing_contract_only=1
    ;;
  *) fail "unknown argument: $1" ;;
esac

git -C "${repo_root}" cat-file -e "${fixed_lifecycle_fixture_sha}^{commit}" 2>/dev/null ||
  fail "fixed lifecycle fixture commit is unavailable: ${fixed_lifecycle_fixture_sha}"

fixed_suspension_paths=(
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

checkout_fixed_suspension_fixture() {
  local fixture_root="$1"
  git -C "${fixture_root}" checkout -q --detach \
    "${fixed_lifecycle_fixture_sha}"
}

restore_fixed_suspension_projection() {
  local fixture_root="$1"
  git -C "${fixture_root}" checkout -q "${fixed_lifecycle_fixture_sha}" -- \
    "${fixed_suspension_paths[@]}"
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

set_first_field() {
  local file="$1"
  local field="$2"
  local value="$3"
  FIRST_FIELD="${field}" FIRST_VALUE="${value}" perl -i.bak -pe '
    if (!$done && /^\Q$ENV{FIRST_FIELD}\E = /) {
      $_ = "$ENV{FIRST_FIELD} = $ENV{FIRST_VALUE}\n";
      $done = 1;
    }
  ' "${file}"
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

i03_closure_origin_sha="cc25439de8019a4434c2ab5aba8b32927240d8b4"
i03_reviewed_candidate_sha="4e63936c631ab34807e714b90d30415a959bc13d"
i03_closure_tmpdir=""
i03_closure_governance_paths=(
  docs/superpowers/specs/2026-08-20-cognitura-w1-i03-closure-design.md
  docs/superpowers/plans/2026-08-20-cognitura-w1-i03-closure.md
  tests/task-cards/verify-wave1-implementation-cards.sh
  scripts/verify-wave1-implementation-cards
)
i03_closure_projection_paths=(
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
  docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md
)
i03_ready_narrative_paths=(
  AGENTS.md
  AGENTS.md
  README.md
  README.md
  docs/design/wave-1/README.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-plan.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1/README.md
  docs/task-cards/wave-1-implementation/README.md
)
i03_ready_narratives=(
  '`W1-I02` 等待独立数据库 Gate，`W1-I03` 为唯一 `READY` 业务卡。'
  'I00；I01 已关闭，当前已原子释放 I03，I02 保持等待独立数据库 Gate。'
  '完成零发现深审并关闭；I02 等待独立数据库 Gate，`W1-I03` 是唯一 `READY` 卡。'
  '保持 `QUEUED` 等待独立数据库 Gate，`W1-I03` 已释放为唯一 `READY` 业务卡。'
  '  I01 已关闭，I02 等待独立数据库 Gate，I03 为唯一 `READY` 卡。'
  '`W1-I03` 已作为唯一 `READY` 卡释放。'
  $'当前业务授权只按既定卡集串行推进至 `W1-I03`；I02 独立数据库 Gate、正式数据库\n写入和远程推送仍未授权。'
  '固定候选深审并关闭；I02 等待独立数据库 Gate，I03 为唯一 `READY` 卡，完整证据记录在'
  '数据库 Gate，I03 为唯一 `READY` 卡。正式数据库、Parser/Object Storage Provider、'
  'I03 为唯一 `READY` 卡。'
  'I00 和 I01 已关闭；I02 等待独立数据库 Gate，W1-I03 为唯一 `READY` 业务卡。'
  '完成零发现深审并关闭；I02 等待独立数据库 Gate，I03 已原子释放为唯一 `READY` 卡。'
)
i04_ready_narratives=(
  '`W1-I02` 等待独立数据库 Gate；`W1-I03` 已零发现关闭，`W1-I04` 为唯一 `READY` 业务卡。'
  'I00、I01 和 I03 已关闭，当前已原子释放 I04；I02 保持等待独立数据库 Gate。'
  '完成零发现深审并关闭；I02 等待独立数据库 Gate，`W1-I04` 是唯一 `READY` 卡。'
  '保持 `QUEUED` 等待独立数据库 Gate；`W1-I03` 已关闭，`W1-I04` 已释放为唯一 `READY` 业务卡。'
  '  I01 和 I03 已关闭，I02 等待独立数据库 Gate，I04 为唯一 `READY` 卡。'
  '`W1-I03` 已零发现关闭，`W1-I04` 已作为唯一 `READY` 卡释放。'
  $'当前业务授权只按既定卡集串行推进至 `W1-I04`；I02 独立数据库 Gate、正式数据库\n写入和远程推送仍未授权。'
  '固定候选深审并关闭；I02 等待独立数据库 Gate，I03 已关闭且 I04 为唯一 `READY` 卡，完整证据记录在'
  '数据库 Gate；I03 已关闭，I04 为唯一 `READY` 卡。正式数据库、Parser/Object Storage Provider、'
  'I03 已关闭，I04 为唯一 `READY` 卡。'
  'I00、I01 和 I03 已关闭；I02 等待独立数据库 Gate，W1-I04 为唯一 `READY` 业务卡。'
  '完成零发现深审并关闭；I02 等待独立数据库 Gate，I03 已关闭且 I04 已原子释放为唯一 `READY` 卡。'
)
i03_review_mutation_fields=(
  ReviewLevel
  ReviewRoute
  ReviewEffort
  ReviewMultiplicity
  ReviewVerdict
  P0
  P1
  P2
  Ultra
  I03ClosureReleasedTaskCard
  QueuedTaskCard
  QueuedReason
)
i03_review_mutation_values=(
  L4
  ultra_gatekeeper
  high
  TWO
  NO_GO
  1
  1
  1
  EXECUTED
  W1-I05
  W1-I04
  NONE
)
i03_projection_field_paths=(
  AGENTS.md
  README.md
  docs/design/wave-1/README.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-plan.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1/README.md
  docs/task-cards/wave-1-implementation/README.md
)
i03_projection_field_names=(
  ActiveImplementationTaskCard
  ActiveImplementationTaskCard
  ActiveImplementationGovernanceTaskCard
  ActiveTaskCard
  ActiveImplementationTaskCard
  ActiveImplementationGovernanceTaskCard
  ImplementationTaskCardPlanStatus
  ActiveImplementationGovernanceTaskCard
  ActiveTaskCard
  ActiveImplementationGovernanceTaskCard
  ActiveTaskCard
)
i03_projection_field_wrong_values=(
  W1-I03
  W1-I03
  W1-I03
  W1-I03
  W1-I03
  W1-I03
  READY_FOR_EXECUTION
  W1-I03
  W1-I03
  W1-I03
  W1-I03
)
i03_projection_field_failure_messages=(
  'I03 closure projection field mismatch'
  'I03 closure projection field mismatch'
  'I03 closure projection field mismatch'
  'I03 closure projection field mismatch'
  'I03 closure projection field mismatch'
  'I03 closure projection field mismatch'
  'I03 closure projection field mismatch'
  'I03 closure projection field mismatch'
  'I03 closure projection field mismatch'
  'I03 closure projection field mismatch'
  'I03 closure receipt may release only W1-I04'
)
i03_projection_table_paths=(
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1-implementation/README.md
  docs/task-cards/wave-1-implementation/README.md
)
i03_projection_table_task_ids=(
  W1-I03
  W1-I04
  W1-I03
  W1-I04
)
i03_projection_table_head_statuses=(
  DONE
  READY
  DONE
  READY
)
i03_projection_table_wrong_statuses=(
  READY
  BLOCKED_BY_DEPENDENCY
  READY
  BLOCKED_BY_DEPENDENCY
)
i03_projection_table_failure_messages=(
  'I03 closure projection table mismatch'
  'I03 closure projection table mismatch'
  'I03 closure receipt must release exactly one READY card'
  'I03 closure receipt must release exactly one READY card'
)
i04_descendant_fixture_paths=(
  server/src/main/java/io/cognitura/source/docx/text/TextListSectionParser.java
  server/src/main/java/io/cognitura/source/docx/text/DocumentBlockCandidate.java
  server/src/main/java/io/cognitura/source/docx/text/SectionPathTracker.java
  server/src/main/java/io/cognitura/source/docx/text/ListSemantics.java
  server/src/main/java/io/cognitura/source/docx/text/SourceOrderCursor.java
  server/src/test/java/io/cognitura/source/docx/text/TextListSectionParserTest.java
  server/src/test/java/io/cognitura/source/docx/text/SectionPathTrackerTest.java
  server/src/test/resources/docx/text/fixture.txt
)

replace_i03_closure_text() {
  local file="$1"
  local old_text="$2"
  local new_text="$3"
  local label="$4"
  local content prefix suffix rewritten
  content="$(cat "${file}"; printf '\034')"
  [[ "${content}" == *"${old_text}"* ]] || fail "${label}: source block is missing"
  prefix="${content%%"${old_text}"*}"
  suffix="${content#*"${old_text}"}"
  [[ "${suffix}" != *"${old_text}"* ]] || fail "${label}: source block is duplicated"
  rewritten="${prefix}${new_text}${suffix}"
  printf '%s' "${rewritten%$'\034'}" > "${file}"
}

append_i03_review_receipt() {
  local fixture_root="$1"
  printf '%s\n' \
    '' \
    '## 8. I03 关闭收据' \
    '' \
    '```text' \
    'W1-I03 = DONE' \
    'ReviewedCandidate = 4e63936c631ab34807e714b90d30415a959bc13d' \
    'ReviewLevel = L3' \
    'ReviewRoute = deep_reviewer' \
    'ReviewEffort = xhigh' \
    'ReviewMultiplicity = ONE' \
    'ReviewVerdict = GO' \
    'P0 = 0' \
    'P1 = 0' \
    'P2 = 0' \
    'Ultra = NOT_RUN' \
    'I03ClosureReleasedTaskCard = W1-I04' \
    'QueuedTaskCard = W1-I02' \
    'QueuedReason = INDEPENDENT_DATABASE_GATE_REQUIRED' \
    '```' >> \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
}

make_i03_closure_projection() {
  local fixture_root="$1"
  local narrative_index narrative_path
  set_field "${fixture_root}/AGENTS.md" "ActiveImplementationTaskCard" "W1-I04"
  set_field "${fixture_root}/README.md" "ActiveImplementationTaskCard" "W1-I04"
  set_field "${fixture_root}/docs/design/wave-1/README.md" \
    "ActiveImplementationGovernanceTaskCard" "W1-I04"
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    "ActiveTaskCard" "W1-I04"
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    "ActiveImplementationTaskCard" "W1-I04"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    "ActiveImplementationGovernanceTaskCard" "W1-I04"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    "ImplementationTaskCardPlanStatus" "I03_COMPLETE_I04_READY"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    "ActiveImplementationGovernanceTaskCard" "W1-I04"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    "ActiveTaskCard" "W1-I04"
  set_table_status \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    "W1-I03" "READY" "DONE"
  set_table_status \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    "W1-I04" "BLOCKED_BY_DEPENDENCY" "READY"
  set_field "${fixture_root}/docs/task-cards/wave-1/README.md" \
    "ActiveImplementationGovernanceTaskCard" "W1-I04"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "ActiveTaskCard" "W1-I04"
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "W1-I03" "READY" "DONE"
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "W1-I04" "BLOCKED_BY_DEPENDENCY" "READY"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md" \
    "Status" "DONE"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md" \
    "Status" "READY"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md" \
    "BusinessImplementationAuthorization" "USER_AUTHORIZED"
  append_i03_review_receipt "${fixture_root}"
  for narrative_index in "${!i03_ready_narratives[@]}"; do
    narrative_path="${i03_ready_narrative_paths[${narrative_index}]}"
    replace_i03_closure_text \
      "${fixture_root}/${narrative_path}" \
      "${i03_ready_narratives[${narrative_index}]}" \
      "${i04_ready_narratives[${narrative_index}]}" \
      "close I03 narrative ${narrative_path}"
  done
}

materialize_i03_governance_path() {
  local fixture_root="$1"
  local relative_path="$2"
  local mode="$3"
  local commit_message="$4"
  mkdir -p "$(dirname "${fixture_root}/${relative_path}")"
  cp "${repo_root}/${relative_path}" "${fixture_root}/${relative_path}"
  chmod "${mode}" "${fixture_root}/${relative_path}"
  if git -C "${fixture_root}" cat-file -e "HEAD:${relative_path}" 2>/dev/null &&
    git -C "${fixture_root}" diff --quiet -- "${relative_path}"; then
    printf '%s\n' '# tests-only RED fixture governance marker' >> \
      "${fixture_root}/${relative_path}"
  fi
  git -C "${fixture_root}" add "${relative_path}"
  git -C "${fixture_root}" commit -qm "${commit_message}"
}

assert_i03_closure_tmp_clean() {
  local residue
  residue="$(find "${i03_closure_tmpdir}" -mindepth 1 -maxdepth 1 \
    ! -name sibling-marker -print -quit)"
  [[ -z "${residue}" ]] || fail "I03 closure verifier left invocation TMPDIR residue: ${residue}"
  [[ -f "${i03_closure_tmpdir}/sibling-marker" ]] ||
    fail "I03 closure verifier removed the TMPDIR sibling marker"
}

expect_i03_closure_static_failure() {
  local fixture_root="$1"
  local expected_message="$2"
  local output
  if output="$(TMPDIR="${i03_closure_tmpdir}" "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" 2>&1)"; then
    fail "invalid I03 closure static state unexpectedly passed at $(git -C "${fixture_root}" log -1 --format=%s): ${expected_message}"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected I03 closure static error '${expected_message}', got: ${output}"
  assert_i03_closure_tmp_clean
  negative_cases=$((negative_cases + 1))
}

expect_i03_closure_transition_failure() {
  local fixture_root="$1"
  local base_sha="$2"
  local head_sha="$3"
  local expected_message="$4"
  local output
  if output="$(TMPDIR="${i03_closure_tmpdir}" "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${base_sha}" \
    --transition-head "${head_sha}" 2>&1)"; then
    fail "invalid I03 closure transition unexpectedly passed: ${expected_message}"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected I03 closure transition error '${expected_message}', got: ${output}"
  assert_i03_closure_tmp_clean
  negative_cases=$((negative_cases + 1))
}

run_w1_i03_closure_contract() {
  local fixture_root governance_tip closure_sha pending_output explicit_output static_output
  local actual_paths expected_paths receipt_plan second_output mutation_sha side_sha name_status
  local review_field_index review_field review_value projection_index
  local projection_path projection_field projection_value projection_task_id
  local projection_head_status projection_wrong_status projection_failure descendant_path
  local positive_cases=0
  negative_cases=0
  fixture_root="${test_tmp_root}/w1-i03-closure"
  i03_closure_tmpdir="${test_tmp_root}/w1-i03-closure-tmp"
  mkdir -p "${i03_closure_tmpdir}"
  : > "${i03_closure_tmpdir}/sibling-marker"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${i03_closure_origin_sha}"
  materialize_i03_governance_path "${fixture_root}" \
    "${i03_closure_governance_paths[0]}" 644 \
    "test: materialize I03 closure design"
  materialize_i03_governance_path "${fixture_root}" \
    "${i03_closure_governance_paths[1]}" 644 \
    "test: materialize I03 closure plan"
  materialize_i03_governance_path "${fixture_root}" \
    "${i03_closure_governance_paths[2]}" 755 \
    "test: materialize I03 closure contract"
  materialize_i03_governance_path "${fixture_root}" \
    "${i03_closure_governance_paths[3]}" 755 \
    "test: materialize I03 closure verifier"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  expected_paths="$(printf '%s\n' "${i03_closure_governance_paths[@]}" | LC_ALL=C sort)"
  actual_paths="$(git -C "${fixture_root}" diff --name-only \
    "${i03_closure_origin_sha}..${governance_tip}" | LC_ALL=C sort)"
  [[ "${actual_paths}" == "${expected_paths}" ]] ||
    fail "I03 closure fixture governance WriteSet mismatch"

  if ! pending_output="$(TMPDIR="${i03_closure_tmpdir}" "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" 2>&1)"; then
    fail "legal W1-I03 closure governance PENDING state was rejected: ${pending_output}"
  fi
  assert_contains "${pending_output}" "W1I03ClosureStatus = PENDING"
  assert_i03_closure_tmp_clean
  positive_cases=$((positive_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  git -C "${fixture_root}" commit -q --allow-empty -m "test: empty I03 closure governance commit"
  expect_i03_closure_static_failure "${fixture_root}" \
    "I03 closure governance commit must be nonempty"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  printf '%s\n' 'outside closure governance path' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add README.md
  git -C "${fixture_root}" commit -qm "test: change outside I03 closure governance path"
  expect_i03_closure_static_failure "${fixture_root}" \
    "I03 closure governance changed a path outside the exact four-path WriteSet"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  printf '%s\n' '# duplicate closure design change' >> \
    "${fixture_root}/${i03_closure_governance_paths[0]}"
  git -C "${fixture_root}" add "${i03_closure_governance_paths[0]}"
  git -C "${fixture_root}" commit -qm "test: change closure design twice"
  expect_i03_closure_static_failure "${fixture_root}" \
    "I03 closure governance path changed more than once"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  git -C "${fixture_root}" mv "${i03_closure_governance_paths[0]}" \
    docs/superpowers/specs/i03-closure-design-moved.md
  git -C "${fixture_root}" commit -qm "test: rename closure governance path"
  expect_i03_closure_static_failure "${fixture_root}" \
    "I03 closure governance commit must not rename or copy paths"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  cp "${fixture_root}/${i03_closure_governance_paths[0]}" \
    "${fixture_root}/docs/superpowers/specs/i03-closure-design-copy.md"
  git -C "${fixture_root}" add docs/superpowers/specs/i03-closure-design-copy.md
  git -C "${fixture_root}" commit -qm "test: copy closure governance path"
  expect_i03_closure_static_failure "${fixture_root}" \
    "I03 closure governance commit must not rename or copy paths"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  printf '\0' >> "${fixture_root}/${i03_closure_governance_paths[0]}"
  git -C "${fixture_root}" add "${i03_closure_governance_paths[0]}"
  git -C "${fixture_root}" commit -qm "test: add NUL to closure governance path"
  expect_i03_closure_static_failure "${fixture_root}" \
    "I03 closure governance path must not contain NUL"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  chmod 755 "${fixture_root}/${i03_closure_governance_paths[0]}"
  git -C "${fixture_root}" add "${i03_closure_governance_paths[0]}"
  git -C "${fixture_root}" commit -qm "test: change closure governance mode"
  expect_i03_closure_static_failure "${fixture_root}" \
    "I03 closure governance path mode mismatch"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  printf '%s\n' '// forbidden reviewed candidate drift' >> \
    "${fixture_root}/server/src/main/java/io/cognitura/source/docx/security/DocxSecurityGate.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/docx/security/DocxSecurityGate.java
  git -C "${fixture_root}" commit -qm "test: drift reviewed W1-I03 production"
  expect_i03_closure_static_failure "${fixture_root}" \
    "reviewed W1-I03 production must remain byte-identical"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  git -C "${fixture_root}" switch -q -c i03-closure-side
  printf '%s\n' 'merge side' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add README.md
  git -C "${fixture_root}" commit -qm "test: create closure governance merge side"
  side_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  git -C "${fixture_root}" merge -q --no-ff "${side_sha}" \
    -m "test: merge closure governance side"
  expect_i03_closure_static_failure "${fixture_root}" \
    "I03 closure governance commit must have exactly one parent"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"

  make_i03_closure_projection "${fixture_root}"
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: close W1-I03 and release W1-I04"
  closure_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  expected_paths="$(printf '%s\n' "${i03_closure_projection_paths[@]}" | LC_ALL=C sort)"
  actual_paths="$(git -C "${fixture_root}" diff --name-only \
    "${governance_tip}..${closure_sha}" | LC_ALL=C sort)"
  [[ "${actual_paths}" == "${expected_paths}" ]] ||
    fail "I03 closure fixture receipt WriteSet mismatch"

  explicit_output="$(TMPDIR="${i03_closure_tmpdir}" "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${governance_tip}" \
    --transition-head "${closure_sha}")" ||
    fail "legal W1-I03 closure transition was rejected"
  assert_contains "${explicit_output}" "W1I03ClosureStatus = PASS"
  assert_i03_closure_tmp_clean
  positive_cases=$((positive_cases + 1))
  static_output="$(TMPDIR="${i03_closure_tmpdir}" "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation")" ||
    fail "legal W1-I03 closure static receipt was rejected"
  assert_contains "${static_output}" "W1I03ClosureStatus = PASS"
  assert_contains "${static_output}" "ActiveTaskCard = W1-I04"
  assert_i03_closure_tmp_clean
  positive_cases=$((positive_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  git -C "${fixture_root}" commit -q --allow-empty \
    -m "test: insert closure receipt intermediate"
  make_i03_closure_projection "${fixture_root}"
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: create non-direct I03 closure receipt"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure receipt HEAD must be the direct child of BASE"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  git -C "${fixture_root}" restore \
    docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: omit I04 card from closure"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure receipt fixed diff must equal the exact eleven projection paths"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  git -C "${fixture_root}" mv docs/design/wave-1/README.md \
    docs/design/wave-1/i03-closure-moved.md
  git -C "${fixture_root}" add -A
  git -C "${fixture_root}" commit -qm "test: rename I03 closure receipt path"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure receipt must not rename or copy paths"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  cp "${fixture_root}/README.md" "${fixture_root}/docs/i03-closure-readme-copy.md"
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}" \
    docs/i03-closure-readme-copy.md
  git -C "${fixture_root}" commit -qm "test: copy I03 closure receipt path"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure receipt must not rename or copy paths"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  chmod 755 "${fixture_root}/README.md"
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: change I03 closure receipt mode"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure receipt must preserve every projection path mode"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  printf '\0' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: add NUL to I03 closure receipt"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure receipt projection must not contain NUL"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  printf '%s\n' 'forbidden extra closure path' > \
    "${fixture_root}/docs/task-cards/wave-1-implementation/i03-closure-extra.txt"
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}" \
    docs/task-cards/wave-1-implementation/i03-closure-extra.txt
  git -C "${fixture_root}" commit -qm "test: add extra I03 closure path"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure receipt fixed diff must equal the exact eleven projection paths"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md" \
    Status READY
  printf '%s\n' '' 'I03ClosureStateMutation = READY' >> \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md"
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: leave I03 READY during closure"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure receipt must set I03 DONE and I04 READY"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md" \
    Status BLOCKED_BY_DEPENDENCY
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I04 READY BLOCKED_BY_DEPENDENCY
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: leave I04 blocked during closure"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure receipt must set I03 DONE and I04 READY"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I05 BLOCKED_BY_DEPENDENCY READY
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: release two cards during I03 closure"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure receipt must release exactly one READY card"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I02 QUEUED DONE
  set_table_status \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    W1-I02 QUEUED DONE
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: release database card during I03 closure"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure must keep W1-I02 queued behind its database gate"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md" \
    Status BLOCKED_BY_DEPENDENCY
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I04 READY BLOCKED_BY_DEPENDENCY
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I05 BLOCKED_BY_DEPENDENCY READY
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    ActiveTaskCard W1-I05
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: release wrong closure successor"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure receipt may release only W1-I04"

  for projection_index in "${!i03_projection_field_paths[@]}"; do
    projection_path="${i03_projection_field_paths[${projection_index}]}"
    projection_field="${i03_projection_field_names[${projection_index}]}"
    projection_value="${i03_projection_field_wrong_values[${projection_index}]}"
    projection_failure="${i03_projection_field_failure_messages[${projection_index}]}"
    git -C "${fixture_root}" switch -q --detach "${governance_tip}"
    make_i03_closure_projection "${fixture_root}"
    set_field "${fixture_root}/${projection_path}" \
      "${projection_field}" "${projection_value}"
    git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
    git -C "${fixture_root}" commit -qm \
      "test: mismatch I03 closure projection field ${projection_field}"
    expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
      "$(git -C "${fixture_root}" rev-parse HEAD)" \
      "${projection_failure}"
  done

  for projection_index in "${!i03_projection_table_paths[@]}"; do
    projection_path="${i03_projection_table_paths[${projection_index}]}"
    projection_task_id="${i03_projection_table_task_ids[${projection_index}]}"
    projection_head_status="${i03_projection_table_head_statuses[${projection_index}]}"
    projection_wrong_status="${i03_projection_table_wrong_statuses[${projection_index}]}"
    projection_failure="${i03_projection_table_failure_messages[${projection_index}]}"
    git -C "${fixture_root}" switch -q --detach "${governance_tip}"
    make_i03_closure_projection "${fixture_root}"
    set_table_status "${fixture_root}/${projection_path}" \
      "${projection_task_id}" "${projection_head_status}" "${projection_wrong_status}"
    git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
    git -C "${fixture_root}" commit -qm \
      "test: mismatch I03 closure projection table ${projection_task_id}"
    expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
      "$(git -C "${fixture_root}" rev-parse HEAD)" \
      "${projection_failure}"
  done

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  receipt_plan="${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  sed -i.bak 's/^ReviewedCandidate = 4e63936c/ReviewedCandidate = 00000000/' \
    "${receipt_plan}"
  rm "${receipt_plan}.bak"
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: use wrong I03 reviewed candidate"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure review receipt mismatch"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    FormalDatabaseWrite AUTHORIZED
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: authorize database during I03 closure"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure must preserve database and push authorization boundaries"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    RemotePush AUTHORIZED
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: authorize push during I03 closure"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure must preserve database and push authorization boundaries"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  receipt_plan="${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  sed -i.bak '/^## 8\. I03 关闭收据$/,$d' "${receipt_plan}"
  rm "${receipt_plan}.bak"
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: omit I03 closure review block"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure review receipt mismatch"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  append_i03_review_receipt "${fixture_root}"
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: duplicate I03 closure review block"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure review receipt mismatch"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  receipt_plan="${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  replace_i03_closure_text "${receipt_plan}" \
    $'ReviewLevel = L3\nReviewRoute = deep_reviewer' \
    $'ReviewRoute = deep_reviewer\nReviewLevel = L3' \
    "reorder I03 closure review block"
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: reorder I03 closure review block"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure review receipt mismatch"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  receipt_plan="${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  replace_i03_closure_text "${receipt_plan}" \
    $'I03ClosureReleasedTaskCard = W1-I04\nQueuedTaskCard = W1-I02\nQueuedReason = INDEPENDENT_DATABASE_GATE_REQUIRED\n```' \
    $'I03ClosureReleasedTaskCard = W1-I04\nQueuedTaskCard = W1-I02\nQueuedReason = INDEPENDENT_DATABASE_GATE_REQUIRED\nI03ClosureUnknown = FORBIDDEN\n```' \
    "add unknown I03 closure review field"
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: add unknown I03 closure review field"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure review receipt mismatch"

  for review_field_index in "${!i03_review_mutation_fields[@]}"; do
    review_field="${i03_review_mutation_fields[${review_field_index}]}"
    review_value="${i03_review_mutation_values[${review_field_index}]}"
    git -C "${fixture_root}" switch -q --detach "${governance_tip}"
    make_i03_closure_projection "${fixture_root}"
    receipt_plan="${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
    set_field "${receipt_plan}" "${review_field}" "${review_value}"
    git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
    git -C "${fixture_root}" commit -qm \
      "test: mutate I03 closure review field ${review_field}"
    expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
      "$(git -C "${fixture_root}" rev-parse HEAD)" \
      "I03 closure review receipt mismatch"
  done

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i03_closure_projection "${fixture_root}"
  replace_i03_closure_text "${fixture_root}/README.md" \
    "${i04_ready_narratives[2]}" "${i03_ready_narratives[2]}" \
    "restore stale I03 READY narrative"
  git -C "${fixture_root}" add "${i03_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: retain stale I03 READY narrative"
  expect_i03_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I03 closure narrative projection mismatch"

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  printf '%s\n' 'working tree mask' >> "${fixture_root}/README.md"
  expect_i03_closure_static_failure "${fixture_root}" \
    "working projection must match I03 closure receipt"
  git -C "${fixture_root}" restore README.md

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  printf '%s\n' '// working frozen production drift' >> \
    "${fixture_root}/server/src/main/java/io/cognitura/source/docx/security/DocxSecurityGate.java"
  expect_i03_closure_static_failure "${fixture_root}" \
    "working W1-I03 production must match the reviewed candidate"
  git -C "${fixture_root}" restore \
    server/src/main/java/io/cognitura/source/docx/security/DocxSecurityGate.java

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  printf '%s\n' 'untracked frozen production drift' > \
    "${fixture_root}/server/src/test/resources/docx/security/working-tree-mask.bin"
  expect_i03_closure_static_failure "${fixture_root}" \
    "working W1-I03 production must match the reviewed candidate"
  rm -f \
    "${fixture_root}/server/src/test/resources/docx/security/working-tree-mask.bin"

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  printf '%s\n' 'ignored frozen production drift' > \
    "${fixture_root}/server/src/test/resources/docx/security/.DS_Store"
  expect_i03_closure_static_failure "${fixture_root}" \
    "working W1-I03 production must match the reviewed candidate"
  rm -f \
    "${fixture_root}/server/src/test/resources/docx/security/.DS_Store"

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  for descendant_path in "${i04_descendant_fixture_paths[@]}"; do
    mkdir -p "$(dirname "${fixture_root}/${descendant_path}")"
    printf '%s\n' "fixture-only ${descendant_path}" > \
      "${fixture_root}/${descendant_path}"
  done
  git -C "${fixture_root}" add "${i04_descendant_fixture_paths[@]}"
  git -C "${fixture_root}" commit -qm \
    "test: add legal post-closure W1-I04 production descendant"
  static_output="$(TMPDIR="${i03_closure_tmpdir}" "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation")" ||
    fail "legal post-closure W1-I04 production descendant was rejected"
  assert_contains "${static_output}" "W1I03ClosureStatus = PASS"
  assert_contains "${static_output}" "ActiveTaskCard = W1-I04"
  assert_i03_closure_tmp_clean
  positive_cases=$((positive_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  mkdir -p "${fixture_root}/server/src/test/resources/docx/text"
  cp "${fixture_root}/server/src/test/resources/docx/security/minimal-document.xml" \
    "${fixture_root}/server/src/test/resources/docx/text/copied-minimal.bin"
  git -C "${fixture_root}" add \
    server/src/test/resources/docx/text/copied-minimal.bin
  git -C "${fixture_root}" commit -qm \
    "test: reject non-XML inferred fixture copy"
  name_status="$(git -C "${fixture_root}" -c diff.renameLimit=0 diff-tree \
    --no-commit-id --name-status -r -M -C --find-copies-harder HEAD^ HEAD)"
  [[ "${name_status}" == C100$'\t'server/src/test/resources/docx/security/minimal-document.xml$'\t'server/src/test/resources/docx/text/copied-minimal.bin ]] ||
    fail "non-XML inferred fixture copy did not produce literal C100"
  expect_i03_closure_static_failure "${fixture_root}" \
    "post-closure descendant commit must not rename or copy paths"

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  mkdir -p "${fixture_root}/server/src/test/resources/docx/text"
  printf '%s\n' '<unique-source/>' > \
    "${fixture_root}/server/src/test/resources/docx/text/rename-source.xml"
  git -C "${fixture_root}" add \
    server/src/test/resources/docx/text/rename-source.xml
  git -C "${fixture_root}" commit -qm "test: add rename source fixture"
  git -C "${fixture_root}" mv \
    server/src/test/resources/docx/text/rename-source.xml \
    server/src/test/resources/docx/text/rename-target.xml
  git -C "${fixture_root}" commit -qm "test: reject inferred fixture rename"
  name_status="$(git -C "${fixture_root}" -c diff.renameLimit=0 diff-tree \
    --no-commit-id --name-status -r -M -C --find-copies-harder HEAD^ HEAD)"
  [[ "${name_status}" == R100$'\t'server/src/test/resources/docx/text/rename-source.xml$'\t'server/src/test/resources/docx/text/rename-target.xml ]] ||
    fail "fixture rename did not produce literal R100"
  expect_i03_closure_static_failure "${fixture_root}" \
    "post-closure descendant commit must not rename or copy paths"

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  mkdir -p "${fixture_root}/server/src/test/resources/docx/text"
  cp "${fixture_root}/server/src/test/resources/docx/security/minimal-document.xml" \
    "${fixture_root}/server/src/test/resources/docx/text/copied-minimal.xml"
  git -C "${fixture_root}" add \
    server/src/test/resources/docx/text/copied-minimal.xml
  git -C "${fixture_root}" commit -qm \
    "test: accept inferred XML fixture copy without source mutation"
  name_status="$(git -C "${fixture_root}" -c diff.renameLimit=0 diff-tree \
    --no-commit-id --name-status -r -M -C --find-copies-harder HEAD^ HEAD)"
  [[ "${name_status}" == C100$'\t'server/src/test/resources/docx/security/minimal-document.xml$'\t'server/src/test/resources/docx/text/copied-minimal.xml ]] ||
    fail "legal inferred XML fixture copy did not produce literal C100"
  static_output="$(TMPDIR="${i03_closure_tmpdir}" "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation")" ||
    fail "legal inferred XML fixture copy was rejected"
  assert_contains "${static_output}" "W1I03ClosureStatus = PASS"
  assert_i03_closure_tmp_clean
  positive_cases=$((positive_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md" \
    Status DONE
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md" \
    FormalDatabaseGate PASS
  git -C "${fixture_root}" add \
    docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md
  git -C "${fixture_root}" commit -qm \
    "test: drift I02 database boundary after I03 closure"
  expect_i03_closure_static_failure "${fixture_root}" \
    "post-closure descendant changed a path outside the W1-I04 WriteSet"

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  printf '%s\n' '' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add README.md
  git -C "${fixture_root}" commit -qm \
    "test: introduce post-closure projection drift"
  git -C "${fixture_root}" restore --source="${closure_sha}" README.md
  git -C "${fixture_root}" add README.md
  git -C "${fixture_root}" commit -qm \
    "test: restore post-closure projection drift"
  expect_i03_closure_static_failure "${fixture_root}" \
    "I03 closure is allowed exactly once"

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  printf '%s\n' '' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add README.md
  git -C "${fixture_root}" commit -qm "test: attempt second I03 closure descendant"
  if second_output="$(TMPDIR="${i03_closure_tmpdir}" "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" 2>&1)"; then
    fail "second I03 closure descendant unexpectedly passed"
  fi
  assert_contains "${second_output}" "I03 closure is allowed exactly once"
  assert_i03_closure_tmp_clean
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 5 ]] ||
    fail "I03 closure positive case count mismatch: ${positive_cases}"
  [[ "${negative_cases}" -eq 65 ]] ||
    fail "I03 closure negative case count mismatch: ${negative_cases}"

  printf '%s\n' \
    "W1I03ClosureContractTests = PASS" \
    "W1I03ClosurePositiveCases = ${positive_cases}" \
    "W1I03ClosureNegativeCases = ${negative_cases}"
}

i04_closure_origin_sha="e5c882f072db62d22b4de32b0aacb1d720a02154"
i04_vsb_terminal_restore_sha="cc25439de8019a4434c2ab5aba8b32927240d8b4"
i04_closure_tmpdir=""
i04_closure_governance_paths=(
  docs/superpowers/specs/2026-08-20-cognitura-w1-i04-closure-successor-design.md
  docs/superpowers/plans/2026-08-20-cognitura-w1-i04-closure-successor.md
  tests/task-cards/verify-wave1-implementation-cards.sh
  scripts/verify-wave1-implementation-cards
)
i04_closure_projection_paths=(
  AGENTS.md
  README.md
  docs/design/wave-1/README.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-plan.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1/README.md
  docs/task-cards/wave-1-implementation/README.md
  docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md
  docs/task-cards/wave-1-implementation/W1-I05-table-fidelity.md
)
i05_ready_narratives=(
  '`W1-I02` 等待独立数据库 Gate；`W1-I03`、`W1-I04` 已零发现关闭，`W1-I05` 为唯一 `READY` 业务卡。'
  'I00、I01、I03 和 I04 已关闭，当前已原子释放 I05；I02 保持等待独立数据库 Gate。'
  '完成零发现深审并关闭；I02 等待独立数据库 Gate，`W1-I05` 是唯一 `READY` 卡。'
  '保持 `QUEUED` 等待独立数据库 Gate；`W1-I03`、`W1-I04` 已关闭，`W1-I05` 已释放为唯一 `READY` 业务卡。'
  '  I01、I03 和 I04 已关闭，I02 等待独立数据库 Gate，I05 为唯一 `READY` 卡。'
  '`W1-I04` 已零发现关闭，`W1-I05` 已作为唯一 `READY` 卡释放。'
  $'当前业务授权只按既定卡集串行推进至 `W1-I05`；I02 独立数据库 Gate、正式数据库\n写入和远程推送仍未授权。'
  '固定候选深审并关闭；I02 等待独立数据库 Gate，I03 和 I04 已关闭且 I05 为唯一 `READY` 卡，完整证据记录在'
  '数据库 Gate；I03 和 I04 已关闭，I05 为唯一 `READY` 卡。正式数据库、Parser/Object Storage Provider、'
  'I03 和 I04 已关闭，I05 为唯一 `READY` 卡。'
  'I00、I01、I03 和 I04 已关闭；I02 等待独立数据库 Gate，W1-I05 为唯一 `READY` 业务卡。'
  '完成零发现深审并关闭；I02 等待独立数据库 Gate，I03 和 I04 已关闭且 I05 已原子释放为唯一 `READY` 卡。'
)
i04_review_mutation_fields=(
  ReviewLevel
  ReviewRoute
  ReviewEffort
  ReviewMultiplicity
  ReviewVerdict
  P0
  P1
  P2
  Ultra
  I04ClosureReleasedTaskCard
  QueuedTaskCard
  QueuedReason
)
i04_review_mutation_values=(
  L4
  ultra_gatekeeper
  high
  TWO
  NO_GO
  1
  1
  1
  EXECUTED
  W1-I06
  W1-I05
  NONE
)

append_i04_review_receipt() {
  local fixture_root="$1"
  printf '%s\n' \
    '' \
    '## 9. I04 关闭收据' \
    '' \
    '```text' \
    'W1-I04 = DONE' \
    'ReviewedCandidate = 4594406e9fd8a9ac380c3b2b880fda67271790bc' \
    'ReviewLevel = L3' \
    'ReviewRoute = deep_reviewer' \
    'ReviewEffort = xhigh' \
    'ReviewMultiplicity = ONE' \
    'ReviewVerdict = GO' \
    'P0 = 0' \
    'P1 = 0' \
    'P2 = 0' \
    'Ultra = NOT_RUN' \
    'I04ClosureReleasedTaskCard = W1-I05' \
    'QueuedTaskCard = W1-I02' \
    'QueuedReason = INDEPENDENT_DATABASE_GATE_REQUIRED' \
    '```' >> \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
}

make_i04_closure_projection() {
  local fixture_root="$1"
  local narrative_index narrative_path
  set_field "${fixture_root}/AGENTS.md" ActiveImplementationTaskCard W1-I05
  set_field "${fixture_root}/README.md" ActiveImplementationTaskCard W1-I05
  set_field "${fixture_root}/docs/design/wave-1/README.md" \
    ActiveImplementationGovernanceTaskCard W1-I05
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    ActiveTaskCard W1-I05
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    ActiveImplementationTaskCard W1-I05
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    ActiveImplementationGovernanceTaskCard W1-I05
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    ImplementationTaskCardPlanStatus I04_COMPLETE_I05_READY
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    ActiveImplementationGovernanceTaskCard W1-I05
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    ActiveTaskCard W1-I05
  set_table_status \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    W1-I04 READY DONE
  set_table_status \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    W1-I05 BLOCKED_BY_DEPENDENCY READY
  set_field "${fixture_root}/docs/task-cards/wave-1/README.md" \
    ActiveImplementationGovernanceTaskCard W1-I05
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    ActiveTaskCard W1-I05
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I04 READY DONE
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I05 BLOCKED_BY_DEPENDENCY READY
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md" \
    Status DONE
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I05-table-fidelity.md" \
    Status READY
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I05-table-fidelity.md" \
    BusinessImplementationAuthorization USER_AUTHORIZED
  append_i04_review_receipt "${fixture_root}"
  for narrative_index in "${!i04_ready_narratives[@]}"; do
    narrative_path="${i03_ready_narrative_paths[${narrative_index}]}"
    replace_i03_closure_text \
      "${fixture_root}/${narrative_path}" \
      "${i04_ready_narratives[${narrative_index}]}" \
      "${i05_ready_narratives[${narrative_index}]}" \
      "close I04 narrative ${narrative_path}"
  done
}

assert_i04_closure_tmp_clean() {
  local residue
  residue="$(find "${i04_closure_tmpdir}" -mindepth 1 -maxdepth 1 \
    ! -name sibling-marker -print -quit)"
  [[ -z "${residue}" ]] || fail "I04 closure verifier left TMPDIR residue: ${residue}"
  [[ -f "${i04_closure_tmpdir}/sibling-marker" ]] ||
    fail "I04 closure verifier removed TMPDIR sibling marker"
}

expect_i04_closure_static_failure() {
  local fixture_root="$1"
  local expected_message="$2"
  local output
  if output="$(TMPDIR="${i04_closure_tmpdir}" "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" 2>&1)"; then
    fail "invalid I04 closure static state unexpectedly passed: ${expected_message}"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected I04 closure static error '${expected_message}', got: ${output}"
  assert_i04_closure_tmp_clean
  i04_negative_cases=$((i04_negative_cases + 1))
}

expect_i04_closure_transition_failure() {
  local fixture_root="$1"
  local base_sha="$2"
  local head_sha="$3"
  local expected_message="$4"
  local output
  if output="$(TMPDIR="${i04_closure_tmpdir}" "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${base_sha}" \
    --transition-head "${head_sha}" 2>&1)"; then
    fail "invalid I04 closure transition unexpectedly passed: ${expected_message}"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected I04 closure transition error '${expected_message}', got: ${output}"
  assert_i04_closure_tmp_clean
  i04_negative_cases=$((i04_negative_cases + 1))
}

run_w1_i04_closure_contract() {
  local fixture_root governance_tip closure_sha pending_output explicit_output static_output
  local actual_paths expected_paths receipt_plan mutation_sha second_output
  local vsb_snapshot_root vsb_snapshot_output
  local review_field_index review_field review_value
  local i04_positive_cases=0
  i04_negative_cases=0
  fixture_root="${test_tmp_root}/w1-i04-closure"
  i04_closure_tmpdir="${test_tmp_root}/w1-i04-closure-tmp"
  mkdir -p "${i04_closure_tmpdir}"
  : > "${i04_closure_tmpdir}/sibling-marker"
  vsb_snapshot_root="${test_tmp_root}/w1-i04-vsb-terminal-restore"
  git clone --shared -q "${repo_root}" "${vsb_snapshot_root}"
  git -C "${vsb_snapshot_root}" checkout -q --detach \
    "${i04_vsb_terminal_restore_sha}"
  vsb_snapshot_output="$(
    "${vsb_snapshot_root}/scripts/verify-visual-style-baseline-cards" \
      --repo-root "${vsb_snapshot_root}" \
      --cards-dir "${vsb_snapshot_root}/docs/task-cards/visual-style-baseline"
  )" || fail "fixed VSB terminal restore snapshot was rejected"
  assert_contains "${vsb_snapshot_output}" "VisualStyleBaselineTaskCardValidation = PASS"
  rm -rf -- "${vsb_snapshot_root}"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${i04_closure_origin_sha}"

  materialize_i03_governance_path "${fixture_root}" \
    "${i04_closure_governance_paths[0]}" 644 "test: materialize I04 closure design"
  materialize_i03_governance_path "${fixture_root}" \
    "${i04_closure_governance_paths[1]}" 644 "test: materialize I04 closure plan"
  materialize_i03_governance_path "${fixture_root}" \
    "${i04_closure_governance_paths[2]}" 755 "test: materialize I04 closure contract"
  materialize_i03_governance_path "${fixture_root}" \
    "${i04_closure_governance_paths[3]}" 755 "test: materialize I04 closure verifier"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  expected_paths="$(printf '%s\n' "${i04_closure_governance_paths[@]}" | LC_ALL=C sort)"
  actual_paths="$(git -C "${fixture_root}" diff --name-only \
    "${i04_closure_origin_sha}..${governance_tip}" | LC_ALL=C sort)"
  [[ "${actual_paths}" == "${expected_paths}" ]] ||
    fail "I04 closure governance fixture WriteSet mismatch"

  pending_output="$(TMPDIR="${i04_closure_tmpdir}" "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation")" ||
    fail "legal I04 closure PENDING state was rejected"
  assert_contains "${pending_output}" "W1I04ClosureStatus = PENDING"
  assert_i04_closure_tmp_clean
  i04_positive_cases=$((i04_positive_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${i04_closure_origin_sha}"

  git -C "${fixture_root}" commit --allow-empty -qm \
    "test: add empty I04 governance commit"
  materialize_i03_governance_path "${fixture_root}" \
    "${i04_closure_governance_paths[0]}" 644 "test: materialize I04 closure design after empty"
  materialize_i03_governance_path "${fixture_root}" \
    "${i04_closure_governance_paths[1]}" 644 "test: materialize I04 closure plan after empty"
  materialize_i03_governance_path "${fixture_root}" \
    "${i04_closure_governance_paths[2]}" 755 "test: materialize I04 closure contract after empty"
  materialize_i03_governance_path "${fixture_root}" \
    "${i04_closure_governance_paths[3]}" 755 "test: materialize I04 closure verifier after empty"
  expect_i04_closure_static_failure "${fixture_root}" \
    "I04 closure governance commit must be nonempty"

  git -C "${fixture_root}" switch -q --detach "${i04_closure_origin_sha}"
  materialize_i03_governance_path "${fixture_root}" \
    "${i04_closure_governance_paths[1]}" 644 "test: materialize I04 closure plan first"
  materialize_i03_governance_path "${fixture_root}" \
    "${i04_closure_governance_paths[0]}" 644 "test: materialize I04 closure design second"
  materialize_i03_governance_path "${fixture_root}" \
    "${i04_closure_governance_paths[2]}" 755 "test: materialize reordered I04 closure contract"
  materialize_i03_governance_path "${fixture_root}" \
    "${i04_closure_governance_paths[3]}" 755 "test: materialize reordered I04 closure verifier"
  expect_i04_closure_static_failure "${fixture_root}" \
    "I04 closure governance paths must be introduced in canonical order"

  git -C "${fixture_root}" switch -q --detach "${i04_closure_origin_sha}"
  materialize_i03_governance_path "${fixture_root}" \
    "${i04_closure_governance_paths[0]}" 644 "test: incomplete I04 design"
  materialize_i03_governance_path "${fixture_root}" \
    "${i04_closure_governance_paths[1]}" 644 "test: incomplete I04 plan"
  materialize_i03_governance_path "${fixture_root}" \
    "${i04_closure_governance_paths[2]}" 755 "test: incomplete I04 tests"
  expect_i04_closure_static_failure "${fixture_root}" \
    "I04 closure governance chain must have the exact four-path cumulative WriteSet"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  printf '%s\n' 'repeat' >> \
    "${fixture_root}/${i04_closure_governance_paths[0]}"
  git -C "${fixture_root}" add "${i04_closure_governance_paths[0]}"
  git -C "${fixture_root}" commit -qm "test: repeat I04 governance path"
  expect_i04_closure_static_failure "${fixture_root}" \
    "I04 closure governance chain must have the exact four-path cumulative WriteSet"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  printf '%s\n' 'outside' > "${fixture_root}/docs/superpowers/specs/i04-outside.md"
  git -C "${fixture_root}" add docs/superpowers/specs/i04-outside.md
  git -C "${fixture_root}" commit -qm "test: add outside I04 governance path"
  expect_i04_closure_static_failure "${fixture_root}" \
    "I04 closure governance chain must have the exact four-path cumulative WriteSet"

  git -C "${fixture_root}" switch -q --detach "${i04_closure_origin_sha}"
  mkdir -p "$(dirname "${fixture_root}/${i04_closure_governance_paths[0]}")"
  cp "${repo_root}/${i04_closure_governance_paths[0]}" \
    "${fixture_root}/${i04_closure_governance_paths[0]}"
  chmod 755 "${fixture_root}/${i04_closure_governance_paths[0]}"
  git -C "${fixture_root}" add "${i04_closure_governance_paths[0]}"
  git -C "${fixture_root}" commit -qm "test: drift I04 governance mode"
  expect_i04_closure_static_failure "${fixture_root}" \
    "I04 closure governance path mode mismatch"

  git -C "${fixture_root}" switch -q --detach "${i04_closure_origin_sha}"
  mkdir -p "$(dirname "${fixture_root}/${i04_closure_governance_paths[0]}")"
  cp "${repo_root}/${i04_closure_governance_paths[0]}" \
    "${fixture_root}/${i04_closure_governance_paths[0]}"
  printf '\0' >> "${fixture_root}/${i04_closure_governance_paths[0]}"
  git -C "${fixture_root}" add "${i04_closure_governance_paths[0]}"
  git -C "${fixture_root}" commit -qm "test: add NUL to I04 governance"
  expect_i04_closure_static_failure "${fixture_root}" \
    "I04 closure governance path must not contain NUL"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  git -C "${fixture_root}" mv "${i04_closure_governance_paths[1]}" \
    "${i04_closure_governance_paths[1]}.moved"
  git -C "${fixture_root}" commit -qm "test: rename I04 governance plan"
  expect_i04_closure_static_failure "${fixture_root}" \
    "I04 closure governance commit must not rename or copy paths"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  cp "${fixture_root}/${i04_closure_governance_paths[0]}" \
    "${fixture_root}/docs/superpowers/specs/i04-copy.md"
  git -C "${fixture_root}" add docs/superpowers/specs/i04-copy.md
  git -C "${fixture_root}" commit -qm "test: copy I04 governance design"
  expect_i04_closure_static_failure "${fixture_root}" \
    "I04 closure governance commit must not rename or copy paths"

  git -C "${fixture_root}" branch -D i04-merge-side >/dev/null 2>&1 || true
  git -C "${fixture_root}" switch -q -c i04-merge-side "${governance_tip}"
  printf '%s\n' 'side' > "${fixture_root}/docs/superpowers/specs/i04-side.md"
  git -C "${fixture_root}" add docs/superpowers/specs/i04-side.md
  git -C "${fixture_root}" commit -qm "test: create I04 merge side"
  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  git -C "${fixture_root}" merge -q --no-ff i04-merge-side -m "test: merge I04 governance"
  expect_i04_closure_static_failure "${fixture_root}" \
    "I04 closure governance commit must have exactly one parent"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  printf '%s\n' '// reviewed product drift' >> \
    "${fixture_root}/server/src/main/java/io/cognitura/source/docx/text/TextListSectionParser.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/docx/text/TextListSectionParser.java
  git -C "${fixture_root}" commit -qm "test: drift reviewed I04 production"
  expect_i04_closure_static_failure "${fixture_root}" \
    "reviewed W1-I04 production must remain byte-identical"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"

  make_i04_closure_projection "${fixture_root}"
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: close I04 and release I05"
  closure_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  actual_paths="$(git -C "${fixture_root}" diff --name-only \
    "${governance_tip}..${closure_sha}" | LC_ALL=C sort)"
  expected_paths="$(printf '%s\n' "${i04_closure_projection_paths[@]}" | LC_ALL=C sort)"
  [[ "${actual_paths}" == "${expected_paths}" ]] ||
    fail "I04 closure receipt fixture WriteSet mismatch"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  git -C "${fixture_root}" commit --allow-empty -qm \
    "test: insert non-direct I04 receipt ancestor"
  make_i04_closure_projection "${fixture_root}"
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: create non-direct I04 closure receipt"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I04 closure receipt HEAD must be the direct child of BASE"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i04_closure_projection "${fixture_root}"
  git -C "${fixture_root}" mv \
    docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md \
    docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.moved
  git -C "${fixture_root}" add -A -- .
  git -C "${fixture_root}" commit -qm "test: rename I04 closure receipt path"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I04 closure receipt must not rename or copy paths"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i04_closure_projection "${fixture_root}"
  cp "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md" \
    "${fixture_root}/docs/task-cards/wave-1-implementation/i04-receipt-copy.md"
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}" \
    docs/task-cards/wave-1-implementation/i04-receipt-copy.md
  git -C "${fixture_root}" commit -qm "test: copy I04 closure receipt path"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I04 closure receipt must not rename or copy paths"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i04_closure_projection "${fixture_root}"
  printf '\0' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: add NUL to I04 closure receipt"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I04 closure receipt projection must not contain NUL"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i04_closure_projection "${fixture_root}"
  chmod 755 "${fixture_root}/README.md"
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: drift I04 closure receipt mode"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I04 closure receipt must preserve every projection path mode"

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"

  explicit_output="$(TMPDIR="${i04_closure_tmpdir}" "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${governance_tip}" \
    --transition-head "${closure_sha}")" ||
    fail "legal explicit I04 closure receipt was rejected"
  assert_contains "${explicit_output}" "W1I04ClosureStatus = PASS"
  assert_i04_closure_tmp_clean
  i04_positive_cases=$((i04_positive_cases + 1))

  static_output="$(TMPDIR="${i04_closure_tmpdir}" "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation")" ||
    fail "legal static I04 closure receipt was rejected"
  assert_contains "${static_output}" "W1I04ClosureStatus = PASS"
  assert_contains "${static_output}" "ActiveTaskCard = W1-I05"
  assert_i04_closure_tmp_clean
  i04_positive_cases=$((i04_positive_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  mkdir -p "${fixture_root}/server/src/main/java/io/cognitura/source/docx/table"
  printf '%s\n' 'package io.cognitura.source.docx.table;' > \
    "${fixture_root}/server/src/main/java/io/cognitura/source/docx/table/TableFidelityParser.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/docx/table/TableFidelityParser.java
  git -C "${fixture_root}" commit -qm "test: add legal post-I04 I05 descendant"
  static_output="$(TMPDIR="${i04_closure_tmpdir}" "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation")" ||
    fail "legal post-I04 I05 descendant was rejected"
  assert_contains "${static_output}" "W1I04ClosureStatus = PASS"
  assert_i04_closure_tmp_clean
  i04_positive_cases=$((i04_positive_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  printf '%s\n' 'outside' > "${fixture_root}/server/i04-outside.txt"
  git -C "${fixture_root}" add server/i04-outside.txt
  git -C "${fixture_root}" commit -qm "test: add post-I04 outside descendant"
  expect_i04_closure_static_failure "${fixture_root}" \
    "post-I04-closure descendant changed a path outside the W1-I05 WriteSet"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i04_closure_projection "${fixture_root}"
  git -C "${fixture_root}" restore --source="${governance_tip}" \
    docs/task-cards/wave-1-implementation/W1-I05-table-fidelity.md
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: omit I05 from I04 closure receipt"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I04 closure receipt fixed diff must equal the exact eleven projection paths"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i04_closure_projection "${fixture_root}"
  printf '%s\n' 'extra' > "${fixture_root}/docs/task-cards/wave-1-implementation/i04-extra.md"
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}" \
    docs/task-cards/wave-1-implementation/i04-extra.md
  git -C "${fixture_root}" commit -qm "test: add extra I04 receipt path"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I04 closure receipt fixed diff must equal the exact eleven projection paths"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i04_closure_projection "${fixture_root}"
  printf '%s\n' '' >> \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I04-text-list-section-parser.md" \
    Status READY
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: keep I04 ready during closure"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I04 closure receipt must set I04 DONE and I05 READY"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i04_closure_projection "${fixture_root}"
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I03 DONE READY
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: create second READY row during I04 closure"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I04 closure receipt must release exactly one READY card"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i04_closure_projection "${fixture_root}"
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I02 QUEUED DONE
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: release I02 during I04 closure"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I04 closure must keep W1-I02 queued behind its database gate"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i04_closure_projection "${fixture_root}"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I05-table-fidelity.md" \
    Status BLOCKED_BY_DEPENDENCY
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: keep I05 blocked during I04 closure"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I04 closure receipt must set I04 DONE and I05 READY"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i04_closure_projection "${fixture_root}"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    FormalDatabaseWrite AUTHORIZED
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: authorize database during I04 closure"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I04 closure must preserve database and push authorization boundaries"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i04_closure_projection "${fixture_root}"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    RemotePush AUTHORIZED
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: authorize push during I04 closure"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I04 closure must preserve database and push authorization boundaries"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i04_closure_projection "${fixture_root}"
  receipt_plan="${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  sed -i.bak '/^## 9\. I04 关闭收据$/,$d' "${receipt_plan}"
  rm "${receipt_plan}.bak"
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: omit I04 closure review receipt"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" "I04 closure review receipt mismatch"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i04_closure_projection "${fixture_root}"
  receipt_plan="${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  perl -0777 -i.bak -pe '
    s/(## 9\. I04 关闭收据.*?\n)ReviewLevel = L3\nReviewRoute = deep_reviewer\n/${1}ReviewRoute = deep_reviewer\nReviewLevel = L3\n/s
  ' "${receipt_plan}"
  rm "${receipt_plan}.bak"
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: reorder I04 closure review receipt"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" "I04 closure review receipt mismatch"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i04_closure_projection "${fixture_root}"
  receipt_plan="${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  sed -i.bak '$i\
I04ClosureUnknown = FORBIDDEN
' "${receipt_plan}"
  rm "${receipt_plan}.bak"
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: add unknown I04 review field"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" "I04 closure review receipt mismatch"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i04_closure_projection "${fixture_root}"
  receipt_plan="${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  sed -i.bak \
    's/^ReviewedCandidate = 4594406e/ReviewedCandidate = 00000000/' \
    "${receipt_plan}"
  rm "${receipt_plan}.bak"
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: use wrong I04 reviewed candidate"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" "I04 closure review receipt mismatch"

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i04_closure_projection "${fixture_root}"
  append_i04_review_receipt "${fixture_root}"
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: duplicate I04 closure review receipt"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" "I04 closure review receipt mismatch"

  for review_field_index in "${!i04_review_mutation_fields[@]}"; do
    review_field="${i04_review_mutation_fields[${review_field_index}]}"
    review_value="${i04_review_mutation_values[${review_field_index}]}"
    git -C "${fixture_root}" switch -q --detach "${governance_tip}"
    make_i04_closure_projection "${fixture_root}"
    receipt_plan="${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
    set_field "${receipt_plan}" "${review_field}" "${review_value}"
    git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}"
    git -C "${fixture_root}" commit -qm "test: mutate I04 review ${review_field}"
    expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
      "$(git -C "${fixture_root}" rev-parse HEAD)" "I04 closure review receipt mismatch"
  done

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_i04_closure_projection "${fixture_root}"
  replace_i03_closure_text "${fixture_root}/README.md" \
    "${i05_ready_narratives[2]}" "${i04_ready_narratives[2]}" \
    "restore stale I04 READY narrative"
  git -C "${fixture_root}" add "${i04_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: retain stale I04 READY narrative"
  expect_i04_closure_transition_failure "${fixture_root}" "${governance_tip}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I04 closure narrative projection mismatch"

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  printf '%s\n' 'working mask' >> "${fixture_root}/README.md"
  expect_i04_closure_static_failure "${fixture_root}" \
    "working projection must match I04 closure receipt"
  git -C "${fixture_root}" restore README.md

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  printf '%s\n' '// working I04 production mask' >> \
    "${fixture_root}/server/src/main/java/io/cognitura/source/docx/text/TextListSectionParser.java"
  expect_i04_closure_static_failure "${fixture_root}" \
    "working W1-I04 production must match the reviewed candidate"
  git -C "${fixture_root}" restore \
    server/src/main/java/io/cognitura/source/docx/text/TextListSectionParser.java

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  printf '%s\n' 'untracked' > \
    "${fixture_root}/server/src/test/resources/docx/text/working-mask.bin"
  expect_i04_closure_static_failure "${fixture_root}" \
    "working W1-I04 production must match the reviewed candidate"
  rm "${fixture_root}/server/src/test/resources/docx/text/working-mask.bin"

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  printf '%s\n' 'ignored' > \
    "${fixture_root}/server/src/test/resources/docx/text/.DS_Store"
  expect_i04_closure_static_failure "${fixture_root}" \
    "working W1-I04 production must match the reviewed candidate"
  rm "${fixture_root}/server/src/test/resources/docx/text/.DS_Store"

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  printf '%s\n' '' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add README.md
  git -C "${fixture_root}" commit -qm "test: introduce I04 projection drift"
  git -C "${fixture_root}" restore --source="${closure_sha}" README.md
  git -C "${fixture_root}" add README.md
  git -C "${fixture_root}" commit -qm "test: restore I04 projection drift"
  expect_i04_closure_static_failure "${fixture_root}" \
    "I04 closure is allowed exactly once"

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  printf '%s\n' '' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add README.md
  git -C "${fixture_root}" commit -qm "test: attempt second I04 closure"
  if second_output="$(TMPDIR="${i04_closure_tmpdir}" "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" 2>&1)"; then
    fail "second I04 closure unexpectedly passed"
  fi
  assert_contains "${second_output}" "I04 closure is allowed exactly once"
  assert_i04_closure_tmp_clean
  i04_negative_cases=$((i04_negative_cases + 1))

  [[ "${i04_positive_cases}" -eq 4 ]] ||
    fail "I04 closure positive case count mismatch: ${i04_positive_cases}"
  [[ "${i04_negative_cases}" -eq 49 ]] ||
    fail "I04 closure negative case count mismatch: ${i04_negative_cases}"
  printf '%s\n' \
    "W1I04ClosureContractTests = PASS" \
    "W1I04ClosurePositiveCases = ${i04_positive_cases}" \
    "W1I04ClosureNegativeCases = ${i04_negative_cases}"
}

w1_i05_repair_origin_sha="2fa4e067a213be03660384b4b32a9cb73c0ad64d"
w1_i05_repair_spec_path="docs/superpowers/specs/2026-08-20-cognitura-w1-i05-recovery-review-repair.md"
w1_i05_repair_fixture_correction_path="docs/superpowers/specs/2026-08-20-cognitura-w1-i05-review-repair-fixture-correction.md"
w1_i05_markdown_path="tests/ci/verify-markdown-links.sh"
w1_i05_repair_test_path="tests/task-cards/verify-wave1-implementation-cards.sh"
w1_i05_repair_verifier_path="scripts/verify-wave1-implementation-cards"
w1_i05_markdown_red_sha="a4d7173b9bfe07238db4f5427f3710bad40ba906"
w1_i05_markdown_green_sha="c5cafcdfb27ea37ca7639127ee5eed23f42467f5"
w1_i05_rejected_repair_test_sha="72a1d243ff93053ad5e254c7e7de280904bb903f"

new_w1_i05_repair_fixture() {
  local fixture_root="$1"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${w1_i05_repair_origin_sha}"
}

commit_w1_i05_repair_path() {
  local fixture_root="$1"
  local path="$2"
  local source_commit="$3"
  local message="$4"
  local mode=644
  mkdir -p "${fixture_root}/$(dirname "${path}")"
  if [[ "${source_commit}" == WORKTREE ]]; then
    cp "${repo_root}/${path}" "${fixture_root}/${path}"
  else
    git -C "${repo_root}" show "${source_commit}:${path}" > \
      "${fixture_root}/${path}"
  fi
  case "${path}" in
    tests/*|scripts/*) mode=755 ;;
  esac
  chmod "${mode}" "${fixture_root}/${path}"
  if git -C "${fixture_root}" ls-files --error-unmatch -- \
      "${path}" >/dev/null 2>&1 &&
      git -C "${fixture_root}" diff --quiet -- "${path}"; then
    printf '%s\n' '# fixture-only repair RED' >> "${fixture_root}/${path}"
  fi
  git -C "${fixture_root}" add "${path}"
  git -C "${fixture_root}" commit -qm "${message}"
}

commit_w1_i05_repair_spec() {
  commit_w1_i05_repair_path "$1" "${w1_i05_repair_spec_path}" WORKTREE \
    "test: materialize W1-I05 repair authority"
}

commit_w1_i05_markdown_red() {
  commit_w1_i05_repair_path "$1" "${w1_i05_markdown_path}" \
    "${w1_i05_markdown_red_sha}" "test: materialize Markdown masking RED"
}

commit_w1_i05_markdown_green() {
  commit_w1_i05_repair_path "$1" "${w1_i05_markdown_path}" \
    "${w1_i05_markdown_green_sha}" "test: materialize Markdown masking GREEN"
}

commit_w1_i05_repair_fixture_correction() {
  commit_w1_i05_repair_path "$1" "${w1_i05_repair_fixture_correction_path}" \
    WORKTREE "test: materialize W1-I05 repair fixture correction"
}

commit_w1_i05_corrected_repair_test() {
  commit_w1_i05_repair_path "$1" "${w1_i05_repair_test_path}" WORKTREE \
    "test: materialize corrected W1-I05 repair contract"
}

commit_w1_i05_repair_verifier() {
  commit_w1_i05_repair_path "$1" "${w1_i05_repair_verifier_path}" WORKTREE \
    "test: materialize W1-I05 repair verifier"
}

complete_w1_i05_repair_after_green() {
  local fixture_root="$1"
  commit_w1_i05_repair_path "${fixture_root}" "${w1_i05_repair_test_path}" \
    "${w1_i05_rejected_repair_test_sha}" \
    "test: materialize rejected W1-I05 repair contract"
  commit_w1_i05_repair_fixture_correction "${fixture_root}"
  commit_w1_i05_corrected_repair_test "${fixture_root}"
  commit_w1_i05_repair_verifier "${fixture_root}"
}

complete_w1_i05_repair_after_red() {
  local fixture_root="$1"
  commit_w1_i05_markdown_green "${fixture_root}"
  complete_w1_i05_repair_after_green "${fixture_root}"
}

complete_w1_i05_repair_after_spec() {
  local fixture_root="$1"
  commit_w1_i05_markdown_red "${fixture_root}"
  complete_w1_i05_repair_after_red "${fixture_root}"
}

build_legal_w1_i05_repair_fixture() {
  local fixture_root="$1"
  new_w1_i05_repair_fixture "${fixture_root}"
  commit_w1_i05_repair_spec "${fixture_root}"
  complete_w1_i05_repair_after_spec "${fixture_root}"
}

run_w1_i05_repair_verifier() {
  local fixture_root="$1"
  "${fixture_root}/${w1_i05_repair_verifier_path}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation"
}

expect_w1_i05_repair_failure() {
  local fixture_root="$1"
  local expected="$2"
  local output
  if output="$(run_w1_i05_repair_verifier "${fixture_root}" 2>&1)"; then
    fail "invalid W1-I05 repair fixture unexpectedly passed: ${fixture_root}"
  fi
  assert_contains "${output}" "${expected}"
}

run_w1_i05_verifier_recovery_contract() {
  local fixture_root
  local output
  local positive_cases=0
  local negative_cases=0

  fixture_root="${test_tmp_root}/w1-i05-repair-legal"
  build_legal_w1_i05_repair_fixture "${fixture_root}"
  output="$(run_w1_i05_repair_verifier "${fixture_root}" 2>&1)" ||
    fail "legal W1-I05 repair was rejected: ${output}"
  assert_contains "${output}" "W1I05VerifierRecoveryStatus = PASS"
  assert_contains "${output}" "W1I05RecoveryReviewRepairStatus = PASS"
  positive_cases=$((positive_cases + 1))

  mkdir -p "${fixture_root}/server/src/main/java/io/cognitura/source/docx/table"
  printf '%s\n' 'package io.cognitura.source.docx.table;' > \
    "${fixture_root}/server/src/main/java/io/cognitura/source/docx/table/TableFidelityParser.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/docx/table/TableFidelityParser.java
  git -C "${fixture_root}" commit -qm "test: add legal post-repair I05 descendant"
  output="$(run_w1_i05_repair_verifier "${fixture_root}" 2>&1)" ||
    fail "legal post-repair I05 descendant was rejected: ${output}"
  assert_contains "${output}" "W1I05RecoveryReviewRepairStatus = PASS"
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-repair-wrong-first"
  new_w1_i05_repair_fixture "${fixture_root}"
  printf '%s\n' 'wrong first' > "${fixture_root}/repair-outside.txt"
  git -C "${fixture_root}" add repair-outside.txt
  git -C "${fixture_root}" commit -qm "test: wrong first repair path"
  commit_w1_i05_repair_spec "${fixture_root}"
  complete_w1_i05_repair_after_spec "${fixture_root}"
  expect_w1_i05_repair_failure "${fixture_root}" \
    "W1-I05 review repair paths must follow the fixed order"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-repair-missing"
  new_w1_i05_repair_fixture "${fixture_root}"
  commit_w1_i05_repair_spec "${fixture_root}"
  commit_w1_i05_markdown_green "${fixture_root}"
  complete_w1_i05_repair_after_green "${fixture_root}"
  expect_w1_i05_repair_failure "${fixture_root}" \
    "W1-I05 review repair Markdown RED evidence mismatch"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-repair-extra"
  new_w1_i05_repair_fixture "${fixture_root}"
  commit_w1_i05_repair_spec "${fixture_root}"
  printf '%s\n' 'extra' > "${fixture_root}/repair-extra.txt"
  git -C "${fixture_root}" add repair-extra.txt
  git -C "${fixture_root}" commit -qm "test: add extra repair path"
  complete_w1_i05_repair_after_spec "${fixture_root}"
  expect_w1_i05_repair_failure "${fixture_root}" \
    "W1-I05 review repair paths must follow the fixed order"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-repair-repeat"
  new_w1_i05_repair_fixture "${fixture_root}"
  commit_w1_i05_repair_spec "${fixture_root}"
  commit_w1_i05_markdown_red "${fixture_root}"
  printf '%s\n' '# repeated repair' >> "${fixture_root}/${w1_i05_markdown_path}"
  git -C "${fixture_root}" add "${w1_i05_markdown_path}"
  git -C "${fixture_root}" commit -qm "test: repeat repair path"
  complete_w1_i05_repair_after_red "${fixture_root}"
  expect_w1_i05_repair_failure "${fixture_root}" \
    "W1-I05 review repair Markdown GREEN evidence mismatch"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-repair-merge"
  new_w1_i05_repair_fixture "${fixture_root}"
  commit_w1_i05_repair_spec "${fixture_root}"
  git -C "${fixture_root}" switch -q -c repair-side
  commit_w1_i05_markdown_red "${fixture_root}"
  git -C "${fixture_root}" switch -q --detach HEAD^
  git -C "${fixture_root}" merge -q --no-ff repair-side -m "test: merge repair RED"
  complete_w1_i05_repair_after_red "${fixture_root}"
  expect_w1_i05_repair_failure "${fixture_root}" \
    "W1-I05 review repair commit must have exactly one parent"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-repair-copy"
  new_w1_i05_repair_fixture "${fixture_root}"
  commit_w1_i05_repair_spec "${fixture_root}"
  cp "${fixture_root}/${w1_i05_repair_spec_path}" \
    "${fixture_root}/repair-spec-copy.md"
  git -C "${fixture_root}" add repair-spec-copy.md
  git -C "${fixture_root}" commit -qm "test: copy repair authority"
  complete_w1_i05_repair_after_spec "${fixture_root}"
  expect_w1_i05_repair_failure "${fixture_root}" \
    "W1-I05 review repair commit must not rename or copy paths"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-repair-mode"
  new_w1_i05_repair_fixture "${fixture_root}"
  commit_w1_i05_repair_spec "${fixture_root}"
  git -C "${repo_root}" show \
    "${w1_i05_markdown_red_sha}:${w1_i05_markdown_path}" > \
    "${fixture_root}/${w1_i05_markdown_path}"
  chmod 644 "${fixture_root}/${w1_i05_markdown_path}"
  git -C "${fixture_root}" add "${w1_i05_markdown_path}"
  git -C "${fixture_root}" commit -qm "test: drift repair mode"
  complete_w1_i05_repair_after_red "${fixture_root}"
  expect_w1_i05_repair_failure "${fixture_root}" \
    "W1-I05 review repair path mode mismatch"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-repair-nul"
  new_w1_i05_repair_fixture "${fixture_root}"
  commit_w1_i05_repair_spec "${fixture_root}"
  git -C "${repo_root}" show \
    "${w1_i05_markdown_red_sha}:${w1_i05_markdown_path}" > \
    "${fixture_root}/${w1_i05_markdown_path}"
  printf '\0' >> "${fixture_root}/${w1_i05_markdown_path}"
  git -C "${fixture_root}" add "${w1_i05_markdown_path}"
  git -C "${fixture_root}" commit -qm "test: add repair NUL"
  complete_w1_i05_repair_after_red "${fixture_root}"
  expect_w1_i05_repair_failure "${fixture_root}" \
    "W1-I05 review repair path must not contain NUL"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-repair-early-i05"
  new_w1_i05_repair_fixture "${fixture_root}"
  commit_w1_i05_repair_spec "${fixture_root}"
  mkdir -p "${fixture_root}/server/src/main/java/io/cognitura/source/docx/table"
  printf '%s\n' 'package io.cognitura.source.docx.table;' > \
    "${fixture_root}/server/src/main/java/io/cognitura/source/docx/table/TableFidelityParser.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/docx/table/TableFidelityParser.java
  git -C "${fixture_root}" commit -qm "test: add I05 before repair tip"
  complete_w1_i05_repair_after_spec "${fixture_root}"
  expect_w1_i05_repair_failure "${fixture_root}" \
    "W1-I05 review repair paths must follow the fixed order"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-repair-post-outside"
  build_legal_w1_i05_repair_fixture "${fixture_root}"
  printf '%s\n' 'outside' > "${fixture_root}/post-repair-outside.txt"
  git -C "${fixture_root}" add post-repair-outside.txt
  git -C "${fixture_root}" commit -qm "test: add post-repair outside path"
  expect_w1_i05_repair_failure "${fixture_root}" \
    "post-I04-closure descendant changed a path outside the W1-I05 WriteSet"
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 2 ]] ||
    fail "W1-I05 repair positive case count mismatch: ${positive_cases}"
  [[ "${negative_cases}" -eq 10 ]] ||
    fail "W1-I05 repair negative case count mismatch: ${negative_cases}"
  printf '%s\n' \
    "W1I05VerifierRecoveryContractTests = PASS" \
    "W1I05VerifierRecoveryPositiveCases = ${positive_cases}" \
    "W1I05VerifierRecoveryNegativeCases = ${negative_cases}"
}

w1_i05_literal_repair_origin_sha="083a969b8a7d1468d0274e1ce227a46ceb16db30"
w1_i05_literal_repair_spec_path="docs/superpowers/specs/2026-08-20-cognitura-w1-i05-literal-pathspec-repair.md"
w1_i05_literal_repair_spec_sha="88ce9a0"
w1_i05_literal_repair_markdown_red_sha="9435114"
w1_i05_literal_repair_markdown_green_sha="1c90804"

new_w1_i05_literal_repair_fixture() {
  local fixture_root="$1"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    "${w1_i05_literal_repair_origin_sha}"
}

commit_w1_i05_literal_repair_path() {
  local fixture_root="$1"
  local path="$2"
  local source_commit="$3"
  local message="$4"
  local mode=644
  mkdir -p "${fixture_root}/$(dirname "${path}")"
  if [[ "${source_commit}" == WORKTREE ]]; then
    cp "${repo_root}/${path}" "${fixture_root}/${path}"
  else
    git -C "${repo_root}" show "${source_commit}:${path}" > \
      "${fixture_root}/${path}"
  fi
  case "${path}" in
    tests/*|scripts/*) mode=755 ;;
  esac
  chmod "${mode}" "${fixture_root}/${path}"
  if git -C "${fixture_root}" ls-files --error-unmatch -- \
      "${path}" >/dev/null 2>&1 &&
      git -C "${fixture_root}" diff --quiet -- "${path}"; then
    printf '%s\n' '# literal-repair fixture materialization' >> \
      "${fixture_root}/${path}"
  fi
  git -C "${fixture_root}" add "${path}"
  git -C "${fixture_root}" commit -qm "${message}"
}

commit_w1_i05_literal_repair_spec() {
  commit_w1_i05_literal_repair_path "$1" \
    "${w1_i05_literal_repair_spec_path}" \
    "${w1_i05_literal_repair_spec_sha}" \
    "test: materialize literal pathspec repair authority"
}

commit_w1_i05_literal_markdown_red() {
  commit_w1_i05_literal_repair_path "$1" "${w1_i05_markdown_path}" \
    "${w1_i05_literal_repair_markdown_red_sha}" \
    "test: materialize literal pathspec RED"
}

commit_w1_i05_literal_markdown_green() {
  commit_w1_i05_literal_repair_path "$1" "${w1_i05_markdown_path}" \
    "${w1_i05_literal_repair_markdown_green_sha}" \
    "test: materialize literal pathspec GREEN"
}

complete_w1_i05_literal_repair_after_green() {
  local fixture_root="$1"
  commit_w1_i05_literal_repair_path "${fixture_root}" \
    "${w1_i05_repair_test_path}" WORKTREE \
    "test: materialize literal pathspec repair contract"
  commit_w1_i05_literal_repair_path "${fixture_root}" \
    "${w1_i05_repair_verifier_path}" WORKTREE \
    "test: materialize literal pathspec repair verifier"
}

complete_w1_i05_literal_repair_after_red() {
  local fixture_root="$1"
  commit_w1_i05_literal_markdown_green "${fixture_root}"
  complete_w1_i05_literal_repair_after_green "${fixture_root}"
}

complete_w1_i05_literal_repair_after_spec() {
  local fixture_root="$1"
  commit_w1_i05_literal_markdown_red "${fixture_root}"
  complete_w1_i05_literal_repair_after_red "${fixture_root}"
}

build_legal_w1_i05_literal_repair_fixture() {
  local fixture_root="$1"
  new_w1_i05_literal_repair_fixture "${fixture_root}"
  commit_w1_i05_literal_repair_spec "${fixture_root}"
  complete_w1_i05_literal_repair_after_spec "${fixture_root}"
}

run_w1_i05_literal_repair_verifier() {
  local fixture_root="$1"
  "${fixture_root}/${w1_i05_repair_verifier_path}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation"
}

expect_w1_i05_literal_repair_failure() {
  local fixture_root="$1"
  local expected="$2"
  local output
  if output="$(run_w1_i05_literal_repair_verifier \
      "${fixture_root}" 2>&1)"; then
    fail "invalid literal pathspec repair fixture unexpectedly passed: ${fixture_root}"
  fi
  assert_contains "${output}" "${expected}"
}

run_w1_i05_literal_repair_contract() {
  local fixture_root output
  local positive_cases=0
  local negative_cases=0

  fixture_root="${test_tmp_root}/w1-i05-literal-repair-legal"
  build_legal_w1_i05_literal_repair_fixture "${fixture_root}"
  output="$(run_w1_i05_literal_repair_verifier "${fixture_root}" 2>&1)" ||
    fail "legal literal pathspec repair was rejected: ${output}"
  assert_contains "${output}" "W1I05LiteralPathspecRepairStatus = PASS"
  positive_cases=$((positive_cases + 1))

  mkdir -p "${fixture_root}/server/src/main/java/io/cognitura/source/docx/table"
  printf '%s\n' 'package io.cognitura.source.docx.table;' > \
    "${fixture_root}/server/src/main/java/io/cognitura/source/docx/table/TableFidelityParser.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/docx/table/TableFidelityParser.java
  git -C "${fixture_root}" commit -qm "test: add legal post-literal-repair I05 descendant"
  output="$(run_w1_i05_literal_repair_verifier "${fixture_root}" 2>&1)" ||
    fail "legal post-literal-repair I05 descendant was rejected: ${output}"
  assert_contains "${output}" "W1I05LiteralPathspecRepairStatus = PASS"
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-literal-repair-wrong-first"
  new_w1_i05_literal_repair_fixture "${fixture_root}"
  printf '%s\n' 'wrong first' > "${fixture_root}/literal-repair-outside.txt"
  git -C "${fixture_root}" add literal-repair-outside.txt
  git -C "${fixture_root}" commit -qm "test: wrong first literal repair path"
  commit_w1_i05_literal_repair_spec "${fixture_root}"
  complete_w1_i05_literal_repair_after_spec "${fixture_root}"
  expect_w1_i05_literal_repair_failure "${fixture_root}" \
    "W1-I05 literal pathspec repair paths must follow the fixed order"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-literal-repair-red-mismatch"
  new_w1_i05_literal_repair_fixture "${fixture_root}"
  commit_w1_i05_literal_repair_spec "${fixture_root}"
  commit_w1_i05_literal_markdown_green "${fixture_root}"
  complete_w1_i05_literal_repair_after_green "${fixture_root}"
  expect_w1_i05_literal_repair_failure "${fixture_root}" \
    "W1-I05 literal pathspec repair Markdown RED evidence mismatch"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-literal-repair-merge"
  new_w1_i05_literal_repair_fixture "${fixture_root}"
  git -C "${fixture_root}" switch -q -c literal-repair-side
  commit_w1_i05_literal_repair_spec "${fixture_root}"
  git -C "${fixture_root}" switch -q --detach HEAD^
  git -C "${fixture_root}" merge -q --no-ff literal-repair-side \
    -m "test: merge literal repair authority"
  complete_w1_i05_literal_repair_after_spec "${fixture_root}"
  expect_w1_i05_literal_repair_failure "${fixture_root}" \
    "W1-I05 literal pathspec repair commit must have exactly one parent"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-literal-repair-post-outside"
  build_legal_w1_i05_literal_repair_fixture "${fixture_root}"
  printf '%s\n' 'outside' > "${fixture_root}/post-literal-repair-outside.txt"
  git -C "${fixture_root}" add post-literal-repair-outside.txt
  git -C "${fixture_root}" commit -qm "test: add post-literal-repair outside path"
  expect_w1_i05_literal_repair_failure "${fixture_root}" \
    "post-I04-closure descendant changed a path outside the W1-I05 WriteSet"
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 2 ]] ||
    fail "literal repair positive case count mismatch: ${positive_cases}"
  [[ "${negative_cases}" -eq 4 ]] ||
    fail "literal repair negative case count mismatch: ${negative_cases}"
  printf '%s\n' \
    "W1I05LiteralPathspecRepairContractTests = PASS" \
    "W1I05LiteralPathspecRepairPositiveCases = ${positive_cases}" \
    "W1I05LiteralPathspecRepairNegativeCases = ${negative_cases}"
}

w1_i05_xml_copy_repair_origin_sha="0f28f0802a894d3e3af127751b3ddddaab8ee840"
w1_i05_xml_copy_repair_base_sha="f25b392edfb71ba634aa96ad815816eb7a8658fa"
w1_i05_xml_copy_repair_spec_path="docs/superpowers/specs/2026-08-20-cognitura-w1-i05-xml-copy-inference-repair.md"
w1_i05_xml_copy_repair_spec_sha="5003776809d2354acf586d767f14f362eb4b612e"
w1_i05_xml_copy_rejected_test_sha="803642d1a4b1172f8c48df98b3dfb9c36e646c49"
w1_i05_xml_copy_correction_path="docs/superpowers/specs/2026-08-20-cognitura-w1-i05-xml-copy-fixture-correction.md"
w1_i05_xml_copy_correction_sha="86c46d9239155b6694e678abd637a2470367411f"

new_w1_i05_xml_copy_repair_fixture() {
  local fixture_root="$1"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    "${w1_i05_xml_copy_repair_origin_sha}"
}

commit_w1_i05_xml_copy_repair_path() {
  local fixture_root="$1"
  local path="$2"
  local source_commit="$3"
  local message="$4"
  local mode=644
  mkdir -p "${fixture_root}/$(dirname "${path}")"
  if [[ "${source_commit}" == WORKTREE ]]; then
    cp "${repo_root}/${path}" "${fixture_root}/${path}"
  else
    git -C "${repo_root}" show "${source_commit}:${path}" > \
      "${fixture_root}/${path}"
  fi
  case "${path}" in
    tests/*|scripts/*) mode=755 ;;
  esac
  chmod "${mode}" "${fixture_root}/${path}"
  if git -C "${fixture_root}" ls-files --error-unmatch -- \
      "${path}" >/dev/null 2>&1 &&
      git -C "${fixture_root}" diff --quiet -- "${path}"; then
    printf '%s\n' '# XML-copy repair fixture materialization' >> \
      "${fixture_root}/${path}"
  fi
  git -C "${fixture_root}" add "${path}"
  git -C "${fixture_root}" commit -qm "${message}"
}

commit_w1_i05_xml_copy_repair_spec() {
  commit_w1_i05_xml_copy_repair_path "$1" \
    "${w1_i05_xml_copy_repair_spec_path}" \
    "${w1_i05_xml_copy_repair_spec_sha}" \
    "test: materialize I05 XML copy repair authority"
}

complete_w1_i05_xml_copy_repair_after_spec() {
  local fixture_root="$1"
  commit_w1_i05_xml_copy_repair_path "${fixture_root}" \
    "${w1_i05_repair_test_path}" "${w1_i05_xml_copy_rejected_test_sha}" \
    "test: materialize rejected I05 XML copy repair contract"
  commit_w1_i05_xml_copy_repair_path "${fixture_root}" \
    "${w1_i05_xml_copy_correction_path}" "${w1_i05_xml_copy_correction_sha}" \
    "test: materialize I05 XML copy fixture correction"
  commit_w1_i05_xml_copy_repair_path "${fixture_root}" \
    "${w1_i05_repair_test_path}" \
    ee346dff798ef4ac77ea83686d8efa12aabcee43 \
    "test: materialize corrected I05 XML copy repair contract"
  commit_w1_i05_xml_copy_repair_path "${fixture_root}" \
    "${w1_i05_repair_verifier_path}" \
    f2f8faa005e2852000cd59cac0c5d9ec98fb6cfd \
    "test: materialize I05 XML copy repair verifier"
}

build_legal_w1_i05_xml_copy_repair_fixture() {
  local fixture_root="$1"
  new_w1_i05_xml_copy_repair_fixture "${fixture_root}"
  commit_w1_i05_xml_copy_repair_spec "${fixture_root}"
  complete_w1_i05_xml_copy_repair_after_spec "${fixture_root}"
}

run_w1_i05_xml_copy_repair_verifier() {
  local fixture_root="$1"
  "${fixture_root}/${w1_i05_repair_verifier_path}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation"
}

expect_w1_i05_xml_copy_repair_failure() {
  local fixture_root="$1"
  local expected="$2"
  local output
  if output="$(run_w1_i05_xml_copy_repair_verifier \
      "${fixture_root}" 2>&1)"; then
    fail "invalid I05 XML copy repair fixture unexpectedly passed: ${fixture_root}"
  fi
  assert_contains "${output}" "${expected}"
}

run_w1_i05_xml_copy_repair_contract() {
  local fixture_root output
  local positive_cases=0
  local negative_cases=0

  fixture_root="${test_tmp_root}/w1-i05-xml-copy-repair-legal"
  build_legal_w1_i05_xml_copy_repair_fixture "${fixture_root}"
  output="$(run_w1_i05_xml_copy_repair_verifier "${fixture_root}" 2>&1)" ||
    fail "legal I05 XML copy repair was rejected: ${output}"
  assert_contains "${output}" "W1I05XmlCopyInferenceRepairStatus = PASS"
  positive_cases=$((positive_cases + 1))

  printf '%s\n' '<w:document/>' > \
    "${fixture_root}/server/src/test/resources/docx/table/post-repair.xml"
  git -C "${fixture_root}" add \
    server/src/test/resources/docx/table/post-repair.xml
  git -C "${fixture_root}" commit -qm "test: add legal post-repair I05 fixture"
  output="$(run_w1_i05_xml_copy_repair_verifier "${fixture_root}" 2>&1)" ||
    fail "legal post-XML-copy-repair I05 descendant was rejected: ${output}"
  assert_contains "${output}" "W1I05XmlCopyInferenceRepairStatus = PASS"
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-xml-copy-repair-spec-mismatch"
  new_w1_i05_xml_copy_repair_fixture "${fixture_root}"
  mkdir -p "${fixture_root}/$(dirname "${w1_i05_xml_copy_repair_spec_path}")"
  git -C "${repo_root}" show \
    "${w1_i05_xml_copy_repair_spec_sha}:${w1_i05_xml_copy_repair_spec_path}" > \
    "${fixture_root}/${w1_i05_xml_copy_repair_spec_path}"
  printf '%s\n' 'evidence drift' >> \
    "${fixture_root}/${w1_i05_xml_copy_repair_spec_path}"
  git -C "${fixture_root}" add "${w1_i05_xml_copy_repair_spec_path}"
  git -C "${fixture_root}" commit -qm "test: materialize wrong I05 XML copy authority"
  complete_w1_i05_xml_copy_repair_after_spec "${fixture_root}"
  expect_w1_i05_xml_copy_repair_failure "${fixture_root}" \
    "W1-I05 XML copy repair evidence mismatch: step 0"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-xml-copy-repair-merge"
  new_w1_i05_xml_copy_repair_fixture "${fixture_root}"
  git -C "${fixture_root}" switch -q -c xml-copy-repair-side
  commit_w1_i05_xml_copy_repair_spec "${fixture_root}"
  git -C "${fixture_root}" switch -q --detach HEAD^
  git -C "${fixture_root}" merge -q --no-ff xml-copy-repair-side \
    -m "test: merge I05 XML copy authority"
  complete_w1_i05_xml_copy_repair_after_spec "${fixture_root}"
  expect_w1_i05_xml_copy_repair_failure "${fixture_root}" \
    "W1-I05 XML copy repair commit must have exactly one parent"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-xml-copy-repair-substitute"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    "${w1_i05_xml_copy_repair_base_sha}"
  git -C "${fixture_root}" cherry-pick -n \
    0e56cc854052b175f9389f7461912dab5b296c10
  git -C "${fixture_root}" commit -qm "test: substitute I05 implementation identity"
  git -C "${fixture_root}" cherry-pick \
    0f28f0802a894d3e3af127751b3ddddaab8ee840
  commit_w1_i05_xml_copy_repair_spec "${fixture_root}"
  complete_w1_i05_xml_copy_repair_after_spec "${fixture_root}"
  expect_w1_i05_xml_copy_repair_failure "${fixture_root}" \
    "HEAD must descend from the fixed W1-I05 implementation candidate"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-xml-copy-repair-post-outside"
  build_legal_w1_i05_xml_copy_repair_fixture "${fixture_root}"
  printf '%s\n' 'outside' > "${fixture_root}/post-XML-copy-repair-outside.txt"
  git -C "${fixture_root}" add post-XML-copy-repair-outside.txt
  git -C "${fixture_root}" commit -qm "test: add post-XML-copy-repair outside path"
  expect_w1_i05_xml_copy_repair_failure "${fixture_root}" \
    "post-I04-closure descendant changed a path outside the W1-I05 WriteSet"
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 2 ]] ||
    fail "I05 XML copy repair positive case count mismatch: ${positive_cases}"
  [[ "${negative_cases}" -eq 4 ]] ||
    fail "I05 XML copy repair negative case count mismatch: ${negative_cases}"
  printf '%s\n' \
    "W1I05XmlCopyInferenceRepairContractTests = PASS" \
    "W1I05XmlCopyInferenceRepairPositiveCases = ${positive_cases}" \
    "W1I05XmlCopyInferenceRepairNegativeCases = ${negative_cases}"
}

w1_i05_fixed_review_origin_sha="46c519f6dc79e9d12f4485a2ed9469c350b76a46"
w1_i05_fixed_review_base_sha="f2f8faa005e2852000cd59cac0c5d9ec98fb6cfd"
w1_i05_fixed_review_spec_path="docs/superpowers/specs/2026-08-21-cognitura-w1-i05-fixed-review-repair.md"
w1_i05_fixed_review_spec_sha="91c9b30eaa791b23f36726a48ca3ac5dbaa49d20"

new_w1_i05_fixed_review_fixture() {
  local fixture_root="$1"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    "${w1_i05_fixed_review_origin_sha}"
}

commit_w1_i05_fixed_review_path() {
  local fixture_root="$1"
  local path="$2"
  local source_commit="$3"
  local message="$4"
  local mode=644
  mkdir -p "${fixture_root}/$(dirname "${path}")"
  if [[ "${source_commit}" == WORKTREE ]]; then
    cp "${repo_root}/${path}" "${fixture_root}/${path}"
  else
    git -C "${repo_root}" show "${source_commit}:${path}" > \
      "${fixture_root}/${path}"
  fi
  case "${path}" in
    tests/*|scripts/*) mode=755 ;;
  esac
  chmod "${mode}" "${fixture_root}/${path}"
  if git -C "${fixture_root}" ls-files --error-unmatch -- \
      "${path}" >/dev/null 2>&1 &&
      git -C "${fixture_root}" diff --quiet -- "${path}"; then
    printf '%s\n' '# fixed-review repair fixture materialization' >> \
      "${fixture_root}/${path}"
  fi
  git -C "${fixture_root}" add "${path}"
  git -C "${fixture_root}" commit -qm "${message}"
}

commit_w1_i05_fixed_review_spec() {
  commit_w1_i05_fixed_review_path "$1" "${w1_i05_fixed_review_spec_path}" \
    "${w1_i05_fixed_review_spec_sha}" \
    "test: materialize W1-I05 fixed review repair authority"
}

complete_w1_i05_fixed_review_after_spec() {
  local fixture_root="$1"
  commit_w1_i05_fixed_review_path "${fixture_root}" \
    "${w1_i05_repair_test_path}" WORKTREE \
    "test: materialize W1-I05 fixed review repair contract"
  commit_w1_i05_fixed_review_path "${fixture_root}" \
    "${w1_i05_repair_verifier_path}" WORKTREE \
    "test: materialize W1-I05 fixed review repair verifier"
}

build_legal_w1_i05_fixed_review_fixture() {
  local fixture_root="$1"
  new_w1_i05_fixed_review_fixture "${fixture_root}"
  commit_w1_i05_fixed_review_spec "${fixture_root}"
  complete_w1_i05_fixed_review_after_spec "${fixture_root}"
}

run_w1_i05_fixed_review_verifier() {
  local fixture_root="$1"
  "${fixture_root}/${w1_i05_repair_verifier_path}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation"
}

expect_w1_i05_fixed_review_failure() {
  local fixture_root="$1"
  local expected="$2"
  local output
  if output="$(run_w1_i05_fixed_review_verifier "${fixture_root}" 2>&1)"; then
    fail "invalid W1-I05 fixed review fixture unexpectedly passed: ${fixture_root}"
  fi
  assert_contains "${output}" "${expected}"
}

run_w1_i05_fixed_review_contract() {
  local fixture_root output
  local positive_cases=0
  local negative_cases=0

  fixture_root="${test_tmp_root}/w1-i05-fixed-review-legal"
  build_legal_w1_i05_fixed_review_fixture "${fixture_root}"
  output="$(run_w1_i05_fixed_review_verifier "${fixture_root}" 2>&1)" ||
    fail "legal W1-I05 fixed review repair was rejected: ${output}"
  assert_contains "${output}" "W1I05FixedReviewRepairStatus = PASS"
  positive_cases=$((positive_cases + 1))

  printf '%s\n' '<w:document/>' > \
    "${fixture_root}/server/src/test/resources/docx/table/post-review.xml"
  git -C "${fixture_root}" add \
    server/src/test/resources/docx/table/post-review.xml
  git -C "${fixture_root}" commit -qm "test: add legal post-review I05 fixture"
  output="$(run_w1_i05_fixed_review_verifier "${fixture_root}" 2>&1)" ||
    fail "legal post-review I05 descendant was rejected: ${output}"
  assert_contains "${output}" "W1I05FixedReviewRepairStatus = PASS"
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-fixed-review-spec-mismatch"
  new_w1_i05_fixed_review_fixture "${fixture_root}"
  mkdir -p "${fixture_root}/$(dirname "${w1_i05_fixed_review_spec_path}")"
  git -C "${repo_root}" show \
    "${w1_i05_fixed_review_spec_sha}:${w1_i05_fixed_review_spec_path}" > \
    "${fixture_root}/${w1_i05_fixed_review_spec_path}"
  printf '%s\n' 'evidence drift' >> \
    "${fixture_root}/${w1_i05_fixed_review_spec_path}"
  git -C "${fixture_root}" add "${w1_i05_fixed_review_spec_path}"
  git -C "${fixture_root}" commit -qm "test: materialize wrong fixed review authority"
  complete_w1_i05_fixed_review_after_spec "${fixture_root}"
  expect_w1_i05_fixed_review_failure "${fixture_root}" \
    "W1-I05 fixed review repair evidence mismatch: step 0"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-fixed-review-merge"
  new_w1_i05_fixed_review_fixture "${fixture_root}"
  git -C "${fixture_root}" switch -q -c fixed-review-side
  commit_w1_i05_fixed_review_spec "${fixture_root}"
  git -C "${fixture_root}" switch -q --detach HEAD^
  git -C "${fixture_root}" merge -q --no-ff fixed-review-side \
    -m "test: merge fixed review authority"
  complete_w1_i05_fixed_review_after_spec "${fixture_root}"
  expect_w1_i05_fixed_review_failure "${fixture_root}" \
    "W1-I05 fixed review repair commit must have exactly one parent"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-fixed-review-substitute"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    "${w1_i05_fixed_review_base_sha}"
  git -C "${fixture_root}" cherry-pick -n \
    558ec44a0d35e0479940ebfb5fbd4c8f8c2f29b5
  git -C "${fixture_root}" commit -qm "test: substitute W1-I05 finding RED identity"
  git -C "${fixture_root}" cherry-pick \
    46c519f6dc79e9d12f4485a2ed9469c350b76a46
  commit_w1_i05_fixed_review_spec "${fixture_root}"
  complete_w1_i05_fixed_review_after_spec "${fixture_root}"
  expect_w1_i05_fixed_review_failure "${fixture_root}" \
    "HEAD must descend from the fixed W1-I05 finding repair candidate"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i05-fixed-review-post-outside"
  build_legal_w1_i05_fixed_review_fixture "${fixture_root}"
  printf '%s\n' 'outside' > "${fixture_root}/post-fixed-review-outside.txt"
  git -C "${fixture_root}" add post-fixed-review-outside.txt
  git -C "${fixture_root}" commit -qm "test: add post-review outside path"
  expect_w1_i05_fixed_review_failure "${fixture_root}" \
    "post-I04-closure descendant changed a path outside the W1-I05 WriteSet"
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 2 ]] ||
    fail "fixed review positive case count mismatch: ${positive_cases}"
  [[ "${negative_cases}" -eq 4 ]] ||
    fail "fixed review negative case count mismatch: ${negative_cases}"
  printf '%s\n' \
    "W1I05FixedReviewRepairContractTests = PASS" \
    "W1I05FixedReviewRepairPositiveCases = ${positive_cases}" \
    "W1I05FixedReviewRepairNegativeCases = ${negative_cases}"
}

i05_reviewed_candidate_sha="b4132e988cd88dce74ae026a1b52a496188452fc"
i05_closure_repair_origin_sha="b1648392f1ce02673d234287cd212a477993316d"
i05_closure_plan_sha="adac0dd30843b8b15ac393f3af30a76ae00b136f"
i05_closure_projection_paths=(
  AGENTS.md
  README.md
  docs/design/wave-1/README.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-plan.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1/README.md
  docs/task-cards/wave-1-implementation/README.md
  docs/task-cards/wave-1-implementation/W1-I05-table-fidelity.md
  docs/task-cards/wave-1-implementation/W1-I06-image-anchor-relationship-projection.md
)
i05_closure_narrative_paths=(
  AGENTS.md
  AGENTS.md
  README.md
  README.md
  docs/design/wave-1/README.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-plan.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1/README.md
  docs/task-cards/wave-1-implementation/README.md
)
i05_closure_base_narratives=(
  '`W1-I02` 等待独立数据库 Gate；`W1-I03`、`W1-I04` 已零发现关闭，`W1-I05` 为唯一 `READY` 业务卡。'
  'I00、I01、I03 和 I04 已关闭，当前已原子释放 I05；I02 保持等待独立数据库 Gate。'
  '完成零发现深审并关闭；I02 等待独立数据库 Gate，`W1-I05` 是唯一 `READY` 卡。'
  '保持 `QUEUED` 等待独立数据库 Gate；`W1-I03`、`W1-I04` 已关闭，`W1-I05` 已释放为唯一 `READY` 业务卡。'
  '  I01、I03 和 I04 已关闭，I02 等待独立数据库 Gate，I05 为唯一 `READY` 卡。'
  '`W1-I04` 已零发现关闭，`W1-I05` 已作为唯一 `READY` 卡释放。'
  $'当前业务授权只按既定卡集串行推进至 `W1-I05`；I02 独立数据库 Gate、正式数据库\n写入和远程推送仍未授权。'
  '固定候选深审并关闭；I02 等待独立数据库 Gate，I03 和 I04 已关闭且 I05 为唯一 `READY` 卡，完整证据记录在'
  '数据库 Gate；I03 和 I04 已关闭，I05 为唯一 `READY` 卡。正式数据库、Parser/Object Storage Provider、'
  'I03 和 I04 已关闭，I05 为唯一 `READY` 卡。'
  'I00、I01、I03 和 I04 已关闭；I02 等待独立数据库 Gate，W1-I05 为唯一 `READY` 业务卡。'
  '完成零发现深审并关闭；I02 等待独立数据库 Gate，I03 和 I04 已关闭且 I05 已原子释放为唯一 `READY` 卡。'
)
i05_closure_head_narratives=(
  '`W1-I02` 等待独立数据库 Gate；`W1-I03`、`W1-I04`、`W1-I05` 已零发现关闭，`W1-I06` 为唯一 `READY` 业务卡。'
  'I00、I01、I03、I04 和 I05 已关闭，当前已原子释放 I06；I02 保持等待独立数据库 Gate。'
  '完成零发现深审并关闭；I02 等待独立数据库 Gate，`W1-I06` 是唯一 `READY` 卡。'
  '保持 `QUEUED` 等待独立数据库 Gate；`W1-I03`、`W1-I04`、`W1-I05` 已关闭，`W1-I06` 已释放为唯一 `READY` 业务卡。'
  '  I01、I03、I04 和 I05 已关闭，I02 等待独立数据库 Gate，I06 为唯一 `READY` 卡。'
  '`W1-I05` 已零发现关闭，`W1-I06` 已作为唯一 `READY` 卡释放。'
  $'当前业务授权只按既定卡集串行推进至 `W1-I06`；I02 独立数据库 Gate、正式数据库\n写入和远程推送仍未授权。'
  '固定候选深审并关闭；I02 等待独立数据库 Gate，I03、I04 和 I05 已关闭且 I06 为唯一 `READY` 卡，完整证据记录在'
  '数据库 Gate；I03、I04 和 I05 已关闭，I06 为唯一 `READY` 卡。正式数据库、Parser/Object Storage Provider、'
  'I03、I04 和 I05 已关闭，I06 为唯一 `READY` 卡。'
  'I00、I01、I03、I04 和 I05 已关闭；I02 等待独立数据库 Gate，W1-I06 为唯一 `READY` 业务卡。'
  '完成零发现深审并关闭；I02 等待独立数据库 Gate，I03、I04 和 I05 已关闭且 I06 已原子释放为唯一 `READY` 卡。'
)

append_i05_review_receipt() {
  local fixture_root="$1"
  local governance_candidate governance_parent governance_tree
  governance_candidate="$(git -C "${fixture_root}" rev-parse HEAD)"
  governance_parent="$(git -C "${fixture_root}" rev-parse HEAD^)"
  governance_tree="$(git -C "${fixture_root}" rev-parse HEAD^{tree})"
  printf '%s\n' \
    '' \
    '## 10. I05 关闭收据' \
    '' \
    '```text' \
    'W1-I05 = DONE' \
    "ReviewedCandidate = ${i05_reviewed_candidate_sha}" \
    "ReviewedGovernanceCandidate = ${governance_candidate}" \
    "ReviewedGovernanceParent = ${governance_parent}" \
    "ReviewedGovernanceTree = ${governance_tree}" \
    'ReviewLevel = L3' \
    'ReviewRoute = deep_reviewer' \
    'ReviewEffort = xhigh' \
    'ReviewMultiplicity = ONE' \
    'ReviewVerdict = GO' \
    'P0 = 0' \
    'P1 = 0' \
    'P2 = 0' \
    'Ultra = NOT_RUN' \
    'I05ClosureReleasedTaskCard = W1-I06' \
    'QueuedTaskCard = W1-I02' \
    'QueuedReason = INDEPENDENT_DATABASE_GATE_REQUIRED' \
    '```' >> \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
}

misorder_i05_review_receipt() {
  local fixture_root="$1"
  perl -0777 -i -pe '
    my ($block) = /(## 10\. I05 关闭收据\n.*)\z/s;
    die "terminal I05 receipt is missing\n" unless defined $block;
    s/\Q$block\E\z//s or die "terminal I05 receipt cannot be removed\n";
    s/(## 8\. I03 关闭收据)/$block . "\n\n" . $1/e or
      die "I03 receipt anchor is missing\n";
  ' "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
}

make_i05_closure_projection() {
  local fixture_root="$1"
  local narrative_index narrative_path
  set_field "${fixture_root}/AGENTS.md" ActiveImplementationTaskCard W1-I06
  set_field "${fixture_root}/README.md" ActiveImplementationTaskCard W1-I06
  set_field "${fixture_root}/docs/design/wave-1/README.md" \
    ActiveImplementationGovernanceTaskCard W1-I06
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    ActiveTaskCard W1-I06
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    ActiveImplementationTaskCard W1-I06
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    ActiveImplementationGovernanceTaskCard W1-I06
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    ImplementationTaskCardPlanStatus I05_COMPLETE_I06_READY
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    ActiveImplementationGovernanceTaskCard W1-I06
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    ActiveTaskCard W1-I06
  set_table_status \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    W1-I05 READY DONE
  set_table_status \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    W1-I06 BLOCKED_BY_DEPENDENCY READY
  set_field "${fixture_root}/docs/task-cards/wave-1/README.md" \
    ActiveImplementationGovernanceTaskCard W1-I06
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    ActiveTaskCard W1-I06
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I05 READY DONE
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I06 BLOCKED_BY_DEPENDENCY READY
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I05-table-fidelity.md" \
    Status DONE
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I06-image-anchor-relationship-projection.md" \
    Status READY
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I06-image-anchor-relationship-projection.md" \
    BusinessImplementationAuthorization USER_AUTHORIZED
  append_i05_review_receipt "${fixture_root}"
  for narrative_index in "${!i05_closure_base_narratives[@]}"; do
    narrative_path="${i05_closure_narrative_paths[${narrative_index}]}"
    replace_i03_closure_text \
      "${fixture_root}/${narrative_path}" \
      "${i05_closure_base_narratives[${narrative_index}]}" \
      "${i05_closure_head_narratives[${narrative_index}]}" \
      "close I05 narrative ${narrative_path}"
  done
}

commit_i05_closure_projection() {
  local fixture_root="$1"
  make_i05_closure_projection "${fixture_root}"
  git -C "${fixture_root}" add "${i05_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: close W1-I05 and release W1-I06"
}

expect_i05_closure_transition_failure() {
  local fixture_root="$1"
  local base_sha="$2"
  local head_sha="$3"
  local expected_message="$4"
  local output
  if output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${base_sha}" \
    --transition-head "${head_sha}" 2>&1)"; then
    fail "invalid I05 closure transition unexpectedly passed: ${expected_message}"
  fi
  assert_contains "${output}" "${expected_message}"
}

run_w1_i05_closure_contract() {
  local fixture_root base_sha closure_sha output mutation_sha
  local positive_cases=0
  local negative_cases=0
  fixture_root="${test_tmp_root}/w1-i05-closure"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  base_sha="$(git -C "${fixture_root}" rev-list --first-parent --reverse \
    "${i05_closure_repair_origin_sha}..HEAD" | sed -n '3p')"
  [[ -n "${base_sha}" ]] || base_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  git -C "${fixture_root}" checkout -q --detach "${base_sha}"
  base_sha="$(git -C "${fixture_root}" rev-parse HEAD)"

  commit_i05_closure_projection "${fixture_root}"
  closure_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${base_sha}" \
    --transition-head "${closure_sha}")" ||
    fail "legal explicit I05 closure receipt was rejected: ${output}"
  assert_contains "${output}" "W1I05ClosureStatus = PASS"
  positive_cases=$((positive_cases + 1))

  output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation")" ||
    fail "legal static I05 closure receipt was rejected: ${output}"
  assert_contains "${output}" "ActiveTaskCard = W1-I06"
  assert_contains "${output}" "W1I05ClosureStatus = PASS"
  positive_cases=$((positive_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${base_sha}"
  make_i05_closure_projection "${fixture_root}"
  sed -i.bak "s/${i05_reviewed_candidate_sha}/0000000000000000000000000000000000000000/" \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i05_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: bind wrong I05 reviewed candidate"
  expect_i05_closure_transition_failure "${fixture_root}" "${base_sha}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I05 closure review receipt mismatch"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${base_sha}"
  make_i05_closure_projection "${fixture_root}"
  git -C "${fixture_root}" restore --source="${base_sha}" \
    docs/task-cards/wave-1-implementation/W1-I06-image-anchor-relationship-projection.md
  git -C "${fixture_root}" add "${i05_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: omit I06 closure projection"
  expect_i05_closure_transition_failure "${fixture_root}" "${base_sha}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I05 closure receipt fixed diff must equal the exact eleven projection paths"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${base_sha}"
  make_i05_closure_projection "${fixture_root}"
  misorder_i05_review_receipt "${fixture_root}"
  git -C "${fixture_root}" add "${i05_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: misorder I05 closure receipt"
  expect_i05_closure_transition_failure "${fixture_root}" "${base_sha}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I05 closure review receipt mismatch"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${base_sha}"
  make_i05_closure_projection "${fixture_root}"
  printf '%s\n' extra > "${fixture_root}/i05-closure-extra.txt"
  git -C "${fixture_root}" add "${i05_closure_projection_paths[@]}" i05-closure-extra.txt
  git -C "${fixture_root}" commit -qm "test: add extra I05 closure projection"
  expect_i05_closure_transition_failure "${fixture_root}" "${base_sha}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I05 closure receipt fixed diff must equal the exact eleven projection paths"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${base_sha}"
  git -C "${fixture_root}" commit --allow-empty -qm "test: insert non-direct I05 receipt ancestor"
  commit_i05_closure_projection "${fixture_root}"
  expect_i05_closure_transition_failure "${fixture_root}" "${base_sha}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I05 closure receipt HEAD must be the direct child of BASE"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${base_sha}"
  make_i05_closure_projection "${fixture_root}"
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I03 DONE READY
  git -C "${fixture_root}" add "${i05_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: release a second READY card with I06"
  expect_i05_closure_transition_failure "${fixture_root}" "${base_sha}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I05 closure receipt must release exactly one READY card"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${base_sha}"
  make_i05_closure_projection "${fixture_root}"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I06-image-anchor-relationship-projection.md" \
    BusinessImplementationAuthorization REQUIRED_BEFORE_READY
  git -C "${fixture_root}" add "${i05_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: release I06 without business authorization"
  expect_i05_closure_transition_failure "${fixture_root}" "${base_sha}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I05 closure must explicitly authorize W1-I06"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${base_sha}"
  printf '%s\n' '// forbidden pre-BASE product drift' >> \
    "${fixture_root}/server/src/main/java/io/cognitura/source/docx/table/TableFidelityParser.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/docx/table/TableFidelityParser.java
  git -C "${fixture_root}" commit -qm "test: drift I05 product before closure BASE"
  mutation_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  commit_i05_closure_projection "${fixture_root}"
  expect_i05_closure_transition_failure "${fixture_root}" "${mutation_sha}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "reviewed W1-I05 production must remain byte-identical"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  printf '%s\n' outside > "${fixture_root}/post-i05-outside.txt"
  git -C "${fixture_root}" add post-i05-outside.txt
  git -C "${fixture_root}" commit -qm "test: add explicit post-I05 outside path"
  expect_i05_closure_transition_failure "${fixture_root}" "${closure_sha}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "post-I05-closure descendant changed a path outside the W1-I06 WriteSet"
  negative_cases=$((negative_cases + 1))

  expect_i05_closure_transition_failure "${fixture_root}" "${closure_sha}" \
    "${base_sha}" \
    "I05 post-closure transition HEAD must descend from BASE"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${base_sha}"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I05-table-fidelity.md" \
    Status DONE
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I06-image-anchor-relationship-projection.md" \
    Status READY
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I06-image-anchor-relationship-projection.md" \
    BusinessImplementationAuthorization USER_AUTHORIZED
  git -C "${fixture_root}" add \
    docs/task-cards/wave-1-implementation/W1-I05-table-fidelity.md \
    docs/task-cards/wave-1-implementation/W1-I06-image-anchor-relationship-projection.md
  git -C "${fixture_root}" commit -qm "test: forge equal I05 closure BASE and HEAD"
  mutation_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  expect_i05_closure_transition_failure "${fixture_root}" "${mutation_sha}" \
    "${mutation_sha}" \
    "I05 closure receipt fixed diff must equal the exact eleven projection paths"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  printf '%s\n' '' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add README.md
  git -C "${fixture_root}" commit -qm "test: replay I05 closure projection"
  mutation_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  if output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" 2>&1)"; then
    fail "post-I05 closure projection replay unexpectedly passed"
  fi
  assert_contains "${output}" "I05 closure is allowed exactly once"
  negative_cases=$((negative_cases + 1))
  [[ -n "${mutation_sha}" ]] || fail "I05 closure mutation SHA is missing"

  [[ "${positive_cases}" -eq 2 ]] ||
    fail "I05 closure positive case count mismatch: ${positive_cases}"
  [[ "${negative_cases}" -eq 12 ]] ||
    fail "I05 closure negative case count mismatch: ${negative_cases}"
  printf '%s\n' \
    "W1I05ClosureContractTests = PASS" \
    "W1I05ClosurePositiveCases = ${positive_cases}" \
    "W1I05ClosureNegativeCases = ${negative_cases}"
}

w1_i06_entry_repair_origin_sha="5937fe6845f3cd7759dcaa5156bfc9f9060b5407"
w1_i06_entry_repair_design_sha="d8c0614d736126cdb914508084d0c84c61420d88"
w1_i06_entry_repair_plan_sha="c5d86bdf29edf790a154ba784592743211a958e0"
w1_i06_entry_review_red_paths=(
  server/src/test/java/io/cognitura/source/docx/text/TextListSectionParserTest.java
)
w1_i06_entry_review_green_paths=(
  server/src/main/java/io/cognitura/source/docx/text/TextListSectionParser.java
)

w1_i06_entry_repair_governance_tip() {
  local tip
  tip="$(git -C "${repo_root}" rev-list --first-parent --reverse \
    "${w1_i06_entry_repair_origin_sha}..HEAD" | sed -n '11p')"
  [[ -n "${tip}" ]] || tip="$(git -C "${repo_root}" rev-parse HEAD)"
  printf '%s\n' "${tip}"
}

new_w1_i06_entry_repair_fixture() {
  local fixture_root="$1"
  local governance_tip="$2"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${governance_tip}"
}

commit_w1_i06_entry_review_red() {
  local fixture_root="$1"
  printf '%s\n' '// W1-I04 image-payload finding RED marker' >> \
    "${fixture_root}/server/src/test/java/io/cognitura/source/docx/text/TextListSectionParserTest.java"
  git -C "${fixture_root}" add "${w1_i06_entry_review_red_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: reject empty image payload wrappers"
}

commit_w1_i06_entry_review_green() {
  local fixture_root="$1"
  printf '%s\n' '// W1-I04 image-payload finding GREEN marker' >> \
    "${fixture_root}/server/src/main/java/io/cognitura/source/docx/text/TextListSectionParser.java"
  git -C "${fixture_root}" add "${w1_i06_entry_review_green_paths[@]}"
  git -C "${fixture_root}" commit -qm "fix: require unique image payload evidence"
}

expect_w1_i06_entry_repair_failure() {
  local fixture_root="$1"
  local expected_message="$2"
  local output
  if output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" 2>&1)"; then
    fail "invalid W1-I06 entry-repair chain unexpectedly passed: ${expected_message}"
  fi
  assert_contains "${output}" "${expected_message}"
}

run_w1_i06_entry_repair_contract() {
  local fixture_root governance_tip output substitute_sha branch_sha
  local replay_commit
  local synthetic_base_sha
  local positive_cases=0
  local negative_cases=0

  governance_tip="$(w1_i06_entry_repair_governance_tip)"

  fixture_root="${test_tmp_root}/w1-i06-entry-repair-pending"
  new_w1_i06_entry_repair_fixture "${fixture_root}" "${governance_tip}"
  output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation")" ||
    fail "legal W1-I06 entry-repair governance tip was rejected: ${output}"
  assert_contains "${output}" "W1I06EntryRepairStatus = PENDING"
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i06-entry-repair-complete"
  new_w1_i06_entry_repair_fixture "${fixture_root}" "${governance_tip}"
  commit_w1_i06_entry_review_red "${fixture_root}"
  commit_w1_i06_entry_review_green "${fixture_root}"
  output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation")" ||
    fail "legal complete W1-I06 entry-repair chain was rejected: ${output}"
  assert_contains "${output}" "W1I06EntryRepairStatus = PASS"
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i06-entry-repair-nonfixed-receipt"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  synthetic_base_sha="$(git -C "${fixture_root}" rev-list --first-parent --reverse \
    "${i05_closure_repair_origin_sha}..HEAD" | sed -n '3p')"
  [[ -n "${synthetic_base_sha}" ]] ||
    fail "synthetic I05 closure base is unavailable"
  git -C "${fixture_root}" checkout -q --detach "${synthetic_base_sha}"
  commit_i05_closure_projection "${fixture_root}"
  mkdir -p \
    "${fixture_root}/server/src/main/java/io/cognitura/source/docx/image"
  printf '%s\n' 'package io.cognitura.source.docx.image;' > \
    "${fixture_root}/server/src/main/java/io/cognitura/source/docx/image/ImageAnchor.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/docx/image/ImageAnchor.java
  git -C "${fixture_root}" commit -qm \
    "test: bypass entry repair after non-fixed I05 receipt"
  expect_w1_i06_entry_repair_failure "${fixture_root}" \
    "non-fixed I05 closure receipt must not have descendants"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i06-entry-repair-substitute"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    "${w1_i06_entry_repair_origin_sha}"
  git -C "${fixture_root}" cherry-pick -n "${w1_i06_entry_repair_design_sha}"
  git -C "${fixture_root}" commit -qm "test: substitute W1-I06 entry-repair design"
  substitute_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  [[ "${substitute_sha}" != "${w1_i06_entry_repair_design_sha}" ]] ||
    fail "substituted W1-I06 entry-repair design retained the fixed identity"
  for replay_commit in $(git -C "${repo_root}" rev-list --first-parent --reverse \
    "${w1_i06_entry_repair_origin_sha}..${governance_tip}" | sed -n '2,$p'); do
    git -C "${fixture_root}" cherry-pick "${replay_commit}"
  done
  expect_w1_i06_entry_repair_failure "${fixture_root}" \
    "W1-I06 entry-repair governance identity mismatch"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i06-entry-repair-empty"
  new_w1_i06_entry_repair_fixture "${fixture_root}" "${governance_tip}"
  git -C "${fixture_root}" commit --allow-empty -qm \
    "test: insert empty W1-I06 entry-repair commit"
  expect_w1_i06_entry_repair_failure "${fixture_root}" \
    "W1-I06 entry-repair RED commit must be nonempty"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i06-entry-repair-reversed"
  new_w1_i06_entry_repair_fixture "${fixture_root}" "${governance_tip}"
  commit_w1_i06_entry_review_green "${fixture_root}"
  commit_w1_i06_entry_review_red "${fixture_root}"
  expect_w1_i06_entry_repair_failure "${fixture_root}" \
    "W1-I06 entry-repair RED commit must change exactly the declared test paths"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i06-entry-repair-undeclared"
  new_w1_i06_entry_repair_fixture "${fixture_root}" "${governance_tip}"
  commit_w1_i06_entry_review_red "${fixture_root}"
  git -C "${fixture_root}" reset -q HEAD^
  printf '%s\n' '<!-- undeclared W1-I04 finding path -->' >> \
    "${fixture_root}/server/src/test/resources/docx/text/inline-images.xml"
  git -C "${fixture_root}" add \
    "${w1_i06_entry_review_red_paths[@]}" \
    server/src/test/resources/docx/text/inline-images.xml
  git -C "${fixture_root}" commit -qm "test: add undeclared I04 repair path"
  expect_w1_i06_entry_repair_failure "${fixture_root}" \
    "W1-I06 entry-repair RED commit must change exactly the declared test paths"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i06-entry-repair-merge"
  new_w1_i06_entry_repair_fixture "${fixture_root}" "${governance_tip}"
  git -C "${fixture_root}" switch -q -c w1-i06-merge-side
  commit_w1_i06_entry_review_red "${fixture_root}"
  branch_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  git -C "${fixture_root}" merge -q --no-ff "${branch_sha}" \
    -m "test: merge W1-I06 entry-repair paths"
  expect_w1_i06_entry_repair_failure "${fixture_root}" \
    "W1-I06 entry-repair RED commit must have exactly one parent"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i06-entry-repair-post-outside"
  new_w1_i06_entry_repair_fixture "${fixture_root}" "${governance_tip}"
  commit_w1_i06_entry_review_red "${fixture_root}"
  commit_w1_i06_entry_review_green "${fixture_root}"
  printf '%s\n' '' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add README.md
  git -C "${fixture_root}" commit -qm "test: add post-repair outside path"
  expect_w1_i06_entry_repair_failure "${fixture_root}" \
    "post-W1-I06-entry-repair descendant changed a path outside the W1-I06 WriteSet"
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 2 ]] ||
    fail "W1-I06 entry-repair positive case count mismatch: ${positive_cases}"
  [[ "${negative_cases}" -eq 7 ]] ||
    fail "W1-I06 entry-repair negative case count mismatch: ${negative_cases}"
  printf '%s\n' \
    "W1I06EntryRepairContractTests = PASS" \
    "W1I06EntryRepairPositiveCases = ${positive_cases}" \
    "W1I06EntryRepairNegativeCases = ${negative_cases}"
}

i06_copy_repair_origin_sha="ee4740a22f103086c38ff27c2f0b9e02820cffcc"
i06_internal_projection_red_sha="68c3fe77bd7cbe3a69d1dd294a6dc7d716d6b307"
i06_internal_projection_green_sha="bb0c88128d7b58112bf20710d08cf7447c793685"
i06_external_projection_red_sha="5e2c6c132fef438a5c7cb54c6de6c83ec77f85f9"
i06_external_projection_green_sha="ee4740a22f103086c38ff27c2f0b9e02820cffcc"
i06_copy_repair_test_sha="61cbb3136ffaf3f0ba3b6b4f4acef57ba4fabdca"
i06_copy_repair_green_sha="71fa70e11f7adf88096839f0fef5e148ba83e989"

new_i06_copy_repair_fixture() {
  local fixture_root="$1"
  local checkout_sha="$2"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${checkout_sha}"
}

run_i06_copy_repair_verifier() {
  local fixture_root="$1"
  "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation"
}

materialize_i06_copy_repair_tip() {
  local fixture_root="$1"
  git -C "${fixture_root}" checkout -q --detach "${i06_copy_repair_green_sha}"
  cp \
    "${repo_root}/tests/task-cards/verify-wave1-implementation-cards.sh" \
    "${fixture_root}/tests/task-cards/verify-wave1-implementation-cards.sh"
  chmod 755 "${fixture_root}/tests/task-cards/verify-wave1-implementation-cards.sh"
  cp "${verifier}" "${fixture_root}/scripts/verify-wave1-implementation-cards"
  chmod 755 "${fixture_root}/scripts/verify-wave1-implementation-cards"
  git -C "${fixture_root}" add \
    tests/task-cards/verify-wave1-implementation-cards.sh \
    scripts/verify-wave1-implementation-cards
  git -C "${fixture_root}" commit -qm "fix: admit fixed I06 copy inference"
}

expect_i06_copy_repair_failure() {
  local fixture_root="$1"
  local expected_message="$2"
  local output
  if output="$(run_i06_copy_repair_verifier "${fixture_root}" 2>&1)"; then
    fail "invalid I06 copy-inference chain unexpectedly passed: ${expected_message}"
  fi
  assert_contains "${output}" "${expected_message}"
}

run_w1_i06_copy_inference_repair_contract() {
  local fixture_root output repair_tip substitute_sha
  local positive_cases=0
  local negative_cases=0

  fixture_root="${test_tmp_root}/w1-i06-copy-fixed-candidate"
  new_i06_copy_repair_fixture "${fixture_root}" "${i06_copy_repair_origin_sha}"
  output="$(run_i06_copy_repair_verifier "${fixture_root}")" ||
    fail "fixed I06 copy-inference candidate was rejected: ${output}"
  assert_contains "${output}" "W1I06EntryRepairStatus = PASS"
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i06-copy-repair-tip"
  new_i06_copy_repair_fixture "${fixture_root}" "${i06_copy_repair_origin_sha}"
  materialize_i06_copy_repair_tip "${fixture_root}"
  repair_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  printf '%s\n' '// legal post-repair I06 descendant' >> \
    "${fixture_root}/server/src/main/java/io/cognitura/source/docx/image/MediaDigest.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/docx/image/MediaDigest.java
  git -C "${fixture_root}" commit -qm "test: add legal post-repair I06 descendant"
  output="$(run_i06_copy_repair_verifier "${fixture_root}")" ||
    fail "legal post-repair I06 descendant was rejected: ${output}"
  assert_contains "${output}" "W1I06EntryRepairStatus = PASS"
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i06-copy-substituted-identity"
  new_i06_copy_repair_fixture "${fixture_root}" \
    "982c04b708b4a9072e34f410eb6eebcb1be3411c"
  git -C "${fixture_root}" cherry-pick -n "${i06_internal_projection_red_sha}"
  git -C "${fixture_root}" commit -qm "test: substitute I06 internal projection RED"
  substitute_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  [[ "${substitute_sha}" != "${i06_internal_projection_red_sha}" ]] ||
    fail "substituted I06 copy commit retained the fixed identity"
  git -C "${fixture_root}" cherry-pick "${i06_internal_projection_green_sha}" >/dev/null
  git -C "${fixture_root}" cherry-pick "${i06_external_projection_red_sha}" >/dev/null
  git -C "${fixture_root}" cherry-pick "${i06_external_projection_green_sha}" >/dev/null
  expect_i06_copy_repair_failure "${fixture_root}" \
    "post-W1-I06-entry-repair descendant commit must not rename or copy paths"
  negative_cases=$((negative_cases + 1))

  git -C "${test_tmp_root}/w1-i06-copy-repair-tip" switch -q --detach "${repair_tip}"
  cp \
    "${test_tmp_root}/w1-i06-copy-repair-tip/server/src/test/resources/docx/security/minimal-content-types.xml" \
    "${test_tmp_root}/w1-i06-copy-repair-tip/server/src/test/resources/docx/image/future-copy.xml"
  git -C "${test_tmp_root}/w1-i06-copy-repair-tip" add \
    server/src/test/resources/docx/image/future-copy.xml
  git -C "${test_tmp_root}/w1-i06-copy-repair-tip" commit -qm \
    "test: infer a future I06 fixture copy"
  expect_i06_copy_repair_failure \
    "${test_tmp_root}/w1-i06-copy-repair-tip" \
    "post-W1-I06-entry-repair descendant commit must not rename or copy paths"
  negative_cases=$((negative_cases + 1))

  git -C "${test_tmp_root}/w1-i06-copy-repair-tip" switch -q --detach "${repair_tip}"
  git -C "${test_tmp_root}/w1-i06-copy-repair-tip" mv \
    server/src/test/resources/docx/image/external-images-document.xml \
    server/src/test/resources/docx/image/external-images-document-renamed.xml
  git -C "${test_tmp_root}/w1-i06-copy-repair-tip" commit -qm \
    "test: rename a future I06 fixture"
  expect_i06_copy_repair_failure \
    "${test_tmp_root}/w1-i06-copy-repair-tip" \
    "post-W1-I06-entry-repair descendant commit must not rename or copy paths"
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 2 ]] ||
    fail "I06 copy-inference positive case count mismatch: ${positive_cases}"
  [[ "${negative_cases}" -eq 3 ]] ||
    fail "I06 copy-inference negative case count mismatch: ${negative_cases}"
  printf '%s\n' \
    "W1I06CopyInferenceRepairContractTests = PASS" \
    "W1I06CopyInferenceRepairPositiveCases = ${positive_cases}" \
    "W1I06CopyInferenceRepairNegativeCases = ${negative_cases}"
}

i06_reviewed_candidate_sha="2a7e1cec184ea50d9e0a5c37d6f3acfa63c955ea"
i06_reviewed_parent_sha="091cccd28216dc9d69588874d82a65548e8a389a"
i06_reviewed_tree_sha="d87740229c75f8411347f291abdc2a5faf44e9cf"
i06_closure_projection_paths=(
  AGENTS.md
  README.md
  docs/design/wave-1/README.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-plan.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1/README.md
  docs/task-cards/wave-1-implementation/README.md
  docs/task-cards/wave-1-implementation/W1-I06-image-anchor-relationship-projection.md
)

append_i06_review_receipt() {
  local fixture_root="$1"
  printf '%s\n' \
    '' \
    '## 11. I06 关闭收据' \
    '' \
    '```text' \
    'W1-I06 = DONE' \
    "ReviewedCandidate = ${i06_reviewed_candidate_sha}" \
    "ReviewedGovernanceCandidate = ${i06_reviewed_candidate_sha}" \
    "ReviewedGovernanceParent = ${i06_reviewed_parent_sha}" \
    "ReviewedGovernanceTree = ${i06_reviewed_tree_sha}" \
    'ReviewLevel = L3' \
    'ReviewRoute = deep_reviewer' \
    'ReviewEffort = xhigh' \
    'ReviewMultiplicity = ONE' \
    'ReviewVerdict = GO' \
    'P0 = 0' \
    'P1 = 0' \
    'P2 = 0' \
    'Ultra = NOT_RUN' \
    'I06ClosureTaskCardSetStatus = BLOCKED_BY_DATABASE_GATE' \
    'BlockedTaskCard = W1-I02' \
    'BlockedReason = INDEPENDENT_DATABASE_GATE_REQUIRED' \
    'ReleasedTaskCard = NONE' \
    'FormalDatabaseWrite = NOT_AUTHORIZED' \
    'RemotePush = NOT_AUTHORIZED' \
    '```' >> \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
}

make_i06_closure_projection() {
  local fixture_root="$1"
  set_field "${fixture_root}/AGENTS.md" Wave1ImplementationTaskCardSet BLOCKED_BY_DATABASE_GATE
  set_field "${fixture_root}/AGENTS.md" ActiveImplementationTaskCard NONE
  set_field "${fixture_root}/README.md" Wave1ImplementationTaskCardSet BLOCKED_BY_DATABASE_GATE
  set_field "${fixture_root}/README.md" ActiveImplementationTaskCard NONE
  set_field "${fixture_root}/docs/design/wave-1/README.md" Wave1ImplementationTaskCardSet BLOCKED_BY_DATABASE_GATE
  set_field "${fixture_root}/docs/design/wave-1/README.md" ActiveImplementationGovernanceTaskCard NONE
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" Wave1ImplementationTaskCardSet BLOCKED_BY_DATABASE_GATE
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" ActiveTaskCard NONE
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" ActiveTaskCardStatus NONE
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" ActiveImplementationTaskCard NONE
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" Wave1ImplementationTaskCardSet BLOCKED_BY_DATABASE_GATE
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" ActiveImplementationGovernanceTaskCard NONE
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" ImplementationTaskCardPlanStatus I06_COMPLETE_BLOCKED_BY_DATABASE_GATE
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" Wave1ImplementationTaskCardSet BLOCKED_BY_DATABASE_GATE
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" ActiveImplementationGovernanceTaskCard NONE
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" TaskCardSetStatus BLOCKED_BY_DATABASE_GATE
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" ActiveTaskCard NONE
  set_table_status "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" W1-I06 READY DONE
  set_field "${fixture_root}/docs/task-cards/wave-1/README.md" Wave1ImplementationTaskCardSet BLOCKED_BY_DATABASE_GATE
  set_field "${fixture_root}/docs/task-cards/wave-1/README.md" ActiveImplementationGovernanceTaskCard NONE
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" TaskCardSetStatus BLOCKED_BY_DATABASE_GATE
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" ActiveTaskCard NONE
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" ReadyTaskCardCount 0
  set_table_status "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" W1-I06 READY DONE
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I06-image-anchor-relationship-projection.md" Status DONE
  append_i06_review_receipt "${fixture_root}"
}

commit_i06_closure_projection() {
  local fixture_root="$1"
  make_i06_closure_projection "${fixture_root}"
  git -C "${fixture_root}" add "${i06_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: close W1-I06 behind database gate"
}

expect_i06_closure_failure() {
  local fixture_root="$1"
  local base_sha="$2"
  local head_sha="$3"
  local expected_message="$4"
  local output
  if output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${base_sha}" \
    --transition-head "${head_sha}" 2>&1)"; then
    fail "invalid I06 closure unexpectedly passed: ${expected_message}"
  fi
  assert_contains "${output}" "${expected_message}"
}

run_w1_i06_closure_contract() {
  local fixture_root base_sha closure_sha output
  local positive_cases=0
  local negative_cases=0
  fixture_root="${test_tmp_root}/w1-i06-closure"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${i06_reviewed_candidate_sha}"
  base_sha="$(git -C "${fixture_root}" rev-parse HEAD)"

  commit_i06_closure_projection "${fixture_root}"
  closure_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${base_sha}" \
    --transition-head "${closure_sha}")" ||
    fail "legal explicit I06 closure was rejected: ${output}"
  assert_contains "${output}" "W1I06ClosureStatus = PASS"
  assert_contains "${output}" "TaskCardSetStatus = BLOCKED_BY_DATABASE_GATE"
  positive_cases=$((positive_cases + 1))

  output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation")" ||
    fail "legal static I06 closure was rejected: ${output}"
  assert_contains "${output}" "ActiveTaskCard = NONE"
  assert_contains "${output}" "W1I06ClosureStatus = PASS"
  positive_cases=$((positive_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${base_sha}"
  make_i06_closure_projection "${fixture_root}"
  sed -i.bak "s/${i06_reviewed_candidate_sha}/0000000000000000000000000000000000000000/" \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i06_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: bind wrong I06 reviewed candidate"
  expect_i06_closure_failure "${fixture_root}" "${base_sha}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I06 closure review receipt mismatch"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${base_sha}"
  make_i06_closure_projection "${fixture_root}"
  set_table_status "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I07 BLOCKED_BY_DEPENDENCY READY
  git -C "${fixture_root}" add "${i06_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: release I07 without database gate"
  expect_i06_closure_failure "${fixture_root}" "${base_sha}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I06 closure must not release a READY card"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${base_sha}"
  make_i06_closure_projection "${fixture_root}"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    FormalDatabaseWrite AUTHORIZED
  git -C "${fixture_root}" add "${i06_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: authorize database write during I06 closure"
  expect_i06_closure_failure "${fixture_root}" "${base_sha}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I06 closure must preserve database and push authorization boundaries"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${base_sha}"
  make_i06_closure_projection "${fixture_root}"
  printf '%s\n' extra > "${fixture_root}/i06-closure-extra.txt"
  git -C "${fixture_root}" add "${i06_closure_projection_paths[@]}" i06-closure-extra.txt
  git -C "${fixture_root}" commit -qm "test: add extra I06 closure path"
  expect_i06_closure_failure "${fixture_root}" "${base_sha}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "I06 closure receipt fixed diff must equal the exact ten projection paths"
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 2 ]] ||
    fail "I06 closure positive case count mismatch: ${positive_cases}"
  [[ "${negative_cases}" -eq 4 ]] ||
    fail "I06 closure negative case count mismatch: ${negative_cases}"
  printf '%s\n' \
    "W1I06ClosureContractTests = PASS" \
    "W1I06ClosurePositiveCases = ${positive_cases}" \
    "W1I06ClosureNegativeCases = ${negative_cases}"
}

w1_i02_database_gate_origin_sha="8175f340c4f3d116a7aa5bc1f6ee5f67b489dee6"
w1_i02_database_gate_design_sha="97504c281b61f6d15ca347c1e0d0369e44819110"
w1_i02_database_gate_plan_sha="1fc1eb6c1d4493e62c8a55979a404f1fff199920"
w1_i02_database_gate_test_sha="2a5f936a3ae9a8e873299b88fea6c59dd8986df7"
w1_i02_database_gate_tip_sha="042a039f8582a51e501530b629fb24fdb3b74c45"
w1_i02_database_gate_rejected_verifier_sha="01165a315dafb77571e74b5086ff85a25ae0e574"
w1_i02_postgres_image="postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a"
w1_i02_release_projection_paths=(
  AGENTS.md
  README.md
  docs/design/wave-1/README.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-plan.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1/README.md
  docs/task-cards/wave-1-implementation/README.md
  docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md
)

find_w1_i02_gate_commit_after() {
  local base_sha="$1"
  local expected_path="$2"
  local commit changed_paths
  for commit in $(git -C "${repo_root}" rev-list --first-parent --reverse \
    "${base_sha}..HEAD"); do
    changed_paths="$(git -C "${repo_root}" diff --name-only "${commit}^..${commit}")"
    if [[ "${changed_paths}" == "${expected_path}" ]]; then
      printf '%s\n' "${commit}"
      return 0
    fi
  done
  return 1
}

find_last_w1_i02_gate_commit_after() {
  local base_sha="$1"
  local expected_path="$2"
  local commit changed_paths found=""
  for commit in $(git -C "${repo_root}" rev-list --first-parent --reverse \
    "${base_sha}..HEAD"); do
    changed_paths="$(git -C "${repo_root}" diff --name-only "${commit}^..${commit}")"
    [[ "${changed_paths}" == "${expected_path}" ]] && found="${commit}"
  done
  [[ -n "${found}" ]] || return 1
  printf '%s\n' "${found}"
}

require_w1_i02_probe_contract() {
  local image="$1"
  local major="$2"
  local reuse="$3"
  local removal="$4"
  [[ "${image}" == "${w1_i02_postgres_image}" && "${major}" == 18 &&
     "${reuse}" == FALSE ]] ||
    fail "W1_I02_DATABASE_GATE_IMAGE_MISMATCH"
  [[ "${removal}" == PASS ]] ||
    fail "W1_I02_DATABASE_GATE_REMOVAL_REQUIRED"
}

run_w1_i02_isolated_postgres_probe() {
  local variable_name variable_value probe_classpath_file probe_classpath probe_output
  for variable_name in SPRING_DATASOURCE_URL JDBC_DATABASE_URL DATABASE_URL \
    PGHOST PGPORT PGUSER PGPASSWORD; do
    variable_value="$(printenv "${variable_name}" 2>/dev/null || true)"
    [[ -z "${variable_value}" ]] ||
      fail "W1_I02_DATABASE_GATE_HOST_DB_INPUT_FORBIDDEN:${variable_name}"
  done
  require_w1_i02_probe_contract \
    "${w1_i02_postgres_image}" 18 FALSE PASS
  probe_classpath_file="${test_tmp_root}/w1-i02-database-gate-classpath.txt"
  (
    cd "${repo_root}"
    ./mvnw -q -f server/pom.xml test-compile dependency:build-classpath \
      -Dmdep.includeScope=test \
      -Dmdep.outputFile="${probe_classpath_file}"
  ) || fail "W1_I02_DATABASE_GATE_CLASSPATH_FAILED"
  probe_classpath="${repo_root}/server/target/test-classes:${repo_root}/server/target/classes:$(cat "${probe_classpath_file}")"
  probe_output="$(jshell -q --class-path "${probe_classpath}" <<'JAVA'
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.UUID;
import org.testcontainers.DockerClientFactory;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;
public final class W1I02DatabaseGateProbe {
  private static final String IMAGE =
      "postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a";
  public static void main(String[] args) throws Exception {
    String database = "cognitura_gate_" + UUID.randomUUID().toString().replace("-", "");
    String username = "gate_" + UUID.randomUUID().toString().replace("-", "");
    String password = UUID.randomUUID().toString() + UUID.randomUUID();
    String containerId;
    String imageId;
    String version;
    try (PostgreSQLContainer container = new PostgreSQLContainer(
        DockerImageName.parse(IMAGE).asCompatibleSubstituteFor("postgres"))
        .withDatabaseName(database)
        .withUsername(username)
        .withPassword(password)
        .withReuse(false)) {
      container.start();
      containerId = container.getContainerId();
      var inspect = DockerClientFactory.instance().client()
          .inspectContainerCmd(containerId).exec();
      imageId = inspect.getImageId();
      try (Connection connection = DriverManager.getConnection(
               container.getJdbcUrl(), container.getUsername(), container.getPassword());
           Statement statement = connection.createStatement();
           ResultSet result = statement.executeQuery(
               "select current_setting('server_version_num'), current_database()")) {
        if (!result.next()) throw new IllegalStateException("version query returned no row");
        version = result.getString(1);
        if (!version.startsWith("18")) {
          throw new IllegalStateException("unexpected PostgreSQL major: " + version);
        }
        if (!database.equals(result.getString(2))) {
          throw new IllegalStateException("unexpected database identity");
        }
      }
      System.out.println("W1I02DatabaseGateContainerId = " + containerId);
      System.out.println("W1I02DatabaseGateImage = " + IMAGE);
      System.out.println("W1I02DatabaseGateImageId = " + imageId);
      System.out.println("W1I02DatabaseGateServerVersionNum = " + version);
      System.out.println("W1I02DatabaseGateDatabaseName = " + database);
    }
    try {
      DockerClientFactory.instance().client().inspectContainerCmd(containerId).exec();
      throw new IllegalStateException("container remains inspectable after close");
    } catch (com.github.dockerjava.api.exception.NotFoundException expected) {
      System.out.println("W1I02DatabaseGateContainerRemoval = PASS");
    }
  }
}
W1I02DatabaseGateProbe.main(new String[0]);
JAVA
  )" || fail "W1_I02_DATABASE_GATE_PROBE_FAILED"
  [[ "${probe_output}" != *'|  Exception '* ]] ||
    fail "W1_I02_DATABASE_GATE_PROBE_FAILED"
  assert_contains "${probe_output}" "W1I02DatabaseGateContainerId = "
  assert_contains "${probe_output}" "W1I02DatabaseGateImage = ${w1_i02_postgres_image}"
  assert_contains "${probe_output}" "W1I02DatabaseGateImageId = sha256:"
  assert_contains "${probe_output}" "W1I02DatabaseGateServerVersionNum = 18"
  assert_contains "${probe_output}" "W1I02DatabaseGateDatabaseName = cognitura_gate_"
  assert_contains "${probe_output}" "W1I02DatabaseGateContainerRemoval = PASS"
  printf '%s\n' "${probe_output}"
}

append_w1_i02_database_gate_receipt() {
  local fixture_root="$1"
  local candidate_sha="$2"
  local parent_sha="$3"
  local tree_sha="$4"
  printf '%s\n' \
    '' \
    '## 12. I02 Database Gate Admission Receipt' \
    '' \
    '```text' \
    'W1-I02DatabaseGate = PASS' \
    "ReviewedGateCandidate = ${candidate_sha}" \
    "ReviewedGateParent = ${parent_sha}" \
    "ReviewedGateTree = ${tree_sha}" \
    'ReviewLevel = L3' \
    'ReviewRoute = deep_reviewer' \
    'ReviewEffort = xhigh' \
    'ReviewMultiplicity = ONE' \
    'ReviewVerdict = GO' \
    'P0Findings = 0' \
    'P1Findings = 0' \
    'P2Findings = 0' \
    'Ultra = NOT_RUN' \
    "PostgreSQLTestImage = ${w1_i02_postgres_image}" \
    'ExpectedPostgreSQLMajor = 18' \
    'IsolatedContainerLifecycle = PASS' \
    'ReleasedTaskCard = W1-I02' \
    'FormalDatabaseWrite = NOT_AUTHORIZED' \
    'RemotePush = NOT_AUTHORIZED' \
    '```' >> \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
}

make_w1_i02_database_gate_release() {
  local fixture_root="$1"
  local candidate_sha="$2"
  local parent_sha="$3"
  local tree_sha="$4"
  set_field "${fixture_root}/AGENTS.md" Wave1ImplementationTaskCardSet READY_FOR_EXECUTION
  set_field "${fixture_root}/AGENTS.md" ActiveImplementationTaskCard W1-I02
  set_field "${fixture_root}/README.md" Wave1ImplementationTaskCardSet READY_FOR_EXECUTION
  set_field "${fixture_root}/README.md" ActiveImplementationTaskCard W1-I02
  set_field "${fixture_root}/docs/design/wave-1/README.md" Wave1ImplementationTaskCardSet READY_FOR_EXECUTION
  set_field "${fixture_root}/docs/design/wave-1/README.md" ActiveImplementationGovernanceTaskCard W1-I02
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" Wave1ImplementationTaskCardSet READY_FOR_EXECUTION
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" ActiveTaskCard W1-I02
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" ActiveTaskCardStatus READY
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" ActiveImplementationTaskCard W1-I02
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" Wave1ImplementationTaskCardSet READY_FOR_EXECUTION
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" ActiveImplementationGovernanceTaskCard W1-I02
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" ImplementationTaskCardPlanStatus I02_DATABASE_GATE_PASS_I02_READY
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" Wave1ImplementationTaskCardSet READY_FOR_EXECUTION
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" ActiveImplementationGovernanceTaskCard W1-I02
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" TaskCardSetStatus READY_FOR_EXECUTION
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" ActiveTaskCard W1-I02
  set_table_status "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" W1-I02 QUEUED READY
  set_field "${fixture_root}/docs/task-cards/wave-1/README.md" Wave1ImplementationTaskCardSet READY_FOR_EXECUTION
  set_field "${fixture_root}/docs/task-cards/wave-1/README.md" ActiveImplementationGovernanceTaskCard W1-I02
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" TaskCardSetStatus READY_FOR_EXECUTION
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" ActiveTaskCard W1-I02
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" ReadyTaskCardCount 1
  set_table_status "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" W1-I02 QUEUED READY
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md" Status READY
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md" BusinessImplementationAuthorization USER_AUTHORIZED
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md" FormalDatabaseGate PASS
  append_w1_i02_database_gate_receipt "${fixture_root}" \
    "${candidate_sha}" "${parent_sha}" "${tree_sha}"
}

commit_w1_i02_database_gate_release() {
  local fixture_root="$1"
  local candidate_sha="$2"
  local parent_sha="$3"
  local tree_sha="$4"
  make_w1_i02_database_gate_release "${fixture_root}" \
    "${candidate_sha}" "${parent_sha}" "${tree_sha}"
  git -C "${fixture_root}" add "${w1_i02_release_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: release W1-I02 after database gate"
}

expect_w1_i02_database_gate_failure() {
  local fixture_root="$1"
  local expected_message="$2"
  local output
  if output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" 2>&1)"; then
    fail "invalid W1-I02 database gate fixture unexpectedly passed: ${expected_message}"
  fi
  assert_contains "${output}" "${expected_message}"
}

expect_w1_i02_database_gate_transition_failure() {
  local fixture_root="$1"
  local base_sha="$2"
  local head_sha="$3"
  local expected_message="$4"
  local output
  if output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${base_sha}" \
    --transition-head "${head_sha}" 2>&1)"; then
    fail "invalid explicit W1-I02 transition unexpectedly passed: ${expected_message}"
  fi
  assert_contains "${output}" "${expected_message}"
}

run_w1_i02_database_gate_contract() {
  local gate_test_sha gate_tip gate_parent gate_tree fixture_root release_sha output
  local positive_cases=0
  local negative_cases=0
  run_w1_i02_isolated_postgres_probe
  positive_cases=$((positive_cases + 1))

  gate_test_sha="${w1_i02_database_gate_test_sha}"
  gate_tip="${w1_i02_database_gate_tip_sha}"
  gate_parent="$(git -C "${repo_root}" rev-parse "${gate_tip}^")"
  gate_tree="$(git -C "${repo_root}" rev-parse "${gate_tip}^{tree}")"

  fixture_root="${test_tmp_root}/w1-i02-database-gate"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${gate_tip}"
  output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation")" ||
    fail "legal W1-I02 database gate governance was rejected: ${output}"
  assert_contains "${output}" "W1I02DatabaseGateStatus = PENDING_REVIEW"
  assert_contains "${output}" "TaskCardSetStatus = BLOCKED_BY_DATABASE_GATE"
  assert_contains "${output}" "ActiveTaskCard = NONE"
  positive_cases=$((positive_cases + 1))

  commit_w1_i02_database_gate_release "${fixture_root}" \
    "${gate_tip}" "${gate_parent}" "${gate_tree}"
  release_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  [[ "$(grep -c '^FormalDatabaseWrite = ' \
      "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md")" -ge 2 ]] ||
    fail "legal W1-I02 release fixture must preserve historical database authority receipts"
  [[ "$(field_value \
      "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
      FormalDatabaseWrite | sed -n '1p')" == NOT_AUTHORIZED ]] ||
    fail "legal W1-I02 release fixture current database authority must remain NOT_AUTHORIZED"
  output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${gate_tip}" \
    --transition-head "${release_sha}")" ||
    fail "legal W1-I02 database gate release transition was rejected: ${output}"
  assert_contains "${output}" "W1I02DatabaseGateStatus = PASS"
  assert_contains "${output}" "ActiveTaskCard = W1-I02"
  positive_cases=$((positive_cases + 1))
  output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation")" ||
    fail "legal static W1-I02 database gate release was rejected: ${output}"
  assert_contains "${output}" "ReadyTaskCardCount = 1"
  positive_cases=$((positive_cases + 1))

  if output="$(SPRING_DATASOURCE_URL='jdbc:postgresql://127.0.0.1:5432/forbidden' \
    bash "${repo_root}/tests/task-cards/verify-wave1-implementation-cards.sh" \
      --w1-i02-database-gate-contract-only 2>&1)"; then
    fail "host database input unexpectedly passed the W1-I02 database gate"
  fi
  assert_contains "${output}" "W1_I02_DATABASE_GATE_HOST_DB_INPUT_FORBIDDEN"
  negative_cases=$((negative_cases + 1))

  if output="$(
    require_w1_i02_probe_contract \
      'postgres:18.4' 18 FALSE PASS 2>&1
  )"; then
    fail "mutable PostgreSQL image unexpectedly passed the W1-I02 database gate"
  fi
  assert_contains "${output}" "W1_I02_DATABASE_GATE_IMAGE_MISMATCH"
  negative_cases=$((negative_cases + 1))

  if output="$(
    require_w1_i02_probe_contract \
      "${w1_i02_postgres_image}" 18 FALSE MISSING 2>&1
  )"; then
    fail "missing container removal proof unexpectedly passed the W1-I02 database gate"
  fi
  assert_contains "${output}" "W1_I02_DATABASE_GATE_REMOVAL_REQUIRED"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${gate_tip}"
  make_w1_i02_database_gate_release "${fixture_root}" \
    "${gate_tip}" "${gate_parent}" "${gate_tree}"
  sed -i.bak "s/ReviewedGateCandidate = ${gate_tip}/ReviewedGateCandidate = 0000000000000000000000000000000000000000/" \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${w1_i02_release_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: bind wrong database gate candidate"
  expect_w1_i02_database_gate_failure "${fixture_root}" \
    "W1_I02_DATABASE_GATE_REVIEW_IDENTITY_MISMATCH"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${gate_tip}"
  make_w1_i02_database_gate_release "${fixture_root}" \
    "${gate_tip}" "${gate_parent}" "${gate_tree}"
  sed -i.bak 's/^P0Findings = 0$/P0Findings = 1/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${w1_i02_release_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: admit a nonzero database gate finding"
  expect_w1_i02_database_gate_failure "${fixture_root}" \
    "W1_I02_DATABASE_GATE_REVIEW_RECEIPT_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${gate_tip}"
  make_w1_i02_database_gate_release "${fixture_root}" \
    "${gate_tip}" "${gate_parent}" "${gate_tree}"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md" FormalDatabaseGate REQUIRED_BEFORE_READY
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md" BusinessImplementationAuthorization REQUIRED_BEFORE_READY
  git -C "${fixture_root}" add "${w1_i02_release_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: release I02 without database gate pass"
  expect_w1_i02_database_gate_failure "${fixture_root}" \
    "I02_READY_REQUIRES_DATABASE_GATE"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${gate_tip}"
  make_w1_i02_database_gate_release "${fixture_root}" \
    "${gate_tip}" "${gate_parent}" "${gate_tree}"
  set_table_status "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I07 BLOCKED_BY_DEPENDENCY READY
  git -C "${fixture_root}" add "${w1_i02_release_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: release I07 with I02"
  expect_w1_i02_database_gate_failure "${fixture_root}" \
    "W1_I02_DATABASE_GATE_RELEASE_SCOPE_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${gate_tip}"
  make_w1_i02_database_gate_release "${fixture_root}" \
    "${gate_tip}" "${gate_parent}" "${gate_tree}"
  sed -i.bak \
    '1,/^FormalDatabaseWrite = / s/^FormalDatabaseWrite = .*$/FormalDatabaseWrite = NOT_AUTHORIZED\
FormalDatabaseWrite = AUTHORIZED/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${w1_i02_release_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: mask current formal database authority drift"
  expect_w1_i02_database_gate_transition_failure "${fixture_root}" \
    "${gate_tip}" "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "W1_I02_DATABASE_GATE_AUTHORIZATION_DRIFT"
  expect_w1_i02_database_gate_failure "${fixture_root}" \
    "W1_I02_DATABASE_GATE_AUTHORIZATION_DRIFT"

  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${gate_tip}"
  make_w1_i02_database_gate_release "${fixture_root}" \
    "${gate_tip}" "${gate_parent}" "${gate_tree}"
  mkdir -p "${fixture_root}/server/src/main/java/io/cognitura/source/persistence"
  printf '%s\n' 'package io.cognitura.source.persistence;' > \
    "${fixture_root}/server/src/main/java/io/cognitura/source/persistence/SourceDocumentRow.java"
  git -C "${fixture_root}" add "${w1_i02_release_projection_paths[@]}" \
    server/src/main/java/io/cognitura/source/persistence/SourceDocumentRow.java
  git -C "${fixture_root}" commit -qm "test: mix I02 product into database gate release"
  expect_w1_i02_database_gate_failure "${fixture_root}" \
    "W1_I02_DATABASE_GATE_RELEASE_PROJECTION_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${gate_tip}"
  commit_w1_i02_database_gate_release "${fixture_root}" \
    "${gate_tip}" "${gate_parent}" "${gate_tree}"
  release_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  git -C "${fixture_root}" switch -q --detach "${gate_tip}"
  mkdir -p "${fixture_root}/server/src/main/java/io/cognitura/source/persistence"
  printf '%s\n' 'package io.cognitura.source.persistence;' > \
    "${fixture_root}/server/src/main/java/io/cognitura/source/persistence/SourceDocumentRow.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/persistence/SourceDocumentRow.java
  git -C "${fixture_root}" commit -qm "test: create a queued fork after database gate"
  expect_w1_i02_database_gate_transition_failure "${fixture_root}" \
    "$(git -C "${fixture_root}" rev-parse HEAD)" "${release_sha}" \
    "W1_I02_DATABASE_GATE_CHAIN_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${gate_tip}"
  make_w1_i02_database_gate_release "${fixture_root}" \
    "${gate_tip}" "${gate_parent}" "${gate_tree}"
  set_field "${fixture_root}/AGENTS.md" Wave1ImplementationTaskCardSet BLOCKED_BY_DATABASE_GATE
  set_field "${fixture_root}/AGENTS.md" ActiveImplementationTaskCard NONE
  printf '%s\n' '' 'W1I02SplitProjectionFixture = TRUE' >> \
    "${fixture_root}/AGENTS.md"
  git -C "${fixture_root}" add "${w1_i02_release_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: split I02 release authority projection"
  expect_w1_i02_database_gate_transition_failure "${fixture_root}" \
    "${gate_tip}" "$(git -C "${fixture_root}" rev-parse HEAD)" \
    "W1_I02_DATABASE_GATE_RELEASE_PROJECTION_INVALID"
  expect_w1_i02_database_gate_failure "${fixture_root}" \
    "W1_I02_DATABASE_GATE_RELEASE_PROJECTION_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${gate_tip}"
  git -C "${fixture_root}" switch -q -c w1-i02-merge-left
  printf '%s\n' left > "${fixture_root}/w1-i02-merge-left.txt"
  git -C "${fixture_root}" add w1-i02-merge-left.txt
  git -C "${fixture_root}" commit -qm "test: create database gate merge left"
  git -C "${fixture_root}" switch -q --detach "${gate_tip}"
  git -C "${fixture_root}" switch -q -c w1-i02-merge-right
  printf '%s\n' right > "${fixture_root}/w1-i02-merge-right.txt"
  git -C "${fixture_root}" add w1-i02-merge-right.txt
  git -C "${fixture_root}" commit -qm "test: create database gate merge right"
  git -C "${fixture_root}" merge -q --no-ff w1-i02-merge-left \
    -m "test: merge invalid database gate governance"
  expect_w1_i02_database_gate_failure "${fixture_root}" \
    "W1_I02_DATABASE_GATE_CHAIN_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${release_sha}"
  printf '%s\n' outside > "${fixture_root}/outside-i02-write-set.txt"
  git -C "${fixture_root}" add outside-i02-write-set.txt
  git -C "${fixture_root}" commit -qm "test: change outside I02 WriteSet"
  expect_w1_i02_database_gate_failure "${fixture_root}" \
    "W1_I02_DATABASE_GATE_DESCENDANT_OUTSIDE_WRITE_SET"
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 4 ]] ||
    fail "W1-I02 database gate positive case count mismatch: ${positive_cases}"
  [[ "${negative_cases}" -eq 13 ]] ||
    fail "W1-I02 database gate negative case count mismatch: ${negative_cases}"
  printf '%s\n' \
    "W1I02DatabaseGateContractTests = PASS" \
    "W1I02DatabaseGatePositiveCases = ${positive_cases}" \
    "W1I02DatabaseGateNegativeCases = ${negative_cases}"
}

i02_reviewed_candidate_sha="59144c9dfca4abacce62de41c7306021bf5b83f8"
i02_reviewed_parent_sha="525e75efe99ad91419c4d455c04bf3744abc7490"
i02_reviewed_tree_sha="592a1b5d427f61e24e7687a532ca8562070c0a8f"
i02_closure_base_sha="f8ff463a45d2801b2833ec769f0a09390240e541"
i02_closure_projection_paths=(
  AGENTS.md
  README.md
  docs/design/wave-1/README.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-plan.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1/README.md
  docs/task-cards/wave-1-implementation/README.md
  docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md
  docs/task-cards/wave-1-implementation/W1-I07-revision-attempt-fencing-publication.md
)
i02_closure_commit_paths=(
  "${i02_closure_projection_paths[@]}"
  scripts/verify-wave1-implementation-cards
  tests/task-cards/verify-wave1-implementation-cards.sh
)

append_i02_closure_receipt() {
  local fixture_root="$1"
  printf '%s\n' \
    '' \
    '## 13. I02 关闭收据' \
    '' \
    '```text' \
    'W1-I02 = DONE' \
    "ReviewedCandidate = ${i02_reviewed_candidate_sha}" \
    "ReviewedParent = ${i02_reviewed_parent_sha}" \
    "ReviewedTree = ${i02_reviewed_tree_sha}" \
    'ReviewLevel = L3' \
    'ReviewRoute = deep_reviewer' \
    'ReviewEffort = xhigh' \
    'ReviewMultiplicity = ONE' \
    'ReviewVerdict = GO' \
    'P0 = 0' \
    'P1 = 0' \
    'P2 = 0' \
    'Ultra = NOT_RUN' \
    'I02ClosureReleasedTaskCard = W1-I07' \
    'FormalDatabaseWrite = NOT_AUTHORIZED' \
    'RemotePush = NOT_AUTHORIZED' \
    '```' >> \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
}

make_i02_closure_projection() {
  local fixture_root="$1"
  set_field "${fixture_root}/AGENTS.md" ActiveImplementationTaskCard W1-I07
  set_field "${fixture_root}/README.md" ActiveImplementationTaskCard W1-I07
  set_field "${fixture_root}/docs/design/wave-1/README.md" \
    ActiveImplementationGovernanceTaskCard W1-I07
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    ActiveTaskCard W1-I07
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    ActiveTaskCardStatus READY
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    ActiveImplementationTaskCard W1-I07
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    ActiveImplementationGovernanceTaskCard W1-I07
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    ImplementationTaskCardPlanStatus I02_DONE_I07_READY
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    ActiveImplementationGovernanceTaskCard W1-I07
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    ActiveTaskCard W1-I07
  set_table_status \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    W1-I02 READY DONE
  set_table_status \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    W1-I07 BLOCKED_BY_DEPENDENCY READY
  set_field "${fixture_root}/docs/task-cards/wave-1/README.md" \
    ActiveImplementationGovernanceTaskCard W1-I07
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    ActiveTaskCard W1-I07
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I02 READY DONE
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I07 BLOCKED_BY_DEPENDENCY READY
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md" \
    Status DONE
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I07-revision-attempt-fencing-publication.md" \
    Status READY
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I07-revision-attempt-fencing-publication.md" \
    BusinessImplementationAuthorization USER_AUTHORIZED

  replace_i03_closure_text "${fixture_root}/AGENTS.md" \
    '`W1-I03`、`W1-I04`、`W1-I05`、`W1-I06` 已零发现关闭；`W1-I02` 的独立数据库 Gate 已通过并成为唯一 `READY` 卡，`W1-I07` 仍未释放。' \
    '`W1-I02` 已完成固定候选零发现深审并关闭；`W1-I07` 已作为唯一 `READY` 卡释放。' \
    'I02 closure AGENTS primary narrative'
  replace_i03_closure_text "${fixture_root}/AGENTS.md" \
    'I00、I01、I03、I04、I05 和 I06 已关闭；I02 为唯一 `READY` 卡，I07 未释放。' \
    'I00、I01、I02、I03、I04、I05 和 I06 已关闭；I07 为唯一 `READY` 卡。' \
    'I02 closure AGENTS secondary narrative'
  replace_i03_closure_text "${fixture_root}/README.md" \
    '完成零发现深审并关闭；I02 的独立数据库 Gate 已通过并成为唯一 `READY` 卡，I07 仍未释放。' \
    '完成零发现深审并关闭；I02 已关闭，I07 已释放为唯一 `READY` 卡。' \
    'I02 closure README primary narrative'
  replace_i03_closure_text "${fixture_root}/README.md" \
    '的独立数据库 Gate 已通过并成为唯一 `READY` 卡；`W1-I03`、`W1-I04`、`W1-I05`、`W1-I06` 已关闭，`W1-I07` 仍未释放。' \
    '已完成固定候选零发现深审并关闭；`W1-I03`、`W1-I04`、`W1-I05`、`W1-I06` 已关闭，`W1-I07` 为唯一 `READY` 卡。' \
    'I02 closure README secondary narrative'
  replace_i03_closure_text "${fixture_root}/docs/design/wave-1/README.md" \
    '  I01、I03、I04、I05 和 I06 已关闭，I02 的独立数据库 Gate 已通过并成为唯一 `READY` 卡，I07 仍未释放。' \
    '  I01、I02、I03、I04、I05 和 I06 已关闭，I07 已释放为唯一 `READY` 卡。' \
    'I02 closure design README narrative'
  replace_i03_closure_text "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    $'现有卡集。`W1-I01` 已完成固定候选零发现深审并关闭，I02 的独立数据库 Gate 已通过\n并成为唯一 `READY` 卡，`W1-I05` 和 `W1-I06` 已零发现关闭；`W1-I07` 仍未释放。' \
    $'现有卡集。`W1-I01`、`W1-I02`、`W1-I05` 和 `W1-I06` 已完成固定候选零发现深审并关闭；\n`W1-I07` 已释放为唯一 `READY` 卡。' \
    'I02 closure design index narrative'
  replace_i03_closure_text "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    '固定候选深审并关闭；I02 的独立数据库 Gate 已通过并成为唯一 `READY` 卡，I03、I04、I05 和 I06 已关闭，I07 仍未释放，完整证据记录在' \
    '固定候选深审并关闭；I02、I03、I04、I05 和 I06 已关闭，I07 已释放为唯一 `READY` 卡，完整证据记录在' \
    'I02 closure design plan narrative'
  replace_i03_closure_text "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    $'数据库 Gate 已通过并成为唯一 `READY` 卡；I03、I04、I05 和 I06 已关闭，I07 仍未释放。正式数据库、Parser/Object Storage Provider、' \
    $'数据库 Gate 和固定候选深审均已通过，I02、I03、I04、I05 和 I06 已关闭；I07 为唯一 `READY` 卡。正式数据库、Parser/Object Storage Provider、' \
    'I02 closure design acceptance narrative'
  replace_i03_closure_text "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    $'非业务治理卡 I00 和来源领域卡 I01 已关闭；I02 的独立数据库 Gate 已\n通过并成为唯一 `READY` 卡，I03、I04、I05 和 I06 已关闭；I07 仍未释放。' \
    $'非业务治理卡 I00 和来源领域卡 I01 已关闭；I02、I03、I04、I05 和 I06 已完成固定候选\n零发现深审并关闭；I07 已释放为唯一 `READY` 卡。' \
    'I02 closure implementation plan narrative'
  replace_i03_closure_text "${fixture_root}/docs/task-cards/wave-1/README.md" \
    'I00、I01、I03、I04、I05 和 I06 已关闭；I02 的独立数据库 Gate 已通过并成为唯一 `READY` 业务卡，I07 仍未释放。' \
    'I00、I01、I02、I03、I04、I05 和 I06 已关闭；I07 已释放为唯一 `READY` 业务卡。' \
    'I02 closure Wave 1 README narrative'
  replace_i03_closure_text "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    '完成零发现深审并关闭；I02 的独立数据库 Gate 已通过并成为唯一 `READY` 卡，I03、I04、I05 和 I06 已关闭，I07 仍未释放。' \
    '完成零发现深审并关闭；I02、I03、I04、I05 和 I06 已关闭，I07 已释放为唯一 `READY` 卡。' \
    'I02 closure implementation index narrative'
  append_i02_closure_receipt "${fixture_root}"
}

prepare_i02_closure_projection() {
  local fixture_root="$1"
  make_i02_closure_projection "${fixture_root}"
  cp -p "${repo_root}/scripts/verify-wave1-implementation-cards" \
    "${fixture_root}/scripts/verify-wave1-implementation-cards"
  cp -p "${repo_root}/tests/task-cards/verify-wave1-implementation-cards.sh" \
    "${fixture_root}/tests/task-cards/verify-wave1-implementation-cards.sh"
}

commit_i02_closure_projection() {
  local fixture_root="$1"
  prepare_i02_closure_projection "${fixture_root}"
  git -C "${fixture_root}" add "${i02_closure_commit_paths[@]}"
  git -C "${fixture_root}" commit -qm "docs: close W1-I02 and release W1-I07"
}

run_i02_closure_verifier() {
  local fixture_root="$1"
  shift
  "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" \
    "$@"
}

expect_i02_closure_failure() {
  local fixture_root="$1"
  local expected_message="$2"
  local output
  if output="$(run_i02_closure_verifier "${fixture_root}" 2>&1)"; then
    fail "invalid I02 closure unexpectedly passed: ${expected_message}"
  fi
  assert_contains "${output}" "${expected_message}"
}

run_w1_i02_closure_contract() {
  local fixture_root closure_sha output
  local positive_cases=0
  local negative_cases=0
  fixture_root="${test_tmp_root}/w1-i02-closure"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${i02_closure_base_sha}"

  commit_i02_closure_projection "${fixture_root}"
  closure_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  output="$(run_i02_closure_verifier "${fixture_root}" \
    --transition-base "${i02_closure_base_sha}" \
    --transition-head "${closure_sha}")" ||
    fail "legal explicit I02 closure was rejected: ${output}"
  assert_contains "${output}" "W1I02ClosureStatus = PASS"
  assert_contains "${output}" "ActiveTaskCard = W1-I07"
  positive_cases=$((positive_cases + 1))

  output="$(run_i02_closure_verifier "${fixture_root}")" ||
    fail "legal static I02 closure was rejected: ${output}"
  assert_contains "${output}" "W1I02ClosureStatus = PASS"
  assert_contains "${output}" "ReadyTaskCardCount = 1"
  positive_cases=$((positive_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${i02_closure_base_sha}"
  prepare_i02_closure_projection "${fixture_root}"
  sed -i.bak "s/${i02_reviewed_candidate_sha}/0000000000000000000000000000000000000000/" \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i02_closure_commit_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: drift I02 review receipt"
  expect_i02_closure_failure "${fixture_root}" "I02 closure review receipt mismatch"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${i02_closure_base_sha}"
  prepare_i02_closure_projection "${fixture_root}"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I07-revision-attempt-fencing-publication.md" \
    BusinessImplementationAuthorization REQUIRED_BEFORE_READY
  git -C "${fixture_root}" add "${i02_closure_commit_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: revoke I07 authorization"
  expect_i02_closure_failure "${fixture_root}" \
    "W1-I07 requires explicit business implementation authorization"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${i02_closure_base_sha}"
  prepare_i02_closure_projection "${fixture_root}"
  printf '%s\n' extra > "${fixture_root}/i02-closure-extra.txt"
  git -C "${fixture_root}" add "${i02_closure_commit_paths[@]}" i02-closure-extra.txt
  git -C "${fixture_root}" commit -qm "test: expand I02 closure scope"
  expect_i02_closure_failure "${fixture_root}" \
    "I02 closure fixed diff must equal the exact thirteen paths"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${i02_closure_base_sha}"
  prepare_i02_closure_projection "${fixture_root}"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    FormalDatabaseWrite AUTHORIZED
  git -C "${fixture_root}" add "${i02_closure_commit_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: authorize formal database write"
  expect_i02_closure_failure "${fixture_root}" \
    "I02 closure must preserve database and push authorization boundaries"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${i02_closure_base_sha}"
  prepare_i02_closure_projection "${fixture_root}"
  printf '%s\n' 'nonterminal receipt drift' >> \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  git -C "${fixture_root}" add "${i02_closure_commit_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: make I02 receipt nonterminal"
  expect_i02_closure_failure "${fixture_root}" "I02 closure review receipt mismatch"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  printf '%s\n' outside > "${fixture_root}/outside-i07-write-set.txt"
  git -C "${fixture_root}" add outside-i07-write-set.txt
  git -C "${fixture_root}" commit -qm "test: change outside I07 WriteSet"
  expect_i02_closure_failure "${fixture_root}" \
    "post-I02-closure descendant changed a path outside the W1-I07 WriteSet"
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 2 ]] ||
    fail "I02 closure positive case count mismatch: ${positive_cases}"
  [[ "${negative_cases}" -eq 6 ]] ||
    fail "I02 closure negative case count mismatch: ${negative_cases}"
  printf '%s\n' \
    "W1I02ClosureContractTests = PASS" \
    "W1I02ClosurePositiveCases = ${positive_cases}" \
    "W1I02ClosureNegativeCases = ${negative_cases}"
}

i07_closure_origin_sha="094f62546cf7a13435c5d61f2a7bede21b86f099"
i07_closure_spec_sha="42b4826f34e5dedf152d2f45f54522c19321757b"
i07_closure_plan_sha="65c62ec2a7b5dbc881d5b874af0d264112c25f96"
i07_closure_original_test_sha="bc2bdac50b1118e457af431e51c6d2e1dcaeb3ff"
i07_closure_count_repair_sha="34bbef63efdcc4b2b83bfde91594705ddac0bd60"
i07_closure_count_corrected_test_sha="ef4393de4464a74971f889fa20cdbf370991209d"
i07_closure_first_green_sha="e0b7c302011b4a84f04ebdd7f88393af76d3d973"
i07_closure_legacy_gate_repair_sha="762dbf3c10b2d68eb5fe07b90e381a4e00e075e8"
i07_closure_legacy_gate_test_sha="463d5fb90d0c0f7859debebf5423dccba1381e75"
i07_closure_legacy_gate_green_sha="a1312b46d42b53ac8bcaa9b38774a123932274b6"
i07_closure_review_repair_sha="90d0620029dc291a79ec2ecced1e34f82c098f22"
i07_closure_review_matrix_test_sha="d1b54a1aabc4982aeefd2749e5e85270947e4eb4"
i07_closure_staging_repair_sha="b56b3abeedc60f9fd7a88e50bf6505cf6d8eb74e"
i07_closure_staging_count_sha="c0f273b72d4011bfa28a979d297514e70c6247f7"
i07_closure_staging_test_sha="b5a3e97c12b3103da2921cfde08d97aca3eaa0d9"
i07_closure_review_green_sha="d59f444ad2d874d8d9dc10c3ade332c8da4ba0ae"
i07_closure_oracle_repair_sha="32523b87d516654f439abf0dd702cbd279e1ddfe"
i07_closure_oracle_test_sha="28698e70bb0c0d2af674fd98c0964abe77c2e17c"
i07_closure_oracle_source_repair_sha="1bbdcdefabea8102becceb9bd2a1706a09fd7f5c"
i07_closure_oracle_source_count_sha="e387582ae380643d82cdd74a56d4490940608f21"
i07_reviewed_candidate_sha="094f62546cf7a13435c5d61f2a7bede21b86f099"
i07_reviewed_parent_sha="5433485e8f88f3846cbda722282223a3c8274b14"
i07_reviewed_tree_sha="d82ece96e0e3dabdfef64a766179b711ea6d557f"
i07_closure_projection_paths=(
  AGENTS.md
  README.md
  docs/design/wave-1/README.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-plan.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1/README.md
  docs/task-cards/wave-1-implementation/README.md
  docs/task-cards/wave-1-implementation/W1-I07-revision-attempt-fencing-publication.md
  docs/task-cards/wave-1-implementation/W1-I08-stable-reference-reparse-lineage.md
  docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md
)
i07_governance_fixture_paths=(
  docs/superpowers/specs/2026-08-21-cognitura-w1-i07-closure-design.md
  docs/superpowers/plans/2026-08-21-cognitura-w1-i07-closure.md
  tests/task-cards/verify-wave1-implementation-cards.sh
  docs/superpowers/specs/2026-08-21-cognitura-w1-i07-closure-contract-count-repair.md
  tests/task-cards/verify-wave1-implementation-cards.sh
  scripts/verify-wave1-implementation-cards
  docs/superpowers/specs/2026-08-21-cognitura-w1-i07-closure-legacy-gate-fixture-repair.md
  tests/task-cards/verify-wave1-implementation-cards.sh
  scripts/verify-wave1-implementation-cards
  docs/superpowers/specs/2026-08-21-cognitura-w1-i07-closure-review-finding-repair.md
  tests/task-cards/verify-wave1-implementation-cards.sh
  docs/superpowers/specs/2026-08-21-cognitura-w1-i07-closure-review-fixture-staging-repair.md
  docs/superpowers/specs/2026-08-21-cognitura-w1-i07-closure-staging-chain-count-clarification.md
  tests/task-cards/verify-wave1-implementation-cards.sh
  scripts/verify-wave1-implementation-cards
  docs/superpowers/specs/2026-08-22-cognitura-w1-i07-closure-governance-oracle-repair.md
  tests/task-cards/verify-wave1-implementation-cards.sh
  docs/superpowers/specs/2026-08-22-cognitura-w1-i07-closure-oracle-source-path-repair.md
  docs/superpowers/specs/2026-08-22-cognitura-w1-i07-oracle-source-chain-count-clarification.md
  tests/task-cards/verify-wave1-implementation-cards.sh
  scripts/verify-wave1-implementation-cards
)
i07_governance_fixture_sources=(
  "${i07_closure_spec_sha}"
  "${i07_closure_plan_sha}"
  "${i07_closure_original_test_sha}"
  "${i07_closure_count_repair_sha}"
  "${i07_closure_count_corrected_test_sha}"
  "${i07_closure_first_green_sha}"
  "${i07_closure_legacy_gate_repair_sha}"
  "${i07_closure_legacy_gate_test_sha}"
  "${i07_closure_legacy_gate_green_sha}"
  "${i07_closure_review_repair_sha}"
  "${i07_closure_review_matrix_test_sha}"
  "${i07_closure_staging_repair_sha}"
  "${i07_closure_staging_count_sha}"
  "${i07_closure_staging_test_sha}"
  "${i07_closure_review_green_sha}"
  "${i07_closure_oracle_repair_sha}"
  "${i07_closure_oracle_test_sha}"
  "${i07_closure_oracle_source_repair_sha}"
  "${i07_closure_oracle_source_count_sha}"
  WORKTREE_TEST
  WORKTREE_VERIFIER
)

new_w1_i07_closure_fixture() {
  local fixture_root="$1"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${i07_closure_origin_sha}"
}

commit_w1_i07_governance_path() {
  local fixture_root="$1"
  local source_sha="$2"
  local path="$3"
  local message="$4"
  mkdir -p "${fixture_root}/$(dirname "${path}")"
  git -C "${repo_root}" show "${source_sha}:${path}" > "${fixture_root}/${path}" ||
    fail "could not materialize I07 governance path: ${path}"
  git -C "${fixture_root}" add "${path}"
  git -C "${fixture_root}" commit -qm "${message}"
}

materialize_w1_i07_governance_tip() {
  materialize_w1_i07_governance_variant "$1" NONE
}

materialize_w1_i07_governance_variant() {
  local fixture_root="$1"
  local mutation="$2"
  local test_path="tests/task-cards/verify-wave1-implementation-cards.sh"
  local verifier_path="scripts/verify-wave1-implementation-cards"
  local index fixture_path source_sha source_path
  for index in "${!i07_governance_fixture_paths[@]}"; do
    fixture_path="${i07_governance_fixture_paths[${index}]}"
    source_sha="${i07_governance_fixture_sources[${index}]}"
    if [[ "${mutation}" == WRONG_ORDER && "${index}" -eq 0 ]]; then
      fixture_path="${i07_governance_fixture_paths[1]}"
      source_sha="${i07_governance_fixture_sources[1]}"
    elif [[ "${mutation}" == WRONG_ORDER && "${index}" -eq 1 ]]; then
      fixture_path="${i07_governance_fixture_paths[0]}"
      source_sha="${i07_governance_fixture_sources[0]}"
    fi
    if [[ "${mutation}" == REPEATED_PATH && "${index}" -eq 1 ]]; then
      printf '%s\n' repeated >> \
        "${fixture_root}/${i07_governance_fixture_paths[0]}"
      git -C "${fixture_root}" add "${i07_governance_fixture_paths[0]}"
      git -C "${fixture_root}" commit -qm "test: repeat I07 governance path"
      continue
    fi
    if [[ "${mutation}" == EMPTY_COMMIT && "${index}" -eq 1 ]]; then
      git -C "${fixture_root}" commit -q --allow-empty -m \
        "test: add empty I07 governance commit"
      continue
    fi
    if [[ "${mutation}" == RENAME && "${index}" -eq 1 ]]; then
      git -C "${fixture_root}" mv "${i07_governance_fixture_paths[0]}" \
        "${i07_governance_fixture_paths[1]}"
      git -C "${fixture_root}" commit -qm "test: rename I07 governance evidence"
      continue
    fi
    if [[ "${mutation}" == COPY && "${index}" -eq 1 ]]; then
      cp -p "${fixture_root}/${i07_governance_fixture_paths[0]}" \
        "${fixture_root}/${i07_governance_fixture_paths[1]}"
      git -C "${fixture_root}" add "${i07_governance_fixture_paths[1]}"
      git -C "${fixture_root}" commit -qm "test: copy I07 governance evidence"
      continue
    fi
    mkdir -p "${fixture_root}/$(dirname "${fixture_path}")"
    case "${source_sha}" in
      WORKTREE_TEST)
        cp -p "${repo_root}/${test_path}" "${fixture_root}/${fixture_path}"
        ;;
      WORKTREE_VERIFIER)
        cp -p "${repo_root}/${verifier_path}" "${fixture_root}/${fixture_path}"
        printf '%s\n' '# W1-I07 closure verifier fixture' >> \
          "${fixture_root}/${fixture_path}"
        ;;
      *)
        source_path="${fixture_path}"
        git -C "${repo_root}" show "${source_sha}:${source_path}" > \
          "${fixture_root}/${fixture_path}" ||
          fail "could not materialize I07 governance path: ${fixture_path}"
        ;;
    esac
    case "${fixture_path}" in
      tests/*|scripts/*) chmod 755 "${fixture_root}/${fixture_path}" ;;
    esac
    if [[ "${mutation}" == MODE && "${index}" -eq 0 ]]; then
      chmod 755 "${fixture_root}/${fixture_path}"
    elif [[ "${mutation}" == NUL && "${index}" -eq 0 ]]; then
      printf '\0' >> "${fixture_root}/${fixture_path}"
    fi
    git -C "${fixture_root}" add "${fixture_path}"
    if [[ "${mutation}" == PROJECTION_DRIFT && "${index}" -eq 1 ]]; then
      set_field "${fixture_root}/AGENTS.md" ActiveImplementationTaskCard W1-I08
      git -C "${fixture_root}" add AGENTS.md
    fi
    git -C "${fixture_root}" commit -qm \
      "test: materialize I07 governance step ${index}"
  done
}

append_w1_i07_review_receipt() {
  local fixture_root="$1"
  local governance_tip="$2"
  local governance_parent governance_tree
  governance_parent="$(git -C "${fixture_root}" rev-parse "${governance_tip}^")"
  governance_tree="$(git -C "${fixture_root}" rev-parse "${governance_tip}^{tree}")"
  printf '%s\n' \
    '' \
    '## 14. I07 关闭收据' \
    '' \
    '```text' \
    'W1-I07 = DONE' \
    "ReviewedCandidate = ${i07_reviewed_candidate_sha}" \
    "ReviewedParent = ${i07_reviewed_parent_sha}" \
    "ReviewedTree = ${i07_reviewed_tree_sha}" \
    "ReviewedGovernanceCandidate = ${governance_tip}" \
    "ReviewedGovernanceParent = ${governance_parent}" \
    "ReviewedGovernanceTree = ${governance_tree}" \
    'ReviewLevel = L3' \
    'ReviewRoute = deep_reviewer' \
    'ReviewEffort = xhigh' \
    'ReviewMultiplicity = ONE' \
    'ReviewVerdict = GO' \
    'P0 = 0' \
    'P1 = 0' \
    'P2 = 0' \
    'Ultra = NOT_RUN' \
    'I07ClosureReleasedTaskCard = W1-I08' \
    'QueuedTaskCard = W1-I09' \
    'QueuedReason = SERIAL_EXECUTION_ORDER' \
    'FormalDatabaseWrite = NOT_AUTHORIZED' \
    'RemotePush = NOT_AUTHORIZED' \
    '```' >> \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
}

make_w1_i07_closure_projection() {
  local fixture_root="$1"
  local governance_tip="$2"
  set_field "${fixture_root}/AGENTS.md" ActiveImplementationTaskCard W1-I08
  set_field "${fixture_root}/README.md" ActiveImplementationTaskCard W1-I08
  set_field "${fixture_root}/docs/design/wave-1/README.md" \
    ActiveImplementationGovernanceTaskCard W1-I08
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    ActiveTaskCard W1-I08
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    ActiveTaskCardStatus READY
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    ActiveImplementationTaskCard W1-I08
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    ActiveImplementationGovernanceTaskCard W1-I08
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    ImplementationTaskCardPlanStatus I07_DONE_I08_READY_I09_QUEUED
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    ActiveImplementationGovernanceTaskCard W1-I08
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    ActiveTaskCard W1-I08
  set_table_status \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    W1-I07 READY DONE
  set_table_status \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    W1-I08 BLOCKED_BY_DEPENDENCY READY
  set_table_status \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    W1-I09 BLOCKED_BY_DEPENDENCY QUEUED
  set_field "${fixture_root}/docs/task-cards/wave-1/README.md" \
    ActiveImplementationGovernanceTaskCard W1-I08
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    ActiveTaskCard W1-I08
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I07 READY DONE
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I08 BLOCKED_BY_DEPENDENCY READY
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I09 BLOCKED_BY_DEPENDENCY QUEUED
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I07-revision-attempt-fencing-publication.md" \
    Status DONE
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I08-stable-reference-reparse-lineage.md" \
    Status READY
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I08-stable-reference-reparse-lineage.md" \
    BusinessImplementationAuthorization USER_AUTHORIZED
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md" \
    Status QUEUED

  replace_i03_closure_text "${fixture_root}/AGENTS.md" \
    '`W1-I02` 已完成固定候选零发现深审并关闭；`W1-I07` 已作为唯一 `READY` 卡释放。' \
    '`W1-I02` 和 `W1-I07` 已完成固定候选零发现深审并关闭；`W1-I08` 已作为唯一 `READY` 卡释放，`W1-I09` 保持 `QUEUED`。' \
    'I07 closure AGENTS primary narrative'
  replace_i03_closure_text "${fixture_root}/AGENTS.md" \
    'I00、I01、I02、I03、I04、I05 和 I06 已关闭；I07 为唯一 `READY` 卡。' \
    'I00、I01、I02、I03、I04、I05、I06 和 I07 已关闭；I08 为唯一 `READY` 卡，I09 保持 `QUEUED`。' \
    'I07 closure AGENTS secondary narrative'
  replace_i03_closure_text "${fixture_root}/README.md" \
    '完成零发现深审并关闭；I02 已关闭，I07 已释放为唯一 `READY` 卡。' \
    '完成零发现深审并关闭；I02 和 I07 已关闭，I08 已释放为唯一 `READY` 卡，I09 保持 `QUEUED`。' \
    'I07 closure README primary narrative'
  replace_i03_closure_text "${fixture_root}/README.md" \
    '已完成固定候选零发现深审并关闭；`W1-I03`、`W1-I04`、`W1-I05`、`W1-I06` 已关闭，`W1-I07` 为唯一 `READY` 卡。' \
    '已完成固定候选零发现深审并关闭；`W1-I03`、`W1-I04`、`W1-I05`、`W1-I06`、`W1-I07` 已关闭，`W1-I08` 为唯一 `READY` 卡，`W1-I09` 保持 `QUEUED`。' \
    'I07 closure README secondary narrative'
  replace_i03_closure_text "${fixture_root}/docs/design/wave-1/README.md" \
    '  I01、I02、I03、I04、I05 和 I06 已关闭，I07 已释放为唯一 `READY` 卡。' \
    '  I01、I02、I03、I04、I05、I06 和 I07 已关闭，I08 已释放为唯一 `READY` 卡，I09 保持 `QUEUED`。' \
    'I07 closure design README narrative'
  replace_i03_closure_text "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    $'现有卡集。`W1-I01`、`W1-I02`、`W1-I05` 和 `W1-I06` 已完成固定候选零发现深审并关闭；\n`W1-I07` 已释放为唯一 `READY` 卡。' \
    $'现有卡集。`W1-I01`、`W1-I02`、`W1-I05`、`W1-I06` 和 `W1-I07` 已完成固定候选零发现深审并关闭；\n`W1-I08` 已释放为唯一 `READY` 卡，`W1-I09` 保持 `QUEUED`。' \
    'I07 closure design index narrative'
  replace_i03_closure_text "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    '固定候选深审并关闭；I02、I03、I04、I05 和 I06 已关闭，I07 已释放为唯一 `READY` 卡，完整证据记录在' \
    '固定候选深审并关闭；I02、I03、I04、I05、I06 和 I07 已关闭，I08 已释放为唯一 `READY` 卡，I09 保持 `QUEUED`，完整证据记录在' \
    'I07 closure design plan narrative'
  replace_i03_closure_text "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    '数据库 Gate 和固定候选深审均已通过，I02、I03、I04、I05 和 I06 已关闭；I07 为唯一 `READY` 卡。正式数据库、Parser/Object Storage Provider、' \
    '数据库 Gate 和固定候选深审均已通过，I02、I03、I04、I05、I06 和 I07 已关闭；I08 为唯一 `READY` 卡，I09 保持 `QUEUED`。正式数据库、Parser/Object Storage Provider、' \
    'I07 closure design acceptance narrative'
  replace_i03_closure_text "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    $'Schema 基线。非业务治理卡 I00 和来源领域卡 I01 已关闭；I02、I03、I04、I05 和 I06 已完成固定候选\n零发现深审并关闭；I07 已释放为唯一 `READY` 卡。' \
    $'Schema 基线。非业务治理卡 I00 和来源领域卡 I01 已关闭；I02、I03、I04、I05、I06 和 I07 已完成固定候选\n零发现深审并关闭；I08 已释放为唯一 `READY` 卡，I09 保持 `QUEUED`。' \
    'I07 closure implementation plan narrative'
  replace_i03_closure_text "${fixture_root}/docs/task-cards/wave-1/README.md" \
    'I00、I01、I02、I03、I04、I05 和 I06 已关闭；I07 已释放为唯一 `READY` 业务卡。' \
    'I00、I01、I02、I03、I04、I05、I06 和 I07 已关闭；I08 已释放为唯一 `READY` 业务卡，I09 保持 `QUEUED`。' \
    'I07 closure Wave 1 README narrative'
  replace_i03_closure_text "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    '完成零发现深审并关闭；I02、I03、I04、I05 和 I06 已关闭，I07 已释放为唯一 `READY` 卡。' \
    '完成零发现深审并关闭；I02、I03、I04、I05、I06 和 I07 已关闭，I08 已释放为唯一 `READY` 卡，I09 保持 `QUEUED`。' \
    'I07 closure implementation index narrative'
  append_w1_i07_review_receipt "${fixture_root}" "${governance_tip}"
}

commit_w1_i07_closure_projection() {
  local fixture_root="$1"
  local governance_tip="$2"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "docs: close W1-I07 and release W1-I08"
}

run_w1_i07_fixture_verifier() {
  local fixture_root="$1"
  shift
  "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" \
    "$@"
}

expect_w1_i07_closure_failure() {
  local fixture_root="$1"
  local expected_message="$2"
  shift 2
  local output
  if output="$(run_w1_i07_fixture_verifier "${fixture_root}" "$@" 2>&1)"; then
    fail "invalid I07 closure unexpectedly passed: ${expected_message}"
  fi
  assert_contains "${output}" "${expected_message}"
}

run_w1_i07_closure_contract() {
  local fixture_root governance_tip closure_sha output invalid_sha
  local positive_cases=0
  local negative_cases=0
  fixture_root="${test_tmp_root}/w1-i07-closure"
  new_w1_i07_closure_fixture "${fixture_root}"
  materialize_w1_i07_governance_tip "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"

  output="$(run_w1_i07_fixture_verifier "${fixture_root}")" ||
    fail "legal I07 governance tip was rejected: ${output}"
  assert_contains "${output}" "W1I07ClosureStatus = PENDING"
  assert_contains "${output}" "ActiveTaskCard = W1-I07"
  positive_cases=$((positive_cases + 1))

  commit_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  closure_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  output="$(run_w1_i07_fixture_verifier "${fixture_root}" \
    --transition-base "${governance_tip}" \
    --transition-head "${closure_sha}")" ||
    fail "legal explicit I07 closure was rejected: ${output}"
  assert_contains "${output}" "W1I07ClosureStatus = PASS"
  assert_contains "${output}" "ActiveTaskCard = W1-I08"
  positive_cases=$((positive_cases + 1))

  output="$(run_w1_i07_fixture_verifier "${fixture_root}")" ||
    fail "legal static I07 closure was rejected: ${output}"
  assert_contains "${output}" "ReadyTaskCardCount = 1"
  assert_contains "${output}" "W1I07ClosureStatus = PASS"
  positive_cases=$((positive_cases + 1))

  mkdir -p "${fixture_root}/server/src/main/java/io/cognitura/source/reference"
  printf '%s\n' 'package io.cognitura.source.reference;' > \
    "${fixture_root}/server/src/main/java/io/cognitura/source/reference/StableSourceReference.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/reference/StableSourceReference.java
  git -C "${fixture_root}" commit -qm "test: add legal post-closure I08 descendant"
  output="$(run_w1_i07_fixture_verifier "${fixture_root}")" ||
    fail "legal post-closure I08 descendant was rejected: ${output}"
  assert_contains "${output}" "W1I07ClosureStatus = PASS"
  positive_cases=$((positive_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${i07_closure_origin_sha}"
  materialize_w1_i07_governance_variant "${fixture_root}" WRONG_ORDER
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_GOVERNANCE_CHAIN_INVALID:path order"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${i07_closure_origin_sha}"
  materialize_w1_i07_governance_variant "${fixture_root}" REPEATED_PATH
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_GOVERNANCE_CHAIN_INVALID:path order"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${i07_closure_origin_sha}"
  materialize_w1_i07_governance_variant "${fixture_root}" EMPTY_COMMIT
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_GOVERNANCE_CHAIN_INVALID:empty commit"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${i07_closure_origin_sha}"
  materialize_w1_i07_governance_variant "${fixture_root}" RENAME
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_GOVERNANCE_CHAIN_INVALID:rename or copy"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${i07_closure_origin_sha}"
  materialize_w1_i07_governance_variant "${fixture_root}" COPY
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_GOVERNANCE_CHAIN_INVALID:rename or copy"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${i07_closure_origin_sha}"
  materialize_w1_i07_governance_variant "${fixture_root}" MODE
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_GOVERNANCE_CHAIN_INVALID:mode"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${i07_closure_origin_sha}"
  materialize_w1_i07_governance_variant "${fixture_root}" NUL
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_GOVERNANCE_CHAIN_INVALID:NUL"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${i07_closure_origin_sha}"
  materialize_w1_i07_governance_variant "${fixture_root}" PROJECTION_DRIFT
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_GOVERNANCE_CHAIN_INVALID:path order"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${i07_closure_origin_sha}^"
  materialize_w1_i07_governance_tip "${fixture_root}"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "post-I02-closure descendant changed a path outside the W1-I07 WriteSet"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  printf '%s\n' outside > "${fixture_root}/outside-governance.txt"
  git -C "${fixture_root}" add outside-governance.txt
  git -C "${fixture_root}" commit -qm "test: expand I07 governance chain"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_GOVERNANCE_CHAIN_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  printf '%s\n' '// forbidden reviewed product drift' >> \
    "${fixture_root}/server/src/main/java/io/cognitura/source/application/processing/AttemptFence.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/application/processing/AttemptFence.java
  git -C "${fixture_root}" commit -qm "test: drift reviewed I07 product"
  expect_w1_i07_closure_failure "${fixture_root}" "I07_CLOSURE_PRODUCT_DRIFT"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  printf '%s\n' extra > "${fixture_root}/i07-closure-extra.txt"
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}" \
    i07-closure-extra.txt
  git -C "${fixture_root}" commit -qm "test: expand I07 closure receipt"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_RECEIPT_PATHS_INVALID" \
    --transition-base "${governance_tip}" \
    --transition-head "$(git -C "${fixture_root}" rev-parse HEAD)"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  mkdir -p "${fixture_root}/server/src/main/java/io/cognitura/source/reference"
  printf '%s\n' 'package io.cognitura.source.reference;' > \
    "${fixture_root}/server/src/main/java/io/cognitura/source/reference/StableSourceReference.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/reference/StableSourceReference.java
  git -C "${fixture_root}" commit -qm "test: interpose before I07 closure receipt"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: create non-direct I07 closure receipt"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_RECEIPT_PATHS_INVALID:direct child" \
    --transition-base "${governance_tip}" \
    --transition-head "$(git -C "${fixture_root}" rev-parse HEAD)"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  git -C "${fixture_root}" mv \
    docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md \
    docs/task-cards/wave-1-implementation/W1-I09-renamed.md
  git -C "${fixture_root}" add -A
  git -C "${fixture_root}" commit -qm "test: rename I09 closure card"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_RECEIPT_PATHS_INVALID" \
    --transition-base "${governance_tip}" \
    --transition-head "$(git -C "${fixture_root}" rev-parse HEAD)"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" reset -q \
    docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md
  git -C "${fixture_root}" commit -qm "test: omit I09 closure card"
  git -C "${fixture_root}" checkout -q HEAD -- \
    docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_RECEIPT_PATHS_INVALID" \
    --transition-base "${governance_tip}" \
    --transition-head "$(git -C "${fixture_root}" rev-parse HEAD)"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I08-stable-reference-reparse-lineage.md" \
    Status QUEUED
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: leave I08 queued during closure"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_STATE_VECTOR_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md" \
    Status DONE
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: close I09 during I07 closure"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_STATE_VECTOR_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I07-revision-attempt-fencing-publication.md" \
    Status READY
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: keep I07 READY during closure"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_STATE_VECTOR_INVALID" \
    --transition-base "${governance_tip}" \
    --transition-head "$(git -C "${fixture_root}" rev-parse HEAD)"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md" \
    Status READY
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I09 QUEUED READY
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: release two READY cards"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_STATE_VECTOR_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I08-stable-reference-reparse-lineage.md" \
    Status QUEUED
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I08-stable-reference-reparse-lineage.md" \
    BusinessImplementationAuthorization REQUIRED_BEFORE_READY
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md" \
    Status READY
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md" \
    BusinessImplementationAuthorization USER_AUTHORIZED
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: release I09 before I08"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_STATE_VECTOR_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I10 BLOCKED_BY_DEPENDENCY READY
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: release I10 early"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_STATE_VECTOR_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    FormalDatabaseWrite AUTHORIZED
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: authorize formal database write"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_AUTHORIZATION_DRIFT"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    ActiveTaskCard W1-I07
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: retain I07 as active after closure"
  expect_w1_i07_closure_failure "${fixture_root}" "ActiveTaskCard = W1-I08"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    ReadyTaskCardCount 2
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: publish wrong I07 ready count"
  expect_w1_i07_closure_failure "${fixture_root}" "ReadyTaskCardCount = 1"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    RemotePush AUTHORIZED
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: authorize push during I07 closure"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_AUTHORIZATION_DRIFT"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  sed -i.bak "s/${i07_reviewed_candidate_sha}/0000000000000000000000000000000000000000/" \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: bind wrong I07 product candidate"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_REVIEW_RECEIPT_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  sed -i.bak \
    's/^ReviewedParent = .*$/ReviewedParent = 0000000000000000000000000000000000000000/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: bind wrong I07 product parent"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_REVIEW_RECEIPT_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  sed -i.bak \
    's/^ReviewedTree = .*$/ReviewedTree = 0000000000000000000000000000000000000000/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: bind wrong I07 product tree"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_REVIEW_RECEIPT_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  sed -i.bak \
    's/^ReviewedGovernanceCandidate = .*$/ReviewedGovernanceCandidate = 0000000000000000000000000000000000000000/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: bind wrong I07 governance candidate"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_REVIEW_RECEIPT_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  sed -i.bak \
    's/^ReviewedGovernanceParent = .*$/ReviewedGovernanceParent = 0000000000000000000000000000000000000000/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: bind wrong I07 governance parent"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_REVIEW_RECEIPT_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  sed -i.bak \
    's/^ReviewedGovernanceTree = .*$/ReviewedGovernanceTree = 0000000000000000000000000000000000000000/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: bind wrong I07 governance tree"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_REVIEW_RECEIPT_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  sed -i.bak 's/^ReviewVerdict = GO$/ReviewVerdict = NO_GO/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: close I07 with NO-GO review"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_REVIEW_RECEIPT_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  sed -i.bak 's/^P1 = 0$/P1 = 1/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: close I07 with nonzero finding"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_REVIEW_RECEIPT_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  sed -i.bak 's/^Ultra = NOT_RUN$/Ultra = RUN/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: close I07 with Ultra review"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_REVIEW_RECEIPT_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  append_w1_i07_review_receipt "${fixture_root}" "${governance_tip}"
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: duplicate I07 closure receipt"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_REVIEW_RECEIPT_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  printf '%s\n' nonterminal >> \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: make I07 receipt nonterminal"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_REVIEW_RECEIPT_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  chmod 755 "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md"
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: drift I09 card mode"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_RECEIPT_PATHS_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  make_w1_i07_closure_projection "${fixture_root}" "${governance_tip}"
  printf '\0' >> "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md"
  git -C "${fixture_root}" add "${i07_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: add NUL to I09 closure card"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_RECEIPT_PATHS_INVALID"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I07-revision-attempt-fencing-publication.md" \
    Status READY
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I08-stable-reference-reparse-lineage.md" \
    Status BLOCKED_BY_DEPENDENCY
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md" \
    Status BLOCKED_BY_DEPENDENCY
  git -C "${fixture_root}" add \
    docs/task-cards/wave-1-implementation/W1-I07-revision-attempt-fencing-publication.md \
    docs/task-cards/wave-1-implementation/W1-I08-stable-reference-reparse-lineage.md \
    docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md
  git -C "${fixture_root}" commit -qm "test: reopen I07 after closure"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I07-revision-attempt-fencing-publication.md" \
    Status DONE
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I08-stable-reference-reparse-lineage.md" \
    Status READY
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md" \
    Status QUEUED
  git -C "${fixture_root}" add \
    docs/task-cards/wave-1-implementation/W1-I07-revision-attempt-fencing-publication.md \
    docs/task-cards/wave-1-implementation/W1-I08-stable-reference-reparse-lineage.md \
    docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md
  git -C "${fixture_root}" commit -qm "test: close I07 a second time"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_REVIEW_RECEIPT_INVALID:exactly once"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  set_field "${fixture_root}/AGENTS.md" ActiveImplementationTaskCard W1-I07
  git -C "${fixture_root}" add AGENTS.md
  git -C "${fixture_root}" commit -qm "test: mutate I07 projection after closure"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_DESCENDANT_OUTSIDE_WRITE_SET"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  set_field "${fixture_root}/AGENTS.md" ActiveImplementationTaskCard W1-I07
  git -C "${fixture_root}" add AGENTS.md
  git -C "${fixture_root}" commit -qm "test: introduce I07 projection drift"
  set_field "${fixture_root}/AGENTS.md" ActiveImplementationTaskCard W1-I08
  git -C "${fixture_root}" add AGENTS.md
  git -C "${fixture_root}" commit -qm "test: restore I07 projection bytes"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_DESCENDANT_OUTSIDE_WRITE_SET"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  printf '%s\n' outside > "${fixture_root}/outside-i08-write-set.txt"
  git -C "${fixture_root}" add outside-i08-write-set.txt
  git -C "${fixture_root}" commit -qm "test: change outside I08 WriteSet"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_DESCENDANT_OUTSIDE_WRITE_SET"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${closure_sha}"
  set_field "${fixture_root}/AGENTS.md" ActiveImplementationTaskCard W1-I07
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_WORKTREE_MISMATCH"
  git -C "${fixture_root}" checkout -q -- AGENTS.md
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  git -C "${fixture_root}" switch -q -c i07-closure-merge-left
  printf '%s\n' left > "${fixture_root}/i07-closure-merge-left.txt"
  git -C "${fixture_root}" add i07-closure-merge-left.txt
  git -C "${fixture_root}" commit -qm "test: create I07 closure merge left"
  invalid_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  git -C "${fixture_root}" switch -q --detach "${governance_tip}"
  git -C "${fixture_root}" switch -q -c i07-closure-merge-right
  printf '%s\n' right > "${fixture_root}/i07-closure-merge-right.txt"
  git -C "${fixture_root}" add i07-closure-merge-right.txt
  git -C "${fixture_root}" commit -qm "test: create I07 closure merge right"
  git -C "${fixture_root}" merge -q --no-ff "${invalid_sha}" \
    -m "test: merge invalid I07 closure governance"
  expect_w1_i07_closure_failure "${fixture_root}" \
    "I07_CLOSURE_GOVERNANCE_CHAIN_INVALID"
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 4 ]] ||
    fail "I07 closure positive case count mismatch: ${positive_cases}"
  [[ "${negative_cases}" -eq 44 ]] ||
    fail "I07 closure negative case count mismatch: ${negative_cases}"
  printf '%s\n' \
    "W1I07ClosureContractTests = PASS" \
    "W1I07ClosurePositiveCases = ${positive_cases}" \
    "W1I07ClosureNegativeCases = ${negative_cases}"
}

run_terra_first_routing_contract() {
  local predecessor_sha="59144c9dfca4abacce62de41c7306021bf5b83f8"
  local fixture_root output successor_sha
  local positive_cases=0
  local negative_cases=0
  local successor_paths=(
    AGENTS.md
    docs/superpowers/specs/2026-08-21-cognitura-terra-first-model-routing-design.md
    scripts/verify-wave1-implementation-cards
    tests/task-cards/verify-wave1-implementation-cards.sh
  )

  fixture_root="${test_tmp_root}/terra-first-routing"
  git clone --shared -q "${repo_root}" "${fixture_root}"

  materialize_terra_first_successor() {
    local path
    git -C "${fixture_root}" checkout -q --detach "${predecessor_sha}"
    for path in "${successor_paths[@]}"; do
      mkdir -p "${fixture_root}/$(dirname "${path}")"
      cp -p "${repo_root}/${path}" "${fixture_root}/${path}"
    done
  }

  materialize_terra_first_successor
  git -C "${fixture_root}" add "${successor_paths[@]}"
  git -C "${fixture_root}" commit -qm "governance: adopt Terra-first model routing"
  successor_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation")" ||
    fail "legal Terra-first routing successor was rejected: ${output}"
  assert_contains "${output}" "Wave1ImplementationTaskCardValidation = PASS"
  positive_cases=$((positive_cases + 1))

  materialize_terra_first_successor
  git -C "${fixture_root}" add \
    AGENTS.md \
    scripts/verify-wave1-implementation-cards \
    tests/task-cards/verify-wave1-implementation-cards.sh
  git -C "${fixture_root}" commit -qm "test: omit Terra-first Authority"
  if output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" 2>&1)"; then
    fail "incomplete Terra-first routing successor unexpectedly passed"
  fi
  assert_contains "${output}" "TERRA_FIRST_ROUTING_SUCCESSOR_INVALID:exact four paths"
  negative_cases=$((negative_cases + 1))

  materialize_terra_first_successor
  printf '\nTerraFirstRoutingExtra = FORBIDDEN\n' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add "${successor_paths[@]}" README.md
  git -C "${fixture_root}" commit -qm "test: expand Terra-first governance scope"
  if output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" 2>&1)"; then
    fail "expanded Terra-first routing successor unexpectedly passed"
  fi
  assert_contains "${output}" "TERRA_FIRST_ROUTING_SUCCESSOR_INVALID:exact four paths"
  negative_cases=$((negative_cases + 1))

  git -C "${fixture_root}" checkout -q --detach "${successor_sha}"
  printf '\nCurrentRoute = gpt-5.6-sol/high\n' >> "${fixture_root}/AGENTS.md"
  if output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" 2>&1)"; then
    fail "working Terra-first route drift unexpectedly passed"
  fi
  assert_contains "${output}" "TERRA_FIRST_ROUTING_WORKTREE_DRIFT:AGENTS.md"
  negative_cases=$((negative_cases + 1))

  printf '%s\n' \
    "TerraFirstRoutingContractTests = PASS" \
    "TerraFirstRoutingPositiveCases = ${positive_cases}" \
    "TerraFirstRoutingNegativeCases = ${negative_cases}"
}

if [[ "${w1_i03_closure_contract_only}" == "1" ]]; then
  run_w1_i03_closure_contract
  exit 0
fi

if [[ "${w1_i04_closure_contract_only}" == "1" ]]; then
  run_w1_i04_closure_contract
  exit 0
fi

if [[ "${w1_i05_verifier_recovery_contract_only}" == "1" ]]; then
  run_w1_i05_xml_copy_repair_contract
  run_w1_i05_fixed_review_contract
  exit 0
fi

if [[ "${w1_i05_closure_contract_only}" == "1" ]]; then
  run_w1_i05_closure_contract
  exit 0
fi

if [[ "${w1_i06_entry_repair_contract_only}" == "1" ]]; then
  run_w1_i06_entry_repair_contract
  exit 0
fi

if [[ "${w1_i06_copy_inference_repair_contract_only}" == "1" ]]; then
  run_w1_i06_copy_inference_repair_contract
  exit 0
fi

if [[ "${w1_i06_closure_contract_only}" == "1" ]]; then
  run_w1_i06_closure_contract
  exit 0
fi

if [[ "${w1_i02_database_gate_contract_only}" == "1" ]]; then
  run_w1_i02_database_gate_contract
  exit 0
fi

if [[ "${w1_i02_closure_contract_only}" == "1" ]]; then
  run_w1_i02_closure_contract
  exit 0
fi

if [[ "${w1_i07_closure_contract_only}" == "1" ]]; then
  run_w1_i07_closure_contract
  exit 0
fi

i08_closure_origin_sha="4890c8ec6af72e57e696845e8fc06a5552aafd45"
i08_closure_spec_sha="ce3545b699a9a38d63ace8de18a117ed322a3054"
i08_rejected_governance_sha="6dfc075be803277c695b729001997345c512c34d"
i08_repair_spec_sha="a5d3954f7f1f2e3cf1b4b887a23ed2b7cf399ec9"
i08_repair_test_sha="ad2f6224f75caf2b439b3c46bcfb9cd4da6b7357"
i08_reviewed_parent_sha="c06ea6ed7efcb2ef04c085e3976d42814af0b3ea"
i08_reviewed_tree_sha="7db68e968432b8b7218a63aba9ea06d6a93a5782"
i08_spec_path="docs/superpowers/specs/2026-08-22-cognitura-w1-i08-closure-design.md"
i08_repair_spec_path="docs/superpowers/specs/2026-08-22-cognitura-w1-i08-closure-review-finding-repair.md"
i08_test_path="tests/task-cards/verify-wave1-implementation-cards.sh"
i08_verifier_path="scripts/verify-wave1-implementation-cards"
i08_card_path="docs/task-cards/wave-1-implementation/W1-I08-stable-reference-reparse-lineage.md"
i09_card_path="docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md"
i08_projection_paths=(
  AGENTS.md
  README.md
  docs/design/wave-1/README.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-plan.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1/README.md
  docs/task-cards/wave-1-implementation/README.md
  "${i08_card_path}"
  "${i09_card_path}"
)

new_i08_closure_fixture() {
  local fixture_root="$1"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${i08_rejected_governance_sha}"
}

materialize_i08_closure_governance() {
  local fixture_root="$1"
  local mutation="${2:-NONE}"
  mkdir -p "${fixture_root}/$(dirname "${i08_repair_spec_path}")"
  git -C "${repo_root}" show "${i08_repair_spec_sha}:${i08_repair_spec_path}" > \
    "${fixture_root}/${i08_repair_spec_path}"
  git -C "${fixture_root}" add "${i08_repair_spec_path}"
  if [[ "${mutation}" == GOVERNANCE_EXTRA_PATH ]]; then
    printf '%s\n' 'I08 closure governance drift' >> "${fixture_root}/README.md"
    git -C "${fixture_root}" add README.md
  fi
  git -C "${fixture_root}" commit -qm "docs: define W1-I08 closure finding repair"

  git -C "${repo_root}" show \
    "${i08_repair_test_sha}:${i08_test_path}" > "${fixture_root}/${i08_test_path}"
  chmod 755 "${fixture_root}/${i08_test_path}"
  git -C "${fixture_root}" add "${i08_test_path}"
  git -C "${fixture_root}" commit -qm "test: define W1-I08 closure contract"

  cp -p "${repo_root}/${i08_verifier_path}" "${fixture_root}/${i08_verifier_path}"
  chmod 755 "${fixture_root}/${i08_verifier_path}"
  if git -C "${fixture_root}" diff --quiet -- "${i08_verifier_path}"; then
    printf '%s\n' '# pending W1-I08 closure verifier' >> \
      "${fixture_root}/${i08_verifier_path}"
  fi
  git -C "${fixture_root}" add "${i08_verifier_path}"
  if [[ "${mutation}" == PRODUCT_DRIFT ]]; then
    printf '%s\n' '// I08 closure product drift' >> \
      "${fixture_root}/server/src/main/java/io/cognitura/source/reference/StableSourceReference.java"
    git -C "${fixture_root}" add \
      server/src/main/java/io/cognitura/source/reference/StableSourceReference.java
  fi
  git -C "${fixture_root}" commit -qm "feat: verify W1-I08 closure"
}

append_i08_closure_receipt() {
  local fixture_root="$1"
  local governance_tip="$2"
  local governance_parent governance_tree
  governance_parent="$(git -C "${fixture_root}" rev-parse "${governance_tip}^")"
  governance_tree="$(git -C "${fixture_root}" rev-parse "${governance_tip}^{tree}")"
  printf '%s\n' \
    '' \
    '## 15. I08 关闭收据' \
    '' \
    '```text' \
    'W1-I08 = DONE' \
    "ReviewedCandidate = ${i08_closure_origin_sha}" \
    "ReviewedParent = ${i08_reviewed_parent_sha}" \
    "ReviewedTree = ${i08_reviewed_tree_sha}" \
    "ReviewedGovernanceCandidate = ${i08_rejected_governance_sha}" \
    "ReviewedVerifierCorrectionCandidate = ${governance_tip}" \
    "ReviewedVerifierCorrectionParent = ${governance_parent}" \
    "ReviewedVerifierCorrectionTree = ${governance_tree}" \
    'ReviewLevel = L3' \
    'ReviewRoute = deep_reviewer' \
    'ReviewEffort = xhigh' \
    'ReviewMultiplicity = ONE' \
    'ReviewVerdict = GO' \
    'P0 = 0' \
    'P1 = 0' \
    'P2 = 0' \
    'Ultra = NOT_RUN' \
    'I08ClosureReleasedTaskCard = W1-I09' \
    'FormalDatabaseWrite = NOT_AUTHORIZED' \
    'RemotePush = NOT_AUTHORIZED' \
    '```' >> \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
}

replace_i08_projection_text() {
  local file="$1"
  local old_text="$2"
  local new_text="$3"
  I08_OLD_TEXT="${old_text}" I08_NEW_TEXT="${new_text}" \
    perl -0777 -i.bak -pe 's/\Q$ENV{I08_OLD_TEXT}\E/$ENV{I08_NEW_TEXT}/g' "${file}"
  rm "${file}.bak"
}

make_i08_closure_projection() {
  local fixture_root="$1"
  local governance_tip="$2"
  set_field "${fixture_root}/AGENTS.md" ActiveImplementationTaskCard W1-I09
  set_field "${fixture_root}/README.md" ActiveImplementationTaskCard W1-I09
  set_field "${fixture_root}/docs/design/wave-1/README.md" \
    ActiveImplementationGovernanceTaskCard W1-I09
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" ActiveTaskCard W1-I09
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" ActiveTaskCardStatus READY
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    ActiveImplementationTaskCard W1-I09
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    ActiveImplementationGovernanceTaskCard W1-I09
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    ImplementationTaskCardPlanStatus I08_DONE_I09_READY
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    ActiveImplementationGovernanceTaskCard W1-I09
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    ActiveTaskCard W1-I09
  set_table_status "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    W1-I08 READY DONE
  set_table_status "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    W1-I09 QUEUED READY
  set_field "${fixture_root}/docs/task-cards/wave-1/README.md" \
    ActiveImplementationGovernanceTaskCard W1-I09
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    ActiveTaskCard W1-I09
  set_table_status "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I08 READY DONE
  set_table_status "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I09 QUEUED READY
  set_field "${fixture_root}/${i08_card_path}" Status DONE
  set_field "${fixture_root}/${i09_card_path}" Status READY
  set_field "${fixture_root}/${i09_card_path}" \
    BusinessImplementationAuthorization USER_AUTHORIZED
  replace_i08_projection_text "${fixture_root}/AGENTS.md" \
    '`W1-I02` 和 `W1-I07` 已完成固定候选零发现深审并关闭；`W1-I08` 已作为唯一 `READY` 卡释放，`W1-I09` 保持 `QUEUED`。' \
    '`W1-I02`、`W1-I07` 和 `W1-I08` 已完成固定候选零发现深审并关闭；`W1-I09` 已作为唯一 `READY` 卡释放。'
  replace_i08_projection_text "${fixture_root}/AGENTS.md" \
    'I00、I01、I02、I03、I04、I05、I06 和 I07 已关闭；I08 为唯一 `READY` 卡，I09 保持 `QUEUED`。' \
    'I00、I01、I02、I03、I04、I05、I06、I07 和 I08 已关闭；I09 为唯一 `READY` 卡。'
  replace_i08_projection_text "${fixture_root}/README.md" \
    '完成零发现深审并关闭；I02 和 I07 已关闭，I08 已释放为唯一 `READY` 卡，I09 保持 `QUEUED`。' \
    '完成零发现深审并关闭；I02、I07 和 I08 已关闭，I09 已释放为唯一 `READY` 卡。'
  replace_i08_projection_text "${fixture_root}/README.md" \
    '已完成固定候选零发现深审并关闭；`W1-I03`、`W1-I04`、`W1-I05`、`W1-I06`、`W1-I07` 已关闭，`W1-I08` 为唯一 `READY` 卡，`W1-I09` 保持 `QUEUED`。' \
    '已完成固定候选零发现深审并关闭；`W1-I03`、`W1-I04`、`W1-I05`、`W1-I06`、`W1-I07`、`W1-I08` 已关闭，`W1-I09` 为唯一 `READY` 卡。'
  replace_i08_projection_text "${fixture_root}/docs/design/wave-1/README.md" \
    '  I01、I02、I03、I04、I05、I06 和 I07 已关闭，I08 已释放为唯一 `READY` 卡，I09 保持 `QUEUED`。' \
    '  I01、I02、I03、I04、I05、I06、I07 和 I08 已关闭，I09 已释放为唯一 `READY` 卡。'
  replace_i08_projection_text "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    '`W1-I08` 已释放为唯一 `READY` 卡，`W1-I09` 保持 `QUEUED`。' \
    '`W1-I08` 已关闭，`W1-I09` 已释放为唯一 `READY` 卡。'
  replace_i08_projection_text "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    '固定候选深审并关闭；I02、I03、I04、I05、I06 和 I07 已关闭，I08 已释放为唯一 `READY` 卡，I09 保持 `QUEUED`，完整证据记录在' \
    '固定候选深审并关闭；I02、I03、I04、I05、I06、I07 和 I08 已关闭，I09 已释放为唯一 `READY` 卡，完整证据记录在'
  replace_i08_projection_text "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    '数据库 Gate 和固定候选深审均已通过，I02、I03、I04、I05、I06 和 I07 已关闭；I08 为唯一 `READY` 卡，I09 保持 `QUEUED`。正式数据库、Parser/Object Storage Provider、' \
    '数据库 Gate 和固定候选深审均已通过，I02、I03、I04、I05、I06、I07 和 I08 已关闭；I09 为唯一 `READY` 卡。正式数据库、Parser/Object Storage Provider、'
  replace_i08_projection_text "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    '零发现深审并关闭；I08 已释放为唯一 `READY` 卡，I09 保持 `QUEUED`。' \
    '零发现深审并关闭；I08 已关闭，I09 已释放为唯一 `READY` 卡。'
  replace_i08_projection_text "${fixture_root}/docs/task-cards/wave-1/README.md" \
    'I00、I01、I02、I03、I04、I05、I06 和 I07 已关闭；I08 已释放为唯一 `READY` 业务卡，I09 保持 `QUEUED`。' \
    'I00、I01、I02、I03、I04、I05、I06、I07 和 I08 已关闭；I09 已释放为唯一 `READY` 业务卡。'
  replace_i08_projection_text "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    '完成零发现深审并关闭；I02、I03、I04、I05、I06 和 I07 已关闭，I08 已释放为唯一 `READY` 卡，I09 保持 `QUEUED`。' \
    '完成零发现深审并关闭；I02、I03、I04、I05、I06、I07 和 I08 已关闭，I09 已释放为唯一 `READY` 卡。'
  append_i08_closure_receipt "${fixture_root}" "${governance_tip}"
}

commit_i08_closure_projection() {
  local fixture_root="$1"
  local governance_tip="$2"
  make_i08_closure_projection "${fixture_root}" "${governance_tip}"
  git -C "${fixture_root}" add "${i08_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "docs: close W1-I08 and release W1-I09"
}

run_i08_fixture_verifier() {
  local fixture_root="$1"
  shift
  "${verifier}" --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" "$@"
}

expect_i08_closure_failure() {
  local fixture_root="$1"
  local expected="$2"
  shift 2
  local output
  if output="$(run_i08_fixture_verifier "${fixture_root}" "$@" 2>&1)"; then
    fail "invalid I08 closure unexpectedly passed: ${expected}"
  fi
  assert_contains "${output}" "${expected}"
}

run_w1_i08_closure_contract() {
  local fixture_root governance_tip closure_sha output
  local positive_cases=0 negative_cases=0

  fixture_root="${test_tmp_root}/w1-i08-closure-positive"
  new_i08_closure_fixture "${fixture_root}"
  materialize_i08_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  commit_i08_closure_projection "${fixture_root}" "${governance_tip}"
  closure_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  output="$(run_i08_fixture_verifier "${fixture_root}" \
    --transition-base "${governance_tip}" --transition-head "${closure_sha}")" ||
    fail "legal explicit I08 closure was rejected: ${output}"
  assert_contains "${output}" "W1I08ClosureStatus = PASS"
  assert_contains "${output}" "ActiveTaskCard = W1-I09"
  positive_cases=$((positive_cases + 1))
  output="$(run_i08_fixture_verifier "${fixture_root}")" ||
    fail "legal static I08 closure was rejected: ${output}"
  assert_contains "${output}" "W1I08ClosureStatus = PASS"
  assert_contains "${output}" "ReadyTaskCardCount = 1"
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i08-closure-wrong-receipt"
  new_i08_closure_fixture "${fixture_root}"
  materialize_i08_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i08_closure_projection "${fixture_root}" "${governance_tip}"
  sed -i.bak 's/^ReviewedCandidate = .*/ReviewedCandidate = bad/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i08_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: drift I08 review receipt"
  expect_i08_closure_failure "${fixture_root}" \
    "I08_CLOSURE_REVIEW_RECEIPT_INVALID" \
    --transition-base "${governance_tip}" --transition-head HEAD
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i08-closure-permission-drift"
  new_i08_closure_fixture "${fixture_root}"
  materialize_i08_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i08_closure_projection "${fixture_root}" "${governance_tip}"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    FormalDatabaseWrite AUTHORIZED
  git -C "${fixture_root}" add "${i08_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: drift I08 closure database authority"
  expect_i08_closure_failure "${fixture_root}" \
    "I08_CLOSURE_PROJECTION_MISMATCH" \
    --transition-base "${governance_tip}" --transition-head HEAD
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i08-closure-i09-contract-drift"
  new_i08_closure_fixture "${fixture_root}"
  materialize_i08_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i08_closure_projection "${fixture_root}" "${governance_tip}"
  printf '%s\n' \
    'WriteSet = server/src/main/java/io/cognitura/source/api/command/Unexpected.java' >> \
    "${fixture_root}/${i09_card_path}"
  git -C "${fixture_root}" add "${i08_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: drift I09 closure contract"
  expect_i08_closure_failure "${fixture_root}" \
    "I08_CLOSURE_PROJECTION_MISMATCH" \
    --transition-base "${governance_tip}" --transition-head HEAD
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i08-closure-state"
  new_i08_closure_fixture "${fixture_root}"
  materialize_i08_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i08_closure_projection "${fixture_root}" "${governance_tip}"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    ReadyTaskCardCount 2
  git -C "${fixture_root}" add "${i08_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: add second I08 closure READY"
  expect_i08_closure_failure "${fixture_root}" "I08_CLOSURE_STATE_VECTOR_INVALID" \
    --transition-base "${governance_tip}" --transition-head HEAD
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i08-closure-governance-extra"
  new_i08_closure_fixture "${fixture_root}"
  materialize_i08_closure_governance "${fixture_root}" GOVERNANCE_EXTRA_PATH
  expect_i08_closure_failure "${fixture_root}" "I08_CLOSURE_GOVERNANCE_CHAIN_INVALID"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i08-closure-projection-extra"
  new_i08_closure_fixture "${fixture_root}"
  materialize_i08_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i08_closure_projection "${fixture_root}" "${governance_tip}"
  printf '%s\n' '' >> "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I10-source-preview-query-api.md"
  git -C "${fixture_root}" add "${i08_projection_paths[@]}" \
    docs/task-cards/wave-1-implementation/W1-I10-source-preview-query-api.md
  git -C "${fixture_root}" commit -qm "test: expand I08 closure projection"
  expect_i08_closure_failure "${fixture_root}" "I08_CLOSURE_RECEIPT_PATHS_INVALID" \
    --transition-base "${governance_tip}" --transition-head HEAD
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i08-closure-product-drift"
  new_i08_closure_fixture "${fixture_root}"
  materialize_i08_closure_governance "${fixture_root}" PRODUCT_DRIFT
  expect_i08_closure_failure "${fixture_root}" "I08_CLOSURE_PRODUCT_DRIFT"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i08-closure-post-write-set"
  new_i08_closure_fixture "${fixture_root}"
  materialize_i08_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  commit_i08_closure_projection "${fixture_root}" "${governance_tip}"
  printf '%s\n' 'post I08 closure drift' >> \
    "${fixture_root}/docs/task-cards/wave-1/README.md"
  git -C "${fixture_root}" add docs/task-cards/wave-1/README.md
  git -C "${fixture_root}" commit -qm "test: exceed I09 WriteSet"
  expect_i08_closure_failure "${fixture_root}" \
    "I08_CLOSURE_DESCENDANT_OUTSIDE_WRITE_SET"
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 2 ]] || fail "I08 closure positive count mismatch"
  [[ "${negative_cases}" -eq 8 ]] || fail "I08 closure negative count mismatch"
  printf '%s\n' \
    "W1I08ClosureContractTests = PASS" \
    "W1I08ClosurePositiveCases = ${positive_cases}" \
    "W1I08ClosureNegativeCases = ${negative_cases}"
}

i09_runtime_rebaseline_origin_sha="ae6d0ba7c1caf6365825909f39ccc3e71da9e966"
i09_runtime_rebaseline_design_sha="2a5f818f22673e3af20bce369e99810e21f0095d"
i09_runtime_rebaseline_plan_sha="7574bfd68f6fe9f0cbce3933dce986401054b61c"
i09_runtime_rebaseline_test_sha="835e6baf7b2df36e696ee1b1248edd491743e8de"
i09_runtime_rebaseline_design_path="docs/superpowers/specs/2026-08-22-cognitura-w1-i09-real-command-runtime-rebaseline-design.md"
i09_runtime_rebaseline_plan_path="docs/superpowers/plans/2026-08-22-cognitura-w1-i09-real-command-runtime-rebaseline.md"
i09_runtime_rebaseline_test_path="tests/task-cards/verify-wave1-implementation-cards.sh"
i09_runtime_rebaseline_verifier_path="scripts/verify-wave1-implementation-cards"

new_i09_runtime_rebaseline_fixture() {
  local fixture_root="$1"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    "${i09_runtime_rebaseline_origin_sha}"
}

commit_i09_runtime_rebaseline_file() {
  local fixture_root="$1"
  local source_sha="$2"
  local path="$3"
  local message="$4"
  mkdir -p "${fixture_root}/$(dirname "${path}")"
  if [[ "${source_sha}" == WORKTREE ]]; then
    cp -p "${repo_root}/${path}" "${fixture_root}/${path}"
  else
    git -C "${repo_root}" show "${source_sha}:${path}" > \
      "${fixture_root}/${path}"
  fi
  case "${path}" in
    scripts/*|tests/*.sh|tests/*/*.sh) chmod 755 "${fixture_root}/${path}" ;;
    *) chmod 644 "${fixture_root}/${path}" ;;
  esac
  if git -C "${fixture_root}" cat-file -e "HEAD:${path}" 2>/dev/null &&
      git -C "${fixture_root}" diff --quiet -- "${path}"; then
    printf '%s\n' '# pending W1-I09 runtime rebaseline step' >> \
      "${fixture_root}/${path}"
  fi
  git -C "${fixture_root}" add "${path}"
  git -C "${fixture_root}" commit -qm "${message}"
}

materialize_i09_runtime_rebaseline_governance() {
  local fixture_root="$1"
  local mutation="${2:-NONE}"

  if [[ "${mutation}" == WRONG_ORDER ]]; then
    commit_i09_runtime_rebaseline_file "${fixture_root}" \
      "${i09_runtime_rebaseline_plan_sha}" \
      "${i09_runtime_rebaseline_plan_path}" \
      "docs: plan W1-I09 real command runtime"
    commit_i09_runtime_rebaseline_file "${fixture_root}" \
      "${i09_runtime_rebaseline_design_sha}" \
      "${i09_runtime_rebaseline_design_path}" \
      "docs: rebaseline W1-I09 real command runtime"
  else
    mkdir -p "${fixture_root}/$(dirname "${i09_runtime_rebaseline_design_path}")"
    git -C "${repo_root}" show \
      "${i09_runtime_rebaseline_design_sha}:${i09_runtime_rebaseline_design_path}" > \
      "${fixture_root}/${i09_runtime_rebaseline_design_path}"
    if [[ "${mutation}" == WRONG_EVIDENCE ]]; then
      printf '%s\n' 'WrongEvidence = YES' >> \
        "${fixture_root}/${i09_runtime_rebaseline_design_path}"
    elif [[ "${mutation}" == NUL ]]; then
      printf '\0' >> "${fixture_root}/${i09_runtime_rebaseline_design_path}"
    elif [[ "${mutation}" == MODE ]]; then
      chmod 755 "${fixture_root}/${i09_runtime_rebaseline_design_path}"
    fi
    git -C "${fixture_root}" add "${i09_runtime_rebaseline_design_path}"
    if [[ "${mutation}" == EXTRA_PATH ]]; then
      printf '%s\n' 'I09 runtime rebaseline scope drift' >> \
        "${fixture_root}/README.md"
      git -C "${fixture_root}" add README.md
    fi
    git -C "${fixture_root}" commit -qm \
      "docs: rebaseline W1-I09 real command runtime"

    if [[ "${mutation}" == MERGE ]]; then
      git -C "${fixture_root}" switch -q -c i09-side \
        "${i09_runtime_rebaseline_origin_sha}"
      printf '%s\n' 'I09 merge side drift' >> "${fixture_root}/README.md"
      git -C "${fixture_root}" add README.md
      git -C "${fixture_root}" commit -qm "test: create I09 merge side"
      git -C "${fixture_root}" switch -q --detach HEAD@{2}
      git -C "${fixture_root}" merge -q --no-ff i09-side \
        -m "test: merge I09 rebaseline side"
    fi

    if [[ "${mutation}" == RENAME ]]; then
      mkdir -p "${fixture_root}/docs/superpowers/plans"
      git -C "${fixture_root}" mv \
        "${i09_runtime_rebaseline_design_path}" \
        "docs/superpowers/plans/i09-runtime-renamed.md"
    fi
    commit_i09_runtime_rebaseline_file "${fixture_root}" \
      "${i09_runtime_rebaseline_plan_sha}" \
      "${i09_runtime_rebaseline_plan_path}" \
      "docs: plan W1-I09 real command runtime"
    if [[ "${mutation}" == RENAME ]]; then
      git -C "${fixture_root}" add -u
      git -C "${fixture_root}" commit --amend -qm \
        "docs: plan W1-I09 real command runtime"
    elif [[ "${mutation}" == COPY ]]; then
      cp -p "${fixture_root}/${i09_runtime_rebaseline_design_path}" \
        "${fixture_root}/docs/superpowers/plans/i09-runtime-copy.md"
      git -C "${fixture_root}" add \
        docs/superpowers/plans/i09-runtime-copy.md
      git -C "${fixture_root}" commit --amend -qm \
        "docs: plan W1-I09 real command runtime"
    fi
  fi

  commit_i09_runtime_rebaseline_file "${fixture_root}" \
    "${i09_runtime_rebaseline_test_sha}" \
    "${i09_runtime_rebaseline_test_path}" \
    "test: require W1-I09 runtime rebaseline"
  if [[ "$(git -C "${fixture_root}" hash-object \
        "${fixture_root}/${i09_runtime_rebaseline_test_path}")" != \
        "$(git -C "${repo_root}" hash-object \
        "${repo_root}/${i09_runtime_rebaseline_test_path}")" ]]; then
    commit_i09_runtime_rebaseline_file "${fixture_root}" WORKTREE \
      "${i09_runtime_rebaseline_test_path}" \
      "test: correct W1-I09 runtime rebaseline fixture"
  fi
  commit_i09_runtime_rebaseline_file "${fixture_root}" WORKTREE \
    "${i09_runtime_rebaseline_verifier_path}" \
    "build: admit W1-I09 runtime rebaseline"
}

run_i09_runtime_rebaseline_fixture_verifier() {
  local fixture_root="$1"
  "${verifier}" --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation"
}

expect_i09_runtime_rebaseline_failure() {
  local fixture_root="$1"
  local expected="$2"
  local output
  if output="$(run_i09_runtime_rebaseline_fixture_verifier \
      "${fixture_root}" 2>&1)"; then
    fail "invalid I09 runtime rebaseline unexpectedly passed: ${expected}"
  fi
  assert_contains "${output}" "${expected}"
}

run_w1_i09_runtime_rebaseline_contract() {
  local fixture_root output
  local positive_cases=0 negative_cases=0

  fixture_root="${test_tmp_root}/w1-i09-runtime-rebaseline-positive"
  new_i09_runtime_rebaseline_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_governance "${fixture_root}"
  output="$(run_i09_runtime_rebaseline_fixture_verifier "${fixture_root}")" ||
    fail "legal I09 runtime rebaseline was rejected: ${output}"
  assert_contains "${output}" \
    "W1I09RuntimeRebaselineStatus = PENDING_PROJECTION"
  assert_contains "${output}" "ActiveTaskCard = W1-I09"
  positive_cases=$((positive_cases + 1))

  output="$("${verifier}" --repo-root "${repo_root}" \
    --cards-dir "${cards_dir}")" ||
    fail "fixed I09 runtime rebaseline was rejected: ${output}"
  assert_contains "${output}" \
    "W1I09RuntimeRebaselineStatus = PENDING_PROJECTION"
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-runtime-rebaseline-evidence"
  new_i09_runtime_rebaseline_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_governance "${fixture_root}" WRONG_EVIDENCE
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    "I09_RUNTIME_REBASELINE_CHAIN_INVALID:evidence"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-runtime-rebaseline-extra"
  new_i09_runtime_rebaseline_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_governance "${fixture_root}" EXTRA_PATH
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    "I09_RUNTIME_REBASELINE_CHAIN_INVALID:exact path"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-runtime-rebaseline-order"
  new_i09_runtime_rebaseline_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_governance "${fixture_root}" WRONG_ORDER
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    "I09_RUNTIME_REBASELINE_CHAIN_INVALID:order"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-runtime-rebaseline-merge"
  new_i09_runtime_rebaseline_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_governance "${fixture_root}" MERGE
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    "I09_RUNTIME_REBASELINE_CHAIN_INVALID:single parent"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-runtime-rebaseline-rename"
  new_i09_runtime_rebaseline_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_governance "${fixture_root}" RENAME
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    "I09_RUNTIME_REBASELINE_CHAIN_INVALID:rename or copy"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-runtime-rebaseline-copy"
  new_i09_runtime_rebaseline_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_governance "${fixture_root}" COPY
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    "I09_RUNTIME_REBASELINE_CHAIN_INVALID:rename or copy"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-runtime-rebaseline-mode"
  new_i09_runtime_rebaseline_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_governance "${fixture_root}" MODE
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    "I09_RUNTIME_REBASELINE_CHAIN_INVALID:mode"
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-runtime-rebaseline-nul"
  new_i09_runtime_rebaseline_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_governance "${fixture_root}" NUL
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    "I09_RUNTIME_REBASELINE_CHAIN_INVALID:NUL"
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 2 ]] ||
    fail "I09 runtime rebaseline positive count mismatch"
  [[ "${negative_cases}" -eq 8 ]] ||
    fail "I09 runtime rebaseline negative count mismatch"
  printf '%s\n' \
    "W1I09RuntimeRebaselineContractTests = PASS" \
    "W1I09RuntimeRebaselinePositiveCases = ${positive_cases}" \
    "W1I09RuntimeRebaselineNegativeCases = ${negative_cases}"
}

i09_runtime_rebaseline_rejected_sha="40bd055047479db91d618320f1ff569e3c651c77"
i09_runtime_rebaseline_repair_sha="2046b0040c1acb43ccde7ef6098ca8acf840b286"
i09_runtime_rebaseline_repair_test_sha="80937ffc99d88fb125f0fe1c99e93120ad1200ec"
i09_runtime_rebaseline_rejected_repair_tip_sha="1544af3407d94b57bc6390f3e8a6e55cd056abdf"
i09_runtime_rebaseline_repair_path="docs/superpowers/specs/2026-08-22-cognitura-w1-i09-runtime-rebaseline-review-finding-repair.md"
i09_runtime_rebaseline_projection_paths=(
  docs/engineering/cognitura-technology-baseline.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md
)

new_i09_runtime_rebaseline_repair_fixture() {
  local fixture_root="$1"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    "${i09_runtime_rebaseline_rejected_sha}"
}

materialize_i09_runtime_rebaseline_repair() {
  local fixture_root="$1"
  local mutation="${2:-NONE}"
  commit_i09_runtime_rebaseline_file "${fixture_root}" \
    "${i09_runtime_rebaseline_repair_sha}" \
    "${i09_runtime_rebaseline_repair_path}" \
    "docs: define W1-I09 rebaseline finding repair"
  if [[ "${mutation}" == WRONG_REPAIR_EVIDENCE ]]; then
    printf '%s\n' 'RepairEvidenceDrift = YES' >> \
      "${fixture_root}/${i09_runtime_rebaseline_repair_path}"
    git -C "${fixture_root}" add "${i09_runtime_rebaseline_repair_path}"
    git -C "${fixture_root}" commit --amend -qm \
      "docs: define W1-I09 rebaseline finding repair"
  fi
  commit_i09_runtime_rebaseline_file "${fixture_root}" \
    "${i09_runtime_rebaseline_repair_test_sha}" \
    "${i09_runtime_rebaseline_test_path}" \
    "test: close W1-I09 rebaseline review findings"
  commit_i09_runtime_rebaseline_file "${fixture_root}" \
    "${i09_runtime_rebaseline_rejected_repair_tip_sha}" \
    "${i09_runtime_rebaseline_verifier_path}" \
    "build: close W1-I09 rebaseline review findings"
  if ! cmp -s "${fixture_root}/${i09_runtime_rebaseline_verifier_path}" \
      "${repo_root}/${i09_runtime_rebaseline_verifier_path}"; then
    commit_i09_runtime_rebaseline_file "${fixture_root}" WORKTREE \
      "${i09_runtime_rebaseline_verifier_path}" \
      "fix: close W1-I09 runtime boundary findings"
  fi
}

extract_i09_runtime_canonical_card() {
  local source_file="$1"
  local destination="$2"
  awk '
    /^I09_CANONICAL_CARD_BEGIN$/ { capture=1; next }
    /^I09_CANONICAL_CARD_END$/ { capture=0; exit }
    capture { print }
  ' "${source_file}" > "${destination}"
}

make_i09_runtime_rebaseline_projection() {
  local fixture_root="$1"
  local correction_tip="$2"
  local correction_parent correction_tree
  correction_parent="$(git -C "${fixture_root}" rev-parse "${correction_tip}^")"
  correction_tree="$(git -C "${fixture_root}" rev-parse "${correction_tip}^{tree}")"
  printf '%s\n' \
    '' \
    '## 10. Wave 1 source binary provider decision' \
    '' \
    '```text' \
    'W1SourceBinaryStorageProvider = LOCAL_CONTENT_ADDRESSED_FILESYSTEM' \
    'W1SourceBinaryProviderScope = SOURCE_BINARY_ONLY' \
    'W1SourceBinaryProviderAuthority = W1_I09_RUNTIME_REBASELINE' \
    'FormalDatabaseWrite = NOT_AUTHORIZED' \
    'RemotePush = NOT_AUTHORIZED' \
    '```' >> \
    "${fixture_root}/docs/engineering/cognitura-technology-baseline.md"
  printf '%s\n' \
    '' \
    '## 16. W1-I09 runtime rebaseline' \
    '' \
    '```text' \
    'W1I09RuntimeRebaseline = PASS' \
    'W1I09RuntimeBoundary = SOURCE_COMMAND_RUNTIME' \
    'W1I09ProductWriteSetCount = 27' \
    'ActiveTaskCard = W1-I09' \
    '```' >> "${fixture_root}/docs/engineering/cognitura-design-index.md"
  printf '%s\n' \
    '' \
    '## 8. W1-I09 runtime rebaseline acceptance' \
    '' \
    '```text' \
    'W1I09RuntimeRebaseline = PASS' \
    'ObjectStorageProvider = LOCAL_CONTENT_ADDRESSED_FILESYSTEM' \
    'I09FormalDatabaseGate = PASS' \
    'FormalDatabaseWrite = NOT_AUTHORIZED' \
    'RemotePush = NOT_AUTHORIZED' \
    '```' >> \
    "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md"
  printf '%s\n' \
    '' \
    '## 16. W1-I09 runtime rebaseline receipt' \
    '' \
    '```text' \
    'W1I09RuntimeRebaseline = PASS' \
    "ReviewedRejectedCandidate = ${i09_runtime_rebaseline_rejected_sha}" \
    "ReviewedVerifierCorrectionCandidate = ${correction_tip}" \
    "ReviewedVerifierCorrectionParent = ${correction_parent}" \
    "ReviewedVerifierCorrectionTree = ${correction_tree}" \
    'ReviewLevel = L3' \
    'ReviewRoute = deep_reviewer' \
    'ReviewEffort = xhigh' \
    'ReviewMultiplicity = ONE' \
    'ReviewVerdict = GO' \
    'P0 = 0' \
    'P1 = 0' \
    'P2 = 0' \
    'Ultra = NOT_RUN' \
    'ActiveTaskCard = W1-I09' \
    'TaskCardCount = 14' \
    'ReadyTaskCardCount = 1' \
    'I09ProductWriteSetCount = 27' \
    'FormalDatabaseWrite = NOT_AUTHORIZED' \
    'RemotePush = NOT_AUTHORIZED' \
    '```' >> \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  extract_i09_runtime_canonical_card \
    "${fixture_root}/${i09_runtime_rebaseline_repair_path}" \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md"
}

commit_i09_runtime_rebaseline_projection() {
  local fixture_root="$1"
  local correction_tip="$2"
  make_i09_runtime_rebaseline_projection "${fixture_root}" "${correction_tip}"
  git -C "${fixture_root}" add \
    "${i09_runtime_rebaseline_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm \
    "docs: project W1-I09 real command runtime"
}

run_w1_i09_runtime_rebaseline_repair_contract() {
  local fixture_root correction_tip output
  local positive_cases=0 negative_cases=0

  fixture_root="${test_tmp_root}/w1-i09-repair-pending"
  new_i09_runtime_rebaseline_repair_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_repair "${fixture_root}"
  correction_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  output="$(run_i09_runtime_rebaseline_fixture_verifier "${fixture_root}")" ||
    fail "legal I09 repair tip was rejected: ${output}"
  assert_contains "${output}" \
    'W1I09RuntimeRebaselineStatus = PENDING_PROJECTION'
  positive_cases=$((positive_cases + 1))

  commit_i09_runtime_rebaseline_projection "${fixture_root}" "${correction_tip}"
  output="$(run_i09_runtime_rebaseline_fixture_verifier "${fixture_root}")" ||
    fail "legal I09 authority projection was rejected: ${output}"
  assert_contains "${output}" \
    'W1I09RuntimeRebaselineStatus = PASS'
  assert_contains "${output}" 'I09ProductWriteSetCount = 27'
  positive_cases=$((positive_cases + 1))

  mkdir -p "${fixture_root}/server/src/main/java/io/cognitura/source/application/command"
  printf '%s\n' 'package io.cognitura.source.application.command;' > \
    "${fixture_root}/server/src/main/java/io/cognitura/source/application/command/TrustedRequestContext.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/application/command/TrustedRequestContext.java
  git -C "${fixture_root}" commit -qm "test: add legal I09 product descendant"
  output="$(run_i09_runtime_rebaseline_fixture_verifier "${fixture_root}")" ||
    fail "legal I09 product descendant was rejected: ${output}"
  assert_contains "${output}" 'W1I09RuntimeRebaselineStatus = PASS'
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-repair-evidence"
  new_i09_runtime_rebaseline_repair_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_repair "${fixture_root}" WRONG_REPAIR_EVIDENCE
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_REPAIR_INVALID:evidence'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-repair-projection-extra"
  new_i09_runtime_rebaseline_repair_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_repair "${fixture_root}"
  correction_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i09_runtime_rebaseline_projection "${fixture_root}" "${correction_tip}"
  printf '%s\n' 'projection drift' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add \
    "${i09_runtime_rebaseline_projection_paths[@]}" README.md
  git -C "${fixture_root}" commit -qm "test: expand I09 authority projection"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PROJECTION_INVALID:exact paths'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-repair-receipt"
  new_i09_runtime_rebaseline_repair_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_repair "${fixture_root}"
  correction_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i09_runtime_rebaseline_projection "${fixture_root}" "${correction_tip}"
  sed -i.bak 's/^ReviewVerdict = GO$/ReviewVerdict = NO_GO/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i09_runtime_rebaseline_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: drift I09 review receipt"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PROJECTION_INVALID:content'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-repair-db-auth"
  new_i09_runtime_rebaseline_repair_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_repair "${fixture_root}"
  correction_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i09_runtime_rebaseline_projection "${fixture_root}" "${correction_tip}"
  sed -i.bak 's/^FormalDatabaseWrite = NOT_AUTHORIZED$/FormalDatabaseWrite = AUTHORIZED/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i09_runtime_rebaseline_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: authorize I09 formal database"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PROJECTION_INVALID:content'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-repair-card"
  new_i09_runtime_rebaseline_repair_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_repair "${fixture_root}"
  correction_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i09_runtime_rebaseline_projection "${fixture_root}" "${correction_tip}"
  sed -i.bak 's/^ProductionFileLimit = 19$/ProductionFileLimit = 20/' \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md"
  rm "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md.bak"
  git -C "${fixture_root}" add "${i09_runtime_rebaseline_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: drift I09 exact WriteSet"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PROJECTION_INVALID:content'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-repair-i08-drift"
  new_i09_runtime_rebaseline_repair_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_repair "${fixture_root}"
  correction_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  commit_i09_runtime_rebaseline_projection "${fixture_root}" "${correction_tip}"
  printf '%s\n' '// forbidden I08 drift' >> \
    "${fixture_root}/server/src/main/java/io/cognitura/source/reference/StableSourceReference.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/reference/StableSourceReference.java
  git -C "${fixture_root}" commit -qm "test: drift frozen I08 product"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_I08_DRIFT'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-repair-product-outside"
  new_i09_runtime_rebaseline_repair_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_repair "${fixture_root}"
  correction_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  commit_i09_runtime_rebaseline_projection "${fixture_root}" "${correction_tip}"
  printf '%s\n' 'outside product drift' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add README.md
  git -C "${fixture_root}" commit -qm "test: exceed I09 product WriteSet"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PRODUCT_INVALID:path'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-repair-formal-location"
  new_i09_runtime_rebaseline_repair_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_repair "${fixture_root}"
  correction_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  commit_i09_runtime_rebaseline_projection "${fixture_root}" "${correction_tip}"
  printf '%s\n' 'spring.datasource.url: jdbc:postgresql://formal-db/cognitura' >> \
    "${fixture_root}/server/src/main/resources/application.yaml"
  git -C "${fixture_root}" add server/src/main/resources/application.yaml
  git -C "${fixture_root}" commit -qm "test: add formal database location"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_FORMAL_DATABASE_LOCATION'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-repair-formal-large-java"
  new_i09_runtime_rebaseline_repair_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_repair "${fixture_root}"
  correction_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  commit_i09_runtime_rebaseline_projection "${fixture_root}" "${correction_tip}"
  mkdir -p \
    "${fixture_root}/server/src/main/java/io/cognitura/source/runtime"
  printf '%s\n' \
    'package io.cognitura.source.runtime;' \
    'final class SourceCommandRuntimeConfiguration {' \
    '  static final String URL = "jdbc:postgresql://formal-db/cognitura";' \
    '}' > \
    "${fixture_root}/server/src/main/java/io/cognitura/source/runtime/SourceCommandRuntimeConfiguration.java"
  awk 'BEGIN { for (i = 0; i < 200000; i++) print "// padding " i }' >> \
    "${fixture_root}/server/src/main/java/io/cognitura/source/runtime/SourceCommandRuntimeConfiguration.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/runtime/SourceCommandRuntimeConfiguration.java
  git -C "${fixture_root}" commit -qm \
    "test: add formal database location in large Java blob"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_FORMAL_DATABASE_LOCATION'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-repair-formal-java"
  new_i09_runtime_rebaseline_repair_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_repair "${fixture_root}"
  correction_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  commit_i09_runtime_rebaseline_projection "${fixture_root}" "${correction_tip}"
  mkdir -p \
    "${fixture_root}/server/src/main/java/io/cognitura/source/runtime"
  printf '%s\n' \
    'package io.cognitura.source.runtime;' \
    'final class SourceCommandRuntimeConfiguration {' \
    '  static final String URL = "jdbc:postgresql://formal-db/cognitura";' \
    '}' > \
    "${fixture_root}/server/src/main/java/io/cognitura/source/runtime/SourceCommandRuntimeConfiguration.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/runtime/SourceCommandRuntimeConfiguration.java
  git -C "${fixture_root}" commit -qm \
    "test: add formal database location in Java"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_FORMAL_DATABASE_LOCATION'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-repair-push-auth"
  new_i09_runtime_rebaseline_repair_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_repair "${fixture_root}"
  correction_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i09_runtime_rebaseline_projection "${fixture_root}" "${correction_tip}"
  sed -i.bak \
    's/^RemotePush = NOT_AUTHORIZED$/RemotePush = AUTHORIZED/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i09_runtime_rebaseline_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: authorize I09 remote push"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PROJECTION_INVALID:content'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-repair-ready-status"
  new_i09_runtime_rebaseline_repair_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_repair "${fixture_root}"
  correction_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i09_runtime_rebaseline_projection "${fixture_root}" "${correction_tip}"
  sed -i.bak 's/^Status = READY$/Status = QUEUED/' \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md"
  rm "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md.bak"
  git -C "${fixture_root}" add "${i09_runtime_rebaseline_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: remove unique I09 READY status"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PROJECTION_INVALID:content'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-repair-task-count"
  new_i09_runtime_rebaseline_repair_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_repair "${fixture_root}"
  correction_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i09_runtime_rebaseline_projection "${fixture_root}" "${correction_tip}"
  sed -i.bak 's/^TaskCardCount = 14$/TaskCardCount = 15/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i09_runtime_rebaseline_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: drift I09 task-card count"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PROJECTION_INVALID:content'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-repair-ready-count"
  new_i09_runtime_rebaseline_repair_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_repair "${fixture_root}"
  correction_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i09_runtime_rebaseline_projection "${fixture_root}" "${correction_tip}"
  sed -i.bak 's/^ReadyTaskCardCount = 1$/ReadyTaskCardCount = 2/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i09_runtime_rebaseline_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: drift I09 READY count"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PROJECTION_INVALID:content'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-repair-raw"
  new_i09_runtime_rebaseline_repair_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_repair "${fixture_root}"
  correction_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  commit_i09_runtime_rebaseline_projection "${fixture_root}" "${correction_tip}"
  mkdir -p "${fixture_root}/raw"
  printf '%s\n' 'forbidden' > "${fixture_root}/raw/i09.txt"
  git -C "${fixture_root}" add raw/i09.txt
  git -C "${fixture_root}" commit -qm "test: write raw during I09"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PRODUCT_INVALID:path'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-repair-post-card"
  new_i09_runtime_rebaseline_repair_fixture "${fixture_root}"
  materialize_i09_runtime_rebaseline_repair "${fixture_root}"
  correction_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  commit_i09_runtime_rebaseline_projection "${fixture_root}" "${correction_tip}"
  printf '%s\n' 'WriteSet = server/src/main/java/io/cognitura/Unexpected.java' >> \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md"
  git -C "${fixture_root}" add \
    docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md
  git -C "${fixture_root}" commit -qm "test: mutate projected I09 card"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PRODUCT_INVALID:path'
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 3 ]] ||
    fail "I09 runtime repair positive count mismatch"
  [[ "${negative_cases}" -eq 16 ]] ||
    fail "I09 runtime repair negative count mismatch"
  printf '%s\n' \
    'W1I09RuntimeRebaselineRepairContractTests = PASS' \
    "W1I09RuntimeRebaselineRepairPositiveCases = ${positive_cases}" \
    "W1I09RuntimeRebaselineRepairNegativeCases = ${negative_cases}"
}

if [[ "${w1_i08_closure_contract_only}" == "1" ]]; then
  run_w1_i08_closure_contract
  exit 0
fi

if [[ "${w1_i09_runtime_rebaseline_contract_only}" == "1" ]]; then
  run_w1_i09_runtime_rebaseline_repair_contract
  exit 0
fi

i09_fixed_runtime_candidate_sha="eab57ecc86b675b4b725d6d9506338282dbae9a7"

new_i09_fixed_runtime_fixture() {
  local fixture_root="$1"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${i09_fixed_runtime_candidate_sha}"
}

materialize_i09_substituted_product_candidate() {
  local fixture_root="$1"
  local mutation="${2:-IDENTITY_ONLY}"
  local path
  for path in $(git -C "${repo_root}" diff --name-only \
      1732c6821d93bcc9f121ba221adff2d137ffd6d0..c934ff7a10a30ed58584d2e5eb0654d2161add70); do
    mkdir -p "${fixture_root}/${path%/*}"
    git -C "${repo_root}" show \
      "c934ff7a10a30ed58584d2e5eb0654d2161add70:${path}" > \
      "${fixture_root}/${path}"
    git -C "${fixture_root}" add "${path}"
  done
  if [[ "${mutation}" == "SOURCE_DRIFT" ]]; then
    printf '%s\n' '// forbidden fixed-copy source drift' >> \
      "${fixture_root}/server/src/main/java/io/cognitura/source/persistence/SourceDocumentMapper.java"
    printf '%s\n' '-- forbidden fixed-copy source drift' >> \
      "${fixture_root}/server/src/test/resources/db/source-persistence-fixture.sql"
    git -C "${fixture_root}" add \
      server/src/main/java/io/cognitura/source/persistence/SourceDocumentMapper.java \
      server/src/test/resources/db/source-persistence-fixture.sql
  fi
  git -C "${fixture_root}" commit -qm \
    "test: substitute fixed I09 product candidate"
}

run_w1_i09_product_copy_inference_contract() {
  local fixture_root output status
  local positive_cases=0 negative_cases=0

  status="$(git -C "${repo_root}" -c diff.renameLimit=0 diff-tree \
    --no-commit-id --name-status -r -M -C --find-copies-harder \
    c934ff7a10a30ed58584d2e5eb0654d2161add70^ \
    c934ff7a10a30ed58584d2e5eb0654d2161add70)"
  assert_contains "${status}" $'C051\tserver/src/main/java/io/cognitura/source/persistence/SourceDocumentMapper.java\tserver/src/main/java/io/cognitura/source/persistence/SourceCommandMapper.java'
  assert_contains "${status}" $'C077\tserver/src/test/resources/db/source-persistence-fixture.sql\tserver/src/test/resources/db/source-command-runtime-fixture.sql'
  fixture_root="${test_tmp_root}/w1-i09-copy-fixed-candidate"
  new_i09_fixed_runtime_fixture "${fixture_root}"
  output="$(run_i09_runtime_rebaseline_fixture_verifier "${fixture_root}")" ||
    fail "fixed I09 inferred-copy repair was rejected: ${output}"
  assert_contains "${output}" 'W1I09RuntimeRebaselineStatus = PASS'
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-copy-legal-descendant"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${i09_fixed_runtime_candidate_sha}"
  printf '%s\n' '// legal post-repair I09 product descendant' >> \
    "${fixture_root}/server/src/main/java/io/cognitura/source/application/command/SourceCommandService.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/application/command/SourceCommandService.java
  git -C "${fixture_root}" commit -qm "test: add legal post-repair I09 product"
  output="$(run_i09_runtime_rebaseline_fixture_verifier "${fixture_root}")" ||
    fail "legal I09 product descendant after copy repair was rejected: ${output}"
  assert_contains "${output}" 'W1I09RuntimeRebaselineStatus = PASS'
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-copy-extra"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${i09_fixed_runtime_candidate_sha}"
  cp "${fixture_root}/server/src/main/java/io/cognitura/source/persistence/SourceCommandMapper.java" \
    "${fixture_root}/server/src/main/java/io/cognitura/source/persistence/UnexpectedCopy.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/persistence/UnexpectedCopy.java
  git -C "${fixture_root}" commit -qm "test: add forbidden I09 inferred copy"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PRODUCT_INVALID:rename or copy'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-copy-rename"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${i09_fixed_runtime_candidate_sha}"
  git -C "${fixture_root}" mv \
    server/src/main/java/io/cognitura/source/application/command/SourceCommandException.java \
    server/src/main/java/io/cognitura/source/application/command/RenamedSourceCommandException.java
  git -C "${fixture_root}" commit -qm "test: rename I09 product path"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PRODUCT_INVALID:rename or copy'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-copy-outside"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${i09_fixed_runtime_candidate_sha}"
  printf '%s\n' 'forbidden post-repair drift' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add README.md
  git -C "${fixture_root}" commit -qm "test: exceed I09 product WriteSet after copy repair"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PRODUCT_INVALID:path'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-copy-substituted-identity"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    1732c6821d93bcc9f121ba221adff2d137ffd6d0
  materialize_i09_substituted_product_candidate "${fixture_root}"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PRODUCT_INVALID:rename or copy'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-copy-source-drift"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    1732c6821d93bcc9f121ba221adff2d137ffd6d0
  materialize_i09_substituted_product_candidate "${fixture_root}" SOURCE_DRIFT
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PRODUCT_INVALID:rename or copy'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-copy-spec-evidence"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    c934ff7a10a30ed58584d2e5eb0654d2161add70
  mkdir -p \
    "${fixture_root}/docs/superpowers/specs"
  git -C "${repo_root}" show \
    8b26b59bc758c3895540e4ceffa295c1e5366a3d:docs/superpowers/specs/2026-08-22-cognitura-w1-i09-product-copy-inference-repair.md > \
    "${fixture_root}/docs/superpowers/specs/2026-08-22-cognitura-w1-i09-product-copy-inference-repair.md"
  printf '%s\n' 'RepairEvidenceDrift = YES' >> \
    "${fixture_root}/docs/superpowers/specs/2026-08-22-cognitura-w1-i09-product-copy-inference-repair.md"
  git -C "${fixture_root}" add \
    docs/superpowers/specs/2026-08-22-cognitura-w1-i09-product-copy-inference-repair.md
  git -C "${fixture_root}" commit -qm "test: drift I09 copy repair spec evidence"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_PRODUCT_COPY_REPAIR_INVALID:order'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-copy-verifier-reentry"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${i09_fixed_runtime_candidate_sha}"
  printf '%s\n' '# forbidden verifier reentry after fixed repair' >> \
    "${fixture_root}/scripts/verify-wave1-implementation-cards"
  git -C "${fixture_root}" add scripts/verify-wave1-implementation-cards
  git -C "${fixture_root}" commit -qm "test: reenter I09 copy repair verifier"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PRODUCT_INVALID:path'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-copy-test-evidence"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    8b26b59bc758c3895540e4ceffa295c1e5366a3d
  git -C "${repo_root}" show \
    bd5f49fa62e47c45559feb0b64ea73a5c3ee0532:tests/task-cards/verify-wave1-implementation-cards.sh > \
    "${fixture_root}/tests/task-cards/verify-wave1-implementation-cards.sh"
  printf '%s\n' '# RepairEvidenceDrift = YES' >> \
    "${fixture_root}/tests/task-cards/verify-wave1-implementation-cards.sh"
  chmod 755 \
    "${fixture_root}/tests/task-cards/verify-wave1-implementation-cards.sh"
  git -C "${fixture_root}" add tests/task-cards/verify-wave1-implementation-cards.sh
  git -C "${fixture_root}" commit -qm "test: drift I09 copy repair test evidence"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_PRODUCT_COPY_REPAIR_INVALID:order'
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 2 ]] ||
    fail "I09 product copy-inference positive count mismatch"
  [[ "${negative_cases}" -eq 8 ]] ||
    fail "I09 product copy-inference negative count mismatch"
  printf '%s\n' \
    'W1I09ProductCopyInferenceContractTests = PASS' \
    "W1I09ProductCopyInferencePositiveCases = ${positive_cases}" \
    "W1I09ProductCopyInferenceNegativeCases = ${negative_cases}"
}

if [[ "${w1_i09_product_copy_inference_contract_only}" == "1" ]]; then
  run_w1_i09_product_copy_inference_contract
  exit 0
fi

materialize_fixed_i09_canonical_bridge_projection() {
  local fixture_root="$1"
  local path
  for path in \
      docs/engineering/cognitura-design-index.md \
      docs/engineering/cognitura-wave-1-implementation-plan.md \
      docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md; do
    mkdir -p "${fixture_root}/${path%/*}"
    git -C "${repo_root}" show \
      "90a77d73f1389593930d8fbd468f0f06238b1c1b:${path}" > \
      "${fixture_root}/${path}"
  done
}

commit_fixed_i09_canonical_bridge_projection() {
  local fixture_root="$1"
  git -C "${fixture_root}" add \
    docs/engineering/cognitura-design-index.md \
    docs/engineering/cognitura-wave-1-implementation-plan.md \
    docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md
  git -C "${fixture_root}" commit -qm \
    "docs: project I09 canonical bytes bridge"
}

run_w1_i09_canonical_bridge_contract() {
  local fixture_root output
  local positive_cases=0 negative_cases=0

  fixture_root="${test_tmp_root}/w1-i09-canonical-fixed-candidate"
  new_i09_fixed_runtime_fixture "${fixture_root}"
  output="$(run_i09_runtime_rebaseline_fixture_verifier "${fixture_root}")" ||
    fail "fixed I09 canonical bridge was rejected: ${output}"
  assert_contains "${output}" 'W1I09RuntimeRebaselineStatus = PASS'
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-canonical-bridge-legal"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    90a77d73f1389593930d8fbd468f0f06238b1c1b
  sed -i.bak \
    -e 's/^    byte\[\] canonicalOmissionsBytes()/    public byte[] canonicalOmissionsBytes()/' \
    -e 's/^    byte\[\] canonicalRevisionDiagnosticsBytes()/    public byte[] canonicalRevisionDiagnosticsBytes()/' \
    "${fixture_root}/server/src/main/java/io/cognitura/source/application/processing/CandidateBlockSet.java"
  rm "${fixture_root}/server/src/main/java/io/cognitura/source/application/processing/CandidateBlockSet.java.bak"
  awk '
    $0 == "    public static final class Block {" { in_block = 1 }
    in_block && $0 == "        byte[] canonicalBytes() {" {
      print "        public byte[] canonicalBytes() {"
      replaced++
      next
    }
    { print }
    END { if (replaced != 1) exit 1 }
  ' "${fixture_root}/server/src/main/java/io/cognitura/source/application/processing/CandidateBlockSet.java" > \
    "${fixture_root}/CandidateBlockSet.java.bridge"
  mv "${fixture_root}/CandidateBlockSet.java.bridge" \
    "${fixture_root}/server/src/main/java/io/cognitura/source/application/processing/CandidateBlockSet.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/application/processing/CandidateBlockSet.java
  git -C "${fixture_root}" commit -qm "test: add legal canonical bytes bridge"
  output="$(run_i09_runtime_rebaseline_fixture_verifier "${fixture_root}")" ||
    fail "legal I09 canonical bridge product was rejected: ${output}"
  assert_contains "${output}" 'I09ProductWriteSetCount = 28'
  positive_cases=$((positive_cases + 1))

  printf '%s\n' '// forbidden second bridge drift' >> \
    "${fixture_root}/server/src/main/java/io/cognitura/source/application/processing/CandidateBlockSet.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/application/processing/CandidateBlockSet.java
  git -C "${fixture_root}" commit -qm "test: drift canonical bridge twice"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_CANONICAL_BRIDGE_PRODUCT_INVALID'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-canonical-bridge-extra-semantics"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    90a77d73f1389593930d8fbd468f0f06238b1c1b
  sed -i.bak \
    's/^    byte\[\] canonicalOmissionsBytes()/    public byte[] canonicalOmissionsBytes()/' \
    "${fixture_root}/server/src/main/java/io/cognitura/source/application/processing/CandidateBlockSet.java"
  rm "${fixture_root}/server/src/main/java/io/cognitura/source/application/processing/CandidateBlockSet.java.bak"
  printf '%s\n' '// extra semantic drift' >> \
    "${fixture_root}/server/src/main/java/io/cognitura/source/application/processing/CandidateBlockSet.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/application/processing/CandidateBlockSet.java
  git -C "${fixture_root}" commit -qm "test: add invalid canonical bridge"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_CANONICAL_BRIDGE_PRODUCT_INVALID'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-canonical-bridge-governance-reentry"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${i09_fixed_runtime_candidate_sha}"
  printf '%s\n' '# forbidden governance reentry' >> \
    "${fixture_root}/scripts/verify-wave1-implementation-cards"
  git -C "${fixture_root}" add scripts/verify-wave1-implementation-cards
  git -C "${fixture_root}" commit -qm "test: reenter bridge governance"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PRODUCT_INVALID:path'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-canonical-bridge-outside"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${i09_fixed_runtime_candidate_sha}"
  printf '%s\n' 'forbidden bridge successor' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add README.md
  git -C "${fixture_root}" commit -qm "test: exceed bridge product WriteSet"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PRODUCT_INVALID:path'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-canonical-bridge-missing-projection"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    2bdc9f7e04306b397dda07b7511f4e0bf831eeab
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_CANONICAL_BRIDGE_PROJECTION_INVALID:missing'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-canonical-bridge-wrong-count"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    2bdc9f7e04306b397dda07b7511f4e0bf831eeab
  materialize_fixed_i09_canonical_bridge_projection "${fixture_root}"
  sed -i.bak 's/^W1I09ProductWriteSetCount = 28$/W1I09ProductWriteSetCount = 29/' \
    "${fixture_root}/docs/engineering/cognitura-design-index.md"
  rm "${fixture_root}/docs/engineering/cognitura-design-index.md.bak"
  sed -i.bak 's/^ProductionFileLimit = 20$/ProductionFileLimit = 21/' \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md"
  rm "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md.bak"
  commit_fixed_i09_canonical_bridge_projection "${fixture_root}"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_CANONICAL_BRIDGE_PROJECTION_INVALID:content'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-canonical-bridge-extra-writeset"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    2bdc9f7e04306b397dda07b7511f4e0bf831eeab
  materialize_fixed_i09_canonical_bridge_projection "${fixture_root}"
  printf '%s\n' \
    'WriteSet = server/src/main/java/io/cognitura/source/application/command/Undeclared.java' >> \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md"
  commit_fixed_i09_canonical_bridge_projection "${fixture_root}"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_CANONICAL_BRIDGE_PROJECTION_INVALID:content'
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 2 ]] || fail "I09 canonical bridge positive count mismatch"
  [[ "${negative_cases}" -eq 7 ]] || fail "I09 canonical bridge negative count mismatch"
  printf '%s\n' \
    'W1I09CanonicalBridgeContractTests = PASS' \
    "W1I09CanonicalBridgePositiveCases = ${positive_cases}" \
    "W1I09CanonicalBridgeNegativeCases = ${negative_cases}"
}

if [[ "${w1_i09_canonical_bridge_contract_only}" == "1" ]]; then
  run_w1_i09_canonical_bridge_contract
  exit 0
fi

find_fixed_i09_v2_compatibility_projection() {
  local commit parent actual expected found=""
  expected="$(printf '%s\n' \
    docs/engineering/cognitura-design-index.md \
    docs/engineering/cognitura-wave-1-implementation-plan.md \
    docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md |
    LC_ALL=C sort)"
  for commit in $(git -C "${repo_root}" rev-list --first-parent --reverse \
      22c0ff2e0dde71fa71a5e6a030f841c99ac4b655..HEAD); do
    parent="$(git -C "${repo_root}" rev-parse "${commit}^")"
    actual="$(git -C "${repo_root}" diff --name-only \
      "${parent}..${commit}" | LC_ALL=C sort)"
    if [[ "${actual}" == "${expected}" ]] &&
        git -C "${repo_root}" show \
          "${commit}:docs/engineering/cognitura-design-index.md" |
          grep -Fxq 'W1I09ProductWriteSetCount = 29'; then
      [[ -z "${found}" ]] || fail "duplicate I09 V2 compatibility projection"
      found="${commit}"
    fi
  done
  [[ -n "${found}" ]] || fail "fixed I09 V2 compatibility projection is unavailable"
  printf '%s\n' "${found}"
}

materialize_fixed_i09_v2_compatibility_projection() {
  local fixture_root="$1"
  local projection="$2"
  local path
  for path in \
      docs/engineering/cognitura-design-index.md \
      docs/engineering/cognitura-wave-1-implementation-plan.md \
      docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md; do
    git -C "${repo_root}" show "${projection}:${path}" > \
      "${fixture_root}/${path}"
  done
}

commit_fixed_i09_v2_compatibility_projection() {
  local fixture_root="$1"
  git -C "${fixture_root}" add \
    docs/engineering/cognitura-design-index.md \
    docs/engineering/cognitura-wave-1-implementation-plan.md \
    docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md
  git -C "${fixture_root}" commit -qm "docs: project I09 V2 compatibility"
}

run_w1_i09_v2_compatibility_contract() {
  local fixture_root output projection projection_parent fixture_verifier
  local positive_cases=0 negative_cases=0
  projection="$(find_fixed_i09_v2_compatibility_projection)"
  projection_parent="$(git -C "${repo_root}" rev-parse "${projection}^")"

  fixture_root="${test_tmp_root}/w1-i09-v2-fixed-candidate"
  new_i09_fixed_runtime_fixture "${fixture_root}"
  output="$(run_i09_runtime_rebaseline_fixture_verifier "${fixture_root}")" ||
    fail "fixed I09 V2 compatibility was rejected: ${output}"
  assert_contains "${output}" 'W1I09RuntimeRebaselineStatus = PASS'
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-v2-compatibility-legal"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${projection}"
  sed -i.bak \
    's/assertThat(flyway.migrate().migrationsExecuted).isEqualTo(1);/assertThat(flyway.migrate().migrationsExecuted).isEqualTo(2);/' \
    "${fixture_root}/server/src/test/java/io/cognitura/source/persistence/SourcePersistenceIntegrationTest.java"
  rm "${fixture_root}/server/src/test/java/io/cognitura/source/persistence/SourcePersistenceIntegrationTest.java.bak"
  git -C "${fixture_root}" add \
    server/src/test/java/io/cognitura/source/persistence/SourcePersistenceIntegrationTest.java
  git -C "${fixture_root}" commit -qm "test: accept two I09 migrations in I02 regression"
  output="$(run_i09_runtime_rebaseline_fixture_verifier "${fixture_root}")" ||
    fail "legal I09 V2 compatibility product was rejected: ${output}"
  assert_contains "${output}" 'I09ProductWriteSetCount = 29'
  positive_cases=$((positive_cases + 1))

  printf '%s\n' '// forbidden second compatibility drift' >> \
    "${fixture_root}/server/src/test/java/io/cognitura/source/persistence/SourcePersistenceIntegrationTest.java"
  git -C "${fixture_root}" add \
    server/src/test/java/io/cognitura/source/persistence/SourcePersistenceIntegrationTest.java
  git -C "${fixture_root}" commit -qm "test: drift compatibility twice"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_V2_COMPATIBILITY_PRODUCT_INVALID'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-v2-compatibility-extra"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${projection}"
  printf '%s\n' '// extra semantic drift' >> \
    "${fixture_root}/server/src/test/java/io/cognitura/source/persistence/SourcePersistenceIntegrationTest.java"
  git -C "${fixture_root}" add \
    server/src/test/java/io/cognitura/source/persistence/SourcePersistenceIntegrationTest.java
  git -C "${fixture_root}" commit -qm "test: add invalid V2 compatibility"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_V2_COMPATIBILITY_PRODUCT_INVALID'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-v2-compatibility-wrong-count"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${projection_parent}"
  materialize_fixed_i09_v2_compatibility_projection "${fixture_root}" "${projection}"
  sed -i.bak 's/^W1I09ProductWriteSetCount = 29$/W1I09ProductWriteSetCount = 30/' \
    "${fixture_root}/docs/engineering/cognitura-design-index.md"
  rm "${fixture_root}/docs/engineering/cognitura-design-index.md.bak"
  commit_fixed_i09_v2_compatibility_projection "${fixture_root}"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_V2_COMPATIBILITY_PROJECTION_INVALID:content'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-v2-compatibility-extra-writeset"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${projection_parent}"
  materialize_fixed_i09_v2_compatibility_projection "${fixture_root}" "${projection}"
  printf '%s\n' 'WriteSet = server/src/test/java/io/cognitura/UndeclaredTest.java' >> \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md"
  commit_fixed_i09_v2_compatibility_projection "${fixture_root}"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_V2_COMPATIBILITY_PROJECTION_INVALID:content'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-v2-compatibility-governance-reentry"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${i09_fixed_runtime_candidate_sha}"
  printf '%s\n' '# forbidden V2 governance reentry' >> \
    "${fixture_root}/scripts/verify-wave1-implementation-cards"
  git -C "${fixture_root}" add scripts/verify-wave1-implementation-cards
  git -C "${fixture_root}" commit -qm "test: reenter V2 governance"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_RUNTIME_REBASELINE_PRODUCT_INVALID:path'
  negative_cases=$((negative_cases + 1))

  fixture_verifier="848f151a1248594f063a3f9665f1fecc0b42558c"
  [[ -n "${fixture_verifier}" ]] || fail "I09 post-product fixture verifier is unavailable"

  fixture_root="${test_tmp_root}/w1-i09-post-product-fixture-legal"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${fixture_verifier}"
  sed -i.bak \
    's#new ClassPathResource("db/source-persistence-fixture.sql")#new ClassPathResource("db/source-command-runtime-fixture.sql")#' \
    "${fixture_root}/server/src/test/java/io/cognitura/source/persistence/SourcePersistenceIntegrationTest.java"
  rm "${fixture_root}/server/src/test/java/io/cognitura/source/persistence/SourcePersistenceIntegrationTest.java.bak"
  git -C "${fixture_root}" add \
    server/src/test/java/io/cognitura/source/persistence/SourcePersistenceIntegrationTest.java
  git -C "${fixture_root}" commit -qm "test: reset I02 facts through complete V2 fixture"
  output="$(run_i09_runtime_rebaseline_fixture_verifier "${fixture_root}")" ||
    fail "legal post-product fixture repair was rejected: ${output}"
  assert_contains "${output}" 'I09ProductWriteSetCount = 29'
  positive_cases=$((positive_cases + 1))

  printf '%s\n' '// forbidden fixture drift' >> \
    "${fixture_root}/server/src/test/java/io/cognitura/source/persistence/SourcePersistenceIntegrationTest.java"
  git -C "${fixture_root}" add \
    server/src/test/java/io/cognitura/source/persistence/SourcePersistenceIntegrationTest.java
  git -C "${fixture_root}" commit -qm "test: drift fixture repair twice"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_POST_PRODUCT_FIXTURE_INVALID'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-post-product-fixture-extra"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${fixture_verifier}"
  printf '%s\n' '// extra fixture semantics' >> \
    "${fixture_root}/server/src/test/java/io/cognitura/source/persistence/SourcePersistenceIntegrationTest.java"
  git -C "${fixture_root}" add \
    server/src/test/java/io/cognitura/source/persistence/SourcePersistenceIntegrationTest.java
  git -C "${fixture_root}" commit -qm "test: add invalid fixture repair"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_POST_PRODUCT_FIXTURE_INVALID'
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 3 ]] || fail "I09 V2 compatibility positive count mismatch"
  [[ "${negative_cases}" -eq 7 ]] || fail "I09 V2 compatibility negative count mismatch"
  printf '%s\n' \
    'W1I09V2CompatibilityContractTests = PASS' \
    "W1I09V2CompatibilityPositiveCases = ${positive_cases}" \
    "W1I09V2CompatibilityNegativeCases = ${negative_cases}"
}

if [[ "${w1_i09_v2_compatibility_contract_only}" == "1" ]]; then
  run_w1_i09_v2_compatibility_contract
  exit 0
fi

run_w1_i09_final_review_finding_contract() {
  local fixture_root output
  local positive_cases=0 negative_cases=0

  fixture_root="${test_tmp_root}/w1-i09-final-review-fixed"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    f0fa4aaee25b66d0e916683e2ed938dac5305c85
  output="$(run_i09_runtime_rebaseline_fixture_verifier "${fixture_root}")" ||
    fail "fixed rejected I09 candidate is not replayable: ${output}"
  assert_contains "${output}" 'W1I09RuntimeRebaselineStatus = PASS'
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-final-review-i08-substituted-verifier"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    3730eb5c71862f51659bd68e4066c392815d5cef
  git -C "${repo_root}" show \
    160fc8a0ab347c3a35a566e0d615a1ad70af7f24:scripts/verify-wave1-implementation-cards > \
    "${fixture_root}/scripts/verify-wave1-implementation-cards"
  printf '%s\n' '# substituted I08 fixture pin verifier' >> \
    "${fixture_root}/scripts/verify-wave1-implementation-cards"
  chmod 755 "${fixture_root}/scripts/verify-wave1-implementation-cards"
  git -C "${fixture_root}" add scripts/verify-wave1-implementation-cards
  git -C "${fixture_root}" commit -qm "test: substitute I08 fixture pin verifier"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_I08_FIXTURE_PIN_INVALID:verifier identity'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-final-review-v2-substituted-verifier"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    160fc8a0ab347c3a35a566e0d615a1ad70af7f24
  git -C "${repo_root}" show \
    665fbdb7929441afd0b81635e2ea5855ee86272f:scripts/verify-wave1-implementation-cards > \
    "${fixture_root}/scripts/verify-wave1-implementation-cards"
  printf '%s\n' '# substituted V2 fixture pin verifier' >> \
    "${fixture_root}/scripts/verify-wave1-implementation-cards"
  chmod 755 "${fixture_root}/scripts/verify-wave1-implementation-cards"
  git -C "${fixture_root}" add scripts/verify-wave1-implementation-cards
  git -C "${fixture_root}" commit -qm "test: substitute V2 fixture pin verifier"
  git -C "${repo_root}" show \
    f0fa4aaee25b66d0e916683e2ed938dac5305c85:tests/task-cards/verify-wave1-implementation-cards.sh > \
    "${fixture_root}/tests/task-cards/verify-wave1-implementation-cards.sh"
  chmod 755 "${fixture_root}/tests/task-cards/verify-wave1-implementation-cards.sh"
  git -C "${fixture_root}" add tests/task-cards/verify-wave1-implementation-cards.sh
  git -C "${fixture_root}" commit -qm "test: retain fixed V2 fixture evidence"
  expect_i09_runtime_rebaseline_failure "${fixture_root}" \
    'I09_V2_FIXTURE_PIN_INVALID:verifier identity'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-final-review-current-fixed-candidate"
  new_i09_fixed_runtime_fixture "${fixture_root}"
  output="$(run_i09_runtime_rebaseline_fixture_verifier "${fixture_root}")" ||
    fail "current I09 final review finding closure was rejected: ${output}"
  assert_contains "${output}" 'W1I09RuntimeRebaselineStatus = PASS'
  positive_cases=$((positive_cases + 1))

  [[ "${positive_cases}" -eq 2 ]] ||
    fail "I09 final review finding positive count mismatch"
  [[ "${negative_cases}" -eq 2 ]] ||
    fail "I09 final review finding negative count mismatch"
  printf '%s\n' \
    'W1I09FinalReviewFindingContractTests = PASS' \
    "W1I09FinalReviewFindingPositiveCases = ${positive_cases}" \
    "W1I09FinalReviewFindingNegativeCases = ${negative_cases}"
}

if [[ "${w1_i09_final_review_finding_contract_only}" == "1" ]]; then
  run_w1_i09_final_review_finding_contract
  exit 0
fi

i09_closure_origin_sha="eab57ecc86b675b4b725d6d9506338282dbae9a7"
i09_closure_reviewed_parent_sha="bbd4c1c2b30af1efa03aea11c97b1b1a21b183cd"
i09_closure_reviewed_tree_sha="c16a5da8605949d29cd09e316a8be5434ab7f8f4"
i09_closure_spec_sha="f0d04a6b798818d44785c7b593c8a767476e5e36"
i09_closure_original_test_sha="6d5c531e0fb4999e0b1ac26eba5a5dc5acb3d345"
i09_closure_repair_spec_sha="1e5b7a9892e3fe10e905ad8bb867aa071ef582c8"
i09_closure_repair_test_sha="cd6ef36bb20663c2b6465c43f2dbee01269e694c"
i09_closure_spec_path="docs/superpowers/specs/2026-08-22-cognitura-w1-i09-closure-design.md"
i09_closure_repair_spec_path="docs/superpowers/specs/2026-08-22-cognitura-w1-i09-closure-test-finding-repair.md"
i09_closure_test_path="tests/task-cards/verify-wave1-implementation-cards.sh"
i09_closure_verifier_path="scripts/verify-wave1-implementation-cards"
i09_closure_i09_card_path="docs/task-cards/wave-1-implementation/W1-I09-upload-processing-command-api.md"
i09_closure_i10_card_path="docs/task-cards/wave-1-implementation/W1-I10-source-preview-query-api.md"
i09_closure_projection_paths=(
  AGENTS.md
  README.md
  docs/design/wave-1/README.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-plan.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1/README.md
  docs/task-cards/wave-1-implementation/README.md
  "${i09_closure_i09_card_path}"
  "${i09_closure_i10_card_path}"
)

new_i09_closure_fixture() {
  local fixture_root="$1"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${i09_closure_origin_sha}"
}

materialize_i09_closure_governance() {
  local fixture_root="$1"
  local mutation="${2:-NONE}"
  mkdir -p "${fixture_root}/$(dirname "${i09_closure_spec_path}")"
  git -C "${repo_root}" show \
    "${i09_closure_spec_sha}:${i09_closure_spec_path}" > \
    "${fixture_root}/${i09_closure_spec_path}"
  git -C "${fixture_root}" add "${i09_closure_spec_path}"
  if [[ "${mutation}" == GOVERNANCE_EXTRA_PATH ]]; then
    printf '%s\n' 'I09 closure governance drift' >> "${fixture_root}/README.md"
    git -C "${fixture_root}" add README.md
  fi
  git -C "${fixture_root}" commit -qm "docs: define W1-I09 closure"

  git -C "${repo_root}" show \
    "${i09_closure_original_test_sha}:${i09_closure_test_path}" > \
    "${fixture_root}/${i09_closure_test_path}"
  chmod 755 "${fixture_root}/${i09_closure_test_path}"
  git -C "${fixture_root}" add "${i09_closure_test_path}"
  git -C "${fixture_root}" commit -qm "test: require W1-I09 closure"

  git -C "${repo_root}" show \
    "${i09_closure_repair_spec_sha}:${i09_closure_repair_spec_path}" > \
    "${fixture_root}/${i09_closure_repair_spec_path}"
  git -C "${fixture_root}" add "${i09_closure_repair_spec_path}"
  git -C "${fixture_root}" commit -qm "docs: preserve I09 closure receipt history"

  git -C "${repo_root}" show \
    "${i09_closure_repair_test_sha}:${i09_closure_test_path}" > \
    "${fixture_root}/${i09_closure_test_path}"
  chmod 755 "${fixture_root}/${i09_closure_test_path}"
  git -C "${fixture_root}" add "${i09_closure_test_path}"
  git -C "${fixture_root}" commit -qm "test: preserve I09 closure receipt history"

  cp -p "${repo_root}/${i09_closure_verifier_path}" \
    "${fixture_root}/${i09_closure_verifier_path}"
  chmod 755 "${fixture_root}/${i09_closure_verifier_path}"
  if git -C "${fixture_root}" diff --quiet -- "${i09_closure_verifier_path}"; then
    printf '%s\n' '# pending W1-I09 closure verifier' >> \
      "${fixture_root}/${i09_closure_verifier_path}"
  fi
  git -C "${fixture_root}" add "${i09_closure_verifier_path}"
  if [[ "${mutation}" == PRODUCT_DRIFT ]]; then
    printf '%s\n' '// forbidden I09 product drift' >> \
      "${fixture_root}/server/src/main/java/io/cognitura/source/storage/LocalContentAddressedSourceBinaryStore.java"
    git -C "${fixture_root}" add \
      server/src/main/java/io/cognitura/source/storage/LocalContentAddressedSourceBinaryStore.java
  fi
  git -C "${fixture_root}" commit -qm "build: verify W1-I09 closure"
}

replace_i09_closure_projection_text() {
  local file="$1"
  local old_text="$2"
  local new_text="$3"
  I09_CLOSURE_OLD_TEXT="${old_text}" I09_CLOSURE_NEW_TEXT="${new_text}" \
    perl -0777 -i.bak -pe \
      's/\Q$ENV{I09_CLOSURE_OLD_TEXT}\E/$ENV{I09_CLOSURE_NEW_TEXT}/g' "${file}"
  rm "${file}.bak"
}

append_i09_closure_receipt() {
  local fixture_root="$1"
  local governance_tip="$2"
  local governance_parent governance_tree
  governance_parent="$(git -C "${fixture_root}" rev-parse "${governance_tip}^")"
  governance_tree="$(git -C "${fixture_root}" rev-parse "${governance_tip}^{tree}")"
  printf '%s\n' \
    '' \
    '## 19. I09 关闭收据' \
    '' \
    '```text' \
    'W1-I09 = DONE' \
    "ReviewedCandidate = ${i09_closure_origin_sha}" \
    "ReviewedParent = ${i09_closure_reviewed_parent_sha}" \
    "ReviewedTree = ${i09_closure_reviewed_tree_sha}" \
    "ReviewedGovernanceCandidate = ${governance_tip}" \
    "ReviewedGovernanceParent = ${governance_parent}" \
    "ReviewedGovernanceTree = ${governance_tree}" \
    'ReviewLevel = L3' \
    'ReviewRoute = deep_reviewer' \
    'ReviewEffort = xhigh' \
    'ReviewMultiplicity = ONE' \
    'ReviewVerdict = GO' \
    'P0 = 0' \
    'P1 = 0' \
    'P2 = 0' \
    'Ultra = NOT_RUN' \
    'I09ClosureReleasedTaskCard = W1-I10' \
    'FormalDatabaseWrite = NOT_AUTHORIZED' \
    'RemotePush = NOT_AUTHORIZED' \
    '```' >> \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
}

make_i09_closure_projection() {
  local fixture_root="$1"
  local governance_tip="$2"
  set_first_field "${fixture_root}/AGENTS.md" ActiveImplementationTaskCard W1-I10
  set_first_field "${fixture_root}/README.md" ActiveImplementationTaskCard W1-I10
  set_first_field "${fixture_root}/docs/design/wave-1/README.md" \
    ActiveImplementationGovernanceTaskCard W1-I10
  set_first_field "${fixture_root}/docs/engineering/cognitura-design-index.md" ActiveTaskCard W1-I10
  set_first_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    ActiveImplementationTaskCard W1-I10
  set_first_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    ActiveImplementationGovernanceTaskCard W1-I10
  set_first_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    ImplementationTaskCardPlanStatus I09_DONE_I10_READY
  set_first_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    ActiveImplementationGovernanceTaskCard W1-I10
  set_first_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    ActiveTaskCard W1-I10
  set_table_status "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    W1-I09 READY DONE
  set_table_status "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    W1-I10 BLOCKED_BY_DEPENDENCY READY
  set_first_field "${fixture_root}/docs/task-cards/wave-1/README.md" \
    ActiveImplementationGovernanceTaskCard W1-I10
  set_first_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    ActiveTaskCard W1-I10
  set_table_status "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I09 READY DONE
  set_table_status "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I10 BLOCKED_BY_DEPENDENCY READY
  set_field "${fixture_root}/${i09_closure_i09_card_path}" Status DONE
  set_field "${fixture_root}/${i09_closure_i10_card_path}" Status READY
  set_field "${fixture_root}/${i09_closure_i10_card_path}" \
    BusinessImplementationAuthorization USER_AUTHORIZED

  replace_i09_closure_projection_text "${fixture_root}/AGENTS.md" \
    '`W1-I02`、`W1-I07` 和 `W1-I08` 已完成固定候选零发现深审并关闭；`W1-I09` 已作为唯一 `READY` 卡释放。' \
    '`W1-I02`、`W1-I07`、`W1-I08` 和 `W1-I09` 已完成固定候选零发现深审并关闭；`W1-I10` 已作为唯一 `READY` 卡释放。'
  replace_i09_closure_projection_text "${fixture_root}/AGENTS.md" \
    'I00、I01、I02、I03、I04、I05、I06、I07 和 I08 已关闭；I09 为唯一 `READY` 卡。' \
    'I00、I01、I02、I03、I04、I05、I06、I07、I08 和 I09 已关闭；I10 为唯一 `READY` 卡。'
  replace_i09_closure_projection_text "${fixture_root}/README.md" \
    '完成零发现深审并关闭；I02、I07 和 I08 已关闭，I09 已释放为唯一 `READY` 卡。' \
    '完成零发现深审并关闭；I02、I07、I08 和 I09 已关闭，I10 已释放为唯一 `READY` 卡。'
  replace_i09_closure_projection_text "${fixture_root}/README.md" \
    '已完成固定候选零发现深审并关闭；`W1-I03`、`W1-I04`、`W1-I05`、`W1-I06`、`W1-I07`、`W1-I08` 已关闭，`W1-I09` 为唯一 `READY` 卡。' \
    '已完成固定候选零发现深审并关闭；`W1-I03`、`W1-I04`、`W1-I05`、`W1-I06`、`W1-I07`、`W1-I08`、`W1-I09` 已关闭，`W1-I10` 为唯一 `READY` 卡。'
  replace_i09_closure_projection_text "${fixture_root}/docs/design/wave-1/README.md" \
    '  I01、I02、I03、I04、I05、I06、I07 和 I08 已关闭，I09 已释放为唯一 `READY` 卡。' \
    '  I01、I02、I03、I04、I05、I06、I07、I08 和 I09 已关闭，I10 已释放为唯一 `READY` 卡。'
  replace_i09_closure_projection_text "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    '`W1-I08` 已关闭，`W1-I09` 已释放为唯一 `READY` 卡。' \
    '`W1-I08` 和 `W1-I09` 已关闭，`W1-I10` 已释放为唯一 `READY` 卡。'
  replace_i09_closure_projection_text "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    '固定候选深审并关闭；I02、I03、I04、I05、I06、I07 和 I08 已关闭，I09 已释放为唯一 `READY` 卡，完整证据记录在' \
    '固定候选深审并关闭；I02、I03、I04、I05、I06、I07、I08 和 I09 已关闭，I10 已释放为唯一 `READY` 卡，完整证据记录在'
  replace_i09_closure_projection_text "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    '数据库 Gate 和固定候选深审均已通过，I02、I03、I04、I05、I06、I07 和 I08 已关闭；I09 为唯一 `READY` 卡。正式数据库、Parser/Object Storage Provider、' \
    '数据库 Gate 和固定候选深审均已通过，I02、I03、I04、I05、I06、I07、I08 和 I09 已关闭；I10 为唯一 `READY` 卡。正式数据库、Parser/Object Storage Provider、'
  replace_i09_closure_projection_text "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    '零发现深审并关闭；I08 已关闭，I09 已释放为唯一 `READY` 卡。' \
    '零发现深审并关闭；I08 和 I09 已关闭，I10 已释放为唯一 `READY` 卡。'
  replace_i09_closure_projection_text "${fixture_root}/docs/task-cards/wave-1/README.md" \
    'I00、I01、I02、I03、I04、I05、I06、I07 和 I08 已关闭；I09 已释放为唯一 `READY` 业务卡。' \
    'I00、I01、I02、I03、I04、I05、I06、I07、I08 和 I09 已关闭；I10 已释放为唯一 `READY` 业务卡。'
  replace_i09_closure_projection_text "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    '完成零发现深审并关闭；I02、I03、I04、I05、I06、I07 和 I08 已关闭，I09 已释放为唯一 `READY` 卡。' \
    '完成零发现深审并关闭；I02、I03、I04、I05、I06、I07、I08 和 I09 已关闭，I10 已释放为唯一 `READY` 卡。'
  append_i09_closure_receipt "${fixture_root}" "${governance_tip}"
}

commit_i09_closure_projection() {
  local fixture_root="$1"
  local governance_tip="$2"
  make_i09_closure_projection "${fixture_root}" "${governance_tip}"
  git -C "${fixture_root}" add "${i09_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "docs: close W1-I09 and release W1-I10"
}

run_i09_closure_fixture_verifier() {
  local fixture_root="$1"
  shift
  "${verifier}" --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" "$@"
}

expect_i09_closure_failure() {
  local fixture_root="$1"
  local expected="$2"
  shift 2
  local output
  if output="$(run_i09_closure_fixture_verifier "${fixture_root}" "$@" 2>&1)"; then
    fail "invalid I09 closure unexpectedly passed: ${expected}"
  fi
  assert_contains "${output}" "${expected}"
}

run_w1_i09_closure_contract() {
  local fixture_root governance_tip closure_sha output
  local positive_cases=0 negative_cases=0

  fixture_root="${test_tmp_root}/w1-i09-closure-positive"
  new_i09_closure_fixture "${fixture_root}"
  materialize_i09_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  commit_i09_closure_projection "${fixture_root}" "${governance_tip}"
  closure_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  output="$(run_i09_closure_fixture_verifier "${fixture_root}" \
    --transition-base "${governance_tip}" --transition-head "${closure_sha}")" ||
    fail "legal explicit I09 closure was rejected: ${output}"
  assert_contains "${output}" 'W1I09ClosureStatus = PASS'
  assert_contains "${output}" 'ActiveTaskCard = W1-I10'
  positive_cases=$((positive_cases + 1))
  output="$(run_i09_closure_fixture_verifier "${fixture_root}")" ||
    fail "legal static I09 closure was rejected: ${output}"
  assert_contains "${output}" 'W1I09ClosureStatus = PASS'
  assert_contains "${output}" 'ReadyTaskCardCount = 1'
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-closure-wrong-product-receipt"
  new_i09_closure_fixture "${fixture_root}"
  materialize_i09_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i09_closure_projection "${fixture_root}" "${governance_tip}"
  sed -i.bak 's/^ReviewedCandidate = .*/ReviewedCandidate = bad/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i09_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: drift I09 product receipt"
  expect_i09_closure_failure "${fixture_root}" 'I09_CLOSURE_REVIEW_RECEIPT_INVALID' \
    --transition-base "${governance_tip}" --transition-head HEAD
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-closure-wrong-governance-receipt"
  new_i09_closure_fixture "${fixture_root}"
  materialize_i09_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i09_closure_projection "${fixture_root}" "${governance_tip}"
  sed -i.bak 's/^ReviewedGovernanceCandidate = .*/ReviewedGovernanceCandidate = bad/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i09_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: drift I09 governance receipt"
  expect_i09_closure_failure "${fixture_root}" 'I09_CLOSURE_REVIEW_RECEIPT_INVALID' \
    --transition-base "${governance_tip}" --transition-head HEAD
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-closure-permission-drift"
  new_i09_closure_fixture "${fixture_root}"
  materialize_i09_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i09_closure_projection "${fixture_root}" "${governance_tip}"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    FormalDatabaseWrite AUTHORIZED
  git -C "${fixture_root}" add "${i09_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: drift I09 closure authority"
  expect_i09_closure_failure "${fixture_root}" 'I09_CLOSURE_PROJECTION_MISMATCH' \
    --transition-base "${governance_tip}" --transition-head HEAD
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-closure-state-drift"
  new_i09_closure_fixture "${fixture_root}"
  materialize_i09_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i09_closure_projection "${fixture_root}" "${governance_tip}"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    ReadyTaskCardCount 2
  git -C "${fixture_root}" add "${i09_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: add second I09 closure READY"
  expect_i09_closure_failure "${fixture_root}" 'I09_CLOSURE_STATE_VECTOR_INVALID' \
    --transition-base "${governance_tip}" --transition-head HEAD
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-closure-projection-extra"
  new_i09_closure_fixture "${fixture_root}"
  materialize_i09_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i09_closure_projection "${fixture_root}" "${governance_tip}"
  printf '%s\n' '' >> \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I11-partial-acceptance-command-api.md"
  git -C "${fixture_root}" add "${i09_closure_projection_paths[@]}" \
    docs/task-cards/wave-1-implementation/W1-I11-partial-acceptance-command-api.md
  git -C "${fixture_root}" commit -qm "test: expand I09 closure projection"
  expect_i09_closure_failure "${fixture_root}" 'I09_CLOSURE_RECEIPT_PATHS_INVALID' \
    --transition-base "${governance_tip}" --transition-head HEAD
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-closure-governance-extra"
  new_i09_closure_fixture "${fixture_root}"
  materialize_i09_closure_governance "${fixture_root}" GOVERNANCE_EXTRA_PATH
  expect_i09_closure_failure "${fixture_root}" 'I09_CLOSURE_GOVERNANCE_CHAIN_INVALID'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-closure-product-drift"
  new_i09_closure_fixture "${fixture_root}"
  materialize_i09_closure_governance "${fixture_root}" PRODUCT_DRIFT
  expect_i09_closure_failure "${fixture_root}" 'I09_CLOSURE_PRODUCT_DRIFT'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i09-closure-post-write-set"
  new_i09_closure_fixture "${fixture_root}"
  materialize_i09_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  commit_i09_closure_projection "${fixture_root}" "${governance_tip}"
  printf '%s\n' 'post I09 closure drift' >> \
    "${fixture_root}/docs/task-cards/wave-1/README.md"
  git -C "${fixture_root}" add docs/task-cards/wave-1/README.md
  git -C "${fixture_root}" commit -qm "test: exceed I10 WriteSet"
  expect_i09_closure_failure "${fixture_root}" \
    'I09_CLOSURE_DESCENDANT_OUTSIDE_WRITE_SET'
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 2 ]] || fail "I09 closure positive count mismatch"
  [[ "${negative_cases}" -eq 8 ]] || fail "I09 closure negative count mismatch"
  printf '%s\n' \
    'W1I09ClosureContractTests = PASS' \
    "W1I09ClosurePositiveCases = ${positive_cases}" \
    "W1I09ClosureNegativeCases = ${negative_cases}"
}

if [[ "${w1_i09_closure_contract_only}" == "1" ]]; then
  run_w1_i09_closure_contract
  exit 0
fi

i10_closure_origin_sha="9eb48f18b8c0ab3552a3f52cfe3a6f5e61db51ad"
i10_closure_reviewed_parent_sha="f4b22f1d5be85e8c9847399fab5d4490056d4e1f"
i10_closure_reviewed_tree_sha="a227ce11facc84b0be56d65f459a8d6005e16bb3"
i10_closure_spec_sha="261ac4d26c102c1cade7f2811e878652b601b108"
i10_closure_red_test_sha="dd89a075491b11957c00ecb7adf3da2138a997f5"
i10_closure_repair_spec_sha="054ecbbd9a4dd7a4d5fac3463c13312d5f166013"
i10_closure_repair_test_sha="f2c22d2ed5ee90e1447ef1609b7b7037bd052bad"
i10_closure_spec_path="docs/superpowers/specs/2026-08-22-cognitura-w1-i10-closure-design.md"
i10_closure_repair_spec_path="docs/superpowers/specs/2026-08-22-cognitura-w1-i10-closure-test-repair.md"
i10_closure_test_path="tests/task-cards/verify-wave1-implementation-cards.sh"
i10_closure_verifier_path="scripts/verify-wave1-implementation-cards"
i10_closure_i10_card_path="docs/task-cards/wave-1-implementation/W1-I10-source-preview-query-api.md"
i10_closure_i11_card_path="docs/task-cards/wave-1-implementation/W1-I11-partial-acceptance-command-api.md"
i10_closure_projection_paths=(
  AGENTS.md
  README.md
  docs/design/wave-1/README.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-plan.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1/README.md
  docs/task-cards/wave-1-implementation/README.md
  "${i10_closure_i10_card_path}"
  "${i10_closure_i11_card_path}"
)

new_i10_closure_fixture() {
  local fixture_root="$1"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${i10_closure_origin_sha}"
}

materialize_i10_closure_governance() {
  local fixture_root="$1"
  mkdir -p "${fixture_root}/$(dirname "${i10_closure_spec_path}")"
  git -C "${repo_root}" show \
    "${i10_closure_spec_sha}:${i10_closure_spec_path}" > \
    "${fixture_root}/${i10_closure_spec_path}"
  git -C "${fixture_root}" add "${i10_closure_spec_path}"
  git -C "${fixture_root}" commit -qm "docs: define W1-I10 closure"

  git -C "${repo_root}" show \
    "${i10_closure_red_test_sha}:${i10_closure_test_path}" > \
    "${fixture_root}/${i10_closure_test_path}"
  chmod 755 "${fixture_root}/${i10_closure_test_path}"
  git -C "${fixture_root}" add "${i10_closure_test_path}"
  git -C "${fixture_root}" commit -qm "test: require W1-I10 closure"

  mkdir -p "${fixture_root}/$(dirname "${i10_closure_repair_spec_path}")"
  git -C "${repo_root}" show \
    "${i10_closure_repair_spec_sha}:${i10_closure_repair_spec_path}" > \
    "${fixture_root}/${i10_closure_repair_spec_path}"
  git -C "${fixture_root}" add "${i10_closure_repair_spec_path}"
  git -C "${fixture_root}" commit -qm "docs: repair W1-I10 closure test fixture"

  git -C "${repo_root}" show \
    "${i10_closure_repair_test_sha}:${i10_closure_test_path}" > \
    "${fixture_root}/${i10_closure_test_path}"
  chmod 755 "${fixture_root}/${i10_closure_test_path}"
  git -C "${fixture_root}" add "${i10_closure_test_path}"
  git -C "${fixture_root}" commit -qm "test: repair W1-I10 closure fixture"

  cp -p "${repo_root}/${i10_closure_verifier_path}" \
    "${fixture_root}/${i10_closure_verifier_path}"
  chmod 755 "${fixture_root}/${i10_closure_verifier_path}"
  if git -C "${fixture_root}" diff --quiet -- "${i10_closure_verifier_path}"; then
    printf '%s\n' '# pending W1-I10 closure verifier' >> \
      "${fixture_root}/${i10_closure_verifier_path}"
  fi
  git -C "${fixture_root}" add "${i10_closure_verifier_path}"
  git -C "${fixture_root}" commit -qm "build: verify W1-I10 closure"
}

replace_i10_closure_projection_text() {
  local file="$1"
  local old_text="$2"
  local new_text="$3"
  I10_CLOSURE_OLD_TEXT="${old_text}" I10_CLOSURE_NEW_TEXT="${new_text}" \
    perl -0777 -i.bak -pe \
      's/\Q$ENV{I10_CLOSURE_OLD_TEXT}\E/$ENV{I10_CLOSURE_NEW_TEXT}/g' "${file}"
  rm "${file}.bak"
}

append_i10_closure_receipt() {
  local fixture_root="$1"
  local governance_tip="$2"
  local governance_parent governance_tree
  governance_parent="$(git -C "${fixture_root}" rev-parse "${governance_tip}^")"
  governance_tree="$(git -C "${fixture_root}" rev-parse "${governance_tip}^{tree}")"
  printf '%s\n' '' '## 20. I10 关闭收据' '' '```text' \
    'W1-I10 = DONE' \
    "ReviewedCandidate = ${i10_closure_origin_sha}" \
    "ReviewedParent = ${i10_closure_reviewed_parent_sha}" \
    "ReviewedTree = ${i10_closure_reviewed_tree_sha}" \
    "ReviewedGovernanceCandidate = ${governance_tip}" \
    "ReviewedGovernanceParent = ${governance_parent}" \
    "ReviewedGovernanceTree = ${governance_tree}" \
    'ReviewLevel = L3' 'ReviewRoute = deep_reviewer' \
    'ReviewEffort = xhigh' 'ReviewMultiplicity = ONE' \
    'ReviewVerdict = GO' 'P0 = 0' 'P1 = 0' 'P2 = 0' \
    'Ultra = NOT_RUN' 'I10ClosureReleasedTaskCard = W1-I11' \
    'FormalDatabaseWrite = NOT_AUTHORIZED' \
    'RemotePush = NOT_AUTHORIZED' '```' >> \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
}

make_i10_closure_projection() {
  local fixture_root="$1"
  local governance_tip="$2"
  set_first_field "${fixture_root}/AGENTS.md" ActiveImplementationTaskCard W1-I11
  set_first_field "${fixture_root}/README.md" ActiveImplementationTaskCard W1-I11
  set_first_field "${fixture_root}/docs/design/wave-1/README.md" \
    ActiveImplementationGovernanceTaskCard W1-I11
  set_first_field "${fixture_root}/docs/engineering/cognitura-design-index.md" ActiveTaskCard W1-I11
  set_first_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    ActiveImplementationTaskCard W1-I11
  set_first_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    ActiveImplementationGovernanceTaskCard W1-I11
  set_first_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    ImplementationTaskCardPlanStatus I10_DONE_I11_READY
  set_first_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    ActiveImplementationGovernanceTaskCard W1-I11
  set_first_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    ActiveTaskCard W1-I11
  set_table_status "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    W1-I10 READY DONE
  set_table_status "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    W1-I11 BLOCKED_BY_DEPENDENCY READY
  set_first_field "${fixture_root}/docs/task-cards/wave-1/README.md" \
    ActiveImplementationGovernanceTaskCard W1-I11
  set_first_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    ActiveTaskCard W1-I11
  set_table_status "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I10 READY DONE
  set_table_status "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I11 BLOCKED_BY_DEPENDENCY READY
  set_field "${fixture_root}/${i10_closure_i10_card_path}" Status DONE
  set_field "${fixture_root}/${i10_closure_i11_card_path}" Status READY
  set_field "${fixture_root}/${i10_closure_i11_card_path}" \
    BusinessImplementationAuthorization USER_AUTHORIZED

  replace_i10_closure_projection_text "${fixture_root}/AGENTS.md" \
    '`W1-I02`、`W1-I07`、`W1-I08` 和 `W1-I09` 已完成固定候选零发现深审并关闭；`W1-I10` 已作为唯一 `READY` 卡释放。' \
    '`W1-I02`、`W1-I07`、`W1-I08`、`W1-I09` 和 `W1-I10` 已完成固定候选零发现深审并关闭；`W1-I11` 已作为唯一 `READY` 卡释放。'
  replace_i10_closure_projection_text "${fixture_root}/AGENTS.md" \
    'I00、I01、I02、I03、I04、I05、I06、I07、I08 和 I09 已关闭；I10 为唯一 `READY` 卡。' \
    'I00、I01、I02、I03、I04、I05、I06、I07、I08、I09 和 I10 已关闭；I11 为唯一 `READY` 卡。'
  replace_i10_closure_projection_text "${fixture_root}/README.md" \
    '完成零发现深审并关闭；I02、I07、I08 和 I09 已关闭，I10 已释放为唯一 `READY` 卡。' \
    '完成零发现深审并关闭；I02、I07、I08、I09 和 I10 已关闭，I11 已释放为唯一 `READY` 卡。'
  replace_i10_closure_projection_text "${fixture_root}/README.md" \
    '已完成固定候选零发现深审并关闭；`W1-I03`、`W1-I04`、`W1-I05`、`W1-I06`、`W1-I07`、`W1-I08`、`W1-I09` 已关闭，`W1-I10` 为唯一 `READY` 卡。' \
    '已完成固定候选零发现深审并关闭；`W1-I03`、`W1-I04`、`W1-I05`、`W1-I06`、`W1-I07`、`W1-I08`、`W1-I09`、`W1-I10` 已关闭，`W1-I11` 为唯一 `READY` 卡。'
  replace_i10_closure_projection_text "${fixture_root}/docs/design/wave-1/README.md" \
    '  I01、I02、I03、I04、I05、I06、I07、I08 和 I09 已关闭，I10 已释放为唯一 `READY` 卡。' \
    '  I01、I02、I03、I04、I05、I06、I07、I08、I09 和 I10 已关闭，I11 已释放为唯一 `READY` 卡。'
  replace_i10_closure_projection_text "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    '`W1-I08` 和 `W1-I09` 已关闭，`W1-I10` 已释放为唯一 `READY` 卡。' \
    '`W1-I08`、`W1-I09` 和 `W1-I10` 已关闭，`W1-I11` 已释放为唯一 `READY` 卡。'
  replace_i10_closure_projection_text "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    '固定候选深审并关闭；I02、I03、I04、I05、I06、I07、I08 和 I09 已关闭，I10 已释放为唯一 `READY` 卡，完整证据记录在' \
    '固定候选深审并关闭；I02、I03、I04、I05、I06、I07、I08、I09 和 I10 已关闭，I11 已释放为唯一 `READY` 卡，完整证据记录在'
  replace_i10_closure_projection_text "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    '数据库 Gate 和固定候选深审均已通过，I02、I03、I04、I05、I06、I07、I08 和 I09 已关闭；I10 为唯一 `READY` 卡。正式数据库、Parser/Object Storage Provider、' \
    '数据库 Gate 和固定候选深审均已通过，I02、I03、I04、I05、I06、I07、I08、I09 和 I10 已关闭；I11 为唯一 `READY` 卡。正式数据库、Parser/Object Storage Provider、'
  replace_i10_closure_projection_text "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    '零发现深审并关闭；I08 和 I09 已关闭，I10 已释放为唯一 `READY` 卡。' \
    '零发现深审并关闭；I08、I09 和 I10 已关闭，I11 已释放为唯一 `READY` 卡。'
  replace_i10_closure_projection_text "${fixture_root}/docs/task-cards/wave-1/README.md" \
    'I00、I01、I02、I03、I04、I05、I06、I07、I08 和 I09 已关闭；I10 已释放为唯一 `READY` 业务卡。' \
    'I00、I01、I02、I03、I04、I05、I06、I07、I08、I09 和 I10 已关闭；I11 已释放为唯一 `READY` 业务卡。'
  replace_i10_closure_projection_text "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    '完成零发现深审并关闭；I02、I03、I04、I05、I06、I07、I08 和 I09 已关闭，I10 已释放为唯一 `READY` 卡。' \
    '完成零发现深审并关闭；I02、I03、I04、I05、I06、I07、I08、I09 和 I10 已关闭，I11 已释放为唯一 `READY` 卡。'
  append_i10_closure_receipt "${fixture_root}" "${governance_tip}"
}

commit_i10_closure_projection() {
  local fixture_root="$1"
  local governance_tip="$2"
  make_i10_closure_projection "${fixture_root}" "${governance_tip}"
  git -C "${fixture_root}" add "${i10_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "docs: close W1-I10 and release W1-I11"
}

run_i10_closure_fixture_verifier() {
  local fixture_root="$1"
  shift
  "${verifier}" --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" "$@"
}

expect_i10_closure_failure() {
  local fixture_root="$1"
  local expected="$2"
  shift 2
  local output
  if output="$(run_i10_closure_fixture_verifier "${fixture_root}" "$@" 2>&1)"; then
    fail "invalid I10 closure unexpectedly passed: ${expected}"
  fi
  assert_contains "${output}" "${expected}"
}

run_w1_i10_closure_contract() {
  local fixture_root governance_tip closure_sha output
  local positive_cases=0 negative_cases=0

  fixture_root="${test_tmp_root}/w1-i10-closure-positive"
  new_i10_closure_fixture "${fixture_root}"
  materialize_i10_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  commit_i10_closure_projection "${fixture_root}" "${governance_tip}"
  closure_sha="$(git -C "${fixture_root}" rev-parse HEAD)"
  output="$(run_i10_closure_fixture_verifier "${fixture_root}" \
    --transition-base "${governance_tip}" --transition-head "${closure_sha}")" ||
    fail "legal explicit I10 closure was rejected: ${output}"
  assert_contains "${output}" 'W1I10ClosureStatus = PASS'
  assert_contains "${output}" 'ActiveTaskCard = W1-I11'
  positive_cases=$((positive_cases + 1))
  output="$(run_i10_closure_fixture_verifier "${fixture_root}")" ||
    fail "legal static I10 closure was rejected: ${output}"
  assert_contains "${output}" 'W1I10ClosureStatus = PASS'
  assert_contains "${output}" 'ReadyTaskCardCount = 1'
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i10-closure-wrong-product"
  new_i10_closure_fixture "${fixture_root}"
  materialize_i10_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i10_closure_projection "${fixture_root}" "${governance_tip}"
  sed -i.bak 's/^ReviewedCandidate = .*/ReviewedCandidate = bad/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i10_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: drift I10 product receipt"
  expect_i10_closure_failure "${fixture_root}" 'I10_CLOSURE_REVIEW_RECEIPT_INVALID' \
    --transition-base "${governance_tip}" --transition-head HEAD
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i10-closure-wrong-governance"
  new_i10_closure_fixture "${fixture_root}"
  materialize_i10_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i10_closure_projection "${fixture_root}" "${governance_tip}"
  sed -i.bak 's/^ReviewedGovernanceCandidate = .*/ReviewedGovernanceCandidate = bad/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md.bak"
  git -C "${fixture_root}" add "${i10_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: drift I10 governance receipt"
  expect_i10_closure_failure "${fixture_root}" 'I10_CLOSURE_REVIEW_RECEIPT_INVALID' \
    --transition-base "${governance_tip}" --transition-head HEAD
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i10-closure-second-ready"
  new_i10_closure_fixture "${fixture_root}"
  materialize_i10_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i10_closure_projection "${fixture_root}" "${governance_tip}"
  set_table_status "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    W1-I12 BLOCKED_BY_DEPENDENCY READY
  git -C "${fixture_root}" add "${i10_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: release I12 early"
  expect_i10_closure_failure "${fixture_root}" 'I10_CLOSURE_PROJECTION_MISMATCH' \
    --transition-base "${governance_tip}" --transition-head HEAD
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i10-closure-authorization"
  new_i10_closure_fixture "${fixture_root}"
  materialize_i10_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i10_closure_projection "${fixture_root}" "${governance_tip}"
  sed -i.bak 's/FormalDatabaseWrite = NOT_AUTHORIZED/FormalDatabaseWrite = AUTHORIZED/' \
    "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md"
  rm "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md.bak"
  git -C "${fixture_root}" add "${i10_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: authorize database write"
  expect_i10_closure_failure "${fixture_root}" 'I10_CLOSURE_PROJECTION_MISMATCH' \
    --transition-base "${governance_tip}" --transition-head HEAD
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i10-closure-extra-path"
  new_i10_closure_fixture "${fixture_root}"
  materialize_i10_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i10_closure_projection "${fixture_root}" "${governance_tip}"
  printf '%s\n' 'I10 closure extra path' >> \
    "${fixture_root}/docs/task-cards/README.md"
  git -C "${fixture_root}" add "${i10_closure_projection_paths[@]}" \
    docs/task-cards/README.md
  git -C "${fixture_root}" commit -qm "test: exceed I10 closure projection"
  expect_i10_closure_failure "${fixture_root}" 'I10_CLOSURE_RECEIPT_PATHS_INVALID' \
    --transition-base "${governance_tip}" --transition-head HEAD
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i10-closure-rename"
  new_i10_closure_fixture "${fixture_root}"
  materialize_i10_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i10_closure_projection "${fixture_root}" "${governance_tip}"
  git -C "${fixture_root}" mv README.md README-I10.md
  git -C "${fixture_root}" add -A
  git -C "${fixture_root}" commit -qm "test: rename I10 projection"
  expect_i10_closure_failure "${fixture_root}" 'I10_CLOSURE_RECEIPT_PATHS_INVALID:rename or copy' \
    --transition-base "${governance_tip}" --transition-head HEAD
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i10-closure-product-drift"
  new_i10_closure_fixture "${fixture_root}"
  materialize_i10_closure_governance "${fixture_root}"
  printf '%s\n' '// forbidden I10 product drift' >> \
    "${fixture_root}/server/src/main/java/io/cognitura/source/api/query/SourcePreviewPage.java"
  git -C "${fixture_root}" add \
    server/src/main/java/io/cognitura/source/api/query/SourcePreviewPage.java
  git -C "${fixture_root}" commit --amend -qm "build: drift W1-I10 product"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  make_i10_closure_projection "${fixture_root}" "${governance_tip}"
  git -C "${fixture_root}" add "${i10_closure_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: close with product drift"
  expect_i10_closure_failure "${fixture_root}" 'I10_CLOSURE_PRODUCT_DRIFT' \
    --transition-base "${governance_tip}" --transition-head HEAD
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i10-closure-post-write-set"
  new_i10_closure_fixture "${fixture_root}"
  materialize_i10_closure_governance "${fixture_root}"
  governance_tip="$(git -C "${fixture_root}" rev-parse HEAD)"
  commit_i10_closure_projection "${fixture_root}" "${governance_tip}"
  printf '%s\n' 'post I10 closure drift' >> \
    "${fixture_root}/docs/task-cards/wave-1/README.md"
  git -C "${fixture_root}" add docs/task-cards/wave-1/README.md
  git -C "${fixture_root}" commit -qm "test: exceed I11 WriteSet"
  expect_i10_closure_failure "${fixture_root}" \
    'I10_CLOSURE_DESCENDANT_OUTSIDE_WRITE_SET'
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 2 ]] || fail "I10 closure positive count mismatch"
  [[ "${negative_cases}" -eq 8 ]] || fail "I10 closure negative count mismatch"
  printf '%s\n' \
    'W1I10ClosureContractTests = PASS' \
    "W1I10ClosurePositiveCases = ${positive_cases}" \
    "W1I10ClosureNegativeCases = ${negative_cases}"
}

i11_rebaseline_origin_sha="b99f20feaa47f36aeb49e05a070bfb3c73615ac0"
i11_rebaseline_spec_sha="55e0665c0b63d8082b269f3f891252dfc6f5f8f6"
i11_rebaseline_plan_sha="a7788d805d7d38fcbbb2d585cafa2c394300db7c"
i11_rebaseline_spec_path="docs/superpowers/specs/2026-08-22-cognitura-w1-i11-persistence-rebaseline-design.md"
i11_rebaseline_plan_path="docs/superpowers/plans/2026-08-22-cognitura-w1-i11-persistence-rebaseline.md"
i11_rebaseline_test_path="tests/task-cards/verify-wave1-implementation-cards.sh"
i11_rebaseline_verifier_path="scripts/verify-wave1-implementation-cards"
i11_rebaseline_index_path="docs/task-cards/wave-1-implementation/README.md"
i11_rebaseline_card_path="docs/task-cards/wave-1-implementation/W1-I11-partial-acceptance-command-api.md"
i11_rebaseline_projection_paths=(
  "${i11_rebaseline_index_path}"
  "${i11_rebaseline_card_path}"
)
i11_rebaseline_product_paths=(
  server/src/main/resources/db/migration/V3__add_partial_acceptance_facts.sql
  server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceController.java
  server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceRequest.java
  server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceCommand.java
  server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceService.java
  server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptancePort.java
  server/src/main/java/io/cognitura/source/api/acceptance/PartialAcceptanceResponse.java
  server/src/main/java/io/cognitura/source/persistence/JdbcPartialAcceptancePort.java
  server/src/main/java/io/cognitura/source/runtime/SourceCommandRuntimeConfiguration.java
  server/src/main/java/io/cognitura/source/api/query/SourcePreviewQuery.java
  server/src/test/java/io/cognitura/source/api/acceptance/PartialAcceptanceControllerTest.java
  server/src/test/java/io/cognitura/source/api/acceptance/PartialAcceptanceServiceTest.java
  server/src/test/java/io/cognitura/source/api/query/SourcePreviewControllerTest.java
)

new_i11_rebaseline_fixture() {
  local fixture_root="$1"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${i11_rebaseline_origin_sha}"
  git -C "${fixture_root}" config user.name "Cognitura Contract Test"
  git -C "${fixture_root}" config user.email "contract-test@cognitura.invalid"
}

materialize_i11_rebaseline_governance() {
  local fixture_root="$1" drift="${2:-none}"
  mkdir -p "${fixture_root}/$(dirname "${i11_rebaseline_spec_path}")"
  git -C "${repo_root}" show \
    "${i11_rebaseline_spec_sha}:${i11_rebaseline_spec_path}" > \
    "${fixture_root}/${i11_rebaseline_spec_path}"
  [[ "${drift}" != spec ]] || printf '%s\n' 'drift' >> \
    "${fixture_root}/${i11_rebaseline_spec_path}"
  git -C "${fixture_root}" add "${i11_rebaseline_spec_path}"
  git -C "${fixture_root}" commit -qm "docs: design W1-I11 persistence rebaseline"

  mkdir -p "${fixture_root}/$(dirname "${i11_rebaseline_plan_path}")"
  git -C "${repo_root}" show \
    "${i11_rebaseline_plan_sha}:${i11_rebaseline_plan_path}" > \
    "${fixture_root}/${i11_rebaseline_plan_path}"
  [[ "${drift}" != plan ]] || printf '%s\n' 'drift' >> \
    "${fixture_root}/${i11_rebaseline_plan_path}"
  git -C "${fixture_root}" add "${i11_rebaseline_plan_path}"
  git -C "${fixture_root}" commit -qm "docs: plan W1-I11 persistence rebaseline"

  git -C "${repo_root}" show \
    "8b5299332971aa85d3ed6563d0327c89136f05da:${i11_rebaseline_test_path}" > \
    "${fixture_root}/${i11_rebaseline_test_path}"
  chmod 755 "${fixture_root}/${i11_rebaseline_test_path}"
  git -C "${fixture_root}" add "${i11_rebaseline_test_path}"
  git -C "${fixture_root}" commit -qm "test: require W1-I11 persistence rebaseline"

  git -C "${repo_root}" show \
    "f19e9b841802c3f69f95818eed2e013a65d54352:${i11_rebaseline_verifier_path}" > \
    "${fixture_root}/${i11_rebaseline_verifier_path}"
  chmod 755 "${fixture_root}/${i11_rebaseline_verifier_path}"
  git -C "${fixture_root}" add "${i11_rebaseline_verifier_path}"
  git -C "${fixture_root}" commit -qm "build: verify W1-I11 persistence rebaseline"
}

commit_i11_rebaseline_fixed_blob() {
  local fixture_root="$1" sha="$2" path="$3" message="$4" mode="$5"
  mkdir -p "${fixture_root}/$(dirname "${path}")"
  git -C "${repo_root}" show "${sha}:${path}" > "${fixture_root}/${path}"
  chmod "${mode}" "${fixture_root}/${path}"
  git -C "${fixture_root}" add "${path}"
  git -C "${fixture_root}" commit -qm "${message}"
}

materialize_i11_rebaseline_governance_variant() {
  local fixture_root="$1" variant="$2"
  local spec_sha="55e0665c0b63d8082b269f3f891252dfc6f5f8f6"
  local plan_sha="a7788d805d7d38fcbbb2d585cafa2c394300db7c"
  local test_sha="8b5299332971aa85d3ed6563d0327c89136f05da"
  local verifier_sha="f19e9b841802c3f69f95818eed2e013a65d54352"
  if [[ "${variant}" == wrong-origin ]]; then
    git -C "${fixture_root}" checkout -q --detach "${i11_rebaseline_origin_sha}^"
  fi
  case "${variant}" in
    wrong-order)
      commit_i11_rebaseline_fixed_blob "${fixture_root}" "${plan_sha}" \
        "${i11_rebaseline_plan_path}" "docs: plan W1-I11 persistence rebaseline" 644
      commit_i11_rebaseline_fixed_blob "${fixture_root}" "${spec_sha}" \
        "${i11_rebaseline_spec_path}" "docs: design W1-I11 persistence rebaseline" 644
      commit_i11_rebaseline_fixed_blob "${fixture_root}" "${test_sha}" \
        "${i11_rebaseline_test_path}" "test: require W1-I11 persistence rebaseline" 755
      ;;
    rename)
      mkdir -p "${fixture_root}/$(dirname "${i11_rebaseline_spec_path}")"
      git -C "${fixture_root}" mv README.md "${i11_rebaseline_spec_path}"
      git -C "${fixture_root}" commit -qm "test: rename I11 authority"
      commit_i11_rebaseline_fixed_blob "${fixture_root}" "${plan_sha}" \
        "${i11_rebaseline_plan_path}" "docs: plan W1-I11 persistence rebaseline" 644
      commit_i11_rebaseline_fixed_blob "${fixture_root}" "${test_sha}" \
        "${i11_rebaseline_test_path}" "test: require W1-I11 persistence rebaseline" 755
      ;;
    copy)
      mkdir -p "${fixture_root}/$(dirname "${i11_rebaseline_spec_path}")"
      cp -p "${fixture_root}/README.md" "${fixture_root}/${i11_rebaseline_spec_path}"
      git -C "${fixture_root}" add "${i11_rebaseline_spec_path}"
      git -C "${fixture_root}" commit -qm "test: copy I11 authority"
      commit_i11_rebaseline_fixed_blob "${fixture_root}" "${plan_sha}" \
        "${i11_rebaseline_plan_path}" "docs: plan W1-I11 persistence rebaseline" 644
      commit_i11_rebaseline_fixed_blob "${fixture_root}" "${test_sha}" \
        "${i11_rebaseline_test_path}" "test: require W1-I11 persistence rebaseline" 755
      ;;
    NUL)
      mkdir -p "${fixture_root}/$(dirname "${i11_rebaseline_spec_path}")"
      printf 'invalid\0authority\n' > "${fixture_root}/${i11_rebaseline_spec_path}"
      git -C "${fixture_root}" add "${i11_rebaseline_spec_path}"
      git -C "${fixture_root}" commit -qm "test: add NUL I11 authority"
      commit_i11_rebaseline_fixed_blob "${fixture_root}" "${plan_sha}" \
        "${i11_rebaseline_plan_path}" "docs: plan W1-I11 persistence rebaseline" 644
      commit_i11_rebaseline_fixed_blob "${fixture_root}" "${test_sha}" \
        "${i11_rebaseline_test_path}" "test: require W1-I11 persistence rebaseline" 755
      ;;
    merge)
      commit_i11_rebaseline_fixed_blob "${fixture_root}" "${spec_sha}" \
        "${i11_rebaseline_spec_path}" "docs: design W1-I11 persistence rebaseline" 644
      commit_i11_rebaseline_fixed_blob "${fixture_root}" "${plan_sha}" \
        "${i11_rebaseline_plan_path}" "docs: plan W1-I11 persistence rebaseline" 644
      ;;
    *)
      commit_i11_rebaseline_fixed_blob "${fixture_root}" "${spec_sha}" \
        "${i11_rebaseline_spec_path}" "docs: design W1-I11 persistence rebaseline" 644
      commit_i11_rebaseline_fixed_blob "${fixture_root}" "${plan_sha}" \
        "${i11_rebaseline_plan_path}" "docs: plan W1-I11 persistence rebaseline" 644
      if [[ "${variant}" == empty ]]; then
        git -C "${fixture_root}" commit --allow-empty -qm \
          "test: empty I11 persistence evidence"
      else
        commit_i11_rebaseline_fixed_blob "${fixture_root}" "${test_sha}" \
          "${i11_rebaseline_test_path}" "test: require W1-I11 persistence rebaseline" 755
      fi
      if [[ "${variant}" == wrong-count ]]; then
        printf '%s\n' 'extra governance commit' >> \
          "${fixture_root}/${i11_rebaseline_plan_path}"
        git -C "${fixture_root}" add "${i11_rebaseline_plan_path}"
        git -C "${fixture_root}" commit -qm "test: add fifth I11 governance step"
      fi
      ;;
  esac
  if [[ "${variant}" == merge ]]; then
    git -C "${fixture_root}" switch -q -c i11-main
    git -C "${fixture_root}" switch -q -c i11-side
    commit_i11_rebaseline_fixed_blob "${fixture_root}" "${test_sha}" \
      "${i11_rebaseline_test_path}" "test: side I11 evidence" 755
    git -C "${fixture_root}" switch -q i11-main
    git -C "${fixture_root}" merge -q --no-ff i11-side -m "test: merge I11 evidence"
  fi
  commit_i11_rebaseline_fixed_blob "${fixture_root}" "${verifier_sha}" \
    "${i11_rebaseline_verifier_path}" "build: verify W1-I11 persistence rebaseline" 755
}

make_i11_rebaseline_projection() {
  local fixture_root="$1" card index write_set forbidden_set validation_block
  card="${fixture_root}/${i11_rebaseline_card_path}"
  index="${fixture_root}/${i11_rebaseline_index_path}"
  write_set="$(printf '%s\n' "${i11_rebaseline_product_paths[@]}" | sed 's/^/WriteSet = /')"
  forbidden_set="$(printf '%s\n' \
    'ForbiddenWriteSet = server/src/main/java/io/cognitura/source/docx/**' \
    'ForbiddenWriteSet = web/**,raw/**,.idea/**' \
    'ForbiddenWriteSet = FORMAL_DATABASE_CONNECTION_OR_WRITE')"
  validation_block="$(printf '%s\n' \
    './mvnw -f server/pom.xml -Dtest='\''io.cognitura.source.api.acceptance.*Test,io.cognitura.source.api.query.SourcePreviewControllerTest'\'' test' \
    'scripts/verify-wave1-implementation' \
    'git diff --check' \
    'git status --short')"

  set_field "${card}" PrimaryBoundary SOURCE_PARTIAL_ACCEPTANCE_COMMAND
  set_field "${card}" ProductionFileLimit 10
  set_field "${card}" ProductionWriteSetException APPROVED_I11_PERSISTENCE_REBASELINE
  I11_WRITE_SET="${write_set}" perl -0777 -i.bak -pe \
    's/(?:^WriteSet = .*\n)+/$ENV{I11_WRITE_SET}."\n"/mge' "${card}"
  rm "${card}.bak"
  I11_FORBIDDEN_SET="${forbidden_set}" perl -0777 -i.bak -pe \
    's/(?:^ForbiddenWriteSet = .*\n)+/$ENV{I11_FORBIDDEN_SET}."\n"/mge' "${card}"
  rm "${card}.bak"
  replace_i10_closure_projection_text "${card}" \
    '本卡不修改 preview query 或 Web。' \
    '本卡只为 ACCEPTED 兼容修改既有 preview query；不修改 Web。'
  I11_VALIDATION_BLOCK="${validation_block}" perl -0777 -i.bak -pe \
    's~(?<=```bash\n).*?(?=```\n\n## 6\.)~$ENV{I11_VALIDATION_BLOCK}."\n"~se' "${card}"
  rm "${card}.bak"
  replace_i10_closure_projection_text "${card}" \
    '完整 digest/actor/idempotency tuple、不可逆性、相同重放和冲突拒绝全部通过；无 query、' \
    '完整 digest/actor/idempotency tuple、不可逆性、相同重放、并发 CAS 和冲突拒绝全部通过；'
  replace_i10_closure_projection_text "${card}" \
    'Parser、migration 或 Web 改动。' \
    '证据来自隔离 PostgreSQL 18.4，且无 Web、Parser 或正式数据库改动。'

  perl -i.bak -pe \
    'if (/^ImplementationGovernanceReviewVerdict = /) { $_ .= "I11PersistenceRebaseline = PASS\n" }' \
    "${index}"
  rm "${index}.bak"
  replace_i10_closure_projection_text "${index}" \
    '完成零发现深审并关闭；I02、I03、I04、I05、I06、I07、I08、I09 和 I10 已关闭，I11 已释放为唯一 `READY` 卡。' \
    '完成零发现深审并关闭；I02、I03、I04、I05、I06、I07、I08、I09 和 I10 已关闭，I11 已完成持久化重基线并保持唯一 `READY` 卡。'
}

commit_i11_rebaseline_projection() {
  local fixture_root="$1"
  make_i11_rebaseline_projection "${fixture_root}"
  git -C "${fixture_root}" add "${i11_rebaseline_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "docs: rebaseline W1-I11 persistence WriteSet"
}

run_i11_rebaseline_fixture_verifier() {
  local fixture_root="$1"
  "${verifier}" --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation"
}

expect_i11_rebaseline_failure() {
  local fixture_root="$1" expected="$2" output
  if output="$(run_i11_rebaseline_fixture_verifier "${fixture_root}" 2>&1)"; then
    fail "invalid I11 persistence rebaseline unexpectedly passed: ${expected}"
  fi
  assert_contains "${output}" "${expected}"
}

run_w1_i11_persistence_rebaseline_contract() {
  local fixture_root output old_card old_write_set old_forbidden_set
  local positive_cases=0 negative_cases=0

  fixture_root="${test_tmp_root}/w1-i11-rebaseline-pending"
  new_i11_rebaseline_fixture "${fixture_root}"
  materialize_i11_rebaseline_governance "${fixture_root}"
  output="$(run_i11_rebaseline_fixture_verifier "${fixture_root}")" ||
    fail "legal I11 persistence governance was rejected: ${output}"
  assert_contains "${output}" 'W1I11PersistenceRebaselineStatus = PENDING'
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-rebaseline-projected"
  new_i11_rebaseline_fixture "${fixture_root}"
  materialize_i11_rebaseline_governance "${fixture_root}"
  commit_i11_rebaseline_projection "${fixture_root}"
  output="$(run_i11_rebaseline_fixture_verifier "${fixture_root}")" ||
    fail "legal I11 persistence projection was rejected: ${output}"
  assert_contains "${output}" 'W1I11PersistenceRebaselineStatus = PASS'
  assert_contains "${output}" 'ActiveTaskCard = W1-I11'
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-rebaseline-spec-drift"
  new_i11_rebaseline_fixture "${fixture_root}"
  materialize_i11_rebaseline_governance "${fixture_root}" spec
  expect_i11_rebaseline_failure "${fixture_root}" \
    'I11_PERSISTENCE_REBASELINE_INVALID:evidence'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-rebaseline-plan-drift"
  new_i11_rebaseline_fixture "${fixture_root}"
  materialize_i11_rebaseline_governance "${fixture_root}" plan
  expect_i11_rebaseline_failure "${fixture_root}" \
    'I11_PERSISTENCE_REBASELINE_INVALID:evidence'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-rebaseline-auth-drift"
  new_i11_rebaseline_fixture "${fixture_root}"
  materialize_i11_rebaseline_governance "${fixture_root}"
  make_i11_rebaseline_projection "${fixture_root}"
  set_field "${fixture_root}/${i11_rebaseline_card_path}" FormalDatabaseGate PASS
  git -C "${fixture_root}" add "${i11_rebaseline_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: drift I11 database boundary"
  expect_i11_rebaseline_failure "${fixture_root}" \
    'I11_PERSISTENCE_REBASELINE_PROJECTION_MISMATCH'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-rebaseline-extra-projection"
  new_i11_rebaseline_fixture "${fixture_root}"
  materialize_i11_rebaseline_governance "${fixture_root}"
  make_i11_rebaseline_projection "${fixture_root}"
  printf '%s\n' 'forbidden projection path' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add "${i11_rebaseline_projection_paths[@]}" README.md
  git -C "${fixture_root}" commit -qm "test: exceed I11 rebaseline projection"
  expect_i11_rebaseline_failure "${fixture_root}" \
    'I11_PERSISTENCE_REBASELINE_PROJECTION_PATHS_INVALID:exact paths'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-rebaseline-mode"
  new_i11_rebaseline_fixture "${fixture_root}"
  materialize_i11_rebaseline_governance "${fixture_root}"
  make_i11_rebaseline_projection "${fixture_root}"
  chmod 755 "${fixture_root}/${i11_rebaseline_card_path}"
  git -C "${fixture_root}" add "${i11_rebaseline_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: drift I11 projection mode"
  expect_i11_rebaseline_failure "${fixture_root}" \
    'I11_PERSISTENCE_REBASELINE_PROJECTION_PATHS_INVALID:mode'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-rebaseline-post-outside"
  new_i11_rebaseline_fixture "${fixture_root}"
  materialize_i11_rebaseline_governance "${fixture_root}"
  commit_i11_rebaseline_projection "${fixture_root}"
  printf '%s\n' 'forbidden post rebaseline path' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add README.md
  git -C "${fixture_root}" commit -qm "test: exceed I11 product WriteSet"
  expect_i11_rebaseline_failure "${fixture_root}" \
    'I11_PERSISTENCE_REBASELINE_DESCENDANT_OUTSIDE_WRITE_SET'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-rebaseline-wrong-origin"
  new_i11_rebaseline_fixture "${fixture_root}"
  materialize_i11_rebaseline_governance_variant "${fixture_root}" wrong-origin
  expect_i11_rebaseline_failure "${fixture_root}" \
    'I11_PERSISTENCE_REBASELINE_INVALID:origin'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-rebaseline-wrong-count"
  new_i11_rebaseline_fixture "${fixture_root}"
  materialize_i11_rebaseline_governance_variant "${fixture_root}" wrong-count
  expect_i11_rebaseline_failure "${fixture_root}" \
    'I11_PERSISTENCE_REBASELINE_INVALID:exact governance commits'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-rebaseline-wrong-order"
  new_i11_rebaseline_fixture "${fixture_root}"
  materialize_i11_rebaseline_governance_variant "${fixture_root}" wrong-order
  expect_i11_rebaseline_failure "${fixture_root}" \
    'I11_PERSISTENCE_REBASELINE_INVALID:path'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-rebaseline-merge"
  new_i11_rebaseline_fixture "${fixture_root}"
  materialize_i11_rebaseline_governance_variant "${fixture_root}" merge
  expect_i11_rebaseline_failure "${fixture_root}" \
    'I11_PERSISTENCE_REBASELINE_INVALID:single parent'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-rebaseline-empty"
  new_i11_rebaseline_fixture "${fixture_root}"
  materialize_i11_rebaseline_governance_variant "${fixture_root}" empty
  expect_i11_rebaseline_failure "${fixture_root}" \
    'I11_PERSISTENCE_REBASELINE_INVALID:empty'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-rebaseline-rename"
  new_i11_rebaseline_fixture "${fixture_root}"
  materialize_i11_rebaseline_governance_variant "${fixture_root}" rename
  expect_i11_rebaseline_failure "${fixture_root}" \
    'I11_PERSISTENCE_REBASELINE_INVALID:rename or copy'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-rebaseline-copy"
  new_i11_rebaseline_fixture "${fixture_root}"
  materialize_i11_rebaseline_governance_variant "${fixture_root}" copy
  expect_i11_rebaseline_failure "${fixture_root}" \
    'I11_PERSISTENCE_REBASELINE_INVALID:rename or copy'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-rebaseline-nul"
  new_i11_rebaseline_fixture "${fixture_root}"
  materialize_i11_rebaseline_governance_variant "${fixture_root}" NUL
  expect_i11_rebaseline_failure "${fixture_root}" \
    'I11_PERSISTENCE_REBASELINE_INVALID:NUL'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-rebaseline-obsolete-write-set"
  new_i11_rebaseline_fixture "${fixture_root}"
  materialize_i11_rebaseline_governance "${fixture_root}"
  old_card="${fixture_root}/.i11-origin-card"
  git -C "${fixture_root}" show \
    "HEAD:${i11_rebaseline_card_path}" > "${old_card}"
  old_write_set="$(sed -n 's/^WriteSet = //p' "${old_card}" | sed 's/^/WriteSet = /')"
  old_forbidden_set="$(sed -n 's/^ForbiddenWriteSet = //p' "${old_card}" | sed 's/^/ForbiddenWriteSet = /')"
  make_i11_rebaseline_projection "${fixture_root}"
  I11_WRITE_SET="${old_write_set}" perl -0777 -i.bak -pe \
    's/(?:^WriteSet = .*\n)+/$ENV{I11_WRITE_SET}."\n"/mge' \
    "${fixture_root}/${i11_rebaseline_card_path}"
  rm "${fixture_root}/${i11_rebaseline_card_path}.bak"
  I11_FORBIDDEN_SET="${old_forbidden_set}" perl -0777 -i.bak -pe \
    's/(?:^ForbiddenWriteSet = .*\n)+/$ENV{I11_FORBIDDEN_SET}."\n"/mge' \
    "${fixture_root}/${i11_rebaseline_card_path}"
  rm "${fixture_root}/${i11_rebaseline_card_path}.bak" "${old_card}"
  git -C "${fixture_root}" add "${i11_rebaseline_projection_paths[@]}"
  git -C "${fixture_root}" commit -qm "test: retain obsolete I11 WriteSet"
  expect_i11_rebaseline_failure "${fixture_root}" \
    'I11_PERSISTENCE_REBASELINE_PROJECTION_MISMATCH:content:docs/task-cards/wave-1-implementation/W1-I11-partial-acceptance-command-api.md'
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 2 ]] || fail "I11 rebaseline positive count mismatch"
  [[ "${negative_cases}" -eq 15 ]] || fail "I11 rebaseline negative count mismatch"
  printf '%s\n' \
    'W1I11PersistenceRebaselineContractTests = PASS' \
    "W1I11PersistenceRebaselinePositiveCases = ${positive_cases}" \
    "W1I11PersistenceRebaselineNegativeCases = ${negative_cases}"
}

i11_migration_count_origin_sha="35393f6e73a0e2299d92c64c783b152b4190ca59"
i11_migration_count_spec_sha="eaaa00b5b25976e629653894e9e3ca49ea5c6493"
i11_migration_count_spec_path="docs/superpowers/specs/2026-08-22-cognitura-w1-i11-migration-count-regression-rebaseline.md"
i11_migration_count_card_path="docs/task-cards/wave-1-implementation/W1-I11-partial-acceptance-command-api.md"
i11_migration_count_test_path="tests/task-cards/verify-wave1-implementation-cards.sh"
i11_migration_count_verifier_path="scripts/verify-wave1-implementation-cards"
i11_migration_count_added_paths=(
  server/src/test/java/io/cognitura/source/application/command/SourceUploadCommandIntegrationTest.java
  server/src/test/java/io/cognitura/source/persistence/JdbcProcessingPublicationPortIntegrationTest.java
  server/src/test/java/io/cognitura/source/persistence/SourcePersistenceIntegrationTest.java
)

new_i11_migration_count_fixture() {
  local fixture_root="$1" origin="${2:-${i11_migration_count_origin_sha}}"
  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach "${origin}"
  git -C "${fixture_root}" config user.name "Cognitura Contract Test"
  git -C "${fixture_root}" config user.email "contract-test@cognitura.invalid"
}

i11_migration_count_test_sha() {
  git -C "${repo_root}" rev-list --first-parent --reverse \
    "${i11_migration_count_spec_sha}..HEAD" -- "${i11_migration_count_test_path}" |
    sed -n '1p'
}

materialize_i11_migration_count_governance() {
  local fixture_root="$1" drift="${2:-none}" test_sha
  test_sha="$(i11_migration_count_test_sha)"
  [[ -n "${test_sha}" ]] || fail "I11 migration-count test evidence is unavailable"
  commit_i11_rebaseline_fixed_blob "${fixture_root}" "${i11_migration_count_spec_sha}" \
    "${i11_migration_count_spec_path}" "docs: admit I11 migration count regression" 644
  if [[ "${drift}" == spec ]]; then
    printf '%s\n' 'drift' >> "${fixture_root}/${i11_migration_count_spec_path}"
    git -C "${fixture_root}" add "${i11_migration_count_spec_path}"
    git -C "${fixture_root}" commit --amend -qm \
      "docs: drift I11 migration count regression"
  fi
  commit_i11_rebaseline_fixed_blob "${fixture_root}" "${test_sha}" \
    "${i11_migration_count_test_path}" "test: require I11 migration count rebaseline" 755
  cp "${repo_root}/${i11_migration_count_verifier_path}" \
    "${fixture_root}/${i11_migration_count_verifier_path}"
  chmod 755 "${fixture_root}/${i11_migration_count_verifier_path}"
  git -C "${fixture_root}" add "${i11_migration_count_verifier_path}"
  git -C "${fixture_root}" commit -qm "build: verify I11 migration count rebaseline"
}

make_i11_migration_count_projection() {
  local fixture_root="$1" count="${2:-3}" card lines
  card="${fixture_root}/${i11_migration_count_card_path}"
  lines="$(printf '%s\n' "${i11_migration_count_added_paths[@]:0:${count}}" |
    sed 's/^/WriteSet = /')"
  I11_MIGRATION_LINES="${lines}" perl -i.bak -pe '
    if (!$done && /^ForbiddenWriteSet = /) {
      print $ENV{I11_MIGRATION_LINES}."\n";
      $done = 1;
    }
  ' "${card}"
  rm "${card}.bak"
}

commit_i11_migration_count_projection() {
  local fixture_root="$1"
  make_i11_migration_count_projection "${fixture_root}"
  git -C "${fixture_root}" add "${i11_migration_count_card_path}"
  git -C "${fixture_root}" commit -qm "docs: admit I11 migration regression tests"
}

run_i11_migration_count_fixture_verifier() {
  local fixture_root="$1"
  "${verifier}" --repo-root "${fixture_root}" \
    --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation"
}

expect_i11_migration_count_failure() {
  local fixture_root="$1" expected="$2" output
  if output="$(run_i11_migration_count_fixture_verifier "${fixture_root}" 2>&1)"; then
    fail "invalid I11 migration-count rebaseline unexpectedly passed: ${expected}"
  fi
  assert_contains "${output}" "${expected}"
}

run_w1_i11_migration_count_rebaseline_contract() {
  local fixture_root output positive_cases=0 negative_cases=0 path

  fixture_root="${test_tmp_root}/w1-i11-migration-pending"
  new_i11_migration_count_fixture "${fixture_root}"
  materialize_i11_migration_count_governance "${fixture_root}"
  output="$(run_i11_migration_count_fixture_verifier "${fixture_root}")" ||
    fail "legal I11 migration-count governance was rejected: ${output}"
  assert_contains "${output}" 'W1I11MigrationCountRebaselineStatus = PENDING'
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-migration-product"
  new_i11_migration_count_fixture "${fixture_root}"
  materialize_i11_migration_count_governance "${fixture_root}"
  commit_i11_migration_count_projection "${fixture_root}"
  path="${i11_migration_count_added_paths[0]}"
  perl -i.bak -pe 's/migrationsExecuted\)\.isEqualTo\(2\)/migrationsExecuted).isEqualTo(3)/' \
    "${fixture_root}/${path}"
  rm "${fixture_root}/${path}.bak"
  git -C "${fixture_root}" add "${path}"
  git -C "${fixture_root}" commit -qm "test: align I11 migration count"
  output="$(run_i11_migration_count_fixture_verifier "${fixture_root}")" ||
    fail "legal I11 migration-count descendant was rejected: ${output}"
  assert_contains "${output}" 'W1I11MigrationCountRebaselineStatus = PASS'
  positive_cases=$((positive_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-migration-spec-drift"
  new_i11_migration_count_fixture "${fixture_root}"
  materialize_i11_migration_count_governance "${fixture_root}" spec
  expect_i11_migration_count_failure "${fixture_root}" \
    'I11_MIGRATION_COUNT_REBASELINE_INVALID:evidence'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-migration-wrong-origin"
  new_i11_migration_count_fixture "${fixture_root}" "${i11_migration_count_origin_sha}^"
  materialize_i11_migration_count_governance "${fixture_root}"
  expect_i11_migration_count_failure "${fixture_root}" \
    'I11_MIGRATION_COUNT_REBASELINE_INVALID:origin'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-migration-missing-projection"
  new_i11_migration_count_fixture "${fixture_root}"
  materialize_i11_migration_count_governance "${fixture_root}"
  make_i11_migration_count_projection "${fixture_root}" 2
  git -C "${fixture_root}" add "${i11_migration_count_card_path}"
  git -C "${fixture_root}" commit -qm "test: omit I11 migration regression path"
  expect_i11_migration_count_failure "${fixture_root}" \
    'I11_MIGRATION_COUNT_PROJECTION_INVALID:content'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-migration-extra-projection"
  new_i11_migration_count_fixture "${fixture_root}"
  materialize_i11_migration_count_governance "${fixture_root}"
  make_i11_migration_count_projection "${fixture_root}"
  printf '%s\n' 'outside projection' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add "${i11_migration_count_card_path}" README.md
  git -C "${fixture_root}" commit -qm "test: exceed I11 migration projection"
  expect_i11_migration_count_failure "${fixture_root}" \
    'I11_MIGRATION_COUNT_PROJECTION_INVALID:exact path'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-migration-wrong-count"
  new_i11_migration_count_fixture "${fixture_root}"
  materialize_i11_migration_count_governance "${fixture_root}"
  commit_i11_migration_count_projection "${fixture_root}"
  path="${i11_migration_count_added_paths[1]}"
  perl -i.bak -pe 's/migrationsExecuted\)\.isEqualTo\(2\)/migrationsExecuted).isEqualTo(4)/' \
    "${fixture_root}/${path}"
  rm "${fixture_root}/${path}.bak"
  git -C "${fixture_root}" add "${path}"
  git -C "${fixture_root}" commit -qm "test: drift I11 migration count"
  expect_i11_migration_count_failure "${fixture_root}" \
    'I11_MIGRATION_COUNT_DESCENDANT_INVALID:content'
  negative_cases=$((negative_cases + 1))

  fixture_root="${test_tmp_root}/w1-i11-migration-post-outside"
  new_i11_migration_count_fixture "${fixture_root}"
  materialize_i11_migration_count_governance "${fixture_root}"
  commit_i11_migration_count_projection "${fixture_root}"
  printf '%s\n' 'outside exact16' >> "${fixture_root}/README.md"
  git -C "${fixture_root}" add README.md
  git -C "${fixture_root}" commit -qm "test: exceed I11 exact16"
  expect_i11_migration_count_failure "${fixture_root}" \
    'I11_MIGRATION_COUNT_DESCENDANT_OUTSIDE_WRITE_SET'
  negative_cases=$((negative_cases + 1))

  [[ "${positive_cases}" -eq 2 ]] || fail "I11 migration positive count mismatch"
  [[ "${negative_cases}" -eq 6 ]] || fail "I11 migration negative count mismatch"
  printf '%s\n' \
    'W1I11MigrationCountRebaselineContractTests = PASS' \
    "W1I11MigrationCountRebaselinePositiveCases = ${positive_cases}" \
    "W1I11MigrationCountRebaselineNegativeCases = ${negative_cases}"
}

if [[ "${w1_i10_closure_contract_only}" == "1" ]]; then
  run_w1_i10_closure_contract
  exit 0
fi

if [[ "${w1_i11_persistence_rebaseline_contract_only}" == "1" ]]; then
  run_w1_i11_persistence_rebaseline_contract
  exit 0
fi

if [[ "${w1_i11_migration_count_rebaseline_contract_only}" == "1" ]]; then
  run_w1_i11_migration_count_rebaseline_contract
  exit 0
fi

if [[ "${terra_first_routing_contract_only}" == "1" ]]; then
  run_terra_first_routing_contract
  exit 0
fi

[[ -x "${verifier}" ]] || fail "Wave 1 implementation task-card verifier is missing or not executable"

run_w1_i05_closure_contract
run_w1_i06_entry_repair_contract
run_w1_i06_copy_inference_repair_contract
run_w1_i06_closure_contract
run_w1_i02_database_gate_contract
run_w1_i02_closure_contract
run_w1_i07_closure_contract
run_w1_i08_closure_contract
run_w1_i09_runtime_rebaseline_repair_contract
run_w1_i09_product_copy_inference_contract
run_w1_i09_canonical_bridge_contract
run_w1_i09_v2_compatibility_contract
run_w1_i09_final_review_finding_contract
run_w1_i09_closure_contract
run_w1_i10_closure_contract
run_w1_i11_persistence_rebaseline_contract
run_w1_i11_migration_count_rebaseline_contract

validation_output="$(
  "${verifier}" \
    --cards-dir "${cards_dir}"
)"

assert_contains "${validation_output}" "Wave1ImplementationTaskCardValidation = PASS"
assert_contains "${validation_output}" "TaskCardCount = 14"

fixed_suspension_root="${test_tmp_root}/fixed-suspension"
git clone --shared -q "${repo_root}" "${fixed_suspension_root}"
checkout_fixed_suspension_fixture "${fixed_suspension_root}"
canonical_cards_dir="${fixed_suspension_root}/docs/task-cards/wave-1-implementation"

ready_i00_dir="${test_tmp_root}/ready-i00"
make_ready_i00_fixture "${canonical_cards_dir}" "${ready_i00_dir}"
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
suspended_output="$(
  "${verifier}" \
    --repo-root "${fixed_suspension_root}" \
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

expect_both_static_verifiers_fail() {
  local fixture_root="$1"
  local expected_message="$2"
  local wave_output vsb_output
  local wave_passed=0
  local vsb_passed=0
  if wave_output="$(
    "${verifier}" \
      --repo-root "${fixture_root}" \
      --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" 2>&1
  )"; then
    wave_passed=1
  fi
  if vsb_output="$(
    "${repo_root}/scripts/verify-visual-style-baseline-cards" \
      --repo-root "${fixture_root}" \
      --cards-dir "${fixture_root}/docs/task-cards/visual-style-baseline" 2>&1
  )"; then
    vsb_passed=1
  fi
  [[ "${wave_passed}" -eq 0 ]] ||
    fail "Wave 1 static validator accepted a drifted suspended projection"
  [[ "${vsb_passed}" -eq 0 ]] ||
    fail "VSB static validator accepted a drifted suspended projection"
  assert_contains "${wave_output}" "${expected_message}"
  assert_contains "${vsb_output}" "Wave 1 static suspension validation failed"
}

expect_wave_static_verifier_fail() {
  local fixture_root="$1"
  local expected_message="$2"
  local wave_output
  if wave_output="$(
    "${verifier}" \
      --repo-root "${fixture_root}" \
      --cards-dir "${fixture_root}/docs/task-cards/wave-1-implementation" 2>&1
  )"; then
    fail "Wave 1 static validator accepted a drifted suspended narrative projection"
  fi
  assert_contains "${wave_output}" "${expected_message}"
}

replace_exact_block() {
  local file="$1"
  local old_text="$2"
  local new_text="$3"
  local label="$4"
  local content prefix suffix rewritten
  content="$(cat "${file}"; printf '\034')"
  [[ "${content}" == *"${old_text}"* ]] ||
    fail "${label}: source block is missing"
  prefix="${content%%"${old_text}"*}"
  suffix="${content#*"${old_text}"}"
  [[ "${suffix}" != *"${old_text}"* ]] ||
    fail "${label}: source block is duplicated"
  rewritten="${prefix}${new_text}${suffix}"
  printf '%s' "${rewritten%$'\034'}" > "${file}"
}

sync_fixed_suspension_projection() {
  local fixture_root="$1"
  checkout_fixed_suspension_fixture "${fixture_root}"
}

suspension_narrative_paths=(
  AGENTS.md
  AGENTS.md
  README.md
  README.md
  docs/design/wave-1/README.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-plan.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1/README.md
  docs/task-cards/wave-1-implementation/README.md
)
suspension_narratives=(
  $'`W1-I02` 等待独立数据库 Gate；`W1-I03` 已冻结在\n`4e63936c631ab34807e714b90d30415a959bc13d`，当前没有 Wave 1 READY 卡。'
  $'I00；I01 已关闭，I02 保持等待独立数据库 Gate；I03 在 Visual Style Baseline\n执行期间冻结为 `SUSPENDED_BY_USER`。'
  $'完成零发现深审并关闭；I02 等待独立数据库 Gate。`W1-I03` 已冻结在\n`4e63936c631ab34807e714b90d30415a959bc13d`，当前没有 Wave 1 READY 卡；'
  $'保持 `QUEUED` 等待独立数据库 Gate；`W1-I03` 在 Visual Style Baseline 期间为\n`SUSPENDED_BY_USER`，冻结候选 production WriteSet 不得变更。'
  $'  I01 已关闭，I02 等待独立数据库 Gate；I03 在 Visual Style Baseline 期间冻结为\n  `SUSPENDED_BY_USER`，当前没有 Wave 1 READY 卡。'
  $'`W1-I03` 在独立 Visual Style Baseline 执行期间冻结为 `SUSPENDED_BY_USER`，当前\n没有 Wave 1 READY 卡；冻结 production WriteSet 不得变更。'
  $'当前业务授权保持有效，但 `W1-I03` 在 Visual Style Baseline 期间暂停；I02 独立\n数据库 Gate、正式数据库写入和远程推送仍未授权。'
  $'固定候选深审并关闭；I02 等待独立数据库 Gate，I03 在 Visual Style Baseline 期间\n冻结为 `SUSPENDED_BY_USER`，当前没有 Wave 1 READY 卡；完整证据记录在'
  $'数据库 Gate；I03 在 Visual Style Baseline 期间冻结为 `SUSPENDED_BY_USER`，当前没有\nWave 1 READY 卡。正式数据库、Parser/Object Storage Provider、'
  'I03 在 Visual Style Baseline 执行期间冻结为 `SUSPENDED_BY_USER`；当前没有 READY 卡。'
  $'I00 和 I01 已关闭；I02 等待独立数据库 Gate。W1-I03 在 Visual Style Baseline\n期间冻结为 `SUSPENDED_BY_USER`，当前没有 Wave 1 READY 卡。'
  $'完成零发现深审并关闭；I02 等待独立数据库 Gate。独立 Visual Style Baseline 执行\n期间，I03 冻结在 `4e63936c631ab34807e714b90d30415a959bc13d`，不得修改其\nproduction WriteSet。'
)
ready_narratives=(
  '`W1-I02` 等待独立数据库 Gate，`W1-I03` 为唯一 `READY` 业务卡。'
  'I00；I01 已关闭，当前已原子释放 I03，I02 保持等待独立数据库 Gate。'
  '完成零发现深审并关闭；I02 等待独立数据库 Gate，`W1-I03` 是唯一 `READY` 卡。'
  '保持 `QUEUED` 等待独立数据库 Gate，`W1-I03` 已释放为唯一 `READY` 业务卡。'
  '  I01 已关闭，I02 等待独立数据库 Gate，I03 为唯一 `READY` 卡。'
  '`W1-I03` 已作为唯一 `READY` 卡释放。'
  $'当前业务授权只按既定卡集串行推进至 `W1-I03`；I02 独立数据库 Gate、正式数据库\n写入和远程推送仍未授权。'
  '固定候选深审并关闭；I02 等待独立数据库 Gate，I03 为唯一 `READY` 卡，完整证据记录在'
  '数据库 Gate，I03 为唯一 `READY` 卡。正式数据库、Parser/Object Storage Provider、'
  'I03 为唯一 `READY` 卡。'
  'I00 和 I01 已关闭；I02 等待独立数据库 Gate，W1-I03 为唯一 `READY` 业务卡。'
  '完成零发现深审并关闭；I02 等待独立数据库 Gate，I03 已原子释放为唯一 `READY` 卡。'
)

static_narrative_base_root="${test_tmp_root}/static-narrative-base"
git clone --shared --no-checkout -q "${repo_root}" "${static_narrative_base_root}"
git -C "${static_narrative_base_root}" checkout -q
sync_fixed_suspension_projection "${static_narrative_base_root}"
git -C "${static_narrative_base_root}" add \
  docs/engineering/cognitura-wave-1-design-acceptance.md
git -C "${static_narrative_base_root}" commit --allow-empty -qm \
  "test: establish exact suspension narrative projection"

current_narrative_cleanup_tmp="$(
  mktemp -d "${test_tmp_root}/round13-current-narrative-tmp.XXXXXX"
)"
replace_exact_block \
  "${static_narrative_base_root}/${suspension_narrative_paths[0]}" \
  "${suspension_narratives[0]}" \
  "${ready_narratives[0]}" \
  "exercise current-narrative cleanup after validation failure"
if current_narrative_cleanup_output="$(
  TMPDIR="${current_narrative_cleanup_tmp}" "${verifier}" \
    --repo-root "${static_narrative_base_root}" \
    --cards-dir "${static_narrative_base_root}/docs/task-cards/wave-1-implementation" 2>&1
)"; then
  fail "current narrative cleanup negative unexpectedly passed"
fi
assert_contains "${current_narrative_cleanup_output}" \
  "current suspension narrative projection mismatch"
shopt -s nullglob
current_narrative_leaks=(
  "${current_narrative_cleanup_tmp}"/cognitura-current-narratives.*
)
shopt -u nullglob
[[ "${#current_narrative_leaks[@]}" -eq 0 ]] ||
  fail "current narrative verifier leaked its registered temporary directory"
git -C "${static_narrative_base_root}" restore \
  "${suspension_narrative_paths[0]}"

for narrative_index in "${!suspension_narratives[@]}"; do
  narrative_path="${suspension_narrative_paths[${narrative_index}]}"
  git -C "${static_narrative_base_root}" switch -q --detach HEAD
  replace_exact_block \
    "${static_narrative_base_root}/${narrative_path}" \
    "${suspension_narratives[${narrative_index}]}" \
    "${ready_narratives[${narrative_index}]}" \
    "drift ${narrative_path} suspension narrative"
  if [[ "${narrative_index}" -eq 8 ]]; then
    expect_both_static_verifiers_fail \
      "${static_narrative_base_root}" \
      "current suspension narrative projection mismatch"
  else
    expect_wave_static_verifier_fail \
      "${static_narrative_base_root}" \
      "current suspension narrative projection mismatch"
  fi
  git -C "${static_narrative_base_root}" restore "${narrative_path}"
done

static_plan_contradictory_row_root="${test_tmp_root}/static-plan-contradictory-row"
git clone --shared -q "${repo_root}" "${static_plan_contradictory_row_root}"
sync_fixed_suspension_projection "${static_plan_contradictory_row_root}"
printf '%s\n' \
  '| `W1-I03` | DOCX security | `I01` | `READY` |' >> \
  "${static_plan_contradictory_row_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
git -C "${static_plan_contradictory_row_root}" add \
  docs/engineering/cognitura-wave-1-implementation-plan.md
git -C "${static_plan_contradictory_row_root}" commit -qm \
  "test: add contradictory current implementation-plan row"
expect_both_static_verifiers_fail \
  "${static_plan_contradictory_row_root}" \
  "current suspension projection mismatch"

static_plan_unexpected_rows_root="${test_tmp_root}/static-plan-unexpected-rows"
git clone --shared -q "${repo_root}" "${static_plan_unexpected_rows_root}"
sync_fixed_suspension_projection "${static_plan_unexpected_rows_root}"
printf '%s\n' \
  '| `W1-I03` | DOCX security | `I01` | `QUEUED` |' \
  '| `W1-I03` | altered projection text | `I01` | `NOT_A_REAL_STATE` |' >> \
  "${static_plan_unexpected_rows_root}/docs/engineering/cognitura-wave-1-implementation-plan.md"
git -C "${static_plan_unexpected_rows_root}" add \
  docs/engineering/cognitura-wave-1-implementation-plan.md
git -C "${static_plan_unexpected_rows_root}" commit -qm \
  "test: add unexpected current implementation-plan rows"
expect_both_static_verifiers_fail \
  "${static_plan_unexpected_rows_root}" \
  "current suspension projection mismatch"

static_plan_row_drift_root="${test_tmp_root}/static-plan-row-drift"
git clone --shared -q "${repo_root}" "${static_plan_row_drift_root}"
sync_fixed_suspension_projection "${static_plan_row_drift_root}"
set_table_status \
  "${static_plan_row_drift_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
  "W1-I03" \
  "SUSPENDED_BY_USER" \
  "READY"
git -C "${static_plan_row_drift_root}" add \
  docs/engineering/cognitura-wave-1-implementation-plan.md
git -C "${static_plan_row_drift_root}" commit -qm \
  "test: drift current suspended implementation-plan row"
expect_both_static_verifiers_fail \
  "${static_plan_row_drift_root}" \
  "current suspension projection mismatch"

static_agents_active_drift_root="${test_tmp_root}/static-agents-active-drift"
git clone --shared -q "${repo_root}" "${static_agents_active_drift_root}"
sync_fixed_suspension_projection "${static_agents_active_drift_root}"
set_field "${static_agents_active_drift_root}/AGENTS.md" \
  "ActiveTaskCard" "W1-I03"
set_field "${static_agents_active_drift_root}/AGENTS.md" \
  "ActiveTaskCardStatus" "READY"
git -C "${static_agents_active_drift_root}" add AGENTS.md
git -C "${static_agents_active_drift_root}" commit -qm \
  "test: drift current suspended active task projections"
expect_both_static_verifiers_fail \
  "${static_agents_active_drift_root}" \
  "ActiveTaskCard projection mismatch"

static_database_auth_drift_root="${test_tmp_root}/static-database-auth-drift"
git clone --shared -q "${repo_root}" "${static_database_auth_drift_root}"
sync_fixed_suspension_projection "${static_database_auth_drift_root}"
set_field "${static_database_auth_drift_root}/AGENTS.md" \
  "FormalDatabaseWrite" "AUTHORIZED"
git -C "${static_database_auth_drift_root}" add AGENTS.md
git -C "${static_database_auth_drift_root}" commit -qm \
  "test: drift current suspended database authorization"
expect_both_static_verifiers_fail \
  "${static_database_auth_drift_root}" \
  "current suspension projection mismatch"

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
transition_paths=("${fixed_suspension_paths[@]}")
checkout_fixed_suspension_fixture "${transition_repo_root}"
transition_state="${transition_repo_root}/docs/task-cards/visual-style-baseline/execution-state.md"
git -C "${transition_repo_root}" add "${transition_paths[@]}" \
  docs/task-cards/visual-style-baseline
git -C "${transition_repo_root}" commit --allow-empty -qm \
  "test: establish suspended Wave 1 bootstrap fixture"

printf '%s\n' 'fixed governance review input' > \
  "${transition_repo_root}/docs/task-cards/visual-style-baseline/governance-review-input.md"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/governance-review-input.md
git -C "${transition_repo_root}" commit -qm \
  "test: create VSB governance candidate"
governance_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "GovernanceBootstrapStatus" "PASS"
set_field "${transition_state}" "GovernanceReviewedCandidateSHA" \
  "${governance_candidate_sha}"
set_field "${transition_state}" "GovernanceReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "TaskCardSetStatus" "IN_PROGRESS"
set_field "${transition_state}" "ActiveTaskCard" "VSB-00"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-00"
set_field "${transition_state}" "NextTaskCard" "VSB-01"
set_field "${transition_state}" "TransitionSequence" "1"
set_field "${transition_state}" "TransitionKind" "ACTIVATE_SET"
set_field "${transition_state}" "TransitionBaseSHA" "${governance_candidate_sha}"
set_field "${transition_state}" "VisualImplementation" "USER_AUTHORIZED"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm "test: activate VSB fixture"
activation_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"

set_field "${transition_state}" "TaskCardSetStatus" "STOPPED_BY_USER"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "CurrentGateStatus" "STOPPED_BY_USER"
set_field "${transition_state}" "CurrentReviewRoute" "NONE"
set_field "${transition_state}" "CurrentReviewVerdict" "NOT_APPLICABLE_USER_STOP"
set_field "${transition_state}" "TransitionSequence" "2"
set_field "${transition_state}" "TransitionKind" "STOP_BY_USER"
set_field "${transition_state}" "TransitionBaseSHA" "${activation_sha}"
set_field "${transition_state}" "VisualImplementation" "STOPPED_BY_USER"
set_field "${transition_state}" "UserStopAuthorization" "EXPLICIT_USER_INSTRUCTION"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: stop VSB by explicit user instruction"
suspension_git_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
allowed_visual_sha="${suspension_git_sha}"
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
  local narrative_index narrative_path
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
  for narrative_index in "${!suspension_narratives[@]}"; do
    narrative_path="${suspension_narrative_paths[${narrative_index}]}"
    replace_exact_block \
      "${fixture_root}/${narrative_path}" \
      "${suspension_narratives[${narrative_index}]}" \
      "${ready_narratives[${narrative_index}]}" \
      "restore ${narrative_path} READY narrative"
  done
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
printf '%s\n' 'merge restore side history' > \
  "${transition_repo_root}/docs/task-cards/wave-1-implementation/round12-side.txt"
git -C "${transition_repo_root}" add \
  docs/task-cards/wave-1-implementation/round12-side.txt
git -C "${transition_repo_root}" commit -qm \
  "test: create side parent for Wave restore"
merge_restore_side_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
git -C "${transition_repo_root}" switch -q --detach "${allowed_visual_sha}"
git -C "${transition_repo_root}" merge -q --no-ff -s ours --no-commit \
  "${merge_restore_side_sha}"
make_restore_projection "${transition_repo_root}"
git -C "${transition_repo_root}" add "${transition_paths[@]}"
git -C "${transition_repo_root}" commit -qm \
  "test: create merge Wave restore"
merge_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
merge_restore_parent_line="$(
  git -C "${transition_repo_root}" rev-list --parents -n 1 "${merge_restore_sha}"
)"
set -- ${merge_restore_parent_line}
[[ "$#" -eq 3 ]] || fail "merge restore fixture must have exactly two parents"
if merge_restore_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${allowed_visual_sha}" \
    --transition-head "${merge_restore_sha}" 2>&1
)"; then
  fail "merge Wave restore HEAD unexpectedly passed"
fi
assert_contains "${merge_restore_output}" \
  "restore transition HEAD must have exactly one parent"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${allowed_visual_sha}"
make_restore_projection "${transition_repo_root}"
set_field \
  "${transition_repo_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
  "ActiveImplementationGovernanceTaskCard" \
  "NONE"
git -C "${transition_repo_root}" add "${transition_paths[@]}"
git -C "${transition_repo_root}" commit -qm \
  "test: omit active governance card from restore acceptance"
inactive_acceptance_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if inactive_acceptance_restore_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${allowed_visual_sha}" \
    --transition-head "${inactive_acceptance_restore_sha}" 2>&1
)"; then
  fail "restore leaving acceptance governance card inactive unexpectedly passed"
fi
assert_contains "${inactive_acceptance_restore_output}" \
  "transition docs/engineering/cognitura-wave-1-design-acceptance.md: ActiveImplementationGovernanceTaskCard must equal W1-I03"

for narrative_index in "${!suspension_narratives[@]}"; do
  narrative_path="${suspension_narrative_paths[${narrative_index}]}"
  git -C "${transition_repo_root}" switch -q --detach "${allowed_visual_sha}"
  make_restore_projection "${transition_repo_root}"
  replace_exact_block \
    "${transition_repo_root}/${narrative_path}" \
    "${ready_narratives[${narrative_index}]}" \
    "${suspension_narratives[${narrative_index}]}" \
    "leave ${narrative_path} narrative suspended during restore"
  git -C "${transition_repo_root}" add "${transition_paths[@]}"
  git -C "${transition_repo_root}" commit -qm \
    "test: leave one narrative suspended during restore"
  incomplete_narrative_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
  if incomplete_narrative_output="$(
    "${verifier}" \
      --repo-root "${transition_repo_root}" \
      --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" \
      --transition-base "${allowed_visual_sha}" \
      --transition-head "${incomplete_narrative_restore_sha}" 2>&1
  )"; then
    fail "restore leaving one suspended narrative unexpectedly passed: ${narrative_path}"
  fi
  assert_contains "${incomplete_narrative_output}" \
    "restore transition HEAD must contain exact READY narrative projection"
done

git -C "${transition_repo_root}" switch -q --detach "${allowed_visual_sha}"
make_restore_projection "${transition_repo_root}"
replace_exact_block \
  "${transition_repo_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
  "${ready_narratives[8]}" \
  '数据库 Gate，I03 和 I04 为 `READY` 卡。正式数据库、Parser/Object Storage Provider、' \
  "write an incorrect READY narrative during restore"
git -C "${transition_repo_root}" add "${transition_paths[@]}"
git -C "${transition_repo_root}" commit -qm \
  "test: write incorrect READY narrative during restore"
wrong_narrative_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if wrong_narrative_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${allowed_visual_sha}" \
    --transition-head "${wrong_narrative_restore_sha}" 2>&1
)"; then
  fail "restore with an incorrect READY narrative unexpectedly passed"
fi
assert_contains "${wrong_narrative_output}" \
  "restore transition HEAD must contain exact READY narrative projection"

git -C "${transition_repo_root}" switch -q --detach "${allowed_visual_sha}"
make_restore_projection "${transition_repo_root}"
printf '%s\n' 'Unauthorized extra restore narrative.' >> \
  "${transition_repo_root}/README.md"
git -C "${transition_repo_root}" add "${transition_paths[@]}"
git -C "${transition_repo_root}" commit -qm \
  "test: add extra narrative during restore"
extra_narrative_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if extra_narrative_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${allowed_visual_sha}" \
    --transition-head "${extra_narrative_restore_sha}" 2>&1
)"; then
  fail "restore with an extra narrative change unexpectedly passed"
fi
assert_contains "${extra_narrative_output}" \
  "restore transition must preserve exact bytes and file mode"

git -C "${transition_repo_root}" switch -q --detach "${allowed_visual_sha}"
make_restore_projection "${transition_repo_root}"
printf '\n' >> "${transition_repo_root}/AGENTS.md"
git -C "${transition_repo_root}" add "${transition_paths[@]}"
git -C "${transition_repo_root}" commit -qm \
  "test: add a trailing newline during restore"
trailing_newline_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if trailing_newline_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${allowed_visual_sha}" \
    --transition-head "${trailing_newline_restore_sha}" 2>&1
)"; then
  fail "restore with trailing-newline drift unexpectedly passed"
fi
assert_contains "${trailing_newline_output}" \
  "restore transition must preserve exact bytes and file mode"

git -C "${transition_repo_root}" switch -q --detach "${allowed_visual_sha}"
make_restore_projection "${transition_repo_root}"
printf '\000' >> "${transition_repo_root}/AGENTS.md"
git -C "${transition_repo_root}" add "${transition_paths[@]}"
git -C "${transition_repo_root}" commit -qm \
  "test: add a NUL byte during restore"
nul_drift_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
nul_restore_cleanup_tmp="$(
  mktemp -d "${test_tmp_root}/round13-restore-compare-tmp.XXXXXX"
)"
if nul_drift_output="$(
  TMPDIR="${nul_restore_cleanup_tmp}" "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${allowed_visual_sha}" \
    --transition-head "${nul_drift_restore_sha}" 2>&1
)"; then
  fail "restore with NUL-byte drift unexpectedly passed"
fi
assert_contains "${nul_drift_output}" \
  "restore transition must preserve exact bytes and file mode"
shopt -s nullglob
nul_restore_compare_leaks=(
  "${nul_restore_cleanup_tmp}"/cognitura-restore-compare.*
)
shopt -u nullglob
[[ "${#nul_restore_compare_leaks[@]}" -eq 0 ]] ||
  fail "restore verifier leaked its registered temporary directory"

git -C "${transition_repo_root}" switch -q --detach "${allowed_visual_sha}"
make_restore_projection "${transition_repo_root}"
chmod 755 "${transition_repo_root}/AGENTS.md"
git -C "${transition_repo_root}" add "${transition_paths[@]}"
git -C "${transition_repo_root}" commit -qm \
  "test: change a restore projection file mode"
mode_drift_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if mode_drift_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_repo_root}/docs/task-cards/wave-1-implementation" \
    --transition-base "${allowed_visual_sha}" \
    --transition-head "${mode_drift_restore_sha}" 2>&1
)"; then
  fail "restore with 100644-to-100755 mode drift unexpectedly passed"
fi
assert_contains "${mode_drift_output}" \
  "restore transition must preserve exact bytes and file mode"

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
  "restore transition must preserve exact bytes and file mode"

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
restore_fixed_suspension_projection "${nonancestor_repo_root}"
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

git_transition_cases=11
narrative_suspension_cases=12
narrative_restore_cases=15
binary_restore_cases=1

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
  "GitTransitionCases = ${git_transition_cases}" \
  "NarrativeSuspensionCases = ${narrative_suspension_cases}" \
  "NarrativeRestoreCases = ${narrative_restore_cases}" \
  "BinaryRestoreCases = ${binary_restore_cases}"
