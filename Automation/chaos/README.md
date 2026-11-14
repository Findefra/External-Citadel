# Chaos Engineering

Resources and templates for running controlled chaos experiments.

## Contents

| File | Description |
|------|-------------|
| `experiment-runbook-template.md` | Reusable checklist and runbook for every chaos experiment |

## How to use the Runbook Template

1. Copy `experiment-runbook-template.md` for each new experiment.
2. Fill out the Pre-Experiment Checklist and Experiment Definition **before** injecting any failure.
3. Use the Execution Steps and Observation Log during the run.
4. Complete Results & Learning and Sign-off afterward.
5. Store completed runbooks (or link them) so learnings accumulate over time.

## Related

- Application recovery scripts live under [`../recovery/`](../recovery/)
- Start with small blast radius and strong observability.
