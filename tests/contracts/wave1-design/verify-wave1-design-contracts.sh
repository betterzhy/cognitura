#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

fail() {
  printf 'Wave1DesignContracts = FAIL\n%s\n' "$1" >&2
  exit 1
}

run_contract() {
  local script="$1"
  local expected="$2"
  local output

  [[ -x "${script}" ]] ||
    fail "contract verifier is missing or not executable: ${script}"
  if ! output="$("${script}" 2>&1)"; then
    printf '%s\n' "${output}" >&2
    fail "contract verifier failed: ${script}"
  fi
  [[ "${output}" == *"${expected}"* ]] ||
    fail "contract verifier did not report expected PASS: ${expected}"
}

run_contract \
  "${repo_root}/tests/contracts/wave1-design/verify-source-document-contract.sh" \
  "SourceDocumentContractValidation = PASS"
printf '%s\n' "Wave1SourceDocumentContract = PASS"

run_contract \
  "${repo_root}/tests/contracts/wave1-design/verify-document-block-contract.sh" \
  "DocumentBlockContractValidation = PASS"
printf '%s\n' "Wave1DocumentBlockContract = PASS"

run_contract \
  "${repo_root}/tests/contracts/wave1-design/verify-reparse-reference-contract.sh" \
  "ReparseReferenceContractValidation = PASS"
printf '%s\n' "Wave1ReparseReferenceContract = PASS"

run_contract \
  "${repo_root}/tests/contracts/wave1-design/verify-source-preview-contract.sh" \
  "SourcePreviewContractValidation = PASS"
printf '%s\n' \
  "Wave1SourcePreviewContract = PASS" \
  "Wave1DesignContracts = PASS"
