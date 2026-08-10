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
  local viewport="1440,1100"
  local expected_dimensions="1440 x 1100"
  local chrome_pid attempt artifact_ready

  case "${state_id}" in
    module-small-screen)
      viewport="390,844"
      expected_dimensions="390 x 844"
      ;;
    static-export)
      viewport="1200,1600"
      expected_dimensions="1200 x 1600"
      ;;
  esac

  "${chrome_bin}" \
    --headless=new --disable-gpu --hide-scrollbars \
    --user-data-dir="${chrome_profile}" --no-first-run --no-default-browser-check \
    --use-mock-keychain \
    --window-size="${viewport}" \
    --screenshot="${staged_png}" \
    "file://${fixture_root}/prototype/index.html?state=${state_id}" >/dev/null 2>&1 &
  chrome_pid=$!
  artifact_ready=NO
  attempt=0
  while [[ "${attempt}" -lt 300 ]]; do
    if file "${staged_png}" 2>/dev/null | grep -Fq "PNG image data, ${expected_dimensions}"; then
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
  file "${fixture_root}/evidence/${artifact_name}" |
    grep -Fq "PNG image data, ${expected_dimensions}" ||
    fail "recaptured ${state_id} mutation evidence must be ${expected_dimensions}: ${fixture_root}"
}

expect_hvd02_dom_failure() {
  local fixture_root="$1"
  local state_id="$2"
  local artifact_name="$3"
  local expected_message="$4"

  case "${state_id}" in
    domain-default|theme-default|module-small-screen|static-export)
      recapture_hvd02_evidence "${fixture_root}" domain-default \
        knowledge-landscape-theme-desktop.png
      recapture_hvd02_evidence "${fixture_root}" theme-default \
        cross-domain-reading-desktop.png
      recapture_hvd02_evidence "${fixture_root}" module-small-screen \
        module-default-reading-small-screen.png
      recapture_hvd02_evidence "${fixture_root}" static-export \
        static-export-example.png
      ;;
    *)
      recapture_hvd02_evidence "${fixture_root}" "${state_id}" "${artifact_name}"
      ;;
  esac
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
  "ActiveTaskCard = HV-D05" \
  "DoneTaskCardCount = 5" \
  "ReadyTaskCardCount = 1" \
  "BlockedTaskCardCount = 0" \
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
  "RevisionImpactBrowserSelectorValidation = PASS" \
  "RevisionImpactInteractionTransitionValidation = PASS" \
  "RevisionImpactEvidence = 1440x1100" \
  "RevisionImpactEvidenceFreshness = PASS" \
  "RecoveryBrowserSelectorValidation = PASS" \
  "RecoveryInteractionTransitionValidation = PASS" \
  "RecoveryEvidence = 1440x1100" \
  "RecoveryEvidenceFreshness = PASS" \
  "ConflictedDraftBrowserSelectorValidation = PASS" \
  "ConflictedDraftInteractionTransitionValidation = PASS" \
  "ConflictedDraftEvidence = 1440x1100" \
  "ConflictedDraftEvidenceFreshness = PASS" \
  "LandscapeThemeBrowserSelectorValidation = PASS" \
  "LandscapeThemeEvidence = 1440x1100" \
  "LandscapeThemeEvidenceFreshness = PASS" \
  "CrossDomainBrowserSelectorValidation = PASS" \
  "CrossDomainEvidence = 1440x1100" \
  "CrossDomainEvidenceFreshness = PASS" \
  "SmallScreenBrowserSelectorValidation = PASS" \
  "SmallScreenInteractionTransitionValidation = PASS" \
  "SmallScreenResponsiveSafetyValidation = PASS" \
  "SmallScreenEvidence = 390x844" \
  "SmallScreenEvidenceFreshness = PASS" \
  "StaticExportBrowserSelectorValidation = PASS" \
  "StaticExportManifestValidation = PASS" \
  "StaticExportEvidence = 1200x1600" \
  "StaticExportEvidenceFreshness = PASS" \
  "HighFidelityVisualDesign = NOT_RUN" \
  "HighFidelityUsabilityValidation = NOT_RUN" \
  "BusinessImplementation = NOT_AUTHORIZED" \
  "FormalDatabaseWrite = NOT_AUTHORIZED" \
  "RemotePush = NOT_AUTHORIZED"; do
  [[ "${canonical_output}" == *"${expected_line}"* ]] ||
    fail "canonical output is missing: ${expected_line}"
done

cross_domain_fifth_object="${test_tmp_root}/cross-domain-fifth-object"
make_fixture "${cross_domain_fifth_object}"
sed -i.bak \
  's/<span class="canonical-level landscape-level">数据系统<\/span>/<span class="canonical-level independent-domain-object">第五领域对象<\/span>/' \
  "${cross_domain_fifth_object}/prototype/index.html"
rm "${cross_domain_fifth_object}/prototype/index.html.bak"
expect_hvd02_dom_failure "${cross_domain_fifth_object}" theme-default \
  cross-domain-reading-desktop.png \
  'theme-default browser selector probe data-probe-independent-domain-raw-count must be 0, got 1'

