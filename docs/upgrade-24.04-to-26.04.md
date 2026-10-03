# Upgrade Ubuntu 24.04 → 26.04 LTS — zkušenosti a rizika

Ověřeno na serveru **base7** (Apache + PHP, MariaDB, Node.js/PM2, Syncthing, Tailscale, herní servery),
upgrade 2026-10-02 na **26.04.1 LTS** (jádro 7.0). Pořadí odpovídá tomu, jak se problémy objevovaly.

---

## 1. Před upgradem

- `do-release-upgrade` pustí LTS → LTS až po vydání **26.04.1** (`Supported: 1` v
  `https://changelogs.ubuntu.com/meta-release-lts`). Na produkci nevynucovat přes `-d`.
- Nejdřív `sudo apt update && sudo apt full-upgrade` a **restart**. Při čekajícím restartu
  (`/var/run/reboot-required`) se `do-release-upgrade` odmítne spustit.
- Restart ukončí i tmux session a běžící Claude Code — předem si uložit rozpracovanou práci.

## 2. Během upgradu — dotazy na konfigurační soubory

Výchozí odpověď (**ponechat lokální verzi**) byla ve všech případech správná:

| Soubor | Proč ponechat lokální |
|---|---|
| `/etc/ssh/sshd_config` | vlastní zabezpečení (`PermitRootLogin no`, `MaxAuthTries`, `MaxStartups` …) |
| `/etc/apache2/envvars` | načítá `envvars.local` s hesly k DB — nová verze ho neobsahuje → **všechny PHP weby by spadly** |
| `/etc/mysql/mariadb.conf.d/50-server.cnf` | `max_allowed_packet`, `utf8mb4` charset/collation, SSL |
| `/etc/apt/apt.conf.d/50unattended-upgrades` | vlastní `Allowed-Origins` |

Tip: vlastní nastavení dávat do samostatných souborů (`sshd_config.d/99-*.conf`, `conf.d/`),
pak se upgrade na nic neptá.

## 3. „Remove obsolete packages?“ → odpovědět **N**

Upgrade vypne repozitáře třetích stran a jejich balíčky pak považuje za zastaralé.
Na seznamu ke smazání (145 balíčků) bylo i: **PHP z PPA ondrej** (všechny weby), **nodejs** (PM2 služby),
**tailscale** (vzdálený přístup!), syncthing, Chrome, a všechna stará jádra (žádná záloha pro případ,
že nové jádro nenaběhne). Úklid udělat až po restartu a obnovení repozitářů.

## 4. Po upgradu — repozitáře třetích stran

- Repozitáře jsou `Enabled: no`, soubory `.list` (syncthing, tailscale, microsoft) se nepodařilo
  převést na `.sources` a zůstaly jako `*.list.disabled` — nutno přepsat ručně do formátu deb822.
- **PPA ondrej/php pro 26.04 (resolute) neexistuje** (stav 10/2026). Řešení: přejít na PHP z Ubuntu
  (`php8.5`, `--allow-downgrades`, `-o Dpkg::Options::=--force-confold`), PPA odstranit.

## 5. `sudo-rs` místo `sudo`

Ubuntu 26.04 používá **sudo-rs**. Ten **nepovoluje zástupné znaky uvnitř argumentů** v sudoers
(např. `/bin/rm -f /opt/app/mods/*`) — taková pravidla ignoruje a při každém `sudo` vypisuje varování.
Samostatná `*` na konci (= libovolné argumenty) projde.

Pozorováno: `sudo bash skript.sh | grep … | tail` se skriptem volajícím `apt-get purge` — `apt-get` se
po dokončení dpkg zastavil ve stavu `T` (stopped) a skript visel. Pomohlo Ctrl+Z,
`sudo kill -CONT <pid>; fg`. Příčina neověřena (sudo-rs + roura, nebo hook `DPkg::Post-Invoke`);
apt přes sudo raději spouštět bez roury.

Řešení wildcard pravidel: místo nich **validující obalovací skript** (root:root 755) v `/usr/local/bin`,
který si sám kontroluje argumenty, a v sudoers povolit jen jeho. Z PHP volat přes `sudo -n` a
`escapeshellarg()`. Wildcard pravidla byla navíc nebezpečná (`*` povolí i `../`).

## 6. Python 3.12 → 3.14 rozbije všechna venv

Venv odkazuje na systémový `python3`, ten je teď 3.14 a balíčky nainstalované pro 3.12 nevidí.
Najít všechna: `find / -xdev -name pyvenv.cfg`. Nejzávažnější:

- **`/opt/certbot`** (pip instalace certbotu) — po upgradu nefunguje, obnova certifikátu tiše selhává.
  Přestavba: `python3 -m venv /opt/certbot` + `pip install certbot certbot-apache`
  (`certbot-apache` potřebuje `libaugeas-dev` ke kompilaci).
- Venv nelze přejmenovat (`mv venv.new venv`) — skripty v `bin/` mají absolutní cestu v shebangu.
  Stavět přímo na cílovém místě.
- Knihovny bez podpory 3.14 (např. **DeepFilterNet** potřebuje `torchaudio < 2.9`, wheels pro 3.14
  existují až od 2.9): použít **`uv`** se spravovaným Pythonem 3.12
  (`uv venv --python 3.12`) — nezávislé na systémovém Pythonu, další upgrade OS ho nerozbije.

## 7. Apache a PHP

- `apache2.service` má nově `MemoryDenyWriteExecute=yes` → PHP hlásí
  `preg_match(): Allocation of JIT memory failed`. Řešení bez oslabení zabezpečení:
  `pcre.jit=0` v `/etc/php/8.5/apache2/conf.d/99-pcre-jit.ini`.
- `PrivateTmp=true` — PHP v Apache má vlastní `/tmp` (procesy spuštěné přes `sudo` z PHP ho sdílejí).

## 8. MariaDB 11.8

Výchozí datový adresář je nově `/var/lib/mariadb`. Instalační skript při upgradu sám vytvoří
`mariadb.conf.d/99-legacy-datadir.cnf`, takže data zůstanou v `/var/lib/mysql`. Po upgradu ověřit.

## 9. Ostatní

- Uživatelské systemd služby, které byly kdysi zapnuté (např. druhá instance Syncthingu), se po upgradu
  znovu rozběhnou — nežádoucí služby `systemctl --user mask`.
- `/etc/apt/apt.conf.d/zzzz-temp-installer-unattended-upgrade` je pozůstatek instalátoru — lze smazat.
- Obnova tmux session po restartu: snapshot (`tmux list-panes -a`) + `@reboot` skript v crontabu,
  příkazy jen vepsat (`send-keys -l`), nespouštět.
