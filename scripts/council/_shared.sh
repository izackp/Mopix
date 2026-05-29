#!/usr/bin/env bash
# Shared helpers for council persona scripts.
# Each persona script sources this file then calls: run_persona "$MEMBER" "$@"

set -euo pipefail

COUNCIL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$COUNCIL_DIR/../.." && pwd)"

# Load a file as context block. Silently skips missing files.
load_file() {
    local path="$1"
    local label="${2:-$path}"
    if [[ -f "$path" ]]; then
        printf '\n--- %s ---\n' "$label"
        cat "$path"
        printf '\n'
    fi
}

# Scan docs/specs/ for feedback files and return their paths.
find_feedback_files() {
    find "$REPO_ROOT/docs/specs" -name "*-feedback.md" 2>/dev/null || true
}

# Build and emit the full prompt for a persona.
# Usage: build_prompt <member> [extra_files...] <<< "user message"
# Or:    build_prompt <member> [extra_files...] -- "user message"
build_prompt() {
    local member="$1"; shift
    local member_dir="$COUNCIL_DIR/$member"
    local user_message=""
    local extra_files=()

    # Parse args: collect files until -- or end; last non-flag arg is message
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --)
                shift
                user_message="$*"
                break
                ;;
            *)
                if [[ -f "$1" ]]; then
                    extra_files+=("$1")
                else
                    user_message="$1"
                fi
                shift
                ;;
        esac
    done

    # If no message yet, read from stdin
    if [[ -z "$user_message" ]] && ! [[ -t 0 ]]; then
        user_message="$(cat)"
    fi

    # === SYSTEM PROMPT ===
    echo "=== SYSTEM ==="
    echo ""
    load_file "$member_dir/persona.md" "PERSONA"
    load_file "$member_dir/skill.md"   "SKILL"
    load_file "$member_dir/memory.md"  "MEMORY"

    # Paths persona needs to manage its own memory
    echo ""
    echo "--- MEMORY FILE PATH ---"
    echo "$member_dir/memory.md"
    echo ""

    # Builder: always load blockers
    if [[ "$member" == "builder" ]]; then
        load_file "$member_dir/blockers.md" "BLOCKERS"
        echo "--- BLOCKERS FILE PATH ---"
        echo "$member_dir/blockers.md"
        echo ""
    fi

    # Architect: always load builder blockers too
    if [[ "$member" == "architect" ]]; then
        load_file "$COUNCIL_DIR/builder/blockers.md" "BUILDER BLOCKERS"
    fi

    # Load any pending feedback files (all members see them)
    local feedback
    while IFS= read -r feedback; do
        [[ -n "$feedback" ]] && load_file "$feedback" "FEEDBACK: $(basename "$feedback")"
    done < <(find_feedback_files)

    echo ""
    echo "=== USER ==="
    echo ""

    # Load explicitly passed files as context
    for f in "${extra_files[@]}"; do
        load_file "$f" "CONTEXT: $(basename "$f")"
    done

    # Emit the user message
    echo "$user_message"
}

# Dispatch to runner. Requires COUNCIL_RUNNER to be set.
run_persona() {
    local member="$1"; shift

    if [[ -z "${COUNCIL_RUNNER:-}" ]]; then
        echo "ERROR: COUNCIL_RUNNER is not set." >&2
        echo "Set it to your LLM harness command, e.g.:" >&2
        echo "  export COUNCIL_RUNNER=\"claude\"" >&2
        echo "  export COUNCIL_RUNNER=\"codex\"" >&2
        exit 1
    fi

    build_prompt "$member" "$@" | $COUNCIL_RUNNER
}
