# Custom ASP.NET Core Health Checks

Reusable custom health checks for .NET web apps (including Azure App Service).

## Contents

| File | Description |
|------|-------------|
| `SelfHealthCheck.cs` | Liveness — process responsive |
| `DiskSpaceHealthCheck.cs` | Readiness — free disk threshold |
| `MemoryHealthCheck.cs` | Readiness — process working set |
| `HttpDependencyHealthCheck.cs` | Readiness — HTTP dependency GET |
| `HealthCheckServiceCollectionExtensions.cs` | DI registration |
| `HealthEndpointExtensions.cs` | Maps `/health/live` and `/health/ready` |
| `Examples/Program.HealthChecks.cs` | Sample Program.cs wiring |

## Tags

- **live** — liveness only (no external deps)
- **ready** — disk, memory, HTTP deps, DB if added

## Azure App Service

Point **Health check** path to `/health/ready`. Verify after remediation:

```bash
curl -sS https://<app>.azurewebsites.net/health/ready
curl -sS https://<app>.azurewebsites.net/health/live
```

Pairs with `Automation/recovery/azure/` scripts.
