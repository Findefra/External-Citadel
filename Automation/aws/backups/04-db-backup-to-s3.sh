#!/bin/bash
# 04-db-backup-to-s3.sh
# Logical database dump (MySQL/MariaDB or PostgreSQL) uploaded to S3
set -euo pipefail

DB_TYPE="${DB_TYPE:-mysql}"          # mysql | postgres
DB_HOST="${DB_HOST:-localhost}"
DB_USER="${DB_USER:-backup}"
DB_NAME="${DB_NAME:-production}"
DB_PASS="${DB_PASS:?Set DB_PASS environment variable}"
S3_BUCKET="${S3_BUCKET:-s3://my-backups/db/$(hostname)}"
DATE=$(date +%Y%m%d_%H%M%S)
FILE="/tmp/${DB_NAME}_${DATE}.sql.gz"

cleanup() { rm -f "$FILE"; }
trap cleanup EXIT

if [[ "$DB_TYPE" == "mysql" ]]; then
  mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" \
    --single-transaction --routines --triggers --events \
    "$DB_NAME" | gzip > "$FILE"
else
  PGPASSWORD="$DB_PASS" pg_dump -h "$DB_HOST" -U "$DB_USER" -Fc "$DB_NAME" | gzip > "$FILE"
fi

aws s3 cp "$FILE" "$S3_BUCKET/" \
  --storage-class STANDARD_IA \
  --sse AES256

echo "Uploaded $(basename "$FILE") to $S3_BUCKET"
