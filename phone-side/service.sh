#!/system/bin/sh
MODDIR=${0%/*}
LOG=/data/local/tmp/np3a-control-service.log
LOCK=/data/local/tmp/np3a-service.lock
NP3A_SRC="$MODDIR/system/bin/np3a"
NP3A_DST=/data/local/tmp/np3a
WAKE_SRC="$MODDIR/system/bin/np3a-wake"
WAKE_DST=/data/local/tmp/np3a-wake
TOGGLE_SRC="$MODDIR/system/bin/np3a-toggle"
TOGGLE_DST=/data/local/tmp/np3a-toggle

{
  if [ -f "$LOCK" ]; then
    echo "service.sh already ran this boot (lock exists), exiting"
    exit 0
  fi
  echo $$ > "$LOCK"

  echo "np3a service start $(date)"

  # Persist ADB TCP on :5555
  setprop service.adb.tcp.port 5555
  setprop persist.adb.tcp.port 5555
  stop adbd 2>/dev/null; sleep 1; start adbd 2>/dev/null
  echo "adbd restarted on :5555"

  sleep 40

  # refresh scripts from module
  for src_dst in "$NP3A_SRC:$NP3A_DST" "$WAKE_SRC:$WAKE_DST" "$TOGGLE_SRC:$TOGGLE_DST"; do
    src="${src_dst%%:*}"
    dst="${src_dst##*:}"
    if [ -f "$src" ]; then
      cp "$src" "$dst" && chmod 755 "$dst" && chown shell:shell "$dst" 2>/dev/null
      echo "refreshed $dst"
    fi
  done

  # get termux uid with retries
  TERMUX_UID=""
  for i in 1 2 3 4 5; do
    TERMUX_UID="$(pm list packages -U com.termux 2>/dev/null | grep 'package:com.termux ' | sed -n 's/.*uid://p' | head -1)"
    [ -n "$TERMUX_UID" ] && break
    echo "uid probe $i failed, waiting..."
    sleep 10
  done

  if [ -z "$TERMUX_UID" ]; then
    echo "termux uid not found after retries"
    exit 1
  fi

  TU="u0_a$((TERMUX_UID - 10000))"
  SSHD=/data/data/com.termux/files/usr/bin/sshd

  for i in 1 2 3; do
    [ -x "$SSHD" ] && break
    echo "sshd not accessible yet ($i), waiting..."
    sleep 10
  done

  if [ ! -x "$SSHD" ]; then
    echo "sshd binary not found at $SSHD"
    exit 1
  fi

  pkill -f "sshd" 2>/dev/null || true
  sleep 2
  su "$TU" -c "PATH=/data/data/com.termux/files/usr/bin:/system/bin sshd" >/dev/null 2>&1 \
    && echo "sshd started for $TU" \
    || echo "sshd start failed"

  am startservice --user 0 -n com.termux/.app.TermuxService \
    --ez run_command true --es arguments "termux-wake-lock" 2>/dev/null \
    && echo "wakelock requested" || true

  sleep 5
  ss -ltnp 2>/dev/null | grep ':8022' && echo "sshd listening :8022" \
    || echo "sshd not listening"

  # np3a-wake daemon
  if [ -x "$WAKE_DST" ]; then
    pkill -f "np3a-wake" 2>/dev/null || true
    setsid "$WAKE_DST" >>/data/local/tmp/np3a-wake.log 2>&1 &
    echo "np3a-wake started (PID $!)"
  fi

  # np3a-button daemon (vol-down x3 → unlock)
  BUTTON_DST=/data/local/tmp/np3a-button
  if [ -f "$MODDIR/system/bin/np3a-button" ]; then
    cp "$MODDIR/system/bin/np3a-button" "$BUTTON_DST"
    chmod 755 "$BUTTON_DST"
  fi
  if [ -x "$BUTTON_DST" ]; then
    pkill -f "np3a-button" 2>/dev/null || true
    setsid "$BUTTON_DST" >>/data/local/tmp/np3a-button.log 2>&1 &
    echo "np3a-button started (PID $!)"
  fi

  # np3a-toggle daemon (double power press → toggle connection stack)
  if [ -x "$TOGGLE_DST" ]; then
    pkill -f "np3a-toggle" 2>/dev/null || true
    setsid "$TOGGLE_DST" >>/data/local/tmp/np3a-toggle.log 2>&1 &
    echo "np3a-toggle started (PID $!)"
  fi

} >>"$LOG" 2>&1
