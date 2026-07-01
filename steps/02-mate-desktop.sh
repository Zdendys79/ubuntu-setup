#!/bin/bash
# Krok 2: MATE Desktop bez snap/firefox + Marco tiling
# Pozn.: spustit AZ PO kroku 01 (snapd musi byt prec)

set -e

echo "[INFO] Instaluji MATE Desktop (bez doporucenych balicku)..."
apt install -y --no-install-recommends ubuntu-mate-desktop

echo "[INFO] Oznacuji MATE jako manually installed (ochrana pred kaskadovym odstranim)..."
apt-mark manual ubuntu-mate-desktop ubuntu-mate-core xserver-xorg xserver-xorg-input-all

# Marco tiling — zjistim jmeno uzivatele (ne root)
REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "")}"
if [ -z "$REAL_USER" ]; then
  echo "[WARNING] Nepodarilo se zjistit uzivatele, preskakuji Marco tiling."
  echo "          Spust rucne: gsettings set org.mate.Marco.general allow-tiling true"
else
  echo "[INFO] Nastavuji Marco tiling pro uzivatele $REAL_USER..."
  sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" bash -c '
    gsettings set org.mate.Marco.general allow-tiling true
    gsettings set org.mate.Marco.general allow-tile-cycling true
    gsettings set org.mate.Marco.general allow-top-tiling true
  ' 2>/dev/null || echo "[WARNING] Marco tiling nenastaveno (pravdepodobne neni aktivni DBUS session — nastavit po prihlaseni)"
fi

echo "[OK] MATE Desktop nainstalovan."
echo "     Po restartu: prihlasit se do MATE a zkontrolovat Marco tiling."
