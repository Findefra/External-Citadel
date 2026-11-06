#!/bin/bash
# 09-lvm-snapshot-backup.sh
# Create a temporary LVM snapshot, rsync data, then remove snapshot
set -euo pipefail

VG="${VG:-vg_data}"
LV="${LV:-lv_db}"
SNAP_SIZE="${SNAP_SIZE:-10G}"
SNAP_NAME="snap_$(date +%Y%m%d%H%M)"
MOUNT="/mnt/snapshot"
BACKUP_DEST="/backup/lvm"

lvcreate -L "$SNAP_SIZE" -s -n "$SNAP_NAME" "/dev/${VG}/${LV}"
mkdir -p "$MOUNT" "$BACKUP_DEST"

mount -o ro "/dev/${VG}/${SNAP_NAME}" "$MOUNT"
rsync -aHAX --delete "$MOUNT/" "$BACKUP_DEST/current/"
umount "$MOUNT"
lvremove -f "/dev/${VG}/${SNAP_NAME}"

echo "LVM snapshot backup complete → $BACKUP_DEST/current"
