# Least Privilege Policy

Genesis Hosting enforces least privilege access for all systems.

## Principles

- Users are given the minimum level of access necessary to perform their work
- Admin tools are isolated by function (e.g., billing vs. system access)
- Escalation of privileges must be requested, documented, and time-bound

## Tools in Use

- WHMCS permissions are restricted by group
- SSH access is limited using `AllowUsers` and firewalled IPs
- TeamTalk server admins are rotated and audited monthly

## Review Cycle

- Access roles are reviewed quarterly
- Logs of access changes are stored and rotated every 90 days
