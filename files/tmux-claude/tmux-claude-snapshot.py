#!/usr/bin/env python3
"""Record Claude Code instances running in tmux panes (cwd + conversation id).

Writes ~/.cache/tmux_claude_snapshot.json as a list of
{"tmux": <session name>, "cwd": <claude working dir>, "id": <conversation id>}.
Run every 5 min by tmux-claude-snapshot.timer (systemd --user); read by
tmux-claude-restore-plan.py at boot. The file is left untouched when no Claude
instance is found, so a snapshot taken during boot cannot wipe the last good state.
Part of ubuntu-setup step 10 (docs/tmux-claude-restore.md).
"""
import glob
import json
import os
import re
import subprocess

OUT = os.path.expanduser("~/.cache/tmux_claude_snapshot.json")
PROJECTS = os.path.expanduser("~/.claude/projects")
UUID = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True).stdout


def cmdline(pid):
    try:
        with open(f"/proc/{pid}/cmdline", "rb") as f:
            return f.read().decode(errors="replace").split("\0")[:-1]
    except OSError:
        return []


def is_claude(args):
    if not args:
        return False
    if os.path.basename(args[0]) == "claude":
        return True
    return os.path.basename(args[0]) == "node" and len(args) > 1 and args[1].endswith("/claude")


def conversation_id(args, cwd):
    # Newest transcript wins: /resume or /clear inside Claude switches conversations
    # without changing the command line.
    project = os.path.join(PROJECTS, re.sub(r"[^A-Za-z0-9]", "-", cwd))
    files = glob.glob(os.path.join(project, "*.jsonl"))
    if files:
        return os.path.basename(max(files, key=os.path.getmtime))[:-len(".jsonl")]
    for i, a in enumerate(args[:-1]):
        if a in ("--resume", "-r", "--session-id") and UUID.match(args[i + 1]):
            return args[i + 1]
    return ""


def main():
    children = {}
    for line in run(["ps", "-eo", "pid=,ppid="]).splitlines():
        pid, ppid = line.split()
        children.setdefault(ppid, []).append(pid)

    found, seen = [], set()
    for line in run(["tmux", "list-panes", "-a", "-F", "#{session_name}|#{pane_pid}"]).splitlines():
        session, pane_pid = line.split("|", 1)
        stack = [pane_pid]
        while stack:
            pid = stack.pop()
            stack.extend(children.get(pid, []))
            args = cmdline(pid)
            if not is_claude(args):
                continue
            try:
                cwd = os.readlink(f"/proc/{pid}/cwd")
            except OSError:
                continue
            if cwd in seen:
                continue
            seen.add(cwd)
            found.append({"tmux": session, "cwd": cwd, "id": conversation_id(args, cwd)})

    if not found:
        return
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    tmp = OUT + ".tmp"
    with open(tmp, "w") as f:
        json.dump(found, f, indent=2)
    os.replace(tmp, OUT)


if __name__ == "__main__":
    main()
