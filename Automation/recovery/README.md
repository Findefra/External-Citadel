# Application Error Recovery Scripts

Specialized recovery scripts that scan logs for errors and restart the target application plus its dependent services.

## Structure

```
recovery/
├── ubuntu/          # Ubuntu (systemd + journalctl)
├── redhat/          # RHEL / Rocky / Alma / CentOS Stream
├── windows/         # Windows Server (PowerShell + Event Log)
└── kubernetes/      # Kubernetes (kubectl logs + rollout restart)
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

## Common Features

- Structured console + file logging (daily rotation)
- Dry-run mode
- Configurable lookback window
- Restarts primary service and declared dependents
- Platform-native tooling (systemctl / Get-Service / kubectl)
- Nginx scripts prefer graceful `reload` after `nginx -t` (use `--force-restart` for full restart)

## Usage Pattern

```bash
# Linux
sudo ./ubuntu/web-app-recovery.sh --dry-run
sudo ./ubuntu/nginx-recovery.sh --minutes 20
sudo ./redhat/nginx-recovery.sh --force-restart

# Windows (elevated PowerShell)
.\windows\web-app-recovery.ps1 -DryRun
.\windows\iis-recovery.ps1 -Minutes 15
.\windows\iis-recovery.ps1 -AppPool "MyWebAppPool","DefaultAppPool"

# Kubernetes
./kubernetes/web-app-recovery.sh --namespace production --dry-run
```

Edit the service / deployment / app pool names inside each script before using in production.
