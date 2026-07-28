#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-source-manifest"
manifest="${repo_root}/docs/engineering/cognitura-source-manifest.yaml"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-source-manifest.XXXXXX")"

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

make_fixture() {
  local fixture_root="$1"

  mkdir -p "${fixture_root}/docs/engineering" "${fixture_root}/raw"
  cp "${manifest}" "${fixture_root}/docs/engineering/cognitura-source-manifest.yaml"
  cp \
    "${repo_root}/cognitive-knowledge-atlas-overall-design-1.2.md" \
    "${fixture_root}/cognitive-knowledge-atlas-overall-design-1.2.md"
  cp "${repo_root}/raw/"*.docx "${fixture_root}/raw/"
}

expect_failure() {
  local fixture_root="$1"
  local expected_message="$2"
  local output

  if output="$(
    "${verifier}" \
      --manifest "${fixture_root}/docs/engineering/cognitura-source-manifest.yaml" \
      2>&1
  )"; then
    fail "invalid fixture unexpectedly passed: ${fixture_root}"
  fi

  if [[ "${output}" != *"${expected_message}"* ]]; then
    fail "expected error '${expected_message}', got: ${output}"
  fi
}

[[ -x "${verifier}" ]] || fail "source manifest verifier is missing or not executable"
[[ -f "${manifest}" ]] || fail "source manifest is missing"

before_hashes="$(snapshot_formal_inputs)"

if ! valid_output="$("${verifier}" --manifest "${manifest}" 2>&1)"; then
  fail "canonical source manifest was rejected: ${valid_output}"
fi

if [[ "${valid_output}" != *"SourceManifestValidation = PASS"* ]]; then
  fail "canonical validation did not report PASS: ${valid_output}"
fi

for source_id in \
  "DESIGN-OVERALL-001" \
  "GC-MYSQL-001" \
  "GC-REDIS-001" \
  "GC-ENGLISH-001"; do
  if [[ "${valid_output}" != *"Source ${source_id} = MATCH"* ]]; then
    fail "canonical validation did not report ${source_id} as MATCH"
  fi
done

hash_drift_root="${test_tmp_root}/hash-drift"
make_fixture "${hash_drift_root}"
printf 'X' | dd \
  of="${hash_drift_root}/cognitive-knowledge-atlas-overall-design-1.2.md" \
  bs=1 seek=0 count=1 conv=notrunc 2>/dev/null
expect_failure "${hash_drift_root}" "HASH_MISMATCH"

missing_file_root="${test_tmp_root}/missing-file"
make_fixture "${missing_file_root}"
rm "${missing_file_root}/raw/12-Redis中间件.docx"
expect_failure "${missing_file_root}" "MISSING_FILE"

duplicate_case_root="${test_tmp_root}/duplicate-case"
make_fixture "${duplicate_case_root}"
sed -i.bak \
  's/^    caseId: GC-REDIS-001$/    caseId: GC-MYSQL-001/' \
  "${duplicate_case_root}/docs/engineering/cognitura-source-manifest.yaml"
rm "${duplicate_case_root}/docs/engineering/cognitura-source-manifest.yaml.bak"
expect_failure "${duplicate_case_root}" "DUPLICATE_CASE_ID"

unknown_input_root="${test_tmp_root}/unknown-input"
make_fixture "${unknown_input_root}"
sed -i.bak \
  's|^    path: raw/40-英语学习.docx$|    path: raw/unknown.docx|' \
  "${unknown_input_root}/docs/engineering/cognitura-source-manifest.yaml"
rm "${unknown_input_root}/docs/engineering/cognitura-source-manifest.yaml.bak"
expect_failure "${unknown_input_root}" "UNKNOWN_FORMAL_INPUT"

missing_source_root="${test_tmp_root}/missing-source"
make_fixture "${missing_source_root}"
sed -i.bak \
  '/^  - sourceId: GC-ENGLISH-001$/,/^    sha256: /d' \
  "${missing_source_root}/docs/engineering/cognitura-source-manifest.yaml"
rm "${missing_source_root}/docs/engineering/cognitura-source-manifest.yaml.bak"
expect_failure "${missing_source_root}" "SOURCE_COUNT"

after_hashes="$(snapshot_formal_inputs)"
if [[ "${after_hashes}" != "${before_hashes}" ]]; then
  fail "formal inputs changed during source manifest validation"
fi

printf '%s\n' \
  "SourceManifestContractTests = PASS" \
  "PositiveSources = 4" \
  "NegativeCases = 5" \
  "FormalInputsUnchanged = PASS"
