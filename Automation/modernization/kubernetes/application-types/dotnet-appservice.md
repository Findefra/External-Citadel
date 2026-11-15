# Type: .NET (App Service / Kestrel) → Kubernetes

## Characteristics

- ASP.NET Core on Kestrel (Linux containers preferred)
- Often coming from Azure App Service or VMs
- Cold start and memory tuning matter on small nodes

## Modernization path

1. **Assess** — .NET version, Windows-only APIs, WeasyPrint/GDI, file system writes under `HOME`
2. **Health** — adopt `Application/dotnet/healthchecks` (`/health/live`, `/health/ready`)
3. **Containerize** — `mcr.microsoft.com/dotnet/aspnet` runtime image; `ASPNETCORE_URLS=http://0.0.0.0:8080`
4. **Config** — appsettings per env via ConfigMap; secrets from CSI/Key Vault/AWS SM
5. **Deploy** — Deployment; startupProbe for slow cold start; readiness on `/health/ready`
6. **Data** — keep Azure SQL / RDS / Cloud SQL managed; update connection strings
7. **Cutover** — slot-swap equivalent = new Deployment revision + ingress switch

## Example layout

See `../examples/deploy-dotnet/`.

## Pitfalls

- Running as root; loading secrets from disk baked in image
- Using liveness against SQL (restart storm)
- Forgetting `DOTNET_EnableDiagnostics` / introspection only in non-prod
