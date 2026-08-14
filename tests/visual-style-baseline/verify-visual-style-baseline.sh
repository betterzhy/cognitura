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

candidate_binding_repo="${runtime_root}/candidate-binding-repo"
candidate_binding_sentinel="${runtime_root}/mutable-tool-was-executed"
git clone --shared --quiet "${repo_root}" "${candidate_binding_repo}"
git -C "${candidate_binding_repo}" checkout --quiet --detach "$(git -C "${repo_root}" rev-parse HEAD)"
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

closed_set_repo="${runtime_root}/closed-set-repo"
git clone --shared --quiet "${repo_root}" "${closed_set_repo}"
git -C "${closed_set_repo}" checkout --quiet --detach "$(git -C "${repo_root}" rev-parse HEAD)"
closed_set_manifest="${closed_set_repo}/docs/design/visual-style-baseline/evidence/README.md"
closed_set_acceptance="${closed_set_repo}/docs/engineering/cognitura-visual-style-baseline-acceptance.md"
for closed_set_mutation in \
    manifest-unknown-field \
    acceptance-authorized-database \
    manifest-real-dom-fail \
    manifest-request-count-drift \
    acceptance-duplicate-fail \
    acceptance-missing-field; do
  git -C "${closed_set_repo}" restore --worktree --source=HEAD -- \
    docs/design/visual-style-baseline/evidence/README.md \
    docs/engineering/cognitura-visual-style-baseline-acceptance.md
  case "${closed_set_mutation}" in
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

imported_function_sentinel="${runtime_root}/imported-function-executed"
(
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
)
[[ ! -e "${imported_function_sentinel}" ]] ||
  fail "fixed visual verification imported an exported shell function"
negative_cases=$((negative_cases + 1))

printf '%s\n' \
  'VisualStyleBaselineBrowserContractTests = PASS' \
  'PositiveCases = 1' \
  "NegativeCases = ${negative_cases}" \
  'RealBrowserVerification = PASS'
