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

chrome_bin="${CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
[[ -x "${chrome_bin}" ]] || fail "Chrome headless is required for DOM mutation screenshot recapture"

terminate_headless_chrome() {
  local chrome_pid="$1"
  kill "${chrome_pid}" 2>/dev/null || true
  wait "${chrome_pid}" 2>/dev/null || true
}

recapture_module_evidence() {
  local fixture_root="$1"
  local chrome_profile="${fixture_root}/chrome-profile-recapture"
  local staged_png="${fixture_root}/evidence/.module-default-reading-recapture.png"
  local chrome_pid attempt artifact_ready

  "${chrome_bin}" \
    --headless=new --disable-gpu --hide-scrollbars \
    --user-data-dir="${chrome_profile}" --no-first-run --no-default-browser-check \
    --use-mock-keychain \
    --window-size=1440,1100 \
    --screenshot="${staged_png}" \
    "file://${fixture_root}/prototype/index.html?state=module-default" >/dev/null 2>&1 &
  chrome_pid=$!
  artifact_ready=NO
  attempt=0
  while [[ "${attempt}" -lt 300 ]]; do
    if file "${staged_png}" 2>/dev/null | grep -Fq 'PNG image data, 1440 x 1100'; then
      artifact_ready=YES
      break
    fi
    kill -0 "${chrome_pid}" 2>/dev/null || break
    sleep 0.1
    attempt=$((attempt + 1))
  done
  terminate_headless_chrome "${chrome_pid}"
  [[ "${artifact_ready}" == "YES" ]] ||
    fail "could not recapture module-default mutation evidence: ${fixture_root}"
  mv -f "${staged_png}" "${fixture_root}/evidence/module-default-reading-desktop.png"
  file "${fixture_root}/evidence/module-default-reading-desktop.png" |
    grep -Fq 'PNG image data, 1440 x 1100' ||
    fail "recaptured module-default mutation evidence must be a 1440x1100 PNG: ${fixture_root}"
}

recapture_hvd02_evidence() {
  local fixture_root="$1"
  local state_id="$2"
  local artifact_name="$3"
  local chrome_profile="${fixture_root}/chrome-profile-${state_id}-recapture"
  local staged_png="${fixture_root}/evidence/.${artifact_name}.recapture.png"
  local chrome_pid attempt artifact_ready

  "${chrome_bin}" \
    --headless=new --disable-gpu --hide-scrollbars \
    --user-data-dir="${chrome_profile}" --no-first-run --no-default-browser-check \
    --use-mock-keychain \
    --window-size=1440,1100 \
    --screenshot="${staged_png}" \
    "file://${fixture_root}/prototype/index.html?state=${state_id}" >/dev/null 2>&1 &
  chrome_pid=$!
  artifact_ready=NO
  attempt=0
  while [[ "${attempt}" -lt 300 ]]; do
    if file "${staged_png}" 2>/dev/null | grep -Fq 'PNG image data, 1440 x 1100'; then
      artifact_ready=YES
      break
    fi
    kill -0 "${chrome_pid}" 2>/dev/null || break
    sleep 0.1
    attempt=$((attempt + 1))
  done
  terminate_headless_chrome "${chrome_pid}"
  [[ "${artifact_ready}" == "YES" ]] ||
    fail "could not recapture ${state_id} mutation evidence: ${fixture_root}"
  mv -f "${staged_png}" "${fixture_root}/evidence/${artifact_name}"
}

expect_hvd02_dom_failure() {
  local fixture_root="$1"
  local state_id="$2"
  local artifact_name="$3"
  local expected_message="$4"

  recapture_hvd02_evidence "${fixture_root}" "${state_id}" "${artifact_name}"
  expect_failure "${fixture_root}" "${expected_message}"
}

