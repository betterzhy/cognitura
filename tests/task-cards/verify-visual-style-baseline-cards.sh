#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-visual-style-baseline-cards"
cards_dir="${repo_root}/docs/task-cards/visual-style-baseline"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-vsb-cards.XXXXXX")"
fixed_lifecycle_fixture_sha="c4d1f4342b16d2110369c4eefea5665edce0614d"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

git -C "${repo_root}" cat-file -e "${fixed_lifecycle_fixture_sha}^{commit}" 2>/dev/null ||
  fail "fixed lifecycle fixture commit is unavailable: ${fixed_lifecycle_fixture_sha}"

fixed_bootstrap_root="${test_tmp_root}/fixed-bootstrap"
mkdir -p "${fixed_bootstrap_root}"
git -C "${repo_root}" archive "${fixed_lifecycle_fixture_sha}" \
  docs/task-cards/visual-style-baseline | tar -x -C "${fixed_bootstrap_root}"
bootstrap_cards_dir="${fixed_bootstrap_root}/docs/task-cards/visual-style-baseline"

fixed_wave1_projection_paths=(
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

assert_contains() {
  local content="$1"
  local expected="$2"
  [[ "${content}" == *"${expected}"* ]] ||
    fail "validation output is missing: ${expected}"
}

assert_commit_parent_count() {
  local fixture_root="$1"
  local commit="$2"
  local expected="$3"
  local parent_line parent_count
  parent_line="$(git -C "${fixture_root}" rev-list --parents -n 1 "${commit}")"
  set -- ${parent_line}
  parent_count=$(($# - 1))
  [[ "${parent_count}" -eq "${expected}" ]] ||
    fail "fixture ${commit} must have ${expected} parents, found ${parent_count}"
}

set_field() {
  local file="$1"
  local field="$2"
  local value="$3"
  sed -i.bak "s#^${field} = .*\$#${field} = ${value}#" "${file}"
  rm "${file}.bak"
}

set_table_status() {
  local file="$1"
  local task_id="$2"
  local old_status="$3"
  local new_status="$4"
  sed -i.bak \
    "/^| \`${task_id}\` |/s/\`${old_status}\`/\`${new_status}\`/" \
    "${file}"
  rm "${file}.bak"
}

replace_exact_block() {
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

suspension_narrative_paths=(
  AGENTS.md AGENTS.md README.md README.md docs/design/wave-1/README.md
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

expect_failure() {
  local fixture_dir="$1"
  local expected_message="$2"
  local output
  if output="$(
    "${verifier}" \
      --repo-root "${repo_root}" \
      --cards-dir "${fixture_dir}" 2>&1
  )"; then
    fail "invalid fixture unexpectedly passed: ${fixture_dir}"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected error '${expected_message}', got: ${output}"
  negative_cases=$((negative_cases + 1))
}

expect_clean_early_exit() {
  local expected_rc="$1"
  local expected_output="$2"
  shift 2
  local output rc
  if output="$("${verifier}" "$@" 2>&1)"; then
    rc=0
  else
    rc=$?
  fi
  [[ "${rc}" -eq "${expected_rc}" ]] ||
    fail "early verifier exit returned ${rc}, expected ${expected_rc}: ${output}"
  [[ "${output}" == "${expected_output}" ]] ||
    fail "early verifier exit polluted its diagnostic: ${output}"
}

# Required RED: the verifier and governed set do not exist before Task 1.
[[ -x "${verifier}" ]] || fail "Visual Style Baseline task-card verifier is missing or not executable"
[[ -d "${cards_dir}" ]] || fail "Visual Style Baseline task-card set is missing"

expect_clean_early_exit 2 \
  'Usage: scripts/verify-visual-style-baseline-cards [--repo-root PATH] --cards-dir PATH [--transition-base SHA --transition-head SHA]'
missing_cards_dir="${test_tmp_root}/missing-cards-dir"
expect_clean_early_exit 1 \
  $'VisualStyleBaselineTaskCardValidation = FAIL\ncards directory does not exist: '"${missing_cards_dir}" \
  --repo-root "${repo_root}" --cards-dir "${missing_cards_dir}"
early_exit_cases=2

registered_cleanup_tmp="${test_tmp_root}/registered-cleanup"
registered_cleanup_cards="${test_tmp_root}/registered-cleanup-cards"
mkdir -p "${registered_cleanup_tmp}"
cp -R "${bootstrap_cards_dir}" "${registered_cleanup_cards}"
printf '\0' >> "${registered_cleanup_cards}/execution-state.md"
if registered_cleanup_output="$(
  TMPDIR="${registered_cleanup_tmp}" "${verifier}" \
    --repo-root "${repo_root}" \
    --cards-dir "${registered_cleanup_cards}" 2>&1
)"; then
  fail "NUL ledger cleanup negative unexpectedly passed"
else
  registered_cleanup_rc=$?
fi
[[ "${registered_cleanup_rc}" -eq 1 ]] ||
  fail "NUL ledger cleanup returned ${registered_cleanup_rc}, expected 1"
[[ "${registered_cleanup_output}" == $'VisualStyleBaselineTaskCardValidation = FAIL\ntransition ledger must not contain NUL bytes' ]] ||
  fail "NUL ledger cleanup polluted its diagnostic: ${registered_cleanup_output}"
shopt -s nullglob
registered_cleanup_leaks=(
  "${registered_cleanup_tmp}"/cognitura-vsb-nul-free.*
)
shopt -u nullglob
[[ "${#registered_cleanup_leaks[@]}" -eq 0 ]] ||
  fail "VSB verifier leaked a registered temporary path"
registered_temporary_cleanup_cases=1

validation_output="$(
  "${verifier}" \
    --repo-root "${repo_root}" \
    --cards-dir "${cards_dir}"
)" || fail "canonical Visual Style Baseline state was rejected"
assert_contains "${validation_output}" "VisualStyleBaselineTaskCardValidation = PASS"
assert_contains "${validation_output}" "TaskCardCount = 4"

negative_cases=0

missing_state_dir="${test_tmp_root}/missing-state"
cp -R "${bootstrap_cards_dir}" "${missing_state_dir}"
rm "${missing_state_dir}/execution-state.md"
expect_failure "${missing_state_dir}" "execution-state.md is missing"

for field in ApprovedSpecSHA FrozenWave1CandidateSHA TaskCardSetStatus ActiveTaskCard \
  ReleasedTaskCard CompletedTaskCards CurrentCandidateSHA CurrentGateStatus \
  CurrentReviewRoute CurrentReviewVerdict TransitionSequence TransitionKind \
  TransitionBaseSHA VSB00CandidateSHA VSB00GateStatus VSB00ReviewVerdict \
  VSB01CandidateSHA VSB01GateStatus VSB01ReviewVerdict VSB02CandidateSHA \
  VSB02GateStatus VSB02ReviewVerdict VSB03CandidateSHA VSB03GateStatus \
  VSB03DeepReviewVerdict VSB03UltraReviewVerdict; do
  missing_field_dir="${test_tmp_root}/missing-${field}"
  cp -R "${bootstrap_cards_dir}" "${missing_field_dir}"
  sed -i.bak "/^${field} = /d" "${missing_field_dir}/execution-state.md"
  rm "${missing_field_dir}/execution-state.md.bak"
  expect_failure "${missing_field_dir}" "${field} must occur exactly once"

  duplicate_field_dir="${test_tmp_root}/duplicate-${field}"
  cp -R "${bootstrap_cards_dir}" "${duplicate_field_dir}"
  value="$(sed -n "s/^${field} = //p" "${duplicate_field_dir}/execution-state.md")"
  printf '%s = %s\n' "${field}" "${value}" >> \
    "${duplicate_field_dir}/execution-state.md"
  expect_failure "${duplicate_field_dir}" "${field} must occur exactly once"
done

fifth_card_dir="${test_tmp_root}/fifth-card"
cp -R "${bootstrap_cards_dir}" "${fifth_card_dir}"
cp "${fifth_card_dir}/VSB-03-fixed-visual-acceptance.md" \
  "${fifth_card_dir}/VSB-04-invented.md"
set_field "${fifth_card_dir}/VSB-04-invented.md" "TaskCardID" "VSB-04"
expect_failure "${fifth_card_dir}" "actual task card count 5 does not match 4"

unknown_id_dir="${test_tmp_root}/unknown-id"
cp -R "${bootstrap_cards_dir}" "${unknown_id_dir}"
set_field "${unknown_id_dir}/VSB-02-module-default-reading-visual.md" "TaskCardID" "VSB-99"
expect_failure "${unknown_id_dir}" "TaskCardID mismatch"

mutable_status_dir="${test_tmp_root}/mutable-status"
cp -R "${bootstrap_cards_dir}" "${mutable_status_dir}"
set_field "${mutable_status_dir}/VSB-01-semantic-tokens.md" "Status" "READY"
expect_failure "${mutable_status_dir}" "Status must be GOVERNED_BY_EXECUTION_STATE"

card_body_drift_dir="${test_tmp_root}/card-body-drift"
cp -R "${bootstrap_cards_dir}" "${card_body_drift_dir}"
printf '\nunauthorized body drift\n' >> \
  "${card_body_drift_dir}/VSB-01-semantic-tokens.md"
expect_failure "${card_body_drift_dir}" "card body contract digest mismatch for VSB-01"

wrong_spec_dir="${test_tmp_root}/wrong-spec"
cp -R "${bootstrap_cards_dir}" "${wrong_spec_dir}"
set_field "${wrong_spec_dir}/execution-state.md" "ApprovedSpecSHA" \
  "4e63936c631ab34807e714b90d30415a959bc13d"
expect_failure "${wrong_spec_dir}" "ApprovedSpecSHA mismatch"

wrong_frozen_dir="${test_tmp_root}/wrong-frozen"
cp -R "${bootstrap_cards_dir}" "${wrong_frozen_dir}"
set_field "${wrong_frozen_dir}/execution-state.md" "FrozenWave1CandidateSHA" \
  "70eefba5912e6884e4e7e1d6477a65f4091d6590"
expect_failure "${wrong_frozen_dir}" "FrozenWave1CandidateSHA mismatch"

premature_activation_dir="${test_tmp_root}/premature-activation"
cp -R "${bootstrap_cards_dir}" "${premature_activation_dir}"
set_field "${premature_activation_dir}/execution-state.md" "TaskCardSetStatus" "IN_PROGRESS"
set_field "${premature_activation_dir}/execution-state.md" "ActiveTaskCard" "VSB-00"
set_field "${premature_activation_dir}/execution-state.md" "ReleasedTaskCard" "VSB-00"
set_field "${premature_activation_dir}/execution-state.md" "NextTaskCard" "VSB-01"
set_field "${premature_activation_dir}/execution-state.md" "TransitionSequence" "1"
set_field "${premature_activation_dir}/execution-state.md" "TransitionKind" "ACTIVATE_SET"
set_field "${premature_activation_dir}/execution-state.md" "VisualImplementation" "USER_AUTHORIZED"
expect_failure "${premature_activation_dir}" "activation requires governance zero-finding GO"

for receipt_field in VSB00CandidateSHA VSB00GateStatus VSB00ReviewVerdict \
  VSB01CandidateSHA VSB01GateStatus VSB01ReviewVerdict VSB02CandidateSHA \
  VSB02GateStatus VSB02ReviewVerdict VSB03CandidateSHA VSB03GateStatus \
  VSB03DeepReviewVerdict VSB03UltraReviewVerdict; do
  overwritten_receipt_dir="${test_tmp_root}/overwritten-${receipt_field}"
  cp -R "${bootstrap_cards_dir}" "${overwritten_receipt_dir}"
  set_field "${overwritten_receipt_dir}/execution-state.md" "${receipt_field}" "FORGED"
  expect_failure "${overwritten_receipt_dir}" "bootstrap receipts must remain NONE or NOT_RUN"
done

two_active_dir="${test_tmp_root}/two-active"
cp -R "${premature_activation_dir}" "${two_active_dir}"
set_field "${two_active_dir}/execution-state.md" "ActiveTaskCard" "VSB-00,VSB-01"
expect_failure "${two_active_dir}" "ActiveTaskCard must name one known card or NONE"

skipped_prefix_dir="${test_tmp_root}/skipped-prefix"
cp -R "${premature_activation_dir}" "${skipped_prefix_dir}"
set_field "${skipped_prefix_dir}/execution-state.md" "CompletedTaskCards" "VSB-01"
expect_failure "${skipped_prefix_dir}" "CompletedTaskCards must be an exact card prefix"

for forbidden_literal in \
  'WriteSet = server/forbidden.java' \
  'WriteSet = schemas/forbidden.json' \
  'WriteSet = raw/forbidden.docx' \
  'WriteSet = web/src/App.tsx' \
  'WriteSet = web/src/main.tsx' \
  'WriteSet = web/src/routes/forbidden.tsx' \
  'WriteSet = docs/design/high-fidelity/evidence/forbidden.png' \
  'WriteSet = .idea/workspace.xml' \
  'WriteSet = FORMAL_DATABASE_WRITE' \
  'WriteSet = REMOTE_PUSH'; do
  slug="$(printf '%s' "${forbidden_literal}" | shasum -a 256 | cut -c1-8)"
  forbidden_dir="${test_tmp_root}/forbidden-${slug}"
  cp -R "${bootstrap_cards_dir}" "${forbidden_dir}"
  printf '%s\n' "${forbidden_literal}" >> \
    "${forbidden_dir}/VSB-02-module-default-reading-visual.md"
  expect_failure "${forbidden_dir}" "card body contract digest mismatch for VSB-02"
done

wave1_not_suspended_dir="${test_tmp_root}/wave1-not-suspended"
cp -R "${premature_activation_dir}" "${wave1_not_suspended_dir}"
set_field "${wave1_not_suspended_dir}/execution-state.md" \
  "GovernanceBootstrapStatus" "PASS"
set_field "${wave1_not_suspended_dir}/execution-state.md" \
  "GovernanceReviewedCandidateSHA" "70eefba5912e6884e4e7e1d6477a65f4091d6590"
set_field "${wave1_not_suspended_dir}/execution-state.md" \
  "GovernanceReviewVerdict" "GO_P0_0_P1_0_P2_0"
wave1_projection_root="${test_tmp_root}/wave1-projection-root"
git clone --shared -q "${repo_root}" "${wave1_projection_root}"
mkdir -p "${wave1_projection_root}/docs/task-cards/visual-style-baseline"
cp -R "${wave1_not_suspended_dir}/." \
  "${wave1_projection_root}/docs/task-cards/visual-style-baseline/"
mkdir -p "${wave1_projection_root}/docs/task-cards/wave-1-implementation"
cp -R "${repo_root}/docs/task-cards/wave-1-implementation/." \
  "${wave1_projection_root}/docs/task-cards/wave-1-implementation/"
wave1_projection_index="${wave1_projection_root}/docs/task-cards/wave-1-implementation/README.md"
wave1_projection_card="${wave1_projection_root}/docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md"
set_field "${wave1_projection_index}" "TaskCardSetStatus" "READY_FOR_EXECUTION"
set_field "${wave1_projection_index}" "ActiveTaskCard" "W1-I03"
set_field "${wave1_projection_index}" "SuspendedTaskCard" "NONE"
set_field "${wave1_projection_index}" "SuspendedCandidateSHA" "NONE"
set_field "${wave1_projection_index}" "SuspendedCandidateMutation" "NONE"
set_field "${wave1_projection_card}" "Status" "READY"
wave1_projection_output="$(
  "${verifier}" \
    --repo-root "${wave1_projection_root}" \
    --cards-dir "${wave1_projection_root}/docs/task-cards/visual-style-baseline" 2>&1
)" && fail "VSB in progress unexpectedly accepted restored Wave 1"
assert_contains "${wave1_projection_output}" "VSB in progress requires exact W1-I03 suspension"
negative_cases=$((negative_cases + 1))

# Real Git state transitions: candidate commits may contain business files, but
# every release/rollback/complete receipt is a direct child that changes only
# execution-state.md.
transition_repo_root="${test_tmp_root}/transition-repo"
git clone --shared -q "${repo_root}" "${transition_repo_root}"
git -C "${transition_repo_root}" checkout -q --detach \
  "${fixed_lifecycle_fixture_sha}"
git -C "${transition_repo_root}" add \
  docs/engineering/cognitura-wave-1-design-acceptance.md \
  docs/task-cards/visual-style-baseline \
  docs/task-cards/wave-1-implementation
git -C "${transition_repo_root}" commit --allow-empty -qm \
  "test: establish VSB bootstrap fixture"

transition_cards="${transition_repo_root}/docs/task-cards/visual-style-baseline"
transition_state="${transition_cards}/execution-state.md"
wave1_restore_paths=("${fixed_wave1_projection_paths[@]}")
candidate_write_sets=(
  'AGENTS.md
docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png
docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md
docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md
docs/engineering/cognitura-design-index.md
docs/engineering/cognitura-visual-style-baseline-manifest.yaml
scripts/import-visual-style-reference
scripts/verify-visual-style-baseline-reference
tests/visual-style-baseline/verify-reference.sh'
  'web/src/styles/tokens.css
web/src/styles/typography.css
web/src/styles/surfaces.css
web/src/styles/cognitive-visual.css
web/src/styles/cognitura.css
web/src/styles/style-contract.test.ts
scripts/verify-module-default-reading
tests/visual-style-baseline/verify-module-default-reading-toolchain.sh'
  'web/src/modules/module-reading/ModuleDefaultReading.tsx
web/src/modules/module-reading/ModuleDefaultReading.test.tsx
web/src/modules/module-reading/ModuleNarrative.tsx
web/src/modules/module-reading/ModuleNarrative.test.tsx
web/src/modules/module-reading/StageChainProjection.tsx
web/src/modules/module-reading/StageChainProjection.test.tsx
web/src/modules/module-reading/ModuleClosure.tsx
web/src/modules/module-reading/ModuleClosure.test.tsx
web/src/modules/module-reading/KeyRelations.tsx
web/src/modules/module-reading/KeyRelations.test.tsx
web/src/modules/module-reading/SourceEntry.tsx
web/src/modules/module-reading/SourceEntry.test.tsx
web/src/modules/module-reading/module-default-reading.css
web/vite.config.mjs
web/visual-reference.html
web/src/visual-reference/main.tsx
web/src/visual-reference/VisualReference.tsx
web/src/visual-reference/VisualReference.test.tsx
web/src/visual-reference/module-default-reading.fixture.ts
web/src/visual-reference/visual-reference.css'
  'scripts/capture-visual-style-baseline
scripts/verify-visual-style-baseline
tests/visual-style-baseline/browser-probe.html
tests/visual-style-baseline/browser-runtime-guard.js
tests/visual-style-baseline/reference-comparison.html
tests/visual-style-baseline/verify-visual-style-baseline.sh
docs/design/visual-style-baseline/evidence/README.md
docs/design/visual-style-baseline/evidence/module-default-reading-1440x1100.png
docs/design/visual-style-baseline/evidence/module-default-reading-1280x960.png
docs/design/visual-style-baseline/evidence/module-default-reading-1024x900.png
docs/design/visual-style-baseline/evidence/reference-comparison.png
docs/engineering/cognitura-visual-style-baseline-acceptance.md'
)

write_exact_candidate_paths() {
  local fixture_root="$1"
  local owner_index="$2"
  local marker="$3"
  local candidate_path
  while IFS= read -r candidate_path; do
    mkdir -p "${fixture_root}/$(dirname "${candidate_path}")"
    if [[ -f "${fixture_root}/${candidate_path}" ]]; then
      printf '\n%s\n' "${marker}" >> "${fixture_root}/${candidate_path}"
    else
      printf '%s\n' "${marker}" > "${fixture_root}/${candidate_path}"
    fi
  done <<< "${candidate_write_sets[${owner_index}]}"
}

make_wave1_restore_projection() {
  local fixture_root="$1"
  local narrative_index narrative_path
  set_field "${fixture_root}/AGENTS.md" \
    "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/AGENTS.md" \
    "ActiveImplementationTaskCard" "W1-I03"
  set_field "${fixture_root}/README.md" \
    "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/README.md" \
    "ActiveImplementationTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/design/wave-1/README.md" \
    "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/design/wave-1/README.md" \
    "ActiveImplementationGovernanceTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    "ActiveTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    "ActiveTaskCardStatus" "READY"
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    "ActiveImplementationTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    "ActiveImplementationGovernanceTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    "ImplementationTaskCardPlanStatus" "I01_COMPLETE_I03_READY"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    "ActiveImplementationGovernanceTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    "TaskCardSetStatus" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    "ActiveTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    "SuspendedTaskCard" "NONE"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    "SuspendedCandidateSHA" "NONE"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    "SuspendedCandidateMutation" "NONE"
  set_table_status \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    "W1-I03" "SUSPENDED_BY_USER" "READY"
  set_field "${fixture_root}/docs/task-cards/wave-1/README.md" \
    "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/task-cards/wave-1/README.md" \
    "ActiveImplementationGovernanceTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "TaskCardSetStatus" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "ActiveTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "SuspendedTaskCard" "NONE"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "SuspendedCandidateSHA" "NONE"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "SuspendedCandidateMutation" "NONE"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "ReadyTaskCardCount" "1"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "SuspendedTaskCardCount" "0"
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "W1-I03" "SUSPENDED_BY_USER" "READY"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md" \
    "Status" "READY"
  for narrative_index in "${!suspension_narratives[@]}"; do
    narrative_path="${suspension_narrative_paths[${narrative_index}]}"
    replace_exact_block \
      "${fixture_root}/${narrative_path}" \
      "${suspension_narratives[${narrative_index}]}" \
      "${ready_narratives[${narrative_index}]}" \
      "restore ${narrative_path} READY narrative"
  done
}

clear_vsb_receipt() {
  local receipt_index="$1"
  set_field "${transition_state}" "VSB0${receipt_index}CandidateSHA" "NONE"
  set_field "${transition_state}" "VSB0${receipt_index}GateStatus" "NOT_RUN"
  if [[ "${receipt_index}" -eq 3 ]]; then
    set_field "${transition_state}" "VSB03DeepReviewVerdict" "NOT_RUN"
    set_field "${transition_state}" "VSB03UltraReviewVerdict" "NOT_RUN"
  else
    set_field "${transition_state}" "VSB0${receipt_index}ReviewVerdict" "NOT_RUN"
  fi
}

prepare_return_to_owner() {
  local failed_candidate_sha="$1"
  local owner="$2"
  local completed_prefix="$3"
  local next_card="$4"
  local sequence="$5"
  local review_route="$6"
  local review_verdict="$7"
  local owner_index receipt_index
  case "${owner}" in
    VSB-00) owner_index=0 ;;
    VSB-01) owner_index=1 ;;
    VSB-02) owner_index=2 ;;
    VSB-03) owner_index=3 ;;
    *) fail "test fixture requested an unknown RETURN owner: ${owner}" ;;
  esac
  set_field "${transition_state}" "TaskCardSetStatus" "IN_PROGRESS"
  set_field "${transition_state}" "ActiveTaskCard" "${owner}"
  set_field "${transition_state}" "ReleasedTaskCard" "${owner}"
  set_field "${transition_state}" "CompletedTaskCards" "${completed_prefix}"
  set_field "${transition_state}" "CurrentCandidateSHA" \
    "${failed_candidate_sha}"
  set_field "${transition_state}" "CurrentGateStatus" "FAIL"
  set_field "${transition_state}" "CurrentReviewRoute" "${review_route}"
  set_field "${transition_state}" "CurrentReviewVerdict" "${review_verdict}"
  for ((receipt_index = owner_index; receipt_index < 4; receipt_index++)); do
    clear_vsb_receipt "${receipt_index}"
  done
  set_field "${transition_state}" "NextTaskCard" "${next_card}"
  set_field "${transition_state}" "TransitionSequence" "${sequence}"
  set_field "${transition_state}" "TransitionKind" "RETURN_TO_OWNER"
  set_field "${transition_state}" "TransitionBaseSHA" \
    "${failed_candidate_sha}"
  printf '%s\n' "Owner = ${owner}" >> "${transition_state}"
}

