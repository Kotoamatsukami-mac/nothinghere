#!/system/bin/sh
# service.sh — nhere module boot service
# Runs as root after boot via Magisk late_start.
# Exits cleanly. No loops. No daemons. No key watchers.

MODDIR="${0%/*}"
NHERE_DIR=/data/adb/nhere
LOG=/data/adb/nhere/service.log
LOCK=/data/adb/nhere/service.lock

# Wait for boot to settle
sleep 30

# Bail if already ran this boot
[ -f "$LOCK" ] && exit 0

# Prepare state directory
mkdir -p "$NHERE_DIR"
chmod 700 "$NHERE_DIR"

# Start log
exec >>"$LOG" 2>&1
echo "=== nhere service.sh boot $(date) ==="

# Write boot lock
echo $$ > "$LOCK"

# Copy nhere binary to data (executable from shell without su -c path tricks)
NHERE_BIN="$MODDIR/system/bin/nhere"
if [ -f "$NHERE_BIN" ]; then
    cp "$NHERE_BIN" "$NHERE_DIR/nhere"
    chmod 755 "$NHERE_DIR/nhere"
    echo "nhere binary deployed: $NHERE_DIR/nhere"
fi

# Init state file if absent (default: disarmed)
[ -f "$NHERE_DIR/state" ] || echo "disarmed" > "$NHERE_DIR/state"
echo "state: $(cat $NHERE_DIR/state)"

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

# Write booted flag
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$NHERE_DIR/booted"
echo "service.sh done"

# Exit cleanly. No daemons started here.
exit 0
