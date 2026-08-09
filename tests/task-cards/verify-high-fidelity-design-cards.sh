#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-high-fidelity-design"
cards_dir="${repo_root}/docs/task-cards/high-fidelity-design"
master_plan="${repo_root}/docs/superpowers/plans/2026-08-06-high-fidelity-design-alignment.md"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-hf-design-cards.XXXXXX")"

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

expect_plan_failure() {
  local fixture_plan="$1"
  local expected_message="$2"
  local output

  if output="$("${verifier}" --cards-dir "${cards_dir}" --plan "${fixture_plan}" 2>&1)"; then
    fail "invalid Task 5 plan unexpectedly passed: ${fixture_plan}"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected error '${expected_message}', got: ${output}"
}

expect_plan_and_cards_failure() {
  local fixture_plan="$1"
  local fixture_dir="$2"
  local expected_message="$3"
  local output

  if output="$("${verifier}" --cards-dir "${fixture_dir}" --plan "${fixture_plan}" 2>&1)"; then
    fail "invalid Task 5 receipt unexpectedly passed: ${fixture_plan} ${fixture_dir}"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected error '${expected_message}', got: ${output}"
}

delete_step_command() {
  local fixture_plan="$1"
  local start_header="$2"
  local end_header="$3"
  local command="$4"
  local rewritten_plan="${fixture_plan}.tmp"

  awk -v start_header="${start_header}" -v end_header="${end_header}" -v command="${command}" '
    $0 == start_header {inside=1}
    $0 == end_header {inside=0}
    !(inside && $0 == command) {print}
  ' "${fixture_plan}" >"${rewritten_plan}"
  mv "${rewritten_plan}" "${fixture_plan}"
}

relocate_step_command() {
  local fixture_plan="$1"
  local start_header="$2"
  local end_header="$3"
  local command="$4"
  local destination_fence="$5"
  local rewritten_plan="${fixture_plan}.tmp"

  awk -v start_header="${start_header}" -v end_header="${end_header}" \
    -v command="${command}" -v destination_fence="${destination_fence}" '
    $0 == start_header {inside_step=1}
    $0 == end_header {inside_step=0}
    inside_step && $0 == "```bash" {fence_count++}
    inside_step && $0 == command {next}
    inside_step && fence_count == destination_fence && $0 == "```" && !relocated {
      print command
      relocated=1
    }
    {print}
    END {
      if (!relocated) {
        exit 1
      }
    }
  ' "${fixture_plan}" >"${rewritten_plan}"
  mv "${rewritten_plan}" "${fixture_plan}"
}

insert_after_designated_fence_open() {
  local fixture_plan="$1"
  local marker="$2"
  local command="$3"
  local rewritten_plan="${fixture_plan}.tmp"

  awk -v marker="${marker}" -v command="${command}" '
    $0 == marker {awaiting_fence=1}
    awaiting_fence && $0 == "```bash" {
      print
      print command
      awaiting_fence=0
      inserted=1
      next
    }
    {print}
    END {
      if (!inserted) {
        exit 1
      }
    }
  ' "${fixture_plan}" >"${rewritten_plan}"
  mv "${rewritten_plan}" "${fixture_plan}"
}

copy_step_command_to_fence() {
  local fixture_plan="$1"
  local start_header="$2"
  local end_header="$3"
  local command="$4"
  local destination_fence="$5"
  local rewritten_plan="${fixture_plan}.tmp"

  awk -v start_header="${start_header}" -v end_header="${end_header}" \
    -v command="${command}" -v destination_fence="${destination_fence}" '
    $0 == start_header {inside_step=1}
    $0 == end_header {inside_step=0}
    inside_step && $0 == "```bash" {fence_count++}
    inside_step && fence_count == destination_fence && $0 == "```" && !copied {
      print command
      copied=1
    }
    {print}
    END {
      if (!copied) {
        exit 1
      }
    }
  ' "${fixture_plan}" >"${rewritten_plan}"
  mv "${rewritten_plan}" "${fixture_plan}"
}

swap_designated_commands() {
  local fixture_plan="$1"
  local marker="$2"
  local first_command="$3"
  local second_command="$4"
  local rewritten_plan="${fixture_plan}.tmp"

  awk -v marker="${marker}" -v first_command="${first_command}" \
    -v second_command="${second_command}" '
    $0 == marker {awaiting_fence=1}
    awaiting_fence && $0 == "```bash" {inside_fence=1; awaiting_fence=0}
    inside_fence && $0 == "```" {inside_fence=0}
    inside_fence && $0 == first_command {
      print second_command
      first_swapped=1
      next
    }
    inside_fence && first_swapped && !second_swapped && $0 == second_command {
      print first_command
      second_swapped=1
      next
    }
    {print}
    END {
      if (!first_swapped || !second_swapped) {
        exit 1
      }
    }
  ' "${fixture_plan}" >"${rewritten_plan}"
  mv "${rewritten_plan}" "${fixture_plan}"
}

[[ -x "${verifier}" ]] || fail "high-fidelity design verifier is missing or not executable"
[[ -d "${cards_dir}" ]] || fail "high-fidelity design card directory is missing"
[[ -f "${master_plan}" ]] || fail "high-fidelity master plan is missing"

canonical_output="$("${verifier}" --cards-dir "${cards_dir}")" ||
  fail "canonical high-fidelity design cards were rejected"
