#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-visual-style-baseline-cards"
cards_dir="${repo_root}/docs/task-cards/visual-style-baseline"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-vsb-cards.XXXXXX")"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

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

set_field() {
  local file="$1"
  local field="$2"
  local value="$3"
  sed -i.bak "s#^${field} = .*\$#${field} = ${value}#" "${file}"
  rm "${file}.bak"
}

expect_failure() {
  local fixture_dir="$1"
  local expected_message="$2"
  local output
  if output="$(
    "${verifier}" \
      --repo-root "${repo_root}" \
      --cards-dir "${fixture_dir}" 2>&1
  )"; then
    fail "invalid fixture unexpectedly passed: ${fixture_dir}"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "expected error '${expected_message}', got: ${output}"
  negative_cases=$((negative_cases + 1))
}

# Required RED: the verifier and governed set do not exist before Task 1.
[[ -x "${verifier}" ]] || fail "Visual Style Baseline task-card verifier is missing or not executable"
[[ -d "${cards_dir}" ]] || fail "Visual Style Baseline task-card set is missing"

validation_output="$(
  "${verifier}" \
    --repo-root "${repo_root}" \
    --cards-dir "${cards_dir}"
)" || fail "canonical Visual Style Baseline bootstrap state was rejected"
assert_contains "${validation_output}" "VisualStyleBaselineTaskCardValidation = PASS"
assert_contains "${validation_output}" "TaskCardCount = 4"
assert_contains \
  "${validation_output}" \
  "TaskCardSetStatus = USER_AUTHORIZED_AWAITING_GOVERNANCE_REVIEW"

negative_cases=0

missing_state_dir="${test_tmp_root}/missing-state"
cp -R "${cards_dir}" "${missing_state_dir}"
rm "${missing_state_dir}/execution-state.md"
expect_failure "${missing_state_dir}" "execution-state.md is missing"

for field in ApprovedSpecSHA FrozenWave1CandidateSHA TaskCardSetStatus ActiveTaskCard \
  ReleasedTaskCard CompletedTaskCards CurrentCandidateSHA CurrentGateStatus \
  CurrentReviewRoute CurrentReviewVerdict TransitionSequence TransitionKind \
  TransitionBaseSHA VSB00CandidateSHA VSB00GateStatus VSB00ReviewVerdict \
  VSB01CandidateSHA VSB01GateStatus VSB01ReviewVerdict VSB02CandidateSHA \
  VSB02GateStatus VSB02ReviewVerdict VSB03CandidateSHA VSB03GateStatus \
  VSB03DeepReviewVerdict VSB03UltraReviewVerdict; do
  missing_field_dir="${test_tmp_root}/missing-${field}"
  cp -R "${cards_dir}" "${missing_field_dir}"
  sed -i.bak "/^${field} = /d" "${missing_field_dir}/execution-state.md"
  rm "${missing_field_dir}/execution-state.md.bak"
  expect_failure "${missing_field_dir}" "${field} must occur exactly once"

  duplicate_field_dir="${test_tmp_root}/duplicate-${field}"
  cp -R "${cards_dir}" "${duplicate_field_dir}"
  value="$(sed -n "s/^${field} = //p" "${duplicate_field_dir}/execution-state.md")"
  printf '%s = %s\n' "${field}" "${value}" >> \
    "${duplicate_field_dir}/execution-state.md"
  expect_failure "${duplicate_field_dir}" "${field} must occur exactly once"
done

fifth_card_dir="${test_tmp_root}/fifth-card"
cp -R "${cards_dir}" "${fifth_card_dir}"
cp "${fifth_card_dir}/VSB-03-fixed-visual-acceptance.md" \
  "${fifth_card_dir}/VSB-04-invented.md"
set_field "${fifth_card_dir}/VSB-04-invented.md" "TaskCardID" "VSB-04"
expect_failure "${fifth_card_dir}" "actual task card count 5 does not match 4"

unknown_id_dir="${test_tmp_root}/unknown-id"
cp -R "${cards_dir}" "${unknown_id_dir}"
set_field "${unknown_id_dir}/VSB-02-module-default-reading-visual.md" "TaskCardID" "VSB-99"
expect_failure "${unknown_id_dir}" "TaskCardID mismatch"

