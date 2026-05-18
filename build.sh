#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$REPO_ROOT/phone-side/magisk-module"
OUT="$REPO_ROOT/nhere-v2.zip"

rm -f "$OUT"
cd "$MODULE_DIR"
zip -r "$OUT" . \
    -x "*.DS_Store" \
    -x ".git" \
    -x "*.zip"

echo ""
echo "Built: $OUT"
echo ""
echo "Contents:"
unzip -l "$OUT"
echo ""
echo "Install:"
echo "  adb push $OUT /sdcard/Download/"
echo "  Then: Magisk → Modules → Install from storage → nhere-v2.zip → Reboot"