module_dom_unexpected_passes=()
module_dom_unexpected_failures=()
expect_module_dom_failure() {
  local fixture_root="$1"
  local expected_message="$2"
  local output

  recapture_module_evidence "${fixture_root}"
  if output="$(run_verifier \
    "${fixture_root}/cards" \
    "${fixture_root}/visual-design.md" \
    "${fixture_root}/prototype" \
    "${fixture_root}/evidence" \
    "${fixture_root}/master-plan.md" \
    "${fixture_root}/acceptance.md" \
    "${fixture_root}/evidence-plan.md" 2>&1)"; then
    module_dom_unexpected_passes+=("$(basename "${fixture_root}")")
    return
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected DOM error '${expected_message}', got: ${output}"
}

expect_module_dom_success() {
  local fixture_root="$1"
  local output

  recapture_module_evidence "${fixture_root}"
  if ! output="$(run_verifier \
    "${fixture_root}/cards" \
    "${fixture_root}/visual-design.md" \
    "${fixture_root}/prototype" \
    "${fixture_root}/evidence" \
    "${fixture_root}/master-plan.md" \
    "${fixture_root}/acceptance.md" \
    "${fixture_root}/evidence-plan.md" 2>&1)"; then
    module_dom_unexpected_failures+=("$(basename "${fixture_root}"):${output}")
  fi
}

assert_module_dom_failures_closed() {
  local failure_summary=""
  if [[ "${#module_dom_unexpected_passes[@]}" -ne 0 ]]; then
    failure_summary="DOM mutations unexpectedly passed: ${module_dom_unexpected_passes[*]}"
  fi
  if [[ "${#module_dom_unexpected_failures[@]}" -ne 0 ]]; then
    failure_summary="${failure_summary} valid selector-semantic fixtures unexpectedly failed: ${module_dom_unexpected_failures[*]}"
  fi
  [[ -z "${failure_summary}" ]] ||
    fail "module-default fresh screenshot selector checks failed:${failure_summary}"
}

[[ -x "${verifier}" ]] || fail "high-fidelity visual verifier is missing or not executable"
[[ "$(grep -Fc -- '--user-data-dir=' "${verifier}" || true)" -eq 2 ]] ||
  fail "every validator Chrome launch must use an isolated temporary user-data-dir"
[[ "$(grep -Fc -- '--user-data-dir=' "${BASH_SOURCE[0]}" || true)" -ge 2 ]] ||
  fail "DOM mutation screenshot recapture must use an isolated temporary user-data-dir"
grep -Fq 'terminate_headless_chrome() {' "${verifier}" ||
  fail "validator Chrome launches must terminate after their artifact is ready"
grep -Fq 'terminate_headless_chrome() {' "${BASH_SOURCE[0]}" ||
  fail "DOM mutation Chrome launches must terminate after their screenshot is ready"

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
  "ActiveTaskCard = HV-D03" \
  "DoneTaskCardCount = 3" \
  "ReadyTaskCardCount = 1" \
  "BlockedTaskCardCount = 2" \
  "Task6WriteSetItemCount = 22" \
  "CurrentStageProjectionValidation = PASS" \
  "VisualFoundationPrototypeValidation = PASS" \
  "VisualFoundationEvidence = 1440x1100" \
  "UnknownFixtureStateRejection = PASS" \
  "VisualFoundationEvidenceFreshness = PASS" \
  "ModuleDefaultReadingPrototypeValidation = PASS" \
  "ModuleDefaultReadingBrowserSelectorValidation = PASS" \
  "ModuleDefaultReadingEvidence = 1440x1100" \
  "ModuleDefaultReadingEvidenceFreshness = PASS" \
  "RelationFocusBrowserSelectorValidation = PASS" \
  "RelationFocusInteractionTransitionValidation = PASS" \
  "QuickSourceTransientTransitionValidation = PASS" \
  "RelationFocusEvidence = 1440x1100" \
  "RelationFocusEvidenceFreshness = PASS" \
  "SourceVerificationBrowserSelectorValidation = PASS" \
  "SourceVerificationInteractionTransitionValidation = PASS" \
  "SourceVerificationEvidence = 1440x1100" \
  "SourceVerificationEvidenceFreshness = PASS" \
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
  "${second_ready}/cards/HV-D04-cross-layer-responsive-export.md"
