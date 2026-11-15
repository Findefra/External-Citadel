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
    └── gitops/
        ├── argocd/           # Argo CD Applications + AppProject
        └── argo-rollouts/    # Canary, blue-green, AnalysisTemplates
```

## Quick links

| Need | Path |
|------|------|
| Full process | [`process/modernization-process.md`](process/modernization-process.md) |
| AKS/EKS landing pointers | [`landing-zones/`](landing-zones/) |
| Helm chart | [`examples/helm/web-app/`](examples/helm/web-app/) |
| Nginx on K8s | [`examples/nginx/`](examples/nginx/) |
| CI/CD | [`examples/cicd/`](examples/cicd/) |
| **Argo CD GitOps** | [`examples/gitops/argocd/`](examples/gitops/argocd/) |
| **Argo Rollouts** | [`examples/gitops/argo-rollouts/`](examples/gitops/argo-rollouts/) |

## Progressive delivery (Argo Rollouts)

- AnalysisTemplates: Prometheus success rate + web `/health/ready`
- **Canary** Rollout with step weights, pauses, and analysis
- **Blue-green** Rollout with active/preview Services, manual promote, pre/post analysis

## Related repo paths

| Path | Use |
|------|-----|
| `Application/dotnet/healthchecks/` | `/health/live` + `/health/ready` |
| `Automation/recovery/kubernetes/` | Runtime recovery |
| `Automation/migration/` | Cloud migration health reports |

## High-level phases

1. Assess → 2. Containerize → 3. Platform map → 4. Observability → 5. CI/CD / GitOps → 6. Cutover → 7. Optimize
