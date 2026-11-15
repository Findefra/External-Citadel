# Nginx modernization examples

Patterns for running **Nginx** on Kubernetes as edge proxy or static front door during app migration.

## Layout

| File | Purpose |
|------|--------|
| `ConfigMap-nginx.conf` | Sample reverse-proxy config to upstream Service |
| `deployment.yaml` | Nginx Deployment with config mount |
| `service.yaml` | ClusterIP Service |
| `ingress.yaml` | Optional Ingress to Nginx or direct to app |
| `values-nginx-frontend.yaml` | Helm value overrides when using `../helm/web-app` as a frontend shell |

## Common migration uses

1. **Strangler** — Nginx routes `/api/v2` to new K8s service, `/` to legacy.
2. **Static + API** — Nginx serves SPA; proxies API to `web-api` Service.
3. **TLS termination at Ingress** — Nginx stays internal ClusterIP.

Pair with incident/recovery:

- `Automation/incident-response/nginx-incident-playbook.md`
- `Automation/recovery/ubuntu|redhat/nginx-recovery.sh` (node-level)
