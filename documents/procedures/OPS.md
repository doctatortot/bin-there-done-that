# 🚀 Genesis Radio - Healthcheck Response Runbook

## Purpose
When an alert fires (Critical or Warning), this guide tells you what to do so that **any team member**  can react quickly, even if the admin is not available.

---

## 🛠️ How to Use
- Every Mastodon DM or Dashboard alert gives you a **timestamp**, **server name**, and **issue**.
- Look up the type of issue in the table below.
- Follow the recommended action immediately.

---

## 📋 Quick Response Table

| Type of Alert | Emoji | What it Means | Immediate Action |
|:---|:---|:---|:---|
| [Critical Service Failure](#critical-service-failure-) | 🔚 | A key service (like Mastodon, MinIO) is **down** | SSH into the server, try `systemctl restart <service>`. | A key service (like Mastodon, MinIO) is **down** | SSH into the server, try `systemctl restart <service>`. |
| [Disk Filling Up](#disk-filling-up-) | 📈 | Disk space critically low (under 10%) | SSH in and delete old logs/backups. Free up space **immediately**. | Disk space critically low (under 10%) | SSH in and delete old logs/backups. Free up space **immediately**. |
| [Rclone Mount Error](#rclone-mount-error-) | 🐢 | Cache failed, mount not healthy | Restart the rclone mount process. (Usually a `systemctl restart rclone@<mount>`, or remount manually.) | Cache failed, mount not healthy | Restart the rclone mount process. (Usually a `systemctl restart rclone@<mount>`, or remount manually.) |
| [PostgreSQL Replication Lag](#postgresql-replication-lag-) | 💥 | Database replicas are falling behind | Check database health. Restart replication if needed. Alert admin if lag is >5 minutes. | Database replicas are falling behind | Check database health. Restart replication if needed. Alert admin if lag is >5 minutes. |
| [RAID Degraded](#raid-degraded-) | 🧸 | RAID array is degraded (missing a disk) | Open server console. Identify failed drive. Replace drive if possible. Otherwise escalate immediately. | RAID array is degraded (missing a disk) | Open server console. Identify failed drive. Replace drive if possible. Otherwise escalate immediately. |
| [Log File Warnings](#log-file-warnings-) | ⚠️ | Error patterns found in logs | Investigate. If system is healthy, **log it for later**. If errors worsen, escalate. | Error patterns found in logs | Investigate. If system is healthy, **log it for later**. If errors worsen, escalate. |

---

## 💻 If Dashboard Shows
- ✅ **All Green** = No action needed.
- ⚠️ **Warnings** = Investigate soon. Not urgent unless repeated.
- 🚨 **Criticals** = Drop everything and act immediately.

---

## 🛡️ Emergency Contacts
| Role | Name | Contact |
|:----|:-----|:--------|
| Primary Admin | (You) | [845-453-0820] |
| Secondary | Brice | [BRICE CONTACT INFO] |

(Replace placeholders with actual contact details.)

---

## ✍️ Example Cheat Sheet for Brice

**Sample Mastodon DM:**
> 🚨 Genesis Radio Critical Healthcheck 2025-04-28 14:22:33 🚨  
> ⚡ 1 critical issue found:  
> - 🔚 [mastodon] CRITICAL: Service mastodon-web not running!

**Brice should:**
1. SSH into Mastodon server.
2. Run `systemctl restart mastodon-web`.
3. Confirm the service is running again.
4. If it fails or stays down, escalate to admin.

---

# 🌟 TL;DR
- 🚨 Criticals: Act immediately.
- ⚠️ Warnings: Investigate soon.
- ✅ Healthy: No action needed.

---

# 🛠️ Genesis Radio - Detailed Ops Playbook

## Critical Service Failure (🔚)
**Symptoms:** Service marked as CRITICAL.

**Fix:**
1. SSH into server.
2. `sudo systemctl status <service>`
3. `sudo systemctl restart <service>`
4. Confirm running. Check logs if it fails.

---

## Disk Filling Up (📈)
**Symptoms:** Disk space critically low.

**Fix:**
1. SSH into server.
2. `df -h`
3. Delete old logs:
   ```bash
   sudo rm -rf /var/log/*.gz /var/log/*.[0-9]
   sudo journalctl --vacuum-time=2d
   ```
4. If still low, find big files and clean.

---

## Rclone Mount Error (🐢)
**Symptoms:** Mount failure or slowness.

**Fix:**
1. SSH into SPL server.
2. Unmount & remount:
   ```bash
   sudo fusermount -uz /path/to/mount
   sudo systemctl restart rclone@<mount>
   ```
3. Confirm mount is active.

---

## PostgreSQL Replication Lag (💥)
**Symptoms:** Replica database lagging.

**Fix:**
1. SSH into replica server.
2. Check lag:
   ```bash
   sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"
   ```
3. Restart PostgreSQL if stuck.
4. Monitor replication logs.

---

## RAID Degraded (🧸)
**Symptoms:** RAID missing a disk.

**Fix:**
1. SSH into server.
2. `cat /proc/mdstat`
3. Find failed drive:
   ```bash
   sudo mdadm --detail /dev/md0
   ```
4. Replace failed disk, rebuild array:
   ```bash
   sudo mdadm --add /dev/md0 /dev/sdX
   ```

---

## Log File Warnings (⚠️)
**Symptoms:** Errors in syslog or nginx.

**Fix:**
1. SSH into server.
2. Review logs:
   ```bash
   grep ERROR /var/log/syslog
   ```
3. Investigate. Escalate if necessary.

---

**Stay sharp. Early fixes prevent major downtime!** 🛡️💪

