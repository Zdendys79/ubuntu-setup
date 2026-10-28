#!/bin/bash
# mate-terminal-startup.sh - open MATE terminal windows attached to the Claude tmux
# sessions (desktop machines only). Called from XDG autostart
# (~/.config/autostart/claude-terminals.desktop) after the MATE desktop is ready.
# Window 1: "claude" + every cl-* session as tabs; window 2: "sudo" + companion shells.

SESSION_WAIT_TIMEOUT=30

# Window definitions: "window_id|session_name"
# Same window_id = same terminal window (tabs).
# New window_id = new terminal window.
WINDOWS=(
    "1|claude"
    "2|sudo"
)

# Every cl-* Claude session becomes a tab in window 1, every companion shell
# session (<project>) a tab in window 2 after sudo.
CL_TABS=()
SHELL_TABS=()
while IFS=$'\t' read -r name _ _ _ companion; do
    case "$name" in
        cl-*) CL_TABS+=( "1|$name" ); SHELL_TABS+=( "2|$companion" ) ;;
    esac
done < <(python3 "$HOME/.local/bin/tmux-claude-restore-plan.py")
WINDOWS=( "${WINDOWS[0]}" "${CL_TABS[@]}" "${WINDOWS[1]}" "${SHELL_TABS[@]}" )

log() { echo "[$(date '+%H:%M:%S')] $*"; }

wait_for_session() {
    local name="$1"
    local elapsed=0
    while ! tmux has-session -t "$name" 2>/dev/null; do
        sleep 1
        elapsed=$((elapsed + 1))
        if [ "$elapsed" -ge "$SESSION_WAIT_TIMEOUT" ]; then
            log "[WARN] Session '$name' not ready after ${SESSION_WAIT_TIMEOUT}s, continuing anyway"
            return 1
        fi
    done
    return 0
}

log "Waiting for tmux sessions..."
for entry in "${WINDOWS[@]}"; do
    session="${entry#*|}"
    wait_for_session "$session"
done

log "Opening MATE terminal windows..."

mate_args=()
prev_window_id=""

for entry in "${WINDOWS[@]}"; do
    window_id="${entry%%|*}"
    session="${entry#*|}"

    if [ "$window_id" != "$prev_window_id" ]; then
        mate_args+=( --window )
    else
        mate_args+=( --tab )
    fi

    mate_args+=(
        --title="$session"
        --command="bash -c 'tmux attach-session -t $session; exec bash'"
    )
    prev_window_id="$window_id"
done

mate-terminal "${mate_args[@]}" &

log "Done."
