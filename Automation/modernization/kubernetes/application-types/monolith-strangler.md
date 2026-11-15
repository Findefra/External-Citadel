# Type: Monolith (strangler pattern)

## Characteristics

- Large codebase, shared DB, mixed modules
- Cannot rewrite all at once

## Modernization path

1. **Containerize monolith as one Deployment** (rehost) for operational parity
2. **Identify seams** — auth, payments, notifications, read APIs
3. **Extract one capability** to a new Service; route via Ingress path or gateway
4. **Strangle** traffic gradually; keep shared DB until data ownership splits
5. **Repeat** extractions; shrink monolith

## Process emphasis

- Phase 1 assessment of module boundaries is mandatory
- Prefer API contracts and async integration over shared libraries for new services
- Each extracted service follows stateless-web or worker guides

## Pitfalls

- Distributed monolith (chatty sync calls, shared DB writes from many services)
- No correlation IDs across services → impossible debugging
