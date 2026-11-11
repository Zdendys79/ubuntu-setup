# Ubuntu Setup — Zdendys Standard

Checklist a skripty pro čistou instalaci Ubuntu (desktop i server).
Testováno na Ubuntu 24.04 / 26.04 LTS.

---

## Pořadí kroků

| # | Krok | Skript | Poznámka |
|---|------|--------|----------|
| 1 | Čistění nepotřebných balíčků | `steps/01-cleanup.sh` | cloud-init, apport, snapd, ... |
| 2 | XFCE Desktop | `steps/02-xfce-desktop.sh` | bez snap/firefox, bez LightDM (pro Chrome Remote Desktop) |
| 3 | Google Chrome | `steps/03-chrome.sh` | přes apt repo (auto-update) |
| 4 | Node.js 22 + Claude Code | `steps/04-claude-code.sh` | bez sudo, do ~/.local/bin |
| 5 | Sudo timeout 3600 min | `steps/05-sudo-timeout.sh` | výchozí je 15 min |
| 6 | SSH klíč (jz-work → nový stroj) | `steps/06-ssh-key.sh` | bezhelslový přístup |
| 7 | Česká klávesnice | `steps/07-czech-keyboard.sh` | jen `cz` bez varianty! (`/etc/default/keyboard`) |
| 8 | Vstupní drivery | `steps/08-input-drivers.sh` | pokud nefunguje klávesnice/touchpad |
| 9 | Oprava screenshotů (glycin freeze) | `steps/09-screenshot-glycin-fix.sh` | jen MATE: mate-screenshot zamrzne na Save (bez MATE se přeskočí) |
| 10 | Obnova Claude v tmux po restartu | `steps/10-tmux-claude-restore.sh` | snapshot à 5 min, `--resume` + `--remote-control` |
| 11 | sudo bez hesla přes SSH klíč (LAN, Tailscale) | `steps/11-sudo-trusted-ssh.sh` | PAM kontrola relace, jinak heslo |
| 12 | Chrome Remote Desktop (XFCE) | `steps/12-chrome-remote-desktop.sh` | přihlášení hostitele kódem z remotedesktop.google.com/headless |
| 13 | Tailscale | `steps/13-tailscale.sh` | apt repozitář, přihlášení `sudo tailscale up` |
| 14 | VirtualBox + Extension Pack | `steps/14-virtualbox.sh` | Oracle repozitář (nejnovější 7.2.x), Secure Boot: podpis modulů + zápis klíče na konzoli |
| 15 | Syncthing | `steps/15-syncthing.sh` | apt.syncthing.net (stable-v2), uživatelská služba, GUI jen 127.0.0.1:8384 |
| 16 | Start VM se serverem, uložení stavu při vypnutí | `steps/16-vbox-autostart.sh` | `vbox-autostart.service`, VM označit `--autostart-enabled on` |

Přechod z dřívějšího MATE na XFCE: `sudo bash extras/remove-mate.sh`, pak krok 2 (XFCE), 7 a 12.

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
sudo bash steps/02-xfce-desktop.sh
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

### Obnova Claude Code v tmux po restartu (krok 10)
- Každých 5 minut se ukládá, ve kterých složkách běží Claude a s jakou konverzací; po startu se
  všechny session samy znovu spustí (`--resume <ID> --remote-control "<Projekt> (<stroj>)"`).
- Claude v `~` neukládá důvěru ke složce (dialog by zastavil autostart) — startup proto před
  spuštěním zapíše `hasTrustDialogAccepted` do `~/.claude.json`.
- Podrobně: [`docs/tmux-claude-restore.md`](docs/tmux-claude-restore.md). Připojení: `cl`, `cl <projekt>`.

### sudo bez hesla přes SSH klíč (krok 11)
- Bez hesla jen pro relaci SSH přihlášenou klíčem (nebo certifikátem) z LAN `192.168.7.0/24` nebo
  Tailscale; konzole, desktop, SSH heslem nebo z internetu se ptají dál.
- Ověřuje to PAM pomocník `sudo-trusted-ssh` podle relace logind a záznamu sshd v journalu (nedá
  se podvrhnout). Sítě: `/etc/sudo-trusted-ssh/networks`. Shell v tmux spuštěném z konzole nebo
  služby se ptá na heslo. Podrobně: [`docs/sudo-trusted-ssh.md`](docs/sudo-trusted-ssh.md).