cross_domain_classless_fifth="${test_tmp_root}/cross-domain-classless-fifth"
make_fixture "${cross_domain_classless_fifth}"
sed -i.bak '/MVCC 一致性读/ s#<span class="canonical-level element-level">Read View</span>#<span class="canonical-level element-level">Read View</span><div class="domain-object-decoy">第五领域对象</div>#' \
  "${cross_domain_classless_fifth}/prototype/index.html"
rm "${cross_domain_classless_fifth}/prototype/index.html.bak"
expect_hvd02_dom_failure "${cross_domain_classless_fifth}" theme-default \
  cross-domain-reading-desktop.png \
  'theme-default browser selector probe data-probe-mechanism-direct-child-count must be 7, got 8'

cross_domain_canonical_class_swap="${test_tmp_root}/cross-domain-canonical-class-swap"
make_fixture "${cross_domain_canonical_class_swap}"
sed -i.bak '/MVCC 一致性读/ s#<span class="canonical-level landscape-level">数据系统</span><i>→</i>#<span class="landscape-level">数据系统</span><i class="canonical-level">→</i>#' \
  "${cross_domain_canonical_class_swap}/prototype/index.html"
rm "${cross_domain_canonical_class_swap}/prototype/index.html.bak"
expect_hvd02_dom_failure "${cross_domain_canonical_class_swap}" theme-default \
  cross-domain-reading-desktop.png \
  'theme-default browser selector probe data-probe-mechanism-direct-child-topology must be SPAN.canonical-level.landscape-level,I.separator,SPAN.canonical-level.theme-level,I.separator,SPAN.canonical-level.module-level,I.separator,SPAN.canonical-level.element-level'

cross_domain_separator_overflow="${test_tmp_root}/cross-domain-separator-overflow"
make_fixture "${cross_domain_separator_overflow}"
sed -i.bak '/MVCC 一致性读/ s#<i>→</i>#<i style="width: auto; height: auto; justify-self: stretch; transform: rotate(90deg);">→</i>#g' \
  "${cross_domain_separator_overflow}/prototype/index.html"
rm "${cross_domain_separator_overflow}/prototype/index.html.bak"
expect_hvd02_dom_failure "${cross_domain_separator_overflow}" theme-default \
  cross-domain-reading-desktop.png \
  'theme-default browser selector probe data-probe-mechanism-safe-separator-count must be 3, got 0'

cross_domain_separator_descendant_overflow="${test_tmp_root}/cross-domain-separator-descendant-overflow"
make_fixture "${cross_domain_separator_descendant_overflow}"
sed -i.bak '/MVCC 一致性读/ s#<i>→</i>#<i>→<span style="position: fixed; top: 20px; left: 360px; z-index: 30;">↓</span></i>#' \
  "${cross_domain_separator_descendant_overflow}/prototype/index.html"
rm "${cross_domain_separator_descendant_overflow}/prototype/index.html.bak"
expect_hvd02_dom_failure "${cross_domain_separator_descendant_overflow}" theme-default \
  cross-domain-reading-desktop.png \
  'theme-default browser selector probe data-probe-mechanism-safe-separator-count must be 3, got 2'

static_orphan_title="${test_tmp_root}/static-orphan-title"
make_fixture "${static_orphan_title}"
sed -i.bak 's/max-width: 800px;/max-width: 720px;/' \
  "${static_orphan_title}/prototype/styles.css"
rm "${static_orphan_title}/prototype/styles.css.bak"
expect_hvd02_dom_failure "${static_orphan_title}" static-export \
  static-export-example.png \
  'static-export browser selector probe data-probe-title-line-count must be 1, got 2'

static_clipped_title="${test_tmp_root}/static-clipped-title"
make_fixture "${static_clipped_title}"
sed -i.bak \
  's#<h1>一致性读：从观察边界到可见版本</h1>#<h1 style="width: 240px; max-width: 240px; white-space: nowrap; overflow: hidden;">一致性读：从观察边界到可见版本</h1>#' \
  "${static_clipped_title}/prototype/index.html"
rm "${static_clipped_title}/prototype/index.html.bak"
expect_hvd02_dom_failure "${static_clipped_title}" static-export \
  static-export-example.png \
  'static-export browser selector probe data-probe-title-visible-complete must be true, got false'

static_offscreen_title="${test_tmp_root}/static-offscreen-title"
make_fixture "${static_offscreen_title}"
sed -i.bak \
  's#<h1>一致性读：从观察边界到可见版本</h1>#<h1 style="transform: translateX(-2000px);">一致性读：从观察边界到可见版本</h1>#' \
  "${static_offscreen_title}/prototype/index.html"
rm "${static_offscreen_title}/prototype/index.html.bak"
expect_hvd02_dom_failure "${static_offscreen_title}" static-export \
  static-export-example.png \
  'static-export browser selector probe data-probe-title-visible-complete must be true, got false'

static_scaled_title="${test_tmp_root}/static-scaled-title"
make_fixture "${static_scaled_title}"
sed -i.bak \
  's#<h1>一致性读：从观察边界到可见版本</h1>#<h1 style="transform: scale(0.01); transform-origin: left top;">一致性读：从观察边界到可见版本</h1>#' \
  "${static_scaled_title}/prototype/index.html"
