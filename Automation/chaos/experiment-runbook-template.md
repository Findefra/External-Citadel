# Chaos Experiment Runbook Template

Reusable checklist and runbook for every chaos engineering experiment.

Copy this file for each new experiment and fill it out before, during, and after the run.

---

**Experiment Name:**  
**Date / Time:**  
**Environment:** (prod / staging / canary / namespace)  
**Owner:**  
**Participants / On-call notified:**  

---

## 1. Pre-Experiment Checklist

- [ ] Steady-state metrics are clearly defined and visible (error rate, latency, saturation, availability)
- [ ] Hypothesis is written and agreed
- [ ] Blast radius is intentionally small and documented
- [ ] Abort conditions are defined and can be detected quickly
- [ ] Observability is confirmed working (dashboards, logs, alerts)
- [ ] Recovery method is known and tested (manual + any automation/scripts)
- [ ] Stakeholders / on-call notified
- [ ] Experiment is scheduled during an appropriate window
- [ ] Rollback / stop procedure is clear

---

## 2. Experiment Definition

| Field | Details |
|-------|--------|
| **Hypothesis** | If we __________, then the system will __________ (within SLO). |
| **Steady State** | (e.g. error rate < 0.5%, p95 latency < 300ms, ≥ 2 ready pods) |
| **Failure Injected** | (e.g. kill 1 pod, add 200ms latency, terminate 1 instance, etc.) |
| **Blast Radius** | (scope, max impact, namespaces, % of fleet, etc.) |
| **Duration** | |
| **Tool / Method** | (kubectl, Chaos Mesh, Litmus, AWS FIS, script, etc.) |
| **Abort Conditions** | 1. <br>2. <br>3. |

---

## 3. Execution Steps

1. [ ] Record baseline metrics (screenshot or note values)
2. [ ] Start experiment / inject failure
3. [ ] Observe system behavior continuously
4. [ ] Watch abort conditions
5. [ ] Stop experiment (automatic duration or manual abort)
6. [ ] Confirm system returns to steady state
7. [ ] Capture final metrics and any alerts that fired

**Commands / Experiment Object used:**
```
(paste exact command or YAML here)
```

---

## 4. Observation Log

| Time | Observation | Metric / Impact | Action Taken |
|------|-------------|------------------|--------------|
|      |             |                  |              |
|      |             |                  |              |
|      |             |                  |              |

---

## 5. Results & Learning

**Did the hypothesis hold?**  
- [ ] Yes  
- [ ] Partially  
- [ ] No  

**What happened?**  
(Short factual summary)

**Recovery time / impact duration:**  

**What worked well?**  

**What was weaker than expected?**  

**Action Items** (create tickets if needed):
- [ ] 
- [ ] 
- [ ] 

**Should this experiment be repeated or made continuous?**  
- [ ] Yes – schedule / automate  
- [ ] No – one-time learning was sufficient  
- [ ] Modify and re-run  

---

## 6. Sign-off

| Role | Name | Timestamp |
|------|------|-----------|
| Experiment Owner |  |  |
| Reviewer (optional) |  |  |

---

**Notes / Links**  
- Dashboard:  
- Related recovery script:  
- Ticket / postmortem:  
