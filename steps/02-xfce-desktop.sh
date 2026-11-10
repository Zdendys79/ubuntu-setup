#!/bin/bash
# Krok 2: XFCE Desktop (doporuceny pro Chrome Remote Desktop) bez snap/firefox
# Pozn.: spustit AZ PO kroku 01 (snapd musi byt prec). Prechod z MATE: extras/remove-mate.sh
# Bez spravce prihlaseni (LightDM): plocha se pouziva pres Chrome Remote Desktop (krok 12).

set -e

echo "[INFO] Instaluji XFCE (bez doporucenych balicku)..."
apt install -y --no-install-recommends xfce4 xfce4-terminal desktop-base dbus-x11 xscreensaver

echo "[INFO] Oznacuji XFCE jako manually installed (ochrana pred kaskadovym odstranim)..."
apt-mark manual xfce4 xfce4-session xfce4-terminal >/dev/null

if systemctl list-unit-files lightdm.service >/dev/null 2>&1; then
  echo "[INFO] LightDM nalezen - vypinam (Chrome Remote Desktop spousti vlastni X session)..."
  systemctl disable lightdm.service 2>/dev/null || true
fi

echo "[OK] XFCE nainstalovano. Vzdaleny pristup: krok 12 (Chrome Remote Desktop)."
