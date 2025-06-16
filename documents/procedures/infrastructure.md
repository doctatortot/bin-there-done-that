# 📊 Genesis Radio Infrastructure Overview
**Date:** April 30, 2025  
**Prepared by:** Doc

---

## 🏗️ Infrastructure Summary

Genesis Radio now operates a fully segmented, secure, and performance-tuned backend suitable for enterprise-grade broadcasting and media delivery. The infrastructure supports high availability (HA) principles for storage and platform independence for core services.

---

## 🧱 Core Components

### 🎙️ Genesis Radio Services
- **StationPlaylist (SPL)**: Windows-based automation system, mounts secure object storage as drives via rclone
- **Voice Tracker (Remote Access)**: Synced with SPL backend and available to authorized remote users
- **Azuracast (Secondary automation)**: Dockerized platform running on dedicated VM
- **Mastodon (Community)**: Hosted in Docker with separate PostgreSQL cluster and MinIO object storage

---

## 💾 Storage Architecture

| Feature                      | Status                    |
|-----------------------------|---------------------------|
| Primary Storage Backend     | MinIO on `shredderv2`     |
| Storage Filesystem          | ZFS RAID-Z1               |
| Encryption                  | Enabled (per-bucket S3 SSE) |
| Buckets (Scoped)            | `genesislibrary-secure`, `genesisassets-secure`, `genesisshows-secure`, `mastodonassets-secure` |
| Snapshot Capability         | ✅ (ZFS native snapshots)  |
| Caching                     | SSD-backed rclone VFS cache per mount |

---

## 🛡️ Security & Access Control

- TLS for all services (Let's Encrypt)
- MinIO Console behind HTTPS (`consolev2.sshjunkie.com`)
- User policies applied per-bucket (read/write scoped)
- Server-to-server rsync/rclone over SSH

---

## 🔄 Backup & Recovery

- Dedicated backup server with SSH access
- Nightly rsync for show archives and Mastodon data
- Snapshot replication via `zfs send | ssh backup zfs recv` planned
- Manual and automated snapshot tools

---

## 🔍 Monitoring & Observability

| Component         | Status       | Notes                        |
|------------------|--------------|------------------------------|
| System Monitoring| `vmstat`, `watch`, custom CLI tools |
| Log Aggregation  | Centralized on pyapps VM |
| Prometheus       | Partial (used with ClusterControl) |
| Alerts           | Mastodon warning bot, Telegram planned |

---

## 🚦 Current Migration Status

| Component        | Status         | Notes                          |
|------------------|----------------|---------------------------------|
| Mastodon Assets  | ✅ Migrated     | Verified, encrypted, ZFS snapshotted |
| Genesis Library  | ✅ Migrated     | Synced from backup server      |
| Genesis Assets   | ✅ Migrated     | Cleanup of shows in progress   |
| Genesis Shows    | ✅ Migrated     | Pulled from same source, cleanup to follow |
| Azuracast        | Migrated        | Staged and restored from staging

---

## 🧭 Next Steps

- Clean up misplaced show files in assets bucket
- Automate ZFS snapshot replication
- Consider Grafana/Prometheus dashboard for real-time metrics
- Continue phasing out legacy containers (LXC → full VMs)

---

This infrastructure is stable, secure, and built for scale. Further improvements will refine observability, automate recovery, and enhance multi-user coordination.
