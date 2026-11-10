#!/bin/bash
# Krok 9: Oprava zaseknuti mate-screenshot (glycin PNG encoder deadlock)
#
# BUG: Na Ubuntu s gdk-pixbuf >= 2.44 + glycin-loaders (napr. dev-release
# "resolute") mate-screenshot pri kliknuti na "Save" navzdy zamrzne.
# Root cause: gdk_pixbuf_save() -> libglycin posle pozadavek na sandboxovany
# enkoder (bwrap + glycin-image-rs) pres soukrome D-Bus peer spojeni, ale
# obe strany se navzajem zablokuji (viz gdb backtrace: hlavni vlakno visi
# v gly_creator_create(), pomocne vlakno "gly-hdl-editor" visi ve wait4()).
# "Copy to Clipboard" funguje, protoze nejde pres gdk_pixbuf_save().
#
# FIX: Shift+PrtScr prepnout na vlastni skript, ktery zachyti oblast pres
# ImageMagick (import — vlastni PNG enkoder, glycin vubec nepouziva) a
# ulozeni resi pres zenity + mv, cimz se glycin cesta uplne obejde.

set -e

# Jen pro MATE (Marco keybinding); XFCE (krok 2) tento krok nepotrebuje.
if ! command -v marco >/dev/null; then
  echo "[SKIP] MATE (marco) neni nainstalovan - krok se tyka jen MATE."
  exit 0
fi

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "")}"
if [ -z "$REAL_USER" ]; then
  echo "[ERROR] Nepodarilo se zjistit uzivatele."
  exit 1
fi
REAL_HOME=$(eval echo "~$REAL_USER")

echo "[INFO] Instaluji imagemagick + zenity (pokud chybi)..."
apt-get install -y imagemagick zenity

echo "[INFO] Vytvarim ~/bin/screenshot-area-safe.sh..."
mkdir -p "$REAL_HOME/bin"
cat > "$REAL_HOME/bin/screenshot-area-safe.sh" << 'SCRIPT'
#!/bin/sh
# Area screenshot ktery obchazi rozbity gdk-pixbuf/glycin PNG encoder
# (mate-screenshot's Save zamrzne navzdy v libglycin sandboxovanem
# enkoderu). ImageMagick import + zenity + mv se gdk-pixbuf save vubec
# nedotknou.

TMPFILE=$(mktemp --suffix=.png /tmp/screenshot-XXXXXX) || exit 1

import "$TMPFILE"
if [ $? -ne 0 ] || [ ! -s "$TMPFILE" ]; then
    rm -f "$TMPFILE"
    exit 1
fi

DEST=$(zenity --file-selection --save --confirm-overwrite \
    --filename="$HOME/Desktop/Screenshot.png" \
    --file-filter="PNG files | *.png" \
    --title="Save Screenshot")

if [ -n "$DEST" ]; then
    case "$DEST" in
        *.png|*.PNG) ;;
        *) DEST="$DEST.png" ;;
    esac
    mv "$TMPFILE" "$DEST"
else
    rm -f "$TMPFILE"
fi
SCRIPT

chmod +x "$REAL_HOME/bin/screenshot-area-safe.sh"
chown "$REAL_USER:$REAL_USER" "$REAL_HOME/bin/screenshot-area-safe.sh"

echo "[INFO] Prebindovavam Shift+PrtScr na novy skript..."
sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" \
  gsettings set org.mate.Marco.keybinding-commands command-2 "$REAL_HOME/bin/screenshot-area-safe.sh" 2>/dev/null \
  || echo "[WARNING] DBUS session neni dostupna — nastavit po prihlaseni do MATE"

echo "[OK] Shift+PrtScr nyni pouziva screenshot-area-safe.sh (obchazi glycin bug)."
echo "     Overeni: gsettings get org.mate.Marco.keybinding-commands command-2"
