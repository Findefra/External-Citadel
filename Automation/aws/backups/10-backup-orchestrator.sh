#!/bin/bash
# 10-backup-orchestrator.sh
# Run a set of backup scripts and alert on any failure
set -euo pipefail

LOG="/var/log/backup-orchestrator.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SCRIPTS=(
  "$SCRIPT_DIR/01-rsync-incremental-backup.sh"
  "$SCRIPT_DIR/02-ebs-snapshot.sh"
  "$SCRIPT_DIR/04-db-backup-to-s3.sh"
  "$SCRIPT_DIR/08-system-config-snapshot.sh"
)

FAILED=0

{
  echo "=== Backup run started $(date) ==="
  for SCRIPT in "${SCRIPTS[@]}"; do
    if [[ -x "$SCRIPT" ]]; then
      echo "Running $SCRIPT ..."
      if ! "$SCRIPT"; then
        echo "FAILED: $SCRIPT"
        FAILED=1
      fi
    else
      echo "Skipping (not executable): $SCRIPT"
    fi
  done
  echo "=== Backup run finished $(date) ==="
} | tee -a "$LOG"

if [[ $FAILED -eq 1 ]]; then
  # Example notification – replace with SNS, Slack webhook, SES, etc.
  echo "One or more backups failed on $(hostname). Check $LOG" | \
    mail -s "Backup Failure on $(hostname)" ops@example.com 2>/dev/null || true
  exit 1
fi

echo "All backups succeeded"
