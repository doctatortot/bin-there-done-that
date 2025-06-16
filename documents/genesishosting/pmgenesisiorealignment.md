# Postmortem: Genesis I/O Realignment

**Date:** May 8, 2025  
**Author:** Doc  
**Systems Involved:** minioraid5, shredder, chatwithus.live, zcluster.technodrome1/2, thevault  
**Scope:** Local-first mirroring, permission normalization, MinIO transition

---

## 🎯 Objective

To realign the Genesis file flow architecture by:

- Making local block storage the **primary source** of truth for AzuraCast and Genesis buckets
- Transitioning FTP uploads to target local storage instead of MinIO directly
- Establishing **two-way mirroring** between local paths and MinIO buckets
- Correcting inherited permission issues across `/mnt/raid5` using `find + chmod`
- Preserving MinIO buckets as **backup mirrors**, not primary data stores

---

## 🔧 Work Performed

### ✅ Infrastructure changes:
- Deployed block storage volume to Linode Mastodon instance
- Mirrored MinIO buckets (`genesisassets`, `genesislibrary`, `azuracast`) to local paths
- Configured cron-based `mc mirror` jobs:
  - Local ➜ MinIO: every 5 minutes with `--overwrite --remove`
  - MinIO ➜ Local: nightly pull, no `--remove`

### ✅ FTP Pipeline Adjustments:
- Users now upload to `/mnt/spl/ftp/uploads` (local)
- Permissions set so only admins access full `/mnt/spl/ftp`
- FTP directory structure created for SPL automation

### ✅ System Tuning:
- Set `vm.swappiness=10` on all nodes
- Apache disabled where not in use
- Daily health checks via `pull_health_everywhere.sh`
- Krang Telegram alerts deployed for cleanup and system state

---

## 🧠 Observations

- **High load** on `minioraid5` during `mc mirror` and `chmod` overlap
  - Load ~6.5 due to concurrent I/O pressure
  - `chmod` stuck in `D` state (I/O wait) while `mc` dominated disk queues
  - Resolved after `mc` completion — `chmod` resumed and completed

- **MinIO buckets were temporarily inaccessible** due to permissions accidentally inherited by FTP group
  - Resolved by recursively resetting permissions on `/mnt/raid5`

- **Krang telemetry** verified:
  - Mastodon swap usage rising under asset load
  - All nodes had Apache disabled or dormant
  - Health alerts triggered on high swap or load

---

## ✅ Outcome

- Full Genesis and AzuraCast data now reside locally with resilient S3 mirrors
- Mastodon running on block storage, no longer dependent on MinIO latency
- FTP integration with SPL directory trees complete
- Cleanup script successfully deployed across all nodes via Krang
- Daily health reports operational with alerts for high swap/load

---

## 🔁 Recommendations

- Consider adding snapshot-based ZFS backups for `/mnt/raid5`
- Build `verify_mirror.sh` to detect drift between MinIO and local storage
- Auto-trigger `chmod` only after `mc mirror` finishes
- Monitor long-running background jobs with Krang watchdogs

---

**Signed,**  
Doc  
Genesis Hosting Technologies

