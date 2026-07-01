#!/bin/bash
# Krok 5: Sudo timeout 180 minut (vychozi je 15 min)

set -e

echo "[INFO] Nastavuji sudo timeout na 180 minut..."
echo 'Defaults timestamp_timeout=180' > /etc/sudoers.d/timeout
chmod 440 /etc/sudoers.d/timeout

echo "[OK] Sudo timeout nastaven na 180 minut."
echo "     Overeni: sudo -l | grep timestamp"
