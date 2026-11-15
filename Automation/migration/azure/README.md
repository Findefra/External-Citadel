# Azure Post-Migration Health Checks

Uses **Azure CLI** after Azure Migrate / ASR / DMS style migrations.

## Scripts

- `post-migration-health-check.sh` — Bash + `az`
- `post-migration-health-check.ps1` — PowerShell + `az`

## Checks

- Resource group VM power state and VM agent
- App Service state (optional names)
- SQL servers/databases presence (optional)
- Recent activity log errors (sample window)

## Usage

```bash
az login
./post-migration-health-check.sh --resource-group rg-migrated-prod --report-dir ../reports
./post-migration-health-check.sh -g rg-migrated-prod --webapp-names app1,app2 --report-dir ../reports
```

```powershell
.\post-migration-health-check.ps1 -ResourceGroup rg-migrated-prod -ReportDir ..\reports
```
