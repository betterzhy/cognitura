#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-golden-cases"
mutator="${repo_root}/tests/golden-cases/DocxFixtureMutator.java"
manifest="${repo_root}/test-data/golden-cases/manifest.yaml"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-golden-cases.XXXXXX")"

cleanup() {
  rm -rf -- "${test_tmp_root}"
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

snapshot_originals() {
  local path

  for path in \
    "raw/11-MySQL数据库.docx" \
    "raw/12-Redis中间件.docx" \
    "raw/40-英语学习.docx"; do
    printf '%s|%s\n' "${path}" "$(hash_file "${repo_root}/${path}")"
  done
}

make_fixture() {
  local fixture_root="$1"

  mkdir -p \
    "${fixture_root}/docs/engineering" \
    "${fixture_root}/test-data/golden-cases" \
    "${fixture_root}/raw"
  cp \
    "${repo_root}/docs/engineering/cognitura-source-manifest.yaml" \
    "${fixture_root}/docs/engineering/cognitura-source-manifest.yaml"
  cp \
    "${repo_root}/test-data/golden-cases/"*.yaml \
    "${fixture_root}/test-data/golden-cases/"
  cp "${repo_root}/raw/"*.docx "${fixture_root}/raw/"
}

refresh_fixture_hash() {
  local fixture_root="$1"
  local case_id="$2"
  local relative_path="$3"
  local expected_name="$4"
  local old_hash
  local new_hash
  local file

  old_hash="$(
    awk -F ': ' -v key="${case_id}.SourceSha256" \
      '$1 == key { print $2 }' \
      "${fixture_root}/test-data/golden-cases/manifest.yaml"
  )"
  new_hash="$(hash_file "${fixture_root}/${relative_path}")"

  for file in \
    "${fixture_root}/docs/engineering/cognitura-source-manifest.yaml" \
    "${fixture_root}/test-data/golden-cases/manifest.yaml" \
    "${fixture_root}/test-data/golden-cases/${expected_name}"; do
    sed -i.bak "s/${old_hash}/${new_hash}/g" "${file}"
    rm -f -- "${file}.bak"
  done
}

expect_failure() {
  local fixture_root="$1"
  local expected_message="$2"
  local output

  if output="$(
    "${verifier}" \
      --manifest "${fixture_root}/test-data/golden-cases/manifest.yaml" \
      2>&1
  )"; then
    fail "invalid fixture unexpectedly passed: ${fixture_root}"
  fi
  if [[ "${output}" != *"${expected_message}"* ]]; then
    fail "expected '${expected_message}', got: ${output}"
  fi
}

[[ -x "${verifier}" ]] || fail "golden case verifier is missing or not executable"
[[ -f "${mutator}" ]] || fail "DOCX fixture mutator is missing"
[[ -f "${manifest}" ]] || fail "golden case manifest is missing"

before_hashes="$(snapshot_originals)"

if ! valid_output="$("${verifier}" --manifest "${manifest}" 2>&1)"; then
  fail "canonical golden cases were rejected: ${valid_output}"
fi
for expected in \
  "GoldenCaseRegression = PASS" \
  "CaseCount = 3" \
  "ExecutableAssertionGroupCount = 24" \
  "StructuralBaselineCount = 3" \
  "ExternalLinksObserved = 4" \
  "ExternalLinksAccessed = 0" \
  "W0-G4 GoldenCaseRegression = PASS"; do
  [[ "${valid_output}" == *"${expected}"* ]] ||
    fail "missing verifier output: ${expected}"
done

hash_drift_root="${test_tmp_root}/hash-drift"
make_fixture "${hash_drift_root}"
printf 'X' >> "${hash_drift_root}/raw/11-MySQL数据库.docx"
expect_failure "${hash_drift_root}" "HASH_MISMATCH"

heading_order_root="${test_tmp_root}/heading-order"
make_fixture "${heading_order_root}"
java "${mutator}" \
  swap-headings \
  "${heading_order_root}/raw/11-MySQL数据库.docx"
