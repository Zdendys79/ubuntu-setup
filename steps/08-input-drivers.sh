#!/bin/bash
# Krok 8: Vstupni drivery (klavesnice, touchpad)
# Pouzit pokud na fyzickem monitoru nefunguje klavesnice nebo touchpad

set -e

echo "[INFO] Instaluji xserver vstupni drivery..."
apt install -y \
  xserver-xorg-input-all \
  xserver-xorg-input-libinput \
  xserver-xorg-input-synaptics

echo "[OK] Vstupni drivery nainstalovany."
echo "     Pokud stale nefunguje klav./touchpad: zkus reboot."
