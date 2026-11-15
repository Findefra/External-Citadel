# Argo CD sync waves (short guide)

Control **apply order** inside an Application sync with:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"
```

## Rules

| Rule | Detail |
|------|--------|
| Default | `0` if omitted |
| Order | Lower wave first; same wave applies together |
| Gate | Next wave starts only after current wave is **healthy** |
| Negative | Allowed (e.g. `-5` for Namespace/CRDs) |
| Delete | Higher waves removed before lower |

**Precedence:** phase (PreSync → Sync → PostSync) → wave → kind → name.

Delay between waves defaults to ~2s (`ARGOCD_SYNC_WAVE_DELAY` on the application-controller).

## Suggested layout

| Wave | Resources |
|------|-----------|
| `-10` … `-5` | Namespace, CRDs |
| `-1` | ConfigMaps, Secrets, SA, RBAC, AnalysisTemplates |
| `0` | Deployment / Rollout, Service |
| `1` | Nginx / dependents |
| `2` | Ingress |
| `5`+ | Optional extras |

Use sparse numbers (`-10`, `-5`, `0`, `5`) so you can insert steps later.

## Example (API then nginx then Ingress)

```yaml
# Service + API workload
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "0"
---
# Nginx frontend (examples/nginx)
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"
---
# Ingress
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "2"
```

## Waves + hooks

| Annotation | Role |
|------------|------|
| `argocd.argoproj.io/sync-wave` | Order within a phase |
| `argocd.argoproj.io/hook: PreSync` | Jobs before normal resources (e.g. DB migrate) |
| `argocd.argoproj.io/hook: PostSync` | After resources healthy (smoke, notify) |
| `argocd.argoproj.io/hook-delete-policy` | Clean up hook Jobs |

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migrate
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/sync-wave: "-1"
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
```

## Notes

- Waves apply **inside one Application**. Ordering across Apps needs App-of-Apps waves or separate dependency design.
- Not the same as **Argo Rollouts** canary/blue-green (traffic). Waves order *apply*; Rollouts order *traffic* after objects exist.
- Prefer AnalysisTemplates / Config in wave `-1` before Rollouts in wave `0` (see `../argo-rollouts/`).

Official docs: [Sync waves](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/).
