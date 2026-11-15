# Strangler routing example

Route modernized paths to Kubernetes while legacy stays on the old platform.

## Nginx ConfigMap sketch

```nginx
location /api/v2/ {
  proxy_pass http://web-api:80;
}
location / {
  proxy_pass http://legacy-upstream;  # externalName Service or legacy LB
}
```

## Kubernetes ExternalName (legacy)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: legacy-upstream
spec:
  type: ExternalName
  externalName: legacy.example.internal
```

## Cutover steps

1. Deploy v2 API in-cluster; verify `/health/ready`
2. Point only `/api/v2` via Nginx/Ingress
3. Expand paths as modules are extracted
4. Decommission legacy when traffic is zero
