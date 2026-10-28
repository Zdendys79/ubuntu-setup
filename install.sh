#!/bin/bash
# Ubuntu Setup — Zdendys Standard
# Interaktivni instalace — kazdy krok potvrdis

set -e

STEPS_DIR="$(dirname "$0")/steps"

run_step() {
    local num="$1"
    local name="$2"
    local script="$3"

    echo ""
    echo "=== Krok $num: $name ==="
    read -r -p "Spustit? [Y/n] " answer
    if [[ "$answer" =~ ^[Nn]$ ]]; then
        echo "[SKIP] $name"
        return
    fi
    sudo bash "$STEPS_DIR/$script"
    echo "[OK] $name"
}

echo "Ubuntu Setup — Zdendys Standard"
echo "================================"

run_step 1 "Cisteni nepotrebnych balicku"   "01-cleanup.sh"
run_step 2 "MATE Desktop"                    "02-mate-desktop.sh"
run_step 3 "Google Chrome"                   "03-chrome.sh"
run_step 4 "Node.js 22 + Claude Code"        "04-claude-code.sh"
run_step 5 "Sudo timeout 3600 min"           "05-sudo-timeout.sh"
run_step 6 "SSH klic (jz-work)"              "06-ssh-key.sh"
run_step 7 "Ceska klavesnice MATE"           "07-czech-keyboard.sh"
run_step 8 "Vstupni drivery"                 "08-input-drivers.sh"
run_step 9 "Oprava screenshotu (glycin)"     "09-screenshot-glycin-fix.sh"
run_step 10 "Obnova Claude v tmux"          "10-tmux-claude-restore.sh"

echo ""
echo "=== Hotovo! ==="
echo "Doporuceno: reboot"
