# CI pattern: bump image tag in Git (Argo CD deploys)

Do **not** run `kubectl set image` / `helm upgrade` against production if Argo CD owns the app.

## Flow

1. CI builds and scans the image.
2. CI pushes to ECR/ACR/GHCR.
3. CI commits an update to desired state in Git:
   - Helm: change `image.tag` in values or Application `helm.parameters`
   - Kustomize: `images:` newTag
   - Plain YAML: update `image:` field via `sed`/yq in a config repo
4. Argo CD syncs (auto or manual).

## Example (values file in config repo)

```bash
yq -i ".image.tag = \"${GIT_SHA}\"" apps/web-app/values-dev.yaml
git commit -am "deploy(web-app): ${GIT_SHA}"
git push
```

## Example (Application helm parameter)

Update `application-web-app-helm.yaml`:

```yaml
helm:
  parameters:
    - name: image.tag
      value: "abc123def"
```

Prefer a **dedicated env/config repo** or protected paths for prod tags.

## Smoke tests

Keep `/health/ready` checks in CI **after** sync completes (poll Argo API or wait on URL), not instead of GitOps.
