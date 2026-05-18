# nothinghere — Doctrine

`nothinghere` is an owner-enrolled Android control deck. It is designed for
devices the operator owns, has configured, and is allowed to administer.

The project is not a camera script, not a Nothing-only toy, not a GUI
experiment, and not a pile of prototype Termux tricks. It is a clean split
between a controller and a phone engine. The controller decides. The phone
engine stays reachable, reports state, and performs approved local actions on
the enrolled phone.

This doctrine should evolve as the build proves what is true. Update it
whenever the architecture changes. Do not preserve old wording because it
sounded good yesterday. Truth beats decoration.

---

## The shape

There are two real parts.

**A — Mac controller.** For v1 this is a fast terminal launcher plus a
localhost browser cockpit. The launcher (`up-n` alias → `mac-side/up`) brings
up Tailscale, starts the cockpit, connects ADB, starts the phone screen stream,
and opens the browser in one command. The cockpit (`mac-side/cockpit`) is a
Deno HTTP server on :7779. It checks status, sends approved requests, manages
scrcpy as a native window for screen relay, manages an HLS stream of the phone
screen embedded in the cockpit page, and stays out of the way. It does not
become the brain. It calls the controller engine (`mac-side/ctl`).

**B — Phone engine.** On the controlled phone, the engine is the Magisk module
plus the Termux runtime working as one backend layer. Magisk provides
privileged startup, service supervision, and the stable backend container.
Termux provides the live userland tools: `sshd`, wake-lock helpers, shell
scripts, dependencies, status checks, and the local execution surface. Do not
argue Magisk-first versus Termux-first on the controlled phone. Together they
are the phone engine.

The first supported phone profile is the Nothing Phone 3a Pro (A059P,
Android 16). That does not mean the repo is Nothing-only. The long-term shape
is rooted Android with profile zero proven on the Nothing device.

Samsung/S25 controller support is parked for now. Its future shape is simple:
Termux text menu, SSH requests, browser stream fallback, no heavy GUI. Do not
let that distract from v1.

---

## The authority chain

Normal command path:

```
up-n alias → mac-side/up → cockpit :7779 → mac-side/ctl → Tailscale → SSH :8022 → phone engine → approved local action
```

Visual relay path (scrcpy native window):

```
cockpit → adb connect over Tailscale → scrcpy native window → close when finished
```

Embedded stream path (phone screen in browser):

```
cockpit /stream-start → adb exec-out screenrecord | ffmpeg → HLS segments /tmp/nhere-stream/ → cockpit /stream/* → hls.js <video>
```

SSH over Tailscale is the normal command channel. ADB is opened on demand for
relay and stream — not always-on. Always-on wireless debugging at boot is
prototype contamination unless a future explicit profile says otherwise.

The Mac does not host a fake app. The launcher is a shell script. The cockpit
is a Deno server. Both are thin.

Tauri is not banned. Tauri is v2 material only if the terminal controller
proves the control model and a real cockpit becomes worth the weight.

---

## Armed mode

Armed mode is not vibes. It is the phone engine intentionally ready to accept
requests from approved controllers.

State model:

| State | Meaning |
|---|---|
| `disarmed` | phone is not controller-ready |
| `armed` | Tailscale up, SSH reachable, agent answers status, requests can run |
| `relay-active` | scrcpy native relay window is open |
| `stream-active` | HLS stream process is running, screen visible in cockpit |
| `degraded` | reachable but one expected service is weak or missing |
| `rescue` | normal path failed, operator in manual recovery |

Do not build a soft toggle that can strand the operator without a recovery
path. The phone engine needs state-aware start, stop, restart, and status
behaviour before any pretty menu tries to control it.

---

## Command scope

The phone engine exposes a narrow owner-useful surface. Currently implemented:

- `status` — battery, thermal hint, root state, Tailscale state, SSH state, wakelock, armed state
- `ping` — reachability check

Deferred (next surface):
- `restart sshd` — service restart via agent
- `wake` / `sleep` — screen wake lock control
- `wakelock` — real value via `su -c dumpsys power` (currently returns `deferred`)
- `rescue` — manual recovery path

A broad manual shell is not the default product. It can exist as a deliberate
owner recovery path, clearly separated from normal menu actions.

---

## Stream architecture

The embedded screen stream is Mac-side only. No new process runs on the phone.

```
adb exec-out screenrecord --output-format=h264 --time-limit=3600 -
  | ffmpeg -re -i pipe:0 -c:v libx264 -preset ultrafast -tune zerolatency
           -vf scale=540:-2 -f hls -hls_time 1 -hls_list_size 4
           -hls_flags delete_segments+omit_endlist
           /tmp/nhere-stream/stream.m3u8
```

Cockpit serves `/stream/*` as static HLS files. Browser plays via hls.js.
Stream is on-demand — starts with `up-n` or cockpit button, stops with cockpit
button or when cockpit stops. Stream does not run at boot.

---

## Identity and configuration

Do not build around IP addresses. Tailscale hostnames and profile names are the
stable layer. IP addresses are plumbing and must not leak into operator-facing
config.

Private values stay in gitignored local profile: Tailscale IPs, Wi-Fi IPs, SSH
keys, host keys, device serials, local usernames, local paths, tokens, PINs.

Reusable values in profile schema: device family, Android version floor, relay
capability, service requirements, package dependencies, capability flags.

---

## What the prototype taught us

Keep: wakeup polling, PID discipline, service supervision patterns,
identity-based peer discovery, SSH control, Tailscale transport, scrcpy as
external native relay, adb+ffmpeg pipe for browser stream.

Bin or quarantine: hardcoded IPs, hardcoded Termux UID, plaintext PINs, fixed
input nodes, fixed Nothing activities, backup copies as real source, old
roomcam identity, localhost dashboards for no reason, always-on wireless
debugging at boot, duplicate logic across wrappers.

---

## Working rule for agents

Read before patching. Do not create duplicate variables because you did not
search the existing strings. Do not promote a wrapper into the brain because it
is the most visible file. Do not flatten the system into a shopping list.
Follow the architecture: controller decides, phone engine performs, transport
stays private, relay wakes only when needed, stream runs on demand only.

When reality contradicts this doctrine, update the doctrine and explain why.
The project should get sharper as it is built, not more cluttered.

Read `docs/OPUS_SCOPE.md` for the current active build scope before touching
any file.
