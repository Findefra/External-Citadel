# Azure Managed Web Application Recovery (.NET)

Remediation scripts and guidance for **Azure App Service** (and related managed web hosting) running **.NET** applications.

## Structure

```
azure/
├── README.md
├── appservice-dotnet-recovery.ps1   # Primary (Az PowerShell / Azure CLI)
└── appservice-dotnet-recovery.sh    # Bash + Azure CLI alternative
```

Related incident playbook:
- `Automation/incident-response/azure-appservice-dotnet-incident-playbook.md`

## What these scripts cover

| Action | Description |
|--------|-------------|
| Status check | App Service state, HTTPS endpoint, instances |
| Log / error scan | Recent log activity via `az webapp log` / activity hints |
| Restart | Full site restart |
| Instance restart | Restart a specific instance (when scaled out) |
| Slot swap | Swap staging ↔ production (rollback or promote) |
| Dry-run | Show actions without making changes |

## Prerequisites

- Azure CLI (`az`) logged in (`az login`) with rights on the subscription/resource group
- For PowerShell script: `Az.Accounts` / `Az.Websites` modules *or* Azure CLI available
- Resource group + web app name (and optional slot name)

## Quick usage

```powershell
# PowerShell
.\appservice-dotnet-recovery.ps1 -ResourceGroup "rg-prod-web" -WebAppName "my-dotnet-app" -DryRun
.\appservice-dotnet-recovery.ps1 -ResourceGroup "rg-prod-web" -WebAppName "my-dotnet-app" -Action Restart
.\appservice-dotnet-recovery.ps1 -ResourceGroup "rg-prod-web" -WebAppName "my-dotnet-app" -Action Swap -Slot "staging"
```

```bash
# Bash
./appservice-dotnet-recovery.sh --resource-group rg-prod-web --name my-dotnet-app --dry-run
./appservice-dotnet-recovery.sh --resource-group rg-prod-web --name my-dotnet-app --action restart
./appservice-dotnet-recovery.sh --resource-group rg-prod-web --name my-dotnet-app --action swap --slot staging
```

## .NET-specific notes

- Prefer **slot swap** for safe rollback after a bad deploy instead of only restarting.
- After restart, allow time for cold start (especially on lower tiers).
- Check Application Insights and App Service **Diagnose and solve problems** for .NET exceptions, thread pool starvation, and 5xx patterns.
- Kudu (`scm` site) and `az webapp log tail` are useful for live .NET stdout/stderr.

Edit default resource names and subscription in the scripts before production use.
