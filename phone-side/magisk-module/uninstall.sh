#!/system/bin/sh
# uninstall.sh — nhere module removal
# Called by Magisk on module uninstall.
# Cleans up state dir. Does NOT disarm — operator responsibility.

echo "nhere uninstall: cleaning /data/adb/nhere"
rm -rf /data/adb/nhere
echo "nhere uninstall: done"
