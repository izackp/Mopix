#!/usr/bin/env bash
# Code Builder (Junior Developer) persona.
# Usage: ./scripts/council/builder.sh "question or task" [files...]
#   COUNCIL_RUNNER must be set to your LLM harness command.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_shared.sh"

run_persona "builder" "$@"
