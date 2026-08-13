#!/bin/bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-module-default-reading"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-mdr-toolchain.XXXXXX")"
fixture_root="${test_tmp_root}/fixture/repo"
fake_bin="${test_tmp_root}/bin"
pnpm_call_log="${test_tmp_root}/pnpm-calls.log"

cleanup() {
  rm -rf -- "${test_tmp_root}"
}
trap cleanup EXIT HUP INT TERM

fail() {
  printf 'ModuleDefaultReadingToolchainTests = FAIL: %s\n' "$1" >&2
  exit 1
}

mkdir -p "${fixture_root}/web" "${fake_bin}"
fixture_root="$(cd "${fixture_root}" && pwd -P)"

cat >"${fake_bin}/node" <<'EOF'
#!/bin/bash
if [[ "$#" -eq 1 && "$1" == "--version" ]]; then
  printf 'v24.18.0\n'
  exit 0
fi
exit 64
EOF

cat >"${fake_bin}/pnpm" <<'EOF'
#!/bin/bash
printf '%s|%s\n' "${PWD}" "$*" >>"${PNPM_CALL_LOG}"
if [[ "${PWD}" == "${EXPECTED_WEB_DIR}" && "$#" -eq 1 && "$1" == "--version" ]]; then
  printf '11.17.0\n'
  exit 0
fi
if [[ "${PWD}" != "${EXPECTED_WEB_DIR}" && "$1" == "--version" ]]; then
  printf '9.15.9\n'
  exit 0
fi
if [[ "${PWD}" != "${EXPECTED_WEB_DIR}" && "$#" -eq 3 && "$1" == "--dir" && "$2" == "${EXPECTED_WEB_DIR}" && "$3" == "--version" ]]; then
  printf '9.15.9\n'
  exit 0
fi
if [[ "${PWD}" == "${EXPECTED_WEB_DIR}" && "$#" -eq 1 && ( "$1" == "test" || "$1" == "build" ) ]]; then
  exit 0
fi
exit 64
EOF

chmod +x "${fake_bin}/node" "${fake_bin}/pnpm"

bare_pnpm_version="$(
  env \
    PATH="${fake_bin}:/usr/bin:/bin" \
    PNPM_CALL_LOG="${pnpm_call_log}" \
    EXPECTED_WEB_DIR="${fixture_root}/web" \
    pnpm --version
)"
[[ "${bare_pnpm_version}" == "9.15.9" ]] ||
  fail "fake bare pnpm did not expose the parent version"

web_scoped_pnpm_version="$(
  env \
    PATH="${fake_bin}:/usr/bin:/bin" \
    PNPM_CALL_LOG="${pnpm_call_log}" \
    EXPECTED_WEB_DIR="${fixture_root}/web" \
    pnpm --dir "${fixture_root}/web" --version
)"
[[ "${web_scoped_pnpm_version}" == "9.15.9" ]] ||
  fail "fake root --dir probe did not retain the parent version"

web_cwd_pnpm_version="$(
  cd "${fixture_root}/web"
  env \
    PATH="${fake_bin}:/usr/bin:/bin" \
    PNPM_CALL_LOG="${pnpm_call_log}" \
    EXPECTED_WEB_DIR="${fixture_root}/web" \
    pnpm --version
)"
[[ "${web_cwd_pnpm_version}" == "11.17.0" ]] ||
  fail "fake web cwd did not expose the locked pnpm version"

if ! output="$(
  env \
    PATH="${fake_bin}:/usr/bin:/bin" \
    PNPM_CALL_LOG="${pnpm_call_log}" \
    EXPECTED_WEB_DIR="${fixture_root}/web" \
    "${verifier}" --repo-root "${fixture_root}" 2>&1
)"; then
  fail "verifier rejected the web-scoped pnpm 11.17.0 fixture: ${output}"
fi

expected_calls="$(printf '%s\n' \
  "${repo_root}|--version" \
  "${repo_root}|--dir ${fixture_root}/web --version" \
  "${fixture_root}/web|--version" \
  "${fixture_root}/web|--version" \
  "${fixture_root}/web|test" \
  "${fixture_root}/web|build")"
actual_calls="$(cat "${pnpm_call_log}")"
[[ "${actual_calls}" == "${expected_calls}" ]] ||
  fail "unexpected pnpm invocation sequence: ${actual_calls}"

printf '%s\n' \
  'ModuleDefaultReadingToolchainTests = PASS' \
  "BarePnpmVersion = ${bare_pnpm_version}" \
  "RootDirPnpmVersion = ${web_scoped_pnpm_version}" \
  "WebCwdPnpmVersion = ${web_cwd_pnpm_version}" \
  'PnpmInvocationSequence = PASS'
