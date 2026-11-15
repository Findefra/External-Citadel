# Incident Playbook: Azure App Service (.NET Web Application)

**Last Updated:** 2026-11-14  
**Owner:** Platform / Azure  
**Related Services:** Azure App Service, deployment slots, Application Insights, Kudu  
**Related Recovery Scripts:**  
- `Automation/recovery/azure/appservice-dotnet-recovery.ps1`  
- `Automation/recovery/azure/appservice-dotnet-recovery.sh`  

---

## 1. Severity Guide

| Severity | Criteria | Response Expectation |
|----------|----------|----------------------|
| SEV-1 | Site unavailable or majority of users failing (5xx / timeouts) | Immediate |
| SEV-2 | Elevated errors, severe latency, or single critical dependency failing | Fast response |
| SEV-3 | Partial impact, non-prod slot, or limited feature | Business hours |
| SEV-4 | Minor / cosmetic | Backlog |

---

## 2. Detection

**Common alerts:**
- Availability / synthetic monitor failures
- High 5xx rate (Application Insights or App Service metrics)
- HTTP queue length / response time spikes
- Health check failures
- Slot swap or deploy pipeline failures

**Primary dashboards:**
- Application Insights (failures, dependencies, exceptions)
- App Service metrics (Average Response Time, Http5xx, CpuTime)
- Azure Monitor alerts

**First places to check:**
- Portal → App Service → **Diagnose and solve problems**
- Log stream / `az webapp log tail`
- Application Insights **Failures** and **Exceptions** (.NET stack traces)
- Kudu (`https://<app>.scm.azurewebsites.net`)

---

## 3. Immediate Actions (First 15 Minutes)

1. [ ] Acknowledge and declare incident if SEV-1/2
2. [ ] Assign Incident Commander
3. [ ] Confirm blast radius (production vs slot, region, % of traffic)
4. [ ] Start timeline
5. [ ] Run status/diagnose via recovery script (dry-run or live)

```powershell
.\appservice-dotnet-recovery.ps1 -ResourceGroup <rg> -WebAppName <app> -Action Diagnose
```

---

## 4. Diagnosis Checklist

- [ ] Recent deploy or slot swap?
- [ ] App Service state (Running / Stopped) and instance count
- [ ] Health check path status
- [ ] Application Insights exceptions (NullReference, timeouts, HttpRequestException, OutOfMemory)
- [ ] Dependency failures (SQL, Redis, Key Vault, external APIs)
- [ ] Configuration / app settings / Key Vault references
- [ ] Certificate / custom domain / TLS issues
- [ ] Quotas / scale limits / SNAT port exhaustion (often shows as intermittent timeouts)

---

## 5. Mitigation Options

| Option | When to use | How / Script | Risk |
|--------|-------------|--------------|------|
| Restart App Service | Stuck process, memory leak, post-config hang | `-Action Restart` | Low–Medium (cold start) |
| Restart single instance | One bad instance in scale-out | `-Action RestartInstance -InstanceId <id>` | Low |
| **Slot swap (rollback)** | Bad production deploy, staging is known-good | `-Action Swap -Slot staging` | Medium (validate staging first) |
| Scale out | CPU/memory/SNAT pressure | Portal / `az appservice plan update` or scale settings | Low |
| Revert app settings | Bad configuration | Portal / ARM/Bicep/Terraform | Medium |

**Prefer slot swap over restart** when the issue correlates with a deployment.

---

## 6. Communication

- Internal channel: #incident-azure-web or #incident-app
- Status page for SEV-1/2 user impact
- Update frequency: SEV-1 every 15–30 min

---

## 7. Resolution & Verification

**Success criteria:**
- HTTP 5xx and latency back within SLO
- Health checks passing
- No new critical exceptions in Application Insights
- Dependencies healthy

**Post-recovery monitoring:** minimum 30–60 minutes (watch cold start and memory after restart)

---

## 8. Post-Incident

- [ ] Timeline completed
- [ ] Blameless review scheduled
- [ ] Action items created (probes, autoscaling, slot validation, App Insights alerts)
- [ ] Playbook / scripts updated
- [ ] Consider chaos: instance restart, dependency latency, slot swap drill

---

## 9. Escalation

| Condition | Escalate to |
|-----------|-------------|
| SEV-1 > 30 min | Platform / Azure owner |
| Platform / regional Azure issue | Azure support / platform lead |
| Data tier root cause | DBA / data team |
| Security / Key Vault | Security |
