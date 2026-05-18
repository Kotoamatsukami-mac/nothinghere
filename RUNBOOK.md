# RUNBOOK — nothinghere

## Prerequisites

**Mac**
- `tailscale` installed (`brew install tailscale`)
- `deno` installed (`brew install deno`)
- `adb` installed (`brew install android-platform-tools`)
- `scrcpy` installed (`brew install scrcpy`)
- `ffmpeg` installed (`brew install ffmpeg`)
- ed25519 key pair for phone (`~/.ssh/nhere_ed25519`)
- Phone enrolled in same Tailscale network

**Phone (Nothing 3a Pro)**
- Termux (F-Droid build)
- Termux packages: `openssh`, `termux-api`
- Magisk + nhere v2.0 module installed
- Tailscale installed and logged in

---

## 1. Generate SSH key (once)

```bash
ssh-keygen -t ed25519 -f ~/.ssh/nhere_ed25519 -C nhere
```

---

## 2. Copy profile

```bash
cp profiles/nothing-3a-pro.example.conf profiles/nothing-3a-pro.conf
```

Fill in real values:

| Field          | Where to find                         |
|----------------|---------------------------------------|
| `NHERE_HOST`   | Tailscale app → machine name          |
| `NHERE_HOST_IP`| Tailscale app → IP                    |
| `NHERE_PORT`   | `8022` (Termux default)               |
| `NHERE_USER`   | Termux: `whoami`                      |
| `NHERE_KEY`    | `~/.ssh/nhere_ed25519`                |

Real `.conf` is gitignored. Never leaves your machine.

---

## 3. Install nhere Magisk module (once per device)

```bash
# On Mac — package the module
cd ~/Desktop/nothinghere/phone-side/magisk-module
zip -r ../../../nhere-v2.zip . -x "*.DS_Store"

# Push to phone
adb push ../../../nhere-v2.zip /sdcard/Download/
```

On phone: Magisk → Modules → Install from storage → `nhere-v2.zip` → Reboot.

After reboot, verify in Termux:
```bash
su -c 'nhere status'
```

---

## 4. Push SSH key to phone (once)

```bash
ssh-copy-id -i ~/.ssh/nhere_ed25519.pub -p 8022 USER@TAILSCALE_IP
```

---

## 5. Test connection

```bash
./mac-side/ctl ping
# → reachable   nothing-phone-3a-pro :8022

./mac-side/ctl status
# → state: armed / disarmed
```

---

## 6. Bring everything up

```bash
~/Desktop/nothinghere/mac-side/up-n
```

Or manually:
```bash
# Arm phone
ssh -i ~/.ssh/nhere_ed25519 -p 8022 USER@IP 'su -c "nhere arm"'

# Start cockpit
cd ~/Desktop/nothinghere
source profiles/nothing-3a-pro.conf
NHERE_HOST_IP="$NHERE_HOST_IP" deno run \
  --allow-net --allow-run --allow-read --allow-env \
  mac-side/cockpit &

open http://localhost:7779
```

---

## 7. Enable ADB TCP on demand

```bash
# On phone (via SSH or Termux):
su -c 'nhere relay-prep'

# On Mac:
source profiles/nothing-3a-pro.conf
adb connect "$NHERE_HOST_IP:5555"
```

Or to persist ADB TCP at boot, set in `/data/adb/nhere/env` on phone:
```
NHERE_ADB_TCP=1
```

---

## Troubleshooting

| Symptom                          | Fix                                              |
|----------------------------------|--------------------------------------------------|
| `tailscale not found`            | Install + start tailscale                        |
| `key file not found`             | Run step 1                                       |
| `profile not found`              | Run step 2                                       |
| `cannot resolve hostname`        | Check Tailscale MagicDNS, both devices on mesh   |
| `ssh: connect ... port 8022`     | Confirm sshd running: `su -c 'nhere status'`     |
| `state: DEAD`                    | Run `su -c 'nhere arm'` on phone                 |
| `state: DEGRADED`                | Check Tailscale on phone, run `nhere restart`    |
| ADB not connecting               | Run `nhere relay-prep` first                     |
| Cockpit shows DEAD but phone OK  | SSH directly, check `nhere status`, arm manually |
| service.sh ran twice at boot     | Lock file `/data/adb/nhere/service.lock` prevents this — verify present |

---

## Recovery (phone unreachable via SSH)

1. Tailscale still up → SSH in, run `su -c 'nhere arm'`
2. USB → `adb -s DEVICE shell su -c 'nhere arm'`
3. Physical → open Termux on phone → `su -c 'nhere arm'`

Never build the system so a single disarm permanently locks out the operator.
`nhere disarm` keeps Tailscale up by design for this reason.
