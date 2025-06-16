# 🛡️ Server Hardening & Disaster Recovery Cheat Sheet

## 🔐 Server Hardening Checklist

### 🔒 OS & User Security
- ✅ Use **key-based SSH authentication** (`~/.ssh/authorized_keys`)
- ✅ Disable root login:  
  ```bash
  sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
  sudo systemctl restart sshd
  ```
- ✅ Change default SSH port and rate-limit with Fail2Ban or UFW
- ✅ Set strong password policies:
  ```bash
  sudo apt install libpam-pwquality
  sudo nano /etc/security/pwquality.conf
  ```
- ✅ Lock down `/etc/sudoers`, remove unnecessary sudo privileges

### 🔧 Kernel & System Hardening
- ✅ Install and configure `ufw` or `iptables`:
  ```bash
  sudo ufw default deny incoming
  sudo ufw allow ssh
  sudo ufw enable
  ```
- ✅ Disable unused filesystems:
  ```bash
  echo "install cramfs /bin/true" >> /etc/modprobe.d/disable-filesystems.conf
  ```
- ✅ Set kernel parameters:
  ```bash
  sudo nano /etc/sysctl.d/99-sysctl.conf
  # Example: net.ipv4.ip_forward = 0
  sudo sysctl -p
  ```

### 🧾 Logging & Monitoring
- ✅ Enable and configure `auditd`:
  ```bash
  sudo apt install auditd audispd-plugins
  sudo systemctl enable auditd
  ```
- ✅ Centralize logs using `rsyslog`, `logrotate`, or Fluentbit
- ✅ Use `fail2ban`, `CrowdSec`, or `Wazuh` for intrusion detection

## 💾 Disaster Recovery Checklist

### 📦 Backups
- ✅ Automate **daily database dumps** (e.g., `pg_dump`, `mysqldump`)
- ✅ Use **ZFS snapshots** for versioned backups
- ✅ Sync offsite via `rclone`, `rsync`, or cloud storage
- ✅ Encrypt backups using `gpg` or `age`

### 🔁 Testing & Recovery
- ✅ **Verify backup integrity** regularly:
  ```bash
  gpg --verify backup.sql.gpg
  pg_restore --list backup.dump
  ```
- ✅ Practice **bare-metal restores** in a test environment
- ✅ Use **PITR** (Point-In-Time Recovery) for PostgreSQL

### 🛑 Emergency Scripts
- ✅ Create service restart scripts:
  ```bash
  systemctl restart mastodon
  docker restart azuracast
  ```
- ✅ Pre-stage `rescue.sh` to rebuild key systems
- ✅ Include Mastodon/Gitea/etc. reconfig tools

### 🗂️ Documentation
- ✅ Maintain a **runbook** with:
  - Service recovery steps
  - IPs, ports, login methods
  - Admin contacts and escalation

### 🧪 Chaos Testing
- ✅ Simulate failure of:
  - A disk or volume (use `zpool offline`)
  - A network link (`iptables -A OUTPUT ...`)
  - A database node (use Patroni/pg_auto_failover tools)

---

> ✅ **Pro Tip**: Integrate all hardening and backup tasks into your Ansible playbooks for consistency and redeployability.
