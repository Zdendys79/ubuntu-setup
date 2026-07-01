#!/bin/bash
# Krok 8: Vstupni drivery (klavesnice, touchpad)
# Pouzit pokud po reinstalaci MATE nefunguje klavesnice nebo touchpad

set -e

echo "[INFO] Instaluji xserver vstupni drivery..."
apt install -y \
  xserver-xorg-input-all \
  xserver-xorg-input-libinput \
  xserver-xorg-input-synaptics

echo "[INFO] Restartuji LightDM..."
systemctl restart lightdm 2>/dev/null || echo "[WARNING] LightDM neni spusten."

echo "[OK] Vstupni drivery nainstalovany."
echo "     Pokud stale nefunguje klav./touchpad: zkus reboot."