printf '%s\n' 'fixed governance review input' > \
  "${transition_cards}/governance-review-input.md"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/governance-review-input.md
git -C "${transition_repo_root}" commit -qm "test: create VSB governance candidate"
governance_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"

set_field "${transition_state}" "GovernanceBootstrapStatus" "PASS"
set_field "${transition_state}" "GovernanceReviewedCandidateSHA" "${governance_candidate_sha}"
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
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" \
  --transition-base "${governance_candidate_sha}" \
  --transition-head "${activation_sha}" >/dev/null ||
  fail "valid VSB activation transition was rejected"

git -C "${transition_repo_root}" switch -q --detach "${governance_candidate_sha}"
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
printf '\000' >> "${transition_state}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: append NUL to an otherwise valid VSB activation receipt"
nul_activation_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if nul_activation_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${governance_candidate_sha}" \
    --transition-head "${nul_activation_sha}" 2>&1
)"; then
  fail "ACTIVATE_SET receipt with NUL-byte drift unexpectedly passed"
fi
assert_contains "${nul_activation_output}" \
  "transition ledger must not contain NUL bytes"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${governance_candidate_sha}"
set_field "${transition_state}" "NextTaskCard" "VSB-03"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: forge malformed bootstrap transition base"
forged_activation_base_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "GovernanceBootstrapStatus" "PASS"
set_field "${transition_state}" "GovernanceReviewedCandidateSHA" \
  "${forged_activation_base_sha}"
