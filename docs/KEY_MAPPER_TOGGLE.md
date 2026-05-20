# Key Mapper — Double-Press Toggle

Optional frontend for `nhere toggle`. Uses the
[Key Mapper](https://play.google.com/store/apps/details?id=io.github.sds100.keymapper)
app to map a hardware button double-press to arm/disarm.

This is **not** part of the Magisk module. The module ships no button listener,
no getevent loop, no power-menu hook. Key Mapper is an external app that calls
the same `nhere toggle` command any rooted shell can call.

---

## Setup

1. Install **Key Mapper** from Google Play (or F-Droid: `io.github.sds100.keymapper`).

2. Open Key Mapper → **+** (new key map).

3. **Trigger:**
   - Tap **Record Trigger**.
   - Press the **power button** twice.
   - Key Mapper should show two "Power" key events.
   - Set click type to **Double Press**.

4. **Action:**
   - Tap **Add Action** → **Shell Command (requires root)**.
   - Enter exactly:
     ```
     su -c 'nhere toggle'
     ```
   - Ensure **Run as root** is enabled.

5. **Save** the key map.

6. Test: double-press the power button.
   - If the phone was disarmed → arms (sshd starts, wakelock acquired).
   - If the phone was armed → disarms (sshd stops after 2 s, wakelock released).
   - Tailscale stays up in both directions.

---

## Verify

After toggling, confirm state from Termux or SSH:

```bash
su -c 'nhere status'
```

Or from Mac:

```bash
./mac-side/ctl status
```

---

## Notes

- Key Mapper needs the **Accessibility Service** enabled to intercept hardware keys.
- The double-press delay is configurable in Key Mapper's trigger settings.
- `nhere toggle` reads `desired_state` — it flips the user's intent, not just
  observed state. Safe to call repeatedly.
- If Key Mapper is uninstalled or disabled, the module is unaffected — `nhere`
  commands still work from Termux, SSH, ADB, or any other rooted shell.

---

## Alternative triggers

The same command works from any trigger source:

| Frontend | Command |
|---|---|
| Key Mapper | `su -c 'nhere toggle'` |
| Tasker | Shell → `su -c 'nhere toggle'` (root required) |
| Termux Widget | `~/.shortcuts/nhere-toggle.sh` containing `su -c 'nhere toggle'` |
| Quick Settings tile | MacroDroid or AutoNotification → shell action |
| Physical Termux | `su -c 'nhere toggle'` |

All of these are optional frontends. None are part of the module.
