# Obnova Claude Code v tmux po restartu

Po restartu nebo výpadku proudu se samy znovu otevřou všechny tmux session, ve kterých běžel
Claude Code — každý ve své složce, se svou konverzací (`--resume <ID>`) a se zapnutým vzdáleným
ovládáním (`--remote-control`). Instaluje krok 10: `sudo bash steps/10-tmux-claude-restore.sh`.

Nasazeno na **JZ-work** (původní verze, skripty v `~` s podtržítky: `tmux_claude_snapshot.py`,
`tmux_claude_restore_plan.py`, `tmux_claude_startup.sh`, `mate_terminal_startup.sh`) a na **Base7**
(od 2026-10-28, verze z tohoto repozitáře v `~/.local/bin`).

## Jak to funguje

| Část | Soubor | Kdy běží |
|---|---|---|
| Snapshot | `~/.local/bin/tmux-claude-snapshot.py` | každých 5 min — `tmux-claude-snapshot.timer` (systemd `--user`) |
| Plán obnovy | `~/.local/bin/tmux-claude-restore-plan.py` | volá ho startup a `cl` |
| Spuštění po startu | `~/.local/bin/tmux-claude-startup.sh` | `tmux-claude-startup.service` (systémová, `User=<uživatel>`) |
| Okna terminálu (jen desktop) | `~/.local/bin/mate-terminal-startup.sh` | XDG autostart `~/.config/autostart/claude-terminals.desktop` |
| Připojení | `cl`, `cl <projekt>` | ručně |

1. **Snapshot** projde všechny tmux panely, najde běžící procesy `claude` a zapíše jejich pracovní
   složku a ID konverzace do `~/.cache/tmux_claude_snapshot.json`. ID je nejnovější přepis
   v `~/.claude/projects/<složka>/*.jsonl` (sedí i po `/resume` nebo `/clear` uvnitř Claude),
   jinak hodnota `--resume` z příkazové řádky.
   **Když žádného Claude nenajde, soubor nepřepíše** — snapshot těsně po startu tak nesmaže
   poslední dobrý stav.
2. **Plán obnovy** z toho udělá seznam session:
   - Claude v `~` → session `claude`, vzdálený název = název stroje (`Base7`, `JZ-work`),
     doprovodná shellová session `sudo`;
   - Claude v jiné složce `<dir>` → session `cl-<dir>`, vzdálený název `<Dir> (<stroj>)`,
     doprovodná session `<dir>`.
   - Název stroje: proměnná `MACHINE_LABEL`, jinak `~/.config/tmux-claude/label`, jinak hostname.
3. **Startup** každou chybějící session vytvoří a **rovnou spustí**
   `claude --dangerously-skip-permissions --resume <ID> --remote-control "<název>"`
   (bez známého ID `--continue`). Existující session přeskočí — počítají se i skupiny session
   (`claude-1`, `cl-parkoviste-6`, které vznikají při připojení přes remote-tmux), takže ho jde
   kdykoli spustit ručně a nic nezdvojí.
4. **Okna terminálu** (jen stroje s MATE): okno 1 = `claude` + všechny `cl-*` jako karty,
   okno 2 = `sudo` + doprovodné shellové session.

## Důležité detaily

- `tmux-claude-startup.service` má `KillMode=process` — tmux server spuštěný z oneshot služby
  musí přežít její dokončení.
- Snapshot timer je uživatelský — vyžaduje `loginctl enable-linger <uživatel>`
  (krok 10 ho zapne), jinak by bez přihlášení neběžel.
- `tmux send-keys -t "=<session>:"` — přesný název session v cíli **musí končit dvojtečkou**,
  samotné `=<session>` tmux odmítne („can't find pane“).
- `tmux has-session -t <název>` bez `=` hledá i podle začátku názvu (`claude` najde `claude-1`) —
  proto startup porovnává přesné názvy session i skupin.
- Zahrnuje se jen Claude; ostatní shellové session (kromě doprovodných) se neobnovují.
- Po upgradu Node.js / Claude Code není potřeba nic měnit — spouští se `~/.local/bin/claude`.

## Ověření a ruční zásahy

```bash
cat ~/.cache/tmux_claude_snapshot.json          # co se obnoví
python3 ~/.local/bin/tmux-claude-restore-plan.py   # plán: session, složka, ID, název, doprovodná
systemctl --user list-timers tmux-claude-snapshot.timer
journalctl -u tmux-claude-startup -b            # co se po startu spustilo
~/.local/bin/tmux-claude-startup.sh             # dospustit chybějící session hned
cl sagu                                         # připojit se ke cl-sagu
```

## Historie

- Dřívější řešení na Base7 (`tmux-save.sh` ručně + `@reboot tmux-restore.sh` v crontabu, příkazy jen
  vepsané bez spuštění) se neosvědčilo: snapshot se nedělal automaticky, takže po výpadku proudu
  2026-10-28 se neobnovilo nic. Nahrazeno tímto řešením.
