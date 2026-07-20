#!/usr/bin/env bash
# Usage: council.sh <persona> <harness> <caller> "message"
#   Personas: pl, designer, architect, builder
#   Harnesses: claude, codex, cat
#   caller: who's invoking this — required, must be one of PL, GD, ARCH, BD, USER.
#     Logged in log.txt. Message is always the last argument.

set -euo pipefail

COUNCIL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$COUNCIL_DIR/../.." && pwd)"
ENV_FILE="$COUNCIL_DIR/.env"

if [[ -f "$ENV_FILE" ]]; then
    # Local harness config, e.g. CLI settings paths.
    source "$ENV_FILE"
fi

if [[ $# -lt 4 ]]; then
    echo "Usage: council.sh <persona> <harness> <caller> \"message\"" >&2
    echo "caller must be one of: PL, GD, ARCH, BD, USER" >&2
    exit 1
fi

PERSONA="$1"
HARNESS="$2"
CALLER="$3"
MESSAGE="$4"

case "$CALLER" in
    PL|GD|ARCH|BD|USER) ;;
    *)
        echo "Unknown caller: $CALLER (must be one of: PL, GD, ARCH, BD, USER)" >&2
        exit 1
        ;;
esac

PERSONA_DIR="$COUNCIL_DIR/$PERSONA"
READONLY_DIR="$PERSONA_DIR/readonly"
if [[ ! -d "$PERSONA_DIR" ]]; then
    echo "Unknown persona: $PERSONA (expected directory $PERSONA_DIR)" >&2
    exit 1
fi

case "$PERSONA" in
    pl)        ACRONYM="PL" ;;
    designer)  ACRONYM="GD" ;;
    architect) ACRONYM="ARCH" ;;
    builder)   ACRONYM="BD" ;;
    *)         ACRONYM="${PERSONA^^}" ;;
esac

LOG_FILE="$COUNCIL_DIR/log.txt"

# Codex internal truncation_policy: compact when context exceeds this token limit
CODEX_TRUNCATION_LIMIT=140000

# Rotate (reset) a persona's session after this many turns. The turn before
# rotation, the persona is told to flush state to its memory files so the
# fresh session can reconstruct context from them.
SESSION_MAX_TURNS="${SESSION_MAX_TURNS:-8}"

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
    echo "$MESSAGE"
}

_save_response() {
    local response="$1"
    printf '%s\n' "$response" > "$PERSONA_DIR/last_response.txt"
    printf '%s: %s\n\n' "$ACRONYM" "$response" >> "$LOG_FILE"
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
    local system="$1" user_msg="$2" response session_id
    local -a claude_env=()

    if [[ -n "${CLAUDE_CONFIG_DIR:-}" ]]; then
        claude_env=(env "CLAUDE_CONFIG_DIR=$CLAUDE_CONFIG_DIR")
    fi

    if [[ -f "$SESSION_FILE" ]]; then
        session_id="$(cat "$SESSION_FILE")"
        # Resume: system context already in session; only send new user message
        response="$(cd "$REPO_ROOT" && "${claude_env[@]}" claude -p \
            --resume "$session_id" \
            --dangerously-skip-permissions \
            "$user_msg")"
    else
        session_id="$(uuidgen | tr '[:upper:]' '[:lower:]')"
        response="$(cd "$REPO_ROOT" && "${claude_env[@]}" claude -p \
            --session-id "$session_id" \
            --system-prompt "$system" \
            --dangerously-skip-permissions \
            "$user_msg")"
        printf '%s' "$session_id" > "$SESSION_FILE"
    fi
    _save_response "$response"
}

_run_cat() {
    local system="$1" user_msg="$2"
    _save_response "$(strip_prompt_echo "$(printf '%s\n\n%s\n' "$system" "$user_msg")" "$system" "$user_msg")"
}

