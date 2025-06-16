# Incident Response Policy

This document defines how we detect, respond to, and report security incidents.

## Response Workflow

1. Detection via monitoring, alert, or client report
2. Triage severity and affected systems
3. Contain and isolate threat (e.g., suspend access)
4. Notify stakeholders if client-impacting
5. Perform root cause analysis
6. Patch, re-secure, and document the event

## Timelines

- Initial triage: within 2 hours
- Client notification (if impacted): within 24 hours
- Final report delivered internally within 72 hours

## Tools Used

- Fail2Ban
- Genesis Shield alerting
- Zabbix/Prometheus incident flags
- Manual log reviews (forensic-level)
