# Backup & Snapshot Scripts

Production-oriented backup and snapshot utilities for Linux hosts and AWS environments.

These scripts are designed to be:
- Idempotent where possible
- Logged and alert-capable
- Retention-aware
- Suitable for cron / systemd timers / EventBridge

## Scripts

| Script | Purpose |
|--------|---------|
| `01-rsync-incremental-backup.sh` | Space-efficient incremental filesystem backups with hard-link rotation |
| `02-ebs-snapshot.sh` | Create and retain tagged EBS volume snapshots |
| `03-create-ami.sh` | Create AMI from a running EC2 instance |
| `04-db-backup-to-s3.sh` | Logical MySQL/MariaDB or PostgreSQL dump → S3 |
| `05-home-backup.sh` | User home directory backup with sensible exclusions |
| `06-docker-volume-backup.sh` | Backup named Docker volumes |
| `07-git-repo-backup.sh` | Mirror and archive Git repositories |
| `08-system-config-snapshot.sh` | Capture package lists + critical /etc state |
| `09-lvm-snapshot-backup.sh` | Consistent LVM snapshot + rsync of data volumes |
| `10-backup-orchestrator.sh` | Run multiple backup jobs and alert on failure |

## Usage Notes

- Review and set variables (volume IDs, paths, regions, credentials) before use.
- Prefer IAM instance profiles / roles over long-lived keys.
- Test restores regularly.
- Pair with S3 lifecycle policies, AMI/EBS retention policies, or local retention logic already included.

Production / highly sensitive variants belong in the private Internal-Citadel repository.
