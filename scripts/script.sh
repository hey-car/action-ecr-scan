#!/usr/bin/env bash

. "$(dirname "$0")/utils.sh"
. "$(dirname "$0")/gh-utils.sh"

sleep 15

function get_scans() {
  _scan_repo_name="${1}"
  _scan_count="${2:-0}"

  if [[ $_scan_count -ge 3 ]]; then
    log_fatal "Scan took toolong. Aborting."
  fi

  _scan_results_tmp="$(aws --region "${AWS_REGION}" ecr describe-image-scan-findings --repository-name "${_scan_repo_name}" --image-id="imageTag=${ECR_REPO_TAG}")"
  if [[ "$(echo "${_scan_results_tmp}" | jq '.imageScanStatus.status')" == "IN_PROGRESS" ]]; then
    sleep 15
    get_scans "${_scan_repo_name}" $((_scan_count + 1))
  else
    echo "${_scan_results_tmp}" | jq '.imageScanFindings.findingSeverityCounts // {}'
  fi
}

REPO_ORG=${GITHUB_REPOSITORY_OWNER}
REPO_NAME=$(echo "${GITHUB_REPOSITORY}" | cut -d "/" -f2)

check_env_var "AWS_ACCOUNT_ID"
check_env_var "AWS_REGION"
check_env_var "ECR_REPO_NAME"
check_env_var "ECR_REPO_TAG"
check_env_var "PR_NUMBER"
check_env_var "USE_ALPHA_REGISTRY"

if [[ "$(check_bool "${USE_ALPHA_REGISTRY}")" ]]; then
  _scan_repo_name="alpha-image/${ECR_REPO_NAME}"
else
  _scan_repo_name="image/${ECR_REPO_NAME}"
fi
_scan_repo_link="https://eu-central-1.console.aws.amazon.com/ecr/repositories/private/${AWS_ACCOUNT_ID}/${_scan_repo_name}"

log_info "Fetching scan results from ECR"
log_debug "repo=\"${_scan_repo_name}\" | imageTag=\"${ECR_REPO_TAG}\""

_scan_results="$(get_scans "${_scan_repo_name}")"

_scan_results_comment="./.tmp.scan-results.txt"
if [[ "${_scan_results}" == "{}" ]]; then
  log_info "Did not find any vulnerabilities on the ECR repo."
  echo ":tada: Did not find any vulnerabilities in [${_scan_repo_name}](${_scan_repo_link}). Good job :+1:" >>"${_scan_results_comment}"
else
  log_info "Found vulnerabilities on ECR."
  {
    echo ":warning: Found the following number of vulnerabilities on [${_scan_repo_name}](${_scan_repo_link}):"
    echo "- type \`CRITICAL\`: **$(echo "${_scan_results}" | jq '.CRITICAL // 0')**"
    echo "- type \`HIGH\`: **$(echo "${_scan_results}" | jq '.HIGH // 0')**"
    echo "- type \`MEDIUM\`: **$(echo "${_scan_results}" | jq '.MEDIUM // 0')**"
    echo "- type \`LOW\`: **$(echo "${_scan_results}" | jq '.LOW // 0')**"
    echo "- type \`UNDEFINED\`: **$(echo "${_scan_results}" | jq '.UNDEFINED // 0')**"
    echo "- type \`INFORMATIONAL\`: **$(echo "${_scan_results}" | jq '.INFORMATIONAL // 0')**"
  } >>"${_scan_results_comment}"
fi

comment_on_pull_request "${REPO_ORG}" \
  "${REPO_NAME}" \
  "${PR_NUMBER}" \
  "${_scan_results_comment}" \
  "true" \
  "scan-results:${_scan_repo_name}"

rm "${_scan_results_comment}"

if [[ "$(echo "${_scan_results}" | jq '.CRITICAL // 0')" != 0 ]]; then
  log_fatal "Please fix critical vulnerabilities"
fi