mutable_status_dir="${test_tmp_root}/mutable-status"
cp -R "${cards_dir}" "${mutable_status_dir}"
set_field "${mutable_status_dir}/VSB-01-semantic-tokens.md" "Status" "READY"
expect_failure "${mutable_status_dir}" "Status must be GOVERNED_BY_EXECUTION_STATE"

card_body_drift_dir="${test_tmp_root}/card-body-drift"
cp -R "${cards_dir}" "${card_body_drift_dir}"
printf '\nunauthorized body drift\n' >> \
  "${card_body_drift_dir}/VSB-01-semantic-tokens.md"
expect_failure "${card_body_drift_dir}" "card body contract digest mismatch for VSB-01"

wrong_spec_dir="${test_tmp_root}/wrong-spec"
cp -R "${cards_dir}" "${wrong_spec_dir}"
set_field "${wrong_spec_dir}/execution-state.md" "ApprovedSpecSHA" \
  "4e63936c631ab34807e714b90d30415a959bc13d"
expect_failure "${wrong_spec_dir}" "ApprovedSpecSHA mismatch"

wrong_frozen_dir="${test_tmp_root}/wrong-frozen"
cp -R "${cards_dir}" "${wrong_frozen_dir}"
set_field "${wrong_frozen_dir}/execution-state.md" "FrozenWave1CandidateSHA" \
  "70eefba5912e6884e4e7e1d6477a65f4091d6590"
expect_failure "${wrong_frozen_dir}" "FrozenWave1CandidateSHA mismatch"

premature_activation_dir="${test_tmp_root}/premature-activation"
cp -R "${cards_dir}" "${premature_activation_dir}"
set_field "${premature_activation_dir}/execution-state.md" "TaskCardSetStatus" "IN_PROGRESS"
set_field "${premature_activation_dir}/execution-state.md" "ActiveTaskCard" "VSB-00"
set_field "${premature_activation_dir}/execution-state.md" "ReleasedTaskCard" "VSB-00"
set_field "${premature_activation_dir}/execution-state.md" "NextTaskCard" "VSB-01"
set_field "${premature_activation_dir}/execution-state.md" "TransitionSequence" "1"
set_field "${premature_activation_dir}/execution-state.md" "TransitionKind" "ACTIVATE_SET"
set_field "${premature_activation_dir}/execution-state.md" "VisualImplementation" "USER_AUTHORIZED"
expect_failure "${premature_activation_dir}" "activation requires governance zero-finding GO"

for receipt_field in VSB00CandidateSHA VSB00GateStatus VSB00ReviewVerdict \
  VSB01CandidateSHA VSB01GateStatus VSB01ReviewVerdict VSB02CandidateSHA \
  VSB02GateStatus VSB02ReviewVerdict VSB03CandidateSHA VSB03GateStatus \
  VSB03DeepReviewVerdict VSB03UltraReviewVerdict; do
  overwritten_receipt_dir="${test_tmp_root}/overwritten-${receipt_field}"
  cp -R "${cards_dir}" "${overwritten_receipt_dir}"
  set_field "${overwritten_receipt_dir}/execution-state.md" "${receipt_field}" "FORGED"
  expect_failure "${overwritten_receipt_dir}" "bootstrap receipts must remain NONE or NOT_RUN"
done

two_active_dir="${test_tmp_root}/two-active"
cp -R "${premature_activation_dir}" "${two_active_dir}"
set_field "${two_active_dir}/execution-state.md" "ActiveTaskCard" "VSB-00,VSB-01"
expect_failure "${two_active_dir}" "ActiveTaskCard must name one known card or NONE"

skipped_prefix_dir="${test_tmp_root}/skipped-prefix"
cp -R "${premature_activation_dir}" "${skipped_prefix_dir}"
set_field "${skipped_prefix_dir}/execution-state.md" "CompletedTaskCards" "VSB-01"
expect_failure "${skipped_prefix_dir}" "CompletedTaskCards must be an exact card prefix"

for forbidden_literal in \
  'WriteSet = server/forbidden.java' \
  'WriteSet = schemas/forbidden.json' \
  'WriteSet = raw/forbidden.docx' \
  'WriteSet = web/src/App.tsx' \
  'WriteSet = web/src/main.tsx' \
  'WriteSet = web/src/routes/forbidden.tsx' \
  'WriteSet = docs/design/high-fidelity/evidence/forbidden.png' \
  'WriteSet = .idea/workspace.xml' \
  'WriteSet = FORMAL_DATABASE_WRITE' \
  'WriteSet = REMOTE_PUSH'; do
  slug="$(printf '%s' "${forbidden_literal}" | shasum -a 256 | cut -c1-8)"
  forbidden_dir="${test_tmp_root}/forbidden-${slug}"
  cp -R "${cards_dir}" "${forbidden_dir}"
  printf '%s\n' "${forbidden_literal}" >> \
    "${forbidden_dir}/VSB-02-module-default-reading-visual.md"
  expect_failure "${forbidden_dir}" "card body contract digest mismatch for VSB-02"
