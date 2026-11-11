#!/bin/bash
# Krok 15: Syncthing (oficialni apt repozitar apt.syncthing.net, kanal stable)
# Bezi jako uzivatelska sluzba (systemctl --user, linger) - i bez prihlaseni po startu.
# GUI jen na 127.0.0.1:8384 (pristup pres SSH tunel nebo Chrome Remote Desktop).

set -e

REAL_USER="${SUDO_USER:-}"
[ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ] || { echo "[ERROR] Spust pres sudo jako bezny uzivatel."; exit 1; }
uid=$(id -u "$REAL_USER")

echo "[INFO] Pridavam apt repozitar Syncthing (stable)..."
install -d -m 755 /etc/apt/keyrings
curl -fsSL -o /etc/apt/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg
chmod 644 /etc/apt/keyrings/syncthing-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable-v2" \
  > /etc/apt/sources.list.d/syncthing.list
chmod 644 /etc/apt/sources.list.d/syncthing.list
apt update -q
apt install -y syncthing

echo "[INFO] Klice a konfigurace (Syncthing 2 nevytvari vychozi slozku; slozky se pridavaji rucne)..."
sudo -u "$REAL_USER" -H syncthing generate >/dev/null

echo "[INFO] Uzivatelska sluzba syncthing pro $REAL_USER (linger)..."
loginctl enable-linger "$REAL_USER"
sudo -u "$REAL_USER" env XDG_RUNTIME_DIR="/run/user/$uid" systemctl --user enable --now syncthing.service

echo "[OK] Syncthing $(syncthing --version | awk '{print $2}') bezi jako $REAL_USER."
echo "     Device ID: sudo -u $REAL_USER syncthing device-id   GUI: http://127.0.0.1:8384"
