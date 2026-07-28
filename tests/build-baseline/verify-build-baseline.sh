#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
verifier="${repo_root}/scripts/verify-build-baseline"
test_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cognitura-build-baseline.XXXXXX")"

cleanup() {
  rm -rf "${test_tmp_root}"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

copy_fixture() {
  local fixture_name="$1"
  local fixture_root="${test_tmp_root}/${fixture_name}"

  mkdir -p "${fixture_root}/docs/engineering" "${fixture_root}/server" "${fixture_root}/web"
  cp "${repo_root}/pom.xml" "${fixture_root}/pom.xml"
  cp "${repo_root}/docs/engineering/cognitura-technology-baseline.md" \
    "${fixture_root}/docs/engineering/cognitura-technology-baseline.md"
  cp "${repo_root}/docs/engineering/cognitura-module-boundaries.md" \
    "${fixture_root}/docs/engineering/cognitura-module-boundaries.md"
  cp -R "${repo_root}/server/." "${fixture_root}/server/"
  cp -R "${repo_root}/web/." "${fixture_root}/web/"
  printf '%s\n' "${fixture_root}"
}

expect_failure() {
  local fixture_root="$1"
  local expected_message="$2"
  local output

  if output="$("${verifier}" --repo-root "${fixture_root}" --structure-only 2>&1)"; then
    fail "invalid fixture unexpectedly passed: ${fixture_root}"
  fi

  if [[ "${output}" != *"${expected_message}"* ]]; then
    fail "expected error '${expected_message}', got: ${output}"
  fi
}

[[ -x "${verifier}" ]] || fail "build baseline verifier is missing or not executable"

if ! valid_output="$("${verifier}" 2>&1)"; then
  fail "canonical build baseline was rejected: ${valid_output}"
fi

for expected_line in \
  "BuildBaselineValidation = PASS" \
  "ServerModuleCount = 5" \
  "WebModuleCount = 9" \
  "ForbiddenDependencyCount = 0" \
  "ServerBuild = PASS" \
  "WebBuild = PASS" \
  "W0-G2A BuildBaseline = PASS"; do
  if [[ "${valid_output}" != *"${expected_line}"* ]]; then
    fail "canonical validation did not report '${expected_line}'"
  fi
done

missing_server_module="$(copy_fixture "missing-server-module")"
rm "${missing_server_module}/server/src/main/java/io/cognitura/source/package-info.java"
expect_failure "${missing_server_module}" "MISSING_SERVER_MODULE: source"

missing_web_module="$(copy_fixture "missing-web-module")"
rm -R "${missing_web_module}/web/src/modules/revision-history"
expect_failure "${missing_web_module}" "MISSING_WEB_MODULE: revision-history"

forbidden_maven_dependency="$(copy_fixture "forbidden-maven-dependency")"
sed -i.bak \
  '/<\/dependencies>/i\
    <dependency>\
      <groupId>org.springframework.boot</groupId>\
      <artifactId>spring-boot-starter-data-jpa</artifactId>\
    </dependency>' \
  "${forbidden_maven_dependency}/server/pom.xml"
rm "${forbidden_maven_dependency}/server/pom.xml.bak"
expect_failure \
  "${forbidden_maven_dependency}" \
  "FORBIDDEN_MAVEN_DEPENDENCY: spring-boot-starter-data-jpa"

forbidden_web_dependency="$(copy_fixture "forbidden-web-dependency")"
sed -i.bak \
  's/"dependencies": {/"dependencies": { "next": "16.0.0",/' \
  "${forbidden_web_dependency}/web/package.json"
rm "${forbidden_web_dependency}/web/package.json.bak"
expect_failure "${forbidden_web_dependency}" "FORBIDDEN_WEB_DEPENDENCY: next"

unpinned_frontend_version="$(copy_fixture "unpinned-frontend-version")"
sed -i.bak \
  's/"react": "19[.]2[.]8"/"react": "^19.2.8"/' \
  "${unpinned_frontend_version}/web/package.json"
rm "${unpinned_frontend_version}/web/package.json.bak"
expect_failure "${unpinned_frontend_version}" "UNPINNED_WEB_VERSION: react"

business_implementation="$(copy_fixture "business-implementation")"
mkdir -p "${business_implementation}/server/src/main/java/io/cognitura/generation/internal"
printf '%s\n' \
  'package io.cognitura.generation.internal;' \
  'final class GenerateKnowledgeUseCase {}' \
  >"${business_implementation}/server/src/main/java/io/cognitura/generation/internal/GenerateKnowledgeUseCase.java"
expect_failure "${business_implementation}" "BUSINESS_IMPLEMENTATION_FORBIDDEN"

extra_deployment_unit="$(copy_fixture "extra-deployment-unit")"
sed -i.bak \
  '/<module>server<\/module>/a\
    <module>worker</module>' \
  "${extra_deployment_unit}/pom.xml"
rm "${extra_deployment_unit}/pom.xml.bak"
expect_failure "${extra_deployment_unit}" "EXTRA_DEPLOYMENT_UNIT: worker"

printf '%s\n' \
  "BuildBaselineContractTests = PASS" \
  "PositiveBaseline = 1" \
  "NegativeCases = 7"
