# Type: Background workers & scheduled jobs

## Characteristics

- Queue consumers (Service Bus, SQS, Pub/Sub, RabbitMQ)
- Cron-style batch (reports, cleanup)
- Often no Ingress

## Modernization path

1. **Split** from web Deployment if currently in-process
2. **Deployment** for long-running consumers; **CronJob** for schedules
3. **Scaling** — KEDA or HPA on queue depth where available
4. **Probes** — liveness = process loop alive; readiness optional or “can pull work”
5. **Graceful shutdown** — handle `SIGTERM`, complete in-flight messages
6. **Idempotency** — safe retries on redelivery

## Pitfalls

- Same pod as web tier → web scale events multiply consumers unexpectedly
- No graceful termination → duplicate processing
