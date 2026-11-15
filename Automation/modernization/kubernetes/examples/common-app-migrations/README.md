# Common application migration examples (→ Kubernetes)

Side-by-side patterns used with nginx, Helm, and CI/CD under this modernization tree.

## Scenarios

| Scenario | From | To | Example assets |
|----------|------|-----|----------------|
| **Stateless API** | VM / PaaS | Deployment + Service | `../deploy-stateless-web/`, `../helm/web-app` |
| **.NET web** | App Service / IIS | Linux container on AKS/EKS | `../deploy-dotnet/`, healthchecks library |
| **Nginx edge** | Host nginx / IIS ARR | ConfigMap + Deployment | `../nginx/` |
| **Strangler** | Monolith URL space | Ingress/Nginx path split | `strangler-routing.md` |
| **Worker** | Windows service / cron | Deployment / CronJob | `../application-types/background-workers.md` |

## Process tie-in

1. Assess using `../../process/modernization-process.md`
2. Choose type under `../../application-types/`
3. Containerize + Helm or raw manifests
4. CI/CD from `../cicd/` (or Helm workflow)
5. Landing-zone checklist: `../../landing-zones/`
6. Post-cutover: `Automation/migration/*/post-migration-health-check*`

## Quick deploy (nginx front + API name)

```bash
kubectl apply -f ../nginx/
kubectl apply -f ../deploy-stateless-web/
# Ensure Service name web-api matches upstream in nginx ConfigMap
```
