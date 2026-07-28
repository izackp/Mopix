#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
scene_file="$script_dir/tennis-headless-score-screen.json"
output_dir="${1:-$repo_root/.artifacts/tennis-headless-score-screen}"
log_file="$output_dir/run.log"

mkdir -p "$output_dir"

inputs='KEYDOWN J; WAIT 2; KEYUP J; WAIT 1; KEYDOWN J; WAIT 1; KEYUP J; WAIT 1; KEYDOWN J; WAIT 1; KEYUP J'
for ((index = 0; index < 100; index += 1)); do
    inputs+="; WAIT 100; KEYDOWN J; WAIT 1; KEYUP J"
done

SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software \
    swift run --package-path "$repo_root" HeadlessRenderer \
    --scene "$scene_file" \
    --inputs "$inputs" \
    --screenshots 10000 \
    --output-dir "$output_dir" 2>&1 | tee "$log_file"

grep -Fq 'Headless capture reached CPU WINS' "$log_file"
test -s "$output_dir/frame_10000.png"
printf 'Verified CPU WINS; capture artifact: %s\n' "$output_dir/frame_10000.png"