rm "${static_scaled_title}/prototype/index.html.bak"
expect_hvd02_dom_failure "${static_scaled_title}" static-export \
  static-export-example.png \
  'static-export browser selector probe data-probe-title-visible-complete must be true, got false'

static_translucent_title="${test_tmp_root}/static-translucent-title"
make_fixture "${static_translucent_title}"
sed -i.bak \
  's#<h1>一致性读：从观察边界到可见版本</h1>#<h1 style="-webkit-text-fill-color: rgba(23, 32, 29, 0.01);">一致性读：从观察边界到可见版本</h1>#' \
  "${static_translucent_title}/prototype/index.html"
rm "${static_translucent_title}/prototype/index.html.bak"
expect_hvd02_dom_failure "${static_translucent_title}" static-export \
  static-export-example.png \
  'static-export browser selector probe data-probe-title-visible-complete must be true, got false'

static_blended_title="${test_tmp_root}/static-blended-title"
make_fixture "${static_blended_title}"
sed -i.bak \
  's#<h1>一致性读：从观察边界到可见版本</h1>#<h1 style="mix-blend-mode: screen;">一致性读：从观察边界到可见版本</h1>#' \
  "${static_blended_title}/prototype/index.html"
rm "${static_blended_title}/prototype/index.html.bak"
expect_hvd02_dom_failure "${static_blended_title}" static-export \
  static-export-example.png \
  'static-export browser selector probe data-probe-title-visible-complete must be true, got false'

static_occluded_title="${test_tmp_root}/static-occluded-title"
make_fixture "${static_occluded_title}"
sed -i.bak \
  's#<h1>一致性读：从观察边界到可见版本</h1>#<h1>一致性读：从观察边界到可见版本</h1><span aria-hidden="true" style="position: fixed; left: 100px; top: 145px; width: 800px; height: 90px; z-index: 99; background: rgb(255, 253, 248);"></span>#' \
  "${static_occluded_title}/prototype/index.html"
rm "${static_occluded_title}/prototype/index.html.bak"
expect_hvd02_dom_failure "${static_occluded_title}" static-export \
  static-export-example.png \
  'static-export browser selector probe data-probe-title-visible-complete must be true, got false'

static_shadow_occluded_title="${test_tmp_root}/static-shadow-occluded-title"
make_fixture "${static_shadow_occluded_title}"
sed -i.bak \
  's#<h1>一致性读：从观察边界到可见版本</h1>#<h1>一致性读：从观察边界到可见版本</h1><span aria-hidden="true" style="position: fixed; left: -1000px; top: -1000px; width: 800px; height: 90px; z-index: 99; pointer-events: none; box-shadow: 1100px 1145px 0 0 rgb(255, 253, 248);"></span>#' \
  "${static_shadow_occluded_title}/prototype/index.html"
rm "${static_shadow_occluded_title}/prototype/index.html.bak"
expect_hvd02_dom_failure "${static_shadow_occluded_title}" static-export \
  static-export-example.png \
  'static-export browser selector probe data-probe-title-visible-complete must be true, got false'

static_marker_occluded_title="${test_tmp_root}/static-marker-occluded-title"
make_fixture "${static_marker_occluded_title}"
sed -i.bak \
  's#<h1>一致性读：从观察边界到可见版本</h1>#<h1>一致性读：从观察边界到可见版本</h1><style>.paint-marker::marker { content: "██████████████"; color: rgb(255, 253, 248); font-size: 70px; }</style><ul aria-hidden="true" style="position: fixed; left: 950px; top: 130px; width: 1px; height: 1px; z-index: 99; pointer-events: none; margin: 0; padding: 0;"><li class="paint-marker" style="width: 1px; height: 1px;"></li></ul>#' \
  "${static_marker_occluded_title}/prototype/index.html"
rm "${static_marker_occluded_title}/prototype/index.html.bak"
expect_hvd02_dom_failure "${static_marker_occluded_title}" static-export \
  static-export-example.png \
  'static-export browser selector probe data-probe-title-visible-complete must be true, got false'

small_noninteractive_close="${test_tmp_root}/small-noninteractive-close"
make_fixture "${small_noninteractive_close}"
sed -i.bak \
  's#<button id="small-overlay-close" type="button" data-focus-return-target="small-element-trigger">关闭并返回正文</button>#<div id="small-overlay-close" data-focus-return-target="small-element-trigger">关闭并返回正文</div>#' \
  "${small_noninteractive_close}/prototype/index.html"
rm "${small_noninteractive_close}/prototype/index.html.bak"
expect_hvd02_dom_failure "${small_noninteractive_close}" module-small-screen \
  module-default-reading-small-screen.png \
  'module-small-screen browser selector probe data-probe-close-control-count must be 1, got 0'

small_pointer_blocked_close="${test_tmp_root}/small-pointer-blocked-close"
make_fixture "${small_pointer_blocked_close}"
sed -i.bak \
  's#<button id="small-overlay-close" type="button" data-focus-return-target="small-element-trigger">关闭并返回正文</button>#<button id="small-overlay-close" type="button" data-focus-return-target="small-element-trigger" style="pointer-events: none;">关闭并返回正文</button>#' \
  "${small_pointer_blocked_close}/prototype/index.html"
