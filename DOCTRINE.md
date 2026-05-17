# nothinghere — Build Doctrine

## Two Parts. No Exceptions.

---

### A — Mac / Laptop (Controller)
The string-pulling station. Source of truth. Where the operator lives.

- Tauri app. Dark mode only. No light mode.
- Neon green = connected / live. Red = offline / dead.
- Live status panel: SSH reachability, Tailscale state, ADB state, stream state.
- All commands fire over SSH → Tailscale → phone.
- Screen relay: operator hits button → scrcpy spawns its own native window.
  scrcpy is the view surface. The Tauri app is the command surface. They are not the same thing.
- ADB TCP enabled on demand for scrcpy only. Torn down when stream ends.
- One `git clone` + one install script. Mac/laptop has root by default. No ceremony.

---

### B — Magisk Module (Phone / Android Side)
The silent backend. One module. Small. No bloat.

**Sole purpose:** guarantee these four services survive boot and stay alive:
1. Termux `sshd` on port `8022`
2. Termux wake lock
3. OpenSSL / crypto deps
4. Tailscale up

**Soft on/off toggle** — runtime start/stop of those four services.
Not the Magisk disable switch (that requires reboot). A live toggle,
controllable from A over SSH. No reboot drawback.

**Command logic lives here too** — the phone-side agent that executes
what A tells it to. Narrow whitelist. Not an open root shell.

**Android 14+ only.** No lower. Non-negotiable.

**Generic Android first.** Nothing Phone 3a Pro is profile zero —
the first polished, confirmed-working profile. Other devices slot in
via capability detection:

- Can it SSH?
- Can it get root?
- Can it run Termux?
- Can it run Tailscale?
- Can it use scrcpy camera mode?
- Does it have camera IDs?
- Can it record screen?
- Can it start services at boot?
- Can it hold wake lock?

---

## Transport Layer

```
Mac/S25 knocks → Tailscale finds → SSH enters → Agent verifies → Root executes → ADB wakes for visual relay only
```

- **SSH over Tailscale** — always alive, all commands go here
- **ADB TCP over Tailscale** — temporary, scrcpy only, closed after stream ends
- **No hardcoded IPs anywhere** — identity by Tailscale hostname, never `100.x.x.x`
- **No `StrictHostKeyChecking=no`** in production — pinned host keys
- **No wireless ADB persisted at boot** — that's a prototype habit, not doctrine

---

## Identity

Tailscale hostnames are the only addresses that matter:

```
nothing-phone-3a-pro   ← phone (profile zero)
macbook-pro            ← primary controller
```

IP addresses are internal plumbing. Never exposed to operator config.

---

## What Gets Binned From the ZIP

- `np3a-tui.bak*` / `np3a-tui.pre-*` — old versions, gone
- `roomcam` — superseded
- `install-codex-native.sh` — dev addon, not core
- `CODEX_NATIVE_TERMUX_TODO.md` — internal notes
- Hardcoded `PHONE_IP_WIFI`, `PHONE_IP_TS`, `TU=u0_a296`, `PIN=1234`
- `service.adb.tcp.port 5555` persisted at boot — opt-in only, never default
- `com.nothing.camera/.activity.CameraActivity` hardcoded — moves to profile

---

## What Carries Forward (Cleaned)

- `wakeup_count` polling pattern from wake daemon — efficient, keep
- PID file pattern from np3a — clean process management, keep
- `ts_peer_ip()` hostname keyword search — already identity-based, keep
- `sshd-ctl` — solid utility, keep
- Tailscale broadcast toggle pattern (`ts` script) — keep
- VM tunables from `ace_sysctl_tune` — keep as separate optional perf profile
- Boot chain structure from `service.sh` — keep, make profile-aware
