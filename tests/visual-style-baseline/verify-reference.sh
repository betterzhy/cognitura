#!/bin/bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-visual-style-baseline-reference"
importer="${repo_root}/scripts/import-visual-style-reference"
manifest="${repo_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml"
reference_doc="${repo_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
reference_image="${repo_root}/docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png"
approved_source="${COGNITURA_VISUAL_STYLE_SOURCE_JPEG:-/tmp/codex-remote-attachments/019ff394-031c-7413-b56a-f998be9014b8/56C24D47-8B5E-4367-A394-5748FBC8DD5A/1-Photo-1.jpg}"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-visual-style-reference.XXXXXX")"
canonical_document_size="$(sed -n '/^document:$/,/^referenceImage:$/s/^  sizeBytes: //p' "${manifest}")"
canonical_document_hash="$(sed -n '/^document:$/,/^referenceImage:$/s/^  sha256: //p' "${manifest}")"

cleanup() {
  rm -rf -- "${test_tmp_root}"
}
trap cleanup EXIT HUP INT TERM

fail() {
  printf 'VisualStyleReferenceContractTests = FAIL: %s\n' "$1" >&2
  exit 1
}

expect_line() {
  local output="$1"
  local expected="$2"
  printf '%s\n' "${output}" | grep -Fqx -- "${expected}" ||
    fail "missing verifier receipt: ${expected}"
}

expect_failure() {
  local fixture_root="$1"
  local label="$2"
  shift 2
  if "${verifier}" --repo-root "${fixture_root}" "$@" >/dev/null 2>&1; then
    fail "negative fixture was accepted: ${label}"
  fi
}

make_fixture() {
  local fixture_root="$1"
  mkdir -p \
    "${fixture_root}/docs/design/reference" \
    "${fixture_root}/docs/design/high-fidelity" \
    "${fixture_root}/docs/engineering"
  cp "${repo_root}/AGENTS.md" "${fixture_root}/AGENTS.md"
  cp "${reference_doc}" "${fixture_root}/docs/design/"
  cp "${reference_image}" "${fixture_root}/docs/design/reference/"
  cp "${repo_root}/docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md" \
    "${fixture_root}/docs/design/high-fidelity/"
  cp "${repo_root}/docs/engineering/cognitura-design-index.md" \
    "${fixture_root}/docs/engineering/"
  cp "${manifest}" "${fixture_root}/docs/engineering/"
}

sync_manifest_document_fingerprint() {
  local fixture_root="$1"
  local target="${fixture_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
  local fixture_manifest="${fixture_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml"
  local size
  local hash
  size="$(stat -f '%z' "${target}")"
  hash="$(shasum -a 256 "${target}" | awk '{print $1}')"
  sed -i.bak "s/^  sizeBytes: ${canonical_document_size}$/  sizeBytes: ${size}/" "${fixture_manifest}"
  rm "${fixture_manifest}.bak"
  sed -i.bak "s/^  sha256: ${canonical_document_hash}$/  sha256: ${hash}/" "${fixture_manifest}"
  rm "${fixture_manifest}.bak"
}

sync_manifest_image_fingerprint() {
  local fixture_root="$1"
  local target="${fixture_root}/docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png"
  local fixture_manifest="${fixture_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml"
  local size
  local hash
  size="$(stat -f '%z' "${target}")"
  hash="$(shasum -a 256 "${target}" | awk '{print $1}')"
  sed -i.bak "s/^  sizeBytes: 867083$/  sizeBytes: ${size}/" "${fixture_manifest}"
  rm "${fixture_manifest}.bak"
  sed -i.bak "s/^  sha256: a8446ea987f6a1710c3845f837e2776190997b77f81584cf7b667cbfebe2f95f$/  sha256: ${hash}/" "${fixture_manifest}"
  rm "${fixture_manifest}.bak"
}

[[ -x "${verifier}" ]] || fail "standalone verifier is missing or not executable"
[[ -x "${importer}" ]] || fail "reference importer is missing or not executable"
[[ -f "${manifest}" ]] || fail "visual style baseline manifest is missing"
[[ -f "${reference_doc}" ]] || fail "formal visual style reference is missing"
[[ -f "${reference_image}" ]] || fail "reference PNG is missing"

canonical_output="$("${verifier}" --repo-root "${repo_root}")" ||
  fail "canonical visual style baseline was rejected"

