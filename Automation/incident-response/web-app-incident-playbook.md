# Incident Playbook: Web Application

**Last Updated:** 2026-11-14  
**Owner:** Platform / App Team  
**Related Services:** web-app, nginx/httpd/IIS, Redis/cache, database  
**Related Recovery Scripts:**  
- `Automation/recovery/ubuntu/web-app-recovery.sh`  
- `Automation/recovery/redhat/web-app-recovery.sh`  
- `Automation/recovery/windows/web-app-recovery.ps1`  
- `Automation/recovery/kubernetes/web-app-recovery.sh`  

---

## 1. Severity Guide

| Severity | Criteria | Response Expectation |
|----------|----------|----------------------|
| SEV-1 | Site fully down or > 50% error rate for majority of users | Immediate |
| SEV-2 | Elevated errors, major feature broken, or high latency | Fast response |
| SEV-3 | Partial degradation or single region/feature impact | Business hours |
| SEV-4 | Cosmetic or very low impact | Backlog |

---

## 2. Detection

**Common alerts:**
- High 5xx rate
- p95/p99 latency breach
- Pod / instance unhealthy
- Certificate or ingress errors

**Primary dashboards:**
- Application golden signals (latency, traffic, errors, saturation)
- Kubernetes / load balancer dashboards

**First logs to check:**
- Application logs
- Ingress / reverse proxy error logs
- Kubernetes events

---

## 3. Immediate Actions (First 15 Minutes)

1. [ ] Acknowledge alert and declare incident if SEV-1/2
2. [ ] Assign Incident Commander
3. [ ] Confirm blast radius (all users? single region? specific endpoint?)
4. [ ] Start timeline
5. [ ] Open incident channel and notify stakeholders if needed

---

## 4. Diagnosis Checklist

- [ ] Recent deploy or config change?
- [ ] Dependency health (DB, cache, external APIs)
- [ ] Current error rate, latency, and saturation
- [ ] Pod / instance readiness and resource usage
- [ ] Ingress / load balancer target health
- [ ] Application and proxy logs for stack traces or upstream errors

---

## 5. Mitigation Options

| Option | When to use | How / Script | Risk |
|--------|-------------|--------------|------|
| Restart app pods / service | Stuck workers, memory issues, process crashes | `kubernetes/web-app-recovery.sh` or OS-specific web-app-recovery | Low |
| Restart proxy (nginx/httpd) | Proxy-level errors | OS recovery scripts include proxy dependents | Low |
| Rollback | Clear correlation with recent release | CD pipeline / `kubectl rollout undo` | Medium |
| Scale up | Traffic spike or resource exhaustion | HPA / manual scale | Low |
| Feature flag / traffic shift | Bad version or partial failure | Flag system | Medium |

---

## 6. Communication

- Internal channel: #incident-web (or equivalent)
- Status page: update for SEV-1/2
- Update frequency: SEV-1 every 15–30 min

---

## 7. Resolution & Verification

**Success criteria:**
- Error rate and latency back within SLO
- All pods/instances healthy and ready
- No related active alerts

**Post-recovery monitoring:** minimum 30–60 minutes

---

## 8. Post-Incident

- [ ] Timeline completed
- [ ] Blameless review scheduled
- [ ] Action items created
- [ ] Playbook and recovery scripts updated if needed
- [ ] Consider adding/adjusting a chaos experiment

---

## 9. Escalation

| Condition | Escalate to |
|-----------|-------------|
| SEV-1 > 30 min | Engineering manager / platform lead |
| Database involvement | Data / DBA on-call |
| Edge / CDN / DNS | Network / infrastructure |
