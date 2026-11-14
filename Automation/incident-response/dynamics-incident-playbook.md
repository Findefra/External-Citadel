# Incident Playbook: Microsoft Dynamics App Server

**Last Updated:** 2026-11-14  
**Owner:** ERP / Platform  
**Related Services:** dynamics-aos, dynamics-batch, dynamics-management  
**Related Recovery Scripts:**  
- `Automation/recovery/ubuntu/dynamics-recovery.sh`  
- `Automation/recovery/redhat/dynamics-recovery.sh`  
- `Automation/recovery/windows/dynamics-recovery.ps1`  
- `Automation/recovery/kubernetes/dynamics-recovery.sh`  

---

## 1. Severity Guide

| Severity | Criteria | Response Expectation |
|----------|----------|----------------------|
| SEV-1 | Core ERP functions unavailable (orders, inventory, finance postings) for majority of users | Immediate |
| SEV-2 | Significant degradation, batch failures, or major module impact | Fast response |
| SEV-3 | Partial module or single-site impact with workaround | Business hours |
| SEV-4 | Minor reporting or non-critical feature issue | Backlog |

---

## 2. Detection

**Common alerts:**
- AOS (Application Object Server) down or unhealthy
- Batch service failures or backlog
- High SQL errors or connection pool exhaustion
- User login or form load failures

**Primary dashboards:**
- Dynamics AOS and batch health
- SQL Server / database metrics
- User session and transaction success rates

**First logs to check:**
- Dynamics AOS logs
- Batch service logs
- SQL error logs related to Dynamics

---

## 3. Immediate Actions (First 15 Minutes)

1. [ ] Acknowledge and declare incident if SEV-1/2
2. [ ] Assign Incident Commander
3. [ ] Determine scope (all users vs specific legal entity/module, interactive vs batch)
4. [ ] Start timeline
5. [ ] Notify ERP / finance / operations stakeholders if business processes are blocked

---

## 4. Diagnosis Checklist

- [ ] Recent Dynamics deploy, code promotion, or config change?
- [ ] AOS, batch, and management reporter service status
- [ ] Database connectivity, blocking, and performance
- [ ] Application event logs and Dynamics-specific logs
- [ ] Resource utilization on AOS and SQL hosts
- [ ] License / configuration / certificate issues
- [ ] Batch job status and history

---

## 5. Mitigation Options

| Option | When to use | How / Script | Risk |
|--------|-------------|--------------|------|
| Restart Dynamics AOS + dependents | Service-level failure, stuck processes | `dynamics-recovery` scripts (all platforms) | Medium |
| Restart batch service only | Batch-specific failures | Targeted dependent restart | Low–Medium |
| Clear stuck sessions / connections | Session or connection pool issues | Dynamics / SQL tools | Medium |
| Rollback | Clear correlation with recent change | Deployment / change process | Medium |
| Database intervention | Blocking, full transaction log, etc. | DBA runbook | Higher |

**Note:** Coordinate restarts with business owners during critical finance close or high-volume order periods when possible.

---

## 6. Communication

- Internal channel: #incident-dynamics or #incident-erp
- Business / finance / operations notification required for SEV-1/2
- Update frequency: SEV-1 every 15–30 min

---

## 7. Resolution & Verification

**Success criteria:**
- Users can log in and complete core transactions
- AOS and batch services healthy
- No sustained critical errors in Dynamics or SQL logs
- Batch jobs progressing normally

**Post-recovery monitoring:** minimum 60 minutes (longer during period-end or peak business windows)

---

## 8. Post-Incident

- [ ] Timeline completed
- [ ] Blameless review scheduled
- [ ] Action items created
- [ ] Playbook and recovery scripts updated
- [ ] Consider chaos experiments on AOS failure and database latency

---

## 9. Escalation

| Condition | Escalate to |
|-----------|-------------|
| SEV-1 lasting > 30 min | Platform lead + ERP owner |
| Database performance or corruption | DBA + Microsoft support if needed |
| Data integrity or financial posting risk | Finance / ERP business owner |