expect_line "${canonical_output}" 'CanonicalProjectName=Cognitura'
expect_line "${canonical_output}" 'SourceMediaType=image/jpeg'
expect_line "${canonical_output}" 'SourcePixelSize=1280x853'
expect_line "${canonical_output}" 'SourceSizeBytes=210103'
expect_line "${canonical_output}" 'SourceSHA256=812eb50de5b4c7678349bf427977d2917388b70f25f18b6035f55123c7739249'
expect_line "${canonical_output}" 'ReferenceMediaType=image/png'
expect_line "${canonical_output}" 'ReferencePixelSize=1280x853'
expect_line "${canonical_output}" 'ReferenceColorMode=RGB'
expect_line "${canonical_output}" 'ReferenceSizeBytes=867083'
expect_line "${canonical_output}" 'ReferenceSHA256=a8446ea987f6a1710c3845f837e2776190997b77f81584cf7b667cbfebe2f95f'
expect_line "${canonical_output}" 'ReferenceRole=VISUAL_STYLE_REFERENCE_ONLY'
expect_line "${canonical_output}" 'PageArchitectureAuthority=NO'
expect_line "${canonical_output}" 'InteractionAuthority=NO'
expect_line "${canonical_output}" 'DashboardLayoutAuthority=NO'
expect_line "${canonical_output}" 'ManifestPath=docs/engineering/cognitura-visual-style-baseline-manifest.yaml'
expect_line "${canonical_output}" 'ManifestDocumentVersion="1.0"'
expect_line "${canonical_output}" 'NormalizedColorRoleCount=25'
expect_line "${canonical_output}" 'NormalizedColorConfidence=INFERRED'
expect_line "${canonical_output}" 'NonColorVisualContract=PASS'
expect_line "${canonical_output}" 'ConditionsResultsProjection=BLOCKED_BY_DOC-GAP-MDR-001'
expect_line "${canonical_output}" 'AntiDashboardForbiddenRuleCount=22'
expect_line "${canonical_output}" 'VisualStyleBaselineReferenceVerification=PASS'

# A wrong source hash must be rejected before image decoding.
wrong_source="${test_tmp_root}/wrong-source.jpg"
printf 'not-the-approved-jpeg' >"${wrong_source}"
if "${verifier}" --repo-root "${repo_root}" --source-jpeg "${wrong_source}" >/dev/null 2>&1; then
  fail "wrong source hash was accepted"
fi
if "${importer}" --source-jpeg "${wrong_source}" --output-png "${test_tmp_root}/wrong-source.png" >/dev/null 2>&1; then
  fail "importer accepted a wrong source hash"
fi
if "${importer}" --output-png "${test_tmp_root}/wrong-order.png" --source-jpeg "${wrong_source}" >/dev/null 2>&1; then
  fail "importer accepted arguments outside the exact wrapper contract"
fi

# The importer must reproduce the exact committed PNG and preserve an existing exact target.
if [[ -f "${approved_source}" ]]; then
  import_root="${test_tmp_root}/import"
  mkdir -p "${import_root}"
  import_output="${import_root}/reference.png"
  import_receipt="$("${importer}" --source-jpeg "${approved_source}" --output-png "${import_output}")" ||
    fail "approved source import failed"
  expect_line "${import_receipt}" 'SourceSHA256=812eb50de5b4c7678349bf427977d2917388b70f25f18b6035f55123c7739249'
  expect_line "${import_receipt}" 'OutputSHA256=a8446ea987f6a1710c3845f837e2776190997b77f81584cf7b667cbfebe2f95f'
  expect_line "${import_receipt}" 'Dimensions=1280x853'
  expect_line "${import_receipt}" 'PixelEquivalence=PASS'
  cmp -s "${import_output}" "${reference_image}" || fail "imported PNG differs from committed reference"
  before_mtime="$(stat -f '%m' "${import_output}")"
  "${importer}" --source-jpeg "${approved_source}" --output-png "${import_output}" >/dev/null ||
    fail "idempotent exact-target import failed"
  [[ "$(stat -f '%m' "${import_output}")" == "${before_mtime}" ]] ||
    fail "exact existing target was overwritten"
fi

wrong_png_hash_root="${test_tmp_root}/wrong-png-hash"
make_fixture "${wrong_png_hash_root}"
printf 'tampered' >>"${wrong_png_hash_root}/docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png"
expect_failure "${wrong_png_hash_root}" 'wrong PNG hash'

