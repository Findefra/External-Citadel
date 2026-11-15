# HCP Terraform / TFE backend migration snippets

Examples for migrating **Terraform state** to HCP Terraform (Terraform Cloud) or Terraform Enterprise.

## Files

| File | Purpose |
|------|--------|
| `backend.cloud.tf.example` | Copy to `cloud.tf` (or merge into existing `terraform {}` block) |
| `versions.tf` | Minimum Terraform version guidance |
| `migrate-state.md` | Step-by-step runbook |

## Quick path

1. Freeze applies on the old backend.
2. Add the `cloud` block (organization + workspace name).
3. `terraform login` (or set `TF_TOKEN_app_terraform_io`).
4. `terraform init` and confirm state copy when prompted.
5. Verify `terraform state list` and a no-op plan.

See `migrate-state.md` for TFE hostname, permissions, and rollback notes.
