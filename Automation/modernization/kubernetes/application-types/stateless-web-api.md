# Type: Stateless web / API

## Characteristics

- HTTP/gRPC API or server-rendered web without local sticky state
- Horizontal scale-out safe
- Dependencies: DB, cache, IdP — external to the pod

## Modernization path

1. **Assess** — confirm no local session files or single-instance locks
2. **Containerize** — multi-stage Dockerfile; listen on `0.0.0.0`
3. **Deploy** — `Deployment` + `ClusterIP` Service + Ingress
4. **Probes** — liveness = process; readiness = app + critical deps
5. **Scale** — HPA on CPU or RPS
6. **Cutover** — blue/green or weighted DNS/ingress

## Example layout

See `../examples/deploy-stateless-web/`.

## Common pitfalls

- Readiness includes DB so one DB blip removes all pods — use careful timeouts and degradation strategy
- Missing resource requests → noisy-neighbor eviction
