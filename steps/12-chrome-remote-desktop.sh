#!/bin/bash
# Krok 12: Chrome Remote Desktop s XFCE (bez monitoru, bez spravce prihlaseni)
# Pozn.: po krocich 02 (XFCE) a 03 (Chrome). Prihlaseni hostitele k uctu Google
# udela uzivatel rucne (kod z https://remotedesktop.google.com/headless).

set -e

REAL_USER="${SUDO_USER:-}"
[ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ] || { echo "[ERROR] Spust pres sudo jako bezny uzivatel."; exit 1; }
DEB_URL="https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb"

echo "[INFO] Stahuji a instaluji Chrome Remote Desktop..."
tmp=$(mktemp -d)
wget -q -O "$tmp/chrome-remote-desktop.deb" "$DEB_URL"
apt install -y "$tmp/chrome-remote-desktop.deb"
rm -rf "$tmp"

echo "[INFO] Vzdalena session spousti XFCE..."
echo "exec /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session

# Starsi verze balicku pouzivaly skupinu chrome-remote-desktop, nove (157+) ji nevytvari.
if getent group chrome-remote-desktop >/dev/null; then
  echo "[INFO] Uzivatel $REAL_USER do skupiny chrome-remote-desktop..."
  usermod -aG chrome-remote-desktop "$REAL_USER"
fi

echo "[OK] Chrome Remote Desktop nainstalovan ($(dpkg-query -W -f='${Version}' chrome-remote-desktop))."
echo "     Dokonceni (jako $REAL_USER, BEZ sudo):"
echo "     1. https://remotedesktop.google.com/headless -> Begin -> Next -> Authorize"
echo "     2. zkopirovany prikaz pro Debian spustit v terminalu tohoto stroje, zadat PIN"
echo "     Stav: systemctl status chrome-remote-desktop@$REAL_USER"
