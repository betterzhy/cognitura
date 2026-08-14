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
env PATH="${locked_toolchain_path}" \
  "${repo_root}/scripts/verify-visual-style-baseline" --repo-root "${repo_root}"

printf '%s\n' \
  'VisualStyleBaselineBrowserContractTests = PASS' \
  'PositiveCases = 1' \
  "NegativeCases = ${negative_cases}" \
  'RealBrowserVerification = PASS'
