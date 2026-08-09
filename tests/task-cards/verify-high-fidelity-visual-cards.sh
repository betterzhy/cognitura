#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-high-fidelity-visual"
cards_dir="${repo_root}/docs/task-cards/high-fidelity-visual"
visual_design="${repo_root}/docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md"
prototype_dir="${repo_root}/docs/design/high-fidelity/prototype"
evidence_dir="${repo_root}/docs/design/high-fidelity/evidence"
master_plan="${repo_root}/docs/superpowers/plans/2026-08-06-high-fidelity-design-alignment.md"
acceptance="${repo_root}/docs/engineering/cognitura-high-fidelity-design-acceptance.md"
evidence_plan="${repo_root}/docs/engineering/cognitura-high-fidelity-design-plan.md"
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
    --plan "$5" \
    --acceptance "$6" \
    --evidence-plan "$7"
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
    "${fixture_root}/master-plan.md" \
    "${fixture_root}/acceptance.md" \
    "${fixture_root}/evidence-plan.md" 2>&1)"; then
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
  cp "${acceptance}" "${fixture_root}/acceptance.md"
  cp "${evidence_plan}" "${fixture_root}/evidence-plan.md"
}

[[ -x "${verifier}" ]] || fail "high-fidelity visual verifier is missing or not executable"

canonical_output="$(run_verifier \
  "${cards_dir}" \
  "${visual_design}" \
  "${prototype_dir}" \
  "${evidence_dir}" \
  "${master_plan}" \
  "${acceptance}" \
  "${evidence_plan}")" || fail "canonical high-fidelity visual assets were rejected"

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
  "UnknownFixtureStateRejection = PASS" \
  "VisualFoundationEvidenceFreshness = PASS" \
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
sed -i.bak 's/^WriteSetItemCount = 18$/WriteSetItemCount = 17/' \
  "${wrong_write_set}/cards/HV-D02-focus-and-source.md"
rm "${wrong_write_set}/cards/HV-D02-focus-and-source.md.bak"
expect_failure "${wrong_write_set}" "HV-D02: WriteSetItemCount must be 18"

inexact_card_write_set="${test_tmp_root}/inexact-card-write-set"
make_fixture "${inexact_card_write_set}"
sed -i.bak \
  's#docs/design/high-fidelity/prototype/index.html#docs/design/high-fidelity/prototype/index.invalid.html#' \
  "${inexact_card_write_set}/cards/HV-D01-module-default-reading.md"
rm "${inexact_card_write_set}/cards/HV-D01-module-default-reading.md.bak"
expect_failure "${inexact_card_write_set}" "HV-D01: write-set paths do not match exact contract"

inexact_plan_write_set="${test_tmp_root}/inexact-plan-write-set"
make_fixture "${inexact_plan_write_set}"
sed -i.bak \
  's#- Create: `docs/design/high-fidelity/evidence/module-source-verification-desktop.png`#- Create: `docs/design/high-fidelity/evidence/module-source-verification-invalid.png`#' \
  "${inexact_plan_write_set}/master-plan.md"
rm "${inexact_plan_write_set}/master-plan.md.bak"
expect_failure "${inexact_plan_write_set}" "master plan Task 8 write-set paths do not match exact contract"

wrong_rf_owner="${test_tmp_root}/wrong-rf-owner"
make_fixture "${wrong_rf_owner}"
sed -i.bak \
  's/\(RFAcceptance = RF-AC-02|.*|Gate=\)HV-D01$/\1HV-D02/' \
  "${wrong_rf_owner}/acceptance.md"
rm "${wrong_rf_owner}/acceptance.md.bak"
expect_failure "${wrong_rf_owner}" "RF-AC-02 must be owned by HV-D01"

wrong_primary_artifact="${test_tmp_root}/wrong-primary-artifact"
make_fixture "${wrong_primary_artifact}"
sed -i.bak \
  's#evidence/module-recovery-desktop.png#evidence/module-partial-failure-desktop.png#' \
  "${wrong_primary_artifact}/evidence-plan.md"
