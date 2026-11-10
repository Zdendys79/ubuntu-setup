#!/bin/bash
# Krok 11: sudo bez hesla pri prihlaseni SSH klicem z lokalni site nebo Tailscale
# PAM (pam_exec, auth "sufficient") v /etc/pam.d/sudo a sudo-i spusti
# /usr/local/sbin/sudo-trusted-ssh: projde jen relace sshd overena klicem (nebo
# certifikatem) z siti v /etc/sudo-trusted-ssh/networks. Jinak se sudo pta na heslo.
# Popis: docs/sudo-trusted-ssh.md

set -e

SRC="$(cd "$(dirname "$0")/../files/sudo-trusted-ssh" && pwd)"
PAM_LINE="auth       sufficient pam_exec.so quiet /usr/local/sbin/sudo-trusted-ssh"

echo "[INFO] Instaluji /usr/local/sbin/sudo-trusted-ssh..."
install -o root -g root -m 755 "$SRC/sudo-trusted-ssh" /usr/local/sbin/sudo-trusted-ssh
install -d -o root -g root -m 755 /etc/sudo-trusted-ssh
if [ -f /etc/sudo-trusted-ssh/networks ]; then
  echo "[INFO] /etc/sudo-trusted-ssh/networks uz existuje, ponechavam."
else
  install -o root -g root -m 644 "$SRC/networks" /etc/sudo-trusted-ssh/networks
fi

for svc in sudo sudo-i; do
  f="/etc/pam.d/$svc"
  [ -f "$f" ] || continue
  if grep -qF "sudo-trusted-ssh" "$f"; then
    echo "[INFO] $f uz obsahuje sudo-trusted-ssh."
  elif grep -q '^@include common-auth' "$f"; then
    sed -i "0,/^@include common-auth/s||$PAM_LINE\n@include common-auth|" "$f"
    echo "[OK] $f doplnen."
  else
    echo "[WARNING] $f nema '@include common-auth' - preskakuji."
  fi
done

echo "[OK] sudo bez hesla pro SSH klic z: $(grep -v '^#' /etc/sudo-trusted-ssh/networks | tr '\n' ' ')"
echo "     Overeni ze jz-work: ssh ${SUDO_USER:-root}@$(hostname -I | awk '{print $1}') sudo true  (ne sudo -n)"
echo "     Log: journalctl -t sudo-trusted-ssh"
