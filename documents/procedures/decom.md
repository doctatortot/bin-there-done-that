# 🗑️ Decommissioning Checklist for `shredderv1`

**Date:** 2025-05-01

---

## 🔐 1. Verify Nothing Critical Is Running
- [ ] Confirm all services (e.g., AzuraCast, Docker containers, media playback) have **been migrated**
- [ ] Double-check DNS entries (e.g., CNAMEs or A records) have been **updated to the new server**
- [ ] Ensure any **active mounts, Rclone remotes, or scheduled tasks** are disabled

---

## 📦 2. Migrate/Preserve Data
- [ ] Backup and copy remaining relevant files (station configs, logs, recordings, playlists)
- [ ] Verify data was successfully migrated to the new ZFS-based AzuraCast VM
- [ ] Remove temporary backup files and export archives

---

## 🧹 3. Remove from Infrastructure
- [ ] Remove from monitoring tools (e.g., Prometheus, Nagios, Grafana)
- [ ] Remove from Ansible inventory or configuration management systems
- [ ] Remove any scheduled crons or automation hooks targeting this VM

---

## 🔧 4. Disable and Secure
- [ ] Power down services (`docker stop`, `systemctl disable`, etc.)
- [ ] Disable remote access (e.g., SSH keys, user accounts)
- [ ] Lock or archive internal credentials (e.g., API tokens, DB creds, rclone configs)

---

## 🧽 5. Wipe or Reclaim Resources
- [ ] If VM: Delete or archive VM snapshot in Proxmox or hypervisor
- [ ] If physical: Securely wipe disks (e.g., `shred`, `blkdiscard`, or DBAN)
- [ ] Reclaim IP address (e.g., assign to new ZFS-based VM)

---

## 📜 6. Documentation & Closure
- [ ] Log the decommission date in your infrastructure inventory or documentation
- [ ] Tag any previous support tickets/issues as “Resolved (Decommissioned)”
- [ ] Inform team members that `shredderv1` has been retired

---

## 🚫 Final Step
```bash
shutdown -h now
```

Or if you're feeling dramatic:
```bash
echo "Goodnight, sweet prince." && shutdown -h now
```
