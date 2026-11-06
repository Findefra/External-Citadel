#!/bin/bash
# 08-system-config-snapshot.sh
# Capture package lists and critical system configuration
set -euo pipefail

OUT="/backup/system/$(hostname)-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"

# Package lists
if command -v dpkg >/dev/null 2>&1; then
  dpkg --get-selections > "$OUT/packages.list"
  apt-mark showmanual > "$OUT/manual-packages.list" 2>/dev/null || true
elif command -v rpm >/dev/null 2>&1; then
  rpm -qa > "$OUT/packages.list"
fi

# Critical configs
tar czf "$OUT/etc.tar.gz" --exclude='*/.cache' /etc 2>/dev/null || true
cp /etc/fstab /etc/hosts /etc/hostname "$OUT/" 2>/dev/null || true

# Runtime info
uname -a > "$OUT/uname.txt"
lsblk > "$OUT/lsblk.txt" 2>/dev/null || true
df -hT > "$OUT/df.txt"
ip a > "$OUT/ip.txt" 2>/dev/null || true

echo "System config snapshot written to $OUT"