rm "${second_ready}/cards/HV-D04-cross-layer-responsive-export.md.bak"
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

for status_contract in \
  'HighFidelityVisualDesign|NOT_RUN|PASS' \
  'HighFidelityUsabilityValidation|NOT_RUN|PASS' \
  'ImplementationValidation|NOT_RUN|PASS' \
  'BusinessImplementation|NOT_AUTHORIZED|AUTHORIZED' \
  'FormalDatabaseWrite|NOT_AUTHORIZED|AUTHORIZED' \
  'RemotePush|NOT_AUTHORIZED|AUTHORIZED'; do
  status_key="${status_contract%%|*}"
  remaining_status="${status_contract#*|}"
  expected_status="${remaining_status%%|*}"
  conflicting_status="${remaining_status#*|}"
  for status_document in evidence-plan acceptance; do
    duplicate_fixture="${test_tmp_root}/duplicate-${status_document}-${status_key}"
    make_fixture "${duplicate_fixture}"
    printf '\n%s = %s\n' "${status_key}" "${expected_status}" >> \
      "${duplicate_fixture}/${status_document}.md"
    expect_failure "${duplicate_fixture}" \
      "${status_document}.md: expected one ${status_key} field, found 2"

    conflicting_fixture="${test_tmp_root}/conflicting-${status_document}-${status_key}"
    make_fixture "${conflicting_fixture}"
    printf '\n%s = %s\n' "${status_key}" "${conflicting_status}" >> \
      "${conflicting_fixture}/${status_document}.md"
    expect_failure "${conflicting_fixture}" \
      "${status_document}.md: expected one ${status_key} field, found 2"
  done
done

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

wrong_module_projection_budget="${test_tmp_root}/wrong-module-projection-budget"
make_fixture "${wrong_module_projection_budget}"
sed -i.bak \
  's/dataset.primaryVisualProjectionCount = "1"/dataset.primaryVisualProjectionCount = "2"/' \
  "${wrong_module_projection_budget}/prototype/prototype.js"
rm "${wrong_module_projection_budget}/prototype/prototype.js.bak"
expect_failure "${wrong_module_projection_budget}" \
  'module-default real primary visual projection count 1 does not match declared count 2'

persistent_module_governance="${test_tmp_root}/persistent-module-governance"
make_fixture "${persistent_module_governance}"
sed -i.bak \
  's/dataset.persistentGovernanceSidePanelCount = "0"/dataset.persistentGovernanceSidePanelCount = "1"/' \
  "${persistent_module_governance}/prototype/prototype.js"
rm "${persistent_module_governance}/prototype/prototype.js.bak"
expect_failure "${persistent_module_governance}" \
  'module-default real persistent governance side panel count 0 does not match declared count 1'

missing_real_module_closure="${test_tmp_root}/missing-real-module-closure"
make_fixture "${missing_real_module_closure}"
perl -0pi -e 's#\s*<section class="module-closure".*?</section>##s' \
  "${missing_real_module_closure}/prototype/index.html"
expect_module_dom_failure "${missing_real_module_closure}" \
  'module-default must contain exactly one real .module-closure'

missing_real_core_question="${test_tmp_root}/missing-real-core-question"
make_fixture "${missing_real_core_question}"
perl -0pi -e 's#(<header class="module-opening">\s*)<div>.*?</div>#$1#s' \
  "${missing_real_core_question}/prototype/index.html"
expect_module_dom_failure "${missing_real_core_question}" \
  'module-default must contain exactly one real CoreQuestion'

duplicate_real_core_question="${test_tmp_root}/duplicate-real-core-question"
make_fixture "${duplicate_real_core_question}"
perl -0pi -e 's#(<header class="module-opening">\s*)(<div>.*?</div>)#$1$2$2#s' \
  "${duplicate_real_core_question}/prototype/index.html"
expect_module_dom_failure "${duplicate_real_core_question}" \
  'module-default must contain exactly one real CoreQuestion'

