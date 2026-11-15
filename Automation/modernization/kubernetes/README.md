# Application Modernization to Kubernetes

Guidance, process, and examples for modernizing applications onto **Kubernetes** (EKS, AKS, GKE, or self-managed).

## Structure

```
kubernetes/
├── README.md
├── process/modernization-process.md
├── application-types/          # per-app-type guides
├── landing-zones/              # AKS/EKS pointers + checklist
└── examples/
    ├── deploy-stateless-web/
    ├── deploy-dotnet/
    ├── nginx/                  # ConfigMap, Deployment, Ingress, Helm values
    ├── helm/web-app/           # Reusable Helm chart
    ├── common-app-migrations/  # Strangler + scenario matrix
    └── cicd/                   # GitHub Actions + GitLab CI (+ Helm deploy)
```

## Quick links

| Need | Path |
|------|------|
| Full process | [`process/modernization-process.md`](process/modernization-process.md) |
| AKS/EKS landing pointers | [`landing-zones/`](landing-zones/) |
| Helm chart | [`examples/helm/web-app/`](examples/helm/web-app/) |
| Nginx on K8s | [`examples/nginx/`](examples/nginx/) |
| Common migration scenarios | [`examples/common-app-migrations/`](examples/common-app-migrations/) |
| CI/CD | [`examples/cicd/`](examples/cicd/) |

## CI/CD examples

- `github-actions-dotnet-aks.yml` — ACR + AKS
- `github-actions-stateless-ecr-eks.yml` — ECR + EKS
- `github-actions-helm-deploy.yml` — build + `helm upgrade --install`
- `gitlab-ci-k8s.yml` — GitLab build/scan/deploy

## Related repo paths

| Path | Use |
|------|-----|
| `Application/dotnet/healthchecks/` | `/health/live` + `/health/ready` |
| `Automation/recovery/kubernetes/` | Runtime recovery |
| `Automation/recovery/*nginx*` | Node-level nginx recovery |
| `Automation/migration/` | Cloud migration health reports |

## High-level phases

1. Assess → 2. Containerize → 3. Platform map → 4. Observability → 5. CI/CD → 6. Cutover → 7. Optimize
