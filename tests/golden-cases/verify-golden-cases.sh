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
    "${fixture_root}/tests/golden-cases/results" \
    "${fixture_root}/raw"
  cp \
    "${repo_root}/docs/engineering/cognitura-source-manifest.yaml" \
    "${fixture_root}/docs/engineering/cognitura-source-manifest.yaml"
  cp \
    "${repo_root}/test-data/golden-cases/"*.yaml \
    "${fixture_root}/test-data/golden-cases/"
  cp \
    "${repo_root}/tests/golden-cases/results/"*.yaml \
    "${fixture_root}/tests/golden-cases/results/"
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

expect_result_failure() {
  local expected_file="$1"
  local result_file="$2"
  local expected_message="$3"
  local output

  if output="$(
    "${verifier}" \
      --assert-result \
      --expected "${expected_file}" \
      --result "${result_file}" \
      2>&1
  )"; then
    fail "invalid result unexpectedly passed: ${result_file}"
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
  "ExternalAccessGuard = ACTIVE" \
  "W0-G4 GoldenCaseRegression = PASS"; do
  [[ "${valid_output}" == *"${expected}"* ]] ||
    fail "missing verifier output: ${expected}"
done

result_positive_count=0
for case_name in mysql redis english; do
  expected_file="${repo_root}/test-data/golden-cases/${case_name}.expected.yaml"
  result_file="${repo_root}/tests/golden-cases/results/${case_name}.result.yaml"
  if ! result_output="$(
    "${verifier}" \
      --assert-result \
      --expected "${expected_file}" \
      --result "${result_file}" \
      2>&1
  )"; then
    fail "valid ${case_name} result was rejected: ${result_output}"
  fi
  [[ "${result_output}" == *"ResultAssertion = PASS"* ]] ||
    fail "missing result assertion PASS for ${case_name}"
  [[ "${result_output}" == *"ExecutableAssertionGroupCount = 8"* ]] ||
    fail "missing assertion group count for ${case_name}"
  result_positive_count=$((result_positive_count + 1))
done

result_negative_root="${test_tmp_root}/result-negatives"
mkdir -p "${result_negative_root}"

cp \
  "${repo_root}/tests/golden-cases/results/mysql.result.yaml" \
  "${result_negative_root}/missing-include.yaml"
sed -i.bak \
  's/^IncludedConcepts: .*$/IncludedConcepts: 锁|事务/' \
  "${result_negative_root}/missing-include.yaml"
rm -f -- "${result_negative_root}/missing-include.yaml.bak"
expect_result_failure \
  "${repo_root}/test-data/golden-cases/mysql.expected.yaml" \
  "${result_negative_root}/missing-include.yaml" \
  "MUST_INCLUDE_VIOLATION"

cp \
  "${repo_root}/tests/golden-cases/results/redis.result.yaml" \
  "${result_negative_root}/wrong-merge.yaml"
sed -i.bak \
  's/^MergeTarget: .*$/MergeTarget: 孤立模块/' \
  "${result_negative_root}/wrong-merge.yaml"
rm -f -- "${result_negative_root}/wrong-merge.yaml.bak"
expect_result_failure \
  "${repo_root}/test-data/golden-cases/redis.expected.yaml" \
  "${result_negative_root}/wrong-merge.yaml" \
  "MUST_MERGE_VIOLATION"

cp \
  "${repo_root}/tests/golden-cases/results/english.result.yaml" \
  "${result_negative_root}/split-members.yaml"
sed -i.bak \
  's/^StandaloneModules: NONE$/StandaloneModules: 主+谓|主+系+表/' \
  "${result_negative_root}/split-members.yaml"
rm -f -- "${result_negative_root}/split-members.yaml.bak"
expect_result_failure \
  "${repo_root}/test-data/golden-cases/english.expected.yaml" \
  "${result_negative_root}/split-members.yaml" \
  "MUST_NOT_SPLIT_VIOLATION"

cp \
  "${repo_root}/tests/golden-cases/results/mysql.result.yaml" \
  "${result_negative_root}/promote-all.yaml"
sed -i.bak \
  's/^PromotedModules: .*$/PromotedModules: MVCC|Read View字段|隐藏列|单个锁类型/' \
  "${result_negative_root}/promote-all.yaml"
rm -f -- "${result_negative_root}/promote-all.yaml.bak"
expect_result_failure \
  "${repo_root}/test-data/golden-cases/mysql.expected.yaml" \
  "${result_negative_root}/promote-all.yaml" \
  "MUST_NOT_PROMOTE_VIOLATION"

cp \
  "${repo_root}/tests/golden-cases/results/mysql.result.yaml" \
  "${result_negative_root}/invented-role.yaml"
sed -i.bak \
  's/^Role: NOT_ASSERTED$/Role: CORE_MODULE/' \
  "${result_negative_root}/invented-role.yaml"
rm -f -- "${result_negative_root}/invented-role.yaml.bak"
expect_result_failure \
  "${repo_root}/test-data/golden-cases/mysql.expected.yaml" \
  "${result_negative_root}/invented-role.yaml" \
  "EXPECTED_ROLE_VIOLATION"

cp \
  "${repo_root}/tests/golden-cases/results/english.result.yaml" \
  "${result_negative_root}/wrong-spine.yaml"
sed -i.bak \
  's/^Spine: .*$/Spine: 五大句型|例句/' \
  "${result_negative_root}/wrong-spine.yaml"
