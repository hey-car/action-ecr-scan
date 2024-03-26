#!/usr/bin/env bash

function get_formatted_comment_id() {
  _comment_id="${1}"
  echo "<!-- comment-id:${_comment_id} -->"
}

# The `delete_previous_comments` function deletes comments by their ids from pull requests.
function delete_previous_comments() {
  _repo_org="${1}"
  _repo_name="${2}"
  _pr_number="${3}"

  _nextPage="1"
  while [[ "${_nextPage}" != "0" ]]; do
    _comments="$(gh api "/repos/${_repo_org}/${_repo_name}/issues/${_pr_number}/comments?direction=asc&per_page=20&page=${_nextPage}")"
    if [[ "$(echo "${_comments}" | jq '.|length')" == 0 ]]; then
      _nextPage="0"
    else
      _nextPage="$((_nextPage + 1))"
    fi
    while read -r _previous_comment_id; do
      log_out "Deleting previous comment with ID: ${_previous_comment_id}"
      gh api "/repos/${_repo_org}/${_repo_name}/issues/comments/${_previous_comment_id}" -X DELETE >/dev/null
    done < <(echo "${_comments}" | jq ".[] | select(.body|startswith(\"$(get_formatted_comment_id "${_comment_id}")\")) | .id")
  done
}

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
    printf "%s" "$(cat "${_comment_body}")" | gh pr comment "${_pr_number}" -R "${_repo_org}/${_repo_name}" -F -
  else
    printf "%s \n %s" "$(get_formatted_comment_id "${_comment_id}")" "$(cat "${_comment_body}")" | gh pr comment "${_pr_number}" -R "${_repo_org}/${_repo_name}" -F -
  fi
}
