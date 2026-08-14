#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd -P)"
runtime_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-vsb-browser-contract.XXXXXX")"

cleanup() {
  find "${runtime_root}" -depth -delete >/dev/null 2>&1 || true
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

require_owned_file() {
  local relative_file="$1"
  [[ -f "${repo_root}/${relative_file}" ]] ||
    fail "required VSB-03 Owner file is missing: ${relative_file}"
}

require_owned_file scripts/verify-visual-style-baseline
require_owned_file scripts/capture-visual-style-baseline
require_owned_file tests/visual-style-baseline/browser-probe.html
require_owned_file tests/visual-style-baseline/browser-runtime-guard.js
require_owned_file tests/visual-style-baseline/reference-comparison.html

capture_source="${repo_root}/scripts/capture-visual-style-baseline"
task_card_verifier="${repo_root}/scripts/verify-visual-style-baseline-cards"
"${task_card_verifier}" --chrome-capture-source-contract "${capture_source}" >/dev/null

historical_hv_snapshot_sha=77d8c1e780f5cc4d209a56baff349135a3c04ee8
[[ "$(git -C "${repo_root}" rev-parse \
     "${historical_hv_snapshot_sha}^{tree}")" == \
   476bc02272b2e0c4f8f6eb4565e9dcf08369f762 ]] ||
  fail "fixed historical HV replay tree drifted"
[[ "$(git -C "${repo_root}" rev-parse \
     "${historical_hv_snapshot_sha}^")" == \
   98d5f89731626c0ead69de46255ba4d433d03c86 ]] ||
  fail "fixed historical HV replay parent drifted"
[[ "$(git -C "${repo_root}" ls-tree "${historical_hv_snapshot_sha}" -- \
     scripts/verify-high-fidelity-visual)" == \
   $'100755 blob 73c1b62e643d3808c16ccab89aefb13e3646502b\tscripts/verify-high-fidelity-visual' ]] ||
  fail "fixed historical HV verifier identity drifted"
[[ "$(git -C "${repo_root}" ls-tree "${historical_hv_snapshot_sha}" -- AGENTS.md)" == \
   $'100644 blob 3b9dbe8c3241671ed2070446d3781b1453239f07\tAGENTS.md' ]] ||
  fail "fixed historical HV AGENTS identity drifted"
[[ "$(git -C "${repo_root}" ls-tree "${historical_hv_snapshot_sha}" -- \
     docs/engineering/cognitura-design-index.md)" == \
   $'100644 blob d0b85366e8eaee7771afdb95436e1a7e28aa75ae\tdocs/engineering/cognitura-design-index.md' ]] ||
  fail "fixed historical HV design-index identity drifted"

negative_cases=0
expect_source_failure() {
  local fixture_file="$1"
  local output
  if output="$("${task_card_verifier}" \
      --chrome-capture-source-contract "${fixture_file}" 2>&1)"; then
    fail "invalid capture source unexpectedly passed: $(basename "${fixture_file}")"
  fi
  [[ "${output}" == *'VisualStyleBaselineTaskCardValidation = FAIL'* ]] ||
    fail "invalid capture source did not fail through the public verifier"
  negative_cases=$((negative_cases + 1))
}

cp "${capture_source}" "${runtime_root}/extra-comment"
printf '# forbidden extra byte\n' >> "${runtime_root}/extra-comment"
chmod 755 "${runtime_root}/extra-comment"
expect_source_failure "${runtime_root}/extra-comment"

cp "${capture_source}" "${runtime_root}/mode-drift"
chmod 644 "${runtime_root}/mode-drift"
expect_source_failure "${runtime_root}/mode-drift"

cp "${capture_source}" "${runtime_root}/missing-final-newline"
perl -0pi -e 's/\n\z//' "${runtime_root}/missing-final-newline"
chmod 755 "${runtime_root}/missing-final-newline"
expect_source_failure "${runtime_root}/missing-final-newline"

grep -Fq 'data-primary-visual-projection' \
  "${repo_root}/tests/visual-style-baseline/browser-probe.html" ||
  fail "browser probe does not compute the primary projection"
! grep -Fq 'data-probe-primary-projection-count' \
  "${repo_root}/tests/visual-style-baseline/browser-probe.html" ||
  fail "browser probe trusts a fixture-authored count"
grep -Fq 'VSB_FORBIDDEN_RUNTIME_API' \
  "${repo_root}/tests/visual-style-baseline/browser-runtime-guard.js" ||
  fail "runtime guard does not fail forbidden APIs"
grep -Fq 'paths.some((path) => path === null || !path.startsWith("/__assets/"))' \
  "${repo_root}/tests/visual-style-baseline/reference-comparison.html" ||
  fail "comparison input is not restricted to same-origin assets"

locked_toolchain_path='/Users/yuzhuangzhuang/.npm/_npx/4aa47c519def57bc/node_modules/.bin:/Users/yuzhuangzhuang/.npm/_npx/acaf29b40d536b0e/node_modules/.bin:/opt/homebrew/opt/python@3.11/libexec/bin:/usr/bin:/bin:/usr/sbin:/sbin'

sanitization_sentinel="${runtime_root}/startup-function-bypass"
(
  export VSB_IMPORTED_FUNCTION_SENTINEL="${sanitization_sentinel}"
  cd() {
    printf 'cd\n' >> "${VSB_IMPORTED_FUNCTION_SENTINEL}"
    builtin cd "$@"
  }
  unset() { :; }
  builtin() { :; }
  compgen() { :; }
  export -f cd unset builtin compgen
  env PATH="${locked_toolchain_path}" \
    "${repo_root}/scripts/verify-visual-style-baseline" \
    --repo-root "${runtime_root}/missing-repository" >/dev/null 2>&1 || true
)
[[ ! -e "${sanitization_sentinel}" ]] ||
  fail "startup sanitization was bypassed by imported shell functions"
negative_cases=$((negative_cases + 1))

bash_env_sentinel="${runtime_root}/bash-env-pre-sanitization-executed"
bash_env_fixture="${runtime_root}/ambient-bash-env"
printf '%s\n' \
  'printf "executed\\n" > "${VSB_BASH_ENV_SENTINEL}"' > "${bash_env_fixture}"
(
  export VSB_BASH_ENV_SENTINEL="${bash_env_sentinel}"
  BASH_ENV="${bash_env_fixture}" ENV="${bash_env_fixture}" \
    env PATH="${locked_toolchain_path}" \
      "${repo_root}/scripts/verify-visual-style-baseline" \
      --repo-root "${runtime_root}/missing-repository" >/dev/null 2>&1 || true
)
[[ ! -e "${bash_env_sentinel}" ]] ||
  fail "BASH_ENV executed before the sanitized verifier payload"
negative_cases=$((negative_cases + 1))

candidate_binding_repo="${runtime_root}/candidate-binding-repo"
candidate_binding_sentinel="${runtime_root}/mutable-tool-was-executed"
git clone --shared --quiet "${repo_root}" "${candidate_binding_repo}"
git -C "${candidate_binding_repo}" checkout --quiet --detach \
  2690ab9e6d0318c63deb56f86bc0b923ae845c04
printf '%s\n' \
  '#!/bin/bash' \
  'set -euo pipefail' \
  "printf 'executed\\n' > '${candidate_binding_sentinel}'" \
  'exit 0' > "${candidate_binding_repo}/scripts/verify-module-default-reading"
chmod 755 "${candidate_binding_repo}/scripts/verify-module-default-reading"
if env PATH="${locked_toolchain_path}" \
    "${repo_root}/scripts/verify-visual-style-baseline" \
    --repo-root "${candidate_binding_repo}" \
    --candidate-sha "$(git -C "${candidate_binding_repo}" rev-parse HEAD)" >/dev/null 2>&1; then
  fail "candidate verification unexpectedly accepted a masked governed tool"
fi
[[ ! -e "${candidate_binding_sentinel}" ]] ||
  fail "candidate identity binding ran after a mutable governed tool"
negative_cases=$((negative_cases + 1))

git -C "${candidate_binding_repo}" restore --worktree --source=HEAD -- \
  scripts/verify-module-default-reading
for candidate_bound_path in \
    scripts/capture-visual-style-baseline \
    scripts/verify-visual-style-baseline \
    tests/visual-style-baseline/browser-probe.html \
    tests/visual-style-baseline/browser-runtime-guard.js \
    tests/visual-style-baseline/reference-comparison.html; do
  git -C "${candidate_binding_repo}" restore --worktree --source=HEAD -- \
    scripts/capture-visual-style-baseline \
    scripts/verify-visual-style-baseline \
    tests/visual-style-baseline/browser-probe.html \
    tests/visual-style-baseline/browser-runtime-guard.js \
    tests/visual-style-baseline/reference-comparison.html
  printf '\n# candidate-bound mutation\n' >> \
    "${candidate_binding_repo}/${candidate_bound_path}"
  candidate_binding_output=""
  if candidate_binding_output="$(env PATH="${locked_toolchain_path}" \
      "${repo_root}/scripts/verify-visual-style-baseline" \
      --repo-root "${candidate_binding_repo}" \
      --candidate-sha "$(git -C "${candidate_binding_repo}" rev-parse HEAD)" 2>&1)"; then
    fail "candidate-bound path mutation unexpectedly passed: ${candidate_bound_path}"
  fi
  [[ "${candidate_binding_output}" == *"working tree differs from candidate: ${candidate_bound_path}"* ]] ||
    fail "candidate-bound path mutation failed without identity diagnostic: ${candidate_bound_path}"
  negative_cases=$((negative_cases + 1))
done

closed_set_repo="${runtime_root}/closed-set-repo"
git clone --shared --quiet "${repo_root}" "${closed_set_repo}"
git -C "${closed_set_repo}" checkout --quiet --detach "$(git -C "${repo_root}" rev-parse HEAD)"
closed_set_manifest="${closed_set_repo}/docs/design/visual-style-baseline/evidence/README.md"
closed_set_acceptance="${closed_set_repo}/docs/engineering/cognitura-visual-style-baseline-acceptance.md"
for closed_set_mutation in \
    evidence-png-missing \
    evidence-png-dimensions \
    evidence-png-byte \
    manifest-sha-mismatch \
    manifest-unknown-field \
    acceptance-authorized-database \
    manifest-real-dom-fail \
    manifest-request-count-drift \
    acceptance-duplicate-fail \
    acceptance-missing-field \
    acceptance-full-product-pass; do
  git -C "${closed_set_repo}" restore --worktree --source=HEAD -- \
    docs/design/visual-style-baseline/evidence/README.md \
    docs/design/visual-style-baseline/evidence/module-default-reading-1440x1100.png \
    docs/design/visual-style-baseline/evidence/module-default-reading-1280x960.png \
    docs/design/visual-style-baseline/evidence/module-default-reading-1024x900.png \
    docs/design/visual-style-baseline/evidence/reference-comparison.png \
    docs/engineering/cognitura-visual-style-baseline-acceptance.md
  case "${closed_set_mutation}" in
    evidence-png-missing)
      find "${closed_set_repo}/docs/design/visual-style-baseline/evidence/module-default-reading-1024x900.png" -delete
      ;;
    evidence-png-dimensions)
      python3 - "${closed_set_repo}/docs/design/visual-style-baseline/evidence/module-default-reading-1280x960.png" <<'PY'
