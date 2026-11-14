# Incident Playbook: IIS (Internet Information Services)

**Last Updated:** 2026-11-14  
**Owner:** Platform / Windows  
**Related Services:** W3SVC, WAS, application pools, site bindings  
**Related Recovery Scripts:**  
- `Automation/recovery/windows/web-app-recovery.ps1` (includes W3SVC / WAS)  
- Application-specific Windows recovery scripts that depend on IIS  

---

## 1. Severity Guide

| Severity | Criteria | Response Expectation |
|----------|----------|----------------------|
| SEV-1 | All or majority of sites down / 503s across critical applications | Immediate |
| SEV-2 | Single critical site or app pool failing, high 5xx rate | Fast response |
| SEV-3 | Non-critical site or limited feature impact | Business hours |
| SEV-4 | Minor configuration or low-traffic site issue | Backlog |

---

## 2. Detection

**Common alerts:**
- W3SVC or WAS service stopped
- Application pool crashed or stuck
- High HTTP 5xx rate from IIS
- Site binding / certificate errors
- Queue length or request rejection spikes

**Primary dashboards:**
- IIS request rates, status codes, and latency
- Application pool state and recycles
- Windows service health (W3SVC, WAS)

**First logs to check:**
- IIS logs (`C:\inetpub\logs\LogFiles`)
- Event Viewer → Application and System (WAS, IIS-W3SVC, ASP.NET)
- stdout logs for the affected application pool (if enabled)

---

## 3. Immediate Actions (First 15 Minutes)

1. [ ] Acknowledge and declare incident if SEV-1/2
2. [ ] Assign Incident Commander
3. [ ] Identify affected sites / app pools / servers
4. [ ] Start timeline
5. [ ] Notify application owners of impacted sites

---

## 4. Diagnosis Checklist

- [ ] Recent IIS config, app deployment, or certificate change?
- [ ] W3SVC and WAS service status
- [ ] Application pool state (Started / Stopped / Starting)
- [ ] HTTP status codes and substatus (e.g. 503.2, 500.19)
- [ ] Event logs for WAS and IIS errors
- [ ] Disk space, memory, and CPU on the server
- [ ] Certificate validity and binding configuration
- [ ] web.config / applicationHost.config errors

---

## 5. Mitigation Options

| Option | When to use | How / Script | Risk |
|--------|-------------|--------------|------|
| Restart application pool | Single app pool unhealthy | IIS Manager / `Import-Module WebAdministration; Restart-WebAppPool` | Low |
| Restart W3SVC / WAS | Broader IIS failure | `web-app-recovery.ps1` or `Restart-Service W3SVC, WAS` | Medium |
| Recycle app pool | Memory growth or stuck requests | Recycle-WebAppPool | Low |
| Rollback application | Clear correlation with deploy | Deployment pipeline | Medium |
| Revert IIS config | Bad configuration change | Backup / previous config | Medium |

---

## 6. Communication

- Internal channel: #incident-iis or #incident-windows
- Application owners notified for user-facing impact
- Update frequency: SEV-1 every 15–30 min

---

## 7. Resolution & Verification

**Success criteria:**
- Affected sites returning 200s at normal rates
- Application pools in Started state
- W3SVC / WAS running
- No sustained critical errors in Event Log or IIS logs

**Post-recovery monitoring:** minimum 30–60 minutes

---

## 8. Post-Incident

- [ ] Timeline completed
- [ ] Blameless review scheduled
- [ ] Action items created
- [ ] Playbook and recovery scripts updated
- [ ] Consider chaos tests (app pool kill, W3SVC stop) in non-prod

---

## 9. Escalation

| Condition | Escalate to |
|-----------|-------------|
| SEV-1 lasting > 30 min | Platform / Windows lead |
| Underlying Windows or hardware issue | Infrastructure |
| Certificate / PKI issues | Security / PKI owner |
