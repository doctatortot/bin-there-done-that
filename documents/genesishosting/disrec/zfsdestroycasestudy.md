# 📛 Case Study: Why RAID Is Not a Backup

## Overview

On May 4, 2025, we experienced a production data loss incident involving the `nexus` dataset on `shredderv1`, a Linux RAID5 server. Despite no hardware failure, critical files were lost due to an unintended command affecting live data.

This incident serves as a clear, real-world illustration of the maxim:

> **RAID protects against hardware failure — not human error, data corruption, or bad automation.**

---

## 🔍 What Happened

- `shredderv1` uses RAID5 for media storage.
- The dataset `nexus/miniodata` (housing `genesisassets`, `genesislibrary`, etc.) was accidentally destroyed.
- **No disks failed.** The failure was logical, not physical.

---

## 🔥 Impact

- StationPlaylist (SPL) lost access to the Genesis media library.
- MinIO bucket data was instantly inaccessible.
- Temporary outage and scrambling to reconfigure mounts, media, and streaming.

---

## ✅ Recovery

Thanks to our disaster recovery stack:

- Nightly **rsync backups** were synced to **The Vault** (backup server).
- **ZFS snapshots** existed on The Vault for the affected datasets.
- We restored the latest snapshot **from The Vault back to Shredder**, effectively reversing the loss.
- No data corruption occurred; sync validation showed dataset integrity.

---

## 🎓 Takeaway

This is a live demonstration of why:

- **RAID is not a backup**
- **Snapshots without off-host replication** are not enough
- **Real backups must be off-server and regularly tested**

---

## 🔐 Current Protection Measures

- Production data (`genesisassets`, `genesislibrary`) now replicated nightly to The Vault via `rsync`.
- ZFS snapshots are validated daily via a **dry-run restore validator**.
- Telegram alerts notify success/failure of backup verification jobs.
- Future goal: full ZFS storage on all production servers for native snapshot support.

---

## 🧠 Lessons Learned

- Always assume you'll delete the wrong thing eventually.
- Snapshots are amazing — **if** they're somewhere else.
- Automated restore testing should be part of every backup pipeline.