from PIL import Image
import sys
Image.new("RGB", (1, 1), "white").save(sys.argv[1])
PY
      ;;
    evidence-png-byte)
      printf 'x' >> "${closed_set_repo}/docs/design/visual-style-baseline/evidence/module-default-reading-1440x1100.png"
      ;;
    manifest-sha-mismatch)
      perl -0pi -e 's/bf753320352d7c9aab7bc7c40d9f8b40e1f649c174684695e77d1f3223e65ab0/0000000000000000000000000000000000000000000000000000000000000000/' \
        "${closed_set_manifest}"
      ;;
    manifest-unknown-field)
      printf '\nRemotePush = AUTHORIZED\n' >> "${closed_set_manifest}"
      ;;
    acceptance-authorized-database)
      printf '\nFormalDatabaseWrite = AUTHORIZED\n' >> "${closed_set_acceptance}"
      ;;
    manifest-real-dom-fail)
      perl -0pi -e 's/(module-default-reading-1440x1100\.png[^\n]*fixed `\.138` capture \|) PASS \|/$1 FAIL |/' \
        "${closed_set_manifest}"
      ;;
    manifest-request-count-drift)
      perl -0pi -e 's/(module-default-reading-1280x960\.png[^\n]*\|) 62 \| PASS \|/$1 999 | PASS |/' \
        "${closed_set_manifest}"
      ;;
    acceptance-duplicate-fail)
      printf '\nSameProductFamily = FAIL\n' >> "${closed_set_acceptance}"
      ;;
    acceptance-missing-field)
      perl -0pi -e 's/^NoDashboardRegression = PASS\n//m' "${closed_set_acceptance}"
      ;;
    acceptance-full-product-pass)
      perl -0pi -e 's/ImplementationValidation = NOT_CLAIMED_FOR_FULL_PRODUCT_PAGE/ImplementationValidation = PASS/' \
        "${closed_set_acceptance}"
      ;;
  esac
  closed_set_output=""
  if closed_set_output="$(env PATH="${locked_toolchain_path}" \
      "${repo_root}/scripts/verify-visual-style-baseline" \
      --repo-root "${closed_set_repo}" 2>&1)"; then
    fail "closed-set mutation unexpectedly passed: ${closed_set_mutation}"
  fi
  [[ "${closed_set_output}" == *'VisualStyleBaselineVerification = FAIL'* ]] ||
    fail "closed-set mutation did not fail through the public verifier: ${closed_set_mutation}"
  negative_cases=$((negative_cases + 1))