set_field "${transition_state}" "GovernanceReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "TaskCardSetStatus" "IN_PROGRESS"
set_field "${transition_state}" "ActiveTaskCard" "VSB-00"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-00"
set_field "${transition_state}" "NextTaskCard" "VSB-01"
set_field "${transition_state}" "TransitionSequence" "1"
set_field "${transition_state}" "TransitionKind" "ACTIVATE_SET"
set_field "${transition_state}" "TransitionBaseSHA" "${forged_activation_base_sha}"
set_field "${transition_state}" "VisualImplementation" "USER_AUTHORIZED"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: activate from malformed bootstrap base"
forged_activation_head_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if forged_activation_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${forged_activation_base_sha}" \
    --transition-head "${forged_activation_head_sha}" 2>&1
)"; then
  fail "ACTIVATE_SET from a forged malformed BASE unexpectedly passed"
fi
assert_contains "${forged_activation_output}" \
  "transition BASE failed full VSB state validation"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
set_field "${transition_state}" "NextTaskCard" "VSB-03"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: forge malformed VSB-00 active state"
forged_advance_preparent_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "forged ADVANCE base candidate"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create candidate over malformed ADVANCE state"
forged_advance_base_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00"
set_field "${transition_state}" "ActiveTaskCard" "VSB-01"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-01"
set_field "${transition_state}" "CurrentCandidateSHA" "${forged_advance_base_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB00CandidateSHA" "${forged_advance_base_sha}"
set_field "${transition_state}" "VSB00GateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "VSB00ReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "VSB-02"
set_field "${transition_state}" "TransitionSequence" "2"
set_field "${transition_state}" "TransitionKind" "ADVANCE"
set_field "${transition_state}" "TransitionBaseSHA" "${forged_advance_base_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: advance from malformed VSB-00 base"
forged_advance_head_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if forged_advance_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${forged_advance_base_sha}" \
    --transition-head "${forged_advance_head_sha}" 2>&1
)"; then
  fail "ADVANCE from a forged malformed BASE unexpectedly passed"
