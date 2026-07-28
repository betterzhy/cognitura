#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH= cd -- "${TEST_DIR}/../../.." && pwd -P)"
VERIFIER="${REPO_ROOT}/scripts/verify-json-schemas"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -x "${VERIFIER}" ]] || fail "schema verifier is missing or not executable"

OUTPUT="$("${VERIFIER}")"
printf '%s\n' "${OUTPUT}"

EXPECTED_LINES=(
  "JsonSchemaValidation = PASS"
  "SchemaDocumentCount = 14"
  "InstantiableSchemaCount = 13"
  "ValidFixtureCount = 13"
  "InvalidFixtureCount = 18"
  "SemanticValidContextCount = 2"
  "NonPublishedModuleNullability = PASS"
  "SemanticNegativeCaseCount = 34"
  "SemanticViolationCodeCount = 68"
  "EvidenceMapSchemaEntryCount = 645"
  "EvidenceMapSemanticEntryCount = 16"
  "EvidenceMapEntryCount = 661"
  "EvidenceMapNegativeCaseCount = 6"
  "EvidenceMapValidation = PASS"
  "NetworkResolution = FORBIDDEN"
  "W0-G3 JsonSchemaValidation = PASS"
)

for expected in "${EXPECTED_LINES[@]}"; do
  grep -Fqx -- "${expected}" <<<"${OUTPUT}" ||
    fail "missing verifier output: ${expected}"
done
