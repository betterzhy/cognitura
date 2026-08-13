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
printf '%s\n' "$*" >>"${PNPM_CALL_LOG}"
if [[ "$#" -eq 1 && "$1" == "--version" ]]; then
  printf '9.15.9\n'
  exit 0
fi
if [[ "$#" -eq 3 && "$1" == "--dir" && "$2" == "${EXPECTED_WEB_DIR}" && "$3" == "--version" ]]; then
  printf '11.17.0\n'
  exit 0
fi
if [[ "$#" -eq 3 && "$1" == "--dir" && "$2" == "${EXPECTED_WEB_DIR}" && ( "$3" == "test" || "$3" == "build" ) ]]; then
  exit 0
fi
exit 64
EOF

chmod +x "${fake_bin}/node" "${fake_bin}/pnpm"

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
  "--dir ${fixture_root}/web --version" \
  "--dir ${fixture_root}/web test" \
  "--dir ${fixture_root}/web build")"
actual_calls="$(cat "${pnpm_call_log}")"
[[ "${actual_calls}" == "${expected_calls}" ]] ||
  fail "unexpected pnpm invocation sequence: ${actual_calls}"

printf '%s\n' \
  'ModuleDefaultReadingToolchainTests = PASS' \
  'BarePnpmVersion = 9.15.9' \
  'WebScopedPnpmVersion = 11.17.0' \
  'PnpmInvocationSequence = PASS'