canonical_active="$(sed -n 's/^ActiveTaskCard = //p' "${cards_dir}/README.md")"
for expected_line in \
  "HighFidelityDesignTaskCardValidation = PASS" \
  "TaskCardCount = 5" \
  "TaskCardSetStatus = COMPLETE" \
  "ActiveTaskCard = NONE" \
  "HFD04ReviewStage1 = GO / P0=0 / P1=0 / P2=0" \
  "HFD04ReviewStage2 = GO / P0=0 / P1=0 / P2=0" \
  "ReviewedPreparationSHA = 463fd4829e7c4bb8da071253e8ae9b15cee2a0cf" \
  "BusinessImplementation = NOT_AUTHORIZED" \
  "W1-I00Release = FORBIDDEN"; do
  [[ "${canonical_output}" == *"${expected_line}"* ]] ||
    fail "canonical output is missing: ${expected_line}"
done
canonical_receipt_review_mode="$(printf '%s\n' "${canonical_output}" | sed -n 's/^ReFreezePreparationReviewMode = //p')"
case "${canonical_receipt_review_mode}" in
  DISABLED) ;;
  *) fail "canonical output is missing a valid ReFreezePreparationReviewMode" ;;
esac

baseline_dir="${test_tmp_root}/baseline"
cp -R "${cards_dir}" "${baseline_dir}"

preparation_dir="${test_tmp_root}/preparation-review"
cp -R "${baseline_dir}" "${preparation_dir}"
sed -i.bak 's/^Status = DONE$/Status = READY/' \
  "${preparation_dir}/HF-D04-fixed-design-review.md"
rm "${preparation_dir}/HF-D04-fixed-design-review.md.bak"
sed -i.bak 's/^ActiveTaskCard = NONE$/ActiveTaskCard = HF-D04/' "${preparation_dir}/README.md"
rm "${preparation_dir}/README.md.bak"
sed -i.bak 's/^TaskCardSetStatus = COMPLETE$/TaskCardSetStatus = READY_FOR_EXECUTION/' \
  "${preparation_dir}/README.md"
rm "${preparation_dir}/README.md.bak"
preparation_output="$("${verifier}" --cards-dir "${preparation_dir}")" ||
  fail "historical HF-D04 preparation-review fixture was rejected"
receipt_review_mode="$(printf '%s\n' "${preparation_output}" | sed -n 's/^ReFreezePreparationReviewMode = //p')"
[[ "${receipt_review_mode}" == "ENABLED" ]] ||
  fail "historical HF-D04 preparation-review mode must remain ENABLED and auditable"
