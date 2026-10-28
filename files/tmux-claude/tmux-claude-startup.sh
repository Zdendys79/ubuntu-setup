#!/bin/bash
# tmux-claude-startup.sh - recreate Claude tmux sessions after boot.
# Run by tmux-claude-startup.service (system unit, User=<installing user>); safe to run by
# hand - existing sessions are skipped. Per Claude instance from the last snapshot
# (see tmux-claude-restore-plan.py):
#   - Claude session "claude" (in ~) or "cl-<project>", started with
#     --resume <conversation id> (--continue if no id is known) and --remote-control
#   - one companion shell session: "sudo" for "claude", "<project>" otherwise

CLAUDE_BIN="$HOME/.local/bin/claude"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# A name counts as existing when a session or a session group has it
# (remote-tmux / grouped attaches create claude-1, cl-parkoviste-6, ...).
session_exists() {
    tmux list-sessions -F '#{session_group}|#{session_name}' 2>/dev/null |
        tr '|' '\n' | grep -qx -- "$1"
}

log "Starting tmux session setup..."

while IFS=$'\t' read -r name workdir conv_id rc_name companion; do
    if session_exists "$name"; then
        log "[SKIP] Session '$name' already exists"
    else
        tmux new-session -d -s "$name" -c "$workdir"
        if [ -n "$conv_id" ]; then
            resume="--resume $conv_id"
        else
            resume="--continue"
        fi
        cmd="$CLAUDE_BIN --dangerously-skip-permissions $resume --remote-control \"$rc_name\""
        tmux send-keys -t "=$name:" "$cmd" Enter
        log "[RUN] $name ($workdir) <- $cmd"
    fi

    if session_exists "$companion"; then
        log "[SKIP] Session '$companion' already exists"
    else
        tmux new-session -d -s "$companion" -c "$workdir"
        log "[CREATE] Session '$companion' (workdir: $workdir)"
    fi
done < <(python3 "$HOME/.local/bin/tmux-claude-restore-plan.py")

log "Done. Active sessions:"
tmux list-sessions 2>/dev/null | sed 's/^/  /'
