#!/bin/bash
# Krok 4: Node.js 22 LTS + Claude Code (nativni instalace, doporucena Anthropicem)
# POZOR: Claude Code se instaluje BEZ sudo, do domova uzivatele (~/.local/bin/claude ->
# ~/.local/share/claude/versions/<verze>). Drivejsi npm instalace se odstrani (dve instalace
# by se pretahovaly o ~/.local/bin/claude). Node.js zustava pro MCP servery a skripty.
# Aktualizace spolu s apt: krok 17.

set -e

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "")}"
if [ -z "$REAL_USER" ] || [ "$REAL_USER" = "root" ]; then
  echo "[ERROR] Nepodarilo se zjistit uzivatele. Spust: sudo bash steps/04-claude-code.sh"
  exit 1
fi
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
as_user() { sudo -u "$REAL_USER" -H "$@"; }

echo "[INFO] Instaluji Node.js 22 LTS..."
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs
node --version
npm --version

echo "[INFO] npm prefix pro uzivatele $REAL_USER (globalni balicky bez sudo)..."
as_user npm config set prefix "$REAL_HOME/.local"

if as_user npm ls -g --depth=0 @anthropic-ai/claude-code >/dev/null 2>&1; then
  echo "[INFO] Odstranuji starsi npm instalaci Claude Code..."
  as_user npm uninstall -g @anthropic-ai/claude-code
fi

echo "[INFO] Instaluji Claude Code (nativne) jako uzivatel $REAL_USER..."
as_user bash -c 'curl -fsSL https://claude.ai/install.sh | bash'

echo "[INFO] Pridavam ~/.local/bin do PATH v .bashrc..."
if ! grep -q '\.local/bin' "$REAL_HOME/.bashrc"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$REAL_HOME/.bashrc"
fi

echo "[OK] Claude Code $(as_user "$REAL_HOME/.local/bin/claude" --version) v $REAL_HOME/.local/bin/claude"
echo "     Prihlaseni: claude (jako $REAL_USER). Aktualizace s apt: krok 17."
