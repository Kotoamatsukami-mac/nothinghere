# Live Access — Operator Notes

## SSH into phone via Tailscale

Tailscale connection confirmed live. Direct SSH access to Nothing 3a Pro
is available when the device is armed (Tailscale up + sshd running in Termux).

```bash
ssh -i ~/.ssh/nhere_ed25519 -p 8022 u0_a296@nothing-phone-3a-pro
```

Or via ctl profile (preferred — resolves hostname automatically):
```bash
./mac-side/ctl ping    # confirm reachable
./mac-side/ctl status  # confirm armed state
ssh -i "$NHERE_KEY" -p "$NHERE_PORT" "$NHERE_USER@$NHERE_HOST"
```

## What this enables (confirmed working)

- Direct shell access to Termux userland on the phone
- Can inspect live state: battery, storage, wakelock, running services
- Can deploy/update phone-side/agent in place over SSH
- Can read Tailscale state, PID state, Magisk module status from shell

## What to build next using this access

- Wire wakelock state: `termux-wake-lock` status read via SSH into `status` output
- Verify sshd is listening before reporting `armed` in armed_state
  (`ss -tlnp | grep 8022` or `netstat -tlnp | grep 8022` from agent)
- Service restart commands (sshd, tailscale) — deliberate owner action only
- Diagnostic snapshots over SSH (logcat tail, thermal state, storage breakdown)

## Constraints (DOCTRINE)

- Live access is owner-enrolled administration — not a relay, not a backdoor
- Do not leave debug bridge open after maintenance
- Do not automate persistent shell sessions
- All actions via ctl profile pattern — no raw IP scripts committed