done

for freeze_mutation in historical-evidence frozen-w1-production; do
  freeze_repo="${runtime_root}/${freeze_mutation}-repo"
  git clone --shared --quiet "${repo_root}" "${freeze_repo}"
  git -C "${freeze_repo}" checkout --quiet --detach "$(git -C "${repo_root}" rev-parse HEAD)"
  git -C "${freeze_repo}" config user.name 'Cognitura VSB Contract'
  git -C "${freeze_repo}" config user.email 'vsb-contract@example.invalid'
  case "${freeze_mutation}" in
    historical-evidence)
      printf 'x' >> \
        "${freeze_repo}/docs/design/high-fidelity/evidence/module-source-verification-desktop.png"
      freeze_expected='historical visual evidence changed'
      ;;
    frozen-w1-production)
      printf '\n// forbidden frozen-tree mutation\n' >> \
        "${freeze_repo}/server/src/main/java/io/cognitura/source/docx/security/DocxPackageLimits.java"
      freeze_expected='frozen W1-I03 production tree changed'
      ;;
  esac
  git -C "${freeze_repo}" add --all
  git -C "${freeze_repo}" commit -qm "test: ${freeze_mutation}"
  freeze_output=""
  if freeze_output="$(env PATH="${locked_toolchain_path}" \
      "${repo_root}/scripts/verify-visual-style-baseline" \
      --repo-root "${freeze_repo}" 2>&1)"; then
    fail "freeze mutation unexpectedly passed: ${freeze_mutation}"
  fi
  [[ "${freeze_output}" == *"${freeze_expected}"* ]] ||
    fail "freeze mutation failed without exact diagnostic: ${freeze_mutation}"
  negative_cases=$((negative_cases + 1))
