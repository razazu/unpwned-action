#!/usr/bin/env bash
set -euo pipefail

if [ "${RUNNER_OS:-}" = "Windows" ]; then
  powershell -NoProfile -Command "Start-Process -FilePath node -ArgumentList 'test/targets.ts' -WindowStyle Hidden"
else
  nohup node test/targets.ts > /dev/null 2>&1 &
fi

for _ in $(seq 1 60); do
  if curl -fsS -o /dev/null http://127.0.0.1:4601/ 2> /dev/null; then
    echo "Test targets are up."
    exit 0
  fi
  sleep 0.5
done

echo "::error::Test targets did not start."
exit 1
