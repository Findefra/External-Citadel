# Terraform Migration Scaffold

Terraform-oriented helpers for:

1. **Platform migration** — move state/workflows to HCP Terraform (Terraform Cloud) / TFE
2. **Workload migration (AWS)** — thin prerequisites module for Application Migration Service (MGN)
3. **Post-apply validation** — run multi-cloud health scripts and attach reports

## Layout

```
terraform/
├── README.md
├── hcp-backend/
│   ├── README.md
│   ├── versions.tf
│   ├── backend.cloud.tf.example
│   └── migrate-state.md
├── modules/
│   └── aws-mgn-prereqs/
│       ├── README.md
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── validate/
    ├── README.md
    └── post-apply-validate.sh
```

## Related

| Path | Role |
|------|------|
| [`../aws/`](../aws/) | AWS post-migration health check + reports |
| [`../azure/`](../azure/) | Azure post-migration health check + reports |
| [`../gcp/`](../gcp/) | GCP post-migration health check + reports |

## Typical flow

```text
1. Build / apply landing zone + (optional) MGN prereqs
2. Execute native migration wave (MGN / Azure Migrate / Migrate to VMs)
3. ./validate/post-apply-validate.sh  → Markdown + JSON reports
4. Close change only if critical checks PASS
```
