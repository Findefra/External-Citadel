# Incident Playbook: Workday Integration / Adapter / Agent

**Last Updated:** 2026-11-14  
**Owner:** HRIS / Platform  
**Related Services:** workday-adapter, workday-agent  
**Related Recovery Scripts:**  
- `Automation/recovery/ubuntu/workday-recovery.sh`  
- `Automation/recovery/redhat/workday-recovery.sh`  
- `Automation/recovery/windows/workday-recovery.ps1`  
- `Automation/recovery/kubernetes/workday-recovery.sh`  

---

## 1. Severity Guide

| Severity | Criteria | Response Expectation |
|----------|----------|----------------------|
| SEV-1 | Critical HR/payroll integrations down (e.g. hire, terminate, pay-impacting feeds) for large population | Immediate |
| SEV-2 | Significant integration failures or delayed syncs affecting multiple processes | Fast response |
| SEV-3 | Single integration or non-critical feed impacted | Business hours |
| SEV-4 | Minor reporting or low-impact sync issue | Backlog |

---

## 2. Detection

**Common alerts:**
- Workday adapter / agent down or unhealthy
- Integration job failures
- API / SOAP timeout or authentication errors
- Data sync lag beyond threshold

**Primary dashboards:**
- Integration success / failure rates
- Adapter and agent health
- Downstream system sync status

**First logs to check:**
- Workday adapter logs
- Workday agent logs
- API / authentication error messages

---

## 3. Immediate Actions (First 15 Minutes)

1. [ ] Acknowledge and declare incident if SEV-1/2
2. [ ] Assign Incident Commander
3. [ ] Determine scope (which integrations, which direction of data flow, population impacted)
4. [ ] Start timeline
5. [ ] Notify HRIS / HR operations stakeholders if employee or payroll impact is possible

---

## 4. Diagnosis Checklist

- [ ] Recent Workday, adapter, or agent changes?
- [ ] Adapter and agent service health
- [ ] Workday API / tenant availability and credentials
- [ ] Network connectivity and DNS
- [ ] Certificate or OAuth/token issues
- [ ] Queue or job backlog on either side
- [ ] Error patterns in adapter and agent logs

---

## 5. Mitigation Options

| Option | When to use | How / Script | Risk |
|--------|-------------|--------------|------|
| Restart Workday adapter + agent | Process crashes, stuck jobs, memory issues | `workday-recovery` scripts (all platforms) | Low–Medium |
| Restart agent only | Agent-specific failures | Targeted dependent restart | Low |
| Re-run failed integration jobs | After connectivity restored | Workday / middleware tools | Medium |
| Rollback | Clear correlation with recent change | CD / change process | Medium |

**Note:** Be cautious with restarts during active payroll or mass-hire windows. Coordinate with HRIS when impact is employee-facing.

---

## 6. Communication

- Internal channel: #incident-workday or #incident-hris
- HR / HRIS notification required for SEV-1/2 with employee or payroll impact
- Update frequency: SEV-1 every 15–30 min

---

## 7. Resolution & Verification

**Success criteria:**
- Critical integrations succeeding at normal rates
- Adapter and agent healthy
- No sustained API or authentication errors
- Sync lag returned to acceptable levels

**Post-recovery monitoring:** minimum 60 minutes (longer if near payroll or major HR events)

---

## 8. Post-Incident

- [ ] Timeline completed
- [ ] Blameless review scheduled
- [ ] Action items created
- [ ] Playbook and recovery scripts updated
- [ ] Consider chaos experiments on adapter/agent failure and API latency

---

## 9. Escalation

| Condition | Escalate to |
|-----------|-------------|
| SEV-1 lasting > 30 min | Platform lead + HRIS owner |
| Workday tenant / vendor-side issue | Workday support |
| Data integrity or payroll risk | HRIS lead + appropriate business owners |
