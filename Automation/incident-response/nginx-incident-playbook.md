# Incident Playbook: Nginx

**Last Updated:** 2026-11-14  
**Owner:** Platform / Linux  
**Related Services:** nginx, upstream application backends  
**Related Recovery Scripts:**  
- `Automation/recovery/ubuntu/nginx-recovery.sh`  
- `Automation/recovery/redhat/nginx-recovery.sh`  
- `Automation/recovery/ubuntu/web-app-recovery.sh` / `redhat/web-app-recovery.sh` (include nginx as dependent)  

---

## 1. Severity Guide

| Severity | Criteria | Response Expectation |
|----------|----------|----------------------|
| SEV-1 | Nginx down or majority of traffic receiving 5xx / connection failures | Immediate |
| SEV-2 | Elevated 5xx, high latency, or single critical upstream failing | Fast response |
| SEV-3 | Non-critical vhost or limited path impact | Business hours |
| SEV-4 | Minor config or low-traffic site issue | Backlog |

---

## 2. Detection

**Common alerts:**
- nginx service down
- High rate of 5xx (especially 502 / 504)
- Upstream connection failures
- Certificate / TLS errors
- Worker connections or queue saturation

**Primary dashboards:**
- Request rate, status codes, latency
- Upstream health
- nginx stub_status / metrics endpoint

**First logs to check:**
- `/var/log/nginx/error.log`
- `/var/log/nginx/access.log` (for status code patterns)
- Upstream application logs
- `journalctl -u nginx`

---

## 3. Immediate Actions (First 15 Minutes)

1. [ ] Acknowledge and declare incident if SEV-1/2
2. [ ] Assign Incident Commander
3. [ ] Identify affected server blocks / upstreams / clients
4. [ ] Start timeline
5. [ ] Notify application owners of impacted traffic

---

## 4. Diagnosis Checklist

- [ ] Recent nginx config or upstream change?
- [ ] `systemctl status nginx` and process health
- [ ] `nginx -t` configuration test result
- [ ] Error log for upstream timeouts, SSL errors, or permission issues
- [ ] Upstream application health and connectivity
- [ ] File descriptor / worker connection limits
- [ ] Disk space for logs and temp paths
- [ ] Certificate expiry and TLS configuration

---

## 5. Mitigation Options

| Option | When to use | How / Script | Risk |
|--------|-------------|--------------|------|
| Reload nginx | Config-only change, graceful | `nginx-recovery.sh` (default prefers reload after `nginx -t`) | Low |
| Restart nginx | Process issues, stuck workers | `nginx-recovery.sh --force-restart` | Low–Medium |
| Disable bad upstream / server block | Single bad backend | Temporary config change + reload | Medium |
| Rollback config | Clear correlation with config change | Restore previous config + reload | Medium |
| Scale / fix upstreams | Backend saturation or failure | App recovery scripts / scaling | Low–Medium |

**Note:** Prefer `reload` over `restart` when possible to avoid dropping active connections.

---

## 6. Communication

- Internal channel: #incident-nginx or #incident-edge
- Application owners notified for user-facing impact
- Update frequency: SEV-1 every 15–30 min

---

## 7. Resolution & Verification

**Success criteria:**
- Traffic returning expected status codes at normal rates
- No sustained critical errors in `error.log`
- nginx service active and workers healthy
- Upstreams responding normally

**Post-recovery monitoring:** minimum 30–60 minutes

---

## 8. Post-Incident

- [ ] Timeline completed
- [ ] Blameless review scheduled
- [ ] Action items created
- [ ] Playbook and recovery scripts updated
- [ ] Consider chaos experiments (nginx stop, upstream failure, latency injection)

---

## 9. Escalation

| Condition | Escalate to |
|-----------|-------------|
| SEV-1 lasting > 30 min | Platform / Linux lead |
| Upstream application root cause | Application owners |
| Certificate / TLS issues | Security / PKI owner |
| Network / load balancer involvement | Network / infrastructure |