receipt_negative_cases=5

  missing_plan_receipt="${test_tmp_root}/missing-plan-receipt.md"
  cp "${master_plan}" "${missing_plan_receipt}"
  sed -i.bak '/^ReFreezeParentRepairSHA = /d' "${missing_plan_receipt}"
  rm "${missing_plan_receipt}.bak"
  expect_plan_and_cards_failure "${missing_plan_receipt}" "${preparation_dir}" \
    "master plan: missing re-freeze receipt field: ReFreezeParentRepairSHA"

  missing_card_receipt_dir="${test_tmp_root}/missing-card-receipt"
  cp -R "${preparation_dir}" "${missing_card_receipt_dir}"
  sed -i.bak '/^ReFreezeReason = /d' \
    "${missing_card_receipt_dir}/HF-D04-fixed-design-review.md"
  rm "${missing_card_receipt_dir}/HF-D04-fixed-design-review.md.bak"
  expect_failure "${missing_card_receipt_dir}" \
    "HF-D04 card: missing re-freeze receipt field: ReFreezeReason"

  wrong_receipt_plan="${test_tmp_root}/wrong-receipt-sha.md"
  wrong_receipt_cards="${test_tmp_root}/wrong-receipt-sha-cards"
  cp "${master_plan}" "${wrong_receipt_plan}"
  cp -R "${preparation_dir}" "${wrong_receipt_cards}"
  sed -i.bak -E 's/^ReFreezeParentRepairSHA = [0-9a-f]{40}$/ReFreezeParentRepairSHA = 0000000000000000000000000000000000000000/' \
    "${wrong_receipt_plan}"
  rm "${wrong_receipt_plan}.bak"
  sed -i.bak -E 's/^ReFreezeParentRepairSHA = [0-9a-f]{40}$/ReFreezeParentRepairSHA = 0000000000000000000000000000000000000000/' \
    "${wrong_receipt_cards}/HF-D04-fixed-design-review.md"
  rm "${wrong_receipt_cards}/HF-D04-fixed-design-review.md.bak"
  expect_plan_and_cards_failure "${wrong_receipt_plan}" "${wrong_receipt_cards}" \
    "re-freeze receipt SHA must equal the parent owner-repair SHA"

  mismatched_receipt_dir="${test_tmp_root}/mismatched-receipt"
  cp -R "${preparation_dir}" "${mismatched_receipt_dir}"
  sed -i.bak -E 's/^ReFreezeParentRepairSHA = [0-9a-f]{40}$/ReFreezeParentRepairSHA = 0000000000000000000000000000000000000000/' \
    "${mismatched_receipt_dir}/HF-D04-fixed-design-review.md"
  rm "${mismatched_receipt_dir}/HF-D04-fixed-design-review.md.bak"
  expect_failure "${mismatched_receipt_dir}" \
    "master plan and HF-D04 card re-freeze receipt SHA must match"

  mismatched_reason_dir="${test_tmp_root}/mismatched-reason"
  cp -R "${preparation_dir}" "${mismatched_reason_dir}"
  sed -i.bak 's/^ReFreezeReason = STATUS_COMMAND_GLOBAL_UNIQUENESS_AND_RECEIPT_TEST_SCOPE$/ReFreezeReason = OTHER_REPAIR/' \
    "${mismatched_reason_dir}/HF-D04-fixed-design-review.md"
  rm "${mismatched_reason_dir}/HF-D04-fixed-design-review.md.bak"
  expect_failure "${mismatched_reason_dir}" \
    "master plan and HF-D04 card re-freeze receipt reason must match"

  nonexistent_reviewed_plan="${test_tmp_root}/nonexistent-reviewed-sha.md"
  nonexistent_reviewed_cards="${test_tmp_root}/nonexistent-reviewed-sha-cards"
  cp "${master_plan}" "${nonexistent_reviewed_plan}"
  cp -R "${preparation_dir}" "${nonexistent_reviewed_cards}"
  sed -i.bak -E 's/^ReviewedPreparationSHA = [0-9a-f]{40}$/ReviewedPreparationSHA = 0000000000000000000000000000000000000000/' \
    "${nonexistent_reviewed_plan}"
  rm "${nonexistent_reviewed_plan}.bak"
  sed -i.bak -E 's/^ReviewedPreparationSHA = [0-9a-f]{40}$/ReviewedPreparationSHA = 0000000000000000000000000000000000000000/' \
    "${nonexistent_reviewed_cards}/HF-D04-fixed-design-review.md"
  rm "${nonexistent_reviewed_cards}/HF-D04-fixed-design-review.md.bak"
  expect_plan_and_cards_failure "${nonexistent_reviewed_plan}" "${nonexistent_reviewed_cards}" \
    "ReviewedPreparationSHA must resolve to an existing Git commit"

  protected_asset_reviewed_plan="${test_tmp_root}/protected-asset-reviewed-sha.md"
  protected_asset_reviewed_cards="${test_tmp_root}/protected-asset-reviewed-sha-cards"
  cp "${master_plan}" "${protected_asset_reviewed_plan}"
  cp -R "${preparation_dir}" "${protected_asset_reviewed_cards}"
  sed -i.bak -E 's/^ReviewedPreparationSHA = [0-9a-f]{40}$/ReviewedPreparationSHA = 18ae0aa8aee57d9db3d277e8f9f2ea6349162956/' \
    "${protected_asset_reviewed_plan}"
  rm "${protected_asset_reviewed_plan}.bak"
  sed -i.bak -E 's/^ReviewedPreparationSHA = [0-9a-f]{40}$/ReviewedPreparationSHA = 18ae0aa8aee57d9db3d277e8f9f2ea6349162956/' \
    "${protected_asset_reviewed_cards}/HF-D04-fixed-design-review.md"
  rm "${protected_asset_reviewed_cards}/HF-D04-fixed-design-review.md.bak"
  sed -i.bak -E 's/^ReFreezeParentRepairSHA = [0-9a-f]{40}$/ReFreezeParentRepairSHA = 463fd4829e7c4bb8da071253e8ae9b15cee2a0cf/' \
    "${protected_asset_reviewed_plan}"
  rm "${protected_asset_reviewed_plan}.bak"
  sed -i.bak -E 's/^ReFreezeParentRepairSHA = [0-9a-f]{40}$/ReFreezeParentRepairSHA = 463fd4829e7c4bb8da071253e8ae9b15cee2a0cf/' \
    "${protected_asset_reviewed_cards}/HF-D04-fixed-design-review.md"
  rm "${protected_asset_reviewed_cards}/HF-D04-fixed-design-review.md.bak"
  expect_plan_and_cards_failure "${protected_asset_reviewed_plan}" "${protected_asset_reviewed_cards}" \
    "re-freeze preparation commit must not modify protected specialty assets"

  wrong_path_reviewed_plan="${test_tmp_root}/wrong-path-reviewed-sha.md"
  wrong_path_reviewed_cards="${test_tmp_root}/wrong-path-reviewed-sha-cards"
  cp "${master_plan}" "${wrong_path_reviewed_plan}"
  cp -R "${preparation_dir}" "${wrong_path_reviewed_cards}"
  sed -i.bak -E 's/^ReviewedPreparationSHA = [0-9a-f]{40}$/ReviewedPreparationSHA = 56285c9c6b3aef6dd748eeadfa684dd824389e07/' \
    "${wrong_path_reviewed_plan}"
  rm "${wrong_path_reviewed_plan}.bak"
  sed -i.bak -E 's/^ReviewedPreparationSHA = [0-9a-f]{40}$/ReviewedPreparationSHA = 56285c9c6b3aef6dd748eeadfa684dd824389e07/' \
    "${wrong_path_reviewed_cards}/HF-D04-fixed-design-review.md"
  rm "${wrong_path_reviewed_cards}/HF-D04-fixed-design-review.md.bak"
  sed -i.bak -E 's/^ReFreezeParentRepairSHA = [0-9a-f]{40}$/ReFreezeParentRepairSHA = 873aacaea9850e786a2ccc4356c592282a460c76/' \
    "${wrong_path_reviewed_plan}"
  rm "${wrong_path_reviewed_plan}.bak"
  sed -i.bak -E 's/^ReFreezeParentRepairSHA = [0-9a-f]{40}$/ReFreezeParentRepairSHA = 873aacaea9850e786a2ccc4356c592282a460c76/' \
    "${wrong_path_reviewed_cards}/HF-D04-fixed-design-review.md"
  rm "${wrong_path_reviewed_cards}/HF-D04-fixed-design-review.md.bak"
  expect_plan_and_cards_failure "${wrong_path_reviewed_plan}" "${wrong_path_reviewed_cards}" \
    "re-freeze preparation commit must contain exactly four governance paths"

