# Live Access — Operator Notes

## Current confirmed state

| Field     | Value                           |
|-----------|---------------------------------|
| device    | Nothing A059P (Android 16)      |
| module    | nhere v2.0 (Magisk)             |
| tailscale | up  tun0  100.123.75.12         |
| sshd      | listening :8022                 |
| root      | available (Magisk)              |
| adb       | on-demand via relay-prep        |
| cockpit   | http://localhost:7779           |
| stream    | HLS on-demand via cockpit       |

## Quick launch

```bash
~/Desktop/nothinghere/mac-side/up-n
```

Tailscale up → cockpit started → ADB connected → stream started → browser opens.

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
./mac-side/ctl arm
./mac-side/ctl disarm
./mac-side/ctl toggle
./mac-side/ctl restart
./mac-side/ctl relay-prep
```

## Phone-side nhere commands

All run via `su -c nhere <cmd>` in Termux or SSH:

| Command          | Effect                                              |
|------------------|-----------------------------------------------------|
| `nhere status`   | root, battery, thermal, sshd, Tailscale, wakelock, ADB |
| `nhere arm`      | start sshd, acquire wakelock, report Tailscale, write state=armed |
| `nhere disarm`   | release wakelock, stop sshd (2s delay), keep Tailscale up, write state=disarmed |
| `nhere toggle`   | arm if disarmed, disarm if armed                   |
| `nhere restart`  | disarm → 3s → arm                                  |
| `nhere relay-prep` | enable ADB TCP :5555 on demand                   |

## ADB

On-demand only. Not enabled at boot by default.

```bash
# via nhere on phone:
su -c 'nhere relay-prep'

# then on Mac:
source profiles/nothing-3a-pro.conf
adb connect "$NHERE_HOST_IP:5555"
```

Or set `NHERE_ADB_TCP=1` in `/data/adb/nhere/env` to persist at boot.

## Cockpit

Start manually:
```bash
cd ~/Desktop/nothinghere
source profiles/nothing-3a-pro.conf
nohup env NHERE_HOST_IP="$NHERE_HOST_IP" NHERE_USER="$NHERE_USER" \
  NHERE_PORT="$NHERE_PORT" NHERE_KEY="$NHERE_KEY" \
  deno run --allow-net --allow-run --allow-read --allow-env \
  mac-side/cockpit > /tmp/cockpit.log 2>&1 &
```

Routes:
| Route           | Action                                        |
|-----------------|-----------------------------------------------|
| `/`             | cockpit UI — LIVE/DEAD/DEGRADED state visual  |
| `/status.json`  | structured JSON                               |
| `/ping`         | SSH reachability check                        |
| `/open-screen`  | scrcpy native window launch                   |
| `/close-screen` | SIGTERM relay                                 |
| `/record`       | scrcpy --no-display --record → recordings/    |
| `/stop-record`  | SIGTERM recording                             |
| `/screenshot`   | adb screencap → recordings/shot-TIMESTAMP.png |
| `/stream-start` | start HLS stream                              |
| `/stream-stop`  | stop stream, clean segments                   |
| `/stream.json`  | `{ alive: bool, pid: number }`                |
| `/stream/*`     | serve HLS segments                            |

Cockpit visual states:
- **LIVE** — armed. Yellow lightning bar, glow badge, bolt SVG overlay.
- **DEGRADED** — reachable but sshd/Tailscale/wakelock missing. Orange.
- **DEAD** — disarmed or unreachable. Dim, frozen.

Browser keyboard shortcuts:
| Key   | Action          |
|-------|-----------------|
| `S`   | open screen relay |
| `R`   | record          |
| `P`   | ping            |
| `X`   | close screen    |
| `V`   | start stream    |
| `Q`   | stop stream     |
| Space | refresh         |

## Magisk module state (last verified 2026-05-19)

| Module             | Flag      |
|--------------------|-----------|
| nhere v2.0         | ✓ clean   |
| playintegrityfix   | ✓ clean   |
| tricky_store       | ✓ clean   |
| zygisksu           | ✓ clean   |
| zygisk_lsposed     | ✓ clean   |
| zygisk-detach      | ✓ clean   |
| SH_Blocker         | ✓ clean   |
| ViPER4Android-RE   | ✓ clean   |
| iOS_Emoji          | ✓ clean   |

Legacy module `np3a_control` replaced by `nhere`. Old zip `n.zip` deleted.

## Detection notes (Termux)

| Tool      | Available | Notes                                            |
|-----------|-----------|--------------------------------------------------|
| ifconfig  | yes       | no per-interface arg — use awk flag              |
| pgrep     | yes       | used for sshd detection                          |
| dumpsys   | root only | wakelock via `su -c dumpsys power`               |
| tailscale | bin only  | CLI cannot reach Android VPN daemon from Termux  |
| ss/ip     | no        | not in this Termux install                       |

## Deferred

- `wakelock` real value — `su -c dumpsys power` path works in nhere now
- Double-power-press plugin — optional Nothing-specific, not in core
- `rescue` mode — documented not wired
- History scrub — real values in early commits (private repo, low urgency)
