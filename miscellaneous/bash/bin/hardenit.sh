#!/bin/bash
# harden_pyapps_box.sh - Secure the Genesis pyapps VM
# Run as root or with sudo

LOG_FILE="/var/log/genesis_pyapps_hardening.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
echo -e "\n🔐 Genesis pyapps VM Hardening - $DATE\n=====================================" | tee -a "$LOG_FILE"

# 1. Lock unused system accounts
LOCK_USERS=(daemon bin sys sync games man lp mail news uucp proxy www-data backup list irc gnats nobody systemd-network systemd-resolve systemd-timesync messagebus syslog _apt tss uuidd tcpdump usbmux sshd landscape pollinate fwupd-refresh dnsmasq cockpit-ws cockpit-wsinstance)
for user in "${LOCK_USERS[@]}"; do
  if id "$user" &>/dev/null; then
    usermod -s /usr/sbin/nologin "$user" && echo "[+] Set nologin shell for $user" | tee -a "$LOG_FILE"
    passwd -l "$user" &>/dev/null && echo "[+] Locked password for $user" | tee -a "$LOG_FILE"
  fi
done

# 2. Enforce password policy for doc
chage -M 90 -W 14 -I 7 doc && echo "[+] Set password expiration policy for doc" | tee -a "$LOG_FILE"

# 3. SSH hardening
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd && echo "[+] SSH config hardened and restarted" | tee -a "$LOG_FILE"

# 4. Install and configure Fail2ban
apt-get install -y fail2ban
cat <<EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port    = ssh
logpath = /var/log/auth.log
maxretry = 4
bantime = 1h
findtime = 10m
EOF
systemctl restart fail2ban && echo "[+] Fail2ban installed and restarted" | tee -a "$LOG_FILE"

# 5. Configure UFW
ufw allow ssh
# Example: allow specific ports for running screen tools
# Adjust these as needed for your app ports
ufw allow 5010/tcp  # toot
ufw allow 5011/tcp  # toot2
ufw allow 8020/tcp  # archive list 
ufw allow 8021/tcp  # archive console
ufw allow 5000/tcp #phone
ufw default deny incoming
ufw default allow outgoing
ufw enable

echo "[+] UFW firewall rules applied" | tee -a "$LOG_FILE"

# Done
echo "✅ pyapps hardening complete. Review log: $LOG_FILE"
exit 0