initial_d00_dir="${test_tmp_root}/initial-d00"
cp -R "${baseline_dir}" "${initial_d00_dir}"
for card_file in "${initial_d00_dir}"/HF-D*.md; do
  task_id="$(sed -n 's/^TaskCardID = //p' "${card_file}")"
  if [[ "${task_id}" == "HF-D00" ]]; then
    initial_status="READY"
  else
    initial_status="BLOCKED_BY_DEPENDENCY"
  fi
  sed -i.bak -E \
    "s/^Status = (DONE|READY|BLOCKED_BY_DEPENDENCY)$/Status = ${initial_status}/" \
    "${card_file}"
  rm "${card_file}.bak"
done
sed -i.bak 's/^ActiveTaskCard = .*$/ActiveTaskCard = HF-D00/' "${initial_d00_dir}/README.md"
rm "${initial_d00_dir}/README.md.bak"
sed -i.bak 's/^TaskCardSetStatus = COMPLETE$/TaskCardSetStatus = READY_FOR_EXECUTION/' \
  "${initial_d00_dir}/README.md"
rm "${initial_d00_dir}/README.md.bak"
initial_output="$("${verifier}" --cards-dir "${initial_d00_dir}")" ||
  fail "HF-D00 initial governance snapshot was rejected"
[[ "${initial_output}" == *"ActiveTaskCard = HF-D00"* ]] ||
  fail "initial snapshot did not retain HF-D00 as the only READY card"

expanded_hfd01_dir="${test_tmp_root}/expanded-hfd01-write-set"
cp -R "${baseline_dir}" "${expanded_hfd01_dir}"
expanded_hfd01_card="${expanded_hfd01_dir}/HF-D01-reading-presentation-contract.md"
sed -i.bak -E \
  's/^WriteSetItemCount = (12|16|17|18|21)$/WriteSetItemCount = 21/' \
  "${expanded_hfd01_card}"
rm "${expanded_hfd01_card}.bak"
for expanded_path in \
  'cognitive-knowledge-atlas-overall-design-1.2.md' \
  'docs/engineering/cognitura-source-manifest.yaml' \
  'docs/superpowers/specs/2026-08-06-high-fidelity-interaction-design-integration.md' \
  'scripts/verify-ui-contracts' \
  'docs/task-cards/high-fidelity-design/HF-D02-interaction-state-model.md' \
  'docs/engineering/cognitura-design-index.md' \
  'docs/superpowers/plans/2026-08-06-high-fidelity-design-alignment.md' \
  'scripts/verify-high-fidelity-design' \
  'tests/contracts/interaction-state/verify-interaction-state-contracts.sh' \
  'tests/task-cards/verify-high-fidelity-design-cards.sh'; do
  if ! grep -Fq -- "- Modify: \`${expanded_path}\`" "${expanded_hfd01_card}"; then
    sed -i.bak \
      "/^## 4[.] 禁止写集$/i\\