wrong_manifest_image_hash_root="${test_tmp_root}/wrong-manifest-image-hash"
make_fixture "${wrong_manifest_image_hash_root}"
sed -i.bak 's/a8446ea987f6a1710c3845f837e2776190997b77f81584cf7b667cbfebe2f95f/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/' \
  "${wrong_manifest_image_hash_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml"
rm "${wrong_manifest_image_hash_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml.bak"
expect_failure "${wrong_manifest_image_hash_root}" 'wrong manifest image hash'

one_pixel_root="${test_tmp_root}/one-pixel-png"
make_fixture "${one_pixel_root}"
python3 - "${one_pixel_root}/docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png" <<'PY'
from PIL import Image
import sys
Image.new("RGB", (1, 1), (255, 255, 255)).save(sys.argv[1], format="PNG", optimize=False, compress_level=6)
PY
sync_manifest_image_fingerprint "${one_pixel_root}"
expect_failure "${one_pixel_root}" '1x1 PNG'

altered_pixel_root="${test_tmp_root}/altered-decoded-pixel"
make_fixture "${altered_pixel_root}"
python3 - "${altered_pixel_root}/docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png" <<'PY'
from PIL import Image
import sys
path = sys.argv[1]
with Image.open(path) as source:
    image = source.convert("RGB")
pixel = image.getpixel((0, 0))
image.putpixel((0, 0), ((pixel[0] + 1) % 256, pixel[1], pixel[2]))
image.save(path, format="PNG", optimize=False, compress_level=6)
PY
sync_manifest_image_fingerprint "${altered_pixel_root}"
if [[ -f "${approved_source}" ]]; then
  expect_failure "${altered_pixel_root}" 'altered decoded pixel' --source-jpeg "${approved_source}"
else
  expect_failure "${altered_pixel_root}" 'altered decoded pixel'
fi

missing_inferred_root="${test_tmp_root}/missing-inferred"
make_fixture "${missing_inferred_root}"
sed -i.bak '/^| FontStack |/s/`INFERRED`/`UNCLASSIFIED`/' \
  "${missing_inferred_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
rm "${missing_inferred_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md.bak"
sync_manifest_document_fingerprint "${missing_inferred_root}"
expect_failure "${missing_inferred_root}" 'missing INFERRED classification'

wrong_color_role_root="${test_tmp_root}/wrong-color-role"
make_fixture "${wrong_color_role_root}"
sed -i.bak 's/^| CanvasBackground |/| Canvas |/' \
  "${wrong_color_role_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
rm "${wrong_color_role_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md.bak"
sync_manifest_document_fingerprint "${wrong_color_role_root}"
expect_failure "${wrong_color_role_root}" 'wrong approved normalized color role name'

wrong_color_value_root="${test_tmp_root}/wrong-color-value"
make_fixture "${wrong_color_value_root}"
sed -i.bak 's/CanvasBackground = #F7F9FC/CanvasBackground = #FFFFFF/' \
  "${wrong_color_value_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
rm "${wrong_color_value_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md.bak"
sync_manifest_document_fingerprint "${wrong_color_value_root}"
expect_failure "${wrong_color_value_root}" 'wrong approved normalized color value'

forged_normalized_confidence_root="${test_tmp_root}/forged-normalized-confidence"
make_fixture "${forged_normalized_confidence_root}"
sed -i.bak '/^| CanvasBackground |/s/`INFERRED`/`MEASURED_FROM_REFERENCE_PIXELS`/' \
  "${forged_normalized_confidence_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
rm "${forged_normalized_confidence_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md.bak"
sync_manifest_document_fingerprint "${forged_normalized_confidence_root}"
expect_failure "${forged_normalized_confidence_root}" 'normalized color token falsely claims pixel precision'

extra_color_role_root="${test_tmp_root}/extra-color-role"
make_fixture "${extra_color_role_root}"
sed -i.bak '/^## 3\. Typography 合同$/i\
| ExperimentalGlow | `#AA77FF` 的装饰性像素簇 | `ExperimentalGlow = #AA77FF` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 未批准的第 26 个角色。 |\
' "${extra_color_role_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
rm "${extra_color_role_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md.bak"
sync_manifest_document_fingerprint "${extra_color_role_root}"
expect_failure "${extra_color_role_root}" 'extra 26th normalized color role'

