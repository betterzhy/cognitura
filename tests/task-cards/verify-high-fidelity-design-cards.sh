#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-high-fidelity-design"
cards_dir="${repo_root}/docs/task-cards/high-fidelity-design"
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

[[ -x "${verifier}" ]] || fail "high-fidelity design verifier is missing or not executable"
[[ -d "${cards_dir}" ]] || fail "high-fidelity design card directory is missing"

canonical_output="$("${verifier}" --cards-dir "${cards_dir}")" ||
  fail "canonical high-fidelity design cards were rejected"
canonical_active="$(sed -n 's/^ActiveTaskCard = //p' "${cards_dir}/README.md")"
for expected_line in \
  "HighFidelityDesignTaskCardValidation = PASS" \
  "TaskCardCount = 5" \
  "TaskCardSetStatus = READY_FOR_EXECUTION" \
  "ActiveTaskCard = ${canonical_active}" \
  "BusinessImplementation = NOT_AUTHORIZED" \
  "W1-I00Release = FORBIDDEN"; do
  [[ "${canonical_output}" == *"${expected_line}"* ]] ||
    fail "canonical output is missing: ${expected_line}"
done

baseline_dir="${test_tmp_root}/baseline"
cp -R "${cards_dir}" "${baseline_dir}"

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
expect_failure "${second_ready_dir}" "expected exactly one READY task card"

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

printf '%s\n' \
  "HighFidelityDesignTaskCardContractTests = PASS" \
  "NegativeCases = 7"