- Modify: \`${expanded_path}\`
" "${expanded_hfd01_card}"
    rm "${expanded_hfd01_card}.bak"
  fi
done
for expanded_card in "${expanded_hfd01_dir}"/HF-D*.md; do
  expanded_id="$(sed -n 's/^TaskCardID = //p' "${expanded_card}")"
  case "${expanded_id}" in
    HF-D00) expanded_status="DONE" ;;
    HF-D01) expanded_status="READY" ;;
    *) expanded_status="BLOCKED_BY_DEPENDENCY" ;;
  esac
  sed -i.bak -E \
    "s/^Status = (DONE|READY|BLOCKED_BY_DEPENDENCY)$/Status = ${expanded_status}/" \
    "${expanded_card}"
  rm "${expanded_card}.bak"
done
sed -i.bak 's/^ActiveTaskCard = .*$/ActiveTaskCard = HF-D01/' \
  "${expanded_hfd01_dir}/README.md"
rm "${expanded_hfd01_dir}/README.md.bak"
sed -i.bak 's/^TaskCardSetStatus = COMPLETE$/TaskCardSetStatus = READY_FOR_EXECUTION/' \
  "${expanded_hfd01_dir}/README.md"
rm "${expanded_hfd01_dir}/README.md.bak"
expanded_output="$("${verifier}" --cards-dir "${expanded_hfd01_dir}")" ||
  fail "HF-D01 cumulative 21-item write set was rejected"
[[ "${expanded_output}" == *"HighFidelityDesignTaskCardValidation = PASS"* ]] ||
  fail "HF-D01 expanded write-set fixture did not report PASS"
for unchanged_card_count in \
  'HF-D00-design-governance.md|20' \
  'HF-D02-interaction-state-model.md|16' \
  'HF-D03-high-fidelity-evidence-contract.md|17' \
  'HF-D04-fixed-design-review.md|19'; do
  unchanged_card="${unchanged_card_count%%|*}"
  unchanged_count="${unchanged_card_count##*|}"
  grep -Fqx "WriteSetItemCount = ${unchanged_count}" "${expanded_hfd01_dir}/${unchanged_card}" ||
    fail "${unchanged_card} write-set count changed while expanding HF-D01"
done

required_hfd03_paths=(
  'AGENTS.md'
  'README.md'
  'Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md'
  'docs/engineering/cognitura-design-index.md'
  'docs/engineering/cognitura-high-fidelity-design-manifest.yaml'
  'docs/engineering/cognitura-high-fidelity-design-plan.md'
  'docs/engineering/cognitura-high-fidelity-design-acceptance.md'
  'docs/superpowers/plans/2026-08-06-high-fidelity-design-alignment.md'
  'docs/task-cards/high-fidelity-design/HF-D03-high-fidelity-evidence-contract.md'
  'docs/task-cards/high-fidelity-design/HF-D04-fixed-design-review.md'
  'docs/task-cards/high-fidelity-design/README.md'
  'scripts/verify-high-fidelity-design'
  'scripts/verify-high-fidelity-design-manifest'
  'scripts/verify-interaction-state-contracts'
  'tests/contracts/interaction-state/verify-high-fidelity-design-manifest.sh'
  'tests/contracts/interaction-state/verify-interaction-state-contracts.sh'
  'tests/task-cards/verify-high-fidelity-design-cards.sh'
)
for required_hfd03_path in "${required_hfd03_paths[@]}"; do
  grep -Fqx -- "- Modify: \`${required_hfd03_path}\`" \
    "${cards_dir}/HF-D03-high-fidelity-evidence-contract.md" ||
    grep -Fqx -- "- Create: \`${required_hfd03_path}\`" \
      "${cards_dir}/HF-D03-high-fidelity-evidence-contract.md" ||
    fail "HF-D03 canonical card is missing exact write-set path: ${required_hfd03_path}"
done

required_hfd04_paths=(
  'AGENTS.md'
  'README.md'
  'Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md'
  'docs/engineering/cognitura-design-index.md'
  'docs/engineering/cognitura-high-fidelity-design-manifest.yaml'
  'docs/engineering/cognitura-high-fidelity-contract-coverage.md'
  'docs/engineering/cognitura-high-fidelity-design-plan.md'
  'docs/engineering/cognitura-high-fidelity-design-acceptance.md'
  'docs/superpowers/plans/2026-08-06-high-fidelity-design-alignment.md'
  'docs/task-cards/high-fidelity-design/HF-D04-fixed-design-review.md'
  'docs/task-cards/high-fidelity-design/README.md'
  'scripts/verify-high-fidelity-design'
  'scripts/verify-high-fidelity-design-manifest'
  'scripts/verify-high-fidelity-contract-coverage'
  'scripts/verify-interaction-state-contracts'
  'tests/contracts/interaction-state/verify-high-fidelity-design-manifest.sh'
  'tests/contracts/interaction-state/verify-high-fidelity-contract-coverage.sh'
  'tests/contracts/interaction-state/verify-interaction-state-contracts.sh'
  'tests/task-cards/verify-high-fidelity-design-cards.sh'
)
for required_hfd04_path in "${required_hfd04_paths[@]}"; do
  grep -Fqx -- "- Modify: \`${required_hfd04_path}\`" \
    "${cards_dir}/HF-D04-fixed-design-review.md" ||
    fail "HF-D04 canonical card is missing exact write-set path: ${required_hfd04_path}"
done

missing_hfd02_path_dir="${test_tmp_root}/missing-hfd02-path"
cp -R "${baseline_dir}" "${missing_hfd02_path_dir}"
sed -i.bak \
  's#^- Modify: `scripts/verify-interaction-state-contracts`$#- Modify: `scripts/verify-high-fidelity-design-manifest`#' \
  "${missing_hfd02_path_dir}/HF-D02-interaction-state-model.md"
rm "${missing_hfd02_path_dir}/HF-D02-interaction-state-model.md.bak"
expect_failure "${missing_hfd02_path_dir}" \
  "missing exact HF-D02 write-set path: scripts/verify-interaction-state-contracts"

missing_hfd03_path_dir="${test_tmp_root}/missing-hfd03-path"
cp -R "${baseline_dir}" "${missing_hfd03_path_dir}"
sed -i.bak \
  's#^- Modify: `scripts/verify-interaction-state-contracts`$#- Modify: `scripts/verify-high-fidelity-design-manifest`#' \
  "${missing_hfd03_path_dir}/HF-D03-high-fidelity-evidence-contract.md"
rm "${missing_hfd03_path_dir}/HF-D03-high-fidelity-evidence-contract.md.bak"
expect_failure "${missing_hfd03_path_dir}" \
  "missing exact HF-D03 write-set path: scripts/verify-interaction-state-contracts"

missing_hfd04_path_dir="${test_tmp_root}/missing-hfd04-path"
cp -R "${baseline_dir}" "${missing_hfd04_path_dir}"
sed -i.bak \
  's#^- Modify: `scripts/verify-interaction-state-contracts`$#- Modify: `scripts/verify-high-fidelity-design-manifest`#' \
  "${missing_hfd04_path_dir}/HF-D04-fixed-design-review.md"
rm "${missing_hfd04_path_dir}/HF-D04-fixed-design-review.md.bak"
expect_failure "${missing_hfd04_path_dir}" \
  "missing exact HF-D04 write-set path: scripts/verify-interaction-state-contracts"

missing_owner_dir="${test_tmp_root}/missing-owner"
cp -R "${baseline_dir}" "${missing_owner_dir}"
sed -i.bak '/^DesignOwner = /d' \
  "${missing_owner_dir}/HF-D02-interaction-state-model.md"
rm "${missing_owner_dir}/HF-D02-interaction-state-model.md.bak"
expect_failure "${missing_owner_dir}" "missing required field: DesignOwner"

second_ready_dir="${test_tmp_root}/second-ready"
cp -R "${baseline_dir}" "${second_ready_dir}"
sed -i.bak 's/^Status = DONE$/Status = READY/' \
  "${second_ready_dir}/HF-D01-reading-presentation-contract.md"
rm "${second_ready_dir}/HF-D01-reading-presentation-contract.md.bak"
expect_failure "${second_ready_dir}" "closed HF design set must keep every card DONE"

forbidden_write_dir="${test_tmp_root}/forbidden-write"
cp -R "${baseline_dir}" "${forbidden_write_dir}"
sed -i.bak '/^## 4[.] 禁止写集$/i\
- Modify: `server/src/forbidden.java`\
' "${forbidden_write_dir}/HF-D01-reading-presentation-contract.md"
rm "${forbidden_write_dir}/HF-D01-reading-presentation-contract.md.bak"
expect_failure "${forbidden_write_dir}" "write set contains forbidden path: server/"

w1_release_dir="${test_tmp_root}/w1-release"
cp -R "${baseline_dir}" "${w1_release_dir}"
sed -i.bak 's/^W1-I00Release = FORBIDDEN$/W1-I00Release = READY/' \
  "${w1_release_dir}/README.md"
rm "${w1_release_dir}/README.md.bak"
expect_failure "${w1_release_dir}" "W1-I00Release must be FORBIDDEN"

reopened_hfd04_dir="${test_tmp_root}/reopened-hfd04"
cp -R "${baseline_dir}" "${reopened_hfd04_dir}"
sed -i.bak 's/^Status = DONE$/Status = READY/' \
  "${reopened_hfd04_dir}/HF-D04-fixed-design-review.md"
rm "${reopened_hfd04_dir}/HF-D04-fixed-design-review.md.bak"
expect_failure "${reopened_hfd04_dir}" "closed HF design set must keep every card DONE"

missing_stage1_dir="${test_tmp_root}/missing-stage1"
cp -R "${baseline_dir}" "${missing_stage1_dir}"
sed -i.bak '/^ReviewStage1Verdict = /d' \
  "${missing_stage1_dir}/HF-D04-fixed-design-review.md"
rm "${missing_stage1_dir}/HF-D04-fixed-design-review.md.bak"
expect_failure "${missing_stage1_dir}" "HF-D04 Stage 1 verdict must be GO"

nonzero_stage2_dir="${test_tmp_root}/nonzero-stage2"
cp -R "${baseline_dir}" "${nonzero_stage2_dir}"
sed -i.bak 's/^ReviewStage2P1 = 0$/ReviewStage2P1 = 1/' \
  "${nonzero_stage2_dir}/HF-D04-fixed-design-review.md"
rm "${nonzero_stage2_dir}/HF-D04-fixed-design-review.md.bak"
expect_failure "${nonzero_stage2_dir}" "HF-D04 Stage 2 findings must be zero"

for extra_mutation in \
  'step1-leading-exit|VerificationFence = TASK5_STEP1_REQUIRED_GATE|exit 0' \
  'step5-leading-exit|VerificationFence = TASK5_STEP5_REQUIRED_GATE|exit 0' \
  'step1-extra-command|VerificationFence = TASK5_STEP1_REQUIRED_GATE|true' \
  'step5-extra-command|VerificationFence = TASK5_STEP5_REQUIRED_GATE|true'; do
  mutation_name="${extra_mutation%%|*}"
  extra_remainder="${extra_mutation#*|}"
  marker="${extra_remainder%%|*}"
  command="${extra_remainder#*|}"
  fixture_plan="${test_tmp_root}/${mutation_name}.md"
  cp "${master_plan}" "${fixture_plan}"
  insert_after_designated_fence_open "${fixture_plan}" "${marker}" "${command}"
  expect_plan_failure "${fixture_plan}" "designated verification fence must exactly match the ordered command list"
done

for duplicate_mutation in \
  'step1-duplicate-status|- [ ] **Step 1: Freeze and verify the candidate**|- [ ] **Step 2: Run independent general and final reviews**|1|git status --short' \
  'step1-duplicate-specialty-core|- [ ] **Step 1: Freeze and verify the candidate**|- [ ] **Step 2: Run independent general and final reviews**|1|scripts/verify-specialty-contract-coverage docs/engineering/cognitura-specialty-contract-coverage.md docs/design/cognitura-schema-baseline-2.0.md' \
  'step1-duplicate-specialty-wrapper|- [ ] **Step 1: Freeze and verify the candidate**|- [ ] **Step 2: Run independent general and final reviews**|1|bash tests/contracts/specialty-coverage/verify-specialty-contract-coverage.sh' \
  'step5-duplicate-specialty-core|- [ ] **Step 5: Verify and commit closure**|### Task 6: HV-D00 Visual Foundation and Prototype Governance|2|scripts/verify-specialty-contract-coverage docs/engineering/cognitura-specialty-contract-coverage.md docs/design/cognitura-schema-baseline-2.0.md' \
  'step5-duplicate-specialty-wrapper|- [ ] **Step 5: Verify and commit closure**|### Task 6: HV-D00 Visual Foundation and Prototype Governance|2|bash tests/contracts/specialty-coverage/verify-specialty-contract-coverage.sh'; do
  mutation_name="${duplicate_mutation%%|*}"
  duplicate_remainder="${duplicate_mutation#*|}"
  start_header="${duplicate_remainder%%|*}"
  duplicate_remainder="${duplicate_remainder#*|}"
  end_header="${duplicate_remainder%%|*}"
  duplicate_remainder="${duplicate_remainder#*|}"
  destination_fence="${duplicate_remainder%%|*}"
  command="${duplicate_remainder#*|}"
  fixture_plan="${test_tmp_root}/${mutation_name}.md"
  cp "${master_plan}" "${fixture_plan}"
  copy_step_command_to_fence \
    "${fixture_plan}" "${start_header}" "${end_header}" "${command}" "${destination_fence}"
  expect_plan_failure "${fixture_plan}" "command must occur exactly once across all Step bash fences: ${command}"
done

specialty_core='scripts/verify-specialty-contract-coverage docs/engineering/cognitura-specialty-contract-coverage.md docs/design/cognitura-schema-baseline-2.0.md'
specialty_wrapper='bash tests/contracts/specialty-coverage/verify-specialty-contract-coverage.sh'
for order_mutation in \
  'step1-command-order|VerificationFence = TASK5_STEP1_REQUIRED_GATE' \
  'step5-command-order|VerificationFence = TASK5_STEP5_REQUIRED_GATE'; do
  mutation_name="${order_mutation%%|*}"
  marker="${order_mutation#*|}"
  fixture_plan="${test_tmp_root}/${mutation_name}.md"
  cp "${master_plan}" "${fixture_plan}"
  swap_designated_commands "${fixture_plan}" "${marker}" "${specialty_core}" "${specialty_wrapper}"
  expect_plan_failure "${fixture_plan}" "designated verification fence must exactly match the ordered command list"
done

for relocation_mutation in \
  'step1-relocated-specialty-core|- [ ] **Step 1: Freeze and verify the candidate**|- [ ] **Step 2: Run independent general and final reviews**|1|scripts/verify-specialty-contract-coverage docs/engineering/cognitura-specialty-contract-coverage.md docs/design/cognitura-schema-baseline-2.0.md' \
  'step1-relocated-specialty-wrapper|- [ ] **Step 1: Freeze and verify the candidate**|- [ ] **Step 2: Run independent general and final reviews**|1|bash tests/contracts/specialty-coverage/verify-specialty-contract-coverage.sh' \
  'step5-relocated-specialty-core|- [ ] **Step 5: Verify and commit closure**|### Task 6: HV-D00 Visual Foundation and Prototype Governance|2|scripts/verify-specialty-contract-coverage docs/engineering/cognitura-specialty-contract-coverage.md docs/design/cognitura-schema-baseline-2.0.md' \
  'step5-relocated-specialty-wrapper|- [ ] **Step 5: Verify and commit closure**|### Task 6: HV-D00 Visual Foundation and Prototype Governance|2|bash tests/contracts/specialty-coverage/verify-specialty-contract-coverage.sh'; do
  mutation_name="${relocation_mutation%%|*}"
  relocation_remainder="${relocation_mutation#*|}"
  start_header="${relocation_remainder%%|*}"
  relocation_remainder="${relocation_remainder#*|}"
  end_header="${relocation_remainder%%|*}"
  relocation_remainder="${relocation_remainder#*|}"
  destination_fence="${relocation_remainder%%|*}"
  command="${relocation_remainder#*|}"
  fixture_plan="${test_tmp_root}/${mutation_name}.md"
  cp "${master_plan}" "${fixture_plan}"
  relocate_step_command \
    "${fixture_plan}" "${start_header}" "${end_header}" "${command}" "${destination_fence}"
  expect_plan_failure "${fixture_plan}" "designated verification fence missing command: ${command}"
done

for marker_mutation in \
  'step1-missing-marker|- [ ] **Step 1: Freeze and verify the candidate**|- [ ] **Step 2: Run independent general and final reviews**|VerificationFence = TASK5_STEP1_REQUIRED_GATE|missing' \
  'step1-duplicate-marker|- [ ] **Step 1: Freeze and verify the candidate**|- [ ] **Step 2: Run independent general and final reviews**|VerificationFence = TASK5_STEP1_REQUIRED_GATE|duplicate' \
  'step5-missing-marker|- [ ] **Step 5: Verify and commit closure**|### Task 6: HV-D00 Visual Foundation and Prototype Governance|VerificationFence = TASK5_STEP5_REQUIRED_GATE|missing' \
  'step5-duplicate-marker|- [ ] **Step 5: Verify and commit closure**|### Task 6: HV-D00 Visual Foundation and Prototype Governance|VerificationFence = TASK5_STEP5_REQUIRED_GATE|duplicate'; do
  mutation_name="${marker_mutation%%|*}"
  marker_remainder="${marker_mutation#*|}"
  start_header="${marker_remainder%%|*}"
  marker_remainder="${marker_remainder#*|}"
  end_header="${marker_remainder%%|*}"
  marker_remainder="${marker_remainder#*|}"
  marker="${marker_remainder%%|*}"
  mutation_kind="${marker_remainder#*|}"
  fixture_plan="${test_tmp_root}/${mutation_name}.md"
  cp "${master_plan}" "${fixture_plan}"
  if [[ "${mutation_kind}" == "missing" ]]; then
    sed -i.bak "/^${marker}$/d" "${fixture_plan}"
    rm "${fixture_plan}.bak"
  else
    rewritten_plan="${fixture_plan}.tmp"
    awk -v start_header="${start_header}" -v end_header="${end_header}" -v marker="${marker}" '
      $0 == start_header {inside_step=1}
      $0 == end_header {inside_step=0}
      inside_step && $0 == "```bash" && !inserted {
        print marker
        print marker
        inserted=1
      }
      {print}
    ' "${fixture_plan}" >"${rewritten_plan}"
    mv "${rewritten_plan}" "${fixture_plan}"
  fi
  expect_plan_failure "${fixture_plan}" "expected exactly one verification fence marker: ${marker}"
