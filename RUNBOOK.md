# RUNBOOK — nothinghere

## Prerequisites

**Mac side**
- `tailscale` installed and running (`brew install tailscale` — start via menu bar)
- `ssh` available (macOS ships it)
- An ed25519 key pair for the phone (`~/.ssh/nhere_ed25519`)
- Nothing 3a Pro enrolled in the same Tailscale network

**Phone side (Nothing 3a Pro)**
- Termux installed (F-Droid build recommended)
- Termux packages: `openssh`, `termux-api`
- Magisk for privilege layer (required for `root:` status field)
- Tailscale installed and logged into the same network

---

## 1. Generate SSH key (once)

```bash
ssh-keygen -t ed25519 -f ~/.ssh/nhere_ed25519 -C nhere
```

---

## 2. Copy the example profile

```bash
cp profiles/nothing-3a-pro.example.conf profiles/nothing-3a-pro.conf
```

Edit `profiles/nothing-3a-pro.conf`:

| Field | Where to find the real value |
|---|---|
| `NHERE_HOST` | Tailscale app on phone → machine name |
| `NHERE_HOST_IP` | Tailscale app on phone → IP address |
| `NHERE_PORT` | Termux default `8022` — confirm with `sshd -p` |
| `NHERE_USER` | In Termux: `whoami` |
| `NHERE_KEY` | Path to your ed25519 private key |

The real `.conf` is gitignored. It never leaves your machine.

---

## 3. Start sshd on the phone

In Termux:

```bash
sshd
```

Verify it is listening:

```bash
ss -tlnp | grep 8022
```

Copy your public key to the phone (once):

```bash
ssh-copy-id -i ~/.ssh/nhere_ed25519.pub -p 8022 USER@TAILSCALE_IP
```

---

## 4. Deploy the agent to the phone

```bash
scp -P 8022 -i ~/.ssh/nhere_ed25519 phone-side/agent USER@HOST:~/nhere/agent
ssh -p 8022 -i ~/.ssh/nhere_ed25519 USER@HOST chmod +x ~/nhere/agent
```

---

## 5. Run ping

```bash
./mac-side/ctl ping
```

Expected output:
```
reachable   nothing-phone-3a-pro :8022
```

---

## 6. Run status

```bash
./mac-side/ctl status
```

Expected output:
```
--- nothing-3a-pro ---
host:       localhost
time:       2026-05-18T...Z
state:      armed
battery:    87% Charging
root:       available
tailscale:  up  tun0  100.x.x.x
wakelock:   unknown
ssh:        reachable (you are here)
```

---

## Alternate profile

```bash
NHERE_PROFILE=other-device ./mac-side/ctl ping
```

---

## Troubleshooting

| Symptom | Check |
|---|---|
| `tailscale not found` | Install tailscale, start the daemon |
| `key file not found` | Run step 1 (keygen) |
| `profile not found` | Run step 2 (copy example) |
| `cannot resolve hostname` | Check Tailscale MagicDNS, ensure both devices are on the mesh |
| `ssh: connect to host ... port 8022` | Confirm `sshd` is running in Termux on the phone |
| `state: degraded` | Check Tailscale on phone is up |
