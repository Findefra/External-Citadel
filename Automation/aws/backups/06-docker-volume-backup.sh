#!/bin/bash
# 06-docker-volume-backup.sh
# Backup a named Docker volume
set -euo pipefail

VOLUME="${1:-app_data}"
BACKUP_DIR="/backup/docker"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"

docker run --rm \
  -v "${VOLUME}:/data:ro" \
  -v "${BACKUP_DIR}:/backup" \
  alpine tar czf "/backup/${VOLUME}_${DATE}.tar.gz" -C /data .

# Optional: push to S3
# aws s3 cp "$BACKUP_DIR/${VOLUME}_${DATE}.tar.gz" s3://my-backups/docker/

find "$BACKUP_DIR" -name "${VOLUME}_*.tar.gz" -mtime +14 -delete

echo "Docker volume backup complete: ${VOLUME}_${DATE}.tar.gz"
