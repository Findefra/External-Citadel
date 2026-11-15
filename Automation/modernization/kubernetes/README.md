# Application Modernization to Kubernetes

Guidance, process, and examples for modernizing applications onto **Kubernetes** (EKS, AKS, GKE, or self-managed).

## Structure

```
kubernetes/
├── README.md
├── process/modernization-process.md
├── application-types/
├── landing-zones/
└── examples/
    ├── deploy-stateless-web/
    ├── deploy-dotnet/
    ├── nginx/
    ├── helm/web-app/
    ├── common-app-migrations/
    ├── cicd/
    └── gitops/argocd/          # Argo CD Applications + AppProject
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
| **Argo CD GitOps** | [`examples/gitops/argocd/`](examples/gitops/argocd/) |

## GitOps (Argo CD)

Sample manifests:

- `AppProject` (`project-modernization.yaml`)
- Applications for **Helm web-app**, **nginx**, **dotnet**
- **App of Apps** root
- CI guidance: bump image tag in Git (`ci-bump-image-tag.md`)

## CI/CD examples

- ACR + AKS, ECR + EKS, Helm deploy, GitLab CI (see `examples/cicd/`)

## Related repo paths

| Path | Use |
|------|-----|
| `Application/dotnet/healthchecks/` | `/health/live` + `/health/ready` |
| `Automation/recovery/kubernetes/` | Runtime recovery |
| `Automation/migration/` | Cloud migration health reports |

## High-level phases

1. Assess → 2. Containerize → 3. Platform map → 4. Observability → 5. CI/CD / GitOps → 6. Cutover → 7. Optimize
