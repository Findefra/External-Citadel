# Incident Response Playbooks

Actionable playbooks for detecting, responding to, containing, and learning from incidents.

## Contents

| File | Description |
|------|-------------|
| `generic-incident-playbook-template.md` | Reusable template for any new playbook |
| `web-app-incident-playbook.md` | Web application incidents |
| `visionline-incident-playbook.md` | Visionline (door lock) application server |
| `freedompay-incident-playbook.md` | FreedomPay payment application server |
| `servicenow-incident-playbook.md` | ServiceNow app server / MID server |

## Related Automation

Recovery scripts live in [`../recovery/`](../recovery/) and are referenced inside each service playbook under **Mitigation Options**.

Chaos experiment runbooks live in [`../chaos/`](../chaos/).

## How to use

1. Start with the **generic template** when creating a new playbook.
2. Use the service-specific playbooks during real incidents.
3. After every major incident, update the relevant playbook with what you learned.
4. Test playbooks during game days and chaos experiments.
