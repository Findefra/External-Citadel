# Argo Rollouts examples

Progressive delivery samples aligned with the Kubernetes modernization tree.

## Prerequisites

```bash
kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
```

Optional CLI: [kubectl argo rollouts plugin](https://argo-rollouts.readthedocs.io/en/stable/installation/#kubectl-plugin-installation).

## Layout

| Path | Purpose |
|------|--------|
| `analysis/prometheus-success-rate.yaml` | AnalysisTemplate — Prometheus success rate |
| `analysis/web-health-ready.yaml` | AnalysisTemplate — HTTP `/health/ready` |
| `canary/` | Canary Rollout + Service + analysis wiring |
| `bluegreen/` | Blue-green Rollout + active/preview Services + analysis stubs |

## Apply order (non-prod namespace)

```bash
NS=dev-web
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n "$NS" -f analysis/
kubectl apply -n "$NS" -f canary/
# or
kubectl apply -n "$NS" -f bluegreen/
```

Replace image repos, Prometheus URL, and Service names for your cluster.

## Day-2 commands

```bash
kubectl argo rollouts get rollout web-api-canary -n dev-web -w
kubectl argo rollouts promote web-api-canary -n dev-web
kubectl argo rollouts abort web-api-canary -n dev-web

kubectl argo rollouts promote web-api-bluegreen -n dev-web
```

## GitOps

Point an Argo CD Application at this directory (or `canary/` / `bluegreen/` only).
CI should bump the image tag in Git; promote/abort remain Rollouts runtime operations.

See also: `../argocd/` for Application manifests.
