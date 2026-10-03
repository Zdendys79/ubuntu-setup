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
| 5 | Sudo timeout 3600 min | `steps/05-sudo-timeout.sh` | výchozí je 15 min |
| 6 | SSH klíč (jz-work → nový stroj) | `steps/06-ssh-key.sh` | bezhelslový přístup |
| 7 | Česká klávesnice (MATE) | `steps/07-czech-keyboard.sh` | jen `cz` bez varianty! |
| 8 | Vstupní drivery | `steps/08-input-drivers.sh` | pokud nefunguje klávesnice/touchpad |
| 9 | Oprava screenshotů (glycin freeze) | `steps/09-screenshot-glycin-fix.sh` | mate-screenshot zamrzne na Save |

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

### Upgrade 24.04 → 26.04
- Zkušenosti, rizika a nálezy z upgradu serveru base7: [`docs/upgrade-24.04-to-26.04.md`](docs/upgrade-24.04-to-26.04.md).

### Čištění balíčků (krok 1) — rizika
- **`python3-apport` neodstraňovat.** Metabalíček `xserver-xorg` na něm v Ubuntu 26.04 závisí — jeho purge
  odstraní i `xorg` a `xserver-xorg` a následný `autoremove` může smazat X server.
- Purge `cloud-init` / `apport` / `multipath-tools` / `snapd` odstraní metabalíček `ubuntu-server-minimal`,
  purge `packagekit` odstraní `software-properties-common` (`add-apt-repository`). Skript proto nejdřív
  označí jejich závislosti jako ručně instalované, jinak by je `autoremove` smazal (včetně `openssh-server`).
- `autoremove` skript jen nasimuluje a vypíše seznam — provede se až po potvrzení.
- **Automatické aktualizace (`unattended-upgrades`) standard odstraňuje.** Bezpečnostní opravy pak
  nepřicházejí samy: pravidelně `sudo apt update && sudo apt full-upgrade`.

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
- Výchozích 15 min je málo při dlouhých sezeních. Standard: 3600 min (sjednoceno 2026-10-03).
- Ubuntu 26.04 používá `sudo-rs` — viz poznámky k upgradu (zástupné znaky v sudoers).

### Screenshoty — mate-screenshot zamrzá na "Save" (glycin bug)
- **Příznak:** `Shift+PrtScr` → výběr oblasti proběhne, "Copy to Clipboard" funguje,
  ale kliknutí na "Save" navždy zamrzne (okno lze zavřít křížkem, proces ale běží dál).
- **Příčina:** Na systémech s `gdk-pixbuf >= 2.44` + `glycin-loaders` (např. dev-release
  "resolute") jde ukládání obrázků přes sandboxovaný enkodér `glycin-image-rs`
  (spouštěný přes `bwrap`). Hlavní vlákno a sandboxovaný pomocný proces se navzájem
  zablokují v soukromém D-Bus peer spojení — reálný upstream bug v `libglycin` 2.1.1,
  ne chyba v konfiguraci. Potvrzeno přes `gdb -p <PID> -batch -ex "thread apply all bt"`
  (vyžaduje dočasně `sudo sysctl -w kernel.yama.ptrace_scope=0`, jinak gdb/strace
  nejde k cizímu procesu vůbec připojit).
- **Vedlejší nález:** pokud běží zároveň dvě X session nad stejným `$HOME`
  (např. VNC na `:0` + Chrome Remote Desktop na `:20`), každá má svého vlastního
  `gvfsd-metadata` démona a oba kolidují na sdíleném `~/.local/share/gvfs-metadata/`
  souboru — způsobuje podobné (ale odlišné) zaseknutí. Řeší se buď ukončením
  nadbytečné session, nebo (lépe, bez zásahu do session) nastavením
  `GIO_USE_VFS=local` pro daný nástroj, aby gvfs vůbec nekontaktoval.
- **Oprava:** `steps/09-screenshot-glycin-fix.sh` — přebinduje `Shift+PrtScr` na
  vlastní skript (`~/bin/screenshot-area-safe.sh`), který zachytí oblast přes
  ImageMagick `import` (vlastní PNG enkodér, glycin nepoužívá) a uložení řeší
  přes `zenity` dialog + `mv`. Žádný krok se nedotkne rozbité `gdk-pixbuf`/`glycin`
  cesty.

---

## SSH klíč (jz-work)

Veřejný klíč pro bezhelslový přístup z jz-work:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8uvCPXXbhRZ3dxUpYQf+puT/xa7kogINOp86k7IT+y remote-access
```

---

**Maintainer:** Zdendys79