missing_real_core_conclusion="${test_tmp_root}/missing-real-core-conclusion"
make_fixture "${missing_real_core_conclusion}"
perl -0pi -e 's#\s*<div class="module-conclusion-lead".*?</div>##s' \
  "${missing_real_core_conclusion}/prototype/index.html"
expect_module_dom_failure "${missing_real_core_conclusion}" \
  'module-default must contain exactly one real CoreConclusion'

duplicate_real_core_conclusion="${test_tmp_root}/duplicate-real-core-conclusion"
make_fixture "${duplicate_real_core_conclusion}"
perl -0pi -e 's#(<div class="module-conclusion-lead".*?</div>)#$1$1#s' \
  "${duplicate_real_core_conclusion}/prototype/index.html"
expect_module_dom_failure "${duplicate_real_core_conclusion}" \
  'module-default must contain exactly one real CoreConclusion'

for closure_region in Conditions Results 'Boundaries / Exceptions'; do
  closure_slug="$(printf '%s' "${closure_region}" | tr '[:upper:] /' '[:lower:]--')"
  missing_real_closure_region="${test_tmp_root}/missing-real-${closure_slug}"
  make_fixture "${missing_real_closure_region}"
  CLOSURE_REGION="${closure_region}" perl -0pi -e \
    's#\s*<div>\s*<p class="eyebrow">\Q$ENV{CLOSURE_REGION}\E.*?</div>##s' \
    "${missing_real_closure_region}/prototype/index.html"
  expect_module_dom_failure "${missing_real_closure_region}" \
    "module-default must contain exactly one real ${closure_region} region"

  duplicate_real_closure_region="${test_tmp_root}/duplicate-real-${closure_slug}"
  make_fixture "${duplicate_real_closure_region}"
  CLOSURE_REGION="${closure_region}" perl -0pi -e \
    's#(<div>\s*<p class="eyebrow">\Q$ENV{CLOSURE_REGION}\E.*?</div>)#$1$1#s' \
    "${duplicate_real_closure_region}/prototype/index.html"
  expect_module_dom_failure "${duplicate_real_closure_region}" \
    "module-default must contain exactly one real ${closure_region} region"
done

four_real_relations="${test_tmp_root}/four-real-relations"
make_fixture "${four_real_relations}"
perl -0pi -e 's#(<li><strong>Read View</strong><span>约束</span><strong>记录版本可见性</strong></li>)#$1\n              <li><strong>活跃事务范围</strong><span>限制</span><strong>观察边界</strong></li>\n              <li><strong>Undo 版本链</strong><span>提供</span><strong>历史候选</strong></li>#' \
  "${four_real_relations}/prototype/index.html"
expect_module_dom_failure "${four_real_relations}" \
  'module-default real Relation count must be between 1 and 3'

mismatched_real_relation_count="${test_tmp_root}/mismatched-real-relation-count"
make_fixture "${mismatched_real_relation_count}"
perl -0pi -e 's#(<li><strong>Read View</strong><span>约束</span><strong>记录版本可见性</strong></li>)#$1\n              <li><strong>Undo 版本链</strong><span>提供</span><strong>历史候选</strong></li>#' \
  "${mismatched_real_relation_count}/prototype/index.html"
expect_module_dom_failure "${mismatched_real_relation_count}" \
  'module-default real Relation count 3 does not match declared count 2'

real_persistent_governance_sidebar="${test_tmp_root}/real-persistent-governance-sidebar"
make_fixture "${real_persistent_governance_sidebar}"
perl -0pi -e 's#(<main\s+id="module-default-document")#<aside class="persistent-governance-sidebar">Governance</aside>\n        $1#s' \
  "${real_persistent_governance_sidebar}/prototype/index.html"
expect_module_dom_failure "${real_persistent_governance_sidebar}" \
  'module-default real persistent governance side panel count 1 does not match declared count 0'

second_real_primary_projection="${test_tmp_root}/second-real-primary-projection"
make_fixture "${second_real_primary_projection}"
perl -0pi -e 's#(<figure\s+class="module-primary-projection".*?</figure>)#$1$1#s' \
  "${second_real_primary_projection}/prototype/index.html"
