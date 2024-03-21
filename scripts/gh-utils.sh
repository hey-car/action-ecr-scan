#!/usr/bin/env bash

# The `comment_on_pull_request` function pushes a comment to a pull request.
function comment_on_pull_request() {
  _repo_org="${1}"
  _repo_name="${2}"
  _pr_number="${3}"
  _comment_body="${4}"
  _delete_previous_comments="${5}"
  _comment_id="${6}"

  if [[ "$(check_bool "${_delete_previous_comments}")" ]]; then
    if [[ -z "${_comment_id}" ]]; then
      log_out "No comment id was provided for deleting previous comments. Aborting." "FATAL" 1
    else
      delete_previous_comments "${_repo_org}" "${_repo_name}" "${_pr_number}"
    fi
  fi

  log_out "Commenting on ${_repo_org}/${_repo_name}#${_pr_number}"
  if [[ -z "${_comment_id}" ]]; then
    printf "%s" "${_comment_body}" | gh pr comment "${_pr_number}" -R "${_repo_org}/${_repo_name}" -F -
  else
    printf "%s \n %s" "$(get_formatted_comment_id "${_comment_id}")" "${_comment_body}" | gh pr comment "${_pr_number}" -R "${_repo_org}/${_repo_name}" -F -
  fi
}
