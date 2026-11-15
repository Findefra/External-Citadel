# AKS / EKS landing-zone pointers

This folder does **not** duplicate a full platform landing zone. It points at the patterns and repo areas to use when modernizing apps onto Kubernetes.

## Amazon EKS

| Concern | Guidance |
|---------|----------|
| Cluster | Private API optional; managed node groups or Fargate; multi-AZ |
| Networking | VPC CNI; security groups for pods as needed; limit public LBs |
| Auth | IRSA (IAM Roles for Service Accounts) for app AWS access |
| Registry | Amazon ECR |
| GitOps / CI | `examples/cicd/github-actions-stateless-ecr-eks.yml` |
| Post-cutover | `Automation/migration/aws/` + `Automation/migration/terraform/validate/` |
| Workload TF | `Automation/migration/terraform/modules/aws-mgn-prereqs` for rehost prereqs; app charts under `examples/helm/` |

**Official / reference**

- [Amazon EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [EKS Blueprints](https://aws-ia.github.io/terraform-aws-eks-blueprints/) (external module ecosystem)

## Azure AKS

| Concern | Guidance |
|---------|----------|
| Cluster | Azure CNI or overlay; availability zones; Azure Policy add-on optional |
| Auth | Azure AD RBAC; Workload Identity for Azure resources |
| Registry | Azure Container Registry (ACR) |
| GitOps / CI | `examples/cicd/github-actions-dotnet-aks.yml` |
| .NET health | `Application/dotnet/healthchecks/` + App Service playbooks when dual-running |
| Post-cutover | `Automation/migration/azure/` health reports |

**Official / reference**

- [AKS baseline architecture](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks)
- [AKS landing zone accelerator](https://learn.microsoft.com/azure/cloud-adoption-framework/scenarios/app-platform/aks/landing-zone-accelerator) (CAF)

## Shared app landing checklist

- [ ] Namespace per app or team + ResourceQuota/LimitRange
- [ ] Ingress / Gateway + TLS
- [ ] External managed DB/cache (not primary DB in-cluster)
- [ ] NetworkPolicy baseline (when enforced)
- [ ] Image pull from private registry only in prod
- [ ] Probes: `/health/live` + `/health/ready`