done

browser_mutation_repo="${runtime_root}/browser-mutation-repo"
browser_mutation_tmp="${runtime_root}/browser-mutation-tmp"
git clone --shared --quiet "${repo_root}" "${browser_mutation_repo}"
git -C "${browser_mutation_repo}" checkout --quiet --detach "$(git -C "${repo_root}" rev-parse HEAD)"
if [[ -d "${repo_root}/web/node_modules" ]]; then
  ln -s "${repo_root}/web/node_modules" "${browser_mutation_repo}/web/node_modules"
fi
mkdir -p "${browser_mutation_tmp}"

wrong_version_verifier="${runtime_root}/wrong-version-verifier"
wrong_version_chrome="${runtime_root}/wrong-version-chrome"
wrong_version_sentinel="${runtime_root}/wrong-version-browser-side-effect"
git -C "${repo_root}" show \
  'c3ee56051d423ae12852787948d71e994005087e:scripts/verify-visual-style-baseline-cards' > \
  "${wrong_version_verifier}"
printf '%s\n' \
  '#!/bin/bash' \
  'if [[ "$#" -eq 1 && "$1" == --version ]]; then' \
  '  printf '\''Google Chrome 151.0.7922.137\\n'\''' \
  '  exit 0' \
  'fi' \
  "printf 'executed\\n' > '${wrong_version_sentinel}'" \
  'exit 97' > "${wrong_version_chrome}"