rm "${small_pointer_blocked_close}/prototype/index.html.bak"
expect_hvd02_dom_failure "${small_pointer_blocked_close}" module-small-screen \
  module-default-reading-small-screen.png \
  'module-small-screen browser selector probe data-probe-close-control-count must be 1, got 0'

small_ancestor_pointer_blocked_close="${test_tmp_root}/small-ancestor-pointer-blocked-close"
make_fixture "${small_ancestor_pointer_blocked_close}"
sed -i.bak \
  's#<section id="small-element-overlay" class="small-element-overlay"#<section id="small-element-overlay" class="small-element-overlay" style="pointer-events: none;"#' \
  "${small_ancestor_pointer_blocked_close}/prototype/index.html"
rm "${small_ancestor_pointer_blocked_close}/prototype/index.html.bak"
expect_hvd02_dom_failure "${small_ancestor_pointer_blocked_close}" module-small-screen \
  module-default-reading-small-screen.png \
  'module-small-screen browser selector probe data-probe-close-control-count must be 1, got 0'

small_occluded_close="${test_tmp_root}/small-occluded-close"
make_fixture "${small_occluded_close}"
sed -i.bak \
  's#<button id="small-overlay-close"#<span aria-hidden="true" style="position: absolute; z-index: 2; top: 1.2rem; right: 1.2rem; left: 1.2rem; height: 44px;"></span><button id="small-overlay-close"#' \
  "${small_occluded_close}/prototype/index.html"
rm "${small_occluded_close}/prototype/index.html.bak"
expect_hvd02_dom_failure "${small_occluded_close}" module-small-screen \
  module-default-reading-small-screen.png \
  'module-small-screen browser selector probe data-probe-close-control-count must be 1, got 0'

small_unsampled_occlusion="${test_tmp_root}/small-unsampled-occlusion"
make_fixture "${small_unsampled_occlusion}"
sed -i.bak \
  's#<button id="small-overlay-close"#<span aria-hidden="true" style="position: fixed; z-index: 30; top: 20px; left: 60px; width: 100px; height: 44px;"></span><button id="small-overlay-close"#' \
  "${small_unsampled_occlusion}/prototype/index.html"
rm "${small_unsampled_occlusion}/prototype/index.html.bak"
expect_hvd02_dom_failure "${small_unsampled_occlusion}" module-small-screen \
  module-default-reading-small-screen.png \
  'module-small-screen browser selector probe data-probe-close-control-count must be 1, got 0'

small_clipped_close="${test_tmp_root}/small-clipped-close"
make_fixture "${small_clipped_close}"
sed -i.bak \
  's#<button id="small-overlay-close" type="button" data-focus-return-target="small-element-trigger">关闭并返回正文</button>#<button id="small-overlay-close" type="button" data-focus-return-target="small-element-trigger" style="position: fixed; left: -150px; top: 20px; width: 320px; z-index: 20;">关闭并返回正文</button>#' \
  "${small_clipped_close}/prototype/index.html"
rm "${small_clipped_close}/prototype/index.html.bak"
expect_hvd02_dom_failure "${small_clipped_close}" module-small-screen \
  module-default-reading-small-screen.png \
  'module-small-screen browser selector probe data-probe-close-control-count must be 1, got 0'

small_clipped_trigger="${test_tmp_root}/small-clipped-trigger"
make_fixture "${small_clipped_trigger}"
sed -i.bak \
  's#<button id="small-element-trigger" class="small-element-trigger" type="button"#<button id="small-element-trigger" class="small-element-trigger" type="button" style="position: fixed; left: -150px; bottom: 20px; width: 320px; z-index: 20;"#' \
  "${small_clipped_trigger}/prototype/index.html"
rm "${small_clipped_trigger}/prototype/index.html.bak"
expect_hvd02_dom_failure "${small_clipped_trigger}" module-small-screen \
  module-default-reading-small-screen.png \
  'module-small-screen browser selector probe data-probe-trigger-count must be 1, got 0'

small_tiny_close="${test_tmp_root}/small-tiny-close"
make_fixture "${small_tiny_close}"
sed -i.bak \
  's#<button id="small-overlay-close" type="button" data-focus-return-target="small-element-trigger">关闭并返回正文</button>#<button id="small-overlay-close" type="button" data-focus-return-target="small-element-trigger" style="width: 1px; height: 1px; min-height: 0; padding: 0; border: 0; font-size: 0;">关闭并返回正文</button>#' \
  "${small_tiny_close}/prototype/index.html"
rm "${small_tiny_close}/prototype/index.html.bak"
expect_hvd02_dom_failure "${small_tiny_close}" module-small-screen \
  module-default-reading-small-screen.png \
  'module-small-screen browser selector probe data-probe-close-control-count must be 1, got 0'

