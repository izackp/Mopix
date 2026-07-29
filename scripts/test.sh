#!/usr/bin/env bash
set -uo pipefail

cd "$(dirname "$0")/.."

LOG_DIR="$(pwd)/.build/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test.log"

echo "== swift test =="
if swift test "$@" >"$LOG_FILE" 2>&1; then
    warnings="$(grep -c 'warning:' "$LOG_FILE" || true)"
    echo "test OK (warnings: $warnings). Full log: $LOG_FILE"
else
    status=$?
    echo "test FAILED (exit $status). Full log: $LOG_FILE"
    echo "---"
    grep -E "error:|Fatal error|Test Case '.*' failed|Test Suite '.*' failed|BUILD FAILED" "$LOG_FILE" | tail -100
    echo "---"
    exit "$status"
fi