chmod 755 "${wrong_version_verifier}" "${wrong_version_chrome}"
python3 - "${wrong_version_verifier}" "${wrong_version_chrome}" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
source = path.read_text(encoding="utf-8")
fixed = "'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'"
if source.count(fixed) != 2:
    raise SystemExit("fixed Chrome dependency replacement count mismatch")
path.write_text(source.replace(fixed, repr(sys.argv[2])), encoding="utf-8")
PY
wrong_version_output=""
if wrong_version_output="$(env -i \
    HOME="${HOME}" \
    TMPDIR="${browser_mutation_tmp}" \
    PATH="${locked_toolchain_path}" \
    LANG="${LANG:-C}" \
    /bin/bash "${wrong_version_verifier}" --chrome-fixed-capture \
      --repo-root "${browser_mutation_repo}" \
      --output-dir "${runtime_root}/wrong-version-output" 2>&1)"; then
  fail "Chrome version 151.0.7922.137 unexpectedly passed"
fi
[[ "${wrong_version_output}" == *'expected Google Chrome 151.0.7922.138'* ]] ||
  fail "wrong Chrome version failed without exact diagnostic"
[[ ! -e "${wrong_version_sentinel}" ]] ||
  fail "wrong Chrome version reached a browser side effect"
negative_cases=$((negative_cases + 1))

inject_probe_mutation() {
  local probe_file="$1"
  local mutation_code="$2"
  python3 - "${probe_file}" "${mutation_code}" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
mutation = sys.argv[2]
source = path.read_text(encoding="utf-8")
marker = "            await waitForReady(doc);\n"
if source.count(marker) != 1:
    raise SystemExit("probe mutation marker mismatch")
path.write_text(source.replace(marker, marker + "            " + mutation + "\n", 1), encoding="utf-8")
PY
}

