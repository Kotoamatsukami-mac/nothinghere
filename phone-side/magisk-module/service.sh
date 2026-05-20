#!/system/bin/sh
# service.sh — nhere module boot service
# Runs as root after boot via Magisk late_start.
# Exits cleanly. No loops. No daemons. No key watchers.

MODDIR="${0%/*}"
NHERE_DIR=/data/adb/nhere
LOG="$NHERE_DIR/service.log"

# Wait for boot to settle
sleep 30

# Prepare state directory (needed before lock path can be written)
mkdir -p "$NHERE_DIR"
chmod 700 "$NHERE_DIR"

# Boot-scoped idempotency guard.
# /proc/sys/kernel/random/boot_id changes on every reboot, so this lock is
# naturally absent after reboot — no manual cleanup needed. Old lock files
# from prior boots are harmless (different name, ignored by future boots).
BOOT_ID="$(cat /proc/sys/kernel/random/boot_id 2>/dev/null | tr -d '[:space:]-')"
LOCK="$NHERE_DIR/service.${BOOT_ID:-once}.lock"
[ -f "$LOCK" ] && exit 0

# Start log
exec >>"$LOG" 2>&1
echo "=== nhere service.sh boot $(date) ==="

# Write boot-scoped lock
echo $$ > "$LOCK"

# Copy nhere binary to data (executable from shell without su -c path tricks)
NHERE_BIN="$MODDIR/system/bin/nhere"
if [ -f "$NHERE_BIN" ]; then
    cp "$NHERE_BIN" "$NHERE_DIR/nhere"
    chmod 755 "$NHERE_DIR/nhere"
    echo "nhere binary deployed: $NHERE_DIR/nhere"
fi

# Init state files if absent (safe defaults).
# Upgrade compat: on v2.0 → v2.1 the legacy `state` file may exist as "armed"
# while `desired_state` does not. Seed desired_state from state so a previously
# armed device stays armed across the upgrade reboot.
[ -f "$NHERE_DIR/state" ] || echo "disarmed" > "$NHERE_DIR/state"
if [ ! -f "$NHERE_DIR/desired_state" ]; then
    seed="$(cat "$NHERE_DIR/state" 2>/dev/null)"
    case "$seed" in
        armed|disarmed) echo "$seed" > "$NHERE_DIR/desired_state" ;;
        *)              echo "disarmed" > "$NHERE_DIR/desired_state" ;;
    esac
    echo "desired_state seeded from state: $(cat "$NHERE_DIR/desired_state")"
fi
DESIRED="$(cat "$NHERE_DIR/desired_state" 2>/dev/null)"
echo "state:         $(cat "$NHERE_DIR/state")"
echo "desired_state: $DESIRED"

# Optional: persist ADB TCP if enabled via env flag
# Set NHERE_ADB_TCP=1 in /data/adb/nhere/env to activate
if [ -f "$NHERE_DIR/env" ]; then
    # shellcheck disable=SC1091
    . "$NHERE_DIR/env"
fi
if [ "${NHERE_ADB_TCP:-0}" = "1" ]; then
    setprop service.adb.tcp.port 5555
    setprop persist.adb.tcp.port 5555
    stop adbd 2>/dev/null; sleep 1; start adbd 2>/dev/null
    echo "ADB TCP :5555 enabled (NHERE_ADB_TCP=1)"
fi

# Persistence contract: restore armed state ONCE on boot if user wanted it.
# Runs as a one-shot call to nhere arm — same code path as manual arm, exits cleanly.
# If desired_state=disarmed (or anything else), nothing is started.
if [ "$DESIRED" = "armed" ]; then
    echo "restoring armed state via nhere arm"
    "$NHERE_DIR/nhere" arm >/dev/null 2>&1 || echo "warn: boot-restore arm failed"
else
    echo "desired=disarmed — no sshd/wakelock started"
fi

# Write booted flag
date -u +%Y-%m-%dT%H:%M:%SZ > "$NHERE_DIR/booted"
echo "service.sh done"

# Exit cleanly. No daemons started here.
exit 0
