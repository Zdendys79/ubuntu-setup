# Ubuntu Setup — Zdendys Standard

Checklist a skripty pro čistou instalaci Ubuntu (desktop i server).
Testováno na Ubuntu 24.04 / 26.04 LTS.

---

## Pořadí kroků

| # | Krok | Skript | Poznámka |
|---|------|--------|----------|
| 1 | Čistění nepotřebných balíčků | `steps/01-cleanup.sh` | cloud-init, apport, snapd, ... |
| 2 | MATE Desktop | `steps/02-mate-desktop.sh` | bez snap/firefox, Marco tiling |
| 3 | Google Chrome | `steps/03-chrome.sh` | přes apt repo (auto-update) |
| 4 | Node.js 22 + Claude Code | `steps/04-claude-code.sh` | bez sudo, do ~/.local/bin |
| 5 | Sudo timeout 180 min | `steps/05-sudo-timeout.sh` | výchozí je 15 min |
| 6 | SSH klíč (jz-work → nový stroj) | `steps/06-ssh-key.sh` | bezhelslový přístup |
| 7 | Česká klávesnice (MATE) | `steps/07-czech-keyboard.sh` | jen `cz` bez varianty! |
| 8 | Vstupní drivery | `steps/08-input-drivers.sh` | pokud nefunguje klávesnice/touchpad |

---

## Rychlé spuštění

```bash
# Klonuj repozitář
git clone https://github.com/Zdendys79/ubuntu-setup.git
cd ubuntu-setup

# Spusť vše najednou (interaktivní — každý krok potvrdíš)
./install.sh

# Nebo jednotlivé kroky:
sudo bash steps/01-cleanup.sh
sudo bash steps/02-mate-desktop.sh
# ...
```

---

## Poznámky

### Snapd
- Neinstalovat. Při instalaci MATE použít `--no-install-recommends`.
- Pokud už je nainstalován: viz `steps/01-cleanup.sh`.

### Claude Code
- NIKDY `sudo npm install -g` — vytvoří duplicitní instalaci.
- Správně: `npm config set prefix ~/.local` pak `npm install -g @anthropic-ai/claude-code`.

### Česká klávesnice
- `variant=qwertz` NEFUNGUJE správně v MATE — způsobuje chyby ve vyhledávání.
- Správně: `gsettings set ... layouts "['cz']"` (bez varianty).

### Sudo timeout
- Výchozích 15 min je málo při dlouhých sezeních. Standard: 180 min.

---

## SSH klíč (jz-work)

Veřejný klíč pro bezhelslový přístup z jz-work:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8uvCPXXbhRZ3dxUpYQf+puT/xa7kogINOp86k7IT+y remote-access
```

---

**Maintainer:** Zdendys79
