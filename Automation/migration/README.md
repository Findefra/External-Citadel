# Multi-Cloud Migration Toolkit

Scripts and assessments for **migrations into AWS, Azure, and GCP** using each provider’s native services, plus **post-migration health checks** that produce structured reports.

## Structure

```
migration/
├── README.md
├── aws/
│   ├── post-migration-health-check.sh
│   └── README.md
├── azure/
│   ├── post-migration-health-check.sh
│   ├── post-migration-health-check.ps1
│   └── README.md
├── gcp/
│   ├── post-migration-health-check.sh
│   └── README.md
└── reports/                    # default output directory (gitignored samples OK)
    └── .gitkeep
```

## Native services (by provider)

| Cloud | Migration-oriented native services | Post-migration health focus |
|-------|------------------------------------|-----------------------------|
| **AWS** | Application Migration Service (MGN), DMS, Migration Hub, Elastic Disaster Recovery | EC2/ASG state, ELB targets, RDS, CloudWatch alarms |
| **Azure** | Azure Migrate, Azure Site Recovery, Azure Database Migration Service | VM power/agent, App Service, SQL, Azure Monitor activity |
| **GCP** | Migrate to VMs, Database Migration Service, Transfer services | GCE instance status, MIG, Cloud SQL, Cloud Monitoring |

These scripts do **not** replace full Azure Migrate / MGN / Migrate to VMs projects. They automate **readiness-style and post-cutover health assessment** and write **reports** you can attach to change records.

## Post-migration report

Each health-check script writes:

- Markdown report: `reports/<cloud>-post-migration-<timestamp>.md`
- JSON summary: `reports/<cloud>-post-migration-<timestamp>.json`

Exit codes: `0` = all critical checks passed, `1` = one or more critical failures, `2` = tool/config error.

## Prerequisites

- **AWS:** AWS CLI v2, credentials/profile with read access to EC2, ELB, RDS, CloudWatch
- **Azure:** Azure CLI (`az login`), subscription access to Compute, Web, SQL, Monitor
- **GCP:** `gcloud` CLI, project configured, roles for compute/sql/monitoring viewer

## Quick start

```bash
# AWS
./aws/post-migration-health-check.sh --region us-east-1 --report-dir ./reports

# Azure
./azure/post-migration-health-check.sh --resource-group rg-migrated-prod --report-dir ./reports

# GCP
./gcp/post-migration-health-check.sh --project my-proj --zone us-central1-a --report-dir ./reports
```

Review the generated Markdown report before closing the migration change window.
