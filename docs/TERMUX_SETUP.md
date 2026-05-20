# TERMUX_SETUP — nothinghere

Safe Termux cleanup and setup procedures. **Default is soft cleanup. Hard wipe requires verified recovery path.**

---

## Before you touch anything: verify recovery

If you cannot afford to lose SSH access, confirm at least one of these works before proceeding:

```bash
# Option A — USB + ADB
adb devices                          # phone listed?
adb shell su -c 'nhere status'       # root + module reachable?

# Option B — Tailscale still up, SSH still open
ssh -i ~/.ssh/nhere_ed25519 -p 8022 USER@TAILSCALE_IP 'su -c nhere status'

# Option C — Physical access
# Open Termux on phone → su -c 'nhere status'
```

If none of these work, do not proceed. Fix connectivity first.

---

## Verification commands (run in Termux)

```bash
# Termux identity
whoami                               # your NHERE_USER value
echo $PREFIX                         # should be /data/data/com.termux/files/usr
which sshd                           # should be $PREFIX/bin/sshd

# sshd state (port-based — matches the contract `nhere` uses)
ss -tln 2>/dev/null  | grep -q ':8022\b' && echo "sshd UP :8022" || \
netstat -tln 2>/dev/null | grep -q ':8022\b' && echo "sshd UP :8022" || \
echo "sshd DOWN"
# Process-based check, scoped to your Termux user (catches listener + sessions)
pgrep -u "$(whoami)" sshd && echo "sshd processes present" || echo "no sshd processes"

# SSH auth
cat ~/.ssh/authorized_keys           # should contain your Mac's nhere_ed25519.pub
ls -la ~/.ssh/                       # authorized_keys should be 600

# Tailscale
tailscale status                     # should show IP and "logged in"
tailscale ip                         # your Tailscale IP for NHERE_HOST_IP

# termux-wake-lock
which termux-wake-lock               # present if termux-api is installed

# Old leftover check (none of these should appear)
ls ~/nhere/ 2>/dev/null && echo "WARNING: old ~/nhere agent dir present" || echo "clean"
pgrep -f getevent  2>/dev/null && echo "WARNING: getevent running" || echo "clean"
pgrep -f "button"  2>/dev/null && echo "WARNING: button listener running" || echo "clean"
```

---

## Soft cleanup (default — preserves SSH access)

Use this after a partial or broken Termux state. Does **not** wipe packages, authorized_keys, or Tailscale.

```bash
# 1. Stop any stale sshd first so we can restart clean
#    User-scoped — won't touch system sshd (root-owned) if one is somehow running.
pkill -u "$(whoami)" sshd 2>/dev/null; sleep 1

# 2. Remove known leftover files from old agent design (safe to delete)
rm -rf ~/nhere/ 2>/dev/null          # old ~/nhere/agent directory
rm -f  ~/start-agent.sh 2>/dev/null
rm -f  ~/button-listener.sh 2>/dev/null

# 3. Update packages (safe, non-destructive)
pkg update -y && pkg upgrade -y

# 4. Ensure required packages present
pkg install -y openssh
pkg install -y termux-api            # optional, enables wakelock

# 5. Verify authorized_keys intact before restarting sshd
cat ~/.ssh/authorized_keys           # confirm your key is there

# 6. Restart sshd
sshd

# 7. Confirm from Mac (separate terminal)
ssh -i ~/.ssh/nhere_ed25519 -p 8022 USER@TAILSCALE_IP 'echo OK'
```

After soft cleanup, verify the Magisk module is still active:

```bash
su -c 'nhere status'
```

---

## Hard wipe (documentation-only — do NOT do this unless recovery is verified)

> **Warning:** This destroys your Termux home directory, all packages, authorized_keys, and SSH config. You will lose SSH access until you manually rebuild from scratch. Only proceed if you have verified ADB/root/Magisk shell access above.

```bash
# STOP. Read the warning above.
# Only proceed if adb shell su -c id returns uid=0 OR physical access is confirmed.

# Hard wipe Termux data
# (run from ADB shell or Magisk shell — not from within Termux SSH, which will die)
rm -rf /data/data/com.termux/files/

# After wipe: open Termux on phone physically and bootstrap from scratch:
pkg update -y && pkg upgrade -y
pkg install -y openssh termux-api
passwd
sshd

# Re-push SSH key from Mac:
ssh-copy-id -i ~/.ssh/nhere_ed25519.pub -p 8022 USER@TAILSCALE_IP

# Re-arm:
su -c 'nhere arm'
```

---

## Post-cleanup reconnect checklist

After any cleanup, confirm from Mac before closing your current session:

```bash
# 1. SSH still works
ssh -i ~/.ssh/nhere_ed25519 -p 8022 USER@TAILSCALE_IP 'echo SSH OK'

# 2. nhere module still active
ssh -i ~/.ssh/nhere_ed25519 -p 8022 USER@TAILSCALE_IP 'su -c "nhere status"'

# 3. State is armed (or re-arm if disarmed)
ssh -i ~/.ssh/nhere_ed25519 -p 8022 USER@TAILSCALE_IP 'su -c "nhere arm"'

# 4. Cockpit reachable (from Mac)
source profiles/nothing-3a-pro.conf
mac-side/up-n
open http://localhost:7779
```
