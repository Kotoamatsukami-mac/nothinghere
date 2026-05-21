# Live Access — Operator Notes

## Current confirmed state

| Field     | Value                           |
|-----------|---------------------------------|
| device    | Nothing A059P (Android 16)      |
| module    | nhere v2.1 (Magisk)             |
| tailscale | up  tun0  (see profile)         |
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
| `nhere status`   | state, desired_state, root, battery, thermal, sshd (port-checked), Tailscale, wakelock, ADB |
| `nhere arm`      | start Termux sshd, acquire wakelock, report Tailscale; write desired_state=armed and state=armed |
| `nhere disarm`   | release wakelock; stop sshd scoped to Termux user (2s delay, listener + sessions); keep Tailscale up; write desired_state=disarmed |
| `nhere toggle`   | flips desired_state — arm if disarmed, disarm if armed |
| `nhere restart`  | disarm → 3s → arm                                  |
| `nhere relay-prep` | enable ADB TCP :5555 on demand                   |

`desired_state` persists across reboots. On boot, `service.sh` reads
`/data/adb/nhere/desired_state` and performs a one-shot `nhere arm` if it
contains `armed`. There is no resident daemon — service.sh exits immediately
after the one-shot call.

### Future external triggers

A future button-mapper app, Tasker job, Quick Settings tile, or Shortcuts
intent can call the same commands from any rooted shell context:

```
su -c 'nhere toggle'
su -c 'nhere arm'
su -c 'nhere disarm'
```

The Magisk module deliberately ships **no** button listener, getevent loop,
SystemUI patch, power-menu hook, or polling daemon. Any "double-press" or
"power menu Live/Off" UX must be implemented as an external wrapper that
shells out to `nhere`.

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
  --allow-write=/tmp/nhere-stream \
  mac-side/cockpit > /tmp/cockpit.log 2>&1 &
```

Routes:
| Route           | Action                                        |
|-----------------|-----------------------------------------------|
| `/`             | cockpit UI — LIVE/DEAD/DEGRADED state visual  |
| `/status.json`  | structured JSON                               |
| `/ping`         | SSH reachability check                        |
| `/open-screen`  | scrcpy launch (--stay-awake --max-size 1280 --video-bit-rate 8M) |
| `/close-screen` | SIGTERM relay                                 |
| `/record`       | scrcpy --no-display --record → recordings/    |
| `/stop-record`  | SIGTERM recording                             |
| `/screenshot`   | adb screencap → recordings/shot-TIMESTAMP.png |
| `/take-screenshot` | adb exec-out screencap → ~/Desktop/NothingCaptures/Screenshots/screenshot_TIMESTAMP.png; returns JSON `{ ok, message, file, url, state }` |
| `/stream-start` | start HLS stream                              |
| `/stream-stop`  | stop stream, clean segments                   |
| `/stream.json`  | `{ alive: bool, pid: number }`                |
| `/stream/*`     | serve HLS segments                            |
| `/pull-recordings` | adb pull /sdcard/Movies/ → ~/Desktop/NothingCaptures/Movies |
| `/pull-screenshots`| adb pull /sdcard/Pictures/Screenshots/ → ~/Desktop/NothingCaptures/Screenshots |
| `/pull-downloads`  | adb pull /sdcard/Download/ → ~/Desktop/NothingCaptures/Download |
| `/open-captures`   | open ~/Desktop/NothingCaptures in Finder      |
| `/open-screenshots`| open ~/Desktop/NothingCaptures/Screenshots in Finder |
| `/captures/*`      | read-only static serving of files under ~/Desktop/NothingCaptures (traversal-blocked, HTTP Range supported) |

Cockpit visual states:
- **LIVE** — `state=armed`. Neon green sweep bar, ambient glow, green badge.
- **OFF** — `state=disarmed`. Dim bar, muted badge.
- **UNKNOWN** — unreachable or any other value. Amber/orange.

Sidebar sections: **live control** (State, Screen, Stream, Refresh/Ping) →
**capture + pull** (Record, Files) → **device status** (inline state badges
for screen/stream/recorder).

### Right preview rail

The layout is a 3-column grid: left controls/sidebar → centre live stream →
right preview rail. The rail holds three bordered cards:

- **Phone Screen Preview** — phone-framed device card. Mirrors the HLS stream
  in a small framed `<video>`. Frame border is neon green when the stream is
  live, muted zinc when offline. Top-right badge shows LIVE / OFFLINE /
  UNKNOWN. *Open Screen Window* launches native scrcpy via `/open-screen`
  (scrcpy is never embedded in the browser). Shows a clean `Stream offline`
  placeholder when no stream is running.
- **Recording Preview** — shows the latest file in
  `~/Desktop/NothingCaptures/Movies` (populated by `/pull-recordings`):
  filename, timestamp, size, and idle/recording status. Browser-playable
  files (mp4/webm/mov) render an inline `<video>`; otherwise it shows
  `No recording loaded yet`.
- **Screenshot Preview** — *Take Screenshot* calls `/take-screenshot`, which
  runs `adb exec-out screencap -p` straight to the Mac capture folder and
  returns JSON. On success the card's image updates immediately (cache-busted
  URL) with no page reload, and the JSON result is echoed to the Console
  debug panel. *Open Screenshot Folder* opens the Screenshots folder. On page
  load the card shows the most recent screenshot if one exists.

The stream LIVE/OFFLINE state is polled every 2s via the cheap `/stream.json`
pid check, which keeps the rail badges and mirrored video honest without a
heavy SSH round trip.

Browser keyboard shortcuts:
| Key   | Action          |
|-------|-----------------|
| `L`   | LIVE (arm)      |
| `O`   | OFF (disarm)    |
| `T`   | status          |
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
| nhere v2.1         | ✓ clean   |
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
| pgrep     | yes       | used as fallback for sshd detection (scoped `-u <user>`) |
| dumpsys   | root only | wakelock via `su -c dumpsys power`               |
| tailscale | bin only  | CLI cannot reach Android VPN daemon from Termux  |
| ss        | root shell| primary sshd detection (port-state); `netstat` is fallback |

## Deferred

- `wakelock` real value — `su -c dumpsys power` path works in nhere now
- Double-power-press plugin — **out of scope** for the Magisk module. Future
  external wrappers (Button Mapper, Key Mapper, Quick Settings, Tasker) can
  call `su -c 'nhere toggle'` from any rooted shell. No SystemUI patch, no
  power-menu hook, no getevent watcher, no root daemon will be added here.
- `rescue` mode — documented not wired
- History scrub — real values in early commits (private repo, low urgency)
