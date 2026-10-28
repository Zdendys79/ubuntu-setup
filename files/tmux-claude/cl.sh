#!/bin/bash
# cl / cl-<project> - attach to a Claude tmux session.
# "cl" -> session "claude" (Claude in ~); "cl-sagu" or "cl sagu" -> "cl-sagu".
# Sessions are created at boot by tmux-claude-startup.sh; if one is missing,
# that script is run first (it skips everything that already exists).

me=$(basename "$0" .sh)
if [ "$me" = "cl" ]; then
    SESSION=${1:+cl-$1}
    SESSION=${SESSION:-claude}
else
    SESSION=$me
fi

tmux list-sessions -F '#{session_group}|#{session_name}' 2>/dev/null | tr '|' '\n' | grep -qx -- "$SESSION" ||
    "$HOME/.local/bin/tmux-claude-startup.sh" >/dev/null

if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$SESSION"
else
    tmux attach-session -t "$SESSION"
fi
