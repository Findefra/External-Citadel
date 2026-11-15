# Application Modernization to Kubernetes

Guidance, process, and examples for modernizing applications onto **Kubernetes** (EKS, AKS, GKE, or self-managed).

## Structure

```
kubernetes/
├── README.md
├── process/
│   └── modernization-process.md
├── application-types/
│   ├── stateless-web-api.md
│   ├── dotnet-appservice.md
│   ├── background-workers.md
│   ├── monolith-strangler.md
│   └── windows-iis-legacy.md
└── examples/
    ├── deploy-stateless-web/
    ├── deploy-dotnet/
    └── cicd/
        ├── README.md
        ├── github-actions-dotnet-aks.yml
        ├── github-actions-stateless-ecr-eks.yml
        └── gitlab-ci-k8s.yml
```

## When Kubernetes is a fit

| Good fit | Often not first target |
|----------|------------------------|
| Stateless APIs and web frontends | COTS with no container support |
| Microservices already loosely coupled | Desktop / heavy GUI apps |
| Batch/workers that scale horizontally | Shared monolith with sticky sessions (until redesigned) |
| Apps with clear health endpoints | Databases as primary in-cluster state |

## CI/CD examples

See [`examples/cicd/`](examples/cicd/) for:

- **GitHub Actions** → ACR + AKS (.NET)
- **GitHub Actions** → ECR + EKS (stateless)
- **GitLab CI** → registry + kubectl deploy

Pattern: build → Trivy scan → push → `kubectl set image` / rollout → optional `/health/ready` smoke test.

## Related repo paths

| Path | Use |
|------|-----|
| `Application/dotnet/healthchecks/` | `/health/live` + `/health/ready` |
| `Automation/recovery/kubernetes/` | Runtime recovery scripts |
| `Automation/migration/` | Cloud migration + post-cutover reports |
| `Automation/incident-response/` | Service playbooks |

## High-level phases

1. Assess → 2. Containerize → 3. Platform map → 4. Observability → **5. CI/CD** → 6. Cutover → 7. Optimize

Details: [`process/modernization-process.md`](process/modernization-process.md).
