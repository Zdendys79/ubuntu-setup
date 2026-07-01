#!/bin/bash
# Krok 3: Google Chrome (s apt repozitarem pro auto-update)

set -e

echo "[INFO] Stahuji GPG klic Google Chrome..."
wget -q -O /tmp/google-chrome.gpg https://dl.google.com/linux/linux_signing_key.pub
gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg /tmp/google-chrome.gpg
rm /tmp/google-chrome.gpg

echo "[INFO] Pridavam apt repozitar..."
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
  > /etc/apt/sources.list.d/google-chrome.list

apt update -q
apt install -y google-chrome-stable

echo "[OK] Google Chrome nainstalovan. Auto-update funguje pres apt upgrade."
