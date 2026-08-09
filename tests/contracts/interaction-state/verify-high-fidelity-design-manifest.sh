#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-high-fidelity-design-manifest"
manifest="${repo_root}/docs/engineering/cognitura-high-fidelity-design-manifest.yaml"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-hf-manifest.XXXXXX")"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

expect_failure() {
  local fixture_root="$1"
  local expected_message="$2"
  local output
  if output="$("${verifier}" \
    --manifest "${fixture_root}/docs/engineering/cognitura-high-fidelity-design-manifest.yaml" \
    --repo-root "${fixture_root}" 2>&1)"; then
    fail "invalid fixture unexpectedly passed: ${fixture_root}"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected error '${expected_message}', got: ${output}"
}

make_fixture() {
  local fixture_root="$1"
  mkdir -p "${fixture_root}/docs/engineering"
  cp "${manifest}" "${fixture_root}/docs/engineering/"
  cp "${repo_root}/Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md" \
    "${fixture_root}/"
}

[[ -x "${verifier}" ]] || fail "high-fidelity manifest verifier is missing or not executable"
[[ -f "${manifest}" ]] || fail "high-fidelity design manifest is missing"

canonical_output="$("${verifier}" --manifest "${manifest}" --repo-root "${repo_root}")" ||
  fail "canonical high-fidelity manifest was rejected"
for expected_line in \
  "HighFidelityDesignManifestValidation = PASS" \
  "SourceBodyManifestCoupling = REQUIRED" \
  "SourceCount = 1" \
  "SourceStatus = FORMAL_SPECIALTY_BASELINE" \
  "ReviewedPreparationSHA = 463fd4829e7c4bb8da071253e8ae9b15cee2a0cf" \
  "SourceFingerprintScope = HF-DG4_FORMAL_SPECIALTY_PROMOTION"; do
  [[ "${canonical_output}" == *"${expected_line}"* ]] ||
    fail "canonical output is missing: ${expected_line}"
done

missing_source_root="${test_tmp_root}/missing-source"
make_fixture "${missing_source_root}"
rm "${missing_source_root}/Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md"
expect_failure "${missing_source_root}" "MISSING_SOURCE"

wrong_hash_root="${test_tmp_root}/wrong-hash"
make_fixture "${wrong_hash_root}"
sed -i.bak -E 's/^    sha256: [0-9a-f]{64}$/    sha256: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/' \
  "${wrong_hash_root}/docs/engineering/cognitura-high-fidelity-design-manifest.yaml"
rm "${wrong_hash_root}/docs/engineering/cognitura-high-fidelity-design-manifest.yaml.bak"
expect_failure "${wrong_hash_root}" "SHA256_MISMATCH"

stale_size_root="${test_tmp_root}/stale-size"
make_fixture "${stale_size_root}"
printf '\n' >> \
  "${stale_size_root}/Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md"
expect_failure "${stale_size_root}" "SIZE_MISMATCH"

stale_sha_root="${test_tmp_root}/stale-sha"
make_fixture "${stale_sha_root}"
sed -i.bak 's/^CanonicalProjectName = Cognitura$/CanonicalProjectName = Cogniturx/' \
  "${stale_sha_root}/Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md"
rm "${stale_sha_root}/Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md.bak"
expect_failure "${stale_sha_root}" "SHA256_MISMATCH"

stale_candidate_status_root="${test_tmp_root}/stale-candidate-status"
make_fixture "${stale_candidate_status_root}"
sed -i.bak 's/^    status: FORMAL_SPECIALTY_BASELINE$/    status: CANDIDATE_AWAITING_REPOSITORY_GATE/' \
  "${stale_candidate_status_root}/docs/engineering/cognitura-high-fidelity-design-manifest.yaml"
rm "${stale_candidate_status_root}/docs/engineering/cognitura-high-fidelity-design-manifest.yaml.bak"
expect_failure "${stale_candidate_status_root}" "STATUS_MISMATCH"

missing_reviewed_sha_root="${test_tmp_root}/missing-reviewed-sha"
make_fixture "${missing_reviewed_sha_root}"
sed -i.bak '/^    reviewedPreparationSha: /d' \
  "${missing_reviewed_sha_root}/docs/engineering/cognitura-high-fidelity-design-manifest.yaml"
rm "${missing_reviewed_sha_root}/docs/engineering/cognitura-high-fidelity-design-manifest.yaml.bak"
expect_failure "${missing_reviewed_sha_root}" "REVIEWED_PREPARATION_SHA_MISMATCH"

mismatched_reviewed_sha_root="${test_tmp_root}/mismatched-reviewed-sha"
make_fixture "${mismatched_reviewed_sha_root}"
sed -i.bak -E 's/^    reviewedPreparationSha: [0-9a-f]{40}$/    reviewedPreparationSha: 0000000000000000000000000000000000000000/' \
  "${mismatched_reviewed_sha_root}/docs/engineering/cognitura-high-fidelity-design-manifest.yaml"
rm "${mismatched_reviewed_sha_root}/docs/engineering/cognitura-high-fidelity-design-manifest.yaml.bak"
expect_failure "${mismatched_reviewed_sha_root}" "REVIEWED_PREPARATION_SHA_MISMATCH"

stale_scope_root="${test_tmp_root}/stale-scope"
make_fixture "${stale_scope_root}"
sed -i.bak \
  's/^    fingerprintScope: HF-DG4_FORMAL_SPECIALTY_PROMOTION$/    fingerprintScope: HF-DG3_HIGH_FIDELITY_EVIDENCE_CONTRACT/' \
  "${stale_scope_root}/docs/engineering/cognitura-high-fidelity-design-manifest.yaml"
rm "${stale_scope_root}/docs/engineering/cognitura-high-fidelity-design-manifest.yaml.bak"
expect_failure "${stale_scope_root}" "FINGERPRINT_SCOPE_MISMATCH"

printf '%s\n' \
  "HighFidelityDesignManifestTests = PASS" \
  "NegativeCases = 8"