expect_module_dom_failure "${second_real_primary_projection}" \
  'module-default must contain exactly one'

serialized_dom_decoy_bypass="${test_tmp_root}/serialized-dom-decoy-bypass"
make_fixture "${serialized_dom_decoy_bypass}"
perl -0pi -e 's#<section class="module-closure".*?</section>#<!-- <section class="module-closure"><div>Conditions ·</div><div>Results ·</div><div>Boundaries / Exceptions ·</div></section> -->#s' \
  "${serialized_dom_decoy_bypass}/prototype/index.html"
perl -0pi -e 's#(<li><strong>Read View</strong><span>约束</span><strong>记录版本可见性</strong></li>)#$1\n              <!-- </section> -->\n              <li><strong>活跃事务范围</strong><span>限制</span><strong>观察边界</strong></li>\n              <li><strong>Undo 版本链</strong><span>提供</span><strong>历史候选</strong></li>#' \
  "${serialized_dom_decoy_bypass}/prototype/index.html"
perl -0pi -e 's#(</figure>)#$1\n            <figure class="module-primary-projection diagnostic-decoy"></figure>#' \
  "${serialized_dom_decoy_bypass}/prototype/index.html"
perl -0pi -e 's#(<main\s+id="module-default-document")#<aside class="diagnostic-decoy persistent-governance-sidebar">Governance</aside>\n        $1#s' \
  "${serialized_dom_decoy_bypass}/prototype/index.html"
expect_module_dom_failure "${serialized_dom_decoy_bypass}" \
  'module-default must contain exactly one real .module-closure'

legal_additional_class_tokens="${test_tmp_root}/legal-additional-class-tokens"
make_fixture "${legal_additional_class_tokens}"
perl -0pi -e 's/class="module-closure"/class="module-closure selector-probe"/; s/class="module-primary-projection"/class="module-primary-projection selector-probe"/; s/class="module-relations"/class="module-relations selector-probe"/' \
  "${legal_additional_class_tokens}/prototype/index.html"
expect_module_dom_success "${legal_additional_class_tokens}"

legal_comment_closing_tag="${test_tmp_root}/legal-comment-closing-tag"
make_fixture "${legal_comment_closing_tag}"
perl -0pi -e 's#(<section class="module-closure"[^>]*>)#$1\n            <!-- </section> must not truncate selector evaluation -->#' \
  "${legal_comment_closing_tag}/prototype/index.html"
expect_module_dom_success "${legal_comment_closing_tag}"

assert_module_dom_failures_closed

missing_relation_primary_focus="${test_tmp_root}/missing-relation-primary-focus"
make_fixture "${missing_relation_primary_focus}"
sed -i.bak 's/class="relation-focus-primary"/class="relation-focus-primary-missing"/' \
  "${missing_relation_primary_focus}/prototype/index.html"
rm "${missing_relation_primary_focus}/prototype/index.html.bak"
expect_hvd02_dom_failure "${missing_relation_primary_focus}" relation-focus \
  module-relation-focus-desktop.png \
  'relation-focus must contain exactly one real primary Relation focus'

missing_relation_origin_anchor="${test_tmp_root}/missing-relation-origin-anchor"
make_fixture "${missing_relation_origin_anchor}"
sed -i.bak 's/relation-origin-anchor focus-return-anchor/relation-origin-anchor-missing focus-return-anchor/' \
  "${missing_relation_origin_anchor}/prototype/index.html"
rm "${missing_relation_origin_anchor}/prototype/index.html.bak"
expect_hvd02_dom_failure "${missing_relation_origin_anchor}" relation-focus \
  module-relation-focus-desktop.png \
  'relation-focus must contain exactly one real origin anchor'

missing_relation_statement="${test_tmp_root}/missing-relation-statement"
make_fixture "${missing_relation_statement}"
sed -i.bak 's/class="relation-focus-statement"/class="relation-focus-statement-missing"/' \
  "${missing_relation_statement}/prototype/index.html"
