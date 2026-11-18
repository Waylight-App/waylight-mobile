#!/usr/bin/env bash
# Checks the rules of docs/workflow.md that are about the pull request, not
# the code: the branch name, commit trailers and attribution.
#
#   tool/check_pr_hygiene.sh <branch> <base-sha> <head-sha>
#
# The pull request description is read from the PR_BODY environment
# variable. Exits non-zero and prints one error per finding.
set -euo pipefail

branch=${1:?branch}
base=${2:?base sha}
head=${3:?head sha}
failed=0

fail() {
  echo "::error::$1"
  failed=1
}

# Branches of the bots follow their own scheme.
if [[ $branch != dependabot/* && $branch != release-please--* ]]; then
  if ! [[ $branch =~ ^(feat|fix|perf|refactor|docs|test|build|ci|chore|revert)/[0-9]+-[a-z0-9-]+$ ]]; then
    fail "Branch \"$branch\" must be named <type>/<issue>-<slug>, e.g. feat/12-password-sign-in."
  fi
fi

# A trailer is a "Key: value" line in the last paragraph of a message;
# only Signed-off-by is allowed there.
trailer='^[A-Za-z][A-Za-z0-9-]*: '
attribution='(generated (with|by) |/session_[A-Za-z0-9]|co-authored-by:)'

while read -r sha; do
  message=$(git log -1 --format=%B "$sha")
  last_paragraph=$(printf '%s\n' "$message" | awk 'BEGIN{RS=""} {p=$0} END{print p}')
  while IFS= read -r line; do
    if [[ $line =~ $trailer && $line != Signed-off-by:* ]]; then
      fail "Commit ${sha:0:8} has the trailer \"${line%%:*}\"; only Signed-off-by is allowed."
    fi
  done <<<"$last_paragraph"
  if grep -Eiq "$attribution" <<<"$message"; then
    fail "Commit ${sha:0:8} attributes the work to a tool or links a session."
  fi
done < <(git rev-list "$base..$head")

if grep -Eiq "$attribution" <<<"${PR_BODY:-}"; then
  fail "The description attributes the work to a tool or links a session."
fi

exit "$failed"