duplicate_color_role_root="${test_tmp_root}/duplicate-color-role"
make_fixture "${duplicate_color_role_root}"
sed -i.bak '/^## 3\. Typography 合同$/i\
| CanvasBackground | `#F8F9FB` 的重复像素簇 | `CanvasBackground = #F7F9FC` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 重复角色。 |\
' "${duplicate_color_role_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
rm "${duplicate_color_role_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md.bak"
sync_manifest_document_fingerprint "${duplicate_color_role_root}"
expect_failure "${duplicate_color_role_root}" 'duplicate normalized color role'

missing_color_role_root="${test_tmp_root}/missing-color-role"
make_fixture "${missing_color_role_root}"
sed -i.bak '/^| InformationSoft |/d' \
  "${missing_color_role_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
rm "${missing_color_role_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md.bak"
sync_manifest_document_fingerprint "${missing_color_role_root}"
expect_failure "${missing_color_role_root}" 'missing normalized color role'

missing_font_stack_root="${test_tmp_root}/missing-font-stack"
make_fixture "${missing_font_stack_root}"
sed -i.bak '/"PingFang SC"/d' \
  "${missing_font_stack_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
rm "${missing_font_stack_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md.bak"
sync_manifest_document_fingerprint "${missing_font_stack_root}"
expect_failure "${missing_font_stack_root}" 'incomplete approved font stack'

missing_mdr_gap_root="${test_tmp_root}/missing-mdr-gap"
make_fixture "${missing_mdr_gap_root}"
sed -i.bak '/DOC-GAP-MDR-001/d' \
  "${missing_mdr_gap_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
rm "${missing_mdr_gap_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md.bak"
sync_manifest_document_fingerprint "${missing_mdr_gap_root}"
expect_failure "${missing_mdr_gap_root}" 'missing Conditions Results documentation-gap boundary'

wrong_shadow_root="${test_tmp_root}/wrong-shadow-contract"
make_fixture "${wrong_shadow_root}"
sed -i.bak 's/0 2px 6px rgb(16 24 40 \/ 5%)/0 4px 12px rgb(16 24 40 \/ 20%)/' \
  "${wrong_shadow_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
rm "${wrong_shadow_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md.bak"
sync_manifest_document_fingerprint "${wrong_shadow_root}"
expect_failure "${wrong_shadow_root}" 'wrong approved shadow contract'

wrong_relation_priority_root="${test_tmp_root}/wrong-relation-priority"
make_fixture "${wrong_relation_priority_root}"
sed -i.bak 's/Natural Language Statement > Relation Verb > Shape > Direction > Endpoint > Line Style > Color/Color > Line Style > Endpoint/' \
  "${wrong_relation_priority_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
rm "${wrong_relation_priority_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md.bak"
sync_manifest_document_fingerprint "${wrong_relation_priority_root}"
expect_failure "${wrong_relation_priority_root}" 'wrong Relation recognition priority'

extra_forbidden_rule_root="${test_tmp_root}/extra-forbidden-rule"
make_fixture "${extra_forbidden_rule_root}"
sed -i.bak '/^```$/i\
UnapprovedParallelVisualRule = FORBIDDEN' \
  "${extra_forbidden_rule_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
rm "${extra_forbidden_rule_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md.bak"
sync_manifest_document_fingerprint "${extra_forbidden_rule_root}"
expect_failure "${extra_forbidden_rule_root}" 'extra parallel anti-dashboard rule'

duplicate_generic_ai_root="${test_tmp_root}/duplicate-generic-ai-rule"
make_fixture "${duplicate_generic_ai_root}"
printf 'GenericAISaaSStyling = FORBIDDEN\n' >> \
  "${duplicate_generic_ai_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
sync_manifest_document_fingerprint "${duplicate_generic_ai_root}"
expect_failure "${duplicate_generic_ai_root}" 'duplicate GenericAISaaSStyling rule'

