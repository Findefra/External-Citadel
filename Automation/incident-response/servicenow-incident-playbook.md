# Incident Playbook: ServiceNow App Server / MID Server

**Last Updated:** 2026-11-14  
**Owner:** Platform / ITSM  
**Related Services:** servicenow, servicenow-mid  
**Related Recovery Scripts:**  
- `Automation/recovery/ubuntu/servicenow-recovery.sh`  
- `Automation/recovery/redhat/servicenow-recovery.sh`  
- `Automation/recovery/windows/servicenow-recovery.ps1`  
- `Automation/recovery/kubernetes/servicenow-recovery.sh`  

---

## 1. Severity Guide

| Severity | Criteria | Response Expectation |
|----------|----------|----------------------|
| SEV-1 | Core ITSM functions unavailable (incident/change/request) for large user base | Immediate |
| SEV-2 | Significant degradation or MID server integration failures impacting automation | Fast response |
| SEV-3 | Partial impact or single integration affected | Business hours |
| SEV-4 | Minor UI or non-critical reporting issue | Backlog |

---

## 2. Detection

**Common alerts:**
- ServiceNow application unavailable
- MID server down or not checking in
- ECC queue backlog
- Integration / discovery failures

**Primary dashboards:**
- ServiceNow health and transaction metrics
- MID server status and ECC queue
- Integration success rates

**First logs to check:**
- ServiceNow application logs
- MID server agent logs
- ECC queue related errors

---

## 3. Immediate Actions (First 15 Minutes)

1. [ ] Acknowledge and declare incident if SEV-1/2
2. [ ] Assign Incident Commander
3. [ ] Determine scope (platform-wide vs specific MID / integration)
4. [ ] Start timeline
5. [ ] Notify ITSM / service desk stakeholders

---

## 4. Diagnosis Checklist

- [ ] Recent ServiceNow or MID server changes?
- [ ] Application server health
- [ ] MID server status and last check-in time
- [ ] ECC queue depth and errors
- [ ] Network connectivity between MID and instance
- [ ] Credentials / certificate issues
- [ ] Resource utilization on app and MID hosts

---

## 5. Mitigation Options

| Option | When to use | How / Script | Risk |
|--------|-------------|--------------|------|
| Restart ServiceNow app server | App-level failure | `servicenow-recovery` scripts | Medium |
| Restart MID server | MID not checking in, integration failures | `servicenow-recovery` (MID dependent) | Low–Medium |
| Clear / reprocess ECC queue issues | Queue backlog (follow vendor guidance) | Manual + scripts | Medium |
| Rollback | Recent change correlated | Change process / deployment tool | Medium |

---

## 6. Communication

- Internal channel: #incident-servicenow or #incident-itsm
- Service desk notification required for user-facing impact
- Update frequency: SEV-1 every 15–30 min

---

## 7. Resolution & Verification

**Success criteria:**
- Users can create and update records normally
- MID servers checking in
- ECC queue healthy
- Key integrations functioning

**Post-recovery monitoring:** minimum 30–60 minutes

---

## 8. Post-Incident

- [ ] Timeline completed
- [ ] Blameless review scheduled
- [ ] Action items created
- [ ] Playbook and recovery scripts updated
- [ ] Consider chaos tests for MID connectivity and app server failure

---

## 9. Escalation

| Condition | Escalate to |
|-----------|-------------|
| SEV-1 lasting > 30 min | Platform lead + ServiceNow support if needed |
| Data integrity concerns | App owner + DBA |
| Security implication | Security team |
