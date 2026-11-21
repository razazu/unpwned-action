#!/usr/bin/env bash
set -euo pipefail

: "${GH_TOKEN:?}" "${REPO:?}" "${PR_NUMBER:?}" "${STARTED_AT:?}"

HEALTHY_TARGET="http://127.0.0.1:4601"
BLOCKED_TARGET="http://127.0.0.1:4602"

comments='[]'

fail() {
  echo "::error::$1"
  exit 1
}

list_comments() {
  gh api "repos/$REPO/issues/$PR_NUMBER/comments?per_page=100&since=$STARTED_AT" \
    --jq '[.[] | select(.user.login == "github-actions[bot]" and (.body | contains("UNPWNED Security Scan")))]'
}

remove_comments() {
  local id
  for id in $(jq -r '.[].id' <<< "$comments"); do
    gh api --method DELETE "repos/$REPO/issues/comments/$id" > /dev/null ||
      echo "::warning::Could not delete test comment $id"
  done
}

body_for() {
  jq -r --arg line "**Target:** \`$1\`" \
    '[.[] | select(.body | contains($line))] | if length == 1 then .[0].body else "" end' <<< "$comments"
}

expect_text() {
  if ! grep -Fq -- "$3" <<< "$2"; then
    fail "$1: missing '$3'"
  fi
  echo "ok: $1 has '$3'"
}

expect_pattern() {
  if ! grep -Eq -- "$3" <<< "$2"; then
    fail "$1: nothing matches $3"
  fi
  echo "ok: $1 matches $3"
}

trap remove_comments EXIT

for _ in 1 2 3 4 5; do
  comments=$(list_comments)
  if [ "$(jq 'length' <<< "$comments")" -ge 2 ]; then
    break
  fi
  sleep 2
done

jq -r '.[] | "----- comment \(.id) -----\n\(.body)\n"' <<< "$comments"

count=$(jq 'length' <<< "$comments")
if [ "$count" -ne 2 ]; then
  fail "expected 2 scan comments on the pull request, found $count"
fi

healthy=$(body_for "$HEALTHY_TARGET")
blocked=$(body_for "$BLOCKED_TARGET")

if [ -z "$healthy" ]; then
  fail "no comment for the healthy target"
fi
if [ -z "$blocked" ]; then
  fail "no comment for the blocked target"
fi

expect_pattern "healthy comment" "$healthy" '\*\*Score:\*\* [0-9]+ / 100 \(Grade [A-F]\+?\)'
expect_text "healthy comment" "$healthy" '| Severity | Count |'
if grep -Fq 'Partial score' <<< "$healthy"; then
  fail "healthy comment: reports a partial score"
fi

expect_pattern "blocked comment" "$blocked" '\*\*Partial score:\*\* [0-9]+ / 100 \([0-9]+ of [0-9]+ checks\)'
expect_text "blocked comment" "$blocked" '**The target blocked this scan** (HTTP 403, Cloudflare challenge page).'
expect_text "blocked comment" "$blocked" 'Not checked: Headers, Cookies, CORS, Sensitive Files, Tech Stack.'
expect_text "blocked comment" "$blocked" '| Severity | Count |'
