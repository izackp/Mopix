#!/usr/bin/env bash
set -euo pipefail

output_dir="${1:-./.artifacts/tennis-score-screen}"

swift run Tennis \
  --score-screen \
  --ticks 10000 \
  --screenshots 10000 \
  --output-dir "$output_dir"

echo "Score-screen screenshot: $output_dir/frame_10000.png"
