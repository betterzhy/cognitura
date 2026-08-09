#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-high-fidelity-visual"
cards_dir="${repo_root}/docs/task-cards/high-fidelity-visual"
visual_design="${repo_root}/docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md"
prototype_dir="${repo_root}/docs/design/high-fidelity/prototype"
evidence_dir="${repo_root}/docs/design/high-fidelity/evidence"
master_plan="${repo_root}/docs/superpowers/plans/2026-08-06-high-fidelity-design-alignment.md"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-hf-visual-cards.XXXXXX")"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

run_verifier() {
  "${verifier}" \
    --cards-dir "$1" \
    --visual-design "$2" \
    --prototype-dir "$3" \
    --evidence-dir "$4" \
    --plan "$5"
}

expect_failure() {
  local fixture_root="$1"
  local expected_message="$2"
  local output

  if output="$(run_verifier \
    "${fixture_root}/cards" \
    "${fixture_root}/visual-design.md" \
    "${fixture_root}/prototype" \
    "${fixture_root}/evidence" \
    "${fixture_root}/master-plan.md" 2>&1)"; then
    fail "invalid fixture unexpectedly passed: ${fixture_root}"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected error '${expected_message}', got: ${output}"
}

make_fixture() {
  local fixture_root="$1"
  mkdir -p "${fixture_root}"
  cp -R "${cards_dir}" "${fixture_root}/cards"
  cp "${visual_design}" "${fixture_root}/visual-design.md"
  cp -R "${prototype_dir}" "${fixture_root}/prototype"
  cp -R "${evidence_dir}" "${fixture_root}/evidence"
  cp "${master_plan}" "${fixture_root}/master-plan.md"
}

[[ -x "${verifier}" ]] || fail "high-fidelity visual verifier is missing or not executable"

canonical_output="$(run_verifier \
  "${cards_dir}" \
  "${visual_design}" \
  "${prototype_dir}" \
  "${evidence_dir}" \
  "${master_plan}")" || fail "canonical high-fidelity visual assets were rejected"

for expected_line in \
  "HighFidelityVisualTaskCardValidation = PASS" \
  "TaskCardCount = 6" \
  "TaskCardSetStatus = READY_FOR_EXECUTION" \
  "ActiveTaskCard = HV-D01" \
  "DoneTaskCardCount = 1" \
  "ReadyTaskCardCount = 1" \
  "BlockedTaskCardCount = 4" \
  "Task6WriteSetItemCount = 22" \
  "VisualFoundationPrototypeValidation = PASS" \
  "VisualFoundationEvidence = 1440x1100" \
  "HighFidelityVisualDesign = NOT_RUN" \
  "HighFidelityUsabilityValidation = NOT_RUN" \
  "BusinessImplementation = NOT_AUTHORIZED" \
  "FormalDatabaseWrite = NOT_AUTHORIZED" \
  "RemotePush = NOT_AUTHORIZED"; do
  [[ "${canonical_output}" == *"${expected_line}"* ]] ||
    fail "canonical output is missing: ${expected_line}"
done

missing_card="${test_tmp_root}/missing-card"
make_fixture "${missing_card}"
rm "${missing_card}/cards/HV-D05-fixed-visual-usability-review.md"
expect_failure "${missing_card}" "actual visual task card count 5 does not match 6"

second_ready="${test_tmp_root}/second-ready"
make_fixture "${second_ready}"
sed -i.bak 's/^Status = BLOCKED_BY_DEPENDENCY$/Status = READY/' \
  "${second_ready}/cards/HV-D02-focus-and-source.md"
rm "${second_ready}/cards/HV-D02-focus-and-source.md.bak"
expect_failure "${second_ready}" "exactly one READY card is required"

wrong_write_set="${test_tmp_root}/wrong-write-set"
make_fixture "${wrong_write_set}"
sed -i.bak 's/^WriteSetItemCount = 9$/WriteSetItemCount = 8/' \
  "${wrong_write_set}/cards/HV-D02-focus-and-source.md"
rm "${wrong_write_set}/cards/HV-D02-focus-and-source.md.bak"
expect_failure "${wrong_write_set}" "HV-D02: WriteSetItemCount must be 9"

wildcard_plan="${test_tmp_root}/wildcard-plan"
make_fixture "${wildcard_plan}"
sed -i.bak \
  's#- Modify: `docs/design/high-fidelity/prototype/index.html`#- Modify: `docs/design/high-fidelity/prototype/*`#' \
  "${wildcard_plan}/master-plan.md"
rm "${wildcard_plan}/master-plan.md.bak"
expect_failure "${wildcard_plan}" "master plan must not use prototype wildcard paths"

network_prototype="${test_tmp_root}/network-prototype"
make_fixture "${network_prototype}"
printf '\nfetch("/api/visual-fixture");\n' >>"${network_prototype}/prototype/prototype.js"
expect_failure "${network_prototype}" "prototype must not use network APIs"

persistent_prototype="${test_tmp_root}/persistent-prototype"
make_fixture "${persistent_prototype}"
printf '\nlocalStorage.setItem("state", "visual-foundation");\n' >>"${persistent_prototype}/prototype/prototype.js"
expect_failure "${persistent_prototype}" "prototype must not persist user data"

wrong_png="${test_tmp_root}/wrong-png"
make_fixture "${wrong_png}"
cp "${wrong_png}/evidence/visual-foundation-desktop.png" \
  "${wrong_png}/evidence/visual-foundation-wrong-size.png"
mv "${wrong_png}/evidence/visual-foundation-wrong-size.png" \
  "${wrong_png}/evidence/visual-foundation-desktop.png"
printf 'not a png\n' >"${wrong_png}/evidence/visual-foundation-desktop.png"
expect_failure "${wrong_png}" "visual foundation evidence must be a 1440x1100 PNG"

printf 'HighFidelityVisualTaskCardContractTests = PASS\n'
printf 'NegativeFixtureCount = 7\n'