manifest_wrong_endpoints="${test_tmp_root}/manifest-wrong-endpoints"
make_fixture "${manifest_wrong_endpoints}"
sed -i.bak \
  -e 's/"sourceId": "element-read-view"/"sourceId": "landscape-data-systems"/' \
  -e 's/"targetId": "element-version-chain"/"targetId": "theme-concurrency-consistency"/' \
  "${manifest_wrong_endpoints}/evidence/static-export-manifest.json"
rm "${manifest_wrong_endpoints}/evidence/static-export-manifest.json.bak"
expect_failure "${manifest_wrong_endpoints}" \
  'static export manifest Relation endpoints do not match canonical export'

static_hidden_duplicate_relation="${test_tmp_root}/static-hidden-duplicate-relation"
make_fixture "${static_hidden_duplicate_relation}"
sed -i.bak \
  's#<blockquote class="export-relation"#<span hidden data-relation-id="rel-read-view-selects-version"></span><blockquote class="export-relation"#' \
  "${static_hidden_duplicate_relation}/prototype/index.html"
rm "${static_hidden_duplicate_relation}/prototype/index.html.bak"
expect_hvd02_dom_failure "${static_hidden_duplicate_relation}" static-export \
  static-export-example.png \
  'static-export browser selector probe data-probe-raw-relation-identity-count must be 1, got 2'

static_hidden_duplicate_source="${test_tmp_root}/static-hidden-duplicate-source"
make_fixture "${static_hidden_duplicate_source}"
sed -i.bak \
  's#<footer class="export-source"#<span hidden data-source-id="src-mvcc-mechanism"></span><footer class="export-source"#' \
  "${static_hidden_duplicate_source}/prototype/index.html"
rm "${static_hidden_duplicate_source}/prototype/index.html.bak"
expect_hvd02_dom_failure "${static_hidden_duplicate_source}" static-export \
  static-export-example.png \
  'static-export browser selector probe data-probe-raw-source-identity-count must be 1, got 2'

manifest_wrong_supports="${test_tmp_root}/manifest-wrong-supports"
make_fixture "${manifest_wrong_supports}"
sed -i.bak '/"supports": \[/,/]/ {
  s/"module-mvcc-consistent-read"/"landscape-data-systems"/
  s/"rel-read-view-selects-version"/"theme-concurrency-consistency"/
}' "${manifest_wrong_supports}/evidence/static-export-manifest.json"
rm "${manifest_wrong_supports}/evidence/static-export-manifest.json.bak"
expect_failure "${manifest_wrong_supports}" \
  'static export manifest source supports do not match canonical export'

missing_card="${test_tmp_root}/missing-card"
make_fixture "${missing_card}"
rm "${missing_card}/cards/HV-D05-fixed-visual-usability-review.md"
expect_failure "${missing_card}" "actual visual task card count 5 does not match 6"

second_ready="${test_tmp_root}/second-ready"
make_fixture "${second_ready}"
sed -i.bak 's/^Status = DONE$/Status = READY/' \
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

transparent_relation_ancestor="${test_tmp_root}/transparent-relation-ancestor"
make_fixture "${transparent_relation_ancestor}"
sed -i.bak 's/class="focus-shell relation-focus-shell"/class="focus-shell relation-focus-shell" style="opacity: 0"/' \
  "${transparent_relation_ancestor}/prototype/index.html"
rm "${transparent_relation_ancestor}/prototype/index.html.bak"
expect_hvd02_dom_failure "${transparent_relation_ancestor}" relation-focus \
  module-relation-focus-desktop.png \
  'relation-focus rendered document count must be 1, got 0'

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

missing_revision_before="${test_tmp_root}/missing-revision-before"
make_fixture "${missing_revision_before}"
sed -i.bak 's/class="revision-before"/class="revision-before-missing"/' \
  "${missing_revision_before}/prototype/index.html"
rm "${missing_revision_before}/prototype/index.html.bak"
expect_hvd02_dom_failure "${missing_revision_before}" revision-impact \
  module-revision-impact-desktop.png \
  'revision-impact browser selector probe data-probe-before-count must be 1, got 0'

hidden_revision_blocker="${test_tmp_root}/hidden-revision-blocker"
make_fixture "${hidden_revision_blocker}"
sed -i.bak 's/<article class="impact-lane impact-semantic blocker"/<article hidden class="impact-lane impact-semantic blocker"/' \
  "${hidden_revision_blocker}/prototype/index.html"
rm "${hidden_revision_blocker}/prototype/index.html.bak"
expect_hvd02_dom_failure "${hidden_revision_blocker}" revision-impact \
  module-revision-impact-desktop.png \
  'revision-impact browser selector probe data-probe-rendered-impact-lane-count must be 3, got 2'

decoy_revision_categories="${test_tmp_root}/decoy-revision-categories"
make_fixture "${decoy_revision_categories}"
sed -i.bak \
  -e 's/<div class="impact-lanes">/<div class="impact-lanes"><article class="impact-lane"><h3>Decoy lane<\/h3><\/article>/' \
  -e 's/<article class="impact-lane impact-semantic blocker"/<article hidden class="impact-semantic"/' \
  -e 's/class="impact-lane impact-structural" data-severity="REVIEW_REQUIRED"/class="impact-lane impact-structural blocker" data-severity="BLOCKER"/' \
  "${decoy_revision_categories}/prototype/index.html"