done

for sentinel_mutation in \
  'refreeze-protected-assets|git diff --exit-code HEAD^ HEAD -- Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md docs/engineering/cognitura-high-fidelity-design-manifest.yaml docs/engineering/cognitura-high-fidelity-contract-coverage.md' \
  'refreeze-exact-four-files|test "$(git diff --name-only HEAD^ HEAD | LC_ALL=C sort | paste -sd " " -)" = "docs/superpowers/plans/2026-08-06-high-fidelity-design-alignment.md docs/task-cards/high-fidelity-design/HF-D04-fixed-design-review.md scripts/verify-high-fidelity-design tests/task-cards/verify-high-fidelity-design-cards.sh"'; do
  mutation_name="${sentinel_mutation%%|*}"
  command="${sentinel_mutation#*|}"
  fixture_plan="${test_tmp_root}/${mutation_name}.md"
  cp "${master_plan}" "${fixture_plan}"
  delete_step_command \
    "${fixture_plan}" \
    '- [ ] **Step 1: Freeze and verify the candidate**' \
    '- [ ] **Step 2: Run independent general and final reviews**' \
    "${command}"
  expect_plan_failure "${fixture_plan}" "re-freeze sentinel missing command: ${command}"
done

for plan_mutation in \
  'step1-interaction-wrapper|- [ ] **Step 1: Freeze and verify the candidate**|- [ ] **Step 2: Run independent general and final reviews**|bash tests/contracts/interaction-state/verify-interaction-state-contracts.sh' \
  'step1-manifest-wrapper|- [ ] **Step 1: Freeze and verify the candidate**|- [ ] **Step 2: Run independent general and final reviews**|bash tests/contracts/interaction-state/verify-high-fidelity-design-manifest.sh' \
  'step1-coverage-wrapper|- [ ] **Step 1: Freeze and verify the candidate**|- [ ] **Step 2: Run independent general and final reviews**|bash tests/contracts/interaction-state/verify-high-fidelity-contract-coverage.sh' \
  'step1-specialty-core|- [ ] **Step 1: Freeze and verify the candidate**|- [ ] **Step 2: Run independent general and final reviews**|scripts/verify-specialty-contract-coverage docs/engineering/cognitura-specialty-contract-coverage.md docs/design/cognitura-schema-baseline-2.0.md' \
  'step1-specialty-wrapper|- [ ] **Step 1: Freeze and verify the candidate**|- [ ] **Step 2: Run independent general and final reviews**|bash tests/contracts/specialty-coverage/verify-specialty-contract-coverage.sh' \
  'step5-interaction-wrapper|- [ ] **Step 5: Verify and commit closure**|### Task 6: HV-D00 Visual Foundation and Prototype Governance|bash tests/contracts/interaction-state/verify-interaction-state-contracts.sh' \
  'step5-manifest-wrapper|- [ ] **Step 5: Verify and commit closure**|### Task 6: HV-D00 Visual Foundation and Prototype Governance|bash tests/contracts/interaction-state/verify-high-fidelity-design-manifest.sh' \
  'step5-coverage-wrapper|- [ ] **Step 5: Verify and commit closure**|### Task 6: HV-D00 Visual Foundation and Prototype Governance|bash tests/contracts/interaction-state/verify-high-fidelity-contract-coverage.sh' \
  'step5-specialty-core|- [ ] **Step 5: Verify and commit closure**|### Task 6: HV-D00 Visual Foundation and Prototype Governance|scripts/verify-specialty-contract-coverage docs/engineering/cognitura-specialty-contract-coverage.md docs/design/cognitura-schema-baseline-2.0.md' \
  'step5-specialty-wrapper|- [ ] **Step 5: Verify and commit closure**|### Task 6: HV-D00 Visual Foundation and Prototype Governance|bash tests/contracts/specialty-coverage/verify-specialty-contract-coverage.sh'; do
  mutation_name="${plan_mutation%%|*}"
  plan_mutation_remainder="${plan_mutation#*|}"
  start_header="${plan_mutation_remainder%%|*}"
  plan_mutation_remainder="${plan_mutation_remainder#*|}"
  end_header="${plan_mutation_remainder%%|*}"
  command="${plan_mutation_remainder#*|}"
  fixture_plan="${test_tmp_root}/${mutation_name}.md"
  cp "${master_plan}" "${fixture_plan}"
  delete_step_command "${fixture_plan}" "${start_header}" "${end_header}" "${command}"
  expect_plan_failure "${fixture_plan}" "designated verification fence missing command: ${command}"
done

printf '%s\n' \
  "HighFidelityDesignTaskCardContractTests = PASS" \
  "ReceiptNegativeCases = ${receipt_negative_cases}" \
  "NegativeCases = $((38 + receipt_negative_cases))"