rm "${wrong_primary_artifact}/evidence-plan.md.bak"
expect_failure "${wrong_primary_artifact}" "EvidencePath 05 canonical primary artifact must be module-recovery-desktop.png"

duplicate_visual_status="${test_tmp_root}/duplicate-visual-status"
make_fixture "${duplicate_visual_status}"
printf '\nHighFidelityVisualDesign = PASS\n' >>"${duplicate_visual_status}/visual-design.md"
expect_failure "${duplicate_visual_status}" "visual-design.md: expected one HighFidelityVisualDesign field, found 2"

extra_fixture_state="${test_tmp_root}/extra-fixture-state"
make_fixture "${extra_fixture_state}"
printf '\nFixtureState = rogue-state\n' >>"${extra_fixture_state}/visual-design.md"
expect_failure "${extra_fixture_state}" "FixtureState must be the exact canonical set"

unknown_state_fallback="${test_tmp_root}/unknown-state-fallback"
make_fixture "${unknown_state_fallback}"
sed -i.bak \
  's/REJECTED_UNKNOWN_STATE/ACCEPTED/' \
  "${unknown_state_fallback}/prototype/prototype.js"
rm "${unknown_state_fallback}/prototype/prototype.js.bak"
expect_failure "${unknown_state_fallback}" "unknown fixture state must be explicitly rejected"

index_glob="${test_tmp_root}/index-glob"
make_fixture "${index_glob}"
sed -i.bak \
  's#docs/design/high-fidelity/prototype/index.html#docs/design/high-fidelity/prototype/index.*#' \
  "${index_glob}/cards/HV-D01-module-default-reading.md"
rm "${index_glob}/cards/HV-D01-module-default-reading.md.bak"
expect_failure "${index_glob}" "HV-D01: write-set paths do not match exact contract"

remote_html="${test_tmp_root}/remote-html"
make_fixture "${remote_html}"
sed -i.bak \
  's#</head>#<script src="https://example.invalid/fixture.js"></script></head>#' \
  "${remote_html}/prototype/index.html"
rm "${remote_html}/prototype/index.html.bak"
expect_failure "${remote_html}" "prototype must not use external network resources"

remote_js="${test_tmp_root}/remote-js"
make_fixture "${remote_js}"
printf '\nimport("https://example.invalid/fixture.js");\n' >>"${remote_js}/prototype/prototype.js"
expect_failure "${remote_js}" "prototype must not use external network resources"

remote_css_import="${test_tmp_root}/remote-css-import"
make_fixture "${remote_css_import}"
printf '\n@import url("https://example.invalid/fixture.css");\n' >>"${remote_css_import}/prototype/styles.css"
expect_failure "${remote_css_import}" "prototype must not use external network resources"

remote_css_url="${test_tmp_root}/remote-css-url"
make_fixture "${remote_css_url}"
printf '\n.remote { background: url("http://example.invalid/fixture.png"); }\n' >>"${remote_css_url}/prototype/styles.css"
expect_failure "${remote_css_url}" "prototype must not use external network resources"

stale_evidence="${test_tmp_root}/stale-evidence"
make_fixture "${stale_evidence}"
sed -i.bak \
  's/并发写入发生时，读取如何保持一个一致的观察边界？/可见标题已改变但截图仍旧。/' \
  "${stale_evidence}/prototype/index.html"
rm "${stale_evidence}/prototype/index.html.bak"
expect_failure "${stale_evidence}" "visual foundation evidence is stale for the current prototype"

wildcard_plan="${test_tmp_root}/wildcard-plan"
make_fixture "${wildcard_plan}"
sed -i.bak \
  's#- Modify: `docs/design/high-fidelity/prototype/index.html`#- Modify: `docs/design/high-fidelity/prototype/*`#' \
  "${wildcard_plan}/master-plan.md"
rm "${wildcard_plan}/master-plan.md.bak"
expect_failure "${wildcard_plan}" "master plan Task 7 write-set paths do not match exact contract"

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
printf 'NegativeFixtureCount = 20\n'