fi
assert_contains "${forged_advance_output}" \
  "transition BASE failed full VSB state validation"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"

git -C "${transition_repo_root}" switch -q --detach "${governance_candidate_sha}"
set_field "${transition_state}" "TaskCardSetStatus" "STOPPED_BY_USER"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "CurrentGateStatus" "STOPPED_BY_USER"
set_field "${transition_state}" "CurrentReviewRoute" "NONE"
set_field "${transition_state}" "CurrentReviewVerdict" "NOT_APPLICABLE_USER_STOP"
set_field "${transition_state}" "TransitionSequence" "1"
set_field "${transition_state}" "TransitionKind" "STOP_BY_USER"
set_field "${transition_state}" "TransitionBaseSHA" "${governance_candidate_sha}"
set_field "${transition_state}" "VisualImplementation" "STOPPED_BY_USER"
set_field "${transition_state}" "UserStopAuthorization" "EXPLICIT_USER_INSTRUCTION"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: stop VSB before activation"
illegal_stop_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if illegal_stop_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${governance_candidate_sha}" \
    --transition-head "${illegal_stop_sha}" 2>&1
)"; then
  fail "STOP_BY_USER from an inactive bootstrap state unexpectedly passed"
fi
assert_contains "${illegal_stop_output}" \
  "terminal VSB state requires governance zero-finding GO"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
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
git -C "${transition_repo_root}" commit -qm "test: stop VSB fixture by explicit user instruction"
stopped_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" \
  --transition-base "${activation_sha}" \
  --transition-head "${stopped_sha}" >/dev/null ||
  fail "valid STOP_BY_USER transition was rejected"
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" >/dev/null ||
  fail "valid STOP_BY_USER terminal receipt was rejected statically"
printf '%s\n' 'post-stop mutation' > \
  "${transition_cards}/post-stop-mutation.md"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/post-stop-mutation.md
git -C "${transition_repo_root}" commit -qm \
  "test: mutate history after terminal STOP receipt"
if post_stop_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" 2>&1
)"; then
  fail "post-STOP commit with copied terminal ledger unexpectedly passed"
fi
assert_contains "${post_stop_output}" \
  "terminal VSB state must be the exact direct-child receipt commit"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${stopped_sha}"
make_wave1_restore_projection "${transition_repo_root}"
git -C "${transition_repo_root}" add "${wave1_restore_paths[@]}"
git -C "${transition_repo_root}" commit -qm \
  "test: restore W1-I03 after terminal STOP receipt"
stopped_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" >/dev/null ||
  fail "valid restored STOPPED_BY_USER state was rejected statically"
printf '%s\n' 'post-restore mutation' > \
  "${transition_cards}/post-restore-mutation.md"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/post-restore-mutation.md
git -C "${transition_repo_root}" commit -qm \
  "test: mutate history after exact Wave 1 restore"
if post_restore_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" 2>&1
)"; then
  fail "post-restore commit with copied terminal ledger unexpectedly passed"
fi
assert_contains "${post_restore_output}" \
  "terminal VSB state must be the exact direct-child receipt commit"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
set_field "${transition_state}" "NextTaskCard" "VSB-03"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: forge nominal in-progress STOP base"
forged_stop_base_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "TaskCardSetStatus" "STOPPED_BY_USER"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "CurrentGateStatus" "STOPPED_BY_USER"
set_field "${transition_state}" "CurrentReviewRoute" "NONE"
set_field "${transition_state}" "CurrentReviewVerdict" "NOT_APPLICABLE_USER_STOP"
set_field "${transition_state}" "TransitionSequence" "2"
set_field "${transition_state}" "TransitionKind" "STOP_BY_USER"
set_field "${transition_state}" "TransitionBaseSHA" "${forged_stop_base_sha}"
set_field "${transition_state}" "VisualImplementation" "STOPPED_BY_USER"
set_field "${transition_state}" "UserStopAuthorization" "EXPLICIT_USER_INSTRUCTION"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: stop from forged nominal in-progress base"
forged_stop_head_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if forged_stop_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${forged_stop_base_sha}" \
    --transition-head "${forged_stop_head_sha}" 2>&1
)"; then
  fail "STOP_BY_USER from a forged nominal IN_PROGRESS base unexpectedly passed"
fi
assert_contains "${forged_stop_output}" \
  "transition BASE failed full VSB state validation"
negative_cases=$((negative_cases + 1))
git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"

printf '%s\n' 'forbidden intervening history' > \
  "${transition_repo_root}/raw/round10-forbidden-intervening.txt"
git -C "${transition_repo_root}" add raw/round10-forbidden-intervening.txt
git -C "${transition_repo_root}" commit -qm \
  "test: insert forbidden commit after VSB activation"
intervening_forbidden_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "candidate after forbidden intervening commit"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create exact VSB-00 candidate after forbidden commit"
intervening_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
[[ "$(git -C "${transition_repo_root}" rev-parse "${intervening_candidate_sha}^")" == \
   "${intervening_forbidden_sha}" ]] ||
  fail "intervening candidate fixture lost its forbidden direct parent"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00"
set_field "${transition_state}" "ActiveTaskCard" "VSB-01"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-01"
set_field "${transition_state}" "CurrentCandidateSHA" \
  "${intervening_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB00CandidateSHA" \
  "${intervening_candidate_sha}"
set_field "${transition_state}" "VSB00GateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "VSB00ReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "VSB-02"
set_field "${transition_state}" "TransitionSequence" "2"
set_field "${transition_state}" "TransitionKind" "ADVANCE"
set_field "${transition_state}" "TransitionBaseSHA" \
  "${intervening_candidate_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: advance candidate with an unbound parent"
intervening_receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if intervening_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${intervening_candidate_sha}" \
    --transition-head "${intervening_receipt_sha}" 2>&1
)"; then
  fail "ADVANCE candidate whose parent is not a VSB receipt unexpectedly passed"
fi
assert_contains "${intervening_output}" \
  "candidate parent must be a replayable ledger-only VSB receipt"
negative_cases=$((negative_cases + 1))
git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"

printf '%s\n' 'merge-only unauthorized history' > \
  "${transition_repo_root}/raw/round11-merge-candidate-side.txt"
git -C "${transition_repo_root}" add raw/round11-merge-candidate-side.txt
git -C "${transition_repo_root}" commit -qm \
  "test: create unauthorized side parent for candidate merge"
merge_candidate_side_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
git -C "${transition_repo_root}" merge -q --no-ff -s ours --no-commit \
  "${merge_candidate_side_sha}"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "exact VSB-00 merge candidate"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create exact VSB-00 merge candidate"
merge_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
assert_commit_parent_count "${transition_repo_root}" "${merge_candidate_sha}" 2
set_field "${transition_state}" "CompletedTaskCards" "VSB-00"
set_field "${transition_state}" "ActiveTaskCard" "VSB-01"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-01"
set_field "${transition_state}" "CurrentCandidateSHA" "${merge_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB00CandidateSHA" "${merge_candidate_sha}"
set_field "${transition_state}" "VSB00GateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "VSB00ReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "VSB-02"
set_field "${transition_state}" "TransitionSequence" "2"
set_field "${transition_state}" "TransitionKind" "ADVANCE"
set_field "${transition_state}" "TransitionBaseSHA" "${merge_candidate_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: advance a merge business candidate"
merge_candidate_receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if merge_candidate_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${merge_candidate_sha}" \
    --transition-head "${merge_candidate_receipt_sha}" 2>&1
)"; then
  fail "merge business candidate unexpectedly passed"
fi
assert_contains "${merge_candidate_output}" \
  "business candidate must have exactly one parent"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "linear VSB-00 candidate for merge receipt"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create linear VSB-00 candidate for merge receipt"
