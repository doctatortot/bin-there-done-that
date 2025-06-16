#!/bin/bash

# === CONFIG ===
SWAPPINESS_LEVEL=10
LOG_CLEANUP_LIMIT_DAYS=14
APACHE_SERVICES=("apache2" "httpd")
HOST=$(hostname)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# === Telegram Config ===
BOT_TOKEN="8178867489:AAH0VjN7VnZSCIWasSz_y97iBLLjPJA751k"
CHAT_ID="1559582356"

echo "🔧 [$HOST] Starting health cleanup..."

# 1. Tune swappiness
echo "→ Setting vm.swappiness to $SWAPPINESS_LEVEL"
echo "vm.swappiness=$SWAPPINESS_LEVEL" | tee /etc/sysctl.d/99-swappiness.conf > /dev/null
sysctl -p /etc/sysctl.d/99-swappiness.conf > /dev/null

# 2. Disable Apache if not needed
apache_disabled=""
for svc in "${APACHE_SERVICES[@]}"; do
  if systemctl list-units --type=service --all | grep -q "$svc"; then
    echo "→ Apache service '$svc' detected"
    if ! ss -tulpn | grep -q ":80"; then
      echo "   🔕 Apache appears idle. Disabling..."
      systemctl disable --now "$svc"
      apache_disabled="yes"
    else
      echo "   ⚠️ Apache is running and serving. Skipping stop."
    fi
  fi
done

# 3. Clean logs older than X days
echo "→ Cleaning logs older than $LOG_CLEANUP_LIMIT_DAYS days in /var/log"
find /var/log -type f -name "*.log" -mtime +$LOG_CLEANUP_LIMIT_DAYS -exec rm -f {} \;

# 4. Summary Info
MEM=$(free -h | grep Mem | awk '{print $4 " free"}')
SWAP=$(free -h | grep Swap | awk '{print $3 " used"}')
DISK=$(df -h / | awk 'NR==2 {print $4 " free"}')
LOAD=$(uptime | awk -F'load average:' '{print $2}' | xargs)

MSG="✅ [$HOST] Cleanup completed at $TIMESTAMP
Memory: $MEM
Swap: $SWAP
Disk: $DISK
Load: $LOAD"

if [ "$apache_disabled" == "yes" ]; then
  MSG="$MSG
Apache was detected and disabled ✅"
fi

# 5. Send Telegram message
curl -s -X POST https://api.telegram.org/bot$BOT_TOKEN/sendMessage \
  -d chat_id="$CHAT_ID" \
  -d text="$MSG"
