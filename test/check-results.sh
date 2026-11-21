#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "::error::$1"
  exit 1
}

expect() {
  if [ "$2" != "$3" ]; then
    fail "$1: expected '$3', got '$2'"
  fi
  echo "ok: $1 = $2"
}

require_number() {
  case "$2" in
    '' | *[!0-9]*) fail "$1 is not a number: '$2'" ;;
  esac
}

version_at_least() {
  local have_major have_minor have_patch want_major want_minor want_patch
  IFS=. read -r have_major have_minor have_patch <<< "$1"
  IFS=. read -r want_major want_minor want_patch <<< "$2"
  if [ "$have_major" -ne "$want_major" ]; then
    [ "$have_major" -gt "$want_major" ]
    return
  fi
  if [ "$have_minor" -ne "$want_minor" ]; then
    [ "$have_minor" -gt "$want_minor" ]
    return
  fi
  [ "$have_patch" -ge "$want_patch" ]
}

require_number "healthy score" "$HEALTHY_SCORE"
require_number "weak score" "$WEAK_SCORE"

expect "healthy blocked flag" "$HEALTHY_BLOCKED" "false"
if [ -z "$HEALTHY_GRADE" ]; then
  fail "healthy target has no grade"
fi
if [ "$HEALTHY_SCORE" -lt 50 ]; then
  fail "healthy target scored $HEALTHY_SCORE, expected 50 or more"
fi
echo "ok: healthy score = $HEALTHY_SCORE (grade $HEALTHY_GRADE)"

expect "blocked outcome" "$BLOCKED_OUTCOME" "failure"
expect "blocked flag" "$BLOCKED_FLAG" "true"
expect "block reason" "$BLOCKED_REASON" "HTTP 403, Cloudflare challenge page"
expect "blocked but allowed outcome" "$ALLOWED_OUTCOME" "success"
expect "blocked but allowed flag" "$ALLOWED_FLAG" "true"

expect "low score outcome" "$WEAK_OUTCOME" "success"
if [ "$WEAK_SCORE" -ge 50 ]; then
  fail "weak target scored $WEAK_SCORE, expected below 50"
fi
echo "ok: weak score = $WEAK_SCORE"
expect "critical finding outcome" "$WEAK_CRITICAL_OUTCOME" "failure"

expect "invalid domain outcome" "$INVALID_OUTCOME" "failure"

CLI_VERSION=$(npx -y unpwned@1 --version | tr -d '\r')
case "$CLI_VERSION" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) fail "could not read the CLI version, got '$CLI_VERSION'" ;;
esac

if version_at_least "$CLI_VERSION" "1.3.0"; then
  expect "unreachable target outcome" "$UNREACHABLE_OUTCOME" "failure"
else
  echo "skipped: an unreachable target ends the scan from CLI 1.3.0 on, this run used $CLI_VERSION"
fi
