#!/bin/bash
# Krok 14: VirtualBox (Oracle apt repozitar, nejnovejsi 7.2.x) + Extension Pack
# Secure Boot: jaderne moduly VirtualBoxu musi byt podepsane klicem zapsanym v MOK.
# Krok vytvori klic /var/lib/shim-signed/mok/MOK.{priv,der} (pokud chybi), moduly jim
# podepise (vboxconfig) a pripravi zapis klice: mokutil se zepta na jednorazove heslo,
# ktere se pri pristim startu zada na konzoli stroje (MOK Manager -> Enroll MOK).
# MOK_PASSWORD_FILE=<soubor> (prvni radek = heslo) zada heslo bez dotazu. Heslo jen z pismen
# bez y/z (stejna mista na ceske i americke klavesnici - MOK Manager bezi s americkou).
# Klic MOK.priv/MOK.der zalohovat mimo stroj: po reinstalaci ho MOK_KEY_SRC=<adresar> vrati
# a zapsany klic plati dal (bez noveho zapisu na konzoli).
# Extension Pack je pod licenci Oracle PUEL (zdarma pro osobni a vzdelavaci pouziti).

set -e

REAL_USER="${SUDO_USER:-}"
[ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ] || { echo "[ERROR] Spust pres sudo jako bezny uzivatel."; exit 1; }
CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
MOK_DIR=/var/lib/shim-signed/mok

echo "[INFO] Pridavam apt repozitar Oracle VirtualBox ($CODENAME)..."
wget -q -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc \
  | gpg --dearmor --yes -o /usr/share/keyrings/oracle-virtualbox-2016.gpg
chmod 644 /usr/share/keyrings/oracle-virtualbox-2016.gpg  # apt verifies as _apt (umask 077 would block it)
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $CODENAME contrib" \
  > /etc/apt/sources.list.d/virtualbox.list
chmod 644 /etc/apt/sources.list.d/virtualbox.list
apt update -q

SB=no
mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled" && SB=yes
if [ "$SB" = yes ] && [ ! -f "$MOK_DIR/MOK.priv" ] && [ -n "${MOK_KEY_SRC:-}" ] \
   && [ -f "$MOK_KEY_SRC/MOK.priv" ] && [ -f "$MOK_KEY_SRC/MOK.der" ]; then
  echo "[INFO] Pouzivam zalohovany podpisovy klic z $MOK_KEY_SRC..."
  install -d -m 700 "$MOK_DIR"
  install -m 600 "$MOK_KEY_SRC/MOK.priv" "$MOK_DIR/MOK.priv"
  install -m 644 "$MOK_KEY_SRC/MOK.der" "$MOK_DIR/MOK.der"
fi
if [ "$SB" = yes ] && [ ! -f "$MOK_DIR/MOK.priv" ]; then
  echo "[INFO] Secure Boot zapnuty - vytvarim podpisovy klic $MOK_DIR/MOK.{priv,der}..."
  install -d -m 700 "$MOK_DIR"
  openssl req -new -x509 -newkey rsa:2048 -nodes -days 36500 -outform DER \
    -keyout "$MOK_DIR/MOK.priv" -out "$MOK_DIR/MOK.der" \
    -subj "/CN=$(hostname) VirtualBox module signing/"
  chmod 600 "$MOK_DIR/MOK.priv"
fi

echo "[INFO] Instaluji VirtualBox 7.2 (build zavislosti pro moduly)..."
apt install -y build-essential dkms "linux-headers-$(uname -r)" virtualbox-7.2
usermod -aG vboxusers "$REAL_USER"

# Version from dpkg: VBoxManage prints a vboxdrv warning first while the modules are not loaded.
VER=$(dpkg-query -W -f='${Version}' virtualbox-7.2 | cut -d- -f1)
echo "[INFO] Extension Pack $VER..."
tmp=$(mktemp -d)
EXT="Oracle_VirtualBox_Extension_Pack-$VER.vbox-extpack"  # VBoxManage checks the file name
wget -q -O "$tmp/$EXT" "https://download.virtualbox.org/virtualbox/$VER/$EXT"
echo y | VBoxManage extpack install --replace "$tmp/$EXT"
rm -rf "$tmp"
VBoxManage list extpacks | grep -E "Pack no|Version|Usable"

if [ "$SB" = yes ]; then
  if mokutil --test-key "$MOK_DIR/MOK.der" 2>&1 | grep -q "already enrolled"; then
    echo "[OK] Podpisovy klic uz je v MOK zapsany."
  else
    if [ -n "${MOK_PASSWORD_FILE:-}" ]; then
      echo "[INFO] Zapis klice do MOK s heslem z $MOK_PASSWORD_FILE..."
      pw=$(head -1 "$MOK_PASSWORD_FILE")
      printf '%s\n%s\n' "$pw" "$pw" | mokutil --import "$MOK_DIR/MOK.der"
      unset pw
    else
      echo "[INFO] Zapis klice do MOK - zadej jednorazove heslo (2x), znovu ho zadas pri startu:"
      mokutil --import "$MOK_DIR/MOK.der"
    fi
    echo "[WARNING] Moduly se nactou az po restartu: na konzoli MOK Manager -> Enroll MOK ->"
    echo "          Continue -> Yes -> heslo -> Reboot. Bez toho VirtualBox VM nespusti."
  fi
fi

echo "[OK] VirtualBox $VER nainstalovan, uzivatel $REAL_USER ve skupine vboxusers."
echo "     Overeni po restartu: lsmod | grep vboxdrv; VBoxManage list extpacks"