for forbidden_field in \
  DashboardLikePanorama \
  ThemeCardWall \
  CardWallAsPrimaryReading \
  PermanentRightSideRelationshipPanel \
  RelationshipOnlyGraphPage \
  EverythingInsideCards \
  PanelInsidePanelInsidePanel \
  GlobalGovernanceDashboardInReadingMode \
  DenseAlwaysVisibleControls \
  GlobalFreeKnowledgeGraph \
  InfiniteCanvas \
  HugeRoundedCards \
  PurpleGradient \
  Glassmorphism \
  FloatingPillsEverywhere \
  OversizedHeroTitles \
  ExcessiveEmptyMarketingSpace \
  EmojiIconSystem \
  RainbowAIGlow \
  GradientBorders \
  EverySectionInACard \
  GenericAISaaSStyling; do
  missing_forbidden_root="${test_tmp_root}/missing-${forbidden_field}"
  make_fixture "${missing_forbidden_root}"
  sed -i.bak "/^${forbidden_field} = FORBIDDEN$/d" \
    "${missing_forbidden_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
  rm "${missing_forbidden_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md.bak"
  sync_manifest_document_fingerprint "${missing_forbidden_root}"
  expect_failure "${missing_forbidden_root}" "missing forbidden rule ${forbidden_field}"

  conflicting_forbidden_root="${test_tmp_root}/conflicting-${forbidden_field}"
  make_fixture "${conflicting_forbidden_root}"
  printf '%s = ALLOWED\n' "${forbidden_field}" >> \
    "${conflicting_forbidden_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
  sync_manifest_document_fingerprint "${conflicting_forbidden_root}"
  expect_failure "${conflicting_forbidden_root}" "conflicting forbidden rule ${forbidden_field}"
done

dashboard_authority_root="${test_tmp_root}/dashboard-authority"
make_fixture "${dashboard_authority_root}"
sed -i.bak 's/^DashboardLayoutAuthority = NO$/DashboardLayoutAuthority = YES/' \
  "${dashboard_authority_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
rm "${dashboard_authority_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md.bak"
sync_manifest_document_fingerprint "${dashboard_authority_root}"
expect_failure "${dashboard_authority_root}" 'DashboardLayoutAuthority=YES'

for authority in DashboardLayoutAuthority InteractionAuthority InformationArchitectureAuthority; do
  conflicting_formal_authority_root="${test_tmp_root}/formal-conflicting-${authority}"
  make_fixture "${conflicting_formal_authority_root}"
  printf '%s = YES\n' "${authority}" >> \
    "${conflicting_formal_authority_root}/docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md"
  sync_manifest_document_fingerprint "${conflicting_formal_authority_root}"
  expect_failure "${conflicting_formal_authority_root}" "formal document appends conflicting ${authority}=YES"
done

for authority in \
  VisualStyleReferenceDashboardLayoutAuthority \
  VisualStyleReferenceInteractionAuthority \
  VisualStyleReferencePageArchitectureAuthority; do
  conflicting_agents_authority_root="${test_tmp_root}/agents-conflicting-${authority}"
  make_fixture "${conflicting_agents_authority_root}"
  printf '%s = YES\n' "${authority}" >> "${conflicting_agents_authority_root}/AGENTS.md"
  expect_failure "${conflicting_agents_authority_root}" "AGENTS appends conflicting ${authority}=YES"
done

missing_gap_root="${test_tmp_root}/missing-doc-gap"
make_fixture "${missing_gap_root}"
sed -i.bak '/DOC-GAP-HF-001/d' "${missing_gap_root}/docs/engineering/cognitura-design-index.md"
rm "${missing_gap_root}/docs/engineering/cognitura-design-index.md.bak"
expect_failure "${missing_gap_root}" 'missing DOC-GAP-HF-001'

missing_demotion_root="${test_tmp_root}/missing-historical-token-demotion"
make_fixture "${missing_demotion_root}"
sed -i.bak '/^LegacyPrototypeTokenRole=HISTORICAL_EVIDENCE_RENDERING_ONLY$/d' \
  "${missing_demotion_root}/docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md"
rm "${missing_demotion_root}/docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md.bak"
expect_failure "${missing_demotion_root}" 'missing historical-token demotion'

missing_manifest_root="${test_tmp_root}/missing-manifest"
make_fixture "${missing_manifest_root}"
rm "${missing_manifest_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml"
expect_failure "${missing_manifest_root}" 'missing manifest'

wrong_doc_size_root="${test_tmp_root}/wrong-doc-size"
make_fixture "${wrong_doc_size_root}"
sed -i.bak "s/^  sizeBytes: ${canonical_document_size}$/  sizeBytes: 1/" \
  "${wrong_doc_size_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml"
rm "${wrong_doc_size_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml.bak"
expect_failure "${wrong_doc_size_root}" 'wrong manifest document size'

