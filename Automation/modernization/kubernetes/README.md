# Application Modernization to Kubernetes

Guidance, process, and examples for modernizing applications onto **Kubernetes** (EKS, AKS, GKE, or self-managed).

## Structure

```
kubernetes/
├── README.md                 # This file — overview & decision guide
├── process/
│   └── modernization-process.md
├── application-types/
│   ├── README.md
│   ├── stateless-web-api.md
│   ├── dotnet-appservice.md
│   ├── background-workers.md
│   ├── monolith-strangler.md
│   └── windows-iis-legacy.md
└── examples/
    ├── deploy-stateless-web/
    │   ├── Dockerfile
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── kustomization.yaml
    └── deploy-dotnet/
        ├── Dockerfile
        ├── deployment.yaml
        └── service.yaml
```

## When Kubernetes is a fit

| Good fit | Often not first target |
|----------|------------------------|
| Stateless APIs and web frontends | Commercial off-the-shelf with no container support |
| Microservices already loosely coupled | Heavy GUI / desktop apps |
| Batch/workers that scale horizontally | Large shared monolith with hard sticky sessions (until redesigned) |
| Apps with clear health endpoints | Databases — prefer managed data services, not pods as primary DB |

## Related repo paths

| Path | Use |
|------|-----|
| `Application/dotnet/healthchecks/` | ASP.NET Core `/health/live` + `/health/ready` |
| `Automation/recovery/kubernetes/` | Post-deploy error recovery scripts |
| `Automation/migration/` | Cloud migration + post-cutover health reports |
| `Automation/incident-response/` | Service playbooks |

## High-level phases

1. **Assess** — runtime, dependencies, state, sessions, jobs
2. **Containerize** — Dockerfile, non-root, config via env
3. **Platform map** — Deployment/StatefulSet, Service, Ingress, ConfigMap/Secret
4. **Observability** — logs, metrics, traces, probes
5. **CI/CD** — build image, scan, deploy (GitOps or pipeline)
6. **Cutover** — parallel run, traffic shift, rollback plan
7. **Optimize** — HPA, PDBs, resource requests/limits, cost

Details: [`process/modernization-process.md`](process/modernization-process.md).