rm "${decoy_revision_categories}/prototype/index.html.bak"
expect_hvd02_dom_failure "${decoy_revision_categories}" revision-impact \
  module-revision-impact-desktop.png \
  'revision-impact browser selector probe data-probe-rendered-semantic-count must be 1, got 0'

enabled_revision_commit="${test_tmp_root}/enabled-revision-commit"
make_fixture "${enabled_revision_commit}"
sed -i.bak 's/type="button" disabled aria-disabled="true">提交 ChangeSet/type="button">提交 ChangeSet/' \
  "${enabled_revision_commit}/prototype/index.html"
rm "${enabled_revision_commit}/prototype/index.html.bak"
expect_hvd02_dom_failure "${enabled_revision_commit}" revision-impact \
  module-revision-impact-desktop.png \
  'revision-impact browser selector probe data-probe-disabled-commit-count must be 1, got 0'

hidden_saved_boundary="${test_tmp_root}/hidden-saved-boundary"
make_fixture "${hidden_saved_boundary}"
sed -i.bak 's/<section class="saved-boundary"/<section hidden class="saved-boundary"/' \
  "${hidden_saved_boundary}/prototype/index.html"
rm "${hidden_saved_boundary}/prototype/index.html.bak"
expect_hvd02_dom_failure "${hidden_saved_boundary}" partial-failure \
  module-recovery-desktop.png \
  'partial-failure browser selector probe data-probe-rendered-saved-boundary-count must be 1, got 0'

missing_processing_state="${test_tmp_root}/missing-processing-state"
make_fixture "${missing_processing_state}"
sed -i.bak 's/class="processing-state failed"/class="processing-state-failed"/' \
  "${missing_processing_state}/prototype/index.html"
rm "${missing_processing_state}/prototype/index.html.bak"
expect_hvd02_dom_failure "${missing_processing_state}" partial-failure \
  module-recovery-desktop.png \
  'partial-failure browser selector probe data-probe-processing-state-count must be 4, got 3'

hidden_stale_projection="${test_tmp_root}/hidden-stale-projection"
make_fixture "${hidden_stale_projection}"
sed -i.bak 's/<span class="stale-badge"/<span hidden class="stale-badge"/' \
  "${hidden_stale_projection}/prototype/index.html"
rm "${hidden_stale_projection}/prototype/index.html.bak"
expect_hvd02_dom_failure "${hidden_stale_projection}" partial-failure \
  module-recovery-desktop.png \
  'partial-failure browser selector probe data-probe-rendered-stale-projection-count must be 1, got 0'

disabled_result_query="${test_tmp_root}/disabled-result-query"
make_fixture "${disabled_result_query}"
sed -i.bak 's/class="query-original-result"/disabled class="query-original-result"/' \
  "${disabled_result_query}/prototype/index.html"
rm "${disabled_result_query}/prototype/index.html.bak"
expect_hvd02_dom_failure "${disabled_result_query}" partial-failure \
  module-recovery-desktop.png \
  'partial-failure browser selector probe data-probe-query-count must be 1, got 0'

inert_result_query="${test_tmp_root}/inert-result-query"
make_fixture "${inert_result_query}"
sed -i.bak 's/class="query-original-result"/inert class="query-original-result"/' \
  "${inert_result_query}/prototype/index.html"
rm "${inert_result_query}/prototype/index.html.bak"
expect_hvd02_dom_failure "${inert_result_query}" partial-failure \
  module-recovery-desktop.png \
  'partial-failure browser selector probe data-probe-query-count must be 1, got 0'

hidden_latest_conflict="${test_tmp_root}/hidden-latest-conflict"
make_fixture "${hidden_latest_conflict}"
sed -i.bak 's/<article class="diff-latest"/<article hidden class="diff-latest"/' \
  "${hidden_latest_conflict}/prototype/index.html"
rm "${hidden_latest_conflict}/prototype/index.html.bak"
expect_hvd02_dom_failure "${hidden_latest_conflict}" conflicted-draft \
  module-conflicted-draft-desktop.png \
  'conflicted-draft browser selector probe data-probe-rendered-three-way-count must be 3, got 2'

disabled_conflict_rebase="${test_tmp_root}/disabled-conflict-rebase"
make_fixture "${disabled_conflict_rebase}"
sed -i.bak 's/class="rebase-draft"/disabled class="rebase-draft"/' \
  "${disabled_conflict_rebase}/prototype/index.html"
rm "${disabled_conflict_rebase}/prototype/index.html.bak"
expect_hvd02_dom_failure "${disabled_conflict_rebase}" conflicted-draft \
  module-conflicted-draft-desktop.png \
  'conflicted-draft browser selector probe data-probe-rebase-count must be 1, got 0'

hidden_conflict_detail="${test_tmp_root}/hidden-conflict-detail"
make_fixture "${hidden_conflict_detail}"
sed -i.bak 's/<section id="conflict-detail-panel"/<section hidden id="conflict-detail-panel"/' \
  "${hidden_conflict_detail}/prototype/index.html"