rm "${missing_relation_statement}/prototype/index.html.bak"
expect_hvd02_dom_failure "${missing_relation_statement}" relation-focus \
  module-relation-focus-desktop.png \
  'relation-focus must contain exactly one complete Relation statement'

missing_relation_endpoint="${test_tmp_root}/missing-relation-endpoint"
make_fixture "${missing_relation_endpoint}"
perl -0pi -e 's/class="relation-endpoint"/class="relation-endpoint-missing"/' \
  "${missing_relation_endpoint}/prototype/index.html"
expect_hvd02_dom_failure "${missing_relation_endpoint}" relation-focus \
  module-relation-focus-desktop.png \
  'relation-focus must contain exactly two secondary endpoints'

missing_relation_support_scope="${test_tmp_root}/missing-relation-support-scope"
make_fixture "${missing_relation_support_scope}"
sed -i.bak 's/class="relation-support-scope"/class="relation-support-scope-missing"/' \
  "${missing_relation_support_scope}/prototype/index.html"
rm "${missing_relation_support_scope}/prototype/index.html.bak"
expect_hvd02_dom_failure "${missing_relation_support_scope}" relation-focus \
  module-relation-focus-desktop.png \
  'relation-focus must contain exactly one evidence support scope'

missing_quick_source_panel="${test_tmp_root}/missing-quick-source-panel"
make_fixture "${missing_quick_source_panel}"
sed -i.bak 's/class="quick-source-panel"/class="quick-source-panel-missing"/' \
  "${missing_quick_source_panel}/prototype/index.html"
rm "${missing_quick_source_panel}/prototype/index.html.bak"
expect_hvd02_dom_failure "${missing_quick_source_panel}" relation-focus \
  module-relation-focus-desktop.png \
  'relation-focus must contain exactly one transient Quick Source panel'

broken_quick_source_explicit_close="${test_tmp_root}/broken-quick-source-explicit-close"
make_fixture "${broken_quick_source_explicit_close}"
sed -i.bak 's/data-touch-equivalent="CLOSE_QUICK_SOURCE"/data-touch-equivalent="BROKEN_QUICK_SOURCE_CLOSE"/' \
  "${broken_quick_source_explicit_close}/prototype/index.html"
rm "${broken_quick_source_explicit_close}/prototype/index.html.bak"
expect_hvd02_dom_failure "${broken_quick_source_explicit_close}" relation-focus \
  module-relation-focus-desktop.png \
  'relation-focus browser selector probe data-probe-quick-source-close-count must be 1, got 0'

invisible_open_quick_source_panel="${test_tmp_root}/invisible-open-quick-source-panel"
make_fixture "${invisible_open_quick_source_panel}"
sed -i.bak 's/class="quick-source-panel"/class="quick-source-panel" style="display: none"/' \
  "${invisible_open_quick_source_panel}/prototype/index.html"
rm "${invisible_open_quick_source_panel}/prototype/index.html.bak"
expect_hvd02_dom_failure "${invisible_open_quick_source_panel}" relation-focus \
  module-relation-focus-desktop.png \
  'relation-focus browser selector probe data-probe-quick-source-rendered-after-enter must be true, got false'

hidden_relation_primary_focus="${test_tmp_root}/hidden-relation-primary-focus"
make_fixture "${hidden_relation_primary_focus}"
sed -i.bak 's/<section class="relation-focus-primary"/<section hidden class="relation-focus-primary"/' \
  "${hidden_relation_primary_focus}/prototype/index.html"
rm "${hidden_relation_primary_focus}/prototype/index.html.bak"
expect_hvd02_dom_failure "${hidden_relation_primary_focus}" relation-focus \
  module-relation-focus-desktop.png \
  'relation-focus rendered primary Relation focus count must be 1, got 0'

aria_hidden_relation_statement="${test_tmp_root}/aria-hidden-relation-statement"
make_fixture "${aria_hidden_relation_statement}"
sed -i.bak 's/class="relation-focus-statement"/aria-hidden="true" class="relation-focus-statement"/' \
  "${aria_hidden_relation_statement}/prototype/index.html"
