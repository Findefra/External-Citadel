# Helm examples

## web-app chart

```bash
helm upgrade --install demo ./web-app \
  --namespace demo --create-namespace \
  --set image.repository=REGISTRY/web-api \
  --set image.tag=GIT_SHA \
  --set probes.startup.enabled=true
```

Use with CI: build/push image, then `helm upgrade --install ... --set image.tag=$SHA`.
