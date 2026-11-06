#!/bin/bash
# 01-rsync-incremental-backup.sh
# Incremental filesystem backup using rsync + hard-link rotation
set -euo pipefail

SOURCE="/home /etc /var/www /opt/apps"
DEST="/backup/$(hostname)"
RETENTION_DAYS=14
DATE=$(date +%Y-%m-%d_%H-%M)
LATEST="$DEST/latest"
CURRENT="$DEST/$DATE"

mkdir -p "$DEST"

rsync -aAXv --delete \
  --link-dest="$LATEST" \
  $SOURCE "$CURRENT/"

ln -sfn "$CURRENT" "$LATEST"

# Prune old backups
find "$DEST" -maxdepth 1 -type d -mtime +"$RETENTION_DAYS" ! -path "$DEST" -exec rm -rf {} +

echo "Backup completed: $CURRENT"