refresh_fixture_hash \
  "${heading_order_root}" \
  "GC-MYSQL-001" \
  "raw/11-MySQL数据库.docx" \
  "mysql.expected.yaml"
expect_failure "${heading_order_root}" "HEADING_ORDER_MISMATCH"

paragraph_order_root="${test_tmp_root}/paragraph-order"
make_fixture "${paragraph_order_root}"
java "${mutator}" \
  swap-paragraphs \
  "${paragraph_order_root}/raw/12-Redis中间件.docx"
refresh_fixture_hash \
  "${paragraph_order_root}" \
  "GC-REDIS-001" \
  "raw/12-Redis中间件.docx" \
  "redis.expected.yaml"
expect_failure "${paragraph_order_root}" "BLOCK_ORDER_MISMATCH"

table_loss_root="${test_tmp_root}/table-loss"
make_fixture "${table_loss_root}"
java "${mutator}" \
  remove-first-table \
  "${table_loss_root}/raw/40-英语学习.docx"
refresh_fixture_hash \
  "${table_loss_root}" \
  "GC-ENGLISH-001" \
  "raw/40-英语学习.docx" \
  "english.expected.yaml"
expect_failure "${table_loss_root}" "TABLE_STRUCTURE_MISMATCH"

image_loss_root="${test_tmp_root}/image-loss"
make_fixture "${image_loss_root}"
java "${mutator}" \
  remove-first-image-reference \
  "${image_loss_root}/raw/11-MySQL数据库.docx"
refresh_fixture_hash \
  "${image_loss_root}" \
  "GC-MYSQL-001" \
  "raw/11-MySQL数据库.docx" \
  "mysql.expected.yaml"
expect_failure "${image_loss_root}" "IMAGE_REFERENCE_MISMATCH"

link_policy_root="${test_tmp_root}/link-policy"
make_fixture "${link_policy_root}"
sed -i.bak \
  's/^ExternalRelationshipPolicy: RECORD_ONLY_DO_NOT_RESOLVE$/ExternalRelationshipPolicy: RESOLVE/' \
  "${link_policy_root}/test-data/golden-cases/redis.expected.yaml"
rm -f -- "${link_policy_root}/test-data/golden-cases/redis.expected.yaml.bak"
expect_failure "${link_policy_root}" "EXTERNAL_LINK_POLICY"

assertion_policy_root="${test_tmp_root}/assertion-policy"
make_fixture "${assertion_policy_root}"
sed -i.bak \
  's/^MustNotPromote: MVCC|Read View字段|隐藏列|单个锁类型$/MustNotPromote: MVCC/' \
  "${assertion_policy_root}/test-data/golden-cases/mysql.expected.yaml"
rm -f -- "${assertion_policy_root}/test-data/golden-cases/mysql.expected.yaml.bak"
expect_failure "${assertion_policy_root}" "ASSERTION_POLICY_MISMATCH"

duplicate_case_root="${test_tmp_root}/duplicate-case"
make_fixture "${duplicate_case_root}"
sed -i.bak \
  's/^CaseOrder: GC-MYSQL-001|GC-REDIS-001|GC-ENGLISH-001$/CaseOrder: GC-MYSQL-001|GC-MYSQL-001|GC-ENGLISH-001/' \
  "${duplicate_case_root}/test-data/golden-cases/manifest.yaml"
rm -f -- "${duplicate_case_root}/test-data/golden-cases/manifest.yaml.bak"
expect_failure "${duplicate_case_root}" "DUPLICATE_CASE_ID"

after_hashes="$(snapshot_originals)"
[[ "${after_hashes}" == "${before_hashes}" ]] ||
  fail "formal Golden Case originals changed during verification"

printf '%s\n' \
  "GoldenCaseContractTests = PASS" \
  "PositiveCases = 3" \
  "NegativeCases = 8" \
  "FormalInputsUnchanged = PASS"
