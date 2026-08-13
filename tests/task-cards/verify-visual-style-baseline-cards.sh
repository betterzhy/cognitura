#!/usr/bin/env bash

set -euo pipefail

repair_contract_only=0
model_gate_routing_contract_only=0
case "${1:-}" in
  --repair-contract-only)
    repair_contract_only=1
    shift
    ;;
  --model-gate-routing-contract-only)
    model_gate_routing_contract_only=1
    shift
    ;;
esac
if [[ "$#" -ne 0 ]]; then
  printf 'FAIL: unknown test argument: %s\n' "$1" >&2
  exit 2
fi

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
    fail "validation output is missing '${expected}', got: ${content}"
}

assert_commit_parent_count() {
  local fixture_root="$1"
  local commit="$2"
  local expected="$3"
  local parent_line parent_count
  parent_line="$(git -C "${fixture_root}" rev-list --parents -n 1 "${commit}")"
  set -- ${parent_line}
  parent_count=$(($# - 1))
  [[ "${parent_count}" -eq "${expected}" ]] ||
    fail "fixture ${commit} must have ${expected} parents, found ${parent_count}"
}

set_field() {
  local file="$1"
  local field="$2"
  local value="$3"
  sed -i.bak "s#^${field} = .*\$#${field} = ${value}#" "${file}"
  rm "${file}.bak"
}

insert_field_after() {
  local file="$1"
  local after_field="$2"
  local new_field="$3"
  local value="$4"
  awk -v after_field="${after_field}" -v new_field="${new_field}" \
    -v value="${value}" '
      { print }
      $0 ~ "^" after_field " = " {
        print new_field " = " value
      }
    ' "${file}" > "${file}.new"
  mv "${file}.new" "${file}"
}

set_table_status() {
  local file="$1"
  local task_id="$2"
  local old_status="$3"
  local new_status="$4"
  sed -i.bak \
    "/^| \`${task_id}\` |/s/\`${old_status}\`/\`${new_status}\`/" \
    "${file}"
  rm "${file}.bak"
}

replace_exact_block() {
  local file="$1"
  local old_text="$2"
  local new_text="$3"
  local label="$4"
  local content prefix suffix rewritten
  content="$(cat "${file}"; printf '\034')"
  [[ "${content}" == *"${old_text}"* ]] || fail "${label}: source block is missing"
  prefix="${content%%"${old_text}"*}"
  suffix="${content#*"${old_text}"}"
  [[ "${suffix}" != *"${old_text}"* ]] || fail "${label}: source block is duplicated"
  rewritten="${prefix}${new_text}${suffix}"
  printf '%s' "${rewritten%$'\034'}" > "${file}"
}

suspension_narrative_paths=(
  AGENTS.md AGENTS.md README.md README.md docs/design/wave-1/README.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-plan.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1/README.md
  docs/task-cards/wave-1-implementation/README.md
)
suspension_narratives=(
  $'`W1-I02` 等待独立数据库 Gate；`W1-I03` 已冻结在\n`4e63936c631ab34807e714b90d30415a959bc13d`，当前没有 Wave 1 READY 卡。'
  $'I00；I01 已关闭，I02 保持等待独立数据库 Gate；I03 在 Visual Style Baseline\n执行期间冻结为 `SUSPENDED_BY_USER`。'
  $'完成零发现深审并关闭；I02 等待独立数据库 Gate。`W1-I03` 已冻结在\n`4e63936c631ab34807e714b90d30415a959bc13d`，当前没有 Wave 1 READY 卡；'
  $'保持 `QUEUED` 等待独立数据库 Gate；`W1-I03` 在 Visual Style Baseline 期间为\n`SUSPENDED_BY_USER`，冻结候选 production WriteSet 不得变更。'
  $'  I01 已关闭，I02 等待独立数据库 Gate；I03 在 Visual Style Baseline 期间冻结为\n  `SUSPENDED_BY_USER`，当前没有 Wave 1 READY 卡。'
  $'`W1-I03` 在独立 Visual Style Baseline 执行期间冻结为 `SUSPENDED_BY_USER`，当前\n没有 Wave 1 READY 卡；冻结 production WriteSet 不得变更。'
  $'当前业务授权保持有效，但 `W1-I03` 在 Visual Style Baseline 期间暂停；I02 独立\n数据库 Gate、正式数据库写入和远程推送仍未授权。'
  $'固定候选深审并关闭；I02 等待独立数据库 Gate，I03 在 Visual Style Baseline 期间\n冻结为 `SUSPENDED_BY_USER`，当前没有 Wave 1 READY 卡；完整证据记录在'
  $'数据库 Gate；I03 在 Visual Style Baseline 期间冻结为 `SUSPENDED_BY_USER`，当前没有\nWave 1 READY 卡。正式数据库、Parser/Object Storage Provider、'
  'I03 在 Visual Style Baseline 执行期间冻结为 `SUSPENDED_BY_USER`；当前没有 READY 卡。'
  $'I00 和 I01 已关闭；I02 等待独立数据库 Gate。W1-I03 在 Visual Style Baseline\n期间冻结为 `SUSPENDED_BY_USER`，当前没有 Wave 1 READY 卡。'
  $'完成零发现深审并关闭；I02 等待独立数据库 Gate。独立 Visual Style Baseline 执行\n期间，I03 冻结在 `4e63936c631ab34807e714b90d30415a959bc13d`，不得修改其\nproduction WriteSet。'
)
ready_narratives=(
  '`W1-I02` 等待独立数据库 Gate，`W1-I03` 为唯一 `READY` 业务卡。'
  'I00；I01 已关闭，当前已原子释放 I03，I02 保持等待独立数据库 Gate。'
  '完成零发现深审并关闭；I02 等待独立数据库 Gate，`W1-I03` 是唯一 `READY` 卡。'
  '保持 `QUEUED` 等待独立数据库 Gate，`W1-I03` 已释放为唯一 `READY` 业务卡。'
  '  I01 已关闭，I02 等待独立数据库 Gate，I03 为唯一 `READY` 卡。'
  '`W1-I03` 已作为唯一 `READY` 卡释放。'
  $'当前业务授权只按既定卡集串行推进至 `W1-I03`；I02 独立数据库 Gate、正式数据库\n写入和远程推送仍未授权。'
  '固定候选深审并关闭；I02 等待独立数据库 Gate，I03 为唯一 `READY` 卡，完整证据记录在'
  '数据库 Gate，I03 为唯一 `READY` 卡。正式数据库、Parser/Object Storage Provider、'
  'I03 为唯一 `READY` 卡。'
  'I00 和 I01 已关闭；I02 等待独立数据库 Gate，W1-I03 为唯一 `READY` 业务卡。'
  '完成零发现深审并关闭；I02 等待独立数据库 Gate，I03 已原子释放为唯一 `READY` 卡。'
)

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

expect_clean_early_exit() {
  local expected_rc="$1"
  local expected_output="$2"
  shift 2
  local output rc
  if output="$("${verifier}" "$@" 2>&1)"; then
    rc=0
  else
    rc=$?
  fi
  [[ "${rc}" -eq "${expected_rc}" ]] ||
    fail "early verifier exit returned ${rc}, expected ${expected_rc}: ${output}"
  [[ "${output}" == "${expected_output}" ]] ||
    fail "early verifier exit polluted its diagnostic: ${output}"
}

model_route_path_bit() {
  case "$1" in
    AGENTS.md) printf '1\n' ;;
    docs/superpowers/plans/2026-08-13-cognitura-model-gate-routing.md)
      printf '2\n'
      ;;
    docs/superpowers/plans/2026-08-13-cognitura-vsb-receipt-correction.md)
      printf '4\n'
      ;;
    docs/superpowers/specs/2026-08-13-cognitura-model-gate-routing-design.md)
      printf '8\n'
      ;;
    docs/superpowers/specs/2026-08-13-cognitura-vsb-receipt-correction-design.md)
      printf '16\n'
      ;;
    docs/task-cards/visual-style-baseline/README.md) printf '32\n' ;;
    docs/task-cards/visual-style-baseline/VSB-02-module-default-reading-visual.md)
      printf '64\n'
      ;;
    docs/task-cards/visual-style-baseline/VSB-03-fixed-visual-acceptance.md)
      printf '128\n'
      ;;
    scripts/verify-visual-style-baseline-cards) printf '256\n' ;;
    tests/task-cards/verify-visual-style-baseline-cards.sh) printf '512\n' ;;
    *) return 1 ;;
  esac
}

model_route_expected_mode() {
  case "$1" in
    scripts/verify-visual-style-baseline-cards|\
      tests/task-cards/verify-visual-style-baseline-cards.sh)
      printf '100755\n'
      ;;
    *)
      model_route_path_bit "$1" >/dev/null || return 1
      printf '100644\n'
      ;;
  esac
}

resolve_receipt_correction_candidate() {
  local source_repo="$1"
  local source_state="$2"
  local origin_sha="$3"
  local ledger_path="$4"
  local source_head state_version reviewed_candidate correction_field field_count
  local version_count=0 reviewed_count=0
  local -a resolver_correction_fields
  while IFS= read -r state_version; do
    version_count=$((version_count + 1))
  done < <(sed -n 's/^ExecutionStateVersion = //p' "${source_state}")
  [[ "${version_count}" -eq 1 ]] ||
    fail "formal execution state must contain ExecutionStateVersion exactly once"
  state_version="$(sed -n 's/^ExecutionStateVersion = //p' "${source_state}")"
  source_head="$(git -C "${source_repo}" rev-parse HEAD)"
  case "${state_version}" in
    2)
      receipt_correction_resolved_candidate="${source_head}"
      ;;
    ''|*[!0-9]*)
      fail "unsupported formal execution state version: ${state_version}"
      ;;
    *)
      [[ "${state_version}" -ge 3 ]] ||
        fail "unsupported formal execution state version: ${state_version}"
      resolver_correction_fields=(
        ReceiptCorrectionStatus
        ReceiptCorrectionSpecSHA
        ReceiptCorrectionOriginReceiptSHA
        ReceiptCorrectionReviewedCandidateSHA
        ReceiptCorrectionReviewLevel
        ReceiptCorrectionReviewRoute
        ReceiptCorrectionReviewEffort
        ReceiptCorrectionReviewMultiplicity
        ReceiptCorrectionReviewVerdict
      )
      for correction_field in "${resolver_correction_fields[@]}"; do
        field_count="$(sed -n "/^${correction_field} = /p" \
          "${source_state}" | wc -l | tr -d ' ')"
        [[ "${field_count}" -eq 1 ]] ||
          fail "version-3 formal state must contain ${correction_field} exactly once"
      done
      while IFS= read -r reviewed_candidate; do
        reviewed_count=$((reviewed_count + 1))
      done < <(sed -n \
        's/^ReceiptCorrectionReviewedCandidateSHA = //p' "${source_state}")
      [[ "${reviewed_count}" -eq 1 ]] ||
        fail "version-3 formal state must contain ReceiptCorrectionReviewedCandidateSHA exactly once"
      reviewed_candidate="$(sed -n \
        's/^ReceiptCorrectionReviewedCandidateSHA = //p' "${source_state}")"
      [[ "${reviewed_candidate}" =~ ^[0-9a-f]{40}$ ]] ||
        fail "formal receipt-correction reviewed candidate SHA is malformed"
      git -C "${source_repo}" cat-file -e \
        "${reviewed_candidate}^{commit}" 2>/dev/null ||
        fail "formal receipt-correction reviewed candidate commit is unavailable"
      git -C "${source_repo}" merge-base --is-ancestor \
        "${reviewed_candidate}" "${source_head}" ||
        fail "formal receipt-correction reviewed candidate is not an ancestor of HEAD"
      receipt_correction_resolved_candidate="${reviewed_candidate}"
      ;;
  esac
  git -C "${source_repo}" merge-base --is-ancestor \
    "${origin_sha}" "${receipt_correction_resolved_candidate}" ||
    fail "resolved receipt-correction candidate does not descend from the fixed origin"
  [[ "$(git -C "${source_repo}" rev-parse \
    "${receipt_correction_resolved_candidate}:${ledger_path}")" == \
     "$(git -C "${source_repo}" rev-parse "${origin_sha}:${ledger_path}")" ]] ||
    fail "resolved receipt-correction candidate ledger is not byte-identical to the origin"
}