done

wave1_not_suspended_dir="${test_tmp_root}/wave1-not-suspended"
cp -R "${premature_activation_dir}" "${wave1_not_suspended_dir}"
set_field "${wave1_not_suspended_dir}/execution-state.md" \
  "GovernanceBootstrapStatus" "PASS"
set_field "${wave1_not_suspended_dir}/execution-state.md" \
  "GovernanceReviewedCandidateSHA" "70eefba5912e6884e4e7e1d6477a65f4091d6590"
set_field "${wave1_not_suspended_dir}/execution-state.md" \
  "GovernanceReviewVerdict" "GO_P0_0_P1_0_P2_0"
wave1_projection_root="${test_tmp_root}/wave1-projection-root"
git clone --shared -q "${repo_root}" "${wave1_projection_root}"
mkdir -p "${wave1_projection_root}/docs/task-cards/visual-style-baseline"
cp -R "${wave1_not_suspended_dir}/." \
  "${wave1_projection_root}/docs/task-cards/visual-style-baseline/"
mkdir -p "${wave1_projection_root}/docs/task-cards/wave-1-implementation"
cp -R "${repo_root}/docs/task-cards/wave-1-implementation/." \
  "${wave1_projection_root}/docs/task-cards/wave-1-implementation/"
wave1_projection_index="${wave1_projection_root}/docs/task-cards/wave-1-implementation/README.md"
wave1_projection_card="${wave1_projection_root}/docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md"
set_field "${wave1_projection_index}" "TaskCardSetStatus" "READY_FOR_EXECUTION"
set_field "${wave1_projection_index}" "ActiveTaskCard" "W1-I03"
set_field "${wave1_projection_index}" "SuspendedTaskCard" "NONE"
set_field "${wave1_projection_index}" "SuspendedCandidateSHA" "NONE"
set_field "${wave1_projection_index}" "SuspendedCandidateMutation" "NONE"
set_field "${wave1_projection_card}" "Status" "READY"
wave1_projection_output="$(
  "${verifier}" \
    --repo-root "${wave1_projection_root}" \
    --cards-dir "${wave1_projection_root}/docs/task-cards/visual-style-baseline" 2>&1
)" && fail "VSB in progress unexpectedly accepted restored Wave 1"
assert_contains "${wave1_projection_output}" "VSB in progress requires exact W1-I03 suspension"
negative_cases=$((negative_cases + 1))

# Real Git state transitions: candidate commits may contain business files, but
# every release/rollback/complete receipt is a direct child that changes only
# execution-state.md.
transition_repo_root="${test_tmp_root}/transition-repo"
git clone --shared -q "${repo_root}" "${transition_repo_root}"
mkdir -p "${transition_repo_root}/docs/task-cards/visual-style-baseline"
cp -R "${cards_dir}/." \
  "${transition_repo_root}/docs/task-cards/visual-style-baseline/"
mkdir -p "${transition_repo_root}/docs/task-cards/wave-1-implementation"
cp -R "${repo_root}/docs/task-cards/wave-1-implementation/." \
  "${transition_repo_root}/docs/task-cards/wave-1-implementation/"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline \
  docs/task-cards/wave-1-implementation
git -C "${transition_repo_root}" commit --allow-empty -qm \
  "test: establish VSB bootstrap fixture"

