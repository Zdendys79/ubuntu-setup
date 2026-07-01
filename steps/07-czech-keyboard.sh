#!/bin/bash
# Krok 7: Ceska klavesnice v MATE
# POZOR: variant=qwertz NEFUNGUJE spravne v MATE — pouzit jen 'cz' bez varianty!

set -e

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "")}"
if [ -z "$REAL_USER" ]; then
  echo "[ERROR] Nepodarilo se zjistit uzivatele."
  exit 1
fi

echo "[INFO] Nastavuji ceskou klavesnici (jen 'cz', bez qwertz varianty)..."
sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" \
  gsettings set org.mate.peripherals-keyboard-xkb.kbd layouts "['cz']" 2>/dev/null \
  || echo "[WARNING] DBUS session neni dostupna — nastavit po prihlaseni do MATE"

echo "[INFO] Nastavuji ceskou klavesnici na LightDM login screenu..."
cat > /etc/lightdm/display-setup.sh << 'SCRIPT'
#!/bin/bash
setxkbmap cz
SCRIPT
chmod +x /etc/lightdm/display-setup.sh

LIGHTDM_CONF="/etc/lightdm/lightdm.conf"
if [ -f "$LIGHTDM_CONF" ]; then
  if grep -q '#display-setup-script=' "$LIGHTDM_CONF"; then
    sed -i 's|#display-setup-script=|display-setup-script=/etc/lightdm/display-setup.sh|' "$LIGHTDM_CONF"
  elif ! grep -q 'display-setup-script=' "$LIGHTDM_CONF"; then
    echo 'display-setup-script=/etc/lightdm/display-setup.sh' >> "$LIGHTDM_CONF"
  fi
fi

echo "[OK] Ceska klavesnice nastavena."
