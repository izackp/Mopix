#!/usr/bin/env bash
# Run UITest in headless mode and capture screenshots.
# Usage: screenshot-uitest.sh [ticks] [screenshot_tick] [output_dir]
#   ticks          — total ticks to simulate (default: 5)
#   screenshot_tick — which tick to capture (default: same as ticks)
#   output_dir     — where to write PNGs (default: /tmp/uitest-screenshots)

set -e

TICKS="${1:-5}"
SCREENSHOT="${2:-$TICKS}"
OUT_DIR="${3:-/tmp/uitest-screenshots}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
BINARY="$REPO/.build/debug/UITest"

mkdir -p "$OUT_DIR"

"$BINARY" --headless --ticks "$TICKS" --screenshots "$SCREENSHOT" --output-dir "$OUT_DIR"

echo "Screenshots in $OUT_DIR"
md5 "$OUT_DIR"/frame_*.png 2>/dev/null || md5sum "$OUT_DIR"/frame_*.png 2>/dev/null || true
