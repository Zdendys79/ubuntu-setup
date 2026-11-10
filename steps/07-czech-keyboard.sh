#!/bin/bash
# Krok 7: Ceska klavesnice (system + X11, plati i pro XFCE a Chrome Remote Desktop)
# POZOR: variant=qwertz NEFUNGUJE spravne (chyby ve vyhledavani) - pouzit jen 'cz' bez varianty!
# /etc/default/keyboard se upravuje primo: "localectl set-x11-keymap" pod sudo-rs pres SSH
# konci "Access denied" (overeno na Ubuntu 26.04, base8).

set -e

KBD=/etc/default/keyboard

echo "[INFO] Nastavuji ceskou klavesnici (jen 'cz', bez qwertz varianty)..."
[ -f "$KBD" ] || printf 'XKBMODEL="pc105"\nXKBLAYOUT=""\nXKBVARIANT=""\nXKBOPTIONS=""\nBACKSPACE="guess"\n' > "$KBD"
sed -i -e 's/^XKBLAYOUT=.*/XKBLAYOUT="cz"/' -e 's/^XKBVARIANT=.*/XKBVARIANT=""/' "$KBD"
grep -E '^XKB(LAYOUT|VARIANT)=' "$KBD"
udevadm trigger --subsystem-match=input --action=change

echo "[OK] Ceska klavesnice nastavena (projevi se v nove X session)."
