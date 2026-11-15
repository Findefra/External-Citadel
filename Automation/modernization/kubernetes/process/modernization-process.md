# Detailed Process: Modernize an Application to Kubernetes

This process applies across application types. Type-specific notes live under `../application-types/`.

---

## Phase 0 — Framing

**Goals (pick explicit ones)**

- Density / cost, faster deploys, scaling, resilience, standard ops model, exit from VMs/App Service/IIS

**Non-goals (examples)**

- Rewriting business logic in one step
- Moving databases into the cluster as day-1

**Outputs**

- Target cluster (EKS/AKS/GKE), environments (dev/stage/prod), success metrics (deploy frequency, p95, error rate, MTTR)

---

## Phase 1 — Assessment

### 1.1 Application profile

| Question | Why it matters |
|----------|----------------|
| Language/runtime and versions | Base image, support lifecycle |
| Stateless vs sticky sessions | Session store (Redis) vs ingress affinity |
| Local disk usage | EmptyDir vs PVC vs object storage |
| Background threads / scheduled jobs | Separate Deployments/CronJobs |
| Windows-only dependencies | Windows node pools vs replatform |
| External config (files, registry, IIS metabase) | ConfigMaps, env, secrets |
| Auth integration | Sidecar, gateway, app-level OIDC |

### 1.2 Dependency map

- Databases, caches, message brokers, file shares, SMTP, SaaS APIs
- Prefer **managed** DB/cache outside the cluster; apps in Kubernetes talk to them over private networking

### 1.3 Operational baseline

- Current SLOs, peak RPS, deployment method, rollback time
- Existing health URLs (or plan to add `/health/live` and `/health/ready`)

### 1.4 Decision: modernization style

| Style | Description |
|-------|-------------|
| **Rehost (lift container)** | Package as-is into container; minimal code change |
| **Replatform** | 12-factor config, health probes, externalize state |
| **Refactor** | Split modules, async boundaries, strangler extraction |
| **Retain / replace** | Keep on VM/PaaS or replace with SaaS |

---

## Phase 2 — Containerization

### 2.1 Dockerfile principles

- Multi-stage builds; small runtime image
- Non-root user; read-only root FS where possible
- No secrets baked into image
- Explicit `EXPOSE`; process runs in foreground (PID 1 awareness / init)

### 2.2 Configuration

- Environment variables and mounted config for environment-specific values
- Secrets from Kubernetes Secrets, CSI driver, or external manager (Key Vault, AWS SM, GCP SM)

### 2.3 Validation locally

```bash
docker build -t myapp:dev .
docker run --rm -p 8080:8080 -e ASPNETCORE_URLS=http://0.0.0.0:8080 myapp:dev
curl -sS http://127.0.0.1:8080/health/ready
```

---

## Phase 3 — Kubernetes design

### 3.1 Core objects

| Object | Typical use |
|--------|-------------|
| **Deployment** | Stateless web/API/workers |
| **StatefulSet** | Rare app-level sticky identity; not default for business apps |
| **Service** | ClusterIP for internal; LB/Ingress for edge |
| **Ingress / Gateway API** | HTTP routing, TLS |
| **ConfigMap / Secret** | Config and credentials |
| **HPA** | CPU/memory or custom metrics scaling |
| **PDB** | Availability during voluntary disruption |
| **NetworkPolicy** | East-west restriction (when CNI supports) |

### 3.2 Probes

| Probe | Endpoint intent |
|-------|-----------------|
| **liveness** | Process stuck → restart (`/health/live`) |
| **readiness** | Ready for traffic (`/health/ready` includes deps) |
| **startup** | Slow cold start (.NET, Java) without killing the pod |

### 3.3 Resources

- Set **requests** (scheduling) and **limits** (cap)
- Right-size from observed usage after soak tests

---

## Phase 4 — Observability & security

- Structured logs to stdout/stderr → cluster log stack
- Metrics (Prometheus style) and optional traces
- Image scan in CI; minimal RBAC; non-root; network policies as maturity allows
- Pod Security Standards / restricted profile where feasible

---

## Phase 5 — CI/CD and GitOps

1. Build image → tag with git SHA
2. Scan (Trivy/Grype/etc.)
3. Push to registry (ECR/ACR/Artifact Registry)
4. Deploy via pipeline (`kubectl`/`helm`) or GitOps (Argo CD/Flux)
5. Smoke test (`/health/ready`, synthetic transaction)

---

## Phase 6 — Cutover

1. Deploy to non-prod; run load and failure tests
2. Prod deploy alongside existing system if possible
3. Shift traffic (DNS weighted, ingress, load balancer)
4. Monitor error rate, latency, saturation
5. Rollback: previous image/tag or traffic shift back
6. Decommission old hosting after stability window

Use recovery scripts under `Automation/recovery/kubernetes/` if automated restarts are part of ops.

---

## Phase 7 — Optimize

- HPA + optional VPA/recommendations
- PodDisruptionBudgets and multi-AZ topology
- Cost: rightsizing, spot/preemptible for non-prod workers
- Chaos experiments on pod kill and dependency latency (see `Automation/chaos/`)

---

## Exit criteria (definition of done)

- [ ] Image builds reproducibly in CI
- [ ] Probes green under normal and dependency-degraded scenarios (ready fails, live stays up)
- [ ] Requests/limits and PDB set in prod
- [ ] Runbook / incident playbook updated
- [ ] Rollback tested once
- [ ] Post-deploy health validation documented
