# nothinghere — Doctrine

`nothinghere` is an owner-enrolled Android control deck. Designed for devices
the operator owns, has configured, and is allowed to administer.

Not a camera script. Not a Nothing-only toy. Not a prototype Termux pile.
A clean split: controller decides, phone engine stays reachable and performs
approved local actions.

Update this doctrine when architecture changes. Do not preserve old wording
because it sounded good. Truth beats decoration.

---

## Shape

Two parts.

**A — Mac controller.**
Terminal launcher + localhost cockpit. `mac-side/up-n` brings Tailscale up,
starts cockpit, connects ADB, starts stream, opens browser. One command.
Cockpit (`mac-side/cockpit`) is a Deno HTTP server on :7779. Checks status,
manages scrcpy relay, manages HLS stream, calls `mac-side/ctl`. Does not
become the brain.

**B — Phone engine.**
Magisk module (`nhere v2.0`) + Termux runtime. Magisk = privileged startup
anchor, clean boot service, command binary in `/system/bin/nhere`. Termux =
live userland: sshd, wakelock helpers, shell execution surface.

No always-on daemons. No key watchers. No getevent loops. No toast spam.
The module is a command engine called on demand only.

First supported profile: Nothing Phone 3a Pro (A059P, Android 16).
Architecture is generic rooted Android. Device-specific behaviour comes
via optional plugins — never baked into core.

---

## Authority chain

Normal:
```
up-n → cockpit :7779 → ctl → Tailscale → SSH :8022 → nhere → approved action
```

Screen relay (on demand):
```
cockpit /open-screen → adb connect (Tailscale) → scrcpy native window → close when done
```

Stream (on demand):
```
cockpit /stream-start → adb exec-out screenrecord | ffmpeg → HLS /tmp/nhere-stream/ → cockpit /stream/* → hls.js
```

SSH over Tailscale = normal command channel.
ADB = opened on demand via `nhere relay-prep` or cockpit. Not always-on at boot.

---

## Phone engine — nhere commands

| Command         | Action                                                         |
|-----------------|----------------------------------------------------------------|
| `nhere status`  | root, battery, thermal, sshd, Tailscale, wakelock, ADB — exits |
| `nhere arm`     | start sshd, acquire wakelock, check Tailscale, write armed     |
| `nhere disarm`  | release wakelock, stop sshd (2s delay), keep Tailscale up, write disarmed |
| `nhere toggle`  | arm ↔ disarm                                                   |
| `nhere restart` | disarm → arm                                                   |
| `nhere relay-prep` | enable ADB TCP :5555 on demand only                         |

Nothing loops. Nothing listens. Called by: Termux terminal, SSH from Mac,
cockpit (future), optional widget/QS tile (future).

---

## Cockpit visual states

| State     | Meaning                                     | Visual                        |
|-----------|---------------------------------------------|-------------------------------|
| LIVE      | armed, sshd up, Tailscale up                | yellow lightning, glow        |
| DEGRADED  | reachable but service missing               | orange bar, dim bolts         |
| DEAD      | disarmed or unreachable                     | dim, frozen, no energy        |

CSS-only, GPU-safe. No polling engine in the animation layer.

---

## State model

| State      | Meaning                                                         |
|------------|-----------------------------------------------------------------|
| `disarmed` | quiet — sshd down, wakelock released, Tailscale left up        |
| `armed`    | controller-ready — sshd up, wakelock held, Tailscale up        |
| `degraded` | reachable but a required service is weak or missing            |
| `rescue`   | manual recovery — normal path failed, operator on device       |

---

## Identity and config

Tailscale hostnames + profile names = stable operator layer.
IPs = plumbing, never in operator-facing config.
Private values (IPs, keys, usernames, paths, PINs) → gitignored local profile only.

---

## Deferred / optional

- Double-power-press toggle → optional Nothing-specific plugin only, calls `nhere toggle`, never in core
- Termux widget / QS tile → optional frontend for `nhere arm` / `nhere disarm`
- Samsung S25 controller → parked, future shape is Termux text menu + SSH + stream fallback
- Tauri cockpit → v2 only if terminal controller proves the model

---

## Working rule for agents

Read before patching. No duplicate variables. No wrapper promoted to brain.
Controller decides. Phone engine performs. Transport stays private.
Relay and stream wake only on demand.

When reality contradicts doctrine, update doctrine and explain why.
The project sharpens as it builds — not clutters.
