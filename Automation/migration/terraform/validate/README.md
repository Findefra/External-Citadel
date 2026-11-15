# Post-apply / post-cutover validation

Runs multi-cloud post-migration health checks and writes reports under `Automation/migration/reports/`.

## Usage

```bash
./post-apply-validate.sh --cloud aws --region us-east-1
./post-apply-validate.sh --cloud azure --resource-group rg-migrated-prod --webapp-names myapp
./post-apply-validate.sh --cloud gcp --project my-proj --zone us-central1-a
```

Exit code **1** = one or more FAIL results.
