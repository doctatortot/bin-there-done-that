# ZFS Strategy

ZFS is used across Genesis Hosting Technologies for performance, integrity, and snapshot-based backup operations.

## Pool Layout

- RAIDZ1 or mirrored vdevs depending on use case
- Dataset naming: `genesisassets-secure`, `genesisshows-secure`, etc.
- Dedicated pools for:
  - Mastodon media
  - Client backups
  - Internal scripts and logs

## Snapshots

- Hourly: last 24 hours
- Daily: last 7 days
- Weekly: last 4 weeks

## Send/Receive

- Used for offsite replication to Servarica and backup nodes
- Verified using checksums and `zfs receive -F`