rm "${aria_hidden_relation_statement}/prototype/index.html.bak"
expect_hvd02_dom_failure "${aria_hidden_relation_statement}" relation-focus \
  module-relation-focus-desktop.png \
  'relation-focus rendered complete Relation statement count must be 1, got 0'

display_none_relation_endpoint="${test_tmp_root}/display-none-relation-endpoint"
make_fixture "${display_none_relation_endpoint}"
perl -0pi -e 's/class="relation-endpoint"/class="relation-endpoint" style="display: none"/' \
  "${display_none_relation_endpoint}/prototype/index.html"
expect_hvd02_dom_failure "${display_none_relation_endpoint}" relation-focus \
  module-relation-focus-desktop.png \
  'relation-focus rendered secondary endpoint count must be 2, got 1'

disabled_quick_source_trigger="${test_tmp_root}/disabled-quick-source-trigger"
make_fixture "${disabled_quick_source_trigger}"
sed -i.bak 's/id="relation-quick-source-trigger"/disabled id="relation-quick-source-trigger"/' \
  "${disabled_quick_source_trigger}/prototype/index.html"
rm "${disabled_quick_source_trigger}/prototype/index.html.bak"
expect_hvd02_dom_failure "${disabled_quick_source_trigger}" relation-focus \
  module-relation-focus-desktop.png \
  'relation-focus must contain exactly one rendered and keyboard-interactable Quick Source trigger'

hidden_source_conflict="${test_tmp_root}/hidden-source-conflict"
make_fixture "${hidden_source_conflict}"
sed -i.bak 's/<article class="source-conflict"/<article hidden class="source-conflict"/' \
  "${hidden_source_conflict}/prototype/index.html"
rm "${hidden_source_conflict}/prototype/index.html.bak"
expect_hvd02_dom_failure "${hidden_source_conflict}" source-verification \
  module-source-verification-desktop.png \
  'source-verification rendered explicit conflict count must be 1, got 0'

hidden_source_return_target="${test_tmp_root}/hidden-source-return-target"
make_fixture "${hidden_source_return_target}"
sed -i.bak 's/id="source-origin-anchor"/hidden id="source-origin-anchor"/' \
  "${hidden_source_return_target}/prototype/index.html"
rm "${hidden_source_return_target}/prototype/index.html.bak"
expect_hvd02_dom_failure "${hidden_source_return_target}" source-verification \
  module-source-verification-desktop.png \
  'source-verification must contain exactly one rendered and keyboard-interactable Escape focus return target'

missing_source_conflict="${test_tmp_root}/missing-source-conflict"
make_fixture "${missing_source_conflict}"
sed -i.bak 's/class="source-conflict"/class="source-conflict-missing"/' \
  "${missing_source_conflict}/prototype/index.html"
rm "${missing_source_conflict}/prototype/index.html.bak"
expect_hvd02_dom_failure "${missing_source_conflict}" source-verification \
  module-source-verification-desktop.png \
  'source-verification must contain exactly one explicit conflict state'

missing_source_gap="${test_tmp_root}/missing-source-gap"
make_fixture "${missing_source_gap}"
sed -i.bak 's/class="source-gap"/class="source-gap-missing"/' \
  "${missing_source_gap}/prototype/index.html"
rm "${missing_source_gap}/prototype/index.html.bak"
expect_hvd02_dom_failure "${missing_source_gap}" source-verification \
  module-source-verification-desktop.png \
  'source-verification must contain exactly one explicit source gap'

missing_source_return_target="${test_tmp_root}/missing-source-return-target"
make_fixture "${missing_source_return_target}"
sed -i.bak 's/id="source-origin-anchor"/id="source-origin-anchor-missing"/' \
  "${missing_source_return_target}/prototype/index.html"