transition_cards="${transition_repo_root}/docs/task-cards/visual-style-baseline"
transition_state="${transition_cards}/execution-state.md"
candidate_write_sets=(
  'AGENTS.md
docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png
docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md
docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md
docs/engineering/cognitura-design-index.md
docs/engineering/cognitura-visual-style-baseline-manifest.yaml
scripts/import-visual-style-reference
scripts/verify-visual-style-baseline-reference
tests/visual-style-baseline/verify-reference.sh'
  'web/src/styles/tokens.css
web/src/styles/typography.css
web/src/styles/surfaces.css
web/src/styles/cognitive-visual.css
web/src/styles/cognitura.css
web/src/styles/style-contract.test.ts
scripts/verify-module-default-reading
tests/visual-style-baseline/verify-module-default-reading-toolchain.sh'
  'web/src/modules/module-reading/ModuleDefaultReading.tsx
web/src/modules/module-reading/ModuleDefaultReading.test.tsx
web/src/modules/module-reading/ModuleNarrative.tsx
web/src/modules/module-reading/ModuleNarrative.test.tsx
web/src/modules/module-reading/StageChainProjection.tsx
web/src/modules/module-reading/StageChainProjection.test.tsx
web/src/modules/module-reading/ModuleClosure.tsx
web/src/modules/module-reading/ModuleClosure.test.tsx
web/src/modules/module-reading/KeyRelations.tsx
web/src/modules/module-reading/KeyRelations.test.tsx
web/src/modules/module-reading/SourceEntry.tsx
web/src/modules/module-reading/SourceEntry.test.tsx
web/src/modules/module-reading/module-default-reading.css
web/vite.config.mjs
web/visual-reference.html
web/src/visual-reference/main.tsx
web/src/visual-reference/VisualReference.tsx
web/src/visual-reference/VisualReference.test.tsx
web/src/visual-reference/module-default-reading.fixture.ts
web/src/visual-reference/visual-reference.css'
  'scripts/capture-visual-style-baseline
scripts/verify-visual-style-baseline
tests/visual-style-baseline/browser-probe.html
tests/visual-style-baseline/browser-runtime-guard.js
tests/visual-style-baseline/reference-comparison.html
tests/visual-style-baseline/verify-visual-style-baseline.sh
docs/design/visual-style-baseline/evidence/README.md
docs/design/visual-style-baseline/evidence/module-default-reading-1440x1100.png
docs/design/visual-style-baseline/evidence/module-default-reading-1280x960.png
docs/design/visual-style-baseline/evidence/module-default-reading-1024x900.png
docs/design/visual-style-baseline/evidence/reference-comparison.png
docs/engineering/cognitura-visual-style-baseline-acceptance.md'
)

write_exact_candidate_paths() {
  local fixture_root="$1"
  local owner_index="$2"
  local marker="$3"
  local candidate_path
  while IFS= read -r candidate_path; do
    mkdir -p "${fixture_root}/$(dirname "${candidate_path}")"
    if [[ -f "${fixture_root}/${candidate_path}" ]]; then
      printf '\n%s\n' "${marker}" >> "${fixture_root}/${candidate_path}"
    else
      printf '%s\n' "${marker}" > "${fixture_root}/${candidate_path}"
    fi
  done <<< "${candidate_write_sets[${owner_index}]}"
}
printf '%s\n' 'fixed governance review input' > \
  "${transition_cards}/governance-review-input.md"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/governance-review-input.md
git -C "${transition_repo_root}" commit -qm "test: create VSB governance candidate"
governance_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"

set_field "${transition_state}" "GovernanceBootstrapStatus" "PASS"
set_field "${transition_state}" "GovernanceReviewedCandidateSHA" "${governance_candidate_sha}"
set_field "${transition_state}" "GovernanceReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "TaskCardSetStatus" "IN_PROGRESS"
set_field "${transition_state}" "ActiveTaskCard" "VSB-00"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-00"
set_field "${transition_state}" "NextTaskCard" "VSB-01"
set_field "${transition_state}" "TransitionSequence" "1"
set_field "${transition_state}" "TransitionKind" "ACTIVATE_SET"
set_field "${transition_state}" "TransitionBaseSHA" "${governance_candidate_sha}"
set_field "${transition_state}" "VisualImplementation" "USER_AUTHORIZED"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm "test: activate VSB fixture"
activation_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" \
  --transition-base "${governance_candidate_sha}" \
  --transition-head "${activation_sha}" >/dev/null ||
  fail "valid VSB activation transition was rejected"

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"

