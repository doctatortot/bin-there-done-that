# Encryption Standards

Encryption is applied to all data in transit and at rest across Genesis Hosting Technologies infrastructure.

## In Transit

- HTTPS via TLS 1.3 (minimum TLS 1.2 for legacy fallback)
- SFTP for all file transfers
- SSH for all administrative access
- rclone with TLS for object storage replication

## At Rest

- ZFS encryption on backup pools
- PostgreSQL encryption at the database or filesystem level
- WHMCS and DirectAdmin credentials hashed and salted
- Backups encrypted with AES-256 before remote transfer

## Key Management

- SSH keys rotated every 6 months
- Let's Encrypt certs auto-renew every 90 days
- Master encryption keys stored offline and version-controlled