merge_advance_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
printf '%s\n' 'merge receipt side history' > \
  "${transition_repo_root}/docs/task-cards/visual-style-baseline/round11-side.txt"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/round11-side.txt
git -C "${transition_repo_root}" commit -qm \
  "test: create side parent for ADVANCE receipt"
merge_advance_side_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
git -C "${transition_repo_root}" switch -q --detach \
  "${merge_advance_candidate_sha}"
git -C "${transition_repo_root}" merge -q --no-ff -s ours --no-commit \
  "${merge_advance_side_sha}"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00"
set_field "${transition_state}" "ActiveTaskCard" "VSB-01"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-01"
set_field "${transition_state}" "CurrentCandidateSHA" \
  "${merge_advance_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB00CandidateSHA" \
  "${merge_advance_candidate_sha}"
set_field "${transition_state}" "VSB00GateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "VSB00ReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "VSB-02"
set_field "${transition_state}" "TransitionSequence" "2"
set_field "${transition_state}" "TransitionKind" "ADVANCE"
set_field "${transition_state}" "TransitionBaseSHA" \
  "${merge_advance_candidate_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: create merge ADVANCE receipt"
merge_advance_receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
assert_commit_parent_count "${transition_repo_root}" \
  "${merge_advance_receipt_sha}" 2
if merge_advance_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${merge_advance_candidate_sha}" \
    --transition-head "${merge_advance_receipt_sha}" 2>&1
)"; then
  fail "merge ADVANCE receipt unexpectedly passed"
fi
assert_contains "${merge_advance_output}" \
  "transition HEAD must have exactly one parent"
negative_cases=$((negative_cases + 1))
git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"

mkdir -p "${transition_repo_root}/docs/design/visual-style-baseline-fixtures"
printf '%s\n' 'unauthorized candidate path' > \
  "${transition_repo_root}/docs/design/visual-style-baseline-fixtures/unauthorized.txt"
git -C "${transition_repo_root}" add \
  docs/design/visual-style-baseline-fixtures/unauthorized.txt
git -C "${transition_repo_root}" commit -qm "test: create unauthorized VSB-00 candidate"
unauthorized_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00"
set_field "${transition_state}" "ActiveTaskCard" "VSB-01"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-01"
set_field "${transition_state}" "CurrentCandidateSHA" "${unauthorized_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB00CandidateSHA" "${unauthorized_candidate_sha}"
set_field "${transition_state}" "VSB00GateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "VSB00ReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "VSB-02"
set_field "${transition_state}" "TransitionSequence" "2"
set_field "${transition_state}" "TransitionKind" "ADVANCE"
set_field "${transition_state}" "TransitionBaseSHA" "${unauthorized_candidate_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm "test: release unauthorized VSB-00 candidate"
unauthorized_receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if unauthorized_candidate_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${unauthorized_candidate_sha}" \
    --transition-head "${unauthorized_receipt_sha}" 2>&1
)"; then
  fail "candidate outside the exact VSB-00 WriteSet unexpectedly passed"
fi
assert_contains "${unauthorized_candidate_output}" \
  "candidate diff must equal the exact VSB-00 WriteSet"
negative_cases=$((negative_cases + 1))
git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"

forbidden_rename_source="server/forbidden-vsb-rename-source.txt"
allowed_rename_target="scripts/import-visual-style-reference"
mkdir -p "${transition_repo_root}/$(dirname "${forbidden_rename_source}")"
printf '%s\n' 'rename-identical-content' > \
  "${transition_repo_root}/${forbidden_rename_source}"
git -C "${transition_repo_root}" add "${forbidden_rename_source}"
git -C "${transition_repo_root}" commit -qm \
  "test: establish forbidden rename source"
rename_parent_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "rename-detection candidate"
rm "${transition_repo_root}/${allowed_rename_target}"
git -C "${transition_repo_root}" mv \
  "${forbidden_rename_source}" "${allowed_rename_target}"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: rename forbidden source into allowed VSB-00 target"
rename_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
test "$(git -C "${transition_repo_root}" diff --name-status \
  "${rename_parent_sha}..${rename_candidate_sha}" -- | \
  grep -c "^R100.*${forbidden_rename_source}.*${allowed_rename_target}$")" -eq 1 ||
  fail "rename bypass fixture did not produce an R100 change"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00"
set_field "${transition_state}" "ActiveTaskCard" "VSB-01"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-01"
set_field "${transition_state}" "CurrentCandidateSHA" "${rename_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB00CandidateSHA" "${rename_candidate_sha}"
set_field "${transition_state}" "VSB00GateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "VSB00ReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "VSB-02"
set_field "${transition_state}" "TransitionSequence" "2"
set_field "${transition_state}" "TransitionKind" "ADVANCE"
set_field "${transition_state}" "TransitionBaseSHA" "${rename_candidate_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: try to release rename-bypassed VSB-00 candidate"
rename_receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if rename_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${rename_candidate_sha}" \
    --transition-head "${rename_receipt_sha}" 2>&1
)"; then
  fail "forbidden-source rename into an allowed candidate target unexpectedly passed"
fi
assert_contains "${rename_output}" \
  "candidate diff must equal the exact VSB-00 WriteSet"
negative_cases=$((negative_cases + 1))
git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"

advance_prefixes=(VSB-00 VSB-00,VSB-01 VSB-00,VSB-01,VSB-02)
advance_actives=(VSB-01 VSB-02 VSB-03)
advance_nexts=(VSB-02 VSB-03 NONE)
candidate_shas=()
receipt_shas=()
for i in 0 1 2; do
  write_exact_candidate_paths \
    "${transition_repo_root}" "${i}" "candidate ${i}"
  printf '%s\n' "${candidate_write_sets[${i}]}" | \
    git -C "${transition_repo_root}" add --pathspec-from-file=-
  git -C "${transition_repo_root}" commit -qm "test: create VSB-0${i} candidate"
  candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
  candidate_shas[${i}]="${candidate_sha}"
  set_field "${transition_state}" "CompletedTaskCards" "${advance_prefixes[${i}]}"
  set_field "${transition_state}" "ActiveTaskCard" "${advance_actives[${i}]}"
  set_field "${transition_state}" "ReleasedTaskCard" "${advance_actives[${i}]}"
  set_field "${transition_state}" "CurrentCandidateSHA" "${candidate_sha}"
  set_field "${transition_state}" "CurrentGateStatus" "VSB-G${i}_PASS"
  set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
  set_field "${transition_state}" "CurrentReviewVerdict" "GO_P0_0_P1_0_P2_0"
  set_field "${transition_state}" "VSB0${i}CandidateSHA" "${candidate_sha}"
  set_field "${transition_state}" "VSB0${i}GateStatus" "VSB-G${i}_PASS"
  set_field "${transition_state}" "VSB0${i}ReviewVerdict" "GO_P0_0_P1_0_P2_0"
  set_field "${transition_state}" "NextTaskCard" "${advance_nexts[${i}]}"
  set_field "${transition_state}" "TransitionSequence" "$((i + 2))"
  set_field "${transition_state}" "TransitionKind" "ADVANCE"
  set_field "${transition_state}" "TransitionBaseSHA" "${candidate_sha}"
  git -C "${transition_repo_root}" add \
    docs/task-cards/visual-style-baseline/execution-state.md
  git -C "${transition_repo_root}" commit -qm "test: advance VSB-0${i} fixture"
  receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
  receipt_shas[${i}]="${receipt_sha}"
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${candidate_sha}" \
    --transition-head "${receipt_sha}" >/dev/null ||
    fail "valid VSB-0${i} ADVANCE transition was rejected"
done

after_vsb02_receipt="${receipt_shas[2]}"

git -C "${transition_repo_root}" switch -q --detach "${after_vsb02_receipt}"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-02"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: forge malformed COMPLETE candidate state"
forged_complete_preparent_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
write_exact_candidate_paths "${transition_repo_root}" 3 \
  "forged COMPLETE base candidate"
printf '%s\n' "${candidate_write_sets[3]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create candidate over malformed COMPLETE state"
forged_complete_base_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "TaskCardSetStatus" "COMPLETE"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00,VSB-01,VSB-02,VSB-03"
set_field "${transition_state}" "CurrentCandidateSHA" "${forged_complete_base_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G3_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer+ultra_gatekeeper"
set_field "${transition_state}" "CurrentReviewVerdict" "FINAL_GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB03CandidateSHA" "${forged_complete_base_sha}"
set_field "${transition_state}" "VSB03GateStatus" "VSB-G3_PASS"
set_field "${transition_state}" "VSB03DeepReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB03UltraReviewVerdict" "FINAL_GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "TransitionSequence" "5"
set_field "${transition_state}" "TransitionKind" "COMPLETE"
set_field "${transition_state}" "TransitionBaseSHA" "${forged_complete_base_sha}"
set_field "${transition_state}" "VisualImplementation" "COMPLETE"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: complete from malformed VSB-03 base"
forged_complete_head_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if forged_complete_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${forged_complete_base_sha}" \
    --transition-head "${forged_complete_head_sha}" 2>&1
)"; then
  fail "COMPLETE from a forged malformed BASE unexpectedly passed"
