# nothinghere

`nothinghere` is an owner-enrolled Android administration deck.

The project has two real parts.

**A — Mac controller.** A terminal launcher alias (`up-n`) plus a localhost
browser cockpit. One command brings up Tailscale, starts the cockpit, connects
ADB, starts the phone screen stream, and opens the browser. The cockpit runs
on :7779 and provides status, screen relay (scrcpy native window), an embedded
live phone screen (HLS in browser), recording, and screenshot.

**B — Phone engine.** On the enrolled phone, the engine is the Magisk module
plus the Termux runtime. The module anchors startup and service supervision.
Termux provides the live userland services and tools. The Nothing Phone 3a Pro
(A059P, Android 16) is profile zero — the first proven device.

---

## Current state (v2.1 — confirmed working)

| Component | Status |
|---|---|
| SSH over Tailscale | ✓ armed and reachable |
| ADB over Tailscale | ✓ authorized, no USB required |
| Cockpit :7779 | ✓ live — status, relay, record, screenshot, stream embed |
| Screen relay (scrcpy) | ✓ native window via cockpit |
| Embedded phone screen (HLS) | ✓ stream embed in cockpit right panel |
| `up-n` alias + launcher | ✓ wired in ~/.zshrc, logic in mac-side/up-n |
| `wakelock` real value | ⏳ deferred |
| `ctl restart / wake / sleep` | ⏳ deferred |
| `rescue` mode | ⏳ deferred |

---

## Quick start (current)

```bash
# Start cockpit manually
cd ~/Desktop/nothinghere
source profiles/nothing-3a-pro.conf
nohup env NHERE_HOST_IP="$NHERE_HOST_IP" NHERE_USER="$NHERE_USER" \
  NHERE_PORT="$NHERE_PORT" NHERE_KEY="$NHERE_KEY" \
  deno run --allow-net --allow-run --allow-read --allow-env \
  --allow-write=/tmp/nhere-stream \
  mac-side/cockpit > /tmp/cockpit.log 2>&1 &
open http://localhost:7779
```

One command (recommended):
```bash
up-n   # Tailscale + cockpit + ADB + stream + browser
```

---

## Repo layout

```
mac-side/
  ctl          — SSH controller (ping, status, arm, disarm, …)
  cockpit      — Deno HTTP server :7779
  up-n         — launcher: Tailscale + cockpit + stream + browser
phone-side/
  magisk-module/
    system/bin/nhere — root command engine (arm/disarm/status/…)
    service.sh       — boot service (one-shot arm restore, no daemon)
    module.prop      — module identity
profiles/
  nothing-3a-pro.conf         — gitignored, your real values
  nothing-3a-pro.example.conf — copy this, fill values
docs/
  LIVE_ACCESS.md   — operator notes, confirmed state
  TERMUX_SETUP.md  — Termux reinstall and cleanup checklist
build.sh     — packages phone-side/magisk-module → nhere-v2.zip
DOCTRINE.md  — architecture doctrine (read before building)
RUNBOOK.md   — setup steps
```

---

## Constraints

- Owner-enrolled administration only — not a relay, not a backdoor
- ADB debug path opens on demand, not at boot
- No hardcoded IPs — profile-scoped values only
- No persistent automated shell sessions
- No Tauri until v1 control model is proven
- Read `DOCTRINE.md` before building or patching anything
