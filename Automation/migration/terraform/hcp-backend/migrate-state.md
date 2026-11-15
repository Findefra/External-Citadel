# Runbook: Migrate state to HCP Terraform / TFE

## Preconditions

- [ ] No in-flight plans/applies
- [ ] Backup of current state
- [ ] HCP/TFE organization exists
- [ ] Token can lock workspaces
- [ ] Terraform >= 1.1 for `cloud {}`

## Steps

1. Record current backend
   ```bash
   terraform init
   terraform state pull > state-backup-$(date -u +%Y%m%dT%H%M%SZ).json
   terraform state list | tee state-list-pre.txt
   ```

2. Add cloud block from `backend.cloud.tf.example` (remove old `backend` blocks).

3. Authenticate: `terraform login` or `TF_TOKEN_app_terraform_io`.

4. Migrate: `terraform init` (confirm state copy).

5. Verify: `terraform state list` and `terraform plan`.

## Notes

- Target workspace should not hold unrelated state.
- For bulk TFE↔HCP moves, evaluate hashicorp-services/tfm.
- Stacks migration is a separate path from CE→HCP state migrate.