rm "${hidden_conflict_detail}/prototype/index.html.bak"
expect_hvd02_dom_failure "${hidden_conflict_detail}" conflicted-draft \
  module-conflicted-draft-desktop.png \
  'conflicted-draft browser selector probe data-probe-rendered-conflict-panel-count must be 1, got 0'

hidden_landscape_level="${test_tmp_root}/hidden-landscape-level"
make_fixture "${hidden_landscape_level}"
sed -i.bak 's/<span class="canonical-level landscape-level" data-layer="KnowledgeLandscape"/<span hidden class="canonical-level landscape-level" data-layer="KnowledgeLandscape"/' \
  "${hidden_landscape_level}/prototype/index.html"
rm "${hidden_landscape_level}/prototype/index.html.bak"
expect_hvd02_dom_failure "${hidden_landscape_level}" domain-default \
  knowledge-landscape-theme-desktop.png \
  'domain-default browser selector probe data-probe-hierarchy-count must be 4, got 3'

duplicate_theme_level="${test_tmp_root}/duplicate-theme-level"
make_fixture "${duplicate_theme_level}"
sed -i.bak 's#<span class="canonical-level theme-level" data-layer="KnowledgeTheme"><small>02#<span class="canonical-level theme-level"><small>02B · KnowledgeTheme</small><strong>重复主题</strong></span><span class="canonical-level theme-level" data-layer="KnowledgeTheme"><small>02#' \
  "${duplicate_theme_level}/prototype/index.html"
rm "${duplicate_theme_level}/prototype/index.html.bak"
expect_hvd02_dom_failure "${duplicate_theme_level}" domain-default \
  knowledge-landscape-theme-desktop.png \
  'domain-default browser selector probe data-probe-hierarchy-count must be 4, got 5'

missing_landscape_thesis="${test_tmp_root}/missing-landscape-thesis"
make_fixture "${missing_landscape_thesis}"
sed -i.bak 's/class="landscape-thesis"/class="landscape-thesis-missing"/' \
  "${missing_landscape_thesis}/prototype/index.html"
rm "${missing_landscape_thesis}/prototype/index.html.bak"
expect_hvd02_dom_failure "${missing_landscape_thesis}" domain-default \
  knowledge-landscape-theme-desktop.png \
  'domain-default browser selector probe data-probe-landscape-thesis-count must be 1, got 0'

landscape_card_wall="${test_tmp_root}/landscape-card-wall"
make_fixture "${landscape_card_wall}"
sed -i.bak 's/<main class="cross-layer-grid">/<div class="card-wall">Forbidden card wall<\/div><main class="cross-layer-grid">/' \
  "${landscape_card_wall}/prototype/index.html"
rm "${landscape_card_wall}/prototype/index.html.bak"
expect_hvd02_dom_failure "${landscape_card_wall}" domain-default \
  knowledge-landscape-theme-desktop.png \
  'domain-default browser selector probe data-probe-forbidden-surface-count must be 0, got 1'

missing_theme_core_question="${test_tmp_root}/missing-theme-core-question"
make_fixture "${missing_theme_core_question}"
sed -i.bak 's/class="theme-core-question"/class="theme-core-question-missing"/' \
  "${missing_theme_core_question}/prototype/index.html"
rm "${missing_theme_core_question}/prototype/index.html.bak"
expect_hvd02_dom_failure "${missing_theme_core_question}" domain-default \
  knowledge-landscape-theme-desktop.png \
  'domain-default browser selector probe data-probe-theme-core-question-count must be 1, got 0'

missing_mechanism_module_layer="${test_tmp_root}/missing-mechanism-module-layer"
make_fixture "${missing_mechanism_module_layer}"
sed -i.bak 's/class="canonical-level module-level">MVCC/class="canonical-level">MVCC/' \
  "${missing_mechanism_module_layer}/prototype/index.html"
rm "${missing_mechanism_module_layer}/prototype/index.html.bak"
expect_hvd02_dom_failure "${missing_mechanism_module_layer}" theme-default \
  cross-domain-reading-desktop.png \
  'theme-default browser selector probe data-probe-mechanism-direct-child-topology must be SPAN.canonical-level.landscape-level,I.separator,SPAN.canonical-level.theme-level,I.separator,SPAN.canonical-level.module-level,I.separator,SPAN.canonical-level.element-level, got SPAN.canonical-level.landscape-level,I.separator,SPAN.canonical-level.theme-level,I.separator,SPAN.canonical-level.,I.separator,SPAN.canonical-level.element-level'

cross_domain_graph_workspace="${test_tmp_root}/cross-domain-graph-workspace"
make_fixture "${cross_domain_graph_workspace}"
sed -i.bak 's/<header class="cross-domain-header">/<div class="graph-workspace">Forbidden graph workspace<\/div><header class="cross-domain-header">/' \
  "${cross_domain_graph_workspace}/prototype/index.html"
rm "${cross_domain_graph_workspace}/prototype/index.html.bak"
expect_hvd02_dom_failure "${cross_domain_graph_workspace}" theme-default \
  cross-domain-reading-desktop.png \
  'theme-default browser selector probe data-probe-forbidden-surface-count must be 0, got 1'

