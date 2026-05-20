# MAGISK_REBUILD — nothinghere

Magisk module rebuild and install checklist. Use this any time you change
`phone-side/magisk-module/` and need to push it to the device.

---

## Before you rebuild: verify recovery

Confirm at least one control path is live so you are not locked out during reboot:

```bash
# Option A — SSH over Tailscale
source profiles/nothing-3a-pro.conf
ssh -i "$NHERE_KEY" -p "$NHERE_PORT" "$NHERE_USER@$NHERE_HOST_IP" 'su -c "nhere status"'

# Option B — ADB over Tailscale
source profiles/nothing-3a-pro.conf
adb connect "$NHERE_HOST_IP:5555"
adb -s "$NHERE_HOST_IP:5555" shell su -c 'nhere status'

# Option C — Physical access
# Open Termux on phone → su -c 'nhere status'
```

If none of these work, fix connectivity first.

---

## 1. Make your edits to the module

Files to know:

| File | Purpose |
|---|---|
| `phone-side/magisk-module/system/bin/nhere` | Root command engine — arm/disarm/status/relay-prep |
| `phone-side/magisk-module/service.sh` | Boot service — one-shot arm restore, no daemon |
| `phone-side/magisk-module/module.prop` | Module identity — version/versionCode |
| `phone-side/magisk-module/customize.sh` | Install-time setup — runs once on install |
| `phone-side/magisk-module/uninstall.sh` | Cleanup on module removal |

When bumping the binary version, update `module.prop` (`version=` and `versionCode=`)
and the `ui_print` line in `customize.sh` to match.

---

## 2. Build the zip

```bash
cd ~/Desktop/nothinghere
bash build.sh
```

`build.sh` produces `nhere-v2.zip` at repo root. It excludes `.DS_Store`, `.git`,
and any existing `*.zip` files. Verify the output listing at the end of the build.

---

## 3. Push to phone

ADB must be connected. If not yet connected:

```bash
source profiles/nothing-3a-pro.conf

# Enable ADB TCP on phone (via SSH if sshd is up):
ssh -i "$NHERE_KEY" -p "$NHERE_PORT" "$NHERE_USER@$NHERE_HOST_IP" \
  'su -c "nhere relay-prep"'
sleep 3
adb connect "$NHERE_HOST_IP:5555"
```

Then push:

```bash
adb push nhere-v2.zip /sdcard/Download/
```

---

## 4. Install in Magisk and reboot

On phone: **Magisk → Modules → Install from storage → nhere-v2.zip → Reboot**

The reboot wipes the boot-scoped lock from the previous boot, so `service.sh`
will run fresh on the next boot.

---

## 5. Post-reboot verification

Wait ~40 s after reboot for `service.sh` to finish its 30 s settle sleep, then:

```bash
# From Termux on phone:
su -c 'nhere status'

# From Mac (after SSH is up):
source profiles/nothing-3a-pro.conf
ssh -i "$NHERE_KEY" -p "$NHERE_PORT" "$NHERE_USER@$NHERE_HOST_IP" \
  'su -c "nhere status"'

# Or via ctl:
./mac-side/ctl status
```

Expected output when armed:
```
state:         armed
desired_state: armed
root:          ok
battery:       XX% discharging
thermal:       XX°C
sshd:          up :8022
tailscale:     up tun0 100.x.x.x
wakelock:      held
adb:           usb-only
```

---

## 6. Confirm service.sh ran cleanly

```bash
# On phone (root shell or SSH):
su -c 'cat /data/adb/nhere/service.log'
```

Look for `service.sh done` at the end. If arm failed at boot, log will show the
error — re-arm manually: `su -c 'nhere arm'`.

---

## Rollback

If the new module is broken, Magisk lets you boot without the module:

- Magisk → Modules → disable/uninstall nhere → reboot
- Or: hold volume-down during boot to enter safe mode (disables all Magisk modules)

State files in `/data/adb/nhere/` survive a module uninstall. A reinstall picks
them up and respects `desired_state`. If you want a clean slate, delete
`/data/adb/nhere/` from an ADB or root shell before reinstalling.