rm -f -- "${result_negative_root}/wrong-spine.yaml.bak"
expect_result_failure \
  "${repo_root}/test-data/golden-cases/english.expected.yaml" \
  "${result_negative_root}/wrong-spine.yaml" \
  "EXPECTED_SPINE_VIOLATION"

cp \
  "${repo_root}/tests/golden-cases/results/redis.result.yaml" \
  "${result_negative_root}/invented-closure.yaml"
sed -i.bak \
  's/^ThemeClosure: NOT_ASSERTED$/ThemeClosure: COMPLETE/' \
  "${result_negative_root}/invented-closure.yaml"
rm -f -- "${result_negative_root}/invented-closure.yaml.bak"
expect_result_failure \
  "${repo_root}/test-data/golden-cases/redis.expected.yaml" \
  "${result_negative_root}/invented-closure.yaml" \
  "EXPECTED_THEME_CLOSURE_VIOLATION"

cp \
  "${repo_root}/tests/golden-cases/results/mysql.result.yaml" \
  "${result_negative_root}/missing-gap.yaml"
sed -i.bak \
  's/|EXPECTED_SPINE_NOT_SPECIFIED//' \
  "${result_negative_root}/missing-gap.yaml"
rm -f -- "${result_negative_root}/missing-gap.yaml.bak"
expect_result_failure \
  "${repo_root}/test-data/golden-cases/mysql.expected.yaml" \
  "${result_negative_root}/missing-gap.yaml" \
  "KNOWN_SOURCE_GAPS_VIOLATION"

hash_drift_root="${test_tmp_root}/hash-drift"
make_fixture "${hash_drift_root}"
printf 'X' >> "${hash_drift_root}/raw/11-MySQL数据库.docx"
expect_failure "${hash_drift_root}" "HASH_MISMATCH"

symlink_escape_root="${test_tmp_root}/symlink-escape"
make_fixture "${symlink_escape_root}"
escaped_mysql="${test_tmp_root}/escaped-mysql.docx"
mv \
  "${symlink_escape_root}/raw/11-MySQL数据库.docx" \
  "${escaped_mysql}"
ln -s \
  "${escaped_mysql}" \
  "${symlink_escape_root}/raw/11-MySQL数据库.docx"
expect_failure "${symlink_escape_root}" "SOURCE_PATH_REALPATH"

raw_symlink_escape_root="${test_tmp_root}/raw-symlink-escape"
make_fixture "${raw_symlink_escape_root}"
mkdir -p "${raw_symlink_escape_root}/other"
mv \
  "${raw_symlink_escape_root}/raw/11-MySQL数据库.docx" \
  "${raw_symlink_escape_root}/other/mysql.docx"
ln -s \
  "${raw_symlink_escape_root}/other/mysql.docx" \
  "${raw_symlink_escape_root}/raw/11-MySQL数据库.docx"
expect_failure \
  "${raw_symlink_escape_root}" \
  "SOURCE_PATH_SYMLINK"

zip_limit_root="${test_tmp_root}/zip-limit"
make_fixture "${zip_limit_root}"
java "${mutator}" \
  inflate-document-xml \
  "${zip_limit_root}/raw/11-MySQL数据库.docx"
refresh_fixture_hash \
  "${zip_limit_root}" \
  "GC-MYSQL-001" \
  "raw/11-MySQL数据库.docx" \
  "mysql.expected.yaml"
expect_failure "${zip_limit_root}" "DOCX_ENTRY_LIMIT"

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

page_order_root="${test_tmp_root}/page-order"
make_fixture "${page_order_root}"
java "${mutator}" \
  move-first-page-marker \
  "${page_order_root}/raw/11-MySQL数据库.docx"
refresh_fixture_hash \
  "${page_order_root}" \
  "GC-MYSQL-001" \
  "raw/11-MySQL数据库.docx" \
  "mysql.expected.yaml"
expect_failure "${page_order_root}" "PAGE_OR_ORDER_MISMATCH"

external_target_root="${test_tmp_root}/external-target"
make_fixture "${external_target_root}"
java "${mutator}" \
  rewrite-first-external-target \
  "${external_target_root}/raw/12-Redis中间件.docx"
refresh_fixture_hash \
  "${external_target_root}" \
  "GC-REDIS-001" \
  "raw/12-Redis中间件.docx" \
  "redis.expected.yaml"
expect_failure \
  "${external_target_root}" \
  "EXTERNAL_RELATIONSHIP_MISMATCH"

access_probe_root="${test_tmp_root}/access-probe"
mkdir -p "${access_probe_root}"
printf 'must-not-be-read\n' > "${access_probe_root}/canary.txt"
if access_probe_output="$(
  "${verifier}" \
    --probe-file-access \
    "${repo_root}/raw/12-Redis中间件.docx" \
    "${access_probe_root}/canary.txt" \
    2>&1
)"; then
  fail "external access guard allowed the canary read"
fi
[[ "${access_probe_output}" == *"EXTERNAL_LINK_ACCESS"* ]] ||
  fail "external access guard did not report its access attempt"

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
  "PositiveResultFixtures = ${result_positive_count}" \
  "AssertionNegativeCases = 8" \
  "BaselineNegativeCases = 13" \
  "AccessIsolationNegativeCases = 1" \
  "NegativeCases = 22" \
  "FormalInputsUnchanged = PASS"
