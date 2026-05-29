#!/usr/bin/env bash
# Game Designer persona.
# Usage: ./scripts/council/designer.sh "question or task" [files...]
#   COUNCIL_RUNNER must be set to your LLM harness command.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_shared.sh"

run_persona "designer" "$@"