fi
assert_contains "${forged_complete_output}" \
  "transition BASE failed full VSB state validation"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${receipt_shas[0]}"
write_exact_candidate_paths "${transition_repo_root}" 1 \
  "early FINAL owner candidate"
printf '%s\n' "${candidate_write_sets[1]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create early FINAL owner candidate"
early_final_base_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "TaskCardSetStatus" "FINAL_NO_GO"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "CurrentCandidateSHA" "${early_final_base_sha}"
set_field "${transition_state}" "CurrentGateStatus" "FAIL"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer+ultra_gatekeeper"
set_field "${transition_state}" "CurrentReviewVerdict" "FINDING_P0_0_P1_1_P2_0"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "TransitionSequence" "3"
set_field "${transition_state}" "TransitionKind" "FINAL_NO_GO"
set_field "${transition_state}" "TransitionBaseSHA" "${early_final_base_sha}"
set_field "${transition_state}" "VisualImplementation" "FINAL_NO_GO"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: try FINAL_NO_GO before VSB-03"
early_final_head_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if early_final_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${early_final_base_sha}" \
    --transition-head "${early_final_head_sha}" 2>&1
)"; then
  fail "FINAL_NO_GO from an Owner other than VSB-03 unexpectedly passed"
fi
assert_contains "${early_final_output}" \
  "FINAL_NO_GO requires the VSB-03 candidate and exact predecessor prefix"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${after_vsb02_receipt}"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-02"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: forge nominal in-progress FINAL base"
forged_final_preparent_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
write_exact_candidate_paths "${transition_repo_root}" 3 \
  "forged FINAL base candidate"
printf '%s\n' "${candidate_write_sets[3]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create candidate over forged FINAL base"
forged_final_base_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "TaskCardSetStatus" "FINAL_NO_GO"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "CurrentCandidateSHA" "${forged_final_base_sha}"
set_field "${transition_state}" "CurrentGateStatus" "FAIL"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer+ultra_gatekeeper"
set_field "${transition_state}" "CurrentReviewVerdict" "FINDING_P0_0_P1_1_P2_0"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "TransitionSequence" "5"
set_field "${transition_state}" "TransitionKind" "FINAL_NO_GO"
set_field "${transition_state}" "TransitionBaseSHA" "${forged_final_base_sha}"
set_field "${transition_state}" "VisualImplementation" "FINAL_NO_GO"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: finalize from forged nominal in-progress base"
forged_final_head_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if forged_final_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${forged_final_base_sha}" \
    --transition-head "${forged_final_head_sha}" 2>&1
)"; then
  fail "FINAL_NO_GO from a forged nominal IN_PROGRESS base unexpectedly passed"
fi
assert_contains "${forged_final_output}" \
  "transition BASE failed full VSB state validation"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "alternate VSB-00 predecessor receipt"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create alternate valid VSB-00 candidate"
alternate_vsb00_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"

git -C "${transition_repo_root}" switch -q --detach "${receipt_shas[1]}"
write_exact_candidate_paths "${transition_repo_root}" 2 \
  "successor overwrite candidate"
printf '%s\n' "${candidate_write_sets[2]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create successor overwrite candidate"
overwrite_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00,VSB-01,VSB-02"
set_field "${transition_state}" "ActiveTaskCard" "VSB-03"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-03"
set_field "${transition_state}" "CurrentCandidateSHA" "${overwrite_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G2_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB02CandidateSHA" "${overwrite_candidate_sha}"
set_field "${transition_state}" "VSB02GateStatus" "VSB-G2_PASS"
set_field "${transition_state}" "VSB02ReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB00CandidateSHA" "${alternate_vsb00_candidate_sha}"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "TransitionSequence" "4"
set_field "${transition_state}" "TransitionKind" "ADVANCE"
set_field "${transition_state}" "TransitionBaseSHA" "${overwrite_candidate_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: overwrite predecessor receipt during successor release"
overwrite_receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if overwrite_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${overwrite_candidate_sha}" \
    --transition-head "${overwrite_receipt_sha}" 2>&1
)"; then
  fail "successor transition overwriting a predecessor receipt unexpectedly passed"
fi
assert_contains "${overwrite_output}" \
  "ADVANCE must preserve every predecessor receipt"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${after_vsb02_receipt}"
write_exact_candidate_paths "${transition_repo_root}" 3 "candidate 3"
printf '%s\n' "${candidate_write_sets[3]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm "test: create VSB-03 candidate"
vsb03_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"

printf '%s\n' 'merge RETURN receipt side history' > \
  "${transition_repo_root}/docs/task-cards/visual-style-baseline/round11-return-side.txt"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/round11-return-side.txt
git -C "${transition_repo_root}" commit -qm \
  "test: create side parent for RETURN receipt"
merge_return_side_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
git -C "${transition_repo_root}" merge -q --no-ff -s ours --no-commit \
  "${merge_return_side_sha}"
prepare_return_to_owner \
  "${vsb03_candidate_sha}" VSB-02 VSB-00,VSB-01 VSB-03 5 \
  deep_reviewer+ultra_gatekeeper VISUAL_ACCEPTANCE_FAIL
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: create merge RETURN receipt"
merge_return_receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
assert_commit_parent_count "${transition_repo_root}" \
  "${merge_return_receipt_sha}" 2
if merge_return_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${merge_return_receipt_sha}" 2>&1
)"; then
  fail "merge RETURN receipt unexpectedly passed"
fi
assert_contains "${merge_return_output}" \
  "transition HEAD must have exactly one parent"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${after_vsb02_receipt}"
printf '%s\n' 'forbidden VSB-03 intervening history' > \
  "${transition_repo_root}/raw/round10-vsb03-forbidden-intervening.txt"
git -C "${transition_repo_root}" add \
  raw/round10-vsb03-forbidden-intervening.txt
git -C "${transition_repo_root}" commit -qm \
  "test: insert forbidden commit before VSB-03 candidate"
intervening_vsb03_parent_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
write_exact_candidate_paths "${transition_repo_root}" 3 \
  "VSB-03 candidate after forbidden intervening commit"
printf '%s\n' "${candidate_write_sets[3]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create exact VSB-03 candidate after forbidden commit"
intervening_vsb03_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
[[ "$(git -C "${transition_repo_root}" rev-parse \
  "${intervening_vsb03_candidate_sha}^")" == \
   "${intervening_vsb03_parent_sha}" ]] ||
  fail "intervening VSB-03 fixture lost its forbidden direct parent"

set_field "${transition_state}" "TaskCardSetStatus" "COMPLETE"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "CompletedTaskCards" \
  "VSB-00,VSB-01,VSB-02,VSB-03"
set_field "${transition_state}" "CurrentCandidateSHA" \
  "${intervening_vsb03_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G3_PASS"
set_field "${transition_state}" "CurrentReviewRoute" \
  "deep_reviewer+ultra_gatekeeper"
set_field "${transition_state}" "CurrentReviewVerdict" \
  "FINAL_GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB03CandidateSHA" \
  "${intervening_vsb03_candidate_sha}"
set_field "${transition_state}" "VSB03GateStatus" "VSB-G3_PASS"
set_field "${transition_state}" "VSB03DeepReviewVerdict" \
  "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB03UltraReviewVerdict" \
  "FINAL_GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "TransitionSequence" "5"
set_field "${transition_state}" "TransitionKind" "COMPLETE"
set_field "${transition_state}" "TransitionBaseSHA" \
  "${intervening_vsb03_candidate_sha}"
set_field "${transition_state}" "VisualImplementation" "COMPLETE"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: complete candidate with an unbound parent"
intervening_complete_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if intervening_complete_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${intervening_vsb03_candidate_sha}" \
    --transition-head "${intervening_complete_sha}" 2>&1
)"; then
  fail "COMPLETE candidate whose parent is not a VSB receipt unexpectedly passed"
fi
assert_contains "${intervening_complete_output}" \
  "candidate parent must be a replayable ledger-only VSB receipt"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach \
  "${intervening_vsb03_candidate_sha}"
prepare_return_to_owner \
  "${intervening_vsb03_candidate_sha}" VSB-02 VSB-00,VSB-01 VSB-03 5 \
  deep_reviewer+ultra_gatekeeper VISUAL_ACCEPTANCE_FAIL
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: cross-card return candidate with an unbound parent"
intervening_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if intervening_return_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${intervening_vsb03_candidate_sha}" \
    --transition-head "${intervening_return_sha}" 2>&1
)"; then
  fail "cross-card RETURN candidate whose parent is not a VSB receipt unexpectedly passed"
