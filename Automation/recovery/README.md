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

## Common Features

- Structured console + file logging (daily rotation)
- Dry-run mode
- Configurable lookback window
- Restarts primary service and declared dependents
- Platform-native tooling (systemctl / Get-Service / kubectl)

## Usage Pattern

```bash
# Linux
sudo ./ubuntu/web-app-recovery.sh --dry-run
sudo ./redhat/visionline-recovery.sh --minutes 20

# Windows (elevated PowerShell)
.\windows\web-app-recovery.ps1 -DryRun
.\windows\dynamics-recovery.ps1 -Minutes 15

# Kubernetes
./kubernetes/web-app-recovery.sh --namespace production --dry-run
./kubernetes/servicenow-recovery.sh --namespace servicenow
```

Edit the service / deployment names inside each script before using in production.
