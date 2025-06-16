# Disaster Recovery Plan

Genesis Hosting is prepared to recover core systems from catastrophic failure.

## Recovery Objectives

- **RPO (Recovery Point Objective)**: 24 hours
- **RTO (Recovery Time Objective)**: 4 hours for customer services

## Full Recovery Flow

1. Triage the affected systems
2. Identify last successful backup or snapshot
3. Restore individual services:
   - DNS
   - WHMCS
   - DirectAdmin
   - AzuraCast
   - TeamTalk
4. Run post-restore validation scripts
5. Notify customers of incident and resolution

## DR Testing

- Simulated quarterly
- Logs retained in `/var/log/genesisdr.log`
