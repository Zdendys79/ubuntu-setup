#!/bin/bash
# Krok 4: Node.js 22 LTS + Claude Code
# POZOR: Claude Code se instaluje BEZ sudo (self-managed do ~/.local/bin)

set -e

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "")}"
if [ -z "$REAL_USER" ]; then
  echo "[ERROR] Nepodarilo se zjistit uzivatele. Spust: sudo -E bash steps/04-claude-code.sh"
  exit 1
fi
REAL_HOME=$(eval echo "~$REAL_USER")

echo "[INFO] Instaluji Node.js 22 LTS..."
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs
node --version
npm --version

echo "[INFO] Nastavuji npm prefix pro uzivatele $REAL_USER (bez sudo)..."
sudo -u "$REAL_USER" npm config set prefix "$REAL_HOME/.local"

echo "[INFO] Instaluji Claude Code jako uzivatel $REAL_USER..."
sudo -u "$REAL_USER" npm install -g @anthropic-ai/claude-code

echo "[INFO] Pridavam ~/.local/bin do PATH v .bashrc..."
if ! grep -q '\.local/bin' "$REAL_HOME/.bashrc"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$REAL_HOME/.bashrc"
fi

echo "[INFO] Pridavam auto-update Claude Code pri apt upgrade..."
echo 'DPkg::Post-Invoke {"claude update 2>/dev/null || true";};' \
  > /etc/apt/apt.conf.d/99claude-code-update

echo "[OK] Claude Code nainstalovan do $REAL_HOME/.local/bin/claude"
echo "     Spust: source ~/.bashrc && claude --version"
