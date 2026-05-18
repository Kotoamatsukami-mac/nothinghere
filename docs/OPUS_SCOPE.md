# OPUS BUILD SCOPE — nothinghere v1.1
# Generated: 2026-05-18 | Status: WRITE ONLY — do not execute

---

## Objective

Two deliverables. Both must leave the existing working cockpit, agent, and ctl
untouched unless a change is explicitly listed below.

---

## Deliverable 1 — `up-n` zsh alias

### What it does (in order)

1. Check if Tailscale is already up on Mac (`tailscale status` exit 0 = already up).
   If not up, run `tailscale up` and wait for it to confirm connected (poll
   `tailscale status --json` until `BackendState == "Running"`, max 15s, print dots).

2. Check if the nothinghere cockpit is already running on :7779
   (`curl -s --max-time 1 http://localhost:7779/status.json`).
   If not running, start it in the background:
   ```
   cd ~/Desktop/nothinghere
   source profiles/nothing-3a-pro.conf
   nohup env NHERE_HOST_IP="$NHERE_HOST_IP" \
     deno run --allow-net --allow-run --allow-read --allow-env \
     mac-side/cockpit > /tmp/cockpit.log 2>&1 &
   ```
   Wait for cockpit to answer (poll /status.json, max 8s, print dots).

3. Ensure ADB is connected to the phone over Tailscale:
   ```
   adb connect $NHERE_HOST_IP:5555
   ```
   (non-fatal if it fails — print warn and continue)

4. Start the embedded screen stream (see Deliverable 2 — stream launcher section).
   This is the `nhere-stream` process. If already running, skip silently.

5. Open the cockpit in the default browser:
   ```
   open http://localhost:7779
   ```

6. Print a one-line status summary to terminal:
   ```
   nothinghere ↗  cockpit :7779  stream :7780  phone armed
   ```

### Alias definition

Add to `~/.zshrc` — idempotent (check for existing alias before inserting):

```zsh
alias up-n='source ~/Desktop/nothinghere/mac-side/up'
```

The actual logic lives in `mac-side/up` (a bash script in the repo), not inline
in .zshrc. This keeps .zshrc clean and makes the logic editable without
re-sourcing the shell.

### File to create: `mac-side/up`

- shebang: `#!/usr/bin/env bash`
- `set -euo pipefail` OFF for this script — individual steps are fault-tolerant,
  a failed ADB connect must not abort the whole sequence
- Source `profiles/nothing-3a-pro.conf` from REPO_ROOT
- Each step prints a short prefix: `[tailscale]`, `[cockpit]`, `[adb]`, `[stream]`, `[open]`
- On success each prefix gets a `✓`. On warn/skip: `~`. On fail: `✗` (non-fatal).
- Whole script should complete in under 20s on a warm system (Tailscale already up)

---

## Deliverable 2 — Phone screen embedded in cockpit web GUI

### Stream architecture

Mac-side ffmpeg pulls h264 from the phone via adb and publishes HLS segments
to a temp directory. The Deno cockpit serves that directory as static files.
The browser loads hls.js from CDN and plays the stream in a `<video>` tag
embedded in the cockpit page.

No new ports. No new services. The cockpit already runs on :7779 — it gains
two new routes: `/stream/*` (static HLS file serving) and `/stream-start` /
`/stream-stop` (lifecycle control).

### Stream process (Mac-side, managed by cockpit)

```bash
adb -s ${ADB_SERIAL} exec-out screenrecord \
  --output-format=h264 --time-limit=3600 - \
| ffmpeg -re -i pipe:0 \
    -c:v libx264 -preset ultrafast -tune zerolatency \
    -vf scale=540:-2 \
    -f hls \
    -hls_time 1 \
    -hls_list_size 4 \
    -hls_flags delete_segments+omit_endlist \
    /tmp/nhere-stream/stream.m3u8
```

- Output dir: `/tmp/nhere-stream/` — created by cockpit before spawn
- PID tracked in cockpit memory as `streamPid` (same pattern as `relayPid`)
- `scale=540:-2` — half-res, even height, keeps bitrate low for LAN loopback

### New cockpit routes