fi
assert_contains "${intervening_return_output}" \
  "candidate parent must be a replayable ledger-only VSB receipt"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${receipt_shas[0]}"
write_exact_candidate_paths "${transition_repo_root}" 1 \
  "alternate immutable VSB-01 receipt"
printf '%s\n' "${candidate_write_sets[1]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create alternate valid VSB-01 candidate"
alternate_vsb01_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
prepare_return_to_owner \
  "${vsb03_candidate_sha}" VSB-02 VSB-00,VSB-01 VSB-03 5 \
  deep_reviewer+ultra_gatekeeper VISUAL_ACCEPTANCE_FAIL
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: return VSB-03 visual finding to VSB-02"
vsb03_to_vsb02_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if ! vsb03_to_vsb02_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${vsb03_to_vsb02_return_sha}" 2>&1
)"; then
  fail "valid VSB-03 to VSB-02 RETURN_TO_OWNER was rejected: ${vsb03_to_vsb02_output}"
fi

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
prepare_return_to_owner \
  "${vsb03_candidate_sha}" VSB-01 VSB-00 VSB-02 5 \
  deep_reviewer+ultra_gatekeeper FINDING_P0_0_P1_1_P2_0
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: return VSB-03 review finding to VSB-01"
vsb03_to_vsb01_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" \
  --transition-base "${vsb03_candidate_sha}" \
  --transition-head "${vsb03_to_vsb01_return_sha}" >/dev/null ||
  fail "valid VSB-03 to VSB-01 RETURN_TO_OWNER was rejected"

git -C "${transition_repo_root}" switch -q --detach "${candidate_shas[1]}"
prepare_return_to_owner \
  "${candidate_shas[1]}" VSB-02 VSB-00,VSB-01 VSB-03 3 \
  deep_reviewer FINDING_P0_0_P1_1_P2_0