_run_codex() {
    local system="$1" user_msg="$2" response resp_tmp run_log marker_tmp session_id session_file
    resp_tmp="$(mktemp)"
    run_log="$(mktemp)"

    if [[ -f "$SESSION_FILE" ]]; then
        session_id="$(cat "$SESSION_FILE")"
        # Resume: system context already in session; only send new user message
        if ! printf '%s' "$user_msg" | \
            codex exec \
                -C "$REPO_ROOT" \
                -s danger-full-access \
                -c "truncation_policy={mode=\"tokens\",limit=$CODEX_TRUNCATION_LIMIT}" \
                resume \
                -o "$resp_tmp" \
                "$session_id" - >"$run_log" 2>&1; then
            tail -40 "$run_log" >&2
            rm -f "$resp_tmp" "$run_log"
            return 1
        fi
    else
        # New session: bundle system + user as initial prompt
        marker_tmp="$(mktemp)"
        if ! printf '%s\n\n%s' "$system" "$user_msg" | \
            codex exec - \
                -C "$REPO_ROOT" \
                -s danger-full-access \
                -c "truncation_policy={mode=\"tokens\",limit=$CODEX_TRUNCATION_LIMIT}" \
                -o "$resp_tmp" >"$run_log" 2>&1; then
            tail -40 "$run_log" >&2
            rm -f "$resp_tmp" "$run_log" "$marker_tmp"
            return 1
        fi

        # Find session file created after marker, extract UUID from filename
        session_file="$(find ~/.codex/sessions -name "*.jsonl" -newer "$marker_tmp" 2>/dev/null | head -1)"
        rm -f "$marker_tmp"

        if [[ -n "$session_file" ]]; then
            session_id="$(basename "$session_file" .jsonl | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' || true)"
            if [[ -n "${session_id:-}" ]]; then
                printf '%s' "$session_id" > "$SESSION_FILE"
            else
                echo "[council] Warning: could not extract session UUID from: $session_file" >&2
            fi
        else
            echo "[council] Warning: no new session file found after run" >&2
        fi
    fi

    response="$(cat "$resp_tmp")"
    rm -f "$resp_tmp" "$run_log"
    response="$(strip_prompt_echo "$response" "$system" "$user_msg")"
    _save_response "$response"
}

# Lines in memory-short.md (state as of the last call) that also show up in
# memory-new.md now (this call's additions) — the same idea noted twice,
# independently. That's the graduation signal for memory-long.md.
recurring_ideas() {
    local short="$PERSONA_DIR/memory-short.md" new="$PERSONA_DIR/memory-new.md"
    [[ -f "$short" && -f "$new" ]] || return 0
    comm -12 \
        <(grep -v '^[[:space:]]*$' "$short" | sort -u) \
        <(grep -v '^[[:space:]]*$' "$new" | sort -u)
}

run_harness() {
    local system user_msg turns=0
    system="$(build_system)"
    user_msg="$(build_user_message)"

    SESSION_FILE="$PERSONA_DIR/session_id_$HARNESS"
    TURNS_FILE="$PERSONA_DIR/session_turns_$HARNESS"
    [[ -f "$TURNS_FILE" ]] && turns="$(cat "$TURNS_FILE")"

    if [[ -f "$SESSION_FILE" && $((turns + 1)) -ge $SESSION_MAX_TURNS ]]; then
        user_msg+=$'\n\n[council] This session resets after this reply.'
    fi

    local recurring
    recurring="$(recurring_ideas)"
    if [[ -n "$recurring" ]]; then
        user_msg+=$'\n\n[council] Recurring across memory-short.md and memory-new.md — consider graduating to memory-long.md:\n'"$recurring"
    fi

    printf '%s\n' "$user_msg" > "$PERSONA_DIR/last_prompt.txt"
    printf '%s: %s\n' "$CALLER" "$MESSAGE" >> "$LOG_FILE"

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

    # Mechanical flush, every call: short := new (script-owned, not persona-trusted).
    if [[ -f "$PERSONA_DIR/memory-new.md" ]]; then
        cp "$PERSONA_DIR/memory-new.md" "$PERSONA_DIR/memory-short.md"
    fi

    if [[ "$HARNESS" == "claude" || "$HARNESS" == "codex" ]]; then
        turns=$((turns + 1))
        if [[ $turns -ge $SESSION_MAX_TURNS ]]; then
            rm -f "$SESSION_FILE" "$TURNS_FILE"
            printf '' > "$PERSONA_DIR/memory-new.md"
            echo "[council] Session rotated after $turns turns; memory-new.md reset." >&2
        else
            printf '%s' "$turns" > "$TURNS_FILE"
        fi
    fi
}

run_harness
