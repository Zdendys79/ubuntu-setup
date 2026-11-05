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

# Claude Code keeps trust for $HOME only for the running session ("home trust is
# session-only"), so an unattended start in ~ would hang on the trust dialog. The
# startup check still honours a persisted projects[<dir>].hasTrustDialogAccepted,
# so set it before launching (no-op when already set).
ensure_trusted() {
    python3 -I - "$1" <<'EOF'
import json, os, sys
path = os.path.expanduser("~/.claude.json")
workdir = os.path.realpath(sys.argv[1])
try:
    with open(path) as f:
        config = json.load(f)
except (OSError, ValueError):
    sys.exit(0)
project = config.setdefault("projects", {}).setdefault(workdir, {})
if project.get("hasTrustDialogAccepted") is True:
    sys.exit(0)
project["hasTrustDialogAccepted"] = True
tmp = f"{path}.trust-{os.getpid()}"
with open(tmp, "w") as f:
    json.dump(config, f, indent=2)
os.chmod(tmp, os.stat(path).st_mode & 0o777)
os.replace(tmp, path)
print(f"[TRUST] {workdir}")
EOF
}

log "Starting tmux session setup..."

while IFS=$'\t' read -r name workdir conv_id rc_name companion; do
    if session_exists "$name"; then
        log "[SKIP] Session '$name' already exists"
    else
        ensure_trusted "$workdir"
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
