# Live Access — Operator Notes

## Current confirmed state

| Field      | Value                          |
|------------|--------------------------------|
| device     | Nothing A059P (Android 16)     |
| state      | armed                          |
| tailscale  | up  tun0  100.123.75.12        |
| sshd       | listening :8022                |
| root       | available (Magisk)             |
| adb        | authorized  100.123.75.12:5555 |
| cockpit    | http://localhost:7779          |
| stream     | HLS on-demand via cockpit (two-column layout, right panel) |

---

## Quick launch

```bash
up-n
```

One command: Tailscale up → cockpit started → ADB connected → HLS stream
started → browser opens at localhost:7779.

Alias lives in `~/.zshrc`, logic lives in `mac-side/up`.

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

Start manually (if not using `up-n`):
```bash
cd ~/Desktop/nothinghere
source profiles/nothing-3a-pro.conf
nohup env NHERE_HOST_IP="$NHERE_HOST_IP" \
  deno run --allow-net --allow-run --allow-read --allow-env \
  mac-side/cockpit > /tmp/cockpit.log 2>&1 &
```

Layout: two-column. Left panel: status + controls. Right panel: phone screen embed.

Routes:
| Route           | Action                                        |
|-----------------|-----------------------------------------------|
| `/`             | cockpit UI — two-column, auto-refresh 15s     |
| `/status.json`  | structured JSON                               |
| `/ping`         | SSH reachability check                        |
| `/open-screen`  | scrcpy native window launch                   |
| `/close-screen` | SIGTERM relay                                 |
| `/record`       | scrcpy --no-display --record → recordings/    |
| `/stop-record`  | SIGTERM recording                             |
| `/screenshot`   | adb screencap → recordings/shot-TIMESTAMP.png |
| `/stream-start` | start HLS stream (adb+ffmpeg→/tmp/nhere-stream/) |
| `/stream-stop`  | stop stream, clean segments                   |
| `/stream.json`  | `{ alive: bool, pid: number }` |
| `/stream/*`     | serve HLS segments (.m3u8 + .ts)              |

Browser keyboard shortcuts:
| Key | Action |
|---|---|
| `S` | open screen relay |
| `R` | record |
| `P` | ping |
| `X` | close screen |
| `V` | start stream |
| `Q` | stop stream |
| `Space` | refresh |

Hammerspoon system hotkeys:
| Hotkey        | Action           |
|---------------|------------------|
| Cmd+Alt+0     | open cockpit     |
| Cmd+Alt+9     | open screen      |
| Cmd+Alt+8     | screenshot       |
| Cmd+Alt+7     | start recording  |

---

## Embedded phone screen stream

The stream is Mac-side only. `adb exec-out screenrecord` pipes h264 to ffmpeg
which outputs HLS segments to `/tmp/nhere-stream/`. Cockpit serves them at
`/stream/*`. Browser plays via hls.js (CDN-loaded).

Stream process:
```
adb exec-out screenrecord --output-format=h264 --time-limit=3600 -
  | ffmpeg -re -i pipe:0 -c:v libx264 -preset ultrafast -tune zerolatency
           -vf scale=540:-2 -f hls -hls_time 1 -hls_list_size 4
           -hls_flags delete_segments+omit_endlist
           /tmp/nhere-stream/stream.m3u8
```

Start: `up-n` (auto) or cockpit "Start Stream" button or `V` key.
Stop: cockpit "Stop" button or `Q` key.
Fullscreen: click ⛶ fullscreen button (bottom-right of video panel).

---

## scrcpy

Connects over ADB TCP at the Tailscale IP.
Keyboard and mouse pass through to device by default.
Recording saves to `recordings/rec-TIMESTAMP.mp4`.
Screenshots save to `recordings/shot-TIMESTAMP.png`.

---

## Detection notes

| Tool      | Available | Notes                                               |
|-----------|-----------|-----------------------------------------------------|
| ifconfig  | yes       | no per-interface arg — use `ifconfig` + awk flag    |
| ip        | no        | not in this Termux install                          |
| ss        | no        | not in this Termux install                          |
| netstat   | yes       | `-an` only                                          |
| pgrep     | yes       | used for sshd detection                             |
| timeout   | yes       | present                                             |
| dumpsys   | no        | not in Termux PATH — wakelock deferred              |
| tailscale | yes (bin) | CLI cannot reach Android VPN daemon from Termux     |

---

## Magisk module state (last checked 2026-05-18)

| Module | Flag |
|---|---|
| np3a_control | ✓ clean |
| playintegrityfix | ✓ clean |
| tricky_store | ✓ clean |
| zygisksu | ✓ clean |
| zygisk_lsposed | ✓ clean |
| zygisk-detach | ✓ clean |
| SH_Blocker | ✓ clean |
| ViPER4Android-RE-Fork | ✓ clean |
| iOS_Emoji | ✓ clean |
| ace_sysctl_tune | ⚠ REMOVE flag set — will be deleted next reboot |
| zn_magisk_compat | ⚠ REMOVE + DISABLE — will be deleted next reboot |

`ace_sysctl_tune` and `zn_magisk_compat` are flagged for removal. This is expected if
they were marked in Magisk Manager. They will be gone after the next reboot.
All core modules (np3a_control, playintegrityfix, tricky_store, lsposed, zygisksu) are clean.

---

## What's deferred

- `wakelock` — needs `su -c dumpsys power` path
- history scrub — real IP + username in early commits (private repo, low urgency)
- service restart commands — `sshd`, tailscale restart via ctl
- `rescue` mode — documented but not wired

## Constraints (DOCTRINE)

- Owner-enrolled administration only
- ADB debug path closes after use — not always-on at boot
- Stream is on-demand, not persistent
- No persistent shell sessions automated
- All operator values in gitignored local profile only
