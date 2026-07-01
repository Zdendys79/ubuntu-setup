#!/bin/bash
# Krok 6: SSH klic pro bezhelslovy pristup z jz-work

set -e

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "")}"
if [ -z "$REAL_USER" ]; then
  echo "[ERROR] Nepodarilo se zjistit uzivatele."
  exit 1
fi
REAL_HOME=$(eval echo "~$REAL_USER")

SSH_DIR="$REAL_HOME/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"
JZ_WORK_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8uvCPXXbhRZ3dxUpYQf+puT/xa7kogINOp86k7IT+y remote-access"

echo "[INFO] Pridavam SSH klic jz-work pro uzivatele $REAL_USER..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if grep -qF "$JZ_WORK_KEY" "$AUTH_KEYS" 2>/dev/null; then
  echo "[INFO] Klic uz existuje, preskakuji."
else
  echo "$JZ_WORK_KEY" >> "$AUTH_KEYS"
  echo "[OK] Klic pridan."
fi

chmod 600 "$AUTH_KEYS"
chown -R "$REAL_USER:$REAL_USER" "$SSH_DIR"

echo "[OK] SSH klic nastaven. Test ze jz-work: ssh $REAL_USER@$(hostname -I | awk '{print $1}')"
