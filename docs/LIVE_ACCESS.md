# Live Access — Operator Notes

## Current confirmed state

| Field      | Value                        |
|------------|------------------------------|
| device     | Nothing A059P (Android 16)   |
| state      | armed                        |
| tailscale  | up  tun0  100.123.75.12      |
| sshd       | listening :8022              |
| root       | available (Magisk)           |
| adb        | authorized  100.123.75.12:5555 |
| cockpit    | http://localhost:7779        |

---

## SSH into phone

```bash
cd ~/Desktop/nothinghere
source profiles/nothing-3a-pro.conf
ssh -i "$NHERE_KEY" -p "$NHERE_PORT" "$NHERE_USER@$NHERE_HOST_IP"
```

Via ctl (preferred):
```bash
./mac-side/ctl ping
./mac-side/ctl status
```

---

## ADB

ADB authorized via SSH+root key push to `/data/misc/adb/adb_keys`.
No USB required. Connects over Tailscale.

```bash
source profiles/nothing-3a-pro.conf
adb connect "$NHERE_HOST_IP:5555"
adb devices
```

---

## Cockpit

Start:
```bash
cd ~/Desktop/nothinghere
source profiles/nothing-3a-pro.conf
nohup env NHERE_HOST_IP="$NHERE_HOST_IP" \
  deno run --allow-net --allow-run --allow-read --allow-env \
  mac-side/cockpit > /tmp/cockpit.log 2>&1 &
```

Routes:
| Route           | Action                                        |
|-----------------|-----------------------------------------------|
| `/`             | status page — auto-refresh 10s                |
| `/status.json`  | structured JSON                               |
| `/ping`         | ctl ping                                      |
| `/open-screen`  | safe scrcpy launch — checks relay PID + ADB   |
| `/close-screen` | SIGTERM relay                                 |
| `/record`       | scrcpy --no-display --record → recordings/    |
| `/stop-record`  | SIGTERM recording                             |
| `/screenshot`   | adb screencap → recordings/shot-TIMESTAMP.png |

Browser keyboard shortcuts: `S` screen · `R` record · `P` ping · `X` close · `Space` refresh

Hammerspoon system hotkeys:
| Hotkey        | Action           |
|---------------|------------------|
| Cmd+Alt+0     | open cockpit     |
| Cmd+Alt+9     | open screen      |
| Cmd+Alt+8     | screenshot       |
| Cmd+Alt+7     | start recording  |

---

## scrcpy

Connects over ADB TCP at `100.123.75.12:5555`.
Keyboard and mouse pass through to device by default.
Recording saves to `recordings/rec-TIMESTAMP.mp4`.
Screenshots save to `recordings/shot-TIMESTAMP.png`.

---

## Detection notes (important for future patches)

| Tool      | Available | Notes                                               |
|-----------|-----------|-----------------------------------------------------|
| ifconfig  | yes       | no per-interface arg — use `ifconfig` + awk flag    |
| ip        | no        | not in this Termux install                          |
| ss        | no        | not in this Termux install                          |
| netstat   | yes       | `-an` only — Android blocks /proc/net without root  |
| pgrep     | yes       | used for sshd detection                             |
| timeout   | yes       | present — used in root_state                        |
| dumpsys   | no        | not in Termux PATH — wakelock deferred              |
| tailscale | yes (bin) | CLI cannot reach Android VPN daemon IPC from Termux |

Tailscale detected via `tun0` interface, not CLI.
sshd detected via `pgrep -x sshd`, not netstat.
PATH bootstrap required at top of agent for non-interactive SSH sessions.

---

## What's deferred

- `wakelock` — needs `su -c dumpsys power` path or `/proc/wakelocks` read
- history scrub — real IP + username in commits a87489d and 3838b44 (private repo, low urgency)
- service restart commands — `sshd`, tailscale restart via ctl (next surface)
- `rescue` mode — manual recovery path documented but not wired

## Constraints (DOCTRINE)

- Owner-enrolled administration only — not a relay, not a backdoor
- ADB debug path closes after use — not always-on
- No persistent shell sessions automated
- All operator values in gitignored local profile only