wrong_doc_hash_root="${test_tmp_root}/wrong-doc-hash"
make_fixture "${wrong_doc_hash_root}"
sed -i.bak "s/^  sha256: ${canonical_document_hash}$/  sha256: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/" \
  "${wrong_doc_hash_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml"
rm "${wrong_doc_hash_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml.bak"
expect_failure "${wrong_doc_hash_root}" 'wrong manifest document hash'

zero_size_root="${test_tmp_root}/zero-size"
make_fixture "${zero_size_root}"
sed -i.bak "s/^  sizeBytes: ${canonical_document_size}$/  sizeBytes: 0/" \
  "${zero_size_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml"
rm "${zero_size_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml.bak"
expect_failure "${zero_size_root}" 'zero manifest size'

nondecimal_size_root="${test_tmp_root}/nondecimal-size"
make_fixture "${nondecimal_size_root}"
sed -i.bak "s/^  sizeBytes: ${canonical_document_size}$/  sizeBytes: eleven/" \
  "${nondecimal_size_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml"
rm "${nondecimal_size_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml.bak"
expect_failure "${nondecimal_size_root}" 'nondecimal manifest size'

short_hash_root="${test_tmp_root}/short-hash"
make_fixture "${short_hash_root}"
sed -i.bak "s/^  sha256: ${canonical_document_hash}$/  sha256: abcdef/" \
  "${short_hash_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml"
rm "${short_hash_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml.bak"
expect_failure "${short_hash_root}" 'non-64-character manifest hash'

wrong_activation_root="${test_tmp_root}/wrong-activation-gate"
make_fixture "${wrong_activation_root}"
sed -i.bak 's/^activationGate: VSB-G0 GOVERNANCE_AND_REFERENCE$/activationGate: VSB-G1 SEMANTIC_TOKENS/' \
  "${wrong_activation_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml"
rm "${wrong_activation_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml.bak"
expect_failure "${wrong_activation_root}" 'wrong activation gate'

unquoted_version_root="${test_tmp_root}/unquoted-document-version"
make_fixture "${unquoted_version_root}"
sed -i.bak 's/^  version: "1.0"$/  version: 1.0/' \
  "${unquoted_version_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml"
rm "${unquoted_version_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml.bak"
expect_failure "${unquoted_version_root}" 'unquoted YAML document version number'

wrong_version_type_root="${test_tmp_root}/wrong-document-version-type"
make_fixture "${wrong_version_type_root}"
sed -i.bak 's/^  version: "1.0"$/  version: true/' \
  "${wrong_version_type_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml"
rm "${wrong_version_type_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml.bak"
expect_failure "${wrong_version_type_root}" 'wrong YAML document version type'

duplicate_manifest_root="${test_tmp_root}/duplicate-manifest-key"
make_fixture "${duplicate_manifest_root}"
sed -i.bak '1a\
canonicalProjectName: Cognitura' \
  "${duplicate_manifest_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml"
rm "${duplicate_manifest_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml.bak"
expect_failure "${duplicate_manifest_root}" 'duplicate manifest key'

unknown_manifest_root="${test_tmp_root}/unknown-manifest-key"
make_fixture "${unknown_manifest_root}"
sed -i.bak '1a\
unknownAuthority: YES' \
  "${unknown_manifest_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml"
rm "${unknown_manifest_root}/docs/engineering/cognitura-visual-style-baseline-manifest.yaml.bak"
expect_failure "${unknown_manifest_root}" 'unknown manifest top-level key'

for authority in \
  VisualStyleReferencePageArchitectureAuthority \
  VisualStyleReferenceInteractionAuthority \
  VisualStyleReferenceDashboardLayoutAuthority; do
  agents_authority_root="${test_tmp_root}/agents-${authority}"
  make_fixture "${agents_authority_root}"
  sed -i.bak "s/${authority} = NO/${authority} = YES/" "${agents_authority_root}/AGENTS.md"
  rm "${agents_authority_root}/AGENTS.md.bak"
  expect_failure "${agents_authority_root}" "AGENTS grants ${authority}"
done

printf '%s\n' \
  'VisualStyleReferenceContractTests = PASS' \
  'LiteralNegativeTests = PASS' \
  'ExpectedReferencePixelSize = 1280x853' \
  'ExpectedReferenceSHA256 = a8446ea987f6a1710c3845f837e2776190997b77f81584cf7b667cbfebe2f95f'
