# GCP Post-Migration Health Checks

Uses **gcloud** after Migrate to VMs / DMS style migrations.

## Script

`post-migration-health-check.sh`

## Checks

- GCE instance status in a zone (or aggregated)
- Managed instance group size (optional)
- Cloud SQL instance state (optional)

## Usage

```bash
gcloud config set project my-project
./post-migration-health-check.sh --project my-project --zone us-central1-a --report-dir ../reports
./post-migration-health-check.sh --project my-project --zone us-central1-a --cloud-sql-instances mydb --report-dir ../reports
```
