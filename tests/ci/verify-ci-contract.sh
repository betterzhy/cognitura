#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
workflow="${repo_root}/.github/workflows/wave0.yml"
unified_verifier="${repo_root}/scripts/verify-wave0"
strategy="${repo_root}/docs/engineering/cognitura-test-strategy.md"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-ci-contract.XXXXXX")"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

hash_file() {
  local path="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${path}" | awk '{print $1}'
  else
    shasum -a 256 "${path}" | awk '{print $1}'
  fi
}

snapshot_formal_inputs() {
  local path

  for path in \
    "cognitive-knowledge-atlas-overall-design-1.2.md" \
    "raw/11-MySQL数据库.docx" \
    "raw/12-Redis中间件.docx" \
    "raw/40-英语学习.docx"; do
    printf '%s|%s\n' "${path}" "$(hash_file "${repo_root}/${path}")"
  done
}

require_workflow_line() {
  local expected="$1"

  grep -Fq -- "${expected}" "${workflow}" ||
    fail "workflow is missing required contract: ${expected}"
}

[[ -x "${unified_verifier}" ]] ||
  fail "unified Wave 0 verifier is missing or not executable"
[[ -f "${workflow}" ]] || fail "CI workflow is missing"
[[ -f "${strategy}" ]] || fail "test strategy is missing"

grep -Fq 'bash "${repo_root}/tests/ci/verify-ci-contract.sh"' "${unified_verifier}" ||
  fail "unified Wave 0 verifier does not execute the CI contract test"
grep -Fq 'bash "${repo_root}/tests/ci/verify-markdown-links.sh"' "${unified_verifier}" ||
  fail "unified Wave 0 verifier does not execute the Markdown link test"

require_workflow_line "contents: read"
require_workflow_line "image: postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a"
require_workflow_line "cache-dependency-path: |"
require_workflow_line ".mvn/wrapper/maven-wrapper.properties"
require_workflow_line "web/pnpm-lock.yaml"
require_workflow_line "tests/contracts/schema/pnpm-lock.yaml"
require_workflow_line "run: scripts/verify-wave0"

if grep -Eq 'uses: [^[:space:]]+@(main|master|v?[0-9]+([.][0-9]+){0,2})([[:space:]]|$)' \
  "${workflow}"; then
  fail "workflow uses a floating action reference"
fi

if awk '
  /^[[:space:]]*uses:/ {
    reference = $2
    sub(/^.*@/, "", reference)
    if (reference !~ /^[0-9a-f]{40}$/) {
      print reference
      exit 1
    }
  }
' "${workflow}" >/dev/null; then
  :
else
  fail "workflow action references must use full commit SHAs"
fi

if grep -Eiq \
  '(secrets[.]|permissions:[[:space:]]*write|contents:[[:space:]]*write|packages:[[:space:]]*write|id-token:[[:space:]]*write|DATABASE_URL|PRODUCTION_|AWS_|REDIS_URL)' \
  "${workflow}"; then
  fail "workflow requests forbidden credentials or write permissions"
fi

unified_run_count="$(grep -Fc 'run: scripts/verify-wave0' "${workflow}")"
[[ "${unified_run_count}" == "1" ]] ||
  fail "workflow must invoke the unified verifier exactly once"

for duplicate_command in \
  "verify-source-manifest" \
  "verify-task-cards" \
  "verify-json-schemas" \
  "verify-golden-cases" \
  "verify-ui-contracts" \
  "./mvnw" \
  "pnpm build"; do
  if grep -Fq "${duplicate_command}" "${workflow}"; then
    fail "workflow duplicates unified verification command: ${duplicate_command}"
  fi
done

for strategy_contract in \
  "CIProvider = GITHUB_ACTIONS" \
  "ProductionCredentialAccess = FORBIDDEN" \
  "ProductionDatabaseWrite = FORBIDDEN" \
  "RedisLegacyLinkAccess = FORBIDDEN" \
  "CanonicalVerificationEntry = scripts/verify-wave0"; do
  grep -Fq "${strategy_contract}" "${strategy}" ||
    fail "test strategy is missing required decision: ${strategy_contract}"
done

before_hashes="$(snapshot_formal_inputs)"
fixture_root="${test_tmp_root}/source-hash-drift"
mkdir -p "${fixture_root}/docs/engineering" "${fixture_root}/raw"
cp \
  "${repo_root}/docs/engineering/cognitura-source-manifest.yaml" \
  "${fixture_root}/docs/engineering/cognitura-source-manifest.yaml"
cp \
  "${repo_root}/cognitive-knowledge-atlas-overall-design-1.2.md" \
  "${fixture_root}/cognitive-knowledge-atlas-overall-design-1.2.md"
cp "${repo_root}/raw/"*.docx "${fixture_root}/raw/"

if ! valid_output="$(
  "${unified_verifier}" --repo-root "${fixture_root}" --stage source 2>&1
)"; then
  fail "valid source fixture was rejected by unified verifier: ${valid_output}"
fi
[[ "${valid_output}" == *"Wave0Verification = PASS"* ]] ||
  fail "valid source stage did not report Wave0Verification = PASS"

printf 'X' | dd \
  of="${fixture_root}/cognitive-knowledge-atlas-overall-design-1.2.md" \
  bs=1 seek=0 count=1 conv=notrunc 2>/dev/null

if invalid_output="$(
  "${unified_verifier}" --repo-root "${fixture_root}" --stage source 2>&1
)"; then
  fail "source hash drift unexpectedly passed unified verifier"
fi
[[ "${invalid_output}" == *"HASH_MISMATCH"* ]] ||
  fail "source hash drift failed for the wrong reason: ${invalid_output}"
[[ "${invalid_output}" == *"Wave0Verification = FAIL"* ]] ||
  fail "source hash drift did not propagate to the unified verifier"

after_hashes="$(snapshot_formal_inputs)"
[[ "${after_hashes}" == "${before_hashes}" ]] ||
  fail "formal inputs changed during CI contract validation"

printf '%s\n' \
  "CiContractTests = PASS" \
  "WorkflowSafetyContract = PASS" \
  "SourceFailurePropagation = PASS" \
  "FormalInputsUnchanged = PASS"