git -C "${transition_repo_root}" switch -q --detach "${governance_candidate_sha}"
set_field "${transition_state}" "TaskCardSetStatus" "STOPPED_BY_USER"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "CurrentGateStatus" "STOPPED_BY_USER"
set_field "${transition_state}" "CurrentReviewRoute" "NONE"
set_field "${transition_state}" "CurrentReviewVerdict" "NOT_APPLICABLE_USER_STOP"
set_field "${transition_state}" "TransitionSequence" "1"
set_field "${transition_state}" "TransitionKind" "STOP_BY_USER"
set_field "${transition_state}" "TransitionBaseSHA" "${governance_candidate_sha}"
set_field "${transition_state}" "VisualImplementation" "STOPPED_BY_USER"
set_field "${transition_state}" "UserStopAuthorization" "EXPLICIT_USER_INSTRUCTION"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: stop VSB before activation"
illegal_stop_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if illegal_stop_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${governance_candidate_sha}" \
    --transition-head "${illegal_stop_sha}" 2>&1
)"; then
  fail "STOP_BY_USER from an inactive bootstrap state unexpectedly passed"
fi
assert_contains "${illegal_stop_output}" \
  "STOP_BY_USER must start from IN_PROGRESS or FINAL_NO_GO"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
set_field "${transition_state}" "TaskCardSetStatus" "STOPPED_BY_USER"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "CurrentGateStatus" "STOPPED_BY_USER"
set_field "${transition_state}" "CurrentReviewRoute" "NONE"
set_field "${transition_state}" "CurrentReviewVerdict" "NOT_APPLICABLE_USER_STOP"
set_field "${transition_state}" "TransitionSequence" "2"
set_field "${transition_state}" "TransitionKind" "STOP_BY_USER"
set_field "${transition_state}" "TransitionBaseSHA" "${activation_sha}"
set_field "${transition_state}" "VisualImplementation" "STOPPED_BY_USER"
set_field "${transition_state}" "UserStopAuthorization" "EXPLICIT_USER_INSTRUCTION"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm "test: stop VSB fixture by explicit user instruction"
stopped_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" \
  --transition-base "${activation_sha}" \
  --transition-head "${stopped_sha}" >/dev/null ||
  fail "valid STOP_BY_USER transition was rejected"
git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"

mkdir -p "${transition_repo_root}/docs/design/visual-style-baseline-fixtures"
printf '%s\n' 'unauthorized candidate path' > \
  "${transition_repo_root}/docs/design/visual-style-baseline-fixtures/unauthorized.txt"
git -C "${transition_repo_root}" add \
  docs/design/visual-style-baseline-fixtures/unauthorized.txt
git -C "${transition_repo_root}" commit -qm "test: create unauthorized VSB-00 candidate"
unauthorized_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00"
set_field "${transition_state}" "ActiveTaskCard" "VSB-01"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-01"
set_field "${transition_state}" "CurrentCandidateSHA" "${unauthorized_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB00CandidateSHA" "${unauthorized_candidate_sha}"
set_field "${transition_state}" "VSB00GateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "VSB00ReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "VSB-02"
set_field "${transition_state}" "TransitionSequence" "2"
set_field "${transition_state}" "TransitionKind" "ADVANCE"
set_field "${transition_state}" "TransitionBaseSHA" "${unauthorized_candidate_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm "test: release unauthorized VSB-00 candidate"
unauthorized_receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if unauthorized_candidate_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${unauthorized_candidate_sha}" \
    --transition-head "${unauthorized_receipt_sha}" 2>&1
)"; then
  fail "candidate outside the exact VSB-00 WriteSet unexpectedly passed"
fi
assert_contains "${unauthorized_candidate_output}" \
  "candidate diff must equal the exact VSB-00 WriteSet"
negative_cases=$((negative_cases + 1))
git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"