small_persistent_sidebar="${test_tmp_root}/small-persistent-sidebar"
make_fixture "${small_persistent_sidebar}"
sed -i.bak 's/<header class="small-reading-header">/<aside class="persistent-governance-panel">Forbidden sidebar<\/aside><header class="small-reading-header">/' \
  "${small_persistent_sidebar}/prototype/index.html"
rm "${small_persistent_sidebar}/prototype/index.html.bak"
expect_hvd02_dom_failure "${small_persistent_sidebar}" module-small-screen \
  module-default-reading-small-screen.png \
  'module-small-screen browser selector probe data-probe-forbidden-surface-count must be 0, got 1'

small_inert_trigger="${test_tmp_root}/small-inert-trigger"
make_fixture "${small_inert_trigger}"
sed -i.bak 's/id="small-element-trigger"/inert id="small-element-trigger"/' \
  "${small_inert_trigger}/prototype/index.html"
rm "${small_inert_trigger}/prototype/index.html.bak"
expect_hvd02_dom_failure "${small_inert_trigger}" module-small-screen \
  module-default-reading-small-screen.png \
  'module-small-screen browser selector probe data-probe-trigger-count must be 1, got 0'

small_hidden_core_text="${test_tmp_root}/small-hidden-core-text"
make_fixture "${small_hidden_core_text}"
sed -i.bak 's/<h1 class="small-core-question"/<h1 hidden class="small-core-question"/' \
  "${small_hidden_core_text}/prototype/index.html"
rm "${small_hidden_core_text}/prototype/index.html.bak"
expect_hvd02_dom_failure "${small_hidden_core_text}" module-small-screen \
  module-default-reading-small-screen.png \
  'module-small-screen browser selector probe data-probe-core-question-count must be 1, got 0'

static_visible_raw_id="${test_tmp_root}/static-visible-raw-id"
make_fixture "${static_visible_raw_id}"
sed -i.bak 's#technical IDs stay silent in normal reading.#technical IDs stay silent in normal reading. landscape-data-systems#' \
  "${static_visible_raw_id}/prototype/index.html"
rm "${static_visible_raw_id}/prototype/index.html.bak"
expect_hvd02_dom_failure "${static_visible_raw_id}" static-export \
  static-export-example.png \
  'static-export browser selector probe data-probe-raw-id-visible-count must be 0, got 1'

static_relation_id_mismatch="${test_tmp_root}/static-relation-id-mismatch"
make_fixture "${static_relation_id_mismatch}"
sed -i.bak 's/data-relation-id="rel-read-view-selects-version"/data-relation-id="rel-wrong"/' \
  "${static_relation_id_mismatch}/prototype/index.html"
rm "${static_relation_id_mismatch}/prototype/index.html.bak"
expect_hvd02_dom_failure "${static_relation_id_mismatch}" static-export \
  static-export-example.png \
  'static-export browser selector probe data-probe-relation-id-set must be rel-read-view-selects-version, got rel-wrong'

manifest_relation_mismatch="${test_tmp_root}/manifest-relation-mismatch"
make_fixture "${manifest_relation_mismatch}"
sed -i.bak 's/"rel-read-view-selects-version"/"rel-manifest-wrong"/' \
  "${manifest_relation_mismatch}/evidence/static-export-manifest.json"
rm "${manifest_relation_mismatch}/evidence/static-export-manifest.json.bak"
expect_failure "${manifest_relation_mismatch}" \
  'static export DOM Relation identities do not match companion manifest'

manifest_duplicate_object="${test_tmp_root}/manifest-duplicate-object"
make_fixture "${manifest_duplicate_object}"
sed -i.bak 's/"element-version-chain"/"element-read-view"/' \
  "${manifest_duplicate_object}/evidence/static-export-manifest.json"
rm "${manifest_duplicate_object}/evidence/static-export-manifest.json.bak"
expect_failure "${manifest_duplicate_object}" \
  'static export companion manifest is invalid'

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
printf 'HV-D02DOMNegativeFixtureCount = 19\n'
printf 'HV-D03DOMNegativeFixtureCount = 12\n'
printf 'HV-D04NegativeFixtureCount = 14\n'
printf 'HV-D04FixRound1NegativeFixtureCount = 6\n'
printf 'HV-D04FixRound2NegativeFixtureCount = 1\n'
printf 'HV-D04FixRound3NegativeFixtureCount = 1\n'
printf 'HV-D04FixRound4NegativeFixtureCount = 3\n'
printf 'HV-D04FixRound5NegativeFixtureCount = 5\n'
printf 'HV-D04FixRound6NegativeFixtureCount = 3\n'
printf 'HV-D04FixRound7NegativeFixtureCount = 1\n'
printf 'HV-D04FixRound8NegativeFixtureCount = 1\n'
printf 'HV-D04FixRound9NegativeFixtureCount = 1\n'
printf 'HV-D04FixRound10NegativeFixtureCount = 1\n'
printf 'HV-D04FixRound11NegativeFixtureCount = 1\n'
printf 'HV-D04FixRound12NegativeFixtureCount = 1\n'
printf 'HV-D04FixRound13NegativeFixtureCount = 1\n'
printf 'NegativeFixtureCount = 139\n'
