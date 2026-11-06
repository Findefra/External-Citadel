#!/bin/bash
# 02-ebs-snapshot.sh
# Create tagged EBS snapshots and enforce retention
set -euo pipefail

# Replace with your volume IDs or discover via tags
VOLUME_IDS=("vol-0123456789abcdef0" "vol-0fedcba9876543210")
RETENTION_DAYS=7
REGION="us-west-2"
DESCRIPTION="Automated snapshot $(date +%Y-%m-%d)"

for VOL in "${VOLUME_IDS[@]}"; do
  SNAP_ID=$(aws ec2 create-snapshot \
    --volume-id "$VOL" \
    --description "$DESCRIPTION" \
    --region "$REGION" \
    --tag-specifications "ResourceType=snapshot,Tags=[{Key=Name,Value=auto-$VOL},{Key=Retention,Value=${RETENTION_DAYS}d},{Key=AutoBackup,Value=true}]" \
    --query SnapshotId --output text)
  echo "Created $SNAP_ID for $VOL"
done

# Cleanup snapshots older than retention
CUTOFF=$(date -u -d "-${RETENTION_DAYS} days" +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -v-${RETENTION_DAYS}d +%Y-%m-%dT%H:%M:%S)

aws ec2 describe-snapshots \
  --owner-ids self \
  --region "$REGION" \
  --filters "Name=tag:Retention,Values=${RETENTION_DAYS}d" \
  --query "Snapshots[?StartTime<='$CUTOFF'].SnapshotId" \
  --output text | xargs -r -n1 aws ec2 delete-snapshot --region "$REGION" --snapshot-id

echo "EBS snapshot run complete"
