#!/usr/bin/env bash
# Usage: council.sh <persona> <harness> "message"
#   Personas: pm, designer, architect, builder
#   Harnesses: claude, codex, cat

set -euo pipefail

COUNCIL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$COUNCIL_DIR/../.." && pwd)"

if [[ $# -lt 3 ]]; then
    echo "Usage: council.sh <persona> <harness> \"message\"" >&2
    exit 1
fi

PERSONA="$1"
HARNESS="$2"
MESSAGE="$3"

PERSONA_DIR="$COUNCIL_DIR/$PERSONA"
if [[ ! -d "$PERSONA_DIR" ]]; then
    echo "Unknown persona: $PERSONA (expected directory $PERSONA_DIR)" >&2
    exit 1
fi

CODEX_COMPACT_THRESHOLD=140000  # tokens (~560k chars in text fields)

load_file() {
    local path="$1" label="${2:-$1}"
    [[ -f "$path" ]] || return 0
    printf '\n--- %s ---\n' "$label"
    cat "$path"
    printf '\n'
}

build_system() {
    load_file "$PERSONA_DIR/persona.md" "PERSONA"
    load_file "$PERSONA_DIR/skill.md"   "SKILL"
    load_file "$PERSONA_DIR/memory.md"  "MEMORY"
}

build_user_message() {
    local path_lines=()

    local feedback
    while IFS= read -r feedback; do
        [[ -n "$feedback" ]] && path_lines+=("$feedback")
    done < <(find "$REPO_ROOT/docs/specs" -name "*-feedback.md" 2>/dev/null || true)

    if [[ ${#path_lines[@]} -gt 0 ]]; then
        echo "Pending feedback files:"
        for p in "${path_lines[@]}"; do
            echo "  $p"
        done
        echo ""
    fi

    echo "$MESSAGE"
}

# Estimate tokens from a codex session JSONL by summing text field chars / 4
_codex_estimate_tokens() {
    local session_file="$1"
    [[ -f "$session_file" ]] || { echo 0; return; }
    python3 - "$session_file" <<'PYEOF'
import json, sys

def count_chars(obj):
    if isinstance(obj, str):
        return len(obj)
    if isinstance(obj, list):
        return sum(count_chars(i) for i in obj)
    if isinstance(obj, dict):
        return sum(count_chars(v) for v in obj.values())
    return 0

total = 0
with open(sys.argv[1]) as f:
    for line in f:
        try:
            total += count_chars(json.loads(line).get('payload', {}))
        except Exception:
            pass
print(total // 4)
PYEOF
}

# Find session JSONL file by UUID
_codex_session_file() {
    find ~/.codex/sessions -name "*${1}*.jsonl" 2>/dev/null | head -1
}

# Ask codex to write memory.md then reset session
_codex_compact() {
    local session_id="$1" token_est="$2" resp_tmp
    echo "[council] Context ~${token_est} tokens — compacting into memory.md" >&2

    resp_tmp="$(mktemp)"
    printf '%s' "The session context is large. Write a comprehensive summary of everything discussed, decided, and built so far into: ${PERSONA_DIR}/memory.md — include key decisions, code changes, problems solved, and current state. This file is loaded as context in future sessions." | \
        codex exec resume "$session_id" - \
            -C "$REPO_ROOT" \
            -s workspace-write \
            -o "$resp_tmp" 2>/dev/null || true
    rm -f "$resp_tmp"

    rm -f "$PERSONA_DIR/session_id"
    echo "[council] Session reset. memory.md updated; will be loaded next run." >&2
}

run_codex() {
    local system user_msg response resp_tmp marker_tmp session_id session_file token_est
    system="$(build_system)"
    user_msg="$(build_user_message)"
    printf '%s\n' "$user_msg" > "$PERSONA_DIR/last_prompt.txt"
    resp_tmp="$(mktemp)"

    if [[ -f "$PERSONA_DIR/session_id" ]]; then
        session_id="$(cat "$PERSONA_DIR/session_id")"
        # Resume: only send new user message (system context already in session)
        printf '%s' "$user_msg" | \
            codex exec resume "$session_id" - \
                -C "$REPO_ROOT" \
                -s workspace-write \
                -o "$resp_tmp"
    else
        # New session: bundle system + user as initial prompt; capture session UUID
        marker_tmp="$(mktemp)"
        printf '%s\n\n%s' "$system" "$user_msg" | \
            codex exec - \
                -C "$REPO_ROOT" \
                -s workspace-write \
                -o "$resp_tmp"

        session_file="$(find ~/.codex/sessions -name "*.jsonl" -newer "$marker_tmp" 2>/dev/null | head -1)"
        rm -f "$marker_tmp"

        if [[ -n "$session_file" ]]; then
            session_id="$(basename "$session_file" .jsonl | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}')"
            [[ -n "$session_id" ]] && printf '%s' "$session_id" > "$PERSONA_DIR/session_id"
        fi
    fi

    response="$(cat "$resp_tmp")"
    rm -f "$resp_tmp"

    # Check context size and compact if over threshold
    if [[ -f "$PERSONA_DIR/session_id" ]]; then
        session_id="$(cat "$PERSONA_DIR/session_id")"
        session_file="$(_codex_session_file "$session_id")"
        if [[ -n "$session_file" ]]; then
            token_est="$(_codex_estimate_tokens "$session_file")"
            if [[ $token_est -gt $CODEX_COMPACT_THRESHOLD ]]; then
                _codex_compact "$session_id" "$token_est"
            fi
        fi
    fi

    printf '%s\n' "$response" > "$PERSONA_DIR/last_response.txt"
    printf '%s\n' "$response"
    echo "Output saved to: $PERSONA_DIR/last_response.txt"
}

run_harness() {
    local system user_msg response
    system="$(build_system)"
    user_msg="$(build_user_message)"
    printf '%s\n' "$user_msg" > "$PERSONA_DIR/last_prompt.txt"

    case "$HARNESS" in
        claude)
            response="$(claude --system "$system" -p "$user_msg" --print)"
            printf '%s\n' "$response" > "$PERSONA_DIR/last_response.txt"
            printf '%s\n' "$response"
            echo "Output saved to: $PERSONA_DIR/last_response.txt"
            ;;
        codex)
            run_codex
            ;;
        cat)
            response="$(printf '%s\n\n%s\n' "$system" "$user_msg")"
            printf '%s\n' "$response" > "$PERSONA_DIR/last_response.txt"
            printf '%s\n' "$response"
            echo "Output saved to: $PERSONA_DIR/last_response.txt"
            ;;
        *)
            echo "Unknown harness: $HARNESS" >&2
            echo "Supported: claude, codex, cat" >&2
            exit 1
            ;;
    esac
}

run_harness
