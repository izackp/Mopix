#!/usr/bin/env bash
# Code Architect (Senior Engineer) persona.
# Usage: ./scripts/council/architect.sh "question or task" [files...]
#   COUNCIL_RUNNER must be set to your LLM harness command.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_shared.sh"

run_persona "architect" "$@"
