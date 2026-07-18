#!/usr/bin/env bash
# Usage: council.sh <persona> <harness> "message"
#   Personas: pm, designer, architect, builder
#   Harnesses: claude, codex, cat

set -euo pipefail

COUNCIL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$COUNCIL_DIR/../.." && pwd)"
ENV_FILE="$COUNCIL_DIR/.env"

if [[ -f "$ENV_FILE" ]]; then
    # Local harness config, e.g. CLI settings paths.
    source "$ENV_FILE"
fi

if [[ $# -lt 3 ]]; then
    echo "Usage: council.sh <persona> <harness> \"message\"" >&2
    exit 1
fi

PERSONA="$1"
HARNESS="$2"
MESSAGE="$3"

PERSONA_DIR="$COUNCIL_DIR/$PERSONA"
READONLY_DIR="$PERSONA_DIR/readonly"
if [[ ! -d "$PERSONA_DIR" ]]; then
    echo "Unknown persona: $PERSONA (expected directory $PERSONA_DIR)" >&2
    exit 1
fi

# Codex internal truncation_policy: compact when context exceeds this token limit
CODEX_TRUNCATION_LIMIT=140000

load_file() {
    local path="$1" label="${2:-$1}"
    [[ -f "$path" ]] || return 0
    printf '\n--- %s ---\n' "$label"
    cat "$path"
    printf '\n'
}

require_file() {
    local path="$1"
    [[ -f "$path" ]] || {
        echo "Missing required file: $path" >&2
        exit 1
    }
}

build_system() {
    require_file "$COUNCIL_DIR/agent.md"
    require_file "$READONLY_DIR/persona.md"
    require_file "$READONLY_DIR/skill.md"
    require_file "$PERSONA_DIR/memory-short.md"
    require_file "$PERSONA_DIR/memory-long.md"
    require_file "$PERSONA_DIR/memory-new.md"

    load_file "$COUNCIL_DIR/agent.md"        "AGENT"
    load_file "$READONLY_DIR/persona.md"     "PERSONA"
    load_file "$READONLY_DIR/skill.md"       "SKILL"
    load_file "$PERSONA_DIR/memory-short.md" "MEMORY-SHORT"

    printf '\n--- WORKSPACE FILES ---\n'
    printf 'Immutable worker files live in: %s\n' "$READONLY_DIR"
    printf 'Editable long-term memory: %s\n' "$PERSONA_DIR/memory-long.md"
    printf 'Editable scratch memory: %s\n' "$PERSONA_DIR/memory-new.md"
    if [[ -f "$PERSONA_DIR/blockers.md" ]]; then
        printf 'Worker blocker file: %s\n' "$PERSONA_DIR/blockers.md"
    fi
    printf '\n'
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

_save_response() {
    local response="$1"
    printf '%s\n' "$response" > "$PERSONA_DIR/last_response.txt"
    printf '%s\n' "$response"
    echo "Output saved to: $PERSONA_DIR/last_response.txt"
}

strip_prompt_echo() {
    local response="$1" system="$2" user_msg="$3"
    local prompt_bundle

    prompt_bundle="$(printf '%s\n\n%s' "$system" "$user_msg")"

    if [[ "$response" == "$prompt_bundle"* ]]; then
        response="${response#"$prompt_bundle"}"
    elif [[ "$response" == "$system"* ]]; then
        response="${response#"$system"}"
    fi

    while [[ "$response" == $'\n'* ]]; do
        response="${response#$'\n'}"
    done

    printf '%s' "$response"
}

_run_claude() {
    local system="$1" user_msg="$2" response
    local -a claude_env=()

    if [[ -n "${CLAUDE_CONFIG_DIR:-}" ]]; then
        claude_env=(env "CLAUDE_CONFIG_DIR=$CLAUDE_CONFIG_DIR")
    fi

    response="$("${claude_env[@]}" claude --system-prompt "$system" -p "$user_msg")"
    _save_response "$response"
}

_run_cat() {
    local system="$1" user_msg="$2"
    _save_response "$(strip_prompt_echo "$(printf '%s\n\n%s\n' "$system" "$user_msg")" "$system" "$user_msg")"
}

_run_codex() {
    local system="$1" user_msg="$2" response resp_tmp marker_tmp session_id session_file
    resp_tmp="$(mktemp)"

    if [[ -f "$PERSONA_DIR/session_id" ]]; then
        session_id="$(cat "$PERSONA_DIR/session_id")"
        # Resume: system context already in session; only send new user message
        printf '%s' "$user_msg" | \
            codex exec resume "$session_id" - \
                -C "$REPO_ROOT" \
                -s workspace-write \
                -c "truncation_policy={mode=\"tokens\",limit=$CODEX_TRUNCATION_LIMIT}" \
                -o "$resp_tmp"
    else
        # New session: bundle system + user as initial prompt
        marker_tmp="$(mktemp)"
        printf '%s\n\n%s' "$system" "$user_msg" | \
            codex exec - \
                -C "$REPO_ROOT" \
                -s workspace-write \
                -c "truncation_policy={mode=\"tokens\",limit=$CODEX_TRUNCATION_LIMIT}" \
                -o "$resp_tmp"

        # Find session file created after marker, extract UUID from filename
        session_file="$(find ~/.codex/sessions -name "*.jsonl" -newer "$marker_tmp" 2>/dev/null | head -1)"
        rm -f "$marker_tmp"

        if [[ -n "$session_file" ]]; then
            session_id="$(basename "$session_file" .jsonl | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' || true)"
            if [[ -n "${session_id:-}" ]]; then
                printf '%s' "$session_id" > "$PERSONA_DIR/session_id"
            else
                echo "[council] Warning: could not extract session UUID from: $session_file" >&2
            fi
        else
            echo "[council] Warning: no new session file found after run" >&2
        fi
    fi

    response="$(cat "$resp_tmp")"
    rm -f "$resp_tmp"
    response="$(strip_prompt_echo "$response" "$system" "$user_msg")"
    _save_response "$response"
}

run_harness() {
    local system user_msg
    system="$(build_system)"
    user_msg="$(build_user_message)"
    printf '%s\n' "$user_msg" > "$PERSONA_DIR/last_prompt.txt"

    case "$HARNESS" in
        claude) _run_claude "$system" "$user_msg" ;;
        codex)  _run_codex  "$system" "$user_msg" ;;
        cat)    _run_cat    "$system" "$user_msg" ;;
        *)
            echo "Unknown harness: $HARNESS" >&2
            echo "Supported: claude, codex, cat" >&2
            exit 1
            ;;
    esac
}

run_harness
