# Incident Playbook: FreedomPay Application Server

**Last Updated:** 2026-11-14  
**Owner:** Payments / Platform  
**Related Services:** freedompay, freedompay-worker, freedompay-queue  
**Related Recovery Scripts:**  
- `Automation/recovery/ubuntu/freedompay-recovery.sh`  
- `Automation/recovery/redhat/freedompay-recovery.sh`  
- `Automation/recovery/windows/freedompay-recovery.ps1`  
- `Automation/recovery/kubernetes/freedompay-recovery.sh`  

---

## 1. Severity Guide

| Severity | Criteria | Response Expectation |
|----------|----------|----------------------|
| SEV-1 | Payments cannot be processed or high failure rate across merchants | Immediate |
| SEV-2 | Elevated payment failures or significant latency | Fast response |
| SEV-3 | Partial impact (single merchant tier, specific payment method) | Business hours |
| SEV-4 | Non-payment reporting or low-impact issue | Backlog |

---

## 2. Detection

**Common alerts:**
- Payment success rate drop
- High latency to FreedomPay or downstream processors
- Worker / queue backlog growth
- Certificate or SSL errors

**Primary dashboards:**
- Payment success / decline rates
- Worker and queue depth
- Dependency health (processors, network)

**First logs to check:**
- FreedomPay application logs
- Worker and queue logs
- SSL / certificate related errors

---

## 3. Immediate Actions (First 15 Minutes)

1. [ ] Acknowledge and declare incident if SEV-1/2
2. [ ] Assign Incident Commander
3. [ ] Assess impact (volume of failed payments, merchants affected)
4. [ ] Start timeline
5. [ ] Notify payments stakeholders and, if needed, prepare customer/merchant communications

---

## 4. Diagnosis Checklist

- [ ] Recent deploy or configuration change?
- [ ] FreedomPay service + worker + queue health
- [ ] Downstream payment processor status
- [ ] Certificate validity and TLS errors
- [ ] Network connectivity and DNS
- [ ] Queue backlog and worker concurrency
- [ ] Error patterns in application logs

---

## 5. Mitigation Options

| Option | When to use | How / Script | Risk |
|--------|-------------|--------------|------|
| Restart FreedomPay + workers/queue | Process crashes, stuck workers, memory issues | `freedompay-recovery` scripts | Low–Medium |
| Scale workers | Backlog / throughput issues | Platform scaling | Low |
| Rollback | Clear correlation with release | CD pipeline | Medium |
| Traffic / feature controls | Partial bad behavior | Flags or routing | Medium |

**Note:** Payment systems are sensitive—prefer low-risk mitigations first and avoid unnecessary restarts during peak transaction windows when possible.

---

## 6. Communication

- Internal channel: #incident-payments or #incident-freedompay
- Merchant / customer communications coordinated with payments/business owners for SEV-1
- Update frequency: SEV-1 every 15 min

---

## 7. Resolution & Verification

**Success criteria:**
- Payment success rate returned to normal baseline
- Queue depth healthy
- No critical errors in FreedomPay logs

**Post-recovery monitoring:** minimum 60 minutes, longer during peak periods

---

## 8. Post-Incident

- [ ] Timeline completed
- [ ] Blameless review scheduled
- [ ] Action items created
- [ ] Playbook and recovery scripts updated
- [ ] Consider chaos experiments around payment path dependencies

---

## 9. Escalation

| Condition | Escalate to |
|-----------|-------------|
| SEV-1 > 15–30 min | Payments lead + platform lead |
| Processor-side issue | Vendor support |
| Security / PCI concern | Security team |