for browser_mutation in \
    body-font-14 \
    body-line-height-low \
    focus-outline-missing \
    horizontal-overflow \
    primary-projection-zero \
    primary-projection-two \
    complementary-region \
    dashboard-selector \
    nested-semantic-surface \
    raw-relation-type \
    visible-source-id \
    conditions-heading \
    spoofed-primary-count \
    forbidden-runtime-api \
    browser-storage \
    runtime-guard-failure \
    csp-violation \
    external-image-csp \
    unexpected-http-request \
    visual-ready-missing \
    comparison-ready-missing; do
  git -C "${browser_mutation_repo}" restore --worktree --source=HEAD -- \
    tests/visual-style-baseline/browser-probe.html \
    tests/visual-style-baseline/browser-runtime-guard.js \
    tests/visual-style-baseline/reference-comparison.html
  browser_probe="${browser_mutation_repo}/tests/visual-style-baseline/browser-probe.html"
  case "${browser_mutation}" in
    body-font-14)
      inject_probe_mutation "${browser_probe}" 'doc.querySelector("[data-reading-section=core-conclusion] p").style.fontSize = "14px";'
      ;;
    body-line-height-low)
      inject_probe_mutation "${browser_probe}" 'doc.querySelector("[data-reading-section=core-conclusion] p").style.lineHeight = "26px";'
      ;;
    focus-outline-missing)
      inject_probe_mutation "${browser_probe}" 'doc.querySelector("[data-reading-section=source-entry] button").style.outline = "none";'
      ;;
    horizontal-overflow)
      inject_probe_mutation "${browser_probe}" 'doc.querySelector(".module-default-reading").style.minWidth = "2000px";'
      ;;
    primary-projection-zero)
      inject_probe_mutation "${browser_probe}" 'doc.querySelector("[data-primary-visual-projection=true]").removeAttribute("data-primary-visual-projection");'
      ;;
    primary-projection-two)
      inject_probe_mutation "${browser_probe}" 'doc.body.append(doc.querySelector("[data-primary-visual-projection=true]").cloneNode(true));'
      ;;
    complementary-region)
      inject_probe_mutation "${browser_probe}" 'doc.body.append(doc.createElement("aside"));'
      ;;
    dashboard-selector)
      inject_probe_mutation "${browser_probe}" 'doc.querySelector(".module-default-reading").classList.add("dashboard-shell");'
      ;;
    nested-semantic-surface)
      inject_probe_mutation "${browser_probe}" 'const nested = doc.createElement("div"); nested.className = "cka-projection-surface"; doc.querySelector(".cka-projection-surface").append(nested);'
      ;;
    raw-relation-type)
      inject_probe_mutation "${browser_probe}" 'const relation = doc.querySelector("li[data-relation-type]"); relation.querySelector("[data-relation-part=type]").textContent = relation.dataset.relationType;'
      ;;
    visible-source-id)
      inject_probe_mutation "${browser_probe}" 'doc.querySelector("[data-source-refs]").insertAdjacentText("afterend", JSON.parse(doc.querySelector("[data-source-refs]").dataset.sourceRefs)[0]);'
      ;;
    conditions-heading)
      inject_probe_mutation "${browser_probe}" 'const heading = doc.createElement("h2"); heading.textContent = "Conditions"; doc.body.append(heading);'
      ;;
    spoofed-primary-count)
      inject_probe_mutation "${browser_probe}" 'doc.body.dataset.probePrimaryProjectionCount = "1"; doc.querySelector("[data-primary-visual-projection=true]").removeAttribute("data-primary-visual-projection");'
      ;;
    forbidden-runtime-api)
      inject_probe_mutation "${browser_probe}" 'try { win.fetch("/forbidden-runtime"); } catch (_error) {}'
      ;;
    browser-storage)
      inject_probe_mutation "${browser_probe}" 'try { win.localStorage.setItem("vsb", "forbidden"); } catch (_error) {}'
      ;;
    runtime-guard-failure)
      inject_probe_mutation "${browser_probe}" 'if (win.__vsbRuntimeUsage) win.__vsbRuntimeUsage.guardInstallStatus = "FAIL";'
      ;;
    csp-violation)
      inject_probe_mutation "${browser_probe}" 'if (win.__vsbRuntimeUsage) win.__vsbRuntimeUsage.cspViolationCount = 1;'
      ;;
    external-image-csp)
      inject_probe_mutation "${browser_probe}" 'const externalImage = doc.createElement("img"); externalImage.src = "http://1.2.3.4/forbidden.png"; doc.body.append(externalImage); await new Promise((resolve) => win.setTimeout(resolve, 250));'
      ;;
    unexpected-http-request)
      inject_probe_mutation "${browser_probe}" 'const image = doc.createElement("img"); image.src = "/unexpected-network-path"; doc.body.append(image);'
      ;;
    visual-ready-missing)
      perl -0pi -e 's/dataset\.visualReferenceReady === "true"/dataset.visualReferenceReady === "never"/' \
        "${browser_probe}"
      ;;
    comparison-ready-missing)
      perl -0pi -e 's/dataset\.comparisonReady = "true"/dataset.comparisonReady = "never"/' \
        "${browser_mutation_repo}/tests/visual-style-baseline/reference-comparison.html"
      ;;
  esac
  browser_output_dir="${runtime_root}/browser-output-${browser_mutation}"
  browser_output=""
  if browser_output="$(env -i \
      HOME="${HOME}" \
      TMPDIR="${browser_mutation_tmp}" \
      PATH="${locked_toolchain_path}" \
      LANG="${LANG:-C}" \
      "${browser_mutation_repo}/scripts/capture-visual-style-baseline" \
      --repo-root "${browser_mutation_repo}" \
      --output-dir "${browser_output_dir}" 2>&1)"; then
    fail "browser mutation unexpectedly passed: ${browser_mutation}"
  fi
  [[ "${browser_output}" == *'VisualStyleBaselineTaskCardValidation = FAIL'* ]] ||
    fail "browser mutation did not fail through the fixed capture verifier: ${browser_mutation}"
  negative_cases=$((negative_cases + 1))
