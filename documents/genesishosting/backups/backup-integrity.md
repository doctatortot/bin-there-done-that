# Backup Integrity

We verify all backups regularly to ensure they are complete, uncorrupted, and restorable.

## Weekly Tasks

- ZFS scrubs for all pools
- Hash checks (SHA-256) for tarballs and dumps
- rsync `--checksum` verification for remote mirrors

## Alerts

- Email/Mastodon alert if:
  - ZFS reports checksum errors
  - Scheduled backup is missing
  - Remote sync fails or lags > 24h

## Tools Used

- `zfs scrub`
- `sha256sum` + custom validation script
- rclone sync logs
- Telegram bot and Genesis Shield notifications
