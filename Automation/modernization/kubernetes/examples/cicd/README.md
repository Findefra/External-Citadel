# CI/CD workflow examples (Kubernetes modernization)

Sample pipelines that **build → scan → push → deploy** containerized apps to Kubernetes.

## Contents

| File | Platform | App style |
|------|----------|-----------|
| `github-actions-dotnet-aks.yml` | GitHub Actions | ASP.NET Core → AKS (kubectl + OIDC-friendly pattern) |
| `github-actions-stateless-ecr-eks.yml` | GitHub Actions | Generic API → ECR + EKS |
| `gitlab-ci-k8s.yml` | GitLab CI | Generic build/scan/deploy |

## Conventions

- Image tag = git SHA (`GITHUB_SHA` / `CI_COMMIT_SHORT_SHA`)
- Scan before push (Trivy)
- Deploy updates Deployment image via `kubectl set image` or Kustomize
- Smoke check against `/health/ready` when `HEALTH_URL` is set

## Secrets / variables (typical)

**GitHub:** `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` (OIDC), or cloud access keys; `KUBE_CONFIG` (base64) only if not using cloud OIDC kube login.

**GitLab:** `CI_REGISTRY_*`, `KUBECONFIG` file variable, `HEALTH_URL`.

Copy into `.github/workflows/` or `.gitlab-ci.yml` and replace placeholders (`REGISTRY`, `RESOURCE_GROUP`, `CLUSTER`, namespaces).
