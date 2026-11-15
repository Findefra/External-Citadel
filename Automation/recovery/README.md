# Application Error Recovery Scripts

Specialized recovery scripts that scan logs for errors and restart the target application plus its dependent services.

## Structure

```
recovery/
├── ubuntu/          # Ubuntu (systemd + journalctl)
├── redhat/          # RHEL / Rocky / Alma / CentOS Stream
├── windows/         # Windows Server (PowerShell + Event Log)
├── kubernetes/      # Kubernetes (kubectl logs + rollout restart)
└── azure/           # Azure App Service (.NET managed web apps)
```

## Applications Covered

| Script | Description |
|--------|-------------|
| `web-app-recovery` | Generic / custom web application |
| `visionline-recovery` | dormakaba Visionline door lock / access control server |
| `freedompay-recovery` | FreedomPay payment application server |
| `servicenow-recovery` | ServiceNow application / MID server components |
| `workday-recovery` | Workday integration / adapter / on-prem components |
| `dynamics-recovery` | Microsoft Dynamics (Finance & Operations / AX / 365) app server |
| `iis-recovery` | IIS (W3SVC, WAS, application pools) – Windows |
| `nginx-recovery` | Nginx reverse proxy / web server – Ubuntu & Red Hat |
| `appservice-dotnet-recovery` | Azure App Service (.NET) – restart, instance restart, slot swap, diagnose |

## Common Features

- Structured console + file logging (daily rotation)
- Dry-run mode
- Configurable lookback window (host scripts) / explicit actions (Azure)
- Restarts primary service and declared dependents
- Platform-native tooling (systemctl / Get-Service / kubectl / Azure CLI)
- Nginx scripts prefer graceful `reload` after `nginx -t` (use `--force-restart` for full restart)
- Azure scripts support Status, Diagnose, Restart, RestartInstance, Swap

## Usage Pattern

```bash
# Linux
sudo ./ubuntu/web-app-recovery.sh --dry-run
sudo ./ubuntu/nginx-recovery.sh --minutes 20

# Windows (elevated PowerShell)
.\windows\iis-recovery.ps1 -DryRun

# Kubernetes
./kubernetes/web-app-recovery.sh --namespace production --dry-run

# Azure App Service (.NET)
./azure/appservice-dotnet-recovery.sh -g rg-prod-web -n my-dotnet-app --action diagnose
./azure/appservice-dotnet-recovery.sh -g rg-prod-web -n my-dotnet-app --action restart
./azure/appservice-dotnet-recovery.sh -g rg-prod-web -n my-dotnet-app --action swap --slot staging
```

```powershell
.\azure\appservice-dotnet-recovery.ps1 -ResourceGroup rg-prod-web -WebAppName my-dotnet-app -Action Diagnose
.\azure\appservice-dotnet-recovery.ps1 -ResourceGroup rg-prod-web -WebAppName my-dotnet-app -Action Swap -Slot staging
```

Edit resource names, services, and app pools inside each script before using in production.
