# Multi-Cloud Migration Toolkit

Scripts and assessments for **migrations into AWS, Azure, and GCP** using each provider’s native services, plus **post-migration health checks** that produce structured reports.

## Structure

```
migration/
├── README.md
├── aws/
├── azure/
├── gcp/
├── terraform/                  # HCP backend examples, MGN prereqs module, validate wrapper
│   ├── hcp-backend/
│   ├── modules/aws-mgn-prereqs/
│   └── validate/
└── reports/
```

## Native services (by provider)

| Cloud | Migration-oriented native services | Post-migration health focus |
|-------|------------------------------------|-----------------------------|
| **AWS** | Application Migration Service (MGN), DMS, Migration Hub | EC2/ASG state, ELB targets, RDS, CloudWatch alarms |
| **Azure** | Azure Migrate, Azure Site Recovery, Azure DMS | VM power, App Service, SQL, activity log |
| **GCP** | Migrate to VMs, Database Migration Service | GCE, MIG, Cloud SQL |

## Terraform scaffold

See [`terraform/README.md`](terraform/README.md) for:

- HCP Terraform / TFE `cloud {}` backend migration snippets + runbook
- Thin **AWS MGN prerequisites** module
- **`validate/post-apply-validate.sh`** wrapper around the health-check scripts

## Post-migration report

- Markdown: `reports/<cloud>-post-migration-<timestamp>.md`
- JSON: `reports/<cloud>-post-migration-<timestamp>.json`
- Exit: `0` pass · `1` critical fail · `2` tool/config error

## Quick start

```bash
./aws/post-migration-health-check.sh --region us-east-1 --report-dir ./reports
./azure/post-migration-health-check.sh -g rg-migrated-prod --report-dir ./reports
./gcp/post-migration-health-check.sh --project my-proj --zone us-central1-a --report-dir ./reports

# After Terraform apply / cutover
./terraform/validate/post-apply-validate.sh --cloud aws --region us-east-1
```
