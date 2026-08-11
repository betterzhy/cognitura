#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-wave1-implementation-cards"
cards_dir="${repo_root}/docs/task-cards/wave-1-implementation"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local content="$1"
  local expected="$2"
  [[ "${content}" == *"${expected}"* ]] ||
    fail "validation output is missing: ${expected}"
}

[[ -x "${verifier}" ]] || fail "Wave 1 implementation task-card verifier is missing or not executable"

validation_output="$(
  "${verifier}" \
    --cards-dir "${cards_dir}"
)"

assert_contains "${validation_output}" "Wave1ImplementationTaskCardValidation = PASS"
assert_contains "${validation_output}" "TaskCardCount = 14"
assert_contains "${validation_output}" "TaskCardSetStatus = READY_FOR_EXECUTION"
assert_contains "${validation_output}" "ActiveTaskCard = W1-I00"

printf '%s\n' \
  "Wave1ImplementationTaskCardContractTests = PASS" \
  "PositiveCases = 1"