| Route | Action |
|---|---|
| `/stream-start` | kill existing streamPid if any, mkdir /tmp/nhere-stream, spawn ffmpeg pipe, return `ok pid=N` |
| `/stream-stop` | SIGTERM streamPid, clear /tmp/nhere-stream/*.ts *.m3u8, return `stopped` |
| `/stream/*` | serve files from `/tmp/nhere-stream/` — set `Cache-Control: no-cache` on .m3u8, short cache on .ts |
| `/stream.json` | `{ alive: bool, pid: number|null }` |

### HTML changes to cockpit

Add a new section between "screen relay" and "controller":

```
PHONE SCREEN
[ embedded <video> or "stream offline" placeholder ]
[ start stream ]  [ stop stream ]
```

The `<video>` element:
- `autoplay muted playsinline` — required for browser autoplay policy
- hls.js loaded from `https://cdn.jsdelivr.net/npm/hls.js@latest/dist/hls.min.js`
- If `Hls.isSupported()` → use hls.js with `src = /stream/stream.m3u8`
- Else if native HLS (`video.canPlayType('application/vnd.apple.mpegurl')`) → set src directly (Safari)
- If stream is offline: show a dark placeholder div with text "stream offline"
- Video element: `width: 100%`, `border-radius: var(--border-radius)` matching cockpit aesthetic
- Match cockpit dark theme: `background: #080610`, no white flash

### State tracking in cockpit

Add `streamPid` alongside existing `relayPid` and `recordingPid`.
`streamAlive()` uses same `isPidAlive()` pattern already in cockpit.
`/stream.json` exposes state for `up-n` script to poll.

### up-n stream launcher (part of mac-side/up)

After ADB connect:
```bash
# Start stream if not alive
curl -s --max-time 2 http://localhost:7779/stream.json | grep -q '"alive":true' \
  || curl -s http://localhost:7779/stream-start > /dev/null
```

---

## Files to create / modify

| File | Action |
|---|---|
| `mac-side/up` | CREATE — the launcher script |
| `~/.zshrc` | APPEND alias (idempotent) |
| `mac-side/cockpit` | MODIFY — add stream routes + HTML section |
| `docs/LIVE_ACCESS.md` | UPDATE — add stream + up-n to operator notes |

## Files NOT to touch

| File | Reason |
|---|---|
| `phone-side/agent` | no phone-side work in this scope |
| `mac-side/ctl` | no new ctl commands in this scope |
| `profiles/*` | no profile schema changes |
| `DOCTRINE.md` | updated separately, not by build agent |
| `RUNBOOK.md` | updated separately |

---

## Constraints (from DOCTRINE)

- No hardcoded IPs in new files — read from profile only
- `up-n` must be fault-tolerant per step — one broken step must not kill the sequence
- Stream process is NOT always-on — it starts on demand via `up-n` or cockpit button
- Stream stops when cockpit stops (process tree)
- No new external dependencies beyond hls.js (CDN, already CSP-compatible at cdn.jsdelivr.net)
- ADB debug path is opened on demand, not at boot
- No new ports — stream files served through existing :7779

---

## Acceptance criteria

1. `up-n` in any terminal → within 20s: Tailscale confirmed, cockpit running, browser
   opens at localhost:7779, phone screen visible in the page.
2. Refreshing the cockpit page shows the live phone screen without re-running `up-n`.
3. "stop stream" button kills ffmpeg, video section shows "stream offline".
4. "start stream" button in cockpit restarts the stream without touching the terminal.
5. If phone is unreachable, stream section shows "stream offline" — cockpit does not crash.
6. `up-n` is idempotent — running it twice does not spawn duplicate processes.
7. All existing cockpit routes (ping, status, open-screen, record, screenshot) continue
   to work exactly as before.

---

## What Opus should NOT do

- Do not refactor the whole cockpit. Surgical additions only.
- Do not change the cockpit aesthetic — match existing dark purple theme exactly.
- Do not add a separate web server or new port for the stream.
- Do not touch the Magisk module or phone-side files.
- Do not add audio to the stream — `--no-audio` / muted only.
- Do not use v4l2 (Linux only), WebRTC, or WebSocket for the stream.
- Do not inline the alias logic in .zshrc — it belongs in mac-side/up.
- Do not create duplicate config variables.
- Read the existing cockpit source fully before writing a single line.

---

## Suggested Opus working order

1. Read `mac-side/cockpit` in full.
2. Read `mac-side/ctl` in full.
3. Read `profiles/nothing-3a-pro.conf` (structure only — values are private).
4. Write `mac-side/up`.
5. Modify `mac-side/cockpit` — stream routes first, HTML section second.
6. Append alias to `~/.zshrc`.
7. Verify acceptance criteria 1–7 against the written code before submitting.
