# ⚠️ Incident Response Checklists for Common Failures

These checklists are designed to normalize responses and reduce stress during downtime in your infrastructure.

---

## 🔌 Node Reboot or Power Loss

- [ ] Verify ZFS pools are imported: `zpool status`
- [ ] Check all ZFS mounts: `mount | grep /mnt`
- [ ] Confirm Proxmox VM auto-start behavior
- [ ] Validate system services: PostgreSQL, Mastodon, MinIO, etc.
- [ ] Run `genesis-tools/healthcheck.sh` or equivalent

---

## 🐘 PostgreSQL Database Failure

- [ ] Ping cluster VIP
- [ ] Check replication lag: `pg_stat_replication`
- [ ] Inspect ClusterControl / Patroni node status
- [ ] Verify HAProxy is routing to correct primary
- [ ] If failover occurred, verify application connections

---

## 🌐 Network Drop or Routing Issue

- [ ] Check interface status: `ip a`, `nmcli`
- [ ] Ping gateway and internal/external hosts
- [ ] Test inter-VM connectivity
- [ ] Inspect HAProxy or Keepalived logs for failover triggers
- [ ] Validate DNS and NTP services are accessible

---

## 📦 Object Storage Outage (MinIO / rclone)

- [ ] Confirm rclone mounts: `mount | grep rclone`
- [ ] View VFS cache stats: `rclone rc vfs/stats`
- [ ] Verify MinIO service and disk health
- [ ] Check cache disk space: `df -h`
- [ ] Restart rclone mounts if needed

---

## 🧠 Split Brain in PostgreSQL Cluster (ClusterControl)

### Symptoms:
- Two nodes think they're primary
- WAL timelines diverge
- Errors in ClusterControl, or inconsistent data in apps

### Immediate Actions:
- [ ] Use `pg_controldata` to verify state and timeline on both nodes
- [ ] Temporarily pause failover automation
- [ ] Identify true primary (most recent WAL, longest uptime, etc.)
- [ ] Stop false primary immediately: `systemctl stop postgresql`

### Fix the Broken Replica:
- [ ] Rebuild broken node:
  ```bash
  pg_basebackup -h <true-primary> -D /var/lib/postgresql/XX/main -U replication -P --wal-method=stream
  ```
- [ ] Restart replication and confirm sync

### Post-Mortem:
- [ ] Audit any split writes for data integrity
- [ ] Review Keepalived/HAProxy fencing logic
- [ ] Add dual-primary alerts with `pg_is_in_recovery()` checks
- [ ] Document findings and update HA policies

---

## 🐘 PostgreSQL Replication Lag / Sync Delay

- [ ] Query replication status:
  ```sql
  SELECT client_addr, state, sync_state, sent_lsn, write_lsn, flush_lsn, replay_lsn FROM pg_stat_replication;
  ```
- [ ] Compare LSNs for lag
- [ ] Check for disk I/O, CPU, or network bottlenecks
- [ ] Ensure WAL retention and streaming are healthy
- [ ] Restart replica or sync service if needed

---

## 🪦 MinIO Bucket Inaccessibility or Failure

- [ ] Run `mc admin info local` to check node status
- [ ] Confirm MinIO access credentials/environment
- [ ] Check rclone and MinIO logs
- [ ] Restart MinIO service: `systemctl restart minio`
- [ ] Check storage backend health/mounts

---

## 🐳 Dockerized Service Crash (e.g., AzuraCast)

- [ ] Inspect containers: `docker ps -a`
- [ ] View logs: `docker logs <container>`
- [ ] Check disk space: `df -h`
- [ ] Restart with Docker or Compose:
  ```bash
  docker restart <container>
  docker-compose down && docker-compose up -d
  ```

---

## 🔒 Fail2Ban or Genesis Shield Alert Triggered

- [ ] Tail logs:
  ```bash
  journalctl -u fail2ban
  tail -f /var/log/fail2ban.log
  ```
- [ ] Inspect logs for false positives
- [ ] Unban IP if needed:
  ```bash
  fail2ban-client set <jail> unbanip <ip>
  ```
- [ ] Notify via Mastodon/Telegram alert system
- [ ] Tune jail thresholds or IP exemptions

---

> ✅ Store these in a Gitea wiki or `/root/checklists/` for quick access under pressure.
