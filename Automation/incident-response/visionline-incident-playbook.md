# Incident Playbook: Visionline (Door Lock) Application Server

**Last Updated:** 2026-11-14  
**Owner:** Platform / Property Systems  
**Related Services:** visionline, visionline-db, visionline-comm  
**Related Recovery Scripts:**  
- `Automation/recovery/ubuntu/visionline-recovery.sh`  
- `Automation/recovery/redhat/visionline-recovery.sh`  
- `Automation/recovery/windows/visionline-recovery.ps1`  
- `Automation/recovery/kubernetes/visionline-recovery.sh`  

---

## 1. Severity Guide

| Severity | Criteria | Response Expectation |
|----------|----------|----------------------|
| SEV-1 | Guests cannot lock/unlock doors or check-in/check-out blocked at scale | Immediate |
| SEV-2 | Significant number of rooms or properties impacted | Fast response |
| SEV-3 | Single property or limited feature impact | Business hours |
| SEV-4 | Minor reporting or non-critical function | Backlog |

---

## 2. Detection

**Common alerts:**
- Visionline service down / unhealthy
- High error rate in lock communication
- Database connectivity failures
- Integration failures with PMS / property systems

**Primary dashboards:**
- Visionline service health
- Lock communication success rate
- Related database and network metrics

**First logs to check:**
- Visionline application logs
- Communication / device gateway logs
- Database connectivity logs

---

## 3. Immediate Actions (First 15 Minutes)

1. [ ] Acknowledge and declare incident (SEV-1/2)
2. [ ] Assign Incident Commander
3. [ ] Determine scope (single property vs multiple, lock type, etc.)
4. [ ] Start timeline
5. [ ] Notify property operations / front-desk stakeholders if guest impact is occurring

---

## 4. Diagnosis Checklist

- [ ] Recent Visionline or related deploy/config change?
- [ ] Visionline service and dependent services status
- [ ] Database connectivity and performance
- [ ] Network path to door hardware / gateways
- [ ] Error patterns in application and communication logs
- [ ] Certificate or authentication issues with devices

---

## 5. Mitigation Options

| Option | When to use | How / Script | Risk |
|--------|-------------|--------------|------|
| Restart Visionline + dependents | Service-level failure, stuck processes | `visionline-recovery` scripts (all platforms) | Low–Medium |
| Restart communication component only | Device communication specific | Targeted dependent restart | Low |
| Database connection reset / failover | DB-related errors | DB runbook + recovery script | Medium |
| Rollback | Recent change correlated | CD / deployment tool | Medium |

**Note:** Always consider guest impact before restarting production Visionline components during peak check-in/out times.

---

## 6. Communication

- Internal channel: #incident-visionline (or equivalent)
- Property operations notification required for SEV-1/2
- Update frequency: SEV-1 every 15 min

---

## 7. Resolution & Verification

**Success criteria:**
- Lock/unlock operations succeeding at normal rates
- No critical errors in Visionline and communication logs
- Dependent services healthy

**Post-recovery monitoring:** at least 60 minutes (include a check-in/out window if possible)

---

## 8. Post-Incident

- [ ] Timeline completed
- [ ] Blameless review scheduled
- [ ] Action items created
- [ ] Playbook and recovery scripts updated
- [ ] Consider chaos experiment on Visionline components

---

## 9. Escalation

| Condition | Escalate to |
|-----------|-------------|
| SEV-1 lasting > 20–30 min | Platform lead + vendor support if needed |
| Hardware / gateway involvement | Field / property engineering |
| Database corruption or data integrity | DBA + vendor |