### XFCE a Chrome Remote Desktop (kroky 2 a 12)
- Plocha je XFCE - Chrome Remote Desktop ji doporučuje (MATE dřív, viz `extras/remove-mate.sh`).
  Krok 2 instaluje `xfce4 xfce4-terminal desktop-base dbus-x11 xscreensaver` bez doporučených
  balíčků, tedy bez LightDM: na monitoru není grafické přihlášení, plocha jde přes Chrome Remote
  Desktop (vlastní X session, `/etc/chrome-remote-desktop-session` = `exec /usr/bin/xfce4-session`).
  Výchozí cíl je `multi-user.target`: server běží bez monitoru a periferií, jen se sítí.
- `extras/remove-mate.sh`: purge MATE nechá apt doplnit chybějící virtuální závislosti z GNOME
  (`gnome-shell`, `gdm3`) - skript je hned odstraní (`zip`/`unzip` si ponechá).
- Chrome Remote Desktop 157+ už nevytváří skupinu `chrome-remote-desktop` (krok 12 ji použije, jen
  když existuje). Hostitele přihlásí uživatel sám bez sudo: remotedesktop.google.com/headless ->
  zkopírovaný příkaz pro Debian spustit na stroji, zadat PIN.

### VirtualBox a Secure Boot (krok 14)
- Ubuntu má starší VirtualBox (26.04: 7.2.6) - krok bere nejnovější 7.2.x z repozitáře Oracle
  a k němu stejnou verzi Extension Packu (licence Oracle PUEL: zdarma pro osobní a vzdělávací
  použití). Soubor Extension Packu musí mít původní jméno, jinak VBoxManage hlásí „name mismatch“.
- Se zapnutým Secure Boot se moduly `vboxdrv` načtou jen podepsané klíčem zapsaným v MOK. Krok
  vytvoří klíč `/var/lib/shim-signed/mok/MOK.{priv,der}`, moduly podepíše a připraví zápis
  (`mokutil --import`). Při dalším startu na konzoli stroje: MOK Manager -> Enroll MOK -> Continue
  -> Yes -> heslo -> Reboot. Bez toho VirtualBox žádný VM nespustí.
- Heslo jen z malých písmen bez `y`/`z` (MOK Manager má americkou klávesnici). `MOK_PASSWORD_FILE=`
  ho předá bez dotazu; uložené je na jz-work v `~/.secrets/<stroj>-mok-password.txt`.
- **Klíč zálohovat mimo stroj** (jz-work `~/.secrets/<stroj>-mok/`): reinstalací se soukromý klíč
  ztratí a zapsaný klíč v MOK je pak k ničemu (base8: starý „Nyara VirtualBox“). S
  `MOK_KEY_SRC=<adresář se zálohou>` krok klíč vrátí a nový zápis na konzoli není potřeba.
- Klíč repozitáře musí být čitelný pro všechny (`chmod 644`): apt ho ověřuje jako uživatel `_apt`.

### VM se serverem (krok 16)
- `vbox-autostart.service` (systémová služba, `User=` majitel VM): při startu spustí bez okna
  každý VM s `--autostart-enabled on` (VM s uloženým stavem pokračuje, kde skončil), při vypnutí
  nebo restartu uloží stav všech běžících VM (i bez autostartu) paralelně, limit 15 min.
- `--autostart-delay <s>`: čekání před startem VM (rozložení zátěže při startu).
- Příznak autostartu potřebuje cestu k databázi (`VBoxManage setproperty autostartdbpath`), jinak
  VBoxManage hlásí „The path to the autostart database is not set“ - krok ji nastaví do
  `~/.config/VirtualBox/autostart`. Oracle `vboxautostart-service` se vypíná (bez konfigurace
  nic nedělá, dvojí start nechceme).
- Řazení `After=user.slice`: při vypnutí se VM uloží dřív, než systemd ukončí přihlášené relace
  (VM spuštěný z SSH běží pod VBoxSVC té relace).
- Stav: `vbox-autostart status`. Ověřeno na base8 zkušebním VM: start -> uložení -> obnovení.

### Snapd
- Neinstalovat. Při instalaci plochy (XFCE) použít `--no-install-recommends`.
- Pokud už je nainstalován: viz `steps/01-cleanup.sh`.

### Claude Code
- NIKDY `sudo npm install -g` — vytvoří duplicitní instalaci.
- Správně: `npm config set prefix ~/.local` pak `npm install -g @anthropic-ai/claude-code`.

### Česká klávesnice
- `variant=qwertz` NEFUNGUJE správně v MATE — způsobuje chyby ve vyhledávání.
- Správně: `gsettings set ... layouts "['cz']"` (bez varianty).
- XFCE / Chrome Remote Desktop: krok 7 zapíše `XKBLAYOUT="cz"`, `XKBVARIANT=""` přímo do
  `/etc/default/keyboard` (`localectl set-x11-keymap` pod sudo-rs přes SSH končí „Access denied“).

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
