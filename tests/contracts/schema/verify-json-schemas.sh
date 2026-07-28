#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH= cd -- "${TEST_DIR}/../../.." && pwd -P)"
VERIFIER="${REPO_ROOT}/scripts/verify-json-schemas"
VERIFIER_JS="${TEST_DIR}/verify-json-schemas.mjs"
EVIDENCE_MAP="${REPO_ROOT}/schemas/evidence-map.json"

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

RENDERED_MAP="$(mktemp "${TMPDIR:-/tmp}/cognitura-evidence-map.XXXXXX")"
cleanup() {
  rm -f -- "${RENDERED_MAP}"
}
trap cleanup EXIT

node "${VERIFIER_JS}" --render-evidence-map | cat > "${RENDERED_MAP}"
node -e '
  const fs = require("node:fs");
  const [renderedPath, expectedPath] = process.argv.slice(1);
  const rendered = fs.readFileSync(renderedPath);
  const expected = fs.readFileSync(expectedPath);
  JSON.parse(rendered.toString("utf8"));
  if (!rendered.equals(expected)) {
    process.exitCode = 1;
  }
' "${RENDERED_MAP}" "${EVIDENCE_MAP}" ||
  fail "rendered evidence map is invalid or differs from schemas/evidence-map.json"

printf '%s\n' "EvidenceMapRenderRoundTrip = PASS"