advance_prefixes=(VSB-00 VSB-00,VSB-01 VSB-00,VSB-01,VSB-02)
advance_actives=(VSB-01 VSB-02 VSB-03)
advance_nexts=(VSB-02 VSB-03 NONE)
candidate_shas=()
receipt_shas=()
for i in 0 1 2; do
  write_exact_candidate_paths \
    "${transition_repo_root}" "${i}" "candidate ${i}"
  printf '%s\n' "${candidate_write_sets[${i}]}" | \
    git -C "${transition_repo_root}" add --pathspec-from-file=-
  git -C "${transition_repo_root}" commit -qm "test: create VSB-0${i} candidate"
  candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
  candidate_shas[${i}]="${candidate_sha}"
  set_field "${transition_state}" "CompletedTaskCards" "${advance_prefixes[${i}]}"
  set_field "${transition_state}" "ActiveTaskCard" "${advance_actives[${i}]}"
  set_field "${transition_state}" "ReleasedTaskCard" "${advance_actives[${i}]}"
  set_field "${transition_state}" "CurrentCandidateSHA" "${candidate_sha}"
  set_field "${transition_state}" "CurrentGateStatus" "VSB-G${i}_PASS"
  set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
  set_field "${transition_state}" "CurrentReviewVerdict" "GO_P0_0_P1_0_P2_0"
  set_field "${transition_state}" "VSB0${i}CandidateSHA" "${candidate_sha}"
  set_field "${transition_state}" "VSB0${i}GateStatus" "VSB-G${i}_PASS"
  set_field "${transition_state}" "VSB0${i}ReviewVerdict" "GO_P0_0_P1_0_P2_0"
  set_field "${transition_state}" "NextTaskCard" "${advance_nexts[${i}]}"
  set_field "${transition_state}" "TransitionSequence" "$((i + 2))"
  set_field "${transition_state}" "TransitionKind" "ADVANCE"
  set_field "${transition_state}" "TransitionBaseSHA" "${candidate_sha}"
  git -C "${transition_repo_root}" add \
    docs/task-cards/visual-style-baseline/execution-state.md
  git -C "${transition_repo_root}" commit -qm "test: advance VSB-0${i} fixture"
  receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
  receipt_shas[${i}]="${receipt_sha}"
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${candidate_sha}" \
    --transition-head "${receipt_sha}" >/dev/null ||
    fail "valid VSB-0${i} ADVANCE transition was rejected"
done

after_vsb02_receipt="${receipt_shas[2]}"

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "alternate VSB-00 predecessor receipt"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create alternate valid VSB-00 candidate"
alternate_vsb00_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"

git -C "${transition_repo_root}" switch -q --detach "${receipt_shas[1]}"
write_exact_candidate_paths "${transition_repo_root}" 2 \
  "successor overwrite candidate"
printf '%s\n' "${candidate_write_sets[2]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create successor overwrite candidate"
overwrite_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00,VSB-01,VSB-02"
set_field "${transition_state}" "ActiveTaskCard" "VSB-03"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-03"
set_field "${transition_state}" "CurrentCandidateSHA" "${overwrite_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G2_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB02CandidateSHA" "${overwrite_candidate_sha}"
set_field "${transition_state}" "VSB02GateStatus" "VSB-G2_PASS"
set_field "${transition_state}" "VSB02ReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB00CandidateSHA" "${alternate_vsb00_candidate_sha}"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "TransitionSequence" "4"
set_field "${transition_state}" "TransitionKind" "ADVANCE"
set_field "${transition_state}" "TransitionBaseSHA" "${overwrite_candidate_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: overwrite predecessor receipt during successor release"
overwrite_receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if overwrite_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${overwrite_candidate_sha}" \
    --transition-head "${overwrite_receipt_sha}" 2>&1
)"; then
  fail "successor transition overwriting a predecessor receipt unexpectedly passed"
fi
assert_contains "${overwrite_output}" \
  "ADVANCE must preserve every predecessor receipt"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${after_vsb02_receipt}"
write_exact_candidate_paths "${transition_repo_root}" 3 "candidate 3"
printf '%s\n' "${candidate_write_sets[3]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm "test: create VSB-03 candidate"
vsb03_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "TaskCardSetStatus" "COMPLETE"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00,VSB-01,VSB-02,VSB-03"
set_field "${transition_state}" "CurrentCandidateSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G3_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer+ultra_gatekeeper"
set_field "${transition_state}" "CurrentReviewVerdict" "FINAL_GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB03CandidateSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "VSB03GateStatus" "VSB-G3_PASS"
set_field "${transition_state}" "VSB03DeepReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB03UltraReviewVerdict" "FINAL_GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "TransitionSequence" "5"
set_field "${transition_state}" "TransitionKind" "COMPLETE"
set_field "${transition_state}" "TransitionBaseSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "VisualImplementation" "COMPLETE"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm "test: complete VSB fixture"
complete_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" \
  --transition-base "${vsb03_candidate_sha}" \
  --transition-head "${complete_sha}" >/dev/null ||
  fail "valid VSB COMPLETE transition was rejected"

