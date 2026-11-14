# Incident Playbook: [Service / Symptom Name]

**Last Updated:** YYYY-MM-DD  
**Owner:**  
**Related Services:**  
**Related Recovery Scripts:**  

---

## 1. Severity Guide

| Severity | Criteria | Response Expectation |
|----------|----------|----------------------|
| SEV-1 | Full outage or major customer/safety/payment impact | Immediate response, Incident Commander assigned |
| SEV-2 | Significant degradation, high error rate, or partial outage | Fast response (< 15 min) |
| SEV-3 | Partial impact, workaround exists | Business hours or next available |
| SEV-4 | Minor / cosmetic / low user impact | Backlog |

---

## 2. Detection

**Common alerts:**
- 

**Primary dashboards:**
- 

**First logs / traces to check:**
- 

---

## 3. Immediate Actions (First 15 Minutes)

1. [ ] Acknowledge the alert and declare the incident (if SEV-1/2)
2. [ ] Assign Incident Commander
3. [ ] Quickly assess blast radius and confirm severity
4. [ ] Start a timeline (who, what, when)
5. [ ] Notify stakeholders / open incident channel (if required)
6. [ ] Page additional help if needed

---

## 4. Diagnosis Checklist

- [ ] Check recent deployments, config changes, or feature flags
- [ ] Check dependency health (DB, cache, upstream/downstream services)
- [ ] Review error rate, latency, saturation, and availability metrics
- [ ] Inspect application and system logs
- [ ] Check resource utilization (CPU, memory, disk, connections, file descriptors)
- [ ] Verify network / DNS / certificate issues if relevant
- [ ] Confirm whether the issue is isolated or wider

---

## 5. Mitigation Options

| Option | When to use | How / Script | Risk |
|--------|-------------|--------------|------|
| Restart service / pods | Process-level failure, memory leak, stuck workers | See recovery scripts | Low |
| Rollback | Recent deploy strongly correlated | Pipeline / kubectl / Terraform | Medium |
| Scale up / add capacity | Resource exhaustion | HPA / ASG / manual scale | Low–Medium |
| Traffic shift / feature flag | Bad version or partial failure | Flag system / weighted service | Medium |
| Failover | Regional or dependency failure | Documented failover procedure | Higher |

**Recovery scripts location:** `Automation/recovery/`

---

## 6. Communication

- **Internal channel:** 
- **Status page / customer updates:** 
- **Update frequency:** SEV-1 every 15–30 min, SEV-2 every 30–60 min
- **Stakeholder list:** 

---

## 7. Resolution & Verification

**Steps to fully restore:**
1. 
2. 
3. 

**Success criteria (back to steady state):**
- Error rate and latency within SLO
- All critical dependencies healthy
- No active pages related to this incident

**Post-recovery monitoring window:** at least 30–60 minutes

---

## 8. Post-Incident

- [ ] Timeline completed
- [ ] Blameless review scheduled
- [ ] Action items created and assigned
- [ ] Playbook updated with new learnings
- [ ] Related chaos experiment or test case considered

---

## 9. Escalation

| Condition | Escalate to |
|-----------|-------------|
| SEV-1 lasting > 30 min |  |
| Security implications |  |
| Data integrity risk |  |
| Need for vendor support |  |

---

**Notes / Links**
- Dashboards:
- Runbooks / recovery scripts:
- Architecture diagram:
- Previous related incidents:
