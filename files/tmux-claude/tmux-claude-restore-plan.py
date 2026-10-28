#!/usr/bin/env python3
"""Print the Claude session launch plan, tab-separated: tmux name, cwd,
conversation id (may be empty), remote-control name, companion shell session.
Used by tmux-claude-startup.sh.

Naming: Claude running in $HOME is the primary session "claude" (remote-control
name = machine label: $MACHINE_LABEL, else ~/.config/tmux-claude/label, else the hostname). Any other project dir <dir> becomes tmux session
"cl-<dir>" with remote-control name "<Dir> (<label>)". Each Claude session has one
companion shell session: "sudo" for the primary one, "<dir>" for the others.
Part of ubuntu-setup step 10 (docs/tmux-claude-restore.md).
"""
import json
import os

HOME = os.path.expanduser("~")
LABEL_FILE = os.path.expanduser("~/.config/tmux-claude/label")


def machine_label():
    if os.environ.get("MACHINE_LABEL"):
        return os.environ["MACHINE_LABEL"]
    if os.path.isfile(LABEL_FILE):
        with open(LABEL_FILE) as f:
            label = f.read().strip()
        if label:
            return label
    return os.uname().nodename


LABEL = machine_label()
SNAPSHOT = os.path.expanduser("~/.cache/tmux_claude_snapshot.json")
DEFAULT_DIRS = [HOME]


def names(cwd):
    if os.path.realpath(cwd) == os.path.realpath(HOME):
        return "claude", LABEL, "sudo"
    base = os.path.basename(cwd.rstrip("/"))
    return "cl-" + base.lower(), f"{base[:1].upper()}{base[1:]} ({LABEL})", base.lower()


entries = {}
if os.path.isfile(SNAPSHOT):
    with open(SNAPSHOT) as f:
        for item in json.load(f):
            if os.path.isdir(item["cwd"]):
                entries.setdefault(item["cwd"], item["id"])
for cwd in DEFAULT_DIRS:
    entries.setdefault(cwd, "")

used = set()
for cwd, cid in entries.items():
    name, rc, companion = names(cwd)
    if name in used:
        continue
    used.add(name)
    print(f"{name}\t{cwd}\t{cid}\t{rc}\t{companion}")
