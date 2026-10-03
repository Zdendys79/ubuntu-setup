#!/bin/bash
# Krok 5: Sudo timeout 3600 minut (vychozi je 15 min)

set -e

echo "[INFO] Nastavuji sudo timeout na 3600 minut..."
tmp=$(mktemp)
echo 'Defaults timestamp_timeout=3600' > "$tmp"
visudo -c -f "$tmp"
install -o root -g root -m 440 "$tmp" /etc/sudoers.d/timeout
rm -f "$tmp"

echo "[OK] Sudo timeout nastaven na 3600 minut."
echo "     Overeni: sudo -l | grep timestamp"