set_field "${transition_state}" "VSB01CandidateSHA" "${candidate_shas[1]}"
set_field "${transition_state}" "VSB01GateStatus" "VSB-G1_PASS"
set_field "${transition_state}" "VSB01ReviewVerdict" "GO_P0_0_P1_0_P2_0"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: try to return VSB-01 forward to VSB-02"
forward_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if forward_return_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${candidate_shas[1]}" \
    --transition-head "${forward_return_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER targeting a later card unexpectedly passed"
fi
assert_contains "${forward_return_output}" \
  "RETURN_TO_OWNER target must be the base active Owner or a strict predecessor"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
prepare_return_to_owner \
  "${vsb03_candidate_sha}" VSB-02 VSB-00 VSB-03 5 \
  deep_reviewer+ultra_gatekeeper VISUAL_ACCEPTANCE_FAIL
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: return with the wrong strict predecessor prefix"
wrong_return_prefix_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if wrong_return_prefix_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${wrong_return_prefix_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER with the wrong predecessor prefix unexpectedly passed"
fi
assert_contains "${wrong_return_prefix_output}" \
  "IN_PROGRESS active, released, or next card mismatch"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
prepare_return_to_owner \
  "${vsb03_candidate_sha}" VSB-02 VSB-00,VSB-01 VSB-03 5 \
  deep_reviewer+ultra_gatekeeper VISUAL_ACCEPTANCE_FAIL
set_field "${transition_state}" "VSB02CandidateSHA" "${candidate_shas[2]}"
set_field "${transition_state}" "VSB02GateStatus" "VSB-G2_PASS"
set_field "${transition_state}" "VSB02ReviewVerdict" "GO_P0_0_P1_0_P2_0"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: retain the returned VSB-02 receipt"
uncleared_owner_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if uncleared_owner_return_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${uncleared_owner_return_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER retaining the target Owner receipt unexpectedly passed"
fi
assert_contains "${uncleared_owner_return_output}" \
  "bootstrap receipts must remain NONE or NOT_RUN"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
prepare_return_to_owner \
  "${vsb03_candidate_sha}" VSB-02 VSB-00,VSB-01 VSB-03 5 \
  deep_reviewer+ultra_gatekeeper VISUAL_ACCEPTANCE_FAIL
set_field "${transition_state}" "VSB03CandidateSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "VSB03GateStatus" "VSB-G3_PASS"
set_field "${transition_state}" "VSB03DeepReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB03UltraReviewVerdict" \
  "FINAL_GO_P0_0_P1_0_P2_0"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: retain a successor receipt during return"
uncleared_successor_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if uncleared_successor_return_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${uncleared_successor_return_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER retaining a successor receipt unexpectedly passed"
fi
assert_contains "${uncleared_successor_return_output}" \
  "bootstrap receipts must remain NONE or NOT_RUN"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
prepare_return_to_owner \
  "${vsb03_candidate_sha}" VSB-02 VSB-00,VSB-01 VSB-03 5 \
  deep_reviewer+ultra_gatekeeper VISUAL_ACCEPTANCE_FAIL
set_field "${transition_state}" "VSB01CandidateSHA" \
  "${alternate_vsb01_candidate_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: rewrite a strict predecessor receipt during return"
mutated_predecessor_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if mutated_predecessor_return_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${mutated_predecessor_return_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER rewriting a strict predecessor receipt unexpectedly passed"
fi
assert_contains "${mutated_predecessor_return_output}" \
  "RETURN_TO_OWNER must preserve strict predecessor receipts"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${after_vsb02_receipt}"
write_exact_candidate_paths "${transition_repo_root}" 2 \
  "wrong VSB-03 failure candidate WriteSet"
printf '%s\n' "${candidate_write_sets[2]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create VSB-03 failure candidate from the VSB-02 WriteSet"
wrong_return_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
prepare_return_to_owner \
  "${wrong_return_candidate_sha}" VSB-02 VSB-00,VSB-01 VSB-03 5 \
  deep_reviewer+ultra_gatekeeper VISUAL_ACCEPTANCE_FAIL
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: return a failure candidate from the wrong card WriteSet"
wrong_return_candidate_receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if wrong_return_candidate_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${wrong_return_candidate_sha}" \
    --transition-head "${wrong_return_candidate_receipt_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER accepting the target Owner WriteSet for the failed candidate unexpectedly passed"
fi
assert_contains "${wrong_return_candidate_output}" \
  "candidate diff must equal the exact VSB-03 WriteSet"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
prepare_return_to_owner \
  "${vsb03_candidate_sha}" VSB-02 VSB-00,VSB-01 VSB-03 5 \
  deep_reviewer VISUAL_ACCEPTANCE_FAIL
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: return with the target Owner review route"
wrong_return_route_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if wrong_return_route_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${wrong_return_route_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER using the target Owner review route unexpectedly passed"
fi
assert_contains "${wrong_return_route_output}" \
  "RETURN_TO_OWNER current review route must match the base active Owner"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
set_field "${transition_state}" "TaskCardSetStatus" "COMPLETE"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00,VSB-01,VSB-02,VSB-03"
set_field "${transition_state}" "CurrentCandidateSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G3_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer+ultra_gatekeeper"
set_field "${transition_state}" "CurrentReviewVerdict" "FINAL_GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB03CandidateSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "VSB03GateStatus" "VSB-G3_PASS"
set_field "${transition_state}" "VSB03DeepReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB03UltraReviewVerdict" "FINAL_GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "TransitionSequence" "5"
set_field "${transition_state}" "TransitionKind" "COMPLETE"
set_field "${transition_state}" "TransitionBaseSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "VisualImplementation" "COMPLETE"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm "test: complete VSB fixture"
complete_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" \
  --transition-base "${vsb03_candidate_sha}" \
  --transition-head "${complete_sha}" >/dev/null ||
  fail "valid VSB COMPLETE transition was rejected"
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" >/dev/null ||
  fail "valid VSB COMPLETE terminal receipt was rejected statically"

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
printf '%s\n' 'merge COMPLETE receipt side history' > \
  "${transition_repo_root}/docs/task-cards/visual-style-baseline/round11-complete-side.txt"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/round11-complete-side.txt
git -C "${transition_repo_root}" commit -qm \
  "test: create side parent for COMPLETE receipt"
merge_complete_side_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
git -C "${transition_repo_root}" merge -q --no-ff -s ours --no-commit \
  "${merge_complete_side_sha}"
set_field "${transition_state}" "TaskCardSetStatus" "COMPLETE"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00,VSB-01,VSB-02,VSB-03"
set_field "${transition_state}" "CurrentCandidateSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G3_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer+ultra_gatekeeper"
set_field "${transition_state}" "CurrentReviewVerdict" "FINAL_GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB03CandidateSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "VSB03GateStatus" "VSB-G3_PASS"
set_field "${transition_state}" "VSB03DeepReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB03UltraReviewVerdict" "FINAL_GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "TransitionSequence" "5"
set_field "${transition_state}" "TransitionKind" "COMPLETE"
set_field "${transition_state}" "TransitionBaseSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "VisualImplementation" "COMPLETE"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: create merge COMPLETE receipt"
merge_complete_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
assert_commit_parent_count "${transition_repo_root}" "${merge_complete_sha}" 2
if merge_complete_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" 2>&1
)"; then
  fail "merge terminal COMPLETE receipt unexpectedly passed"
fi
assert_contains "${merge_complete_output}" \
  "terminal VSB state HEAD must have exactly one parent"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${complete_sha}"
make_wave1_restore_projection "${transition_repo_root}"
git -C "${transition_repo_root}" add "${wave1_restore_paths[@]}"
git -C "${transition_repo_root}" commit -qm \
  "test: restore W1-I03 after terminal COMPLETE receipt"
complete_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" >/dev/null ||
  fail "valid restored COMPLETE state was rejected statically"

git -C "${transition_repo_root}" switch -q --detach "${complete_sha}"
printf '%s\n' 'merge restore side history' > \
  "${transition_repo_root}/docs/task-cards/visual-style-baseline/round11-restore-side.txt"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/round11-restore-side.txt
git -C "${transition_repo_root}" commit -qm \
  "test: create side parent for Wave restore"
merge_restore_side_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
git -C "${transition_repo_root}" switch -q --detach "${complete_sha}"
git -C "${transition_repo_root}" merge -q --no-ff -s ours --no-commit \
  "${merge_restore_side_sha}"
make_wave1_restore_projection "${transition_repo_root}"
git -C "${transition_repo_root}" add "${wave1_restore_paths[@]}"
git -C "${transition_repo_root}" commit -qm \
  "test: create merge Wave restore"
merge_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
assert_commit_parent_count "${transition_repo_root}" "${merge_restore_sha}" 2
if merge_restore_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" 2>&1
)"; then
  fail "merge Wave restore unexpectedly passed"
fi
assert_contains "${merge_restore_output}" \
  "terminal VSB state HEAD must have exactly one parent"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${complete_restore_sha}"

set_field "${transition_state}" "VSB03UltraReviewVerdict" "NOT_RUN"
complete_failure_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" 2>&1
)" && fail "COMPLETE without ultra GO unexpectedly passed"
assert_contains "${complete_failure_output}" "VSB03 ultra review must be final zero-finding GO"
git -C "${transition_repo_root}" restore \
  docs/task-cards/visual-style-baseline/execution-state.md
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
set_field "${transition_state}" "TaskCardSetStatus" "FINAL_NO_GO"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "CurrentCandidateSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "FAIL"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer+ultra_gatekeeper"
set_field "${transition_state}" "CurrentReviewVerdict" "FINDING_P0_0_P1_1_P2_0"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "TransitionSequence" "5"
set_field "${transition_state}" "TransitionKind" "FINAL_NO_GO"
set_field "${transition_state}" "TransitionBaseSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "VisualImplementation" "FINAL_NO_GO"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm "test: record final VSB no-go"
final_no_go_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" \
  --transition-base "${vsb03_candidate_sha}" \
  --transition-head "${final_no_go_sha}" >/dev/null ||
  fail "valid FINAL_NO_GO transition was rejected"

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
set_field "${transition_state}" "TaskCardSetStatus" "FINAL_NO_GO"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "CurrentCandidateSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "FAIL"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "FINDING_P0_0_P1_1_P2_0"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "TransitionSequence" "5"
set_field "${transition_state}" "TransitionKind" "FINAL_NO_GO"
set_field "${transition_state}" "TransitionBaseSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "VisualImplementation" "FINAL_NO_GO"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: finalize VSB-03 with wrong review route"
wrong_final_route_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if wrong_final_route_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${wrong_final_route_sha}" 2>&1
)"; then
  fail "FINAL_NO_GO with the wrong review route unexpectedly passed"
fi
assert_contains "${wrong_final_route_output}" \
  "FINAL_NO_GO requires the fixed visual acceptance review route"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
set_field "${transition_state}" "ActiveTaskCard" "VSB-99"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-99"
set_field "${transition_state}" "CurrentCandidateSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "FAIL"
set_field "${transition_state}" "CurrentReviewRoute" \
  "deep_reviewer+ultra_gatekeeper"
set_field "${transition_state}" "CurrentReviewVerdict" "FINDING_P0_0_P1_1_P2_0"
set_field "${transition_state}" "TransitionSequence" "5"
set_field "${transition_state}" "TransitionKind" "RETURN_TO_OWNER"
set_field "${transition_state}" "TransitionBaseSHA" "${vsb03_candidate_sha}"
printf '%s\n' 'Owner = VSB-99' >> "${transition_state}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: return VSB-03 finding to a nonexistent owner"
wrong_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if wrong_return_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${wrong_return_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER reopening a nonexistent card unexpectedly passed"
fi
assert_contains "${wrong_return_output}" \
  "ActiveTaskCard must name one known card or NONE"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${receipt_shas[0]}"
write_exact_candidate_paths "${transition_repo_root}" 1 "VSB-01 finding candidate"
printf '%s\n' "${candidate_write_sets[1]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm "test: create VSB-01 finding candidate"
return_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "NextTaskCard" "VSB-03"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: forge malformed RETURN_TO_OWNER candidate state"
forged_return_preparent_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
write_exact_candidate_paths "${transition_repo_root}" 1 \
  "forged RETURN_TO_OWNER base candidate"
printf '%s\n' "${candidate_write_sets[1]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create candidate over malformed RETURN_TO_OWNER state"
forged_return_base_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "CurrentCandidateSHA" "${forged_return_base_sha}"
set_field "${transition_state}" "CurrentGateStatus" "FAIL"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "FINDING_P0_0_P1_1_P2_0"
set_field "${transition_state}" "NextTaskCard" "VSB-02"
set_field "${transition_state}" "TransitionSequence" "3"
set_field "${transition_state}" "TransitionKind" "RETURN_TO_OWNER"
set_field "${transition_state}" "TransitionBaseSHA" "${forged_return_base_sha}"
printf '%s\n' 'Owner = VSB-01' >> "${transition_state}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: return from malformed VSB-01 base"
forged_return_head_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if forged_return_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${forged_return_base_sha}" \
    --transition-head "${forged_return_head_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER from a forged malformed BASE unexpectedly passed"
fi
assert_contains "${forged_return_output}" \
  "transition BASE failed full VSB state validation"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${return_candidate_sha}"
set_field "${transition_state}" "CurrentCandidateSHA" "${return_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "FAIL"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "FINDING_P0_0_P1_1_P2_0"
set_field "${transition_state}" "TransitionSequence" "3"
set_field "${transition_state}" "TransitionKind" "RETURN_TO_OWNER"
set_field "${transition_state}" "TransitionBaseSHA" "${return_candidate_sha}"
printf '%s\n' 'Owner = VSB-01' >> "${transition_state}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm "test: return VSB-01 finding to owner"
return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" \
  --transition-base "${return_candidate_sha}" \
  --transition-head "${return_sha}" >/dev/null ||
  fail "valid RETURN_TO_OWNER transition was rejected"

git -C "${transition_repo_root}" switch -q --detach "${return_candidate_sha}"
set_field "${transition_state}" "CurrentCandidateSHA" "${return_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "FAIL"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "FINDING_P0_0_P1_0_P2_0"
set_field "${transition_state}" "TransitionSequence" "3"
set_field "${transition_state}" "TransitionKind" "RETURN_TO_OWNER"
set_field "${transition_state}" "TransitionBaseSHA" "${return_candidate_sha}"
printf '%s\n' 'Owner = VSB-01' >> "${transition_state}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm "test: return with zero findings"
zero_finding_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if zero_finding_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${return_candidate_sha}" \
    --transition-head "${zero_finding_return_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER with an all-zero finding unexpectedly passed"
fi
assert_contains "${zero_finding_output}" \
  "finding verdict must contain at least one non-zero count"
negative_cases=$((negative_cases + 1))

baseline_transition_cases=22
round10_parent_binding_transition_cases=3
round11_merge_transition_cases=3
transition_cases=$((
  baseline_transition_cases +
  round10_parent_binding_transition_cases +
  round11_merge_transition_cases
))
fixed_base_transition_cases=6
binary_ledger_cases=1
cross_card_return_positive_cases=2
cross_card_return_negative_cases=8

printf '%s\n' \
  "VisualStyleBaselineTaskCardContractTests = PASS" \
  "PositiveCases = 1" \
  "EarlyExitCases = ${early_exit_cases}" \
  "RegisteredTemporaryCleanupCases = ${registered_temporary_cleanup_cases}" \
  "NegativeCases = ${negative_cases}" \
  "TransitionCases = ${transition_cases}" \
  "FixedBaseTransitionCases = ${fixed_base_transition_cases}" \
  "BinaryLedgerCases = ${binary_ledger_cases}" \
  "CrossCardReturnPositiveCases = ${cross_card_return_positive_cases}" \
  "CrossCardReturnNegativeCases = ${cross_card_return_negative_cases}"
