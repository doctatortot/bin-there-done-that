# Backup Policy

Genesis Hosting Technologies maintains regular backups to ensure customer data and internal infrastructure are recoverable in the event of failure, corruption, or disaster.

## Backup Schedule

| System         | Frequency | Retention | Method           |
|----------------|-----------|-----------|------------------|
| DirectAdmin    | Daily     | 7 Days    | rsync + tarball  |
| WHMCS          | Daily     | 14 Days   | Encrypted dump   |
| AzuraCast      | Daily     | 7 Days    | Docker volume snapshot + config export |
| TeamTalk       | Daily     | 7 Days    | XML + config archive |
| Full VMs       | Weekly    | 4 Weeks   | ZFS snapshots or Proxmox backups       |
| Offsite Backups| Weekly    | 4 Weeks   | Rsync to remote ZFS or object storage  |

## Retention Policy

- Daily: 7 days
- Weekly: 4 weeks
- Monthly: Optional, for specific business data

## Encryption

- Backups are encrypted at rest (AES-256)
- Transfers to remote locations use SSH or TLS

## Notes

- No backup occurs on client plans marked "opt-out"