assert_model_route_tmp_clean() {
  local invocation_tmp="$1"
  local invocation_marker="$2"
  local label="$3"
  local -a invocation_entries
  shopt -s nullglob
  invocation_entries=("${invocation_tmp}"/*)
  shopt -u nullglob
  [[ -f "${invocation_marker}" &&
     "$(cat "${invocation_marker}")" == "preserve sibling" &&
     "${#invocation_entries[@]}" -eq 1 &&
     "${invocation_entries[0]}" == "${invocation_marker}" ]] ||
    fail "${label} did not preserve a clean sibling TMPDIR"
}

run_model_route_static() {
  local fixture_root="$1"
  local fixture_cards="$2"
  local invocation_tmp="$3"
  local invocation_marker="$4"
  local label="$5"
  if model_route_public_output="$(TMPDIR="${invocation_tmp}" "${verifier}" \
    --repo-root "${fixture_root}" --cards-dir "${fixture_cards}" 2>&1)"; then
    model_route_public_rc=0
  else
    model_route_public_rc=$?
  fi
  assert_model_route_tmp_clean \
    "${invocation_tmp}" "${invocation_marker}" "${label}"
}

run_model_route_transition() {
  local fixture_root="$1"
  local fixture_cards="$2"
  local base_sha="$3"
  local head_sha="$4"
  local invocation_tmp="$5"
  local invocation_marker="$6"
  local label="$7"
  if model_route_public_output="$(TMPDIR="${invocation_tmp}" "${verifier}" \
    --repo-root "${fixture_root}" --cards-dir "${fixture_cards}" \
    --transition-base "${base_sha}" --transition-head "${head_sha}" \
    2>&1)"; then
    model_route_public_rc=0
  else
    model_route_public_rc=$?
  fi
  assert_model_route_tmp_clean \
    "${invocation_tmp}" "${invocation_marker}" "${label}"
}

expect_model_route_static_failure() {
  local fixture_root="$1"
  local fixture_cards="$2"
  local expected_message="$3"
  local invocation_tmp="$4"
  local invocation_marker="$5"
  local label="$6"
  run_model_route_static "${fixture_root}" "${fixture_cards}" \
    "${invocation_tmp}" "${invocation_marker}" "${label}"
  [[ "${model_route_public_rc}" -ne 0 ]] ||
    fail "${label} unexpectedly passed"
  assert_contains "${model_route_public_output}" "${expected_message}"
  receipt_correction_negative_cases=$((receipt_correction_negative_cases + 1))
}

expect_model_route_transition_failure() {
  local fixture_root="$1"
  local fixture_cards="$2"
  local base_sha="$3"
  local head_sha="$4"
  local expected_message="$5"
  local invocation_tmp="$6"
  local invocation_marker="$7"
  local label="$8"
  run_model_route_transition "${fixture_root}" "${fixture_cards}" \
    "${base_sha}" "${head_sha}" "${invocation_tmp}" \
    "${invocation_marker}" "${label}"
  [[ "${model_route_public_rc}" -ne 0 ]] ||
    fail "${label} unexpectedly passed"
  assert_contains "${model_route_public_output}" "${expected_message}"
  receipt_correction_negative_cases=$((receipt_correction_negative_cases + 1))
}

write_exact_receipt_correction_ledger() {
  local fixture_root="$1"
  local candidate_sha="$2"
  local ledger_path="docs/task-cards/visual-style-baseline/execution-state.md"
  local fixture_state="${fixture_root}/${ledger_path}"
  awk -v candidate_sha="${candidate_sha}" '
    /^ExecutionStateVersion = / {
      print "ExecutionStateVersion = 3"
      next
    }
    /^NextTaskCard = / {
      print "NextTaskCard = VSB-03"
      next
    }
    /^TransitionSequence = / {
      print "TransitionSequence = 5"
      next
    }
    /^TransitionKind = / {
      print "TransitionKind = RECEIPT_CORRECTION"
      next
    }
    /^TransitionBaseSHA = / {
      print "TransitionBaseSHA = " candidate_sha
      next
    }
    { print }
    /^GovernanceRepairReviewVerdict = / {
      print "ReceiptCorrectionStatus = PASS"
      print "ReceiptCorrectionSpecSHA = dc4a105bbe95b1b07fa0e734cec1148eab15279c"
      print "ReceiptCorrectionOriginReceiptSHA = 0ff410961b0f3865652e54ae46453646ed87f69e"
      print "ReceiptCorrectionReviewedCandidateSHA = " candidate_sha
      print "ReceiptCorrectionReviewLevel = L4"
      print "ReceiptCorrectionReviewRoute = deep_reviewer"
      print "ReceiptCorrectionReviewEffort = xhigh"
      print "ReceiptCorrectionReviewMultiplicity = ONE"
      print "ReceiptCorrectionReviewVerdict = FINAL_GO_P0_0_P1_0_P2_0"
    }
  ' "${fixture_state}" > "${fixture_state}.new"
  mv "${fixture_state}.new" "${fixture_state}"
}

commit_receipt_correction_ledger() {
  local fixture_root="$1"
  local subject="$2"
  local extra_path="${3:-}"
  local ledger_path="docs/task-cards/visual-style-baseline/execution-state.md"
  git -C "${fixture_root}" add -- "${ledger_path}"
  if [[ -n "${extra_path}" ]]; then
    mkdir -p "${fixture_root}/$(dirname "${extra_path}")"
    printf 'receipt-extra\n' > "${fixture_root}/${extra_path}"
    git -C "${fixture_root}" add -- "${extra_path}"
  fi
  git -C "${fixture_root}" commit -qm "${subject}"
  git -C "${fixture_root}" rev-parse HEAD
}

prepare_receipt_correction_fixture() {
  local fixture_root="$1"
  local candidate_sha="$2"
  git -C "${fixture_root}" checkout -q --detach "${candidate_sha}"
  write_exact_receipt_correction_ledger "${fixture_root}" "${candidate_sha}"
}

set_legal_stop_by_user() {
  local fixture_state="$1"
  local base_sha="$2"
  set_field "${fixture_state}" TaskCardSetStatus STOPPED_BY_USER
  set_field "${fixture_state}" ActiveTaskCard NONE
  set_field "${fixture_state}" ReleasedTaskCard NONE
  set_field "${fixture_state}" NextTaskCard NONE
  set_field "${fixture_state}" CurrentGateStatus STOPPED_BY_USER
  set_field "${fixture_state}" CurrentReviewRoute NONE
  set_field "${fixture_state}" CurrentReviewVerdict NOT_APPLICABLE_USER_STOP
  set_field "${fixture_state}" TransitionSequence 6
  set_field "${fixture_state}" TransitionKind STOP_BY_USER
  set_field "${fixture_state}" TransitionBaseSHA "${base_sha}"
  set_field "${fixture_state}" VisualImplementation STOPPED_BY_USER
  set_field "${fixture_state}" UserStopAuthorization EXPLICIT_USER_INSTRUCTION
}

mutate_exact_receipt_correction_ledger() {
  local fixture_state="$1"
  local mutation="$2"
  case "${mutation}" in
    reorder)
      sed -i.bak '/^ReceiptCorrectionStatus = /d' "${fixture_state}"
      rm "${fixture_state}.bak"
      insert_field_after "${fixture_state}" ReceiptCorrectionReviewVerdict \
        ReceiptCorrectionStatus PASS
      ;;
    unknown)
      insert_field_after "${fixture_state}" ReceiptCorrectionStatus \
        ReceiptCorrectionUnknownField FORBIDDEN
      ;;
    origin-byte)
      set_field "${fixture_state}" FullProductImplementation USER_AUTHORIZED
      ;;
    *) fail "unknown exact receipt-correction mutation: ${mutation}" ;;
  esac
}

copy_candidate_tree_onto_base() {
  local fixture_root="$1"
  local base_sha="$2"
  local candidate_sha="$3"
  local subject="$4"
  local omitted_path="${5:-}"
  git -C "${fixture_root}" checkout -q --detach "${base_sha}"
  git -C "${fixture_root}" read-tree --reset -u "${candidate_sha}^{tree}"
  if [[ -n "${omitted_path}" ]]; then
    if git -C "${fixture_root}" cat-file -e \
      "${base_sha}:${omitted_path}" 2>/dev/null; then
      git -C "${fixture_root}" checkout -q "${base_sha}" -- "${omitted_path}"
    else
      git -C "${fixture_root}" rm -q --cached --ignore-unmatch "${omitted_path}"
      rm -f "${fixture_root}/${omitted_path}"
    fi
  fi
  git -C "${fixture_root}" commit -qm "${subject}"
  git -C "${fixture_root}" rev-parse HEAD
}

mutate_receipt_correction_chain() {
  local fixture_root="$1"
  local mutation="$2"
  local candidate_sha="$3"
  local origin_sha="$4"
  local ledger_path="$5"
  git -C "${fixture_root}" checkout -q --detach "${candidate_sha}"
  case "${mutation}" in
    omit)
      copy_candidate_tree_onto_base "${fixture_root}" "${origin_sha}" \
        "${candidate_sha}" "test: omit correction path" AGENTS.md >/dev/null
      ;;
    extra)
      printf 'extra\n' > "${fixture_root}/docs/engineering/model-route-extra.md"
      git -C "${fixture_root}" add -- docs/engineering/model-route-extra.md
      git -C "${fixture_root}" commit -qm "test: extra correction path"
      ;;
    empty)
      git -C "${fixture_root}" commit --allow-empty -qm \
        "test: empty correction governance commit"
      ;;
    merge)
      git -C "${fixture_root}" switch -q -c correction-chain-side
      printf '\nside\n' >> "${fixture_root}/AGENTS.md"
      git -C "${fixture_root}" commit -qam "test: correction chain side"
      git -C "${fixture_root}" switch -q -c correction-chain-main \
        "${candidate_sha}"
      printf '\nmain\n' >> \
        "${fixture_root}/tests/task-cards/verify-visual-style-baseline-cards.sh"
      git -C "${fixture_root}" commit -qam "test: correction chain main"
      git -C "${fixture_root}" merge -q --no-ff correction-chain-side \
        -m "test: merge correction governance"
      ;;
    rename)
      git -C "${fixture_root}" mv -- AGENTS.md AGENTS.model-route.md
      git -C "${fixture_root}" commit -qm "test: rename correction path"
      git -C "${fixture_root}" checkout -q "${candidate_sha}" -- AGENTS.md
      git -C "${fixture_root}" rm -q -- AGENTS.model-route.md
      git -C "${fixture_root}" commit -qm "test: restore renamed path"
      ;;
    copy)
      git -C "${fixture_root}" rm -q -- scripts/verify-visual-style-baseline-cards
      git -C "${fixture_root}" commit -qm "test: delete correction copy target"
      cp "${fixture_root}/AGENTS.md" \
        "${fixture_root}/scripts/verify-visual-style-baseline-cards"
      chmod +x "${fixture_root}/scripts/verify-visual-style-baseline-cards"
      git -C "${fixture_root}" add -- scripts/verify-visual-style-baseline-cards
      git -C "${fixture_root}" commit -qm "test: copy correction path"
      git -C "${fixture_root}" checkout -q "${candidate_sha}" -- \
        scripts/verify-visual-style-baseline-cards
      git -C "${fixture_root}" commit -qm "test: restore copied path"
      ;;
    low-limit)
      git -C "${fixture_root}" config diff.renameLimit 1
      git -C "${fixture_root}" mv -- AGENTS.md AGENTS.low-limit.md
      git -C "${fixture_root}" mv -- \
        docs/task-cards/visual-style-baseline/README.md \
        docs/task-cards/visual-style-baseline/README.low-limit.md
      printf '\nlow-a\n' >> "${fixture_root}/AGENTS.low-limit.md"
      printf '\nlow-b\n' >> \
        "${fixture_root}/docs/task-cards/visual-style-baseline/README.low-limit.md"
      git -C "${fixture_root}" commit -qam "test: low-limit correction rename"
      git -C "${fixture_root}" checkout -q "${candidate_sha}" -- AGENTS.md \
        docs/task-cards/visual-style-baseline/README.md
      git -C "${fixture_root}" rm -q -- AGENTS.low-limit.md \
        docs/task-cards/visual-style-baseline/README.low-limit.md
      git -C "${fixture_root}" commit -qm "test: restore low-limit rename"
      ;;
    ledger)
      printf '\ndrift\n' >> "${fixture_root}/${ledger_path}"
      git -C "${fixture_root}" commit -qam "test: drift correction ledger"
      git -C "${fixture_root}" checkout -q "${candidate_sha}" -- "${ledger_path}"
      git -C "${fixture_root}" commit -qm "test: restore correction ledger"
      ;;
    nul)
      printf '\000' >> "${fixture_root}/AGENTS.md"
      git -C "${fixture_root}" commit -qam "test: NUL correction governance"
      ;;
    newline)
      printf 'newline\n' > "${fixture_root}/AGENTS.newline"$'\n'path
      git -C "${fixture_root}" add -- "AGENTS.newline"$'\n'path
      git -C "${fixture_root}" commit -qm "test: newline correction path"
      ;;
    mode)
      chmod +x "${fixture_root}/AGENTS.md"
      git -C "${fixture_root}" commit -qam "test: correction mode drift"
      ;;
    *) fail "unknown receipt-correction chain mutation: ${mutation}" ;;
  esac
}

run_model_gate_routing_contract() {
  local correction_origin_sha="0ff410961b0f3865652e54ae46453646ed87f69e"
  local correction_spec_sha="dc4a105bbe95b1b07fa0e734cec1148eab15279c"
  local correction_plan_sha="f4bd848186a4a4d2d771d0d031340483bfa5de9b"
  local model_route_design_sha="1199e76a18db1d168c67c328ce7f195f3cdac7d9"
  local model_route_plan_sha="fac5f50c6a3f1afb743f95f40ac6b7f5e4e888e1"
  local reviewed_vsb01_sha="108592b757ba50ea6ded7b901bd2b623737a7048"
  local historical_repair_receipt_sha="e7ed6509b6de95817b8bbc983ab438f0163f6322"
  local ledger_path="docs/task-cards/visual-style-baseline/execution-state.md"
  local fixture_root="${test_tmp_root}/model-gate-routing-repo"
  local fixture_cards="${fixture_root}/docs/task-cards/visual-style-baseline"
  local fixture_state="${fixture_cards}/execution-state.md"
  local invocation_tmp="${test_tmp_root}/model-gate-routing-tmp"
  local invocation_marker="${invocation_tmp}/sibling-marker"
  local commit parent parent_line path path_bit expected_mode
  local raw_metadata old_mode new_mode old_blob new_blob raw_status
  local rename_status rename_source rename_target
  local chain_file raw_file raw_error rename_file rename_error net_file net_error
  local chain_path_mask=0 net_path_mask=0 net_path_count=0 commit_path_count
  local authority_sha authority_path authority_mode fixed_blob tip_blob
  local origin_ledger candidate_ledger pending_output pending_rc
  local candidate_vsb02 candidate_vsb03 candidate_vsb03_content
  local vsb03_old_review vsb03_new_review
  local historical_root historical_output historical_rc
  local authority_swap_cards authority_swap_output authority_swap_rc
  local historical_route_cards historical_route_output historical_route_rc
  local contradictory_route_cards contradictory_route_output contradictory_route_rc
  local route_card_negative_cases=0
  local -a invocation_entries

  mkdir -p "${invocation_tmp}"
  printf 'preserve sibling\n' > "${invocation_marker}"

  # The completed historical version-1-to-2 GovernanceRepair retains its
  # original stacked deep+ultra route.  The current migration must not weaken
  # replay of that immutable receipt.
  historical_root="${test_tmp_root}/historical-governance-repair"
  git clone --shared -q "${repo_root}" "${historical_root}"
  git -C "${historical_root}" checkout -q --detach \
    "${historical_repair_receipt_sha}"
  if historical_output="$(TMPDIR="${invocation_tmp}" "${verifier}" \
    --repo-root "${historical_root}" \
    --cards-dir "${historical_root}/docs/task-cards/visual-style-baseline" \
    2>&1)"; then
    historical_rc=0
  else
    historical_rc=$?
  fi
  [[ "${historical_rc}" -eq 0 ]] ||
    fail "historical GovernanceRepair replay was rejected: ${historical_output}"
  assert_contains "${historical_output}" \
    "GovernanceRepairStatus = PASS"
  [[ "$(git -C "${historical_root}" show \
    "${historical_repair_receipt_sha}:${ledger_path}" | \
    sed -n 's/^GovernanceRepairReviewRoute = //p')" == \
    deep_reviewer+ultra_gatekeeper ]] ||
    fail "historical GovernanceRepair route was not preserved"

  git clone --shared -q "${repo_root}" "${fixture_root}"
  git -C "${fixture_root}" checkout -q --detach \
    "${model_route_plan_sha}"
  [[ "$(git -C "${fixture_root}" rev-parse \
    "${correction_origin_sha}^")" == "${reviewed_vsb01_sha}" ]] ||
    fail "receipt-correction origin is not the direct child of reviewed VSB-01"
  [[ "$(git -C "${fixture_root}" diff --name-only \
    "${reviewed_vsb01_sha}..${correction_origin_sha}")" == "${ledger_path}" ]] ||
    fail "receipt-correction origin is not the fixed ledger-only receipt"

  set_field "${fixture_cards}/VSB-02-module-default-reading-visual.md" \
    ReviewRoute deep_reviewer
  insert_field_after \
    "${fixture_cards}/VSB-02-module-default-reading-visual.md" \
    Gate ReviewLevel L3
  insert_field_after \
    "${fixture_cards}/VSB-02-module-default-reading-visual.md" \
    ReviewRoute ReviewEffort xhigh
  insert_field_after \
    "${fixture_cards}/VSB-02-module-default-reading-visual.md" \
    ReviewEffort ReviewMultiplicity ONE
  insert_field_after \
    "${fixture_cards}/VSB-02-module-default-reading-visual.md" \
    ReviewMultiplicity ReviewVerdict GO_P0_0_P1_0_P2_0
  replace_exact_block \
    "${fixture_cards}/VSB-02-module-default-reading-visual.md" \
    '形成独立本地候选，执行 `deep_reviewer` 固定 SHA 零发现审查；回执前不释放后继卡。' \
    $'`ReviewVerdict` 仅定义 required acceptance，不是运行态或已执行事实。形成独立本地候选，\n对同一固定 SHA 只执行一次 `L3 / deep_reviewer / xhigh` 零 finding 门禁；回执前不释放后继卡。' \
    "VSB-02 single L3 xhigh review narrative"

  set_field "${fixture_cards}/VSB-03-fixed-visual-acceptance.md" \
    ReviewRoute deep_reviewer
  insert_field_after \
    "${fixture_cards}/VSB-03-fixed-visual-acceptance.md" \
    Gate ReviewLevel L4
  insert_field_after \
    "${fixture_cards}/VSB-03-fixed-visual-acceptance.md" \
    ReviewRoute ReviewEffort xhigh
  insert_field_after \
    "${fixture_cards}/VSB-03-fixed-visual-acceptance.md" \
    ReviewEffort ReviewMultiplicity ONE
  insert_field_after \
    "${fixture_cards}/VSB-03-fixed-visual-acceptance.md" \
    ReviewMultiplicity UltraRequiredByDefault NO
  insert_field_after \
    "${fixture_cards}/VSB-03-fixed-visual-acceptance.md" \
    UltraRequiredByDefault ReviewVerdict FINAL_GO_P0_0_P1_0_P2_0

  vsb03_old_review=$'同一未变候选依次取得 `deep_reviewer` 与 `ultra_gatekeeper` 零发现 GO。任一 finding\n必须 `RETURN_TO_OWNER`；两阶段 GO 前不得 COMPLETE 或恢复 Wave 1。'
  vsb03_new_review=$'同一未变候选只执行一次 `L4 / deep_reviewer / xhigh` 固定 SHA 最终门禁。只有主\nAgent 先记录本设计允许的明确升级原因时，`ultra_gatekeeper` 才替代默认门禁；\n不得自动叠加。任一 finding 必须 `RETURN_TO_OWNER`；最终 GO 前不得 `COMPLETE`\n或恢复 Wave 1。'
  replace_exact_block \
    "${fixture_cards}/VSB-03-fixed-visual-acceptance.md" \
    "${vsb03_old_review}" "${vsb03_new_review}" \
    "VSB-03 single L4 xhigh review narrative"

  insert_field_after \
    "${fixture_cards}/README.md" SetAuthorization ModelGateRouting \
    L3_DEEP_REVIEWER_XHIGH_ONE__L4_DEEP_REVIEWER_XHIGH_ONE
  replace_exact_block \
    "${fixture_cards}/README.md" \
    '| `VSB-02` | [Module 默认阅读视觉实现](VSB-02-module-default-reading-visual.md) | `VSB-01` | `VSB-G2 MODULE_DEFAULT_READING_VISUAL` | `deep_reviewer` |' \
    '| `VSB-02` | [Module 默认阅读视觉实现](VSB-02-module-default-reading-visual.md) | `VSB-01` | `VSB-G2 MODULE_DEFAULT_READING_VISUAL` | `deep_reviewer / L3 / xhigh / ONE` |' \
    "VSB-02 README route table"
  replace_exact_block \
    "${fixture_cards}/README.md" \
    '| `VSB-03` | [固定视觉验收](VSB-03-fixed-visual-acceptance.md) | `VSB-02` | `VSB-G3 FIXED_VISUAL_ACCEPTANCE` | `deep_reviewer+ultra_gatekeeper` |' \
    '| `VSB-03` | [固定视觉验收](VSB-03-fixed-visual-acceptance.md) | `VSB-02` | `VSB-G3 FIXED_VISUAL_ACCEPTANCE` | `deep_reviewer / L4 / xhigh / ONE`（default） |' \
    "VSB-03 README route table"
  replace_exact_block \
    "${fixture_cards}/README.md" \
    $'- 修复后，仅 G 的 ledger-only `GOVERNANCE_REPAIR` receipt R 可作为 VSB-01 release anchor。\n\n| ID | 任务卡 | 依赖 | Gate | ReviewRoute |' \
    $'- 修复后，仅 G 的 ledger-only `GOVERNANCE_REPAIR` receipt R 可作为 VSB-01 release anchor。\n\n当前模型路由 Authority 是\n[`2026-08-13-cognitura-model-gate-routing-design.md`](../../superpowers/specs/2026-08-13-cognitura-model-gate-routing-design.md)\n（固定 SHA `1199e76a18db1d168c67c328ce7f195f3cdac7d9`）及其 TDD 修订计划\n[`2026-08-13-cognitura-model-gate-routing.md`](../../superpowers/plans/2026-08-13-cognitura-model-gate-routing.md)\n（固定 SHA `fac5f50c6a3f1afb743f95f40ac6b7f5e4e888e1`）。它们只迁移当前路由；上述已完成\n`GOVERNANCE_REPAIR` 的 stacked route 仍是历史事实，不追溯改写。\n\n| ID | 任务卡 | 依赖 | Gate | ReviewRoute |' \
    "model-route README Authority"
  printf '\n%s\n' \
    'ModelGateRoutingFixture = L3_L4_SINGLE_XHIGH' >> "${fixture_root}/AGENTS.md"
  printf '\n# model-gate-routing fixture production entry\n' >> \
    "${fixture_root}/scripts/verify-visual-style-baseline-cards"
  printf '\n# model-gate-routing fixture contract entry\n' >> \
    "${fixture_root}/tests/task-cards/verify-visual-style-baseline-cards.sh"
  git -C "${fixture_root}" add -- \
    AGENTS.md \
    docs/task-cards/visual-style-baseline/README.md \
    docs/task-cards/visual-style-baseline/VSB-02-module-default-reading-visual.md \
    docs/task-cards/visual-style-baseline/VSB-03-fixed-visual-acceptance.md \
    scripts/verify-visual-style-baseline-cards \
    tests/task-cards/verify-visual-style-baseline-cards.sh
  git -C "${fixture_root}" commit -qm \
    "test: establish single xhigh model routing candidate"
  model_route_candidate_sha="$(git -C "${fixture_root}" rev-parse HEAD)"

  git -C "${fixture_root}" merge-base --is-ancestor \
    "${correction_origin_sha}" "${model_route_candidate_sha}" ||
    fail "model-route candidate does not descend from the correction origin"
  chain_file="${test_tmp_root}/model-route-chain"
  git -C "${fixture_root}" rev-list --reverse \
    "${correction_origin_sha}..${model_route_candidate_sha}" > "${chain_file}" ||
    fail "could not enumerate the model-route governance chain"
  [[ -s "${chain_file}" ]] ||
    fail "model-route governance chain must be non-empty"

  while IFS= read -r commit; do
    parent_line="$(git -C "${fixture_root}" rev-list --parents -n 1 "${commit}")"
    set -- ${parent_line}
    [[ "$#" -eq 2 ]] ||
      fail "model-route governance commit must have exactly one parent: ${commit}"
    parent="$2"
    commit_path_count=0

    rename_file="${test_tmp_root}/model-route-rename-${commit}"
    rename_error="${rename_file}.err"
    git -C "${fixture_root}" -c diff.renameLimit=0 diff-tree \
      --no-commit-id -r -M -C --find-copies-harder --name-status -z \
      "${parent}" "${commit}" > "${rename_file}" 2> "${rename_error}" ||
      fail "rename/copy inspection failed for model-route commit: ${commit}"
    [[ ! -s "${rename_error}" ]] ||
      fail "rename/copy inspection emitted diagnostics for model-route commit: ${commit}"
    while IFS= read -r -d '' rename_status; do
      IFS= read -r -d '' rename_source ||
        fail "truncated model-route name-status record: ${commit}"
      case "${rename_status}" in
        R*|C*)
          IFS= read -r -d '' rename_target ||
            fail "truncated model-route rename/copy record: ${commit}"
          fail "model-route governance chain must not rename or copy: ${rename_source} -> ${rename_target}"
          ;;
      esac
    done < "${rename_file}"

    raw_file="${test_tmp_root}/model-route-raw-${commit}"
    raw_error="${raw_file}.err"
    git -C "${fixture_root}" diff-tree --no-commit-id -r --raw -z \
      --no-renames "${parent}" "${commit}" > "${raw_file}" 2> "${raw_error}" ||
      fail "raw path inspection failed for model-route commit: ${commit}"
    [[ ! -s "${raw_error}" ]] ||
      fail "raw path inspection emitted diagnostics for model-route commit: ${commit}"
    while IFS= read -r -d '' raw_metadata; do
      IFS= read -r -d '' path ||
        fail "truncated model-route raw path record: ${commit}"
      case "${path}" in
        *$'\n'*) fail "model-route governance path contains a newline" ;;
      esac
      [[ "${path}" != "${ledger_path}" ]] ||
        fail "model-route governance chain changed the execution ledger"
      path_bit="$(model_route_path_bit "${path}")" ||
        fail "model-route governance chain changed an extra path: ${path}"
      expected_mode="$(model_route_expected_mode "${path}")"
      read -r old_mode new_mode old_blob new_blob raw_status <<< \
        "${raw_metadata#:}"
      case "${raw_status}" in
        A)
          [[ "${old_mode}" == 000000 && "${new_mode}" == "${expected_mode}" ]] ||
            fail "model-route added path has an invalid mode: ${path}"
          ;;
        M)
          [[ "${old_mode}" == "${new_mode}" && \
             "${new_mode}" == "${expected_mode}" ]] ||
            fail "model-route governance commit changed path mode: ${path}"
          ;;
        *)
          fail "model-route governance commit used invalid status ${raw_status}: ${path}"
          ;;
      esac
      chain_path_mask=$((chain_path_mask | path_bit))
      commit_path_count=$((commit_path_count + 1))
    done < "${raw_file}"
    [[ "${commit_path_count}" -gt 0 ]] ||
      fail "model-route governance commit must be non-empty: ${commit}"
  done < "${chain_file}"
  [[ "${chain_path_mask}" -eq 1023 ]] ||
    fail "model-route origin-exclusive chain did not touch the exact ten-path set"

  net_file="${test_tmp_root}/model-route-net-paths"
  net_error="${net_file}.err"
  git -C "${fixture_root}" diff --no-renames --name-only -z \
    "${correction_origin_sha}..${model_route_candidate_sha}" \
    > "${net_file}" 2> "${net_error}" ||
    fail "could not inspect the model-route cumulative WriteSet"
  [[ ! -s "${net_error}" ]] ||
    fail "model-route cumulative WriteSet inspection emitted diagnostics"
  while IFS= read -r -d '' path; do
    case "${path}" in
      *$'\n'*) fail "model-route cumulative path contains a newline" ;;
    esac
    path_bit="$(model_route_path_bit "${path}")" ||
      fail "model-route cumulative WriteSet contains an extra path: ${path}"
    net_path_mask=$((net_path_mask | path_bit))
    net_path_count=$((net_path_count + 1))
  done < "${net_file}"
  [[ "${net_path_mask}" -eq 1023 && "${net_path_count}" -eq 10 ]] ||
    fail "model-route candidate must have the exact ten-path WriteSet"

  for authority_sha in \
    "${correction_spec_sha}" "${correction_plan_sha}" \
    "${model_route_design_sha}" "${model_route_plan_sha}"; do
    git -C "${fixture_root}" merge-base --is-ancestor \
      "${authority_sha}" "${model_route_candidate_sha}" ||
      fail "fixed authority is absent from model-route candidate ancestry: ${authority_sha}"
  done
  while IFS='|' read -r authority_sha authority_path; do
    authority_mode="$(git -C "${fixture_root}" ls-tree "${authority_sha}" \
      -- "${authority_path}" | awk '{print $1}')"
    [[ "${authority_mode}" == 100644 ]] ||
      fail "fixed model-route authority mode is not 100644: ${authority_path}"
    [[ "$(git -C "${fixture_root}" ls-tree "${model_route_candidate_sha}" \
      -- "${authority_path}" | awk '{print $1}')" == 100644 ]] ||
      fail "model-route candidate authority mode is not 100644: ${authority_path}"
    fixed_blob="$(git -C "${fixture_root}" rev-parse \
      "${authority_sha}:${authority_path}")"
    tip_blob="$(git -C "${fixture_root}" rev-parse \
      "${model_route_candidate_sha}:${authority_path}")"
    [[ "${fixed_blob}" == "${tip_blob}" ]] ||
      fail "fixed model-route authority blob drifted: ${authority_path}"
  done <<EOF
${correction_spec_sha}|docs/superpowers/specs/2026-08-13-cognitura-vsb-receipt-correction-design.md
${correction_plan_sha}|docs/superpowers/plans/2026-08-13-cognitura-vsb-receipt-correction.md
${model_route_design_sha}|docs/superpowers/specs/2026-08-13-cognitura-model-gate-routing-design.md
${model_route_plan_sha}|docs/superpowers/plans/2026-08-13-cognitura-model-gate-routing.md
EOF

  origin_ledger="${test_tmp_root}/model-route-origin-ledger"
  candidate_ledger="${test_tmp_root}/model-route-candidate-ledger"
  git -C "${fixture_root}" show \
    "${correction_origin_sha}:${ledger_path}" > "${origin_ledger}"
  git -C "${fixture_root}" show \
    "${model_route_candidate_sha}:${ledger_path}" > "${candidate_ledger}"
  cmp -s "${origin_ledger}" "${candidate_ledger}" ||
    fail "model-route candidate ledger is not byte-identical to the origin"
  [[ "$(git -C "${fixture_root}" ls-tree "${model_route_candidate_sha}" \
    -- "${ledger_path}" | awk '{print $1}')" == 100644 ]] ||
    fail "model-route candidate ledger mode is not 100644"

  candidate_vsb02="${test_tmp_root}/model-route-candidate-vsb02"
  candidate_vsb03="${test_tmp_root}/model-route-candidate-vsb03"
  git -C "${fixture_root}" show \
    "${model_route_candidate_sha}:docs/task-cards/visual-style-baseline/VSB-02-module-default-reading-visual.md" \
    > "${candidate_vsb02}"
  git -C "${fixture_root}" show \
    "${model_route_candidate_sha}:docs/task-cards/visual-style-baseline/VSB-03-fixed-visual-acceptance.md" \
    > "${candidate_vsb03}"
  candidate_vsb03_content="$(cat "${candidate_vsb03}"; printf '\034')"
  [[ "$(sed -n 's/^ReviewLevel = //p' "${candidate_vsb02}")" == L3 &&
     "$(sed -n 's/^ReviewRoute = //p' \
    "${candidate_vsb02}")" == deep_reviewer &&
     "$(sed -n 's/^ReviewEffort = //p' \
    "${candidate_vsb02}")" == xhigh &&
     "$(sed -n 's/^ReviewMultiplicity = //p' \
    "${candidate_vsb02}")" == ONE &&
     "$(sed -n 's/^ReviewVerdict = //p' \
    "${candidate_vsb02}")" == GO_P0_0_P1_0_P2_0 ]] ||
    fail "legal VSB-02 L3 single-xhigh route fixture is malformed"
  [[ "$(sed -n 's/^ReviewLevel = //p' "${candidate_vsb03}")" == L4 &&
     "$(sed -n 's/^ReviewRoute = //p' \
    "${candidate_vsb03}")" == deep_reviewer &&
     "$(sed -n 's/^ReviewEffort = //p' \
    "${candidate_vsb03}")" == xhigh &&
     "$(sed -n 's/^ReviewMultiplicity = //p' \
    "${candidate_vsb03}")" == ONE &&
     "$(sed -n 's/^ReviewVerdict = //p' \
    "${candidate_vsb03}")" == FINAL_GO_P0_0_P1_0_P2_0 &&
     "$(sed -n 's/^UltraRequiredByDefault = //p' \
    "${candidate_vsb03}")" == NO ]] ||
    fail "legal VSB-03 L4 single-xhigh route fixture is malformed"
  assert_contains "${candidate_vsb03_content%$'\034'}" \
    "${vsb03_new_review}"
  [[ "${candidate_vsb03_content}" != \
       *'deep_reviewer+ultra_gatekeeper'* &&
     "${candidate_vsb03_content}" != *'依次取得'* ]] ||
    fail "committed VSB-03 candidate retained the old stacked review narrative"

  # The candidate Git blob remains the immutable failed 0ff receipt evidence.
  # Cycle A exercises only the new card/route schema against the last legal
  # VSB-01 runtime projection; receipt-correction pending behavior belongs to
  # Cycle B and is not made legal here.
  git -C "${fixture_root}" show \
    "${reviewed_vsb01_sha}:${ledger_path}" > "${fixture_state}"
  [[ "$(sed -n 's/^ActiveTaskCard = //p' "${fixture_state}")" == VSB-01 &&
     "$(sed -n 's/^NextTaskCard = //p' "${fixture_state}")" == VSB-02 &&
     "$(sed -n 's/^TransitionKind = //p' "${fixture_state}")" == GOVERNANCE_REPAIR ]] ||
    fail "Cycle A legal VSB-01 runtime projection is malformed"

  if pending_output="$(TMPDIR="${invocation_tmp}" "${verifier}" \
    --repo-root "${fixture_root}" --cards-dir "${fixture_cards}" 2>&1)"; then
    pending_rc=0
  else
    pending_rc=$?
  fi
  shopt -s nullglob
  invocation_entries=("${invocation_tmp}"/*)
  shopt -u nullglob
  [[ -f "${invocation_marker}" &&
     "$(cat "${invocation_marker}")" == "preserve sibling" &&
     "${#invocation_entries[@]}" -eq 1 &&
     "${invocation_entries[0]}" == "${invocation_marker}" ]] ||
    fail "model-route verifier did not preserve a clean sibling TMPDIR"
  [[ "${pending_rc}" -eq 0 ]] ||
    fail "Cycle A route-card contract was rejected: ${pending_output}"
  assert_contains "${pending_output}" \
    "VisualStyleBaselineTaskCardValidation = PASS"

  authority_swap_cards="${test_tmp_root}/model-route-authority-swap"
  cp -R "${fixture_cards}" "${authority_swap_cards}"
  sed -i.bak \
    -e 's/1199e76a18db1d168c67c328ce7f195f3cdac7d9/MODEL_ROUTE_SHA_SWAP/' \
    -e 's/fac5f50c6a3f1afb743f95f40ac6b7f5e4e888e1/1199e76a18db1d168c67c328ce7f195f3cdac7d9/' \
    -e 's/MODEL_ROUTE_SHA_SWAP/fac5f50c6a3f1afb743f95f40ac6b7f5e4e888e1/' \
    "${authority_swap_cards}/README.md"
  rm "${authority_swap_cards}/README.md.bak"
  if authority_swap_output="$(TMPDIR="${invocation_tmp}" "${verifier}" \
    --repo-root "${fixture_root}" --cards-dir "${authority_swap_cards}" 2>&1)"; then
    authority_swap_rc=0
  else
    authority_swap_rc=$?
  fi
  [[ "${authority_swap_rc}" -ne 0 ]] ||
    fail "swapped model-route Authority SHAs unexpectedly passed"
  [[ "${authority_swap_output}" == \
     $'VisualStyleBaselineTaskCardValidation = FAIL\nREADME.md: model-route Authority block mismatch' ]] ||
    fail "swapped Authority SHAs returned the wrong diagnostic: ${authority_swap_output}"
  shopt -s nullglob
  invocation_entries=("${invocation_tmp}"/*)
  shopt -u nullglob
  [[ -f "${invocation_marker}" &&
     "$(cat "${invocation_marker}")" == "preserve sibling" &&
     "${#invocation_entries[@]}" -eq 1 &&
     "${invocation_entries[0]}" == "${invocation_marker}" ]] ||
    fail "Authority swap negative did not preserve a clean sibling TMPDIR"
  route_card_negative_cases=$((route_card_negative_cases + 1))

  historical_route_cards="${test_tmp_root}/model-route-historical-rewrite"
  cp -R "${fixture_cards}" "${historical_route_cards}"
  sed -i.bak \
    's/并要求 `deep_reviewer` 零 finding GO 以及 `ultra_gatekeeper` 零 finding 最终 GO。/并要求历史审查为零 finding GO。/' \
    "${historical_route_cards}/README.md"
  rm "${historical_route_cards}/README.md.bak"
  if historical_route_output="$(TMPDIR="${invocation_tmp}" "${verifier}" \
    --repo-root "${fixture_root}" --cards-dir "${historical_route_cards}" 2>&1)"; then
    historical_route_rc=0
  else
    historical_route_rc=$?
  fi
  [[ "${historical_route_rc}" -ne 0 ]] ||
    fail "rewritten historical GovernanceRepair route unexpectedly passed"
  [[ "${historical_route_output}" == \
     $'VisualStyleBaselineTaskCardValidation = FAIL\nREADME.md: model-route Authority block mismatch' ]] ||
    fail "historical GovernanceRepair rewrite returned the wrong diagnostic: ${historical_route_output}"
  shopt -s nullglob
  invocation_entries=("${invocation_tmp}"/*)
  shopt -u nullglob
  [[ -f "${invocation_marker}" &&
     "$(cat "${invocation_marker}")" == "preserve sibling" &&
     "${#invocation_entries[@]}" -eq 1 &&
     "${invocation_entries[0]}" == "${invocation_marker}" ]] ||
    fail "historical route negative did not preserve a clean sibling TMPDIR"
  route_card_negative_cases=$((route_card_negative_cases + 1))

  contradictory_route_cards="${test_tmp_root}/model-route-contradictory-current"
  cp -R "${fixture_cards}" "${contradictory_route_cards}"
  printf '\n%s\n' \
    'CurrentVSB03ReviewRoute = deep_reviewer+ultra_gatekeeper' >> \
    "${contradictory_route_cards}/README.md"
  if contradictory_route_output="$(TMPDIR="${invocation_tmp}" "${verifier}" \
    --repo-root "${fixture_root}" --cards-dir "${contradictory_route_cards}" 2>&1)"; then
    contradictory_route_rc=0
  else
    contradictory_route_rc=$?
  fi
  [[ "${contradictory_route_rc}" -ne 0 ]] ||
    fail "contradictory current VSB-03 route unexpectedly passed"
  [[ "${contradictory_route_output}" == \
     $'VisualStyleBaselineTaskCardValidation = FAIL\nREADME.md: contradictory current model route' ]] ||
    fail "contradictory current route returned the wrong diagnostic: ${contradictory_route_output}"
  shopt -s nullglob
  invocation_entries=("${invocation_tmp}"/*)
  shopt -u nullglob
  [[ -f "${invocation_marker}" &&
     "$(cat "${invocation_marker}")" == "preserve sibling" &&
     "${#invocation_entries[@]}" -eq 1 &&
     "${invocation_entries[0]}" == "${invocation_marker}" ]] ||
    fail "contradictory current route negative did not preserve a clean sibling TMPDIR"
  route_card_negative_cases=$((route_card_negative_cases + 1))

  # Cycle B starts only after every Cycle A route/card fixture above is green.
  # Its first public call is a legal origin-exclusive exact-ten-path G2 whose
  # ledger is still byte-identical to the failed 0ff receipt.  The assertion is
  # deliberately the post-GREEN contract: an implementation without the
  # one-time RECEIPT_CORRECTION branch must reject this positive and produce RED.
  local correction_fixture_root="${test_tmp_root}/receipt-correction-repo"
  local correction_fixture_cards=
  local correction_fixture_state=
  local correction_candidate_sha=
  local correction_receipt_sha=
  local correction_ordinary_receipt_sha
  local correction_positive_cases=0
  receipt_correction_negative_cases=0
  resolve_receipt_correction_candidate "${repo_root}" \
    "${cards_dir}/execution-state.md" "${correction_origin_sha}" \
    "${ledger_path}"
  correction_candidate_sha="${receipt_correction_resolved_candidate}"
  git clone --shared -q "${repo_root}" "${correction_fixture_root}"
  git -C "${correction_fixture_root}" checkout -q --detach \
    "${correction_candidate_sha}"
  correction_fixture_cards="${correction_fixture_root}/docs/task-cards/visual-style-baseline"
  correction_fixture_state="${correction_fixture_cards}/execution-state.md"

  git -C "${correction_fixture_root}" merge-base --is-ancestor \
    "${correction_origin_sha}" "${correction_candidate_sha}" ||
    fail "Cycle B candidate does not descend from the fixed correction origin"
  git -C "${correction_fixture_root}" show \
    "${correction_origin_sha}:${ledger_path}" > \
    "${test_tmp_root}/cycle-b-origin-ledger"
  git -C "${correction_fixture_root}" show \
    "${correction_candidate_sha}:${ledger_path}" > \
    "${test_tmp_root}/cycle-b-candidate-ledger"
  cmp -s "${test_tmp_root}/cycle-b-origin-ledger" \
    "${test_tmp_root}/cycle-b-candidate-ledger" ||
    fail "Cycle B G2 ledger is not byte-identical to the fixed origin"

  run_model_route_static "${correction_fixture_root}" \
    "${correction_fixture_cards}" "${invocation_tmp}" \
    "${invocation_marker}" "legal Cycle B G2/PENDING positive"
  [[ "${model_route_public_rc}" -eq 0 ]] ||
    fail "legal Cycle B G2/PENDING candidate was rejected: ${model_route_public_output}"
  assert_contains "${model_route_public_output}" \
    "VisualStyleBaselineTaskCardValidation = PASS"
  assert_contains "${model_route_public_output}" \
    "ReceiptCorrectionStatus = PENDING"
  correction_positive_cases=$((correction_positive_cases + 1))

  prepare_receipt_correction_fixture \
    "${correction_fixture_root}" "${correction_candidate_sha}"
  correction_receipt_sha="$(commit_receipt_correction_ledger \
    "${correction_fixture_root}" \
    "test: exact model-route receipt correction")"
  assert_commit_parent_count \
    "${correction_fixture_root}" "${correction_receipt_sha}" 1
  [[ "$(git -C "${correction_fixture_root}" rev-parse \
    "${correction_receipt_sha}^")" == "${correction_candidate_sha}" ]] ||
    fail "legal R2 is not the direct child of G2"
  [[ "$(git -C "${correction_fixture_root}" diff --name-only \
    "${correction_candidate_sha}..${correction_receipt_sha}")" == \
    "${ledger_path}" ]] || fail "legal R2 is not ledger-only"
  run_model_route_transition "${correction_fixture_root}" \
    "${correction_fixture_cards}" "${correction_candidate_sha}" \
    "${correction_receipt_sha}" "${invocation_tmp}" \
    "${invocation_marker}" "legal G2-to-R2 correction positive"
  [[ "${model_route_public_rc}" -eq 0 ]] ||
    fail "legal G2-to-R2 correction was rejected: ${model_route_public_output}"
  assert_contains "${model_route_public_output}" \
    "VisualStyleBaselineTaskCardValidation = PASS"
  correction_positive_cases=$((correction_positive_cases + 1))

  run_model_route_static "${correction_fixture_root}" \
    "${correction_fixture_cards}" "${invocation_tmp}" \
    "${invocation_marker}" "legal version-3 static correction positive"
  [[ "${model_route_public_rc}" -eq 0 ]] ||
    fail "legal version-3 static correction was rejected: ${model_route_public_output}"
  assert_contains "${model_route_public_output}" \
    "ReceiptCorrectionStatus = PASS"
  correction_positive_cases=$((correction_positive_cases + 1))

  # A minimal later ordinary transition proves version-3 replay preserves the
  # correction fields without duplicating the separate Owner-chain suite.
  git -C "${correction_fixture_root}" checkout -q --detach \
    "${correction_receipt_sha}"
  set_legal_stop_by_user \
    "${correction_fixture_state}" "${correction_receipt_sha}"
  correction_ordinary_receipt_sha="$(commit_receipt_correction_ledger \
    "${correction_fixture_root}" \
    "test: ordinary version-3 stop after correction")"
  run_model_route_transition "${correction_fixture_root}" \
    "${correction_fixture_cards}" "${correction_receipt_sha}" \
    "${correction_ordinary_receipt_sha}" "${invocation_tmp}" \
    "${invocation_marker}" "ordinary version-3 correction replay positive"
  [[ "${model_route_public_rc}" -eq 0 ]] ||
    fail "ordinary version-3 replay was rejected: ${model_route_public_output}"
  correction_positive_cases=$((correction_positive_cases + 1))

  local -a correction_fields correction_missing_messages
  local correction_field correction_field_index bad_correction_receipt
  correction_fields=(
    ReceiptCorrectionStatus
    ReceiptCorrectionSpecSHA
    ReceiptCorrectionOriginReceiptSHA
    ReceiptCorrectionReviewedCandidateSHA
    ReceiptCorrectionReviewLevel
    ReceiptCorrectionReviewRoute
    ReceiptCorrectionReviewEffort
    ReceiptCorrectionReviewMultiplicity
    ReceiptCorrectionReviewVerdict
  )
  correction_missing_messages=(
    "missing receipt correction field: ReceiptCorrectionStatus"
    "missing receipt correction field: ReceiptCorrectionSpecSHA"
    "missing receipt correction field: ReceiptCorrectionOriginReceiptSHA"
    "missing receipt correction field: ReceiptCorrectionReviewedCandidateSHA"
    "missing receipt correction field: ReceiptCorrectionReviewLevel"
    "missing receipt correction field: ReceiptCorrectionReviewRoute"
    "missing receipt correction field: ReceiptCorrectionReviewEffort"
    "missing receipt correction field: ReceiptCorrectionReviewMultiplicity"
    "missing receipt correction field: ReceiptCorrectionReviewVerdict"
  )
  for correction_field_index in "${!correction_fields[@]}"; do
    correction_field="${correction_fields[${correction_field_index}]}"
    prepare_receipt_correction_fixture \
      "${correction_fixture_root}" "${correction_candidate_sha}"
    sed -i.bak "/^${correction_field} = /d" "${correction_fixture_state}"
    rm "${correction_fixture_state}.bak"
    bad_correction_receipt="$(commit_receipt_correction_ledger \
      "${correction_fixture_root}" \
      "test: correction missing ${correction_field}")"
    expect_model_route_transition_failure \
      "${correction_fixture_root}" "${correction_fixture_cards}" \
      "${correction_candidate_sha}" "${bad_correction_receipt}" \
      "${correction_missing_messages[${correction_field_index}]}" \
      "${invocation_tmp}" "${invocation_marker}" \
      "receipt correction missing ${correction_field}"

    prepare_receipt_correction_fixture \
      "${correction_fixture_root}" "${correction_candidate_sha}"
    sed -n "/^${correction_field} = /p" "${correction_fixture_state}" >> \
      "${correction_fixture_state}"
    bad_correction_receipt="$(commit_receipt_correction_ledger \
      "${correction_fixture_root}" \
      "test: correction duplicates ${correction_field}")"
    expect_model_route_transition_failure \
      "${correction_fixture_root}" "${correction_fixture_cards}" \
      "${correction_candidate_sha}" "${bad_correction_receipt}" \
      "duplicate receipt correction field: ${correction_field}" \
      "${invocation_tmp}" "${invocation_marker}" \
      "receipt correction duplicate ${correction_field}"
  done

  local -a correction_route_values correction_route_messages correction_route_labels
  local correction_route_index
  correction_route_values=(
    deep_reviewer+ultra_gatekeeper
    ultra_gatekeeper
    deep_reviewer+ultra_gatekeeper
  )
  correction_route_messages=(
    "receipt correction must not use the historical stacked review route"
    "receipt correction must not claim an unexecuted Ultra review"
    "fixed receipt correction does not authorize Ultra replacement"
  )
  correction_route_labels=(
    "old stacked correction route"
    "Ultra route without an allowed recorded reason"
    "allowed reason with an actual route mismatch"
  )
  for correction_route_index in "${!correction_route_values[@]}"; do
    prepare_receipt_correction_fixture \
      "${correction_fixture_root}" "${correction_candidate_sha}"
    set_field "${correction_fixture_state}" ReceiptCorrectionReviewRoute \
      "${correction_route_values[${correction_route_index}]}"
    if [[ "${correction_route_index}" -eq 2 ]]; then
      insert_field_after "${correction_fixture_state}" \
        ReceiptCorrectionReviewRoute ReceiptCorrectionUltraEscalationReason \
        DIRECT_USER_INSTRUCTION
    fi
    bad_correction_receipt="$(commit_receipt_correction_ledger \
      "${correction_fixture_root}" \
      "test: ${correction_route_labels[${correction_route_index}]}")"
    expect_model_route_transition_failure \
      "${correction_fixture_root}" "${correction_fixture_cards}" \
      "${correction_candidate_sha}" "${bad_correction_receipt}" \
      "${correction_route_messages[${correction_route_index}]}" \
      "${invocation_tmp}" "${invocation_marker}" \
      "${correction_route_labels[${correction_route_index}]}"
  done

  # Fixed authority provenance is ancestry plus byte/mode identity, never a
  # copied final tree.  Each fixture is a real Git repository and is sent to
  # the public static verifier.
  local -a absent_authority_bases absent_authority_messages absent_authority_labels
  local absent_authority_index absent_fixture_root absent_fixture_cards
  absent_authority_bases=(
    "${correction_origin_sha}"
    "${correction_spec_sha}"
    "${correction_plan_sha}"
    "${model_route_design_sha}"
  )
  absent_authority_messages=(
    "fixed receipt-correction specification is absent from candidate ancestry"
    "fixed receipt-correction plan is absent from candidate ancestry"
    "fixed model-route design is absent from candidate ancestry"
    "fixed model-route plan is absent from candidate ancestry"
  )
  absent_authority_labels=(
    "copied final tree without correction-spec ancestry"
    "copied final tree without correction-plan ancestry"
    "copied final tree without model-route-design ancestry"
    "copied final tree without model-route-plan ancestry"
  )
  for absent_authority_index in "${!absent_authority_bases[@]}"; do
    absent_fixture_root="${test_tmp_root}/absent-authority-${absent_authority_index}"
    git clone --shared -q "${repo_root}" "${absent_fixture_root}"
    copy_candidate_tree_onto_base "${absent_fixture_root}" \
      "${absent_authority_bases[${absent_authority_index}]}" \
      "${correction_candidate_sha}" \
      "test: ${absent_authority_labels[${absent_authority_index}]}" >/dev/null
    absent_fixture_cards="${absent_fixture_root}/docs/task-cards/visual-style-baseline"
    expect_model_route_static_failure "${absent_fixture_root}" \
      "${absent_fixture_cards}" \
      "${absent_authority_messages[${absent_authority_index}]}" \
      "${invocation_tmp}" "${invocation_marker}" \
      "${absent_authority_labels[${absent_authority_index}]}"
  done

  local -a fixed_authority_paths
  local fixed_authority_index drift_fixture_root drift_fixture_cards
  fixed_authority_paths=(
    docs/superpowers/specs/2026-08-13-cognitura-vsb-receipt-correction-design.md
    docs/superpowers/plans/2026-08-13-cognitura-vsb-receipt-correction.md
    docs/superpowers/specs/2026-08-13-cognitura-model-gate-routing-design.md
    docs/superpowers/plans/2026-08-13-cognitura-model-gate-routing.md
  )
  for fixed_authority_index in "${!fixed_authority_paths[@]}"; do
    drift_fixture_root="${test_tmp_root}/authority-blob-drift-${fixed_authority_index}"
    git clone --shared -q "${repo_root}" "${drift_fixture_root}"
    git -C "${drift_fixture_root}" checkout -q --detach \
      "${correction_candidate_sha}"
    printf '\nauthority-drift\n' >> \
      "${drift_fixture_root}/${fixed_authority_paths[${fixed_authority_index}]}"
    git -C "${drift_fixture_root}" add -- \
      "${fixed_authority_paths[${fixed_authority_index}]}"
    git -C "${drift_fixture_root}" commit -qm \
      "test: drift fixed authority ${fixed_authority_index}"
    drift_fixture_cards="${drift_fixture_root}/docs/task-cards/visual-style-baseline"
    expect_model_route_static_failure "${drift_fixture_root}" \
      "${drift_fixture_cards}" \
      "fixed correction authority blob drifted: ${fixed_authority_paths[${fixed_authority_index}]}" \
      "${invocation_tmp}" "${invocation_marker}" \
      "fixed authority blob drift ${fixed_authority_index}"

    drift_fixture_root="${test_tmp_root}/authority-mode-drift-${fixed_authority_index}"
    git clone --shared -q "${repo_root}" "${drift_fixture_root}"
    git -C "${drift_fixture_root}" checkout -q --detach \
      "${correction_candidate_sha}"
    chmod +x "${drift_fixture_root}/${fixed_authority_paths[${fixed_authority_index}]}"
    git -C "${drift_fixture_root}" add -- \
      "${fixed_authority_paths[${fixed_authority_index}]}"
    git -C "${drift_fixture_root}" commit -qm \
      "test: change fixed authority mode ${fixed_authority_index}"
    drift_fixture_cards="${drift_fixture_root}/docs/task-cards/visual-style-baseline"
    expect_model_route_static_failure "${drift_fixture_root}" \
      "${drift_fixture_cards}" \
      "fixed correction authority mode drifted: ${fixed_authority_paths[${fixed_authority_index}]}" \
      "${invocation_tmp}" "${invocation_marker}" \
      "fixed authority mode drift ${fixed_authority_index}"
  done

  # Restoring the tip blob does not erase an intermediate immutable-authority
  # violation in the origin-exclusive governance chain.
  drift_fixture_root="${test_tmp_root}/authority-intermediate-drift"
  git clone --shared -q "${repo_root}" "${drift_fixture_root}"
  git -C "${drift_fixture_root}" checkout -q --detach \
    "${correction_candidate_sha}"
  printf '\nintermediate-authority-drift\n' >> \
    "${drift_fixture_root}/${fixed_authority_paths[0]}"
  git -C "${drift_fixture_root}" add -- "${fixed_authority_paths[0]}"
  git -C "${drift_fixture_root}" commit -qm \
    "test: drift immutable correction authority"
  git -C "${drift_fixture_root}" checkout -q \
    "${correction_candidate_sha}" -- "${fixed_authority_paths[0]}"
  git -C "${drift_fixture_root}" commit -qm \
    "test: restore immutable correction authority"
  drift_fixture_cards="${drift_fixture_root}/docs/task-cards/visual-style-baseline"
  expect_model_route_static_failure "${drift_fixture_root}" \
    "${drift_fixture_cards}" \
    "fixed correction authority changed in an intermediate governance commit: ${fixed_authority_paths[0]}" \
    "${invocation_tmp}" "${invocation_marker}" \
    "intermediate immutable authority drift restored at tip"

  local -a chain_mutations chain_messages chain_labels
  local chain_index chain_fixture_root chain_fixture_cards
  chain_mutations=(omit extra empty merge rename copy low-limit ledger nul newline mode)
  chain_messages=(
    "receipt correction chain must have the exact ten-path cumulative WriteSet"
    "receipt correction chain contains a path outside the exact ten-path WriteSet"
    "receipt correction governance commit must be non-empty"
    "receipt correction governance commit must have exactly one parent"
    "receipt correction governance chain must not rename or copy paths"
    "receipt correction governance chain must not rename or copy paths"
    "receipt correction governance chain must not rename or copy paths"
    "receipt correction governance chain must not change the execution ledger"
    "receipt correction governance path must not contain NUL bytes"
    "receipt correction governance path must not contain a newline"
    "receipt correction governance commit changed path mode"
  )
  chain_labels=(
    "path omission" "extra path" "empty commit" "merge commit"
    "rename" "copy" "low diff.renameLimit rename" "intermediate ledger drift"
    "governance NUL" "newline path" "mode drift"
  )
  for chain_index in "${!chain_mutations[@]}"; do
    chain_fixture_root="${test_tmp_root}/chain-${chain_mutations[${chain_index}]}"
    git clone --shared -q "${repo_root}" "${chain_fixture_root}"
    mutate_receipt_correction_chain "${chain_fixture_root}" \
      "${chain_mutations[${chain_index}]}" "${correction_candidate_sha}" \
      "${correction_origin_sha}" "${ledger_path}"
    chain_fixture_cards="${chain_fixture_root}/docs/task-cards/visual-style-baseline"
    expect_model_route_static_failure "${chain_fixture_root}" \
      "${chain_fixture_cards}" "${chain_messages[${chain_index}]}" \
      "${invocation_tmp}" "${invocation_marker}" \
      "correction chain ${chain_labels[${chain_index}]}"
  done

  # Exact version-3 transform values.  The field set above tests cardinality;
  # this literal table tests each semantic binding independently.
  local -a correction_value_fields correction_bad_values correction_value_messages
  local correction_value_index
  correction_value_fields=(
    ReceiptCorrectionStatus
    ReceiptCorrectionSpecSHA
    ReceiptCorrectionOriginReceiptSHA
    ReceiptCorrectionReviewedCandidateSHA
    ReceiptCorrectionReviewLevel
    ReceiptCorrectionReviewRoute
    ReceiptCorrectionReviewEffort
    ReceiptCorrectionReviewMultiplicity
    ReceiptCorrectionReviewVerdict
    ExecutionStateVersion
    NextTaskCard
    TransitionSequence
    TransitionKind
    TransitionBaseSHA
  )
  correction_bad_values=(
    PENDING
    "${model_route_design_sha}"
    "${reviewed_vsb01_sha}"
    "${reviewed_vsb01_sha}"
    L3
    main_or_worker
    high
    TWO
    GO_P0_0_P1_0_P2_0
    2
    VSB-02
    4
    ADVANCE
    "${correction_origin_sha}"
  )
  correction_value_messages=(
    "ReceiptCorrectionStatus must be PASS"
    "receipt correction approved spec SHA mismatch"
    "receipt correction origin SHA mismatch"
    "receipt correction reviewed candidate SHA mismatch"
    "receipt correction review level mismatch"
    "receipt correction review route mismatch"
    "receipt correction review effort mismatch"
    "receipt correction review multiplicity mismatch"
    "receipt correction review verdict mismatch"
    "RECEIPT_CORRECTION must upgrade ExecutionStateVersion from 2 to 3"
    "receipt correction NextTaskCard must be VSB-03"
    "RECEIPT_CORRECTION TransitionSequence must be 5"
    "receipt transition kind must be RECEIPT_CORRECTION"
    "receipt TransitionBaseSHA must equal its fixed BASE"
  )
  for correction_value_index in "${!correction_value_fields[@]}"; do
    prepare_receipt_correction_fixture \
      "${correction_fixture_root}" "${correction_candidate_sha}"
    set_field "${correction_fixture_state}" \
      "${correction_value_fields[${correction_value_index}]}" \
      "${correction_bad_values[${correction_value_index}]}"
    bad_correction_receipt="$(commit_receipt_correction_ledger \
      "${correction_fixture_root}" \
      "test: wrong correction value ${correction_value_index}")"
    expect_model_route_transition_failure \
      "${correction_fixture_root}" "${correction_fixture_cards}" \
      "${correction_candidate_sha}" "${bad_correction_receipt}" \
      "${correction_value_messages[${correction_value_index}]}" \
      "${invocation_tmp}" "${invocation_marker}" \
      "wrong correction value ${correction_value_index}"
  done

  prepare_receipt_correction_fixture \
    "${correction_fixture_root}" "${correction_candidate_sha}"
  bad_correction_receipt="$(commit_receipt_correction_ledger \
    "${correction_fixture_root}" \
    "test: correction receipt with extra path" \
    docs/engineering/receipt-correction-extra.md)"
  expect_model_route_transition_failure \
    "${correction_fixture_root}" "${correction_fixture_cards}" \
    "${correction_candidate_sha}" "${bad_correction_receipt}" \
    "receipt diff must contain only execution-state.md" \
    "${invocation_tmp}" "${invocation_marker}" \
    "correction receipt with extra path"

  prepare_receipt_correction_fixture \
    "${correction_fixture_root}" "${correction_candidate_sha}"
  printf '\000' >> "${correction_fixture_state}"
  bad_correction_receipt="$(commit_receipt_correction_ledger \
    "${correction_fixture_root}" \
    "test: correction receipt containing NUL")"
  expect_model_route_transition_failure \
    "${correction_fixture_root}" "${correction_fixture_cards}" \
    "${correction_candidate_sha}" "${bad_correction_receipt}" \
    "transition ledger must not contain NUL bytes" \
    "${invocation_tmp}" "${invocation_marker}" \
    "NUL in correction receipt ledger"

  prepare_receipt_correction_fixture \
    "${correction_fixture_root}" "${correction_candidate_sha}"
  printf '\n' >> "${correction_fixture_state}"
  bad_correction_receipt="$(commit_receipt_correction_ledger \
    "${correction_fixture_root}" \
    "test: correction receipt newline drift")"
  expect_model_route_transition_failure \
    "${correction_fixture_root}" "${correction_fixture_cards}" \
    "${correction_candidate_sha}" "${bad_correction_receipt}" \
    "RECEIPT_CORRECTION receipt must be the exact approved ledger transform" \
    "${invocation_tmp}" "${invocation_marker}" \
    "correction receipt newline drift"

  prepare_receipt_correction_fixture \
    "${correction_fixture_root}" "${correction_candidate_sha}"
  chmod +x "${correction_fixture_state}"
  bad_correction_receipt="$(commit_receipt_correction_ledger \
    "${correction_fixture_root}" \
    "test: correction receipt ledger mode drift")"
  expect_model_route_transition_failure \
    "${correction_fixture_root}" "${correction_fixture_cards}" \
    "${correction_candidate_sha}" "${bad_correction_receipt}" \
    "RECEIPT_CORRECTION receipt ledger mode must remain canonical" \
    "${invocation_tmp}" "${invocation_marker}" \
    "correction receipt ledger mode drift"

  local -a exact_transform_mutations exact_transform_labels
  local exact_transform_index
  exact_transform_mutations=(reorder unknown origin-byte)
  exact_transform_labels=(
    "correction fields reordered"
    "unknown correction field"
    "unlisted origin byte changed"
  )
  for exact_transform_index in "${!exact_transform_mutations[@]}"; do
    prepare_receipt_correction_fixture \
      "${correction_fixture_root}" "${correction_candidate_sha}"
    mutate_exact_receipt_correction_ledger "${correction_fixture_state}" \
      "${exact_transform_mutations[${exact_transform_index}]}"
    bad_correction_receipt="$(commit_receipt_correction_ledger \
      "${correction_fixture_root}" \
      "test: ${exact_transform_labels[${exact_transform_index}]}")"
    expect_model_route_transition_failure \
      "${correction_fixture_root}" "${correction_fixture_cards}" \
      "${correction_candidate_sha}" "${bad_correction_receipt}" \
      "RECEIPT_CORRECTION receipt must be the exact approved ledger transform" \
      "${invocation_tmp}" "${invocation_marker}" \
      "${exact_transform_labels[${exact_transform_index}]}"
  done

  # O2 cannot be substituted for R2, and the correction must be direct,
  # single-parent, terminal, ledger-only, and exactly once.
  local -a current_route_card_paths
  local current_route_card_path
  current_route_card_paths=(
    docs/task-cards/visual-style-baseline/README.md
    docs/task-cards/visual-style-baseline/VSB-02-module-default-reading-visual.md
    docs/task-cards/visual-style-baseline/VSB-03-fixed-visual-acceptance.md
  )
  git -C "${correction_fixture_root}" checkout -q --detach \
    "${correction_origin_sha}"
  git -C "${correction_fixture_root}" restore --worktree \
    --source="${correction_candidate_sha}" -- "${current_route_card_paths[@]}"
  [[ "$(git -C "${correction_fixture_root}" rev-parse HEAD)" == \
     "${correction_origin_sha}" ]] ||
    fail "ordinary O2 negative changed HEAD while adopting current route cards"
  [[ "$(git -C "${correction_fixture_root}" hash-object \
    "${correction_fixture_root}/${ledger_path}")" == \
     "$(git -C "${correction_fixture_root}" rev-parse \
       "${correction_origin_sha}:${ledger_path}")" ]] ||
    fail "ordinary O2 negative did not retain the fixed O2 worktree ledger"
  for current_route_card_path in "${current_route_card_paths[@]}"; do
    [[ "$(git -C "${correction_fixture_root}" hash-object \
      "${correction_fixture_root}/${current_route_card_path}")" == \
       "$(git -C "${correction_fixture_root}" rev-parse \
         "${correction_candidate_sha}:${current_route_card_path}")" ]] ||
      fail "ordinary O2 negative did not adopt current candidate card: ${current_route_card_path}"
  done
  git -C "${correction_fixture_root}" diff --cached --quiet ||
    fail "ordinary O2 negative staged current route cards"
  expect_model_route_transition_failure \
    "${correction_fixture_root}" "${correction_fixture_cards}" \
    "${reviewed_vsb01_sha}" "${correction_origin_sha}" \
    "IN_PROGRESS active, released, or next card mismatch" \
    "${invocation_tmp}" "${invocation_marker}" \
    "ordinary O2 substituted for receipt correction"
  git -C "${correction_fixture_root}" restore --worktree \
    --source=HEAD -- "${current_route_card_paths[@]}"
  git -C "${correction_fixture_root}" diff --quiet ||
    fail "ordinary O2 negative left worktree residue after restoring route cards"

  git -C "${correction_fixture_root}" checkout -q --detach \
    "${correction_candidate_sha}"
  git -C "${correction_fixture_root}" commit --allow-empty -qm \
    "test: interpose empty commit before correction receipt"
  local correction_nondirect_receipt
  write_exact_receipt_correction_ledger \
    "${correction_fixture_root}" "${correction_candidate_sha}"
  correction_nondirect_receipt="$(commit_receipt_correction_ledger \
    "${correction_fixture_root}" \
    "test: non-direct correction receipt")"
  expect_model_route_transition_failure \
    "${correction_fixture_root}" "${correction_fixture_cards}" \
    "${correction_candidate_sha}" "${correction_nondirect_receipt}" \
    "transition HEAD must be a direct child of transition BASE" \
    "${invocation_tmp}" "${invocation_marker}" \
    "non-direct correction receipt"

  prepare_receipt_correction_fixture \
    "${correction_fixture_root}" "${correction_candidate_sha}"
  local correction_merge_receipt
  git -C "${correction_fixture_root}" switch -q -c correction-receipt-side
  commit_receipt_correction_ledger \
    "${correction_fixture_root}" \
    "test: correction receipt side" >/dev/null
  git -C "${correction_fixture_root}" switch -q -c correction-receipt-main \
    "${correction_candidate_sha}"
  git -C "${correction_fixture_root}" commit --allow-empty -qm \
    "test: competing correction receipt parent"
  git -C "${correction_fixture_root}" merge -q --no-ff \
    correction-receipt-side -m "test: merge correction receipt"
  correction_merge_receipt="$(git -C "${correction_fixture_root}" rev-parse HEAD)"
  expect_model_route_transition_failure \
    "${correction_fixture_root}" "${correction_fixture_cards}" \
    "${correction_candidate_sha}" "${correction_merge_receipt}" \
    "transition HEAD must have exactly one parent" \
    "${invocation_tmp}" "${invocation_marker}" \
    "merged correction receipt"

  git -C "${correction_fixture_root}" checkout -q --detach \
    "${correction_receipt_sha}"
  git -C "${correction_fixture_root}" commit --allow-empty -qm \
    "test: place legal correction receipt below repository tip"
  expect_model_route_transition_failure \
    "${correction_fixture_root}" "${correction_fixture_cards}" \
    "${correction_candidate_sha}" "${correction_receipt_sha}" \
    "transition HEAD must equal repository HEAD" \
    "${invocation_tmp}" "${invocation_marker}" \
    "non-tip correction receipt"

  git -C "${correction_fixture_root}" checkout -q --detach \
    "${correction_receipt_sha}"
  set_field "${correction_fixture_state}" TransitionSequence 6
  set_field "${correction_fixture_state}" TransitionBaseSHA \
    "${correction_receipt_sha}"
  local second_correction_sha
  second_correction_sha="$(commit_receipt_correction_ledger \
    "${correction_fixture_root}" \
    "test: second receipt correction")"
  expect_model_route_transition_failure \
    "${correction_fixture_root}" "${correction_fixture_cards}" \
    "${correction_receipt_sha}" "${second_correction_sha}" \
    "RECEIPT_CORRECTION is allowed exactly once" \
    "${invocation_tmp}" "${invocation_marker}" \
    "second receipt correction"

  git -C "${correction_fixture_root}" checkout -q --detach \
    "${correction_receipt_sha}"
  set_legal_stop_by_user \
    "${correction_fixture_state}" "${correction_receipt_sha}"
  set_field "${correction_fixture_state}" ReceiptCorrectionReviewEffort high
  local mutated_correction_receipt
  mutated_correction_receipt="$(commit_receipt_correction_ledger \
    "${correction_fixture_root}" \
    "test: mutate correction fields after R2")"
  expect_model_route_transition_failure \
    "${correction_fixture_root}" "${correction_fixture_cards}" \
    "${correction_receipt_sha}" "${mutated_correction_receipt}" \
    "ordinary version-3 transition must preserve ReceiptCorrection fields" \
    "${invocation_tmp}" "${invocation_marker}" \
    "post-R2 correction-field mutation"

  [[ "${correction_positive_cases}" -eq 4 ]] ||
    fail "Cycle B positive matrix count drifted from 4"
  [[ "${receipt_correction_negative_cases}" -eq 72 ]] ||
    fail "Cycle B negative matrix count drifted from 72"
  printf '%s\n' \
    "ReceiptCorrectionContractTests = PASS" \
    "ReceiptCorrectionPositiveCases = ${correction_positive_cases}" \
    "ReceiptCorrectionNegativeCases = ${receipt_correction_negative_cases}"

  printf '%s\n' "RouteCardContractTests = PASS"
  printf '%s\n' "RouteCardContractPositiveCases = 2"
  printf '%s\n' "RouteCardContractNegativeCases = ${route_card_negative_cases}"
  printf '%s\n' "RouteCardContractCases = $((2 + route_card_negative_cases))"
  return 0
}

if [[ "${model_gate_routing_contract_only}" -eq 1 ]]; then
  run_model_gate_routing_contract
  exit 0
fi

fixed_lifecycle_fixture_sha="c4d1f4342b16d2110369c4eefea5665edce0614d"
git -C "${repo_root}" cat-file -e \
  "${fixed_lifecycle_fixture_sha}^{commit}" 2>/dev/null ||
  fail "fixed lifecycle fixture commit is unavailable: ${fixed_lifecycle_fixture_sha}"

fixed_bootstrap_root="${test_tmp_root}/fixed-bootstrap"
mkdir -p "${fixed_bootstrap_root}"
git -C "${repo_root}" archive "${fixed_lifecycle_fixture_sha}" \
  docs/task-cards/visual-style-baseline | tar -x -C "${fixed_bootstrap_root}"
bootstrap_cards_dir="${fixed_bootstrap_root}/docs/task-cards/visual-style-baseline"

fixed_wave1_projection_paths=(
  AGENTS.md
  README.md
  docs/design/wave-1/README.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-plan.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1/README.md
  docs/task-cards/wave-1-implementation/README.md
  docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md
)

# Required RED: the verifier and governed set do not exist before Task 1.
[[ -x "${verifier}" ]] || fail "Visual Style Baseline task-card verifier is missing or not executable"
[[ -d "${cards_dir}" ]] || fail "Visual Style Baseline task-card set is missing"

expect_clean_early_exit 2 \
  'Usage: scripts/verify-visual-style-baseline-cards [--repo-root PATH] --cards-dir PATH [--transition-base SHA --transition-head SHA]'
missing_cards_dir="${test_tmp_root}/missing-cards-dir"
expect_clean_early_exit 1 \
  $'VisualStyleBaselineTaskCardValidation = FAIL\ncards directory does not exist: '"${missing_cards_dir}" \
  --repo-root "${repo_root}" --cards-dir "${missing_cards_dir}"
early_exit_cases=2

registered_cleanup_tmp="${test_tmp_root}/registered-cleanup"
registered_cleanup_cards="${test_tmp_root}/registered-cleanup-cards"
mkdir -p "${registered_cleanup_tmp}"
registered_cleanup_marker="${registered_cleanup_tmp}/sibling-marker"
printf 'preserve sibling\n' > "${registered_cleanup_marker}"
cp -R "${bootstrap_cards_dir}" "${registered_cleanup_cards}"
printf '\0' >> "${registered_cleanup_cards}/execution-state.md"
if registered_cleanup_output="$(
  TMPDIR="${registered_cleanup_tmp}" "${verifier}" \
    --repo-root "${repo_root}" \
    --cards-dir "${registered_cleanup_cards}" 2>&1
)"; then
  fail "NUL ledger cleanup negative unexpectedly passed"
else
  registered_cleanup_rc=$?
fi
[[ "${registered_cleanup_rc}" -eq 1 ]] ||
  fail "NUL ledger cleanup returned ${registered_cleanup_rc}, expected 1"
[[ "${registered_cleanup_output}" == $'VisualStyleBaselineTaskCardValidation = FAIL\ntransition ledger must not contain NUL bytes' ]] ||
  fail "NUL ledger cleanup polluted its diagnostic: ${registered_cleanup_output}"
shopt -s nullglob
registered_cleanup_leaks=(
  "${registered_cleanup_tmp}"/cognitura-vsb-verifier.*
)
shopt -u nullglob
[[ "${#registered_cleanup_leaks[@]}" -eq 0 ]] ||
  fail "VSB verifier leaked its invocation root after NUL early failure"
[[ -f "${registered_cleanup_marker}" &&
   "$(cat "${registered_cleanup_marker}")" == "preserve sibling" ]] ||
  fail "VSB verifier removed or changed a sibling during NUL early failure"
shopt -s nullglob
registered_cleanup_entries=("${registered_cleanup_tmp}"/*)
shopt -u nullglob
[[ "${#registered_cleanup_entries[@]}" -eq 1 &&
   "${registered_cleanup_entries[0]}" == "${registered_cleanup_marker}" ]] ||
  fail "NUL early failure left temporary entries outside the sibling marker"
registered_temporary_cleanup_cases=1

negative_cases=0
if [[ "${repair_contract_only}" -eq 0 ]]; then
validation_output="$(
  "${verifier}" \
    --repo-root "${repo_root}" \
    --cards-dir "${bootstrap_cards_dir}"
)" || fail "canonical Visual Style Baseline state was rejected"
assert_contains "${validation_output}" "VisualStyleBaselineTaskCardValidation = PASS"
assert_contains "${validation_output}" "TaskCardCount = 4"

# At the real governance candidate G, static validation must distinguish the
# approved pending repair from an ordinary receipt without mutating the ledger.
current_governance_repair_output="$(
  "${verifier}" --repo-root "${repo_root}" --cards-dir "${cards_dir}"
)" || fail "current governance repair candidate was rejected"
assert_contains "${current_governance_repair_output}" \
  "VisualStyleBaselineTaskCardValidation = PASS"
assert_contains "${current_governance_repair_output}" \
  "GovernanceRepairStatus = PENDING"

missing_state_dir="${test_tmp_root}/missing-state"
cp -R "${bootstrap_cards_dir}" "${missing_state_dir}"
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
  cp -R "${bootstrap_cards_dir}" "${missing_field_dir}"
  sed -i.bak "/^${field} = /d" "${missing_field_dir}/execution-state.md"
  rm "${missing_field_dir}/execution-state.md.bak"
  expect_failure "${missing_field_dir}" "${field} must occur exactly once"

  duplicate_field_dir="${test_tmp_root}/duplicate-${field}"
  cp -R "${bootstrap_cards_dir}" "${duplicate_field_dir}"
  value="$(sed -n "s/^${field} = //p" "${duplicate_field_dir}/execution-state.md")"
  printf '%s = %s\n' "${field}" "${value}" >> \
    "${duplicate_field_dir}/execution-state.md"
  expect_failure "${duplicate_field_dir}" "${field} must occur exactly once"
done

fifth_card_dir="${test_tmp_root}/fifth-card"
cp -R "${bootstrap_cards_dir}" "${fifth_card_dir}"
cp "${fifth_card_dir}/VSB-03-fixed-visual-acceptance.md" \
  "${fifth_card_dir}/VSB-04-invented.md"
set_field "${fifth_card_dir}/VSB-04-invented.md" "TaskCardID" "VSB-04"
expect_failure "${fifth_card_dir}" "actual task card count 5 does not match 4"

unknown_id_dir="${test_tmp_root}/unknown-id"
cp -R "${bootstrap_cards_dir}" "${unknown_id_dir}"
set_field "${unknown_id_dir}/VSB-02-module-default-reading-visual.md" "TaskCardID" "VSB-99"
expect_failure "${unknown_id_dir}" "TaskCardID mismatch"

mutable_status_dir="${test_tmp_root}/mutable-status"
cp -R "${bootstrap_cards_dir}" "${mutable_status_dir}"
set_field "${mutable_status_dir}/VSB-01-semantic-tokens.md" "Status" "READY"
expect_failure "${mutable_status_dir}" "Status must be GOVERNED_BY_EXECUTION_STATE"

card_body_drift_dir="${test_tmp_root}/card-body-drift"
cp -R "${bootstrap_cards_dir}" "${card_body_drift_dir}"
printf '\nunauthorized body drift\n' >> \
  "${card_body_drift_dir}/VSB-01-semantic-tokens.md"
expect_failure "${card_body_drift_dir}" "card body contract digest mismatch for VSB-01"

wrong_spec_dir="${test_tmp_root}/wrong-spec"
cp -R "${bootstrap_cards_dir}" "${wrong_spec_dir}"
set_field "${wrong_spec_dir}/execution-state.md" "ApprovedSpecSHA" \
  "4e63936c631ab34807e714b90d30415a959bc13d"
expect_failure "${wrong_spec_dir}" "ApprovedSpecSHA mismatch"

wrong_frozen_dir="${test_tmp_root}/wrong-frozen"
cp -R "${bootstrap_cards_dir}" "${wrong_frozen_dir}"
set_field "${wrong_frozen_dir}/execution-state.md" "FrozenWave1CandidateSHA" \
  "70eefba5912e6884e4e7e1d6477a65f4091d6590"
expect_failure "${wrong_frozen_dir}" "FrozenWave1CandidateSHA mismatch"

premature_activation_dir="${test_tmp_root}/premature-activation"
cp -R "${bootstrap_cards_dir}" "${premature_activation_dir}"
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
  cp -R "${bootstrap_cards_dir}" "${overwritten_receipt_dir}"
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
  cp -R "${bootstrap_cards_dir}" "${forbidden_dir}"
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
fi

# Real Git state transitions: candidate commits may contain business files, but
# every release/rollback/complete receipt is a direct child that changes only
# execution-state.md.
transition_repo_root="${test_tmp_root}/transition-repo"
git clone --shared -q "${repo_root}" "${transition_repo_root}"
git -C "${transition_repo_root}" checkout -q --detach \
  "${fixed_lifecycle_fixture_sha}"
git -C "${transition_repo_root}" add \
  docs/engineering/cognitura-wave-1-design-acceptance.md \
  docs/task-cards/visual-style-baseline \
  docs/task-cards/wave-1-implementation
git -C "${transition_repo_root}" commit --allow-empty -qm \
  "test: establish VSB bootstrap fixture"

transition_cards="${transition_repo_root}/docs/task-cards/visual-style-baseline"
transition_state="${transition_cards}/execution-state.md"
wave1_restore_paths=("${fixed_wave1_projection_paths[@]}")
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

commit_candidate_subset() {
  local fixture_root="$1"
  local subject="$2"
  shift 2
  local candidate_path
  for candidate_path in "$@"; do
    mkdir -p "${fixture_root}/$(dirname "${candidate_path}")"
    if [[ -f "${fixture_root}/${candidate_path}" ]]; then
      printf '\nround-marker=%s\n' "${subject}" >> \
        "${fixture_root}/${candidate_path}"
    else
      printf 'round-marker=%s\n' "${subject}" > \
        "${fixture_root}/${candidate_path}"
    fi
  done
  git -C "${fixture_root}" add -- "$@"
  git -C "${fixture_root}" commit -qm "${subject}"
  git -C "${fixture_root}" rev-parse HEAD
}

make_vsb00_advance_receipt() {
  local candidate_sha="$1"
  local subject="$2"
  local reviewed_sha="${3:-${candidate_sha}}"
  local sequence="${4:-2}"
  set_field "${transition_state}" "CompletedTaskCards" "VSB-00"
  set_field "${transition_state}" "ActiveTaskCard" "VSB-01"
  set_field "${transition_state}" "ReleasedTaskCard" "VSB-01"
  set_field "${transition_state}" "CurrentCandidateSHA" "${reviewed_sha}"
  set_field "${transition_state}" "CurrentGateStatus" "VSB-G0_PASS"
  set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
  set_field "${transition_state}" "CurrentReviewVerdict" \
    "GO_P0_0_P1_0_P2_0"
  set_field "${transition_state}" "VSB00CandidateSHA" "${reviewed_sha}"
  set_field "${transition_state}" "VSB00GateStatus" "VSB-G0_PASS"
  set_field "${transition_state}" "VSB00ReviewVerdict" \
    "GO_P0_0_P1_0_P2_0"
  set_field "${transition_state}" "NextTaskCard" "VSB-02"
  set_field "${transition_state}" "TransitionSequence" "${sequence}"
  set_field "${transition_state}" "TransitionKind" "ADVANCE"
  set_field "${transition_state}" "TransitionBaseSHA" "${candidate_sha}"
  git -C "${transition_repo_root}" add \
    docs/task-cards/visual-style-baseline/execution-state.md
  git -C "${transition_repo_root}" commit -qm "${subject}"
  git -C "${transition_repo_root}" rev-parse HEAD
}

run_vsb_transition() {
  local transition_base_sha="$1"
  local transition_head_sha="$2"
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${transition_base_sha}" \
    --transition-head "${transition_head_sha}" 2>&1
}

expect_transition_failure() {
  local transition_base_sha="$1"
  local transition_head_sha="$2"
  local expected_message="$3"
  local label="$4"
  local output
  if output="$(run_vsb_transition \
    "${transition_base_sha}" "${transition_head_sha}")"; then
    fail "${label} unexpectedly passed"
  fi
  [[ "${output}" == *"${expected_message}"* ]] ||
    fail "${label}: expected '${expected_message}', got: ${output}"
  negative_cases=$((negative_cases + 1))
  cumulative_candidate_negative_cases=$((cumulative_candidate_negative_cases + 1))
}

expect_repair_transition_failure() {
  local fixture_root="$1"
  local fixture_cards="$2"
  local transition_base_sha="$3"
  local transition_head_sha="$4"
  local expected_message="$5"
  local label="$6"
  local output
  if output="$("${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir "${fixture_cards}" \
    --transition-base "${transition_base_sha}" \
    --transition-head "${transition_head_sha}" 2>&1)"; then
    fail "${label} unexpectedly passed"
  fi
  assert_contains "${output}" "${expected_message}"
  negative_cases=$((negative_cases + 1))
  governance_repair_negative_cases=$((governance_repair_negative_cases + 1))
}

run_repair_static() {
  local fixture_root="$1"
  "${verifier}" \
    --repo-root "${fixture_root}" \
    --cards-dir \
      "${fixture_root}/docs/task-cards/visual-style-baseline" 2>&1
}

expect_repair_static_failure() {
  local fixture_root="$1"
  local expected_message="$2"
  local label="$3"
  local output
  if output="$(run_repair_static "${fixture_root}")"; then
    fail "${label} unexpectedly passed"
  fi
  assert_contains "${output}" "${expected_message}"
  negative_cases=$((negative_cases + 1))
  governance_repair_negative_cases=$((governance_repair_negative_cases + 1))
}

governance_repair_paths='docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md
docs/superpowers/plans/2026-08-13-cognitura-vsb-governance-repair.md
docs/task-cards/visual-style-baseline/README.md
scripts/verify-visual-style-baseline-cards
tests/task-cards/verify-visual-style-baseline-cards.sh'

commit_governance_repair_subset() {
  local fixture_root="$1"
  local subject="$2"
  shift 2
  local repair_path
  for repair_path in "$@"; do
    mkdir -p "${fixture_root}/$(dirname "${repair_path}")"
    if [[ -f "${fixture_root}/${repair_path}" ]]; then
      printf '\nrepair-marker=%s\n' "${subject}" >> \
        "${fixture_root}/${repair_path}"
    else
      printf 'repair-marker=%s\n' "${subject}" > \
        "${fixture_root}/${repair_path}"
    fi
  done
  git -C "${fixture_root}" add -- "$@"
  git -C "${fixture_root}" commit -qm "${subject}"
  git -C "${fixture_root}" rev-parse HEAD
}

commit_current_governance_repair_subset() {
  local fixture_root="$1"
  local subject="$2"
  shift 2
  local repair_path
  for repair_path in "$@"; do
    mkdir -p "${fixture_root}/$(dirname "${repair_path}")"
    cp -p "${repo_root}/${repair_path}" "${fixture_root}/${repair_path}"
  done
  git -C "${fixture_root}" add -- "$@"
  git -C "${fixture_root}" commit -qm "${subject}"
  git -C "${fixture_root}" rev-parse HEAD
}

make_governance_repair_receipt() {
  local fixture_root="$1"
  local candidate_sha="$2"
  local subject="$3"
  local override_field="${4:-}"
  local override_value="${5:-}"
  local extra_path="${6:-}"
  local append_text="${7:-}"
  local ledger_mode="${8:-}"
  local append_nul="${9:-0}"
  local fixture_state="${fixture_root}/docs/task-cards/visual-style-baseline/execution-state.md"
  set_field "${fixture_state}" ExecutionStateVersion 2
  insert_field_after "${fixture_state}" GovernanceReviewVerdict \
    GovernanceRepairStatus PASS
  insert_field_after "${fixture_state}" GovernanceRepairStatus \
    GovernanceRepairSpecSHA 2123594540c91341c480f504949315a6abec316c
  insert_field_after "${fixture_state}" GovernanceRepairSpecSHA \
    GovernanceRepairOriginReceiptSHA d47c8c7bd7355947b5e8e1de6c264d80c2e27c9a
  insert_field_after "${fixture_state}" GovernanceRepairOriginReceiptSHA \
    GovernanceRepairReviewedCandidateSHA "${candidate_sha}"
  insert_field_after "${fixture_state}" GovernanceRepairReviewedCandidateSHA \
    GovernanceRepairReviewRoute deep_reviewer+ultra_gatekeeper
  insert_field_after "${fixture_state}" GovernanceRepairReviewRoute \
    GovernanceRepairReviewVerdict FINAL_GO_P0_0_P1_0_P2_0
  set_field "${fixture_state}" TransitionSequence 3
  set_field "${fixture_state}" TransitionKind GOVERNANCE_REPAIR
  set_field "${fixture_state}" TransitionBaseSHA "${candidate_sha}"
  if [[ -n "${override_field}" ]]; then
    set_field "${fixture_state}" "${override_field}" "${override_value}"
  fi
  if [[ -n "${extra_path}" ]]; then
    mkdir -p "${fixture_root}/$(dirname "${extra_path}")"
    printf 'unauthorized repair receipt path\n' > \
      "${fixture_root}/${extra_path}"
  fi
  if [[ -n "${append_text}" ]]; then
    printf '%s\n' "${append_text}" >> "${fixture_state}"
  fi
  if [[ "${append_nul}" -eq 1 ]]; then
    printf '\000' >> "${fixture_state}"
  fi
  if [[ -n "${ledger_mode}" ]]; then
    chmod "${ledger_mode}" "${fixture_state}"
  fi
  git -C "${fixture_root}" add \
    docs/task-cards/visual-style-baseline/execution-state.md
  if [[ -n "${extra_path}" ]]; then
    git -C "${fixture_root}" add -- "${extra_path}"
  fi
  git -C "${fixture_root}" commit -qm "${subject}"
  git -C "${fixture_root}" rev-parse HEAD
}

make_wave1_restore_projection() {
  local fixture_root="$1"
  local narrative_index narrative_path
  set_field "${fixture_root}/AGENTS.md" \
    "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/AGENTS.md" \
    "ActiveImplementationTaskCard" "W1-I03"
  set_field "${fixture_root}/README.md" \
    "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/README.md" \
    "ActiveImplementationTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/design/wave-1/README.md" \
    "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/design/wave-1/README.md" \
    "ActiveImplementationGovernanceTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    "ActiveTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    "ActiveTaskCardStatus" "READY"
  set_field "${fixture_root}/docs/engineering/cognitura-design-index.md" \
    "ActiveImplementationTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-plan.md" \
    "ActiveImplementationGovernanceTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    "ImplementationTaskCardPlanStatus" "I01_COMPLETE_I03_READY"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-design-acceptance.md" \
    "ActiveImplementationGovernanceTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    "TaskCardSetStatus" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    "ActiveTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    "SuspendedTaskCard" "NONE"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    "SuspendedCandidateSHA" "NONE"
  set_field "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    "SuspendedCandidateMutation" "NONE"
  set_table_status \
    "${fixture_root}/docs/engineering/cognitura-wave-1-implementation-plan.md" \
    "W1-I03" "SUSPENDED_BY_USER" "READY"
  set_field "${fixture_root}/docs/task-cards/wave-1/README.md" \
    "Wave1ImplementationTaskCardSet" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/task-cards/wave-1/README.md" \
    "ActiveImplementationGovernanceTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "TaskCardSetStatus" "READY_FOR_EXECUTION"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "ActiveTaskCard" "W1-I03"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "SuspendedTaskCard" "NONE"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "SuspendedCandidateSHA" "NONE"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "SuspendedCandidateMutation" "NONE"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "ReadyTaskCardCount" "1"
  set_field "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "SuspendedTaskCardCount" "0"
  set_table_status \
    "${fixture_root}/docs/task-cards/wave-1-implementation/README.md" \
    "W1-I03" "SUSPENDED_BY_USER" "READY"
  set_field \
    "${fixture_root}/docs/task-cards/wave-1-implementation/W1-I03-docx-security-gate.md" \
    "Status" "READY"
  for narrative_index in "${!suspension_narratives[@]}"; do
    narrative_path="${suspension_narrative_paths[${narrative_index}]}"
    replace_exact_block \
      "${fixture_root}/${narrative_path}" \
      "${suspension_narratives[${narrative_index}]}" \
      "${ready_narratives[${narrative_index}]}" \
      "restore ${narrative_path} READY narrative"
  done
}

clear_vsb_receipt() {
  local receipt_index="$1"
  set_field "${transition_state}" "VSB0${receipt_index}CandidateSHA" "NONE"
  set_field "${transition_state}" "VSB0${receipt_index}GateStatus" "NOT_RUN"
  if [[ "${receipt_index}" -eq 3 ]]; then
    set_field "${transition_state}" "VSB03DeepReviewVerdict" "NOT_RUN"
    set_field "${transition_state}" "VSB03UltraReviewVerdict" "NOT_RUN"
  else
    set_field "${transition_state}" "VSB0${receipt_index}ReviewVerdict" "NOT_RUN"
  fi
}

prepare_return_to_owner() {
  local failed_candidate_sha="$1"
  local owner="$2"
  local completed_prefix="$3"
  local next_card="$4"
  local sequence="$5"
  local review_route="$6"
  local review_verdict="$7"
  local owner_index receipt_index
  case "${owner}" in
    VSB-00) owner_index=0 ;;
    VSB-01) owner_index=1 ;;
    VSB-02) owner_index=2 ;;
    VSB-03) owner_index=3 ;;
    *) fail "test fixture requested an unknown RETURN owner: ${owner}" ;;
  esac
  set_field "${transition_state}" "TaskCardSetStatus" "IN_PROGRESS"
  set_field "${transition_state}" "ActiveTaskCard" "${owner}"
  set_field "${transition_state}" "ReleasedTaskCard" "${owner}"
  set_field "${transition_state}" "CompletedTaskCards" "${completed_prefix}"
  set_field "${transition_state}" "CurrentCandidateSHA" \
    "${failed_candidate_sha}"
  set_field "${transition_state}" "CurrentGateStatus" "FAIL"
  set_field "${transition_state}" "CurrentReviewRoute" "${review_route}"
  set_field "${transition_state}" "CurrentReviewVerdict" "${review_verdict}"
  for ((receipt_index = owner_index; receipt_index < 4; receipt_index++)); do
    clear_vsb_receipt "${receipt_index}"
  done
  set_field "${transition_state}" "NextTaskCard" "${next_card}"
  set_field "${transition_state}" "TransitionSequence" "${sequence}"
  set_field "${transition_state}" "TransitionKind" "RETURN_TO_OWNER"
  set_field "${transition_state}" "TransitionBaseSHA" \
    "${failed_candidate_sha}"
  printf '%s\n' "Owner = ${owner}" >> "${transition_state}"
}

if [[ "${repair_contract_only}" -eq 0 ]]; then
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

git -C "${transition_repo_root}" switch -q --detach "${governance_candidate_sha}"
set_field "${transition_state}" "GovernanceBootstrapStatus" "PASS"
set_field "${transition_state}" "GovernanceReviewedCandidateSHA" \
  "${governance_candidate_sha}"
set_field "${transition_state}" "GovernanceReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "TaskCardSetStatus" "IN_PROGRESS"
set_field "${transition_state}" "ActiveTaskCard" "VSB-00"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-00"
set_field "${transition_state}" "NextTaskCard" "VSB-01"
set_field "${transition_state}" "TransitionSequence" "1"
set_field "${transition_state}" "TransitionKind" "ACTIVATE_SET"
set_field "${transition_state}" "TransitionBaseSHA" "${governance_candidate_sha}"
set_field "${transition_state}" "VisualImplementation" "USER_AUTHORIZED"
printf '\000' >> "${transition_state}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: append NUL to an otherwise valid VSB activation receipt"
nul_activation_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if nul_activation_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${governance_candidate_sha}" \
    --transition-head "${nul_activation_sha}" 2>&1
)"; then
  fail "ACTIVATE_SET receipt with NUL-byte drift unexpectedly passed"
fi
assert_contains "${nul_activation_output}" \
  "transition ledger must not contain NUL bytes"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${governance_candidate_sha}"
set_field "${transition_state}" "NextTaskCard" "VSB-03"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: forge malformed bootstrap transition base"
forged_activation_base_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "GovernanceBootstrapStatus" "PASS"
set_field "${transition_state}" "GovernanceReviewedCandidateSHA" \
  "${forged_activation_base_sha}"
set_field "${transition_state}" "GovernanceReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "TaskCardSetStatus" "IN_PROGRESS"
set_field "${transition_state}" "ActiveTaskCard" "VSB-00"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-00"
set_field "${transition_state}" "NextTaskCard" "VSB-01"
set_field "${transition_state}" "TransitionSequence" "1"
set_field "${transition_state}" "TransitionKind" "ACTIVATE_SET"
set_field "${transition_state}" "TransitionBaseSHA" "${forged_activation_base_sha}"
set_field "${transition_state}" "VisualImplementation" "USER_AUTHORIZED"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: activate from malformed bootstrap base"
forged_activation_head_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if forged_activation_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${forged_activation_base_sha}" \
    --transition-head "${forged_activation_head_sha}" 2>&1
)"; then
  fail "ACTIVATE_SET from a forged malformed BASE unexpectedly passed"
fi
assert_contains "${forged_activation_output}" \
  "transition BASE failed full VSB state validation"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
set_field "${transition_state}" "NextTaskCard" "VSB-03"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: forge malformed VSB-00 active state"
forged_advance_preparent_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "forged ADVANCE base candidate"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create candidate over malformed ADVANCE state"
forged_advance_base_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00"
set_field "${transition_state}" "ActiveTaskCard" "VSB-01"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-01"
set_field "${transition_state}" "CurrentCandidateSHA" "${forged_advance_base_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB00CandidateSHA" "${forged_advance_base_sha}"
set_field "${transition_state}" "VSB00GateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "VSB00ReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "VSB-02"
set_field "${transition_state}" "TransitionSequence" "2"
set_field "${transition_state}" "TransitionKind" "ADVANCE"
set_field "${transition_state}" "TransitionBaseSHA" "${forged_advance_base_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: advance from malformed VSB-00 base"
forged_advance_head_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if forged_advance_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${forged_advance_base_sha}" \
    --transition-head "${forged_advance_head_sha}" 2>&1
)"; then
  fail "ADVANCE from a forged malformed BASE unexpectedly passed"
fi
assert_contains "${forged_advance_output}" \
  "transition BASE failed full VSB state validation"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"

# A business candidate is the complete linear chain from the nearest valid
# Owner release receipt to the reviewed tip.  Exercise every row through the
# public fixed-transition entry.
cumulative_candidate_positive_cases=0
cumulative_candidate_negative_cases=0

cumulative_candidate_one="$(commit_candidate_subset \
  "${transition_repo_root}" "test: VSB-00 candidate round one" \
  AGENTS.md \
  docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png)"
cumulative_candidate_two="$(commit_candidate_subset \
  "${transition_repo_root}" "test: VSB-00 candidate round two" \
  docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md \
  docs/engineering/cognitura-visual-style-baseline-manifest.yaml)"
cumulative_candidate_tip="$(commit_candidate_subset \
  "${transition_repo_root}" "test: VSB-00 candidate final round" \
  docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md \
  docs/engineering/cognitura-design-index.md \
  scripts/import-visual-style-reference \
  scripts/verify-visual-style-baseline-reference \
  tests/visual-style-baseline/verify-reference.sh)"
assert_commit_parent_count "${transition_repo_root}" \
  "${cumulative_candidate_one}" 1
assert_commit_parent_count "${transition_repo_root}" \
  "${cumulative_candidate_two}" 1
assert_commit_parent_count "${transition_repo_root}" \
  "${cumulative_candidate_tip}" 1
cumulative_paths="$(git -C "${transition_repo_root}" diff --no-renames \
  --name-only "${activation_sha}..${cumulative_candidate_tip}" | LC_ALL=C sort)"
expected_cumulative_paths="$(printf '%s\n' "${candidate_write_sets[0]}" | \
  LC_ALL=C sort)"
[[ "${cumulative_paths}" == "${expected_cumulative_paths}" ]] ||
  fail "three-commit positive fixture lost the exact VSB-00 WriteSet"
cumulative_advance_sha="$(make_vsb00_advance_receipt \
  "${cumulative_candidate_tip}" \
  "test: advance three-commit VSB-00 candidate")"
cumulative_output="$(run_vsb_transition \
  "${cumulative_candidate_tip}" "${cumulative_advance_sha}")" ||
  fail "legal three-commit cumulative candidate was rejected: ${cumulative_output}"
assert_contains "${cumulative_output}" \
  "VisualStyleBaselineTaskCardValidation = PASS"
cumulative_candidate_positive_cases=$((cumulative_candidate_positive_cases + 1))

cumulative_cleanup_tmp="${test_tmp_root}/cumulative-cleanup"
mkdir -p "${cumulative_cleanup_tmp}"
cumulative_cleanup_marker="${cumulative_cleanup_tmp}/sibling-marker"
printf 'preserve sibling\n' > "${cumulative_cleanup_marker}"
TMPDIR="${cumulative_cleanup_tmp}" "${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" \
  --transition-base "${cumulative_candidate_tip}" \
  --transition-head "${cumulative_advance_sha}" >/dev/null ||
  fail "cumulative candidate cleanup probe was rejected"
shopt -s nullglob
cumulative_cleanup_leaks=("${cumulative_cleanup_tmp}"/*)
shopt -u nullglob
[[ "${#cumulative_cleanup_leaks[@]}" -eq 1 &&
   "${cumulative_cleanup_leaks[0]}" == "${cumulative_cleanup_marker}" &&
   "$(cat "${cumulative_cleanup_marker}")" == "preserve sibling" ]] ||
  fail "cumulative replay leaked temporary entries or changed its sibling marker"

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
missing_cumulative_tip="$(commit_candidate_subset \
  "${transition_repo_root}" "test: omit one VSB-00 cumulative path" \
  AGENTS.md \
  docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png \
  docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md \
  docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-visual-style-baseline-manifest.yaml \
  scripts/import-visual-style-reference \
  scripts/verify-visual-style-baseline-reference)"
missing_cumulative_receipt="$(make_vsb00_advance_receipt \
  "${missing_cumulative_tip}" "test: advance incomplete cumulative candidate")"
expect_transition_failure "${missing_cumulative_tip}" \
  "${missing_cumulative_receipt}" \
  "candidate cumulative diff must equal the exact Owner WriteSet" \
  "candidate missing one cumulative Owner path"

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "candidate with hidden mode drift"
chmod +x "${transition_repo_root}/AGENTS.md"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create candidate with hidden mode drift"
mode_drift_tip="$(git -C "${transition_repo_root}" rev-parse HEAD)"
mode_drift_receipt="$(make_vsb00_advance_receipt \
  "${mode_drift_tip}" "test: advance mode-drifted candidate")"
expect_transition_failure "${mode_drift_tip}" "${mode_drift_receipt}" \
  "candidate chain commit must preserve existing file modes" \
  "candidate containing hidden file-mode drift"

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
same_mode_recreated_path=AGENTS.md
git -C "${transition_repo_root}" rm -q -- "${same_mode_recreated_path}"
git -C "${transition_repo_root}" commit -qm \
  "test: delete Owner path before same-mode recreation"
git -C "${transition_repo_root}" show \
  "${activation_sha}:${same_mode_recreated_path}" > \
  "${transition_repo_root}/${same_mode_recreated_path}"
git -C "${transition_repo_root}" add -- "${same_mode_recreated_path}"
git -C "${transition_repo_root}" commit -qm \
  "test: recreate Owner path with the release mode"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "candidate completing WriteSet after same-mode recreation"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: complete same-mode recreated candidate"
same_mode_recreated_tip="$(git -C "${transition_repo_root}" rev-parse HEAD)"
same_mode_recreated_receipt="$(make_vsb00_advance_receipt \
  "${same_mode_recreated_tip}" \
  "test: advance same-mode recreated candidate")"
same_mode_recreated_output="$(run_vsb_transition \
  "${same_mode_recreated_tip}" "${same_mode_recreated_receipt}")" ||
  fail "legal same-mode delete-and-recreate candidate was rejected: ${same_mode_recreated_output}"
assert_contains "${same_mode_recreated_output}" \
  "VisualStyleBaselineTaskCardValidation = PASS"
cumulative_candidate_positive_cases=$((cumulative_candidate_positive_cases + 1))
fi

# One-time governance repair: use the real fixed origin, Git objects and
# byte-identical ledger.  G is a linear exact-five-path candidate; R is its
# ledger-only direct child and the sole VSB-01 release anchor.
governance_repair_positive_cases=0
governance_repair_negative_cases=0
repair_origin_sha=d47c8c7bd7355947b5e8e1de6c264d80c2e27c9a
repair_reviewed_vsb00_sha=737c053483d1f3d084d5f90d5c36f76b0ae8f5a3
repair_repo_root="${test_tmp_root}/governance-repair-repo"
git clone --shared -q "${repo_root}" "${repair_repo_root}"
git -C "${repair_repo_root}" config advice.detachedHead false
git -C "${repair_repo_root}" checkout -q --detach \
  2123594540c91341c480f504949315a6abec316c
repair_cards="${repair_repo_root}/docs/task-cards/visual-style-baseline"
repair_state="${repair_cards}/execution-state.md"

repair_round_one_sha="$(commit_current_governance_repair_subset \
  "${repair_repo_root}" "test: governance repair authority" \
  docs/superpowers/plans/2026-08-13-cognitura-vsb-governance-repair.md)"
repair_candidate_sha="$(commit_current_governance_repair_subset \
  "${repair_repo_root}" "test: governance repair contracts" \
  docs/task-cards/visual-style-baseline/README.md \
  scripts/verify-visual-style-baseline-cards \
  tests/task-cards/verify-visual-style-baseline-cards.sh)"
assert_commit_parent_count "${repair_repo_root}" "${repair_round_one_sha}" 1
assert_commit_parent_count "${repair_repo_root}" "${repair_candidate_sha}" 1
repair_actual_paths="$(git -C "${repair_repo_root}" diff --no-renames \
  --name-only "${repair_origin_sha}..${repair_candidate_sha}" | LC_ALL=C sort)"
repair_expected_paths="$(printf '%s\n' "${governance_repair_paths}" | LC_ALL=C sort)"
[[ "${repair_actual_paths}" == "${repair_expected_paths}" ]] ||
  fail "positive governance repair fixture lost the exact five-path WriteSet"
repair_origin_ledger_hash="$(git -C "${repair_repo_root}" show \
  "${repair_origin_sha}:docs/task-cards/visual-style-baseline/execution-state.md" | \
  shasum -a 256 | awk '{print $1}')"
repair_candidate_ledger_hash="$(git -C "${repair_repo_root}" show \
  "${repair_candidate_sha}:docs/task-cards/visual-style-baseline/execution-state.md" | \
  shasum -a 256 | awk '{print $1}')"
[[ "${repair_origin_ledger_hash}" == "${repair_candidate_ledger_hash}" ]] ||
  fail "positive governance repair fixture changed the origin ledger"
repair_pending_output="$(run_repair_static "${repair_repo_root}")" ||
  fail "valid pending governance repair candidate was rejected"
assert_contains "${repair_pending_output}" \
  "VisualStyleBaselineTaskCardValidation = PASS"
assert_contains "${repair_pending_output}" "GovernanceRepairStatus = PENDING"
governance_repair_positive_cases=$((governance_repair_positive_cases + 1))

# Copying the approved final tree is insufficient: the fixed approved spec
# commit must be in G's ancestry, and its approved spec blob must remain exact.
git -C "${repair_repo_root}" checkout -q --detach "${repair_origin_sha}"
commit_current_governance_repair_subset "${repair_repo_root}" \
  "test: copy final repair tree without approved spec ancestry" \
  docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md \
  docs/superpowers/plans/2026-08-13-cognitura-vsb-governance-repair.md \
  docs/task-cards/visual-style-baseline/README.md \
  scripts/verify-visual-style-baseline-cards \
  tests/task-cards/verify-visual-style-baseline-cards.sh >/dev/null
copied_tree_candidate="$(git -C "${repair_repo_root}" rev-parse HEAD)"
expect_repair_static_failure "${repair_repo_root}" \
  "approved governance repair spec commit must be an ancestor of G" \
  "governance repair copied tree without approved spec ancestry"
copied_tree_receipt="$(make_governance_repair_receipt \
  "${repair_repo_root}" "${copied_tree_candidate}" \
  "test: record copied-tree governance repair receipt")"
expect_repair_transition_failure "${repair_repo_root}" "${repair_cards}" \
  "${copied_tree_candidate}" "${copied_tree_receipt}" \
  "approved governance repair spec commit must be an ancestor of G" \
  "GOVERNANCE_REPAIR receipt for copied tree without approved spec ancestry"

git -C "${repair_repo_root}" checkout -q --detach \
  2123594540c91341c480f504949315a6abec316c
printf '\nunauthorized post-approval spec drift\n' >> \
  "${repair_repo_root}/docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md"
git -C "${repair_repo_root}" add \
  docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md
git -C "${repair_repo_root}" commit -qm \
  "test: drift approved governance repair spec"
commit_current_governance_repair_subset "${repair_repo_root}" \
  "test: finish repair after approved spec drift" \
  docs/superpowers/plans/2026-08-13-cognitura-vsb-governance-repair.md \
  docs/task-cards/visual-style-baseline/README.md \
  scripts/verify-visual-style-baseline-cards \
  tests/task-cards/verify-visual-style-baseline-cards.sh >/dev/null
spec_drift_candidate="$(git -C "${repair_repo_root}" rev-parse HEAD)"
expect_repair_static_failure "${repair_repo_root}" \
  "governance repair spec blob must match the approved spec commit" \
  "governance repair candidate with post-approval spec drift"

# Every governance path is mandatory in the cumulative repair WriteSet.
repair_paths=(
  docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md
  docs/superpowers/plans/2026-08-13-cognitura-vsb-governance-repair.md
  docs/task-cards/visual-style-baseline/README.md
  scripts/verify-visual-style-baseline-cards
  tests/task-cards/verify-visual-style-baseline-cards.sh
)
for missing_repair_path in "${repair_paths[@]}"; do
  if [[ "${missing_repair_path}" == \
    docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md ]]; then
    git -C "${repair_repo_root}" checkout -q --detach "${repair_origin_sha}"
  else
    git -C "${repair_repo_root}" checkout -q --detach \
      2123594540c91341c480f504949315a6abec316c
  fi
  included_repair_paths=()
  for repair_path in "${repair_paths[@]}"; do
    [[ "${repair_path}" == \
      docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md ]] ||
      [[ "${repair_path}" == "${missing_repair_path}" ]] ||
      included_repair_paths+=("${repair_path}")
  done
  commit_governance_repair_subset "${repair_repo_root}" \
    "test: omit governance path ${missing_repair_path}" \
    "${included_repair_paths[@]}" >/dev/null
  if [[ "${missing_repair_path}" == \
    docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md ]]; then
    expect_repair_static_failure "${repair_repo_root}" \
      "approved governance repair spec commit must be an ancestor of G" \
      "governance repair missing ${missing_repair_path}"
  else
    expect_repair_static_failure "${repair_repo_root}" \
      "governance repair chain must have the exact repair WriteSet" \
      "governance repair missing ${missing_repair_path}"
  fi
done

git -C "${repair_repo_root}" checkout -q --detach \
  2123594540c91341c480f504949315a6abec316c
commit_governance_repair_subset "${repair_repo_root}" \
  "test: governance repair with extra path" \
  docs/superpowers/plans/2026-08-13-cognitura-vsb-governance-repair.md \
  docs/task-cards/visual-style-baseline/README.md \
  scripts/verify-visual-style-baseline-cards \
  tests/task-cards/verify-visual-style-baseline-cards.sh \
  docs/engineering/governance-repair-extra.md >/dev/null
expect_repair_static_failure "${repair_repo_root}" \
  "governance repair chain changed an unauthorized path" \
  "governance repair containing an extra path"

git -C "${repair_repo_root}" checkout -q --detach \
  2123594540c91341c480f504949315a6abec316c
set_field "${repair_state}" NextTaskCard VSB-03
printf '\nrepair-marker=ledger-intermediate\n' >> \
  "${repair_repo_root}/docs/task-cards/visual-style-baseline/README.md"
git -C "${repair_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md \
  docs/task-cards/visual-style-baseline/README.md
git -C "${repair_repo_root}" commit -qm \
  "test: change ledger inside governance repair chain"
git -C "${repair_repo_root}" show \
  "${repair_origin_sha}:docs/task-cards/visual-style-baseline/execution-state.md" > \
  "${repair_state}"
commit_governance_repair_subset "${repair_repo_root}" \
  "test: restore ledger and finish governance repair" \
  docs/superpowers/plans/2026-08-13-cognitura-vsb-governance-repair.md \
  scripts/verify-visual-style-baseline-cards \
  tests/task-cards/verify-visual-style-baseline-cards.sh >/dev/null
git -C "${repair_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${repair_repo_root}" commit -qm \
  "test: record restored origin ledger"
expect_repair_static_failure "${repair_repo_root}" \
  "governance repair chain must preserve the origin ledger bytes" \
  "governance repair changing and restoring the ledger"

git -C "${repair_repo_root}" checkout -q --detach \
  2123594540c91341c480f504949315a6abec316c
commit_governance_repair_subset "${repair_repo_root}" \
  "test: governance repair before empty commit" \
  docs/superpowers/plans/2026-08-13-cognitura-vsb-governance-repair.md >/dev/null
git -C "${repair_repo_root}" commit --allow-empty -qm \
  "test: empty governance repair round"
commit_governance_repair_subset "${repair_repo_root}" \
  "test: finish governance repair after empty commit" \
  docs/task-cards/visual-style-baseline/README.md \
  scripts/verify-visual-style-baseline-cards \
  tests/task-cards/verify-visual-style-baseline-cards.sh >/dev/null
expect_repair_static_failure "${repair_repo_root}" \
  "governance repair chain commit must not be empty" \
  "governance repair containing an empty commit"

git -C "${repair_repo_root}" checkout -q --detach \
  2123594540c91341c480f504949315a6abec316c
repair_merge_base="$(commit_governance_repair_subset \
  "${repair_repo_root}" "test: governance repair merge base" \
  docs/superpowers/plans/2026-08-13-cognitura-vsb-governance-repair.md)"
git -C "${repair_repo_root}" switch -q -c repair-side "${repair_merge_base}"
commit_governance_repair_subset "${repair_repo_root}" \
  "test: governance repair side" \
  docs/task-cards/visual-style-baseline/README.md >/dev/null
repair_side_sha="$(git -C "${repair_repo_root}" rev-parse HEAD)"
git -C "${repair_repo_root}" switch -q -c repair-main "${repair_merge_base}"
commit_governance_repair_subset "${repair_repo_root}" \
  "test: governance repair main" \
  scripts/verify-visual-style-baseline-cards >/dev/null
git -C "${repair_repo_root}" merge -q --no-ff "${repair_side_sha}" \
  -m "test: merge governance repair rounds"
commit_governance_repair_subset "${repair_repo_root}" \
  "test: finish merged governance repair" \
  tests/task-cards/verify-visual-style-baseline-cards.sh >/dev/null
expect_repair_static_failure "${repair_repo_root}" \
  "governance repair chain commit must have exactly one parent" \
  "governance repair containing a merge"

# Mode history is cumulative: delete/recreate with the canonical mode is valid,
# while restoring the same path with a different executable bit is not.
git -C "${repair_repo_root}" checkout -q --detach \
  2123594540c91341c480f504949315a6abec316c
git -C "${repair_repo_root}" rm -q -- \
  docs/task-cards/visual-style-baseline/README.md
git -C "${repair_repo_root}" commit -qm \
  "test: delete repair README before same-mode recreation"
commit_current_governance_repair_subset "${repair_repo_root}" \
  "test: recreate repair README with canonical mode" \
  "${repair_paths[@]}" >/dev/null
repair_same_mode_candidate="$(git -C "${repair_repo_root}" rev-parse HEAD)"
repair_same_mode_output="$(run_repair_static "${repair_repo_root}")" ||
  fail "same-mode repair delete/recreate was rejected: ${repair_same_mode_output}"
assert_contains "${repair_same_mode_output}" "GovernanceRepairStatus = PENDING"
governance_repair_positive_cases=$((governance_repair_positive_cases + 1))

git -C "${repair_repo_root}" checkout -q --detach \
  2123594540c91341c480f504949315a6abec316c
git -C "${repair_repo_root}" rm -q -- \
  docs/task-cards/visual-style-baseline/README.md
git -C "${repair_repo_root}" commit -qm \
  "test: delete repair README before mode drift"
for repair_path in "${repair_paths[@]}"; do
  mkdir -p "${repair_repo_root}/$(dirname "${repair_path}")"
  cp -p "${repo_root}/${repair_path}" "${repair_repo_root}/${repair_path}"
done
chmod +x "${repair_repo_root}/docs/task-cards/visual-style-baseline/README.md"
git -C "${repair_repo_root}" add -- "${repair_paths[@]}"
git -C "${repair_repo_root}" commit -qm \
  "test: recreate repair README directly with different mode"
expect_repair_static_failure "${repair_repo_root}" \
  "governance repair chain must preserve file mode history" \
  "governance repair delete and different-mode recreate"

# Owner-internal rename/copy attempts must fail even when the final five-path
# tree is restored.  Low repository rename limits must not weaken detection.
git -C "${repair_repo_root}" checkout -q --detach \
  2123594540c91341c480f504949315a6abec316c
git -C "${repair_repo_root}" mv -f -- \
  docs/task-cards/visual-style-baseline/README.md \
  docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md
git -C "${repair_repo_root}" commit -qm \
  "test: rename one repair path onto another"
commit_current_governance_repair_subset "${repair_repo_root}" \
  "test: restore renamed repair paths" "${repair_paths[@]}" >/dev/null
expect_repair_static_failure "${repair_repo_root}" \
  "governance repair chain must not rename or copy paths" \
  "governance repair owner-internal rename"

git -C "${repair_repo_root}" checkout -q --detach \
  2123594540c91341c480f504949315a6abec316c
git -C "${repair_repo_root}" rm -q -- \
  docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md
git -C "${repair_repo_root}" commit -qm \
  "test: delete repair spec before owner-internal copy"
cp "${repair_repo_root}/docs/task-cards/visual-style-baseline/README.md" \
  "${repair_repo_root}/docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md"
git -C "${repair_repo_root}" add \
  docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md
git -C "${repair_repo_root}" commit -qm \
  "test: copy one repair path onto another"
commit_current_governance_repair_subset "${repair_repo_root}" \
  "test: restore copied repair paths" "${repair_paths[@]}" >/dev/null
expect_repair_static_failure "${repair_repo_root}" \
  "governance repair chain must not rename or copy paths" \
  "governance repair owner-internal copy"

git -C "${repair_repo_root}" checkout -q --detach \
  2123594540c91341c480f504949315a6abec316c
repair_low_limit_parent="$(git -C "${repair_repo_root}" rev-parse HEAD)"
git -C "${repair_repo_root}" mv -f -- \
  docs/task-cards/visual-style-baseline/README.md \
  docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md
git -C "${repair_repo_root}" mv -f -- \
  scripts/verify-visual-style-baseline-cards \
  docs/superpowers/plans/2026-08-13-cognitura-vsb-governance-repair.md
printf '\ninexact low-limit repair rename A\n' >> \
  "${repair_repo_root}/docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md"
printf '\ninexact low-limit repair rename B\n' >> \
  "${repair_repo_root}/docs/superpowers/plans/2026-08-13-cognitura-vsb-governance-repair.md"
git -C "${repair_repo_root}" add -- \
  docs/superpowers/specs/2026-08-13-cognitura-vsb-governance-repair-design.md \
  docs/superpowers/plans/2026-08-13-cognitura-vsb-governance-repair.md
git -C "${repair_repo_root}" commit -qm \
  "test: rename repair paths under a low detection limit"
repair_low_limit_rename_sha="$(git -C "${repair_repo_root}" rev-parse HEAD)"
git -C "${repair_repo_root}" config diff.renameLimit 1
repair_low_limit_status="${test_tmp_root}/repair-low-limit-status"
repair_low_limit_error="${test_tmp_root}/repair-low-limit-error"
git -C "${repair_repo_root}" diff-tree --no-commit-id -r -M -C \
  --find-copies-harder --name-status \
  "${repair_low_limit_parent}" "${repair_low_limit_rename_sha}" \
  > "${repair_low_limit_status}" 2> "${repair_low_limit_error}" ||
  fail "low-limit repair rename fixture inspection failed"
if grep -Eq '^[RC][0-9]+' "${repair_low_limit_status}"; then
  fail "low-limit repair rename fixture did not degrade detection"
fi
grep -q 'exhaustive rename detection was skipped' \
  "${repair_low_limit_error}" ||
  fail "low-limit repair rename fixture emitted no degradation warning"
commit_current_governance_repair_subset "${repair_repo_root}" \
  "test: restore low-limit repair renames" "${repair_paths[@]}" >/dev/null
expect_repair_static_failure "${repair_repo_root}" \
  "governance repair chain must not rename or copy paths" \
  "governance repair rename under low diff.renameLimit"
git -C "${repair_repo_root}" config --unset diff.renameLimit

git -C "${repair_repo_root}" checkout -q --detach "${repair_candidate_sha}"
repair_receipt_sha="$(make_governance_repair_receipt \
  "${repair_repo_root}" "${repair_candidate_sha}" \
  "test: record governance repair receipt")"
repair_transition_output="$("${verifier}" \
  --repo-root "${repair_repo_root}" --cards-dir "${repair_cards}" \
  --transition-base "${repair_candidate_sha}" \
  --transition-head "${repair_receipt_sha}" 2>&1)" ||
  fail "valid GOVERNANCE_REPAIR transition was rejected: ${repair_transition_output}"
assert_contains "${repair_transition_output}" \
  "VisualStyleBaselineTaskCardValidation = PASS"
repair_static_pass_output="$(run_repair_static "${repair_repo_root}")" ||
  fail "valid GOVERNANCE_REPAIR receipt failed static validation"
assert_contains "${repair_static_pass_output}" "GovernanceRepairStatus = PASS"
governance_repair_positive_cases=$((governance_repair_positive_cases + 1))

# R is one exact deterministic byte transform of the fixed origin ledger.
# Unknown keys, free-form body drift, binary data, and ledger mode drift fail.
repair_receipt_drift_texts=(
  'UnapprovedState = X'
  'unapproved governance receipt body'
)
repair_drift_receipts=()
for repair_receipt_drift_text in "${repair_receipt_drift_texts[@]}"; do
  git -C "${repair_repo_root}" checkout -q --detach "${repair_candidate_sha}"
  repair_drift_receipt="$(make_governance_repair_receipt \
    "${repair_repo_root}" "${repair_candidate_sha}" \
    "test: governance repair receipt with ledger drift" "" "" "" \
    "${repair_receipt_drift_text}")"
  repair_drift_receipts+=("${repair_drift_receipt}")
  expect_repair_transition_failure "${repair_repo_root}" "${repair_cards}" \
    "${repair_candidate_sha}" "${repair_drift_receipt}" \
    "GOVERNANCE_REPAIR receipt must be the exact approved ledger transform" \
    "governance repair receipt drift ${repair_receipt_drift_text}"
done

git -C "${repair_repo_root}" checkout -q --detach "${repair_candidate_sha}"
repair_nul_receipt="$(make_governance_repair_receipt \
  "${repair_repo_root}" "${repair_candidate_sha}" \
  "test: governance repair receipt with NUL" "" "" "" "" "" 1)"
expect_repair_transition_failure "${repair_repo_root}" "${repair_cards}" \
  "${repair_candidate_sha}" "${repair_nul_receipt}" \
  "transition ledger must not contain NUL bytes" \
  "governance repair receipt with NUL"

git -C "${repair_repo_root}" checkout -q --detach "${repair_candidate_sha}"
repair_mode_receipt="$(make_governance_repair_receipt \
  "${repair_repo_root}" "${repair_candidate_sha}" \
  "test: governance repair receipt with executable ledger" \
  "" "" "" "" 755)"
expect_repair_transition_failure "${repair_repo_root}" "${repair_cards}" \
  "${repair_candidate_sha}" "${repair_mode_receipt}" \
  "GOVERNANCE_REPAIR receipt ledger mode must remain canonical" \
  "governance repair receipt ledger mode drift"

# Fixed-old RED audit: the pre-fix verifier at f99b74f accepted the exact
# malformed R fixtures that the current public entry rejects above.
old_verifier_root="${test_tmp_root}/old-governance-repair-verifier"
git clone --shared -q "${repo_root}" "${old_verifier_root}"
git -C "${old_verifier_root}" checkout -q --detach \
  f99b74f98d0ac8e497021bb3ea624c32380c0aeb
old_verifier_bin="${test_tmp_root}/old-verifier-bin"
mkdir -p "${old_verifier_bin}/scripts"
old_verifier="${old_verifier_bin}/scripts/verify-visual-style-baseline-cards"
cp "${old_verifier_root}/scripts/verify-visual-style-baseline-cards" \
  "${old_verifier}"
cp "${old_verifier_root}/scripts/verify-wave1-implementation-cards" \
  "${old_verifier_bin}/scripts/verify-wave1-implementation-cards"
old_verifier_red_cases=0
for old_red_receipt_sha in \
  "${repair_drift_receipts[@]}" "${repair_mode_receipt}"; do
  git -C "${old_verifier_root}" fetch -q "${repair_repo_root}" \
    "${old_red_receipt_sha}"
  git -C "${old_verifier_root}" checkout -q --detach FETCH_HEAD
  old_red_output="$("${old_verifier}" \
    --repo-root "${old_verifier_root}" \
    --cards-dir \
      "${old_verifier_root}/docs/task-cards/visual-style-baseline" \
    --transition-base "${repair_candidate_sha}" \
    --transition-head "${old_red_receipt_sha}" 2>&1)" ||
    fail "fixed-old verifier did not reproduce expected malformed-R PASS"
  assert_contains "${old_red_output}" \
    "VisualStyleBaselineTaskCardValidation = PASS"
  old_verifier_red_cases=$((old_verifier_red_cases + 1))
done
[[ "${old_verifier_red_cases}" -eq 3 ]] ||
  fail "fixed-old malformed-R RED audit did not execute three cases"

repair_negative_fields=(
  GovernanceRepairSpecSHA
  GovernanceRepairOriginReceiptSHA
  TransitionBaseSHA
  GovernanceRepairReviewedCandidateSHA
  GovernanceRepairReviewRoute
  GovernanceRepairReviewRoute
  GovernanceRepairReviewVerdict
  CurrentGateStatus
  TransitionSequence
  ExecutionStateVersion
)
repair_negative_values=(
  70eefba5912e6884e4e7e1d6477a65f4091d6590
  c9fe3d6c081f67459e13cbcff010ddb5cdbf1508
  737c053483d1f3d084d5f90d5c36f76b0ae8f5a3
  737c053483d1f3d084d5f90d5c36f76b0ae8f5a3
  ultra_gatekeeper
  deep_reviewer
  GO_P0_0_P1_0_P2_0
  FAIL
  4
  3
)
repair_negative_messages=(
  "GOVERNANCE_REPAIR approved spec SHA mismatch"
  "GOVERNANCE_REPAIR origin SHA mismatch"
  "receipt TransitionBaseSHA must equal its fixed BASE"
  "GOVERNANCE_REPAIR reviewed candidate SHA mismatch"
  "GOVERNANCE_REPAIR review route mismatch"
  "GOVERNANCE_REPAIR review route mismatch"
  "GOVERNANCE_REPAIR review verdict mismatch"
  "GOVERNANCE_REPAIR must preserve the failed receipt business state"
  "GOVERNANCE_REPAIR TransitionSequence must be 3"
  "GOVERNANCE_REPAIR must upgrade ExecutionStateVersion from 1 to 2"
)
for repair_negative_index in "${!repair_negative_fields[@]}"; do
  git -C "${repair_repo_root}" checkout -q --detach "${repair_candidate_sha}"
  repair_bad_receipt="$(make_governance_repair_receipt \
    "${repair_repo_root}" "${repair_candidate_sha}" \
    "test: invalid governance repair ${repair_negative_index}" \
    "${repair_negative_fields[${repair_negative_index}]}" \
    "${repair_negative_values[${repair_negative_index}]}")"
  expect_repair_transition_failure "${repair_repo_root}" "${repair_cards}" \
    "${repair_candidate_sha}" "${repair_bad_receipt}" \
    "${repair_negative_messages[${repair_negative_index}]}" \
    "invalid governance repair field ${repair_negative_index}"
done

git -C "${repair_repo_root}" checkout -q --detach "${repair_candidate_sha}"
repair_extra_receipt="$(make_governance_repair_receipt \
  "${repair_repo_root}" "${repair_candidate_sha}" \
  "test: governance repair receipt with extra diff" "" "" \
  docs/engineering/governance-repair-receipt-extra.md)"
expect_repair_transition_failure "${repair_repo_root}" "${repair_cards}" \
  "${repair_candidate_sha}" "${repair_extra_receipt}" \
  "receipt diff must contain only execution-state.md" \
  "governance repair receipt with extra path"

git -C "${repair_repo_root}" checkout -q --detach "${repair_round_one_sha}"
repair_nontip_receipt="$(make_governance_repair_receipt \
  "${repair_repo_root}" "${repair_round_one_sha}" \
  "test: repair receipt from non-final governance candidate")"
expect_repair_transition_failure "${repair_repo_root}" "${repair_cards}" \
  "${repair_round_one_sha}" "${repair_nontip_receipt}" \
  "governance repair chain must have the exact repair WriteSet" \
  "governance repair receipt from a non-final candidate"

git -C "${repair_repo_root}" checkout -q --detach "${repair_candidate_sha}"
git -C "${repair_repo_root}" switch -q -c repair-receipt-side
repair_merge_side="$(make_governance_repair_receipt \
  "${repair_repo_root}" "${repair_candidate_sha}" \
  "test: governance repair receipt side")"
git -C "${repair_repo_root}" switch -q -c repair-receipt-main \
  "${repair_candidate_sha}"
git -C "${repair_repo_root}" commit --allow-empty -qm \
  "test: empty competing repair receipt parent"
git -C "${repair_repo_root}" merge -q --no-ff "${repair_merge_side}" \
  -m "test: merge governance repair receipt"
repair_merge_receipt="$(git -C "${repair_repo_root}" rev-parse HEAD)"
expect_repair_transition_failure "${repair_repo_root}" "${repair_cards}" \
  "${repair_candidate_sha}" "${repair_merge_receipt}" \
  "transition HEAD must have exactly one parent" \
  "merged governance repair receipt"

git -C "${repair_repo_root}" checkout -q --detach "${repair_receipt_sha}"
set_field "${repair_state}" TransitionSequence 4
set_field "${repair_state}" TransitionBaseSHA "${repair_receipt_sha}"
git -C "${repair_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${repair_repo_root}" commit -qm \
  "test: attempt second governance repair"
second_repair_sha="$(git -C "${repair_repo_root}" rev-parse HEAD)"
expect_repair_transition_failure "${repair_repo_root}" "${repair_cards}" \
  "${repair_receipt_sha}" "${second_repair_sha}" \
  "GOVERNANCE_REPAIR is allowed exactly once" \
  "second governance repair"

# R, never d47 or G, is the legal VSB-01 candidate anchor.  Exercise both a
# one-commit and a multi-commit exact candidate through the public dispatcher.
make_vsb01_advance_receipt() {
  local fixture_root="$1"
  local candidate_sha="$2"
  local subject="$3"
  local fixture_state="${fixture_root}/docs/task-cards/visual-style-baseline/execution-state.md"
  set_field "${fixture_state}" CompletedTaskCards VSB-00,VSB-01
  set_field "${fixture_state}" ActiveTaskCard VSB-02
  set_field "${fixture_state}" ReleasedTaskCard VSB-02
  set_field "${fixture_state}" CurrentCandidateSHA "${candidate_sha}"
  set_field "${fixture_state}" CurrentGateStatus VSB-G1_PASS
  set_field "${fixture_state}" CurrentReviewRoute deep_reviewer
  set_field "${fixture_state}" CurrentReviewVerdict GO_P0_0_P1_0_P2_0
  set_field "${fixture_state}" VSB01CandidateSHA "${candidate_sha}"
  set_field "${fixture_state}" VSB01GateStatus VSB-G1_PASS
  set_field "${fixture_state}" VSB01ReviewVerdict GO_P0_0_P1_0_P2_0
  set_field "${fixture_state}" NextTaskCard VSB-03
  set_field "${fixture_state}" TransitionSequence 4
  set_field "${fixture_state}" TransitionKind ADVANCE
  set_field "${fixture_state}" TransitionBaseSHA "${candidate_sha}"
  git -C "${fixture_root}" add \
    docs/task-cards/visual-style-baseline/execution-state.md
  git -C "${fixture_root}" commit -qm "${subject}"
  git -C "${fixture_root}" rev-parse HEAD
}

git -C "${repair_repo_root}" checkout -q --detach "${repair_receipt_sha}"
write_exact_candidate_paths "${repair_repo_root}" 1 \
  "single-commit VSB-01 after governance repair"
printf '%s\n' "${candidate_write_sets[1]}" | \
  git -C "${repair_repo_root}" add --pathspec-from-file=-
git -C "${repair_repo_root}" commit -qm \
  "test: create single-commit VSB-01 candidate after repair"
repair_vsb01_single_candidate="$(git -C "${repair_repo_root}" rev-parse HEAD)"
repair_vsb01_single_receipt="$(make_vsb01_advance_receipt \
  "${repair_repo_root}" "${repair_vsb01_single_candidate}" \
  "test: advance single-commit VSB-01 after repair")"
repair_vsb01_single_output="$("${verifier}" \
  --repo-root "${repair_repo_root}" --cards-dir "${repair_cards}" \
  --transition-base "${repair_vsb01_single_candidate}" \
  --transition-head "${repair_vsb01_single_receipt}" 2>&1)" ||
  fail "single-commit VSB-01 candidate after R was rejected: ${repair_vsb01_single_output}"
assert_contains "${repair_vsb01_single_output}" \
  "VisualStyleBaselineTaskCardValidation = PASS"
governance_repair_positive_cases=$((governance_repair_positive_cases + 1))

git -C "${repair_repo_root}" checkout -q --detach "${repair_receipt_sha}"
commit_candidate_subset "${repair_repo_root}" \
  "test: VSB-01 after repair round one" \
  web/src/styles/tokens.css web/src/styles/typography.css \
  web/src/styles/surfaces.css >/dev/null
repair_vsb01_multi_candidate="$(commit_candidate_subset \
  "${repair_repo_root}" "test: VSB-01 after repair final round" \
  web/src/styles/cognitive-visual.css web/src/styles/cognitura.css \
  web/src/styles/style-contract.test.ts scripts/verify-module-default-reading \
  tests/visual-style-baseline/verify-module-default-reading-toolchain.sh)"
repair_vsb01_multi_receipt="$(make_vsb01_advance_receipt \
  "${repair_repo_root}" "${repair_vsb01_multi_candidate}" \
  "test: advance multi-commit VSB-01 after repair")"
repair_vsb01_multi_output="$("${verifier}" \
  --repo-root "${repair_repo_root}" --cards-dir "${repair_cards}" \
  --transition-base "${repair_vsb01_multi_candidate}" \
  --transition-head "${repair_vsb01_multi_receipt}" 2>&1)" ||
  fail "multi-commit VSB-01 candidate after R was rejected: ${repair_vsb01_multi_output}"
assert_contains "${repair_vsb01_multi_output}" \
  "VisualStyleBaselineTaskCardValidation = PASS"
governance_repair_positive_cases=$((governance_repair_positive_cases + 1))

git -C "${repair_repo_root}" checkout -q --detach "${repair_receipt_sha}"
commit_candidate_subset "${repair_repo_root}" \
  "test: absorb governance path into VSB-01" \
  docs/task-cards/visual-style-baseline/README.md \
  web/src/styles/tokens.css >/dev/null
write_exact_candidate_paths "${repair_repo_root}" 1 \
  "finish VSB-01 after governance path absorption"
printf '%s\n' "${candidate_write_sets[1]}" | \
  git -C "${repair_repo_root}" add --pathspec-from-file=-
git -C "${repair_repo_root}" commit -qm \
  "test: finish VSB-01 containing governance path"
repair_absorbed_candidate="$(git -C "${repair_repo_root}" rev-parse HEAD)"
repair_absorbed_receipt="$(make_vsb01_advance_receipt \
  "${repair_repo_root}" "${repair_absorbed_candidate}" \
  "test: advance VSB-01 containing governance path")"
expect_repair_transition_failure "${repair_repo_root}" "${repair_cards}" \
  "${repair_absorbed_candidate}" "${repair_absorbed_receipt}" \
  "candidate chain commit changed a path outside the Owner WriteSet" \
  "VSB-01 candidate absorbing a governance repair path"

if [[ "${repair_contract_only}" -eq 1 ]]; then
  printf '%s\n' \
    "GovernanceRepairContractTests = PASS" \
    "GovernanceRepairPositiveCases = ${governance_repair_positive_cases}" \
    "GovernanceRepairNegativeCases = ${governance_repair_negative_cases}"
  exit 0
fi

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
new_mode_path=scripts/import-visual-style-reference
printf 'first creation\n' > "${transition_repo_root}/${new_mode_path}"
git -C "${transition_repo_root}" add -- "${new_mode_path}"
git -C "${transition_repo_root}" commit -qm \
  "test: create new Owner path with initial mode"
git -C "${transition_repo_root}" rm -q -- "${new_mode_path}"
git -C "${transition_repo_root}" commit -qm \
  "test: delete newly created Owner path"
printf 'recreated with different mode\n' > \
  "${transition_repo_root}/${new_mode_path}"
chmod +x "${transition_repo_root}/${new_mode_path}"
git -C "${transition_repo_root}" add -- "${new_mode_path}"
git -C "${transition_repo_root}" commit -qm \
  "test: recreate new Owner path with different mode"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "candidate completing WriteSet after new-path mode drift"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: complete candidate after new-path mode drift"
new_mode_tip="$(git -C "${transition_repo_root}" rev-parse HEAD)"
new_mode_receipt="$(make_vsb00_advance_receipt \
  "${new_mode_tip}" "test: advance new-path mode-drift candidate")"
expect_transition_failure "${new_mode_tip}" "${new_mode_receipt}" \
  "candidate chain commit must preserve candidate file modes" \
  "candidate recreating a new Owner path with a different mode"

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
rename_source=AGENTS.md
rename_target=scripts/import-visual-style-reference
git -C "${transition_repo_root}" mv -f -- \
  "${rename_source}" "${rename_target}"
git -C "${transition_repo_root}" commit -qm \
  "test: rename one Owner path onto another"
git -C "${transition_repo_root}" show \
  "${activation_sha}:${rename_source}" > \
  "${transition_repo_root}/${rename_source}"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "candidate rebuilding an Owner path after rename"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: rebuild renamed Owner source and complete candidate"
owner_rename_tip="$(git -C "${transition_repo_root}" rev-parse HEAD)"
owner_rename_receipt="$(make_vsb00_advance_receipt \
  "${owner_rename_tip}" "test: advance Owner-rename candidate")"
expect_transition_failure "${owner_rename_tip}" "${owner_rename_receipt}" \
  "candidate chain commit must not rename or copy paths" \
  "candidate renaming between Owner paths then rebuilding the source"

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
copy_target=scripts/import-visual-style-reference
copy_source=server/pom.xml
cp "${transition_repo_root}/${copy_source}" \
  "${transition_repo_root}/${copy_target}"
git -C "${transition_repo_root}" add -- "${copy_target}"
git -C "${transition_repo_root}" commit -qm \
  "test: copy existing source onto Owner target"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "candidate completing Owner WriteSet after copy"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: complete candidate containing copied Owner target"
owner_copy_tip="$(git -C "${transition_repo_root}" rev-parse HEAD)"
owner_copy_receipt="$(make_vsb00_advance_receipt \
  "${owner_copy_tip}" "test: advance Owner-copy candidate")"
expect_transition_failure "${owner_copy_tip}" "${owner_copy_receipt}" \
  "candidate chain commit must not rename or copy paths" \
  "candidate copying an existing source onto an Owner target"

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
low_limit_source_a=AGENTS.md
low_limit_source_b=docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md
low_limit_target_a=scripts/import-visual-style-reference
low_limit_target_b=scripts/verify-visual-style-baseline-reference
low_limit_parent="$(git -C "${transition_repo_root}" rev-parse HEAD)"
git -C "${transition_repo_root}" mv -- \
  "${low_limit_source_a}" "${low_limit_target_a}"
git -C "${transition_repo_root}" mv -- \
  "${low_limit_source_b}" "${low_limit_target_b}"
printf '\nmodified after low-limit rename A\n' >> \
  "${transition_repo_root}/${low_limit_target_a}"
printf '\nmodified after low-limit rename B\n' >> \
  "${transition_repo_root}/${low_limit_target_b}"
git -C "${transition_repo_root}" add -- \
  "${low_limit_target_a}" "${low_limit_target_b}"
git -C "${transition_repo_root}" commit -qm \
  "test: rename Owner paths under a low detection limit"
low_limit_rename_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
git -C "${transition_repo_root}" config diff.renameLimit 1
low_limit_status_file="${test_tmp_root}/low-limit-status"
low_limit_error_file="${test_tmp_root}/low-limit-error"
git -C "${transition_repo_root}" diff-tree --no-commit-id -r -M -C \
  --find-copies-harder --name-status \
  "${low_limit_parent}" "${low_limit_rename_sha}" \
  > "${low_limit_status_file}" 2> "${low_limit_error_file}" ||
  fail "low-limit rename fixture could not inspect its raw Git status"
if grep -Eq '^[RC][0-9]+' "${low_limit_status_file}"; then
  fail "low-limit rename fixture did not degrade rename detection"
fi
grep -q 'exhaustive rename detection was skipped' "${low_limit_error_file}" ||
  fail "low-limit rename fixture did not emit the expected degradation warning"
git -C "${transition_repo_root}" show \
  "${activation_sha}:${low_limit_source_a}" > \
  "${transition_repo_root}/${low_limit_source_a}"
git -C "${transition_repo_root}" show \
  "${activation_sha}:${low_limit_source_b}" > \
  "${transition_repo_root}/${low_limit_source_b}"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "candidate completing WriteSet after low-limit renames"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: rebuild low-limit rename sources and complete candidate"
low_limit_rename_tip="$(git -C "${transition_repo_root}" rev-parse HEAD)"
low_limit_rename_receipt="$(make_vsb00_advance_receipt \
  "${low_limit_rename_tip}" "test: advance low-limit rename candidate")"
expect_transition_failure "${low_limit_rename_tip}" \
  "${low_limit_rename_receipt}" \
  "candidate chain commit must not rename or copy paths" \
  "candidate hiding Owner renames behind a low diff.renameLimit"
git -C "${transition_repo_root}" config --unset diff.renameLimit

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
recreated_mode_path=AGENTS.md
git -C "${transition_repo_root}" rm -q -- "${recreated_mode_path}"
git -C "${transition_repo_root}" commit -qm \
  "test: delete Owner path before mode-changing recreation"
git -C "${transition_repo_root}" show \
  "${activation_sha}:${recreated_mode_path}" > \
  "${transition_repo_root}/${recreated_mode_path}"
chmod +x "${transition_repo_root}/${recreated_mode_path}"
git -C "${transition_repo_root}" add -- "${recreated_mode_path}"
git -C "${transition_repo_root}" commit -qm \
  "test: recreate Owner path with a different mode"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "candidate completing WriteSet after mode-changing recreation"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: complete candidate after mode-changing recreation"
recreated_mode_tip="$(git -C "${transition_repo_root}" rev-parse HEAD)"
recreated_mode_receipt="$(make_vsb00_advance_receipt \
  "${recreated_mode_tip}" "test: advance recreated-mode candidate")"
expect_transition_failure "${recreated_mode_tip}" \
  "${recreated_mode_receipt}" \
  "candidate chain commit must preserve release file modes" \
  "candidate deleting then recreating an Owner path with a different mode"

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
extra_candidate_path=docs/design/visual-style-baseline-fixtures/temporary-extra.txt
extra_round_one="$(commit_candidate_subset \
  "${transition_repo_root}" "test: add temporary unauthorized path" \
  AGENTS.md "${extra_candidate_path}")"
git -C "${transition_repo_root}" rm -q -- "${extra_candidate_path}"
commit_candidate_subset "${transition_repo_root}" \
  "test: restore temporary unauthorized path" \
  docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png \
  docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md \
  docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-visual-style-baseline-manifest.yaml \
  scripts/import-visual-style-reference \
  scripts/verify-visual-style-baseline-reference \
  tests/visual-style-baseline/verify-reference.sh >/dev/null
extra_restored_tip="$(git -C "${transition_repo_root}" rev-parse HEAD)"
extra_restored_receipt="$(make_vsb00_advance_receipt \
  "${extra_restored_tip}" "test: advance restored-extra candidate")"
expect_transition_failure "${extra_restored_tip}" \
  "${extra_restored_receipt}" \
  "candidate chain commit changed a path outside the Owner WriteSet" \
  "candidate with intermediate extra path restored before tip"

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
set_field "${transition_state}" "NextTaskCard" "VSB-03"
printf '\nround-marker=ledger-chain\n' >> "${transition_repo_root}/AGENTS.md"
git -C "${transition_repo_root}" add AGENTS.md \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: record intermediate execution-ledger mutation"
git -C "${transition_repo_root}" show \
  "${activation_sha}:docs/task-cards/visual-style-baseline/execution-state.md" > \
  "${transition_state}"
commit_candidate_subset "${transition_repo_root}" \
  "test: finish candidate after restoring execution ledger" \
  docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png \
  docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md \
  docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-visual-style-baseline-manifest.yaml \
  scripts/import-visual-style-reference \
  scripts/verify-visual-style-baseline-reference \
  tests/visual-style-baseline/verify-reference.sh >/dev/null
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: restore intermediate execution ledger"
ledger_restored_tip="$(git -C "${transition_repo_root}" rev-parse HEAD)"
ledger_restored_receipt="$(make_vsb00_advance_receipt \
  "${ledger_restored_tip}" "test: advance ledger-restored candidate")"
expect_transition_failure "${ledger_restored_tip}" \
  "${ledger_restored_receipt}" \
  "candidate chain must not modify the execution ledger" \
  "candidate with intermediate ledger mutation restored before tip"

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
other_owner_path=web/src/styles/tokens.css
other_owner_tip="$(commit_candidate_subset \
  "${transition_repo_root}" "test: mix another Owner path" \
  AGENTS.md "${other_owner_path}")"
other_owner_receipt="$(make_vsb00_advance_receipt \
  "${other_owner_tip}" "test: advance cross-Owner candidate")"
expect_transition_failure "${other_owner_tip}" "${other_owner_receipt}" \
  "candidate chain commit changed a path outside the Owner WriteSet" \
  "candidate containing another Owner path"

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
git -C "${transition_repo_root}" mv -- \
  server/pom.xml scripts/import-visual-style-reference
git -C "${transition_repo_root}" commit -qm \
  "test: rename forbidden source into Owner WriteSet"
rename_chain_tip="$(git -C "${transition_repo_root}" rev-parse HEAD)"
rename_chain_receipt="$(make_vsb00_advance_receipt \
  "${rename_chain_tip}" "test: advance rename-containing candidate")"
expect_transition_failure "${rename_chain_tip}" "${rename_chain_receipt}" \
  "candidate chain commit must not rename or copy paths" \
  "candidate containing a rename"

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
merge_side_sha="$(commit_candidate_subset \
  "${transition_repo_root}" "test: candidate merge side" AGENTS.md)"
git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
commit_candidate_subset "${transition_repo_root}" \
  "test: candidate merge first parent" \
  docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png >/dev/null
git -C "${transition_repo_root}" merge -q --no-ff \
  -m "test: merge candidate chain" "${merge_side_sha}"
merge_chain_tip="$(git -C "${transition_repo_root}" rev-parse HEAD)"
assert_commit_parent_count "${transition_repo_root}" "${merge_chain_tip}" 2
merge_chain_receipt="$(make_vsb00_advance_receipt \
  "${merge_chain_tip}" "test: advance merge-containing candidate")"
expect_transition_failure "${merge_chain_tip}" "${merge_chain_receipt}" \
  "candidate chain commit must have exactly one parent" \
  "candidate containing a merge commit"

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
git -C "${transition_repo_root}" commit --allow-empty -qm \
  "test: empty candidate chain commit"
empty_chain_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
empty_chain_tip="$(commit_candidate_subset \
  "${transition_repo_root}" "test: complete candidate after empty commit" \
  AGENTS.md \
  docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png \
  docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md \
  docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-visual-style-baseline-manifest.yaml \
  scripts/import-visual-style-reference \
  scripts/verify-visual-style-baseline-reference \
  tests/visual-style-baseline/verify-reference.sh)"
empty_chain_receipt="$(make_vsb00_advance_receipt \
  "${empty_chain_tip}" "test: advance candidate containing empty commit")"
expect_transition_failure "${empty_chain_tip}" "${empty_chain_receipt}" \
  "candidate chain commit must not be empty" \
  "candidate containing an empty commit"

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
reviewed_non_tip_sha="$(commit_candidate_subset \
  "${transition_repo_root}" "test: initial reviewed candidate" \
  AGENTS.md \
  docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png \
  docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md \
  docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-visual-style-baseline-manifest.yaml \
  scripts/import-visual-style-reference \
  scripts/verify-visual-style-baseline-reference \
  tests/visual-style-baseline/verify-reference.sh)"
reviewed_actual_tip="$(commit_candidate_subset \
  "${transition_repo_root}" "test: unreviewed candidate tip" AGENTS.md)"
reviewed_non_tip_receipt="$(make_vsb00_advance_receipt \
  "${reviewed_actual_tip}" "test: bind review to a non-tip commit" \
  "${reviewed_non_tip_sha}")"
expect_transition_failure "${reviewed_actual_tip}" \
  "${reviewed_non_tip_receipt}" \
  "reviewed candidate must be the candidate chain tip" \
  "review receipt bound to a non-tip candidate"

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
set_field "${transition_state}" "TransitionSequence" "3"
set_field "${transition_state}" "TransitionBaseSHA" "${activation_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: forge newer claimed VSB-00 release receipt"
invalid_nearest_receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
invalid_nearest_tip="$(commit_candidate_subset \
  "${transition_repo_root}" "test: candidate after invalid nearest receipt" \
  AGENTS.md \
  docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png \
  docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md \
  docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-visual-style-baseline-manifest.yaml \
  scripts/import-visual-style-reference \
  scripts/verify-visual-style-baseline-reference \
  tests/visual-style-baseline/verify-reference.sh)"
invalid_nearest_head="$(make_vsb00_advance_receipt \
  "${invalid_nearest_tip}" \
  "test: try to skip invalid nearest Owner receipt" \
  "${invalid_nearest_tip}" 4)"
expect_transition_failure "${invalid_nearest_tip}" "${invalid_nearest_head}" \
  "candidate chain must start at the nearest valid Owner release receipt" \
  "candidate selection skipping the nearest claimed Owner receipt"

fixed_failed_receipt_cards="${test_tmp_root}/fixed-failed-receipt-cards"
mkdir -p "${fixed_failed_receipt_cards}"
git -C "${repo_root}" archive \
  d47c8c7bd7355947b5e8e1de6c264d80c2e27c9a \
  docs/task-cards/visual-style-baseline | \
  tar -x -C "${fixed_failed_receipt_cards}"
if fixed_failed_receipt_output="$("${verifier}" \
  --repo-root "${repo_root}" \
  --cards-dir "${fixed_failed_receipt_cards}/docs/task-cards/visual-style-baseline" \
  --transition-base 737c053483d1f3d084d5f90d5c36f76b0ae8f5a3 \
  --transition-head d47c8c7bd7355947b5e8e1de6c264d80c2e27c9a 2>&1)"; then
  fail "fixed failed VSB receipt unexpectedly passed as ordinary ADVANCE"
fi
assert_contains "${fixed_failed_receipt_output}" \
  "fixed governance repair origin is not a valid ordinary VSB receipt"
negative_cases=$((negative_cases + 1))
cumulative_candidate_negative_cases=$((cumulative_candidate_negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach \
  737c053483d1f3d084d5f90d5c36f76b0ae8f5a3
reviewed_vsb00_head="$(make_vsb00_advance_receipt \
  737c053483d1f3d084d5f90d5c36f76b0ae8f5a3 \
  "test: replay reviewed real VSB-00 candidate tip")"
reviewed_vsb00_output="$(run_vsb_transition \
  737c053483d1f3d084d5f90d5c36f76b0ae8f5a3 \
  "${reviewed_vsb00_head}")" ||
  fail "reviewed real VSB-00 business tip was rejected: ${reviewed_vsb00_output}"
assert_contains "${reviewed_vsb00_output}" \
  "VisualStyleBaselineTaskCardValidation = PASS"
cumulative_candidate_positive_cases=$((cumulative_candidate_positive_cases + 1))

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
  "terminal VSB state requires governance zero-finding GO"
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
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" >/dev/null ||
  fail "valid STOP_BY_USER terminal receipt was rejected statically"
printf '%s\n' 'post-stop mutation' > \
  "${transition_cards}/post-stop-mutation.md"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/post-stop-mutation.md
git -C "${transition_repo_root}" commit -qm \
  "test: mutate history after terminal STOP receipt"
if post_stop_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" 2>&1
)"; then
  fail "post-STOP commit with copied terminal ledger unexpectedly passed"
fi
assert_contains "${post_stop_output}" \
  "terminal VSB state must be the exact direct-child receipt commit"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${stopped_sha}"
make_wave1_restore_projection "${transition_repo_root}"
git -C "${transition_repo_root}" add "${wave1_restore_paths[@]}"
git -C "${transition_repo_root}" commit -qm \
  "test: restore W1-I03 after terminal STOP receipt"
stopped_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" >/dev/null ||
  fail "valid restored STOPPED_BY_USER state was rejected statically"
printf '%s\n' 'post-restore mutation' > \
  "${transition_cards}/post-restore-mutation.md"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/post-restore-mutation.md
git -C "${transition_repo_root}" commit -qm \
  "test: mutate history after exact Wave 1 restore"
if post_restore_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" 2>&1
)"; then
  fail "post-restore commit with copied terminal ledger unexpectedly passed"
fi
assert_contains "${post_restore_output}" \
  "terminal VSB state must be the exact direct-child receipt commit"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
set_field "${transition_state}" "NextTaskCard" "VSB-03"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: forge nominal in-progress STOP base"
forged_stop_base_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "TaskCardSetStatus" "STOPPED_BY_USER"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "CurrentGateStatus" "STOPPED_BY_USER"
set_field "${transition_state}" "CurrentReviewRoute" "NONE"
set_field "${transition_state}" "CurrentReviewVerdict" "NOT_APPLICABLE_USER_STOP"
set_field "${transition_state}" "TransitionSequence" "2"
set_field "${transition_state}" "TransitionKind" "STOP_BY_USER"
set_field "${transition_state}" "TransitionBaseSHA" "${forged_stop_base_sha}"
set_field "${transition_state}" "VisualImplementation" "STOPPED_BY_USER"
set_field "${transition_state}" "UserStopAuthorization" "EXPLICIT_USER_INSTRUCTION"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: stop from forged nominal in-progress base"
forged_stop_head_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if forged_stop_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${forged_stop_base_sha}" \
    --transition-head "${forged_stop_head_sha}" 2>&1
)"; then
  fail "STOP_BY_USER from a forged nominal IN_PROGRESS base unexpectedly passed"
fi
assert_contains "${forged_stop_output}" \
  "transition BASE failed full VSB state validation"
negative_cases=$((negative_cases + 1))
git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"

printf '%s\n' 'forbidden intervening history' > \
  "${transition_repo_root}/raw/round10-forbidden-intervening.txt"
git -C "${transition_repo_root}" add raw/round10-forbidden-intervening.txt
git -C "${transition_repo_root}" commit -qm \
  "test: insert forbidden commit after VSB activation"
intervening_forbidden_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "candidate after forbidden intervening commit"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create exact VSB-00 candidate after forbidden commit"
intervening_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
[[ "$(git -C "${transition_repo_root}" rev-parse "${intervening_candidate_sha}^")" == \
   "${intervening_forbidden_sha}" ]] ||
  fail "intervening candidate fixture lost its forbidden direct parent"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00"
set_field "${transition_state}" "ActiveTaskCard" "VSB-01"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-01"
set_field "${transition_state}" "CurrentCandidateSHA" \
  "${intervening_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB00CandidateSHA" \
  "${intervening_candidate_sha}"
set_field "${transition_state}" "VSB00GateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "VSB00ReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "VSB-02"
set_field "${transition_state}" "TransitionSequence" "2"
set_field "${transition_state}" "TransitionKind" "ADVANCE"
set_field "${transition_state}" "TransitionBaseSHA" \
  "${intervening_candidate_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: advance candidate with an unbound parent"
intervening_receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if intervening_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${intervening_candidate_sha}" \
    --transition-head "${intervening_receipt_sha}" 2>&1
)"; then
  fail "ADVANCE candidate whose parent is not a VSB receipt unexpectedly passed"
fi
assert_contains "${intervening_output}" \
  "candidate chain commit changed a path outside the Owner WriteSet"
negative_cases=$((negative_cases + 1))
git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"

printf '%s\n' 'merge-only unauthorized history' > \
  "${transition_repo_root}/raw/round11-merge-candidate-side.txt"
git -C "${transition_repo_root}" add raw/round11-merge-candidate-side.txt
git -C "${transition_repo_root}" commit -qm \
  "test: create unauthorized side parent for candidate merge"
merge_candidate_side_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
git -C "${transition_repo_root}" merge -q --no-ff -s ours --no-commit \
  "${merge_candidate_side_sha}"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "exact VSB-00 merge candidate"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create exact VSB-00 merge candidate"
merge_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
assert_commit_parent_count "${transition_repo_root}" "${merge_candidate_sha}" 2
set_field "${transition_state}" "CompletedTaskCards" "VSB-00"
set_field "${transition_state}" "ActiveTaskCard" "VSB-01"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-01"
set_field "${transition_state}" "CurrentCandidateSHA" "${merge_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB00CandidateSHA" "${merge_candidate_sha}"
set_field "${transition_state}" "VSB00GateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "VSB00ReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "VSB-02"
set_field "${transition_state}" "TransitionSequence" "2"
set_field "${transition_state}" "TransitionKind" "ADVANCE"
set_field "${transition_state}" "TransitionBaseSHA" "${merge_candidate_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: advance a merge business candidate"
merge_candidate_receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if merge_candidate_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${merge_candidate_sha}" \
    --transition-head "${merge_candidate_receipt_sha}" 2>&1
)"; then
  fail "merge business candidate unexpectedly passed"
fi
assert_contains "${merge_candidate_output}" \
  "candidate chain commit must have exactly one parent"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "linear VSB-00 candidate for merge receipt"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create linear VSB-00 candidate for merge receipt"
merge_advance_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
printf '%s\n' 'merge receipt side history' > \
  "${transition_repo_root}/docs/task-cards/visual-style-baseline/round11-side.txt"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/round11-side.txt
git -C "${transition_repo_root}" commit -qm \
  "test: create side parent for ADVANCE receipt"
merge_advance_side_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
git -C "${transition_repo_root}" switch -q --detach \
  "${merge_advance_candidate_sha}"
git -C "${transition_repo_root}" merge -q --no-ff -s ours --no-commit \
  "${merge_advance_side_sha}"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00"
set_field "${transition_state}" "ActiveTaskCard" "VSB-01"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-01"
set_field "${transition_state}" "CurrentCandidateSHA" \
  "${merge_advance_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB00CandidateSHA" \
  "${merge_advance_candidate_sha}"
set_field "${transition_state}" "VSB00GateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "VSB00ReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "VSB-02"
set_field "${transition_state}" "TransitionSequence" "2"
set_field "${transition_state}" "TransitionKind" "ADVANCE"
set_field "${transition_state}" "TransitionBaseSHA" \
  "${merge_advance_candidate_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: create merge ADVANCE receipt"
merge_advance_receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
assert_commit_parent_count "${transition_repo_root}" \
  "${merge_advance_receipt_sha}" 2
if merge_advance_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${merge_advance_candidate_sha}" \
    --transition-head "${merge_advance_receipt_sha}" 2>&1
)"; then
  fail "merge ADVANCE receipt unexpectedly passed"
fi
assert_contains "${merge_advance_output}" \
  "transition HEAD must have exactly one parent"
negative_cases=$((negative_cases + 1))
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
  "candidate chain commit changed a path outside the Owner WriteSet"
negative_cases=$((negative_cases + 1))
git -C "${transition_repo_root}" switch -q --detach "${activation_sha}"

forbidden_rename_source="server/forbidden-vsb-rename-source.txt"
allowed_rename_target="scripts/import-visual-style-reference"
mkdir -p "${transition_repo_root}/$(dirname "${forbidden_rename_source}")"
printf '%s\n' 'rename-identical-content' > \
  "${transition_repo_root}/${forbidden_rename_source}"
git -C "${transition_repo_root}" add "${forbidden_rename_source}"
git -C "${transition_repo_root}" commit -qm \
  "test: establish forbidden rename source"
rename_parent_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
write_exact_candidate_paths "${transition_repo_root}" 0 \
  "rename-detection candidate"
rm "${transition_repo_root}/${allowed_rename_target}"
git -C "${transition_repo_root}" mv \
  "${forbidden_rename_source}" "${allowed_rename_target}"
printf '%s\n' "${candidate_write_sets[0]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: rename forbidden source into allowed VSB-00 target"
rename_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
test "$(git -C "${transition_repo_root}" diff --name-status \
  "${rename_parent_sha}..${rename_candidate_sha}" -- | \
  grep -c "^R100.*${forbidden_rename_source}.*${allowed_rename_target}$")" -eq 1 ||
  fail "rename bypass fixture did not produce an R100 change"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00"
set_field "${transition_state}" "ActiveTaskCard" "VSB-01"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-01"
set_field "${transition_state}" "CurrentCandidateSHA" "${rename_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB00CandidateSHA" "${rename_candidate_sha}"
set_field "${transition_state}" "VSB00GateStatus" "VSB-G0_PASS"
set_field "${transition_state}" "VSB00ReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "VSB-02"
set_field "${transition_state}" "TransitionSequence" "2"
set_field "${transition_state}" "TransitionKind" "ADVANCE"
set_field "${transition_state}" "TransitionBaseSHA" "${rename_candidate_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: try to release rename-bypassed VSB-00 candidate"
rename_receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if rename_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${rename_candidate_sha}" \
    --transition-head "${rename_receipt_sha}" 2>&1
)"; then
  fail "forbidden-source rename into an allowed candidate target unexpectedly passed"
fi
assert_contains "${rename_output}" \
  "candidate chain commit changed a path outside the Owner WriteSet"
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

git -C "${transition_repo_root}" switch -q --detach "${after_vsb02_receipt}"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-02"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: forge malformed COMPLETE candidate state"
forged_complete_preparent_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
write_exact_candidate_paths "${transition_repo_root}" 3 \
  "forged COMPLETE base candidate"
printf '%s\n' "${candidate_write_sets[3]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create candidate over malformed COMPLETE state"
forged_complete_base_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "TaskCardSetStatus" "COMPLETE"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "CompletedTaskCards" "VSB-00,VSB-01,VSB-02,VSB-03"
set_field "${transition_state}" "CurrentCandidateSHA" "${forged_complete_base_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G3_PASS"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer+ultra_gatekeeper"
set_field "${transition_state}" "CurrentReviewVerdict" "FINAL_GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB03CandidateSHA" "${forged_complete_base_sha}"
set_field "${transition_state}" "VSB03GateStatus" "VSB-G3_PASS"
set_field "${transition_state}" "VSB03DeepReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB03UltraReviewVerdict" "FINAL_GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "TransitionSequence" "5"
set_field "${transition_state}" "TransitionKind" "COMPLETE"
set_field "${transition_state}" "TransitionBaseSHA" "${forged_complete_base_sha}"
set_field "${transition_state}" "VisualImplementation" "COMPLETE"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: complete from malformed VSB-03 base"
forged_complete_head_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if forged_complete_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${forged_complete_base_sha}" \
    --transition-head "${forged_complete_head_sha}" 2>&1
)"; then
  fail "COMPLETE from a forged malformed BASE unexpectedly passed"
fi
assert_contains "${forged_complete_output}" \
  "transition BASE failed full VSB state validation"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${receipt_shas[0]}"
write_exact_candidate_paths "${transition_repo_root}" 1 \
  "early FINAL owner candidate"
printf '%s\n' "${candidate_write_sets[1]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create early FINAL owner candidate"
early_final_base_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "TaskCardSetStatus" "FINAL_NO_GO"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "CurrentCandidateSHA" "${early_final_base_sha}"
set_field "${transition_state}" "CurrentGateStatus" "FAIL"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer+ultra_gatekeeper"
set_field "${transition_state}" "CurrentReviewVerdict" "FINDING_P0_0_P1_1_P2_0"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "TransitionSequence" "3"
set_field "${transition_state}" "TransitionKind" "FINAL_NO_GO"
set_field "${transition_state}" "TransitionBaseSHA" "${early_final_base_sha}"
set_field "${transition_state}" "VisualImplementation" "FINAL_NO_GO"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: try FINAL_NO_GO before VSB-03"
early_final_head_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if early_final_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${early_final_base_sha}" \
    --transition-head "${early_final_head_sha}" 2>&1
)"; then
  fail "FINAL_NO_GO from an Owner other than VSB-03 unexpectedly passed"
fi
assert_contains "${early_final_output}" \
  "FINAL_NO_GO requires the VSB-03 candidate and exact predecessor prefix"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${after_vsb02_receipt}"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-02"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: forge nominal in-progress FINAL base"
forged_final_preparent_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
write_exact_candidate_paths "${transition_repo_root}" 3 \
  "forged FINAL base candidate"
printf '%s\n' "${candidate_write_sets[3]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create candidate over forged FINAL base"
forged_final_base_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "TaskCardSetStatus" "FINAL_NO_GO"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "CurrentCandidateSHA" "${forged_final_base_sha}"
set_field "${transition_state}" "CurrentGateStatus" "FAIL"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer+ultra_gatekeeper"
set_field "${transition_state}" "CurrentReviewVerdict" "FINDING_P0_0_P1_1_P2_0"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "TransitionSequence" "5"
set_field "${transition_state}" "TransitionKind" "FINAL_NO_GO"
set_field "${transition_state}" "TransitionBaseSHA" "${forged_final_base_sha}"
set_field "${transition_state}" "VisualImplementation" "FINAL_NO_GO"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: finalize from forged nominal in-progress base"
forged_final_head_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if forged_final_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${forged_final_base_sha}" \
    --transition-head "${forged_final_head_sha}" 2>&1
)"; then
  fail "FINAL_NO_GO from a forged nominal IN_PROGRESS base unexpectedly passed"
fi
assert_contains "${forged_final_output}" \
  "transition BASE failed full VSB state validation"
negative_cases=$((negative_cases + 1))

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

printf '%s\n' 'merge RETURN receipt side history' > \
  "${transition_repo_root}/docs/task-cards/visual-style-baseline/round11-return-side.txt"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/round11-return-side.txt
git -C "${transition_repo_root}" commit -qm \
  "test: create side parent for RETURN receipt"
merge_return_side_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
git -C "${transition_repo_root}" merge -q --no-ff -s ours --no-commit \
  "${merge_return_side_sha}"
prepare_return_to_owner \
  "${vsb03_candidate_sha}" VSB-02 VSB-00,VSB-01 VSB-03 5 \
  deep_reviewer+ultra_gatekeeper VISUAL_ACCEPTANCE_FAIL
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: create merge RETURN receipt"
merge_return_receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
assert_commit_parent_count "${transition_repo_root}" \
  "${merge_return_receipt_sha}" 2
if merge_return_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${merge_return_receipt_sha}" 2>&1
)"; then
  fail "merge RETURN receipt unexpectedly passed"
fi
assert_contains "${merge_return_output}" \
  "transition HEAD must have exactly one parent"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${after_vsb02_receipt}"
printf '%s\n' 'forbidden VSB-03 intervening history' > \
  "${transition_repo_root}/raw/round10-vsb03-forbidden-intervening.txt"
git -C "${transition_repo_root}" add \
  raw/round10-vsb03-forbidden-intervening.txt
git -C "${transition_repo_root}" commit -qm \
  "test: insert forbidden commit before VSB-03 candidate"
intervening_vsb03_parent_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
write_exact_candidate_paths "${transition_repo_root}" 3 \
  "VSB-03 candidate after forbidden intervening commit"
printf '%s\n' "${candidate_write_sets[3]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create exact VSB-03 candidate after forbidden commit"
intervening_vsb03_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
[[ "$(git -C "${transition_repo_root}" rev-parse \
  "${intervening_vsb03_candidate_sha}^")" == \
   "${intervening_vsb03_parent_sha}" ]] ||
  fail "intervening VSB-03 fixture lost its forbidden direct parent"

set_field "${transition_state}" "TaskCardSetStatus" "COMPLETE"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "CompletedTaskCards" \
  "VSB-00,VSB-01,VSB-02,VSB-03"
set_field "${transition_state}" "CurrentCandidateSHA" \
  "${intervening_vsb03_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "VSB-G3_PASS"
set_field "${transition_state}" "CurrentReviewRoute" \
  "deep_reviewer+ultra_gatekeeper"
set_field "${transition_state}" "CurrentReviewVerdict" \
  "FINAL_GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB03CandidateSHA" \
  "${intervening_vsb03_candidate_sha}"
set_field "${transition_state}" "VSB03GateStatus" "VSB-G3_PASS"
set_field "${transition_state}" "VSB03DeepReviewVerdict" \
  "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB03UltraReviewVerdict" \
  "FINAL_GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "TransitionSequence" "5"
set_field "${transition_state}" "TransitionKind" "COMPLETE"
set_field "${transition_state}" "TransitionBaseSHA" \
  "${intervening_vsb03_candidate_sha}"
set_field "${transition_state}" "VisualImplementation" "COMPLETE"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: complete candidate with an unbound parent"
intervening_complete_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if intervening_complete_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${intervening_vsb03_candidate_sha}" \
    --transition-head "${intervening_complete_sha}" 2>&1
)"; then
  fail "COMPLETE candidate whose parent is not a VSB receipt unexpectedly passed"
fi
assert_contains "${intervening_complete_output}" \
  "candidate chain commit changed a path outside the Owner WriteSet"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach \
  "${intervening_vsb03_candidate_sha}"
prepare_return_to_owner \
  "${intervening_vsb03_candidate_sha}" VSB-02 VSB-00,VSB-01 VSB-03 5 \
  deep_reviewer+ultra_gatekeeper VISUAL_ACCEPTANCE_FAIL
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: cross-card return candidate with an unbound parent"
intervening_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if intervening_return_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${intervening_vsb03_candidate_sha}" \
    --transition-head "${intervening_return_sha}" 2>&1
)"; then
  fail "cross-card RETURN candidate whose parent is not a VSB receipt unexpectedly passed"
fi
assert_contains "${intervening_return_output}" \
  "candidate chain commit changed a path outside the Owner WriteSet"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${receipt_shas[0]}"
write_exact_candidate_paths "${transition_repo_root}" 1 \
  "alternate immutable VSB-01 receipt"
printf '%s\n' "${candidate_write_sets[1]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create alternate valid VSB-01 candidate"
alternate_vsb01_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
prepare_return_to_owner \
  "${vsb03_candidate_sha}" VSB-02 VSB-00,VSB-01 VSB-03 5 \
  deep_reviewer+ultra_gatekeeper VISUAL_ACCEPTANCE_FAIL
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: return VSB-03 visual finding to VSB-02"
vsb03_to_vsb02_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if ! vsb03_to_vsb02_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${vsb03_to_vsb02_return_sha}" 2>&1
)"; then
  fail "valid VSB-03 to VSB-02 RETURN_TO_OWNER was rejected: ${vsb03_to_vsb02_output}"
fi

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
prepare_return_to_owner \
  "${vsb03_candidate_sha}" VSB-01 VSB-00 VSB-02 5 \
  deep_reviewer+ultra_gatekeeper FINDING_P0_0_P1_1_P2_0
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: return VSB-03 review finding to VSB-01"
vsb03_to_vsb01_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" \
  --transition-base "${vsb03_candidate_sha}" \
  --transition-head "${vsb03_to_vsb01_return_sha}" >/dev/null ||
  fail "valid VSB-03 to VSB-01 RETURN_TO_OWNER was rejected"

git -C "${transition_repo_root}" switch -q --detach "${candidate_shas[1]}"
prepare_return_to_owner \
  "${candidate_shas[1]}" VSB-02 VSB-00,VSB-01 VSB-03 3 \
  deep_reviewer FINDING_P0_0_P1_1_P2_0
set_field "${transition_state}" "VSB01CandidateSHA" "${candidate_shas[1]}"
set_field "${transition_state}" "VSB01GateStatus" "VSB-G1_PASS"
set_field "${transition_state}" "VSB01ReviewVerdict" "GO_P0_0_P1_0_P2_0"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: try to return VSB-01 forward to VSB-02"
forward_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if forward_return_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${candidate_shas[1]}" \
    --transition-head "${forward_return_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER targeting a later card unexpectedly passed"
fi
assert_contains "${forward_return_output}" \
  "RETURN_TO_OWNER target must be the base active Owner or a strict predecessor"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
prepare_return_to_owner \
  "${vsb03_candidate_sha}" VSB-02 VSB-00 VSB-03 5 \
  deep_reviewer+ultra_gatekeeper VISUAL_ACCEPTANCE_FAIL
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: return with the wrong strict predecessor prefix"
wrong_return_prefix_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if wrong_return_prefix_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${wrong_return_prefix_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER with the wrong predecessor prefix unexpectedly passed"
fi
assert_contains "${wrong_return_prefix_output}" \
  "IN_PROGRESS active, released, or next card mismatch"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
prepare_return_to_owner \
  "${vsb03_candidate_sha}" VSB-02 VSB-00,VSB-01 VSB-03 5 \
  deep_reviewer+ultra_gatekeeper VISUAL_ACCEPTANCE_FAIL
set_field "${transition_state}" "VSB02CandidateSHA" "${candidate_shas[2]}"
set_field "${transition_state}" "VSB02GateStatus" "VSB-G2_PASS"
set_field "${transition_state}" "VSB02ReviewVerdict" "GO_P0_0_P1_0_P2_0"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: retain the returned VSB-02 receipt"
uncleared_owner_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if uncleared_owner_return_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${uncleared_owner_return_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER retaining the target Owner receipt unexpectedly passed"
fi
assert_contains "${uncleared_owner_return_output}" \
  "bootstrap receipts must remain NONE or NOT_RUN"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
prepare_return_to_owner \
  "${vsb03_candidate_sha}" VSB-02 VSB-00,VSB-01 VSB-03 5 \
  deep_reviewer+ultra_gatekeeper VISUAL_ACCEPTANCE_FAIL
set_field "${transition_state}" "VSB03CandidateSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "VSB03GateStatus" "VSB-G3_PASS"
set_field "${transition_state}" "VSB03DeepReviewVerdict" "GO_P0_0_P1_0_P2_0"
set_field "${transition_state}" "VSB03UltraReviewVerdict" \
  "FINAL_GO_P0_0_P1_0_P2_0"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: retain a successor receipt during return"
uncleared_successor_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if uncleared_successor_return_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${uncleared_successor_return_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER retaining a successor receipt unexpectedly passed"
fi
assert_contains "${uncleared_successor_return_output}" \
  "bootstrap receipts must remain NONE or NOT_RUN"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
prepare_return_to_owner \
  "${vsb03_candidate_sha}" VSB-02 VSB-00,VSB-01 VSB-03 5 \
  deep_reviewer+ultra_gatekeeper VISUAL_ACCEPTANCE_FAIL
set_field "${transition_state}" "VSB01CandidateSHA" \
  "${alternate_vsb01_candidate_sha}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: rewrite a strict predecessor receipt during return"
mutated_predecessor_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if mutated_predecessor_return_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${mutated_predecessor_return_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER rewriting a strict predecessor receipt unexpectedly passed"
fi
assert_contains "${mutated_predecessor_return_output}" \
  "RETURN_TO_OWNER must preserve strict predecessor receipts"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${after_vsb02_receipt}"
write_exact_candidate_paths "${transition_repo_root}" 2 \
  "wrong VSB-03 failure candidate WriteSet"
printf '%s\n' "${candidate_write_sets[2]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create VSB-03 failure candidate from the VSB-02 WriteSet"
wrong_return_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
prepare_return_to_owner \
  "${wrong_return_candidate_sha}" VSB-02 VSB-00,VSB-01 VSB-03 5 \
  deep_reviewer+ultra_gatekeeper VISUAL_ACCEPTANCE_FAIL
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: return a failure candidate from the wrong card WriteSet"
wrong_return_candidate_receipt_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if wrong_return_candidate_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${wrong_return_candidate_sha}" \
    --transition-head "${wrong_return_candidate_receipt_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER accepting the target Owner WriteSet for the failed candidate unexpectedly passed"
fi
assert_contains "${wrong_return_candidate_output}" \
  "candidate chain commit changed a path outside the Owner WriteSet"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
prepare_return_to_owner \
  "${vsb03_candidate_sha}" VSB-02 VSB-00,VSB-01 VSB-03 5 \
  deep_reviewer VISUAL_ACCEPTANCE_FAIL
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: return with the target Owner review route"
wrong_return_route_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if wrong_return_route_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${wrong_return_route_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER using the target Owner review route unexpectedly passed"
fi
assert_contains "${wrong_return_route_output}" \
  "RETURN_TO_OWNER current review route must match the base active Owner"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
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
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" >/dev/null ||
  fail "valid VSB COMPLETE terminal receipt was rejected statically"

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
printf '%s\n' 'merge COMPLETE receipt side history' > \
  "${transition_repo_root}/docs/task-cards/visual-style-baseline/round11-complete-side.txt"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/round11-complete-side.txt
git -C "${transition_repo_root}" commit -qm \
  "test: create side parent for COMPLETE receipt"
merge_complete_side_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
git -C "${transition_repo_root}" merge -q --no-ff -s ours --no-commit \
  "${merge_complete_side_sha}"
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
git -C "${transition_repo_root}" commit -qm \
  "test: create merge COMPLETE receipt"
merge_complete_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
assert_commit_parent_count "${transition_repo_root}" "${merge_complete_sha}" 2
if merge_complete_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" 2>&1
)"; then
  fail "merge terminal COMPLETE receipt unexpectedly passed"
fi
assert_contains "${merge_complete_output}" \
  "terminal VSB state HEAD must have exactly one parent"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${complete_sha}"
make_wave1_restore_projection "${transition_repo_root}"
git -C "${transition_repo_root}" add "${wave1_restore_paths[@]}"
git -C "${transition_repo_root}" commit -qm \
  "test: restore W1-I03 after terminal COMPLETE receipt"
complete_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
"${verifier}" \
  --repo-root "${transition_repo_root}" \
  --cards-dir "${transition_cards}" >/dev/null ||
  fail "valid restored COMPLETE state was rejected statically"

git -C "${transition_repo_root}" switch -q --detach "${complete_sha}"
printf '%s\n' 'merge restore side history' > \
  "${transition_repo_root}/docs/task-cards/visual-style-baseline/round11-restore-side.txt"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/round11-restore-side.txt
git -C "${transition_repo_root}" commit -qm \
  "test: create side parent for Wave restore"
merge_restore_side_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
git -C "${transition_repo_root}" switch -q --detach "${complete_sha}"
git -C "${transition_repo_root}" merge -q --no-ff -s ours --no-commit \
  "${merge_restore_side_sha}"
make_wave1_restore_projection "${transition_repo_root}"
git -C "${transition_repo_root}" add "${wave1_restore_paths[@]}"
git -C "${transition_repo_root}" commit -qm \
  "test: create merge Wave restore"
merge_restore_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
assert_commit_parent_count "${transition_repo_root}" "${merge_restore_sha}" 2
if merge_restore_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" 2>&1
)"; then
  fail "merge Wave restore unexpectedly passed"
fi
assert_contains "${merge_restore_output}" \
  "terminal VSB state HEAD must have exactly one parent"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${complete_restore_sha}"

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
set_field "${transition_state}" "TaskCardSetStatus" "FINAL_NO_GO"
set_field "${transition_state}" "ActiveTaskCard" "NONE"
set_field "${transition_state}" "ReleasedTaskCard" "NONE"
set_field "${transition_state}" "CurrentCandidateSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "FAIL"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "FINDING_P0_0_P1_1_P2_0"
set_field "${transition_state}" "NextTaskCard" "NONE"
set_field "${transition_state}" "TransitionSequence" "5"
set_field "${transition_state}" "TransitionKind" "FINAL_NO_GO"
set_field "${transition_state}" "TransitionBaseSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "VisualImplementation" "FINAL_NO_GO"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: finalize VSB-03 with wrong review route"
wrong_final_route_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if wrong_final_route_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${wrong_final_route_sha}" 2>&1
)"; then
  fail "FINAL_NO_GO with the wrong review route unexpectedly passed"
fi
assert_contains "${wrong_final_route_output}" \
  "FINAL_NO_GO requires the fixed visual acceptance review route"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${vsb03_candidate_sha}"
set_field "${transition_state}" "ActiveTaskCard" "VSB-99"
set_field "${transition_state}" "ReleasedTaskCard" "VSB-99"
set_field "${transition_state}" "CurrentCandidateSHA" "${vsb03_candidate_sha}"
set_field "${transition_state}" "CurrentGateStatus" "FAIL"
set_field "${transition_state}" "CurrentReviewRoute" \
  "deep_reviewer+ultra_gatekeeper"
set_field "${transition_state}" "CurrentReviewVerdict" "FINDING_P0_0_P1_1_P2_0"
set_field "${transition_state}" "TransitionSequence" "5"
set_field "${transition_state}" "TransitionKind" "RETURN_TO_OWNER"
set_field "${transition_state}" "TransitionBaseSHA" "${vsb03_candidate_sha}"
printf '%s\n' 'Owner = VSB-99' >> "${transition_state}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: return VSB-03 finding to a nonexistent owner"
wrong_return_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if wrong_return_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${vsb03_candidate_sha}" \
    --transition-head "${wrong_return_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER reopening a nonexistent card unexpectedly passed"
fi
assert_contains "${wrong_return_output}" \
  "ActiveTaskCard must name one known card or NONE"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${receipt_shas[0]}"
write_exact_candidate_paths "${transition_repo_root}" 1 "VSB-01 finding candidate"
printf '%s\n' "${candidate_write_sets[1]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm "test: create VSB-01 finding candidate"
return_candidate_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "NextTaskCard" "VSB-03"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: forge malformed RETURN_TO_OWNER candidate state"
forged_return_preparent_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
write_exact_candidate_paths "${transition_repo_root}" 1 \
  "forged RETURN_TO_OWNER base candidate"
printf '%s\n' "${candidate_write_sets[1]}" | \
  git -C "${transition_repo_root}" add --pathspec-from-file=-
git -C "${transition_repo_root}" commit -qm \
  "test: create candidate over malformed RETURN_TO_OWNER state"
forged_return_base_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
set_field "${transition_state}" "CurrentCandidateSHA" "${forged_return_base_sha}"
set_field "${transition_state}" "CurrentGateStatus" "FAIL"
set_field "${transition_state}" "CurrentReviewRoute" "deep_reviewer"
set_field "${transition_state}" "CurrentReviewVerdict" "FINDING_P0_0_P1_1_P2_0"
set_field "${transition_state}" "NextTaskCard" "VSB-02"
set_field "${transition_state}" "TransitionSequence" "3"
set_field "${transition_state}" "TransitionKind" "RETURN_TO_OWNER"
set_field "${transition_state}" "TransitionBaseSHA" "${forged_return_base_sha}"
printf '%s\n' 'Owner = VSB-01' >> "${transition_state}"
git -C "${transition_repo_root}" add \
  docs/task-cards/visual-style-baseline/execution-state.md
git -C "${transition_repo_root}" commit -qm \
  "test: return from malformed VSB-01 base"
forged_return_head_sha="$(git -C "${transition_repo_root}" rev-parse HEAD)"
if forged_return_output="$(
  "${verifier}" \
    --repo-root "${transition_repo_root}" \
    --cards-dir "${transition_cards}" \
    --transition-base "${forged_return_base_sha}" \
    --transition-head "${forged_return_head_sha}" 2>&1
)"; then
  fail "RETURN_TO_OWNER from a forged malformed BASE unexpectedly passed"
fi
assert_contains "${forged_return_output}" \
  "transition BASE failed full VSB state validation"
negative_cases=$((negative_cases + 1))

git -C "${transition_repo_root}" switch -q --detach "${return_candidate_sha}"
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

baseline_transition_cases=22
round10_parent_binding_transition_cases=3
round11_merge_transition_cases=3
governance_repair_transition_cases=3
transition_cases=$((
  baseline_transition_cases +
  round10_parent_binding_transition_cases +
  round11_merge_transition_cases +
  governance_repair_transition_cases
))
fixed_base_transition_cases=6
binary_ledger_cases=1
cross_card_return_positive_cases=2
cross_card_return_negative_cases=8

printf '%s\n' \
  "VisualStyleBaselineTaskCardContractTests = PASS" \
  "PositiveCases = 1" \
  "EarlyExitCases = ${early_exit_cases}" \
  "RegisteredTemporaryCleanupCases = ${registered_temporary_cleanup_cases}" \
  "NegativeCases = ${negative_cases}" \
  "TransitionCases = ${transition_cases}" \
  "FixedBaseTransitionCases = ${fixed_base_transition_cases}" \
  "BinaryLedgerCases = ${binary_ledger_cases}" \
  "CumulativeCandidatePositiveCases = ${cumulative_candidate_positive_cases}" \
  "CumulativeCandidateNegativeCases = ${cumulative_candidate_negative_cases}" \
  "GovernanceRepairPositiveCases = ${governance_repair_positive_cases}" \
  "GovernanceRepairNegativeCases = ${governance_repair_negative_cases}" \
  "CrossCardReturnPositiveCases = ${cross_card_return_positive_cases}" \
  "CrossCardReturnNegativeCases = ${cross_card_return_negative_cases}"
