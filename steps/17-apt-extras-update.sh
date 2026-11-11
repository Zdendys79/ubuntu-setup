#!/bin/bash
# Krok 17: aktualizace programu mimo apt spolu s "sudo apt update && sudo apt full-upgrade"
# Claude Code (nativni instalace uzivatele) a VirtualBox Extension Pack - viz
# files/apt-extras-update/apt-extras-update. Ostatni programy (Chrome, Chrome Remote Desktop,
# Node.js, Tailscale, VirtualBox, Syncthing) maji vlastni apt repozitar.

set -e

SRC="$(cd "$(dirname "$0")/../files/apt-extras-update" && pwd)"
REAL_USER="${SUDO_USER:-}"
[ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ] || { echo "[ERROR] Spust pres sudo jako bezny uzivatel."; exit 1; }

install -o root -g root -m 755 "$SRC/apt-extras-update" /usr/local/sbin/apt-extras-update
install -o root -g root -m 644 "$SRC/99apt-extras-update" /etc/apt/apt.conf.d/99apt-extras-update
install -d -o root -g root -m 755 /etc/apt-extras-update
touch /etc/apt-extras-update/users
grep -qx "$REAL_USER" /etc/apt-extras-update/users || echo "$REAL_USER" >> /etc/apt-extras-update/users
chmod 644 /etc/apt-extras-update/users
# Old hook of step 4 ran "claude update" as root (no Claude there) - replaced by this step.
rm -f /etc/apt/apt.conf.d/99claude-code-update

echo "[INFO] Prvni beh..."
rm -f /run/apt-extras-update.stamp
/usr/local/sbin/apt-extras-update

echo "[OK] Aktualizace mimo apt zapojene do apt (uzivatele: $(tr '\n' ' ' < /etc/apt-extras-update/users))."
echo "     Log: journalctl -t apt-extras-update"
