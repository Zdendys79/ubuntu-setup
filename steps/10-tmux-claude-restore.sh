#!/bin/bash
# Krok 10: Automaticka obnova Claude Code v tmux po restartu
# Snapshot kazdych 5 min (systemd --user timer) + system sluzba, ktera po startu
# znovu spusti kazdou Claude instanci s jejim ID konverzace a --remote-control.
# Popis: docs/tmux-claude-restore.md
# Spousti se pres sudo (install.sh); soubory jdou do domova uzivatele $SUDO_USER.

set -e

SRC="$(cd "$(dirname "$0")/../files/tmux-claude" && pwd)"
USER_NAME="${SUDO_USER:-}"
[ -n "$USER_NAME" ] && [ "$USER_NAME" != "root" ] || { echo "[ERROR] Spust pres sudo jako bezny uzivatel."; exit 1; }
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)

read -r -p "Nazev stroje pro --remote-control (napr. Base7, JZ-work) [$(hostname)]: " LABEL
LABEL="${LABEL:-$(hostname)}"

as_user() { sudo -u "$USER_NAME" -H "$@"; }

echo "[INFO] tmux, python3..."
apt-get install -y tmux python3 >/dev/null

echo "[INFO] Skripty do $USER_HOME/.local/bin..."
as_user mkdir -p "$USER_HOME/.local/bin" "$USER_HOME/.config/tmux-claude" "$USER_HOME/.config/systemd/user"
for f in tmux-claude-snapshot.py tmux-claude-restore-plan.py tmux-claude-startup.sh cl.sh; do
    install -o "$USER_NAME" -g "$USER_NAME" -m 755 "$SRC/$f" "$USER_HOME/.local/bin/$f"
done
as_user ln -sf cl.sh "$USER_HOME/.local/bin/cl"
echo "$LABEL" | as_user tee "$USER_HOME/.config/tmux-claude/label" >/dev/null

echo "[INFO] Snapshot timer (systemd --user, kazdych 5 min)..."
for f in tmux-claude-snapshot.service tmux-claude-snapshot.timer; do
    install -o "$USER_NAME" -g "$USER_NAME" -m 644 "$SRC/$f" "$USER_HOME/.config/systemd/user/$f"
done
loginctl enable-linger "$USER_NAME"
uid=$(id -u "$USER_NAME")
as_user env XDG_RUNTIME_DIR="/run/user/$uid" systemctl --user daemon-reload
as_user env XDG_RUNTIME_DIR="/run/user/$uid" systemctl --user enable --now tmux-claude-snapshot.timer

echo "[INFO] Sluzba po startu (tmux-claude-startup.service)..."
sed -e "s|@USER@|$USER_NAME|g" -e "s|@HOME@|$USER_HOME|g" \
    "$SRC/tmux-claude-startup.service.in" > /etc/systemd/system/tmux-claude-startup.service
systemctl daemon-reload
systemctl enable tmux-claude-startup.service

if command -v mate-terminal >/dev/null; then
    read -r -p "Otevirat po prihlaseni do MATE okna terminalu se sessions? [Y/n] " answer
    if [[ ! "$answer" =~ ^[Nn]$ ]]; then
        install -o "$USER_NAME" -g "$USER_NAME" -m 755 "$SRC/mate-terminal-startup.sh" "$USER_HOME/.local/bin/"
        as_user mkdir -p "$USER_HOME/.config/autostart"
        as_user tee "$USER_HOME/.config/autostart/claude-terminals.desktop" >/dev/null <<DESKTOP
[Desktop Entry]
Type=Application
Name=Claude Terminal Sessions
Comment=Open MATE terminal windows attached to Claude tmux sessions
Exec=$USER_HOME/.local/bin/mate-terminal-startup.sh
Terminal=false
Hidden=false
X-MATE-Autostart-enabled=true
DESKTOP
        echo "[OK] MATE autostart nastaven."
    fi
fi

echo "[OK] Obnova Claude v tmux nastavena (stroj: $LABEL)."
echo "     Prvni snapshot do 5 min. Hned: python3 ~/.local/bin/tmux-claude-snapshot.py"
echo "     Pripojeni: cl (hlavni Claude), cl <projekt> (cl-<projekt>)"