rm "${missing_source_return_target}/prototype/index.html.bak"
expect_hvd02_dom_failure "${missing_source_return_target}" source-verification \
  module-source-verification-desktop.png \
  'source-verification must contain exactly one Escape focus return target'

independent_source_fact="${test_tmp_root}/independent-source-fact"
make_fixture "${independent_source_fact}"
perl -0pi -e 's/(id="source-verification-document".*?data-independent-fact-count=)"0"/$1"1"/s' \
  "${independent_source_fact}/prototype/index.html"
expect_hvd02_dom_failure "${independent_source_fact}" source-verification \
  module-source-verification-desktop.png \
  'source-verification must declare zero independent facts'

missing_module_source_label="${test_tmp_root}/missing-module-source-label"
make_fixture "${missing_module_source_label}"
sed -i.bak \
  's/aria-label="按需查看 SourceEvidence 支持范围"/aria-label="来源"/' \
  "${missing_module_source_label}/prototype/index.html"
rm "${missing_module_source_label}/prototype/index.html.bak"
expect_failure "${missing_module_source_label}" \
  'module-default browser selector probe data-probe-source-evidence-label-count must be 1, got 0'

missing_module_element_label="${test_tmp_root}/missing-module-element-label"
make_fixture "${missing_module_element_label}"
sed -i.bak \
  's/aria-label="展开 KnowledgeElement：Read View"/aria-label="展开"/' \
  "${missing_module_element_label}/prototype/index.html"
rm "${missing_module_element_label}/prototype/index.html.bak"
expect_failure "${missing_module_element_label}" \
  'module-default browser selector probe data-probe-knowledge-element-label-count must be 1, got 0'

stale_module_evidence="${test_tmp_root}/stale-module-evidence"
make_fixture "${stale_module_evidence}"
sed -i.bak \
  's/一次一致性读，如何从多个记录版本中选出当前事务真正可见的那个？/模块标题改变但截图仍旧。/' \
  "${stale_module_evidence}/prototype/index.html"
rm "${stale_module_evidence}/prototype/index.html.bak"
expect_failure "${stale_module_evidence}" \
  'module-default visual evidence is stale for the current prototype'

wrong_module_png="${test_tmp_root}/wrong-module-png"
make_fixture "${wrong_module_png}"
printf 'not a png\n' >"${wrong_module_png}/evidence/module-default-reading-desktop.png"
expect_failure "${wrong_module_png}" \
  'module-default visual evidence must be a 1440x1100 PNG'

regressed_completed_owner="${test_tmp_root}/regressed-completed-owner"
make_fixture "${regressed_completed_owner}"
sed -i.bak \
  '/^HVVisualAcceptanceObservation = RF-AC-02|/ s/Status=PASS_HIGH_FIDELITY_VISUAL_ONLY/Status=NOT_RUN/' \
  "${regressed_completed_owner}/acceptance.md"
rm "${regressed_completed_owner}/acceptance.md.bak"
expect_failure "${regressed_completed_owner}" \
  'RF-AC-02 must record PASS_HIGH_FIDELITY_VISUAL_ONLY'

premature_future_owner="${test_tmp_root}/premature-future-owner"
make_fixture "${premature_future_owner}"
sed -i.bak \
  '/^RFAcceptance = RF-AC-13|/ s/Status=NOT_RUN/Status=PASS/' \
  "${premature_future_owner}/acceptance.md"
rm "${premature_future_owner}/acceptance.md.bak"
expect_failure "${premature_future_owner}" \
  'RF-AC-13 canonical input contract must remain PLANNED/NOT_RUN'

printf 'HighFidelityVisualTaskCardContractTests = PASS\n'
printf 'ExistingNegativeFixtureCount = 44\n'
printf 'HV-D01FixRound1DOMNegativeFixtureCount = 15\n'
printf 'HV-D01FixRound2AdversarialNegativeFixtureCount = 1\n'
printf 'HV-D01SelectorSemanticsPositiveFixtureCount = 2\n'
printf 'HV-D02DOMNegativeFixtureCount = 18\n'
printf 'NegativeFixtureCount = 86\n'
