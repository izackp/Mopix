#!/usr/bin/env bash
set -uo pipefail

cd "$(dirname "$0")/.."

TARGET="${1:?Usage: build.sh <target> [-- swift-args...]}"
shift
[[ "${1:-}" == "--" ]] && shift

LOG_DIR="$(pwd)/.build/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/build-$TARGET.log"

echo "== swift build --product $TARGET =="
if swift build --product "$TARGET" "$@" >"$LOG_FILE" 2>&1; then
    warnings="$(grep -c 'warning:' "$LOG_FILE" || true)"
    echo "build OK (warnings: $warnings). Full log: $LOG_FILE"
else
    status=$?
    echo "build FAILED (exit $status). Full log: $LOG_FILE"
    echo "---"
    grep -E 'error:|BUILD FAILED' "$LOG_FILE" | tail -100
    echo "---"
    exit "$status"
fi
