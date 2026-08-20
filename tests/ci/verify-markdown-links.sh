#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-markdown-links.XXXXXX")"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

list_markdown_files() {
  local root="$1"
  local scope="$2"
  local relative_path

  if [[ "${scope}" == "tracked" ]]; then
    while IFS= read -r -d '' relative_path; do
      printf '%s\0' "${root}/${relative_path}"
    done < <(git -C "${root}" ls-files -z -- '*.md')
    return
  fi
  [[ "${scope}" == "filesystem" ]] || fail "unknown Markdown file scope: ${scope}"
  find "${root}" \
    -type d \( \
      -name .git -o \
      -name node_modules -o \
      -name target -o \
      -name dist \
    \) -prune -o \
    -type f -name '*.md' -print0
}

verify_markdown_tree() {
  local root="$1"
  local scope="${2:-filesystem}"
  local markdown_file
  local raw_link
  local link
  local candidate
  local link_count=0

  while IFS= read -r -d '' markdown_file; do
    while IFS= read -r raw_link; do
      link="${raw_link#](}"
      link="${link%)}"

      case "${link}" in
        ""|\#*|http://*|https://*|mailto:*)
          continue
          ;;
      esac

      link="${link%%#*}"
      [[ -n "${link}" ]] || continue
      if [[ "${link}" == /* ]]; then
        printf 'BROKEN_MARKDOWN_LINK: absolute local path in %s: %s\n' \
          "${markdown_file#${root}/}" "${link}" >&2
        return 1
      fi

      candidate="$(dirname "${markdown_file}")/${link}"
      if [[ ! -e "${candidate}" ]]; then
        printf 'BROKEN_MARKDOWN_LINK: %s -> %s\n' \
          "${markdown_file#${root}/}" "${link}" >&2
        return 1
      fi
      link_count=$((link_count + 1))
    done < <(grep -Eo '\]\([^)]*\)' "${markdown_file}" || true)
  done < <(list_markdown_files "${root}" "${scope}")

  printf '%s\n' \
    "MarkdownLinkValidation = PASS" \
    "LocalMarkdownLinkCount = ${link_count}"
}

if ! canonical_output="$(verify_markdown_tree "${repo_root}" tracked 2>&1)"; then
  fail "canonical Markdown links were rejected: ${canonical_output}"
fi
[[ "${canonical_output}" == *"MarkdownLinkValidation = PASS"* ]] ||
  fail "canonical Markdown validation did not report PASS"

broken_root="${test_tmp_root}/broken"
mkdir -p "${broken_root}"
printf '%s\n' '[missing](missing.md)' >"${broken_root}/README.md"
if broken_output="$(verify_markdown_tree "${broken_root}" 2>&1)"; then
  fail "broken Markdown link unexpectedly passed"
fi
[[ "${broken_output}" == *"BROKEN_MARKDOWN_LINK: README.md -> missing.md"* ]] ||
  fail "broken Markdown link failed for the wrong reason: ${broken_output}"

tracked_root="${test_tmp_root}/tracked"
mkdir -p "${tracked_root}"
git -C "${tracked_root}" init -q
printf '%s\n' '[target](target.md)' >"${tracked_root}/README.md"
printf '%s\n' '# Target' >"${tracked_root}/target.md"
git -C "${tracked_root}" add README.md target.md
printf '%s\n' '[missing](missing.md)' >"${tracked_root}/untracked.md"
if ! tracked_output="$(verify_markdown_tree "${tracked_root}" tracked 2>&1)"; then
  fail "untracked Markdown affected tracked-only validation: ${tracked_output}"
fi

printf '%s\n' \
  "MarkdownLinkContractTests = PASS" \
  "CanonicalMarkdownLinks = PASS" \
  "BrokenLinkNegativeCases = 1" \
  "UntrackedMarkdownIsolationCases = 1"
