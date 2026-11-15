# Argo CD GitOps examples

Sample **Argo CD Application** manifests for the modernization examples in this repo.

## Layout

| File | Purpose |
|------|--------|
| `application-web-app-helm.yaml` | Helm chart `examples/helm/web-app` |
| `application-nginx.yaml` | Nginx frontend manifests |
| `application-dotnet.yaml` | .NET raw manifests |
| `app-of-apps.yaml` | Root app that can point at a folder of Applications |
| `project-modernization.yaml` | Example AppProject boundaries |
| `ci-bump-image-tag.md` | How CI should update image tags in Git (not live kubectl) |

## Prerequisites

- Argo CD installed in the cluster (or management cluster)
- Repo reachable by Argo CD (public, or deploy key / GitHub App / PAT)
- Destination namespaces allowed by the Project

## Apply (bootstrap)

```bash
# From a machine authenticated to the cluster hosting Argo CD
kubectl apply -f project-modernization.yaml
kubectl apply -f application-web-app-helm.yaml
kubectl apply -f application-nginx.yaml
# Optional:
# kubectl apply -f application-dotnet.yaml
# kubectl apply -f app-of-apps.yaml
```

Replace `repoURL`, image parameters, and namespaces before production use.

## Related

- Chart: `../../helm/web-app/`
- Nginx: `../../nginx/`
- CI (build/scan/push): `../../cicd/`
- Landing zones: `../../../landing-zones/`