done

chrome_override_output=""
if chrome_override_output="$(env -i \
    HOME="${HOME}" \
    TMPDIR="${browser_mutation_tmp}" \
    PATH="${locked_toolchain_path}" \
    LANG="${LANG:-C}" \
    CHROME_BIN=/bin/false \
    "${browser_mutation_repo}/scripts/capture-visual-style-baseline" \
    --repo-root "${browser_mutation_repo}" \
    --output-dir "${runtime_root}/browser-output-override" 2>&1)"; then
  fail "Chrome binary override unexpectedly passed"
fi
[[ "${chrome_override_output}" == *'Chrome browser executable override is forbidden'* ]] ||
  fail "Chrome binary override failed without exact diagnostic"
negative_cases=$((negative_cases + 1))

imported_function_sentinel="${runtime_root}/imported-function-executed"
historical_replay_output="$( (
  export VSB_IMPORTED_FUNCTION_SENTINEL="${imported_function_sentinel}"
  cd() {
    printf 'cd\n' >> "${VSB_IMPORTED_FUNCTION_SENTINEL}"
    builtin cd "$@"
  }
  exec() {
    printf 'exec\n' >> "${VSB_IMPORTED_FUNCTION_SENTINEL}"
    builtin exec "$@"
  }
  git() {
    printf 'git\n' >> "${VSB_IMPORTED_FUNCTION_SENTINEL}"
    /usr/bin/git "$@"
  }
  export -f cd exec git
  env PATH="${locked_toolchain_path}" \
    "${repo_root}/scripts/verify-visual-style-baseline" --repo-root "${repo_root}"
) )"
[[ ! -e "${imported_function_sentinel}" ]] ||
  fail "fixed visual verification imported an exported shell function"
negative_cases=$((negative_cases + 1))
[[ "${historical_replay_output}" == \
   *'HistoricalHVReplaySHA = 77d8c1e780f5cc4d209a56baff349135a3c04ee8'* ]] ||
  fail "fixed visual verifier did not bind the historical HV replay SHA"
[[ "${historical_replay_output}" == *'HistoricalHVReplay = PASS'* ]] ||
  fail "fixed visual verifier did not replay the historical HV Gate"
[[ "${historical_replay_output}" == \
   *'HistoricalHVCurrentTreeVerifier = NOT_RUN'* ]] ||
  fail "fixed visual verifier did not exclude the current-tree HV verifier"

[[ "${negative_cases}" -eq 48 ]] ||
  fail "visual browser negative matrix count drifted from 48"

printf '%s\n' \
  'VisualStyleBaselineBrowserContractTests = PASS' \
  'PositiveCases = 1' \
  "NegativeCases = ${negative_cases}" \
  'RealBrowserVerification = PASS'
