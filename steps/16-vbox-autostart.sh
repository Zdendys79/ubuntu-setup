#!/bin/bash
# Krok 16: VM ve VirtualBoxu startuji se serverem a pri vypnuti/restartu se ulozi jejich stav
# Sluzba vbox-autostart.service (User=uzivatel s VM): start = spusti VM s autostart-enabled
# (headless, z ulozeneho stavu pokracuji), stop = savestate vsech bezicich VM.
# VM se oznaci: VBoxManage modifyvm <vm> --autostart-enabled on
# Oracle vboxautostart-service se vypina (bez konfigurace nic nedela, nechceme dvoji start).

set -e

SRC="$(cd "$(dirname "$0")/../files/vbox-autostart" && pwd)"
REAL_USER="${SUDO_USER:-}"
[ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ] || { echo "[ERROR] Spust pres sudo jako bezny uzivatel."; exit 1; }
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
command -v VBoxManage >/dev/null || { echo "[ERROR] VirtualBox neni nainstalovan (krok 14)."; exit 1; }

install -o root -g root -m 755 "$SRC/vbox-autostart" /usr/local/bin/vbox-autostart
# --autostart-enabled needs an autostart database path ("The path to the autostart database is
# not set"); a directory of the user is enough - only this service reads the flags.
sudo -u "$REAL_USER" -H mkdir -p "$REAL_HOME/.config/VirtualBox/autostart"
sudo -u "$REAL_USER" -H VBoxManage setproperty autostartdbpath "$REAL_HOME/.config/VirtualBox/autostart"
sed -e "s|@USER@|$REAL_USER|g" -e "s|@HOME@|$REAL_HOME|g" "$SRC/vbox-autostart.service.in" \
  > /etc/systemd/system/vbox-autostart.service
systemctl disable vboxautostart-service.service 2>/dev/null || true
systemctl daemon-reload
systemctl enable vbox-autostart.service
# Aktivovat hned (spusti oznacene VM, ktere nebezi): jen aktivni sluzba ulozi VM pri vypnuti.
systemctl start vbox-autostart.service

echo "[OK] vbox-autostart.service zapnuta pro $REAL_USER."
sudo -u "$REAL_USER" -H /usr/local/bin/vbox-autostart status
echo "     Oznacit VM: VBoxManage modifyvm <vm> --autostart-enabled on"
