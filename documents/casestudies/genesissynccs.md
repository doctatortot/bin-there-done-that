# GenesisSync: Hybrid Object–Block Media Architecture for Broadcast Reliability and Scalable Archiving

## Executive Summary

GenesisSync is a hybrid storage architecture developed by Genesis Hosting Technologies to solve a persistent challenge in modern broadcast environments: enabling fast, local access for traditional DJ software while simultaneously ensuring secure, scalable, and redundant storage using object-based infrastructure.

The system has been implemented in a live production environment, integrating StationPlaylist (SPL), AzuraCast, Mastodon, and MinIO object storage with ZFS-backed block storage. GenesisSync enables near-real-time file synchronization, integrity checking, and disaster recovery with no vendor lock-in or reliance on fragile mount hacks.

---

## The Problem

- **SPL and similar DJ automation systems** require low-latency, POSIX-style file access for real-time media playback and cue-point accuracy.
- **Web-native applications** (like Mastodon and AzuraCast) operate more efficiently using scalable object storage (e.g., S3, MinIO).
- Legacy systems often can't interface directly with object storage without middleware or fragile FUSE mounts.
- Previous attempts to unify object and block storage often led to file locking issues, broken workflows, or manual copy loops.

---

## The GenesisSync Architecture

### Components

- **Primary Storage**: ZFS-backed local block volumes (ext4 or ZFS)
- **Backup Target**: MinIO object storage with S3-compatible APIs
- **Apps**: StationPlaylist (Windows via SMB), AzuraCast (Docker), Mastodon
- **Sync Tooling**: `rsync` for local, `mc mirror` for object sync

### Sync Strategy

- Local paths like `/mnt/azuracast` and `/mnt/stations` serve as the source of truth
- Hourly cronjob or systemd timer mirrors data to MinIO using:
  ```bash
  mc mirror --overwrite --remove /mnt/azuracast localminio/azuracast-backup
  ```
- Optionally, `rsync` is used for internal ZFS → block migrations

### Benefits

- 🎧 Local-first for performance-sensitive apps  
- ☁️ Cloud-capable for redundancy and long-term archiving  
- 🔁 Resilient to network blips, container restarts, or media sync delays  

---

## Real-World Implementation

| Component        | Role                                             |
|------------------|--------------------------------------------------|
| SPL              | Reads from ZFS mirror via SMB                   |
| AzuraCast        | Writes directly to MinIO via S3 API             |
| MinIO            | Remote object store for backups                 |
| ZFS              | Local resilience, snapshots, and fast access    |
| `mc`             | Handles object sync from local storage          |
| `rsync`          | Handles safe internal migration and deduplication |

### Recovery Drill

- Snapshot-based rollback with ZFS for quick recovery
- Verified `mc mirror` restore from MinIO to cold boot new environment

---

## Results

| Metric                        | Value                                  |
|-------------------------------|----------------------------------------|
| Playback latency (SPL)       | <10ms via local ZFS                    |
| Average mirror time (100MB)  | ~12 seconds                            |
| Recovery time (5GB)          | <2 minutes                             |
| Deployment size              | ~4.8TB usable                          |
| Interruption events          | 0 file-level issues since deployment   |

---

## Lessons Learned

- Object storage is powerful, but it's not a filesystem — don't pretend it is.
- Legacy apps need real disk paths — even if the data lives in the cloud.
- Syncing on your terms (with tools like `rsync` and `mc`) beats fighting with FUSE.
- Snapshot + mirror = peace of mind.

---

## Future Roadmap

- 📦 Add bidirectional sync detection for selective restores  
- ✅ Build in sync integrity verification (hash/diff-based)  
- 🔔 Hook Telegram alerts for failed syncs or staleness  
- 🌐 Publish GenesisSync as an open-source utility  
- 📄 Full documentation for third-party station adoption  

---

## About Genesis Hosting Technologies

Genesis Hosting Technologies operates media infrastructure for Genesis Radio and affiliated stations. With a focus on low-latency access, hybrid cloud flexibility, and disaster resilience, GenesisSync represents a foundational step toward a smarter, mirrored media future.

_"Fast on the air, safe on the backend."_
