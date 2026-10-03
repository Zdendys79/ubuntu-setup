#!/bin/bash
# Krok 1: Cisteni nepotrebnych balicku po ciste instalaci Ubuntu
#
# POZOR (overeno na Ubuntu 26.04, base7, 2026-10-03):
# - python3-apport NEODSTRANOVAT: metabalicek xserver-xorg na nem zavisi, jeho purge
#   by odstranil i xorg + xserver-xorg a nasledny autoremove by mohl smazat X server.
#   Samotna sluzba apport se odstrani (balicky apport, apport-core-dump-handler).
# - Purge cloud-init / apport / multipath-tools / snapd odstrani metabalicek
#   ubuntu-server-minimal, purge packagekit odstrani software-properties-common.
#   Jejich zavislosti by pak autoremove smazal (vcetne openssh-server apod.),
#   proto je pred purge oznacujeme jako rucne instalovane (apt-mark manual).
# - unattended-upgrades se odstranuje zamerne: aktualizace se delaji rucne
#   (sudo apt update && sudo apt full-upgrade). Bez nej nechodi automaticky
#   ani bezpecnostni opravy - nezapomenout na pravidelny upgrade.

set -e

echo "[INFO] Chranim zavislosti metabalicku, ktere purge odstrani..."
DEPS=$(apt-cache depends --installed ubuntu-server-minimal ubuntu-minimal software-properties-common 2>/dev/null \
       | awk '/^\s+Depends:/{print $2}' | grep -v '^<' | sort -u)
if [ -n "$DEPS" ]; then
  apt-mark manual $DEPS >/dev/null
fi

echo "[INFO] Odstranuji zbytecne balicky (server + desktop)..."
apt purge -y \
  cloud-init cloud-initramfs-copymods cloud-initramfs-dyn-netconf \
  apport apport-core-dump-handler apport-symptoms \
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

echo "[INFO] Zbytky konfigurace unattended-upgrades..."
rm -f /etc/apt/apt.conf.d/20auto-upgrades \
      /etc/apt/apt.conf.d/50unattended-upgrades* \
      /etc/apt/apt.conf.d/52unattended-upgrades-extras \
      /etc/apt/apt.conf.d/zzzz-temp-installer-unattended-upgrade

echo "[INFO] Autoremove - nejdriv simulace, zkontroluj seznam!"
apt-get -s autoremove --purge | awk '/^Purg|^Remv/{print $2}' | tr '\n' ' '
echo
read -r -p "Provest autoremove? [y/N] " answer || answer=n
if [[ "$answer" =~ ^[Yy]$ ]]; then
  apt autoremove --purge -y
fi
echo "[OK] Cisteni dokonceno."