set_field "${transition_state}" "VSB03UltraReviewVerdict" "NOT_RUN"
complete_failure_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" 2>&1
)" && fail "COMPLETE without ultra GO unexpectedly passed"
assert_contains "${complete_failure_output}" "VSB03 ultra review must be final zero-finding GO"
git -C "${transition_repo_root}" restore \
  docs/task-cards/visual-style-baseline/execution-state.md
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
set_field "${transition_state}" "TaskCardSetStatus" "FINAL_NO_GO"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "CurrentCandidateSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "FAIL"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer+ultra_gatekeeper"
set_field "${transition_state}" "CurrentReviewVerdict" "FINDING_P0_0_P1_1_P2_0"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "TransitionSequence" "5"
set_field "${transition_state}" "TransitionKind" "FINAL_NO_GO"
set_field "${transition_state}" "TransitionBaseSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "VisualImplementation" "FINAL_NO_GO"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm "test: record final VSB no-go"
final_no_go_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" \
  --transition-base "${vsb03_candidate_sha}" \
  --transition-head "${final_no_go_sha}" >/dev/null ||
  fail "valid FINAL_NO_GO transition was rejected"

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
set_field "${transition_state}" "ActiveTaskCard" "VSB-01"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-01"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00"
set_field "${transition_state}" "CurrentCandidateSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "FAIL"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "FINDING_P0_0_P1_1_P2_0"
for i in 1 2; do
  set_field "${transition_state}" "VSB0${i}CandidateSHA" "NONE"
  set_field "${transition_state}" "VSB0${i}GateStatus" "NOT_RUN"
  set_field "${transition_state}" "VSB0${i}ReviewVerdict" "NOT_RUN"
done
set_field "${transition_state}" "VSB03CandidateSHA" "NONE"
set_field "${transition_state}" "VSB03GateStatus" "NOT_RUN"
set_field "${transition_state}" "VSB03DeepReviewVerdict" "NOT_RUN"
set_field "${transition_state}" "VSB03UltraReviewVerdict" "NOT_RUN"
set_field "${transition_state}" "NextTaskCard" "VSB-02"
set_field "${transition_state}" "TransitionSequence" "5"
set_field "${transition_state}" "TransitionKind" "RETURN_TO_OWNER"
set_field "${transition_state}" "TransitionBaseSHA" "${vsb03_candidate_sha}"
printf '%s\n' 'Owner = VSB-01' >> "${transition_state}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: return VSB-03 finding to the wrong owner"
wrong_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if wrong_return_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${wrong_return_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER reopening a card other than the base active Owner unexpectedly passed"
fi
assert_contains "${wrong_return_output}" \
  "RETURN_TO_OWNER Owner must equal the base active Owner"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${receipt_shas[0]}"
write_exact_candidate_paths "${transition_repo_root}" 1 "VSB-01 finding candidate"
printf '%s\n' "${candidate_write_sets[1]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm "test: create VSB-01 finding candidate"
return_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "CurrentCandidateSHA" "${return_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "FAIL"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "FINDING_P0_0_P1_1_P2_0"
set_field "${transition_state}" "TransitionSequence" "3"
set_field "${transition_state}" "TransitionKind" "RETURN_TO_OWNER"
set_field "${transition_state}" "TransitionBaseSHA" "${return_candidate_sha}"
printf '%s\n' 'Owner = VSB-01' >> "${transition_state}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm "test: return VSB-01 finding to owner"
return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" \
  --transition-base "${return_candidate_sha}" \
  --transition-head "${return_sha}" >/dev/null ||
  fail "valid RETURN_TO_OWNER transition was rejected"

git -C "${transition_repo_root}" switch -q --detach "${return_candidate_sha}"
set_field "${transition_state}" "CurrentCandidateSHA" "${return_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "FAIL"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "FINDING_P0_0_P1_0_P2_0"
set_field "${transition_state}" "TransitionSequence" "3"
set_field "${transition_state}" "TransitionKind" "RETURN_TO_OWNER"
set_field "${transition_state}" "TransitionBaseSHA" "${return_candidate_sha}"
printf '%s\n' 'Owner = VSB-01' >> "${transition_state}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm "test: return with zero findings"
zero_finding_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if zero_finding_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${return_candidate_sha}" \
    --transition-head "${zero_finding_return_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER with an all-zero finding unexpectedly passed"
fi
assert_contains "${zero_finding_output}" \
  "finding verdict must contain at least one non-zero count"
negative_cases=$((negative_cases + 1))

transition_cases=9

printf '%s\n' \
  "VisualStyleBaselineTaskCardContractTests = PASS" \
  "PositiveCases = 1" \
  "NegativeCases = ${negative_cases}" \
  "TransitionCases = ${transition_cases}"
