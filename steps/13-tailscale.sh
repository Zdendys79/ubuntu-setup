#!/bin/bash
# Krok 13: Tailscale (oficialni apt repozitar, aktualizace pres apt upgrade)
# Prihlaseni do tailnetu: tailscale up vypise odkaz, ktery uzivatel otevre v prohlizeci.

set -e

CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
BASE="https://pkgs.tailscale.com/stable/ubuntu/$CODENAME"

echo "[INFO] Pridavam apt repozitar Tailscale ($CODENAME)..."
curl -fsSL "$BASE.noarmor.gpg" -o /usr/share/keyrings/tailscale-archive-keyring.gpg
curl -fsSL "$BASE.tailscale-keyring.list" -o /etc/apt/sources.list.d/tailscale.list

apt update -q
apt install -y tailscale
systemctl enable --now tailscaled

echo "[OK] Tailscale nainstalovan ($(tailscale version | head -1))."
echo "     Prihlaseni: sudo tailscale up  -> otevrit vypsany odkaz a potvrdit"
echo "     Stav: tailscale status; adresa: tailscale ip -4"
