#!/bin/bash
# Prechod z MATE na XFCE: odstrani MATE (krok 2 drive instaloval ubuntu-mate-desktop)
# a jeho nastaveni z kroku 7 (LightDM), 9 (screenshot skript) a 10 (MATE autostart).
# Spustit pres sudo, pak steps/02-xfce-desktop.sh.

set -e

REAL_USER="${SUDO_USER:-}"
[ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ] || { echo "[ERROR] Spust pres sudo jako bezny uzivatel."; exit 1; }
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "[INFO] Chranim zavislosti, ktere MATE nepotrebuje jen pro sebe (openssh-server apod.)..."
apt-mark manual openssh-server python3 sudo curl wget tmux >/dev/null 2>&1 || true

MATE_PKGS=$( { dpkg-query -W -f='${db:Status-Abbrev} ${binary:Package}\n' 'ubuntu-mate-*' 'mate-*' \
            'marco*' 'caja*' 'pluma*' 'atril*' 'engrampa*' 'eom*' 'lightdm*' 'slick-greeter' \
            'arctica-greeter' 2>/dev/null || true; } | awk '$1 == "ii" { print $2 }' | sort -u)
if [ -z "$MATE_PKGS" ]; then
  echo "[INFO] Zadne balicky MATE nenalezeny."
else
  echo "[INFO] Odstranuji: $(echo "$MATE_PKGS" | tr '\n' ' ')"
  apt-get purge -y $MATE_PKGS
fi

# Purge MATE nahradi virtualni zavislosti (polkit agent, notifikace) balicky GNOME: apt
# doinstaluje gnome-shell + gdm3 (overeno na base8, Ubuntu 26.04). Hned je zase odstranime.
GNOME_PKGS=$(dpkg-query -W -f='${db:Status-Abbrev} ${binary:Package}\n' gdm3 gnome-shell \
             gnome-session-bin gnome-remote-desktop 2>/dev/null | awk '$1 == "ii" { print $2 }' || true)
if [ -n "$GNOME_PKGS" ]; then
  echo "[INFO] Odstranuji GNOME, ktery apt doinstaloval misto MATE: $(echo "$GNOME_PKGS" | tr '\n' ' ')"
  apt-get purge -y $GNOME_PKGS
fi
apt-mark manual zip unzip >/dev/null 2>&1 || true

echo "[INFO] Zbytky nastaveni MATE (kroky 7, 9, 10)..."
rm -rf /etc/lightdm
rm -f "$REAL_HOME/bin/screenshot-area-safe.sh" \
      "$REAL_HOME/.config/autostart/claude-terminals.desktop" \
      "$REAL_HOME/.local/bin/mate-terminal-startup.sh"
rmdir "$REAL_HOME/bin" 2>/dev/null || true

echo "[INFO] Autoremove - nejdriv simulace, zkontroluj seznam!"
apt-get -s autoremove --purge | awk '/^Purg|^Remv/{print $2}' | tr '\n' ' '
echo
read -r -p "Provest autoremove? [y/N] " answer || answer=n
if [[ "$answer" =~ ^[Yy]$ ]]; then
  apt-get autoremove --purge -y
fi
echo "[OK] MATE odstranen. Dal: sudo bash steps/02-xfce-desktop.sh"
