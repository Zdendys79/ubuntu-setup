#!/bin/bash
# Krok 1: Cisteni nepotrebnych balicku po ciste instalaci Ubuntu

set -e

echo "[INFO] Odstranuji zbytecne balicky (server + desktop)..."
apt purge -y \
  cloud-init cloud-initramfs-copymods cloud-initramfs-dyn-netconf \
  apport apport-core-dump-handler apport-symptoms python3-apport \
  landscape-common \
  modemmanager \
  multipath-tools \
  packagekit \
  unattended-upgrades \
  avahi-daemon \
  cups cups-browsed \
  memtest86+ \
  2>/dev/null || true

echo "[INFO] Odstranuji desktop-specificke balicky..."
apt purge -y \
  whoopsie whoopsie-preferences \
  ubuntu-advantage-desktop-daemon \
  ibus-gtk3 \
  2>/dev/null || true

echo "[INFO] Pokud je snapd pritomen, odstranim ho..."
if dpkg -l snapd 2>/dev/null | grep -q ^ii; then
  apt purge -y snapd firefox 2>/dev/null || true
fi

apt autoremove --purge -y
echo "[OK] Cisteni dokonceno."
